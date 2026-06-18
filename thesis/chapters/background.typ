#import "../prelude.typ": *

Computing depends on communication between peers and the problem it solves is
old. Smoke signals were among the earliest forms of long distance
communication, and they already worked the way every protocol since has: the
two sides agreed beforehand on what a given puff or sequence meant, and that
shared convention, not the smoke, carried the message. Modern communication is
the same idea grown to large scale meaning for two parties to communicate they follow
shared standards that fix how a message is framed, how a session opens, and
what each side may assume about the other. The Transport Layer Security
protocol, described later in this chapter, is an important standard, carrying most of the
encrypted traffic on the Internet.

Since the smoke, a lot has changed: communication has become an entire domain of its own, resting on a vast infrastructure that spans the planet and scales to almost any point on the globe. Most communication now happens between parties that have never met, across networks neither of them owns. A browser opens a session with a server it has no prior
relationship with, a service calls another through infrastructure run by
someone else entirely. The path a message takes is shared with unknown others,
any of whom might read it or tamper with it along the way that leads to the fact that a shared convention
is no longer enough by itself. Agreeing on what a message means does nothing to
keep it private or intact while it crosses ground neither party trusts.

This is why in communication it became important to have a security layer.
Security is not just one property but several guarantees at once: that an outsider
cannot read the traffic, cannot alter it without being noticed, and is in fact
the party it claims to be. These are confidentiality, integrity, and
authentication, and a protocol like TLS exists to deliver all three over a
channel it cannot trust. How each is achieved, and what it assumes, is the
subject of the section on security models later in this chapter.

How strong those guarantees must be is not fixed. It depends on what the
information is worth and how long it has to stay protected. A session token
that expires in minutes only has to resist an attacker for minutes. A medical
record or a state secret may need to stay confidential for decades, long enough
that an adversary who just stores the traffic today and waits could still break
it later. How much security is enough, and whether the strongest guarantee is
even within reach, is one of communication's more important problems.

All of this rests on an assumption that is rarely contested. The key
exchange that protects almost every connection on the Internet is only
computationally secure: it holds because no known algorithm can recover the key
in any feasible time, not because recovering it is impossible. The hardness it
depends on is determined only by the absence of a fast enough
attack so far.

This is a concern because the history of cryptography is full of
algorithms that were trusted in their time and broken later, as computers grew
faster and new algorithms were developed. The Data Encryption Standard (DES) algorithm was eventually broken by sheer brute force: in 1998 a
purpose built machine recovered a DES key in under three days
#cite(<eff1998crackingdes>), more than its 56-bit key could withstand. To continue on this idea, the hash function MD5, once used everywhere, was shown to admit
practical collisions in 2004 #cite(<wang2005md5>), and SHA-1 followed in 2017
when the first full collision was produced #cite(<stevens2017sha1>). In each
case the algorithm was considered safe right up until it was proven faulty, and the data
it had protected was exposed as a consequence.

To put this in perspective, there are two main problems in communication
security. The first is that computational security is always provisional: it
lasts only until someone finds a better attack or builds a faster machine. The
second is that a large enough quantum computer would not chip away at today's
key exchange but break it completely, solving in reasonable time the very
problems it is built on. Even though such a quantum computer does not exist yet,
an adversary can store encrypted traffic now and decrypt it once the capability
exists, so data that must stay secret for decades is already at risk. This is
what motivates the search for a guarantee that does not rest on any assumption
about the attacker's resources, security that holds not because an attack is too
expensive, but because it is impossible. Such a guarantee is called
information-theoretic.

== Alternative approaches and related work

There are two broad ways to defend communication against the quantum threat,
and they differ at the root. The first keeps the architecture we already have
and only replaces the broken pieces: the vulnerable key exchange is swapped for
one built on mathematical problems that no known quantum algorithm can solve.
This approach is called post-quantum cryptography, treated in detail in the
post-quantum cryptography section later in this chapter. It runs on ordinary
hardware and fits inside existing protocols, which makes it the path the wider
Internet is taking. Its security, however, is still computational and it rests on
an assumption about how hard a problem is, a stronger assumption than before but
an assumption all the same, and one that a future attack could in principle
overturn just as earlier ones did.

