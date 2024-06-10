#import "preamble.typ":*

#let rbox(s) = [#text(red)[#ellipse(stroke: red, inset: 2pt, s)]]
#let bbox(s) = [#text(blue)[#rect(stroke: blue, inset: 4pt, s)]]

= PLONK, a zkSNARK protocol <plonk>

For this section, one can use any polynomial commitment scheme one prefers.
So we'll introduce the notation $Com(P)$ for the commitment of a polynomial
$P(X) in FF_q [X]$, with the understanding that either KZG, IPA, or something
else could be in use here.

== Root check (using long division with commitment schemes)

Both commitments schemes allow for a technique I privately call _root-check_ here.
Here's the problem statement:

#problem[
  Suppose one had two polynomials $P_1$ and $P_2$,
  and Peggy has given commitments $Com(P_1)$ and $Com(P_2)$.
  Peggy would like to prove to Victor that, say,
  the equation $P_1(z) = P_2(z)$ for all $z$ in some large finite set $S$.
]

Of course, Peggy could open $Com(P_1)$ and $Com(P_2)$ at every point in $S$.
But there are some situations in which Peggy still wants to prove this
without actually revealing the common values of the polynomial for any $z in S$.
Even when $S$ is a single number (i.e. Peggy wants to show $P_1$ and $P_2$ agree
on a single value without revealing the common value),
it's not obvious how to do this.

Well, it turns out we can basically employ the same technique as in @kzg.
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
she could define $F(X) = P_1(X) + P_2(X) P_3(X)^4 + P_4(X) P_5(X) + P_6(X)$
and run the same protocol with this $F$.
This means she doesn't have to reveal any $P_i (42)$, which is great!

To be fully explicit, here is the algorithm:

#algorithm[Root-check][
  Assume that $F$ is a polynomial for which
  Peggy can establish the value of $F$ at any point in $FF_q$.
  Peggy wants to convince Victor that $F$ vanishes on a given finite set $S subset.eq FF_q$.

  1. Both parties compute the polynomial
    $ Z(X) := product_(z in S) (X-z) in FF_q [X]. $
  2. Peggy does polynomial long division to compute $H(X) = F(X) / Z(X)$.
  3. Peggy sends $Com(H)$.
  4. Victor picks a random challenge $lambda in FF_q$
    and asks Peggy to open $Com(H)$ at $lambda$,
    as well as the value of $F$ at $lambda$.
  5. Victor verifies $F(lambda) = Z(lambda) H(lambda)$.
] <root-check>

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
we can fix $omega in FF_q$ to be a primitive $n$th root of unity.

Then, by polynomial interpolation, Peggy chooses polynomials $A(X)$, $B(X)$,
and $C(X)$ in $FF_q [X]$ such that
#eqn[
  $ A(omega^i) = a_i, #h(1em) B(omega^i) = b_i, #h(1em) C(omega^i) = c_i #h(1em)
    " for all " i = 1, 2, ..., n. $
  <plonk-setup>
]
We specifically choose $omega^i$ because that way,
if we use @root-check on the set ${omega, omega^1, ..., omega^n}$,
then the polynomial called $Z$ is just
$Z(X) = (X-omega) ... (X-omega^n) = X^n-1$, which is really nice.
In fact, often $n$ is chosen to be a power of $2$ so that $A$, $B$, and $C$
are really easy to compute, using a fast Fourier transform.
(Note: When you're working in a finite field, the fast Fourier transform
is sometimes called the "number theoretic transform" (NTT)
even though it's exactly the same as the usual FFT.)

Then:
#algorithm("Commitment step of PLONK")[
  1. Peggy interpolates $A$, $B$, $C$ as in @plonk-setup.
  2. Peggy sends $Com(A)$, $Com(B)$, $Com(C)$ to Victor.
]
To reiterate, each commitment is a 256-bit
that can later be "opened" at any value $x in FF_q$.

== Step 2: Gate-check

Both Peggy and Victor knows the PLONK instance,
so they can interpolate a polynomial
$Q_L(X) in FF_q [X]$ of degree $n-1$ such that
$ Q_L (omega^i) = q_(L,i) #h(1em) " for " i = 1, ..., n. $
Then the analogous polynomials $Q_R$, $Q_O$, $Q_M$, $Q_C$
are defined in the same way.

