#import "preamble.typ":*

= FHE Takeaways

#green[
1. A _fully homomorphic encryption_ protocol allows Bob to compute some function $f(x)$ for Alice in a way that Bob doesn't get to know $x$ or $f(x)$.
2. The hard problem backing known FHE protocols is the _learning with errors (LWE)_ problem, which comes down to deciding if a system of "approximate equations" over $F_q$ is consistent.
3. The main idea of this approach to FHEs is to use "approximate eigenvalues" as the encrypted computation and an "approximate eigenvector" as the secret key. 
  Intuitively, adding and multiplying two matrices with different approximate eigenvalues for the same eigenvector approximately adds and multiplies the eigenvalues, respectively.
4. To carefully do this, we actually need to control the error blowup with the _flatten_ operation. This creates a _leveled FHE_ protocol.
]
