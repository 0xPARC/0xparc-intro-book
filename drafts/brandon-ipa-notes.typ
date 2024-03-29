#import "@preview/ctheorems:1.1.2": *
#show: thmrules

#let theorem = thmplain(
  "theorem",
  "Theorem",
  base_level: 0,
  titlefmt: strong
)

#let definition = thmplain(
  "theorem",
  "Definition",
  base_level: 0,
  titlefmt: strong
)

#let proposition = thmplain(
  "theorem",
  "Proposition",
  base_level: 0,
  titlefmt: strong
)

#let lemma = thmplain(
  "theorem",
  "Lemma",
  base_level: 0,
  titlefmt: strong
)

#let corollary = thmplain(
  "theorem",
  "Corollary",
  base_level: 0,
  titlefmt: strong
)

#let proof = thmproof(
  "proof", 
  "Proof"
)

#set par(
  justify: true,
)


= IPA #sym.arrow.r Proof System

We will implement the R1CS system using IPA. 
Recall that in R1CS, we wish to do the following:
We have 3 $n times n$ matrices $A$, $B$, $C$ with entries in $FF_p$.
We are interested in solving the quadratic equation $(A x) dot.circle (B x) = (C x)$
over $x in FF_p^n$ (here, $dot.circle$ denotes the Hadamard, i.e. element-wise, product).
The prover wishes to show that they know a solution to this equation.
In addition, they need to be able to reveal information about $x$ (specifically, they need to be able to open the $i$th entry for arbitrary $i$).

== Pedersen Commits and the IPA API

We will fix a large prime $p$ and some (Elliptic curve) group $E$ of order $p$.
We first use the following:

#definition("Basis")[
  A set of points $P_1, P_2, dots, P_n$ is a #emph("basis") if they have no "known" linear combinations.
]

Generically, we will let the verifier pick some large basis by just randomly sampling points on the curve.
This is useful for the following reason.

#definition("Pedersen Commitment")[
  For a vector $x = (x_1, x_2, dots, x_n)$, we let the #emph("Pedersen commitment")
  of $x$ with respect to some basis $(G_1, G_2, dots, G_n)$ be the group element $x_1G_1 + x_2G_2 + dots.c + x_n G_n in E$.
]

Note that the commitment depends on the choice of basis. 
We will later show that it is possible to perform a "change of basis".

#theorem("Inner Product Argument")[
  Suppose that $G_1, G_2, dots, G_n, H_1, H_2, dots, H_n, Q$ is a basis.
  There exists an interactive protocol with $O(log n)$ message complexity and $O(n)$ verifier computational complexity that allows a prover to prove the following about some commitment $C$:
  The prover knows $a_1, a_2, dots, a_n, b_1, b_2, dots, b_n, z$ such that 
  $ C = a_1G_1 + a_2G_2 + dots.c + a_n G_n + b_1 H_1 + b_2 H_2 + dots.c + b_n H_n + z Q. $
  Furthermore, the prover can show that $z = a_1 b_1 + a_2 b_2 + dots.c + a_n b_n$.
]

One corollary is that this lets us query arbitrary inner products of some commit, as follows:
1. Prover commits to some $(a_1, a_2, dots, a_n)$ with respect to some basis $(G_1, G_2, dots, G_n)$, and sends the commitment $C = a_1 G_1 + a_2 G_2 + dots.c + a_n G_n$ to the verifier.
2. Verifier extends the basis to $(G_1, G_2, dots, G_n, H_1, H_2, dots, H_n, Q)$ and sends the rest of the basis to the prover, along with some query $(b_1, b_2, dots, b_n)$ to the prover.
3. Prover computes $z = a_1 b_1 + a_2 b_2 + dots.c + a_n b_n$ (and sends it to the verifier), and shows that $C' = C + b_1 H_1 + b_2 H_2 + dots.c + b_n H_n + z Q$ is in the desired format from IPA.
In particular, note that in step 3, the verifier can compute $C'$ themselves and make sure it is the correct $C'$ being argued in the IPA.
We thus have:

#proposition[
  There exists a protocol that runs in $O(n)$ verifier time, which lets the verifier get the value of $a dot b$ for some commited $a$.
  The proof size can be made to take $O(log n)$ space with Fiat-Shamir.
] <dot_product>

By doing the following with $b = e_i$ for some standard basis vector $e_i$, we have the following:

#corollary[
  There exists a protocol that runs in $O(n)$ verifier time (and $O(log n)$ space with Fiat-Shamir)
  that reveals 
]

== Basic Primitives

We also have the following:

#theorem[
  Suppose $C$ is the Pedersen commitment of $(a_1, a_2, dots, a_n)$ with respect to some basis 
  $(G_1, G_2, dots, G_n)$.
  Then, there exists a protocol that lets the prover show that some public $C'$ can be written in the form $C' = a_1 H_1 + dots.c + a_n H_n$, where $(H_1, H_2, dots, H_n)$ are #emph("any") publicly known elements of $E$ (in particular, they may have known linear combinations).
  This protocol requires $O(n)$ verifier work.
] <check_vector>

Before describing the protocol, we first need the following gadget:

#lemma[
  Suppose $C$, $C'$ are publicly known commitments with respect to $(G_1, G_2, dots, G_n)$ and $(H_1, H_2, dots, H_n)$, respectively, where, $(G_i)$ and $(H_i)$ are bases, but can overlap (in particular, they are not required to be linearly independent of each other).
  Then, it is possible to check, in $O(n)$ verifier time complexity, that $C$ and $C'$ are commitments of the same vector.
] <change_basis>

