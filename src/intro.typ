#import "preamble.typ":*

= Introduction

#quote(attribution: [gubsheep introducing progcrypto to Evan for the first time])[
  Evan, I can now prove to you that I have a message $M$ such that
  $op("sha256")(M) = "0xa948904f..."$, without revealing $M$.
  But not just for SHA. I can do this for any function you want.
]

== What is programmable cryptography?

Cryptography is everywhere now and needs no introduction.
"Programmable cryptography" is a term coined by 0xPARC for a second-generation
of cryptographic primitives that have arisen in the last 15 or so years.

To be concrete, let's consider two examples of what protocols designed by
classical cryptography can achieve:

- _Proofs_. An example of this is digital signature algorithms like RSA,
  where Alice can do some protocol to prove to Bob that a message was sent by her.
  A more complicated example might be a
  #link("https://w.wiki/9fXW", "group signature scheme"),
  allowing one member of a group to sign a message on behalf of a group.

- _Hiding inputs_: for example, consider
  #link("https://w.wiki/9fXQ", "Yao's millionaire problem"),
  where Alice and Bob wants to know which of them has more money
  without learning the actual incomes.

Classically, first-generation cryptography relied on coming up for a protocol
for solving given problems or computing certain functions.
The goal of the second-generation "programmable cryptography" can
then be described as:

#quote[
  We want to devise cryptographic primitives that could
  be programmed to work on *arbitrary* problems and functions,
  rather than designing protocols on a per-problem or per-function basis.
]

To draw an analogy, it's sort of like going from older single-purpose hardware,
like a digital alarm clock or thermostat,
to having a general-purpose device like a smartphone which can
do any computation so long as someone writes code for it.
The quote shown at the start of this section about SHA256 is a concrete example;
the hash function SHA256 is a particular set of arbitrary instructions,
yet programmable cryptography promises that such a proof can be made
without having to invent a "new" algorithm per function.

#todo[Brian's image of an alarm clock and a computer chip]

== Ideas in programmable cryptography

These notes focus on the following specific topics.

=== The zkSNARK: proofs of general problems

The *zkSNARK*, first described in 2012, was the first type of primitive
that arguably falls into the "programmable cryptography" umbrella.
It provides a way to produce proofs of _arbitrary_ problem statements,
at least once encoded as a system of equations in a certain way.
The name stands for:

- *Zero-knowledge*: a person reading the proof doesn't learn anything
  about the solution besides that it's correct.
- *Succinct*: the proof length is short (actually constant length).
- *Non-interactive*: the protocol is not interactive.
- *Argument of Knowledge*: a six-syllable synonym for "proof" that makes the
  acronym "SNARK" cuter and allows us to quote
  #link("https://w.wiki/9fY8", "Lewis Carroll") repeatedly.

So, you can think of these as generalizing something like a group signature
scheme to authenticating any sort of transaction:

- A normal signature scheme is a (zero-knowledge, succinct, non-interactive)
  proof that "I know Alice's private key".
- A group signature scheme can be construed as a succinct proof that
  "I know one of Alice, Bob, or Charlie's private keys".
- But you could also use a zkSNARK to prove a statement like
  "I know a message $M$ such that $sha(M) = "0x91af3ac..."$",
  of course without revealing $M$ or anything about $M$.
- ... Or really any arbitrarily complicated statement.

#todo[gubsheep's slide had a funny example with emoji, link it]

These notes focus on two constructions, PLONK (@plonk) and Groth16 (@groth16).

=== Multi-party computation (MPC)

A *multi-party computation*, in which $n >= 2$ people want to
jointly compute some known function
$ F(x_1, ..., x_n) $
where the $i$th person only knows the input $x_i$
and does not learn the other inputs.

For example, we saw earlier Yao's millionaire problem --- Alice and Bob
want to know who has a higher income without revealing the incomes themselves.
This is the case where $n=2$, $F = max$, and $x_i$ is the $i$'th person's income.

Multi-party computation makes a promise that we'll be able to do this
for _any_ function $F$ as long as we implement it in code.

=== Fully homomorphic encryption (FHE)

#todo[Needs writing.]

== Where these fit together

#todo[Brian's tree. Talk about reduction?]

== What's all the fuss about zero-knowledge anyhow?

#figure(
  image("../figures/care-about.png", width:90%),
  caption: [Expectations vs. reality.]
)
