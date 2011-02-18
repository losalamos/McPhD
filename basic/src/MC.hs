-- SimpleMC.hs
-- T. M. Kelley
-- Dec 06, 2010
-- Copyright (c) 2010 LANSLLC all rights reserved.

{- Second crack at it--this time with two cells and an opacity.
 - We have five events: scatter, absorb, reflect, transmit, and escape. 
 - Absorption or escape terminates a particle's flight. 
 - 
 - Caller supplies a probability of scattering 
 - called 'sigma'--not really using a cross section yet.    
 -
 - Uses getStdRandom, which commits one to doing a lot in IO. Not  
 - sure whether that's a problem.                                  -}

module MC where

-- import DataTypes
import Physical
import Particle
import Material
import Mesh
import Tally
import Event

import Data.Function
import Data.List
import System.Random (getStdRandom,randomR)
import Control.Applicative

-- push a particle, tally what happens, report each step
runParticleV :: Particle -> Mesh -> Material -> IO Tally
runParticleV p mesh mat = tally <$> push p mesh mat stepMsg2

-- ditto sans reporting
runParticleQ :: Particle ->  Mesh -> Material -> IO Tally
runParticleQ p mesh mat = tally <$> push p mesh mat nullPrtr

{- Use a particle, 'opacity', and an RNG to
 - generate a list of Event, Particle pairs.  
 - Pass a printer function to control per-step reporting.  -}
push :: Particle -> Mesh -> Material -> (Event -> Particle -> IO ())
     -> IO [(Event,Particle)]
push p msh mat prtr = do 
  sel_s <- random $ pRNG p 
  sel_a <- random $ pRNG p
  omega' <- sampleDirection msh (pRNG p)
  let evt = pickEvent p sel_s sel_a omega' mat msh
      p' = stream p evt omega'
  if (isContinuing evt) 
    then prtr evt p' >> ((evt,p'):) <$> (push p' msh mat prtr)
    else prtr evt p' >> return [(evt,p')]

-- Pick event for a particle. Provide particle, two uniform random deviates
-- (to select distances), a new direction (however sampled), a material, and a 
-- mesh; get an Event in return. Distance to event and momentum transfer are 
-- encoded in the event. For boundary events, the face is also encoded.
pickEvent :: Particle -> 
             FP   ->    -- distance to scatter selector (RN)
             FP   ->    -- distance to absorption selector (RN)
             Direction ->  -- omega': sampled new direction from scatter (lab frame) 
             Material -> 
             Mesh -> 
             Event
