#import "@local/evan:1.0.0":*

= Advanced math seminar: Multilinear polynomial commitment scheme (Aard Vark)

== What is Binius and why is it important?

If you've seen PLONK before, it works in a field $FF_q$ where $q approx 2^256$ is a large prime.
In PLONK, values are packaged as the values of a polynomial $f$ at roots of unity.
Part of the problem is that using $FF_q$ as the base field generates a lot of overhead:
for example, in real life, our values are often $0$/$1$ bits,
but they would have to be encoded as a $256$-bit number in $FF_q$.

Binius instead tries to package the values not at roots of unity,
but instead at the values of a multilinear polynomial on the hypercube.

== Commitment schemes
=== What's a commitment scheme for?

We start with a reminder of what commitment scheme is for.

Let's think back to PLONK.
In PLONK, we had the concept of a KZG commitment.
This lets us commit to a list of values; for example,
if we had a list of 1,000,000 values,
we can interpolate the polynomial $f(1)$, $f(2)$, ..., $f(1000000)$ through those values
and send just a _single_ commitment (which is a single field element)
that can be opened at any particular value like $f(13)$.

So in general, a polynomial commitment scheme ought to let us _commit_ to a polynomial $f$
and then _open_ the commitment at any value of $f$
(and prove this value is right, without having to give the whole polynomial).

=== A different kind of polynomial

Binius will commit to a different kind of polynomial.
In KZG, we used single-variable polynomials $f(x)$,
but for Binius, we will need to commit to a _multilinear polynomial_.

To describe this, I need to define two concepts:

- Multilinear polynomials
- Reed-Solomon codes

We talk about these notes.

== Prerequisite: multilinear polynomials

=== Definition

#definition[
  A multilinear polynomial is an $n$-variable polynomial which is variable
  in each _individual_ variable, but not necessarily as a whole.
]
For example, if we had a multilinear polynomial in variables $x$, $y$, $z$,
then things like $1$, $x$, $y$, $z$, $x y$, $x y z$ could appear, but not $x^2$ or $x y^2 z^3$.

#example[Three variables gives eight coefficients][
  A three-variable multilinear polynomial is determined by eight coefficients:
  the coefficients of $1$, $x$, $y$, $z$, $x y$, $y z$, $z x$, $x y z$.

  In general, an $n$-variable multilinear polynomial is determined by $2^n$ coefficients.
]

=== Interpolation

Now, think back to Lagrange interpolation.
When we had a single-variable polynomial $f(x)$, let's say of degree $5$,
it's determined by six coefficients $f(x) = a_0 + a_1 x + ... + a_5 x^5$.
Or, turning it on its head, if we pick six points, we could find a (unique) polynomial through them.

So, if we have an $n$-variable mutlilinear polynomial,
then we would hope to be able to interpolate a unique polynomial through $2^n$ inputs.
In our case, we will specifically want to do interpolation
where the $2^n$ values are a _hypercube_ ${0,1}^n$.

Let's work this out concretely with two variables.
A generic two-variable polynomial would have the shape
$ f(x,y) = a + b x + c y + d x y. $

Let's do a hands-on interpolation example.
#exercise[
  Find coefficients $(a,b,c,d)$ such that
  $
  f(0,0) &= 1 \
  f(0,1) &= 5 \
  f(1,0) &= 3 \
  f(1,1) &= 2.
  $
]

#soln[
  The idea is to fix $x$ and interpolate $y$ as a linear polynomial first: we should have
  $
  f(0,y) &= 1+4y \
  f(1,y) &= 3-y.
  $
  Then we do the same idea again through the coefficients of $y$:
  $ f(x,y) = (1+2x) + (4-5x)y. #qedhere $
]

We have worked over $RR$ here, but in general for Binius we could imagine using instead
elements of the tower of fields

=== Extrapolation <extrapolation>

Let's go back to the table
$
  f(0,0) &= 1 \
  f(0,1) &= 5 \
  f(1,0) &= 3 \
  f(1,1) &= 2.
$
Here's a question:
#question[
  Can you calculate $f(0,3)$ without having to interpolate the polynomial?
  (That is, without referring to the interpolation we did earlier.)
]
#soln[
  The trick is that $ell(y) := f(0,y)$ is a linear function,
  so if $ell(0) = 1$ and $ell(1) = 5$ then we should have $ell(2) = 9$ and $ell(3) = 13$.
]

More generally, if
$ f(0,0) = alpha " and " f(0,1) = beta $
then the general answer is
$ f(0,3) = 3 beta - 2 alpha$
by considering the line $f(0,y) = alpha + (beta-alpha) y$.

