= Kate-Zaverucha-Goldberg (KGZ) commitments

This chapter requires reading the earlier chapter on discrete logarithm.

== Pitch: KZG lets you commit a polynomial and reveal individual values

The goal of the KGZ commitment schemes is to have the following API:

- Penny has a secret polynomial $P(T) in FF_q [T]$.
- Penny sends a short "commitment" the polynomial, which is a hash.
- This commitment should have the additional property that
  Penny should be able to "open" the commitment at any $z in FF_q$:
  Specifically:

  - Victor has an input $z in FF_q$ and wants to know $P(z)$.
  - Peggy knows $P$ so she can compute $P(z)$;
    she sends the resulting number $y = P(z)$ to Victor.
  - Peggy can then send a short "proof" convincing Victor that $y$ is the
    correct value, without having to reveal $P$.

We describe the protocol here.

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
However, the _pairing_ on the elliptic curve allows us to sidestep this by
defining a nondegenerate bilinear function
$ e : E times E -> ZZ slash N ZZ $
for some large $N$.
(This seems to be most commonly done via the Weil pairing.
It may require replacing $FF_q$ with $FF_(q^n)$ or something?
I'm unsure of the details.)

=== Trusted calculation

To set up the Kate commitment scheme,
a trusted computer needs to pick a secret scalar $s in FF_p$ and publishes
$ [s^0], [s^1], ..., [s^N] $
for some large $N$.
(This only needs to be done once for the curve $E$.)
These published points are considered globally known
so anyone can evaluate $[P(s)]$ for any given polynomial $P$.
(For example, $[s^2+8s+6] = [s^2] + 8[s] + 6[1]$.)
Meanwhile, the secret scalar $s$ is never revealed to anyone.

== The KZG commitment scheme

Penny has a polynomial $P(T) in FF_p [T]$.
She commits to it by evaluating $[P(s)]$,
which she may do because $[s^i]$ is published and globally known.

Now consider an input $x in FF_p$,
where Penny wishes to convince Victor that $P(z) = y$.
To show $y in FF_p$, Penny does polynomial division to derive $Q$ such that
$ P(T)-y = (T-z) Q(T) $
and sends the value of $[Q(s)]$,
which again she can compute (without knowing $s$)
from the globally known trusted calculation.

Victor then verifies by checking
$ e([Q(s)], [s-z]) = e([P(s)-y], [1]). $

== Soundness of protocol (heuristic argument)

If $y != P(z)$, then Penny can't do the polynomial long division described above.
So to cheat Victor, she needs to otherwise find an element
$ 1/(s-x) ([P(s)]-[y]) in E. $
Since $s$ is a secret nobody knows, there isn't any known way to do this.