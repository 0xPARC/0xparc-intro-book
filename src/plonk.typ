#import "preamble.typ":*

#let rbox(s) = [#text(red)[#ellipse(stroke: red, inset: 2pt, s)]]
#let bbox(s) = [#text(blue)[#ellipse(stroke: blue, inset: 2pt, s)]]

= PLONK, a zkSNARK protocol <plonk>

For this section, one can use any polynomial commitment scheme one prefers.
So we'll introduce the notation $Com(P)$ for the commitment of a polynomial
$P(X) in FF_q [X]$, with the understanding that either KZG, IPA, or something
else could be in use here.

== Arithmetization <arith-intro>

The promise of programmable cryptography is that we should be able to
perform zero-knowledge proofs for arbitrary functions.
That means we need a "programming language" that we'll write our function in.

For PLONK (and Groth16 in the next section), the choice that's used is:
*systems of quadratic equations over $FF_q$*.

This leads to the natural question of how a function like SHA256 can be encoded
into a system of quadratic equations.
Well, quadratic equations over $FF_q$,
viewed as an NP-problem called Quad-SAT, is pretty clearly NP-complete,
as the following example shows:

#remark([Quad-SAT is pretty obviously NP-complete])[
  If you can't see right away that Quad-SAT is NP-complete,
  the following example instance can help,
  showing how to convert any instance of 3-SAT into a Quad-SAT problem:
  $
    x_i^2 &= x_i #h(1em) forall 1 <= i <= 1000 & \
    y_1 &= (1-x_(42)) dot x_(17), & #h(1em) & 0 = y_1 dot x_(53) & \
    y_2 &= (1-x_(19)) dot (1-x_(52)) & #h(1em) & 0 = y_2 dot (1-x_(75)) & \
    y_3 &= x_(25) dot x_(64), &#h(1em) & 0 = y_3 dot x_(81) & \
    &dots.v
  $
  (imagine many more such pairs of equations).
  The $x_i$'s are variables which are seen to either be $0$ or $1$.
  And then each pair of equations with $y_i$ corresponds to a clause of 3-SAT.
]

So for example, any NP decision problem should be encodable.
Still, such a theoretical reduction might not be usable in practice:
polynomial factors might not matter in complexity theory,
but they do matter a lot to engineers and end users.
Just having a #link("https://w.wiki/5z5Z", "galactic algorithm") isn't enough.

But it turns out that Quad-SAT is actually reasonably code-able.
This is the goal of projects like
#link("https://docs.circom.io/", "Circom"),
which gives a high-level language that compiles a function like SHA-256
into a system of equations over $FF_q$ that can actually be used in practice.
Systems like this are called *arithmetic circuits*,
and Circom is appropriately short for "circuit compiler".
If you're curious, you can see how SHA256 is implemented in Circom on
#link("https://github.com/iden3/circomlib/blob/master/circuits/sha256/sha256.circom",
"GitHub").

To preserve continuity of the mathematics,
we'll defer further discussion of coding in quadratic equations to later.

== An instance of PLONK

For PLONK, the equations are standardized further to a certain form:

#definition[
  An instance of PLONK consists of two pieces,
  the *gate constraints* and the *copy constraints*.

  The *gate constraints* are a system of $n$ equations,
  $ q_(L,i) a_i + q_(R,i) b_i + q_(O,i) c_i + q_(M,i) a_i b_i + q_(C,i) = 0 $
  for $i = 1, ..., n$,
  in the $3n$ variables $a_i$, $b_i$, $c_i$.
  while the $q_(*,i)$ are coefficients in $FF_q$, which are globally known.
  The confusing choice of subscripts stands for "Left", "Right", "Output",
  "Multiplication", and "Constant", respectively.

  The *copy constraints* are a bunch of assertions that some of the
  $3n$ variables should be equal to each other,
  so e.g. "$a_1 = c_7$", "$b_17 = b_42$", and so on.
]

So the PLONK protocol purports to do the following:
Penny and Victor have a PLONK instance given to them.
Penny has a solution to the system of equations,
i.e. an assignment of values to each $a_i$, $b_i$, $c_i$ such that
all the gate constraints and all the copy constraints are satisfied.
Penny wants to prove this to Victor succinctly
and without revealing the solution itself.
The protocol then proceeds by having:

1. Penny sends a polynomial commitment corresponding to $a_i$, $b_i$, and $c_i$
  (the details of what polynomial are described below).
2. Penny proves to Victor that the commitment from Step 1
  satisfies the gate constraints.
