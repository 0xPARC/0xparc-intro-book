#import "@local/evan:1.0.0":*

#show: evan.with(
  title: "Notes from 0xPARC Retreat",
  subtitle: none,
  author: "Evan Chen",
  date: datetime.today(),
)

#toc

= Commitment schemes

== Discrete logarithm is hard

=== The discrete log problem

Let $E$ be an elliptic curve.
Given arbitrary nonzero $g, g' in E$,
it's hard to find $n$ such that $n dot g = g'$.

In other words, if one only
sees $g in E$ and $n dot g in E$, one cannot find $n$.

(This is called discrete log because when $E$ is replaced by an abelian group
written multiplicatively, it looks like solving $g^n = g'$ instead.
We will never use this multiplicative notation.)

=== Vectors

One upshot of this is that if $g_1, ..., g_m in E$ are a bunch of points,
then it's infeasible to find
$(a_1, ..., a_m) != (b_1, ..., b_m) in ZZ^m$ such that
$ a_1 g_1 + ... + a_m g_m = b_1 g_1 + ... + b_m g_m. $
Indeed, even if one fixes any choice of $2m-1$ of the $2m$ coefficients above,
one cannot find the last coefficient.

In these notes, if there's a globally known elliptic curve $E$
and points $g_1, ..., g_n$ with no known dependencies between them,
we'll say they're "practically independent".

=== Petersen commitments

Let $g_1, ..., g_n in E$ be "practically independent".
If one has a vector $angle.l a_1, ..., a_n angle.r in FF_p^n$ of scalars,
one can "commit" the vector by sending $sum a_i g_i in E$.
This actually acts like a hash of the vector with shorter length
(with "practically independent" now being phrased as
"we can't find a collision").

It turns out the Petersen commitment will work natively with IPA later on.

== Kate commitment

=== Elliptic curve setup

==== Generator

