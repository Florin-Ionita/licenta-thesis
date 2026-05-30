#import "../prelude.typ": *

   BACKGROUND / THEORETICAL FOUNDATION – WRITING GUIDE (paragraph by paragraph)

   P1. Domain
        - Describe the broad field of the thesis, why it matters,
          and which aspects are important.
        - Example (hardware): "Computer architecture is the foundation of all computing systems; advances in arithmetic units directly affect the performance, energy efficiency, and applicability of modern accelerators."
        - Example (software): "Scientific computing underpins discoveries in physics, chemistry, climate modelling, and engineering; the fidelity and cost of numerical simulations determine how quickly science can progress."

   P2. Context
        - Zoom in on the specific setting where the problem appears and explain its relevance to the broader domain.
        - Example (hardware): "Within computer architecture, the choice of number representation (fixed-point, floating-point, posit, etc.) determines the trade-off between accuracy, silicon area, and power consumption in hardware accelerators."
        - Example (software): "In scientific-computing workflows, number-representation libraries are called repeatedly inside kernels; their precision and runtime influence the overall reliability and turnaround time of large simulations."

   P3. Problem and Motivation
        - State clearly the gap or deficiency that motivates your work and why solving it is important.
        - Example (hardware):
              "There is currently no unified hardware library that offers multiple number representations together with a common benchmark suite, making fair comparison and reuse across projects difficult."
              "This gap forces designers to re-implement basic operators for each format, increasing development time and hindering reproducible evaluation."
        - Example (software):
              "Existing software libraries provide many number formats but lack integrated automated testing and continuous-integration support, which hinders reproducible evaluation in large scientific-computing projects."
              "Consequently, developers must manually run correctness and benchmark tests, slowing down experimentation and increasing the risk of inconsistent results."

   P4. Related Work
        - Discuss existing solutions (libraries, tools, architectures) and point out their limitations with respect to your goal.
        - Example hardware paragraph 1:
              "FloPoCo provides a rich set of floating-point cores but focuses mainly on IEEE-754 and related formats, offering limited support for posit or unum."
        - Example hardware paragraph 2:
              "Several open-source Chisel libraries implement individual formats (e.g., a fixed-point package) but they do not share a common test harness, making cross-format benchmarking ad-hoc."
        - Example hardware paragraph 3:
              "Recent proposals for programmable arithmetic units (e.g., POSH) demonstrate flexibility but lack a standardized evaluation framework."
        - Example software paragraph 1:
              "General-purpose libraries such as NumPy (Python) and the Julia standard library supply many number formats, yet they are not coupled to automated CI pipelines, so developers must run correctness and benchmark tests manually."
        - Example software paragraph 2:
              "Some research prototypes (e.g., a posit package for Julia) provide the arithmetic but lack integration with build systems like Jenkins, which limits their usability in large, collaborative scientific-computing projects."
        - Example software paragraph 3:
              "Workflow tools like GitHub Actions or GitLab CI can run tests, but they do not provide a ready-made library of number representations for direct reuse."

   P5. Research Question / Goal
        - State the main question or engineering goal that your thesis will answer.
        - Example (hardware):
              "Which number-representation format(s) give the best trade-off between accuracy, area, and power for a given class of accelerator kernels?"
        - Example (software):
              "How can we provide a reusable, CI-integrated software library that lets scientific-computing teams evaluate and compare diverse number representations with minimal manual effort?"

   P6. Thesis Contributions
        - Summarize the main contributions of the thesis in prose (2-4 items).
        - Example (hardware):
              "The thesis contributes: (i) a reusable Chisel number-representation library; (ii) a common benchmark framework for fair cross-format comparison; (iii) quantitative evaluation of format trade-offs on FPGA targets; and (iv) guidance for hardware designers on selecting formats for accelerator design."
        - Example (software):
              "The thesis contributes: (i) a Scala software library with multiple number representations; (ii) a Jenkins-based CI workflow that automates testing and benchmarking; (iii) empirical results showing accuracy-runtime-energy trade-offs for scientific kernels; and (iv) a reusable template for integrating numerical experiments into CI pipelines."

   Replace each block below (the text between _[ and ]_) with your own paragraph(s) following the order above.

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

Cryptographic guarantees come in two strengths. A scheme is
#emph[computationally secure] if breaking it is possible in principle but
requires an amount of computation that no realistic adversary can afford;
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
bound #cite(<vernam1926cipher>). Given a message $m$ and a uniformly random
key $k$ of the same length, used a single time, encryption and decryption
are bitwise exclusive-or:

