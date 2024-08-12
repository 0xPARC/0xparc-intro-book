#import "@local/evan:1.0.0":*

= Research workshop on August 3: Problem statements

== Coding Theory I (Liam Eagen)

#problem[
  Solve conjecture 1 in
  #url("https://cic.iacr.org/p/1/1/2/pdf")
]

== Dan Boneh's two problems

1. Outsource SNARK proof generation to untrusted servers
2. Efficient short _weighted_ threshold signature.

Good progress in #url("https://eprint.iacr.org/2023/1609.pdf").

=== Outsource SNARK proof generation to untrusted servers

- We have a secret witness $w$, and a complicated circuit $C$,
  and want a server to get a proof of $C(w) = 0$ (say).
  But we don't want the server to learn $w$.
- One method is a collaborative proof where we secret-share among $n$ servers.
  [B-Ozdemir'21, GGJPS'23, CLMZ'23.]
  As long as at most $n-1$ are malicious, we're OK.
- Surprisingly, this uses zkSNARK with an MPC-friendly prover,
  and the MPC adds almost no overhead.
- But we need an assumption the servers are not colluding.

#problem[
  Can we do it with a single untrusted server?
]

The obvious approach is to use FHE:
the powerful server could run the SNARK-prover inside an FHE.
This is a theoretical approach, but is completely unpractical.

#remark[
  We don't need verifiable FHE for this, unlike some other situations:
  because the output is an FHE proof, the client can just
]

The goal is to design a FHE-friendly SNARK:
that is, the SNARK prover is a shallow circuit that can run inside FHE.

#url("https://eprint.iacr.org/2023/1609")
points out that FRI on hidden values is a viable approach.

One other way to make the work shallower for the FHE is to do some rounds of interaction.

=== Weighted signatures

We have $n$ people with weights $w_1$, ..., $w_n$
and we want a quorum $S subset.eq [n]$ to be able to sign iff
$sum_(i in S) w_i > t$ for some threshold $t$.

#remark[
  Used in proof-of-stake sometimes.
]

The trivial way to do this is to use a non-weighted scheme
and then give $w_i$ shares to the $i$th person; this is pretty inefficient.
(But it's actually done in practice this way sometimes.)

#problem[
  We want a _practical_ scheme where all the following
  are independent of $n$, $t$, and $(w_1, ..., w_n)$:

  - the signature size,
  - secret key size,
  - public key size,
  - verification time,
  - and each party's signing team.
]

This is easy with generic SNARK techniques,
because the aggregator could simply produce a proof
it saw all the signatures from $S$.
But we'd like a simple scheme that don't require SNARK's.

== A new hash function (Jordi Baylina)

Let $p := 2^64-2^32+1$ be the Goldilocks prime and work in $FF_p$.
Our function has signature
$ FF_p^8 arrow.r.hook FF_p^(12) -> FF_p^(12) arrow.r.twohead FF_p^4. $
The first arrow is inclusion where the last four coordinates are dropped to zero.
The last arrow is projection onto the first four coordinates.
The main operation is the center arrow.

We view the input as $vec(v) in FF_p^(12)$ and apply a certain function $30$ times.
It involves a linear part, and a seventh powers.

This is a new hash function and hasn't been thought about much yet.

#problem[
  Try to either find a preimage or a collision for this hash function.
]

#remark[
  Colin's question clarifies that the $arrow.r.hook$ and $arrow.r.twohead$
  are necessary because the main arrow is easily invertible
  (they are invertible matrix multiplications and seventh powers in $FF_p$).
]

== PIR open problems (Elaine Shi)

To start, repeat the following content in @pir:

- Statement of PIR problem
- Comparison to ORAM
- The discussion of the two naive attempts

The following two facts are known:

1. In a single-server setting,
  cryptography is necessary for sub-linear bandwidth/communication.
2. Classical PIR with no pre-processing always requires at least $Omega(n)$ compute.

In a 2-server, Dvir-Gopi'16 (FOCS best paper) gets $n^o(1)$ bandwidth
and $n^O(sqrt(log log n slash log n))$ computation for the server.

With $omega(1)$ servers, doubly-efficient schemes exist with
$n^o(1)$ bandwidth and $n^(1+o(1))$ server space.

Questions (purely information theoretic):

#problem[
  In DG'16, can we make the server compute linear without cryptographic assumptions?
]
(Boneh says this already known with crytographic assumptions.)

#problem[
  For 2-server IT, can we have a scheme with $o(n^(1/3))$ bandwidth
  and sublinear computation?
]
