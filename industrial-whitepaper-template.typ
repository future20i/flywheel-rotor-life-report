// ============================================================
// Typst Industrial Whitepaper Template — 现代极简工业风
// 技术报告 / 科技白皮书风格排版模板
// 使用说明: 
//   1. #import "industrial-whitepaper-template.typ": *
//   2. #show: industrial-whitepaper.with(...)
//   3. 写正文内容
// ============================================================
// Font stack:
//   - 英文+数字: Inter / Noto Sans (system sans fallback)
//   - 中文: Noto Sans CJK SC (思源黑体SC)
//   - 代码: JetBrains Mono
//   - 数学: Fira Math (无衬线数学字体)

// ============================================================
// 模版函数
// ============================================================
#let industrial-whitepaper(
  // ---- 页面基础 ----
  margin: (top: 30mm, bottom: 25mm, left: 30mm, right: 30mm),

  // ---- 封面 ----
  cover-title: "报告标题",
  cover-subtitle: none,
  cover-meta: (),

  // ---- 正文 ----
  font-size: 10pt,
  leading: 1.6,
  par-spacing: 7pt,

  // ---- 颜色 ----
  accent-color: rgb("#1A365D"),
  text-color: rgb("#1A202C"),
  meta-color: rgb("#718096"),
  border-color: rgb("#333333"),

  // ---- 标题 ----
  h1-size: 12pt,
  h2-size: 10.5pt,
  h3-size: 10pt,

  // ---- 数学 ----
  math-font: "Fira Math",
  eq-above: 8pt,
  eq-below: 8pt,

  // ---- 代码 ----
  code-bg: rgb("#F7FAFC"),
  code-accent: rgb("#3182CE"),
  code-size: 9pt,

  // ---- 表格 ----
  table-top-width: 1.2pt,
  table-header-width: 0.5pt,
  table-bottom-width: 1.2pt,

  body,
) = {
  // ============================================================
  // PAGE SETUP
  // ============================================================
  set page(
    paper: "a4",
    margin: margin,
    numbering: "01",
    header: context {
      let p = counter(page).get().first()
      if p > 1 {
        set text(size: 8.5pt, fill: meta-color)
        if calc.even(p) {
          align(left)[飞轮转子结构完整性论证报告]
        } else {
          align(right)[转子结构完整性论证]
        }
      }
    },
    footer: context {
      let p = counter(page).get().first()
      if p > 1 {
        set text(size: 9pt, fill: meta-color)
        align(center + bottom)[#counter(page).display("01")]
      }
    },
  )

  // ============================================================
  // TYPOGRAPHY
  // ============================================================
  set text(
    font: ("Noto Sans CJK SC", "Liberation Sans"),
    size: font-size,
    fill: text-color,
    lang: "zh",
  )
  set par(
    justify: true,
    leading: leading * font-size,
    first-line-indent: 0pt,
  )

  // 段后距 — 替代首行缩进
  set par(spacing: par-spacing)

  // ============================================================
  // HEADINGS
  // ============================================================
  set heading(numbering: "1.")

  show heading.where(level: 1): it => {
    v(1.5em)
    set text(size: h1-size, weight: 800)
    set block(spacing: 0pt)
    set par(first-line-indent: 0pt)
    it
    v(0.4em)
    line(length: 100%, stroke: 0.5pt + border-color)
    v(0.6em)
  }

  show heading.where(level: 2): it => {
    v(1em)
    set text(size: h2-size, weight: "bold")
    set block(spacing: 0pt)
    set par(first-line-indent: 0pt)
    it
    v(0.25em)
  }

  show heading.where(level: 3): it => {
    v(0.6em)
    set text(size: h3-size, weight: "semibold")
    set block(spacing: 0pt)
    set par(first-line-indent: 0pt)
    it
    v(0.15em)
  }

  // ============================================================
  // MATH — 无衬线数学公式 (Fira Math)
  // ============================================================
  set math.equation(numbering: "(1)")

  show math.equation.where(block: true): it => {
    v(eq-above)
    set text(font: math-font, size: font-size)
    it
    v(eq-below)
  }

  show math.equation.where(block: false): it => {
    set text(font: math-font)
    it
  }

  // ============================================================
  // TABLES — 三线表
  // ============================================================
  show table: it => {
    set table(
      stroke: none,
      inset: 5pt,
    )
    it
  }

  show table.header: it => {
    set text(weight: "bold")
    it
    table.cell(stroke: (bottom: table-header-width + border-color), fill: none)[]
  }

  // ============================================================
  // CODE BLOCKS — 左侧科技蓝竖线
  // ============================================================
  show raw.where(block: true): it => {
    set block(
      fill: code-bg,
      inset: (left: 16pt, right: 12pt, top: 10pt, bottom: 10pt),
    )
    set text(font: ("JetBrains Mono", "Cascadia Code", "SF Mono"), size: code-size)
    rect(
      width: 100%,
      stroke: (left: 2pt + code-accent),
      fill: code-bg,
      inset: (left: 14pt, right: 8pt, top: 6pt, bottom: 6pt),
    )[#it]
  }

  // ============================================================
  // COVER PAGE
  // ============================================================
  set page(margin: margin, header: none, footer: none)
  v(5cm)

  set text(size: 30pt, weight: 800, fill: text-color)
  align(left)[#cover-title]

  v(0.3cm)
  line(length: 15%, stroke: 0.5pt + border-color)

  if cover-subtitle != none {
    v(0.5cm)
    set text(size: 14pt, weight: "regular", fill: meta-color)
    align(left)[#cover-subtitle]
  }

  v(1fr)

  set text(size: 10pt, weight: "regular")
  align(left)[
    #for (k, v) in cover-meta [
      #k: #v \
    ]
  ]

  pagebreak()

  // ============================================================
  // TABLE OF CONTENTS
  // ============================================================
  set page(header: none, footer: none)
  outline(title: [
    #set text(size: h1-size, weight: 800)
    目录
  ])

  pagebreak()

  // ============================================================
  // BODY CONTENT (with headers/footers)
  // ============================================================
  set page(header: context {
    let p = counter(page).get().first()
    if p > 1 {
      set text(size: 8.5pt, fill: meta-color)
      if calc.even(p) {
        align(left)[飞轮转子结构完整性论证报告]
      } else {
        align(right)[转子结构完整性论证]
      }
    }
  }, footer: context {
    let p = counter(page).get().first()
    if p > 1 {
      set text(size: 9pt, fill: meta-color)
      align(center + bottom)[#counter(page).display("01")]
    }
  })

  body
}

// ============================================================
// 辅助函数：表格底线
// ============================================================
#let tbl-bottom(span) = {
  table.cell(
    stroke: (top: 1.2pt + rgb("#333333")),
    colspan: span,
  )[]
}
