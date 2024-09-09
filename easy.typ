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
  title: "Four Easy Pieces in Programmable Cryptography",
  long-title: [Four Easy Pieces in \ Programmable \ Cryptography],
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

#authoredpart[Introduction][Brian Gu and Yan X Zhang]
#chapter("src/intro.typ")

#authoredpart[Two-party Computation][Brian Gu and Brian Lawrence]
#chapter("src/mpc.typ")
#chapter("src/ot.typ")
#chapter("src/2pc-takeaways.typ")

#authoredpart[SNARKs Prelude: Elliptic Curves and Polynomial Commitments][Evan Chen]
#chapter("src/ec.typ")
#chapter("src/pair.typ")
#chapter("src/kzg.typ")
#chapter("src/kzg-takeaways.typ")

#authoredpart[SNARKs][Evan Chen]
#chapter("src/zkintro.typ")
#chapter("src/plonk.typ")
#chapter("src/copy-constraints.typ")
#chapter("src/fs.typ")
#chapter("src/snark-takeaways.typ")

#authoredpart[Fully Homomorphic Encryption][Brian Lawrence and Yan X Zhang]
#chapter("src/fhe0.typ")
#chapter("src/lwe.typ")
#chapter("src/fhe2.typ")
#chapter("src/fhe3.typ")
#chapter("src/fhe-takeaways.typ")

#authoredpart[Oblivious RAM][Elaine Shi]
#chapter("src/oram.typ")
#chapter("src/oram-takeaways.typ")