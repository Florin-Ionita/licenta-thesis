#import "../prelude.typ": *

== Evaluation strategy

The evaluation first checks whether the
system works at all: whether the two ends really agree on the same key, whether
a key is never reused, whether the KME interface stays faithful to ETSI 014,
and whether an end-to-end session can be established and carry data. The other thing
we look at, and the more interesting one, is what all this costs. Because the thesis trades a
computational guarantee for an information-theoretic one, the point is not to
beat classical TLS on speed but to measure the price of that trade. Therefore,
the tests measure handshake latency and time-to-last-byte, application-data throughput,
the rate at which the key pool drains under load, the amount of key consumed per
byte of data, and how the final key rate behaves as the channel error rate
rises. 
The baselines which are compared with QTLS are experiments chosen on aspects
where it would make sense to measure the trade-off. The handshake
latency is compared directly against a real TLS 1.3 handshake, and the data-path
throughput against TLS 1.3 with AES-GCM, since both protocols do the same job
there. The key exchange is compared three ways: the QKD key fetch against the
X25519 elliptic-curve exchange and against the post-quantum ML-KEM-768, on
latency and on bytes sent over the wire. The remaining three experiments, pool
drain, key consumption and the QBER sweep, have no baseline because they
measure properties that exist only because the keys come from a finite QKD
supply.

== Benchmarks and metrics

The benchmark suite consists of six modular experiments, each measuring one cost
and runnable on its own.

The handshake-latency experiment measures the time to complete a QTLS handshake
against a real TLS 1.3 handshake, reported as median, 95th and 99th percentile
over many runs. 

The throughput experiment measures the sustained
application-data rate of the one-time-pad data path against TLS 1.3 with
AES-GCM, across several payload sizes. 

The pool-drain experiment measures how
many handshakes, records and bytes a KME key pool sustains under continuous load
before it is exhausted, given a fixed key-generation rate. 

The key-consumption
experiment measures the ratio of key bytes consumed to useful payload bytes as a
function of record size, which exposes the fixed 16-byte authentication overhead
per record. 

The QBER sweep measures the final secret-key rate as a function of
the quantum bit error rate, showing how reconciliation leakage and privacy
amplification shrink the usable key as the channel degrades. 

Finally, the
key-exchange experiment measures the latency and the on-the-wire size of
obtaining a shared secret, comparing the QKD key fetch against X25519 and
ML-KEM-768.

== Experimental setup

All measurements come from a single run of the `full` benchmark profile, which
fixes the iteration counts for every experiment: the handshake is measured over
5000 timed runs after a warm-up, the key exchange over 5000, and the
throughput, pool-drain and QBER experiments over fixed time budgets and payload
lists.

Across all experiments the keys come from the abstract high-rate generator
rather than from the quantum BB84 simulation, which is too slow to produce key
at these volumes; the implications of this choice are discussed in the
discussion chapter. The generator still runs the same reconciliation and
privacy-amplification pipeline as BB84, so the keys it produces are
cryptographically identical and only the raw-entropy source differs.

The whole stack runs in one process on a laptop with an Intel Core i7-10810U CPU
(6 cores, 12 threads) and 32 GB of RAM, running Ubuntu 24.04 and Python 3.12, so
the figures presented below reflect the real protocol and record-layer code path the
earlier chapters describe, not a model of it. The TLS 1.3 baseline is a real handshake and record
layer over the same loopback transport, so the two protocols are measured under
identical conditions and only the cryptography differs. The library versions are
those pinned in @tab:deps.

== Results

=== Handshake latency

@fig:eval-handshake compares the two handshakes. The QTLS handshake takes a
median of about 44.6 ms against 2.9 ms for TLS 1.3, roughly an
order of magnitude slower. That gap comes from round-trips: a QTLS
handshake makes two extra requests to the KME (the master pull and the slave
fetch) before any traffic flows, whereas TLS 1.3 derives its secret inline from
the Diffie-Hellman exchange. The tail (99th percentile) is influenced by those
requests rather than by the one-time-pad work, which is negligible.

