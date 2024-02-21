{-# LANGUAGE Trustworthy #-}
{-# LANGUAGE NoImplicitPrelude #-}

-- |
-- Module      :  GHC.Internal.Control.Monad.Fail
-- Copyright   :  (C) 2015 David Luposchainsky,
--                (C) 2015 Herbert Valerio Riedel
-- License     :  BSD-style (see the file LICENSE)
--
-- Maintainer  :  libraries@haskell.org
-- Stability   :  provisional
-- Portability :  portable
--
-- Transitional module providing the 'MonadFail' class and primitive
-- instances.
--
-- This module can be imported for defining forward compatible
-- 'MonadFail' instances:
--
-- @
-- import qualified GHC.Internal.Control.Monad.Fail as Fail
--
-- instance Monad Foo where
--   (>>=) = {- ...bind impl... -}
--
--   -- Provide legacy 'fail' implementation for when
--   -- new-style MonadFail desugaring is not enabled.
--   fail = Fail.fail
--
-- instance Fail.MonadFail Foo where
--   fail = {- ...fail implementation... -}
-- @
--
-- See <https://gitlab.haskell.org/haskell/prime/-/wikis/libraries/proposals/monad-fail>
-- for more details.
--
-- @since base-4.9.0.0
--
module GHC.Internal.Control.Monad.Fail ( MonadFail(fail) ) where

import GHC.Internal.Base (String, Monad(), Maybe(Nothing), IO(), failIO)

-- | When a value is bound in @do@-notation, the pattern on the left
-- hand side of @<-@ might not match. In this case, this class
-- provides a function to recover.
--
-- A 'Monad' without a 'MonadFail' instance may only be used in conjunction
-- with pattern that always match, such as newtypes, tuples, data types with
-- only a single data constructor, and irrefutable patterns (@~pat@).
--
-- Instances of 'MonadFail' should satisfy the following law: @fail s@ should
-- be a left zero for 'Control.Monad.>>=',
--
-- @
-- fail s >>= f  =  fail s
-- @
--
-- If your 'Monad' is also 'Control.Monad.MonadPlus', a popular definition is
--
-- @
-- fail _ = mzero
-- @
--
-- @fail s@ should be an action that runs in the monad itself, not an
-- exception (except in instances of @MonadIO@).  In particular,
-- @fail@ should not be implemented in terms of @error@.
--
-- @since base-4.9.0.0
class Monad m => MonadFail m where
    fail :: String -> m a


-- | @since base-4.9.0.0
instance MonadFail Maybe where
    fail _ = Nothing

-- | @since base-4.9.0.0
instance MonadFail [] where
    {-# INLINE fail #-}
    fail _ = []

-- | @since base-4.9.0.0
instance MonadFail IO where
    fail = failIO
