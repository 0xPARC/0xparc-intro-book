#import "@local/evan:1.0.0":*

= Practice run for Evan's talk

== Overview

Brian asked me to give a math-for-engineers talk on why polynomials
keep on reappearing over and over in cryptography.
I'm going to try my best, but this is going to be really a math philosophy talk.

I don't know if I'm able to give _the_ reason why polynomials, because that's above my pay-grade,
so I'm content to try to explain _one_ reason why polynomials appear.
The overall assertion is the following pseudo-theorem.

#proposition[
  Whenever you are trying to do linear algebra,
  the "best" choice of coefficients are given by polynomials.
]

To try to stake this claim, I'm going to do a dive into one particular protocol,
Shamir secret-sharing.
I'm going to phrase it entirely in terms of linear algebra at first,
and then show how polynomials arise "organically" as the best fit by several criteria.

== Secret-sharing

Let's say we want to do a $2$-of-$N$ secret sharing scheme,
which means we give each of $N$ people a secret share
such that any two of them can reconstruct the secret, but no single one of them.

The typical way to do this is to let $x$ be a number corresponding to the secret
and $y$ a random "noise" number.
Then

- Send person 1 the value of $x+y$
- Send person 2 the value of $2x+y$
- ...
- Send person $N$ the value of $N x+ y$.

Then each individual person has no information,
but any two can solve a two-variable system of equations to extract $x$.
For example, if person $8$ is told that $8x + y = 12245$
while person $9$ is told that $9x + y = 13112$,
then each of them alone doesn't know anything about $x$,
but together they can solve to get $(x,y) = (867, 5309)$.

What if you want to do $3$-of-$N$?
If you want to keep buying the linear algebra idea,
then the general principle is that we want to choose some functions $f$, $g$, $h$ such that

- Send person 1 the value of $f(1) x + g(1) y + h(1) z$
- Send person 2 the value of $f(2) x + g(2) y + h(2) z$
- ...
- Send person $N$ the value of $f(N) x + g(N) y + h(N) z$.

In the two-variable example, we just used $f(n) = n$ and $g(n) = 1$.
For three functions, what would we pick?
Well, let's first make a wish-list of properties that we would want to satisfy:

1. For every three indices $1 <= a < b < c <= N$, we want there to be a unique $(x,y,z)$
  solution to the linear algebra task
  $
    f(a) x + g(a) y + h(a) z &= 0 \
    f(b) x + g(b) y + h(b) z &= 0 \
    f(c) x + g(c) y + h(c) z &= 0.
  $
  This is equivalent to
  $ det M_(a,b,c) != 0 " where "
  M_(a,b,c) = mat(f(a), g(a), h(a); f(b), g(b), h(b); f(c), g(c), h(c)). $
2. Ideally, for practical reasons, we'd like $f$, $g$, $h$ to not grow too quickly
  and be pretty easy to calculate.
3. Ideally, for practical reasons, we'd like inverting $M_(a,b,c)^(-1)$ to be
  easy to implement.
  That is, actually solving the system shouldn't be too expensive.

Now, the thing I want to communicate is that the first property is "easy" to satisfy,
in the sense that I pull random numbers out of a hat,
the chance that the determinant happens to be zero is vanishingly small.
The issue with random garbage is that the second and third properties become harder to check,
and anyway we want a deterministic promise that $det M_(a,b,c) != 0$, not just a "probably".

== Vandermonde determinant

Up until now I've made no mention of polynomials yet, and that's on purpose,
because my thesis is that even in pure linear-algebra contexts
there are good reasons to want polynomials.
Now we'll bring them in.

If you know how Shamir's secret-sharing works already, you know what the functions
$f$, $g$, $h$ should be: it uses $f(n) = n^2$, $g(n) = n$, $h(n) = 1$.

