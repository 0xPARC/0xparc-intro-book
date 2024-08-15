#import "preamble.typ":*

= Lookups and cq <cq>

This is a summary of cq,
a recent paper that tells how to do "lookup arguments"
in a succinct (or ZK) setting.

== What are lookups

Suppose you have two lists of items,
$f_1, dots, f_n$ and $t_1, dots, t_N$.
A "lookup argument" is an interactive proof protocol
that lets Peggy prove the following claim,
with a short proof:
#claim[
Each of the $f_i$'s is equal to (at least) one of the $t_j$'s.
]

=== Wait a second, who cares?

Here are a couple of applications of lookups
which are very very important
as part of practical ZK proof systems.

#example[
Range checks.

Suppose you have some field element $x$,
and you want to prove some claim like $0 lt.eq.slant x < 2^{64}$.
This sort of thing is surprisingly difficult in ZK,
because we're working in a finite field,
and there's no notion of "less than" or "greater than" in a finite field.

Kind of incredibly, one of the most competitive ways to prove this claim
turns out to be a lookup argument:
You simply write out a list of all the numbers $0, 1, dots, 2^{64} - 1$,
and check that $x$ is in this list.

There are lots of variants on this idea.
For example, you could write $x$ in base $2^{16}$ as
$$x = x_0 + 2^{16} x_1 + 2^{32} x_2 + 2^{48} x_3,$$
and run a lookup argument on each $x_i$ to show that $0 lt.eq.slant x_i < 2^{16}$.
]

#example[
Function lookups.

Suppose you have some function $f$ that is hard to compute in a circuit,
and you want to prove that $y = f(x)$,
where $x$ and $y$ are two numbers in your proof.

One way to do it is to precompute a table of all the pairs $(x, f(x))$,
and then look up your specific value $(x, y)$ in the table.
] <function-lookups>

=== Back to lookups

Let's notice a couple of features of these applications of the lookup problem.

First of all, let's call the values $f_i$ the _sought_ values,
and the values $t_j$ the _table_ or the _index_.
So the lookup problem is to prove that all the sought values can be found in the table.

- The values $t_j$ are typically known to the verifier.
- The table $t_1, dots, t_N$ might be very long (i.e. $N$ might be very big).
  In practice it's not uncommon to have a value of $N$ in the millions.
- A single, fixed table of values $t_j$ might be used in many, many proofs.

Conversely:

- The values $f_i$ are usually secret, at least if the prover is concerned about zero knowledge.
- There may or may not be many values $f_i$ (i.e. $n$ might be big or small).
  If $n$ is small, we'd like the prover runtime to be relatively small (roughly $O(n)$),
  even if $N$ is big.
- The values $f_i$ will be different in every proof.

As it turns out, lookups are a huge bottleneck in ZK proof systems,
so an incredible amount of work has been done to optimize them.
We're just going to talk about one system.

#remark[
We will assume that the values $f_i$ and $t_j$ are all elements of some large finite field $FF_q$,
and we will do algebra over this finite field.

In general, you might want to work with other values of other types than field elements.
In the "function lookups" example (@function-lookups),
we want to work with ordered pairs (of, say, field elements).
In other contexts we might want to work with (suitably encoded) strings, or...

You can always solve this by hashing whatever type it is into a field element.

A second option (the "random linear combination" trick, we will see a lot of it)
is to use a verifier challenge.
In place of the pair $(x_i, y_i)$, we will work with the single field element $x_i + r y_i$,
where $r$ is randomness provided by the verifier.

In more detail, imagine you have a list of pairs $(x_i, y_i)$ that you want to run a lookup argument on.
The prover sends two commitments, one to $x_1, dots, x_n$, and one to $y_1, dots, y_n$.
The verifier responds with a challenge $r$, and then you run the lookup argument on the elements
$x_i + r y_i$.
(This is secure because the prover committed to both vectors before $r$ was chosen.)

A similar trick works for tuples of arbitrary length:
just use powers of $r$ as the coefficients of your random linear combination.

In any case, we will only consider looking up field elements from here on out.
]

== cq

The name of the system "cq" stands for "cached quotients."
For extra punniness, the authors of the paper note that "cq" is pronounced like "seek you."

