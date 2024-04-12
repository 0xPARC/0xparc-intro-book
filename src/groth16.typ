#import "preamble.typ":*

= Groth16, another zkSNARK protocol <groth16>

#todo[rough, based on Aard's lecture. needs cleanup.]

Like PLONK, Groth16 is a protocol for quadratic equations,
as we described in @arith-intro.
For Groth16, the format of the equations is in so-called _R1CS format_.

== Input format

To describe the technical specification of the input format,
we call the variables $a_0 = 1$, $a_1$, ..., $a_n$.
The $q$'th equation takes the form
$ (sum_(i=0)^n u_(i,q) a_i) (sum_(i=0)^n v_(i,q) a_i)
  = (sum_(i=0)^n a_i w_(i,q)) $
for $1 <= q <= m$, where $m$ is the number of equations.
(In other words, we require the quadratic part of each equation to factor.
The $a_0 = 1$ term is a dummy variable that simplifies notation
so that we don't need to write the constant terms separately.)

The inputs are divided into two categories:

- ($a_0$), $a_1$, ..., $a_ell$ are _public inputs_; and
- $a_(ell+1)$, $a_1$, ..., $a_n$ are _private inputs_.

#todo[Deal with trusted setup]

== Trusted setup

We start with the same secret setup as the KZG commitment scheme.
That is, we have a fixed pairing $"pair" : E times E -> ZZ slash N ZZ$
and a secret scalar $s in FF_p$.
The trusted setup is as before: $s$ is kept secret from everyone,
but the numbers $[1]$, $[s]$, ..., up to $[s^(2m)]$ are published.

However, for this protocol requires additional setup
that actually depends on the system of equations (unlike in the KZG situation in
@kzg, in which trusted setups is done for the curve $E$ itself
and afterwards can be freely reused for any situation needing a KZG commitment.)

Specifically, let's interpolate polynomials $U$, $V$, $W$
through the coefficients of our R1CS system;
that is we have $U_i (X), V_i (X), W_i (X) in FF_p [X]$ such that
$ U_i (q) = u_(i,q), #h(1em) V_i (q) = v_(i,q), #h(1em) W_i (q) = w_(i,q). $

Whoever is doing the trusted setup then selects a secret $gamma in FF_p$
and publishes all of the following points on $E$:
$ [gamma],
  #h(1em) [(U_i (s)) / gamma],
  #h(1em) [(V_i (s)) / gamma],
  #h(1em) [(W_i (s)) / gamma] $
for all $1 <= i <= n$.
Finally, there are two more secrets scalars $alpha, beta in FF_p$
chosen during trusted setup; Trent publishes
$ [alpha], #h(1em) [beta], #h(1em)
  [beta U_i (s) + alpha V_i (s) + W_i (s)] $
for all $1 <= i <= n$.
We'll explain later what these three additional secrets are used for.

Note that this means this setup needs to be done _for each system of equations_.
That is, if you are running Groth16 and you change the system,
the trusted setup with $gamma$ needs to be redone.

This might make the protocol seems limited.
On the other hand, for practical purposes,
one can imagine a really general system of equations

#todo[SHA example]

== Interpolation

Unlike with PLONK, we're _not_ going to interpolate
a polynomial through Penny's solution $(a_0, ..., a_n)$.
The previous interpolations of $U_i (X)$, $V_i (X)$, $W_i (X)$ are good enough.

Let's summarize what we have up to here.
Penny is trying to prove to Victor that she knows $(a_0, ..., a_n) in FF_p$
such that the identity
$ (sum_(i=0)^n a_i U_i (X) ) (sum_(i=0)^n a_i V_i (X) )
  = (sum_(i=0)^n a_i W_i (X)) $
holds for all $X = 1, 2, ..., m$.
We can rephrase this a polynomial divisibility,
where we want the difference between the left-hand side and the right-hand side
to be divisible by the polynomial $T(X) := (X-1)(X-2) ... (X-m)$.

We are hoping that there exists $H in FF_p [X]$ such that
$ (sum_(i=0)^n a_i U_i (X) ) (sum_(i=0)^n a_i V_i (X) )
  = (sum_(i=0)^n a_i W_i (X)) + H(X) T(X) $
where $T(X) = (X-1)(X-2) ... (X-q)$.
