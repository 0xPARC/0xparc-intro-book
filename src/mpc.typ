#import "preamble.typ":*

= Garbled circuits

Imagine Alice and Bob each have some secret values
$a$ and $b$, and would like to jointly compute some function $f$ over
their respective inputs. Furthermore, they’d like to keep their secret
values hidden from each other: if Alice and Bob follow the protocol
honestly, they should both end up learning the correct value of
$f (a , b)$, but Alice shouldn’t learn anything about $b$ (other than
what could be learned by knowing both $a$ and $f (a , b)$), and likewise
for Bob.

Yao’s garbled circuits is one of the most well-known 2PC protocols.
The protocol is quite clever, and optimized variants of the protocol are
being
#cite("https://github.com/privacy-scaling-explorations/mpz/tree/dev/crates/mpz-garble")[implemented and used today];.

== The problem
<the-problem>
Here is our problem setting, slightly more formally:

- Alice knows a secret bitstring $a$ of length $m$ bits.
- Bob knows a secret bitstring $b$ of length $n$ bits.
- $f$ is a binary circuit, which takes in $m + n$ bits, and runs them
  through some $k$ gates. The outputs of some of the gates are the
  public outputs of the circuit. Without loss of generality, let’s also
  suppose that each gate in $f$ accepts either $1$ or $2$ input bits,
  and outputs a single output bit.
- Alice and Bob would like to jointly compute $f (a , b)$ without
  revealing their secrets to each other.

== Outline of solution

Our solution will contain two key components:
- Alice constructs a _garbled circuit_
  that takes in the value $b$ (whatever it is)
  and spits out $f(a, b)$.
  A _garbled circuit_, roughly speaking,
  is an "encrypted" circuit that takes encrypted input and creates encrypted output.
- An _oblivious transfer_ is a protocol where Alice has two messages,
  $m_0$ and $m_1$.
  Bob can get exactly one of them, $m_i$,
  without letting Alice know what $i$ is.
  In this context, Alice ends up sending Bob a password
  for his input in a way that
  Bob doesn't learn the passwords for any other inputs,
  and Alice doesn't find out which password she sent to Bob.

In slightly more detail:

1. Whatever the function $f$ is, we'll assume that it takes $m+n$ bits of input
   $a_1, dots, a_m$ and $b_1, dots, b_n$,
   and that it's computed by some sort of circuit
   made of AND, OR and NOT gates.
2. Alice's first task is to "plug her own inputs into this circuit $f$."
   The result will be a new circuit
   (you might call it $f_a$)
   that has just $n$ input slots
   for Bob's $n$ bits $b_1, dots, b_n$.
3. Now, Alice is going to "garble" the circuit $f_a$.
   Once it's garbled, Bob won't be able to see how it works.
   He'll only be able to plug his own input $(b_1, dots, b_n)$
   into the circuit.
4. To prevent Bob from plugging other inputs in as well,
   a garbled circuit will require a "password"
   for each input Bob wants to plug in --
   a different password for every possible input.
   If Bob has the password for $(b_1, dots, b_n)$,
   he can learn $f_a (b_1, dots, b_n) = f(a, b)$,
   but he won't learn anything else about how the circuit works.
5. Now, Alice has all the passwords for all the possible inputs, but how can she give Bob the password for $(b_1, dots, b_n)$?
   Alice doesn't want to let Bob have any other passwords --
   and Bob isn't willing to tell Alice which password he is asking for.
   This is where we will use the "oblivious transfer."

We now flesh out this outline, starting with garbled circuits.

== Garbled gates

Our garbled circuits are going to be built out of _garbled gates_.
A garbled gate is like a traditional gate (like AND, OR, NAND, NOR),
except its functionality is hidden.

What does that mean? Let's say the gate has two input bits,
so there are four possible inputs to the gate:
$(0, 0), (0, 1), (1, 0), (1, 1)$.
For each of those four inputs $(x, y)$,
there is a secret password $P_(x, y)$.
The gate $G$ will only reveal its value $G(x, y)$
if you give it the password $P_(x, y)$.

Here is a natural approach to make a garbled gate.
Choose a _symmetric-key_#footnote[Symmetric-key encryption is probably
what you think of
when you think of plain-vanilla encryption:
You use a secret key $K$ to encrypt a message $m$,
and then you (or someone else) need the same secret key $K$ to decrypt it.]
encryption scheme
$Enc$ and publish the following table:

#table(
  columns: 2,
  inset: (x: 5pt, y: 8pt),
  [$(0, 0)$], [$Enc_(P_(0, 0))(G(0, 0))$],
  [$(0, 1)$], [$Enc_(P_(0, 1))(G(0, 1))$],
  [$(1, 0)$], [$Enc_(P_(1, 0))(G(1, 0))$],
  [$(1, 1)$], [$Enc_(P_(1, 1))(G(1, 1))$],
)

