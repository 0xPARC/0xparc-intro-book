#import "preamble.typ":*

*WARNING*: THESE ARE NOT POLISHED AT ALL AND MAY BE NONSENSE.

= FHE intro raw notes (April 16 raw notes from lecture)

#todo[raw notes based on Aard's lecture]

*Fully homomorphic encryption* (FHE) refers to the idea that one can have some encrypted data
and do circuit operations on this encrypted data (NAND gates, etc.).

== Outline

There are six pieces that go into this:

1. LWE (learning with errors): this was the red/blue tables from the retreat.
  Given a secret $arrow(a)$ and a bunch of vectors $arrow(v)$,
  and the values of $angle.l arrow(a), arrow(v) angle.r + epsilon(arrow(v))$
  where there are errors $epsilon(v) in {0,1}$, determine $arrow(a)$.
2. How to public key cryptosystem out of LWE
3. The _approximate eignevector trick_
4. The _flatten trick_.

After the first four items, we get *somewhat homomorphic encryption*,
which works but only up to a certain depth.
(LWE always give small errors, and the errors compound as you do more operations.)
To get from somewhat homomorphic encryption to FHE, we need:

5. Bootstrapping trick.

It turns out that LWE problems don't really care about the values of $(q,n)$.
So you can actually try to translate into a problem with smaller $(q,n)$, which is called:

6. Dimension and modulus reduction

== Learning with errors (LWE)

Pick parameters $q$ and $n$, and a "secret key" $arrow(s) in FF_q^n$.
I put secret key in quotes because we're not going to try to do cryptography just yet;
instead, I'll invite you to guess $arrow(s)$.

Here's the puzzle.
For lots of vectors $arrow(x) in FF_q^n$, I will share with you
$ ( arrow(x), arrow(x) dot arrow(s) + epsilon ) $
where the "errors" $epsilon$ are being sampled from some random distribution
(e.g. Gaussian, doesn't really matter) and bounded with $|epsilon| <= r$.
At the retreat, we had $r = 1$.

I'm happy to give you as many of these perturbed dot products as you like.
The challenge is to determine $arrow(s)$.
#footnote[
  Technically, at the retreat we did a decision problem, but it's no different.
  Yan has an write-up at #url("https://hackmd.io/F1vjMWzhTk-J7u-ctWQIIQ")
  of the red and blue example.
]

Assume LWE is a "hard" problem, i.e. we can't easily recover $arrow(s)$ in this challenge.
(LWE might be hard even when $q=2$, if $epsilon$ is say 90% zero and 10% one.)

=== Attacks on LWE

- Brute force $epsilon$: once you have $n$ vectors, guess all $(2r+1)^n$
  possibilities of $epsilon$ and invert the matrices, and see if they work with other vectors.
- Find linear dependencies among the $arrow(x)_i$.

Turns out all the naive algorithms still end up being exponential in $n$.

#remark[
  Lattice-based cryptography uses "find the shortest vector in a lattice" as a hard problem,
  and it turns out LWE can be reduced to this problem.
  So this provides reasons to believe LWE is hard.
]

== Building a public-key system out of LWE

Here's how to build a public-key system.

The public key will consist of $m$ ordered pairs
$ arrow(x)_i, #h(1em) y_i := arrow(x)_i dot arrow(s) + epsilon_i $
where $m approx 2 n log q = 2 log(q^n)$ and $epsilon_i$ are small errors.
We'll assume roughly the size constraints $n^2 <= q <= 2^(sqrt(n))$.

Now, how can I submit a single bit?
Suppose Bob wants to send a single bit to Alice.
The idea is to take $arrow(x)$ as a "not-too-big" random linear combination, like say
$ arrow(x) := 2 arrow(x)_1 + arrow(x)_7 + arrow(x)_9 $
so that Bob can compute
$ y := 2 y_1 + y_7 + y_9 = arrow(x) dot arrow(s) + "up to 4 errors". $
Then Bob sends $arrow(x)$ and then _either_ $y + floor(q/2)$ or $y$.

Since Alice knows the true value of $arrow(x) dot arrow(s)$,
she can figure out whether $y$ or $y + floor(q/2)$ was sent.

So $m$ needs to be big enough that $arrow(x)$ could be almost anything
even with "not-too-big" coefficients, but small enough LWE is still hard.

== Building homomorphic encryption on top of this: approximate

Addition is actually just addition (as long as you don't add too many things
and cause the errors to overflow).
But multiplication needs a new idea, the approximate eigenvalue trick.

Suppose Bob has a message $mu in {0, 1} subset FF_q$.
Our goal is to construct a matrix $C$ such that $C arrow(s) approx mu arrow(s)$,
which we can send as a ciphertext.

#algorithm[
  1. Use the public key to find $n$ "almost orthogonal" vectors $arrow(c)_i$,
    meaning $arrow(c)_i dot arrow(s)$ is small.
  2. If $mu = 0$, use $C$ as the matrix whose rows are $arrow(c_i)$.
  3. If $mu = 1$, take the matrix $C$ from Step 2
    and then increase its diagonal by $floor(q/2)$.
]

The NOT gate is $1 - C$.

#todo[something about subset sum?]

