#import "src/preamble.typ":*
#let chapter(filename) = {
  include filename
  pagebreak(weak: true)
}

#show: evan.with(
  title: "Intro to Programmable Cryptography",
  subtitle: "Notes from a spring 2024 reading group",
  author: "0xPARC",
  date: datetime.today(),
)

#toc
#pagebreak()

#chapter("src/frontmatter.typ")
#chapter("src/intro.typ")

#heading(numbering: none)[zkSNARK constructions]
#chapter("src/h-zksnark.typ")
#chapter("src/ec.typ")
#chapter("src/kzg.typ")
#chapter("src/ipa.typ")
#chapter("src/plonk.typ")
#chapter("src/groth16.typ")

#heading(numbering: none)[Multi-party computation and garbled circuits]
#chapter("src/h-mpc.typ")
#chapter("src/mpc.typ")

#heading(numbering: none)[Classical PCP]
#chapter("src/h-classical-pcp.typ")
#chapter("src/sumcheck.typ")
#chapter("src/pcp.typ")

#heading(numbering: none)[Appendix]
#chapter("src/backmatter.typ")
