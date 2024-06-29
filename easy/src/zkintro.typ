#import "preamble.typ":*

= Introduction to SNARKs

Peggy has done some very difficult calculation.
She wants to prove to Victor that she did it.
Victor wants to check that Peggy did it, but he
is too lazy to redo the whole calculation himself.

- Maybe Peggy wants to keep part of the calculation secret.
  Maybe her calculation was "find a solution to this puzzle,"
  and she wants to prove that she found a solution
  without saying what the solution is.
- Maybe it's just a really long, annoying calculation,
  and Victor doesn't have the energy to check it all line-by-line.

A _SNARK_ lets Peggy (the "prover")
send Victor (the "verifier") a short proof
that she has indeed done the calculation correctly.
The proof will much shorter than the original calculation,
and Victor's verification is much faster.
(As a tradeoff, writing a SNARK proof of a calculation is much slower
than just doing the calculation.)

We won't discuss it here, but it is also possible and frequently useful to make a _zero knowledge (zk)_ SNARK. These are typically called "zkSNARKs." This gives Peggy a guarantee
that Victor will not learn anything about the intermediate steps
in her calculation, aside from any particular steps Peggy chooses to reveal.

== What can you do with a SNARK?

One answer: You can prove that you have a solution to a system of equations.
Sounds pretty boring, unless you're an algebra student.

Slightly better answer: You can prove that you have executed a program correctly,
revealing some or all of the inputs and outputs, as you please.
For example: You know a message $M$ such that
$op("sha")(M) = "0xa91af3ac..."$, but you don't want to reveal $M$.
Or: You only want to reveal the first 30 bytes of $M$.
Or: You know a message $M$, and a digital signature proving that $M$ was signed by
[trusted authority], such that a certain neural network, run on the input $M$, outputs "Good."

One recent application along these lines is
#link("https://tlsnotary.org", "TLSNotary").
TLSNotary lets you certify a transcript of communications with a server
in a privacy-preserving way: you only reveal the parts you want to.

