#let tech-report(
  title: "",
  subtitle: "",
  authors: (),
  date: none,
  body
) = {
  // 1. 页面设置（A4，宽边距留白）
  set page(
    paper: "a4",
    margin: (top: 25mm, bottom: 25mm, left: 22mm, right: 22mm),
    
    header: context {
      if counter(page).get().first() > 1 {
        align(right, text(size: 8.5pt, font: ("Inter", "Noto Sans CJK SC"), tracking: 0.5pt, fill: rgb("#718096"), 
          if calc.even(counter(page).get().first()) {
            [飞轮转子寿命评估报告]
          } else {
            [转子寿命与可靠性]
          }
        ))
      }
    },
    
    footer: context {
      if counter(page).get().first() > 1 {
        align(center, text(size: 9pt, font: "Inter", fill: rgb("#718096"), 
          str(counter(page).get().first())
        ))
      }
    }
  )

  // 2. 核心排版
  set text(
    font: ("Inter", "Noto Sans CJK SC"),
    size: 10pt,
    fill: rgb("#222222"),
    tracking: 0.6pt,
    lang: "zh"
  )
  
  set par(
    justify: true,
    leading: 0.8em,
    first-line-indent: 0pt,
  )
  
  // 间距替代缩进
  set par(spacing: 1.4em)

  // 3. 标题样式
  show heading: set text(fill: rgb("#111111"), tracking: 1.2pt)
  show heading.where(level: 1): it => block(above: 2.2em, below: 1.2em)[
    #set text(size: 16pt, weight: "bold")
    #it.body
  ]
  show heading.where(level: 2): it => block(above: 1.6em, below: 0.8em)[
    #set text(size: 12pt, weight: "bold")
    #it.body
  ]

  // 4. 数学公式排版（无衬线公式搭配）
  show math.equation: set text(font: "Fira Math") 
  show math.equation.where(block: true): it => block(spacing: 1.6em, align(center, it))

  // 5. 现代三线表规范
  set table(
    stroke: (x, y) => if y == 0 {
      (top: 1.5pt + rgb("#333333"), bottom: 0.75pt + rgb("#333333"))
    } else if y == 1 {
      (bottom: 0.5pt + rgb("#718096"))
    } else {
      none
    },
    fill: none 
  )
  show table: it => block[
    #it
    #v(-1.2em)
    #line(length: 100%, stroke: 1.5pt + rgb("#333333"))
  ]

  // 6. 代码块美化
  show raw: set text(font: "JetBrains Mono", size: 9pt)
  show raw.where(block: true): it => block(
    fill: rgb("#F7FAFC"),
    inset: 12pt,
    radius: 4pt,
    width: 100%,
    stroke: (left: 2.5pt + rgb("#3182CE")),
    it
  )

  // 7. 极简封面
  page(header: none, footer: none)[
    #v(18%)
    #block(width: 100%, stroke: (bottom: 0.5pt + rgb("#CBD5E0")), inset: (bottom: 24pt))[
      #text(size: 28pt, weight: "black", fill: rgb("#1A202C"), tracking: 1.5pt)[#title] \
      #v(12pt)
      #text(size: 13pt, fill: rgb("#718096"), tracking: 0.8pt)[#subtitle]
    ]
    #v(35%)
    #text(size: 10pt, fill: rgb("#4A5568"), tracking: 0.5pt)[
      #grid(
        columns: (60pt, 1fr),
        row-gutter: 10pt,
        "作者:", authors.join(", "),
        "日期:", if date != none { date } else { datetime.today().display("[year]-[month]-[day]") }
      )
    ]
  ]

  body
}
