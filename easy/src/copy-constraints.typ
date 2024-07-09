#import "preamble.typ":*

#let rbox(s) = [#text(red)[#ellipse(stroke: red, inset: 2pt, s)]]
#let bbox(s) = [#text(blue)[#rect(stroke: blue, inset: 4pt, s)]]

= Copy Constraints in PLONK <copy-constraints>

Now we elaborate on Step 3 which we deferred back in @copy-constraint-deferred.
As an example, the constraints might be:
$ a_1 = a_4 = c_4
  #h(1em) "and" #h(1em)
  b_2 = c_1. $
Before we show how to check this,
we provide a solution to a "simpler" problem called "permutation-check".
Then we explain how to deal with the full copy check.

== Easier case: permutation-check

#problem[
Suppose we have polynomials $P, Q in FF_q [X]$
which encode two vectors of values
$ arrow(p) &= angle.l P(omega^1), P(omega^2), ..., P(omega^n) angle.r \
  arrow(q) &= angle.l Q(omega^1), Q(omega^2), ..., Q(omega^n) angle.r. $
Is there a way that one can quickly verify $arrow(p)$ and $arrow(q)$
are the same up to permutation of the $n$ entries?
]

Well, actually, it would be necessary and sufficient for the identity
#eqn[
  $ (T+P(omega^1))(T+P(omega^2)) ... (T+P(omega^n)) \
    = (T+Q(omega^1))(T+Q(omega^2)) ... (T+Q(omega^n)) $
  <permcheck-poly>
]
to be true, in the sense both sides are the same polynomial in $FF_q [T]$
in a single formal variable $T$.
And for that, it is sufficient that a single random challenge
$T = lambda$ passes @permcheck-poly: if the two sides of @permcheck-poly
aren't the same polynomial,
then the two sides can have at most $n-1$ common values.
So for a randomly chosen $lambda$
(chosen from a field with $q approx 2^(256)$ elements),
the chances that $T = lambda$ passes @permcheck-poly are extremely small.

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
Then the accumulator $F_Q in FF_q [T]$ is defined analogously.

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
    - $F_P (omega X) - (lambda + P(omega X)) F_P (X)$
      vanishes at $X in {omega, ..., omega^(n-1)}$;
    - The previous two statements also hold with $F_P$ replaced by $F_Q$;
    - $F_P (X) - F_Q (X)$ vanishes at $X = 1$.
]

== Copy check

Moving on to copy-check, let's look at a concrete example where $n=4$.
Suppose that our copy constraints were
$ #rbox($a_1$) = #rbox($a_4$) = #rbox($c_4$)
  #h(1em) "and" #h(1em)
  #bbox($b_2$) = #bbox($c_1$). $
(We've colored and circled the variables that will move around for readability.)
So, the copy constraint means we want the following equality of matrices:
#eqn[
  $
  mat(
    a_1, b_1, c_1;
    a_2, b_2, c_2;
    a_3, b_3, c_3;
    a_4, b_4, c_4
  )
  =
  mat(
    #rbox($a_4$), b_1, #bbox($b_2$) ;
    a_2, #bbox($c_1$), c_2 ;
    a_3, b_3, c_3 ;
    #rbox($c_4$), b_4, #rbox($a_1$);
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
    a_1 + omega^1 mu, b_1 + eta omega^1 mu, c_1 + eta^2 omega^1 mu;
    a_2 + omega^2 mu, b_2 + eta omega^2 mu, c_2 + eta^2 omega^2 mu;
    a_3 + omega^3 mu, b_3 + eta omega^3 mu, c_3 + eta^2 omega^3 mu;
    a_4 + omega^4 mu, b_4 + eta omega^4 mu, c_4 + eta^2 omega^4 mu;
  ) \
  =&
  mat(
    #rbox($a_4$) + omega^1 mu, b_1 + eta omega^1 mu, #bbox($b_2$) + eta^2 omega^1 mu;
    a_2 + omega^2 mu, #bbox($c_1$) + eta omega^2 mu, c_2 + eta^2 omega^2 mu;
    a_3 + omega^3 mu, b_3 + eta omega^3 mu, c_3 + eta^2 omega^3 mu;
    #rbox($c_4$) + omega^4 mu, b_4 + eta omega^4 mu, #rbox($a_1$) + eta^2 omega^4 mu;
  )
  .
  $
  <copy2>
]
Now how can the prover establish @copy2 succinctly?
The answer is to run a permutation-check on the $3n$ entries of @copy2!
The prover will simply prove that the twelve matrix entries
of the matrix on the left
are a permutation of the twelve matrix entries
of the matrix on the right.

