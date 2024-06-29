#let pair = math.op("pair")
#let sha = math.op("hash")
#let msg = math.sans("msg")
#let Com = math.op("Com")
#let Flatten = math.op("Flatten")
#let Enc = math.op("Enc")
#let Dec = math.op("Dec")
#let pk = math.sans("pk")
#let sk = math.sans("sk")
#let Id = math.upright("Id")

// https://github.com/vEnhance/dotfiles/blob/main/typst/packages/local/evan/1.0.0/evan.typ
#import "@preview/ctheorems:1.1.2": *

#let fonts = (
  text: ("Linux Libertine"),
  sans: ("Noto Sans"),
  mono: ("Inconsolata"),
)
#let colors = (
  title: eastern,
  headers: maroon,
)

#let toc = {
  show outline.entry.where(level: 1): it => {
    v(1.2em, weak:true)
    text(weight:"bold", font:fonts.sans, it)
  }
  text(fill:colors.title, size:1.4em, font:fonts.sans, [*Table of contents*])
  v(0.6em)
  outline(
    title: none,
    indent: 2em,
  )
}

#let eqn(s) = {
  set math.equation(numbering: "(1)")
  s
}

#let theorem = thmbox("main", "Theorem", fill: rgb("#ffeeee"), base_level: 1, breakable: true)
#let lemma = thmbox("main", "Lemma", fill: rgb("#ffeeee"), base_level: 1, breakable: true)
#let proposition = thmbox("main", "Proposition", fill: rgb("#ffeeee"), base_level: 1, breakable: true)
#let claim = thmbox("main", "Claim", fill: rgb("#ffeeee"), base_level: 1, breakable: true)
#let definition = thmbox("main", "Definition", fill: rgb("#ddddff"), base_level: 1, breakable: true)
#let example = thmbox("main", "Example", fill: rgb("#ffffdd"), base_level: 1, breakable: true)
#let algorithm = thmbox("main", "Algorithm", fill: rgb("#ddffdd"), base_level: 1, breakable: true)
#let remark = thmbox("main", "Remark", fill: rgb("#eeeeee"), base_level: 1, breakable: true)
#let situation = thmbox("main", "Situation", fill: rgb("#eeeeee"), base_level: 1, breakable: true)

#let problem = thmplain("main", "Problem", base_level: 1)
#let exercise = thmplain("main", "Problem", base_level: 1)

#let todo = thmbox("todo", "TODO", fill: rgb("#ddaa77")).with(numbering: none)
#let gray(body) = block(
    fill: luma(210),
    inset: 8pt,
    radius: 4pt,
    width: 100%,
    [#body]
)

#let green(body) = block(
    fill: rgb("#2ecc40"),
    inset: 8pt,
    radius: 4pt,
    width: 100%,
    [#body]
)

#let proof = thmproof("proof", "Proof")
#let solution = thmproof("proof", "Solution")

#let assumption = thmbox("main", "Assumption", fill: rgb("#eeeeaa"), base_level: 1)
#let goal = thmbox("main", "Goal", fill: rgb("#eeeeaa"), base_level: 1)

#let url(s) = {
  link(s, text(font:fonts.mono, s))
}
#let pmod(x) = $space (mod #x)$

// Main entry point to use in a global show rule
#let evan(
  title: none,
  long-title: none,
  author: none,
  subtitle: none,
  date: none,
  maketitle: true,
  body
) = {
  // Set document parameters
  if (title != none) {
    set document(title: title)
  }
  if (author != none) {
    set document(author: author)
  }

  // General settings
  set page(
    width: 5.5in,
    height: 8.5in,
    margin: auto,
    header: context {
      set align(right)
      set text(size:0.8em)
      if (not maketitle or counter(page).get().first() > 1) {
        text(weight:"bold", title)
        if (author != none) {
          h(0.2em)
          sym.dash.em
          h(0.2em)
          text(style:"italic", author)
        }
      }
    },
    numbering: "1",
  )
  set par(
    justify: true
  )
  set text(
    font:fonts.text,
    size:11pt,
  )

  // Theorem environments
  show: thmrules.with(qed-symbol: $square$)

  // Change quote display
  set quote(block: true)
  show quote: set pad(x:2em, y:0em)
  show quote: it => {
    set text(style: "italic")
    v(-1em)
    it
    v(-0.5em)
  }
  show quote: set align(center)
  show table: set align(center)

  // Section headers
  set heading(numbering: "1.1")
  show heading: it => {
    block([
      #if (it.numbering != none) [
        #text(fill:colors.headers, "§" + counter(heading).display())
        #h(0.2em)
      ]
      #it.body
      #v(0.4em)
    ])
  }
  show heading: set text(font:fonts.sans, size: 11pt)
  show heading.where(level: 1): set text(size: 16pt)
  show heading.where(level: 2): set text(size: 13pt)

  // Hyperlinks in blue text
  show link: it => {
    if (type(it.dest) == "label") {
      set text(fill:red)
      it
    } else {
      set text(fill:blue)
      it
    }
  }
  show ref: it => {
    if (it.supplement == auto) {
      link(it.target, it)
    } else {
      link(it.target, it.supplement)
    }
  }

  // Title page, if maketitle is true
  if maketitle {
    v(2.5em)
    set align(center)
    set block(spacing: 2em)
    block(text(fill:colors.title, size:2em, font:fonts.sans, weight:"bold",
      if long-title != none { long-title } else { title }
    ))
    if (subtitle != none) {
      block(text(size:1.5em, font:fonts.sans, weight:"bold", subtitle))
    }
    if (author != none) {
      block(smallcaps(text(size:1.7em, author)))
    }
    if (type(date) == "datetime") {
      block(text(size:1.2em, date.display("[day] [month repr:long] [year]")))
    }
    else if (date != none) {
      block(text(size:1.2em, date))
    }
    v(1.5em)
  }
  body
}
