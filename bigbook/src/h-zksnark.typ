#import "preamble.typ":*

This part covers two constructions of the zkSNARK,
the *PLONK* and *Groth16* constructions.
Despite being fairly modern constructions,
these are arguably simpler and more informative to learn about than
the PCP construction that preceded them (which is covered in @pcp).

The dependency chart of this chapter goes as follows:

- @ec describes the discrete logarithm problem on an elliptic curve,
  which provides a basis for everything afterwards.

- @kzg and @ipa give two different *polynomial commitment schemes*,
  which allow a prover Peggy to

  - commit to some polynomial $P(X) in FF_q [X]$ ahead of time,
  - and then *open the commitment* at any input $z in FF_q$ while not revealing $P$ itself.

  The KZG scheme from @kzg is quite simple and elegant but requires a trusted setup.
  In contrast, IPA from @ipa has fewer assumptions and is more versatile,
  but it's slower and more complicated.

- Regardless of whether KZG/IPA scheme is used,
  we then show two constructions of a zkSNARK.
  In @plonk we construct PLONK;
  in @groth16 we construct Groth16.
