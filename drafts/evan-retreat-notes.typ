#import "@local/evan:1.0.0":*

#show: evan.with(
  title: "Notes from 0xPARC Retreat",
  subtitle: none,
  author: "Evan Chen",
  date: datetime.today(),
)

#toc

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

Suppose Penny and Victor have a finite simple graph $G = (V,E)$ on $n$ vertices
and want to count the number of triangles in it.
Victor can count this in $O(n^3)$ time, but that's a lot of work.
We'd like to have Penny provide a proof to Victor that Victor can check in less time.
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
This requires some work from Penny, but for Victor,
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
Now Penny wants to convince Victor that
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