We fix an elliptic curve $E$ over a finite field $FF_q$
and a globally known generator $g in E$.
For $n in ZZ$ define
$ [n] := n dot g. $
The hardness of discrete logarithm means that, given $[n]$, we cannot get $n$.
You can almost think of the notation as an "armor" on the integer $n$:
it conceals the integer, but still allows us to perform (armored) addition:
$ [a+b] = [a] + [b]. $
Multiplication can't be done directly, in the sense there isn't a way to get
$[a b]$ given $[a]$ and $[b]$.
However, the _pairing_ on the elliptic curve allows us to sidestep this by
defining a nondegenerate bilinear function
$ e : E times E -> ZZ slash N ZZ $
for some large $N$.
(This seems to be most commonly done via the Weil pairing.
It may require replacing $FF_q$ with $FF_(q^n)$ or something?
I'm unsure of the details.)

==== Trusted calculation

To set up the Kate commitment scheme,
a trusted computer needs to pick a secret scalar $s in FF_p$ and publishes
$ [s^0], [s^1], ..., [s^N] $
for some large $N$.
(This only needs to be done once for the curve $E$.)
These published points are considered globally known
so anyone can evaluate $[P(s)]$ for any given polynomial $P$.
(For example, $[s^2+8s+6] = [s^2] + 8[s] + 6[1]$.)
Meanwhile, the secret scalar $s$ is never revealed to anyone.

=== Commitment scheme

==== Protocol

Suppose Peggy has a polynomial $P(T) in FF_p [T]$.
She commits to it by evaluating $[P(s)]$,
which she may do because $[s^i]$ is globally known.

Now consider an input $x in FF_p$,
where Peggy wishes to convince Victor that $P(z) = y$.
To show $y in FF_p$, Peggy does polynomial division to derive $Q$ such that
$ P(T)-y = (T-z) Q(T) $
and sends the value of $[Q(s)]$,
which again she can compute (without knowing $s$)
from the globally known trusted calculation.

Victor then verifies by checking
$ e([Q(s)], [s-z]) = e([P(s)-y], [1]). $

==== Soundness (heuristic argument)

If $y != P(z)$, then Peggy can't do the polynomial long division described above.
So to cheat Victor, she needs to otherwise find an element
$ 1/(s-x) ([P(s)]-[y]) in E. $
Since $s$ is a secret nobody knows, there isn't any known way to do this.

== IPA stuff

Let $E$ be an elliptic curve over $FF_p$
and we have fixed globally known generators
$g_1, ..., g_n, h_1, ..., h_n, u in E$ which are "practically independent".

=== Goal of Inner Product Argument

As we mentioned before, an element of the form
$ a_1 g_1 + ... + a_n g_n + b_1 h_1 + ... + b_n h_n + c u in E $
where $a_1, ..., a_n, b_1, ..., b_n, c in FF_p$,
is practically a vector of length $2n + 1$, as discussed earlier.
(If you like terminology, it's a Petersen commitment of such a vector.)

#definition[
  Let's say that an element
  $ v = a_1 g_1 + ... + a_n g_n + b_1 h_1 + ... + b_n h_n + c u in E $
  is *good* if $sum_1^n a_i b_i = c$.
]

The Inner Product Argument (IPA) is a protocol that kind of
resembles Sum-Check in spirit: Penny and Victor will do a series of interactions
which allow Peggy to prove to Victor that $v$ is good
(without having to reveal all $a_i$'s, $b_i$'s, and $c$).

(I think we missed a chance to call this "Inner Product Interactive Proof
Inductive Protocol" or something cute like this,
but I'm late to the party.)

=== The interactive induction of IPA

The way IPA is done is by induction:
one reduces verifying a vector for $n$ is good (hence $2n+1$ length)
by verifying a vector for $n/2$ is good (of length $n+1$).
The base case $n=1$ (with three basis elements $g_1$, $h_1$, $u$) is straightforward:
Victor simply demands from Peggy the values of $a_1$ and $b_1$
and verifies $v = a_1 g_1 + b_1 h_1 + a_1 b_1 u$.

Now, to illustrate the induction, we'll first show how to get from $n=2$ to $n=1$.
So the given input to the protocol is
$ v = a_1 g_1 + a_2 g_2 + b_1 h_1 + b_2 h_2 + c u $
which has the basis $angle.l g_1, g_2, h_1, h_2, u angle.r$.
The idea is that we want to construct a new (good) vector $w$ whose basis is
$ angle.l (g_1 + x^(-1) g_2), (h_1 + x h_2), u angle.r $
for a random $x in FF_p$.

The construction is the following vector:
$ w(x) &:= (a_1 + x a_2) dot underbrace((g_1 + x^(-1) g_2), "basis")
  + (b_1 + x^(-1) b_2) dot underbrace((h_1 + x h_2), "basis")
  + (a_1 + x a_2)(b_1 + x^(-1) b_2) underbrace(u, "basis"). $
Expanding and isolating the parts with $x$ and $x^(-1)$ gives
$ w(x)
  &= (a_1 g_1 + a_2 g_2 + b_1 h_1 + b_2 h_2 + c u) \
  &#h(1em) + x dot underbrace((a_2 g_1 + b_1 h_2 + a_2 b_1 u), =: w_L)
  + x^(-1) dot underbrace((a_1 g_2 + b_2 h_1 + a_1 b_2 u), =: w_R) \
  &= v + x dot w_L + x^(-1) dot w_R.
  $
Note that, importantly, $w_L$ and $w_R$ don't depend on $x$.
So this gives a way to provide a construction of a good vector $w$
of half the length (in the new basis) given a good vector $v$.

This suggests the following protocol: Peggy, who knows the $a_i$'s, computes
$w_L := a_2 g_1 + b_1 h_2 + a_2 b_1 u$ and $w_R := a_1 g_2 + b_2 h_1 + a_1 b_2 u$,
and sends those values to Victor (this doesn't depend on $x$).
Then Victor picks a random value of $x$ and defines
$ w(x) = v + x dot w_L + x^(-1) dot w_R. $
Assume Peggy is truthful and $v$ was indeed good with respect
to the original 5-element basis for $n=2$, the resulting $w(x)$
is good with respect to the smaller $3$-element basis for $n=1$.

The interesting part is soundness:

#claim[
  Suppose $v = a_1 g_1 + a_2 g_2 + b_1 h_1 + b_2 h_2 + c u$ is given.
  Assume further that Peggy can provide some $w_L, w_R in E$ in this basis such that
  $ w(x) := v + x dot w_L + x^(-1) dot w_R $
  is good for at least four values of $x$.

  Then all of the following statements must hold for this property to occur:
  - $w_L = a_2 g_1 + b_1 h_2 + a_2 b_1 u$,
  - $w_R = a_1 g_2 + b_2 h_1 + a_1 b_2 u$,
  - $c = a_1 b_1 + a_2 b_2$, i.e., $v$ is good.
]

#proof[
  At first, it might seem like a cheating prover has too many parameters
  they could play with to satisfy too few conditions.
  The trick is that $x$ is really like a formal variable,
  and even the requirement that $w(x)$ lies in the span of
  $ angle.l (g_1 + x^(-1) g_2), (h_1 + x h_2), u angle.r $
  is going to determine almost all the coefficients of $w_L$ and $w_R$.

  To be explicit, suppose a cheating prover tried to provide
  $ w_L &= ell_1 g_1 + ell_2 g_2 + ell_3 h_1 + ell_4 h_2 + ell_5 \
    w_R &= r_1 g_1 + r_2 g_2 + r_3 h_1 + r_4 h_2 + r_5. $
  Then we can compute
  $ w(x) &= v + x dot w_L + x^(-1) dot w_R \
    &= (a_1 + x ell_1 + x^(-1) r_1)g_1 + (a_2 + x ell_2 + x^(-1) r_2)g_2 \
    &+ (b_1 + x ell_3 + x^(-1) r_3)h_1 + (b_2 + x ell_4 + x^(-1) r_4)h_1 \
    &+ (c + x ell_5 + x^(-1) r_5)u. $
  In order to lie in the span we described, one needs the coefficient of $g_1$
  to be $x$ times the coefficient of $g_2$, that is
  $ x^(-1) r_1 + a_1 + x ell_1 = r_2 + x a_2 + x^2 ell_2. $
  Since this holds for more than three values of $x$,
  the two sides must actually be equal coefficient by coefficient.
  This means that $ell_1 = a_2$, $r_2 = a_1$, and $r_1 = ell_2 = 0$.
  In the same way, we get $ell_4 = b_1$, $r_3 = b_2$, and $ell_3 = r_4 = 0$.

  So just to lie inside the span,
  the cheating prover's hand is already forced for all the coefficients
  other than the $ell_5$ and $r_5$ in front of $u$.
  Then indeed the condition that $w(x)$ is good is that
  $ (a_1 + x a_2) (b_1 + x^(-1) b_2) = c + x ell_5 + x^(-1) r_5. $
  Comparing the constant coefficients we see that $c = a_1 b_1 + a_2 b_2$ as
  desired. (One also can recover $ell_5$ and $r_5$, but we never use this.)
]

So we've shown completeness and soundness for our protocol reducing $n=2$ to $n=1$.
The general situation is basically the same with more notation:
if $n = 6$, for example, and we have
$v = a_1 g_1 + ... + a_6 g_6 + b_1 h_1 + ... + b_6 h_6 + c u $
then we replace the length-thirteen basis with the length-seven one
$ angle.l
  g_1 + x^(-1) g_4,
  g_2 + x^(-1) g_5,
  g_3 + x^(-1) g_6,
  h_1 + x h_4,
  h_2 + x h_5,
  h_3 + x h_6,
  u
  angle.r $
and the relevant $w_L$ and $w_R$ are
$ w_L &= (a_4 g_1 + a_5 g_2 + a_6 g_3) + (b_1 h_4 + b_2 h_5 + b_3 h_6)
  + (a_1 b_4 + a_2 b_5 + a_3 b_6) u \
  w_R &= (a_1 g_4 + a_2 g_5 + a_3 g_6) + (b_4 h_1 + b_5 h_2 + b_6 h_3)
  + (a_4 b_1 + a_5 b_2 + a_6 b_3) u. $
And $w(x) = v + x dot w_L + x^(-1) dot w_R$ as before.

=== Using IPA for a polynomial commitment scheme

Suppose now $P(T) = sum a_i T^(i-1)$ is given polynomial.
Then Peggy could get a scheme resembling Kate commitments as follows:

- Peggy publishes Petersen commitment of the coefficients of $P$,
  that is $v = sum a_i g_i in E$.
- Suppose Victor wants to open the commitment at a value $z$,
  and Peggy asserts that $P(z) = y$.
- Victor picks a random constant $lambda in FF_p$.
- Both parties compute
  $ underbrace((a_1 g_1 + ... + a_n g_n), v)
  + (lambda z^0 h_1 + ... + lambda z^(n-1) h_n) + lambda y u $
  and run IPA on it.

When Peggy does a vanilla IPA, she can keep all $2n+1$ coefficients secret.
Here, Peggy is fine to reveal the latter $n+1$ numbers
(because they are just powers of $z$ and the claimed $y$)
as they don't leak any other information;
she still gets to keep her coefficients $a_n$ private from Victor.

The introduction of the hacked constant $c$ might be a bit of a surprise.
The reason is that without it, there is an amusing loophole that Peggy can exploit:
Peggy can pick the vector $v$ after all.
So suppose Peggy tries to swindle Victor by reporting
$v = a_1 g_1 + ... + a_n g_n - 10 u$ instead
of the honest $v = a_1 g_1 + ... + a_n g_n$.
Then, Peggy inflates all the values of $y$ she claims to Victor by $10$.
This would allow Peggy to cheat Victor into committing the polynomial $P$
but given any $z$ giving Victor the value of $P(z) + 10$  rather than $P(z)$.
The addition of the shift $lambda$ prevents this attack.

#pagebreak()

= Applications of sum-check (problem 3)

== Modification to the sum-check Evan did in his PCP write-up

In the sum-check I described for PCP,
I described how we took a function $f : {0,1}^n -> FF_q$ encoding $2^n$ values
and then interpolated a multilinear polynomial $P$ through them.
And then we needed an oracle that can evaluate $P$ at one point off the hypercube.

If you're trying to sum-check a bunch of truly arbitrary unrelated numbers,
and you don't have an oracle, then naturally it's a lost cause.
You can't just interpolate $P$ through your $2^n$ numbers as a "manual oracle",
because the work of interpolating the polynomial is just as expensive.

However, in real life, sum-check gives you leverage because of the ambient
context giving us a way to rope in polynomials.
For example, in PCP, the problem we were considering was QuadSAT.
Why is this a good choice? Well, the equations are already (quadratic) polynomials.
So even though we have to do _some_ interpolation
(namely, we interpolated both the claimed assignment
and the coefficients appearing in the Quad-SAT problem),
we could then collate the resulting polynomials together.

The point of problem 3 is to problem set shows two easier examples of this idea.

There is one note I should make here: $P$ does not
actually need to be multilinear for the sum-check protocol to work!
Suppose $P$ is degree at most $d$ in each variable.
Then during the protocol the degree of the intermediate polynomials
in the back-and-forth will be degree up to $d$.
So you don't want $d$ to be huge, but e.g. $d = 3$ is totally fine.

== Verifying a triangle count

Suppose Peggy and Victor have a finite simple graph $G = (V,E)$ on $n$ vertices
and want to count the number of triangles in it.
Victor can count this in $O(n^3)$ time, but that's a lot of work.
We'd like to have Peggy provide a proof to Victor that Victor can check in less time.
Victor will always need at least $O(n^2)$ time because he needs to read the
entire input; our protocol will require only $O(n^2 log n)$ time from Bob.

Assume for convenience $n = 2^m$ and biject $V$ to ${0,1}^m$.
Both parties then compute the coefficients of the multilinear function
$g : {0,1}^2m -> {0,1}$ defined by
$
  g(x_1, ..., x_m, y_1, ..., y_m)
  =
  cases(
    1 "if" (x_1, ..., x_m) "has an edge to" (y_1, ..., y_m),
    0 "otherwise".
  )
$
In general, this interpolation calculation takes
$O(2^(2m) dot 2m) = O(n^2 log n)$ time.

Once this is done, they set
$ f(arrow(x), arrow(y), arrow(z)) :=
  g(arrow(x), arrow(y)) g(arrow(y), arrow(z)) g(arrow(z), arrow(x)). $
they can just run the Sum-Check protocol on:
$ "number triangles"
  = sum_(arrow(x) in {0,1}^m) sum_(arrow(y) in {0,1}^m) sum_(arrow(z) in {0,1}^m)
  f(arrow(x), arrow(y), arrow(z)) $
This requires some work from Peggy, but for Victor,
the steps in between don't require much work.
The final oracle call requires Victor to evaluate
$ g(arrow(x), arrow(y)) g(arrow(y), arrow(z)) g(arrow(z), arrow(x)) $
for one random choice $(arrow(x), arrow(y), arrow(z)) in (FF_p^m)^(times 3)$.
Victor can do this because he's already computed all the coefficients of $g$.

(Note that Victor does NOT need to compute $f$ as a polynomial,
which is much more work.
Victor does need to compute coefficients of $g$ so that it can be
evaluated at three points.
But then Victor just multiplies those three numbers together.)

#remark[
  You could in principle check for counts of any
  more complicated subgraph as opposed to just $K_3$.
]

