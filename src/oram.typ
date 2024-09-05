#import "preamble.typ":*
// #import algorithmic: algorithm

To motivate Oblivious RAM, let us think of Signal’s usage scenario.
Signal is an encrypted messenger app with billions of users. They want
to support a private contact discovery application. In contact
discovery, a user Alice sends her address book to Signal, and Signal
will look up its user database and return Alice the information about
her friends. The problem is that many users want to keep their address
book private, and Signal wants to provide contact discovery without
learning the users’ contacts.

A naive solution is to rely on trusted hardware. Suppose Signal has a
secure processor (e.g., Intel SGX) on its server. One can think of the
secure processor as providing a hardware sandbox (often referred to as
an #emph[enclave];). Now, Alice sends her address book in encrypted
format to the server’s enclave; further, the server’s database is also
encrypted as it is stored in memory and on disk. Now, the enclave has a
secret key that can decrypt the data and perform computation inside. At
first sight, this seems to solve the privacy problem, since data is
always encrypted in transit and at rest, and the server cannot see the
contents. 

Unfortunately, encryption alone provides
little privacy in such scenarios. The enclave will need
to access encrypted entries stored on disk, and the server’s operating
system can easily observe the #emph[access patterns];, i.e., which
memory pages are being fetched by the enclave. The access patterns leak
exactly who Alice’s friends are even if the data is encrypted!

In general, access patterns of a program leak sensitive information
about your private data. As a simpler example, if you are performing binary
search over a sorted array, the entries accessed during the search would
leak your private query. 

We can also think of
access pattern leakage through a programming language perspective: for
example, the following program has an `if`-branch dependent on secret
inputs (e.g., think of the secret input as the last bit of a secret key)
Thus by observing whether memory location `x` or `y` is accessed, one
can infer which branch is taken.

#align(center)[
#block[
```
if (s) {
  mem[x]
} else {
  mem[y]
}
```
]
]
Therefore, we want to solve the following challenge:

#quote[How can we provably hide access patterns while preserving
  efficiency?]

The solution Signal eventually deployed is an algorithmic technique
called Oblivious RAM (ORAM).

= Oblivious RAM: Problem Definitions
<oblivious-ram-problem-definitions>
Oblivious RAM (ORAM) is a powerful cryptographic protocol that
#emph[provably] hides access patterns to sensitive data.

We would like to ensure a very strong notion of security. In particular,
no information should be leaked about: 1) which data block is being
accessed; 2) the age of the data block (i.e., when it was last
accessed); 3) whether a single block is being requested repeatedly
(frequency); 4) whether data blocks are often being accessed
together (co-occurrence); or 5) whether each access is a read or a
write.

Let us explain the parts of an ORAM system.

An ORAM algorithm (the #emph[client];) 
sits between a #emph[user]; who wants to access memory
and a #emph[server]; that has memory capabilities.
At the server-ORAM interface, the server simply acts as a memory:
the ORAM client sends read and write requests to the server,
and the server responds.
Between the ORAM and the user,
the user submits #emph[logical] read and write requests
to the ORAM client,
and the client will reply to each (after interaction with the server).

We will call #emph[physical] memory the memory that the server manages,
and #emph[logical] memory the memory the user wants to access.
Memory, both physical and logical, will be made up of "blocks";
our ORAM algorithm will support $N$ blocks of logical memory.

Formally, the user sends to the algorithm
a sequence of #emph[logical] requests, where each logical request
is of the form
$(mono("read"), mono("addr"))$ or $(mono("write"), mono("addr"),
mono("data"))$.

After each user request, the ORAM algorithm interacts with 
the server to make a sequence of
#emph[physical] accesses, where each physical access either reads or
writes a block to a physical location.

And finally, the ORAM algorithm
turns back to the user and
returns an answer to the logical request. 

For example, in Signal’s scenario, 
the "user" and the "ORAM client"
are both in the hardware enclave,
and the "ORAM server" is the untrusted memory and disk on
Signal’s server. 

The security requirement for ORAM is that the server should learn nothing
about the user's logical memory requests
from observing the sequence of physical memory requests.
For any two #emph[logical] request sequences, the ORAM’s
resulting #emph[physical] access sequences will be indistinguishable.

#remark[
In this security requirement, 
we require that the server learn nothing from the list of
physical addresses, and whether each physical
access is a read or write.
We don't say anything about the data that is written to physical memory.

In practice, we need to use encryption to hide
the contents of the blocks. 
For example, if we read a block and then write it back,
we should re-encrypt it with a different ciphertext,
or else the server would recognize it as the same block.

From now on we will simply assume secure encryption as
given, and focus on hiding the access patterns.
]

