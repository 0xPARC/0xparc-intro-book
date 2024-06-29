#import "preamble.typ":*

= Introduction to FHE
<fhe-intro>

Alice has a secret $x$, and Bob has a function $f$.
They want to compute $f(x)$.
Actually, Alice wants Bob to compute $f(x)$ -- but
she doesn't want to tell him $x$.

Alice wants to encrypt $x$ and send Bob $Enc (x)$.
Then Bob is going to "apply $f$ to the ciphertext",
to turn $Enc (x)$ into $Enc (f(x))$.
Finally, Bob sends $Enc (f(x))$ back,
and Alice decrypts it to learn $f(x)$. This is _fully homomorphic encryption (FHE)_.

_Levelled FHE_ is a sort of weaker version of FHE. Like FHE, levelled FHE
lets you perform operations on encrypted data. But unlike FHE, there
will be a limit on the number of operations you can perform before the
data must be decrypted.

Loosely speaking, the encryption procedure will involve some sort of
"noise" or "error." As long as the error is not too big, the message can
be decoded without trouble. But each operation on the encrypted data
will cause the error to grow – and if it grows beyond some maximum error
tolerance, the message will be lost. So there is a limit on how many
operations you can do before the error gets too big.

As a sort of silly example, imagine your message is a whole number
between 0 and 10 (so it’s one of 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10), and
your "encryption" scheme encodes the message as a real number that is
very close to the message. So if the ciphertext is 1.999832, well then
that means the original message was 2. The decryption procedure is
"round to the nearest integer."

(You might be thinking: This is some pretty terrible cryptography,
because the message isn’t secure. Anyone can figure out how to round a
number, no secret key required. Yep, you’re right. The actual encryption
#link("https://hackmd.io/mQB8_nWPTm-Kyua7QgNLNw")[scheme] is more
complicated. But it still has this "rounding-off-errors" feature, and
that’s what I want to focus on right now.)

Now imagine that the "operations" you want to perform are addition. (If
you like, imagine doing the addition modulo 11, so if a number gets too
big, it "wraps around.") Well, every time you add two encrypted numbers
($1.999832 + 2.999701 = 4.999533$), the errors add as well. After too
many operations, the error will exceed $0.5$, and the rounding procedure
won’t give the right answer anymore. But as long as you’re careful not to go over the error limit, you can
add ciphertexts with confidence.

For our levelled FHE protocol, our message will be a bit (either 0 or 1) and
our operations will be the logic gates AND and NOT. Because any logic circuit can be built out of AND and NOT gates, we'll be able to perform arbitrary calculations
within the FHE encryption.

Our protocol uses a cryptosystem built
from a problem called "learning with errors."
"Learning with errors" is kind of a strange name;
We'd call it "approximate linear algebra modulo $q$."
Anyway, we'll start with the learning-with-errors problem
(@lwe) and how to build cryptography on top of it (@lwe-crypto)
before we get back to levelled FHE.