To convince you there is something special about this choice,
let me show you a magic trick, which is how you can calculate the determinant
$ det mat(a^2, a, 1; b^2, b, 1; c^2, c, 1) $
completely in your head.
The idea is that this determinant has got to vanish when $a=b$,
because then the first two rows of the matrix will coincide.
Therefore, the determinant is a multiple of $a-b$.
For the same reason, it must be a multiple of $a-c$ and $b-c$.
In other words, the determinant should be a multiple of $(a-b)(a-c)(b-c)$.

However, the determinant is also a polynomial of degree $2+1+0=3$.
So there's no more "room" left for any additional factors!
In other words, the determinant _has_ to be equal to
$lambda (a-b)(a-c)(b-c)$ for some constant $lambda$.
And so all you need to is look at any particular monomial to determine $lambda$;
for example, if you look at the determinant you can see a $+a^2b$ on the diagonal,
which isn't cancelled out by anything else,
while $(a-b)(a-c)(b-c)$ also has an $+a^2b$ term, ergo $lambda = 1$.

In summary, we have the following result:
#theorem[Vandermonde determinant][
  We have
  $
    det M_(a,b,c) = det mat(a^2, a, 1; b^2, b, 1; c^2, c, 1)
    = (a-b)(a-c)(b-c)
  $
  The obvious generalization to more than three variables (with the same proof)
  is also valid, e.g.
  $
    det mat(
      a^3, a^2, a, 1;
      b^3, b^2, b, 1;
      c^3, c^2, c, 1;
      d^3, d^2, d, 1
    )
    = (a-b)(a-c)(a-d)(b-c)(b-d)(c-d).
  $
]
This theorem provides an affirmative answer to the first criteria,
and gives a reason to believe this is "pretty good" for the second criteria.
The point is that $M_(a,b,c)$ is _always_ going to equal zero if any of the variables are equal.
That means we expect $det M_(a,b,c)$ will always at least have to be "divisible" by
$(a-b)(a-c)(b-c)$, depending on what you mean by "divisible".
The fact that the Vandermonde determinant has no additional "garbage" factors means,
philosophically, we can't compress the sizes of $f$, $g$, $h$ in a meaningful further way.

== Lagrange interpolation

What about the last criteria --- actually solving the system quickly?
Let's specialize again to three-variables,
and in fact let's specialize to $a=2$, $b=3$, $c=5$ so we have fewer symbols.
That means we'd like to rapidly solve equations of the form
$
  4x + 2y + z &= lambda_2 \
  9x + 3y + z &= lambda_3 \
  25x + 5y + z &= lambda_5.
$

=== The case where just one $lambda_*$ is zero

Linear algebra means that it suffices to do the case where all but
one of the $lambda_*$'s is zero.
Let's try $lambda_2 = 1$, $lambda_3 = lambda_5 = 0$, that is:
$
  4x + 2y + z &= 1 \
  9x + 3y + z &= 0 \
  25x + 5y + z &= 0.
$
I'm going to show you yet another magic trick:
how you can solve for $(x,y,z)$ in your head, too.

The idea is to consider the polynomial whose roots are $3$ and $5$, namely
$ P(n) = (n-3)(n-5) = n^2 - 8 n + 15 $.
Now the trick is that this polynomial has $P(3) = P(5) = 0$ by definition,
and so $(x,y,z) = (1, -8, 15)$ will actually satisfy the second two equations! Indeed,
$
  9(1) + 3(-8) + (15) &= 0 \
  25(1) + 5(-8) + (15) &= 0.
$
But it doesn't satisfy the first equation, because $P(2) = (2-3)(2-5) = 3$ instead of $1$.
But that's no problem, because you can just scale by a factor of $3$:
so the answer is
$ (x,y,z) = (1/3, (-8)/3, 15/3). $

So in fact, solving the system of equations when all but one $lambda$ is zero
is really equivalent to just expanding the polynomial whose roots are the other $n-1$ numbers,
and then adding a scaling factor to get the last equation right.
And then solving a general system can be done by adding them all together.