$ c = m xor k, quad m = c xor k. $ <eq:otp>

Because $k$ is uniform and independent of $m$, every plaintext is equally
consistent with a given $c$, so $I(M; C) = 0$. The OTP shows that perfect
secrecy is achievable, but only at the cost Shannon identified: a fresh,
truly random key as long as the data, never reused. Reusing any portion of
the key is fatal for the secrecy.

Confidentiality is not integrity. An adversary who cannot read an
OTP ciphertext can still flip chosen bits of the plaintext by flipping the
corresponding bits of $c$. Protecting integrity with an
information-theoretic guarantee requires a separate primitive: a
#emph[message authentication code] built from a family of hash functions,
following Wegman and Carter
#cite(<wegman1981new>)#cite(<carter1979universal>). The idea is that the
sender does not use a single, fixed hash function, but picks one at random
from a whole family $cal(H)$, and the secret key is exactly the choice of
which function is used. Since the attacker does not know the key, it does
not know which function was picked. The family is built so that any two
different messages $m$ and $m'$ are mapped to the same tag by only a small
fraction of its functions. Formally, a function $h$ chosen at random from
$cal(H)$ produces a collision with probability at most $epsilon$:

$ Pr_(h in cal(H)) [h(m) = h(m')] <= epsilon. $ <eq:almost-universal>

The tag itself is not just $h(m)$: the hash value is hidden by adding a
fresh one-time random string, the #emph[mask], so that the transmitted tag
is $h(m) xor "mask"$. The mask stops the attacker from learning anything
about which function was chosen from the tags it observes, just as the
one-time pad hides the message.

To forge, an attacker who has seen one valid message and its tag would have
to produce the correct tag for a different message. Because it does not know
which function was used and collisions are rare, the best it can do is
guess, succeeding with probability at most $epsilon$, regardless of how much
computation it performs, making it information-theoretic #cite(<stinson1991universal>). The cost, exactly as with the one-time pad,
is that fresh, single-use key material (both the random choice of function
and the mask) is needed for every message; reusing it breaks the guarantee.

Together, the one-time pad and a Wegman-Carter authenticator provide
information-theoretic confidentiality and integrity, but both demand a
continuous supply of, uniformly random, secret key shared by the two
parties. Classical key exchange, the subject of the next section, does not
provide such a supply unconditionally, it fails to provide more than computational secure keys.

== Classical key exchange in TLS

The shared secret of Section 2.1 is produced by an authenticated
Diffie-Hellman key exchange. In TLS 1.3 the only key-exchange family
retained is #emph[ephemeral elliptic-curve Diffie-Hellman] (ECDHE)
#cite(<rfc8446>). Each peer sends a public value derived from a fresh secret
in its #emph[key_share], and from its own secret and the other peer's public
value both sides arrive at the same point on an elliptic curve, which is
then hashed into the shared secret fed to the key schedule. The curves used
are standardised, most commonly P-256 #cite(<nist2023sp800186>) or
Curve25519. Because the secrets are #emph[ephemeral] 
(the secrets are used omce then discarded), the exchange gains a property called forward secrecy, meaning that, recovering one session's key does
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

In 1994 Shor gave a quantum algorithm that solves both integer factorisation
and the discrete logarithm problem in polynomial time
#cite(<shor1994algorithms>)#cite(<shor2000simple>). The same idea applies to
the elliptic-curve discrete logarithm of @eq:ecdlp, so a sufficiently large
quantum computer would recover the scalar $k$
efficiently, and with it the shared secret of an ECDHE handshake. The two
hard problems underlying essentially all deployed public-key cryptography,
factoring for RSA and discrete logarithms for Diffie-Hellman and its
elliptic-curve variant, are broken by this algorithm.

The core of Shor's algorithm is #emph[order finding]: the hardness of these
problems can be reduced to finding the period of a function, and a quantum
computer finds that period efficiently using the #emph[quantum Fourier
transform]. This is done because of the the
superposition and interference available to a quantum computer to explore more states. What matters for this thesis is the impact of this algorithm explaining the need for information-theoretic primitives in the face of a future quantum adversary.

Two qualifications keep this threat in perspective. First, the algorithm
exists but the hardware does not yet: running Shor against the curve sizes
used in practice requires a fault-tolerant quantum computer with far more
stable qubits than any built so far. Second, not all cryptography is equally
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
#cite(<castryck2023efficient>), a reminder that "post-quantum" means "no
known quantum attack", not "provably secure".

The scheme standardised for key establishment is #emph[ML-KEM]
#cite(<nist2024mlkem>), a lattice-based key-encapsulation mechanism derived
from CRYSTALS-Kyber. Its security rests on the #emph[learning with errors]
(LWE) problem. LWE asks one to recover a secret vector $s$ from many noisy
linear equations: one is given pairs $(a_i, b_i)$ with

$ b_i = chevron.l a_i, s chevron.r + e_i, $ <eq:lwe>

where the $a_i$ are random, $chevron.l dot, dot chevron.r$ is the inner product,
and each $e_i$ is a small random error. Without the errors this is ordinary
linear algebra and $s$ is trivially recovered; the small noise terms $e_i$
are what make the problem hard, and no efficient algorithm, classical or
quantum, is known to solve it for suitable parameters. 

In practice PQC is not deployed alone but in a #emph[hybrid] key exchange:
the TLS handshake runs both a classical primitive (ECDHE) and a
post-quantum one (ML-KEM) in parallel, and the shared secret is derived from both. This is the migration path currently being adopted on the Web.

PQC changes the assumption but not its nature. ML-KEM is secure because no
efficient algorithm for MLWE is known, exactly the kind of guarantee that
Shor's algorithm overturned for ECDLP.

== Quantum foundations

The security of the key exchange in the next section rests on two physical
facts about quantum measurement. The physical
carrier of quantum key distribution is the #emph[qubit], a
two-level quantum system whose state is a superposition of two basis states
#cite(<nielsen2010quantum>). Two bases matter here. The
#emph[computational] (or Z) basis is $ket(0)$ and $ket(1)$; the
#emph[diagonal] (or X) basis is

$ ket(+) = 1/sqrt(2) (ket(0) + ket(1)), quad
  ket(-) = 1/sqrt(2) (ket(0) - ket(1)). $ <eq:diagonal-basis>

The two bases are #emph[conjugate]: a state that is definite in one basis is
uncertain in the other. Take $ket(+)$. It is perfectly defined in the X
basis, yet in the Z basis it is an equal superposition of $ket(0)$ and
$ket(1)$.

The only way to read a qubit is to measure it, and measuring destroys the
state. A measurement in a given basis projects the qubit onto one of that
basis's two outcomes and returns the matching bit. If the qubit was prepared
in the same basis, the result is deterministic and the state survives:
measuring $ket(0)$ in the Z basis gives $0$ with certainty. If it was prepared
in the #emph[conjugate] basis, the outcome is uniformly random and the
original state is gone: measuring $ket(+)$ in the Z basis gives $0$ or $1$
with equal probability, and the qubit is left in $ket(0)$ or $ket(1)$
accordingly. An observer who does not know the preparation basis cannot read
the bit without risking both an error and a disturbance to the state.

The #emph[no-cloning theorem] makes the same point another way: no quantum
operation copies an arbitrary unknown state #cite(<nielsen2010quantum>).
The argument is a short proof by contradiction. Suppose such an operation
$U$ existed, satisfying $U(ket(psi) ket(0)) = ket(psi) ket(psi)$ for every
state $ket(psi)$. Apply it to two different states $ket(psi)$ and $ket(phi)$.
Quantum operations preserve inner products, so equating the inner product
before and after gives $braket(psi, phi) = braket(psi, phi)^2$. This holds
only when $braket(psi, phi)$ is $0$ or $1$, that is, only when the two states
are orthogonal or identical. A $U$ that clones arbitrary states would have to
satisfy it for every pair, which is a contradiction, so no such operation exists. An
eavesdropper therefore cannot duplicate a qubit in flight, measure one copy,
and forward the other untouched. The disturbance from measuring in the wrong basis and
the impossibility of cloning are the two facts that help make quantum key distribution secure against eavesdropping.

== The BB84 protocol

BB84, due to Bennett and Brassard #cite(<bennett1984quantum>)#cite(<nielsen2010quantum>), turns the
facts of the previous section into a way for two parties, conventionally
Alice and Bob, to agree on a shared random string that an eavesdropper
cannot learn without being detected. For each bit, Alice picks a random bit
value and a random basis, Z or X, encodes the bit in that basis (a $0$ as
$ket(0)$ or $ket(+)$, a $1$ as $ket(1)$ or $ket(-)$) and sends the qubit to
Bob. Bob, not knowing Alice's basis, measures each qubit in a basis he also
chooses at random. When their bases coincide his result equals Alice's bit;
when they differ his result is random and carries no information.

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

But realistically, the sifted key is not yet usable. Channel noise and any eavesdropping
introduce disagreements between Alice's and Bob's versions, measured by the
#emph[quantum bit error rate] (QBER), the fraction of sifted positions where
their bits differ. Alice and Bob estimate it by publicly comparing the bits
on a random sample of the sifted key and then discarding that sample. By the
disturbance property of the previous section, an eavesdropper who measures
qubits in a basis she has guessed wrong corrupts them and so raises the
QBER; an observed error rate above a protocol-dependent threshold signals
interception and the key is aborted. A low QBER bounds how much information
an eavesdropper can have obtained.

Below that threshold the remaining errors are removed by #emph[information
reconciliation], a public-discussion procedure that lets Alice and Bob
correct the differing bits and reach an identical string. The implementation
in this work uses Cascade #cite(<brassard1994secret>)
#cite(<martinez2015demystifying>), which proceeds in passes: the key is split
into blocks, parities of the blocks are compared, and a binary search inside
any block with mismatched parity locates and flips the erroneous bit, with
later passes catching errors the earlier ones missed. Reconciliation leaks
some information to the eavesdropper, because the exchanged parities are
public.

