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
