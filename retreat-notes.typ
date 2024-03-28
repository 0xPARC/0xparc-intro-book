#import "@local/evan:1.0.0":*

#show: evan.with(
  title: "Notes from 0xPARC Retreat",
  subtitle: none,
  author: "Evan Chen",
  date: datetime.today(),
)

#toc

= Commitment schemes

== Discrete logarithm is hard

=== The discrete log problem

Let $E$ be an elliptic curve.
Given arbitrary nonzero $g, g' in E$,
it's hard to find $n$ such that $n dot g = g'$.

In other words, if one only
sees $g in E$ and $n dot g in E$, one cannot find $n$.

(This is called discrete log because when $E$ is replaced by an abelian group
written multiplicatively, it looks like solving $g^n = g'$ instead.
We will never use this multiplicative notation.)

=== Vectors

One upshot of this is that if $g_1, ..., g_m in E$ are a bunch of points,
then it's infeasible to find
$(a_1, ..., a_m) != (b_1, ..., b_m) in ZZ^m$ such that
$ a_1 g_1 + ... + a_m g_m = b_1 g_1 + ... + b_m g_m. $
Indeed, even if one fixes any choice of $2m-1$ of the $2m$ coefficients above,
one cannot find the last coefficient.

In these notes, if there's a globally known elliptic curve $E$
and points $g_1, ..., g_n$ with no known dependencies between them,
we'll say they're "practically independent".

=== Petersen commitments

Let $g_1, ..., g_n in E$ be "practically independent".
If one has a vector $angle.l a_1, ..., a_n angle.r in FF_p^n$ of scalars,
one can "commit" the vector by sending $sum a_i g_i in E$.
This actually acts like a hash of the vector with shorter length
(with "practically independent" now being phrased as
"we can't find a collision").

It turns out the Petersen commitment will work natively with IPA later on.

== Kate commitment

=== Elliptic curve setup

==== Generator

We fix an elliptic curve $E$ over a finite field $FF_q$
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

==== Trusted calculation

To set up the Kate commitment scheme,
a trusted computer needs to pick a secret scalar $s in FF_p$ and publishes
$ [s^0], [s^1], ..., [s^N] $
for some large $N$.
(This only needs to be done once for the curve $E$.)
These published points are considered globally known
so anyone can evaluate $[P(s)]$ for any given polynomial $P$.
(For example, $[s^2+8s+6] = [s^2] + 8[s] + 6[1]$.)
Meanwhile, the secret scalar $s$ is never revealed to anyone.

=== Commitment scheme

==== Protocol

Suppose Peggy has a polynomial $P(T) in FF_p [T]$.
She commits to it by evaluating $[P(s)]$,
which she may do because $[s^i]$ is globally known.

Now consider an input $x in FF_p$,
where Peggy wishes to convince Victor that $P(z) = y$.
To show $y in FF_p$, Peggy does polynomial division to derive $Q$ such that
$ P(T)-y = (T-z) Q(T) $
and sends the value of $[Q(s)]$,
which again she can compute (without knowing $s$)
from the globally known trusted calculation.

Victor then verifies by checking
$ e([Q(s)], [s-z]) = e([P(s)-y], [1]). $

==== Soundness (heuristic argument)

If $y != P(z)$, then Peggy can't do the polynomial long division described above.
So to cheat Victor, she needs to otherwise find an element
$ 1/(s-x) ([P(s)]-[y]) in E. $
Since $s$ is a secret nobody knows, there isn't any known way to do this.

== IPA stuff

Let $E$ be an elliptic curve over $FF_p$
and we have fixed globally known generators
$g_1, ..., g_n, h_1, ..., h_n, u in E$ which are "practically independent".

=== Goal of Inner Product Argument

As we mentioned before, an element of the form
$ a_1 g_1 + ... + a_n g_n + b_1 h_1 + ... + b_n h_n + c u in E $
where $a_1, ..., a_n, b_1, ..., b_n, c in FF_p$,
is practically a vector of length $2n + 1$, as discussed earlier.
(If you like terminology, it's a Petersen commitment of such a vector.)

#definition[
  Let's say that an element
  $ v = a_1 g_1 + ... + a_n g_n + b_1 h_1 + ... + b_n h_n + c u in E $
  is *good* if $sum_1^n a_i b_i = c$.
]

