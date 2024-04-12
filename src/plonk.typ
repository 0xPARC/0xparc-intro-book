#import "preamble.typ":*

= PLONK, a zkSNARK protocol <plonk>

For this section, one can use any polynomial commitment scheme one prefers.
So we'll introduce the notation $Com(P)$ for the commitment of a polynomial
$P(T) in FF_q [T]$, with the understanding that either KZG, IPA, or something
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

Then, by polynomial interpolation, Penny constraints polynomials $A(T)$, $B(T)$,
and $C(T)$ in $FF_q [T]$ each of degree $n-1$ such that
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
$Q_L(T) in FF_q [T]$ of degree $n-1$ such that
$ Q_L (omega^i) = q_(L,i) #h(1em) " for " i = 1, ..., n. $
Then the analogous polynomials $Q_R$, $Q_O$, $Q_M$, $Q_C$
are defined in the same way.

Now, what do the gate constraints amount to?
Penny is trying to convince Victor that the equation

$ Q_L (x) A_i (x) + Q_R (x) B_i (x) + Q_O (x) C_i (x)
  + Q_M (x) A_i (x) B_i (x) + Q_C (x) = 0 $

is true for the $n$ numbers $x = 1, omega, omega^2, ..., omega^(n-1)$.
However, that's equivalent to the _polynomial_
$ Q_L (T) A_i (T) + Q_R (T) B_i (T) + Q_O (T) C_i (T)
  + Q_M (T) A_i (T) B_i (T) + Q_C (T) in FF_q [T] $
being divisible by the degree $n$ polynomial
$ Z(T) = (T-omega)(T-omega^2) ... (T-omega^n) = T^n - 1. $
(And now it's revealed why we liked powers of $omega$: it makes the $Z$
polynomial really simple.
In fact, $n$ is often taken to be a power of $2$ to make evaluation
of $Z$ even easier.)

In other words, it suffices for Penny to convince Victor that there
is a polynomial $H(T) in FF_q [T]$ such that
#eqn[
  $ Q_L (T) A_i (T) &+ Q_R (T) B_i (T) + Q_O (T) C_i (T) \
    &+ Q_M (T) A_i (T) B_i (T) + Q_C (T) = Z(T) H(T). $
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
  1. Penny computes $H(T) in FF_q [T]$ using polynomial long division
    and sends $Com(H)$ to Victor.
  2. Victor picks a random challenge $x in FF_q$.
  3. Penny opens all of $Com(A)$, $Com(B)$, $Com(C)$, $Com(H)$ at $x$.
  4. Victor accepts if and only if @plonkpoly is true at $T = x$.
]

== Step 3: Proving the copy constraints

#todo[write this]
