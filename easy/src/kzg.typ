#import "preamble.typ":*

= KZG commitments <kzg>

The goal of a _polynomial commitment scheme_ is to have the following API:

- Peggy has a secret polynomial $P(X) in FF_q [X]$.
- Peggy sends a short "commitment" to the polynomial (like a hash).
- This commitment should have the additional property that
  Peggy should be able to "open" the commitment at any $z in FF_q$.
  Specifically:

  - Victor has an input $z in FF_q$ and wants to know $P(z)$.
  - Peggy knows $P$ so she can compute $P(z)$;
    she sends the resulting number $y = P(z)$ to Victor.
  - Peggy can then send a short "proof" convincing Victor that $y$ is the
    correct value, without having to reveal $P$.

The _Kate-Zaverucha-Goldberg (KZG)_ commitment scheme is amazingly efficient because both the commitment and proof lengths are a single point on $E$, encodable in 256 bits.

== The setup

Remember the notation $[n] := n dot g in E$ defined in @armor. To set up the KZG commitment scheme,
a trusted party needs to pick a secret scalar $s in FF_q$ and publishes
$ [s^0], [s^1], ..., [s^M] $
for some large $M$, the maximum degree of a polynomial the scheme needs to support.
This means anyone can evaluate $[P(s)]$ for any given polynomial $P$ of degree up to $M$.
For example, $ [s^2+8s+6] = [s^2] + 8[s] + 6[1]. $
Meanwhile, the secret scalar $s$ is never revealed to anyone.

The setup only needs to be done by a trusted party once for the curve $E$.
Then anyone in the world can use the resulting sequence for KZG commitments.

#remark[
  The trusted party has to delete $s$ after the calculation.
  If anybody knows the value of $s$, the protocol will be insecure.
  The trusted party will only publish $[s^0] = [1], [s^1], ..., [s^M]$.
  This is why we call them "trusted":
  the security of KZG depends on them not saving the value of $s$.

  Given the published values, it is (probably) extremely hard to recover $s$ --
  this is a case of the discrete logarithm problem.

  You can make the protocol somewhat more secure by involving several different trusted parties.
  The first party chooses a random $s_1$, computes $[s_1^0], ..., [s_1^M]$,
  and then discards $s_1$.
  The second party chooses $s_2$ and computes
  $[(s_1 s_2)^0], ..., [(s_1 s_2)^M]$.
  And so forth.
  In the end, the value $s$ will be the product of the secrets $s_i$
  chosen by the $i$ parties... so the only way they can break secrecy
  is if all the "trusted parties" collaborate.
]

#pagebreak() // TODO manual pagebreak for printed easy; stopgap hack

== The KZG commitment scheme

Peggy has a polynomial $P(X) in FF_p [X]$.
To commit to it:

#algorithm("Creating a KZG commitment")[
  1. Peggy computes and publishes $[P(s)]$.
]
This computation is possible as $[s^i]$ are globally known.

Now consider an input $z in FF_p$; Victor wants to know the value of $P(z)$.
If Peggy wishes to convince Victor that $P(z) = y$, then:

#algorithm("Opening a KZG commitment")[
  1. Peggy does polynomial division to compute $Q(X) in FF_q [X]$ such that
    $ P(X)-y = (X-z) Q(X). $
  2. Peggy computes and sends Victor $[Q(s)]$,
    which again she can compute from the globally known $[s^i]$.
  3. Victor verifies by checking
    #eqn[
      $ pair([Q(s)], [s]-[z]) = pair([P(s)]-[y], [1]) $
      <kzg-verify>
    ]
    and accepts if and only if @kzg-verify is true.
]

If Peggy is truthful, then @kzg-verify will certainly check out.

If $y != P(z)$, then Peggy can't do the polynomial long division described above.
So to cheat Victor, she needs to otherwise find an element
$ 1/(s-x) ([P(s)]-[y]) in E. $
Since $s$ is a secret nobody knows, there isn't any known way to do this.

== Multi-openings <multi-openings>

To reveal $P$ at a single value $z$, we did polynomial division
to divide $P(X)$ by $X-z$.
But there's no reason we have to restrict ourselves to linear polynomials;
this would work equally well with higher-degree polynomials,
while still using only a single 256-bit curve point for the proof.

For example, suppose Peggy wanted to prove that
$P(1) = 100$, $P(2) = 400$, ..., $P(9) = 8100$.
(We chose these numbers so that $P(X) = 100 X^2$
for $X = 1, dots, 9$.)

