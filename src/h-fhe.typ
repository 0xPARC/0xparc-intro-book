#import "preamble.typ":*

= FHE intro raw notes

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
So you can actually try to translate into a problem with smaller $(q,n)$, which is call.ed:

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