3. Penny proves to Victor that the commitment from Step 1
  also satisfies the copy constraints.

Let's now explain how each step works.

== Step 1: The commitment

In PLONK, we'll assume that $q equiv 1 mod n$, which means that
we can fix $omega in FF_q$ to be a primitive $n$th root of unity.

Xhen, by polynomial interpolation, Penny constraints polynomials $A(X)$, $B(X)$,
and $C(X)$ in $FF_q [X]$ each of degree $n-1$ such that
$ A(omega^i) = a_i, #h(1em) B(omega^i) = b_i, #h(1em) C(omega^i) = c_i #h(1em)
  " for all " i = 1, 2, ..., n. $
(We'll explain next section why we like powers of $omega$.)
Then:
#algorithm("Commitment step of PLONK")[
  1. Penny sends $Com(A)$, $Com(B)$, $Com(C)$ to Victor.
]
To reiterate, each commitment is a 256-bit
that can later be "opened" at any value $x in FF_q$.

== Step 2: Proving the gate constraints

Both Penny and Victor knows the PLONK instance, so they can interpolate a polynomial
$Q_L(X) in FF_q [X]$ of degree $n-1$ such that
$ Q_L (omega^i) = q_(L,i) #h(1em) " for " i = 1, ..., n. $
Then the analogous polynomials $Q_R$, $Q_O$, $Q_M$, $Q_C$
are defined in the same way.

Now, what do the gate constraints amount to?
Penny is trying to convince Victor that the equation

$ Q_L (x) A_i (x) + Q_R (x) B_i (x) + Q_O (x) C_i (x)
  + Q_M (x) A_i (x) B_i (x) + Q_C (x) = 0 $

is true for the $n$ numbers $x = 1, omega, omega^2, ..., omega^(n-1)$.
However, that's equivalent to the _polynomial_
$ Q_L (X) A_i (X) + Q_R (X) B_i (X) + Q_O (X) C_i (X)
  + Q_M (X) A_i (X) B_i (X) + Q_C (X) in FF_q [X] $
being divisible by the degree $n$ polynomial
$ Z(X) = (X-omega)(X-omega^2) ... (X-omega^n) = X^n - 1. $
(And now it's revealed why we liked powers of $omega$: it makes the $Z$
polynomial really simple.
In fact, $n$ is often taken to be a power of $2$ to make evaluation
of $Z$ even easier.)

In other words, it suffices for Penny to convince Victor that there
is a polynomial $H(X) in FF_q [X]$ such that
#eqn[
  $ Q_L (X) A_i (X) &+ Q_R (X) B_i (X) + Q_O (X) C_i (X) \
    &+ Q_M (X) A_i (X) B_i (X) + Q_C (X) = Z(X) H(X). $
  <plonkpoly>
]

And this can be done using polynomial commitments pretty easily:
Penny should send $Com(H)$,
and then Victor just verifies @plonkpoly at random values in $FF_q$.
As both sides are polynomials of degree up to $3(n-1)$,
either the equation holds for every input
or there are at most $3n-4$ values for which it's true
(two different polynomials of degree $3(n-1)$ can agree at up to $3n-4$ points).

#algorithm("Proving PLONK satisfies the gate constraints")[
  1. Penny computes $H(X) in FF_q [X]$ using polynomial long division
    and sends $Com(H)$ to Victor.
  2. Victor picks a random challenge $lambda in FF_q$.
  3. Penny opens all of $Com(A)$, $Com(B)$, $Com(C)$, $Com(H)$ at $lambda$.
  4. Victor accepts if and only if @plonkpoly is true at $X = lambda$.
]

== Step 3: Proving the copy constraints

The copy constraints are the trickier step.
There are a few moving parts to this idea, so to ease into it slightly,
we provide a solution to a "simpler" problem called "permutation check".
Then we explain how to deal with the full copy check.

=== (Optional) Permutation check

Let's suppose we have polynomials $P, Q in FF_q [X]$
which are encoding two vectors of values
$ arrow(p) &= angle.l P(omega^1), P(omega^2), ..., P(omega^n) angle.r \
  arrow(q) &= angle.l Q(omega^1), Q(omega^2), ..., Q(omega^n) angle.r. $
Is there a way that one can quickly verify $arrow(p)$ and $arrow(q)$
are the same up to permutation of the $n$ entries?

Well, actually, it would be necessary and sufficient for the identity
$ (X+P(omega^1))(X+P(omega^2)) ... (X+P(omega^n))
  = (X+Q(omega^1))(X+Q(omega^2)) ... (X+Q(omega^n)) $
