#import "src/preamble.typ":*
#let chapter(filename) = {
  include filename
}
#show: evan.with(
  title: "Notes on Programmable Cryptography",
  author: "0xPARC",
  date: datetime.today(),
)

#quote[
  I can prove to you that I have a message $M$ such that
  $op("sha")(M) = "0xa91af3ac..."$, without revealing $M$.
  But not just for the hash function SHA.
  I can do this for any function you want.
]

#toc
#pagebreak()

#set heading(offset: 1)
#part[Introduction]
#chapter("src/bigbook-frontmatter.typ")
#chapter("src/intro.typ") // needs some rewriting though

#part[Two-party Computation]
#chapter("src/mpc.typ")
#chapter("src/ot.typ")
#chapter("src/2pc-takeaways.typ")

#part[SNARKs Prelude: Elliptic Curves and Polynomial Commitments]
#chapter("src/ec.typ")
#chapter("src/pair.typ")
#chapter("src/kzg.typ")
#chapter("src/kzg-takeaways.typ")

#part[Your first SNARK: The PLONK Protocol]
#chapter("src/zkintro.typ")
#chapter("src/plonk.typ")
#chapter("src/copy-constraints.typ")
#chapter("src/fs.typ")
#chapter("src/snark-takeaways.typ")

#part[Another STARK: GROTH-16]
#chapter("src/ipa.typ")
#chapter("src/groth16.typ")

#part[Binius]
#chapter("src/sumcheck.typ")

#part[Fully Homomorphic Encryption with LWE]
#chapter("src/fhe0.typ")
#chapter("src/lwe.typ")
#chapter("src/fhe2.typ")
#chapter("src/fhe3.typ")
#chapter("src/fhe-takeaways.typ")

#part[Oblivious RAM]

#part[Obfuscation]

#part[Others]
#chapter("src/cq.typ")