Now, what do the gate constraints amount to?
Peggy is trying to convince Victor that the equation
#eqn[
  $ Q_L (x) A (x) + Q_R (x) B (x) + Q_O (x) C (x)
    + Q_M (x) A (x) B (x) + Q_C (x) = 0 $
  <plonk-gate>
]
is true for the $n$ numbers $x = 1, omega, omega^2, ..., omega^(n-1)$.

However, Peggy has committed $A$, $B$, $C$ already,
while all the $Q_*$ polynomials are globally known.
So this is a direct application of @root-check:

#algorithm[Gate-check][
  1. Both parties interpolate five polynomials $Q_* in FF_q [X]$
    from the $15n$ coefficients $q_*$
    (globally known from the PLONK instance).
  2. Peggy uses @root-check to convince Victor that @plonk-gate
    holds for $X = omega^i$
    (that is, the left-hand side is is indeed divisible by $Z(X) := X^n-1$).
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

The copy constraints are the trickier step.
There are a few moving parts to this idea, so to ease into it slightly,
we provide a solution to a "simpler" problem called "permutation-check".
Then we explain how to deal with the full copy check.

=== Easier case: permutation-check

So let's suppose we have polynomials $P, Q in FF_q [X]$
which are encoding two vectors of values
$ arrow(p) &= angle.l P(omega^1), P(omega^2), ..., P(omega^n) angle.r \
  arrow(q) &= angle.l Q(omega^1), Q(omega^2), ..., Q(omega^n) angle.r. $
Is there a way that one can quickly verify $arrow(p)$ and $arrow(q)$
are the same up to permutation of the $n$ entries?

Well, actually, it would be necessary and sufficient for the identity
#eqn[
  $ (T+P(omega^1))(T+P(omega^2)) ... (T+P(omega^n))
    = (T+Q(omega^1))(T+Q(omega^2)) ... (T+Q(omega^n)) $
  <permcheck-poly>
]
to be true, in the sense both sides are the same polynomial in $FF_q [T]$
in a single formal variable $T$.
And for that, it actually is sufficient that a single random challenge
$T = lambda$ passes @permcheck-poly; as if the two sides of @permcheck-poly
aren't the same polynomial,
then the two sides can have at most $n-1$ common values.

We can then get a proof of @permcheck-poly
using the technique of adding an _accumulator polynomial_.
The idea is this: Victor picks a random challenge $lambda in FF_q$.
Peggy then interpolates the polynomial $F_P in FF_q [T]$ such that
$
  F_P (omega^1) &= lambda + P(omega^1) \
  F_P (omega^2) &= (lambda + P(omega^1))(lambda + P(omega^2)) \
  &dots.v \
  F_P (omega^n) &= (lambda + P(omega^1))(lambda + P(omega^2)) dots.c (lambda + P(omega^n)).
$
Then the accumulator $F_Q in FF_q[T]$ is defined analogously.

So to prove @permcheck-poly, the following algorithm works:

#algorithm[Permutation-check][
  Suppose Peggy has committed $Com(P)$ and $Com(Q)$.

  1. Victor sends a random challenge $lambda in FF_q$.
  2. Peggy interpolates polynomials $F_P [T]$ and $F_Q [T]$
    such that $F_P (omega^k) = product_(i <= k) (lambda + P(omega^i))$.
    Define $F_Q$ similarly.
    Peggy sends $Com(F_P)$ and $Com(F_Q)$.
  3. Peggy uses @root-check to prove all of the following statements:

    - $F_P (X) - (lambda + P(X))$
      vanishes at $X = omega$;
    - $F_P (omega X) - (lambda + P(X)) F_P (X)$
      vanishes at $X in {omega, ..., omega^(n-1)}$;
    - The previous two statements also hold with $F_P$ replaced by $F_Q$;
    - $F_P (X) - F_Q (X)$ vanishes at $X = 1$.
]

=== Copy check

