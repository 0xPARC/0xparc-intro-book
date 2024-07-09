#import "preamble.typ":*

= Levelled FHE from LWE
<fhe>

== The main idea: Approximate eigenvalues

Now we want to turn the public-key encryption from @lwe-crypto
into a levelled FHE scheme.
In other words:
We want to be able to encrypt bits (0s and 1s)
and operate on them with AND and NOT gates.

It might help to imagine that, instead of AND and NOT,
the operations we want to encrypt are addition and multiplication.
If $x$ and $y$ are bits, then
NOT $x$ is just $1 - x$, and $x$ AND $y$ is just $x y$.
But it's easier to do algebra with $+$ and $times$.

Recall the setup from @lwe-crypto: We’re going pick some
large integer $q$ (in practice $q$ could be anywhere from a few thousand
to $2^1000$), and do "approximate linear algebra" modulo $q$. In other
words, we’ll do linear algebra, where all our calculations are done
modulo $q$ – but we’ll also allow the calculations to have a small
"error" $epsilon.alt$, which will typically be much, much smaller than
$q$.

As before, our #emph[secret key] will be a vector of length $n$:
$ upright(bold(v)) = (v_1, dots, v_n) in (ZZ \/ q ZZ)^n. $
Suppose
we want to encode a message $mu$ that’s just a single bit, let’s say
$mu in { 0 , 1 }$. Our ciphertext will be a square $n$-by-$n$ matrix $C$
such that $ C upright(bold(v)) approx mu upright(bold(v)) . $ Now if we
assume that $upright(bold(v))$ has at least one "big" entry (say $v_i$),
then decryption is easy: Just compute the $i$-th entry of
$C upright(bold(v))$, and determine whether it is closer to $0$ or to
$v_i$.

With a bit of effort, it’s possible to make this into a public-key
cryptosystem. Just like in @lwe-crypto,
the main idea is to release a
table of vectors
$upright(bold(x))$ such that
$ upright(bold(x)) dot.op upright(bold(v)) approx 0, $ and use that as a
public key. Given $mu$ and the public key, you can find a matrix $C_0$
such that $ C_0 upright(bold(v)) approx 0 $ then take
$ C = C_0 + mu Id, $ where $Id$ is the identity
matrix. This gives a $C$ such that

$ C upright(bold(v)) approx mu upright(bold(v)). $

#problem[How do we build such a $C_0$? (One possible direction is to build it row-by-row.)]

== Operations on encrypted data

To make homomorphic encryption work, we need to explain how to operate
on $mu$. We’ll describe three operations: addition, NOT, and
multiplication (aka AND).

Addition is simple: Just add the matrices. If
$C_1 upright(bold(v)) approx mu_1 upright(bold(v))$ and
$C_2 upright(bold(v)) approx mu_2 upright(bold(v))$, then
$ (C_1 + C_2) upright(bold(v)) = C_1 upright(bold(v)) + C_2 upright(bold(v)) approx mu_1 upright(bold(v)) + mu_2 upright(bold(v)) = (mu_1 + mu_2) upright(bold(v)) . $
Of course, addition on bits isn’t a great operation, because if you add
$1 + 1$, you get $2$, and $2$ isn’t a legitimate bit anymore. So we
won’t really use this.

Negation of a bit (NOT) is equally simple. If $mu in { 0 , 1 }$
is a bit, then its negation is simply $1 - mu$. And if $C$ is a
ciphertext for $mu$, then $Id - C$ is a ciphertext for
$1 - mu$, since
$ (Id - C) upright(bold(v)) = upright(bold(v)) - C upright(bold(v)) approx (1 - mu) upright(bold(v)) . $

Multiplication is also a good operation on bits – it’s just AND. To
multiply two bits, you just multiply (matrix multiplication) the
ciphertexts:
$ C_1 C_2 upright(bold(v)) approx C_1 (mu_2 upright(bold(v))) = mu_2 C_1 upright(bold(v)) approx mu_2 mu_1 upright(bold(v)) = mu_1 mu_2 upright(bold(v)) . $

(At this point you might be concerned about this symbol $approx$ and
what happens to the size of the error. That’s an important issue, and
we’ll come back to it.)

Anyway, once you have AND and NOT, you can build arbitrary logic gates –
and this is what we mean when we say you can perform arbitrary
calculations on your encrypted bits, without ever learning what those
bits are. At the end of the calculation, you can send the resulting
ciphertexts back to be decrypted.

== The "Flatten" operation
<a-constraint-on-the-secret-key-mathbfv-and-the-flatten-operation>
In order to make the error estimates work out, we’re going to need to
make it so that all the ciphertext matrices $C$ have "small" entries. In
fact, we will be able to make it so that all entries of $C$ are either
$0$ or $1$.

To make this work, we will assume our secret key $upright(bold(v))$ has
the special form
#eqn[
  $ upright(bold(v)) = ( & a_1 , 2 a_1 , 4 a_1 , dots.h , 2^k a_1, \
    & a_2 , 2 a_2 , 4 a_2 , dots.h , 2^k a_2 , \
    & dots.v \
    & a_r , 2 a_r , 4 a_r , dots.h , 2^k a_r) , $
  <fhe-v-form>
]
where $k = ⌊log_2 q⌋$.

