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

For this scheme we need an elliptic curve $E$ and a fixed generator $g$ of it,
and some points on the curve.
The good news is that this can be done just once, period.
After that, anyone in the world can use the published data to run this protocol.

=== The notation $[n]$

Fix an elliptic curve $E$ over a finite field $FF_q$
and a globally known generator $g in E$.
For $n in ZZ$ define
$ [n] := n dot g. $
The hardness of discrete logarithm means that, given $[n]$, we cannot get $n$.
You can almost think of the notation as an "armor" on the integer $n$:
it conceals the integer, but still allows us to perform (armored) addition:
$ [a+b] = [a] + [b]. $

Multiplication can't be done directly, in the sense there isn't a way to get
$[a b]$ given $[a]$ and $[b]$.
We work around this with a so-called _pairing_, defined a bit later.

=== Pairing

On the curve $E$ one needs a *pairing* which is a nondegenerate bilinear function
$ "pair" : E times E -> ZZ slash N ZZ $
for some large integer $N$.
One example of a construction is the so-called
#link("https://en.wikipedia.org/wiki/Weil_pairing", "Weil pairing").
Like with the previous setup,
this only needs to be done once for the curve $E$,
and then anyone in the world can use the published curve for their protocol.

The exact details of how this pairing is constructed won't matter below.
But the upshot is that the equation
$ "pair"([m], [n]) = "pair"([m'], [n']) $
will be true whenever $m n = m' n'$,
because both sides will equal $m n "pair"([1], [1])$.
So this gives us at least a way to verify multiplication.

=== Trusted calculation

To set up the Kate commitment scheme,
a trusted party also needs to pick a secret scalar $s in FF_p$ and publishes
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
      $ e([Q(s)], [s-z]) = e([P(s)-y], [1]) $
      <kzg-verify>
    ]
    and accepts if and only if @kzg-verify is true.
]

If Penny is truthful, then @kzg-verify will certainly check out.

If $y != P(z)$, then Penny can't do the polynomial long division described above.
So to cheat Victor, she needs to otherwise find an element
$ 1/(s-x) ([P(s)]-[y]) in E. $
Since $s$ is a secret nobody knows, there isn't any known way to do this.