#figure(
  image("/docs/benchmarks/plots/01_handshake_latency_histogram.pdf", width: 85%),
  caption: [Handshake latency distribution, QTLS versus TLS 1.3. The two
    histograms use independent x-axes, and the 99.5th percentile is clipped.],
) <fig:eval-handshake>

=== Throughput

@fig:eval-throughput shows sustained throughput across payload sizes. Here QTLS
is much closer to TLS 1.3 than the handshake suggests, because a one-time pad is
a single XOR per byte, cheaper than the block-cipher work in AES-GCM. And the cost
of QTLS on the data path is the key budget it spends, not the time it takes.

#figure(
  image("/docs/benchmarks/plots/03_throughput_bars.pdf", width: 85%),
  caption: [Application-data throughput, QTLS versus TLS 1.3.],
) <fig:eval-throughput>

=== Pool drain

@fig:eval-pooldrain shows the key pool under a paced, chat-style load. Starting
from a small prefill, the pool climbs steadily for the whole run because the QKD
producer outpaces this light consumption by a wide margin: at a realistic chat
rate the source keeps up easily, so the pool only grows. The cumulative payload
on the right axis rises in steps as messages are sent, but the key this consumes
is too small against the production rate to bend the pool curve downward. The two
KME curves coincide because the feeder writes the same blocks into both stores.
The takeaway is that a normal chat never exhausts the pool. Only a saturating
sender, one that ships data faster than the source refills the pool, drains it to
zero; at that point the sender is throttled to the key-production rate, since it
cannot send a byte it has no key for. The rate at which keys are produced is the
parameter that decides which regime a deployment is in.

#figure(
  image("/docs/benchmarks/plots/04_pool_drain.pdf", width: 85%),
  caption: [Key pool over time. The
    two y-axes are independent: the left counts keys in the pool (each key is an
    8 KiB block), the right is the cumulative payload sent in KiB.],
) <fig:eval-pooldrain>

=== Key consumption

@fig:eval-keyconsumption plots the ratio of key bytes consumed to useful payload
bytes against record size. The ratio is dominated by the fixed 16-byte
Wegman-Carter mask per record: for small records the overhead is large, while
for large records it amortises and the ratio approaches one key byte per payload
byte.

#figure(
  image("/docs/benchmarks/plots/05_key_consumption_ratio.pdf", width: 85%),
  caption: [Key consumed per useful byte, as a function of record size.],
) <fig:eval-keyconsumption>

=== Key rate versus QBER

@fig:eval-qber shows the final secret-key rate as the quantum bit error rate
rises. The rate falls as QBER grows, because more errors mean more parity bits
revealed during reconciliation and a larger reduction during privacy
amplification. Above the Shor-Preskill abort threshold, introduced in the background chapter, no key is produced at all.

#figure(
  image("/docs/benchmarks/plots/06_qber_vs_rate.pdf", width: 85%),
  caption: [Final secret-key rate as a function of the channel QBER (asymptotic
    rate at a 1.0 Mbps raw key rate).],
) <fig:eval-qber>

=== Key exchange comparison

@fig:eval-kx-latency and @fig:eval-kx-wire compare obtaining the shared secret
three ways. In latency the QKD fetch is the slowest (a median of about
2336 us against 255 us for X25519 and 343 us for ML-KEM-768),
because it is a network request to the KME rather than a local computation. On
the link, however, the picture inverts: the QKD path sends only a 16-byte key
identifier and never the key itself, against 32 bytes each way for X25519 and
over a kilobyte each way for ML-KEM-768.

#figure(
  image("/docs/benchmarks/plots/07_keyexchange_latency.pdf", width: 85%),
  caption: [Key-exchange latency: QKD fetch, X25519, ML-KEM-768 (median with
    95th-percentile error bars).],
) <fig:eval-kx-latency>

#figure(
  image("/docs/benchmarks/plots/08_keyexchange_wire.pdf", width: 85%),
  caption: [On the link bytes per key exchange (log scale).],
) <fig:eval-kx-wire>

== Data analysis