#proof[
  Suppose that $C$ is the commitment of $a = (a_1, a_2, dots, a_n)$, and $C'$ is the commitment 
  of $b = (b_1, b_2, dots, b_n)$
  
  The verifier picks a random challenge $lambda = (lambda_1, lambda_2, dots, lambda_n) in FF_p^n$, 
  and sends it to the prover.
  The prover then computes $a dot lambda$ and $b dot lambda$ with IPA (see @dot_product).
  If $a$ and $b$ are not the same, this passes with probability $p^(-1)$.
]

Now we are ready to prove @check_vector.

#proof([of @check_vector])[
  The verifier picks some random challenge $mu in FF_p$, 
  and computes $C'' = C + mu C'$.
  If $C = a_1 G_1 + a_2 G_2 + dots + a_n G_n$, and $C' = a_1 H_1 + a_2 H_2 + dots + a_n H_n$, 
  then $ C'' = a_1(G_1 + mu H_1) + a_2 (G_2 + mu H_2) + dots.c + a_n (G_n + mu H_n). $
  Now, for randomly chosen $mu$, we also have that $(G_1 + mu H_1, G_2 + mu H_2, dots, G_n + mu H_n)$
  have no known linear dependencies, so we can use @change_basis on $C$ and $C''$.
]

We also have the following extension of @change_basis:

#lemma[
  Suppose $C$ and $C'$ are publicly known commitments of $a = (a_1, a_2, dots, a_n)$ and $b = (b_1, b_2, dots, b_n)$ with respect to the bases $(G_1, G_2, dots, G_n)$ and $(H_1, H_2, dots, H_n)$ (again, the bases $(G_i)$ and $(H_i)$ can have dependencies).
  Then, there exists a protocol with $O(n)$ verifier time complexity that checks that $a = b dot.circle c$, where $c$ is some publicly known vector.
] <check_public_hadamard>

#proof[
  The idea is for the verifier to pick a random challenge $lambda in FF_p^n$ and then to check that 
  $ a dot lambda = (b dot.circle c) dot lambda <=> a dot lambda = b dot (c dot.circle lambda). $
  Since $c$ is publicly known, we can run @dot_product to reveal the values of both $a dot lambda$ and $b dot (c dot.circle lambda)$.
]

== Towards R1CS

In this section, we will describe the following protocols:

#proposition[
  There exists a protocol that can, for some commitments $C$ and $C'$ with respect to publicly known bases $(G_1, G_2, dots, G_n)$ and $(H_1, H_2, dots, H_n)$, can show that $C = x_1 G_1 + x_2 G_2 + dots.c + x_n G_n$ and $C' = y_1 H_1 + y_2 H_2 + dots.c + y_n H_n$, and that $y = M x$, where $M$ is a publicly known square matrix.
  This computation takes $O(n^2)$ verifier time, though it can be made to take $O(n^2)$ preprocessing and $O(n)$ per proof.
] <matrix_by_vector>

#proposition[
  There exists a protocol, that, for some commitments $C_a, C_b, C_c$ with respect to publicly known bases, can show that the commitments are with respect to $a$, $b$, $c$, respectively, satisfying $c = a dot.circle b$.
] <hadamard_commit>

To see how we can turn this into an R1CS system, suppose we have some problem $(A x) dot.circle (B x) = C x$, and we wish to show that the prover has a solution $x$ to this system.
We can do the following:
1. Prover commits to $C_x$ with respect to some basis.
2. Prover provides commitments $C_(A x), C_(B x)$, and $C_(C x)$, and uses @matrix_by_vector to show that $C_(A x)$ is indeed the multiplication of $x$ by $A$ (and similarly for $C_(B x)$ and $C_(C x)$).
3. Prover shows that $C_(A x)$, $C_(B x)$ are commitments of vectors whose Hadamard product is the preimage of $C_(C x)$, using @hadamard_commit.

This implies the following:

#theorem[
  There exists a proof system (implementing R1CS) using IPA, such that each proof takes linear time for the verifier (though with $O(n^2)$ preprocessing time).
]

Now, we describe how to prove the propositions.

#proof([of @matrix_by_vector])[
  Note that we have 
  $ y_i = M_(i, 1) x_1 + M_(i, 2) x_2 + dots.c + M_(i, n) x_n. $
  So, if $C' = y_1 H_1 + y_2 H_2 + dots + y_n H_n$, we must have 
  $ C' = sum_(i=1)^n sum_(j=1)^n M_(i, j) x_j H_i = sum_(j=1)^n x_j sum_(i=1)^n M_(i, j) H_i. $
  So, letting $T_j = sum_(i=1)^n M_(i, j) H_i$, we see that we require $C' = x_1 T_1 + x_2 T_2 + dots.c + x_n T_n$.
  This can be done with @check_vector.
]

#proof([of @hadamard_commit])[
  As usual, our general proof strategy will be for the verifier to generate random $lambda$, and then 
  the prover will show that $(a dot.circle b) dot lambda = c dot lambda$.
  The prover can reveal $t = c dot lambda$ (this is just @dot_product), 
  so it remains to show that the prover can show that $(a dot.circle b) dot lambda = t$.

  Note that $(a dot.circle b) dot lambda = a dot (b dot.circle lambda)$.
  So, we can do the following: For some basis $(G_1, G_2, dots, G_n, H_1, H_2, dots, H_n, Q)$, 
  the verifier performs the following proofs:
  1. $C = a_1 G_1 + a_2 G_2 + dots + a_n G_n$ is the commitment of the same vector as $C_a$.
  2. $C' = v_1 H_1 + v_2 H_2 + dots + v_n H_n$ is the commitment of some vector $v$ satisfying $v = b dot.circle lambda$ (using @check_public_hadamard).
  3. $C + C' + t Q$ satisfies the IPA condition.
  This shows that $t = a dot v = (a dot.circle b) dot lambda$.
]




