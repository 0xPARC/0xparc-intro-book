#import "preamble.typ":*

#takeaway[ORAM takeaways][
1. _Oblivious RAM_ is a system to hide memory access patterns from a server.
2. The server stores encrypted data blocks in a binary tree,
  and it does not learn which blocks correspond to which memory items.
3. Every time the ORAM client accesses a block, it writes that block back to the root.
4. A randomized eviction procedure moves blocks away from the root,
  so individual nodes of the tree don't overflow.
]
