#import "preamble.typ":*

= PLONK, a zkSNARK protocol <plonk>

== Arithmetization

#todo[write this]

== An instance of PLONK

#definition[
  An instance of PLONK consists of two pieces,
  the *gate constraints* and the *copy constraints*.

  The *gate constraints* are a system of equations.
  For convenience, the number of equations is assumed to be a power of $2$,
  which we denote $N = 2^n$ henceforth.
  Then the gate constraints are the $N = 2^n$ equations
  $ q_(L,i) a_i + q_(R,i) b_i + q_(O,i) c_i + q_(M,i) a_i b_i + q_(C,i) = 0 $
  for $i = 0, 1, ..., N-1$,
  where we consider $a_i$, $b_i$, $c_i$ are a set of $3N$ variables,
  while the $q_(*,i)$ are coefficients in $FF_q$, which are globally known.
  The confusing choice of subscripts stands for "Left", "Right", "Output",
  "Multiplication", and "Constant", respectively.

  The *copy constraints* are a bunch of assertions that some of the
  $3N$ variables should be equal to each other,
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

In PLONK, we'll assume that $q equiv 1 mod N$, which means that
we can fix $omega in FF_q$ to be a primitive $N$th root of unity.

Then, by polynomial interpolation, Penny constraints polynomials $A(T)$, $B(T)$,
and $C(T)$ in $FF_q [T]$ each of degree $N-1$ such that
$ A(omega^i) = a_i, #h(1em) B(omega^i) = b_i, #h(1em) C(omega^i) = c_i #h(1em)
  " for all " i = 1, 2, ..., N. $
(We'll explain next section why we like powers of $omega$.)
Then:
#algorithm("Commitment step of PLONK")[
  1. Penny sends the polynomial commitment of $A(T)$, $B(T)$, $C(T)$ to Victor.
]
To reiterate, each commitment is a 256-bit
that can later be "opened" at any value $x in FF_q$.

== Step 2: Proving the gate constraints

Both Penny and Victor knows the PLONK instance, so they can interpolate a polynomial
$Q_L(T) in FF_q [T]$ of degree $N-1$ such that
$ Q_L (omega^i) = q_(L,i) #h(1em) " for " i = 1, ..., N. $
Then the analogous polynomials $Q_R$, $Q_O$, $Q_M$, $Q_C$
are defined in the same way.

Now, what do the gate constraints amount to?
Penny is trying to convince Victor that the equation

$ Q_L (x) A_i (x) + Q_R (x) B_i (x) + Q_O (x) C_i (x)
  + Q_M (x) A_i (x) B_i (x) + Q_C (x) = 0 $

is true for the $N$ numbers $x = 1, omega, omega^2, ..., omega^(N-1)$.
However, that's equivalent to the _polynomial_
$ Q_L (T) A_i (T) + Q_R (T) B_i (T) + Q_O (T) C_i (T)
  + Q_M (T) A_i (T) B_i (T) + Q_C (T) in FF_q [T] $
being divisible by the degree $N$ polynomial
$ Z(T) = (T-omega)(T-omega^2) ... (T-omega^N) = T^N - 1. $
(And now it's revealed why we liked powers of $omega$: it makes the $Z$
polynomial really simple.)

In other words, it suffices for Penny to convince Victor that there
is a polynomial $H(T) in FF_q [T]$ such that
#eqn[
  $ Q_L (T) A_i (T) &+ Q_R (T) B_i (T) + Q_O (T) C_i (T) \
    &+ Q_M (T) A_i (T) B_i (T) + Q_C (T) = Z(T) H(T). $
  <plonkpoly>
]

And this can be done using polynomial commitments pretty easily:
Penny should send a commitment to $H(T)$,
and then Victor just verifies @plonkpoly at random values in $FF_q$.
As both sides are polynomials of degree up to $3(N-1)$,
either the equation holds for every input
or there are at most $3N-4$ values for which it's true
(two different polynomials of degree $3(N-1)$ can agree at up to $3N-4$ points).

#algorithm("Proving PLONK satisfies the gate constraints")[
  1. Penny computes $H(T) in FF_q [T]$
     and sends a polynomial commitment of $H(T)$ to Victor.
  2. Victor picks a random challenge $x in FF_q$.
  3. Penny opens the commitments of $A$, $B$, $C$, and $H$ at $x$,
     revealing the values of $A(x)$, $B(x)$, $C(x)$, and $H(x)$ to Victor.
  4. Victor accepts if and only if @plonkpoly is true for those values.
]

== Step 3: Proving the copy constraints

#todo[write this]