If you have the values $x$ and $y$,
and you know the password $P_(x, y)$,
you just go to the $(x, y)$ row of the table,
look up
$
  Enc_(P_(x, y))(G(x, y)),
$
decrypt it, and learn $G(x, y)$.

But if you don't know the password $P_(x, y)$,
assuming $Enc$ is a suitably secure encryption scheme,
you won't learn anything about the value $G_(x, y)$
from its encryption.

== Chaining garbled gates

The next step to combine a bunch of garbled gates into a circuit.
We'll need to make two changes to the protocol.

1. To chain garbled gates together,
  we need to modify the output of each gate:
  In addition to outputting the bit $z = G_i (x, y)$,
  the $i$-th gate $G_i$
  will also output a password $P_z$ that Bob can use at the next step.

  Now Bob has one bit coming in for the left-hand input $x$,
  and it came with some password $P_x^(text("left"))$ --
  and then another bit coming in for $y$,
  with some password $P_y^(text("right"))$.
  To get the combined password $P_(x, y)$,
  Bob concatenates the two passwords $P_x^(text("left"))$ and $P_y^(text("right"))$.

2. To keep the functionality of the circuit hidden,
  we don't want Bob to learn anything about the structure of
  the individual gates --
  even the single bit he gets as output.

  This is an easy fix:
  Instead of having the gate output
  both the bit $z$ and the password $P_z$,
  we'll have the gate just output $P_z$.

  But now how does Bob know what values to feed into the next gate?
  The left-hand column of the "gate table"
  needs to be indexed by the passwords
  $P_x^(text("left"))$ and $P_y^(text("right"))$,
  not by the bits $(x, y)$.
  But we don't want Bob to learn the other passwords from the table!

  Let's say this again.  We want:
  - If Bob knows both passwords $P_x^(text("left"))$ and $P_y^(text("right"))$,
    Bob can find the row of the table for the input $(x, y)$.
  - If Bob doesn't know the passwords, he can't learn them by looking at the table.

  Of course, the solution is to use a hash function!
  So here is the new version of our garbled gate.
  For simplicity, we'll assume it's an AND gate --
  so the outputs will be (the passwords encoding) 0, 0, 0, 1.
  #table(
    columns: 2,
    inset: (x: 5pt, y: 8pt),
    [$hash(P_0^(text("left")), P_0^(text("right")))$], [$Enc_(P_0^(text("left")), P_0^(text("right"))) (P_0^(text("out")))$],
    [$hash(P_0^(text("left")), P_1^(text("right")))$], [$Enc_(P_0^(text("left")), P_1^(text("right"))) (P_0^(text("out")))$],
    [$hash(P_1^(text("left")), P_0^(text("right")))$], [$Enc_(P_1^(text("left")), P_0^(text("right"))) (P_0^(text("out")))$],
    [$hash(P_1^(text("left")), P_1^(text("right")))$], [$Enc_(P_1^(text("left")), P_1^(text("right"))) (P_1^(text("out")))$],
  )

== How Bob uses one gate

Let's play through one round of Bob's gate-using protocol.

1. Suppose Bob's input bits are 0 (on the left) and 1 (on the right).
  Bob doesn't know he has 0 and 1 (but we do!).
  Bob knows his left password is some value
  $P_0^(text("left"))$,
  and his right password is some other value
  $P_1^(text("right"))$.

2. Bob takes the two passwords, concatenates them, and computes a hash.
  Now Bob has
  $
    hash(P_0^(text("left")), P_1^(text("right"))).
  $

3. Bob finds the row of the table indexed by
  $hash(P_0^(text("left")), P_1^(text("right")))$,
  and he uses it to look up
  $
    Enc_(P_0^(text("left")), P_1^(text("right"))) (P_0^(text("out"))).
  $

4. Bob uses the concatenation of the two passwords
  $P_0^(text("left")), P_1^(text("right"))$
  to decrypt
  $P_0^(text("out")).$

5. Now Bob has the password for the bit 0 to feed into the next gate --
  but he doesn't know his bit is 0.

So Bob is exactly where he started:
he knows the password for his bit, but he doesn't know his bit.
So we can chain together as many of these garbled gates as we like
to make a full garbled circuit.

== How the circuit ends

At the end of the computation,
Bob needs to learn the final result.
How?

Easy!
The final output gates are different from the intermediate gates.
Instead of outputting a password,
they will just output the resulting bit in plain text.

== How the circuit starts

This is trickier.
At the beginning of the computation,
Bob needs to learn the passwords for all of his input bits. Let's just frame the problem for a single bit.
- Alice has two passwords, $P_0$ and $P_1$.
- Bob has a bit $b$, either $0$ or $1$.
- Bob wants to learn one of the passwords, $P_b$, from Alice.
- Bob does not want Alice to learn the value of $b$.
- Alice does not want Bob to learn the other password.

This is where _oblivious transfer_ comes in, which we'll see in @ot.
