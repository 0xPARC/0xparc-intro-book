---
title: "Motivating Garbled Circuits"
permalink: "/motivating-garbled-circuits"
date: April 17, 2024
postType: 0
---

# Motivating Garbled Circuits

Cryptographic protocols can sometimes feel a bit like magic. If you're like us, you've probably had the experience where you can verify that a protocol is probably complete (and if you're lucky, you might even be convinced that it's sound), but you might have no idea as to _why_ the protocol works the way it does, or how one might even have arrived at the construction in the first place. So attempting to rederive a protocol is often helpful for understanding the key ideas or "cruxes."

In this post, we'll explain how one might rederive Yao's Garbled Circuits protocol from scratch, from an intuitive perspective. Garbled Circuits are a neat primitive for general-purpose 2-party computation, but the construction may seem a bit "magical"--how would you come up with the idea of garbling, in a world where it doesn't exist?

Garbled Circuits are a solution to the general problem of 2-party computation, or 2PC. In 2PC, Alice and Bob each have some secret values $a$ and $b$, and would like to jointly compute some function $f$ over their respective inputs. Furthermore, they'd like to keep their secret values hidden from each other: if Alice and Bob follow the protocol honestly, they should both end up learning the correct value of $f(a,b)$, but Alice shouldn't learn anything about $b$ (other than what could be learned by knowing both $a$ and $f(a,b)$), and likewise for Bob.

Yao's Garbled Circuits is one of the most well-known 2PC protocols (Vitalik has a great explanation [here](https://vitalik.eth.limo/general/2020/03/21/garbled.html)). The protocol is quite clever, and optimized variants of the protocol are being [implemented and used today](https://github.com/privacy-scaling-explorations/mpz/tree/dev/garble).

We don't know exactly what led Yao to the idea of garbling, but we'll describe one plausible path for someone today to independently rediscover garbling, assuming the existence of an earlier primitive called "Oblivious Transfer."

## The Problem

Here is our problem setting, slightly more formally:

- $A$ knows a secret bitstring $a$ of length $s$ bits
- $B$ knows a secret bitstring $b$ of length $t$ bits
- $C$ is a binary circuit, which takes in $s + t$ bits, and runs them through some $n$ gates. The outputs of some of the gates are the public outputs of the circuit. Without loss of generality, let's also suppose that each gate in $C$ accepts either $1$ or $2$ input bits, and outputs a single output bit.
- $A$ and $B$ would like to jointly compute $C(a, b)$ without revealing to each other their secrets.

## Precursor: Oblivious Transfer

If you're aware of Oblivious Transfer (OT), an earlier cryptoraphic primitive, it's plausibly one of the first things you might try to use if you're approaching the general problem of 2PC.

As a quick primer: Oblivious Transfer protocols also involve two parties, Alice and Bob. Alice has a tuple of some records, $(x_1, x_2, ..., x_n)$ (imagine that each of these values is some 32-bit integer). Bob would like to query for the value $x_i$, for some specific index $i$, without letting Alice know which $i$ he is asking for. Alice would like for Bob to only learn the single value of $x_i$, without learning anything about $x_j$ for $j \neq i$.

This might seem almost paradoxical at first glance. However, with a bit of cleverness, you can design a protocol such that Alice and Bob can carry this procedure out by transmitting $cn$ bits between each other, where $c$ is in the hundreds. Today, protocols where Alice and Bob communicate sublinear information in $n$ exist as well!

- If you're curious, we break down two simple Oblivious Transfer protocols in [another post](https://hackmd.io/4BcDxaUdS4yDkB9B0HzMow).

