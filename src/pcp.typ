#import "preamble.typ":*

= A toy PCP protocol

== Pitch: How to grade papers without reading them

Imagine that Penny has a long proof of some mathematical theorem, and Victor wants to verify it.
_A priori_, this would require Victor to actually read every line of the proof.
As anyone who has experience grading students knows, that's a whole lot of work.
A lazy grader might try to save time by only "spot checking"
a small number of lines of the proof.
However, it would be really easy to cheat such a grader:
all you have to do is make a single wrong step somewhere
and hope that particular step is not one of the ones examined by Victor.

A probabilistically checkable proof is a way to try to circumvent this issue.
It provides a protocol where Penny can format her proof such that
Victor can get high-probability confidence of its confidence
by only checking $K$ bits of the proof at random, for some absolute constant $K$.
This result is one part of the _PCP theorem_ which is super famous.

The section hopes to give a high level summary of the ideas that go into the
protocol and convince you that the result is possible,
because at first glance it seems absurd that a single universal constant $K$
is going to be enough.
Our toy protocol uses the following parts:

- Sum-check from the previous chapter.
- Low-degree testing theorem, which we'll just state the result but not prove.
- Statement of the Quad-SAT problem,
  which is the NP-complete problem which we'll be using for this post:
  an instance of Quad-SAT is a bunch of quadratic equations in multiple variables
  that one wants to find a solution to.

We'll staple everything to get a toy PCP protocol.
Finally, we'll give an improvement to it using error-correcting codes.

== Low-degree testing

In the general sum-check protocol we just described,
we have what looks like a pretty neat procedure,
but the elephant in the room is that we needed to make a call to a polynomial oracle.
Just one call, which we denoted $P(r_1, ..., r_n)$, but you need an oracle nonetheless.

When we do PCP, the eventual plan
is to replace both the oracle call and Penny's answers
with a printed phone book.
The phone book contains, among other things, a big table mapping every $n$-tuple
$(r_1, ..., r_n) in FF_q^n$ to its value $P(r_1, ..., r_n)$
that Penny mails to Victor via Fedex or whatever.
This is of course a lot of work for Penny to print and mail this phone book.
However, Victor doesn't care about Penny's shipping costs.
After all, it's not like he's _reading_ the phone book;
he's just checking the entries he needs.
(That's sort of the point of a phone book, right?)

But now there's a new issue.
How can we trust the entries of the phone book are legitimate?
After all, Penny is the one putting it together.
If Penny was trying to fool Victor, she could write whatever she wanted
("hey Victor, the value of $P$ is $42$ at every input")
and then just lie during the sum-check protocol.
After all, she knows Victor isn't actually going to read the whole phone book.

=== Goal of low-degree testing

The answer to this turns out be _low-degree testing_.
For example, in the case where $|HH| = 2$ we described earlier,
there is a promise that $P$ is supposed a multilinear polynomial.
For example, this means that
$ 5/8 P(100, r_2, ..., r_n) + 3/8 P(900, r_2, ..., r_n) = P(400, r_2, ..., r_n) $
should be true.
If Victor randomly samples equations like this, and they all check out,
he can be confident that $P$ is probably "mostly" a polynomial.

I say "mostly" because, well, there's no way to verify the whole phone book.
By definition, Victor is trying to avoid reading.
Imagine if Penny makes a typo somewhere in the phone book ---
well, there's no way to notice it, because that entry will never see daylight.
However, Victor _also_ doesn't care about occasional typos in the phone book.
For his purposes, he just wants to check the phone book is 99% accurate,
since the sum-check protocol only needs to read a few entries anyhow.

=== The procedure --- the line-versus-point test
This is now a self-contained math problem, so I'll just write the statement
and not prove it (the proof is quite difficult).
Suppose $g colon FF_q^m -> FF_q$ is a function
and we want to see whether or not it's a polynomial of total degree at most $d$.

The procedure goes as follows.
The prover prints out two additional posters containing large tables $B_0$ and $B_1$,
whose contents are defined as follows:

- In the table $B_0$, for each point $arrow(b) in FF_q^m$,
  the prover writes $g(arrow(b)) in FF_q$.
  We denote the entry of the table by $B_0[arrow(b)]$.

- In the table $B_1$, for each line
  $ ell = { arrow(b) + t arrow(m) | t in FF_q } $
  the prover writes the restriction of $g$ to the line $ell$,
  which is a single-variable polynomial of degree at most $d$ in $FF_q [t]$.
  We denote the entry of the table by $B_1[ell]$.

The verifier then does the obvious thing:
pick a random point $arrow(b)$, a random line $ell$ through it,
and check the tables $B_0$ and $B_1$ are consistent.

This simple test turns out to be good enough, though proving this is hard
and requires a lot of math.
But the statement of the theorem is simple:

== Quad-SAT

As all NP-complete problems are equivalent, we can pick any one which is convenient.
Systems of linear equations don't make for good NP-complete problems,
but quadratic equations do.
So we are going to use Quad-SAT,
in which one has a bunch of variables over a finite field $FF_q$,
a bunch of polynomial equations in these variables of degree at most two,
and one wishes to find a satisfying assignment.

#remark([QSAT is pretty obviously NP-complete])[
  If you can't see right away that QSAT is NP-complete,
  the following example instance can help,
  showing how to convert any instance of 3-SAT into a QSAT problem:
  $
    x_i^2 &= x_i #h(1em) forall 1 <= i <= 1000 & \
    y_1 &= (1-x_(42)) dot x_(17), & #h(1em) & 0 = y_1 dot x_(53) & \
    y_2 &= (1-x_(19)) dot (1-x_(52)) & #h(1em) & 0 = y_2 dot (1-x_(75)) & \
    y_3 &= x_(25) dot x_(64), &#h(1em) & 0 = y_3 dot x_(81) & \
    &dots.v
  $
  (imagine many more such pairs of equations).
  The $x_i$'s are variables which are seen to either be $0$ or $1$.
  And then each pair of equations with $y_i$ corresponds to a clause of 3-SAT.
]