== Verifying a polynomial vanishes

Suppose $f(T_1, ..., T_n) in FF_q [T_1, ..., T_n]$
is a polynomial of degree up to $2$ in each variable,
specified by the coefficients.
Now Peggy wants to convince Victor that
$f(x_1, ..., x_n) = 0$ whenever $x_i in {0,1}$.

Of course, Victor could verify this himself by plugging in all $2^n$ pairs.
Because $f$ is the sum of $3^n$ terms, this takes about $6^n$ operations.
We'd like to get this down to a lot less using sum-check.

Victor can accomplish this with a random weighting.
Specifically, he picks a multilinear polynomial
$g(T_1, ..., T_n) in FF_q [T_1, ..., T_n]$
out of the $q^(2^n)$ possible multilinear polynomials.
Note that this is equivalent to picking the $2^n$ values of
$g(x_1, ..., x_n)$ for $(x_1, ..., x_n) in {0,1}^n$ uniformly at random.
Then we run sum-check to prove that

$ 0 = sum_(arrow(x) in {0,1}^n) f(x_1, ..., x_n) g(x_1, ..., x_n) $

The polynomial $f g$ is degree up to $3$ in each variable, so that's fine.
The final "oracle" call is then straightforward,
because the coefficients of both $f$ and $g$ are known;
it takes only $3^n + 2^n$ operations
(i.e. one evaluates two polynomials each at one point,
rather than $2^n$ evaluations).

