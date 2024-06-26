#import "preamble.typ":*

= Elliptic curves <ec>

Every modern cryptosystem rests on a hard problem
-- a computationally infeasible challenge
whose difficulty makes the protocol secure.
The best-known example is 
#link("https://en.wikipedia.org/wiki/RSA_(cryptosystem)", "RSA"),
which is secure because
it is hard to factor a composite number (like $6177$)
into prime factors ($6177 = 71*87$).

Our SNARK protocol will be based on a different hard problem:
the #link("https://w.wiki/9jgX", "discrete logarithm problem")
(@discretelog) on elliptic curves.
But before we get to the problem,
we need to introduce some of the math behind elliptic curves.

An _elliptic curve_ is a set of points with a group operation.
The set of points is the set of solutions $(x, y)$
to an equation in two variables;
the group operation is a rule for "adding" two of the points
to get a third point.
Our first task, before we can get to the SNARK,
will be to understand what all this means.

The roadmap goes roughly as follows:

- In @bn254 we will describe one standard elliptic curve $E$, the BN254 curve,
  that will be used in these notes.
- In @discretelog we describe the discrete logarithm problem:
  that for $g in E$ and $n in FF_q$, 
  one cannot recover the scaling factor $n$ 
  from the two elliptic curve points $g$ and $n dot g$.
  This is labeled as @ddh in these notes.
- As an example, in @eddsa we describe how @ddh
  can be used to construct a signature scheme, namely
  #link("https://en.wikipedia.org/wiki/EdDSA", "EdDSA").
  This idea will later grow up to be the KZG commitment scheme in @kzg.

== The BN254 curve <bn254>

Rather than set up a general definition of elliptic curve,
for these notes we will be satisfied to describe one specific elliptic curve
that can be used for all the protocols we describe later.
The curve we choose for these notes is the _BN254 curve_.

== The set of points

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
  The _BN254 curve_ is the elliptic curve
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
  Let $E$ be the BN254 curve.
  The number of points in $E(FF_p)$,
  including the point at infinity $O$, is a prime $q approx 2^(254)$.
]
#definition[
  This prime $q approx 2^(254)$ is affectionately called the _Baby Jubjub prime_
  (a reference to #link("https://w.wiki/5Ck3", "The Hunting of the Snark")).
  It will usually be denoted by $q$ in these notes.
]

=== The group law

So at this point, we have a bag of $q$ points denoted $E(FF_p)$.
However, right now it only has the structure of a set.

The beauty of elliptic curves
is that it's possible to define an *addition* operation on the curve;
this is called the #link("https://w.wiki/9jhM", "group law on the elliptic curve").
This addition will make $E(FF_p)$ into an abelian group whose identity element
is the point at infinity $O$. This addition can be formalized as a _group law_, which is an equation that points on the curve must follow.

This group law involves some kind of heavy algebra.
It's not important to understand exactly how it works.
All you really need to take away from this section is that there is some group law,
and we can program a computer to compute it.