The Inner Product Argument (IPA) is a protocol that kind of
resembles Sum-Check in spirit: Penny and Victor will do a series of interactions
which allow Peggy to prove to Victor that $v$ is good
(without having to reveal all $a_i$'s, $b_i$'s, and $c$).

(I think we missed a chance to call this "Inner Product Interactive Proof
Inductive Protocol" or something cute like this,
but I'm late to the party.)

=== The interactive induction of IPA

The way IPA is done is by induction:
one reduces verifying a vector for $n$ is good (hence $2n+1$ length)
by verifying a vector for $n/2$ is good (of length $n+1$).
The base case $n=1$ (with three basis elements $g_1$, $h_1$, $u$) is straightforward:
Victor simply demands from Peggy the values of $a_1$ and $b_1$
and verifies $v = a_1 g_1 + b_1 h_1 + a_1 b_1 u$.

Now, to illustrate the induction, we'll first show how to get from $n=2$ to $n=1$.
So the given input to the protocol is
$ v = a_1 g_1 + a_2 g_2 + b_1 h_1 + b_2 h_2 + c u $
which has the basis $angle.l g_1, g_2, h_1, h_2, u angle.r$.
The idea is that we want to construct a new (good) vector $w$ whose basis is
$ angle.l (g_1 + x^(-1) g_2), (h_1 + x h_2), u angle.r $
for a random $x in FF_p$.

The construction is the following vector:
$ w(x) &:= (a_1 + x a_2) dot underbrace((g_1 + x^(-1) g_2), "basis")
  + (b_1 + x^(-1) b_2) dot underbrace((h_1 + x h_2), "basis")
  + (a_1 + x a_2)(b_1 + x^(-1) b_2) underbrace(u, "basis"). $
Expanding and isolating the parts with $x$ and $x^(-1)$ gives
$ w(x)
  &= (a_1 g_1 + a_2 g_2 + b_1 h_1 + b_2 h_2 + c u) \
  &#h(1em) + x dot underbrace((a_2 g_1 + b_1 h_2 + a_2 b_1 u), =: w_L)
  + x^(-1) dot underbrace((a_1 g_2 + b_2 h_1 + a_1 b_2 u), =: w_R) \
  &= v + x dot w_L + x^(-1) dot w_R.
  $
Note that, importantly, $w_L$ and $w_R$ don't depend on $x$.
So this gives a way to provide a construction of a good vector $w$
of half the length (in the new basis) given a good vector $v$.

This suggests the following protocol: Peggy, who knows the $a_i$'s, computes
$w_L := a_2 g_1 + b_1 h_2 + a_2 b_1 u$ and $w_R := a_1 g_2 + b_2 h_1 + a_1 b_2 u$,
and sends those values to Victor (this doesn't depend on $x$).
Then Victor picks a random value of $x$ and defines
$ w(x) = v + x dot w_L + x^(-1) dot w_R. $
Assume Peggy is truthful and $v$ was indeed good with respect
to the original 5-element basis for $n=2$, the resulting $w(x)$
is good with respect to the smaller $3$-element basis for $n=1$.

The interesting part is soundness:

#claim[
  Suppose $v = a_1 g_1 + a_2 g_2 + b_1 h_1 + b_2 h_2 + c u$ is given.
  Assume further that Peggy can provide some $w_L, w_R in E$ in this basis such that
  $ w(x) := v + x dot w_L + x^(-1) dot w_R $
  is good for at least four values of $x$.

  Then all of the following statements must hold for this property to occur:
  - $w_L = a_2 g_1 + b_1 h_2 + a_2 b_1 u$,
  - $w_R = a_1 g_2 + b_2 h_1 + a_1 b_2 u$,
  - $c = a_1 b_1 + a_2 b_2$, i.e., $v$ is good.
]

#proof[
  At first, it might seem like a cheating prover has too many parameters
  they could play with to satisfy too few conditions.
  The trick is that $x$ is really like a formal variable,
  and even the requirement that $w(x)$ lies in the span of
  $ angle.l (g_1 + x^(-1) g_2), (h_1 + x h_2), u angle.r $
  is going to determine almost all the coefficients of $w_L$ and $w_R$.

  To be explicit, suppose a cheating prover tried to provide
  $ w_L &= ell_1 g_1 + ell_2 g_2 + ell_3 h_1 + ell_4 h_2 + ell_5 \
    w_R &= r_1 g_1 + r_2 g_2 + r_3 h_1 + r_4 h_2 + r_5. $
  Then we can compute
  $ w(x) &= v + x dot w_L + x^(-1) dot w_R \
    &= (a_1 + x ell_1 + x^(-1) r_1)g_1 + (a_2 + x ell_2 + x^(-1) r_2)g_2 \
    &+ (b_1 + x ell_3 + x^(-1) r_3)h_1 + (b_2 + x ell_4 + x^(-1) r_4)h_1 \
    &+ (c + x ell_5 + x^(-1) r_5)u. $
  In order to lie in the span we described, one needs the coefficient of $g_1$
  to be $x$ times the coefficient of $g_2$, that is
  $ x^(-1) r_1 + a_1 + x ell_1 = r_2 + x a_2 + x^2 ell_2. $
  Since this holds for more than three values of $x$,
  the two sides must actually be equal coefficient by coefficient.
  This means that $ell_1 = a_2$, $r_2 = a_1$, and $r_1 = ell_2 = 0$.
  In the same way, we get $ell_4 = b_1$, $r_3 = b_2$, and $ell_3 = r_4 = 0$.

  So just to lie inside the span,
  the cheating prover's hand is already forced for all the coefficients
  other than the $ell_5$ and $r_5$ in front of $u$.
  Then indeed the condition that $w(x)$ is good is that
  $ (a_1 + x a_2) (b_1 + x^(-1) b_2) = c + x ell_5 + x^(-1) r_5. $
  Comparing the constant coefficients we see that $c = a_1 b_1 + a_2 b_2$ as
  desired. (One also can recover $ell_5$ and $r_5$, but we never use this.)
]

