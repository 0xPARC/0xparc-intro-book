#import "preamble.typ":*

Historically, the construction of the first PCP,
or *Probabilistically Checkable Proof*, was sort of an ancestor to the zkSNARK.
There are a few nice ideas in here, but they're actually more complicated
than the zkSNARK and hence included here mostly for historical reference.

Pedagogically, we think it makes sense to just jump straight into PLONK
and Groth16 even though the PCP construction came first.
The more modern zkSNARK protocols are both better
(according to metrics like message length or verifier complexity)
and simpler (fewer moving parts).

This part is divided into two sections.

- @sumcheck describes the sum-check protocol, which is actually useful
  a bit more generally and shows up in some other SNARK constructions
  besides the PLONK and Groth16 that we covered.

- @pcp gives an overview of the first PCP constructions,
  but it's quite involved and much less enlightening.
  It's mostly here for historical reasons and not otherwise worth reading.

Elliptic curves will not be used in this part at all;
in fact, these two chapters are self-contained and don't depend on earlier parts
of these lecture notes.