#gray[
  So, let's get started.
  The equation of $E$ is cubic -- the highest-degree terms have degree $3$.
  This means that (in general) if you take a line $y = m x + b$ and intersect it with $E$,
  the line will meet $E$ in exactly three points.
  The basic idea behind the group law is:
  If $P, Q, R$ are the three intersection points of a line (any line)
  with the curve $E$, then the group-law addition of the three points is
  $
  P + Q + R = O.
  $

  (You might be wondering how we can do geometry
  when the coordinates $x$ and $y$ are in a finite field.
  It turns out that all the geometric operations we're describing --
  like finding the intersection of a curve with a line --
  can be translated into algebra.
  And then you just do the algebra in your finite field.
  But we'll come back to this.)

  Why three points?
  Algebraically, if you take the equations $Y^2 = X^3 + 3$ and $Y = m X + b$
  and try to solve them,
  you get
  $
  (m X + b)^2 = X^3 + 3,
  $
  which is a degree-3 polynomial in $X$,
  so it has (at most) 3 roots.
  And in fact if it has 2 roots, it's guaranteed to have a third
  (because you can factor out the first two roots, and then you're left with a linear factor).

  OK, so given two points $P$ and $Q$, how do we find their sum $P+Q$?
  We can draw the line through the two points.
  That line -- like any line -- will intersect $E$ in three points:
  $P$, $Q$, and a third point $R$.
  Now since $P + Q + R = 0$, we know that
  $
  - R = P + Q.
  $

  So now the question is just: how to find $-R$?
  Well, it turns out that if $R = (x_R, y_R)$, then
  $
  - R = (x_R, -y_R).
  $
  Why is this?
  If you take the vertical line $X = x_R$,
  and try to intersect it with the curve,
  it looks like there are only two intersection points.
  After all, we're solving
  $
  Y^2 = x_R^3 + 3,
  $
  and since $x_R$ is fixed now, this equation is quadratic.
  The two roots are $Y = \pm y_R$.

  OK, there are only two intersection points, but
  we say that the third intersection point is "the point at infinity" $O$.
  (The reason for this lies in projective geometry, but we won't get into it.)
  So the group law here tells us
  $
    (x_R, y_R) + (x_R, -y_R) + O = O.
  $
  And since $O$ is the identity, we get
  $
  -R = (x_R, -y_R).
  $

  So:
  - Given a point $P = (x_P, y_P)$, its negative is just $-P = (x, -y)$.
  - To add two points $P$ and $Q$, compute the line through the two points,
    let $R$ be the third intersection of that line with $E$,
    and set
    $
    P + Q = -R.
    $

  I just described the group law as a geometric thing,
  but there are algebraic formulas to compute it as well.
  They are kind of a mess, but here goes.

  If $P = (x_P, y_P)$ and $Q = (x_Q, y_Q)$, then the line between the two points is
  $Y = m X + b$, where
  $
  m = (y_Q - y_P) / (x_Q - x_P)
  $
  and
  $
  b = y_P - m x_P.
  $

  The third intersection is $R = (x_R, y_R)$, where
  $
  x_R = m^2 - x_P - x_Q
  $
  and
  $
  y_R = m x_R + b.
  $

  There are separate formulas to deal with various special cases
  (if $P = Q$, you need to compute the tangent line to $E$ at $P$, for example),
  but we won't get into it.
]

In summary we have endowed the set of points $E(FF_p)$ with the additional
structure of an abelian group, which happens to have exactly $q$ elements.
However, an abelian group with prime order is necessarily cyclic.
In other words:

#theorem[The group BN254 is isomorphic to $FF_q$][
  Let $E$ be the BN254 curve.
  We have the isomorphism of abelian groups
  $ E(FF_p) tilde.equiv ZZ slash q ZZ. $
]

In these notes, this isomorphism will basically be a standing assumption.
Moving forward we'll abuse notation slightly
and just write $E$ instead of $E(FF_p)$.
In fancy language, $E$ will be a one-dimensional vector space over $FF_q$.
In less fancy language, we'll be working with points on $E$ as black boxes.
We'll be able to add them, subtract them, 
and multiply them by arbitrary scalars from $FF_q$.

Consequently --- and this is important ---
*one should actually think of $FF_q$ as the base field
for all our cryptographic primitives*
(despite the fact that the coordinates of our points are in $FF_p$).

#remark[
  Whenever we talk about protocols, and there are any sorts of
  "numbers" or "scalars" in the protocol,
  *these scalars are always going to be elements of $FF_q$*.
  Since $q approx 2^(254)$,
  that means we are doing something like $256$-bit integer arithmetic.
  This is why the baby Jubjub prime $q$ gets a special name,
  while the prime $p$ is unnamed and doesn't get any screen-time later.
]

== A hard problem: discrete logarithm <discretelog>

For our systems to be useful, rather than relying on factoring,
we will rely on the so-called _discrete logarithm_ assumption.

#assumption[Discrete logarithm assumption][
  Let $E$ be the BN254 curve (or another standardized curve).
  Given arbitrary nonzero $g, g' in E$,
  it's hard to find an integer $n$ such that $n dot g = g'$. (the act of obtaining this integer is called the _discrete logarithm problem_)
] <ddh>

In other words, if one only
sees $g in E$ and $n dot g in E$, one cannot find $n$.
For cryptography, we generally assume $g$ has order $q$,
so we will talk about $n in NN$ and $n in FF_q$ interchangeably.
In other words, $n$ will generally be thought of as being up to about $2^(254)$ in size.

#remark[The name "discrete log"][
  This problem is called discrete log because if one used multiplicative notation
  for the group operation, it looks like solving $g^n = g'$ instead.
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

Because we think of $n$ as up to $q approx 2^(254)$-ish in size,
we consider $O(log n)$ operations like this to be quite tolerable.

== Curves other than BN254

We comment briefly on how the previous two sections adapt to other curves,
although readers could get away with always assuming $E$ is BN254 if they prefer.

In general, we could have chosen for $E$ any equation of the form
$Y^2 = X^3 + a X + b$ and chosen any prime $p >= 5$
such that a nondegeneracy constraint $4a^3 + 27b^2 equiv.not 0 mod p$ holds.
In such a situation, $E(FF_p)$ will indeed be an abelian group
once the identity element $O = (0, oo)$ is added in.

How large is $E(FF_p)$?
There is a theorem called
#link("https://w.wiki/9jhi", "Hasse's theorem") that states
the number of points in $E(FF_p)$ is between $p+1-2sqrt(p)$ and $p+1+2sqrt(p)$.
But there is no promise that $E(FF_p)$ will be _prime_;
consequently, it may not be a cyclic group either.
So among many other considerations,
the choice of constants in BN254 is engineered to get a prime order.