Let's say there are $N$ variables and $E$ equations, and $N$ and $E$ are both large.
Penny has worked really hard and figured out a satisfying assignment
$ A colon {x_1, ..., x_N} -> FF_q $
and wants to convince Victor she has this $A$.
Victor really hates reading,
so Victor neither wants to read all $N$ values of the $x_i$
nor plug them into each of the $E$ equations.
He's fine receiving lots of stuff in the mail; he just doesn't want to read it.

#remark([$q$ is not too big])[
  In earlier chapters, $q$ was usually a large prime like $q approx 2^255$.
  This is actually not desirable here: Quad-SAT is already interesting even
  when $q = 2$.
  So in this chapter, large $q$ is a bug and not a feature.

  For our protocol to work, we do need $q$ to be modestly large,
  but its size will turn out to be around $(log N E)^O(1)$.
]


== Description of the toy PCP protocol for Quad-SAT

We now have enough tools to describe a quad-SAT protocol that will break
the hearts of Fedex drivers everywhere.
In summary, the overview of this protocol is going to be the following:

- Penny prints $q^E$ phone books, one phone book each for each linear combination
  of the given Q-SAT equations.
  We'll describe the details of the phone book contents later.

- Penny additionally prints the two posters corresponding
  to a low-degree polynomial extension of $A$
  (we describe this exactly in the next section).

- Victor picks a random phone book and runs sum-check on it.

- Victor runs a low-degree test on the posters.

- Victor makes sure that the phone book value he read is consistent with the posters.

Let's dive in.

=== Setup

In sum-check, we saw we needed a bijection of $[N]$ into $HH^m$.
So let's fix this notation now (it is annoying, I'm sorry).
We'll let $HH$ be a set of size $|HH| := log (N)$
and set $m = log_(|HH|) N$.
This means we have a bijection from ${1, ..., N} -> HH^m$,
so we can rewrite the type-signature of $A$ to be
$ A colon HH^m -> FF_q. $

The contents of the phone books will take us a while to describe,
but we can actually describe the posters right now, and we'll do so.
Earlier when describing sum-check, we alluded to the following theorem,
but we'll state it explicitly now:
#theorem[
  Suppose $phi colon HH^n -> FF_q$ is _any_ function.
  Then there exists a unique polynomial $tilde(phi) colon FF_q^n -> FF_q$,
  which agrees with $phi$ on the values of $HH^n$
  and has degree at most $|HH|+1$ in each coordinate.
  Moreover, this polynomial $tilde(phi)$ can be easily computed given the values of $phi$.
]
#proof[
  Lagrange interpolation and induction on $m$.
]
We saw this earlier in the special case $HH={0,1}$ and $n=3$,
where we constructed the multilinear polynomial $5x y z+9x y+7z+8$ out of
eight initial values.

