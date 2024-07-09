#import "preamble.typ":*

// copied from bigger project, edit into this one

= What is programmable cryptography?

Cryptography is everywhere now and needs no introduction.
_Programmable cryptography_ is a term coined by 0xPARC for a second generation
of cryptographic primitives that has arisen in the last 15 or so years.

To be concrete, let's consider two examples of what protocols designed by classical cryptography can do:

- _Digital signatures_.
  RSA and ElGamal are examples of digital signature algorithms,
  where Alice can perform some protocol to prove to Bob that she 
  endorses a message.
  A more complicated example might be a
  #cite("https://en.wikipedia.org/wiki/Group_signature", "group signature scheme"),
  which allows one member of a group to sign a message on behalf of the group.
- _Confidential computing_. For example, consider
  #cite("https://en.wikipedia.org/wiki/Yao%27s_Millionaires%27_problem", "Yao's millionaire problem"),
  where Alice and Bob wants to know which of them makes more money
  without learning anything more about each other's incomes.

Classically, first-generation cryptography relied on coming up with a protocol
for solving given problems or computing certain functions.
The goal of the second-generation "programmable cryptography" can
then be described as:

#quote[
  We want cryptography that can
  be "programmed" to work on *arbitrary* problems and functions,
  rather than designing protocols on a per-problem or per-function basis.
]

To draw an analogy, it's like going from single-purpose hardware
(like a digital alarm clock or thermostat)
to a general-purpose device (like a smartphone) which can
do any computation so long as someone writes code for it.

#remark[
  The quote on the title page
("I have a message $M$ such that $sha(M) = "0x91af3ac..."$")
is a concrete example.
The hash function sha is a particular set of arbitrary instructions,
yet programmable cryptography promises that such a proof can be made
using a general compiler rather than inventing an algorithm specific to SHA-256.
]

= Ideas in programmable cryptography

Our work presents programmable cryptography through specific topics in several self-contained "easy pieces," imitating Richard Feynman's
wonderful approach to physics exposition. We quickly preview them here.

== 2PC: Two-party computation

In a _two-party computation (2PC)_, two people want to
jointly compute some known function
$ F(x_1, x_2), $
where the $i$-th person only knows the input $x_i$, without either person learning the other person's input.

For example, in Yao's millionaire problem, Alice and Bob
want to know who has a higher income without revealing their own amounts.
This is the case where $F$ is the comparison function
($F(x_1, x_2)$ is $1$ if $x_1 > x_2$, $2$ if $x_2 > x_1$,
and $0$ if the two inputs are equal),
and $x_i$ is the $i$-th person's income.

Two-party computation makes a promise that we'll be able to do this
for _any_ function $F$ as long as we can implement it in code. It generalizes to _multi-party computation (MPC)_, which is one of the main classes of programmable cryptography.

== SNARK: proofs of general statements

A powerful way of thinking of a signature scheme is that it is a *proof*. Specifically, Alice's signature is a proof that "I [the
person who generated the signature] know Alice's private key." Similarly, a
group signature can be thought of as a succinct proof that "I know one of
Alice, Bob, or Charlie's private keys".

In the spirit of programmable cryptography, a _SNARK_ generalizes this concept
as a "proof system" protocol that produces efficient proofs of *arbitrary*
statements of the form:

#quote[
  I know $X$ such that $F(X, Y) = Z$, where $Y,Z$ are public,
]
once the statement is encoded as a system of equations. One such statement would be "I know $M$ such that $sha(M) = Y$."

SNARKS are an active area of research, and many different SNARKs are known.
Our work focuses on a particular example, PLONK (@plonk).

== FHE: Fully homomorphic encryption

Imagine you have some private text that you want to translate into another
language. While many services today will do this, even for free, we can also
imagine that you care about security a lot and you really don't want the
translating service to know anything about your text at all (e.g. selling the
text to someone else, adding your text to large language models that can then
be reverse-engineered to find your private information, blackmailing you...).

In _fully homomorphic encryption (FHE)_, one person encrypts some data $x$,
and then a second person can perform arbitrary operations on the encrypted data
$x$ without being able to read $x$.

With this technology, you have a solution to your problem!
You simply encrypt your text $Enc(x)$ and send it to your FHE machine translation server.
The server will faithfully translate it into
another language and give you $Enc(y)$, where $y$ is the translation of $x$.
You can then decrypt and obtain $y$, knowing that the server cannot extract
anything meaningful from $Enc(x)$ without your secret key.

(You could imagine many more applications of FHE,
such as a dating service that doesn't know anything about people it
is matchmaking.)

= Programmable Cryptography in the World

In the past decade, there has been both a surprisingly high amount of theoretical work but also
a surprisingly low amount of implementation work on primitives in programmable cryptography.
However, recent advances in areas like
blockchain and other decentralized systems are rapidly driving
demand for practical implementations of programmable cryptography. The gap
that is being revealed right now, as theory meets reality, is exciting and
enlightening.

Many of the protocols we mention in this book can be implemented today, but only at a very high cost (for example, the cost of proving a computation in a SNARK can be millions of times the
cost of performing the computation directly). As we study the theory of programmable cryptography, it is useful to keep in mind some practical questions. Can we reduce the theoretical overhead of programmable cryptography? How can we make programmable cryptography systems more performant for modern hardware and software systems? What
other systems or applications can be built on top of this technology?

It is easy to be carried away by the staggering possibilities, and to imagine a
perfect "post-cryptographic" world where everyone has control over all their
data and everyone's security preferences are completely fulfilled. It is also
easy to be cynical and assume that these ideas will get no further than the next
version of cryptocurrency scams at worst, or of private communication servers at best. Reality is always somewhere in the middle; the Internet
today offers free search and civilization-scale repositories of information to everyone, but is also used for plenty of frivolous or even antisocial activity.

No matter what the future actually holds, one thing is clear - it is up to people who are capable, curious, and optimistic to guide the next stage of the evolution of cryptography-based systems. We hope that these "easy pieces" will inspire you to read, imagine, and build.
