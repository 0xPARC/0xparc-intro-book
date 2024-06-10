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
  title: "Five Easy Pieces in Programmable Cryptography",
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

#chapter("src/intro.typ")

#part[Oblivious transfer, garbled circuits, and multiparty computation]
#chapter("src/mpc.typ")
#chapter("src/ot.typ")

#part[zkSNARK constructions]
#chapter("src/ec.typ")
#chapter("src/pair.typ")
#chapter("src/kzg.typ")
#chapter("src/plonk.typ")

#part[Levelled fully homomorphic encryption]
#chapter("src/fhe0.typ")
#chapter("src/lwe.typ")
#chapter("src/fhe2.typ")
#chapter("src/fhe3.typ")


