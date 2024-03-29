#import "preamble.typ":*

= The sum-check protocol

== Pitch: Sum-check lets you prove a calculation without having the verifier redo it

Let's imagine we have a _single_ equation
$ Z_1 + Z_2 + dots.c + Z_"big" = H $
for some variables $Z_i$ and constant $H in FF_q$, all over $FF_q$,
and assume further that $q$ is not too small.

Imagine a prover Penny has a value assigned to each $Z_i$,
and is asserting to the verifier Victor they $Z_i$'s sum to $H$.
Victor wants to know that Penny computed the sum $H$ correctly,
but Victor doesn't want to actually read all the values of $Z_i$.

Well, at face value, this is an obviously impossible task.
Even if Victor knew all but one of Penny's $Z_i$'s, that wouldn't be good enough.
Nevertheless, the goal of Sum-Check is to show that,
with only a little bit of extra structure, this is actually possible.

=== An oracle to a polynomial

Assume for convenience that the number of $Z$'s happens to be $2^n$
and change notation to a function $f colon {0,1}^n -> FF_q$,
so our equation becomes
$ sum_(arrow(v) in {0,1}^n) f(arrow(v)) = H $.
In other words, we have changed notation so that our variables are indexed over a
hypercube: from $f(0, dots, 0)$ to $f(1, dots, 1)$.

But suppose that the values of $f$ coincide with a polynomial
$P in FF_q[X_1, ..., X_n]$
of degree at most $d$ in each variable.

#theorem("Sum-check")[
  There's an interactive protocol that allows Penny to convince Victor
  that the value $H$ above is the sum, which takes

  - $n$ rounds of communication, where each message from Penny is a
    single-polynomial of degree at most $d$;
  - For Victor, only a single evaluation of the polynomial $P$ at some point
    (not necessarily in ${0,1}^n$).
]

In other words, Sum-Check becomes possible if Victor
can make _one_ call to an oracle that can tell Victor the value of
$P(r_1,...,r_n)$, for one random choice of $(r_1, ..., r_n) in FF_q^n$.
Note importantly that the $r_i$'s do not have to $0$ or $1$;
Victor chooses them randomly from the much larger $FF_q$.
But he can only ask the oracle for that single value of $P$,
and otherwise has no idea what any of the $Z_i$'s are.

This is a vast improvement from the case where Victor had to evaluate $P$ at
$2^n$ points and add them all together.

=== Comment on polynomial interpolation

The assumption that $f$ coincides with a low-degree polynomial might seem
stringent _a priori_.
However, the truth is that _every_ function $f : {0,1}^n -> FF_q$
can be expressed as a _multilinear_ polynomial!
(In other words, we can take $d=1$ in the above theorem.)

The reason is just polynomial interpolation.
For example, suppose $n=3$ and the eight (arbitrary) variable values were given
$
  f(0,0,0) &= 8 \
  f(0,0,1) &= 15 \
  f(0,1,0) &= 8 \
  f(0,1,1) &= 15 \
  f(1,0,0) &= 8 \
  f(1,0,1) &= 15 \
  f(1,1,0) &= 17 \
  f(1,1,1) &= 29.
$
(So $H = 8+15+8+15+8+15+17+29 = 115$.)
Then we'd be trying to fill in the blanks in the equation
$ P(x,y,z) = square + square x + square y + square z
  + square x y + square y z + square z x + square x y z $
so that $P$ agrees with $f$ on the cube.
This comes down to solving a system of linear equations;
in this case it turns out that $P(x,y,z) = 5x y z + 9x y + 7z + 8$ works,
and I've cherry-picked the numbers so a lot of the coefficients work out to $0$ for
convenience, but math majors should be able to verify that $P$ exists and is unique
no matter what eight initial numbers I would have picked (by induction on $n$).

Earlier, we commented that Sum-Check was an "obviously impossible task"
if the values of $f$'s were unrelated random numbers.
The reason this doesn't contradict the above paragraph is that,
if Penny just sends Victor the table of $2^n$ values,
it would be just as much work for Victor to manually compute $P$.
However, in a lot of contexts, the values that are being summed
can be construed as a polynomial in some way,
and then the sum-check protocol will give us an advantage.
We'll show two example applications at the end of the section.

== Description of the sum-check protocol

The author's opinion is that it's actually easier to see a specific example for
$n=3$ before specifying the pseudocode in general, rather than vice-versa.

=== A playthrough of the sum-check protocol

