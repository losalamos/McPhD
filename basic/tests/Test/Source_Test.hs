-- | A test module for Sphere1D
module Test.Source_Test (tests) where

-- Testing libraries
import Test.Framework (testGroup)
import Test.Framework.Providers.HUnit
import Test.Framework.Providers.QuickCheck2 (testProperty)
import Test.HUnit
import Test.QuickCheck
import Test.Arbitraries

-- The library under test
import Source
import Physical
-- import PRNG

-- helpers
-- import Control.Applicative
import SoftEquiv
import Data.List (zip4)

-- test case data
import Test.Source_Test_Cases

-- * energy sampling properties
-- | The power law rejector is bounded: specialized to a = 2.0 
-- (nondegenerate Fermi gas).
rejectorBndedA2 :: (Positive Double) -> Bool
rejectorBndedA2 (Positive x) = r >= 0.0 && r <= 1.0
  where r = rejector x 2.0

-- | More general case
rejectorBnded :: (Positive Double) -> Alpha -> Bool
rejectorBnded (Positive x) (Alpha a) = r >= 0.0 && r <= 1.0
  where r = rejector x a

-- * energy sampling test cases
rejData = zip4 [1..(length rejxs)] rejxs rejas rejs 

rejStr :: Int -> String
rejStr i = "rej. case " ++ show i 

rejFailStr :: Int -> FP -> FP -> FP -> String
rejFailStr i x a r = "rejection case " ++ show i ++ " failed, x: " ++ show x ++
                     ", a: " ++ show a ++ ", expected: " ++ show r

rejTest :: Int -> FP -> FP -> FP -> Assertion
rejTest i x a r = assertBool (rejFailStr i x a r) (softEquiv (rejector x a) r 1e-15)

rejCases = [testCase (rejStr i) (rejTest i x a r) | (i,x,a,r) <- rejData]



tests = [testGroup "energy sampling properties" 
         [ testProperty "rejector: 0 <= r <= 1 (alpha = 2)" rejectorBndedA2
         , testProperty "rejector: 0 <= r <= 1 (alpha arb)" rejectorBnded
         ]
        , testGroup "energy sampling cases: rejector" rejCases
        ]



-- end of file
