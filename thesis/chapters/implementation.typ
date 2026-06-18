#import "../prelude.typ": *

== Implementation overview

The whole stack is implemented in Python and its libraries, with a single small
component in C. Python's well-developed libraries, together with it being an easy language
to understand (which makes it easier to concentrate on the critical parts of the application), 
made it the right choice for a research prototype whose goal is to show that 
the protocol works and to measure its cost. The language has strong cryptographic
library support, supports asynchronous I/O, and lets the QKD layer, the KME,
the QTLS endpoint, the benchmark harness and the dashboard all live in one 
process and one event loop which keeps the demo in a single observable place. The one place where Python was not enough is the 
Cascade reconciliation, which is written in C and called through `ctypes`.

== How the stack is assembled

Although the architecture describes two ends, each with its own QKD endpoint,
KME and SAE, the implementation runs all of them inside a single process and a
single asyncio event loop #cite(<python-asyncio>). This way, every layer the
thesis describes is actually running and exercising the same code the tests
cover, rather than being mocked. A small orchestrator owns every background
task and wires the layers together as an asynchronous context manager, so that the whole system can be run or stopped.

The flow is built bottom-up, meaning that a producer generates final key blocks and puts
them on a shared queue. A feeder then takes each block off the queue and writes
it into both key stores, KME A and KME B, under the same identifier, which is
what keeps the two stores synchronised. The orchestrator waits until both
stores hold at least one key before it lets any handshake start, so the first 
connection cannot race ahead of the producer.

After the KMEs hold at least one key each, the SAEs begin the TLS-style handshake. Each one reaches its KME without going through
the network: instead of opening a real socket, the requests are delivered
straight into the KME application through its ASGI (Asynchronous Server Gateway
Interface) interface, the standard interface a Python web server uses to talk
to a web application. The full ETSI
014 request path still runs, only the network transport is skipped. The QTLS (SAEs)
server and client, by contrast, talk to each other over a real loopback TCP
socket. The master
SAE pulls a key, the handshake carries its identifier to the slave, the slave
resolves the same key from its own KME, and from there the two SAEs exchange
protected records until the key runs out.

The orchestrator only assembles components
that already exist and are tested on their own. This way,
what runs in the live demo is exactly the code validated by the earlier tests,
with the orchestrator adding only the wiring.

== Technology choices

The QKD layer has been implemented in two ways that are interchangeable sources, both of which produce the same
kind of final key block. The first is a
simulation built on Qiskit #cite(<qiskit2024>): one round of BB84 is expressed
as a real quantum circuit and run on the AerSimulator using the stabilizer
method, which handles many qubits per round almost instantly because BB84 only
uses Clifford gates. @fig:bb84-circuit shows one round on four qubits, chosen so the four
combinations of preparation and measurement basis all appear. On $q_0$ Alice
prepares bit $0$ in the Z basis and Bob measures in Z as well, so the bases
match and the bit is kept. On $q_1$ Alice sends bit $1$ in Z but Bob measures in
X: the bases differ and the result is discarded during sifting. On $q_2$ both
use the X basis (Alice applies X then H to encode a $1$, Bob applies H before
measuring), the bases match and the bit survives. On $q_3$ Alice prepares in X
while Bob measures in Z, another mismatch that is dropped. Two of the four
positions survive sifting and form the sifted key for this round.

#figure(
  image("/docs/figures/bb84_circuit_demo.pdf", width: 80%),
  caption: [A BB84 round as a Qiskit circuit on four qubits. Alice's
    preparation (the leftmost gates) and Bob's measurement bases together cover
    every combination of the $Z$ and $X$ basis.],
) <fig:bb84-circuit>

The second is an abstract key generator that
does not simulate qubits, it draws random key material, applies a
configurable error rate to model a noisy channel, and runs that through the
same reconciliation and privacy amplification as BB84. This is the source that
feeds the stack and the benchmarks. Using an abstraction is needed because simulating
 bb84 rounds and reconciliation would need strong computational power.

The KME exposes its ETSI 014 interface with FastAPI #cite(<fastapi>). 
ETSI 014 is a REST interface with strict request and
response formats, and FastAPI maps onto it directly: the data formats become
Pydantic #cite(<pydantic>) models that validate every field against the
standard, and the four endpoints become route handlers. A custom HTTP server written from scratch
was rejected because it would mean reimplementing validation and routing for no protocol gain.

The SAE talks to the KME with httpx #cite(<httpx>), chosen over the more common
requests library for two reasons: it is asynchronous, which fits the
single event loop design, and it can drive a FastAPI application in process
through its ASGI interface, so the tests exercise the full ETSI request path
without opening a real socket. A socket connection works with this implementation too.

