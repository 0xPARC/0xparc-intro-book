#import("preamble.typ"):*

= Making it non-interactive: Fiat--Shamir

As we described it,
PLONK is an interactive protocol.
Peggy sends Victor some data;
Victor reads that data and sends back a random challenge.
Peggy sends back some more data;
Victor replies with more challenges.
After a few rounds of this,
the protocol is complete, and Victor is convinced
of the truth of Peggy's claim.

We want to turn this into a non-interactive protocol.
Peggy sends Victor some data once.
Victor reads the data, does some calculation,
and convinces himself of the truth of Peggy's claim.

We will do this using a general trick, called the "Fiat--Shamir heuristic."

Let us step back and philosophize for a moment.
Why does Victor need to send challenges at all?
This is actually what makes the whole SNARK thing work.
Peggy condenses a long calculation down into
a very short proof, which she sends to Victor.
What keeps her from cheating is that
she has to be prepared to respond to any challenge
Victor could possibly send back.
If Peggy knew what challenge Victor was going to send,
Peggy could use that foreknowledge to create a false proof.
But by sending a random challenge after Peggy's original commitment,
Victor prevents her from adapting her proof to the challenge.

The idea of Fiat and Shamir is to replace
Victor's random number generator with a
(cryptographically secure) hash function.
Instead of interacting with Victor,
Peggy simply runs this hash function to generate the challenge for each round.

For example, consider the following (slightly simplified)
version of @root-check.

#algorithm[
  Peggy wants to prove to Victor that two polynomials $F$ and $H$
  (known only to Peggy) satisfy $F(X) = Z(X) H(X)$, where
  $Z(X) = product_(z in S) (X-z)$ is a fixed polynomial
  known to both Peggy and Victor.

  1. Peggy sends $Com(F)$ and $Com(H)$.
  2. Victor picks a random challenge $lambda in FF_q$
  3. Peggy opens both $Com(F)$ and $Com(H)$ at $lambda$.
  4. Victor verifies $F(lambda) = Z(lambda) H(lambda)$.
]

Fiat--Shamir turns it into the following noninteractive protocol.

#algorithm[
  Peggy wants to prove to Victor that two polynomials $F$ and $H$
  (known only to Peggy) satisfy $F(X) = Z(X) H(X)$, where
  $Z(X) = product_(z in S) (X-z)$ is a fixed polynomial
  known to both Peggy and Victor.

  1. Peggy sends $Com(F)$ and $Com(H)$.
  2. Peggy computes $lambda in FF_q$ by $lambda = sha(Com(F), Com(H))$.
  3. Peggy opens both $Com(F)$ and $Com(H)$ at $lambda$.
  4. Victor verifies that
    $lambda = sha(Com(F), Com(H))$ and $F(lambda) = Z(lambda) H(lambda)$.
]

We can apply the Fiat--Shamir heuristic to the full PLONK protocol.
Now Peggy can write the whole proof herself
(without waiting for Victor's challenges),
and publish it.
Victor can then verify the proof at leisure.

