# Pedersen Commitments, Inner Product Arguments, and Proving Systems

Or "some things you can do with Pedersen commitments."

The goal of this post is to answer the question: How would you develop a proving system from the ground up?  We start with a commitment scheme called Pedersen commitments, and a simple protocol called the inner product argument that works on Pedersen-committed vectors.  Our goal is to build these up into a full proof system.

Of course this is nothing new!  There's a proof system called Bulletproofs that does exactly the same thing.  So you can view these notes as "how would you rediscover Bulletproofs."

[Dankrad's notes on Pedersen commitments and the inner product argument](https://dankradfeist.de/ethereum/2021/07/27/inner-product-arguments.html)

[Original paper on Bulletproofs](https://eprint.iacr.org/2017/1066.pdf)


## Pedersen commitments

To start with, let's recall how Pedersen commitments work.  Suppose you have a group $G$ -- concretely, let's say $G$ is an elliptic curve over some large finite field.  Fix once and for all a bunch of "random" elements of $G$, say $g_1, g_2, \ldots, g_N$. Now suppose you want to commit to a vector $\mathbf{a} = (a_1, \ldots, a_n)$, for some $n \leq N$.  Your commitment is simply the group element $$\operatorname{Com}(\mathbf{a}) = a_1 g_1 + a_2 g_2 + \cdots + a_n g_n.$$ To open your commitment, you simply reveal the full vector $(a_1, \ldots, a_n)$, and the other party can verify that the commitment matches the vector.

Why does this work?  You want a commitment scheme to have two properties: hiding and binding.  Hiding means that it's hard to recover $\mathbf{a}$ from the commitment $\operatorname{Com}(\mathbf{a})$.  Binding means that the committer is committed to $\mathbf{a}$: it's hard to find two vectors $\mathbf{a}$ and $\mathbf{a}'$ such that $\operatorname{Com}(\mathbf{a}) = \operatorname{Com}(\mathbf{a}')$.  We'll see that our scheme is binding but not hiding.

Let's assume that the discrete logarithm problem is hard in $G$.  For us, this means it's hard to find $x_1, \ldots, x_n$ such that $x_1 g_1 + \cdots + x_n g_n = 0$.  (This is widely believed to be true if $G$ is a large elliptic curve, for example.) This means it's hard to find $\mathbf{x}$ such that $\operatorname{Com}(\mathbf{x}) = 0$.  But if $\operatorname{Com}(\mathbf{a}') = \operatorname{Com}(\mathbf{a})$, then $\operatorname{Com}(\mathbf{a}' - \mathbf{a}) = 0$, so we have proved that Pedersen commitments are binding.

On the other hand, Pedersen commitments as we've presented them don't hide the committed vector.  For example, imagine you commit to a vector and send the commitment to someone -- but the other person knows that your vector has to be one of a short list of vectors.  They can simply test those vectors one by one, computing $\operatorname{Com}(\mathbf{a})$ for each of them, until they find a commitment that matches.

One solution to this is to introduce a "blinding term" $a_{n+1} g_{n+1}$, where $a_{n+1}$ is chosen at random.  Instead of $\operatorname{Com}((a_1, \ldots, a_n))$, you send $\operatorname{Com}((a_1, \ldots, a_n, a_{n+1}))$ -- and to open the commitment, you reveal all of $a_1, \ldots, a_{n+1}$.

The blinding term makes the "guess the committed vector" attack impossible.  In fact, since $a_{n+1}$ is chosen uniformly at random, the commitment will be statistically equally likely to be any element of $G$.  So you have a strong statistical guarantee that the the commitment leaks no information at all about the original vector $(a_1, \ldots, a_n)$.

## Basic games with Pedersen commitments

I'm not going to explain inner product arguments -- they are explained well in Dankrad's notes.  Instead, I want to explain some simpler protocols.  We will need these to get any proof system off the ground.

1. Suppose I (the "prover") have a Pedersen commitment of the form $k = a_1 g_1$.  I want to prove $k$ is of this form, without telling the "verifier" $a_1$.  How?

The prover chooses at random a second value $a_1'$, and tells the verifier both $k$ and $k' = a_1' g_1$. 

The verifier sends back a challenge $\lambda$.

The prover sends $(a_1 + \lambda a_1')$, and the verifier checks that $(a_1 + \lambda a_1') g_1 = k + \lambda k'$.

To rephrase: The prover wants to prove a claim "I know a discrete logarithm for $k$".  The prover introduces $k'$, and offers to prove that "I know discrete logarithms for both $k$ and $k'$."  This sort of claim can be proven by the "random linear combination" trick: it is enough to show that the prover knows a discrete logarithm for a random linear combination $k + \lambda k'$, where $\lambda$ is some random value chosen after the prover has committed to $k$ and $k'$.  And because of this trick, the prover never reveals the discrete logarithm of $k$.

2. Suppose I have a Pedersen commitment to a vector $\mathbf{a}$ of length $n$: $k = a_1 g_1 + \cdots + a_n g_n$.  How do I prove it?

Same trick.  Choose a random second vector $\mathbf{a}' = (a_1', \ldots, a_n')$, and send the commitment $k' = a_1' g_1 + \ldots + a_n' g_n$.  Then the prover sends a random challenge $\lambda$, and the verifier reveals the vector $\mathbf{a} + \lambda \mathbf{b}$.

3. I have two different Pedersen commitments to the same vector $\mathbf{a}$: $k = a_1 g_1 + \cdots + a_n g_n$ and $k' = a_1 g_1' + \cdots + a_n g_n'$.  I want to prove they are Pedersen commitments to the same vector, without revealing anything about the vector.  (The group elements $g_1, \ldots, g_n$ and $g_1', \ldots, g_n'$ are publicly known.)

The verifier sends a random challenge $\lambda$, and the prover uses the above protocol to prove that $k + \lambda k'$ is a known linear combination of $g_1 + \lambda g_1', \ldots, g_n + \lambda g_n'$.

We will apply this in a situation where $g_1', \ldots, g_n'$ are not necessarily linearly independent -- there may be easily computed linear relations among them.  However, $g_1, \ldots, g_n$ will satisfy the "discrete log is hard" hypothesis.  It follows that for almost all $\lambda$, the vectors $g_1 + \lambda g_1', \ldots, g_n + \lambda g_n'$ also satisfy the "discrete log is hard" hypothesis, so the protocol above works as usual.

## On to a proof system

We will make a proof system for R1CS.  In other words, we want to prove we have a satisfying witness $\mathbf{x}$ for a system of equations $$A \mathbf{x} \circ B \mathbf{x} = C \mathbf{x}.$$  Here $\mathbf{x} = (x_1, \ldots, x_n)$ is a vector of length $n$, each of $A, B, C$ is an $n$-by-$n$ matrix, and $\circ$ represents the Hadamard (elementwise) product of two vectors.

The proof will go as follows.  The prover will give Pedersen commitments $k = \operatorname{Com}(\mathbf{x})$, $k_A = \operatorname{Com}(A\mathbf{x})$, $k_B = \operatorname{Com}(B\mathbf{x})$, and $k_C = \operatorname{Com}(C\mathbf{x})$.  Then the prover has to prove the following claims:
-- The linear transformations $A$, $B$, $C$ were applied honestly.  In other words, the pair $(k, k_A)$ is of the form $(\operatorname{Com}(\mathbf{x})), \operatorname{Com}(A\mathbf{x}))$ for some $x$ -- and similarly for $(k, k_B)$ and $(k, k_C)$.
-- The Hadamard relation is satisfied.  In other words, $A \mathbf{x} \circ B \mathbf{x} = C \mathbf{x}$.

