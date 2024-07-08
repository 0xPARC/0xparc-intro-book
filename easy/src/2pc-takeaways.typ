#import "preamble.typ":*

= 2PC Takeaways

#green[
1. A _garbled circuit_ allows Alice and Bob to jointly compute some 
  function over their respective secret inputs. We can think of this 
  as your prototypical _2PC_ (two-party computation).
2. The main ingredient of a garbled circuit is _garbled gates_, 
  which area gates whose functionality is hidden. This can be done 
  by Alice precomputing different outputs of the garbled circuit 
  based on all possible inputs of Bob, and then letting Bob pick one.
3. Bob "picks an input" with the technique of _oblivious transfer (OT)_. 
  This can be built in various ways, including with commutative 
  encryption or public-key cryptography.
4. More generally, it is also possible for a group of people to
  compute whatever secret function they want, which is the field of 
  _multiparty computation (MPC)_.
]
