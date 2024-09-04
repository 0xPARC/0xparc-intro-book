#import "src/preamble.typ":*
#set page(
  width: 5.5in,
  height: 8.5in,
  margin: (inside: 0.6in, outside: 0.6in, top: 0.8in, bottom: 0.5in),
  header-ascent: 40%,
)

#let chapter(filename) = {
  include filename
}

#show: evan.with(
  title: "Three Easy Pieces in Programmable Cryptography",
  long-title: [Three Easy Pieces in \ Programmable \ Cryptography],
  author: "0xPARC",
  date: datetime.today(),
)

#v(4em)

#quote[
  I can prove to you that I have a message $M$ such that
  $sha(M) = "0xa91af3ac..."$, without revealing $M$.
  But not just for the hash function sha.
  I can do this for any function you want.
]

#pagebreak()

#toc
#pagebreak()

#set heading(offset: 1)

#part[Introduction]
#chapter("src/intro.typ")

#part[Two-party Computation]
#chapter("src/mpc.typ")
#chapter("src/ot.typ")
#chapter("src/2pc-takeaways.typ")

#part[SNARKs Prelude: Elliptic Curves and Polynomial Commitments]
#chapter("src/ec.typ")
#chapter("src/pair.typ")
#chapter("src/kzg.typ")
#chapter("src/kzg-takeaways.typ")

#part[SNARKs]
#chapter("src/zkintro.typ")
#chapter("src/plonk.typ")
#chapter("src/copy-constraints.typ")
#chapter("src/fs.typ")
#chapter("src/snark-takeaways.typ")

#part[Fully Homomorphic Encryption]
#chapter("src/fhe0.typ")
#chapter("src/lwe.typ")
#chapter("src/fhe2.typ")
#chapter("src/fhe3.typ")
#chapter("src/fhe-takeaways.typ")

#part[Oblivious RAM]
#chapter("src/oram.typ")