Cq lookup arguments are based on the following bit of algebra:
#theorem[
The lookup condition is satisfied
(every $f_i$ is equal to some $t_j$)
if and only if there are field elements $m_j$ such that
$
sum_(i=1)^n (1)/(X - f_i) = sum_(j=1)^N (m_j)/(X - t_j)
$
(as a formal equality of rational functions of the formal variable $X$).
] <cq-identity>

#proof[
If each $f_i$ is equal to some $t_j$, it's easy.
For each $j$, just take $m_j$ to be the number of times $t_j$
occurs among the $f_i$'s, and the equality is obvious.

Conversely, if the equality of rational functions holds,
then the rational function on the left will have a pole at each $f_i$.
The rational function on the right can only have poles at the values $t_j$
(of course, it may or may not have a pole at any given $t_j$, depending
whether $m_j$ is zero or not),
so every $f_i$ must be equal to some $t_j$.
]

=== Polynomial commitments for cq

Cq is going to rely on polynomial commitments.
For concreteness, we'll work with KZG commitments (@kzg).

Cq will let the prover prove the lookup claim to the verifier...
- The proof (data sent from prover to verifier) will consist of $O(1)$ group elements.
  This includes a KZG commitment to the vector of sought values $f_i$.
- Given the index $t_j$, both prover and verifier
  will run a "setup" algorithm with $O(N log N)$ runtime.
- Once the setup algorithm has been run, each lookup proof
  will require a three-round interactive protocol.
- The verifier work will be $O(1)$ calculations.
- Given the sought values $f_i$ and the output of the setup algorithm,
  the prover will require $O(n)$ time to generate a proof.

Let's start with a brief outline of the protocol,
and then we'll flesh it out.

- We're assuming both prover and verifier know the "index" values $t_j$.
  So they can both compute the KZG commitment to these values,
  and we'll assume this has been done once and for all
  before the protocol starts.
- The prover sends $Com(F)$ and $Com(M)$, KZG commitments to
  the polynomials $F$ and $M$ such that $F(omega^i) = f_i$ for each $i = 1, dots, n$
  and $M(zeta^j) = m_j$ for each $j = 1, dots, N$.
  (Here $omega$ is an $n$th root of unity, and $zeta$ an $N$th root of unity.)
- The verifier sends a random challenge $beta$,
  which will substitute for $X$ in the equality of rational functions
  (@cq-identity).
- The verifier chooses a random challenge $beta$.
- The prover sends two more KZG commitments:
  a commitment $Com(L)$ to the polynomial $L$ such that
  $
    L(omega^i) = 1/(beta - f_i),
  $
  and another $Com(R)$ to the polynomial $R$ such that
  $
    R(zeta^j) = m_j/(beta - t_j).
  $
- The prover sends the value
  $
  s = sum_(i=1)^n (1)/(X - f_i) = sum_(j=1)^N (m_j)/(X - t_j).
  $
- Now the prover has to prove the following:
  - The polynomials $L$ and $R$ are well-formed.
    That is,
    $
    L(omega^i) (beta - F(omega^i)) = 1
    $
    for all $i = 1, dots, n$, and
    $
    R(zeta^j) (beta - T(zeta^j)) = M(zeta^j)
    $
    for all $j = 1, dots, N$.
  - The value $s$ is equal to both the sum of the $l_i$'s
    and the sum of the $r_j$'s.

The first claim is proven by a standard polynomial division trick:
Asking that two polynomials agree on all powers of $omega$
is the same as asking that they are congruent modulo $Z_n(X) = X^n-1$.
So the prover simply produces a KZG commitment to the quotient polynomial $Q_L$
satisfying
$
    L(x) (beta - F(x)) = 1 + Q_L (X) Z_n (X).
$
And similarly for the claim involving $R$:
the prover produces a KZG commitment to the polynomial $Q_R$ such that
$
    R(X) (beta - T(X)) = M(X) + Q_R (X) Z_N (X).
$

#remark[
The verifier can check the claim that
$L(x) (beta - F(x)) = 1 + Q_L(X) Z_n(X)$,
and others like it, using the pairing trick.

