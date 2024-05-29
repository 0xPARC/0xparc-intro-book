#import "preamble.typ":*

= Groth16, another zkSNARK protocol <groth16>

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
a polynomial through Peggy's solution $(a_0, ..., a_n)$.
Philosophically, you might also think of this as verifying a 
random linear combination of the $m$ equations --
where the coefficients of the random linear combination
are determined by the unknown secret $s$ from the KZG protocol.)

Interpolate polynomials $U_i, V_i, W_i$ such that
$
  U_i (q) & = u_(i, q) \
  V_i (q) & = v_(i, q) \
  W_i (q) & = w_(i, q)
$
for $1 lt.eq q lt.eq m$.
In this notation, we want to show that
$ (sum_(i=0)^n a_i U_i (q)) (sum_(i=0)^n a_i V_i(q))
  = (sum_(i=0)^n a_i W_i(q)), $
for $q = 1, dots, m$.
This is the same as showing that there exists some polynomial $H$
such that
$ (sum_(i=0)^n a_i U_i (X)) (sum_(i=0)^n a_i V_i (X))
  = (sum_(i=0)^n a_i W_i (X)) + H(X)T(X), $
where
$ T(X) = (X-1)(X-2) dots (X-m). $

The proof that Peggy sends to Victor will take the form of
a handful of KZG commitments.
As a first idea (we'll have to build on this afterwards),
let's have Peggy send KZG commitments
$ Com( sum_(i=0)^n a_i U_i ), #h(1em) Com( sum_(i=0)^n a_i V_i ), #h(1em) Com( sum_(i=0)^n a_i W_i ), #h(1em) Com( H T ). $
Recall from @kzg that the Kate commitment $Com( F )$ to a polynomial
$F$ is just the elliptic curve point $[F(s)]$.
Here $s$ is some field element whose value nobody knows,
but a handful of small powers $[1], [s], [s^2], dots,$
are known from the trusted setup.

The problem here is for Peggy to convince Victor that these four group elements,
supposedly $ Com( sum_(i=0)^n a_i U_i ) $ and so forth, are well-formed.
For example, Peggy needs to show that $ Com( sum_(i=0)^n a_i U_i ) $ 
is a linear combination of the KZG commitments $Com(U_i)$,
that $ Com( sum_(i=0)^n a_i V_i ) $
is a linear combination of the KZG commitments $Com(V_i)$,
and that the two linear combinations use the same coefficients $a_i$.
How can Peggy prove this sort of claim?

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
  chooses a nonzero field element $delta$ at random
  and publishes:
  $ [delta], Com(U_1), Com(delta U_1), Com(U_2), Com(delta U_2),
  dots, Com(U_n), Com(delta U_n). $
  Trent then throws away $delta$.

  Peggy now sends to Victor
  $ g = [a_0] + sum_(i=1)^n a_i Com(U_i) $
  and
  $ h = delta g = a_0 [delta] + sum_(i=1)^n a_i Com(delta U_i). $
  
  Victor can verify that
  $ pair(g, [delta]) = pair( h, [1] ), $
  which shows that the element Peggy said was $delta g$
  is in fact $delta$ times the element $g$.

  But Peggy does not know $delta$!
  So (assuming, as usual, that the discrete logarithm problem is hard),
  the only way Peggy can find elements 
  $g$ and $h$ such that $h = delta g$
  is to use the commitments Trent released in trusted setup.
  In other words,
  $g$ must be a linear combination of 
  the elements $[1], Com(U_1), dots, Com(U_n),$
  which Peggy knows how to multiply by $delta$, 
  and $h$ must be the same linear combination
  of $[delta], Com(delta U_1), dots, Com(delta U_n)$.
] <groth-motiv-1>

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
  and publishes $[alpha]$, $[beta]$, and
  $ alpha Com(U_i) + beta Com(V_i), $
  for $1 lt.eq i lt.eq n$.

  In addition to $g_1$ and $g_2$,
  Peggy now also publishes
  $ h = sum_(i=1)^n a_i (alpha Com(U_i) + beta Com(V_i) ). $
  Victor needs to verify that
  $ h = alpha g_1 + beta g_2; $
  if this equality holds, then $g_1$ and $g_2$ must
  have the correct form,
  just like in @groth-motiv-1.

  So Victor checks the equality of pairings
  $ pair(h, [1]) = pair(g_1, [alpha]) + pair(g_2, [beta]), $
  and the proof is complete.
] <groth-motiv-2>

== The protocol 

Armed with @groth-motiv-1 and @groth-motiv-2,
it's not hard to turn our vague idea from earlier
into a full protocol.
This protocol won't be zero-knowledge --
to make it zero-knowledge, we would have to throw in
an extra "blinding" term,
which just adds an additional layer of complication
on top of the whole thing.
If you want to see the full ZK version,
check out #link("https://eprint.iacr.org/2016/260.pdf")[Groth's original paper].

=== Trusted setup

We start with the same secret setup as the KZG commitment scheme.
That is, we have a fixed pairing $"pair" : E times E -> ZZ slash N ZZ$
and a secret scalar $s in FF_p$.
The trusted setup is as before: $s$ is kept secret from everyone,
but the numbers $[1]$, $[s]$, ..., up to $[s^(2m)]$ are published.

However,  this protocol requires additional setup
that actually depends on the system of equations (unlike in the KZG situation in
@kzg, in which trusted setup is done for the curve $E$ itself
and afterwards can be freely reused for any situation needing a KZG commitment.)

Specifically, let's interpolate polynomials $U$, $V$, $W$
through the coefficients of our R1CS system;
that is we have $U_i (X), V_i (X), W_i (X) in FF_p [X]$ such that
$ U_i (q) = u_(i,q), #h(1em) V_i (q) = v_(i,q), #h(1em) W_i (q) = w_(i,q). $