Reconciliation runs the Cascade algorithm #cite(<brassard1994secret>),
implemented in C language and loaded through `ctypes`. Cascade is the bottleneck of the
key procedure because it makes many passes over the raw key, and a pure Python
version was too slow to keep the key rate believable and significant. In case the C
implementation cannot be run, the code will show an error and stop itself.

The cryptographic primitives that are not information-theoretic, the HKDF key
schedule, the SHA-2 transcript hashing, and the X.509 certificate handling for
mTLS, come from the cryptography #cite(<pyca-cryptography>) library rather than
being written by hand. The one-time pad and the Wegman-Carter MAC, which are the
information-theoretic core, are implemented directly so their cost and
behaviour are fully visible in the measurements.

The dashboard is a Streamlit #cite(<streamlit>) application with Plotly
#cite(<plotly>) charts, chosen because it turns a single Python script into a
live browser dashboard with almost no interface code, which is not the scope of this thesis.
The benchmark suite uses pyperf #cite(<pyperf>) for the measurements that
need a stable average. The handshake is timed directly instead, because there
the interesting number is the real cost of a single reconnection, not an
average over many runs.

== Core components

This section describes how the central components are built. Each one is
presented together with the problems and design decisions it raised. They are considered
to be critical parts of the stack and went through several iterations before reaching their current form.

=== Key management entity

Each KME holds its keys in a store indexed by identifier. When a master SAE
requests a key, the store checks the access list, takes the oldest unused key,
marks it reserved for that master and slave pair, and mirrors the reservation
to the peer store (the slave KME) before returning. The mirror happens while the shared lock is
still held, so the local mark and the peer reservation commit as one step,
which is what stops the same key from being delivered on both ends.