= Naive Solutions
<naive-solutions>
== Naive solution 1
<naive-solution-1.>
One trivial solution is for the client to read all blocks from the
server upon every logical request. Obviously this scheme leaks nothing
but would be prohibitively expensive.

== Naive solution 2
<naive-solution-2.>
Another trivial solution is for the client to store all blocks, and thus
the client need not access the server to answer any memory request. But
this defeats the numerous advantages of cloud outsourcing in the first
place. #emph[Henceforth, we require that client store only a small
amount of blocks] (e.g., constant or polylogarithmic in $N$).

== Naive solution 3
<naive-solution-3.>
Another naive idea is to randomly permute all memory blocks through a
secret permutation known only to the client. Whenever the client wishes
to access a block, it will appear to the server to reside at a random
location.

Indeed, this scheme gives a secure #emph[one-time] ORAM scheme, i.e., it
provides security if every block is accessed only once. However, if the
client needs to access each block multiple times, then the access
patterns will leak statistical information such as frequency (i.e., how
often the same block is accessed) and co-occurrence (i.e., how likely
two blocks are accessed together). As mentioned earlier, one can
#cite("https://www.ndss-symposium.org/wp-content/uploads/2017/09/06_1.pdf", "leverage")
such statistical information to infer sensitive
secrets.

== Important observation
<important-observation.>
The above naive solution 3 gives us the following useful insight:
informally, if we want a "non-trivial" ORAM scheme, it appears that we
may have to relocate a block after it is accessed — otherwise, if the
next access to the same block goes back to the same location, we can
thus leak statistical information. It helps to keep this observation in
mind when we describe our ORAM scheme later.

= Binary-Tree ORAM: Data Structure
<data-structure>
We will learn about tree-based ORAMs. 
Then, we will mention an
improvement called #cite("https://eprint.iacr.org/2013/280.pdf", "Path ORAM"),
which is the scheme
that Signal has deployed.

== Server data structure
<server-data-structure.>
The server stores a binary tree, where each node is called a
#emph[bucket];, and each bucket is a finite array that can hold up to
$Z$ number of blocks — for now, think of $Z$ as being relatively small
(e.g., polylogarithmic in $N$); we will describe how to parametrize $Z$
later. Some of the blocks stored by the server are #emph[real];, other
blocks are #emph[dummy];. As will be clear later, these dummy blocks are
introduced for security.

== Main path invariant
<main-path-invariant.>
The most important invariant is that at any point of time, each block is
mapped to a random path in the tree (also referred to as the block’s
designated path), where a path begins from the root and ends at some
leaf node — and thus a path can be specified by the corresponding leaf
node’s identifier. When a block is mapped to a path, it means that the
block can legitimately reside anywhere along the path.

== Imaginary position map
<imaginary-position-map.>
For the time being, we will rely on the following cheat (an assumption
that we can get rid of later). We assume that the client can store a
somewhat large position map that records the designated path of every
block. In general, such a position map would require roughly
$Theta (N log N)$ bits to store — but later we can recursively outsource
the storage of the position map to the server by placing them in
progressively smaller ORAMs.

= Binary Tree ORAM: Operations
<operations>
We now describe how to access blocks in our ORAM scheme.

== Fetching a block
<fetching-a-block.>
Given how our data structures are set up, accessing a block is very
easy: the client simply looks up its local position map, finds out on
which path the block is residing, and then reads each and every block on
the path. As long as the main invariant is respected, the client is
guaranteed to find the desired block.

== Remapping a block
<remapping-a-block.>
Recall that earlier, we have gained the informal insight that whenever a
block is accessed, it should relocate. Here, whenever we access a block,
we must remap it to a randomly chosen new path — otherwise, we would end
up going back to the same path if the block is requested again, thus
leaking statistical information.

To remap the block, we choose a fresh new path, and update the client’s
position map to associate the new path with the block. We now would like
to write this block back to the tree, to somewhere on the new path (and
if the request is a `write` request, the block’s contents are updated
before being written back to the server). But doing this is tricky! It
turns out that we cannot write the block back directly to the leaf
bucket of the new path — since doing so would reveal which new path the
block got assigned, this leaks information since if the next request
asks for the same block, it would then go to this new path; otherwise
most likely the next request will go to a different path. By a similar
reasoning, we cannot write this block back to any internal nodes of the
new path either, since writing to any internal node on the new path also
leaks partial information about the new path.

