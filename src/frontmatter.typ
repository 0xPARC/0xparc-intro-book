#import "preamble.typ":*

= Frontmatter

These are lightly edited notes from a reading group hosted by the
#link("https://0xparc.org", "0xPARC Foundation").
It's not meant to be a mathematically complete reference,
but rather a introduction to the general landscape and ideas for newcomers.

== Prerequisites

- Modular arithmetic is assumed, and $FF_q$ denotes the finite field with $q$ elements.
- The group law on an elliptic curve is assumed, but not much more than that.
- You should know what a one-way hash function is (like SHA-256).

== Characters

- *Alice* and *Bob* reprise their
  #link("https://w.wiki/8iXL", "usual roles as generic characters").
- *Penny* and *Victor* play the roles of _Prover_ and _Verifier_
  for protocols in which Penny wishes to prove something to Victor.
- *Trent* is a trusted administrator or arbiter,
  for protocols in which a trusted setup is required.
  (In real life, Trent is often a group of people performing

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

- $FF_q [T]$ denotes the ring of univariate polynomials
  with coefficients in $FF_q$ in a single formal variable $T$.
  More generally, $FF_q [T_1, ..., T_n]$ denotes the ring of
  polynomials in the $n$ formal variables $T_1$, ..., $T_n$.
  We'll prefer capital Roman letters for both polynomials and formal variables.

- $NN = {1,2,...,}$ denotes the set of _positive_ integers,
  while $ZZ = {...,-1,0,1,...}$ is the set of all integers.
  We prefer the Roman letters $m$, $n$, $N$ for integers.

== Acknowledgments

Authors

#todo[Vitalik, Darken]
