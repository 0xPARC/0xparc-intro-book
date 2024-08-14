#import "@local/evan:1.0.0":*

= Math seminar for August 12: Binius (Aard Vark)

== Synopsis

One of the annoyances about our cryptographic ecosystem right now is they
often have different underlying base fields.
For example, one system might use a 128-bit prime while the other uses a 256-bit prime.
And then you have to figure out how to interact between them,
and there may not be a great way to do this in general.

So why don't we just use a two-element field $FF_2$?

Well, the problem is that most of our protocols rely on $q$ over $FF_q$,
say $q approx 2^256$.
This is an important criteria because, for example, a random challenge comes from a huge space,
so two polynomials that differ are unlikely to have many common roots.
Over $FF_2$, we don't have this, $2$-element fields are too small.

So in this math talk we're going to try to build a _finite extension_ of $FF_2$ that's big.

== Review of complex numbers

Recall that the way we extend $RR$ to $CC$ by adjoining a single element,
traditionally named $i$, which is imagined as a root of the (irreducible) polynomial $X^2+1$.
Our tower looks like

$
  i in& CC
  & RR
$

After we do this, we can do addition, e.g.
$ (a + b i)(c + d i) = (a c - b d) + (b c + a d) i. $
Division can be done too since
$ a + b i = a/(a^2+b^2) + b/(a^2+b^2) i. $

== Construction of $FF_4$, the field with four elements

We'd like to do the same thing by taking an irreducible quadratic polynomial over $FF_2$.
There are four possible quadratic polynomials ($X^2$, $X^2+1$, $X^2+X$, $X^2+X+1$),
and of these only the fourth one is irreducible.
So let us agree to take $p_0$ to be a root of $X^2+X+1$.
Then $FF_4$ will consist of our four elements
$ FF_4 = { a p_0 + b | a in {0,1}, b in {0,1} }. $

Our tower of fields now has two links in it:
$
  p_0 in& FF_4 \
  & FF_2
$

As some practice with arithmetic in this fields:
$
  p_0^2 &= p_0 + 1 \
  p_0 + p_0 &= (1+1) p_0 = 0 \
  1/p_0 &= p_0 + 1 \
  1/(p_0+1) &= p_0.
$
(Right now, this third identity might be easiest to find by guessing all four,
since there are only four elements. The fourth one follows from the third identity.)

Now for $FF_4$ we're going to imagine we encode our four elements using binary strings:
$
  0 &-> 00 \
  1 &-> 10 \
  p_0 &-> 01 \
  p_0+1 &-> 11.
$
In other words, we encode $a+b p_0$ by simply writing $a b$.
Then

- Addition corresponds to just bitwise XOR; but
- Multiplication is more annoying: $(a + b p_0)(c + d p_0) = (a c + b d) + (a d + b c + b d) p_0$.
  We could imagine implementing this in a circuit.

== Moving on to $FF_16$, the field with eight elements

To extend $FF_4$ to $FF_16$,
we need to guess a quadratic polynomial with coefficients in $FF_4$ which is irreducible.
It turns out that about half of the choices will factor and half won't.

But we standardize one particular choice to make things easier.
Recall that $p_0 in F_4$.
Ur next element $p_1$ will be chosen so that
$ p_1 + 1/p_1 = p_0. $
Indeed, we can check $ X + 1/X $ has no roots of $FF_4$ by trying them all.
(Note that $p_0 + 1/p_0 = 1$ and $(p_0+1) + 1/(p_0+1) = 1$.)
In still other words, $p_1$ is chosen to be one root of the quadratic
$ X^2 - p_0 X + 1 = 0. $

We then write
$ FF_16 = { a p_1 + b | a in FF_4, b in FF_4 } $
which indeed has $4^2 = 16$ elements.

Our tower of fields now reads
$
  p_1 in& FF_16 \
  p_0 in& FF_4 \
  & FF_2
$

Multiplication can be done, e.g.
$ p_1^2 = p_0 p_1 + 1. $
As a more complicated example, we can calculate
$
  &#hide[=] (p_0 p_1 + 1)^2 \
  &= p_0^2 p_1^2 + 1 \
  &= p_0^2 (p_0 p_1 + 1) + 1 \
  &= p_0^3 p_1 + (p_0^2 + 1) \
  &= p_0 + p_1.
$

Division can be done by a system of equations or a "multiply-by-conjugate" trick,
but we won't cover that here.

== Keep going

Now $16$ elements is still not good enough for cryptographic security,
so we now have to show how we keep going.

We go one level higher from $FF_16$ to $FF_256$ by introducing $p_2$ such that
$ p_2 + 1 / p_2 = p_1 <=> p_2^2 + 1 = p_1 p_2. $

(We won't prove that $t + 1/t != p_1$ for any $t in FF_16$,
i.e. that $X^2 - p_1 X + 1$ does not factor in $FF_16$.
I think a high-powered proof is to use the fact that the
Chebyshev polynomials are irreducible modulo $2$.)

Our tower now looks like:

$
  p_2 in& FF_256 \
  p_1 in& FF_16 \
  p_0 in& FF_4 \
  & FF_2.
$

The pattern continues

$ FF_256 = { a p_2 + b | a in FF_16, b in FF_16 } $


Multiplication can be done in an analogous way, by induction:
$ (a p_2 + b)(c p_2 + d)
  &= a c p_2^2 + (b c + a d) p_2 + b d \
  &= (b c + a d + a c) p_2 + (b d + a c) $

Bit representations can done by induction as well.
An $FF_16$ element could be written as
$ a_0 + a_1 p _0 + a_2 p_1 + a_3 p_0 p_1 $
and hence a four-bit string.
An $FF_256$ element could be written with $8$ bits as you need.
