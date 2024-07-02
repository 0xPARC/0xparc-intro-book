#import "preamble.typ":*

// copied from bigger project, edit into this one

= Introduction

== What is programmable cryptography?

Cryptography is everywhere now
and needs no introduction.
As examples, let's consider two examples of what protocols designed by
classical cryptography can achieve:

- *Proofs*. An example of this is digital signature algorithms like RSA,
  where Alice can do some protocol to prove to Bob that a message was sent by her.
  A more complicated example might be a
  #link("https://w.wiki/9fXW", "group signature scheme"),
  allowing one member of a group to sign a message on behalf of a group.

- *Hiding inputs*: for example, consider
  #link("https://w.wiki/9fXQ", "Yao's millionaire problem"),
  where Alice and Bob wants to know which of them has more money
  without learning each other's incomes.

Classically, first-generation cryptography relied on coming up for a protocol
for solving given problems or computing certain functions. _Programmable cryptography_ is a term coined by 0xPARC for a second generation
of cryptographic primitives that have arisen in the last 15 or so years.
The goal of this "second-generation cryptography" can be described as:

#quote[
  We want to devise cryptographic primitives that can
  be programmed to work on *arbitrary* problems and functions,
  rather than designing protocols on a per-problem or per-function basis.
]

To draw an analogy, it's sort of like going from older single-purpose hardware,
like a digital alarm clock or thermostat,
to a general-purpose device, like a smartphone, which can
do any computation so long as someone writes code for it.

The quote on the title page
("I have a message $M$ such that $op("sha")(M) = "0x91af3ac..."$")
is a concrete example;
the hash function SHA is a particular set of arbitrary instructions,
yet programmable cryptography promises that such a proof can be made
using a general compiler rather than inventing an algorithm specific to SHA256.

#todo[Brian's image of an alarm clock and a computer chip]

== Ideas in programmable cryptography

These notes address programmable cryptography through expositions on specific topics. We quickly preview them here.

=== 2PC: Two-party computation

In a _two-party computation_, two people want to
jointly compute some known function
$ F(x_1, x_2), $
where the $i$th person only knows the input $x_i$ ---
and they want to do it without either person learning the other person's input.

For example, in Yao's millionaire problem --- Alice and Bob
want to know who has a higher income without revealing the incomes themselves.
This is the case where $F$ is the comparison function
($F(x_1, x_2)$ is $1$ if $x_1 > x_2$, $2$ if $x_2 > x_1$,
and $0$ if the two inputs are equal)
and $x_i$ is the $i$'th person's income.

Two-party computation makes a promise that we'll be able to do this
for _any_ function $F$ as long as we can implement it in code. It generalizes to _multi-party computation (MPC)_, which is one of the main classes of programmable cryptography.

=== SNARK: proofs of general problems

The _SNARK_, first described in 2012,
provides a way to produce proofs of *arbitrary* problem statements, once the problem statements are encoded as a system of equations in a certain way.
The name stands for:

- _Succinct_: the proof length is short (actually constant length).
- _Non-interactive_: the protocol does not require back-and-forth communication.
- _Argument_: basically a proof.
  There's a technical difference, but we won't worry about it.
- _of Knowledge_: the proof doesn't just show the system of equations has a solution;
  it also shows that the prover knows one.

One additional feature (which we will not cover in these notes) is
_zero-knowledge (zk)_ (which turns the abbreviation into "zkSNARK"):
with a zero-knowledge proof, a person reading the proof
doesn't learn anything about the solution besides that it's correct.

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

This is an active area of research,
and many different proof systems are known.
These notes focus on one construction, called PLONK (@plonk).


=== FHE: Fully homomorphic encryption

In _fully homomorphic encryption_, one person encrypts some data $x$,
and then anybody can perform arbitrary operations on the encrypted data $x$
without being able to read $x$.

For example, imagine you have some private text that you want to
translate into another language.
You encrypt the text and feed it to your favorite FHE machine translation server.
You decrypt the server's output and get the translation.
The server only ever sees encrypted text,
so the server learns nothing about the text you translated.

== Where these fit together

MPC, SNARKs, and FHE are just some examples in a huge zoo of cryptographic primitives,
from the elementary (public-key cryptography)
to the impossibly powerful (indistinguishability obfuscation).
There are protocols for MPC, SNARKS, and FHE;
they are very slow, but they can be implemented and used in practice.

This whole field is an active area of research.
- Can we make existing tools (SNARKS, etc.) more efficient?
  For example, the cost of proving a computation in a SNARK
  is currently about $10^6$ times the cost of doing the computation directly.
  Can we bring that number down?
- What other cryptographic games can we play
  to develop new sorts of programmable cryptography functionality?

At 0xPARC, we see this as a door to a new world.
What sort of systems can we build on top of programmable cryptography?

#todo[Import Brian's tree. Talk about reduction? Evan, take a look at the flavor text, idk if I like it - Aard]
#todo[Agree should somehow talk about reduction here, since reader will probably start wondering high-level how you can ensure things are secure (right now first instance is at beginning of Section 3.1 Elliptic Curves) -jbel]