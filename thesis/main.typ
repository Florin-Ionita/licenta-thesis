// ============================================================
//  Template Lucrare de Diplomă / Thesis Template
//  Facultatea de Automatică și Calculatoare
//  UNSTPB (Politehnica București)
//  Adaptat după modelul oficial 2024
// ============================================================

#import "config.typ": *

#let rosu = rgb("#C00000")
#let lightblue = rgb("#2e74b5")


// ---------- Page settings (no default number) ----------
#set page(
  paper:        "a4",
  margin:       (left: 3cm, right: 2.5cm, top: 2.54cm, bottom: 2.54cm),
  numbering:    none,
  number-align: center,
)


// ---------- Font and paragraph ----------
#set text(
  font:   "Times New Roman",
  size:   12pt,
  lang:   language,
)

#set par(
  justify: true,
  leading: 0.65em,
  spacing: 1.2em,
)


// ---------- Headings manually numbered in title ----------
#show heading.where(level: 1): it => {
  set text(size: 20pt, weight: "bold")
  set par(justify: false)
  v(1.2em, weak: true)
  it.body
  v(0.6em, weak: true)
}

#show heading.where(level: 2): it => {
  set text(size: 16pt, weight: "bold")
  set par(justify: false)
  v(0.8em, weak: true)
  it.body
  v(0.4em, weak: true)
}

#show heading.where(level: 3): it => {
  set text(size: 14pt, weight: "bold")
  set par(justify: false)
  v(0.6em, weak: true)
  it.body
  v(0.3em, weak: true)
}


// ---------- Figures: captions BELOW, italic ----------
#show figure.where(kind: image): it => {
  v(0.5em)
  align(center, it.body)
  v(0.3em)
  align(
    center,
    text(style: "italic")[#t("figure_prefix") #it.counter.display(). #it.caption.body],
  )
  v(0.8em)
}


// ---------- Tables: captions ABOVE, italic ----------
#show figure.where(kind: table): it => {
  v(0.5em)
  align(
    center,
    text(style: "italic")[#t("table_prefix") #it.counter.display(). #it.caption.body],
  )
  v(0.3em)
  align(center, it.body)
  v(0.8em)
}


// ---------- Code: Courier New 10pt ----------
#show raw.where(block: true): it => {
  set text(font: "Courier New", size: 10pt)
  block(width: 100%, inset: (x: 1em, y: 0.5em), it)
}
#show raw.where(block: false): it => {
  set text(font: "Courier New", size: 10pt)
  it
}


// ============================================================
//  TITLE PAGE
// ============================================================
#align(center)[
  // Top: one-column grid, two rows.
  #grid(
    columns: (1fr,),
    row-gutter: 0.5cm,
    align: (center,),

    // --- Upper row: only middle logo ---
    align(center + horizon)[
      #image(university_logo_path(), height: 2cm, fit: "contain")
    ],

    // --- Lower row: original 3-column layout ---
    grid(
      columns: (2cm, 1fr, 2cm),
      column-gutter: 0.5cm,
      align: (center + horizon, center, center + horizon),

      // Left logo: faculty logo (fixed)
      image("../logos/fac_acs/acc_logo.svg", height: 2cm, fit: "contain"),

      // Center text: department, faculty, university
      align(center + horizon)[
        #set par(leading: 0.4em, spacing: 0em)
        #text(size: 10pt, weight: "bold", fill: lightblue)[#department_name()] \
        #text(size: 10pt, weight: "bold")[#t("label_faculty")] \
        #text(size: 10pt, weight: "bold")[#t("label_university")] \
        #text(size: 10pt, weight: "bold")[#t("label_university_short")]
      ],

      // Right logo: department-specific, language-specific
      image(department_logo_path(), width: 3.5cm, fit: "contain"),
    ),
  )

  #v(3.5cm)

  // Document type: Lucrare de diplomă / Bachelor Thesis / etc.
  #text(size: 20pt, weight: "bold")[#doc_kind()]

  #v(1.2cm)

  // Thesis title
  #text(size: 20pt, weight: "bold")[#thesis_title]

  #v(1fr)

  #grid(
    columns: (1fr, 1fr),
    align:   (left, right),
    [
      #text(size: 16pt)[#t("label_supervisor")] \
      #text(size: 16pt)[#t("label_supervisor_title") #supervisor]
    ],
    [
      #text(size: 16pt)[#t("label_student")] \
      #text(size: 16pt)[#student]
    ],
  )

  #v(2cm)

  #text(size: 16pt, weight: "bold")[#year]
  #v(2cm)
]

// ============================================================
//  Table of Contents
// ============================================================

#pagebreak()

#outline(
  title:  [
    *#t("label_toc")*
    #v(0.5em)
  ],
  indent: 1.5em,
  depth:  3,
)


// ============================================================
//  Actual content - page number starting from 1
// ============================================================

#pagebreak()
#set page(numbering: "1", number-align: right)
#counter(page).update(1)


// ============================================================
//  Abstract / Rezumat
// ============================================================

= #t("label_abstract")

_[#t("placeholder_fill_chapter")]_



// ============================================================
//  1. Introducere / Introduction
// ============================================================

= 1. #t("ch_intro")

_[#t("placeholder_fill_chapter")]_


// ============================================================
//  2. Fundament teoretic / Theoretical background
// ============================================================

= 2. #t("ch_theory")

_[#t("placeholder_fill_chapter")]_


// ============================================================
//  3. Arhitectură / Architecture
// ============================================================

= 3. #t("ch_arch")

_[#t("placeholder_fill_chapter")]_


// ============================================================
//  4. Implementare / Implementation
// ============================================================

= 4. #t("ch_impl")

_[#t("placeholder_fill_chapter")]_

== 4.1. s1

_[#t("placeholder_fill_section")]_

== 4.2. s2

_[#t("placeholder_fill_section")]_

== 4.3. s3

_[#t("placeholder_fill_section")]_


// ============================================================
//  5. Evaluare / Evaluation
// ============================================================

= 5. #t("ch_eval")

_[#t("placeholder_fill_chapter")]_


// ============================================================
//  6. Discuții / Discussion
// ============================================================

= 6. #t("ch_discussion")

_[#t("placeholder_fill_chapter")]_


// ============================================================
//  7. Concluzii / Conclusions
// ============================================================

= 7. #t("ch_conclusions")

_[#t("placeholder_fill_chapter")]_


// ============================================================
//  Bibliografie / References
//  IMPORTANT: #bibliography generates the title automatically —
//  we pass a localized title here.
// ============================================================

#bibliography(
  "refs.bib",
  title: [#t("label_bibliography")],
  style: "ieee",
)


// ============================================================
//  Anexe / Appendices
// ============================================================

= #t("label_appendices")

_[#t("placeholder_appendix_note")]_