#import "../prelude.typ": *

// ============================================================
//  P1. Domain  (prose, draft 1)
// ============================================================

Modern society depends on digital communication for nearly every
critical activity, from banking and healthcare to government
services and personal correspondence containing private information. Securing this communication
became an important concern of computer science, and the
dominant protocol that addresses it is Transport Layer Security
(TLS), in its latest version 1.3 #cite(<rfc8446>). The adoption of
encrypted transport has become the norm: as of 2026, around
95% of the web traffic observed by major browsers is protected by
HTTPS, which has only grown in recent years
#cite(<google2026httpsreport>). The security guarantees that this
infrastructure provides (confidentiality, integrity, and
authentication) rely, however, on a specific class of mathematical
assumptions: that certain problems, such as factoring large
integers or computing discrete logarithms over elliptic curves,
are computationally infeasible for any realistic adversary
#cite(<bernstein2009postquantum>).

// ============================================================
//  P2. Context  (prose, draft 1)
// ============================================================

The most security critical step of a TLS 1.3 session is the
initial key exchange, since every subsequent record on the
connection is based on keys derived from it. TLS 1.3
performs this exchange with ephemeral Diffie-Hellman, in both its
finite-field and elliptic-curve variants, and modern implementations use the elliptic-curve form (ECDHE) over the
standardised curves X25519 and P-256 #cite(<rfc8446>)
#cite(<nist2023sp800186>). The security of ECDHE reduces to the
Elliptic-Curve Discrete Logarithm Problem (ECDLP), introduced by
Koblitz in the mid-1980s as the basis for elliptic-curve
cryptosystems #cite(<koblitz1987elliptic>). At the parameter sizes
recommended by NIST, no known classical algorithm solves ECDLP in
less than exponential time, which is why TLS 1.3 is considered
secure today. However this is a strong
assumption about the computational model available to the
attacker.

// ============================================================
//  P3. Problem  (prose, draft 1)
// ============================================================

That assumption breaks under quantum computation. Shor's algorithm
solves both integer factoring and the discrete logarithm problem,
including its elliptic-curve variant, in polynomial time on a
sufficiently large quantum computer #cite(<shor1994algorithms>).
Today it is not the case, but every public-key primitive
currently deployed in TLS 1.3 (RSA, finite-field DH, and ECDHE)
loses its key-exchange security when such computers become available. Furthermore, the threat is not purely
a future one. An attacker who records encrypted traffic today and
stores it can decrypt it later. This "harvest now, decrypt
later" model makes the quantum threat a problem of the present
for any data that must remain confidential for decades, such as
state secrets, medical records, and industrial intellectual
property.

// ============================================================
//  P4. Importance, part 1  (long-term confidentiality + Mosca)
// ============================================================

It is important to understand that the urgency of this threat is
not the same across applications. For short-lived data, such as a
one-off web session or a disappearing chat, a moderately delayed
quantum break would arrive long after the data has lost any value.
For data with a long secrecy horizon, any quantum computer that
arrives before the secrecy requirement expires compromises the
data. Mosca formalised this trade-off as a simple inequality: if
data must remain secret for X years, and deploying a cryptographic
stack for that data takes Y years, then a quantum computer
arriving in fewer than X + Y years is already a concern today
#cite(<mosca2018cybersecurity>). For documents whose required
secrecy lifetime is measured in decades, such as classified
government communications, health and legal records, or
industrial trade secrets, this inequality is plausibly already
violated.

// ============================================================
//  P5. Importance, part 2  (concrete data with long secrecy horizons)
// ============================================================

The categories of data for which Mosca's inequality is already
violated are not hypothetical. Electronic health records are
required by national legislation to remain confidential for the
lifetime of the patient and beyond, and the European Union's
General Data Protection Regulation imposes similar long-term
confidentiality obligations on any personal data that has been
collected. Classified government communications follow declassification
schedules measured in decades, with NATO COSMIC TOP SECRET and
equivalent national markings often requiring secrecy for fifty
years or more. Industrial trade secrets and pharmaceutical
research data lose commercial value only when patents expire,
which is typically twenty years after filing. For all of these
categories, an adversary who records ciphertext today and
decrypts it ten or twenty years from now would still cause harm.

// ============================================================
//  P7. Alternative solutions, part 1  (PQC-augmented TLS)
// ============================================================

