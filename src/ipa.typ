#import "preamble.typ":*

= The inner product argument (IPA) <ipa>

IPA is actually a lot more general than polynomial commitment.
So the roadmap is as follows:

- In @ipa-pitch, describe the API of the inner product argument.
- In @ipa-induct and @ipa-base, describe the protocol.
- In @ipa-app, show two other applications of IPA, as a side demo.
- In @ipa-poly, show how IPA can be used as a polynomial commitment scheme.

Throughout this section, $E$ is defined as in @notation,
and there are fixed globally known generators
$g_1, ..., g_n, h_1, ..., h_n, u in E$ which are a computational basis (@comp_basis).

== Pitch: IPA allows verifying $c = sum a_i b_i$ without revealing $a_i$, $b_i$, $c$ <ipa-pitch>

Consider Pedersen commitments of the form
$ a_1 g_1 + ... + a_n g_n + b_1 h_1 + ... + b_n h_n + c u in E $
where $a_1, ..., a_n, b_1, ..., b_n, c in FF_p$.

#definition[
  Let's say that an element
  $ v = a_1 g_1 + ... + a_n g_n + b_1 h_1 + ... + b_n h_n + c u in E $
  is *good*
  (with respect to the basis $angle.l g_1, ..., g_n, h_1, ..., h_n, u angle.r$)
  if $sum_1^n a_i b_i = c$.
]

The Inner Product Argument (IPA) is a protocol that kind of
resembles the older Sum-Check (described in @sumcheck) in spirit:
Peggy and Victor will do a series of interactions
which allow Peggy to prove to Victor that $v$ is good.
And Peggy will be able to do this without
having to reveal all of the $a_i$'s, $b_i$'s, and $c$.

(I think we missed a chance to call this "Inner Product Interactive Proof
Inductive Protocol" or something cute like this,
but I'm late to the party.)

== The interactive induction of IPA <ipa-induct>

The way IPA is done is by induction:
one reduces verifying a vector for $n$ is good (hence $2n+1$ length)
by verifying a vector for $n/2$ is good (of length $n+1$).

To see how you might think of the idea on your own,
check out this
#link("https://notes.0xparc.org/notes/pedersen-ipa", "0xPARC blog post").

To illustrate the induction, we'll first show how to get from $n=2$ to $n=1$.
So the given input to the protocol is
$ v = a_1 g_1 + a_2 g_2 + b_1 h_1 + b_2 h_2 + c u $
which has the basis $angle.l g_1, g_2, h_1, h_2, u angle.r$.
The idea is that we want to construct a new (good) vector $w$ whose basis is
$ angle.l (g_1 + lambda^(-1) g_2), (h_1 + lambda h_2), u angle.r $
for a randomly chosen challenge $lambda in FF_p$.

The construction is the following vector:
$ w(lambda) &:= (a_1 + lambda a_2) dot underbrace((g_1 + lambda^(-1) g_2), "basis elm")
  + (b_1 + lambda^(-1) b_2) dot underbrace((h_1 + lambda h_2), "basis elm")
  + (a_1 + lambda a_2)(b_1 + lambda^(-1) b_2) underbrace(u, "basis elm"). $
Expanding and isolating the parts with $lambda$ and $lambda^(-1)$ gives
$ w(lambda)
  &= (a_1 g_1 + a_2 g_2 + b_1 h_1 + b_2 h_2 + c u) \
  &#h(1em) + lambda dot underbrace((a_2 g_1 + b_1 h_2 + a_2 b_1 u), =: w_L)
  + lambda^(-1) dot underbrace((a_1 g_2 + b_2 h_1 + a_1 b_2 u), =: w_R) \
  &= v + lambda dot w_L + lambda^(-1) dot w_R.
  $
Note that, importantly, $w_L$ and $w_R$ don't depend on $lambda$.
So this gives a way to provide a construction of a good vector $w$
of half the length (in the new basis) given a good vector $v$.

This suggests the following protocol:
#algorithm[Reducing IPA for $n=2$ to $n=1$][
  1. Peggy, who knows the $a_i$'s, computes
    $ w_L := a_2 g_1 + b_1 h_2 + a_2 b_1 u in E
    #h(1em) "and" #h(1em)
    w_R := a_1 g_2 + b_2 h_1 + a_1 b_2 u in E, $
    and sends those values to Victor.
    (Note there is no dependence on $lambda$.)
  2. Victor picks a random challenge $lambda in FF_q$ and sends it.
  3. Both Peggy and Victor calculate the point
    $ w(lambda) = v + lambda dot w_L + lambda^(-1) dot w_R in E. $
  4. Peggy and Victor run the $n=1$ case of IPA to verify whether
    $w(lambda)$ is good with respect the smaller $3$-element basis
    $ angle.l (g_1 + lambda^(-1) g_2), (h_1 + lambda h_2), u angle.r . $
    Victor accepts if and only if this IPA is accepted.
]
Assuming Peggy was truthful and $v$ was indeed good with respect
to the original 5-element basis for $n=2$,
the resulting $w(lambda)$ is good with respect to the new basis.
So the interesting part is soundness:

#claim[
  Suppose $v = a_1 g_1 + a_2 g_2 + b_1 h_1 + b_2 h_2 + c u$ is given.
  Assume further that Peggy can provide some $w_L, w_R in E$ such that
  $ w(lambda) := v + lambda dot w_L + lambda^(-1) dot w_R $
  lies in the span of the shorter basis,
  and is good for at least four values of $lambda$.

  Then all of the following statements must be true:
  - $w_L = a_2 g_1 + b_1 h_2 + a_2 b_1 u$,
  - $w_R = a_1 g_2 + b_2 h_1 + a_1 b_2 u$,
  - $c = a_1 b_1 + a_2 b_2$, i.e., $v$ is good.
]

#proof[
  At first, it might seem like a cheating prover has too many parameters
  they could play with to satisfy too few conditions.
  The trick is that $lambda$ is really like a formal variable,
  and even the requirement that $w(lambda)$ lies in the span of
  $ angle.l (g_1 + lambda^(-1) g_2), (h_1 + lambda h_2), u angle.r $
  is going to determine almost all the coefficients of $w_L$ and $w_R$.

  To be explicit, suppose a cheating prover tried to provide
  $ w_L &= ell_1 g_1 + ell_2 g_2 + ell_3 h_1 + ell_4 h_2 + ell_5 \
    w_R &= r_1 g_1 + r_2 g_2 + r_3 h_1 + r_4 h_2 + r_5. $
  Then we can compute
  $ w(lambda) &= v + lambda dot w_L + lambda^(-1) dot w_R \
    &= (a_1 + lambda ell_1 + lambda^(-1) r_1)g_1 + (a_2 + lambda ell_2 + lambda^(-1) r_2)g_2 \
    &+ (b_1 + lambda ell_3 + lambda^(-1) r_3)h_1 + (b_2 + lambda ell_4 + lambda^(-1) r_4)h_1 \
    &+ (c + lambda ell_5 + lambda^(-1) r_5)u. $
  In order to lie in the span we described, one needs the coefficient of $g_1$
  to be $lambda$ times the coefficient of $g_2$, that is
  $ lambda^(-1) r_1 + a_1 + lambda ell_1 = r_2 + lambda a_2 + lambda^2 ell_2. $
  Since this holds for more than three values of $lambda$,
  the two sides must actually be equal coefficient by coefficient.
  This means that $ell_1 = a_2$, $r_2 = a_1$, and $r_1 = ell_2 = 0$.
  In the same way, we get $ell_4 = b_1$, $r_3 = b_2$, and $ell_3 = r_4 = 0$.

  So just to lie inside the span,
  the cheating prover's hand is already forced for all the coefficients
  other than the $ell_5$ and $r_5$ in front of $u$.
  Then indeed the condition that $w(lambda)$ is good is that
  $ (a_1 + lambda a_2) (b_1 + lambda^(-1) b_2) = c + lambda ell_5 + lambda^(-1) r_5. $
  Comparing the constant coefficients we see that $c = a_1 b_1 + a_2 b_2$ as desired.
  (One also can recover $ell_5 = a_2 b_1$ and $r_5 = a_1 b_2$,
  but we never actually use this.)
]