pickEvent p sel_s sel_a omega' matl msh = 
    let d_scat = min (-log( sel_s)/sig_s) huge -- knows div-by-0 is greater than huge
        d_abs  = min (-log( sel_a)/sig_a) huge 
        (d_bdy,face)  = distToBdy msh cell x omega
        d_cen  = c * tcen where tcen = t $ pTime p
        cellt  = bdyEvent msh cell face
    in closestEvent [(Scatter d_scat (dp omega') (pWeight p)),     --
                     (Absorb  d_abs (dp 0) (pWeight p)), -- omega' is 0 
                     (cellt   d_bdy face),
                     (Census  d_cen 0)]
        where sig_s = sigma $ sig_scat ( (mat matl) ! cell)
              sig_a = sigma $ sig_abs  ( (mat matl) ! cell)
              x     = pPos p
              cell  = pCell p
              -- TO DO: boost to co-moving frame, compute the scatter,
              -- boost back to lab frame.
              omega = pDir p
              dp o' = elasticScatterMomDep (pEnergy p) omega o'

-- must have at least one event!
closestEvent :: [Event] -> Event
closestEvent = minimumBy (compare `on` dist)

-- compute the elastic scattering momentum deposition: E/c (k_i^ - k_f)
-- somewhat bogus--won't conserve momentum, also must acct for energy weight
elasticScatterMomDep :: Energy -> Direction -> Direction -> Momentum
elasticScatterMomDep energy omega_i omega_f = Momentum ((nrg/c) *| dir (omega_i - omega_f))
    where nrg = e energy

-- Generate a particle at the event with the new direction 
stream :: Particle -> Event -> Direction -> Particle
stream p event omega' = 
    case event of
      Scatter {}  -> p' {pDir=omega'}
      Absorb {}   -> p' {pDir=omega}
      Reflect {}  -> p' {pDir=(-omega)}
      Transmit {} -> p' {pCell=newcell}
      Escape {}   -> p' {pCell=0}
      Census {}   -> p' {pTime=0}
    where p'        = p{pPos = x', pTime = t'}
          d         = dist event
          x'        = pPos p + Position (d *| dir omega)
          t'        = pTime p - Time (d/c)
          omega     = pDir p
          newcell   = if (xcomp . dir $ omega) > 0.0 then 1 + pCell p else pCell p - 1

-- for testing, we'll need greater control of the RNG
rand :: (IO FP)
rand = getStdRandom (randomR (0.0 :: FP,1.0))

-- for printing out steps
stepMsg2 :: Event -> Particle -> IO ()
stepMsg2 evt pp = putStrLn $ show evt ++ " at x = " ++ show (pPos pp) ++ ", t = " 
                  ++ show (pTime pp) ++ ", cell = " 
                         ++ show (pCell pp) ++ ", omega' = " ++ show (pDir pp)

nullPrtr :: Event -> Particle -> IO ()
nullPrtr _ _ = return ()


-- version
-- $Id$

-- End of file

{- pack rat!

-- pushV2 p rng mesh mat = do 
--   sel_s <- rng 
--   sel_a <- rng
--   sel_o <- rng
--   let omega' = isotropicDirection1D sel_o
--       evt = pickEvent p sel_s sel_a omega' mat mesh
--       p' = stream p evt omega'
--   if (isContinuing evt)
--     then stepMsg2 evt p' >> ((evt, p'):) <$> (pushV p' rng mesh mat)
--     else stepMsg2 evt p' >> return [(evt, p')]
--   where 
--     stepMsg2 :: Event -> Particle -> IO ()
--     stepMsg2 evt pp = putStrLn $ show evt ++ " at x = " ++ show (pPos pp) ++ ", t = " 
--                       ++ show (pTime pp) ++ ", cell = " 
--                       ++ show (pCell pp) ++ ", omega' = " ++ show (pDir pp)
{- Use a particle, 'opacity', and an RNG to
 - generate a list of Event, Particle pairs. Guaranteed verbose.   -}
pushV :: Particle -> IO FP -> Mesh -> Material -> IO [(Event,Particle)]
pushV p rng mesh mat = do 
  sel_s <- rng 
  sel_a <- rng
  sel_o <- rng
  let omega' = isotropicDirection1D sel_o
      evt = pickEvent p sel_s sel_a omega' mat mesh
      p' = stream p evt omega'
  case evt of 
    -- continuing events
    evt@(Scatter {}) -> 
        stepMsg "Scatter" p' >> ((evt, p'):) <$> (pushV p' rng mesh mat)
    evt@(Reflect {}) ->  
        stepMsg "Reflect" p' >> ((evt, p'):) <$> (pushV p' rng mesh mat)
    evt@(Transmit {}) -> 
        stepMsg "Transmit" p' >> ((evt, p'):) <$> (pushV p' rng mesh mat)
    -- terminal events
    evt@(Escape {})  -> stepMsg "Escape" p' >> return [(evt, p')]
    evt@(Absorb {})  -> stepMsg "Absorb" p' >> return [(evt, p')]
    evt@(Census {})  -> stepMsg "Census" p' >> return [(evt, p')]
  where 
    stepMsg :: String -> Particle -> IO ()
    stepMsg s pp = putStrLn $ s ++ " at x = " ++ show (pPos pp) ++ ", t = " 
                   ++ show (pTime pp) ++ ", cell = " 
                          ++ show (pCell pp) ++ ", omega' = " ++ show (pDir pp)
-}
