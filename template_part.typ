// ============================================================
// Flywheel Rotor Fatigue Life & Dynamic Reliability Assessment
// IEEE-Style Engineering Report — Typst v0.13
// ============================================================

// ---- Page Layout ----
#set page(
  paper: "a4",
  margin: (top: 25mm, bottom: 25mm, left: 22mm, right: 22mm),
  numbering: "1",
  header: context {
    if counter(page).get().first() > 1 {
      set text(size: 8pt, fill: luma(100))
      line(length: 100%, stroke: 0.5pt)
      v(2pt)
      align(left)[
        #smallcaps("Flywheel Rotor Fatigue Life Assessment")
        #h(1fr)
        #counter(page).display()
      ]
    }
  },
)

// ---- Typography ----
#set text(font: ("New Computer Modern"), size: 10pt, lang: "en")
#set par(justify: true, leading: 0.65em, first-line-indent: 1.5em)

// ---- Headings ----
#set heading(numbering: "1.1")
#show heading.where(level: 1): it => {
  v(1.2em)
  set text(size: 11pt, weight: "bold")
  set par(first-line-indent: 0pt)
  smallcaps(it)
  v(0.3em)
  line(length: 100%, stroke: 0.4pt)
  v(0.3em)
}
#show heading.where(level: 2): it => {
  v(0.8em)
  set text(size: 10pt, weight: "bold")
  set par(first-line-indent: 0pt)
  it
  v(0.2em)
}
#show heading.where(level: 3): it => {
  v(0.5em)
  set text(size: 10pt, style: "italic")
  set par(first-line-indent: 0pt)
  it
  v(0.1em)
}

// ---- Math ----
#set math.equation(numbering: "(1)")

// ---- Figures & Tables ----
#set figure(numbering: "1")
#set table(stroke: 0.5pt, inset: 4pt, align: center + horizon)

// ---- Code ----

// ---- Bibliography ----
#show bibliography: it => {
  v(1em)
  set heading(numbering: none)
  set text(size: 9pt)
  [#smallcaps("References")]
  v(0.3em)
  line(length: 100%, stroke: 0.4pt)
  v(0.3em)
  it
}


// ============================================================
// TITLE PAGE
// ============================================================
#align(center, v(2cm))
#set text(size: 14pt, weight: "bold")
#smallcaps("Flywheel Rotor Fatigue Life & Dynamic Reliability Assessment")

#v(0.3cm)
#set text(size: 11pt)
#smallcaps("for AI Mega-Cluster DC-Bus Systems")

#v(0.6cm)
#set text(size: 10pt, weight: "regular")
Technical Engineering Report \
Date: 2026-05-21 \
Material: 25Cr2Ni4MoV | Max Speed: 20,000 rpm | 800V DC Bus | SiC DC/DC + SST

#v(0.8cm)
#line(length: 60%, stroke: 0.6pt)

#v(0.5cm)
#set text(size: 9pt)
#align(center)[
  *Abstract* — This report presents a comprehensive fatigue life and dynamic reliability
  assessment of a 25Cr2Ni4MoV forged steel flywheel rotor ($phi$430 mm, 20,000 rpm)
  for AI mega-cluster GPU data center applications. Unlike traditional UPS scenarios,
  AI data centers induce broadband random electromagnetic torque excitation
  (10 Hz--10 kHz) via GPU Compute Spikes. A full-chain coupling fatigue analysis
  framework is established. Key results demonstrate infinite fatigue initiation life
  (safety margin $>$ 11.8$times$) and bounded crack propagation
  ($Delta K = 1.38 "MPa"·m^(1/2)$ vs. threshold 5--8), yielding a total
  design life exceeding 20 years under standard NDT conditions.
]

#v(0.3cm)
#set text(size: 9pt)
#align(center)[
  *Keywords* — flywheel energy storage, AI data center, rotor fatigue,
  25Cr2Ni4MoV, dynamic reliability, broadband random excitation
]

#pagebreak()

// ============================================================
// TABLE OF CONTENTS
// ============================================================
#outline(title: [#smallcaps("Contents")])