The second way changes what the guarantee rests on and it uses the laws of physics, which an adversary cannot
outcompute no matter how much power it has. Quantum key distribution takes this
route: two parties derive a shared key whose secrecy follows from the behaviour
of quantum measurement rather than from any unproven hardness, as the quantum
foundations and BB84 sections develop. The cost is that it needs dedicated
quantum hardware and a physical channel between the parties, where post-quantum
cryptography needs only software. This thesis follows the second route, using a
QKD-derived key to drive an information-theoretically secure channel.

Integrating quantum-distributed keys into a standard secure-channel protocol
has been attempted before. Rubio Garcia et al. #cite(<rubiogarcia2024qrtls>)
build quantum-resistant TLS by feeding a QKD-delivered key into the handshake,
combining it with the negotiated secret so that the session survives even if
the classical exchange is broken. Notably, they discuss using the QKD key as a
one-time pad but set that option aside as too costly, and protect the data with
a conventional cipher such as AES-GCM instead. The transport therefore stays
computationally secure: the QKD key improves how the secret is established, but
the data is still guarded by a computational primitive. This thesis implements
what the other attempt declined and makes it so that the QKD key is not handed to a block cipher but consumed
directly by a one-time pad and a Wegman-Carter authenticator, so the
confidentiality and integrity of the data are themselves information-theoretic,
and the cost of doing so is exactly what this work sets out to measure.

A related and now widely deployed line of work hardens the classical handshake
without QKD and using Hybrid key exchange, as specified for TLS 1.3 by Stebila et
al. #cite(<stebila2025hybrid>), runs a post-quantum KEM such as ML-KEM
alongside the ordinary elliptic-curve exchange and derives the session secret
from both, so the connection holds as long as either component resists attack.
This is the migration path the Internet is taking, and it is pragmatic because
it needs no new hardware and degrades gracefully. Its guarantee, however, is
still computational on the data path, resting on the conjectured hardness of
the lattice problem behind ML-KEM, detailed in the post-quantum cryptography
section.

== Goal and contributions

The question this thesis sets out to answer is whether a standard secure
channel can be made #emph[information-theoretically secure] end to end, using a
key produced by quantum key distribution, and at what cost. Concretely: can the
key-exchange and data-protection primitives of TLS 1.3 be replaced by ones
whose security rests on physics and on Shannon's bounds rather than on
computational hardness, while keeping the surrounding protocol structure
intact, and what price in throughput, latency, and key consumption does that
replacement carry?

In answering it, this thesis makes the following contributions.

A working end-to-end implementation of QTLS-over-QKD, in which the TLS 1.3
architecture is preserved but its cryptographic core is replaced: the ECDHE key
exchange by a QKD key fetched over the ETSI GS QKD 014 interface, the AES-GCM
record protection by a one-time pad, and the HMAC authentication by a
Wegman-Carter code over GF($2^128$). The stack keeps the TLS data path
information-theoretic rather than re-keying a classical cipher, the option that
existing QKD-in-TLS work set aside as too costly.

A self-contained QKD layer: a BB84 simulation followed by full Cascade
information reconciliation and privacy amplification, producing identical,
secret keys at the two endpoints and feeding them into a single-pair ETSI 014
Key Management Entity.

An empirical evaluation of what unconditional security costs on the data path,
measuring handshake latency, bulk throughput, and per-record key consumption
against a classical TLS 1.3 baseline, and comparing the key-establishment step
against both X25519 and ML-KEM-768.

An account of the boundary of the guarantee: a threat model that states
plainly which parts are information-theoretic and which rest on assumptions
(the authentication bootstrap and the trusted-node nature of the KMEs), so the
claim is neither overstated nor hidden.

== TLS 1.3 handshake

TLS 1.3 is the transport-layer protocol that secures the vast majority of
encrypted traffic on the Internet today #cite(<rfc8446>). A TLS connection
begins with a handshake whose purpose is to (i) agree on a shared secret
between client and server, (ii) authenticate at least the server, and (iii)
derive the symmetric keys that protect every subsequent application record.
All later guarantees of the connection rest on this handshake.

