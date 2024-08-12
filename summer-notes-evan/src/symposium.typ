#import "@local/evan:1.0.0":*

#let DB = math.sans("DB")
#let DS = math.sans("DS")
#let mem = math.sans("mem")
#let cpustate = math.sans("cpu")
#let Enc = math.op("Enc")
#let addr = math.sans("addr")
#let fetched = math.sans("fetched")
#let wdata = math.sans("wdata")
#let NI = math.op("NextInstruct")


= Symposium on August 1, 2024: Notes on PIR (Elaine Shi) <pir>

Warning: these notes are _really_ rough.

== Problem statement: doubly efficient private information retrieval

The problem statement is roughly:
we have a database $DB$, and we want to to be able to query $DB[i]$
without revealing the index $i$.

== Comparison to ORAM

Some runtimes are given below for PIR stuff.
For ORAM, for comparison:

- For each client, stores $O(n)$ data (i.e. a copy of database is needed per client)
  - Trusted hardware circumvents this;
    in effect, trusted hardware _is_ the client, making it one-client.
    You can also replace trusted hardware with MPC.
- Query requires $O(log n)$ runtime for comm/compute.

So PIR should be thought of as being useful for situations with a _single_ database
being read by several people to gain an advantage over ORAM.

Multi-client ORAM/PIR is considered an open problem,
because even defining what the access control policy should be
(i.e. formulating the problem) is nontrivial.
In other words, for PIR, write operations are not well-defined with more than one client.

== Naive attempts

- Naive 1: communicate the whole database. $O(n)$ communication time.
- Naive 2: use FHE; this is called "classical PIR".
  You send an FHE-encrypted $i$ and the server returns FHE-encrypted $DB[i]$.
  This requires $tilde(O)(1)$ communication but $Omega(n)$ computation, and that's inevitable:

#theorem[BIOM 4][
  Any classical PIR without pre-processing must incur $Omega(n)$ compute.
]

The idea vaguely is that if you don't read the entire database,
then the choice of which things aren't read will leak information.


For large database, no matter how good your implied constant are,
the linear cost will be a dealbreaker.
(This impossibility results hold even for multi-server setup;
the total computation cost across all servers must sum to at least $Omega(n)$.)

== Preprocessing PIR

We need to do some pre-processing to make the queries sublinea.
There are two lines of approach here:

- Client-side preprocessing (subscription model)
- Global preprocessing
  - [LMW'23] "Doubly efficient PIR"

=== Client-side preprocessing

The _Piano_ scheme relies only on PRF and

- client space $tilde(O)(sqrt(n))$;
- communication/compute per query is also $tilde(O)(sqrt(n))$
- server stores only the original database; i.e. no extra storage overhead for server.

This scheme is simple and practical.

=== Global preprocessing

The state of the art is:

#theorem[LMW'23][
  Assuming Ring-LWE, one can do $n^(1+epsilon)$ server space
  and poly-log $tilde(O)(1)$ comm/compute overhead per query.
  No extra storage space on the client side.
]

This won the STOC'23 award, but it's theoretical
(it has astronomical constants and cannot be implemented in practice).
It's also a fairly complex scheme.

We need as a primitive a _polynomial evaluation data structure_
with the following property:
suppose $f$ is an $m$-variate polynomial of degree $d$.
There are some assumptions on relative size of $m$ and $d$.
We need to preprocess $f$ into a data structure $DS_f$
such that given any vector $vec x$,
we can compute $f(vec(x))$ from $DS_f$ efficiently,
where $DS_f$ might be long but one only reads a few parts from $f$.
Here the advertisement is:

- $tilde(O)(1)$ efficiency
- $DS_f$ has size $n^(1+epsilon)$ where $f$ has $n$ terms in it.

#remark[
  I got the impression the idea behind constructing $DS_f$
  is that you take a large prime $p$, and set up so you want values $f mod p$.
  Then you store tables of $f mod p_i$ for each $i$ for a bunch of smaller primes $i$
  such that $p_1 p_2 ... p_ell > p$ and store a table of $f(x) mod p_i$ for all $x in ZZ slash p_i ZZ$.

  But you need to do this twice? I think.
]


The naive approach would be to interpolate a polynomial $f$ such that $f(i) = DB[i]$,
build $DS_f$, and then query $DS_f$ at any given $i$.
The issue is this isn't private;
information is leaked by the choice of which parts of $DS_f$ are read.
(Also, it's deterministic, so this can't be easily fixed.)

