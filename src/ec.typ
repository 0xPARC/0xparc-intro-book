#import "preamble.typ":*

= Elliptic curves <ec>

In the public-key cryptography system RSA, one key assumption
is that there is no efficient method to factor large semiprimes.
RSA can be thought of as working with the abelian group $(ZZ slash N ZZ)^times$,
where $N$ is the product of two large primes.
This setup, while it does work, is brittle in some ways
(for example, every person needs to pick a different $N$ for RSA).

In many modern protocols, one replaces $(ZZ slash N ZZ)^times$ with
a so-called _elliptic curve_ $E$.
The assumption "factoring is hard" is then replaced by a new one,
that the #link("https://w.wiki/9jgX", "discrete logarithm problem is hard").

This chapter sets up the math behind this elliptic curve $E$.
The roadmap goes roughly as follows:

- In @bn254 we will describe one standard elliptic curves $E$, the BN254 curve,
  that will be used in these notes.
- In @discretelog we describe the discrete logarithm problem:
  that for $g in E$ and $n in FF_q$, one cannot recover $n$ from $n dot g$.
  This is labeled as @ddh in these notes.
- As an example, in @eddsa we describe how @ddh
  can be used to construct a signature scheme, namely
  #link("https://en.wikipedia.org/wiki/EdDSA", "EdDSA").
  This idea will later grow up to be the KZG commitment scheme in @kzg.
- As another example, in @pedersen we describe how @ddh
  can be used to create a commitment scheme for vectors: the Pedersen commitment.
  This idea will later grow up to be the IPA commitment scheme in @ipa.

== The BN254 curve <bn254>

Rather than set up a general definition of elliptic curve,
for these notes we will be satisfied to describe one specific elliptic curve
that could be used for all the protocols we describe later.
The curve we choose for these notes is the *BN254 curve*.

=== The set of points

The BN254 specification fixes a specific#footnote[
  If you must know, the values in the specification are given exactly by
  $
  x &:= 4965661367192848881 \
  p &:= 36x^4 + 36x^3 + 24x^2 + 6x + 1 \
  &= 21888242871839275222246405745257275088696311157297823662689037894645226208583 \
  q &:= 36x^4 + 3x^3 + 18x^2 + 6x + 1 \
  &= 21888242871839275222246405745257275088548364400416034343698204186575808495617.
  $
]
large prime $p approx 2^(254)$
(and a second large prime $q approx 2^(254)$ that we define later)
which has been specifically engineered to have certain properties
(see e.g. #url("https://hackmd.io/@jpw/bn254")).
The name BN stands for Barreto-Naehrig, two mathematicians who
#link("https://link.springer.com/content/pdf/10.1007/11693383_22.pdf",
"proposed a family of such curves in 2006").

#definition[
  The *BN254 curve* is the elliptic curve
  #eqn[$ E(FF_p) : Y^2 = X^3 + 3 $ <bn254eqn>]
  defined over $FF_p$, where $p approx 2^(254)$
  is the prime from the BN254 specification.
]

So each point on $E(FF_p)$ is an ordered pair $(X,Y) in FF_p^2$ satisfying @bn254eqn.
Okay, actually, that's a white lie: conventionally,
there is one additional point $O = (0, oo)$ called the "point at infinity"
added in (whose purpose we describe in the next section).

The constants $p$ and $q$ are contrived so that the following holds:
#theorem[BN254 has prime order][
  The number of points in $E(FF_p)$,
  including the point at infinity $O$, is a prime $q approx 2^(254)$.
]
#definition[
  This prime $q approx 2^(254)$ is affectionately called the *Baby Jubjub prime*
  (a reference to #link("https://w.wiki/5Ck3", "The Hunting of the Snark")).
  It will usually be denoted by $q$ in these notes.
]

=== The group law

So at this point, we have a bag of $q$ points denoted $E(FF_p)$.
However, right now it only has the structure of a set.

The beauty of elliptic curves
is that it's possible to define an _addition_ operation on the curve;
this is called the #link("https://w.wiki/9jhM", "group law on elliptic curve").
This addition will make $E(FF_p)$ into an abelian group whose identity element
is $O$.

#todo[Can someone write up the group law please and thanks]

In summary we have endowed the set of points $E(FF_p)$ with the additional
structure of an abelian group, which happens to have exactly $q$ elements.
However, an abelian group with prime order is necessarily cyclic.
In other words:

#theorem[The group BN254 is isomorphic to $FF_q$][
  We have the isomorphism of abelian groups $E(FF_p) tilde.equiv ZZ slash q ZZ$.
]

In these notes, this isomorphism will basically be a standing assumption;
so moving forward, as described in @notation we'll abuse notation slightly
and just write $E$ instead of $E(FF_p)$.