In any case, the posters are generated as follows.
Penny takes her known assignment $A colon HH^m -> FF_q$
and extends it to a polynomial
$ tilde(A) in FF_q [T_1, ..., T_m] $
using the above theorem;
by abuse of notation, we'll also write $tilde(A) colon FF_q^m -> FF_q$.
She then prints the two posters we described earlier for the point-versus-line test.

=== Taking a random linear combination
The first step of the reduction is to try and generate just a single equation to check,
rather than have to check all of them.
There is a straightforward (but inefficient; we'll improve it later) way to do this:
take a _random_ linear combination of the equations
(there are $q^E$ possible combinations).

To be really verbose, if $cal(E)_1$, ..., $cal(E)_E$ were the equations,
Victor picks random weights $lambda_1$, ..., $lambda_E$ in $FF_q$
and takes the equation $lambda_1 cal(E)_1 + ... + lambda_E cal(E)_E$.
In fact, imagine the title on the cover of the phone book is
given by the weights $(lambda_1, ..., lambda_E) in FF_q^m$.
Since both parties know $cal(E)_1$, ..., $cal(E)_E$,
they agree on which equation is referenced by the weights.

We'll just check _one_ such random linear combination.
This is good enough because, in fact,
if an assignment of the variables fails even one of the $E$ equations,
it will fail the collated equation with probability $1 - 1/q$ --- exactly!
(To see this, suppose that equation $cal(E)_1$ was failed by the assignment $A$.
Then, for any fixed choice of $lambda_2$, ..., $lambda_E$, there is always
exactly one choice of $lambda_1$ which makes the collated equation true,
while the other $q-1$ all fail.)

To emphasize again: Penny is printing $q^E$ phone books right now and we only use one.
Look, I'm sorry, okay?

=== Sum-checking the equation (or: how to print the phone book)

Let's zoom in on one linear combination to use sum-check on.
(In other words, pick only one of the phone books at random.)
Let's agree to describe the equation using the notation
$
  c = sum_(arrow(i) in HH^m) sum_(arrow(j) in HH^m)
  a_(arrow(i), arrow(j)) x_(arrow(i)) dot x_(arrow(j))
  + sum_(arrow(i) in HH^m) b_(arrow(i)) x_(arrow(i)).
$
In other words, we've changed notation so both the variables
and the coefficients are indexed by vectors in $HH^m$.
When we actually implement this protocol, the coefficients need to be actually computed:
they came out of $lambda_1 cal(E)_1 + ... + lambda_E cal(E)_E$.
(So for example, the value of $c$ above is given
by $lambda_1$ times the constant term of $cal(E)_1$,
plus $lambda_2$ times the constant term of $cal(E)_2$, etc.)

Our sum-check protocol that we talked about earlier
used a sequence $(r_1, ..., r_n) in {0,1}^n$.
For our purposes, we have these quadratic equations,
and so it'll be convenient for us if we alter the protocol to use pairs
$(arrow(i), arrow(j)) in FF_q^m times FF_q^m$ instead.
In other words, rather than $f(arrow(v))$
our variables will be indexed instead in the following way:
$
  f &colon HH^m times HH^m -> FF_q \
  f(arrow(i), arrow(j)) &:=
    a_(arrow(i), arrow(j)) A(arrow(i)) A(arrow(j))
    + 1 / (|HH|^m) b_(arrow(i)) A(arrow(i)).
$
Hence Penny is trying to convince Victor that
$ sum_(arrow(i) in FF_q^m)
  sum_(arrow(j) in FF_q^m) f(arrow(i), arrow(j)) = c. $

In this modified sum-check protocol, Victor picks the indices two at a time.
So in the step where Victor picked $r_1$ in the previous step,
he instead picks $i_1$ and $j_1$ at once.
Then instead of picking an $r_2$, he picks a pair $(i_2, j_2)$ and so on.

Then, to run the protocol, the entries of the phone book are going to correspond to
$
  P &in FF_q [T_1, ..., T_m, U_1, ..., U_m] \
  P(T_1, ..., T_m, U_1, ..., U_m) &:=
    tilde(a) (T_1, ..., T_m, U_1, ..., U_m) tilde(A)(T_1, ..., T_m)
    tilde(A)(U_1, ..., U_m) \
    &+ 1/(|HH|^m) tilde(b)(T_1, ..., T_m) tilde(A)(T_1, ..., T_m)
$
in place of what we called $P(x,y,z)$ in the sum-check section.

I want to stress now the tilde's above are actually hiding a lot of work.
Let's unpack it a bit: what does $tilde(a)$ mean?
After all, when you unwind this notational mess we wrote,
we realize that the $a$'s and $b$'s came out of the coefficients of the original
equations $cal(E)_k$.

The answer is that both Victor and Penny have a lot of arithmetic to do.
Specifically, for Penny,
when she's printing this phone book for $(lambda_1, ..., lambda_E)$,
needs to apply the extension result three times:

- Penny views $a_(arrow(i), arrow(j))$ as a function $HH^(2m) -> FF_q$
  and extends it to a polynomial using the above;
  this lets us define
  $tilde(a) in FF_q [T_1, ..., T_m, U_1, ..., U_m]$
  as a _bona fide_ $2m$-variate polynomial.

- Penny does the same for $tilde(b)_(arrow(i))$.

- Finally, Penny does the same on $A colon HH^m -> FF_q$,
  extending it to $tilde(A) in FF_q [T_1, ..., T_m]$.
  (However, this step is the same across all the phone books, so it only happens once.)

Victor has to do the same work for $a_(arrow(i), arrow(j))$ and $b_(arrow(i))$.
Victor can do this, because he picked the $lambda$'s,
as he computed the coefficients of his linear combination too.
But Victor does _not_ do the last step of computing $tilde(A)$:
for that, he just refers to the poster Penny gave him,
which conveniently happens to have a table of values of $tilde(A)$.

Now we can actually finally describe the full contents of the phone book.
It's not simply a table of values of $P$!
We saw in the sum-check protocol that we needed a lot of intermediate steps too
(like the $23T+46$, $161U+23$, $112V+197$).
So the contents of this phone book include, for every index $k$,
every single possible result that Victor would need to run sum-check at the $k$th step.
That is, the $k$th part of this phone book are a big directory where,
for each possible choice of indices $(i_1, ..., i_(k-1), j_1, ..., j_(k-1))$,
Penny has printed the two-variable polynomial in $FF_q [T,U]$ that arises from sum-check.
(There are two variables rather than one now,
because $(i_k, j_k)$ are selected in pairs.)

This gives Victor a non-interactive way to run sum-check.
Rather than ask Penny, consult the already printed phone book.
Inefficient? Yes. Works? Also yes.

=== Finishing up
Once Victor runs through the sum-check protocol,
at the end he has a random $(arrow(i), arrow(j))$ and received
the checked the phone book for $P(arrow(i), arrow(j))$.

Assuming it checks out, his other task is to
verify that the accompanying posters that Penny sent ---
that is, the table of values $B_0$ and $B_2$ associated to $tilde(A)$ ---
look like they mostly come from a low-degree polynomial.
Unlike the sum-check step where we needed to hack the earlier procedure,
this step is a direct application of line-versus-point test, without modification.

Up until now the phone book and posters haven't interacted.
So Victor has to do one more check:
he makes sure that the value of $P(arrow(i), arrow(j))$ he got from the phone book
in fact matches the value corresponding to the poster $B_0$.
In other words, he does the arduous task of computing the extensions
$tilde(a)$ and $tilde(b)$, and finally verifies that
$
  P(arrow(i), arrow(j)) :=
  tilde(a)(arrow(i), arrow(j)) B_0[arrow(i)] B_0[arrow(j)]
  + 1/(|HH|^m) tilde(b)(arrow(i)) B_0[arrow(i)]
$
is actually true.

== Reasons to not be excited by this protocol
The previous section describes a long procedure that has a PCP flavor,
but it suffers from several issues (which is why we call it a toy example).

- *Amount of reading*:
  The amount of reading on Victor's part is not $O(1)$ like we promised.
  The low-degree testing step with the posters used $O(1)$ entries,
  but the sum-check required reading roughly
  $ O(|HH|^2) dot (m+O(1)) approx (log N)^3 / (log log N) $
  entries from the phone book.
  The PCP theorem promises we can get that down to $O(1)$,
  but that's beyond this post's scope.

- *Length of proof*:
  The procedure above involved mailing $q^E$ phone books,
  which is what we in the business call either "unacceptably inefficient"
  or "fucking terrible", depending on whether you're in polite company or not.
  The next section will show how to get this down to $q E N$ if $q$ is large enough.

  For context, in this protocol one wants a reasonably small prime $q$
  which is about polynomial in $log(E N)$.
  After all, Quad-SAT is already an NP-complete problem for $q=2$.
  (In contrast, in other unrelated more modern ecosystems,
  the prime $q$ often instead denotes a fixed large prime $q approx 2^256$.)

- *Time complexity*:
  Even though Victor doesn't read much,
  Penny and Victor both do quite a bit of computation.
  For example,

  - Victor has to compute $tilde(a)_(arrow(i), arrow(j))$ for his one phone book.
  - Penny needs to do it for _every_ phone book.


- One other weird thing about this result is that,
  even though Victor has to read only a small part of Penny's proof,
  he still has to read the entire _problem statement_,
  that is, the entire system of equations from the original Quad-SAT.
  This can feel strange because for Quad-SAT,
  the problem statement is of similar length to the satisfying assignment!

  TODO: some comments from Telegram here

== Reducing the number of phone books --- error correcting codes

We saw that we can combine all the $E$ equations from Quad-SAT into a single one
by taking a random linear combination.
Our goal is to improve this by taking a "random-looking" combination
that still has the same property an assignment failing even one of the $E$ equations
is going to fail the collated equation with probability close to $1$.

It turns out there is actually a well-developed theory of how to take
the "random-looking" linear combination,
and it comes from the study of _error-correcting codes_.
We will use this to show that if $q >= 4(log (E N))^2$ is large enough,
one can do this with only $q dot E N$ combinations.
That's much better than the $q^E$ we had before.

=== (Optional) A hint of the idea: polynomial combinations

Rather than simply doing a random linear combination,
one could imagine considering the following $100 E$ combinations

$ k^1 cal(E)_1 + k^2 cal(E)_2 + ... + k^E cal(E)_E
  " for " k = 1, 2, ..., 100 E. $

If any of the equations $cal(E)_i$ are wrong,
then we can view this as a degree $E$ polynomial in $k$,
and hence it will have at most $E$ roots.
Since we have $100 E$ combinations,
that means at least 99% of the combinations will fail.

So why don't we just do that?
Well, the issue is that we are working over $FF_q$.
And this argument only works if $q >= 100 E$, which is too big.

=== Definition of error-correcting codes

An *error-correcting code* is a bunch of codewords
with the property that any two differ in "many" places.
An example is the following set of sixteen bit-strings of length $7$:
$
  C = {
    & 0000000, 1101000, 0110100, 0011010, \
    & 0001101, 1000110, 0100011, 1010001, \
    & 0010111, 1001011, 1100101, 1110010 \
    & 0111001, 1011100, 0101110, 1111111 } subset.eq FF_2^7
$
which has the nice property that any two of the codewords in it differ in at least $3$ bits.
This particular $C$ also enjoys the nice property that it's actually
a vector subspace of $FF_2^7$ (i.e. it is closed under addition).
In practice, all the examples we consider will be subspaces,
and we call them *linear error-correcting codes* to reflect this.

When designing an error-correcting code, broadly your goal is to make sure the
minimum distance of the code is as large as possible,
while still trying to squeeze in as many codewords as possible.
The notations used for this are:

- Usually we let $q$ denote the alphabet size and $n$ the block length
  (the length of the codewords),
  so the codewords live in the set of $q^n$ possible length $n$ strings.

- The *relative distance* is defined as the minimum Hamming distance divided by $n$;
  Higher relative distance is better (more error corrections).

- The *rate* is the $log_(q^n)("num codewords")$.
  Higher rates are better (more densely packed codewords).

So the example $C$ has relative distance $3/7$,
and rate $log_(2^7)(16) = 4/7$.

=== Examples of error-correcting codes

TODO: Hadamard, ...

=== Composition

TODO: Define this

=== Recipe
Compose the Reed-Solomon codes
$
  C_1 &= "RS"_(d=E,q=E N) \
  C_2 &= "RS"_(d=log(E N),q).
$
This gives a linear code corresponding to an $s times m$ matrix $M$,
where $s := q dot E N$, which has relative distance at least $1 - 1/sqrt(q)$.
The rows of this matrix (just the rows, not their row span)
then correspond to the desired linear combinations.