The used solution to the quantum threat in TLS today is to
enforce the protocol with post-quantum cryptography (PQC), a
family of public-key primitives that replaces ECDLP with newer
mathematical problems such as structured lattices
#cite(<bernstein2009postquantum>). The approach is a hybrid key exchange: the client and server run ECDHE
over X25519 and ML-KEM-768 in parallel, and combine the two
shared secrets. This solution is used by Cloudflare
and Google. They have enabled X25519MLKEM768 by default on a
significant fraction of TLS 1.3 traffic since 2024. Two limitations
matter for this thesis. First, PQC remains a computational
construction: the lattice problems it relies on have been studied
for far less time than factoring or discrete logarithms, and a
future algorithmic advance, classical or quantum, could weaken
any of them, so for data with multi-decade secrecy horizons the
residual risk does not disappear. Second, only the key-exchange
step is touched: the record layer still encrypts data with
AES-GCM, so even with PQC key agreement the data path is not
information-theoretically secure.

// ============================================================
//  P8. Alternative solutions, part 2  (commercial QKD products)
// ============================================================

On the QKD side of the market, vendors such as ID Quantique,
Toshiba, and QuantumXchange ship QKD-VPN and QKD-Ethernet products
that use quantum-distributed keys to seed AES-256 for the data
path. This fixes the key-exchange step but leaves the bulk
encryption computational, so the stack is again not
information-theoretically secure end to end.

// ============================================================
//  P9. Solution  (QTLS as a simulated, end-to-end IT-secure stack)
// ============================================================

This thesis presents a QTLS software simulation, a TLS 1.3 shaped protocol whose data
path is information-theoretically secure end to end. The TLS 1.3 architecture is preserved (the
handshake, key schedule, record layer, and close), with replacements that close this gap: ECDHE becomes a Quantum Key
Distribution (QKD) key fetched by `key_ID` over the ETSI GS QKD 014 REST
API #cite(<etsi2019qkd014>), AES-GCM becomes a One-Time Pad #cite(<shannon1949communication>),
and HMAC becomes a Wegman-Carter MAC over GF(2^128)
#cite(<wegman1981new>). The QKD layer is a Qiskit-based BB84
simulation, followed by Cascade reconciliation with
back-propagation and privacy amplification
#cite(<nielsen2010quantum>); the quantum channel is modelled as an
abstract link with a configurable error rate, and the Key
Management Entity (KME) runs as a local service that exposes the
standard ETSI 014 HTTP API. The result is a reproducible reference 
in which every part of the implementation is information-theoretically secure.

// ============================================================
//  P10. Experiment overview  (correctness + empirical trade-offs)
// ============================================================

QTLS is evaluated along two axes. The first is correctness: a
deterministic test suite covering BB84 sifting, Cascade
convergence, the ETSI 014 KME contract, the OTP and Wegman-Carter
primitives, the full QTLS handshake, and the end-to-end demo. The
second is the cost. The baseline for cost is one of the other solutions, 
X25519MLKEM768 TLS 1.3, since it is the present adopted standard 
against quantum adversaries. The metrics are: Time To Last Byte (TTLB),
handshake latency, the per-record key-consumption rate,
the rate at which the KME pool drains under concurrent sessions,
and the Cascade information leak as a function of the channel
QBER. The goal is not to claim parity with the PQC baseline on
raw throughput, but to quantify the price of unconditional
security in a regime where it is the right price to pay.

// ============================================================
//  P11. Contributions
// ============================================================