Let's use the example above with $n=3$:
Penny has chosen the eight values above with $H = 115$,
and wants to convince Victor without actually sending all eight values.
Penny has done her homework and computed the coefficients of $P$ as well
(after all, she chose the values of $f$), so Penny can evaluate $P$ anywhere she wants.
Victor is given oracle access to a single value of the polynomial $P$
on a point (probably) outside the hypercube.

Here's how they do it.
(All the information sent by Penny to Victor is $#rect("boxed")$.)

1. Penny announces her claim $H = #rect($115$)$.
2. They now discuss the first coordinate:
  - Victor asks Penny to evaluate the linear one-variable polynomial
    $ g_1(T) := P(T,0,0) + P(T,0,1) + P(T,1,0) + P(T,1,1) $
    and send the result. In our example, it equals
    $ g_1(T) = 8 + 15 + (9T+8) + (14T+15) = #rect($23T+46$). $

  - Victor then checks that this $g_1$ is consistent with the claim $H=115$;
    it should satisfy $H = g_1(0) + g_1(1)$ by definition.
    Indeed, $g_1(0)+g_1(1) = 46+69 = 115 = H$.

  - Finally, Victor commits to a random choice of $r_1 in FF_q$; let's say $r_1 = 7$.
    From now on, he'll always use $7$ for the first argument to $P$.

3. With the first coordinate fixed at $r_1 = 7$, they talk about the second coordinate:
  - Victor asks Penny to evaluate the linear polynomial
    $ g_2(U) := P(7,U,0) + P(7,U,1). $
    and send the result. In our example, it equals
    $ g_2(U) = (63U+8) + (98U+15) = #rect($161U + 23$). $

  - Victor makes sure the claimed $g_2$ is consistent with $g_1$;
    it should satisfy $g_1(r_1) = g_2(0)+g_2(1)$.
    Indeed, it does $g_1(7) = 23 dot 7 + 46 = 23 + 184 = g_2(0) + g_2(1)$.

  - Finally, Victor commits to a random choice of $r_2 in FF_q$; let's say $r_1 = 3$.
    From now on, he'll always use $3$ for the second argument to $P$.

4. They now settle the last coordinate:
  - Victor asks Penny to evaluate the linear polynomial
    $ g_3(U) := P(7,3,V) $
    and send the result. In our example, it equals
    $ g_3(U) = #rect($112V+197$). $

  - Victor makes sure the claimed $g_3$ is consistent with $g_2$;
    it should satisfy $g_2(r_2) = g_3(0)+g_3(1)$.
    Indeed, it does $g_2(3) = 161 dot 3 + 23 = 197 + 309 = g_3(0) + g_3(1)$.

  - Finally, Victor commits to a random choice of $r_3 in FF_q$; let's say $r_3 = -1$.

5. Victor has picked all three coordinates, and is ready consults the oracle.
  He gets $P(7,3,-1) = 85$.
  This matches $g_3(-1) = 85$, and the protocol ends.

=== General procedure

The previous transcript should generalize obviously to any $n > 3$,
but we spell it out anyways.
Penny has already announced $H$ and pre-computed $P$.
Now for $i = 1, ..., n$,

- Victor asks Penny to compute the univariate polynomial $g_i$
  corresponding to partial sum, where the $i$th parameter is a free parameter
  while all the $r_1$, ..., $r_(i-1)$ have been fixed already.
- Victor sanity-checks each of Penny's answer by making sure $g_i$ is consistent
  with (that is, $g_(i-1)(r_(i-1)) = g_i (0) + g_i (1)$,
  or for the edge case $i=1$ that $H = g_1(0) + g_1(1)$).
- Then Victor commits to a random $r_i in FF_q$ and moves on to the next coordinate.

Once Victor has decided on every $r_i$, he asks the oracle for $P(r_1, ..., r_n)$
and makes sure that it matches the value of $g_n(r_n)$.
If so, Victor believes Penny.

Up until now, we wrote the sum-check protocol as a sum over ${0,1}^n$.
However, actually there is nothing in particular special about ${0,1}^n$
and it would work equally well with $HH^n$ for any small finite set $HH$;
the only change is that the polynomial $P$
would now have degree at most $|HH|-1$ in each variable,
rather than being multilinear.
Accordingly, the $g_i$'s change from being linear to up to degree $|HH|-1$.
Everything else stays the same.

=== Soundness

TODO: Can Penny cheat?

== Two simple applications of sum-check

If you're trying to sum-check a bunch of truly arbitrary unrelated numbers,
and you don't have an oracle, then naturally it's a lost cause.
You can't just interpolate $P$ through your $2^n$ numbers as a "manual oracle",
because the work of interpolating the polynomial is just as expensive.

However, in real life, sum-check gives you leverage because of the ambient
context giving us a way to rope in polynomials.
We'll give two examples below.

TODO: Credit wherever the triangle example is from

=== Verifying a triangle count

Suppose Penny and Victor have a finite simple graph $G = (V,E)$ on $n$ vertices
and want to count the number of triangles in it.
Penny has done the count, and wants to convince a lazy verifier Victor
who doesn't want to spend the $O(n^3)$ time it would take to count it himself.

#proposition[
  It's possible for Penny to prove her count of the number
  of triangles is correct with only $O(n^2 log n)$ work for Vicrtor.
]

