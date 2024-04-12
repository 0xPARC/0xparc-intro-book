#import "preamble.typ":*

= Kate-Zaverucha-Goldberg (KZG) commitments <kzg>

== Pitch: KZG lets you commit a polynomial and reveal individual values

The goal of the KZG commitment schemes is to have the following API:

- Penny has a secret polynomial $P(T) in FF_q [T]$.
- Penny sends a short "commitment" to the polynomial (like a hash).
- This commitment should have the additional property that
  Penny should be able to "open" the commitment at any $z in FF_q$.
  Specifically:

  - Victor has an input $z in FF_q$ and wants to know $P(z)$.
  - Peggy knows $P$ so she can compute $P(z)$;
    she sends the resulting number $y = P(z)$ to Victor.
  - Peggy can then send a short "proof" convincing Victor that $y$ is the
    correct value, without having to reveal $P$.

The KZG commitment scheme is amazingly efficient because both the commitment
and proof lengths are a single point on $E$, encodable in 256 bits.

== Elliptic curve setup done once

The good news is that this can be done just once, period.
After that, anyone in the world can use the published data to run this protocol.

For concreteness, $E$ will be the BN256 curve and $g$ a fixed generator.

=== The notation $[n]$

We retain the notation $[n] := n dot g in E$ defined in @armor.

=== Bilinear pairing

The map $[bullet] : FF_q -> E$ is linear,
but as written we can't do "armored multiplication":

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
but for some reason everyone justs says *pairing* instead.
A curve is called *pairing-friendly* if this pairing can be computed reasonably
(e.g. BN254 is pairing-friendly, but Curve25519 is not).

This construction is actually uses some really deep graduate-level number theory
(in contrast, all the math in @ec is within an undergraduate curriculum)
that are well beyond the scope of these lecture notes.
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
  the pairing is only used by the _verifier_ Victor, never by the prover Penny.
]

#remark[We don't know how to do multilinear pairings][
  On the other hand, we currently don't seem to know a good
  way to do _multilinear_ pairings.
  For example, we don't know a good trilinear map
  $E times E times E -> ZZ slash N ZZ$
  that would allow us to compare $[a b c]$, $[a]$, $[b]$, $[c]$
  (without already knowing one of $[a b]$, $[b c]$, $[c a]$).
]

=== Trusted calculation

To set up the KZG commitment scheme,
a trusted party needs to pick a secret scalar $s in FF_q$ and publishes
$ [s^0], [s^1], ..., [s^M] $
for some large $M$, the maximum degree of a polynomial the scheme needs to support.
This means anyone can evaluate $[P(s)]$ for any given polynomial $P$ of degree up to $M$.
(For example, $[s^2+8s+6] = [s^2] + 8[s] + 6[1]$.)
Meanwhile, the secret scalar $s$ is never revealed to anyone.

This only needs to be done by a trusted party once for the curve $E$.
Then anyone in the world can use the resulting sequence for KZG commitments.

== The KZG commitment scheme

Penny has a polynomial $P(T) in FF_p [T]$.
To commit to it:

#algorithm("Creating a KZG commitment")[
  1. Penny computes and publishes $[P(s)]$.
]
This computation is possible as $[s^i]$ are globally known.

Now consider an input $z in FF_p$; Victor wants to know the value of $P(z)$.
If Penny wishes to convince Victor that $P(z) = y$, then:

#algorithm("Opening a KZG commitment")[
  1. Penny does polynomial division to compute $Q(T) in FF_q [T]$ such that
    $ P(T)-y = (T-z) Q(T). $
  2. Penny computes and sends Victor $[Q(s)]$,
    which again she can compute from the globally known $[s^i]$.
  3. Victor verifies by checking
    #eqn[
      $ pair([Q(s)], [s]-[z]) = pair([P(s)]-[y], [1]) $
      <kzg-verify>
    ]
    and accepts if and only if @kzg-verify is true.
]

If Penny is truthful, then @kzg-verify will certainly check out.

If $y != P(z)$, then Penny can't do the polynomial long division described above.
So to cheat Victor, she needs to otherwise find an element
$ 1/(s-x) ([P(s)]-[y]) in E. $
Since $s$ is a secret nobody knows, there isn't any known way to do this.

== Multi-openings

To reveal $P$ at a single value $z$, we did polynomial division
to divide $P(T)$ by $T-z$.
But there's no reason we have to restrict ourselves to linear polynomials;
this would work equally well with higher-degree polynomials,
while still using only a single 256-bit for the proof.

For example, suppose Penny wanted to prove that
$P(1) = 100$, $P(2) = 400$, ..., $P(9) = 8100$.
Then she could do polynomial long division to get a polynomial $Q$
of degree $deg(P) - 9$ such that
$ P(T) - 100T^2 = (T-1)(T-2) ... (T-9) dot Q(T). $
Then Penny sends $[Q(s)]$ as her proof, and the verification equation is that
$ pair([Q(s)], [(s-1)(s-2) ... (s-9)]) = pair([P(s)] - 100[s^2], [1]). $

The full generality just replaces the $100T^2$ with the polynomial
obtained from #link("https://w.wiki/8Yin", "Lagrange interpolation");
there is a unique one of degree $n-1$.
Suppose Penny wishes to prove to Victor that
$P(z_i) = y_i$ for $1 <= i <= n$.

#algorithm[Opening a KZG commitment at $n$ values][
  1. By Lagrange interpolation, both parties agree on a polynomial $f(T)$
    such that $f(z_i) = y_i$.
  2. Penny does polynomial long division to get $Q(T)$ such that
    $ P(T) - f(T) = (T-z_1)(T-z_2) ... (T-z_n) dot Q(T). $
  3. Penny sends the single element $[Q(s)]$ as her proof.
  4. Victor verifies
    $ pair([Q(s)], [(s-z_1)(s-z_2) ... (s-z_n)]) = pair([P(s)] - [I(s)], [1]). $
]

So one can even open the polynomial $P$ at $1000$ points with a single 256-bit proof.
The verification runtime is a single pairing plus however long
it takes to compute the Lagrange interpolation $f$.

== So which curves are pairing-friendly? <pairing-friendly>

If we chose $E$ to be BN254, the following property holds:

#proposition[
  For $(p,q)$ as in BN254,
  the smallest integer $k$ such that $q$ divides $p^k-1$ is $k=12$.
]

This integer $k$ is called the *embedding degree*.
This section is an aside explaining how the embedding degree affects pairing.

#todo[write this section, describing
  the #link("https://en.wikipedia.org/wiki/Weil_pairing", "Weil pairing").
]
