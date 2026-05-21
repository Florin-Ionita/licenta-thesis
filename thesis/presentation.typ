// ============================================================
//  Thesis Presentation (Touying)
//  Uses config.typ from the thesis template
// ============================================================

#import "@preview/touying:0.6.1": *
#import themes.university: *
#import "@preview/cetz:0.3.2"
#import "@preview/fletcher:0.5.5" as fletcher: node, edge
#import "@preview/numbly:0.1.0": numbly
#import "@preview/theorion:0.3.2": *
#import cosmos.clouds: *
#import "config.typ": *

#show: show-theorion

// cetz and fletcher bindings for touying (optional, for diagrams)
#let cetz-canvas = touying-reducer.with(
  reduce: cetz.canvas,
  cover: cetz.draw.hide.with(bounds: true),
)
#let fletcher-diagram = touying-reducer.with(
  reduce: fletcher.diagram,
  cover: fletcher.hide,
)

// Helper: bilingual slide titles based on config.typ's `language`
#let slide-title(ro, en) = if language == "ro" { ro } else { en }

// Configure touying university theme
#show: university-theme.with(
  aspect-ratio: "16-9",
  align: left + top,
  config-common(
    frozen-counters: (theorem-counter,),
  ),
  config-info(
    title: [#thesis_title],
    subtitle: [#doc_kind()],
    author: [#student],
    date: year,  // adjust to a specific defense date if needed
    institution: [
      #align(center)[
        // Top: one-column grid, two rows.
        #grid(
          columns: (1fr,),
          row-gutter: 0.5cm,
          align: (center,),


          // --- Lower row: original 3-column layout ---
          grid(
            columns: (2cm, 2cm, 4cm),
            column-gutter: 0.5cm,
            align: (center + horizon, center + horizon),
            // left logo: university
            image(university_logo_path(), height: 2cm, fit: "contain"),

            // center logo: faculty logo (fixed)
            image("../logos/fac_acs/acc_logo.svg", height: 2cm, fit: "contain"),

            // right logo: department-specific, language-specific
            image(department_logo_path(), width: 4cm, fit: "contain"),

          ),

          // Center text: department, faculty, university
          align(center + horizon)[
            #set par(leading: 0.4em, spacing: 0em)
            #text(size: 10pt, weight: "bold")[#department_name()] \
            #text(size: 10pt, weight: "bold")[#t("label_faculty")] \
            #text(size: 10pt, weight: "bold")[#t("label_university")] \
            #text(size: 10pt, weight: "bold")[#t("label_university_short")]
          ],
        )
      ]
    ],
    // Replace with your preferred logo (e.g., central university logo)
    logo: box(
      image(department_logo_path(), height: 1em),
      height: 1em,
    ),
  ),
)

// Heading numbering for slides (simple, or set to `none`)
#set heading(numbering: numbly("{1}.", default: "1.1"))

// ------------------------------------------------------------
//  Title & Outline
// ------------------------------------------------------------

#title-slide()

== #slide-title("Cuprins", "Outline") <touying:hidden>

#components.adaptive-columns(
  outline(title: none, indent: 1em, depth: 1),
)

// ------------------------------------------------------------
//  Domain and Context
// ------------------------------------------------------------

= #slide-title("Domeniu și context", "Domain and Context")

== #slide-title("Domeniu și context", "Domain and Context")

- Domain of the thesis (e.g., computer architecture, etc.).
- Context of the domain (e.g., hardware accelerators for RISC-V).
- Maximum 20-second introduction for non-experts.
- You can give some information about the domain/context. 

#speaker-note[
  My thesis focuses on open-source computer architecture, in particular on
  hardware accelerators for RISC-V. RISC-V is a free and open instruction set
  architecture that enables innovation and collaboration in processor and
  accelerator design. General-purpose CPUs are reaching a performance wall for
  specialized workloads, so dedicated hardware accelerators are increasingly
  used to improve speed and efficiency.
]

// ------------------------------------------------------------
//  Problem and Importance
// ------------------------------------------------------------

= #slide-title("Problema abordată", "Problem and Motivation")

== #slide-title("Problema abordată", "Problem Statement")

- The problem addressed by the thesis.
- Why this problem exists? What are the challenges?
- How does this problem relate to the domain and context?
- Time : 20 seconds, keep it concise and focused on the key points.

#speaker-note[
  The problem I address in my thesis is the design and implementation of an efficient hardware accelerator for symmetric cryptographic functions on RISC-V. This problem exists because most cryptographic standards rely on software implementations that are often inefficient, slow, and vulnerable to attacks. The goals of solving this problem include achieving high performance, low latency, low power consumption, and security against side-channel attacks. This problem is relevant to the domain of computer architecture and the context of hardware accelerators for RISC-V, as RISC-V is a popular architecture for hardware accelerators but lacks efficient support for cryptographic functions.
]

== #slide-title("Importanța problemei", "Why Is This Important?")

