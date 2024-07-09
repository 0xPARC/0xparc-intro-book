#import "preamble.typ":*

#let rbox(s) = [#text(red)[#ellipse(stroke: red, inset: 2pt, s)]]
#let bbox(s) = [#text(blue)[#rect(stroke: blue, inset: 4pt, s)]]

= PLONK, a zkSNARK protocol <plonk>


== Arithmetization <arith-intro>

The promise of programmable cryptography is that we should be able to
perform proofs for arbitrary functions.
That means we need a "programming language" that we'll write our function in.
For PLONK, the choice that's used is:
*systems of quadratic equations over $FF_q$*. In other words, PLONK is going to
give us the ability to prove that we have solutions to a system of quadratic 
equations. 

#situation[
  Suppose we have a system of $m$ equations in $k$ variables $x_1, dots, x_k$:
  $
    Q_1 (x_1 , dots, x_k) & = 0 \
    dots.v \
    Q_m (x_1 , dots, x_k) & = 0.
  $

  Of these $k$ variables,
  the first $ell$ ($x_1, dots, x_ell$) have publicly known, fixed values;
  the remaining $k - ell$ are unknown.

  PLONK will let Peggy prove to Victor the following claim:
  I know $k - ell$ values $x_(ell+1), dots, x_k$ such that
  (when you combine them with the $ell$ public fixed values
  $x_1, dots, x_ell$)
  the $k$ values $x_1, dots, x_k$ satisfy all $m$ quadratic equations.
]

This leads to the natural question of how a function like SHA-256 can be encoded
into a system of quadratic equations. This process of encoding a problem
into algebra is called _arithmetization_. It turns out that quadratic equations
over $FF_q$, viewed as an NP problem called Quad-SAT, is _NP-complete_; 
in other words, any NP problem can be rewritten as a system of quadratic equations. 
If you are not familiar with this concept, the upshot is that Quad-SAT
being NP-complete means it can serve as a reasonable arithmetization that can
express most reasonable (NP) problems.

#remark([Quad-SAT is NP-complete])[
  We assume knowledge of 3-SAT and it being NP-complete. 
  The following example instance illustrates how to convert 
  any instance of 3-SAT into a Quad-SAT problem:
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
] <np-complete>

So for example, any NP decision problem should be encodable.
Still, such a theoretical reduction might not be usable in practice:
polynomial factors might not matter in complexity theory,
but they do matter a lot to engineers and end users.

But it turns out that Quad-SAT is actually reasonably code-able.
This is the goal of projects like
#cite("https://docs.circom.io/", "Circom"),
which gives a high-level language that compiles a function like SHA-256
into a system of equations over $FF_q$ that can be used in practice.
Systems like this are called _arithmetic circuits_,
and Circom is appropriately short for "circuit compiler".
If you're curious, you can see how SHA-256 is implemented in Circom on
#cite("https://github.com/iden3/circomlib/blob/master/circuits/sha256/sha256.circom",
"GitHub").

So, the first step in proving a claim like
"I have a message $M$ such that
  $sha(M) = "0xa91af3ac..."$"
is to translate the claim into a system of quadratic equations.
This process is called "arithmetization."

One approach (suggested by @np-complete)
is to represent each bit involved in the calculation
by a variable $x_i$
(which would then be constrained to be either 0 or 1
by an equation $x_i^2 = x_i$).
In this setup, the value $"0xa91af3ac"$
would be represented by 32 public bits $x_1, dots, x_32$;
the unknown message $M$ would be represented by
some private variables;
and the calculation of $op("sha")$
would introduce a series of constraints,
maybe involving some additional variables.

We won't get into any more details of arithmetization here.




== An instance of PLONK

PLONK is going to prove solutions to
systems of quadratic equations of a very particular form:

#definition[
  An instance of PLONK consists of two pieces,
  the _gate constraints_ and the _copy constraints_.

  The _gate constraints_ are a system of $n$ equations,
  $ q_(L,i) a_i + q_(R,i) b_i + q_(O,i) c_i + q_(M,i) a_i b_i + q_(C,i) = 0 $
  for $i = 1, ..., n$,
  in the $3n$ variables $a_i$, $b_i$, $c_i$.
  while the $q_(*,i)$ are coefficients in $FF_q$, which are globally known.
  The confusing choice of subscripts stands for "Left", "Right", "Output",
  "Multiplication", and "Constant", respectively.

  The _copy constraints_ are a bunch of assertions that some of the
  $3n$ variables should be equal to each other,
  so e.g. "$a_1 = c_7$", "$b_17 = b_42$", and so on.
]