The thesis makes three concrete contributions. (i) A reproducible
end-to-end stack in which every primitive on the data path is
information-theoretically secure, integrating a Qiskit-based BB84
simulation, a native Cascade reconciliation with back-propagation,
an ETSI GS QKD 014 Key Management Entity, and a TLS 1.3 shaped
protocol whose record layer uses One-Time Pad encryption and a
Wegman-Carter MAC. (ii) An open-source reference implementation
of the ETSI GS QKD 014 Key Management Entity (KME). It exposes
the standard REST endpoints used by applications to fetch QKD
keys, and includes a simulated link between the two KMEs at the
endpoints of a QKD connection. (iii) An evaluation of
the cost of unconditional security against the X25519MLKEM768
TLS 1.3 baseline, reporting Time To Last Byte and handshake
latency over representative payloads, together with
key-consumption and KME-pool-drain measurements that describe
the behavior of such an implementation. One limitation has to be
acknowledged up front: the privacy amplification step uses
SHAKE-128 as its extractor rather than a two-universal hash
family. The scope and impact of this caveat are discussed in the
discussion chapter.

   P1. Domain
        - Describe the broad field of the thesis, why it matters,
          and which aspects are important.
        - Example (hardware): "Computer architecture is the foundation of all computing systems; advances in arithmetic units directly affect the performance, energy efficiency, and applicability of modern accelerators."
        - Example (software): "Scientific computing underpins discoveries in physics, chemistry, climate modelling, and engineering; the fidelity and cost of numerical simulations determine how quickly science can progress."

   P2. Context
        - Zoom in on the specific setting where the problem appears and explain its relevance to the broader domain.
        - Example (hardware): "Within computer architecture, the choice of number representation (fixed-point, floating-point, posit, etc.) determines the trade-off between accuracy, silicon area, and power consumption in hardware accelerators."
        - Example (software): "In scientific-computing workflows, number-representation libraries are called repeatedly inside kernels; their precision and runtime influence the overall reliability and turnaround time of large simulations."

   P3. Problem
        - State clearly the gap or deficiency that motivates your work.
        - Example (hardware): "There is currently no unified hardware library that offers multiple number representations together with a common benchmark suite, making fair comparison and reuse across projects difficult."
        - Example (software): "Existing software libraries provide many number formats but lack integrated automated testing and continuous-integration support, which hinders reproducible evaluation in large scientific-computing projects."

   P4-P6. Importance (2-3 paragraphs)
        - Explain why solving the problem matters, using concrete impacts and, if possible, literature examples.
        - Example hardware paragraph 4 (accuracy & performance):
              "An inappropriate number format can introduce unacceptable error in signal-processing pipelines or waste precious silicon area on under-utilized functional units."
        - Example hardware paragraph 5 (energy & cost):
              "Reducing the bit-width or adopting a more efficient format lowers dynamic power and static leakage, directly decreasing the energy per operation and the overall chip cost."
        - Example hardware paragraph 6 (literature/example):
              "Recent work on neural-network accelerators shows that switching from IEEE-754 float to posits can improve inference accuracy by up to 15 % while cutting energy by 20 %." [web:119]

        - Example software paragraph 4 (precision & reliability):
              "In climate-model simulations, floating-point rounding errors can accumulate and mask real physical signals, leading to misleading predictions."
        - Example software paragraph 5 (runtime & resources):
              "More compact representations reduce memory bandwidth and cache pressure, shortening kernel execution and allowing larger problem sizes on the same hardware."
        - Example software paragraph 6 (literature/example):
              "Studies in high-performance computing demonstrate that posit-based arithmetic can cut the time-to-solution of turbulent-flow simulations by ~10 % without sacrificing scientific validity." [web:121]

   P7-P8. Alternative solutions (2 paragraphs)
        - Briefly discuss what already exists and what it lacks concerning your goal.
        - Example hardware paragraph 7:
              "FloPoCo provides a rich set of floating-point cores but focuses mainly on IEEE-754 and related formats, offering limited support for posit or unum."
        - Example hardware paragraph 8:
              "Several open-source Chisel libraries implement individual formats (e.g., a fixed-point package) but they do not share a common test harness, making cross-format benchmarking ad-hoc."
        - Example software paragraph 7:
              "General-purpose libraries such as NumPy (Python) and the Julia standard library supply many number formats, yet they are not coupled to automated CI pipelines, so developers must run correctness and benchmark tests manually."
        - Example software paragraph 8:
              "Some research prototypes (e.g., a posit package for Julia) provide the arithmetic but lack integration with build systems like Jenkins, which limits their usability in large, collaborative scientific-computing projects."

   P9. Solution
        - Describe what you built or contributed in one concise paragraph.
        - Example (hardware):
              "We present a parameterizable Chisel library that implements fixed-point, floating-point, posit, and unum formats, together with a shared test-and-benchmark framework that can be instantiated for any target FPGA or ASIC."
        - Example (software):
              "We provide a Scala-based software library that encapsulates the same set of number representations and is wired into a Jenkins CI pipeline; the pipeline automatically compiles, runs correctness tests, and collects performance metrics for each format on demand."

   P10. Experiment overview (optional, 1 paragraph)
        - Briefly mention the kinds of benchmarks or experiments you will run to evaluate the solution.
        - Example (hardware):
              "To assess the library we synthesize designs for a mid-range FPGA and run a suite of DSP kernels (FIR filter, matrix multiply, CORDIC) measuring area, maximum frequency, and error versus a high-precision software reference."
        - Example (software):
              "We evaluate the software library using three representative scientific-computing kernels: a climate-model advection step, an n-body gravitational simulation, and a dense linear-algebra benchmark, reporting runtime, energy (via RAPL), and numerical error."

   P11. Contributions
        - List 2-4 concrete contributions of the thesis in prose.
        - Example (hardware):
              "The thesis contributes: (i) a reusable Chisel number-representation library; (ii) a common benchmark framework for fair cross-format comparison; (iii) quantitative evaluation of format trade-offs on FPGA targets; and (iv) guidance for hardware designers on selecting formats for accelerator design."
        - Example (software):
              "The thesis contributes: (i) a Scala software library with multiple number representations; (ii) a Jenkins-based CI workflow that automates testing and benchmarking; (iii) empirical results showing accuracy-runtime-energy trade-offs for scientific kernels; and (iv) a reusable template for integrating numerical experiments into CI pipelines."

   P12. Thesis structure
        - One sentence per chapter summarizing what the reader will find.
        - Example (hardware):
              "Chapter 2 reviews the theoretical foundations of number representation and related work; Chapter 3 presents the high-level architecture of the library and benchmark framework; Chapter 4 details the implementation choices and Chisel code generation; Chapter 5 describes the experimental setup and results; Chapter 6 discusses the implications for accelerator design; and Chapter 7 concludes with summary and future work."
        - Example (software):
              "Chapter 2 covers the background on scientific computing, number representations, and CI concepts; Chapter 3 outlines the proposed software architecture and Jenkins pipeline; Chapter 4 explains the implementation details and build configuration; Chapter 5 presents the evaluation kernels, metrics, and results; Chapter 6 discusses the impact on scientific-computing workflows; and Chapter 7 concludes with a summary and outlook."


