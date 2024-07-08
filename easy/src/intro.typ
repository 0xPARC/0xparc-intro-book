#import "preamble.typ":*

// copied from bigger project, edit into this one

= Introduction

== What is programmable cryptography?

Cryptography is so ubiquitous that it has become invisible:
- _Encryption_ (hiding and then decoding messages) make people talking to each other over apps and computers talking to each other over protocols (like SSH) secure.
- _Digital signatures_ 
  (signing a message with some data that anyone can verify must come from some specific identity) 
  authenticate people's identity, so you know that the website you are going to is actually what it says it is.
- _Key exchanges_ (allowing two parties to agree on a secret piece of data, even talking over an public channel) 
  allow people to set up secure connections remotely, 
  without having to meet in person to agree on a key.

However, there is actually a lot more cryptography that has been implemented in academic and other smaller circles, 
such as #cite("https://w.wiki/9fXW", "group signature schemes") 
(more advanced versions of digital signatures supporting multiple participants) 
and commitment schemes (general methods to commit to some secret that is to be revealed later in a way that prevents cheating).

Even beyond this, there is cryptography that has been theoretically constructed 
but barely (or never) tried in practice, often with a ambitious sense of scale. 
Its spirit can be summarized as:

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

This led 0xPARC to coin the term _programmable cryptography_ to differentiate 
this "second-generation" technology from "classical" cryptography that solve 
specific problems and/or involve specific functions. 

Programmable cryptography has a surprisingly high amount of theory but 
also a surprisingly low amount of implementation. Recent advances in 
blockchain, especially due to the success of cryptocurrencies, have driven 
demand for practical implementations of programmable cryptography. The friction
that is forming right now, as theory meets reality, is both exciting and 
enlightening.

== Ideas in programmable cryptography

Our work presents programmable cryptography through specific topics in (to the 
best of our ability) self-contained "easy pieces," imitating Richard Feynman's 
approach to wonderful physics exposition. We quickly preview them here.

=== 2PC: Two-party computation

In a _two-party computation (2PC)_, two people want to
jointly compute some known function
$ F(x_1, x_2), $
where the $i$-th person only knows the input $x_i$, without either person learning the other person's input.

For example, in  #cite("https://w.wiki/9fXQ", "Yao's millionaire problem"), Alice and Bob
want to know who has a higher income without revealing their own amounts.
This is the case where $F$ is the comparison function
($F(x_1, x_2)$ is $1$ if $x_1 > x_2$, $2$ if $x_2 > x_1$,
and $0$ if the two inputs are equal),
and $x_i$ is the $i$-th person's income.

Two-party computation makes a promise that we'll be able to do this
for _any_ function $F$ as long as we can implement it in code. It generalizes to _multi-party computation (MPC)_, which is one of the main classes of programmable cryptography. 

=== SNARK: proofs of general statements

A powerful way of thinking of a signature scheme is that it is a *proof*. Specifically, Alice's signature is a proof that "I [the
person who generated the signature] know Alice's private key." Similarly, a 
group signature can be thought of as a succinct proof that "I know one of 
Alice, Bob, or Charlie's private keys". 

In the spirit of programmable cryptography, a _SNARK_ generalizes this concept
as a "proof system" protocol that produces efficient proofs of *arbitrary* 
statements of the form:

#quote[
  I know $X$ such that $F(X, Y) = Z$, where $Y,Z$ are public.
]
once the statement is encoded as a system of equations. One such statement would be "I know $M$ such that $sha(M) = Y$."

SNARKS are an active area of research, and many different SNARKs are known.
Our work focuses on a particular example, PLONK (@plonk).

=== FHE: Fully homomorphic encryption

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
such as a dating service that does not even know the names of people it provides 
matchmaking to.)

== Where these fit together

MPC, SNARKs, and FHE are just some examples in a huge zoo of cryptographic primitives,
from the elementary (public-key cryptography)
to the impossibly powerful (indistinguishability obfuscation).
There are protocols for MPC, SNARKs, and FHE;
they are very slow, but they can be implemented and used in practice.

This whole field is an active area of research.
- Can we make existing tools (SNARKs, etc.) more efficient?
  For example, the cost of proving a computation in a SNARK
  is currently about $10^6$ times the cost of doing the computation directly.
  Can we bring that number down?
- What other cryptographic games can we play
  to develop new sorts of programmable cryptography functionality?

At 0xPARC, we see this as a door to a new world.
What sorts of systems can we build on top of programmable cryptography?

