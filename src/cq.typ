#import "preamble.typ":*

= Lookups and cq <cq>

This is a summary of cq, 
a recent paper that tells how to do "lookup arguments"
in a succint (or ZK) setting.

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
]

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
]

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

