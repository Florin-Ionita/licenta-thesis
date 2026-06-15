#import "../prelude.typ": *

== Summary of key findings

Our evaluation confirmed that the QTLS handshake is slower than classical TLS
1.3. The reason is the round-trips to the Key Management Entity, not the
cryptography itself. Apart from that, the system works: it sets up a session
whose data path is protected information-theoretically and the experiments also
measured what this protection costs. Each byte of payload spends one byte of QKD
key, and every record carries a fixed 16-byte authentication tag on top.
Finally, they showed that the channel error rate controls how much key gets
produced, with a threshold above which no key is produced at all.

== Interpretation of results

The handshake is slow for an infrastructural reason. The KME is reached over
HTTP, and fetching the key identifiers takes a few round-trips, a cost a session
pays only once, at startup. That is acceptable here, because QTLS is meant for
short, important exchanges, not for bulk traffic, so paying tens of milliseconds
once does not hurt.

On the data path the cost is built into the design, and it comes from the one-time pad.
Encrypting one byte of payload consumes one byte of key, and each record adds a
fixed 16-byte mask on top, so the amount a session can send is bounded directly
by the amount of key it holds. This makes communication depend on the
key-generation rate rather than on processing power. For light traffic the bound
is not a real constraint: as long as the sender does not consume key faster than
the link produces it, the supply is never exhausted. In a real deployment this
is the normal case, since a QKD link continuously fills a large pool of generated
keys that the SAEs draw from on demand, and a saturating sender that outpaces
that production is the only situation in which the budget actually runs out.

One caveat on that experiment: the key producer used there is a fast random key 
generator, not a real QKD link. So it shows the drain versus refill behaviour,
and it is modelled to produce keys at a rate a standard QKD would. Whether a deployment
stays in the comfortable regime depends entirely on the real key-generation
rate.

The last result is the link between error rate and key rate. As errors rise, the
key rate falls, and what is above the Shor-Preskill threshold drops to zero. It is exactly the mechanism that makes the security unconditional: if
the error rate is too high, an eavesdropper might be listening, so the protocol
refuses to produce a key instead of producing one that could be compromised.

One point applies to all of these numbers. The benchmarks draw their keys from
the abstract high-rate generator, not from the quantum BB84 simulation, so they
measure the protocol and the post-processing, not the cost of producing key on
real quantum hardware. The keys are not weaker for it, since the abstract
generator runs the same reconciliation and privacy-amplification pipeline as
BB84, but the figures should be read as the cost of everything above the quantum
layer rather than of the full system.

== Comparison with existing work

These findings line up with Rubio Garcia et al. #cite(<rubiogarcia2024qrtls>),
who chose not to use a one-time pad on the TLS data path precisely to save
QKD key material. Our results extend their position and show that, in
pure computational terms, an OTP record layer is cheap and practical: a single
XOR per byte keeps throughput close to TLS. By accepting the strict one to one
key consumption on purpose, this thesis demonstrates that end-to-end
information-theoretic security inside a standard protocol is feasible in a
prototype, and that the hard part is the key-generation rate of the hardware,
not the software.

The contrast with post-quantum cryptography sharpens this. As the key-exchange comparison showed, a scheme like ML-KEM-768 keeps TLS fast and easy to deploy but leaves a computational assumption in place. QKD takes the opposite trade: it removes the assumption entirely and pays for it in latency, key budget, and infrastructure.
It is important to understand the scope of the problem. The quantum-distributed key is secure in an information-theoretic sense and should be used on important data, while ML-KEM is a good alternative against a quantum computer but that guarantee can still be broken.

== Implications for the domain

For the wider area of secure communications, QTLS is not a general-purpose
protocol, and it does not try to be. It fits a niche: short, highly critical
messages that would be exposed by a harvest-now-decrypt-later attack, where
someone records your traffic today and just waits for a quantum computer or algorithm
to break its security. Things like cryptographic bootstrapping keys or other secrets
that have to stay confidential for decades. For that kind of payload, paying in
latency and key budget is an acceptable trade. The broader implication is that it
makes a case for building more information-theoretically secure systems where
the stakes justify them, and it highlights a real problem: anything
resting on a computational assumption today is only as safe as that assumption
stays unbroken, and a future attack on it would expose every message ever
recorded under it.

The protocol itself delivers the security it promises, but what
holds it back is not the cryptography but how hard it is to adopt, since it asks
for a whole QKD infrastructure that few organisations have today. That is an
argument for encouraging this direction rather than dismissing it: work that
makes the case for unconditional security and mentions its importance
is what will decide whether protocols like QTLS ever move beyond a
niche.

== Limitations

Several limitations of the current prototype should be acknowledged. The
architecture models a point-to-point link between exactly two endpoints, which
limits its range because the quantum signal degrades over long optical fibre. It
also relies on the trusted-node assumption from the ETSI 014 standard, and this
is a genuine gap in the security model, not a detail: the KME sees the key in
the clear. The data path is information-theoretically secure, but each KME is a
point that has to be trusted, so the unconditional guarantee holds between
endpoints only as far as the KMEs are honest.

On the implementation side, privacy amplification uses SHAKE-128 as a practical
extractor instead of a mathematically pure universal hash family. The modular
design makes this a drop-in replacement, but as it stands it softens the
strictness of the information-theoretic claim. The KME synchronisation through a
shared lock and the header-simulated mTLS are simplifications that fit a local
proof-of-concept, not a distributed production deployment.

