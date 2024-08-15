#import "src/preamble.typ":*
#let chapter(filename) = {
  include filename
  pagebreak(weak: true)
}
#let part(s) = {
  set text(size:1.4em, fill: rgb("#002299"))
  heading(numbering: none, s)
}

#show: evan.with(
  title: "More Topics in Programmable Cryptography",
  author: "0xPARC",
  date: datetime.today(),
)

#quote(attribution: [gubsheep introducing progcrypto to Evan for the first time])[
  Evan, I can now prove to you that I have a message $M$ such that
  $op("sha")(M) = "0xa91af3ac..."$, without revealing $M$.
  But not just for SHA. I can do this for any function you want.
]

#toc
#pagebreak()

#chapter("src/frontmatter.typ")
#chapter("src/intro.typ")

#part[zkSNARK constructions]
#chapter("src/h-zksnark.typ")
#chapter("src/ec.typ")
#chapter("src/pair.typ")
#chapter("src/kzg.typ")
#chapter("src/ipa.typ")
#chapter("src/plonk.typ")
#chapter("src/groth16.typ")
#chapter("src/cq.typ")

#part[Multi-party computation and garbled circuits]
#chapter("src/h-mpc.typ")
#chapter("src/mpc.typ")

#part[Fully homomorphic encryption]
#chapter("src/h-fhe.typ")

#part[Appendix: Classical PCP]
#chapter("src/h-classical-pcp.typ")
#chapter("src/sumcheck.typ")
#chapter("src/pcp.typ")