The handshake is carried by a small fixed sequence of messages. The client
opens with a #emph[ClientHello] that mentions its supported cipher suites
and, in its #emph[key_share] extension, sends one or more ephemeral
Diffie-Hellman public keys. The server replies with a #emph[ServerHello]
containing its own #emph[key_share]; at this point both peers can compute
the shared secret and derive the keys that protect the rest of the
handshake. Everything the server sends after #emph[ServerHello] is already
encrypted: #emph[EncryptedExtensions], optionally a #emph[Certificate] and
#emph[CertificateVerify] (the server's signature over the transcript), and
a #emph[Finished] message that authenticates the handshake so far. The
client answers with its own #emph[Finished], after which both sides switch
to the application traffic keys.

#figure(
  chronos.diagram({
    import chronos: *
    _par("C", display-name: "Client")
    _par("S", display-name: "Server")
    _seq("C", "S", comment: "ClientHello, key_share")
    _seq("S", "C", comment: "ServerHello, key_share")
    _seq("S", "C", comment: "{EncryptedExtensions}")
    _seq("S", "C", comment: "{Certificate, CertificateVerify}")
    _seq("S", "C", comment: "{Finished}")
    _seq("C", "S", comment: "{Finished}")
    _seq("C", "S", comment: "[Application Data]")
    _seq("S", "C", comment: "[Application Data]")
  }),
  caption: [TLS 1.3 full handshake. Messages in braces #emph[{...}] are
  encrypted under the handshake traffic keys; messages in brackets
  #emph[\[...\]] under the application traffic keys.],
)

The keys themselves are produced by a key schedule based on the
HMAC-based key derivation function (HKDF) #cite(<rfc5869>). The shared secret from the key exchange is mixed through
a sequence of #emph[Extract] and #emph[Expand] operations that create,
successively, the handshake traffic secrets (protecting the rest of the
handshake, the {...} messages) and the application traffic secrets
(protecting the data phase, the [...] messages).
The same schedule also produces the message authentication code (MAC) key
used inside the #emph[Finished] messages, which bind both peers to the full
sequence of handshake messages they have exchanged and thereby detect any
tampering by a man in the middle.

Two properties of this handshake matter for the rest of the chapter.
First, the entire confidentiality of the connection depends on the secrecy
of the value produced by the key exchange in the #emph[key_share]
extension: an adversary who can recover it can derive every traffic key
that follows. Second, TLS 1.3 specifies the message flow and the key
schedule, but the actual mechanism that produces the shared secret can be implemented in different variants. The next section makes precise what kind of security guarantee
this primitive is expected to provide.

== Security models and information-theoretic primitives

Cryptographic guarantees come in two strengths: a scheme is
#emph[computationally secure] if breaking it is possible in principle but
requires an amount of computation that no realistic adversary can afford,
its security rests on the assumed hardness of some problem, such as
factoring or computing discrete logarithms. A scheme is
#emph[information-theoretically secure] (ITS) if it cannot be broken
regardless of the adversary's computational power, because the ciphertext
simply does not contain enough information to recover the plaintext. The
distinction is vital for this thesis: a computational guarantee can be invalidated by
a faster algorithm or a faster machine, whereas an information-theoretic one
cannot.

Shannon formalised the notion of perfect secrecy
#cite(<shannon1949communication>). A cipher achieves perfect secrecy if the
probability of observing a given ciphertext $c$ is the same whatever the
underlying message $m$ is:

$ Pr[C = c mid(|) M = m] = Pr[C = c] quad "for all" m, c. $ <eq:perfect-secrecy>

This is Shannon's necessary-and-sufficient condition: the ciphertext
distribution is independent of the message, so observing $c$ tells the
adversary nothing it did not already know. Equivalently, in
information-theoretic terms, the mutual information between message and
ciphertext is zero,

$ I(M; C) = 0, $ <eq:mutual-info>

which is why the guarantee is called information-theoretic. Shannon also
proved a price for it: perfect secrecy requires the key to be at least as
long as the message and to be used only once.

The #emph[one-time pad] (OTP) is the textbook cipher that attains this
bound #cite(<shannon1949communication>). Given a message $m$ and a uniformly random
key $k$ of the same length, used a single time, encryption and decryption
are bitwise exclusive-or:

$ c = m xor k, quad m = c xor k. $ <eq:otp>

Because $k$ is uniform and independent of $m$, every plaintext is equally
consistent with a given $c$, so $I(M; C) = 0$. The OTP shows that perfect
secrecy is achievable, but only at the cost Shannon identified: a fresh,
truly random key as long as the data, never reused because it will show
the message due to the nature of the xor operation.