It turns out that the only safe location to write the block back is to
the root bucket! The root bucket resides on every path, and thus writing
the block back to the root does not violate the main path invariant; and
further, it does not leak any information about the new path.

Now this is great. Our idea thus is to write this block back to the root
bucket. However, there is also an obvious problem! The root bucket has a
capacity of $Z$, and if we keep writing blocks back to the root, soon
enough the root bucket will overflow! Therefore, we now introduce a new
procedure called #emph[eviction] to cope with this problem.

== Eviction
<eviction.>
Eviction is a maintenance operation performed upon every data access to
ensure that none of the buckets in the ORAM tree will ever overflow
except with negligible in $N$ failure probability. Note that if an
overflow does happen, the block that leads to the overflow can get lost
since there is no space to hold it on the server, and this can affect
the correctness of our ORAM scheme. However, we will guarantee that such
correctness failure happens only with negligible probability.

The high-level idea is very simple: whenever we can, we will try to move
blocks in the tree closer to the leaves, to allow space to free up in
smaller levels of the tree (i.e., levels closer to the root). There are
a few important considerations when performing such eviction:

- Data movement during eviction must respect the main path invariant,
  i.e., each block can only be moved into buckets in which it can
  legitimately reside.

- Data movement during eviction must retain #emph[obliviousness];, i.e.,
  the physical locations accessed during eviction should be independent
  of the input requests to the ORAM.

- As we perform eviction, we pay a cost for this maintenance operation
  and the cost is charged to each data access. Obviously, if we are
  willing to pay more such cost, we can pack blocks closer to the
  leaves, thus leaving more room in smaller levels. In this way,
  overflows are less likely to happen. On the other hand, we also do not
  want the eviction cost to be too expensive. Therefore, another tricky
  issue is how we can design an eviction algorithm that achieves the
  best of both worlds: with a small number of eviction operations, we
  can avoid overflow almost surely (i.e., no overflow except with
  negligible in $N$ probability).

#figure(image("binaryoram16-evict.png"),
  caption: [
    The `Evict` algorithm. Upon every data access operation, 2 buckets
    are chosen at every level of the tree for eviction during which one
    data block will be evicted to one of its children. To ensure
    security, a dummy eviction is performed for the child that does not
    receive a block; further, if the bucket chosen for eviction is
    empty, dummy evictions are performed on both child buckets. In
    this figure, $R$ denotes a real eviction and $D$ denotes a dummy
    eviction.
  ]
)

We describe a simple candidate eviction scheme, and we will give an
informal analysis of the scheme later:

- #emph[\[An eviction algorithm\]] Upon every data access, we choose
  random $2$ buckets in every level of the tree for eviction (for the
  root level, pick one bucket). If a bucket is chosen for eviction, we
  will pop an arbitrary block (if one exists) from the bucket, and write
  the block to one of its children.

Note that depending on the chosen block’s designated path, there is only
one child where the block can legitimately go. We must take precautions
to hide where this block is going: thus for the remaining child that
does not receive a block, we can perform a "dummy" eviction.
Additionally, if the bucket chosen for eviction is empty (i.e., does not
contain any real blocks), then we make a dummy eviction for both
children — this way we avoid leaking the information that the chosen
bucket is empty.

More specifically, to write an intended block to a child bucket, we
sequentially scan through the child bucket. If the slot is occupied with
a real block, we simply write the block back. If the slot is empty, we
write the intended block into that slot. A dummy eviction therefore is
basically reading every block sequentially and writing the original
contents back.

So far, we have not argued why any bucket that receives a block always
has space for this block — we will give an informal analysis later to show
that this is indeed the case.

== Algorithm pseudo-code
<algorithm-pseudo-code.>
We present the algorithm’s pseudo-code in Algorithms~@alg:access and
@alg:evict.


#algorithm[
The procedure $mono("Access")(mono("op"), mono("addr") , mono("data")^(\*))$
where $mono("op") = mono("read")$ or $mono("op") = mono("write")$

#strong[Assume:] each block is of the form
$(mono("addr") , mono("data") , l)$ where $l$ denotes the block’s
current designated path.