If you meditate on OT and 2PC for a bit, you might see how the "API" of Oblivious Transfer is nearly identical the "API" of 2PC. (We'll explain exactly what that correspondence looks like in the next section.)

## OTing a Huge Function Lookup Table is 2PC

In the previous section, we mentioned that OT and 2PC have the same "API." This comes from the observation that a function can be seen as a big lookup table, so reading from a lookup table is somehow equivalent to evaluating a function.

The most straightforward thing Alice can do is to simply construct a huge lookup table of all the possible values of $C(a,b)$, given her fixed value of $a$, and then allow Bob to query for the appropriate value of $C(a,b)$ for his $b$.

For a concrete example, suppose $t = \operatorname{len}(b) = 3$. Knowing $a$, Alice is able to calculate the following lookup table:

| $b_1, b_2, b_3$ | $C(a, b)$   |
| --------------- | ----------- |
| 000             | $C(a, 000)$ |
| 001             | $C(a, 001)$ |
| 010             | $C(a, 010)$ |
| 011             | $C(a, 011)$ |
| 100             | $C(a, 100)$ |
| 101             | $C(a, 101)$ |
| 110             | $C(a, 110)$ |
| 111             | $C(a, 111)$ |

Then she allows Bob to retrieve the value corresponding to $b$, using Oblivious Transfer. Bob learns the correct value of $C(a, b)$ and shares this with Alice.

While this protocol works, it's clearly not very efficient. It requires Alice to construct and perform OT with a lookup table of size $2^t$, which grows exponentially larger in the length of Bob's input. How can we improve this?

## Can we perform OT Gate-By-Gate?

$C$ has lots of structure: it can be broken down into a bunch of gates. A natural question to ask is whether we can somehow perform our OT-lookup idea gate-by-gate, instead of on the whole circuit. Since gates are small, our lookup tables would be much smaller.

Let's start with a single AND gate: $x_1 \wedge x_2 = x_3$, where Alice knows $x_1$, and Bob knows $x_2$. The output of this gate is some intermediate result $x_3$ will get fed into some other gates deeper in the circuit.

What happens when we try to blindly apply our lookup OT procedure in computing $x_3$? According to our procedure, Alice constructs a lookup table that specifies the result of $x_3$ for the possible values of $x_2$, and Bob will retrieve the value of $x_3$ corresponding to his value of $x_2$. Finally, Bob tells Alice the value $x_3$.

With this protocol, if Alice and Bob's bits are both $1$, they'll learn this. But if either of their bits is $0$, the person with a $0$ bit will learn nothing about the other person's bit.

Can we build a multi-gate 2PC protocol off of this directly? Well, we'll run into two problems:

- Bob (and Alice) learn the value of $x_3$ at the end of the procedure. But in a larger circuit, $x_3$ is an intermediate value, and we only want Bob and Alice to learn the final values--they shouldn't learn anything about the intermediate values of the circuit!
- As we mentioned, Bob might also learn something about Alice's value of $x_1$. For example, if $x_3$ is $1$ and $x_2$ is $1$, Bob knows that $x_1$ is $1$ as well.

So we can't blindly apply our lookup OT gate-by-gate, but with a bit of tweaking we can maybe still construct a modified lookup-OT-procedure that can be "chained," gate by gate.

## Computing a Gate on Secret Shares

We'd like for Alice and Bob to each learn some information that would allow them to _jointly_ compute the output of the gate, but we don't want either of them to actually be able to know learn the result on their own without consulting the other. A common tactic for this kind of setting is to have Alice and Bob try to compute "secret shares" of the result.

What this means is that Alice and Bob might try to design a procedure where Alice will end up with some $a_3$ and Bob will end up with some $b_3$ such that $a_3 \oplus b_3 = x_3$, where $x_3$ is the expected output of the gate. If Alice's $a_3$ is drawn from a random distribution, then neither Alice nor Bob have gained any information on $x_3$, but they've managed to "jointly compute" the gate.

Even if Alice and Bob can do this, there's still some trickiness: in future computations involving $x_3$, Alice and Bob will have to both bring their respective shares, and we'll have to figure out how to pass secret shares through gates.

But if we can figure out how to deal with that, a possible strategy emerges:

- Alice and Bob proceed through the computation of $C$ gate-by-gate. For each gate, they plug in the secret shares into the gate's inputs (which they've previously computed), and then produce secret shares of the gate's output. These output secret shares can be used in future gates.
  - To reiterate: by "secret shares", we mean - if the output of a gate is $x_i$, Alice should learn some $a_i$ and Bob should learn some $b_i$, such that $a_i \oplus b_i = x_i$.
  - All shares for intermediate values should be randomized, so that neither $A$ nor $B$ should learn anything about the intermediate bits or about each other's bits, though taken as a collective $A$ and $B$ are tracking the computation correctly as it progresses.
- At the end of the computation, $A$ and $B$ will reveal their secret shares of the output bits, and combine them together to retrieve the output.

It turns out that it's a pretty straightforward extension to modify our lookup-OT tactic to make it work for computing gates on secret shares. (We recommend trying to figure this out yourself before reading the next paragraph!)

Suppose that $G_i$ is gate with two inputs, and that $G_i$ computes $x_i = x_j \diamondsuit x_k$ for some operator $\diamondsuit$. Alice knows two bits $a_j, a_k$, and Bob knows two bits $b_j, b_k$, such that $a_j \oplus b_j = x_j$ and $a_k \oplus b_k = x_k$. Alice would like to end up computing some $a_i$ and Bob some $b_i$ such that $a_i \oplus b_i = x_i$ is indeed the correct result of the gate.

First, Alice flips a coin to choose a random bit for $a_i$. Then, she computes a lookup table that describes what $b_i$ should be, conditional on $b_j, b_k$, and given $A$'s fixed values of $a_i, a_j, a_k$:

| $b_j, b_k$ | $b_i$                                               |
| ---------- | --------------------------------------------------- |
| 00         | $b_i = (a_j \diamondsuit a_k) \oplus a_i$           |
| 01         | $b_i = (a_j \diamondsuit \neg a_k) \oplus a_i$      |
| 10         | $b_i = (\neg a_j \diamondsuit a_k) \oplus a_i$      |
| 11         | $b_i = (\neg a_j \diamondsuit \neg a_k) \oplus a_i$ |

How do we fill in the values in the $b_i$ column? Well, we know that $(a_j \oplus b_j) \diamondsuit (a_k \oplus b_k) = a_i \oplus b_i$; that's what it means to compute the gate $G_i$ over secret shares. Since Alice knows $a_j, a_k, a_i$, for each row she can substitute in values of $b_j, b_k$ suggested by the row label, and then solve for $b_i$.

To complete the computation, Alice and Bob can simply carry out an oblivious transfer. Bob knows his values $b_j$ and $b_k$, so he should be able to ask for the appropriate row of the table containing the correct value of $b_i$ without Alice learning which row he is asking for. The two of them have now jointly computed a gate, in a "chainable" way, without learning anything about the gate outputs!

## A full gate-by-gate protocol

Once we've built a gadget for computing secret-share-outputs of a gate from secret-share-inputs, we can chain these together into a complete protocol. For completeness, we've written down the full protocol below.

- First, topologically sort all of the gates $G_1, G_2, ..., G_n$. We'll denote the output of gate $G_i$ as $x_i$, and denote Alice and Bob's shares of $x_i$ as $a_i$ and $b_i$ respectively. Our goal is for Alice and Bob to jointly compute all of their $a_i$ and $b_i$ shares, going gate-by-gate.
  - We'll also handle the inputs as follows: first, for the purposes of this algorithm, we will consider the input bits to be gates as well. $A$'s input bits will be the first $s$ "gates", and $B$'s input bits will be the next $t$ "gates." For the first $s$ gates, $a_i = x_i$ and $b_i = 0$. For the next $t$ gates, $b_i = x_i$ and $a_i = 0$.
- Now, we go gate-by-gate, starting at gate $G_{s+t+1}$, and use a lookup-OT procedure to enable Alice to compute $a_i$ and Bob to compute $b_i$ as $i$ increments. There are two cases for any given gate:
  - If $G_i$ is a gate with a single input, then it's a NOT gate. In this case, $x_i = \neg x_j$ for some $j < i$. If $G_i$ is a gate of this form, $A$ sets $a_i = \neg a_j$ and $B$ sets $b_i = b_j$.
  - In the second case, Alice and Bob use the secret-share-gate OT protocol described above.

With this protocol, $A$ and $B$ can compute all values of $a_i$ and $b_i$. At the end they simply reveal and xor their desired output bits together!

Note that we can reduce the number of OTs with a few optimizations. For example, any time $\diamondsuit$ is a linear operator (such as xor), $A$ and $B$ can simply apply that linear operator to their respective shares. So we only need to perform OTs for the nonlinear gates.

## Yao's Garbled Circuits: Replacing Per-Gate OTs With Encryption