Moving on to copy-check, let's look at a concrete example where $n=4$.
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
There's a really clever way to do this by tagging each entry with $+ eta^j omega^k mu$
in reading order for $j = 0, 1, 2$ and $k = 1, ..., n$;
here $eta in FF_q$ is any number such that $eta^2$ doesn't happen to be a power of $omega$,
so all the tags are distinct.
Specifically, if @copy1 is true, then for any $mu in FF_q$, we also have
#eqn[
  $
  & mat(
    a_1 + omega^1 mu, a_2 + omega^2 mu, a_3 + omega^3 mu, a_4 + omega^4 mu;
    b_1 + eta omega^1 mu, b_2 + eta omega^2 mu, b_3 + eta omega^3 mu, b_4 + eta omega^4 mu;
    c_1 + eta^2 omega^1 mu, c_2 + eta^2 omega^2 mu, c_3 + eta^2 omega^3 mu, c_4 + eta^2 omega^4 mu;
  ) \
  =&
  mat(
    #rbox($a_4$) + omega^1 mu, a_2 + omega^2 mu, a_3 + omega^3 mu, #rbox($c_3$) + omega^4 mu;
    b_1 + eta omega^1 mu, #bbox($c_1$) + eta omega^2 mu, b_3 + eta omega^3 mu, b_4 + eta omega^4 mu;
    #bbox($b_2$) + eta^2 omega^1 mu, c_2 + eta^2 omega^2 mu, c_3 + eta^2 omega^3 mu, #rbox($a_1$) + eta^2 omega^4 mu;
  )
  .
  $
  <copy2>
]
Now how can the prover establish @copy2 succinctly?
The answer is to run a permutation-check on the $3n$ entries of @copy2!
Because $mu$ was a random challenge,
one can really think of each binomial above more like an ordered pair:
for almost all challenges $mu$, there are no "unexpected" equalities.
In other words, up to a negligible number of $mu$,
@copy2 will be true if and only if the right-hand side is just
a permutation of the left-hand side.

To clean things up, shuffle the $12$ terms on the right-hand side of @copy2
so that each variable is in the cell it started at:
#eqn[
  $
  "Want to prove" & mat(
    a_1 + omega^1 mu, a_2 + omega^2 mu, a_3 + omega^3 mu, a_4 + omega^4 mu;
    b_1 + eta omega^1 mu, b_2 + eta omega^2 mu, b_3 + eta omega^3 mu, b_4 + eta omega^4  mu;
    c_1 + eta^2 omega^1 mu, c_2 + eta^2 omega^2 mu, c_3 + eta^2 omega^3 mu, c_4 + eta^2 omega^4 mu;
  ) \
  "is a permutation of" &
  mat(
  a_1 + #rbox($eta^2 omega^4 mu$), a_2 + omega^2 mu, a_3 + omega^3 mu, a_4 + #rbox($omega^1 mu$) ;
  b_1 + eta omega^1 mu, b_2+ #bbox($eta^2 omega^1 mu$), b_3 + eta omega^3 mu, b_4 + eta omega^4  mu ;
  b_1 + #bbox($eta omega^2 mu$), c_2 + eta^2 omega^2 mu, c_3 + eta^2 omega^3 mu, c_4 + #rbox($omega^4 mu$)
  )
  .
  $
  <copy3>
]
The permutations needed are part of the problem statement, hence globally known.
So in this example, both parties are going to interpolate cubic polynomials
$sigma_a, sigma_b, sigma_c$ that encode the weird coefficients row-by-row:
$
  mat(
    delim: #none,
    sigma_a (omega^1) = #rbox($eta^2 omega^4$),
    sigma_a (omega^2) = omega^2,
    sigma_a (omega^3) = omega^3,
    sigma_a (omega^4) = #rbox($omega^1$) ;
    sigma_b (omega^1) = eta omega^1,
    sigma_b (omega^2) = #bbox($eta^2 omega^1$),
    sigma_b (omega^3) = eta omega^3,
    sigma_b (omega^4) = eta omega^4  ;
    sigma_c (omega^1) = #bbox($eta omega^2$),
    sigma_c (omega^2) = eta^2 omega^2,
    sigma_c (omega^3) = eta^2 omega^3,
    sigma_c (omega^4) = #rbox($omega^4$).
  )
