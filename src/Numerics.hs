{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-- A module for various numeric definitions useful in building
domain-specific numeric types

For each new type, there are various functions defined:

  makeFoo        :: Double -> Maybe Foo  Create a Foo if the input is acceptable
  unsafe_makeFoo :: Double -> Foo        Create a Foo which may be invalid. User beware!
  sampleFoo      :: Var    -> Foo        Maps Var values uniformly onto Foos

  This looks like an opportunity for a new class.

--}
module Numerics where

import Approx

-- | A newtype for aribtrary values in (0,1)
newtype UnitInterval n = UnitInterval n deriving (Show, Eq, Ord)

makeUnitary :: (RealFloat n) => n -> Maybe (UnitInterval n)
makeUnitary x
    | (x < 1) && (x > 0) = Just (UnitInterval x)
    | otherwise          = Nothing

unsafe_makeUnitary :: (RealFloat n) => n -> UnitInterval n
unsafe_makeUnitary x = UnitInterval x

-- TODO: There are two degrees of un-safety: you can omit the check as
-- you do, or you can crash the program on failure (using error). Is
-- omitting the check really what you want?

-- | The type for uniform variants.
type Var = UnitInterval Double


-- | A type for Azimuthal Angles limited to -pi < phi < pi.  Generally
-- interpreted as the angle from positive x, depending on the context.
newtype AzimuthAngle = AzimuthAngle Double deriving (Show, Eq, Ord)

makeAzimuthAngle :: Double -> Maybe AzimuthAngle
makeAzimuthAngle x
    | abs x <= pi = Just (AzimuthAngle x)
    | otherwise   = Nothing

unsafe_makeAzimuthAngle :: Double -> AzimuthAngle
unsafe_makeAzimuthAngle = AzimuthAngle

sampleAzimuthAngle :: Var -> AzimuthAngle
sampleAzimuthAngle (UnitInterval a) = AzimuthAngle (pi*(2*a - 1))


-- | A type for Zenith Angles. Limited to 0 < theta < pi. Generally
-- interpreted as the angle from positive z, depending on context.
newtype ZenithAngle = ZenithAngle Double deriving (Show, Eq, Ord)

makeZenithAngle :: Double -> Maybe ZenithAngle
makeZenithAngle z
    | (0 < z) && (z < pi) = Just (ZenithAngle z)
    | otherwise           = Nothing

unsafe_makeZenithAngle :: Double -> ZenithAngle
unsafe_makeZenithAngle = ZenithAngle

sampleZenithAngle :: Var -> ZenithAngle
sampleZenithAngle (UnitInterval a) = ZenithAngle (pi*a)


-- | A type for Radii. Limited to 0 < r.
newtype Radius = Radius {get_radius :: Double } deriving (Show, Eq, Ord, Approx)

makeRadius :: Double -> Maybe Radius
makeRadius x
    | (x > 0)   = Just (Radius x)
    | otherwise = Nothing

unsafe_makeRadius :: Double -> Radius
unsafe_makeRadius = Radius

sampleRadius :: Var -> Radius
sampleRadius (UnitInterval x) = (Radius . negate . log) x


-- | Time, elapsed time from beginning of streaming
newtype Time = Time { getTime :: Double } deriving (Eq, Show, Num, Ord, Approx)
