#import "src/preamble.typ":*

#let chapter(filename) = {
  include filename
  pagebreak(weak: true)
}
#let part(s) = {
  set text(size:1.4em, fill: rgb("#002299"))
  heading(offset: 0, s)
}

#show: evan.with(
  title: "Three Easy Pieces in Programmable Cryptography",
  author: "0xPARC",
  date: datetime.today(),
)

#quote[
  I can now prove to you that I have a message $M$ such that
  $op("sha")(M) = "0xa91af3ac..."$, without revealing $M$.
  But not just for SHA. I can do this for any function you want.
]

#toc
#pagebreak()


#chapter("src/intro.typ")

#set heading(offset: 1)

#part[Two-party Computation]
#chapter("src/mpc.typ")
#chapter("src/ot.typ")

#part[SNARKs Prelude: Elliptic Curves and Polynomial Commitments]
#chapter("src/ec.typ")
#chapter("src/pair.typ")
#chapter("src/kzg.typ")

#part[SNARKs]
#chapter("src/zkintro.typ")
#chapter("src/plonk.typ")
#chapter("src/fs.typ")

#part[Fully Homomorphic Encryption]
#chapter("src/fhe0.typ")
#chapter("src/lwe.typ")
#chapter("src/fhe2.typ")
#chapter("src/fhe3.typ")