#figure(
  align(left)[#text(size: 9pt)[```python
function take_key(master, slave):
    acquire shared lock
    if not authorised(master, slave):
        abort: access denied
    key <- oldest unused key in store
    if no such key:
        abort: pool empty
    mark key reserved for (master, slave)               // local
    mirror reservation (key.id, master, slave) to peer  // same lock
    release shared lock
    return (key.id, key.material)
```]],
  caption: [Reserving a key on the master KME. The local mark and the peer
    mirror commit together under one lock, so a key is never delivered twice.],
) <fig:keystore>

==== KME-to-KME synchronisation

The two KMEs that an ETSI 014 deployment places at the ends of a QKD link
must agree atomically on which key material backs which `key_ID` and on the
SAE pair each delivered key is reserved for. In a distributed deployment this
is done over an authenticated KME-to-KME channel, typically a two-phase commit,
so that a master pull and the corresponding peer
reservation either both succeed or both fail.

The implementation reached its current form through two iterations. The first
design gave each `KeyStore` its own lock and turned out to be both slow,
because every reservation paid a lock hand-off between the two stores, and
racy, because a master could pull a key on KME A before the feeder had finished
propagating the same block to KME B. The final design replaces the two locks
with a single reentrant lock (`threading.RLock`) shared by both stores through
`link_peer`, so that marking a key locally and mirroring the reservation to the
peer happen under one lock and commit as one atomic step. The same lock also
guards `add_block` in the feeder, closing the race. The lock is reentrant
because `take_keys` calls `peer.apply_reservation` while still holding it, and
`apply_reservation` re-acquires the same shared lock. Using a reentrant lock lets the
holding thread re-enter instead of deadlocking, so each function that needs atomicity 
stays correct on its own, with its atomicity guaranteed by the lock it takes rather 
than by which caller invoked it.
Microbenchmarks confirmed that at the demo's concurrency level this shared lock
is not a bottleneck.

This is a simplified synchronisation that works and avoids a lot of
complexity. A production
KME would replace the shared lock with a proper distributed protocol such as
two-phase commit, but the rest of the storage and API code would be unaffected
by that substitution.

==== Scope of the ETSI 014 implementation

The KME component implements the single pair subset of ETSI GS QKD 014
V1.1.1: one master SAE, one slave SAE, and one peer KME on the other end of
the QKD link. Multicast key delivery to multiple slave SAEs (the optional
`additional_slave_SAE_IDs` field of the Key request data format in clause 6.2 of
the standard) is out of scope. The endpoints
that the standard prescribes #cite(<etsi2019qkd014>) are exposed
(`GET /status`, `GET`/`POST /enc_keys`, `GET`/`POST /dec_keys`) with the
request and response data formats matching the standard verbatim for every
field that lies inside that single pair scope. An example of a status response 
carries `source_KME_ID`, `target_KME_ID`,
`key_size` and `stored_key_count`, and a delivered key is a `key_ID` paired
with its Base64-encoded `key` material. Each format is a Pydantic model, so a
request or response that does not match the standard's shape is rejected before
it reaches any protocol logic.

Forward-compatibility and extension support were left out so the thesis would
not have to add a big pile of KME-to-KME coordination logic that does not change
any of the properties it evaluates: key-ID synchronisation, no-reuse, ETSI
wire-format conformance, and the cost of staying information-theoretically
secure on the application data path. If this functionality were developed, it
would extend the existing `KeyStore` mirror mechanism rather than restructure it.

==== Authentication and the mTLS gap

ETSI 014 clause 5.1 #cite(<etsi2019qkd014>) states that "all communications
between SAE and KME shall use the HTTPS protocols (with TLS version 1.2 or
higher)" and that "at the connection establishment, mutual authentication
between SAE and KME shall be performed", with the SAE ID derived from the
Common Name (CN) of the client certificate. 

The cryptographic simulation for that mTLS is built
in the stack (a self-signed demonstration Certificate Authority
together with X.509 leaf-certificate issuance, where the SAE ID is carried
in the leaf CN, as the standard prescribes), and its end-to-end
validity is exercised by an integration test
(`test_mtls_cert_chain_round_trip`) that verifies a client certificate
chains back to the demo CA and that its CN is the expected SAE ID.

At runtime, the SAE identity is resolved through a single injectable
dependency, `current_sae`, that reads an `X-SAE-ID` header instead of the
certificate's CN. The assumption behind this is that, for what the thesis
measures, how an SAE is identified is not critical and the key-ID synchronisation,
no-reuse, and ETSI wire-format conformance are all determined by the key store
and the route handlers, none of which depend on the identification method.
Authentication here is a property of the surrounding infrastructure, so we simplify
 it to a header and keep identity
resolution in one place. An upgrade would be implemented by serving
the KME over real sockets with mTLS and extracting the CN from the verified
peer certificate and because `current_sae` is the only place identity is resolved,
that upgrade touches no other module.

==== Extensibility

To support extensibility, the KME data structures are organised so that the extension fields the
standard reserves "for future use" can be added without touching the storage
layer or the KME-to-KME synchronisation path. The `KeyStore` indexes blocks
by their UUID and treats the rest of each block as opaque payload; adding a
`key_extension` object would amount to a new optional Pydantic field on the
`Key` model and a pass-through in the API serialiser. The same is true of
`status_extension` and the request-side `extension_mandatory` /
`extension_optional` arrays: parsing them is local to the request handler,
and the storage contract is unchanged.

=== QKD layer

After sifting, Alice's and Bob's keys still differ on a fraction of positions
given by the QBER. The reconciliation step first checks that the QBER is below
a configurable abort threshold, the Shor-Preskill gate, and raises if it is
not, so a channel that is too noisy or under eavesdropping never yields a key.
Below the threshold, it runs Cascade to correct the differing bits and counts
exactly how many parity bits were revealed on the public channel. Privacy
amplification then shrinks the corrected key by at least that many bits, using
a hash that removes whatever an eavesdropper could have learned, so the final
key is bit-identical for both ends and secret. If Cascade fails to converge,
the result is treated as an abort rather than a bad key. @fig:reconcile
sketches the algorithm.

#figure(
  align(left)[#text(size: 9pt)[```python
function reconcile_and_amplify(alice, bob, qber):
    if qber >= abort_threshold:        // Shor-Preskill gate
        abort: QBER too high

    // Cascade reconciliation, over the public channel
    leaked <- 0
    for pass in 1 .. P:
        shuffle both keys by an agreed permutation
        split into blocks
        for each block:
            if parity(alice_block) != parity(bob_block):
                binary-search the block to flip one differing bit
                leaked <- leaked + bits announced
        revisit earlier passes for newly-exposed odd blocks
    if alice != bob:
        abort: failed to converge

    // Privacy amplification
    shrink         <- leaked + eve_information     // bits to remove
    secure_length  <- len(alice) - shrink
    key <- SHAKE128(alice).output(secure_length)   // variable-length hash
    return key      // identical on both ends, and secret
```]],
  caption: [The reconciliation and privacy-amplification pipeline. Cascade
    corrects the differing bits while tallying the parity bits it reveals;
    privacy amplification then removes at least that many bits.],
) <fig:reconcile>

=== QTLS endpoint

The SAE is the component an application actually uses to send data and it ties
together the KME client and the secure session. Each SAE owns a client to its
local KME, through which it requests or resolves keys by identifier, and it
speaks the QTLS protocol to the SAE at the other end. To the application above
it, the SAE looks like an ordinary secure socket: one side calls `connect` and
the other `accept` to establish the session, after which both use `send`,
`recv` and `close`. The two endpoints are asymmetric only while the key is
obtained, the master pulls a fresh key and the slave resolves it by identifier,
but once the session is up the two directions are independent and the roles no
longer matter.

The protocol is best understood as TLS 1.3 with the (EC)DHE exchange replaced. QTLS
removes that step and substitutes the QKD key looked up from the KME.
Everything around it follows RFC 8446: the same message flow, the same
transcript handling, the same Finished step. This keeps it TLS-like, and it is
also where its guarantee changes, since the shared secret no longer comes from a
computational assumption but from the quantum channel.

That QKD key feeds a key schedule that follows the structure of RFC 8446
section 7.1, simplified to the secrets this protocol actually uses: a single
`HKDF-Extract` from the QKD key, where TLS uses the (EC)DHE secret, with no
pre shared key or early secret stage, followed by the same `Derive-Secret` and
`HKDF-Expand-Label` steps and labels. From it the schedule derives the traffic
keys for each direction, the material for the Finished messages, and the
one-time-pad stream for the records.

The handshake itself is a short state machine: the client sends its key
identifier in the ClientHello, checks that the ServerHello echoes the same
identifier, and the two sides exchange Finished messages. Authentication is
where QTLS departs most visibly from TLS, as there are no certificates or
signatures: each side proves its identity simply by holding the same QKD key,
demonstrated by the Finished message, a Wegman-Carter tag over the transcript
that also proves the transcript was not tampered with. These messages are serialised as compact JSON
rather than TLS's byte-exact binary, which adds parsing code but no security and
keeps the handshake readable in captures.

Once the handshake completes, the data path is protected with the
information-theoretic primitives introduced in the background chapter.
Confidentiality comes from a one-time pad: the payload is XOR-ed with key bytes
drawn from the key stream, which holds the QKD material behind an offset that
only moves forward, so a byte is never reused and a request for more bytes than
remain raises an error rather than wrapping, turning key exhaustion into a hard stop.
Integrity comes from a Wegman-Carter tag whose one-time mask is taken fresh from
the same key stream, the hash key is reused across records but the mask is not,
which costs 16 key bytes per record on top of the payload. Every record is
sealed the same way, shown in @fig:record, consuming `len(payload) + 16` key
bytes in a fixed order, so both ends consume the same key bytes in the same
order and stay synchronised without exchanging any extra information.

#figure(
  align(left)[#text(size: 9pt)[```python
function seal(rtype, plaintext):
    ciphertext <- plaintext XOR key_stream.take(len(plaintext))
    mask          <- key_stream.take(16)        
    header     <- pack(rtype, len(ciphertext))   // record type + length
    tag        <- wegman_carter(header + ciphertext, mask)
    return header + ciphertext + tag
```]],
  caption: [Sealing one record: one-time-pad encryption followed by a
    Wegman-Carter tag, consuming payload-length plus 16 key bytes.],
) <fig:record>

== Environment and setup

The whole project is a single Python package, so setting it up takes one
command after creating a virtual environment, and a `Makefile` wraps the common
tasks so none of them have to be typed by hand. `make setup` creates the
environment and installs the package together with its optional groups (the
test, dashboard and benchmark dependencies). After that, `make demo` runs the
command-line chat demo, `make dash` launches the live dashboard in the browser,
`make test` runs the test suite, and `make bench` runs the quick benchmark
profile. The only requirement beyond Python is a C compiler, used once to build
the Cascade extension during installation. The project requires Python 3.12 or
newer and @tab:deps lists the main libraries and the minimum versions the build
pins.

#figure(
  table(
    columns: (auto, auto, auto),
    align: (left, left, left),
    table.header([*Library*], [*Min. version*], [*Used for*]),
    [Qiskit / qiskit-aer], [1.2 / 0.15], [BB84 circuit simulation],
    [NumPy], [1.26], [bit packing in reconciliation],
    [FastAPI], [0.115], [ETSI 014 REST interface],
    [Pydantic], [2.8], [request/response validation],
    [httpx], [0.27], [SAE-side KME client],
    [cryptography], [43], [HKDF, SHA-2, X.509],
    [Streamlit / Plotly], [1.31 / 5.20], [live dashboard],
    [pyperf], [2.6], [benchmark timing],
    [pytest], [8.0], [test suite],
  ),
  caption: [Main dependencies and the minimum versions pinned by the build.],
) <tab:deps>
