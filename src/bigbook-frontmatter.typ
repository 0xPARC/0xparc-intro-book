#import "preamble.typ":*

= About this novel

This novel _Notes on Programmable Cryptography_ is a sequel
to the novella _Three Easy Pieces in Programmable Cryptography_,
from the #link("https://0xparc.org", "0xPARC Foundation").
Whereas the novella was short enough to print and give to friends
as a souvenir to read on a plane ride,
this novel is meant to be a bit of a deeper dive.
Nonetheless, it's still not meant to be a exhaustive textbook or mathematically complete reference;
but rather a introduction to the general landscape and ideas for newcomers.

We assume a bit of general undergraduate math background, but not too much.
(For example, we'll just use the word "abelian group" freely,
and the reader is assumed to know modular arithmetic.)
We don't assume specialized knowledge like elliptic curve magic.

== Characters

- *Alice* and *Bob* reprise their
  #link("https://w.wiki/8iXL", "usual roles as generic characters").
- *Peggy* and *Victor* play the roles of _Prover_ and _Verifier_
  for protocols in which Peggy wishes to prove something to Victor.
- *Trent* is a trusted administrator or arbiter,
  for protocols in which a trusted setup is required.
  (In real life, Trent is often a group of people performing a multi-party
  computation, such that as long as at least one of them is honest,
  the trusted setup will work.)

== Notation and conventions <notation>

- Throughout these notes,
  $E$ will always denote an elliptic curve over some finite field $FF$
  (whose order is known for calculation but otherwise irrelevant).

- If we were being pedantic, we might be careful to distinguish
  the elliptic curve $E$ from its set of $FF$-points $E(FF)$.
  But to ease notation, we simply use $E$ interchangeably with $E(FF)$.

- Hence, the notation "$g in E$" means "$g$ is a point of $E(FF)$".
  Elements of the curve $E$ are denoted by lowercase Roman letters;
  $g in E$ and $h in E$ are especially common.

- We always use additive notation for the group law on $E$:
  given $g in E$ and $h in E$ we have $g+h in E$.

- $FF_q$ denotes the finite field of order $q$.
  In these notes, $q$ is usually a globally known large prime,
  often $q approx 2^256$.

- $FF_q [X]$ denotes the ring of univariate polynomials
  with coefficients in $FF_q$ in a single formal variable $X$.
  More generally, $FF_q [T_1, ..., T_n]$ denotes the ring of
  polynomials in the $n$ formal variables $T_1$, ..., $T_n$.
  We'll prefer capital Roman letters for both polynomials and formal variables.

- $NN = {1,2,...,}$ denotes the set of _positive_ integers,
  while $ZZ = {...,-1,0,1,...}$ is the set of all integers.
  We prefer the Roman letters $m$, $n$, $N$ for integers.

- We let $sha()$ denote your favorite one-way hash function,
  such as #link("https://w.wiki/KgC", "SHA-256").
  For us, it'll take in any number of arguments of any type
  (you should imagine they are coerced into strings)
  and output a single number in $FF_q$.
  That is,
  $ sha : "any number of inputs" -> FF_q. $


== Acknowledgments

Authors

#todo[Vitalik, Darken]