$
Then one can start defining accumulator polynomials, after
re-introducing the random challenge $lambda$ from permutation-check.
We're going to need six in all, three for each side of @copy3:
we call them $F_a$, $F_b$, $F_c$, $F_a'$, $F_b'$, $F_c'$.
The ones on the left-hand side are interpolated so that
#eqn[
  $
    F_a (omega^k) &= product_(i <= k) (a_i + omega^i mu + lambda) \
    F_b (omega^k) &= product_(i <= k) (b_i + eta omega^i mu + lambda) \
    F_c (omega^k) &= product_(i <= k) (c_i + eta^2 omega^i mu + lambda) \
  $
  <copycheck-left>
]
whilst the ones on the right have the extra permutation polynomials
#eqn[
  $
    F'_a (omega^k) &= product_(i <= k) (a_i + sigma_a (omega^i) mu + lambda) \
    F'_b (omega^k) &= product_(i <= k) (b_i + sigma_b (omega^i) mu + lambda) \
    F'_c (omega^k) &= product_(i <= k) (c_i + sigma_c (omega^i) mu  + lambda).
  $
  <copycheck-right>
]
And then we can run essentially the algorithm from before.
There are six initialization conditions
#eqn[
  $
    F_a (omega^1) &= A(omega^1) + omega^1 mu + lambda \
    F_b (omega^1) &= B(omega^1) + eta omega^1 mu + lambda \
    F_c (omega^1) &= C(omega^1) + eta^2 omega^1 mu + lambda \
    F_a (omega^1) &= A(omega^1) + sigma_a (omega^1) mu + lambda \
    F_b (omega^1) &= B(omega^1) + sigma_b (omega^1) mu + lambda \
    F_c (omega^1) &= C(omega^1) + sigma_c (omega^1) mu + lambda.
  $
  <copycheck-init>
]
and six accumulation conditions
#eqn[
  $
    F_a (omega X) &= F_a (X) dot (A(X) + X mu + lambda) \
    F_b (omega X) &= F_b (X) dot (B(X) + 2 X mu + lambda) \
    F_c (omega X) &= F_c (X) dot (C(X) + 3 X mu + lambda) \
    F'_a (omega X) &= F'_a (X) dot (A(X) + sigma_a (X) mu + lambda) \
    F'_b (omega X) &= F'_b (X) dot (B(X) + sigma_b (X) mu + lambda) \
    F'_c (omega X) &= F'_c (X) dot (C(X) + sigma_c (X) mu + lambda) \
  $
  <copycheck-accum>
]
before the final product condition
#eqn[
  $
  F_a (1) F_b (1) F_c (1) = F'_a (1) F'_b (1) F'_c (1)
  $
  <copycheck-final>
]

To summarize, the copy-check goes as follows:
#algorithm[Copy-check][
  1. Both parties compute the degree $n-1$ polynomials
    $sigma_a, sigma_b, sigma_c in FF_q [X]$ described above,
    based on the copy constraints in the problem statement.
  2. Victor chooses random challenges $mu, lambda in FF_q$ and sends them to Peggy.
  3. Peggy interpolates the six accumulator polynomials $F_a$, ..., $F'_c$ defined
    in @copycheck-left and @copycheck-right.
  4. Peggy uses @root-check to prove @copycheck-init holds.
  5. Peggy uses @root-check to prove @copycheck-accum holds
    for $X in {omega, omega^2, ..., omega^(n-1)}$.
  6. Peggy uses @root-check to prove @copycheck-final holds.
]

== Public and private witnesses

#todo[warning: $A$, $B$, $C$ should not be the lowest degree interpolations, imo 
AV: why not?  I think it's fine if they are]

The last thing to be done is to reveal the value of public witnesses,
so the prover can convince the verifier that those values are correct.
This is simply an application of @root-check.
Let's say the public witnesses are the values $a_i$, for all $i$ in some set $S$.
(If some of the $b$'s and $c$'s are also public, we'll just do the same thing for them.)
The prover can interpolate another polynomial, $A^"public"$, 
such that $A^"public"(omega^i) = a_i$ if $i in S$, and $A^"public"(omega^i) = 0$ if $i in.not S$.
Actually, both the prover and the verifier can compute $A^"public"$, since
all the values $a_i$ are publicly known!

Now the prover runs @root-check to prove that $A - A^"public"$ 
vanishes on $S$.
(And similarly for $B$ and $C$, if needed.)
And we're done.