So we've shown completeness and soundness for our protocol reducing $n=2$ to $n=1$.
The general situation is basically the same with more notation.
To prevent drowning in notation, we write this out for $n=6$,
with the general case of even $n$ being analogous.
So suppose Peggy wishes to prove
$v = a_1 g_1 + ... + a_6 g_6 + b_1 h_1 + ... + b_6 h_6 + c u $
is good with respect to the length-thirteen basis
$angle.l g_1, ..., h_6, u angle.r$.

#algorithm[Reducing IPA for $n=6$ to $n=3$][
  1. Peggy computes
    $ w_L &= (a_4 g_1 + a_5 g_2 + a_6 g_3) + (b_1 h_4 + b_2 h_5 + b_3 h_6)
      + (a_1 b_4 + a_2 b_5 + a_3 b_6) u \
      w_R &= (a_1 g_4 + a_2 g_5 + a_3 g_6) + (b_4 h_1 + b_5 h_2 + b_6 h_3)
      + (a_4 b_1 + a_5 b_2 + a_6 b_3) u $
    and sends these to Victor.
  2. Victor picks a random challenge $lambda in FF_q$.
  3. Both parties compute $w(lambda) = v + lambda dot w_L + lambda^(-1) dot w_R$.
  4. Peggy runs IPA for $n=3$ on $w(lambda)$ to convince Victor it's good
    with respect to the length-seven basis
    $ angle.l g_1 + lambda^(-1) g_4, g_2 + lambda^(-1) g_5, g_3 + lambda^(-1) g_6,
      h_1 + lambda h_4, h_2 + lambda h_5, h_3 + lambda h_6, u angle.r . $
]

== The base case <ipa-base>

If we're in the $n = 1$ case, meaning we have a Pedersen commitment
$ v = a g + b h + c u $
for $a,b,c in FF_q$, how can Peggy convince Victor that $v$ is good?

Well, one easy way to do that would be to just reveal all of $a$, $b$, $c$.
However, this isn't good enough in situations in which Peggy really
cares about the zero-knowledge part.
Is there a way to proceed without revealing anything about $a$, $b$, $c$?

The answer is yes, we just need more blinding factors.

#algorithm[The $n=1$ case of IPA][
  1. Peggy picks random blinding factors $a', b' in FF_q$.
  2. Peggy sends the following Pedersen commitments:
  $
    w_1 &:= a' g + a' b u \
    w_2 &:= b' h + a b ' u \
    w_3 &:= a' b' u.
  $
  3. Victor picks a random challenge $lambda in FF_q$.
  4. Both parties compute
  $
    w &= v + lambda dot w_1 + lambda^(-1) dot w_2 + dot w_3  \
    &= (a+lambda a') g + (b+lambda^(-1) b') h + (a+lambda a')(b + lambda^(-1) b') u.
  $
  5. Victor asks Peggy to reveal all three coefficients of $w$.
  6. Victor verifies that the third coefficient is the product of the first two.
]

This is really the naive protocol we described except that
$a$ and $b$ have each been offset by a blinding factors
that prevents Victor from learning anything about $a$ and $b$:
he gets $a + lambda a'$ and $b + lambda^(-1) b'$, and knows $lambda$,
but since $a'$ and $b'$ are randomly chosen,
this reveals no information about $a$ and $b$ themselves.

== Two simple applications <ipa-app>

As we mentioned before, IPA can actually do a lot more than just
polynomial commitments.

=== Application: revealing an element of a Pedersen commitment

