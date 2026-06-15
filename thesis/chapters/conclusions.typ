#import "../prelude.typ": *

This thesis delivered a secure-channel stack whose data path does not rest on any
computational assumption. Between the two endpoints, confidentiality comes from a
one-time pad, while integrity and authentication come from a Wegman-Carter tag
and from proving possession of the same quantum-distributed key, all keyed from
QKD material rather than from any problem being hard to solve. Where TLS 1.3
protects almost all web traffic today by relying on problems like the
elliptic-curve discrete logarithm staying hard to solve, the system built here
removes that dependency entirely. The two endpoints draw identical key material
from a quantum key distribution link instead of negotiating it over the network,
so the secrecy of the channel comes from the laws of physics rather than from the
cost of a computation.

What was built is a complete system from point A to B. Key material is produced over a
QKD link and reconciled into final secret bytes, a key management entity stores
and serves it through the ETSI 014 interface, and two secure application
entities run a TLS-style handshake and then protect every record with a one-time
pad and a Wegman-Carter authentication tag.

The point of the comparison with classical and post-quantum alternatives is not
that QTLS is faster, because it is not, and it never tried to be. Its advantage
is the security model: even if it is slower, the fact that the data stays secure
for as long as it must is priceless. A post-quantum scheme such as ML-KEM-768
keeps TLS fast and easy to deploy, but it still rests on a computational
assumption. QTLS takes the opposite trade: it drops the assumption entirely and
pays for that in latency and in key budget. Where the data must stay secret
regardless of how much computing power an attacker ever gains, that is the trade
worth making. Even though it serves a niche, it proves its worth by protecting
critical information under a strong theoretical guarantee.

The evaluation worked both as validation and as a benchmark. First, the system does what it claims: the
two ends agree on the same key, each key is used once, the ETSI interface is
honoured, and a session runs end to end with information-theoretic protection on
the data path. Second, the cost of that guarantee is measurable and sits in a
predictable place. It is concentrated in the handshake, which is about an order
of magnitude slower than TLS because of the round-trips to the KME, and in the
key budget, since the one-time pad spends a byte of key for every byte of data.
The data path itself stays competitive, so the price is paid at setup and in key
consumption, not in the protection of the data.

In developing this work, the strongest constraint and the one where other expertise is needed is
hardware: a full deployment needs real QKD endpoints, optical fibre, and the
supporting infrastructure, none of which was available for this work. The
measurements therefore use an abstract high-rate key generator and a BB84
simulation in place of a physical link, which means the cost of the quantum
layer itself is outside what we could measure, and the behaviour of the channel
over real long-distance fibre could not be tested. These are limits of access
and resources rather than flaws in the design, and they bound what the
evaluation can claim more than they bound the protocol.

Several extensions are left for the future:
replacing the SHAKE-128 extractor with a Toeplitz construction to tighten the
theoretical guarantee, moving KME synchronisation to a distributed protocol with
real mutual TLS, supporting multi-hop QKD networks to reach beyond two
endpoints, and adding the option of mid-session key refetching so a connection is not bounded
by the key it starts with. Re-running the benchmarks against a real QKD source,
for instance on the quantum infrastructure available at the faculty, would also
close the gap left by the abstract generator. These directions are discussed in
more detail in the discussion chapter.

The question this thesis set out to answer was whether unconditional security could be placed on a standard secure-channel protocol, and the answer is that it can. It comes at a cost, since the handshake is slower than TLS and every byte of data spends a byte of key, but that cost buys something no computational scheme can offer: protection on the data path that holds regardless of how much computing power an attacker ever gains. QTLS is not a replacement for TLS on everyday traffic, yet for short, high-value data that has to stay secret for decades, that guarantee is what makes it worth the price.

/*
   CONCLUSIONS CHAPTER - WRITING GUIDE (paragraph by paragraph)

   P1. Problem & solution recap
        - Briefly restate the original problem and your solution in one or two sentences.
        - Example (hardware):
              "We addressed the lack of a unified hardware library for comparing multiple number representations by delivering a parameterizable Chisel library with a shared test-and-benchmark framework."
        - Example (software):
              "We solved the missing reproducible evaluation of diverse number representations in scientific-computing projects by providing a Scala-based library integrated into a Jenkins CI pipeline."

   P2. Key results summary
        - Highlight the 2-4 most important quantitative or qualitative outcomes of your evaluation
          (no new details, just the take-away numbers).
        - Example (hardware):
              "Posit-8 gave the highest Fmax and lowest LUT usage across DSP kernels; posit-16 offered a noticeable accuracy gain with < 10 % area overhead."
        - Example (software):
              "Posit-16 yielded the best balance of error, runtime, and energy for climate-advection and n-body kernels; the unum-like format excelled for LU decomposition where dynamic range is critical."

   P3. Comparison with existing work
        - Explain how your results and approach improve upon or differ from the related work discussed
          in the background chapter.
        - Example (hardware):
              "Unlike FloPoCo, which focuses mainly on IEEE-754 formats, our library supports posit and
               unum-like formats and provides a common benchmark suite for fair cross-format comparison."
        - Example (software):
              "Compared to general-purpose libraries such as NumPy, our solution adds automated testing,
               CI integration, and a ready-made benchmark suite, enabling rapid experimentation in large teams."

   P4. Limitations
        - Acknowledge any threats to validity, assumptions, or constraints that affect the
          generalizability of your findings.
        - Example (hardware):
              "Results are based on synthesis for a single Artix-7 FPGA; power numbers are estimates
               from XPE, not silicon measurements."
        - Example (software):
              "Benchmarks use synthetic kernels; real scientific applications may involve different I/O
               patterns or mixed-precision workflows that could shift the trade-offs."

   P5. Future work
        - Propose concrete, feasible extensions that build directly on your thesis (keep this list
          shorter than the conclusions).
        - Example (hardware):
              "Future work could integrate the library into a full SoC with a RISC-V core, explore
               posit-32 for higher-dynamic-range kernels, and automate on-chip power measurement."
        - Example (software):
              "Future work could add stochastic-rounding support, extend the benchmark suite to include
               machine-learning inference kernels, and provide a GitHub-Action template for broader CI adoption."

   P6. Closing take-away
        - End with one memorable sentence that captures the core contribution and its impact.
        - Example (hardware):
              "This work gives hardware designers a practical, reproducible way to select the most
               efficient number representation for their accelerators."
        - Example (software):
              "This work equips scientific-computing teams with a CI-friendly toolbox to experiment
               with and quantify the impact of alternative number representations on correctness and cost."
*/