To see how this helps us, try the following puzzle. Assume $q = 11$ (so
all our vectors have entries modulo 11), and $r = 1$, so our secret key
has the form $ upright(bold(v)) = (a_1 , 2 a_1 , 4 a_1 , 8 a_1) . $ You
know $upright(bold(v))$ has this form, but you don’t know the specific
value of $a_1$.

Now suppose I give you the vector
$ upright(bold(x)) = (9 , 0 , 0 , 0) . $ I ask you for another vector
$ "Flatten"(upright(bold(x))) = upright(bold(x)) prime , $ where
$upright(bold(x)) prime$ has to have the following two properties:
- $upright(bold(x)) prime dot.op upright(bold(v)) = upright(bold(x)) dot.op upright(bold(v))$,
  and
- All the entries of $upright(bold(x)) prime$ are either 0 or 1.

And you have to find this vector $upright(bold(x)) prime$ without
knowing $a_1$.

The solution is to use binary expansion: take
$upright(bold(x)) prime = (1 , 0 , 0 , 1)$. You should check for
yourself to see why this works – it boils down to the fact that
$(1 , 0 , 0 , 1)$ is the binary expansion of $9$.

#problem[
How would you flatten a different vector, like
$ upright(bold(x)) = (9 , 3 , 1 , 4) ? $
As a hint, remember we’re working with numbers modulo 11: so if
you come across a number that’s bigger than 11 in your calculation, it’s
safe to reduce it mod 11.
]

In general, if you know that $upright(bold(v))$ has the form in @fhe-v-form
and you are given some matrix $C$ with coefficients in
$ZZ \/ q ZZ$, then you can compute another matrix $"Flatten"(C)$
such that:
- $"Flatten"(C) upright(bold(v)) = C upright(bold(v))$, and
- All the entries of $"Flatten"(C)$ are either 0 or 1.

The $"Flatten"$ process is essentially the same binary-expansion process
we used above to turn $upright(bold(x))$ into $upright(bold(x)) prime$,
applied to each $k + 1$ entries of each row of the matrix $C$.

So now, using this $"Flatten"$ operation, we can insist that all of our
ciphertexts $C$ are matrices with coefficients in ${ 0 , 1 }$. For
example, to multiply two messages $mu_1$ and $mu_2$, we first multiply
the corresponding ciphertexts, then flatten the resulting product:
$ "Flatten"(C_1 C_2) . $

Of course, revealing that the secret key $upright(bold(v))$ has this
special form will degrade security. This cryptosystem is as secure as an
LWE problem on vectors of length $r$, not $n$. So we need to make $n$
bigger, say $n approx r log q$, to get the same level of security.

== Error analysis
<error-analysis>
Now let’s compute more carefully what happens to the error when we add,
negate, and multiply bits. Suppose
$ C_1 upright(bold(v)) = mu_1 upright(bold(v)) + epsilon.alt_1 , $ where
$epsilon.alt_1$ is some vector with all its entries bounded by some
$B$. (And similarly for $C_2$ and $mu_2$.)

When we add two ciphertexts, the errors add:
$ (C_1 + C_2) upright(bold(v)) = (mu_1 + mu_2) upright(bold(v)) + (epsilon.alt_1 + epsilon.alt_2) . $
So the error on the sum will be bounded by $2 B$.

Negation is similar to addition – in fact, the error won’t change at
all.

Multiplication is more complicated, and this is why we insisted that all
ciphertexts have entries in ${ 0 , 1 }$. We compute
$ C_1 C_2 upright(bold(v)) = C_1 (mu_2 upright(bold(v)) + epsilon.alt_2) = mu_1 mu_2 upright(bold(v)) + (mu_2 epsilon.alt_1 + C_1 epsilon.alt_2) . $

Now since $mu_2$ is either $0$ or $1$, we know that $mu_2 epsilon.alt_1$
is a vector with all entries bounded by $B$. What about
$C_1 epsilon.alt_2$? Here we have to think carefully about matrix
multiplication: when you multiply an $n$-by-$n$ matrix by a vector, each
entry of the product comes as a sum of $n$ different products. Now we’re
assuming that $C_1$ is a $0$-$1$ matrix, and all entries of
$epsilon.alt_2$ are bounded by $B$… so the product has all entries
bounded by $n B$. Adding this to the error for $mu_2 epsilon.alt_1$, we
get that the total error in the product $C_1 C_2 upright(bold(v))$ is
bounded by $(n + 1) B$.

In summary: We can start with ciphertexts having a very small error (if
you think carefully about this
protocol, you will
see that the error is bounded by approximately $n log q$). Every
addition operation will double the error bound; every multiplication
(AND gate) will multiply it by $(n + 1)$. And you can’t allow the
error to exceed $q \/ 2$ – otherwise the message cannot be decrypted. So
you can perform calculations of up to approximately $log_n q$ steps. (In
fact, it’s a question of #emph[circuit depth];: you can start with many
more than $log_n q$ input bits, but no bit can follow a path of length
greater than $log_n q$ AND gates.)

This gives us a #emph[levelled] FHE protocol:
it lets us evaluate arbitrary circuits on encrypted data,
as long as those circuits have bounded depth.
If we need to evaluate a bigger circuit, we have two options:
+ Increase the value of $q$.
  Of course, the cost of the computations increases with $q$.
+ Use some technique to "reset" the error
  and start anew, as if with a freshly encrypted ciphertext. This approach is called _bootstrapping_ and it incurs some hefty
  computational costs.
  But for large circuits, it's the only viable option. Bootstrapping is beyond the scope of this book.