Beyond the prototype, the protocol is fundamentally constrained by its hardware.
Its security depends on a real QKD link, a KME, and the SAEs, so the guarantee is
only as available as that infrastructure is. A deployment needs all of it in
place and producing key at a usable rate, which is expensive and not yet widely
accessible, and this is as much a limit on where QTLS can be used as any property
of the protocol itself.

== Future work

Future work should close the theoretical gap first, by replacing the SHAKE-128
extractor with a Toeplitz-matrix construction so that privacy amplification is
unconditionally secure. SHAKE-128 was used because it is a strong cryptographic extractor in practice and was enough to sustain the privacy of the key; the Toeplitz construction would tighten the theoretical guarantee rather than fix a functional gap. On the infrastructure side, the KME synchronisation
should move to a distributed two-phase commit protocol with real
network-level mTLS instead of the header simulation.

Two further extensions would lift the current limits on distance and data
volume. The architecture could be integrated with multi-hop QKD networks for
longer-range routing, which would relax the two-endpoint constraint. A
mid-session key-refetching mechanism would let an active connection draw fresh
keys before its pool runs out, so a session is no longer bounded by the key it
held at startup.

A few smaller extensions follow directly from the gaps above. The ETSI 014
interface lets a master SAE share one key with several slave SAEs at once, which
the current prototype does not support, so adding this multi-SAE delivery would let
the same key reach a group rather than a single peer. The benchmarks could also
be re-run against a real QKD source instead of the abstract generator, for
example on the quantum infrastructure available at the faculty, to measure the
cost of the quantum layer that the current figures leave out and complete the
picture the evaluation gives.

/*
   DISCUSSION CHAPTER - WRITING GUIDE (paragraph by paragraph)

   P1. Summary of key findings
        - Briefly recap the most important quantitative or qualitative outcomes
          of your evaluation (no new numbers, just a high-level summary).
        - Example (hardware):
              "Our evaluation showed that the posit-8 format consistently delivers
               the highest clock frequency and lowest LUT usage across DSP kernels,
               while posit-16 offers a modest accuracy improvement with a small
               area overhead."
        - Example (software):
              "The software evaluation revealed that posit-16 provides the best
               balance of numerical error, runtime, and energy consumption for
               the climate-advection and n-body kernels, whereas the unum-like
               format excels for the LU-decomposition kernel where dynamic range
               is critical."

   P2. Interpretation of results
        - Explain why you observed those outcomes, linking them to the underlying
          characteristics of the number representations (precision, range,
          encoding efficiency, etc.).
        - Example (hardware):
              "Posit-8's tapered accuracy and compact encoding reduce the amount
               of logic needed for arithmetic, whereas posit-16's larger fraction
               gives an extra bit of precision without a proportional increase
               in routing complexity."
        - Example (software):
              "Posit-16's use-of-regime encoding yields efficient representation
               of numbers near unity, which are common in scientific kernels,
               while the unum-like format's variable-size exponent avoids
               overflow/underflow in the LU decomposition's large intermediate
               values."

   P3. Comparison with existing work
        - Relate your findings to the related work discussed in the background
          chapter: do you confirm, extend, or contradict previous claims?
        - Example (hardware):
              "These results agree with earlier FloPoCo studies that posit-8
               achieves lower area than IEEE-754 for low-precision DSP[web:119],
               and they extend the observation to a broader set of kernels and
               to the posit-16 format."
        - Example (software):
              "Our findings corroborate recent HPC work that posit-based
               arithmetic can reduce time-to-solution in turbulent-flow
               simulations[web:121], and they add the insight that a CI-integrated
               library makes such experiments repeatable across large teams."

   P4. Implications for the domain
        - Discuss how the results affect practitioners or researchers in your
          broader domain (e.g., hardware designers, scientific-computing teams).
        - Example (hardware):
              "For hardware accelerators, the data suggest that posit-8 should be
               the default choice for throughput-oriented DSP blocks, while
               posit-16 is worth considering when a few extra LUTs are available
               and higher fidelity is needed."
        - Example (software):
              "Scientific-computing teams can now plug the number-representation
               library into their Jenkins pipelines and instantly see the
               trade-off between precision, runtime, and energy, enabling
               data-driven format selection for climate-modeling, n-body
               simulations, or linear-algebra workloads."

   P5. Limitations
        - Identify any threats to validity, assumptions, or constraints that
          could affect the generalizability of your results.
        - Example (hardware):
              "Our synthesis targets a single Artix-7 FPGA; results may differ on
               newer Ultrascale+ or ASIC technologies. The power numbers are
               estimates from XPE, not measured on silicon."
        - Example (software):
              "Benchmark kernels are synthetic proxies; real scientific
               applications may involve different memory access patterns or
               mixed-precision workflows that could shift the trade-offs."

   P6. Future work
        - Propose concrete, feasible extensions that build on your thesis
          (e.g., new formats, larger benchmarks, hardware-software co-design).
        - Example (hardware):
              "Future work could integrate the library into a full SoC with a
               RISC-V core, explore posit-32 for higher-dynamic-range kernels,
               and automate power measurement via on-chip sensors."
        - Example (software):
              "Future work could add support for stochastic rounding, extend the
               benchmark suite to include machine-learning inference kernels,
               and provide a GitHub Action template for broader CI adoption."
*/
