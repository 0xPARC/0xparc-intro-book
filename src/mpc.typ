#import "preamble.typ":*

= Oblivious transfer and multi-party computations

== Pitch: TODO

TODO

== How to do oblivious transfer

Suppose Alice has $n$ keys, corresponding to elements $g_1, ..., g_n in E$.
Alice wants to send exactly one to Bob,
and Bob can pick which one, but doesn't want Alice to know which one he picked.
Here's how you do it:

1. Alice picks a secret scalar $a in FF_q$ and sends $a dot g_1$, ..., $a dot g_n$.
2. Bob picks the index $i$ corresponding to the key he wants and
  reads the value of $a dot g_i$, throwing away the other $n-1$ values.
3. Bob picks a secret scalar $b in FF_q$ and sends $b dot a dot g_i$ back.
4. Alice sends $1/a dot (b dot a dot g_i) = b dot g_i$ back to Bob.
5. Bob computes $1/b dot (b dot g_i) = g_i$.

== How to do 2-party AND computation

Suppose Alice and Bob have bits $a, b in {0,1}$.
They'd like to compute $a and b$ in such a way that if someone's bit was $0$,
they don't learn anything about the other person's bit.
(Of course, if $a=1$, then once Alice knows $a and b$ then Alice knows $b$ too,
and this is inevitable.)

This is actually surprisingly easy.
Alice knows there are only two cases for Bob,
so she puts the value of $a and 0$ into one envelope labeled "For Bob if $b=0$",
and the value of $a and 1$ into another envelope labeled "For Bob if $b=1$".
Then she uses oblivious transfer to send one of them.
Then Bob opens the envelope corresponding to the desired output.
Repeat in the other direction.

#remark[
  Stupid use case I made up: Alice and Bob want to determine whether
  they have a mutual crush on each other.
  (Specifically, let $a=1$ if Alice likes Bob and $0$ otherwise; define $b$ similarly.)
  Now we have a secure way to compute $a and b$.
]

== Chaining circuits

Suppose now that instead of a single bit,
Alice and Bob each have $1000$ bits.
They'd like to run a 2PC for function $f : {0,1}^2000 -> {0,1}$ together.

The above protocol would work, but it would be really inefficient:
it involves sending $2^1000$ envelopes each way.

However, in many real-life situations involving bits,
the function $f$ is actually given
by a _circuit_ with several AND, XOR, NOT gates or similar.
So we'll try to improve the $2^1000$ down to something that grows only linearly in
the number of gates in the circuit, rather than exponential in the input size.

Let $xor$ be binary XOR.

The idea is the following.
A normal circuit has a bunch of registers,
where the $i$th register just has a single bit $x_i$.
We'd like to instead end up in a situation where we get a pair of bits
$(a_i, b_i)$ such that $x_i = a_i xor b_i$,
where Alice can see $a_i$ but not $b_i$ and vice-versa.
This would let us do a 2PC for an arbitrarily complicated circuit.

It suffices to implement a single gate.
#lemma[
  Suppose $diamond : {0,1}^2 -> {0,1}$ is some fixed Boolean operator.
  Alice has two secret bits $a_1$ and $a_2$,
  while Bob has two secret bits $b_1$ and $b_2$.
  Then Alice and Bob can do use oblivious transfer to get $a_3$ and $b_3$ such that
  $a_3 xor b_3 = (a_1 xor b_1) diamond (a_2 xor b_2)$
  without revealing $a_3$ or $b_3$ to each other.
]
#proof[
  Alice picks $a_3 in {0,1}$ at random and prepares four envelopes
  for the four cases of $(b_1, b_2)$ describing what Bob should set $b_3$ as.
]
