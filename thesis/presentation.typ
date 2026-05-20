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

- Domeniul lucrării / Thesis domain.
- Contextul aplicativ (industrie, cercetare, laborator).
- Sisteme / abordări existente relevante.
- Poziționarea lucrării în acest context.

// ------------------------------------------------------------
//  Problem and Importance
// ------------------------------------------------------------

= #slide-title("Problema abordată", "Problem and Motivation")

== #slide-title("Problema abordată", "Problem Statement")

- Ce problemă specifică este abordată.
- Inputuri, outputuri, constrângeri.
- Cerințe de performanță / timp real / scalabilitate.
- Mediul țintă (embedded, cloud, HPC etc.).

== #slide-title("Importanța problemei", "Why Is This Important?")

- Impactul rezolvării problemei (performanță, cost, fiabilitate).
- Cine beneficiază (utilizatori, clienți, cercetare).
- Limitările soluțiilor existente.
- Motivație pentru soluția propusă în teză.

// ------------------------------------------------------------
//  Proposed Solution & Architecture
// ------------------------------------------------------------

= #slide-title("Soluția propusă", "Proposed Solution")

== #slide-title("Prezentare generală a soluției", "Solution Overview")

- Ideea de bază a soluției.
- Ce aduce nou față de abordările existente.
- Obiective cheie (ex: throughput mai mare, latență mai mică).
- Scopul general al implementării.

== #slide-title("Arhitectura sistemului", "System Architecture")

- Componente principale și responsabilitățile lor.
- Fluxul de date între componente.
- Interfețe (API, protocoale, mesaje).
- Puncte cheie de extensibilitate și integrare.

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

- Limbaje și tehnologii folosite (ex: C++, Docker, etc.).
- Biblioteci și framework-uri (ex: gRPC, Boost, etc.).
- Model de concurență (threading, async, actor model).
- Decizii privind deploy (containere, orchestrare, CI/CD).

== #slide-title("Flux de date și interfețe", "Data Flow and Interfaces")

- Modul de configurare (fișiere, variabile de mediu, CLI).
- Tipuri de mesaje / structuri de date.
- Gestionarea erorilor și logării.
- Considerații de securitate (autentificare, autorizare, izolare).

// ------------------------------------------------------------
//  Evaluation and Results
// ------------------------------------------------------------

= #slide-title("Evaluare și rezultate", "Evaluation and Results")

== #slide-title("Setup de evaluare", "Evaluation Setup")

- Platforma hardware (CPU, GPU, memorie, rețea).
- Seturi de date / generatoare de trafic.
- Metodologie de testare (număr de rulari, condiții).
- Metrici de evaluare (throughput, latență, utilizare resurse).

== #slide-title("Rezultate cantitative I", "Quantitative Results I")

- Rezultate numerice principale (ex: TPS, ms, utilizare CPU).
- Comparație cu baseline / soluții existente.
- Tabel de rezultate (placeholder).

#figure(
  table(
    columns: 4,
    align: center,
    table.header(
      [*Scenariu*], [*Măsură*], [*Valoare*], [*Referință/Baseline*],
    ),
    ["Scenario 1"], ["Latency (ms)"], ["TODO"], ["TODO"],
    ["Scenario 2"], ["Throughput (req/s)"], ["TODO"], ["TODO"],
  ),
  caption: [#slide-title("Rezultate experimentale principale", "Main Experimental Results")],
)

== #slide-title("Rezultate cantitative II", "Quantitative Results II")

- Rezultate detaliate pe scenarii suplimentare.
- Sensibilitate la parametri (load, dimensiune mesaje).
- Compararea mai multor configurații ale sistemului.

== #slide-title("Evaluare calitativă", "Qualitative Evaluation")

- Feedback de la utilizatori / colegi / supervizor.
- Cazuri de utilizare reprezentative.
- Limitări observate în practică.
- Posibile direcții de îmbunătățire.

// ------------------------------------------------------------
//  Conclusions and Key Results
// ------------------------------------------------------------

= #slide-title("Concluzii", "Conclusions")

== #slide-title("Concluzii", "Conclusions")

- Ce a realizat teza, în termeni concreți.
- Cum se raportează rezultatele la obiectivele inițiale.
- Ce lecții tehnice au fost învățate.
- Care sunt limitele actuale ale soluției.

== #slide-title("Lucrări viitoare", "Future Work")

- Îmbunătățiri planificate sau posibile.
- Extensii spre alte domenii / scenarii.
- Idei de publicații sau proiecte viitoare.

== #slide-title("Rezultatele cele mai importante", "Most Important Results")

- Rezultat 1: descriere foarte scurtă + metrica cheie.
- Rezultat 2: descriere foarte scurtă + metrica cheie.
- Rezultat 3: descriere foarte scurtă + metrica cheie.
- Un mesaj de închidere / „take-home message”.



// ------------------------------------------------------------
//  Backup / Appendix slides
// ------------------------------------------------------------

#show: appendix

= #slide-title("Anexe", "Appendix")

== #slide-title("Detalii suplimentare", "Additional Details")

- Slide-uri de rezervă pentru întrebări.
- Detalii de implementare sau rezultate suplimentare.