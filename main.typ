#import "src/preamble.typ":*
#let chapter(filename) = {
  include filename
  pagebreak()
}


#show: evan.with(
  title: "Topics in Programmable Cryptography",
  subtitle: "Notes from a spring 2024 reading group",
  author: "0xPARC",
  date: datetime.today(),
)

#toc
#pagebreak()

#chapter("src/frontmatter.typ")
#chapter("src/sumcheck.typ")
#chapter("src/pcp.typ")
#chapter("src/ec.typ")
#chapter("src/kzg.typ")
#chapter("src/ipa.typ")
#chapter("src/mpc.typ")