So we've shown completeness and soundness for our protocol reducing $n=2$ to $n=1$.
The general situation is basically the same with more notation:
if $n = 6$, for example, and we have
$v = a_1 g_1 + ... + a_6 g_6 + b_1 h_1 + ... + b_6 h_6 + c u $
then we replace the length-thirteen basis with the length-seven one
$ angle.l
  g_1 + x^(-1) g_4,
  g_2 + x^(-1) g_5,
  g_3 + x^(-1) g_6,
  h_1 + x h_4,
  h_2 + x h_5,
  h_3 + x h_6,
  u
  angle.r $
and the relevant $w_L$ and $w_R$ are
$ w_L &= (a_4 g_1 + a_5 g_2 + a_6 g_3) + (b_1 h_4 + b_2 h_5 + b_3 h_6)
  + (a_1 b_4 + a_2 b_5 + a_3 b_6) u \
  w_R &= (a_1 g_4 + a_2 g_5 + a_3 g_6) + (b_4 h_1 + b_5 h_2 + b_6 h_3)
  + (a_4 b_1 + a_5 b_2 + a_6 b_3) u. $
And $w(x) = v + x dot w_L + x^(-1) dot w_R$ as before.

=== Using IPA for a polynomial commitment scheme

Suppose now $P(T) = sum a_i T^(i-1)$ is given polynomial.
Then Peggy could get a scheme resembling Kate commitments as follows:

- Peggy publishes Petersen commitment of the coefficients of $P$,
  that is $v = sum a_i g_i in E$.
- Suppose Victor wants to open the commitment at a value $z$,
  and Peggy asserts that $P(z) = y$.
- Victor picks a random constant $lambda in FF_p$.
- Both parties compute
  $ underbrace((a_1 g_1 + ... + a_n g_n), v)
  + (lambda z^0 h_1 + ... + lambda z^(n-1) h_n) + lambda y u $
  and run IPA on it.

When Peggy does a vanilla IPA, she can keep all $2n+1$ coefficients secret.
Here, Peggy is fine to reveal the latter $n+1$ numbers
(because they are just powers of $z$ and the claimed $y$)
as they don't leak any other information;
she still gets to keep her coefficients $a_n$ private from Victor.

The introduction of the hacked constant $c$ might be a bit of a surprise.
The reason is that without it, there is an amusing loophole that Peggy can exploit:
Peggy can pick the vector $v$ after all.
So suppose Peggy tries to swindle Victor by reporting
$v = a_1 g_1 + ... + a_n g_n - 10 u$ instead
of the honest $v = a_1 g_1 + ... + a_n g_n$.
Then, Peggy inflates all the values of $y$ she claims to Victor by $10$.
This would allow Peggy to cheat Victor into committing the polynomial $P$
but given any $z$ giving Victor the value of $P(z) + 10$  rather than $P(z)$.
The addition of the shift $lambda$ prevents this attack.

#pagebreak()