An adversary who cannot read an
OTP ciphertext can still flip chosen bits of the plaintext by flipping the
corresponding bits of $c$. This means a communication can be confidential but it does not guarantee integrity. Protecting integrity with an
information-theoretic guarantee requires a separate primitive: a
#emph[message authentication code] built from a family of hash functions,
following Wegman and Carter
#cite(<wegman1981new>). The idea is that the
sender does not use a single, fixed hash function, but picks one at random
from a whole family $cal(H)$, and the secret key is exactly the choice of
which function is used. Since the attacker does not know the key, it does
not know which function was picked. The family is built so that any two
different messages $m$ and $m'$ are mapped to the same tag by only a small
fraction of its functions. Formally, a function $h$ chosen at random from
$cal(H)$ produces a collision with probability at most $epsilon$:

$ Pr_(h in cal(H)) [h(m) = h(m')] <= epsilon. $ <eq:almost-universal>

The tag itself is not just $h(m)$: the hash value is hidden by adding a
fresh one-time random string (mask), so that the transmitted tag
is $h(m) xor "mask"$. The mask stops the attacker from learning anything
about which function was chosen from the tags it observes, just as the
one-time pad hides the message.

To forge, an attacker who has seen one valid message and its tag would have
to produce the correct tag for a different message. Because it does not know
which function was used and collisions are rare, the best it can do is
guess, succeeding with probability at most $epsilon$, regardless of how much
computation it performs, making it information-theoretic #cite(<stinson1991universal>). The cost, exactly as with the one-time pad,
is that fresh, single-use key material (both the random choice of function
and the mask) is needed for every message.

Together, the one-time pad and a Wegman-Carter authenticator provide
information-theoretic confidentiality and integrity, but both demand a
continuous supply of uniformly random secret key shared by the two
parties. Classical key exchange, the subject of the next section, does not
provide such a supply unconditionally and it fails to provide more than computationally secure keys.

== Classical key exchange in TLS

The shared secret of the TLS handshake is produced by an authenticated
Diffie-Hellman key exchange. In TLS 1.3 the only key-exchange family
retained is #emph[ephemeral elliptic-curve Diffie-Hellman] (ECDHE)
#cite(<rfc8446>). Each peer sends a public value derived from a fresh secret
in its #emph[key_share], and from its own secret and the other peer's public
value both sides arrive at the same point on an elliptic curve, which is
then hashed into the shared secret fed to the key schedule. The curves used
are standardised, most commonly P-256 #cite(<nist2023sp800186>) or
Curve25519. Because the secrets are #emph[ephemeral] 
(the secrets are used once then discarded), the exchange gains a property called forward secrecy, meaning that, recovering one session's key does
not compromise any other.

The security of this exchange is #emph[computational]. An eavesdropper sees
both public values but, to recover the shared secret, would have to solve
the #emph[elliptic-curve discrete logarithm problem] (ECDLP): given a base
point $G$ and a public multiple $Q = k G$ of it, find the scalar multiplier
$k$ #cite(<koblitz1987elliptic>),

$ "given " G "and" Q = k G, quad "find " k. $ <eq:ecdlp>

No efficient classical algorithm is known for ECDLP on well-chosen curves,
and the best known attacks take time exponential in the key size, which is
what makes ECDHE practical and secure against classical adversaries. This
security, however, rests on the absence of an efficient algorithm,
not on a proof that none can exist. Cryptography has a history
of schemes once believed secure that were later broken when a better attack
was found, and ECDLP is one of them: it is broken by Shor's algorithm on a
quantum computer.

== The quantum threat

In 1994 Shor discovered a quantum algorithm that solves both integer factorisation
and the discrete logarithm problem in polynomial time
#cite(<shor1994algorithms>). The same idea applies to
the elliptic-curve discrete logarithm of @eq:ecdlp, so a sufficiently large
quantum computer would recover the scalar $k$ 
efficiently, and with it the shared secret of an ECDHE handshake. This means that the two
hard problems underlying essentially all deployed public-key cryptography,
factoring for RSA and discrete logarithms for Diffie-Hellman and its
elliptic-curve variant, are broken by this algorithm.

The core of Shor's algorithm is #emph[order finding]: the hardness of these
problems can be reduced to finding the period of a function, and a quantum
computer finds that period efficiently using the #emph[quantum Fourier
transform]. This works because a quantum computer can use
superposition and interference to explore many states at once. What matters for this thesis is the consequence: this algorithm is what forces the need for information-theoretic primitives in the face of a future quantum adversary.

It needs to be taken note that the algorithm exists but the hardware does not yet: running Shor against the curve sizes
used in practice requires a fault-tolerant quantum computer with far more
stable qubits than any built so far. Moreover, not all cryptography is equally
affected. Grover's algorithm gives only a quadratic speed-up for brute-force
search #cite(<grover1996fast>), so primitives such as block
ciphers and hash functions are weakened but not broken, and doubling the key
length restores their security. The damage is concentrated on public-key
key exchange, exactly the component that establishes the shared secret in
TLS.

An adversary can record encrypted
traffic today and decrypt it once a capable quantum computer becomes
available, an attack known as #emph[harvest now, decrypt later]
#cite(<mosca2018cybersecurity>). Any data whose confidentiality must outlive
the arrival of quantum computers is therefore already at risk, even though
no such machine exists yet.

== Post-quantum cryptography

The first response to the quantum threat is to keep the classical
architecture but replace the broken primitives with new ones believed to
resist quantum attack. This is the goal of #emph[post-quantum cryptography]
(PQC): public-key algorithms that run on ordinary computers yet rely on
mathematical problems for which no efficient quantum algorithm is known
#cite(<bernstein2009postquantum>). The candidates are usually grouped by the
hard problem they build on: lattice-based schemes (short vectors in a
lattice), code-based schemes (decoding random linear codes), hash-based
schemes (the security of a hash function, used mainly for signatures), and
isogeny-based schemes (paths in graphs of elliptic curves). They differ
widely in key size, speed, and maturity, and not all resisted attack: the
isogeny key exchange SIKE was broken by a classical attack in 2022
#cite(<castryck2023efficient>), a proof that "post-quantum" means "no
known quantum attack", not "provably secure".

The scheme standardised for key establishment is #emph[ML-KEM]
#cite(<nist2024mlkem>), a lattice-based key-encapsulation mechanism derived
from CRYSTALS-Kyber. Its security rests on the #emph[learning with errors]
(LWE) problem. LWE asks one to recover a secret vector $s$ from many noisy
linear equations: one is given pairs $(a_i, b_i)$ with

$ b_i = chevron.l a_i, s chevron.r + e_i, $ <eq:lwe>

where the $a_i$ are random, $chevron.l dot, dot chevron.r$ is the inner product,
and each $e_i$ is a small random error. Without the errors this is ordinary
linear algebra and $s$ is trivially recovered, but the small noise terms $e_i$
are what make the problem hard, and no efficient algorithm, classical or
quantum, is known to solve it for suitable parameters. 

In practice PQC is not deployed alone but in a #emph[hybrid] key exchange:
the TLS handshake runs both a classical primitive (ECDHE) and a
post-quantum one (ML-KEM) in parallel, and the shared secret is derived from both. This is the migration path currently being adopted on the Web.

ML-KEM is secure because no
efficient algorithm for MLWE is known, exactly the kind of guarantee that
Shor's algorithm overturned for ECDLP.

== Quantum foundations

The security of the key exchange in the next section rests on two physical
facts about quantum measurement. This section establishes both. The physical
carrier of quantum key distribution is the #emph[qubit], a
two-level quantum system whose state is a superposition of two basis states
#cite(<nielsen2010quantum>).

The
#emph[computational] (or Z) basis is $ket(0)$ and $ket(1)$; the
#emph[diagonal] (or X) basis is

$ ket(+) = 1/sqrt(2) (ket(0) + ket(1)), quad
  ket(-) = 1/sqrt(2) (ket(0) - ket(1)). $ <eq:diagonal-basis>

The two bases are #emph[conjugate]: a state that is definite in one basis is
uncertain in the other. Take $ket(+)$. It is perfectly defined in the X
basis, yet in the Z basis it is an equal superposition of $ket(0)$ and
$ket(1)$.

In order to read a qubit we need to measure it, and measuring destroys the
state. A measurement in a given basis projects the qubit onto one of that
basis's two outcomes and returns the matching bit. If the qubit was prepared
in the same basis, the result is deterministic and the state survives:
measuring $ket(0)$ in the Z basis gives $0$ with certainty. If it was prepared
in the #emph[conjugate] basis, the outcome is uniformly random and the
original state is gone: measuring $ket(+)$ in the Z basis gives $0$ or $1$
with equal probability, and the qubit is left in $ket(0)$ or $ket(1)$
accordingly. An observer who does not know the preparation basis cannot read
the bit without risking both an error and a disturbance to the state.

The second physical fact is the #emph[no-cloning theorem], which makes the
same point another way: no quantum
operation copies an arbitrary unknown state #cite(<nielsen2010quantum>).
The argument is a proof by contradiction. Suppose such an operation
$U$ existed, satisfying $U(ket(psi) ket(0)) = ket(psi) ket(psi)$ for every
state $ket(psi)$. Apply it to two different states $ket(psi)$ and $ket(phi)$.
Quantum operations preserve inner products, so equating the inner product
before and after gives $braket(psi, phi) = braket(psi, phi)^2$. This holds
only when $braket(psi, phi)$ is $0$ or $1$, that is, only when the two states
are orthogonal or identical. A $U$ that clones arbitrary states would have to
satisfy it for every pair, which is a contradiction, so no such operation exists. An
eavesdropper therefore cannot duplicate a qubit in flight, measure one copy,
and forward the other untouched. 

Both facts rest on physics rather than on the hardness of a computation, so the protection they give against eavesdropping holds regardless of the adversary's computing power.

== The BB84 protocol

BB84, due to Bennett and Brassard #cite(<bennett1984quantum>)#cite(<nielsen2010quantum>), turns the
facts of the previous section into a way for two parties,
Alice and Bob, to agree on a shared random string that an eavesdropper
cannot learn without being detected. For each bit, Alice picks a random bit
value and a random basis, Z or X, encodes the bit in that basis (a $0$ as
$ket(0)$ or $ket(+)$, a $1$ as $ket(1)$ or $ket(-)$) and sends the qubit to
Bob. Bob, not knowing Alice's basis, measures each qubit in a basis he also
chooses at random. If their bases coincide, his result equals Alice's bit;
if they differ, his result is random and carries no information.

After transmission the two perform #emph[sifting] over an authenticated
public channel: they announce the basis used for each qubit, without
revealing the bit values, and discard every position where their bases
differed. On the remaining positions, where the bases matched, their bits
agree in the absence of noise and eavesdropping, and these form the
#emph[sifted key]. Since the bases are independent and uniform, on average
half the qubits survive sifting. @tab:bb84 illustrates one round.

#figure(
  table(
    columns: 7,
    align: center,
    table.header([Alice bit], [1], [0], [1], [1], [0], [0]),
    [Alice basis], [Z], [X], [Z], [X], [Z], [X],
    [Bob basis],   [Z], [Z], [Z], [X], [X], [X],
    [Bases match], [yes], [no], [yes], [yes], [no], [yes],
    [Sifted key],  [1], [], [1], [1], [], [0],
  ),
  caption: [One round of BB84. Positions where the bases differ are discarded;
  the matching positions form the sifted key.],
) <tab:bb84>

