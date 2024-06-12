#import "preamble.typ":*

// copied from bigger project, edit into this one

= Introduction

== What is programmable cryptography?

Cryptography is everywhere now and needs no introduction.
"Programmable cryptography" is a term coined by 0xPARC for a second generation
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

The quote on the title page
("I have a message $M$ such that $op("sha")(M) = "0x91af3ac..."$")
is a concrete example;
the hash function SHA is a particular set of arbitrary instructions,
yet programmable cryptography promises that such a proof can be made
using a general compiler rather than inventing an algorithm specific to SHA256.

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
- *Argument*: technically not a "proof," but we won't worry about the difference.
- *of Knowledge*: the proof doesn't just show the system of equations has a solution;
  it also shows that the prover knows one.

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

These notes focus on a construction called PLONK (@plonk).

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

In *fully homomorphic encryption*, one person encrypts some data $x$,
and then anybody can perform arbitrary operations on the encrypted data $x$
without being able to read $x$.

For example, imagine you have some private text that you want to
translate into another language.
You encrypt the text and feed it to your favorite FHE machine translation server.
You decrypt the server's output and get the translation.
The server only ever sees encrypted text,
so the server learns nothing about the text you translated.

== Where these fit together

ZkSNARKS, MPC, and FHE are just some of a huge zoo of cryptographic primitives,
from the elementary (public-key cryptography)
to the impossibly powerful (indistinguishability obfuscation).
There are protocols for zkSNARKS, MPC and FHE;
they are very slow, but they can be implemented and used in practice.

This whole field is an active area of research.
On the one hand: Can we make existing tools (zkSNARKS, etc.) more efficient?
For example, the cost of doing a computation in zero knowledge
is currently about $10^6$ times the cost of doing the computation directly.
Can we bring that number down?
On the other hand: What other cryptographic games can we play
to develop new sorts of programmable cryptography functionality?

At 0xPARC, we see this as a door to a new world.
What sort of systems can we build on top of programmable cryptography?

#todo[Import Brian's tree. Talk about reduction? Evan, take a look at the flavor text, idk if I like it - Aard]

== What's all the fuss about zero-knowledge anyhow?

When we think about how to use programmable cryptography we need to be creative.
As an example, what can you do with a zkSNARK?

One answer: You can prove that you have a solution to a system of equations.
Sounds pretty boring, unless you're an algebra student.

Slightly better answer: You can prove that you have executed a program correctly,
revealing some or all of the inputs and outputs, as you please.
For example: You know a messame $M$ such that
$op("sha")(M) = "0xa91af3ac..."$, but you don't want to reveal $M$.
Or: You only want to reveal the first 30 bytes of $M$.
Or: You know a message $M$, and a digital signature proving that $M$ was signed by
[trusted authority], such that a certain neural network, run on the input $M$, outputs "Good."

One recent application along these lines is
#link("https://tlsnotary.org", "TLSNotary").
TLSNotary lets you certify a transcript of communications with a server
in a privacy-preserving way: you only reveal the parts you want to.