1. 
  $l^(\*) arrow.l^(\$) [1 . . N]$, 
  $l arrow.l mono("position")[mono("addr")]$,
  $mono("position")[mono("addr")] arrow.l l^(\*)$.
2. For each bucket from leaf $l$ to root do:
  3. Scan $mono("bucket")$, and if
    $(mono("addr") , mono("data")_0 , \_) in mono("bucket")$ then let
    $mono("data")^(\*) arrow.l mono("data")_0$ and remove this block from
    $mono("bucket")$.
4. End for
5. If $mono("op") = mono("read")$ then add
  $(mono("addr") , mono("data")^(\*) , l^(\*))$ to the root bucket; else
  add $(mono("addr") , mono("data") , l^(\*))$ to the root bucket.
6. Call the $mono("Evict")$ subroutine.
7. Return $mono("data")^(\*)$.
]<alg:access>
#algorithm[
The procedure $mono("evict")$

1. For each level $d$ from the root to the level of leaves $-1$, do:
  2. $mono("bucket")_0$, $mono("bucket")_1 arrow.l$ 
    randomly choose $2$
    distinct buckets in the level $d$ (for the root level, pick one bucket).
  3. For $mono("bucket") in \{ mono("bucket")_0, mono("bucket")_1 \}$ do:
    4. $sans("block") :=$ pop a real block from $sans("bucket")$ if one exists;
      else $sans("block") := (tack.t , tack.t , tack.t)$.
    5. For each of the two children of $mono("bucket")$ in a fixed order: 
      scan the child
      bucket reading and writing every block. 
      If $sans("block")$ is real and
      wants to go to the child, write $sans("block")$ to an empty slot in the
      child bucket.
  6. End for
7. End for
]<alg:evict>

#block[
#strong[Remark 2];. Note that in a full-fledged implementation, all
blocks are typically encrypted to hide the contents of the block.
Whenever reading and writing back a block, the block must be
re-encrypted prior to being written back. If the encryption scheme is
secure, the server should not be able to tell whether the block’s
content has changed upon seeing the new ciphertext.

]
= Analysis
<analysis>
We will now discuss why the aforementioned binary-tree ORAM construction

1) preserves obliviousness; and 

2) is correct (except with negligible probability).

== Obliviousness
<obliviousness.>
Obliviousness is easy to see. 

First, whenever a block is
accessed, it is assigned to a new path and the choice of the new path is
kept secret from the server. So whenever the block is accessed again,
the server simply sees a random path being accessed. 

Second, 
the entire eviction process does not depend on the input requests
at all.

== Correctness
<correctness.>
Correctness is somewhat more tricky to argue. As mentioned earlier, to
argue correctness, we must argue why no overflow will ever occur except
with negligible probability — as long as the bucket size $Z$ is set
appropriately.

#claim[
(Bucket size and overflow probability). #emph[If the
bucket size $Z$ is super-logarithmic in $N$, then over any polynomially
many accesses, no bucket overflows except with negligible in $N$
probability. ]

] <clm:bucketsize>
#block[
#emph[Proof.] 
We will give a heuristic outline of a proof.
The full argument uses results from
#cite("https://en.wikipedia.org/wiki/Queueing_theory", "queueing theory"),
in particular 
#cite("https://en.wikipedia.org/wiki/Burke%27s_theorem", "Burke's theorem").

- The root bucket (i.e., level $0$ of the ORAM tree)
  receives exactly $1$ incoming block with every access, but we get to
  evict the root bucket twice upon every access, and thus whatever
  enters the root gets evicted immediately.

- Now consider a bucket at level $1$ of the ORAM tree. On average, one
  out of every two accesses, a block will enqueue in
  the bucket. With probability $1$, the bucket will be chosen for
  eviction. If the bucket is chosen for eviction, a block gets to
  dequeue from this bucket.

- Similarly, consider a bucket at level $2$ of the ORAM tree. On
  average, one out of every four accesses, a block
  will enqueue in the bucket. With probability $1 / 2$, the bucket will
  be chosen for eviction.

- In general, at level $i > 1$ of the
  ORAM tree, a block will enqueue on one out of every $2^i$ accesses, 
  and with probability $1 / 2^(i - 1)$, the bucket is
  chosen for eviction.

Now we see a useful pattern: for every non-leaf and non-root level of
the tree, with every ORAM access, the dequeue probability is twice as
large as the enqueue probability. 
This situation is well-known in queueing theory as the
"M/M/1 queue":

