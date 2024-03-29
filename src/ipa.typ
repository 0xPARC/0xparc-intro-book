#import "preamble.typ":*

= Inner product arguments (IPA)

This chapter requires the earlier chapter on the discrete logarithm problem and
Petersen commitments.
Let $E$ be an elliptic curve over $FF_p$
and we have fixed globally known generators
$g_1, ..., g_n, h_1, ..., h_n, u in E$ which are "practically independent".

We'll start by describing the goal of the general IPA protocol
and how to implement it.,
Then we'll show some use cases for IPA:

- Polynomial commitments in the style of KZG are a special case.
- TODO: Problem 6 applications go here

== Pitch: IPA allows verifying $c = sum a_i b_i$ without revealing $a_i$ and $b_i$

As we mentioned before, an element of the form
$ a_1 g_1 + ... + a_n g_n + b_1 h_1 + ... + b_n h_n + c u in E $
where $a_1, ..., a_n, b_1, ..., b_n, c in FF_p$,
is practically a vector of length $2n + 1$, as discussed earlier.
(If you like terminology, it's a Petersen commitment.)

#definition[
  Let's say that an element
  $ v = a_1 g_1 + ... + a_n g_n + b_1 h_1 + ... + b_n h_n + c u in E $
  is *good* if $sum_1^n a_i b_i = c$.
]

The Inner Product Argument (IPA) is a protocol that kind of
resembles Sum-Check in spirit: Penny and Victor will do a series of interactions
which allow Penny to prove to Victor that $v$ is good.
And Penny will be able to do this without
having to reveal all of the $a_i$'s, $b_i$'s, and $c$.

(I think we missed a chance to call this "Inner Product Interactive Proof
Inductive Protocol" or something cute like this,
but I'm late to the party.)

== The interactive induction of IPA

The way IPA is done is by induction:
one reduces verifying a vector for $n$ is good (hence $2n+1$ length)
by verifying a vector for $n/2$ is good (of length $n+1$).

To illustrate the induction, we'll first show how to get from $n=2$ to $n=1$.
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

This suggests the following protocol: Penny, who knows the $a_i$'s, computes
$w_L := a_2 g_1 + b_1 h_2 + a_2 b_1 u$ and $w_R := a_1 g_2 + b_2 h_1 + a_1 b_2 u$,
and sends those values to Victor (this doesn't depend on $x$).
Then Victor picks a random value of $x$ and defines
$ w(x) = v + x dot w_L + x^(-1) dot w_R. $
Assume Penny is truthful and $v$ was indeed good with respect
to the original 5-element basis for $n=2$, the resulting $w(x)$
is good with respect to the smaller $3$-element basis for $n=1$.

The interesting part is soundness:

#claim[
  Suppose $v = a_1 g_1 + a_2 g_2 + b_1 h_1 + b_2 h_2 + c u$ is given.
  Assume further that Penny can provide some $w_L, w_R in E$ in this basis such that
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
  Comparing the constant coefficients we see that $c = a_1 b_1 + a_2 b_2$ as desired.
  (One also can recover $ell_5 = a_2 b_1$ and $r_5 = a_1 b_2$,
  but we never actually use this.)
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

== The base case

TODO (this is the argument with $mu$ and $lambda$ that Aard mentioned)

== Polynomial commitment scheme is a special case of IPA

Suppose now $P(T) = sum a_i T^(i-1)$ is given polynomial.
Then Penny could get a scheme resembling KGZ commitments as follows:

- Penny publishes Petersen commitment of the coefficients of $P$,
  that is Penny publishes $ g := sum a_i g_i in E. $
- Suppose Victor wants to open the commitment at a value $z$,
  and Penny asserts that $P(z) = y$.
- Victor picks a random constant $lambda in FF_p$.
- Both parties compute
  $ v := underbrace((a_1 g_1 + ... + a_n g_n), C)
  + (lambda z^0 h_1 + ... + lambda z^(n-1) h_n) + lambda y u $
  and run IPA on it.

(When Penny does a vanilla IPA protocol, she can keep all $2n+1$ coefficients secret.
In this context, Penny has published the first part $g$
and still gets to keep her coefficients $a_n$ private from Victor.
The other $n+1$ coefficients are globally known because
they're inputs to the protocol for opening the commitment at $z$.)

The introduction of the hacked constant $lambda$ might be a bit of a surprise.
The reason is that without it, there is an amusing loophole that Penny can exploit:
Penny can pick the vector $v$ after all.
So suppose Penny tries to swindle Victor by reporting
$v = a_1 g_1 + ... + a_n g_n - 10 u$ instead
of the honest $v = a_1 g_1 + ... + a_n g_n$.
Then, Penny inflates all the values of $y$ she claims to Victor by $10$.
This would allow Penny to cheat Victor into committing the polynomial $P$
but given any $z$ giving Victor the value of $P(z) + 10$  rather than $P(z)$
(though the cheating offset would be the same at every value she opened).
The addition of the offset $lambda$ prevents this attack.
