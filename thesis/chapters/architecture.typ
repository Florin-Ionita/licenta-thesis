#import "../prelude.typ": *
#import "@preview/fletcher:0.5.5" as fletcher: diagram, node, edge

== Solution overview

The solution is a secure communication system for parties who need their
traffic to stay secret no matter how much computing power an attacker has. The way it works is that the two communicating
endpoints obtain a shared secret without a public-key exchange: instead of
negotiating a key over the network, both sides draw identical key material from
a quantum key distribution (QKD) link and use it to protect their traffic. Once both sides hold the same key, the endpoints run a
TLS-style handshake to authenticate the channel and then encrypt the
application payload.

We describe the architecture abstractly as a small set of replaceable black
boxes. The system has two endpoints. Each end holds a QKD endpoint, a KME that
mediates access to the keys, and a SAE that consumes them. The two QKD
endpoints face each other over the quantum link and converge on the same key;
the two KMEs hand that key to their local SAE over a standard interface, and
the two SAEs run the secure session between them. Two other boxes observe the system, one to evaluate it and one to monitor it. Every box can be replaced with different hardware or algorithms, as long as the
system still delivers information-theoretically secure ciphertext. The QKD link
is a good example: it cannot be replaced with a classic channel, because that
would defeat the purpose of the thesis.