- Every time step, with probability $p$, an item enqueues;

- Every time step, with probability $2 p$, an item dequeues if the queue
  is non-empty.

Since the bucket is drained (on average) twice as fast as it is filled,
we expect that it's very unlikely for a lot of blocks to accumulate
in any one bucket.

Indeed, one can prove an exponential bound on the probability
that any one bucket gets too full:
$ Pr [upright("number of items in queue") > R] lt.eq exp (Omega (- R)). $

Unfortunately, this doesn't quite finish our analysis of the ORAM tree.
The reason is that the buckets in the ORAM tree are not independent, and
our informal argument above ignored possible dependence between buckets.
It turns out that this gap can be filled using Burke's theorem.
But at this point the reader should already be convinced that 
the result is at least quite plausible.
]
= Binary-Tree ORAM: Recursion
<binary-tree-oram-recursion>
So far, we have cheated and pretended that the client can store a large
position map. We now describe how to get rid of this position map. The
idea is simple: instead of storing the position map on the client side,
we simply store it in a smaller ORAM denoted $sans("posORAM")_1$ on the
server. The position map of $sans("posORAM")_1$ will then be stored in
an even smaller ORAM denoted $sans("posORAM")_2$ on the server, and so
on. As long as the block size is at least $Omega (log N)$ bits, every
time we recurse, the ORAM’s size reduces by a constant factor; and thus
$O (log N)$ levels of recursion would suffice.

We can thus conclude with the following theorem.

#theorem[
#cite("https://eprint.iacr.org/2011/407.pdf", "Binary-tree ORAM")
#emph[For any
super-constant function $alpha (dot.op)$, there is an ORAM scheme that
achieves $O (alpha log^3 N)$ cost for each access, i.e., each logical
request will translate to $O (alpha log^3 N)$ physical accesses; and
moreover, the client is required to store only $O (1)$ number of
blocks.]
]
Note that in the total cost $O (alpha log^3 N)$, an $alpha log N$ factor
comes from the bucket size; another $log N$ factor comes from the total
height of the tree; and the remaining $log N$ factors comes from the
recursion.

= Path ORAM
<path-oram>
The design of the above binary-tree ORAM is a little silly: whenever we
visit a triplet of buckets for eviction, we only evict one block. For
this reason, the bucket size needs to be super-logarithmic to get
negligible failure probability.
It turns out that if we instead use a more aggressive eviction
algorithm, and with a more sophisticated proof, the bucket size can be
made constant. At this point, we are ready to introduce an improved
version called Path ORAM.

Unlike the above binary-tree ORAM, in Path ORAM, every bucket has
constant size (e.g., 4 or 5), except the root bucket which is
super-logarithmic in size. Every time we access some path to fetch a
block, we also perform eviction on the same path. In particular, we will
rearrange the blocks on the path in the most aggressive manner possible:
we want to move the blocks as close to the leaf level as possible, but
#emph[without violating the path invariant];. With Path ORAM, every
access operation touches a single path, hence the name Path ORAM.
The cost of each access is $O (alpha log^2 N)$ for an
arbitarily small superconstant function $alpha$.

== Other Applications of ORAM
<other-applications-of-oram>
ORAM promises many potential applications. For instance, in Large
Language Models (LLMs), a commonly used technique is called Retrieval
Augmented Generation (RAG). RAG parses the user’s query and looks up the
relevant locations in a large knowledge base to fetch the relevant
entries. If we want to protect the privacy of users’ queries in LLMs, it
is also crucial to hide the access patterns, and this would be a great
application of ORAM.

Besides its usage in secure processors, ORAM is critical for scaling
cryptographic multi-party computation (MPC) to big data. Traditional MPC
techniques require us to express the desired computation as a circuit.
However, in the real-world, we program assuming the Random Access
Machine (RAM) model where a CPU can dynamically read and write a memory
array. Translating a RAM program to a circuit brute-force would incur a
linear (in the memory size) cost for each memory access! For example, a
binary search in a sorted database requires only logarithmic time on a
RAM, but it requires linear cost when expressed as a circuit.
Fortunately, ORAM again comes to our rescue. There is a line of work on
RAM-model MPC, and the idea is that we first translate the RAM to an
oblivious RAM, and at this point all the memory accesses are safe to
reveal. At this moment, we can use MPC to securely emulate a "secure
processor" that performs computation while accessing memory obliviously.
