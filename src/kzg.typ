= KZG commitments
<kzg>
The goal of a #emph[polynomial commitment scheme] is to have the
following API:

- Peggy has a secret polynomial $P (X) in bb(F)_q \[ X \]$.

- Peggy sends a short “commitment” to the polynomial (like a hash).

- This commitment should have the additional property that Peggy should
  be able to “open” the commitment at any $z in bb(F)_q$. Specifically:

  - Victor has an input $z in bb(F)_q$ and wants to know $P (z)$.

  - Peggy knows $P$ so she can compute $P (z)$; she sends the resulting
    number $y = P (z)$ to Victor.

  - Peggy can then send a short “proof” convincing Victor that $y$ is
    the correct value, without having to reveal $P$.

The #emph[Kate-Zaverucha-Goldberg (KZG)] commitment scheme is amazingly
efficient because both the commitment and proof lengths are a single
point on $E$, encodable in 256 bits, no matter how many coefficients the
polynomial has.

== The setup
Remember the notation $\[ n \] colon.eq n dot.op g in E$ defined in
@armor. To set up the KZG commitment scheme, a trusted party needs to
pick a secret scalar $s in bb(F)_q$ and publish
$ [s^0] \, [s^1] \, dots.h \, [s^M] $ for some large $M$, the maximum
degree of a polynomial the scheme needs to support. This means anyone
can evaluate $[P (s)]$ for any given polynomial $P$ of degree up to $M$.
For example, $ [s^2 + 8 s + 6] = [s^2] + 8 \[ s \] + 6 \[ 1 \] . $
Meanwhile, the secret scalar $s$ is never revealed to anyone.

The setup only needs to be done by a trusted party once for the curve
$E$. Then anyone in the world can use the resulting sequence for KZG
commitments.

rectangle\[ fill: fill, inset: 1em, radius: 0.25em, stroke: black,

\]( strong(title) + “ “ + body )

== The KZG commitment scheme
Peggy has a polynomial $P (X) in bb(F)_p \[ X \]$. To commit to it:

rectangle\[ fill: fill, inset: 1em, radius: 0.25em, stroke: black,

\]( strong(title) + “ “ + body )

This computation is possible as $[s^i]$ are globally known.

Now consider an input $z in bb(F)_p$; Victor wants to know the value of
$P (z)$. If Peggy wishes to convince Victor that $P (z) = y$, then:

rectangle\[ fill: fill, inset: 1em, radius: 0.25em, stroke: black,

\]( strong(title) + “ “ + body )

If Peggy is truthful, then @kzg-verify will certainly check out.

If $y eq.not P (z)$, then Peggy cannot do the polynomial long division
described above. So to cheat Victor, she needs to otherwise find an
element $ frac(1, s - x) ([P (s)] - \[ y \]) in E . $ Since $s$ is a
secret nobody knows, there is not any known way to do this.

== Multi-openings
<multi-openings>
To reveal $P$ at a single value $z$, we did polynomial division to
divide $P (X)$ by $X - z$. But there is no reason we have to restrict
ourselves to linear polynomials; this would work equally well with
higher-degree polynomials, while still using only a single 256-bit curve
point for the proof.

For example, suppose Peggy wanted to prove that $P (1) = 100$,
$P (2) = 400$, …, $P (9) = 8100$. (We chose these numbers so that
$P (X) = 100 X^2$ for $X = 1 \, dots.h \, 9$.)

Evaluating a polynomial at $1 \, 2 \, dots.h \, 9$ is essentially the
same as dividing by $(X - 1) (X - 2) dots.h (X - 9)$ and taking the
remainder. In other words, if Peggy does a polynomial long division, she
will find that
$ P (X) = Q (X) ((X - 1) (X - 2) dots.h (X - 9)) + 100 X^(2 .) $ Then
Peggy sends $[Q (s)]$ as her proof, and the verification equation is
that $  & "pair" ([Q (s)] \, [(s - 1) (s - 2) dots.h (s - 9)])\
 & = "pair" ([P (s)] - 100 [s^2] \, \[ 1 \]) . $

The full generality just replaces the $100 X^2$ with the polynomial
obtained from Lagrange
interpolation#footnote[https:\/\/en.wikipedia.org/wiki/Lagrange\_polynomial]
(there is a unique such polynomial $f$ of degree $n - 1$). To spell this
out, suppose Peggy wishes to prove to Victor that $P (z_i) = y_i$ for
$1 lt.eq i lt.eq n$.

rectangle\[ fill: fill, inset: 1em, radius: 0.25em, stroke: black,

\]( strong(title) + “ “ + body )

So one can even open the polynomial $P$ at $1000$ points with a single
256-bit proof. The verification runtime is a single pairing plus however
long it takes to compute the Lagrange interpolation $f$.

== Root check
To make PLONK work, we are going to need a small variant of the
multi-opening protocol for KZG commitments
(#link(<multi-openings>)[\[multi-openings\]];), which we call #emph[root
check] (not a standard name). Here is the problem statement:

rectangle\[ fill: fill, inset: 1em, radius: 0.25em, stroke: black,

\]( strong(title) + “ “ + body )

Peggy just needs to show that $P_1 - P_2$ is divisible by
$Z (X) colon.eq product_(z in S) (X - z)$. This can be done by
committing the quotient
$ H (X) colon.eq frac(P_1 (X) - P_2 (X), Z (X)) . $ Victor then gives a
random challenge $lambda in bb(F)_q$, and then Peggy opens
$"Com" (P_1)$, $"Com" (P_2)$, and $"Com" (H)$ at $lambda$.

But we can actually do this more generally with #emph[any] polynomial
expression $F$ in place of $P_1 - P_2$, as long as Peggy has a way to
prove the values of $F$ are correct. As an artificial example, if Peggy
has sent Victor $"Com" (P_1)$ through $"Com" (P_6)$, and wants to show
that
$ P_1 (42) + P_2 (42) P_3 (42)^4 + P_4 (42) P_5 (42) P_6 (42) = 1337 \, $
she could define
$ F (X) colon.eq P_1 (X) + P_2 (X) P_3 (X)^4 + P_4 (X) P_5 (X) P_6 (X) - 1337 $
and run the same protocol with this $F$. This means she does not have to
reveal any $P_i (42)$, which is great!

To be fully explicit, here is the algorithm:

rectangle\[ fill: fill, inset: 1em, radius: 0.25em, stroke: black,

\]( strong(title) + “ “ + body )

<root-check>
