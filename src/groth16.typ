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

== Interpolation

The basic idea of Groth16 is to interpolate polynomials 
through the coefficients of the $m$ equations,
then work with KZG commitments to these polynomials.
(This is sort of the opposite of the interpolation in PLONK (@plonk),
where we interpolate
a polynomial through Peggy's solution $(a_0, ..., a_n)$.)

Interpolate polynomials $U_i, V_i, W_i$ such that
$
  U_i (q) & = u_(i, q) \
  V_i (q) & = v_(i, q) \
  W_i (q) & = w_(i, q)
$
for $1 lt.eq q lt.eq m$.
In this notation, we want to show that
$ (sum_(i=0)^n a_i U_i (q)) (sum_(i=0)^n a_i V_i(q))
  = (sum_(i=0)^n a_i W_i(q)),$
for $q = 1, dots, m$.
This is the same as showing that there exists some polynomial $H$
such that
$ (sum_(i=0)^n a_i U_i (X)) (sum_(i=0)^n a_i V_i(X))
  = (sum_(i=0)^n a_i W_i(X)) + H(x)T(x), $
where
$ T(x) = (x-1)(x-2) dots (x-m). $

The proof that Peggy sends to Victor will take the form of
a handful of KZG commitments.
As a first idea (we'll have to build on this afterwards),
let's have Peggy send KZG commitments
$ Com( sum a_i U_i ) $
$ Com( sum a_i V_i ) $
$ Com( sum a_i W_i ) $
$ Com( H T ). $
Recall from @kzg that the Kate commitment $Com( F )$ to a polynomial
$F$ is just the elliptic curve point $[F(s)]$.
Here $s$ is some field element whose value nobody knows,
but a handful of small powers $[1], [s], [s^2], dots$
are known from the trusted setup.

The problem here is for Peggy to convince Victor that these four group elements,
supposedly $ Com( sum a_i U_i ) $ and so forth, are well-formed.
For example, Peggy needs to show that $ Com( sum a_i U_i ) $ 
is a linear combination of the KZG commitments $Com(U_i)$,
that $ Com( sum a_i V_i ) $
is a linear combination of the KZG commitments $Com(V_i)$,
and that the two linear combinations use the same coefficients $a_i$.

== Proving claims about linear combinations

We've already come across this sort of challenge
in the setting of IPA (@ipa),
but Groth16 uses a different approach,
so let's get back to a simple toy example.

#example[
  Suppose there are publicly known group elements
  $ Com(U_1), Com(U_2), dots, Com(U_n). $
  Suppose Peggy has another group element $g$, 
  and she wants to show that $g$ has the form
  $ g = a_0 + sum_(i=1)^n a_i Com(U_i), $
  where the $a_i$'s are constants Peggy knows.

  Groth's solution to this problem
  uses a _trusted setup_ phase, as follows.

  Before the protocol runs, Trent (our trusted setup agent)
  chooses a nonzero field element $gamma$ at random
  and publishes:
  $ [gamma], Com(U_1), Com(gamma U_1), Com(U_2), Com(gamma U_2),
  dots, Com(U_n), Com(gamma U_n). $
  Trent then throws away $gamma$.

  Peggy now sends to Victor
  $ g = [a_0] + sum_(i=1)^n a_i Com(U_i) $
  and
  $ h = gamma g = a_0 [gamma] + sum_(i=1)^n a_i Com(gamma U_i). $
  
  Victor can verify that
  $ pair(g, [gamma]) = pair( h, [1] ), $
  which shows that the element Peggy said was $gamma g$
  is in fact $gamma$ times the element $g$.

  But Peggy does not know $gamma$!
  So (assuming, as usual, that the discrete logarithm problem is hard),
  the only way Peggy can find elements 
  $g$ and $h$ such that $h = gamma g$
  is to use the commitments Trent released in trusted setup.
  In other words,
  $g$ must be a linear combination of 
  the elements $[1], Com(U_1), dots, Com(U_n),$
  which Peggy knows how to multiply by $gamma$, 
  and $h$ must be the same linear combination
  of $[gamma], Com(gamma U_1), dots, Com(gamma U_n)$.
]

#example[
  Here's a more complicated challenge,
  on the way to building up the Groth16 protocol.

  Suppose there are publicly known group elements
  $ Com(U_1), Com(U_2), dots, Com(U_n) $
  and
  $ Com(V_1), Com(V_2), dots, Com(V_n). $
  Peggy wants to publish 
  $ g_1 = sum_(i=1)^n a_i Com(U_i) $
  and
  $ g_2 = sum_(i=1)^n a_i Com(V_i), $
  and prove to Victor that these two group elements
  have the desired form
  (in particular, with the same coefficients $a_i$
  used for both).

  To do this, Trent does the same trusted setup thing.
  Trent chooses two constants $alpha$ and $beta$
  and publishes
  $ alpha Com(U_i) + beta Com(V_i), $
  for $1 lt.eq i lt.eq n$.

  

]

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

Trent (who is doing the trusted setup) then selects a secret $gamma in FF_p$
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
a polynomial through Peggy's solution $(a_0, ..., a_n)$.
The previous interpolations of $U_i (X)$, $V_i (X)$, $W_i (X)$ are good enough.

Let's summarize what we have up to here.
Peggy is trying to prove to Victor that she knows $(a_0, ..., a_n) in FF_p$
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
