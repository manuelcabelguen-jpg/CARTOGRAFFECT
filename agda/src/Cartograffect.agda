{-# OPTIONS --safe --without-K #-}
------------------------------------------------------------------------
-- Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
-- SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
-- Cartograffect: Root aggregator module for the Agda 2.9.0 formalization
------------------------------------------------------------------------
module Cartograffect where

open import Cartograffect.Prelude           public
open import Cartograffect.PredictiveEngine  public
open import Cartograffect.CoreAffect        public
open import Cartograffect.AffectiveMatrix   public
open import Cartograffect.AffectiveTaxonomy public
open import Cartograffect.AffectiveDynamics public
open import Cartograffect.Lexicon176        public
open import Cartograffect.PredictiveCircuit public
open import Cartograffect.AuditTests        public
