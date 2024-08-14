#import "@local/evan:1.0.0":*

= Practice run for Evan's talk

== Overview

Brian mentioned that some of the engineers were curious why polynomials keep on reappearing
over and over, and asked me to give a talk on this.
So this is going to be a math _philosophy_ talk.

I don't know if I'm able to give _the_ reason why polynomials, because that's above my pay-grade,
so I'm content to try to explain _one_ reason why polynomials appear.
The overall assertion is the following pseudo-theorem.

#proposition[
  Whenever you are trying to do linear algebra,
  the "best" choice of coefficients are given by polynomials.
]

What do I mean by this?
Let me give a concrete example by talking about secret sharing.

== Secret-sharing

Let's say we want to do a $2$-of-$N$ secret sharing scheme,
which means we give each of $N$ people a secret share
such that any two of them can reconstruct the secret, but no single one of them.
If we denote the secret by, say, an ordered pair of integers $(x,y)$,
then there is a pretty easy way to do this:

- Send person 1 the value of $x+y$
- Send person 2 the value of $x+2y$
- ...
- Send person $N$ the value of $x+N y$.

And then you can solve a two-variable system of equations.
In fact, no person can even recover one of $x$ or $y$,
so in practice often $x$ is the secret and $y$ is just a random blinding factor.

What if you want to do $3$-of-$N$?
If you want to keep buying the linear algebra idea,
then the general principle is that we want to choose some functions $f$, $g$, $h$ such that

- Send person 1 the value of $f(1) x + g(1) y + h(1) z$
- Send person 2 the value of $f(2) x + g(2) y + h(2) z$
- ...
- Send person $N$ the value of $f(N) x + g(N) y + h(N) z$.

In the two-variable example, we just used $f(n) = 1$ and $g(n) = n$.
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
$f$, $g$, $h$ should be: it uses $f(n) = 1$, $g(n) = n$, $h(n) = n^2$.
The relevant math theorem is this:
#theorem[Vandermonde determinant][
  $
    det M_(a,b,c) = det mat(1, a, a^2; 1, b, b^2; 1, c, c^2)
    = -(a-b)(a-c)(b-c)
  $
  The obvious generalization to more than three variables is also valid, e.g.
  $
    det mat(1, a, a^2, a^3; 1, b, b^2, b^3; 1, c, c^2, c^3; 1, d, d^2, d^3)
    = (a-b)(a-c)(a-d)(b-c)(b-d)(c-d).
  $
  although I never remember which $plus.minus$ sign is on the front.
]
This theorem provides an affirmative answer to the first criteria,
and gives a reason to believe this is "pretty good" for the second criteria.
The point is that $M_(a,b,c)$ is _always_ going to equal zero if any of the variables are equal.
That means we expect $det M_(a,b,c)$ will always at least have to be "divisible" by
$(a-b)(a-c)(b-c)$, depending on what you mean by "divisible".
The fact that the Vandermonde determinant has no additional garbage factors,
just a single $plus.minus$ sign, means we have a reason to believe
that we can't get a more reasonably slowly growing $f$, $g$, $h$.

== Lagrange interpolation

What about the last criteria?
Let's specialize again to three-variables,
and in fact let's specialize to $a=2$, $b=3$, $c=5$ so we have fewer symbols.
That means we'd like to "rapidly" solve equations of the form
$
  x + 2y + 4z &= lambda_2 \
  x + 3y + 9z &= lambda_3 \
  x + 5y + 25z &= lambda_5.
$
Linear algebra means that it suffices to do the case where one of the $lambda_*$'s is zero,

- TODO: switch order so leading coeffs first
- TODO: mention FTA is a _linear algebra_ fact
- TODO: evaluate this