#figure(
  diagram(
    spacing: (20mm, 18mm),
    node-stroke: 0.5pt,
    node-corner-radius: 3pt,
    node-shape: rect,

    node((1, 0), [QKD\ endpoint A], name: <qa>),
    node((3, 0), [QKD\ endpoint B], name: <qb>),
    node((1, 1), [KME A], name: <ka>),
    node((3, 1), [KME B], name: <kb>),
    node((1, 2), [SAE A\ (master)], name: <sa>),
    node((3, 2), [SAE B\ (slave)], name: <sb>),

    node((0, -0.22), [Benchmark], name: <bench>, stroke: (dash: "dashed")),
    node((0, 0.22), [Dashboard], name: <dash>, stroke: (dash: "dashed")),

    // Channel 1: QKD <-> QKD, two separate straight arrows (offset, not curved)
    edge(<qa>, <qb>, "<->", [quantum], shift: 4pt, label-size: 0.7em),
    edge(<qa>, <qb>, "<->", [classical (reconciliation)], shift: -4pt, label-side: right, label-size: 0.7em),
    // Channel 2: KME <-> KME (synchronisation)
    edge(<ka>, <kb>, "<->", [synchronisation], label-size: 0.7em),
    // Channel 3: QKD -> KME (one-way push)
    edge(<qa>, <ka>, "-|>", [raw key], label-side: left, label-size: 0.7em),
    edge(<qb>, <kb>, "-|>", [raw key], label-side: right, label-size: 0.7em),
    // Channel 4: SAE <-> KME (ETSI 014)
    edge(<sa>, <ka>, "<->", [ETSI 014], label-side: left, label-size: 0.7em),
    edge(<sb>, <kb>, "<->", [ETSI 014], label-side: right, label-size: 0.7em),
    // Channel 5: SAE <-> SAE (QTLS data path)
    edge(<sa>, <sb>, "<->", [QTLS handshake + data], label-size: 0.7em),

    node((0, -0.62), [#text(0.75em, gray)[*Monitoring*]], stroke: none),
    node(enclose: (<bench>, <dash>),
      stroke: (dash: "dashed", paint: gray), inset: 4mm, snap: -1),
    
    node((0, -1.15), [#text(gray)[*Application stack*]], stroke: none),

    node(enclose: (<qa>, <qb>, <ka>, <kb>, <sa>, <sb>, <bench>, <dash>),
      stroke: 0.75pt + gray, inset: 10mm, snap: -1),
  ),
  caption: [System architecture. Each end holds a QKD endpoint, a KME and a
    SAE. The five protocol channels are: QKD to QKD (a quantum link and a
    classical public link), QKD to KME (key production), KME to KME
    (synchronisation), SAE to KME (ETSI 014), and SAE to SAE (the QTLS data
    path). The benchmark and dashboard monitor the running stack.],
) <fig:architecture>


== Functional decomposition

This section breaks the system into its functional blocks. For each block we
state what it is responsible for and what it exposes to the others, but not how
it works inside; the internal algorithms are left for the implementation
chapter.

=== Secure application entity (SAE)

The SAE is the application-facing end of the system. Its point is to send data
securely to the other endpoint, and it hides everything about QKD behind a
familiar connection interface. An SAE does two things. First, it obtains a key
from its local KME over the ETSI interface: the client SAE pulls a fresh key
and gets back a key identifier together with the key, and the server SAE later
resolves that same identifier into the same key. Second, it runs a TLS-style
handshake with the SAE on the other end, which carries the key identifier as an
authentication mechanism to prove that both sides hold the same QKD key without
ever sending the key over the wire. After that, the rest of the communication
is secured using the QKD keys.

The SAE has three interfaces. Towards the application it exposes a secure connection: one side opens it
as a client and the other accepts it as a server, after which both can send and
receive data and finally close the connection, much like an ordinary secure
socket. Towards the KME, the SAE is only a client of the ETSI interface, meaning it
requests and resolves keys by their identifier and exposes nothing back.
Towards the peer SAE, it exposes the handshake messages that carry the key
identifier and prove key possession, followed by the protected data stream. The
SAEs work asymmetrically: one acts as the master that pulls a fresh key and one
as the slave that resolves the identifier it is given. Once the session is
established the roles no longer matter and the two ends are interchangeable.

=== Key management entity (KME)

The KME sits between the QKD endpoint and the SAE. The QKD endpoint produces a
stream of raw key material but knows nothing about who wants it; the KME turns
that stream into a service an application can actually use. In practice, it
stores the material it receives, gives each key an identifier, and hands keys
out on request, while making sure a key is never given to an SAE that is
not allowed to have it and never handed out twice. This way, the SAE never
touches the QKD endpoint directly.

A KME talks over three interfaces. Towards its local QKD endpoint it only
receives: the endpoint pushes finished key material into the store, and the KME
accepts and keeps it. Towards its local SAEs it exposes the ETSI interface,
which behaves differently depending on the type of SAE: a master SAE asks for a
fresh key and receives an identifier together with the key, and a slave SAE
asks for the key behind a given identifier. On every such request the KME also
checks that the requesting SAE is authorised. Towards the other KME it exposes
a synchronisation interface. The two KMEs must give the same key material the
same identifier on both ends, so that a key the master pulls on one side
resolves to the same key on the other, and they must ensure that a key reserved
on one side is never reused on the other. The KME exposes the ETSI interface to
its SAEs and the synchronisation interface to its peer, but it never exposes
the QKD endpoint to anyone.

=== QKD endpoint

The QKD endpoint is the provider of key material. The way it works is: there is one at each end,
and the two of them are what actually let the system work: through the laws of
quantum mechanics they arrive at the same secret key in two separate places,
without that key ever travelling over a channel an attacker could tamper with.

A QKD endpoint has three interfaces. With the QKD endpoint at the other end it
shares a quantum channel, over which the raw key is established, and a public
classical channel, over which the two ends compare notes and reconcile the
errors the quantum channel introduced. Towards its local KME it pushes the
finished key material. The result of that exchange is a block of final, agreed key
material that is identical on both ends. Towards its local KME, the endpoint
only pushes information. How the key is actually produced and corrected
is internal to this box and is described in the background and implementation
chapters.

=== Benchmark module

The benchmark module is used to observe the metrics in the system. Its job is to measure the system under
controlled conditions and produce the data the evaluation chapter reports
on: how long a handshake takes, how much application data the one-time-pad path
sustains, the time-to-last-byte (TTLB) #cite(<kampanakis2024ttlb>), how fast
the key pool drains under load, how the key rate behaves as the error rate
changes, and how the key exchange compares against classical and post-quantum
alternatives. It drives a full instance of the entire stack and runs a chosen set of
scenarios and writes the raw results and the resulting plots to disk, so that a
run is reproducible and the output can be regenerated without re-measuring.

=== Visualisation dashboard

The second observing box is a live dashboard that shows how the implementation works in real time: the
key blocks as they are produced, the handshake as it advances step by step, the
records as they are sent, and the key pool as it fills and drains. It attaches
to a running instance of the stack and listens to the events each layer emits,
without influencing the protocol. Its purpose is to give the system
a visual demo, useful both during development and for showing a live demo. It exposes a
browser interface a person can watch, and consumes the events the running
stack publishes.

== Interfaces and communication

The communication between the boxes is done in five different communication channels. The first channel is the one between the two
 QKDs that implements both a quantum and classical link for reconciliation. The quantum link is used for sending the qubits that 
 create the quantum keys. The second channel is between the two different KMEs and it uses a link for synchronisation between the two 
 ends, making sure we do not use the same key in two different records and that the keys used by both endpoints are corresponding. The third channel is between the QKD 
 and the KME, being a one way channel, the KME consuming the raw
 produced keys from the QKD anytime it sends them. The fourth channel is 
 between the KME and SAE, using the ETSI 014 format, and its
 responsibility is to make sure that the SAEs get the keys from the KMEs
 so they can secure their data. The last channel, between SAEs, is used 
 for data communication and initiating the TLS-style handshake to 
 authenticate.

 The flow of a key used in securing a record is as follows: first, the two QKD nodes each arrive at the same key, which is reconciled over the
 classical link, and then it is given to the KMEs. The KMEs parse the raw key output and generate an identifier that they have to synchronise on both ends, so the same key does not get a different identifier on the two KMEs, which would make it unusable. After the synchronisation process is done, the key is ready to be used by the SAEs in two different scenarios. If SAE A is the one that initiated the connection (the master), it will request the key and its id from its KME A, then the master SAE initiates a TLS-style handshake giving the slave SAE the key id so it knows what key to request from its KME. After that, both SAEs have the same key and can secure their connection using the same flow, which can be interchanged, meaning the SAEs can be both slave
and master in the same connection. At the same time the KMEs make sure
that they stay synchronised and keep track of which keys were used and which keys
are available.

 Once the session is running, the two SAEs no longer talk to the KMEs. Each record consumes a slice of the shared key, and both sides advance through the same key, so they stay in sync on their own.

 Each channel has to respect some rules so the boxes can be replaced without breaking the others. The channel between the QKD and the KME only has to deliver finished key material, so the KME does not care how the key was produced. The channel between the two KMEs has to guarantee that the same key gets the same identifier on both ends and that a key is never handed out twice. The channel between the KME and the SAE has to follow the ETSI 014 format, so any SAE that speaks in that standard can request keys. The channel between the two SAEs has to follow the handshake protocol, so the key id is carried across and both sides prove they hold the same key before any data is sent.

== Non-functional considerations

The architecture supports modularity (boxes can be replaced with different implementations as long as they respect their set of rules), encapsulation (the KME does not need to know how the QKD works) and separation of concerns (the KME is used for key preparation, delivery and synchronisation, the QKD is used to generate key material and the SAE is the consumer and maintainer of the connection). For a common consumer of the stack, the implementation is abstracted so the client needs only to understand the ETSI 014 standard to receive the keys and the handshake protocol.

In addition, the communication between SAE and KME is standardized (ETSI 014), making it easy to implement, and the data path between the two SAEs is information-theoretically secure at a cost (OTP encrypts the communication with keys as long as the message), while other channels (authentication from SAE to KME, QKD to QKD classic link for reconciliation etc.) depend on infrastructure. 
The TLS handshake has overhead caused by requesting the keys from its KME through the ETSI 014 API and a session is initiated by a handshake and ends when the SAEs consume the key they requested from the KME, highlighting that the stack uses QKD keys. For evaluation, the stack gives transparent data evaluation and visualisation that can be reproduced.

By design, a session stops once its key runs out, instead of quietly fetching more. Because a one-time pad spends one key byte per data byte, this makes the cost of OTP and the QKD key rate visible. The alternative would be to fetch a new key mid-session and switch to it, which is an extension left for future work.

== Mapping to implementation and evaluation

Having the architecture presented, in order to implement the stack there are a lot of decisions that need to be taken and make sense with the proposed layout. The SAE becomes the QTLS endpoint, which integrates the handshake behaviour, the key schedule, and the
one-time-pad and Wegman-Carter record protection, together with the client
that talks to the KME. The KME becomes the key store, the ETSI 014 REST API,
and the synchronisation path between the two stores. The QKD endpoint develops the key generation, the reconciliation and privacy-amplification. The benchmark module and the
dashboard become the measurement runner and the live demo visualisation.

The evaluation chapter then validates these boxes through the experiments the
benchmark module runs: the handshake latency and time-to-last-byte against the
post-quantum TLS baseline, the rate at which the key pool drains under
concurrent sessions, the per-record key consumption, and the reconciliation
leakage.
