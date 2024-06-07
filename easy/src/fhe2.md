$\newcommand{\ZZ}{\mathbb{Z}}$

# Public-Key Cryptography from Learning with Errors

The [learning with errors](https://notes.0xparc.org/notes/learning-with-errors-exercise) problem is one of those "hard problems that you can build cryptography on."  The problem is to solve for constants $a_1, \ldots, a_n \in \ZZ / q \ZZ$, given a bunch of _approximate_ equations of the form $$a_1 x_1 + \dots + a_n x_n = y + \epsilon,$$ where each $\epsilon$ is a "small" error (in the linked example, $\epsilon$ is either 0 or 1).

In Yan's [post](https://notes.0xparc.org/notes/learning-with-errors-exercise) we saw how even a small case of this problem ($q = 11$, $n = 4$) can be annoyingly tricky.  In the real world, you should imagine that $n$ and $q$ are much bigger -- maybe $n$ is in the range $100 \leq n \leq 1000$, and $q$ could be anywhere from $n^2$ to $2^{\sqrt{n}}$, say.

Now let's see how to turn this into a public-key cryptosystem.  We'll use the same numbers from the "blue set" in Yan's post.  In fact, that "blue set" will be exactly the public key.

| Public Key          |
| ------------------- |
| (1, 0, 1, 7) : 2    |
| (5, 8, 4, 10) : 9   |
| (7, 7, 8, 5) : 3    |
| (5, 1, 10, 6) : 3   |
| (8, 0, 2, 4) : 1    |
| (9, 3, 0, 6) : 9    |
| (0, 6, 1, 6) : 9    |
| (0, 4, 9, 7) : 5    |
| (10, 7, 4, 10) : 10 |
| (5, 5, 10, 6) : 8   |
| (10, 7, 3, 1) : 9   |
| (0, 2, 5, 5) : 6    |
| (9, 10, 2, 1) : 2   |
| (3, 7, 2, 1) : 5    |
| (2, 3, 4, 5) : 3    |
| (2, 1, 6, 9) : 3    |

The private key is simply the vector $a$.

| Private Key         |
| ------------------- |
| $\mathbf{a}$ = (10, 8, 10, 10) |

## How to encrypt $\mu$?

Suppose you have a message $m \in \{0, 5\}$.  (You'll see in a moment why we insist that $\mu$ is one of these two values.)  The cyphertext to encrypt $m$ will be a pair $(\mathbf{x} : y)$, where $x$ is a vector, $y$ is a scalar, and $\mathbf{x} \cdot \mathbf{a} + \epsilon = y + \mu$, where $\epsilon$ is "small".

How to do the encryption?  If you're trying to encrypt, you only have access to the public key -- that list of pairs $(\mathbf{x} : y)$ above.  You want to make up your own $\mathbf{x}$, for which you know approximately the value $\mathbf{x} \cdot \mathbf{a}$.  You could just take one of the vectors $\mathbf{x}$ from the table, but that wouldn't be very secure: if I see your cyphertext, I can find that $\mathbf{x}$ in the table and use it to decrypt $\mu$.

Instead, you are going to combine several rows of the table to get your vector $\mathbf{x}$.  Now you have to be careful: when you combine rows of the table, the errors will add up.  We're guaranteed that each row of the table has $\epsilon$ either $0$ or $1$.  So if you add at most $4$ rows, then the total $\epsilon$ will be at most $4$.  Since $\mu$ is either $0$ or $5$ (and we're working modulo $q = 11$), that's just enough to determine $\mu$ uniquely.

So, here's the method.  You choose at random 4 (or fewer) rows of the table, and add them up to get a pair $(\mathbf{x} : y_0)$ with $\mathbf{x} \cdot \mathbf{a} \approx y_0$.  Then you take $y = y_0 - \mu$ (mod $q = 11$ of course), and send the message $(\mathbf{x}: y)$.

## An example

Let's suppose you randomly choose the first 4 rows:

| Some rows of public key |
| ---- |
| (1, 0, 1, 7) : 2    |
| (5, 8, 4, 10) : 9   |
| (7, 7, 8, 5) : 3    |
| (5, 1, 10, 6) : 3   |

Now you add them up to get the following.
| $\mathbf{x} : y_0$ |
| - |
| (7, 5, 1, 6) : 6 |

Finally, let's say your message is $m = 5$.  So you set $y = y_0 - m = 6 - 5 = 1$, and send the cyphertext:
| $\mathbf{x} : y_0$ |
| - |
| (7, 5, 1, 6) : 1. |

## Decryption

Decryption is easy!  The decryptor knows $$\mathbf{x} \cdot \mathbf{a} + \epsilon = y + \mu$$ where $0 \leq \epsilon \leq 4$.

Plugging in $\mathbf{x}$ and $\mathbf{a}$, the decryptor computes $$\mathbf{x} \cdot \mathbf{a} = 4.$$  Plugging in $y = 1$, we see that $$4 + \epsilon = 1 + \mu.$$

Now it's a simple "rounding" problem.  We know that $\epsilon$ is small and positive, so $1 + \mu$ is either $4$ or ... a little more.  (In fact, it's one of $4, 5, 6, 7, 8$.)  On the other hand, since $\mu$ is 0 or 5, well, $1+\mu$ had better be 1 or 6... so the only possibility is that $1+\mu = 6$, and $\mu = 5$.

## How does this work in general?

In practice, $n$ and $q$ are often much larger.  Maybe $n$ is in the hundreds, and $q$ could be anywhere from "a little bigger than $n$" to "almost exponentially large in $n$," say $q = 2^{\sqrt{n}}$.  In fact, to do FHE, we're going to want to take $q$ pretty big, so you should imagine that $q \approx 2^{\sqrt{n}}$.

For security, the encryption algorithm shouldn't just take add up 3 or 4 rows of the public key.  In fact we want the encryption algorithm to add at least $\log(q^n) = n \log q$ rows -- to be safe, maybe make that number a little bigger, say $m = 2 n \log q$.  Of course, for this to work, the public key has to have at least $m$ rows.

So in practice, the public key will have $m = 2n \log q$ rows, and the encryption algorithm will be "select some subset of the rows at random, and add them up".

Of course, combining $m$ rows will have the effect of multiplying the error by $m$ -- so if the initial $\epsilon$ was bounded by $1$, then the error in the cyphertext will be at most $m$.  But remember that $q$ is exponentially large compared to $m$ and $n$ anyway, so a mere factor of $m$ isn't going to scare us!

Now we could insist that the message is just a single bit -- either $0$ or $\left \lfloor \frac{q}{2} \right \rfloor$.  Or we could allow the message to be any multiple of some constant $r$, where $r$ is bigger than the error bound (right now that's $m$) -- which allows you to encode a message space of size $q/r$ rather than just a single bit.

When we do FHE, we're going to apply many operations to a cyphertext, and each is going to cause the error to grow.  We're going to have to put some effort into keeping the error under control -- and then, when the error inevitably grows beyond the permissible bound, we'll need a special technique ("bootstrapping") to refresh the cyphertext and start anew.

