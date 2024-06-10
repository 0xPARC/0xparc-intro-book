#import "preamble.typ":*

= A hard problem: learning with errors
<lwe>

Many cryptographic protocols rely on some sort of "hard problem"
-- a computationally infeasible challenge 
whose difficulty makes the protocol secure.
It is hard to factor a composite number (like $6177$)
into prime factors ($6177 = 71*87$);
the challenge of factoring gives us
#link("https://en.wikipedia.org/wiki/RSA_(cryptosystem)", "RSA").
The challenge of the discrete logarithm problem
(@discretelog)
gives us elliptic curve cryptography,
KZG polynomial commitments (@kzg), and so forth.

Our protocol for levelled FHE relies on a different hard problem.
The problem is to solve systems of linear equations.
Except the equations are only approximately true -- 
they permit a small "error" --
and instead of solving for rational or real numbers,
you're solving for integers modulo $q$.

Here’s a concrete example of a LWE problem and how one might attack it
"by hand." This exercise will make the inherent difficulty of the
problem quite intuitive, but also give us some ideas on how one might
write a LWE solver in practice to attack small LWE
problems.

#problem[
We are working over $bb(F)_11$, and there is some secret vector
$a = (a_1 , dots.h , a_4)$. There are two sets of claims. Each claim
"$(x_1 , dots.h , x_4) : y$" purports the relationship

$
  y = a_1 x_1 + a_2 x_2 + a_3 x_3 + a_4 x_4 + epsilon, #h(0.3in) epsilon in {0,1}.
$

One of the sets of claims is "genuine" and comes from a consistent set
of $a_i$, while the other set is "fake" and has randomly generated $y$
values. Tell them apart and find the correct secret vector
$(a_1 , dots.h , a_4)$.

#figure(
  align(center)[#table(
    columns: 2,
    align: (auto,auto,),
    table.header([Blue Set], [Red Set],),
    table.hline(),
    [(1, 0, 1, 7) : 2], [(5, 4, 5, 2) : 2],
    [(5, 8, 4, 10) : 9], [(7, 7, 7, 8) : 5],
    [(7, 7, 8, 5) : 3], [(6, 8, 2, 2) : 0],
    [(5, 1, 10, 6) : 3], [(10, 4, 4, 3) : 1],
    [(8, 0, 2, 4) : 1], [(1, 10, 8, 6) : 6],
    [(9, 3, 0, 6) : 9], [(2, 7, 7, 4) : 4],
    [(0, 6, 1, 6) : 9], [(8, 6, 6, 9) : 1],
    [(0, 4, 9, 7) : 5], [(10, 6, 1, 6) : 9],
    [(10, 7, 4, 10) : 10], [(3, 1, 10, 9) : 7],
    [(5, 5, 10, 6) : 8], [(2, 4, 10, 3) : 7],
    [(10, 7, 3, 1) : 9], [(10, 4, 6, 4) : 2],
    [(0, 2, 5, 5) : 6], [(8, 5, 7, 2) : 2],
    [(9, 10, 2, 1) : 2], [(4, 7, 0, 0) : 8],
    [(3, 7, 2, 1) : 5], [(0, 3, 0, 0) : 0],
    [(2, 3, 4, 5) : 3], [(8, 3, 2, 7) : 8],
    [(2, 1, 6, 9) : 3], [(4, 6, 6, 3) : 2],
  )]
  , kind: table
  )
]

#solution[
We start with some helpful notation. Define an #strong[information
vector] 
$
  (x_1 , x_2 , x_3 , x_4 lr(|y|) S),
$
where $S subset F_11$, to
mean the statement 
#quote[$sum a_i x_i = y + s$, where $s in S$.] 
In
particular, a given purported approximation
$
  (x_1 , x_2 , x_3 , x_4) : y
$ 
in the LWE protocol corresponds to the
information vector 
$
  (x_1 , x_2 , x_3 , x_4 lr(|y|) { 0 , - 1 }).
$ 
The
benefit of this notion is that we can take linear combinations of them.
Specifically,

#proposition[ 
If $(X_1 lr(|y_1|) S_1)$ and
$(X_2 lr(|y_2|) S_2)$ are information vectors (where $X_i$ are vectors),
then

$ (alpha X_1 + beta X_2 lr(|alpha y_1 + beta y_2|) alpha S_1 + beta S_2) , $

where $alpha S = { alpha s \| s in S }$ and
$S + T = { s + t \| s in S , t in T }$.
]

We can observe the following:

+ If we obtain two vectors $(X lr(|y|) S_1)$ and $(X lr(|y|) S_2)$, then
  we have the information (assuming the vectors are accurate)
  $(X lr(|y|) S_1 sect S_2)$. So if we are lucky enough, say, to have
  $lr(|S_1 sect S_2|) = 1$, then we have found an actual equation with
  no error.
+ As we linearly combine vectors, their "error part" $S$ gets bigger
  exponentially. So we can only add vectors very few times, ideally just
  1 or 2 times, before they start being unusable.

With these heuristics, we are ready to solve this problem.

#todo[Is it better with the equations displayed, or no?]