#remark[Other choices of curves][
  Here is the general situation for other curves:
  we could have chosen for $E$ any equation of the form
  $Y^2 = X^3 + a X + b$ and chosen any prime $p >= 5$
  such that a nondegeneracy constraint $4a^3 + 27b^2 equiv.not 0 mod p$ holds.
  In such a situation, $E(FF_p)$ will indeed be an abelian group
  (once the identity element $(0, oo)$ is added in).

  There is a theorem called
  #link("https://w.wiki/9jhi", "Hasse's theorem") that states
  the number of points in $E(FF_p)$ is between $p+1-2sqrt(p)$ and $p+1+2sqrt(p)$.
  However, if we pick $a$, $b$, $p$ arbitrarily,
  there is no promise that $E(FF_p)$ will be _prime_;
  consequently, it may not be a cyclic group either.
  So among many other considerations,
  the choice of constants in BN254 is engineered to get a prime order.

  There are other curves used in practice for which $E(FF_p)$
  is not a prime, but rather a small multiple of a prime.
  The popular #link("https://w.wiki/9jhp", "Curve25519") is such a curve.
  Curve25519 is defined as $Y^2 = X^3 + 486662X^2 + X$ over $FF_p$
  for the prime $p := 2^(255)-19$.
  Its order is actually $8$ times a large prime
  $q' := 2^(252) + 27742317777372353535851937790883648493$.
  In that case, to generate a random point on Curve25519 with order $q'$,
  one will usually take a random point in it and multiply it by $8$.
]

=== For later: BN254 is also pairing-friendly

The parameters of BN254 are _also_ chosen to be "pairing-friendly".
(In contrast, Curve25519 is not pairing-friendly.)
We won't define what this means until @kzg,
but we can actually mention the relevant mathematical property now:

#proposition[
  The smallest integer $k$ such that $q$ divides $p^k-1$ is $k=12$.
]

This integer $k$ is called the *embedding degree*,
and it needs to be not too small, but not too big either.

== Discrete logarithm is hard <discretelog>

For our systems to be useful, rather than relying on factoring,
we will rely on the so-called *discrete logarithm* problem.

#assumption[Discrete logarithm problem][
  Let $E$ be the BN254 curve (or another standardized curve).
  Given arbitrary nonzero $g, g' in E$,
  it's hard to find an integer $n$ such that $n dot g = g'$.
] <ddh>

In other words, if one only
sees $g in E$ and $n dot g in E$, one cannot find $n$.
For cryptography, we generally assume $g$ has order $q$,
so we will talk about $n in NN$ and $n in FF_q$ interchangeably.
In other words, $n$ will generally be thought of as being up to $2^(256)$ in size.

#remark[The name "discrete log"][
  This problem is called discrete log because if one used multiplicative notation
  like in RSA, it looks like solving $g^n = g'$ instead.
  We will never use this multiplicative notation in these notes.
]

On the other hand, given $g in E$,
one can compute $n dot g$ in just $O(log n)$ operations,
by #link("https://w.wiki/9jim", "repeated squaring").
For example, to compute $400g$, one only needs to do $10$ additions,
rather than $400$: one starts with
$
  2g &= g + g \
  4g &= 2g + 2g \
  8g &= 4g + 4g \
  16g &= 8g + 8g \
  32g &= 16g + 16g \
  64g &= 32g + 32g \
  128g &= 64g + 64g \
  256g &= 128g + 128g \
$
and then computes
$ 400g = 256g + 128g + 16g. $

Because we think of $n$ as up to $2^(256)$-ish in size,
we consider $O(log n)$ operations like this to be quite tolerable.

== Example application: EdDSA signature scheme <eddsa>

We'll show how @ddh can be used to construct a signature scheme that replaces RSA.
This scheme is called #link("https://w.wiki/4usy", "EdDSA").



== Example application: Pedersen commitments <pedersen>

One other corollary of @ddh is that if $g_1, ..., g_n in E$
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

This injectivity gives us a sort of hash function on vectors
(with "linearly independent" now being phrased as "we can't find a collision").
To spell this out:

#definition[
  Let $g_1, ..., g_n in E$ be a computational basis over $FF_q$.
  Given a vector $arrow(a) = angle.l a_1, ..., a_n angle.r in FF_q^n$ of scalars,
  the group element
  $ sum a_i g_i in E$
  is called the *Pedersen commitment* of our vector $arrow(a)$.
]

The Pedersen commitment is thus a sort of hash function:
given the group element above,
one cannot recover any of the $a_i$ (even when $n=1$);
but given the entire vector $arrow(a)$
one can compute the Pedersen commitment easily.

Pedersen commitments aren't used in the KZG scheme covered in @kzg,
but they feature extensively in the IPA scheme covered in @ipa.