Evaluating a polynomial at $1, 2, dots, 9$ is essentially the same
as dividing by $(X-1)(X-2) dots (X-9)$ and taking the remainder.
In other words, if Peggy does a polynomial long division, she will find that
$
  P(X) = Q(X) ( (X-1)(X-2) dots (X-9) ) + 100 X^2.
$
Then Peggy sends $[Q(s)]$ as her proof, and the verification equation is that
$ & pair([Q(s)], [(s-1)(s-2) ... (s-9)]) \
  & = pair([P(s)] - 100[s^2], [1]). $

The full generality just replaces the $100X^2$ with the polynomial
obtained from #cite("https://en.wikipedia.org/wiki/Lagrange_polynomial", "Lagrange interpolation")
(there is a unique such polynomial $f$ of degree $n-1$).
To spell this out, suppose Peggy wishes to prove to Victor that
$P(z_i) = y_i$ for $1 <= i <= n$.

#algorithm[Opening a KZG commitment at $n$ values][
  1. By Lagrange interpolation, both parties agree on a polynomial $f(X)$
    such that $f(z_i) = y_i$.
  2. Peggy does polynomial long division to get $Q(X)$ such that
    $ P(X) - f(X) = (X-z_1)(X-z_2) ... (X-z_n) dot Q(X). $
  3. Peggy sends the single element $[Q(s)]$ as her proof.
  4. Victor verifies
    $ & pair([Q(s)], [(s-z_1)(s-z_2) ... (s-z_n)]) \
      & = pair([P(s)] - [f(s)], [1]). $
]

So one can even open the polynomial $P$ at $1000$ points with a single 256-bit proof.
The verification runtime is a single pairing plus however long
it takes to compute the Lagrange interpolation $f$.


== Root check (using long division with commitment schemes)

To make PLONK work, we're going to need a small variant
of the multi-opening protocol for KZG commitments (@multi-openings),
which we call _root-check_ (not a standard name).
Here's the problem statement:

#problem[
  Suppose one had two polynomials $P_1$ and $P_2$,
  and Peggy has given commitments $Com(P_1)$ and $Com(P_2)$.
  Peggy would like to prove to Victor that, say,
  the equation $P_1(z) = P_2(z)$ for all $z$ in some large finite set $S$.
]

Peggy just needs to show is that $P_1-P_2$
is divisible by $Z(X) := product_(z in S) (X-z)$.
This can be done by committing the quotient $H(X) := (P_1(X) - P_2(X)) / Z(X)$.
Victor then gives a random challenge $lambda in FF_q$,
and then Peggy opens $Com(P_1)$, $Com(P_2)$, and $Com(H)$ at $lambda$.

But we can actually do this more generally with _any_ polynomial
expression $F$ in place of $P_1 - P_2$,
as long as Peggy has a way to prove the values of $F$ are correct.
As an artificial example, if Peggy has sent Victor $Com(P_1)$ through $Com(P_6)$,
and wants to show that
$ P_1(42) + P_2(42) P_3(42)^4 + P_4(42) P_5(42) P_6(42) = 1337, $
she could define
$ F(X) := P_1(X) + P_2(X) P_3(X)^4 + P_4(X) P_5(X) P_6(X) - 1337 $
and run the same protocol with this $F$.
This means she doesn't have to reveal any $P_i (42)$, which is great!

To be fully explicit, here is the algorithm:

#algorithm[Root-check][
  Assume that $F$ is a polynomial for which
  Peggy can establish the value of $F$ at any point in $FF_q$.
  Peggy wants to convince Victor that $F$ vanishes on a given finite set $S subset.eq FF_q$.

  1. If she has not already done so, Peggy sends to Victor
    a commitment $Com(F)$ to $F$.#footnote[
      In fact, it is enough for Peggy to have some way
      to prove to Victor the values of $F$.

      So for example, if $F$ is a product of two polynomials
      $F = F_1 F_2$,
      and Peggy has already sent commitments to $F_1$ and $F_2$,
      then there is no need for Peggy to commit to $F$.

      Instead, in Step 5 below, Peggy opens $Com(F_1)$ and $Com(F_2)$ at $lambda$,
      and that proves to Victor the value of $F(lambda) = F_1 (lambda) F_2 (lambda)$.
    ]
  2. Both parties compute the polynomial
    $ Z(X) := product_(z in S) (X-z) in FF_q [X]. $
  3. Peggy does polynomial long division to compute $H(X) = F(X) / Z(X)$.
  4. Peggy sends $Com(H)$.
  5. Victor picks a random challenge $lambda in FF_q$
    and asks Peggy to open $Com(H)$ at $lambda$,
    as well as the value of $F$ at $lambda$.
  6. Victor verifies $F(lambda) = Z(lambda) H(lambda)$.
] <root-check>