=== A full general example

Let's put some flesh on this example by doing it fully explicitly for some numbers.

$
  4x + 2y + z &= 42 \
  9x + 3y + z &= 1337 \
  25x + 5y + z &= 2024.
$

We first solve the three "basic" systems using the procedure we described earlier
$
  cases(
    4x + 2y + z = 1,
    9x + 3y + z = 0,
    25x + 5y + z = 0,
    reverse: #true
  ) &=> arrow(v_2) = (1/3, (-8)/3, 15/3) " since " (n-3)(n-5) = n^2-8n+15 \
  cases(
    4x + 2y + z = 0,
    9x + 3y + z = 1,
    25x + 5y + z = 0,
    reverse: #true
  ) &=> arrow(v_3) = (1/(-2), (-7)/(-2), 10/(-2)) " since " (n-2)(n-5) = n^2-7n+10 \
  cases(
    4x + 2y + z = 0,
    9x + 3y + z = 0,
    25x + 5y + z = 1,
    reverse: #true
  ) &=> arrow(v_5) = (1/6, (-5)/6, 6/6) " since " (n-2)(n-3) = n^2-5n+6 \
$
Again, to reiterate,
the numerators are the coefficients you get when you expand a quadratic polynomial,
and the denominator is the scaling factor you throw in to make sure the last equation
comes out to $1$ (by plugging in the final input into the polyonmial).

Then the answer to the general system will just be
$
  & 42 arrow(v_2)
  + 1337 arrow(v_3)
  + 2024 arrow(v_5) \
  &=
  (
    42/3 + 1337/(-2) + 2024/6,
    (42 dot -8)/3 + (1337 dot -7)/(-2) + (2024 dot -5)/6,
    (42 dot 15)/3 + (1337 dot 10)/(-2) + (2024 dot 6)/6
  ) \
  &=
  (-1903/6, 17285/6, -4451).
$

This process, which works equally well in any number of variables,
is known in mathematics as
#link("https://en.wikipedia.org/wiki/Lagrange_polynomial")[Lagrange interpolation].

== Afterthought: random challenges

You might remember the following fundamental theorem about polynomials:
#theorem[
  A polynomial of degree $n$ has at most $n$ roots.
]
Fun fact: this theorem is secretly a _linear algebra_ fact, too.

In fact, we've basically already proven this, and I'll just point it out.
Suppose $P(T) = x T^2 + y T + z$ is a quadratic polynomial,
and $P$ has three roots $P(2) = P(3) = P(5) = 0$.
The claim is that $P$ must then be the zero polynomial.
If you actually plug in the numbers, this just saying
$ 4x+2y+z = 9x+3y+z = 25x+5y+z = 0 $
has only the solution $(x,y,z) = (0,0,0)$,
which is what we showed earlier by calculating the determinant $M_(2,3,5) = (2-3)(2-5)(3-5) != 0$.

As a consequence, we get the following corollary.
#corollary[
  Whenever $P$ and $Q$ are two _different_ polynomials of degree at most $d$,
  then there will be at most $d$ points at which they give different outputs,
  because $P-Q$ is a nonzero polynomial of degree at most $d$, and hence has at most $d$ roots.
]
This key fact is used in a lot of cryptographic protocols,
where whenever a prover wants to show two polynomials $P$ and $Q$ are equal to each other,
it's enough for them to receive a random challenge $lambda$ and show $P(lambda) = Q(lambda)$.
This works because if $P != Q$, a cheating prover would be exposed unless the verifier
was so unlucky they picked one of the $d$ roots of $P-Q$.
As long as the verifier has a lot of numbers to pick from (often $2^256$), this is vanishingly small.

And so the same linear algebra idea that let us do
Lagrange interpolation is also quietly pulling the strings
behind all the "random-challenge" protocols that show up ubiquitously.