Read together, the experiments confirm that QTLS does not win on
speed: its handshake is about an order of magnitude slower than TLS 1.3, and its
key exchange is several times slower than either X25519 or ML-KEM-768. Both slowdowns
come from the round-trips to the KME, not from
the information-theoretic primitives, which are cheap: the one-time pad keeps
throughput close to TLS, and the per-record cost is a flat 16 bytes.

The real constraint on QTLS is not time but key material: the one-time pad 
spends a byte of key for every byte of data, so a session's reach is bounded
by how much key it holds, and the supply itself shrinks as the channel error
rate rises. The implementation makes this limit visible
by letting a session end once its pool is exhausted instead
of silently fetching more, which keeps the cost of QKD visible
throughout the measurements. QTLS pays in a finite key budget, and the experiments
show that this is a price worth paying where the guarantee has to hold 
regardless of the attacker's power.

Against the alternatives the trade is sharpest on the communication link. A post-quantum key
exchange such as ML-KEM-768 keeps TLS fast but inflates the handshake to more
than a kilobyte in each direction, which is exactly the cost the data-heavy TLS
study #cite(<kampanakis2024ttlb>) measures while the QKD path sends 16 bytes. The
comparison is not entirely like-for-like, since ML-KEM is measured as a
primitive and its security is still computational, but it frames the difference:
post-quantum cryptography buys quantum resistance cheaply and keeps a
computational assumption, whereas QKD removes the assumption and pays for it in
latency and key budget.

== Evaluation conclusion

The evaluation confirms that the system does what it claims: the two ends agree
on the same key, the key is used once, the ETSI interface is honoured, and a
session runs end to end with information-theoretic protection on the data path.
It also quantifies the cost of that guarantee. QTLS is slower to start and bounded
by its key supply, but its data path is competitive and the bytes used for key exchange are 
lower. This answers the question the thesis set out with: unconditional
security on a standard secure-channel protocol is achievable, and its price is
measurable, concentrated in handshake latency and key consumption rather than in
the protection of the data itself.

