#import "preamble.typ":*

= A hard problem: learning with errors
<lwe>

As we've seen (@ec),
a lot of cryptography relies on hard math problems.
RSA is based on the difficulty of integer factorization;
elliptic curve cryptography depends on the discrete log assumption.

Our protocol for levelled FHE relies on a different hard problem:
the learning with errors problem (LWE).
The problem is to solve systems of linear equations,
except that the equations are only approximately true --
they permit a small "error" --
and instead of solving for rational or real numbers,
you're solving for integers modulo $q$.

Here’s a concrete example of an LWE problem and how one might attack it
"by hand." This exercise will make the inherent difficulty of the
problem quite intuitive.

#problem[
We are working over $bb(F)_11$, and there is some secret vector
$a = (a_1 , dots.h , a_4)$. There are two sets of claims. Each claim
"$(x_1 , dots.h , x_4) : y$" purports the relationship

$
  y = a_1 x_1 + a_2 x_2 + a_3 x_3 + a_4 x_4 + epsilon, #h(0.3in) epsilon in {0,1}.
$
(The $epsilon$ is different from equation to equation.)

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
    [(5, 8, 4, 10) : 2], [(7, 7, 7, 8) : 5],
    [(7, 7, 8, 5) : 3], [(6, 8, 2, 2) : 0],
    [(5, 1, 10, 6) : 10], [(10, 4, 4, 3) : 1],
    [(8, 0, 2, 4) : 9], [(1, 10, 8, 6) : 6],
    [(9, 3, 0, 6) : 9], [(2, 7, 7, 4) : 4],
    [(0, 6, 1, 6) : 9], [(8, 6, 6, 9) : 1],
    [(0, 4, 9, 7) : 5], [(10, 6, 1, 6) : 9],
    [(10, 7, 4, 10) : 10], [(3, 1, 10, 9) : 7],
    [(5, 5, 10, 6) : 9], [(2, 4, 10, 3) : 7],
    [(10, 7, 3, 1) : 9], [(10, 4, 6, 4) : 7],
    [(0, 2, 5, 5) : 6], [(8, 5, 7, 2) : 5],
    [(9, 10, 2, 1) : 3], [(4, 7, 0, 0) : 8],
    [(3, 7, 2, 1) : 6], [(0, 3, 0, 0) : 0],
    [(2, 3, 4, 5) : 3], [(8, 3, 2, 7) : 5],
    [(2, 1, 6, 9) : 3], [(4, 6, 6, 3) : 1],
  )]
  , kind: table
  )
]

#gray[
(*Solution sketch; can be skipped safely.*) One way to start would be to define an _information
vector_
$
  (x_1 , x_2 , x_3 , x_4 lr(|y|) S),
$
where $S subset FF_11$, to
mean the statement
$ sum a_i x_i = y + s, #text(" where ") s in S. $
In particular, a purported approximation
$(x_1 , x_2 , x_3 , x_4) : y$
in the LWE protocol corresponds to the
information vector
$
  (x_1 , x_2 , x_3 , x_4 lr(|y|) { 0 , - 1 }).
$
The
benefit of this notation is that we can take linear combinations of them.
Specifically, if $(X_1 lr(|y_1|) S_1)$ and
$(X_2 lr(|y_2|) S_2)$ are information vectors (where $X_i$ are vectors),
then

$ (alpha X_1 + beta X_2 lr(|alpha y_1 + beta y_2|) alpha S_1 + beta S_2) , $

where $alpha S = { alpha s \| s in S }$ and
$S + T = { s + t \| s in S , t in T }$.

We can observe the following:

+ If we obtain two vectors $(X lr(|y|) S_1)$ and $(X lr(|y|) S_2)$, then
  we have the information (assuming the vectors are accurate)
  $(X lr(|y|) S_1 sect S_2)$. So if we are lucky enough, say, to have
  $lr(|S_1 sect S_2|) = 1$, then we have found an exact equation with
  no error.
+ As we linearly combine vectors, their "error part" $S$ gets bigger
  exponentially. So we can only add vectors very few times, ideally just
  1 or 2 times, before they start being unusable.

With these heuristics, we can start by looking at the Red Set, and make vectors with many $0$’s in the same places.

+ Our eyes are drawn to the juicy-looking
  $(0 , 3 , 0 , 0 lr(|0|) { 0 , - 1 }),$ which immediately gives
  $a_2 in { 0 , 7 }$.
+ $(4 , 7 , 0 , 0 lr(|8|) { 0 , - 1 })$ gives
  $4 a_1 + 7 a_2 in { 7 , 8 },$ Since $7 a_2 in { 0 , 5 },$
  $ 4 a_1 in { 7 , 8 } - { 0 , 5 } = { 7 , 8 , 2 , 3 }, $ and
  $a_1 in { 10 , 2 , 6 , 9 }.$
+ Adding $ (10 , 4 , 4 , 3 lr(|1|) { 0 , - 1 }) + (7 , 7 , 7 , 8 lr(|5|) { 0 , - 1 }) $ gives $(6 , 0 , 0 , 0 lr(|6|) { 0 , - 1 , - 2 }),$
  which is nice because it has 3 zeroes! This gives
  $a_1 in { 1 , 8 , 10}. $ Combining with (2), we conclude that
  $a_1 = 10.$
+ ...

We omit the rest of the solution, which makes for some fun tinkering.
]
