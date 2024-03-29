#import "preamble.typ":*

= The discrete logarithm problem on an elliptic curve

== Pitch: Discrete logarithm is hard

In the public-key cryptography system RSA, one key assumption
is that there is no efficient method to factor large semiprimes.
RSA can be thought of as working with the abelian group $(ZZ slash N ZZ)^times$.

In many modern protocols, one replaces $(ZZ slash N ZZ)^times$ with
an elliptic curve $E$ defined over a finite field $FF_q$.
For our systems to be useful, rather than relying on factoring,
we will rely on the so-called *discrete logarithm* problem.

#claim[
  Let $E$ be an elliptic curve.
  Given arbitrary nonzero $g, g' in E$,
  it's hard to find $n$ such that $n dot g = g'$.
]

In other words, if one only
sees $g in E$ and $n dot g in E$, one cannot find $n$.

(This is called discrete log because if one used multiplicative notation
like in RSA, it looks like solving $g^n = g'$ instead.
We will never use this multiplicative notation in these notes.)

== Vectors

One quick application of this is that if $g_1, ..., g_n in E$
are a bunch of random points,
then it's computationally infeasible to find
$(a_1, ..., a_n) != (b_1, ..., b_n) in FF_q^n$ such that
$ a_1 g_1 + ... + a_n g_n = b_1 g_1 + ... + b_n g_n. $
Indeed, even if one fixes any choice of $2n-1$ of the $2n$ coefficients above,
one cannot find the last coefficient.

#definition[
  In these notes, if there's a globally known elliptic curve $E$
  and points $g_1, ..., g_n$ with no known nontrivial
  linear dependencies between them,
  we'll say they're *"practically independent"*.
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

== Pedersen commitments

One application of this injectivity is that
we can have a hash of the vector with shorter length
(with "practically independent" now being phrased as "we can't find a collision").
This is named:

#definition[
  Let $g_1, ..., g_n in E$ be "practically independent".
  Given a vector $angle.l a_1, ..., a_n angle.r in FF_q^n$ of scalars,
  the vector
  $ arrow(a) = sum a_i g_i in E$
  is called the *Pedersen commitment*.
]

We will see Pedersen commitments later on in IPA.