The idea of LMW'23 is starting from the database $DB$,
interpolate $f$ such that $f(i) = DB[i]$,
and the do a homomorphic encryption to get $hat(f)$.
There's a special FHE scheme (called _algebraic FHE_;
this might just be somewhat homomorphic encryption? not sure) such that
$
  Enc(x+y) = Enc(x) + Enc(y) \
  Enc(x dot y) = Enc(x) dot Enc(y)
$
(the ciphertext space are polynomials).
Then rather than querying $i$, one queries $Enc(i)$ instead (?).

I asked which parts of this gives astronomical constants, and was told "everything".
A good open problem is to make LMW'23 more practical.

== RAM-Model MPC/2PC

We'll assume the RAM is already oblivious
(i.e. if we have an insecure RAM, put it through an ORAM compiler first).

In a traditional computer, you can imagine
you have a CPU state $cpustate$ and a memory state $mem$,
and at every time step $t$ we overwrite $cpustate$ and some data $wdata$
to write to some address $addr$.
Formalize this as
$ NI_t (cpustate_(t-1), fetched_(t-1)) |-> (addr, cpustate_t, wdata_t) $

Suppose Alice and Bob are implementing a secure computer.

They each have secret shares
- $overline(mem_A)$ and $overline(mem_B)$ of the memory state
- $overline(cpustate_A)$ and $overline(cpustate_B)$ of the memory state
- $overline(fetched_(t-1,A))$ and $overline(fetched_(t-1,B))$ fetched at the last step.

Then in every time step, we use 2PC to evaluate the next-instruction circuit $NI$
using the $cpustate$ and $fetched$ secret shares (not the $mem$ shares)
and have it output
$(addr, overline(wdata)_A)$
and $(addr, overline(wdata)_B)$.
Then the number of rounds is $O(T log n)$ (the $log n$ is due to the ORAM overhead),
where $T$ is the runtime of the original RAM.
The comm/compute cost is thus $tilde(O)(T)$.

#remark[
  RAM-model is still just MPC.
  The point is to use ORAM to avoid having to convert a program to a circuit,
  because the blowups of changing programs to RAM are huge.
]

=== Garbled RAM

We now show how to improve the number of rounds from $O(T log n)$ to $2$
while keeping the same comm/compute cost.

Recall _garbled circuits_ from the 3EP book,
where e.g. we had single gates that mapped two garbled bits to another garbled bit.
We want to similarly garble

$ tilde(NI)_t (tilde(cpustate)_(t-1), tilde(fetched)_(t-1)) |->
  (addr, tilde(cpustate)_t, tilde(wdata)_t). $

The problem is that we don't know where $tilde(fetched)_(t-1)$ is coming from.
(Also, the fetched data is probably a word and not a bit, but that is a separate issue.)
But even if $tilde(NI)_t$ only took in a small number of inputs (like $4$)
the problem is that one does not know where $tilde(fetched)_(t-1)$ is coming from.
This is different from the circuit case,
where for every gate, we knew exactly which other gates feed into it.
But $tilde(fetched)_(t-1)$ is coming from an unknown place:
in other words, *the wiring is dynamic*.

This issues is called a _language translation problem_
and is the biggest obstruction to construction of garbled RAM.

Assuming each address is read at most once:

- Permutation network (butterfly)
- Not sufficient for eager evaluation. Can improve to $O(log^2 N)$ per instruction
  (rather than the naive $O(N)$).

Following, HKO'23: rather than use boolean circuit, we need _tri-state circuit_
which has three basic gates (instead of AND, XOR used in classical):

- BUFFER: $x -> y$ if a control wire is $1$, otherwise disconnected.
- JOIN: consider two BUFFER gates with a promise that the two control wires
  are in opposite states; say the inputs are $x_0 -> y_0$ and $x_1 -> y_1$.
  Then we merge $y_0$ to $y_1$.
- XOR

We need to describe how to garble the BUFFER and JOIN gates.
The BUFFER gate's garbled truth table has just two rows.
Similarly for JOIN.
BUFFER and XOR require 1 bit of communication from the garbler to the evaluator,
while JOIN uses $lambda + 1$ bits.
(In practice, communication cost is the bottleneck.)