to be true, in the sense both sides are the same polynomial in $FF_q [X]$.

=== Copy check

To explain the motivation, let's look at a concrete example where $n=4$.
Suppose that our copy constraints were
$ #rbox($a_1$) = #rbox($a_4$) = #rbox($c_3$)
  #h(1em) "and" #h(1em)
  #bbox($b_2$) = #bbox($c_1$). $
(We've colored and circled the variables that will move around for readability.)
So, the copy constraint means we want the following equality of matrices:
#eqn[
  $
  mat(
    a_1, a_2, a_3, a_4;
    b_1, b_2, b_3, b_4;
    c_1, c_2, c_3, c_4;
  )
  =
  mat(
    #rbox($a_4$), a_2, a_3, #rbox($c_3$) ;
    b_1, #bbox($c_1$), b_3, b_4;
    #bbox($b_2$), c_2, c_3, #rbox($a_1$)
  )
  .
  $
  <copy1>
]
Again, our goal is to make this into a _single_ equation.
There's a really clever way to do this by tagging each entry with $lambda + k mu$
in reading order for $k = 1, ..., 3n$:
if @copy1 is true, then for any $mu in FF_q$, we also have
#eqn[
  $
  & mat(
    a_1 + lambda + mu, a_2 + lambda + 2mu, a_3 + lambda + 3mu, a_4 + lambda + 4mu;
    b_1 + lambda + 5mu, b_2 + lambda + 6mu, b_3 + lambda + 7mu, b_4 + lambda + 8mu;
    c_1 + lambda + 9mu, c_2 + lambda + 10mu, c_3 + lambda + 11mu, c_4 + lambda + 12mu;
  ) \
  =&
  mat(
    #rbox($a_4$) + lambda + mu, a_2 + lambda + 2mu, a_3 + lambda + 3mu, #rbox($c_3$) + lambda + 4mu;
    b_1 + lambda + 5mu, #bbox($c_1$) + lambda + 6mu, b_3 + lambda + 7mu, b_4 + lambda + 8mu;
    #bbox($b_2$) + lambda + 9mu, c_2 + lambda + 10mu, c_3 + lambda + 11mu, #rbox($a_1$) + lambda + 12mu;
  )
  .
  $
  <copy2>
]
By taking the entire product
(i.e. looking at the product of all twelve entries on each side),
@copy2 implies the equation
#eqn[
  $
  (a_1 + mu)(a_2 + 2mu) dots.c (c_4 + 12 mu)
  = & (#rbox($a_4$) + mu)(a_2 + 2mu)(a_3 + 3mu)(#rbox($c_3$) + 4mu) \
  &(b_1 + 5mu)(#bbox($c_1$) + 6mu)(b_3 + 7mu)(b_4 + 8mu) \
  &(#bbox($b_2$) + 9mu)(c_2 + 10mu)(c_3 + 11mu)(#rbox($a_1$) + 12mu).
  $
  <copy3>
]
At first, this might seem like @copy3 is weaker than @copy2.
But we've seen many times that, when one takes random challenges,
we can get almost equivalence, and this happens here too.
#lemma[
  If @copy2 is true, then @copy3 is true.
  Conversely, if @copy2 is not true,
  then @copy3 will also fail for all but at most $3n-1$ values of $mu$.
]
#proof[
  The first half is obvious.
  For the second half, note that both sides of @copy3
  are polynomials of degree $3n$ in $mu$,
  but they are not the same polynomial;
  hence their difference can vanish in at most $3n-1$ points.
]
So as long as we take $mu$ randomly,
we can treat @copy3 as basically equivalent to @copy1.

Now how can the prover establish @copy3 succinctly?
This is another clever trick:
first rearrange the $12$ terms @copy3 so that,
rather than shuffling the variables the tags as shown below:
#eqn[
  $
  (a_1 + mu)(a_2 + 2mu) dots.c (c_4 + 12 mu)
  = & (a_1 + #rbox($12 mu$))(a_2 + 2mu)(a_3 + 3mu)(a_4 + #rbox($mu$)) \
  &(b_1 + 5mu)(b_2+ #bbox($9 mu$))(b_3 + 7mu)(b_4 + 8mu) \
  &(b_1 + #bbox($6 mu$))(c_2 + 10mu)(c_3 + 11mu)(c_4 + #rbox($4 mu$)).
  $
  <copy4>
]
