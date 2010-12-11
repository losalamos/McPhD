{-# OPTIONS_GHC -XMultiParamTypeClasses #-}

module Particles.Simple where

import Space
import Particles.Classes

-- A Simple particle.

data SimpleParticle = Simple { s_p :: Position,  s_d :: Direction } deriving Show
instance InSpace SimpleParticle where
  position   = s_p
  direction  = s_d
  
instance Advance SimpleParticle where
  advance particle distance =  Simple (move particle distance) (direction particle)


