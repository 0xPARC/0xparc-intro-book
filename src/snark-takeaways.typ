#import "preamble.typ":*

#takeaway[SNARK Takeaways][
1. A _SNARK_ can be used to succinctly prove that a piece of computation has been done correctly; specifically, it proves to some Verifier that the Prover had the K(nowledge) of some information that worked as feasible inputs to some computational circuit.
2. The _arithmetization_ of the circuit is a way of converting circuits to arithmetic. Specifically for PLONK (but also other SNARKs, e.g. Groth16), our arithmetization is systems of quadratic equations over $FF_q$, meaning that what PLONK does under the hood is prove that a system of these equations are satisfied.
3. The work under the hood of PLONK comes down to polynomial commitments (specifically KZG). KZG allows PLONK's gate checks and copy checks.
4. The N(oninteractivity) of SNARKs basically come down to the _Fiat-Shamir heuristic_, which is very common in this field. Generally speaking, the "meat" of zkSNARKs are mostly about S(uccinctness) of the AR(guments).
]
