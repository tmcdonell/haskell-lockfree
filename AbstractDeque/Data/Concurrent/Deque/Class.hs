{-# LANGUAGE TypeFamilies, CPP, TypeSynonymInstances, MultiParamTypeClasses,
    FlexibleInstances #-}

module Data.Concurrent.Deque.Class where 

import Prelude hiding (Bounded)

----------------------------------------------------------------------------------------------------

-- * The choices that select a queue-variant.

-- | Choice #1 -- thread saftety.
data Threadsafe
data Nonthreadsafe

-- | Choice #2 -- double or or single functionality (push/pop) on EACH end.
data SingleEnd
data DoubleEnd

-- | Choice #3 -- bounded or growing queues:
data Bound
data Grow

-- | Choice #4 -- duplication of elements.
data Safe  -- | Will not duplicate elements.
data Dup   -- | Possibly duplicating elements on pop.
-- data Lossy -- I know of no algorithm which would motivate having a Lossy mode.

------------------------------------------------------------

-- * Aliases for more concise Deque types:
type T  = Threadsafe
type NT = Nonthreadsafe
type S  = SingleEnd
type D  = DoubleEnd

--------------------------------------------------------------------------------
-- Example queue creation functions:

-- Minimally functional Q
newQ :: IO (Deque NT NT S S Bound Safe elt)
newQ = undefined

-- Maximally functional Q
newQ2 :: IO (Deque T T D D Grow Safe elt)
newQ2 = undefined

--------------------------------------------------------------------------------

-- Considering two formulations for the type family.  The first
-- variant separates the data family from the type class and thereby
-- hides the (excessive) six phantom-type parameters, at the expense
-- of introducing a bunch of type auxilary type classes.

#if 1
    
data family Deque lThreaded rThreaded lDbl rDbl bnd safe elt 

class DequeClass d where
   pushL :: d elt -> elt -> IO ()
   popR  :: d elt -> IO elt

-- In spite of hiding the extra phantom type parameters in the
--  DequeClass, we wish to retain the ability for clients to constrain
--  the set of implementations they work with **statically**.
class DequeClass d => PopL d where 
   popL  :: d elt -> IO elt
class DequeClass d => PushR d where 
   pushR :: d elt -> elt -> IO ()
class DequeClass d => Bounded d where 
   tryPushL :: d elt -> elt -> IO Bool
class PushR d => BoundedPushR d where 
   tryPushR :: d elt -> elt -> IO Bool

------------------------------------------------------------
-- Examples / Tests:

-- Test:
data instance Deque NT NT S S Bound Safe elt = DequeL [elt]
foo (DequeL []) = "hello"

bar :: Deque T T D D Grow Safe elt -> elt
bar q = undefined

instance DequeClass (Deque T T S S Grow Safe) where 
  pushL = undefined
  popR  = undefined

instance DequeClass (Deque T T D D Grow Safe) where 
  pushL = undefined
  popR  = undefined
instance PopL       (Deque T T D D Grow Safe) where 
  popL  = undefined
instance PushR      (Deque T T D D Grow Safe) where 
  pushR = undefined

-- The problem here is that there's no way for an implementation to 

test :: (Num elt, PopL d, BoundedPushR d, Bounded d) => d elt -> IO Bool
test x = do popL x; pushR x 3; tryPushR x 3; tryPushL x 3


#else

-- | The highly-paramewerized type for Deques.
class DequeLike lThreaded rThreaded lDbl rDbl bnd safe elt where
   data Deque lThreaded rThreaded lDbl rDbl bnd safe elt :: *

   -- Example, work stealing deque: (Deque NT T  D S Grow elt)
   --
   -- But really you never want to overconsrain by forcing the
   -- less-functional option when accepting a queue as input to a
   -- function.
   --   So rather than (Deque NT D T S Grow elt)
   --   You would probably want: (Deque nt D T s Grow elt)
   --     Could also nest this I guess:  (Deque (D nt) (S T) Grow elt)

   -- ----------------------------------------------------------
   -- * Natural queue operations that hold for all single, 1.5, and double ended modes.

   -- | Natural push: push left
   pushL :: Deque lt rt l r  bnd sf elt -> elt -> IO ()

   -- | Natural pop: pop right.
   popR  :: Deque lt rt l r bnd sf elt -> IO elt

   -- ----------------------------------------------------------
   -- * The "unnatural" double ended cases: pop left, push right.

   -- | PopL is not the native operation for the left end, so it requires
   --   that the left end be a "Double", but places no other requirements
   --   on the input queue.
   -- 
   --   The implementation is requiredy to block or spin until an element is available.
   popL :: Deque lt rt DoubleEnd r bnd sf elt -> IO elt
   popL = undefined

   -- -- Should the normal popL require thread safety?  Here's a potentially single-threaded pop:
   -- spopL :: DblEnded a => Deque a b  c elt -> elt -> IO ()
   -- spopL = undefined

   -- | Pushing is not the native operation for the right end, so it requires
   --   that end be a "Double".
   pushR :: Deque lt rt l DoubleEnd bnd sf elt -> elt -> IO ()
   pushR = undefined

   -- ------------------------------------------------------------
   -- * Operations on bounded queues.

   -- tryPush REQUIRES bounded:
   tryPushL :: Deque lt rt l  r        Bound safe elt -> elt -> IO Bool
   tryPushR :: Deque lt rt l DoubleEnd Bound safe elt -> elt -> IO Bool


#endif