Note that Victor will always need at least $O(n^2)$ time
because he needs to read the input graph $G$, so this is pretty good.

#proof[
  Assume for convenience $n = 2^m$ and biject $V$ to ${0,1}^m$.
  Both parties then compute the coefficients of the multilinear function
  $g : {0,1}^2m -> {0,1}$ defined by
  $
    g(x_1, ..., x_m, y_1, ..., y_m)
    =
    cases(
      1 "if" (x_1, ..., x_m) "has an edge to" (y_1, ..., y_m),
      0 "otherwise".
    )
  $
  In general, this interpolation calculation takes
  $O(2^(2m) dot 2m) = O(n^2 log n)$ time.

  Once this is done, they set
  $ f(arrow(x), arrow(y), arrow(z)) :=
    g(arrow(x), arrow(y)) g(arrow(y), arrow(z)) g(arrow(z), arrow(x)). $
  they can just run the Sum-Check protocol on:
  $ "number triangles"
    = sum_(arrow(x) in {0,1}^m) sum_(arrow(y) in {0,1}^m) sum_(arrow(z) in {0,1}^m)
    f(arrow(x), arrow(y), arrow(z)) $
  This requires some work from Penny, but for Victor,
  the steps in between don't require much work.
  The final oracle call requires Victor to evaluate
  $ g(arrow(x), arrow(y)) g(arrow(y), arrow(z)) g(arrow(z), arrow(x)) $
  for one random choice $(arrow(x), arrow(y), arrow(z)) in (FF_p^m)^(times 3)$.
  Victor can do this because he's already computed all the coefficients of $g$.
]

#remark[
  Note that Victor does NOT need to compute $f$ as a polynomial,
  which is much more work.
  Victor does need to compute coefficients of $g$ so that it can be
  evaluated at three points.
  But then Victor just multiplies those three numbers together.
]

You could in principle check for counts of any
more complicated subgraph as opposed to just $K_3$.

=== Verifying a polynomial vanishes

Suppose $f(T_1, ..., T_n) in FF_q [T_1, ..., T_n]$
is a polynomial of degree up to $2$ in each variable,
specified by the coefficients.
Now Penny wants to convince Victor that
$f(x_1, ..., x_n) = 0$ whenever $x_i in {0,1}$.

Of course, Victor could verify this himself by plugging in all $2^n$ pairs.
Because $f$ is the sum of $3^n$ terms, this takes about $6^n$ operations.
We'd like to get this down:

#proposition[
  Penny can convince Victor that $f(x_1, ..., x_n) = 0$ for all $x_i in {0,1}$.
  with only $O(3^n + 2^n)$ work for Victor.
]

#proof[
  The idea is to take a random linear combination of the $2^n$ values.
  Specifically, Victor picks a multilinear polynomial
  $g(T_1, ..., T_n) in FF_q [T_1, ..., T_n]$
  coefficient by coefficient out of the $q^(2^n)$ possible multilinear polynomials.
  Note that this is equivalent to picking the $2^n$ values of
  $g(x_1, ..., x_n)$ for $(x_1, ..., x_n) in {0,1}^n$ uniformly at random.
  Then we run sum-check to prove that

  $ 0 = sum_(arrow(x) in {0,1}^n) f(x_1, ..., x_n) g(x_1, ..., x_n) $

  The polynomial $f g$ is degree up to $3$ in each variable, so that's fine.
  The final "oracle" call is then straightforward,
  because the coefficients of both $f$ and $g$ are known;
  it takes only $3^n + 2^n$ operations
  (i.e. one evaluates two polynomials each at one point,
  rather than $2^n$ evaluations).
]