/*
   EVALUATION CHAPTER - WRITING GUIDE (paragraph by paragraph)

   P1. Evaluation strategy
        - Explain how you will evaluate whether the solution addresses the original problem.
        - List the qualities you will measure (accuracy, performance, energy, area, usability, etc.) and why they matter.
        - Example (hardware):
              "To assess whether the Chisel library provides a fair basis for comparing number representations, we measure functional correctness (bit-exact match with a high-precision software reference), resource usage (LUT/FF count, DSP-slice usage, BRAM), maximum clock frequency (Fmax) from synthesis, and estimated power from the Xilinx Power Estimator."
        - Example (software):
              "To evaluate the software library we verify numerical correctness (error versus a 128-bit decimal reference), runtime (wall-clock time per kernel), energy consumption (via Intel RAPL), and memory footprint (peak RSS)."

   P2. Benchmarks & metrics
        - Describe the benchmark suite you use, what each benchmark represents, and which metrics you collect for each.
        - Example (hardware):
              "We use a suite of DSP kernels: FIR filter (64-tap), 2-D 8x8 DCT, matrix-vector multiply (64-bit inputs), and a CORDIC-based phase-rotation block. For each kernel we record: area (LUT+FF), DSP-slice usage, BRAM, Fmax (MHz), and estimated dynamic power (mW)."
        - Example (software):
              "We evaluate three representative scientific-computing kernels: climate-model advection step, n-body gravitational simulation, and dense linear-algebra kernel. For each kernel we collect: mean absolute error (vs. 128-bit decimal reference), median runtime (seconds) over 30 runs, average socket power (watts) from RAPL, and peak resident memory (MiB)."

   P3. Experimental setup
        - Detail the hardware, software, and environmental conditions under which the benchmarks run.
        - Include versions, configurations, and any steps taken to ensure fairness.
        - Example (hardware):
              "All designs are synthesized for a Xilinx Artix-7 XC7A200T FPGA (speedgrade -2) using Vivado 2023.2. Target clock is 200 MHz; we enforce a uniform IO-standard (LVCMOS18) and disable unnecessary optimizations (-no bufg). Power estimates are generated with the Xilinx Power Estimator (XPE) using default activity factors (0.1 for registers, 0.2 for logic)."
        - Example (software):
              "Benchmarks run on an Intel Core i7-12700K (Linux 6.8, Ubuntu 24.04) with Intel RAPL enabled for socket-level power measurement. The JVM is OpenJDK 17.0.12; sbt version is 1.9.8. Each benchmark is executed in a fresh Docker container (Ubuntu 22.04, OpenJDK 17) to isolate the build environment, while the benchmark binary itself runs on the host to access RAPL. We pin the CPU frequency to the base turbo boost (3.6 GHz) and disable hyper-threading to reduce variance."

   P4. Results
        - Present the outcome of each benchmark, preferably in tables or figures, and give a short, plain-language interpretation of what the numbers mean.
        - You may split this into sub-paragraphs or sub-sections per benchmark.
        - Example (hardware):
              "Table 1 shows the synthesis results for the FIR filter: the posit-8 adder uses 112 LUTs and achieves a Fmax of 340 MHz, while the IEEE-754 binary32 adder needs 158 LUTs and tops out at 285 MHz. The posit-8 version therefore saves ≈ 30 % area and allows ≈ 20 % higher clock speed. Similar trends appear across the DCT and matrix-vector kernels, with posit-8 consistently delivering the best area-frequency product."
              "Figure 2 plots estimated power versus accuracy (mean absolute error) for the CORDIC kernel; the posit-16 operating point lies on the lower-left corner, indicating lower power and lower error than binary32 at the same workload."
        - Example (software):
              "Table 2 summarizes the climate-advection kernel: the posit-16 implementation incurs a mean absolute error of 1.2 x 10⁻⁴ (vs. 3.5 x 10⁻⁴ for binary32) while running in 0.84 s (binary32: 0.96 s) and drawing 42 W average socket power (binary32: 48 W). This translates to a ≈ 12 % reduction in error, ≈ 13 % faster execution, and ≈ 13 % lower power."
              "Figure 3 shows the energy-vs-error trade-off for the n-body benchmark; the unum-like format dominates the Pareto frontier, delivering the lowest error for a given energy budget."

   P5. Data analysis
        - Interpret the patterns across benchmarks. Discuss trade-offs, outliers, and what the results imply for the choice of number representation in different scenarios.
        - Example (hardware):
              "Across all four DSP kernels, the posit-8 format consistently yields the highest Fmax and lowest LUT count, making it attractive for throughput-oriented designs. The posit-16 format, while slightly larger, provides a noticeable accuracy gain (≈ 1 bit extra precision) at a modest area cost (< 10 % increase). The IEEE-754 binary32 format is never optimal on either axis for these kernels, suggesting it is over-engineered for the targeted precision range."
        - Example (software):
              "For memory-bound kernels (climate advection, n-body) the compact posit-8 and posit-16 formats win because they reduce memory bandwidth and cache pressure, leading to lower runtime and energy. For compute-intensive kernels with high dynamic range (LU decomposition), the unum-like format 's ability to represent very large and very small numbers without overflow/underflow gives it an accuracy edge, even though it uses more bits."

   P6. Evaluation conclusion
        - Summarize what the evaluation tells you about the original problem and how your solution addresses it.
        - Link back to the research question or goal stated in the background chapter.
        - Example (hardware):
              "The evaluation confirms that a parameterizable hardware library enables fair, reproducible comparison of number representations. Posit-8 emerges as the best choice for low-latency, low-area accelerator kernels, while posit-16 offers a useful accuracy boost when a few extra LUTs are affordable. This answers our research question: which format(s) give the best accuracy-area-power trade-off for accelerator kernels?"
        - Example (software):
              "The evaluation shows that our Jenkins-integrated software library lets scientific-computing teams swap number representations with a single configuration change and instantly see the impact on correctness, runtime, and energy. Posit-16 provides the best balance for the kernels we tested, confirming that a CI-friendly library can accelerate experimentation with alternative formats in large-scale projects."
*/