So far we have ignored the issue of public inputs.
The values $a_0, a_1, dots, a_ell$ will be public inputs to the circuit,
so both Peggy and Victor know their values,
and Victor has to be able to verify that they were assigned correctly.
The remaining values $a_(ell+1), dots, a_n$ 
will be private.

Trent (who is doing the trusted setup) then selects secrets 
$alpha, beta, delta, epsilon in FF_p$
and publishes all of the following points on $E$:
$ [alpha], [beta], [delta], [epsilon], \
  #h(1em) [(beta U_i (s) + alpha V_i (s) + W_i (s)) / delta] text("for") ell lt i lt.eq m,
  #h(1em) [(x^i T(s)) / epsilon] text("for") 0 lt.eq i lt.eq n-2.
$

Note that this means this setup needs to be done _for each system of equations_.
That is, if you are running Groth16 and you change the system,
the trusted setup with $delta$ needs to be redone.

This might make the protocol seem limited.
On the other hand, for practical purposes,
one can imagine that Peggy has 
a really general system of equations
that she wants to prove many solutions for.
In this case, Trent can run the trusted setup just once,
and once the setup is done there is no additional cost.

#example[
  In practice, one often wants to prove a computation of a hash function:
  $ op("sha")(M) = H. $
  When you convert this into a system of quadratic equations
  for PLONK or Groth16,
  both $M$ and $H$ will be public inputs to the system.
  The equations themselves will depend only on the 
  details of the hash function $op("sha")$.
  
  In this case, a single trusted setup can be used 
  to prove the hash of any message.
]

=== The protocol (not optimized)

+ Peggy now sends to Victor:
  $ A = [sum_(i=0)^n a_i U_i (s)], #h(1em) B = [sum_(i=0)^n a_i V_i (s)], #h(1em) C = [sum_(i=0)^n a_i W_i (s)], \
  D = [sum_(i=ell+1)^n a_i (beta U_i (s) + alpha V_i (s) + W_i (s)) / delta], \
  E = [H(s)], #h(1em) F = [H(s) T(s) / epsilon]. $

+ Victor additionally computes
  $ D_0 = [sum_(i=1)^ell (beta U_i (s) + alpha V_i (s) + W_i (s))] $
  and
  $ G = [T(s)] $
  based on publicly known information.

+ Victor verifies the pairings
  $ pair( [delta], D ) + pair( [1], D_0 ) = pair( [beta], A ) + pair( [alpha], B ) + pair( [1], C ). $

  This pairing shows that $ delta D + D_0 = beta A + alpha B + C. $
  Now just like in @groth-motiv-1,
  the only way that Peggy could possibly find two group elements $g$ and $h$
  such that $delta g = h$
  is if $g$ is a linear combination of terms
  $[(beta U_i (s) + alpha V_i (s) + W_i (s)) / delta]$.
  So we have verified that
  $
    D = [sum_(i=ell+1)^n a_i (beta U_i (s) + alpha V_i (s) + W_i (s)) / delta]
  $
  for some constants $a_i$, which implies
  $
    beta A + alpha B + C = [sum_(i=0)^n a_i (beta U_i (s) + alpha V_i (s) + W_i (s))].
  $
  And just like in @groth-motiv-2,
  since $alpha$ and $beta$ are unknown,
  the only way an equality like this can hold is if
  $ A = [sum_(i=0)^n a_i U_i (s)], #h(1em) B = [sum_(i=0)^n a_i V_i (s)], #h(1em) C = [sum_(i=0)^n a_i W_i (s)], $
  where $a_i$ is equal to the public input for $i lt.eq ell$
  (because Victor computed $D_0$ himself!)
  and $a_i$ is equal to some fixed unknown value for $i gt ell$.

+ Victor verifies that
  $  pair( [epsilon], F ) = pair( E, G ). $
  Again like in @groth-motiv-1, since $epsilon$ is unknown,
  this shows that $F$ has the form
  $ [(H(s) T(s)) / epsilon], $
  where $H$ is a polynomial of degree at most $n-2$.
  Since $G = [T(s)] $ (Victor knows this because he computed it himself),
  we learn that $E = [H(s)]$ is a KZG commitment to a polynomial
  whose coefficients Peggy knows.

+ Finally, Victor verifies that
  $ pair(A, B) = pair( [1], C ) + pair(E, G). $
  At this point, Victor already knows that $A$, $B$, $C$, $E$, $H$
  have the correct form, so this last pairing check 
  convinces Victor of the key equality,
  $ (sum_(i=0)^n a_i U_i (X)) (sum_(i=0)^n a_i V_i(X))
    = (sum_(i=0)^n a_i W_i(X)) + H(x)T(x). $
  The proof is complete.

=== Optimizing the protocol

The protocol above can be optimized further.
We didn't optimize it because we wanted it to be easier to understand.

In our protocol, the proof length is 6 group elements
(Peggy sends Victor $A, B, C, D, E, F$),
and Victor has to compute 8 elliptic curve pairings to verify the proof.
Additionally, Victor has to do $O(ell)$ group operations
to compute $D_0$ depending on the public input.

It turns out that, by cleverly combining multiple verifications into one,
you can get away with a proof length of just 3 group elements,
and verifier work of just 3 elliptic curve pairings 
(plus the same $O(ell)$ group operations).

Additionally, we didn't make the protocol zero-knowledge.
This requires the addition of a blinding factor.
Incredibly, Groth manages to take care of the blinding factor
in the 3-element proof as well.

The fully optimized protocol
is in #link("https://eprint.iacr.org/2016/260.pdf")[Groth's paper].