= Oblivious transfer (problem 5)

== How to do oblivious transfer

Suppose Alice has $n$ keys, corresponding to elements $g_1, ..., g_n in E$.
Alice wants to send exactly one to Bob,
and Bob can pick which one, but doesn't want Alice to know which one he picked.
Here's how you do it:

1. Alice picks a secret scalar $a in FF_q$ and sends $a dot g_1$, ..., $a dot g_n$.
2. Bob picks the index $i$ corresponding to the key he wants and
  reads the value of $a dot g_i$, throwing away the other $n-1$ values.
3. Bob picks a secret scalar $b in FF_q$ and sends $b dot a dot g_i$ back.
4. Alice sends $1/a dot (b dot a dot g_i) = b dot g_i$ back to Bob.
5. Bob computes $1/b dot (b dot g_i) = g_i$.

== How to do 2-party AND computation

Suppose Alice and Bob have bits $a, b in {0,1}$.
They'd like to compute $a and b$ in such a way that if someone's bit was $0$,
they don't learn anything about the other person's bit.
(Of course, if $a=1$, then once Alice knows $a and b$ then Alice knows $b$ too,
and this is inevitable.)

This is actually surprisingly easy.
Alice knows there are only two cases for Bob,
so she puts the value of $a and 0$ into one envelope labeled "For Bob if $b=0$",
and the value of $a and 1$ into another envelope labeled "For Bob if $b=1$".
Then she uses oblivious transfer to send one of them.
Then Bob opens the envelope corresponding to the desired output.
Repeat in the other direction.

