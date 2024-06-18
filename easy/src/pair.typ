#import "preamble.typ":*

= Bilinear pairings on elliptic curves <pair>



The map $[bullet] : FF_q -> E$ is linear,
meaning that $[a + b] = [a] + [b]$, and $[n a] = n[a]$.
But as written we can't do "armored multiplication":

#claim[
  As far as we know, given $[a]$ and $[b]$, one cannot compute $[a b]$.
]

On the other hand, it _does_ turn out that we know a way to _verify_
a claimed answer on certain curves.
That is:
#proposition[
  On the curve BN254, given three points $[a]$, $[b]$, and $[c]$ on the curve,
  one can verify whether $a b = c$.
]

The technique needed is that one wants to construct a
nondegenerate bilinear function
$ pair : E times E -> ZZ slash N ZZ $
for some large integer $N$.
I think this should be called a *bilinear pairing*,
but for some reason everyone just says *pairing* instead.
A curve is called *pairing-friendly* 
if this pairing can be computed reasonably quickly
(e.g. BN254 is pairing-friendly, but Curve25519 is not).

This construction actually uses some really deep number theory
(heavier than all the math in @ec)
that is well beyond the scope of these lecture notes.
Fortunately, we won't need the details of how it works;
but we'll comment briefly in @pairing-friendly on what curves it can be done on.
And this pairing algorithm needs to be worked out just once for the curve $E$;
and then anyone in the world can use the published curve for their protocol.

Going a little more generally, the four-number equation
$ pair([m], [n]) = pair([m'], [n']) $
will be true whenever $m n = m' n'$,
because both sides will equal $m n pair([1], [1])$.
So this gives us a way to _verify_ two-by-two multiplication.

#remark[
  The last sentence is worth bearing in mind: in all the protocols we'll see,
  the pairing is only used by the _verifier_ Victor, never by the prover Peggy.
]

#remark[We don't know how to do multilinear pairings][
  On the other hand, we currently don't seem to know a good
  way to do _multilinear_ pairings.
  For example, we don't know a good trilinear map
  $E times E times E -> ZZ slash N ZZ$
  that would allow us to compare $[a b c]$, $[a]$, $[b]$, $[c]$
  (without knowing one of $[a b]$, $[b c]$, $[c a]$).
]

== Verifying more complicated claims <pair-verify>

#example[
  Suppose Peggy wants to convince Victor that $y = x^3 + 2$,
  where Peggy has sent Victor elliptic curve points [x] and [y].
  To do this, Peggy additionally sends to Victor $[x^2]$ and $[x^3]$.

  Given $[x]$, $[x^2]$, $[x^3]$, and $[y]$,
  Victor verifies that:
  - $pair([x^2], 1) = pair([x], [x]) $
  - $pair([x^3], 1) = pair([x^2], [x]) $
  - $[y] = [x^3] + 2 [1]$.

  The process of verifying this sort of identity is quite general:
  The prover sends intermediate values as needed
  so that the verifier can verify the claim using only pairings and linearity.
] <pair-verify-example>


== So which curves are pairing-friendly? <pairing-friendly>

If we chose $E$ to be BN254, the following property holds:

#proposition[
  For $(p,q)$ as in BN254,
  the smallest integer $k$ such that $q$ divides $p^k-1$ is $k=12$.
]

This integer $k$ is called the *embedding degree*.
This section is an aside explaining how the embedding degree affects pairing.

The pairing function $pair(a, b)$ takes as input two points $a, b in E$
on the elliptic curve,
and spits out a value $pair(a, b) in FF_{p^k}^*$ --
in other words, a nonzero element of the finite field of order $p^k$
(where $k$ is the embedding degree we just defined).
In fact, this element will always be a $q$th root of unity in $FF_{p^k}$,
and it will satisfy $pair([m], [n]) = zeta^{m n}$,
where $zeta$ is some fixed $q$th root of unity.
The construction of the pairing is based on the
#link("https://en.wikipedia.org/wiki/Weil_pairing", "Weil pairing")
in algebraic geometry.
How to compute these pairings is well beyond the scope of these notes;
the raw definition is quite abstract,
and a lot of work has gone into computing the pairings efficiently.
(For more details, see these
#link("https://crypto.stanford.edu/pbc/notes/ep/pairing.html", "notes").)

The difficulty of computing these pairings is determined by the size of $k$:
the values $pair(a, b)$ will be elements of a field of size $p^k$,
so they will require $256k$ bits even to store.
For a curve to be "pairing-friendly" -- in order to be able to
do pairing-based cryptography on it -- we need the value of $k$ to be pretty small.


