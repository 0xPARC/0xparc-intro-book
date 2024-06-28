#import "preamble.typ":*

= KZG Takeaways

#green[
1. _Elliptic curves_ are very useful in cryptography. Roughly speaking, they are sets of points (usually in $F_p^2$) that satisfy some group law / "addition." The BN254 curve is a good "typical curve" to keep in mind.
2. The _discrete logarithm_ assumption is a common "hard problem assumption" used in cryptography with different groups. Specifically, since elliptic curves are groups, discrete logarithm over elliptic curves is very often used. 
3. _Commitment schemes_ are ways for one party to commit values to another. Elliptic curves enable _Pedersen commitments_, a very useful example of a commitment scheme.
4. Specifically, _polynomial commitment schemes_ are commitments of polynomials that are small and easy to "open" (evaluate at different points). KZG is one of the main polynomial commitment schemes being used in cryptography, such as in PLONK (coming up).
]