#remark("From Quad-SAT to PLONK")[
  PLONK might look less general than Quad-SAT,
  but it turns out you can convert any Quad-SAT problem to PLONK.
]

#gray[
  First off, note that if we set
  $ ( q_(L,i), q_(R,i), q_(O,i), q_(M,i), q_(C,i)) = ( 1, 1, -1, 0, 0 ), $
  we get an "addition" gate
  $a_i + b_i = c_i,$
  while if we set
  $ ( q_(L,i), q_(R,i), q_(O,i), q_(M,i), q_(C,i)) = ( 0, 0, -1, 1, 0 ), $
  we get a "multiplication" gate
  $a_i b_i = c_i.$
  Finally, if $q$ is any constant, then
  $ ( q_(L,i), q_(R,i), q_(O,i), q_(M,i), q_(C,i)) = ( 1, 0, 0, 0, -q ), $
  gives the constraint
  $a_i = q.$

  Now imagine we want to encode some quadratic equation
  like
  $y = x^2 + 2$
  in PLONK. We'll break this down into two steps:
  $ x dot x & = (x^2) text(" (multiplication)") \
  t & = 2 text(" (constant)") \
  (x^2) + t & = y text(" (addition)"). $

  We'll assign the variables $a_i, b_i, c_i$ for these two gates
  by looking at the equations:
  $ (a_1, b_1, c_1) & = (x, x, x^2) \
  (a_2, b_2, c_2) & = (t = 2, 0, 0) \
  (a_3, b_3, c_3) & = (x^2, t = 2, y). $

  And finally, we'll assign copy constraints
  to make sure the variables are faithfully copied
  from line to line:
  $ a_1 & = b_1 \
  c_1 & = a_3 \
  a_2 & = b_3. $

  If the variables $a_i, b_i, c_i$ satisfy the gate and copy constraints,
  then $x = a_1$ and $y = c_3$ are forced to satisfy
  the original equation $y = x^2 + 2$.
]

Back to PLONK: Our protocol needs to do the following:
Peggy and Victor have a PLONK instance given to them.
Peggy has a solution to the system of equations,
i.e. an assignment of values to each $a_i$, $b_i$, $c_i$ such that
all the gate constraints and all the copy constraints are satisfied.
Peggy wants to prove this to Victor succinctly
and without revealing the solution itself.
The protocol then proceeds by having:

1. Peggy sends a polynomial commitment corresponding to $a_i$, $b_i$, and $c_i$
  (the details of what polynomial are described below).
2. Peggy proves to Victor that the commitment from Step 1
  satisfies the gate constraints.
3. Peggy proves to Victor that the commitment from Step 1
  also satisfies the copy constraints.

Let's now explain how each step works.

== Step 1: The commitment

In PLONK, we'll assume that $q equiv 1 mod n$, which means that
we can fix $omega in FF_q$ to be a primitive $n$-th root of unity.

Then, by polynomial interpolation, Peggy chooses polynomials $A(X)$, $B(X)$,
and $C(X)$ in $FF_q [X]$ such that
#eqn[
  $ A(omega^i) = a_i, B(omega^i) = b_i, C(omega^i) = c_i
    " for all " i = 1, 2, ..., n. $
  <plonk-setup>
]
We specifically choose $omega^i$ because that way,
if we use @root-check on the set ${omega, omega^2, ..., omega^n}$,
then the polynomial called $Z$ is just
$Z(X) = (X-omega) ... (X-omega^n) = X^n-1$, which is really nice.
In fact, often $n$ is chosen to be a power of $2$ so that $A$, $B$, and $C$
are very easy to compute, using a fast Fourier transform.
(Note: When you're working in a finite field, the fast Fourier transform
is sometimes called the "number theoretic transform" (NTT)
even though it's exactly the same as the usual FFT.)

Then:
#algorithm("Commitment step of PLONK")[
  1. Peggy interpolates $A$, $B$, $C$ as in @plonk-setup.
  2. Peggy sends $Com(A)$, $Com(B)$, $Com(C)$ to Victor.
]
To reiterate, each commitment is a
single value -- a 256-bit elliptic curve point --
that can later be "opened" at any value $x in FF_q$.

