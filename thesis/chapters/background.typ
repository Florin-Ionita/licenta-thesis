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
computation it performs #cite(<stinson1991universal>). This is what makes
the guarantee information-theoretic: it holds against any attacker, not just
a computationally limited one. The cost, exactly as with the one-time pad,
is that fresh, single-use key material (both the random choice of function
and the mask) is needed for every message; reusing it breaks the guarantee.

Together, the one-time pad and a Wegman-Carter authenticator provide
information-theoretic confidentiality and integrity, but both demand a
continuous supply of fresh, uniformly random, secret key shared by the two
parties. Classical key exchange, the subject of the next section, does not
provide such a supply unconditionally; it provides keys whose secrecy is
only computational.