The reader should check that this is correct!
If the prover starts with values $a_i$, $b_i$, and $c_i$
that don't satisfy all the copy constraints,
then a randomly selected $mu$ is very unlikely to satisfy this
permutation check.
The right-hand side will not be a permutation of the left-hand side,
and the check will fail.

To clean things up, shuffle the $12$ terms on the right-hand side of @copy2
so that each variable is in the cell it started at:
We want to prove
#eqn[
  $
  mat(
    a_1 + omega^1 mu, b_1 + eta omega^1 mu, c_1 + eta^2 omega^1 mu;
    a_2 + omega^2 mu, b_2 + eta omega^2 mu, c_2 + eta^2 omega^2 mu;
    a_3 + omega^3 mu, b_3 + eta omega^3 mu, c_3 + eta^2 omega^3 mu;
    a_4 + omega^4 mu, b_4 + eta omega^4  mu, c_4 + eta^2 omega^4 mu;
  ) \
  "is a permutation of" \
  mat(
  a_1 + #rbox($eta^2 omega^4 mu$), b_1 + eta omega^1 mu, c_1 + #bbox($eta omega^2 mu$) ;
  a_2 + omega^2 mu, b_2+ #bbox($eta^2 omega^1 mu$), c_2 + eta^2 omega^2 mu;
  a_3 + omega^3 mu, b_3 + eta omega^3 mu, c_3 + eta^2 omega^3 mu;
  a_4 + #rbox($omega^1 mu$),   b_4 + eta omega^4  mu,  c_4 + #rbox($omega^4 mu$)
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
    sigma_b (omega^1) = eta omega^1,
    sigma_c (omega^1) = #bbox($eta omega^2$) ;
    sigma_a (omega^2) = omega^2,
    sigma_b (omega^2) = #bbox($eta^2 omega^1$),
    sigma_c (omega^2) = eta^2 omega^2;
    sigma_a (omega^3) = omega^3,
    sigma_b (omega^3) = eta omega^3,
    sigma_c (omega^3) = eta^2 omega^3;
    sigma_a (omega^4) = #rbox($omega^1$),
    sigma_b (omega^4) = eta omega^4,
    sigma_c (omega^4) = #rbox($omega^4$).
  )
$
Then the prover can start defining accumulator polynomials, after
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
while the ones on the right have the extra permutation polynomials
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
    F_a' (omega^1) &= A(omega^1) + sigma_a (omega^1) mu + lambda \
    F_b' (omega^1) &= B(omega^1) + sigma_b (omega^1) mu + lambda \
    F_c' (omega^1) &= C(omega^1) + sigma_c (omega^1) mu + lambda.
  $
  <copycheck-init>
]
and six accumulation conditions
#eqn[
  $
    F_a (omega X) &= F_a (X) dot (A(omega X) + X mu + lambda) \
    F_b (omega X) &= F_b (X) dot (B(omega X) + eta X mu + lambda) \
    F_c (omega X) &= F_c (X) dot (C(omega X) + eta^2 X mu + lambda) \
    F'_a (omega X) &= F'_a (X) dot (A(omega X) + sigma_a (X) mu + lambda) \
    F'_b (omega X) &= F'_b (X) dot (B(omega X) + sigma_b (X) mu + lambda) \
    F'_c (omega X) &= F'_c (X) dot (C(omega X) + sigma_c (X) mu + lambda) \
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
  0. Peggy has already sent the three commitments
    $Com(A), Com(B), Com(C)$ to Victor;
    these commitments bind her to the values of all the variables
    $a_i$, $b_i$, and $c_i$.
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