(This is an example of the method explained in @pair-verify-example.)

The verifier already has access to KZG commitments
$Com(L)$, $Com(F)$, $Com(Q_L)$, and $Com(Z_n)$,
either because he can compute them himself ($Com(Z_n)$),
or because the prover sent them as part of the protocol
($Com(L), Com(F), Com(Q_L)$).
Additionally, the prover will need to send the intermediate value
$Com(Q_L Z_n)$, a KZG commitment to the product.

The verifier then checks the pairings
$
pair(Com(Q_L Z_n), [1]) = pair(Com(Q_L), Com(Z_n))
$
(which verifies that the commitment $Com(Q_L Z_n)$ to the product polynomial
was computed honestly)
and
$
pair(Com(L), [beta] - Com(F)) = pair([1] + Com(Q_L Z_n), [1])
$
(which verifies the claimed equality).

The process of verifying this sort of identity is quite general:
The prover sends intermediate values as needed
so that the verifier can verify the claim using only pairings and linearity.
] <cq-pairing-verify>

The second claim is most easily verified by means of the following trick.
If $L$ is a polynomial of degree less than $n$,
then
$
sum_(i=0)^n L(omega^i) = n L(0).
$
So the prover simply has to open the KZG commitment $Com(L)$ at $0$,
showing that $n L(0) = s$
(and similarly for $R$).

=== Cached quotients: improving the prover complexity

The protocol above works, and it does everything we want it to,
except it's not clear how quickly the prover can generate the proof.
To recall what we want:
- We're assuming $n << N$.
- Prover and verifier can both do a one-time $O(N)$ setup,
  depending on the lookup table $T$ but not on the sought values $F$.
- After the one-time setup, the prover runtime (given the sought values $F$)
  should be only $O(n log n)$.

The polynomial $L$ has degree less than $n$ --
it is defined by Lagrange interpolation from its values at the $n$th roots of unity.
So $L$ can be computed quickly by a fast Fourier transform,
and none of the identities involving $L$
will give the prover any trouble.

But $R$ is a bigger problem: it has degree $N$.
So any calculation involving the coefficients of $R$ -- or of $M$, or the quotient $Q_R$ --
is a no-go.

So what saves us?
- The prover only ever needs to compute KZG commitments, not actual polynomials --
  and KZG commitments are linear.
- $M$, $R$ and $Q_R$ can be written as sums of only $n$ terms
  (which can be precomputed once and for all).

Let's take $R$ for example.
$R$ is the polynomial determined by
Lagrange interpolation and the condition
$
    R(zeta^j) (beta - T(zeta^j)) = M(zeta^j)
$
Let $R_j$ be the polynomial
(a multiple of a Lagrange basis polynomial)
such that
$
    R_j(zeta^j) = 1 / (beta - t_j)
$
but
$
    R_j(zeta^k) = 0
$
for $k eq.not j$.
Then
$
    R = sum_j m_j R_j,
$
and the sum has at most $n$ nonzero terms,
one for each item on the sought list $t_i$.
So the prover simply computes each commitment $Com(R_j)$
in advance, and then given $t_i$, computes
$
    Com(R) = sum_j m_j Com(R_j).
$

A similar trick works for $Q_R$,
which is the origin of the name "cached quotients."
Recall that $Q_R$ is defined by
$
    R(X) (beta - T(X)) = M(X) + Q_R (X) Z_N (X).
$
In other words, $Q_R$ is the result of "division with remainder":
$
    R(X) (beta - T(X)) / Z_N (X) = Q_R (X) + M(X) / Z_N (X).
$
So the prover simply precomputes quotients $Q_(R_j)$ and remainders $M_j$ such that
$
    R_j (X) (beta - T(X)) / Z_N (X) = Q_(R_j) (X) + M_j (X) / Z_N (X),
$
and then computes $Q_R$ and $M$ as linear combinations of them.

So, in summary:
The prover precomputes KZG commitments to $R_j$, $Q_(R_j)$, and $M_j$.
Then prover and verifier run the protocol described above,
and all the prover messages can be computed in $O(n log n)$ time,
using linear combinations of the cached precomputes.