#todo[I think we can commit to $arrow(s)$ having first component $1$ for convenience
  because the augmentation thing is terrible notation-wise]

If we can do this, then multiplication can be done by multiplying the matrices.

#todo[Use NOT, AND gates]

= FHE intro raw notes continued (April 23 raw notes from lecture)

== Recap

To paraphrase last week's setup:

- Our secret key is a vector $v = (1, ...)$ of length $n+1$.
- Our public key is about $2 log(q^n) = 2 n log q$ vectors $a$ such that $a dot v approx 0$.

#remark[
  I think we don't even really care whether $q$ is prime or not,
  if we work in $ZZ slash q ZZ$.
]

Our idea was that given a message $mu in {0,1}$,
we construct a matrix $C$ such that $C v approx mu v$; the matrix $C$ is the ciphertext.
And we can apply NOT by just looking at $id - C$.

Then given the equations
$
  C_1 v &= mu_1 v + epsilon_1 \
  C_2 v &= mu_2 v + epsilon_2
$
the multiplication goes like
$
  C_1 C_2 v = mu_1 mu_2 v + (mu_2 epsilon_1 + C_1 epsilon_2).
$
In the new error term, $mu_2 epsilon_1$ is still small,
but $C_1 epsilon_2$ is not obviously bounded,
because we don't have constraints on the entries of $C_1$.

== Flatten

So our goal is to modify our scheme so that:
#goal[
  We want to change our protocol so that $C$ only has zero-one entries.
]
To do this, we are going to demand our secret key $v$ has a specific form: it must be
$ v = (& 1,  2,  4,  ....,  2^ell, \
   & a_1,  2a_1,  4a_1,  ...,  2^ell a_1, \
   & a_2,  2a_2,  4a_2,  ...,  2^ell a_2, \
   & ..., \
   & a_p,  2a_p,  4a_p,  ...,  2^ell a_p ) $
where $ell approx log(q)$, where $p := n / ell - 1$.
(This means we really have security parameters $(p,q)$ rather than $(n,q)$.)
#todo[
  I think it's better to use $n$ and $N$ instead of $p$ and $n$.
  Also, maybe we should just always use $arrow(s)$ for the secret key vector?
  $v$ feels too generic for something that never changes lol.
]

#proposition[
  There exists a map $Flatten : FF_q^n -> FF_q^n$
  taking row vectors of length $n$ such that:

  - $Flatten(r)$ has all entries either $0$ or $1$
  - $Flatten(r) dot v = r dot v$ for any $v$ in nice binary form.

]

We can then extend $Flatten$ to work on $n times n$ matrices,
by just flattening each of the rows.

When we add this additional assumption, we have a natural map
$ C |-> Flatten(C) $
on matrices that forces them to have $0$/$1$.

#example[
  For concreteness, let's write out an example $ell = 3$ and $p = 2$, so
  $ v = (1,2,4,8, a_1, 2a_1, 4a_1, 8a_1, a_2, 2a_2, 4a_2, 8a_2). $
  Let $q = 13$ for concreteness.
  Suppose the first row of $C$ is
  $ r := (3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5, 8). $
  Then, we compute the dot product
  $ r dot v = 29 + 79 a_1 + 95 a_2 = 3 + 11 a_1 + 4 a_2 pmod(13). $
  Now, how can we get a 0-1 vector? The answer is to just use binary: we can use
  $ Flatten(r) = (1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1, 0) $
  because
  $ Flatten(r) dot v = (1+2) + (1+2+8) a_1 + 4 a_2. $
  Repeating this for however many rows of the matrix you need
]

So, we can flatten any ciphertexts $C$ we get.
Now if $C_1$ and $C_2$ are flattened already, if we multiply $C_1$ and $C_2$,
we don't get a zero-one matrix; but we can just use $Flatten(C_1 C_2)$ instead.

== Going from somewhat homomorphic encryption to fully homomorphic encryption

After a while, our errors are getting big enough that we have trouble.
So we show how to go from somewhat homomorphic encryption to FHE.

This is the jankiest thing ever:

- So, suppose we're stuck at $Enc_(pk)(x)$.
- Generate another pair $(pk', sk')$.
- Send $Enc_(pk')(sk)$.
- We could compute $Enc_(pk')(Enc_(pk)(x))$.
- The decryption is itself a circuit of absolute constant length.
  If we picked $(pk, pk')$ well, we should be able to get $Enc_(pk')(x)$.

So we need a way to convert $Enc_(pk')(x)$ back to $Enc_(pk)(x)$.

Let's assume for now $q = q'$.
So let's say we have a secret key $v in FF_q^n$ and $v' in FF_q^(n')$.
Our goal is to provide an almost linear map
$ F = F_(v,v') : FF_q^n -> FF_q^(n') $
that given an arbitrary vector $a in FF_q^n$, gives $F(a) in FF_q^(n')$ such that
$ F(a) dot v' approx a dot v. $

#todo[Something seems fishy here: we were about to provide $F$ at all values
  of $(0, ..., 0 2^i, 0 ..., 0)$, but this seems like too much information.
  Defer to next meeting.]

In the case where $q' != q$, modulus reduction is done by
$ (F(a) dot v') / q' approx (a dot v) / q. $