Two adjustments then turn the reconciled string into a secure key. First, the
information leaked during reconciliation, together with whatever the
eavesdropper may have gathered from the channel within the QBER bound, is
removed by #emph[privacy amplification] #cite(<bennett1995generalized>):
Alice and Bob apply a randomly chosen function from a universal family
(Section 2.2) to compress their shared string into a shorter one about which
the eavesdropper's information is negligible. The leftover hash lemma
#cite(<renner2005security>) quantifies how much the string must be shortened
as a function of the eavesdropper's estimated knowledge, so that the output
is, up to a negligible deviation, uniform and independent of everything the
eavesdropper holds. The result is a shared key whose secrecy rests on the
laws of physics rather than on any computational assumption.

== The ETSI QKD 014 key delivery standard

BB84 produces a shared key between two physical QKD endpoints, but an
application such as a TLS stack cannot speak to the quantum hardware
directly; it needs a defined interface through which to request keys. ETSI
GS QKD 014 standardises that interface #cite(<etsi2019qkd014>). It separates
the system into two roles: the #emph[Key Management Entity] (KME), which is
attached to a QKD device and stores the keys it produces, and the
#emph[Secure Application Entity] (SAE), the application that consumes them.
Each KME serves the SAEs at its own site over a local, secured channel.

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

