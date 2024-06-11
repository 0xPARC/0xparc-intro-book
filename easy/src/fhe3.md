$\newcommand{\ZZ}{\mathbb{Z}}$

# Levelled Fully Homomorphic Encryption from Learning with Errors

This is part of a series of posts where we explain how to do fully homomorphic encryption (FHE). FHE lets you encrypt a message, and then other people can perform arbitrary operations on the encrypted message without being able to read the message.

Levelled FHE is a sort of weaker version of FHE. Like FHE, levelled FHE lets you perform operations on encrypted data. But unlike FHE, there will be a limit on the number of operations you can perform before the data must be decrypted.

Loosely speaking, the encryption procedure will involve some sort of "noise" or "error." As long as the error is not too big, the message can be decoded without trouble. But each operation on the encrypted data will cause the error to grow -- and if it grows beyond some maximum error tolerance, the message will be lost. So there is a limit on how many operations you can do before the error gets too big.

As a sort of silly example, imagine your message is a whole number between 0 and 10 (so it's one of 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10), and your "encryption" scheme encodes the message as a real number that is very close to the message. So if the ciphertext is 1.999832, well then that means the original message was 2. The decryption procedure is "round to the nearest integer."

(You might be thinking: This is some pretty terrible cryptography, because the message isn't secure. Anyone can figure out how to round a number, no secret key required. Yep, you're right. The actual encryption [scheme](https://hackmd.io/mQB8_nWPTm-Kyua7QgNLNw) is more complicated. But it still has this "rounding-off-errors" feature, and that's what I want to focus on right now.)

Now imagine that the "operations" you want to perform are addition. (If you like, imagine doing the addition modulo 11, so if a number gets too big, it "wraps around.") Well, every time you add two encrypted numbers ($1.999832 + 2.999701 = 4.999533$), the errors add as well. After too many operations, the error will exceed $0.5$, and the rounding procedure won't give the right answer anymore.

But as long as you're careful not to go over the error limit, you can add ciphertexts with confidence.

## The main idea: Approximate eigenvalues

If you haven't already, this might be a good time to go back and read about the [learning with errors](https://notes.0xparc.org/notes/learning-with-errors-exercise) problem and how you can use it to do [public-key cryptography](https://hackmd.io/mQB8_nWPTm-Kyua7QgNLNw).

You should at least understand the vague idea: We're going pick some large integer $q$ (in practice $q$ could be anywhere from a few thousand to $2^{1000}$), and do "approximate linear algebra" modulo $q$. In other words, we'll do linear algebra, where all our calculations are done modulo $q$ -- but we'll also allow the calculations to have a small "error" $\epsilon$, which will typically be much, much smaller than $q$.

Here's the setup. Our _secret key_ will be a vector $\mathbf{v} = (v_1, \ldots, v_n) \in (\ZZ / q \ZZ)^n$ -- a vector of length $n$, where the entries are integers modulo $q$. Suppose we want to encode a message $\mu$ that's just a single bit, let's say $\mu \in \{0, 1\}$. Our ciphertext will be a square $n$-by$n$ matrix $C$ such that $$C \mathbf{v} \approx \mu \mathbf{v}.$$ Now if we assume that $\mathbf{v}$ has at least one "big" entry (say $v_i$), then decryption is easy: Just compute the $i$-th entry of $C \mathbf{v}$, and determine whether it is closer to $0$ or to $v_i$.

With a bit of effort, it's possible to make this into a public-key cryptosystem. The main idea is to release a [table](https://hackmd.io/mQB8_nWPTm-Kyua7QgNLNw) of vectors $\mathbf{x}$ such that $\mathbf{x} \cdot \mathbf{v} \approx 0$, and use that as a public key. Given $\mu$ and the public key, you can find a matrix $C_0$ such that $C_0 \mathbf{v} \approx 0$ -- then take $C = C_0 + \mu *\mathrm{Id}$, where $\mathrm{Id}$ is the identity matrix. And $C_0$ can be built row-by-row... but we won't get into the details here.

Indeed homomorphic encryption is already interesting without the public-key feature. If you assume the person encrypting the data knows $\mathbf{v}$, it's easy (linear algebra, again) to find $C$ such that $C \mathbf{v} \approx \mu \mathbf{v}$.

To make homomorphic encryption work, we need to explain how to operate on $\mu$. We'll describe three operations: addition, NOT, and multiplication (aka AND).

Addition is simple: Just add the matrices. If $C_1 \mathbf{v} \approx \mu_1 \mathbf{v}$ and $C_2 \mathbf{v} \approx \mu_2 \mathbf{v}$, then $$(C_1 + C_2) \mathbf{v} = C_1 \mathbf{v} + C_2 \mathbf{v} \approx \mu_1 \mathbf{v} + \mu_2 \mathbf{v} = (\mu_1 + \mu_2) \mathbf{v}.$$ Of course, addition on bits isn't a great operation, because if you add $1+1$, you get $2$, and $2$ isn't a legitimate bit anymore. So we won't really use this.

Negation of a bit (NOT) is equally simple, though. If $\mu \in \{0, 1 \}$ is a bit, then its negation is simply $1 - \mu$. And if $C$ is a ciphertext for $\mu$, then $\mathrm{Id} - C$ is a ciphertext for $1 - \mu$, since $$(\mathrm{Id} - C) \mathbf{v} = \mathbf{v} - C \mathbf{v} \approx (1 - \mu) \mathbf{v}.$$

Multiplication is also a good operation on bits -- it's just AND. To multiply two bits, you just multiply (matrix multiplication) the ciphertexts: $$C_1 C_2 \mathbf{v} \approx C_1 (\mu_2 \mathbf{v}) = \mu_2 C_1 \mathbf{v} \approx \mu_2 \mu_1 \mathbf{v} = \mu_1 \mu_2 \mathbf{v}.$$

(At this point you might be concerned about this symbol $\approx$ and what happens to the size of the error. That's an important issue, and we'll come back to it.)

Anyway, once you have AND and NOT, you can build arbitrary logic gates -- and this is what we mean when we say you can perform arbitrary calculations on your encrypted bits, without ever learning what those bits are. At the end of the calculation, you can send the resulting ciphertexts back to be decrypted.

## A constraint on the secret key $\mathbf{v}$ and the "Flatten" operation

In order to make the error estimates work out, we're going to need to make it so that all the ciphertext matrices $C$ have "small" entries. In fact, we will be able to make it so that all entries of $C$ are either $0$ or $1$.

To make this work, we will assume our secret key $\mathbf{v}$ has the special form $$\mathbf{v} = (a_1, 2 a_1, 4 a_1, \ldots, 2^k a_1, a_2, 2 a_2, 4 a_2, \ldots, 2^k a_2, \ldots, a_r, 2 a_r, 4 a_r, \ldots, 2^k a_r),$$ where $k = \left \lfloor \log_2 q \right \rfloor$.

To see how this helps us, try the following puzzle. Assume $q = 11$ (so all our vectors have entries modulo 11), and $r = 1$, so our secret key has the form $$\mathbf{v} = (a_1, 2 a_1, 4 a_1, 8 a_1).$$ You know $\mathbf{v}$ has this form, but you don't know the specific value of $a_1$.

Now suppose I give you the vector $$\mathbf{x} = (9, 0, 0, 0).$$ I ask you for another vector $$\operatorname{Flatten}(\mathbf{x}) = \mathbf{x}',$$ where $\mathbf{x}'$ has to have the following two properties:

- $\mathbf{x}' \cdot \mathbf{v} = \mathbf{x} \cdot \mathbf{v}$, and
- All the entries of $\mathbf{x}'$ are either 0 or 1.

And you have to find this vector $\mathbf{x}'$ without knowing $a_1$.

The solution is to use binary expansion: take $\mathbf{x}' = (1, 0, 0, 1)$. You should check for yourself to see why this works -- it boils down to the fact that $(1, 0, 0, 1)$ is the binary expansion of $9$.

How would you flatten a different vector, like $$\mathbf{x} = (9, 3, 1, 4)?$$ I'll leave this as an exercise to you! As a hint, remember we're working with numbers modulo 11 -- so if you come across a number that's bigger than 11 in your calculation, it's safe to reduce it mod 11.

Similarly, if you know $\mathbf{v}$ has the form $$\mathbf{v} = (a_1, 2 a_1, 4 a_1, \ldots, 2^k a_1, a_2, 2 a_2, 4 a_2, \ldots, 2^k a_2, \ldots, a_r, 2 a_r, 4 a_r, \ldots, 2^k a_r),$$ and you are given some matrix $C$ with coefficients in $\ZZ / q \ZZ$, then you can compute another matrix $\operatorname{Flatten}(C)$ such that:

- $\operatorname{Flatten}(C) \mathbf{v} = C \mathbf{v}$, and
- All the entries of $\operatorname{Flatten}(C)$ are either 0 or 1.

The $\operatorname{Flatten}$ process is essentially the same binary-expansion process we used above to turn $\mathbf{x}$ into $\mathbf{x}'$, applied to each $k+1$ entries of each row of the matrix $C$.

So now, using this $\operatorname{Flatten}$ operation, we can insist that all of our ciphertexts $C$ are matrices with coefficients in $\{0, 1\}$. For example, to multiply two messages $\mu_1$ and $\mu_2$, we first multiply the corresponding ciphertexts, then flatten the resulting product: $$\operatorname{Flatten}(C_1 C_2).$$

Of course, revealing that the secret key $\mathbf{v}$ has this special form will degrade security. This cryptosystem is as secure as an LWE problem on vectors of length $r$, not $n$. So we need to make $n$ bigger, say $n \approx r \log q$, to get the same level of security.

## Error analysis

Now let's compute more carefully what happens to the error when we add, negate, and multiply bits. Suppose $$C_1 \mathbf{v} = \mu_1 \mathbf{v} + \epsilon_1,$$ where $\epsilon$ is some vector with all its entries bounded by a bound $B$. (And similarly for $C_2$ and $\mu_2$.)

When we add two ciphertexts, the errors add: $$(C_1 + C_2) \mathbf{v} = (\mu_1 + \mu_2) \mathbf{v} + (\epsilon_1 + \epsilon_2).$$ So the error on the sum will be bounded by $2B$.

Negation is similar to addition -- in fact, the error won't change at all.

Multiplication is more complicated, and this is why we insisted that all ciphertexts have entries in $\{0, 1\}$. We compute $$C_1 C_2 \mathbf{v} = C_1 (\mu_2 \mathbf{v} + \epsilon_2) = \mu_1 \mu_2 \mathbf{v} + (\mu_2 \epsilon_1 + C_1 \epsilon_2).$$

Now since $\mu_2$ is either $0$ or $1$, we know that $\mu_2 \epsilon_1$ is a vector with all entries bounded by $B$. What about $C_1 \epsilon_2$? Here you have to think for a second about matrix multiplication: when you multiply an $n$-by-$n$ matrix by a vector, each entry of the product comes as a sum of $n$ different products. Now we're assuming that $C_1$ is a $0-1$ matrix, and all entries of $\epsilon_2$ are bounded by $B$... so the product has all entries bounded by $nB$. Adding this to the error for $\mu_2 \epsilon_1$, we get that the total error in the product $C_1 C_2 \mathbf{v}$ is bounded by $(n+1)B$.

In summary: We can start with ciphertexts having a very small error (if you think carefully about this [protocol](https://hackmd.io/mQB8_nWPTm-Kyua7QgNLNw), you will see that the error is bounded by approximately $n \log q$). Every addition operation will double the error bound; every multiplication ("and" gate) will multiply it by $(n+1)$. And you can't allow the error to exceed $q/2$ -- otherwise the message cannot be decrypted. So you can perform calculations of up to approximately $\log_n q$ steps. (In fact, it's a question of _circuit depth_: you can start with many more than $\log_n q$ input bits, but no bit can follow a path of length greater than $\log_n q$ AND gates.)

This gives us a _levelled_ fully homomorphic encryption protocol. Next we'll see a trick called "bootstrapping," which lets us turn this into FHE.