Similarly, if we have
$ f(1,0) = gamma " and "  f(1,1) = delta $
then
$ f(1,3) = 3 delta - 2 gamma. $

== Prerequisite: Reed-Solomon codes

For this prerequisite, we'll go back to a single-variable polynomial.

Suppose you have four numbers, let's say $e$, $f$, $g$, $h$.
We want to provide some commitment to these four values,
that can be _spot-checked_. Let's explain how.

Our goal is to produce a single-variable polynomial such that
$ p(0) = e, #h(1em) p(1) = f, #h(1em) p(2) = g, #h(1em) p(3) = h. $
We know we can interpolate a cubic polynomial through them.
Rather than tell just these four values, we're actually going to tell eight values,
by adding the following four additional values:
$ p(4) = ..., #h(1em) p(5) = ..., #h(1em) p(6) = ..., #h(1em) p(7) = ... . $
The upshot of this is that a cubic polynomial is always determined by four points,
so if we wanted to try to "cheat" and change a value,
I would have to change _at least five_ of the eight values.
(That is, if we only change four values.)

That is, by doubling the length of the message, we allow _spot checking_,
in the sense that cheating would change at least half the components of the message.

== Prerequisite: Merkle trees

See #url("https://en.wikipedia.org/wiki/Merkle_tree")
(it's a simple construction, I promise).
tl;dr: A Merkle tree lets you commit a list of $N$ objects such that the commitment
is a single hash, and revealing a single element is done with a proof of length $log_2 N$.

== The commitment scheme for a multilinear polynomial

We are now ready to describe the commitment scheme for a multilinear polynomial.

=== Providing the commitment

Let's imagine for concreteness we have a four variable polynomial $f(w,x,y,z)$.
We're going to put the values of the polynomial in a table as follows:
$
  mat(
    f(#text(red)[0,0],#text(blue)[0,0]),
    f(#text(red)[0,0],#text(blue)[0,1]),
    f(#text(red)[0,0],#text(blue)[1,0]),
    f(#text(red)[0,0],#text(blue)[1,1]);

    f(#text(red)[0,1],#text(blue)[0,0]),
    f(#text(red)[0,1],#text(blue)[0,1]),
    f(#text(red)[0,1],#text(blue)[1,0]),
    f(#text(red)[0,1],#text(blue)[1,1]);

    f(#text(red)[1,0],#text(blue)[0,0]),
    f(#text(red)[1,0],#text(blue)[0,1]),
    f(#text(red)[1,0],#text(blue)[1,0]),
    f(#text(red)[1,0],#text(blue)[1,1]);

    f(#text(red)[1,1],#text(blue)[0,0]),
    f(#text(red)[1,1],#text(blue)[0,1]),
    f(#text(red)[1,1],#text(blue)[1,0]),
    f(#text(red)[1,1],#text(blue)[1,1]);
  )
$

We extend each _row_ of the table using the Reed-Solomon idea.
That is, for the $i$th row, we interpolate $p_i$ through that row and use that to double its length.
$
  mat(
    underbrace(f(#text(red)[0,0],#text(blue)[0,0]), =p_1(0)),
    underbrace(f(#text(red)[0,1],#text(blue)[0,0]), =p_1(1)),
    underbrace(f(#text(red)[1,0],#text(blue)[0,0]), =p_1(2)),
    underbrace(f(#text(red)[1,1],#text(blue)[0,0]), =p_1(3)),
    p_1(4), p_1(5), p_1(6), p_1(7);

    underbrace(f(#text(red)[0,0],#text(blue)[0,1]), =p_2(0)),
    underbrace(f(#text(red)[0,1],#text(blue)[0,1]), =p_2(1)),
    underbrace(f(#text(red)[1,0],#text(blue)[0,1]), =p_2(2)),
    underbrace(f(#text(red)[1,1],#text(blue)[0,1]), =p_2(3)),
    p_2(4), p_2(5), p_2(6), p_2(7);

    underbrace(f(#text(red)[0,0],#text(blue)[1,0]), =p_3(0)),
    underbrace(f(#text(red)[0,1],#text(blue)[1,0]), =p_3(1)),
    underbrace(f(#text(red)[1,0],#text(blue)[1,0]), =p_3(2)),
    underbrace(f(#text(red)[1,1],#text(blue)[1,0]), =p_3(3)),
    p_3(4), p_3(5), p_3(6), p_3(7);

    underbrace(f(#text(red)[0,0],#text(blue)[1,1]), =p_4(0)),
    underbrace(f(#text(red)[0,1],#text(blue)[1,1]), =p_4(1)),
    underbrace(f(#text(red)[1,0],#text(blue)[1,1]), =p_4(2)),
    underbrace(f(#text(red)[1,1],#text(blue)[1,1]), =p_4(3)),
    p_4(4), p_4(5), p_4(6), p_4(7);
  )
$

Next, we produce a _Merkle tree_ on the set of columns;
*the Merkle root is our commitment*.
This means that we can reveal any individually column.

=== Opening the commitment

Let's suppose someone wants to query $f(3,2,4,3)$.
Of course, one dumb thing we can do is just provide all $16$ values,
but our goal is to do better.
The idea of our commitment is to do just the second half: if we could send the four values of

- $f(0,0,#text(green)[4,3])$
- $f(0,1,#text(green)[4,3])$
- $f(1,0,#text(green)[4,3])$
- $f(1,1,#text(green)[4,3])$

and prove their correctness, then this would be enough to unveil $f(3,2,4,3)$.
So the general situation, we are improving $N$ to $sqrt(N)$ over the naive method
(where $N = 2^("big")$ rather than $N = 2^4$ here).

The way we think about this is to imagine adding a new "phantom" row to the table corresponding
to the challenge $f(bullet,bullet,4,3)$ that was provided.
(The Merkle commitment for all the other tables is already fixed, and sent.)

$
  mat(
    underbrace(f(#text(red)[0,0],#text(blue)[0,0]), =p_1(0)),
    underbrace(f(#text(red)[0,1],#text(blue)[0,0]), =p_1(1)),
    underbrace(f(#text(red)[1,0],#text(blue)[0,0]), =p_1(2)),
    underbrace(f(#text(red)[1,1],#text(blue)[0,0]), =p_1(3)),
    p_1(4), p_1(5), p_1(6), p_1(7);

    underbrace(f(#text(red)[0,0],#text(blue)[0,1]), =p_2(0)),
    underbrace(f(#text(red)[0,1],#text(blue)[0,1]), =p_2(1)),
    underbrace(f(#text(red)[1,0],#text(blue)[0,1]), =p_2(2)),
    underbrace(f(#text(red)[1,1],#text(blue)[0,1]), =p_2(3)),
    p_2(4), p_2(5), p_2(6), p_2(7);

    underbrace(f(#text(red)[0,0],#text(blue)[1,0]), =p_3(0)),
    underbrace(f(#text(red)[0,1],#text(blue)[1,0]), =p_3(1)),
    underbrace(f(#text(red)[1,0],#text(blue)[1,0]), =p_3(2)),
    underbrace(f(#text(red)[1,1],#text(blue)[1,0]), =p_3(3)),
    p_3(4), p_3(5), p_3(6), p_3(7);

    underbrace(f(#text(red)[0,0],#text(blue)[1,1]), =p_4(0)),
    underbrace(f(#text(red)[0,1],#text(blue)[1,1]), =p_4(1)),
    underbrace(f(#text(red)[1,0],#text(blue)[1,1]), =p_4(2)),
    underbrace(f(#text(red)[1,1],#text(blue)[1,1]), =p_4(3)),
    p_4(4), p_4(5), p_4(6), p_4(7);

    underbrace(f(0,0,#text(green)[4,3]), =q(0)),
    underbrace(f(0,1,#text(green)[4,3]), =q(1)),
    underbrace(f(1,0,#text(green)[4,3]), =q(2)),
    underbrace(f(1,1,#text(green)[4,3]), =q(3)),
    q(4), q(5), q(6), q(7);
  )
$

Ignoring protocol stuff for the moment, let's ask:
the prover has all of the first four rows.
How would the prover calculate the last row?

The first half of the phantom row is done by using the extrapolation we described before
in @extrapolation, using just the first four columns.

The second half is more interesting.
There's actually two ways to get $q(4)$, for example, that give the same answer:

- Using the phantom row:
  We know $q(0)$, $q(1)$, $q(2)$, $q(3)$,
  and then we can do Lagrange interpolation.
- Using the fifth column: perform the @extrapolation procedure
  on $p_1(4)$, $p_2(4)$, $p_3(4)$, $p_4(4)$.

Now let's get back to the protocol.
The prover sends the entire bottom phantom row, and asserts they calculated it right.

In order to verify it's correct,
the verifier will pick a random column on the right half of the table
and ask the prover to reveal it (via the Merkle tree).
For example, if the prover asks to reveal the $7$th column,
then the verifier opens the Merkle commitment for
$ mat(p_1(7); p_2(7); p_3(7); p_4(7)) $
and the verifier checks that $q(7)$ is indeed what you get via @extrapolation.

== Where does the binary come in?

The commitment scheme we've describe is actually called the _Brakedown_ commitment scheme.
The Binius one, instead of working over $RR$ like we did here,
we would use the binary field that we described before.
This will probably not be discussed in today's session because we're a bit over-time.