The model carries a strong assumption. The two KMEs hold the keys in the
clear and exchange them between sites, so the security of the delivered key
depends on each KME being uncompromised; in QKD terminology each KME is a
#emph[trusted node]. The quantum guarantee covers the link between the QKD
devices, but the KMEs that store and forward the keys are trusted by
assumption, not protected by physics. This boundary is revisited when the
threat model of the full system is stated.

== Threat model

The foundations above can now be combined into the adversary against which
the rest of the thesis reasons. The adversary is assumed to be
computationally unbounded in the quantum sense: it has access to a
large-scale quantum computer and can therefore run Shor's algorithm, so any
guarantee that reduces to the hardness of factoring or discrete logarithms
is considered broken. It can read, store, and tamper with all classical
traffic, and in particular it can mount the harvest-now-decrypt-later attack,
recording today's traffic to break it later. On the quantum channel it may do
anything the laws of physics permit, including intercepting and resending
qubits, but it cannot clone an unknown state or read a qubit without
disturbing it, by the facts of the quantum foundations section.

Against this adversary the stack splits cleanly into two layers. The key
itself is #emph[information-theoretically secure]: it is produced by BB84,
whose secrecy follows from physics and whose residual leakage is removed by
privacy amplification, and once installed it protects data through a one-time
pad and a Wegman-Carter authenticator, both unconditionally secure. None of
this rests on a computational assumption, so a quantum computer does not
weaken it. The classical key exchange of TLS, by contrast, would be broken by
such an adversary, which is precisely why it is replaced.

Two assumptions remain outside the information-theoretic guarantee and must
be stated plainly. First, authentication of the public channels, both the
sifting and reconciliation discussion and the SAE-to-SAE exchange, relies on
the parties already sharing a short secret to key the Wegman-Carter
authenticator; the unconditional security of the key is conditional on this
bootstrap. Second, the trusted-node assumption of the previous section: the
KMEs hold key material in the clear, so an adversary who compromises a KME
obtains the keys directly, bypassing the quantum guarantee entirely. The
information-theoretic claim of this work therefore applies to the key
agreement and the data path given uncompromised, authenticated endpoints, not
to the physical and administrative security of the nodes themselves.