// ============================================================
//  THESIS-SPECIFIC BULLETS
//  Concrete content for *this* thesis, paragraph by paragraph,
//  to be turned into prose after we attach citations and
//  documentation excerpts. The P1–P12 guide above stays as
//  reference. Wrapped in a raw block so symbols like *, _, #
//  are shown literally instead of being parsed as Typst syntax.
// ============================================================

#text(size: 10pt)[```
   P1. Domain — bullets
       - Secure communication is the foundation of the modern
         internet: HTTPS, messaging, banking, e-government,
         healthcare records.
       - The convention standard is TLS 1.3 (RFC 8446):
         confidentiality, integrity, and authentication over TCP.
       - The security of TLS — and of nearly all deployed
         cryptography — rests on *computational* assumptions:
         certain mathematical problems are believed to be hard for
         any realistic adversary.

   P2. Context — bullets
       - TLS 1.3 establishes a session key with ECDHE
         (Elliptic-Curve Diffie–Hellman Ephemeral); its security
         reduces to the hardness of the elliptic-curve discrete-log
         problem (ECDLP).
       - No classical algorithm solves ECDLP in practical time, so
         TLS is secure *today*.
       - The "secure today" guarantee is exactly what quantum
         computing calls into question.

   P3. Problem — bullets (harvest-now, decrypt-later)
       - Shor's algorithm (1994) solves factoring and discrete log
         in polynomial time on a sufficiently large quantum
         computer.
       - When such a machine exists, RSA, classical DH, and ECDHE
         all break — TLS 1.3 as deployed today loses its
         key-exchange security.
       - The threat is not purely future: an adversary can record
         TLS-protected traffic now and decrypt it later, once a
         quantum computer is available. This is the "harvest now,
         decrypt later" (HNDL) model, acknowledged by NSA / NIST /
         ENISA as a present concern for data with long-lived
         confidentiality requirements — state secrets, medical
         records, diplomatic traffic, industrial IP.

   P4–P6. Importance — bullets
       P4 (long-term confidentiality matters):
         - Categories of data whose secrecy must hold for decades,
           not years: classified government documents, health
           records, legal archives, long-lived industrial trade
           secrets.
         - Mosca's inequality (data retention time + migration time
           vs. time-to-CRQC): if data must remain secret for X
           years and migration takes Y years, a cryptographically
           relevant quantum computer arriving in fewer than X+Y
           years is already a problem.
       P5 (limits of computational responses):
         - The mainstream response is Post-Quantum Cryptography
           (PQC): Kyber, Dilithium, Falcon, SPHINCS+, standardised
           by NIST in 2024.
         - PQC is practical, scales globally, and is the right
           answer for most applications — but it remains
           *computational*. Its security bets on the hardness of
           newly-proposed problems (lattices, codes, isogenies); a
           future algorithmic break is believed unlikely but not
           ruled out.
         - For data with 30+ year secrecy requirements, this
           residual risk is hard to quantify and hard to discharge.
       P6 (the QKD + IT-secure alternative):
         - The only response that removes computational assumptions
           entirely is to combine:
             (a) Quantum Key Distribution for the key exchange —
                 security from the laws of quantum mechanics
                 (no-cloning, measurement disturbance);
             (b) One-Time Pad for encryption — Shannon-secure (1949);
             (c) Wegman–Carter MAC for authentication — IT-secure
                 (Wegman & Carter, 1981).
         - The resulting stack is *information-theoretically
           secure*: secure against an adversary with unbounded
           computational power.
         - QKD has been a real technology since the late 1990s, and
           the ETSI GS QKD 014 standard defines how applications
           consume QKD-generated keys over a REST API.

   P7–P8. Alternative solutions — bullets
       P7 (commercial QKD integrations):
         - Commercial QKD-VPN and QKD-Ethernet products exist
           (ID Quantique, Toshiba, QuantumXchange).
         - They use QKD-derived keys to feed *symmetric* algorithms,
           typically AES-256: the key exchange becomes quantum-safe,
           but the data path remains computational.
         - The overall stack is therefore not end-to-end
           information-theoretically secure.
       P8 (academic TLS+QKD proposals):
         - Several academic works integrate QKD into TLS (Mink et
           al.; Aguado et al.; recent ETSI hybrid-key drafts).
         - Most replace or augment the TLS key exchange with QKD
           but retain AES-GCM for the record layer.
         - To the author's knowledge, no reproducible open prototype
           combines (i) a full BB84 + Cascade + privacy-amplification
           QKD pipeline, (ii) an ETSI 014 KME, and (iii) a TLS 1.3
           shaped protocol whose record layer is itself IT-secure
           (OTP + Wegman–Carter).

   P9. Solution — bullets
       - This thesis presents *QTLS*: a TLS 1.3 shaped protocol
         whose data path is information-theoretically secure
         end-to-end.
       - The TLS 1.3 architecture is preserved (handshake →
         key schedule → record layer → close); only the cryptographic
         primitives change:
           * ECDHE   →  QKD key fetched by `key_ID` over ETSI GS QKD 014,
           * AES-GCM →  One-Time Pad with split directional key streams,
           * HMAC    →  Wegman–Carter MAC over GF(2^128).
       - The QKD layer is a real Qiskit-based BB84 simulation,
         followed by full Cascade reconciliation with
         back-propagation (implemented in C for performance) and
         privacy amplification.
       - The KME exposes the standard ETSI GS QKD 014 HTTP API and
         supports multi-node trusted-relay topologies.

   P10. Experiment overview — bullets
       - Evaluation has two parts.
         (1) Correctness — a deterministic test suite (52 tests
             across phases 1–9) covering BB84 sifting, Cascade
             convergence, the KME contract, OTP / Wegman–Carter
             primitives, the full QTLS handshake, and the
             end-to-end demo.
         (2) Empirical trade-offs — benchmarks measuring handshake
             latency, per-record key-consumption rate, KME pool
             drain under load, and Cascade information leak as a
             function of QBER.

   P11. Contributions — bullets
       The thesis contributes:
         (i)   a reproducible, end-to-end stack — BB84 (Qiskit) →
               Cascade (native C) → privacy amplification →
               ETSI 014 KME → QTLS — in which every primitive on
               the data path is information-theoretically secure
               (with one explicitly documented caveat: the SHAKE-128
               extractor in privacy amplification, discussed in
               Ch. 6);
         (ii)  an open-source reference implementation of the
               ETSI GS QKD 014 KME with a simulated KME-to-KME
               synchronisation channel, suitable as a teaching
               artefact;
         (iii) a quantitative evaluation of the cost of staying
               information-theoretically secure (handshake
               latency, key-consumption rate, pool drain) compared
               to a classical TLS 1.3 baseline;
         (iv)  a thesis-grade decision record
               (`docs/design_notes.md`) documenting every
               non-obvious design choice with rationale and
               rejected alternatives.

   P12. Thesis structure — bullets
       - Ch. 2 — theoretical background: classical cryptography
         and TLS 1.3; the quantum threat; information-theoretic
         security; QKD (BB84 + Cascade + privacy amplification);
         QKD networks and the ETSI 014 standard; related work.
       - Ch. 3 — system architecture: producer/consumer split,
         the KME as integration boundary, the QTLS state machine.
       - Ch. 4 — implementation: Qiskit BB84, the C Cascade core,
         the KME service, the QTLS primitives and key schedule.
       - Ch. 5 — evaluation: correctness suite, handshake latency,
         key-consumption profile, and Cascade leak under varying
         QBER.
       - Ch. 6 — discussion: the SHAKE-128 extractor caveat,
         scope and limits of the prototype, threats to validity.
       - Ch. 7 — conclusions and future work: Toeplitz extractor,
         decoy states, integration with real QKD hardware.
```]
