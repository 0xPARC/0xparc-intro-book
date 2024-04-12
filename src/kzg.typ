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

== Elliptic curve setup done once

The good news is that this can be done just once, period.
After that, anyone in the world can use the published data to run this protocol.

For concreteness, $E$ will be the BN256 curve and $g$ a fixed generator.

=== The notation $[n]$

We retain the notation $[n] := n dot g in E$ defined in @armor,
so $[bullet] : FF_q -> E$ is linear.

=== Pairing

Unfortunately, multiplication can't be done directly,
in the sense there isn't a way to get
$[a b]$ given $[a]$ and $[b]$.
But we work around this with a so-called _pairing_, defined a bit later.

On the curve $E$ one needs a *pairing* which is a nondegenerate bilinear function
$ pair : E times E -> ZZ slash N ZZ $
for some large integer $N$.
One example of a construction is the so-called
#link("https://en.wikipedia.org/wiki/Weil_pairing", "Weil pairing").
Like with the previous setup,
this only needs to be done once for the curve $E$,
and then anyone in the world can use the published curve for their protocol.

#todo[I'm still a bit confused whether this requires changing $FF$. Is $N = q$?]

The exact details of how this pairing is constructed won't matter below.
But the upshot is that the equation
$ "pair"([m], [n]) = "pair"([m'], [n']) $
will be true whenever $m n = m' n'$,
because both sides will equal $m n "pair"([1], [1])$.
So this gives us at least a way to _verify_ a statement about multiplication.

#remark[
  The last sentence is worth bearing in mind: in all the protocols we'll see,
  the pairing is only used by the _verifier_ Victor, never by the prover Penny.
]

#remark[
  On the other hand, we currently don't seem to know a good
  way to do _multilinear_ pairings.
  For example, we don't know a good trilinear map
  $E times E times E -> ZZ slash n ZZ$
  that would allow us to compare $[a b c]$, $[a]$, $[b]$, $[c]$.
]

=== Trusted calculation

To set up the KZG commitment scheme,
a trusted party needs to pick a secret scalar $s in FF_q$ and publishes
$ [s^0], [s^1], ..., [s^N] $
for some large $N$.
This means anyone can evaluate $[P(s)]$ for any given polynomial $P$.
(For example, $[s^2+8s+6] = [s^2] + 8[s] + 6[1]$.)
Meanwhile, the secret scalar $s$ is never revealed to anyone.

This only needs to be done by a trusted party once for the curve $E$.
Then anyone in the world can use the resulting sequence for KZG commitments.

== The KZG commitment scheme

Penny has a polynomial $P(T) in FF_p [T]$.
To commit to it:

#algorithm("Creating a KZG commitment")[
  1. Penny computes and publishes $[P(s)]$.
     (This computation is possible as $[s^i]$ are globally known.)
]

Now consider an input $z in FF_p$; Victor wants to know the value of $P(z)$.
If Penny wishes to convince Victor that $P(z) = y$, then:

#algorithm("Opening a KZG commitment")[
  1. Penny does polynomial division to compute $Q(T) in FF_q [T]$ such that
    $ P(T)-y = (T-z) Q(T). $
  2. Penny computes and sends Victor $[Q(s)]$,
    which again she can compute from the globally known $[s^i]$.
  3. Victor verifies by checking
    #eqn[
      $ "pair"([Q(s)], [s-z]) = "pair"([P(s)-y], [1]) $
      <kzg-verify>
    ]
    and accepts if and only if @kzg-verify is true.
]

If Penny is truthful, then @kzg-verify will certainly check out.

If $y != P(z)$, then Penny can't do the polynomial long division described above.
So to cheat Victor, she needs to otherwise find an element
$ 1/(s-x) ([P(s)]-[y]) in E. $
Since $s$ is a secret nobody knows, there isn't any known way to do this.