Though it might not seem like it on the surface, we've now arrived at something that is actually quite close to [Yao's garbled circuits protocol](https://vitalik.eth.limo/general/2020/03/21/garbled.html). In fact, Yao's protocol can be seen as the above protocol with some optimizations, that enable us to replace a bunch of OTs with "precomputation" from Alice.

OTs are expensive, and doing one OT per gate is still pretty inefficient (though it's certainly far better than an OT of size $2^s$!). Each OT also requires a round of interaction between Alice and Bob, meaning that this protocol involves many, many back-and-forths between Alice and Bob (not ideal).

A natural question to ask would be: is there a way that we can somehow "batch" all of the OTs, or else perform some kind of precomputation so that Alice and Bob can learn their secret shares at each gate non-interactively?

### Observation: Alice never actually interacts with Bob

This question becomes especially interesting in light of the following observation: in our previous protocol, it turns out that Alice's $a_i$ values are selected completely independently of anything Bob does. In other words, at the start of the protocol Alice could have simply decided to write down all of her $a_i$'s in advance.

In this view, Alice is essentially writing down a "scrambling" function for the circuit trace at the very start of the protocol. Concretely, the tuple $\{b_1, ..., b_n\}$ that Bob computes over the course of the protocol will end up being a scrambled version of the "true" trace $\{x_1, ..., x_n\}$, where the scrambling is decided by Alice at the beginning of the protocol.

What does it mean to see Alice's "scrambling" as a function, or set of functions? Well, Alice is essentially defining a scrambling map $g_i$ for each gate (including the input "gates"). For each gate $G_i$, the scrambling map $g_i$ takes $\{0, 1\}$ to some random shuffling of $\{0, 1\}$. Specifically:

- If $a_i = 0$, then $g_i(0) = 0$ and $g_i(1) = 1$
- If $a_i = 1$, then $g_i(0) = 1$ and $g_i(1) = 0$

So, to sum up this alternative view of our latest protocol: Alice writes down a bunch of scrambling functions $g_i$ at the start of the protocol, and then over the course of the protocol Bob gradually learns the scrambled version of the true circuit trace $x_i$. In particular, he's learning $b_i = g_i(x_i)$ for all $i$.

### Replacing OTs with Encryption

Currently, Bob learns his "scrambled" values through OT. If we want to find a way to remove the requirement of "one OT per gate," we need to figure out a way for Bob to learn the scrambled trace non-interactively.

This seems plausible. Alice shouldn't really need to interact with Bob at all, until the very end of the protocol. She wrote down the scrambling at the beginning of the protocol, and she's not supposed to learn anything about Bob's values or what he's doing anyway; so it seems like it might be possible for Alice to simply send Bob some information that allows him to figure out his $b_i$'s without too much more interaction with her.

Let's try to do this in the most direct way. For a gate $G_i$ that represents the intermediate calculation $x_i = x_j \diamondsuit x_k$, Alice might publish a table that looks something like the following for Bob:

| $b_j = g_j(x_j), b_k = g_k(x_k)$ | $b_i = g_i(x_i)$                                                    |
| -------------------------------- | ------------------------------------------------------------------- |
| 00                               | $\operatorname{Enc}_1((a_j \diamondsuit a_k) \oplus a_i$)           |
| 01                               | $\operatorname{Enc}_2((a_j \diamondsuit \neg a_k) \oplus a_i)$      |
| 10                               | $\operatorname{Enc}_3((\neg a_j \diamondsuit a_k) \oplus a_i)$      |
| 11                               | $\operatorname{Enc}_4((\neg a_j \diamondsuit \neg a_k) \oplus a_i)$ |

(This table is the same as the lookup table from above, just with the $b$'s written as outputs of scrambling functions, and with the values in the second column "locked" by encryption).

This table should be constructed so that Bob can only "unlock" the appropriate value of $g_i(x_i)$ for the row of $g_j(x_j), g_k(x_k)$ values that he actually possesses--this simulates the OT property that Bob can't learn the values of any other rows. For example, $\operatorname{Enc}_1$ should only be possible for Bob to decrypt if $g_j(x_j) = 0$ and $g_k(x_k) = 0$.

But it turns out that there's a very direct way to do this! We simply have our scrambling $g_j$ and $g_k$ _also_ output some symmetric encryption keys picked by Alice at the start of the protocol, in addition to the scrambled bit. The values in the second column should be encrypted with both of these keys, and the output of $g_i$ should also include a new symmetric encryption key as well that can be used to unlock later values.

For example, suppose that for some value $x_j$ we have $g_j(x_j) = (1, \mathsf{key}_{j1})$, and for some value of $x_k$ we have $g_k(x_k) = (0, \mathsf{key}_{k0})$. Then $\operatorname{Enc}_3$ is symmetric encryption with a key derived from $\mathsf{key}_{j1}$ and $\mathsf{key}_{k0}$ - for example, $\operatorname{Hash}(\mathsf{key}_{j1}, \mathsf{key}_{k0})$.

In other words, the output of our "scrambling" function $g_i$ should actually be a _tuple_ of two values: a scrambled bit, and a symmetric encryption key that can be used to decrypt values in lookup tables deeper in the circuit, where outputs of $g_i$ are involved:

$g_i(0) = (a_i, \mathsf{key}_{ia_i})$
$g_i(1) = (\neg a_i, \mathsf{key}_{i (\neg a_i)})$

Now, for each $i$, Bob learns both the scrambled bit of $g_i(x_i)$, as well as a symmetric encryption key that can be used to decrypt future outputs for which $x_i$ is an input. At the very end, Bob asks Alice to reveal the scrambling functions for the final circuit outputs, and then unscrambles his output bits.

It turns out that there are still a few more kinks to iron out, like handling inputs--for example, we'll find that our lazy default of setting $a_i = x_i, b_i = 0$ for Alice's inputs and $b_i = x_i, a_i = 0$ for Bob's inputs won't work anymore. But we've essentially arrived at what we now know today as Yao's Garbled Circuits protocol! In the Garbled Circuits protocol, our operation of "scrambling" is instead called "garbling."

**Final exercise for the reader**: Work out the remaining kinks to arrive at a complete Garbled Circuits protocol.