#import "preamble.typ":*

= Public-Key Cryptography from LWE
<lwe-crypto>

In @lwe-small
we saw how even a small case of this problem ($q = 11$, $n = 4$) can be
annoyingly tricky. In the real world, you should imagine that $n$ and
$q$ are much bigger – maybe $n$ is in the range
$100 lt.eq n lt.eq 1000$, and $q$ could be anywhere from $n^2$ to
$2^(sqrt(n))$, say.

As an example of how LWE can be used,
let’s see how to turn LWE into a public-key cryptosystem. We’ll use
the same numbers from the "blue set" in @lwe-small. In fact, that "blue
set" will be exactly the public key.

#figure(
  align(center)[#table(
    columns: 1,
    align: (auto,),
    table.header([Public Key],),
    table.hline(),
    [(1, 0, 1, 7) : 2],
    [(5, 8, 4, 10) : 2],
    [(7, 7, 8, 5) : 3],
    [(5, 1, 10, 6) : 10],
    [(8, 0, 2, 4) : 9],
    [(9, 3, 0, 6) : 9],
    [(0, 6, 1, 6) : 9],
    [(0, 4, 9, 7) : 5],
    [(10, 7, 4, 10) : 10],
    [(5, 5, 10, 6) : 9],
    [(10, 7, 3, 1) : 9],
    [(0, 2, 5, 5) : 6],
    [(9, 10, 2, 1) : 3],
    [(3, 7, 2, 1) : 6],
    [(2, 3, 4, 5) : 3],
    [(2, 1, 6, 9) : 3],
  )]
  , kind: table
  )

The private key is simply the vector $a$.

#figure(
  align(center)[#table(
    columns: 1,
    align: (auto,),
    table.header([Private Key],),
    table.hline(),
    [$upright(bold(a))$ = (10, 8, 10, 10)],
  )]
  , kind: table
  )

Since the LWE problem is hard,
we can release the public key to everybody,
and they will not be able to determine the private key.

== Encryption
<how-to-encrypt-mu>
Suppose you have a message $m in { 0 , 5 }$. (You’ll see in a moment why
we insist that $mu$ is one of these two values.) The ciphertext to
encrypt $m$ will be a pair $(upright(bold(x)) : y)$, where $x$ is a
vector, $y$ is a scalar, and
$upright(bold(x)) dot.op upright(bold(a)) + epsilon.alt = y + m$, where
$epsilon.alt$ is "small".

How to do the encryption? If you’re trying to encrypt, you only have
access to the public key -- that list of pairs $(upright(bold(x)) : y)$
above. You want to make up your own $upright(bold(x))$, for which you
know approximately the value $upright(bold(x)) dot.op upright(bold(a))$.
You could just take one of the vectors $upright(bold(x))$ from the
table, but that wouldn’t be very secure: if I see your ciphertext, I can
find that $upright(bold(x))$ in the table and use it to decrypt $mu$.

Instead, you are going to combine several rows of the table to get your
vector $upright(bold(x))$. Now you have to be careful: when you combine
rows of the table, the errors will add up. We’re guaranteed that each
row of the table has $epsilon.alt$ either $0$ or $1$. So if you add at
most $4$ rows, then the total $epsilon.alt$ will be at most $4$. Since
$mu$ is either $0$ or $5$ (and we’re working modulo $q = 11$), that’s
just enough to determine $mu$ uniquely.

So, here’s the method. You choose at random 4 (or fewer) rows of the
table, and add them up to get a pair $(upright(bold(x)) : y_0)$ with
$upright(bold(x)) dot.op upright(bold(a)) approx y_0$. Then you take
$y = y_0 - m$ (mod $q = 11$ of course), and send the message
$(upright(bold(x)) : y)$.

== An example
<an-example>
Let’s say you randomly choose the 4 rows:

#figure(
  align(center)[#table(
    columns: 1,
    align: (auto,),
    table.header([Some rows of public key],),
    table.hline(),
    [(1, 0, 1, 7) : 2],
    [(5, 8, 4, 10) : 2],
    [(7, 7, 8, 5) : 3],
    [(5, 1, 10, 6) : 10],
  )]
  , kind: table
  )

Now you add them up to get the following.
#figure(
  align(center)[#table(
    columns: 1,
    align: (auto,),
    table.header([$upright(bold(x)) : y_0$],),
    [(7, 5, 1, 6) : 6],
)],
  kind: table
)
(For reference, the actual value is $4$, so our accumulated error is $2$.)

Finally, let’s say your message is $m = 5$. So you set
$y = y_0 - m = 6 - 5 = 1$, and send the ciphertext:
#figure(
  align(center)[#table(
    columns: 1,
    align: (auto,),
    table.header([$upright(bold(x)) : y$],),
    [(7, 5, 1, 6) : 1],
)],
  kind: table
)

== Decryption
<decryption>
Decryption is easy! The decryptor knows
$ upright(bold(x)) dot.op upright(bold(a)) + epsilon.alt = y + m $
where $0 lt.eq epsilon.alt lt.eq 4$.

Plugging in $upright(bold(x))$ and $upright(bold(a))$, the decryptor
computes $ upright(bold(x)) dot.op upright(bold(a)) = 4 . $ Plugging in
$y = 1$, we see that $ 4 + epsilon.alt = 1 + m . $

Now it’s a simple "rounding" problem. We know that $epsilon.alt$ is
small and positive, so $1 + m$ is either $4$ or … a little more.
(In fact, it’s one of $4 , 5 , 6 , 7 , 8$.) On the other hand, since $m$ is
0 or 5, $1 + m$ had better be 1 or 6, so the only possibility is
that $m = 5$ (so $1+m = 6$).

== How does this work in general?
<how-does-this-work-in-general>
In practice, $n$ and $q$ are often much larger. Maybe $n$ is in the
hundreds, and $q$ could be anywhere from "a little bigger than $n$" to
"almost exponentially large in $n$," say $q = 2^(sqrt(n))$. In fact, to
do FHE, we’re going to want to take $q$ pretty big, so you should
imagine that $q approx 2^(sqrt(n))$.

For security, instead of adding $4$ rows of the public key, we want to add
at least $log (q^n) = n log q$ rows. To be safe, maybe a little bigger, say
$N = 2 n log q$ (of course, for this to work, the
public key has to have at least $N$ rows). The
encryption algorithm will be "select some subset of the rows at random,
and add them up".

Combining $N$ rows will have the effect of multiplying the
error by $N$, so if the initial $epsilon.alt$ was bounded by $1$, then
the error in the ciphertext will be at most $N$. But remember that $q$
is exponentially large compared to $N$ and $n$ anyway, so a mere factor
of $N$ should not scare us!

To generalize our choice of $m$ in $\{0,5\}$, we could encode a single bit
by using either $0$ or $⌊q / 2⌋$ to obtain maximum separation and thus
tolerance to error. Alternatively, we could allow the message to be any
multiple of some constant $r$, where $r$ is bigger than the error bound (right
now that’s $m$), which allows you to encode a message space of size $q \/ r$
rather than just a single bit.

When we do FHE, we’re going to apply many operations to a ciphertext,
and each is going to cause the error to grow. We’re going to have to put
some effort into keeping the error under control,
and the size of $q\/ r$ will determine how many operations
we can do before the error grows too big.