- Why this problem is important to solve?
- Are there others that tried to solve this problem? What are their limitations?. Keep it short and to the point. e.g. "X and Y proposed a, but their solution has limitations such as b ...".
- What is the impact of solving this problem?
- Time: 20 seconds, focus on the significance and potential impact of the problem.

#speaker-note[
  This problem is important to solve because secure communication and data protection are critical in today's digital world, and efficient hardware accelerators can enable faster and more secure with higher throughput applications. Some hardware accelerators exist, but they are often proprietary, expensive, or not optimized for RISC-V. Solving this problem can have a significant impact on the performance and security of applications that rely on cryptographic functions, as well as on the adoption of RISC-V.
]

// ------------------------------------------------------------
//  Proposed Solution & Architecture
// ------------------------------------------------------------

= #slide-title("Soluția propusă", "Proposed Solution")

== #slide-title("Prezentare generală a soluției", "Solution Overview")

- What is the proposed solution?
- What are the key components of the solution?
- What is the main goal of the solution?
- Time: 20 seconds, provide a high-level overview of the solution without going into technical details.


#speaker-note[
  The proposed solution is a novel hardware accelerator design for symmetric cryptographic functions on RISC-V. The key components of the solution include a custom instruction set extension for cryptographic functions, a hardware module for accelerating specific functions, and a software library for interfacing with the hardware. The main goal of the solution is to achieve high performance, low latency, low power consumption, and security against side-channel attacks.
]

== #slide-title("Arhitectura sistemului", "System Architecture")

- Describe the architecture of the proposed solution
- Highlight the main components and their interactions
- Discuss any novel architectural features or design choices
- Best here to have a diagram illustrating the architecture.
- Time: 50 seconds, focus on the high-level structure and key components of the system.


#speaker-note[
  The architecture of the proposed solution consists of RISC-V Rocket CPU with a custom instruction set extension for cryptographic functions, a hardware module that implements the specific functions, and a software library that provides an API for applications to use the hardware accelerator. The C++ software library uses RoCC assembly inline instuction and compare it with the software implementation of the same functions. The two-approach are tested on the same hardware platform emulated thourgh Verilator and using Proxy kernel.
  ...
]

//// Exemplu de placeholder pentru o diagramă (comentează/înlocuiește după nevoie):
// #figure(
//   cetz-canvas[
//     // your cetz diagram here
//   ],
//   caption: [#slide-title("Arhitectura sistemului", "System Architecture Diagram")],
// )

// ------------------------------------------------------------
//  Implementation Decisions
// ------------------------------------------------------------

= #slide-title("Implementare", "Implementation")

== #slide-title("Decizii de implementare", "Implementation Decisions")

- What were the main implementation decisions you made?
- Why did you choose a particular programming language, framework, or tool?
- What were the trade-offs you considered?
- Here you can briefly mention the technologies used (e.g., RISC-V, Chisel, C++) and why they were suitable for your solution.
- You are showing your Engineering skills here, so be sure to highlight the key technical choices and their rationale.
- Time: 60 seconds, focus on the key implementation choices and their rationale.

#speaker-note[
  The main implementation decisions I made include choosing RISC-V as the target architecture for the hardware accelerator, using Chisel as the hardware description language, and implementing the software library in C++. I chose RISC-V because it is an open and flexible architecture that allows for custom extensions. I chose Chisel because it is a powerful and expressive language for hardware design that integrates well with the RISC-V ecosystem (Rocket Chip + Chipyard). I implemented the software library in C++ because it is a widely used language for performance-critical applications and has good support for interfacing with hardware.
]

// ------------------------------------------------------------
//  Evaluation and Results
// ------------------------------------------------------------

= #slide-title("Evaluare și rezultate", "Evaluation and Results")

== #slide-title("Setup de evaluare", "Evaluation Setup")

- What is the computer/platform used for evaluation? CPU, RAM, GPU, etc. Software versions, OS, etc.
- What benchmarks or workloads were used for testing? How were they selected?
- What is the methodology for testing? How many runs, under what conditions? (verified by statistical methods - results are normal distributed, etc.)
- What metrics were used for evaluation? Throughput, latency, resource utilization, etc.
- Time : 30 seconds, provide a clear and detailed description of the evaluation setup to ensure that the results are credible and reproducible.

#speaker-note[
  The evaluation was conducted on a RISC-V Rocket CPU with the custom hardware accelerator implemented in Chisel. The software library was tested on the same hardware platform emulated through Verilator and using Proxy kernel. The benchmarks used for testing include a set of symmetric cryptographic functions and hash functions, such as AES and SHA-256, which were selected based on their relevance and common use in secure applications. The methodology for testing involved running each benchmark 1000 times under controlled conditions to ensure consistency and reliability of the results. The metrics used for evaluation include throughput (requests per second), latency (milliseconds), and resource utilization (CPU usage).
]

== #slide-title("Rezultate cantitative I", "Quantitative Results I")