There are other curves used in practice for which $E(FF_p)$
is not a prime, but rather a small multiple of a prime.
The popular #link("https://w.wiki/9jhp", "Curve25519") is such a curve
that is also believed to satisfy @ddh.
Curve25519 is defined as $Y^2 = X^3 + 486662X^2 + X$ over $FF_p$
for the prime $p := 2^(255)-19$.
Its order is actually $8$ times a large prime
$q' := 2^(252) + 27742317777372353535851937790883648493$.
In that case, to generate a random point on Curve25519 with order $q'$,
one will usually take a random point in it and multiply it by $8$.

BN254 is also engineered to have a property called _pairing-friendly_,
which is defined in @pairing-friendly when we need it later.
(In contrast, Curve25519 does not have this property.)

== Example application: EdDSA signature scheme <eddsa>

We'll show how @ddh can be used to construct a signature scheme that replaces RSA.
This scheme is called #link("https://w.wiki/4usy", "EdDSA"),
and it's used quite frequently (e.g. in OpenSSH and GnuPG).
One advantage it has over RSA is that its key size is much smaller:
both the public and private key are 256 bits.
(In contrast, RSA needs 2048-4096 bit keys for comparable security.)

=== The notation $[n]$ <armor>

Let $E$ be an elliptic curve and let $g in E$
be a fixed point on it of prime order $q approx 2^(254)$.
For $n in ZZ$ (equivalently $n in FF_q$) we define
$ [n] := n dot g in E. $

The hardness of discrete logarithm means that, given $[n]$, we cannot get $n$.
You can almost think of the notation as an "armor" on the integer $n$:
it conceals the integer, but still allows us to perform (armored) addition:
$ [a+b] = [a] + [b]. $
In other words, $n |-> [n]$ viewed as a map $FF_q -> E$ is $FF_q$-linear.

=== Signature scheme

So now suppose Alice wants to set up a signature scheme.

#algorithm[EdDSA public and secret key][
  1. Alice picks a random integer $d in FF_q$ as her _secret key_ (a piece of information that she needs to keep private for the security of the protocol).
  2. Alice publishes $[d] in E$ as her _public key_ (a piece of information which, even when obtained by adversaries, does not challenge the security of the protocol).
]

Now suppose Alice wants to prove to Bob that she approves the message $msg$,
given her published public key $[d]$.

#algorithm[EdDSA signature generation][
  Suppose Alice wants to sign a message $msg$.

  1. Alice picks a random scalar $r in FF_q$ (keeping this secret)
    and publishes $[r] in E$.
  2. Alice generates a number $n in FF_q$ by hashing $msg$ with all public information,
    say $ n := sha([r], msg, [d]). $
  3. Alice publishes the integer $ s := (r + d n) mod q. $

  In other words, the signature is the ordered pair $([r], s)$.
]

#algorithm[EdDSA signature generation][
  For Bob to verify a signature $([r], s)$ for $msg$:

  1. Bob recomputes $n$ (by also performing the hash) and computes $[s] in E$.
  2. Bob verifies that $[r] + n dot [d] = [s]$.
]

An adversary cannot forge the signature even if they know $r$ and $n$.
Indeed, such an adversary can compute what the point $[s] = [r] + n [d]$
should be, but without knowledge of $d$ they cannot get the integer $s$,
due to @ddh.

The number $r$ is called a _blinding factor_ because
its use prevents Bob from stealing Alice's secret key $d$ from the published $s$.
It's therefore imperative that $r$ isn't known to Bob
nor reused between signatures, and so on.
One way to do this would be to pick $r = sha(d, msg)$; this has the
bonus that it's deterministic as a function of the message and signer.

In @kzg we will use ideas quite similar to this to
build the KZG commitment scheme.

== Example application: Pedersen commitments <pedersen>

A multivariable generalization of @ddh is that if $g_1, ..., g_n in E$
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
  we'll say they're a _computational basis over $FF_q$_.
] <comp_basis>

#remark[
  This may horrify pure mathematicians because we're pretending the map
  $ FF_q^n -> FF_q " by " (a_1, ..., a_n) |-> sum_1^n a_i g_i $
  is injective,
  even though the domain is an $n$-dimensional $FF_q$-vector space
  and the codomain is one-dimensional.
  This can feel weird because our instincts from linear algebra in pure math
  are wrong now. This map, while not injective in theory,
  ends up being injective *in practice* (because we can't find collisions).
  And this is a critical standing assumption for this entire framework!
]

This injectivity gives us a sort of hash function on vectors
(with "linearly independent" now being phrased as "we can't find a collision").
To spell this out:

#definition[
  Let $g_1, ..., g_n in E$ be a computational basis over $FF_q$.
  Given a vector
  $ arrow(a) = angle.l a_1, ..., a_n angle.r in FF_q^n $ of scalars,
  the group element
  $ sum a_i g_i = a_1 g_1 + ... + a_n g_n in E $
  is called the _Pedersen commitment_ of our vector $arrow(a)$.
]

The Pedersen commitment is thus a sort of hash function:
given the group element above,
one cannot recover any of the $a_i$;
but given the entire vector $arrow(a)$
one can compute the Pedersen commitment easily.

We won't use Pedersen commitments in this book,
but in @kzg we will see a closely related commitment scheme,
called KZG.