== Step 2: Gate-check

Both Peggy and Victor know the PLONK instance,
so they can interpolate a polynomial
$Q_L (X) in FF_q [X]$ of degree $n-1$ such that
$ Q_L (omega^i) = q_(L,i) #h(1em) " for " i = 1, ..., n. $
The analogous polynomials $Q_R$, $Q_O$, $Q_M$, $Q_C$
are defined in the same way.

Now, what do the gate constraints amount to?
Peggy is trying to convince Victor that the equation
#eqn[
  $ Q_L (x) A (x) + Q_R (x) B (x) + Q_O (x) C (x) & \
    + Q_M (x) A (x) B (x) + Q_C (x) & = 0 $
  <plonk-gate>
]
is true for the $n$ numbers $x = omega, omega^2, ..., omega^n$.

However, Peggy has committed $A$, $B$, $C$ already,
while all the $Q_*$ polynomials are globally known.
So this is a direct application of @root-check:

#algorithm[Gate-check][
  1. Both parties interpolate five polynomials $Q_* in FF_q [X]$
    from the $5n$ coefficients $q_*$
    (globally known from the PLONK instance).
  2. Peggy uses @root-check to convince Victor that @plonk-gate
    holds for $X = omega^i$
    (that is, the left-hand side is indeed divisible by $Z(X) := X^n-1$).
]


/*
However, that's equivalent to the _polynomial_
$ Q_L (X) A_i (X) + Q_R (X) B_i (X) + Q_O (X) C_i (X)
  + Q_M (X) A_i (X) B_i (X) + Q_C (X) in FF_q [X] $
being divisible by the degree $n$ polynomial
$ Z(X) = (X-omega)(X-omega^2) ... (X-omega^n) = X^n - 1. $

In other words, it suffices for Peggy to convince Victor that there
is a polynomial $H(X) in FF_q [X]$ such that
#eqn[
  $ Q_L (X) A_i (X) &+ Q_R (X) B_i (X) + Q_O (X) C_i (X) \
    &+ Q_M (X) A_i (X) B_i (X) + Q_C (X) = Z(X) H(X). $
  <plonkpoly>
]

And this can be done using polynomial commitments pretty easily:
Peggy should send $Com(H)$,
and then Victor just verifies @plonkpoly at random values in $FF_q$.
As both sides are polynomials of degree up to $3(n-1)$,
either the equation holds for every input
or there are at most $3n-4$ values for which it's true
(two different polynomials of degree $3(n-1)$ can agree at up to $3n-4$ points).

#algorithm("Proving PLONK satisfies the gate constraints")[
  1. Peggy computes $H(X) in FF_q [X]$ using polynomial long division
    and sends $Com(H)$ to Victor.
  2. Victor picks a random challenge and asks Peggy to open
    all of $Com(A)$, $Com(B)$, $Com(C)$, $Com(H)$ at that challenge.
  3. Victor accepts if and only if @plonkpoly is true at the random challenge.
]
*/

== Step 3: Proving the copy constraints

The copy constraints are the trickiest step.
There are a few moving parts to this idea, so we skip it for now and dedicate
@copy-constraints to it.

== Public and private witnesses

The last thing to be done is to reveal the value of public witnesses,
so the prover can convince the verifier that those values are correct.
This is simply an application of @root-check.
Let's say the public witnesses are the values $a_i$, for all $i$ in some set $S$.
(If some of the $b$'s and $c$'s are also public, we'll just do the same thing for them.)
The prover can interpolate another polynomial, $A^"public"$,
such that $A^"public" (omega^i) = a_i$ if $i in S$, and $A^"public" (omega^i) = 0$ if $i in.not S$.
Actually, both the prover and the verifier can compute $A^"public"$, since
all the values $a_i$ are publicly known!

Now the prover runs @root-check to prove that $A - A^"public"$ vanishes on $S$.
(And similarly for $B$ and $C$, if needed.)
And we're done.