#figure(
  align(left)[#text(size: 9pt)[```python
function bb84_round(n):
    // sifted holds the positions where both sides chose the same basis
    sifted <- empty list
    for i = 1 .. n:
        alice_bit   <- random bit
        alice_basis <- random basis (Z or X)
        bob_basis   <- random basis (Z or X)
        qubit       <- encode(alice_bit, alice_basis)   // quantum channel
        bob_bit     <- measure(qubit, bob_basis)
        // sifting, over the authenticated public channel:
        if alice_basis = bob_basis:        // bases announced, not bit values
            append (alice_bit, bob_bit) to sifted
    return sifted
```]],
  caption: [One round of BB84: per-qubit preparation and measurement, followed
    by sifting on the positions where the two bases agree.],
) <fig:bb84-pseudo>

But realistically, the sifted key is not yet usable. Channel noise and any eavesdropping
introduce disagreements between Alice's and Bob's versions, measured by the
#emph[quantum bit error rate] (QBER), the fraction of sifted positions where
their bits differ. Alice and Bob estimate it by publicly comparing the bits
on a random sample of the sifted key and then discarding that sample. By the
disturbance property, an eavesdropper who measures
qubits in a basis she has guessed wrong corrupts them and so raises the
QBER. An observed error rate above a threshold, derived from the Shor-Preskill
security proof of BB84 #cite(<shor2000simple>), signals interception and the
key is aborted. A low QBER bounds how much information an eavesdropper can have
obtained.

In the case the QBER is below that threshold, the remaining errors are removed by #emph[information
reconciliation], a public-discussion procedure that lets Alice and Bob
correct the differing bits and reach an identical string. The implementation chosen for this work uses Cascade #cite(<brassard1994secret>), which proceeds in passes: the key is split
into blocks, parities of the blocks are compared, and a binary search inside
any block with mismatched parity locates and flips the problem bit, with
later passes catching errors the earlier ones missed. Reconciliation leaks
some information to the eavesdropper, because the exchanged parities are
public.

Two adjustments then turn the reconciled string into a secure key. First, the
information leaked during reconciliation, together with whatever the
eavesdropper may have gathered from the channel within the QBER bound, is
removed by #emph[privacy amplification] #cite(<bennett1995generalized>):
Alice and Bob apply a randomly chosen function from a universal family
(the universal families of the security-models section) to compress their shared string into a shorter one about which
the eavesdropper's information is negligible. How much the string must be
shortened depends on how much the eavesdropper is estimated to know. The result is a shared key whose secrecy rests on the
laws of physics rather than on any computational assumption.

== The ETSI QKD 014 key delivery standard

ETSI GS QKD 014 standardises the interface through which an application
requests keys from QKD hardware #cite(<etsi2019qkd014>). It separates the
system into two roles: the #emph[Key Management Entity] (KME), attached to a
QKD device and storing the keys it produces, and the #emph[Secure Application
Entity] (SAE), the application that consumes them. This way, the TLS stack is an SAE and never speaks to the quantum hardware directly, but asks its local KME for keys over a defined API. Each KME serves the SAEs at its own site over a local, secured channel.

A pair of SAEs obtains a shared key as follows. The master SAE asks its local
KME for key material; the KME returns one or more keys, each paired with a
#emph[key_ID]. The master SAE passes the key_ID to the slave SAE over its own
application channel, and the slave SAE presents that key_ID to its own KME,
which returns the identical key. The two SAEs then hold the same secret
without ever exchanging it directly. The standard defines this through a
small REST API with three endpoints: `/status`, which reports the key
material a KME has available for a given peer; `/enc_keys`, by which the
master SAE requests new keys and receives them with their key_IDs; and
`/dec_keys`, by which the slave SAE retrieves a key by its key_ID.

This model carries a strong assumption: the two KMEs hold the keys in the
clear and exchange them between sites, meaning the security of the delivered key
depends on each KME being uncompromised (in QKD terminology each KME is a
#emph[trusted node]). The quantum guarantee covers the link between the QKD network, but the KMEs that store and forward the keys are trusted by
assumption, not protected by physics.

== Threat model

The foundations above can now be combined into the adversary against which
the rest of the thesis reasons. The adversary is assumed to be
computationally unbounded in the quantum sense: it has access to a
large-scale quantum computer and can run Shor's algorithm. It can read, store, and tamper with all classical
traffic, and in particular it can mount the harvest-now-decrypt-later attack,
recording today's traffic to break it later. On the quantum channel it can intercept and tamper with qubits in transit, but it cannot clone an unknown state or read a qubit without disturbing it, by the facts of the quantum foundations section.

Against this adversary the stack splits cleanly into two layers. The key
itself is #emph[information-theoretically secure]: it is produced by BB84,
whose secrecy follows from physics and whose residual leakage is removed by
privacy amplification, and once installed it protects data through a one-time
pad and a Wegman-Carter authenticator, both unconditionally secure. The classical key exchange of TLS, by contrast, would be broken by
such an adversary, which is precisely why it is replaced.

Two assumptions remain outside the information-theoretic guarantee. First, authentication of the public channels, both the
sifting and reconciliation discussion and the SAE-to-SAE exchange, relies on
the parties already sharing a short secret to key the Wegman-Carter
authenticator. Second, the trusted-node assumption of the previous section: the
KMEs hold key material in the clear, so an adversary who compromises a KME
obtains the keys directly. The
information-theoretic claim of this work therefore applies to the key
agreement and the data path given uncompromised.
