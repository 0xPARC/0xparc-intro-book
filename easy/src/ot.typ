#import "preamble.typ":*

= Oblivious Transfer
<ot>

Alice has $n$ messages $x_1, dots, x_n$.
Bob wants to request the $i$-th message,
without letting Alice learn anything about the value of $i$.
Alice wants to send Bob $x_i$,
without letting him learn anything about the other $n-1$ messages. An _oblivious transfer (OT)_ allows Alice to transfer a single message to Bob, but she remains oblivious as to which message she has transferred. We'll see two simple protocols to achieve this.

(In fact, for two-party computation,
we only need "1-of-2 OT":
Alice has $x_1$ and $x_2$, and she wants to send one of
those two to Bob.
But "1-of-$n$ OT" isn't any harder, so we'll do 1-of-$n$.)

== Commutative encryption

Let's imagine that Alice and Bob
have access to some encryption scheme that is _commutative_:
$
  Dec_B( Dec_A
  ( Enc_B
  ( Enc_A(x) ) ) )
  = x.
$

In other words, if Alice encrypts a message,
and Bob applies a second-layer of encryption to the encrypted message,
it doesn't matter which order Alice and Bob decrypt the message in --
they will still get the original message back.

A metaphor for commutative encryption
is a box that's locked with two padlocks.
Alice puts a message inside the box,
lock it with her lock, and ship it to Bob.
Bob puts his own lock back on the box and ships it back to Alice.
What's special about commutative encryption
is that Bob's lock doesn't block Alice from unlocking her own --
so Alice can remove her lock and send it back to Bob,
and then Bob removes his lock and recovers the message.

Mathematically, you can get commutative encryption
by working in a finite group (for example $ZZ_p^times$, or an elliptic curve).
1. Alice's secret key is an integer $a$;
she encrypts a message $g$ by raising it to the $a$-th power,
and she sends Bob $g^a$.
2. Bob encrypts again with his own secret key $b$,
and he sends $(g^a)^b = g^(a b)$ back to Alice.
3. Now Alice removes her lock by taking an $a$-th root. The result is $g^b$, which she sends back to Bob. And Bob takes another $b$-th root, recovering $g$.

== OT using commutative encryption

Our first oblivious transfer protocol is built on the commutative encryption we just described.

Alice has $n$ messages $x_1, dots, x_n$, which we may as well assume are elements of the group $G$. Alice chooses a secret key $a$, encrypts each message, and sends all $n$ ciphertexts to Bob:
$
  Enc_a(x_1), dots, Enc_a(x_n).
$

But crucially, Alice sends the ciphertexts in order, so Bob knows which is which.

At this point, Bob can't read any of the messages,
because he doesn't know the keys.
No problem!
Bob just picks out the $i$-th ciphertext $Enc_a(x_i)$,
adds his own layer of encryption onto it,
and sends the resulting doubly-encoded message back to Alice:
$
  Enc_b(Enc_a(x_i)).
$

Alice doesn't know Bob's key $b$,
so she can't learn anything about the message he encrypted --
even though it originally came from her.
Nonetheless she can apply her own decryption method
$Dec_a$ to it.
Since the encryption scheme is commutative,
the result of Alice's decryption is simply
$
  Enc_b(x_i),
$
which she sends back to Bob.

And Bob decrypts the message to learn $x_i$.

== OT in one step

The protocol above required one and a half rounds of communication:
Alice sent two messages to Bob, and Bob sent one message back to Alice.

We can do better, using public-key cryptography.

Let's start with a simplified protocol that is not quite secure.
The idea is for Bob to send Alice $n$ keys
$
b_1, dots, b_n.
$

One of the $n$, say $b_i$, is a public key for which Bob knows the private key. The other $n-1$ are random garbage.

Alice then uses one key to encrypt each message, and sends back to Bob:
$
Enc_(b_1)(x_1), dots, Enc_(b_n)(x_n).
$

Now Bob uses the private key for $b_i$ to decrypt $x_i$, and he's done.

Is Bob happy with this protocol? Yes.
Alice has no way of learning the value of $i$,
as long as she can't distinguish a true public key
from a random fake key (which is true of public-key schemes in practice).

But is Alice happy with it? Not so much.
A cheating Bob could send $n$ different public keys,
and Alice has no way to detect it --
like we just said, Alice can't tell random garbage from a true public key!
And then Bob would be able to decrypt all $n$ messages $x_1, dots, x_n$.

But there's a simple trick to fix it.
Bob chooses some "verifiably random" value $r$;
to fix ideas, we could agree to use $r = sha(1)$.
Then we require that the numbers $b_1, dots, b_n$
form an arithmetic progression with common difference $r$.
 Bob chooses $i$, computes a public-private key pair,
 and sets $b_i$ equal to that key.
 Then all the other terms $b_1, dots, b_n$
 are determined by the arithmetic progression requirement $b_j = b_i + (j-i)r$.
 (Or if the keys are elements of a group in multiplicative notation,
 we could write this as $b_j = r^(j-i) dot b_i$.)

Is this secure?
If we think of the hash function as a random-number generator,
then all $n-1$ "garbage keys" are effectively random values.
So now the question is:
Can Bob compute a private key for a given (randomly generated) public key?
It's a standard assumption in public-key cryptography that Bob can't do this:
there's no algorithm that reads in a public key and spits out the corresponding private key.
(Otherwise, the whole enterprise is doomed.)
So Alice is guaranteed that Bob only knows how to decrypt (at most) one message.

In fact, some public-key cryptosystems (like ElGamal)
have a sort of "homomorphic" property:
If you know the private keys for to two different public keys $b_1$ and $b_2$,
then you can compute the private key for the public key $b_2 b_1^(-1)$.
(In ElGamal, this is true because the private key is just a discrete logarithm.)
So, if Bob could dishonestly decrypt two of Alice's messages,
he could compute the private key for the public key $r$.
But $r$ is verifiably random,
and it's very hard (we assume) for Bob to find a private key for a random public key.
