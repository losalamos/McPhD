{- | Analytic microscopic neutrino cross sections.
 - From Herant, Benz, Fryer, and Colgate: Ap. J. 435:339-361 (1994).
 - Cross sections are in cm^2, energies in MeV
 -}

module Sigma_HBFC where

import Physical


-- * neutrino--baryon events
-- ------------------------
-- | nucleon absorption/emission

nuNAbs :: Energy -> CrossSection
nuNAbs (Energy nrg) = CrossSection $ 9e-44 * nrg * nrg

-- | nu--nucleon elastic scattering
nuNElastic :: Energy -> CrossSection
nuNElastic (Energy nrg) = CrossSection $ 1.7e-44* nrg * nrg

-- -- | nu-nucleus elastic scatter: attempts to account
-- -- | for coherent scattering from bound nucleons
-- nuNZ_elastic
-- nuNZ_elastic (Energy e) N Z =
--   CrossSection $ 1.7e-44*(N-0.08*Z)*(N-0.08*Z)/6.0*e*e

-- | if not too concerned about the balance between n's & p's:
nuAElastic :: Energy -> NucleonNumber -> CrossSection
nuAElastic (Energy nrg) (NucleonNumber a) = 
  CrossSection $ 1.7e-44*a*a/6.0*nrg*nrg


-- NOTE: the lepton cross sections are complicated by dependence on
-- species. The first set of functions is how I coded this in the
-- Python version. The corresponding opacity code figures out which
-- species is involved, then branches to one of these functions....

-- * neutrino--lepton scattering
-- ----------------------------
-- | nu_e--e^- & nu_bar_e--e^+ scattering
nuEEMinus :: Energy -> Energy -> CrossSection
nuEEMinus  (Energy e_nu) (Energy e_e) = CrossSection $ 9.2e-45 * e_nu * e_e

-- | nu_bar_e--e^- & nu_e--e^+ scattering
nuEEPlus :: Energy -> Energy -> CrossSection
nuEEPlus (Energy e_nu) (Energy e_e) = CrossSection $ 3.9e-45 * e_nu * e_e


-- | nu_x--e^- & nu_bar_x--e^+ scattering
nuXEMinus :: Energy -> Energy -> CrossSection
nuXEMinus  (Energy e_nu) (Energy e_e) = CrossSection $ 1.8e-45 * e_nu * e_e

-- | nu_bar_x--e^- & nu_x--e^+ scattering
nuXEPlus :: Energy -> Energy -> CrossSection
nuXEPlus (Energy e_nu) (Energy e_e) = CrossSection $ 1.3e-45 * e_nu * e_e



-- ...QUESTION: I'm hoping this will be more efficient (it's easier to code)
-- that what I have above.
-- The use case is something like this: we'll pass an instance of
-- Sigma.Lepton to MC.runParticle (or maybe curried into a MC.runParticleWith)
-- for a container of particles of one species. My hope is that
-- GHC will be able to determine statically which function is being called,
-- and inline it, or at least avoid the penalty of a function pointer.
-- Does that sound realistic?

-- | Lepton packs cross-section functions for each different neutrino species.
-- For the moment, we don't differentiate between tau and mu neutrinos (nu_x).
data Lepton = Lepton {
    e_minus :: Energy -> Energy -> CrossSection
  , e_plus  :: Energy -> Energy -> CrossSection
} 

nuE :: Lepton
nuE = Lepton {
    e_minus = nuEEMinus
  , e_plus  = nuEEPlus
}

nuEBar :: Lepton
nuEBar = Lepton {
    e_minus = nuEEPlus
  , e_plus  = nuEEMinus
}

nuX :: Lepton
nuX = Lepton {
    e_minus = nuXEMinus
  , e_plus  = nuXEPlus
}

nuXBar :: Lepton
nuXBar = Lepton {
    e_minus = nuXEPlus
  , e_plus  = nuXEMinus
}

-- really, I suppose we could do better
instance Show Lepton where
  show _ = "lepton"


-- end of file