### Verification of the linear transformation.

How to prove that a pair of commitments is of the form $(\operatorname{Com}(\mathbf{x})), \operatorname{Com}(A\mathbf{x}))$?  (Here $A$ is publicly known.)

This is actually equivalent to the problem in (3) above.  For example, suppose $A$ is the linear transformation $A(x_1, x_2) = (x_1 + 2 x_2, x_1 - x_2)$.  The prover wants to prove that the two committed vectors are $$k = x_1 g_1 + x_2 g_2$$ and $$k_A = (x_1 + 2x_2) g_1 + (x_1 - x_2) g_2.$$
Now $k_A$ can be rewritten as
$$k_A = x_1 (g_1 + g_2) + x_2 (2g_1 - g_2).$$

In other words, what we need to prove is that $k$ and $k_A$ are commitments of the same vector, $k$ with respect to the basis $(g_1, g_2)$, and $k_A$ with respect to $(g_1 + g_2, 2 g_1 - g_2)$.  But this is exactly what item (3) gives.

### Verification of the Hadamard product

Given Pedersen commitments to three vectors $\mathbf{a}, \mathbf{b}, \mathbf{c}$, we want to prove that $\mathbf{c} = \mathbf{a} \circ \mathbf{b}$.  In other words, we want to prove $c_i = a_i b_i$ for each $i$.