- Figure/Tables with the main quantitative results (e.g., performance metrics, comparisons with baselines).
- Interpretation of the results: what do they show? Are they consistent with your expectations?
- Highlight any significant improvements or findings.
- You can have multiple slides here if you have a lot of results to show, but try to keep it concise and focused on the key findings.

#figure(
  table(
    columns: 4,
    align: center,
    table.header(
      [*Scenario*], [*Measure*], [*Value*], [*Reference/Baseline*],
    ),
    ["Scenario 1"], ["Latency (ms)"], ["TODO"], ["TODO"],
    ["Scenario 2"], ["Throughput (req/s)"], ["TODO"], ["TODO"],
  ),
  caption: [#slide-title("Rezultate experimentale principale", "Main Experimental Results")],
)

#speaker-note[
  The main experimental results show that the proposed hardware accelerator achieves a significant improvement in latency and throughput compared to the software implementation. For example, in Scenario 1, the latency was reduced from TODO ms to TODO ms, which is a TODO% improvement. In Scenario 2, the throughput increased from TODO req/s to TODO req/s, which is a TODO% improvement. These results are consistent with our expectations based on the design of the hardware accelerator and demonstrate the effectiveness of our solution.
]

== #slide-title("Evaluare calitativă", "Qualitative Evaluation")

- In the case of thesis includes qualitative results (e.g., user studies, case studies, etc.), describe the setup and findings.
- What insights were gained from the qualitative evaluation?
- How do these insights complement the quantitative results?
- Time: 30 seconds, provide a clear and concise summary of the qualitative evaluation and its implications for the overall findings of the thesis.

#speaker-note[
  In addition to the quantitative results, we also conducted a qualitative evaluation through a case study of how easy it is to integrate the proposed hardware accelerator into existing applications. The case study involved working with developers to understand their experiences and challenges when adopting the new technology. The insights gained from this evaluation include feedback on the integration process, performance improvements observed in real-world scenarios, and suggestions for further enhancements. These insights complement the quantitative results by providing a more holistic view of the solution's impact. ...
  For other subjects, we could have conducted user studies or interviews to gather qualitative feedback on the usability and effectiveness of the solution on X people. The main results are ...
]
// ------------------------------------------------------------
//  Conclusions and Key Results
// ------------------------------------------------------------

= #slide-title("Concluzii", "Conclusions")

== #slide-title("Concluzii", "Conclusions")

- Summary of the main findings and contributions of the thesis.
- What are the key takeaways from your work?
- How does your work advance the state of the art in the domain?
- Time: 30 seconds, focus on the most important conclusions and their implications for the field

#speaker-note[
  In conclusion, this thesis presents a novel hardware accelerator design for symmetric cryptographic functions on RISC-V, which achieves significant improvements in performance and security compared to existing solutions. The key contributions include the design of a custom instruction set extension, the implementation of a hardware module for accelerating specific functions, and the development of a software library for interfacing with the hardware. The results demonstrate that our solution can significantly enhance the performance of cryptographic applications while maintaining security against side-channel attacks, thus advancing the state of the art in hardware accelerators for RISC-V.
]

== #slide-title("Lucrări viitoare", "Future Work")

- What are the limitations of your work?
- What are the potential directions for future research or development based on your findings?
- Time: 10 seconds, provide a clear and concise overview of the limitations and future work. Don't talk more than the conclusions, it will show that you left more work for the future than you actually did in the thesis.

#speaker-note[
  While this thesis makes significant contributions to the design of hardware accelerators for symmetric cryptographic functions on RISC-V, there are some limitations that can be addressed in future work. For example, the current implementation focuses on a specific set of cryptographic functions, and future research could explore extending the accelerator to support a wider range of functions or algorithms. Additionally, further optimization techniques could be investigated to enhance performance and reduce power consumption even further. 
]

== #slide-title("Rezultatele cele mai importante", "Most Important Results")

- Instead of a summary, you can choose to highlight the most important results of your thesis in a more visual way (e.g., with a figure or table).
- It is better to have the last slide with a strong visual that leaves a lasting impression on the audience, rather than just text for the QA.
- QA time.

#speaker-note[
  To summarize the most important results of this thesis, we can refer to the main experimental results shown in the table. The proposed hardware accelerator achieved a TODO% improvement in latency and a TODO% improvement in throughput compared to the software implementation. These results highlight the effectiveness of our solution and its potential impact on the performance of cryptographic applications on RISC-V.
]



// ------------------------------------------------------------
//  Backup / Appendix slides
// ------------------------------------------------------------

#show: appendix

= #slide-title("Anexe", "Appendix")

== #slide-title("Detalii suplimentare", "Additional Details")

- Slide with additional details, results, or backup information that may be useful during the Q&A session.
- This slide can be used to address specific questions from the audience or to provide more in-depth information about certain aspects of the thesis that were not covered in the main presentation.
- Time: This slide is not part of the main presentation, but it can be used during the Q&A session as needed.