=== Red Set
<red-set>
First, we show that the "Red set" is inconsistent. Our main strategy
will be to make vectors with many $0$’s in the same places.

+ Our eyes are drawn to the juicy-looking
  $ (0 , 3 , 0 , 0 lr(|0|) { 0 , - 1 }), $ which immediately gives
  $ a_2 in { 0 , 7 } $.
+ $ (4 , 7 , 0 , 0 lr(|8|) { 0 , - 1 }) $ gives
  $ 4 a_1 + 7 a_2 in { 7 , 8 }. $ Since $ 7 a_2 in { 0 , 5 }, $
  $ 4 a_1 in { 7 , 8 } - { 0 , 5 } = { 7 , 8 , 2 , 3 }, $ and
  $ a_1 in { 10 , 2 , 6 , 9 }. $
+ $ (10 , 4 , 4 , 3 lr(|1|) { 0 , - 1 }) + (7 , 7 , 7 , 8 lr(|5|) { 0 , - 1 }) = (6 , 0 , 0 , 0 lr(|6|) { 0 , - 1 , - 2 }), $
  which is nice because it has 3 zeroes! This gives
  $ a_1 in { 1 , 8 , 10 }. $ Combining with (2), we conclude that
  $ a_1 = 10. $
+ We can reuse $ (4 , 7 , 0 , 0) : 8. $ Since we knew from (2) that
  $ 4 a_1 + 7 a_2 in { 7 , 8 }, $ we can substitute $ a_1 = 10 $ to get
  $ 7 a_2 in { 0 , 1 }. $ This forces $ a_2 = 0 $ because of (1).

At this point, basically any isolation of the first two variables would
force a contradiction. For example, we can compute

$ (8 , 6 , 6 , 9 lr(|1|) { 0 , - 1 }) + (5 , 4 , 5 , 2 lr(|2|) { 0 , - 1 }) = (2 , 10 , 0 , 0 lr(|3|) { 0 , - 1 , - 2 }) . $

Since $ 2 a_1 + 10 a_2 = 9$, but $3 + { 0 , - 1 , - 2 } = { 1 , 2 , 3 }, $
we have a contradiction.

=== Blue Set
<blue-set>
This is slightly harder because we don’t have really nice vectors like
$(0 , 3 , 0 , 0)$, but still very doable. First, we try to isolate two
of the variables. For example, we can compute

- $10 (10 , 7 , 4 , 10 lr(|10|) { 0 , - 1 }) - 9 (10 , 7 , 3 , 1 lr(|9|) { 0 , - 1 }) = (0 , 0 , 1 , 9 lr(|1|) { 1 , 0 , - 1 })$
- $5 (5 , 5 , 10 , 6 lr(|8|) { 0 , - 1 }) + 9 (7 , 7 , 8 , 5 lr(|3|) { 0 , - 1 }) = (0 , 0 , 1 , 9 lr(|1|) { 0 , 2 , 6 , 8 })$

By looking at the intersection, we can conclude that
$(0 , 0 , 1 , 9 lr(|1|) { 0 })$. Equivalently, $a_3 + 9 a_4 = 1$ or
$a_3 = 1 + 2 a_4$. Now, we can compute

- $(2 , 1 , 6 , 9 lr(|3|) { 0 , - 1 }) + (9 , 10 , 2 , 1 lr(|2|) { 0 , - 1 }) = (0 , 0 , 8 , 10 lr(|5|) { 0 , - 1 , - 2 })$.
  This says that, using $a_3 = 1 + 2 a_4$,

  $ 8 a_3 + 10 a_4 = 8 + 4 a_4 in 5 + { 0 , - 1 , - 2 } . $

  Solving, we know that $a_4 in 2 + { 0 , - 3 , - 6 } = { 2 , 7 , 10 }$.

- $- 2 (0 , 2 , 5 , 5 lr(|6|) { 0 , - 1 }) + (0 , 4 , 9 , 7 lr(|5|) { 0 , - 1 }) = (0 , 0 , 10 , 8 lr(|4|) { - 1 , 0 , 1 , 2 })$.
  Substituting for $a_3$ as before, we obtain

  $ 10 + 6 a_4 in { 3 , 4 , 5 , 6 } . $

  Solving, we know that $a_4 in { 8 , 10 , 1 , 3 }$.

The combination proves that $a_4 = 10$; in turn, we deduce $a_3 = 10$ by
substitution. We omit some details in the remaining algebra (which can
be done in various ways, as any triple of equations will set up 3
"almost equations" in the 2 remaining unknowns):

+ $(1 , 0 , 1 , 7 lr(|2|) { 0 , - 1 })$ gives $a_1 in { 9 , 10 }$.
+ $(0 , 6 , 1 , 6 lr(|9|) { 0 , - 1 })$ gives $a_2 in { 8 , 10 }$.
+ $(2 , 3 , 4 , 5 lr(|3|) { 0 , - 1 })$ gives
  $2 a_1 + 3 a_2 in { 0 , 1 }$.

This is enough to conclude that $a_1 = 10$ and $a_2 = 8$, giving the
answer $(10 , 8 , 10 , 10)$.
]