Suppose Peggy has a vector $arrow(a) = angle.l a_1, ..., a_n angle.r$
and a Pedersen commitment $v = sum a_i g_i$ to it.
Suppose Peggy wishes to reveal $a_1$.
The right way to think of this is as the dot product $arrow(a) dot arrow(b)$,
where $ arrow(b) = angle.l 1, 0, ..., 0 angle.r $
has a $1$ in the $1$st position and $0$'s elsewhere.
To spell this out:

#algorithm[Revealing $a_1$ in a Pedersen commitment][
  1. Both parties compute $w = v + h_1 + a_1 u$.
  2. Peggy runs IPA on $w$ to convince Victor that $w$ is good.
]

=== Application: showing two Pedersen commitments are to the same vector

Suppose there are two Pedersen commitments
$v = sum a_i g_i$ and $v' = sum a'_i g'_i$ in different bases;
Peggy wants to prove that $a_i = a'_i$ for all $i$
(i.e. the vectors $arrow(a)$ and $arrow(a')$ coincide)
without revealing anything else about the two vectors.

This can also be done straightforwardly:
show that the dot products of $arrow(a)$ and $arrow(a)'$
with a random other vector $arrow(lambda)$ are equal.

#algorithm[Matching Pedersen commitments][
  1. Victor picks a random challenge vector
    $arrow(lambda) = angle.l lambda_1, ..., lambda_n angle.r in FF_q^n$.
  2. Both parties compute its Pedersen commitment
    $w = lambda_1 h_1 + ... + lambda_n h_n$.
  3. Peggy also privately computes the dot product
    $c := arrow(a) dot arrow(lambda) = arrow(a)' dot arrow(lambda) = a_1 lambda_1 + ... + a_n lambda_n$.
  4. Peggy sends a Pedersen commitment $c u$ to the number $c$.
  5. Peggy runs IPA to convince Victor both $v + w + c u$ and $v' + w + c u$ are good.
]

This protocol provides a proof to Victor that $arrow(a)$ and $arrow(a)'$
have the same dot product with his random challenge vector $arrow(lambda)$,
without having to actually reveal this dot product.
Since Victor chose the random vector $arrow(lambda)$,
this check passes with vanishingly small probability
of at most $1/q$ if $arrow(a) != arrow(a)'$.

== Using IPA for polynomial commitments <ipa-poly>

Suppose now $P(X) = sum a_i X^(i-1)$ is a given polynomial.
Then Peggy can use IPA to commit the polynomial $P$ as follows:

- Peggy publishes Pedersen commitment of the coefficients of $P$;
  that is, Peggy publishes $ g := sum a_i g_i in E. $
- Suppose Victor wants to open the commitment at a value $z$,
  and Peggy asserts that $P(z) = y$.
- Victor picks a random constant $lambda in FF_p$.
- Both parties compute
  $ v := underbrace((a_1 g_1 + ... + a_n g_n), C)
  + (lambda z^0 h_1 + ... + lambda z^(n-1) h_n) + lambda y u $
  and run IPA on it.

(When Peggy does a vanilla IPA protocol, she can keep all $2n+1$ coefficients secret.
In this context, Peggy has published the first part $g$
and still gets to keep her coefficients $a_n$ private from Victor.
The other $n+1$ coefficients are globally known because
they're inputs to the protocol for opening the commitment at $z$.)

The introduction of the hacked constant $lambda$ might be a bit of a surprise.
The reason is that without it, there is an amusing loophole that Peggy can exploit.
Peggy can pick the vector $v$, so imagine she tries to swindle Victor by reporting
$v = a_1 g_1 + ... + a_n g_n - 10 u$ instead
of the honest $v = a_1 g_1 + ... + a_n g_n$.
Then, Peggy inflates all the values of $y$ she claims to Victor by $10$.
This would allow Peggy to cheat Victor into committing the polynomial $P$
but for each input $z$ giving Victor the value of $P(z) + 10$  rather than $P(z)$
(though the cheating offset would be the same at every value she opened).
The offset $lambda$ prevents this attack.
