#import "preamble.typ":*

= Garbled Circuits and Two-party Computation

Imagine Alice and Bob each have some secret values
$a$ and $b$, and would like to jointly compute some function $f$ over
their respective inputs. Furthermore, they’d like to keep their secret
values hidden from each other: if Alice and Bob follow the protocol
honestly, they should both end up learning the correct value of
$f (a , b)$, but Alice shouldn’t learn anything about $b$ (other than
what could be learned by knowing both $a$ and $f (a , b)$), and likewise
for Bob.

Yao’s Garbled Circuits is one of the most well-known 2PC protocols
(Vitalik has a great explanation
#link("https://vitalik.eth.limo/general/2020/03/21/garbled.html")[here];).
The protocol is quite clever, and optimized variants of the protocol are
being
#link("https://github.com/privacy-scaling-explorations/mpz/tree/dev/garble")[implemented and used today];.

== The Problem
<the-problem>
Here is our problem setting, slightly more formally:

- $A$ knows a secret bitstring $a$ of length $s$ bits
- $B$ knows a secret bitstring $b$ of length $t$ bits
- $C$ is a binary circuit, which takes in $s + t$ bits, and runs them
  through some $n$ gates. The outputs of some of the gates are the
  public outputs of the circuit. Without loss of generality, let’s also
  suppose that each gate in $C$ accepts either $1$ or $2$ input bits,
  and outputs a single output bit.
- $A$ and $B$ would like to jointly compute $C (a , b)$ without
  revealing to each other their secrets.

== Garbled gates

Our garbled circuits are going to be built out of "garbled gates".
A garbled gate is like a traditional gate (like AND, OR, NAND, NOR),
except its functionality is hidden.

What does that mean?

Let's say the gate has two input bits,
so there are four possible inputs to the gate: 
$(0, 0), (0, 1), (1, 0), (1, 1)$.
For each of those four inputs $(x, y)$,
there is a secret password $P_(x, y)$.
The gate $G$ will only reveal its value $G(x, y)$
if you give it the password $P_(x, y)$.

It's easy to see how to make a garbled gate.
Choose a symmetric-key
[#footnote("Symmetric-key encryption is probably " +
"what you think of " +
"when you think of plain-vanilla encryption: " +
"You use a secret key $K$ to encrypt a message $m$, " +
"and then you use the same secret key $K$ to decrypt it.")
] 
encryption scheme $Enc$
[#footnote("We'll talk later about what sort of " +
"encryption scheme is suitable for this...")]
and publish the following table:
#table(
  columns: 2,
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

To chain garbled gates together,
we need to modify the output of each gate:
In addition to outputting the bit $z = G_i (x, y)$,
the $i$-th gate $G_i$ 
will also output a password $P_z$ that Bob can use at the next step.
#todo[Introduce Bob]

Now there's a problem here!
We said before that each gate should require four passwords
$
  P_(0, 0), P_(0, 1), P_(1, 0), P_(1, 1),
$
one for each possible input pair of bits.


