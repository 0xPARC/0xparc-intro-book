#import "preamble.typ":*

= Elliptic curve <ec>

In the public-key cryptography system RSA, one key assumption
is that there is no efficient method to factor large semiprimes.
RSA can be thought of as working with the abelian group $(ZZ slash N ZZ)^times$,
where $N$ is the product of two large primes.
This setup, while it does work, is brittle in some ways
(for example, every person needs to pick a different $N$ for RSA).

In many modern protocols, one replaces $(ZZ slash N ZZ)^times$ with
a _so-called_ elliptic curve $E$.
The assumption "factoring is hard" is then replaced by a new one,
that the #link("https://w.wiki/9jgX", "discrete logarithm problem is hard").

This chapter sets up the math behind this elliptic curve $E$.
The roadmap goes roughly as follows:

- In @bn254 we will describe the structure of elliptic curves $E$.
- In @discretelog we describe the discrete logarithm problem:
  that for $g in E$ and $n in FF_q$, one cannot recover $n$ from $n dot g$.
- As an example, in @eddsa we describe how the assumption in @discretelog
  can be used to construct a signature scheme, namely
  #link("https://en.wikipedia.org/wiki/EdDSA", "EdDSA").
  This idea will later grow up to be the KZG commitment scheme in @kzg.
- As another example, in @pedersen we describe how the assumption in @discretelog
  can be used to create a commitment scheme for vectors: the Pedersen commitment.
  This idea will later grow up to be the IPA commitment scheme in @ipa.

== The BN254 curve <bn254>

Rather than set up a general definition of elliptic curve,
for these notes we will be satsified to describe one specific elliptic curve
that could be used for all the protocols we describe later.
But we will comment briefly on the general situation.

#todo[define BN254 curve I think]

== Pitch: Discrete logarithm is hard <discretelog>

For our systems to be useful, rather than relying on factoring,
we will rely on the so-called *discrete logarithm* problem.

#claim[
  Let $E$ be an elliptic curve.
  Given arbitrary nonzero $g, g' in E$,
  it's hard to find $n$ such that $n dot g = g'$.
]

In other words, if one only
sees $g in E$ and $n dot g in E$, one cannot find $n$.

#remark[The name "discrete log"][
  This problem is called discrete log because if one used multiplicative notation
  like in RSA, it looks like solving $g^n = g'$ instead.
  We will never use this multiplicative notation in these notes.
]

#todo[repeated squaring]

One corollary of this is that if $g_1, ..., g_n in E$
are a bunch of randomly chosen points of $E$ with order $q$,
then it's computationally infeasible to find
$(a_1, ..., a_n) != (b_1, ..., b_n) in FF_q^n$ such that
$ a_1 g_1 + ... + a_n g_n = b_1 g_1 + ... + b_n g_n. $
Indeed, even if one fixes any choice of $2n-1$ of the $2n$ coefficients above,
one cannot find the last coefficient.

#definition[
  In these notes, if there's a globally known elliptic curve $E$
  and points $g_1, ..., g_n$ have order $q$ and no known nontrivial
  linear dependencies between them,
  we'll say they're a *computational basis over $FF_q$*.
]

#remark[
  This may horrify pure mathematicians because we're pretending the map
  $ FF_q^n -> FF_q " by " (a_1, ..., a_n) |-> sum_1^n a_i g_i $
  is injective,
  even though the domain is an $n$-dimensional $FF_q$-vector space
  and the codomain is one-dimensional.
  This can feel weird because our instincts from linear algebra in pure math
  are wrong now --- this map, while not injective in theory,
  ends up being injective _in practice_ (because we can't find collisions),
  and this is a critical standing assumption for this entire framework.
]

== Example application: EdDSA signature scheme <eddsa>

#todo[write this]

== Example application: Pedersen commitments <pedersen>

Another application of this injectivity is that
we can have a hash of the vector with shorter length
(with "practically independent" now being phrased as "we can't find a collision").
This is named:

#definition[
  Let $g_1, ..., g_n in E$ be a computational basis over $FF_q$.
  Given a vector $arrow(a) = angle.l a_1, ..., a_n angle.r in FF_q^n$ of scalars,
  the group element
  $ sum a_i g_i in E$
  is called the *Pedersen commitment* of our vector $arrow(a)$.
]

Pedersen commitments aren't used in the KZG scheme covered in @kzg,
but they feature extensively in the IPA scheme covered in @ipa.