#remark[
  Stupid use case I made up: Alice and Bob want to determine whether
  they have a mutual crush on each other.
  (Specifically, let $a=1$ if Alice likes Bob and $0$ otherwise; define $b$ similarly.)
  Now we have a secure way to compute $a and b$.
]

== Chaining circuits

Suppose now that instead of a single bit,
Alice and Bob each have $1000$ bits.
They'd like to run a 2PC for function $f : {0,1}^2000 -> {0,1}$ together.

The above protocol would work, but it would be really inefficient:
it involves sending $2^1000$ envelopes each way.

However, in many real-life situations involving bits,
the function $f$ is actually given
by a _circuit_ with several AND, XOR, NOT gates or similar.
So we'll try to improve the $2^1000$ down to something that grows only linearly in
the number of gates in the circuit, rather than exponential in the input size.

Let $xor$ be binary XOR.

The idea is the following.
A normal circuit has a bunch of registers,
where the $i$th register just has a single bit $x_i$.
We'd like to instead end up in a situation where we get a pair of bits
$(a_i, b_i)$ such that $x_i = a_i xor b_i$,
where Alice can see $a_i$ but not $b_i$ and vice-versa.
This would let us do a 2PC for an arbitrarily complicated circuit.

It suffices to implement a single gate.
#lemma[
  Suppose $diamond : {0,1}^2 -> {0,1}$ is some fixed Boolean operator.
  Alice has two secret bits $a_1$ and $a_2$,
  while Bob has two secret bits $b_1$ and $b_2$.
  Then Alice and Bob can do use oblivious transfer to get $a_3$ and $b_3$ such that
  $a_3 xor b_3 = (a_1 xor b_1) diamond (a_2 xor b_2)$
  without revealing $a_3$ or $b_3$ to each other.
]
#proof[
  Alice picks $a_3 in {0,1}$ at random and prepares four envelopes
  for the four cases of $(b_1, b_2)$ describing what Bob should set $b_3$ as.
]