Here's a silly solution: That's a special case of the inner-product argument, for vectors of length one!  After all, the product $a_1 b_1$ is just the inner product of the length-one vectors $(a_1)$ and $(b_1)$.  So we simply apply the inner product argument to each of the entries of $\mathbf{c}$ separately.

### A zero knowledge (inner) product argument

How can we prove $ab = c$ without revealing $a$, $b$, or $c$?  (More generally, we might want to make a zero-knowledge version of the inner product argument.  Since we only need the case of length-one vectors, I'll focus on those.)

Suppose a prover has a commitment to a vector of the form $$v = ag + bh + abk.$$  She wants to prove that the committed vector indeed has this form, without revealing $a$ or $b$.  (As usual, $g, h, k$ are publicly known.)

We will do this by a variant of the random linear combination trick we already saw above.

The prover chooses some random blinding term $a'$, and sends the commitment
$$v' = a' g + b h + a' b k.$$
The verifier responds with a random challenge $\lambda$.  Now prover and verifier can compute the linear combination 
$$w = v + \lambda v' = (a + \lambda a')g + (1 + \lambda) b h + (a + \lambda a') b k.$$
Now $a$ has been blinded away, and we repeat the process with $b$.

So the prover chooses another blinding term $b'$ and sends
$$w' = (a + \lambda a')g + (1 + \lambda) b' h + (a + \lambda a') b' k.$$
The verifier chooses another random challenge $\mu$ and both prover and verifier compute
$$w + \mu w' = (a + \lambda a') (1 + \mu) g + (1 + \lambda) (b + \mu b') h + (a + \lambda a') (b + \lambda b') k.$$

A bit of algebra: If we write
$$w + \mu w' = Ag + Bh + Ck,$$
we expect $A$, $B$, $C$ to satisfy the compatibility condition
$$AB = (1 + \lambda)(1 + \mu) C.$$
Notice that $\lambda$ and $\mu$ are both publicly known, so this condition is easy to verify.

Now it's clear how to finish the protocol: the prover simply reveals the coefficients $(a + \lambda a')(1 + \mu)$ and $(1 + \lambda)(b + \mu b')$, which proves that $w + \mu w'$ has the required form.  The verifier can't determine anything about $a$ or $b$, because they have been blinded by combination with the randomly-chosen values $a'$ and $b'$.

## Complexity of the protocol

Our protocol, like IPA and bulletproofs, requires linear verifier work.

For the protocol above, we prove the Hadamard product constraint by proving $a_i b_i = c_i$ separately for each value of $i$; the total number of times this procedure has to be run is the number of constraints in the R1CS system.

The IPA protocol in [Dankrad's post](https://dankradfeist.de/ethereum/2021/07/27/inner-product-arguments.html#fn:2) might appear at first glance to only require logarithmic time -- it runs on a divide-and-conquer approach that reduces a claim about vectors of length $n$ to a claim about vectors of length $2$.  But in fact the required verifier work remains linear in $n$: as part of the reduction, the verifier has to compute linear combinations of the group elements $g_1, g_2, \ldots, g_n$.

Some vague thoughts on why this linear work is needed: A dishonest prover could cheat by "using the wrong vector for some $g_i$" -- the only way the verifier can catch such a cheater is if the final output of the verifier's computation depends on each of the elements $g_i$.

Dankrad's post suggests a couple of workarounds, specifically [multiopenings](https://dankradfeist.de/ethereum/2021/06/18/pcs-multiproofs.html) and [Halo proofs](https://eprint.iacr.org/2019/1021.pdf).  I wonder if it's also possible to work around this using some combination of precomputation and [error-correcting codes](https://ocw.mit.edu/courses/18-408-topics-in-theoretical-computer-science-probabilistically-checkable-proofs-fall-2022/pages/lecture-notes/) (see lectures 2-3 and 4-6)...
