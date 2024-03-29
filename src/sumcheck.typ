= The sum-check protocol

== Pitch

Before worrying about systems of equations
(which we'll do in the next chapter), let's imagine we just have a
_single_ equation
$ Z_1 + Z_2 + dots.c + Z_"big" = H $
for some variables $Z_i$ and constant $H in FF_q$, all over $FF_q$,
and assume further that $q$ is not too small.

Imagine a prover Penny has a value assigned to each $Z_i$,
and is asserting to the verifier Victor they $Z_i$'s sum to $H$.
Victor wants to know that Penny computed the sum $H$ correctly,
but Victor doesn't want to actually read all the values of $Z_i$.

Well, at face value, this is an obviously impossible task.
Even if Victor knew all but one of Penny's $Z_i$'s, that wouldn't be good enough.

So to get anywhere, we need to to give Victor at least one magic power.

== An oracle to a multilinear polynomial

Assume for convenience that the number of $Z$'s happens to be $2^n$
and change notation to a function $f colon {0,1}^n -> FF_q$,
so our equation becomes
$ sum_(arrow(v) in {0,1}^n) f(arrow(v)) = H $.
In other words, we have changed notation so that our variables are indexed over a
hypercube: from $f(0, dots, 0)$ to $f(1, dots, 1)$.

Now here's the magic power we're granting.
By polynomial interpolation, no matter what function $f$ we had initially,
we can view it as multilinear polynomial $P in FF_q [X_1, ..., X_n]$.
For example, suppose $n=3$ and the eight (arbitrary) variable values were given
$
  f(0,0,0) &= 8 \
  f(0,0,1) &= 15 \
  f(0,1,0) &= 8 \
  f(0,1,1) &= 15 \
  f(1,0,0) &= 8 \
  f(1,0,1) &= 15 \
  f(1,1,0) &= 17 \
  f(1,1,1) &= 29.
$
(So $H = 8+15+8+15+8+15+17+29 = 115$.)
Then we'd be trying to fill in the blanks in the equation
$ P(x,y,z) = square + square x + square y + square z
  + square x y + square y z + square z x + square x y z $
so that $P$ agrees with $f$ on the cube.
This comes down to solving a system of linear equations;
in this case it turns out that $P(x,y,z) = 5x y z + 9x y + 7z + 8$ works,
and I've cherry-picked the numbers so a lot of the coefficients work out to $0$ for
convenience, but math majors should be able to verify that $P$ exists and is unique
no matter what eight initial numbers I would have picked (by induction on $n$).

Now here's the magic power:
we are going to let Victor make _one_ call to a magic oracle
that can tell Victor the value of $P(r_1,...,r_n)$,
for his choice of $(r_1, ..., r_n) in FF_q^n$.
Note importantly that the $r_i$'s do not have to $0$/$1$,
in fact we will say Victor just chooses them randomly from the much larger $FF_q$.
But he can only ask the oracle for that single value of $P$,
and otherwise has no idea what any of the $Z_i$'s are.
The punch line of the protocol is that this single oracle call is good enough.
If Victor has this oracle, he only needs to read one value for
Penny to convince him that $H$ was computed correctly.

== A playthrough of the sum-check protocol

Let's use the example above with $n=3$:
Penny has chosen those eight values with $H = 115$,
and wants to convince Victor without actually sending all eight values.
Penny has done her homework and computed the coefficients of $P$ as well
(after all, she chose the values of $f$), so Penny can evaluate $P$ anywhere she wants.
But Victor can only ask the oracle about a single value of the polynomial $P$
on a point (probably) outside the hypercube.

Here's how they do it.
(All the information sent by Penny to Victor is $#rect("boxed")$.)

1. Penny announces her claim $H = #rect($115$)$.
2. They now discuss the first coordinate:
  - Victor asks Penny to evaluate the linear one-variable polynomial
    $ g_1(T) := P(T,0,0) + P(T,0,1) + P(T,1,0) + P(T,1,1) $
    and send the result. In our example, it equals
    $ g_1(T) = 8 + 15 + (9T+8) + (14T+15) = #rect($23T+46$). $

  - Victor then checks that this $g_1$ is consistent with the claim $H=115$;
    it should satisfy $H = g_1(0) + g_1(1)$ by definition.
    Indeed, $g_1(0)+g_1(1) = 46+69 = 115 = H$.

  - Finally, Victor commits to a random choice of $r_1 in FF_q$; let's say $r_1 = 7$.
    From now on, he'll always use $7$ for the first argument to $P$.

3. With the first coordinate fixed at $r_1 = 7$, they talk about the second coordinate:
  - Victor asks Penny to evaluate the linear polynomial
    $ g_2(U) := P(7,U,0) + P(7,U,1). $
    and send the result. In our example, it equals
    $ g_2(U) = (63U+8) + (98U+15) = #rect($161U + 23$). $

  - Victor makes sure the claimed $g_2$ is consistent with $g_1$;
    it should satisfy $g_1(r_1) = g_2(0)+g_2(1)$.
    Indeed, it does $g_1(7) = 23 dot 7 + 46 = 23 + 184 = g_2(0) + g_2(1)$.

  - Finally, Victor commits to a random choice of $r_2 in FF_q$; let's say $r_1 = 3$.
    From now on, he'll always use $3$ for the second argument to $P$.

4. They now settle the last coordinate:
  - Victor asks Penny to evaluate the linear polynomial
    $ g_3(U) := P(7,3,V) $
    and send the result. In our example, it equals
    $ g_3(U) = #rect($112V+197$). $

  - Victor makes sure the claimed $g_3$ is consistent with $g_2$;
    it should satisfy $g_2(r_2) = g_3(0)+g_3(1)$.
    Indeed, it does $g_2(3) = 161 dot 3 + 23 = 197 + 309 = g_3(0) + g_3(1)$.

  - Finally, Victor commits to a random choice of $r_3 in FF_q$; let's say $r_3 = -1$.

5. Victor has picked all three coordinates, and is ready consults the oracle.
  He gets $P(7,3,-1) = 85$.
  This matches $g_3(-1) = 85$, and the protocol ends.

== General procedure

The previous transcript should generalize obviously to any $n > 3$,
but we spell it out anyways.
Penny has already announced $H$ and pre-computed $P$.
Now for $i = 1, ..., n$,

- Victor asks Penny to compute the univariate polynomial $g_i$
  corresponding to partial sum, where the $i$th parameter is a free parameter
  while all the $r_1$, ..., $r_(i-1)$ have been fixed already.
- Victor sanity-checks each of Penny's answer by making sure $g_i$ is consistent
  with (that is, $g_(i-1)(r_(i-1)) = g_i (0) + g_i (1)$,
  or for the edge case $i=1$ that $H = g_1(0) + g_1(1)$).
- Then Victor commits to a random $r_i in FF_q$ and moves on to the next coordinate.

Once Victor has decided on every $r_i$, he asks the oracle for $P(r_1, ..., r_n)$
and makes sure that it matches the value of $g_n(r_n)$.
If so, Victor believes Penny.

Up until now, we wrote the sum-check protocol as a sum over ${0,1}^n$.
However, actually there is nothing in particular special about ${0,1}^n$
and it would work equally well with $HH^n$ for any small finite set $HH$;
the only change is that the polynomial $P$
would now have degree at most $|HH|-1$ in each variable,
rather than being multilinear.
Accordingly, the $g_i$'s change from being linear to up to degree $|HH|-1$.
Everything else stays the same.
