import Lake
open Lake DSL

package «cartograffect» where
  -- add package configuration options here

@[default_target]
lean_lib «Cartograffect» where
  leanOptions := #[⟨`warningAsError, true⟩]
  roots := #[`Cartograffect, `Cartograffect.AffectiveDynamics, `Cartograffect.PredictiveCircuit]

@[default_target]
lean_lib «PredictiveEngineCanonical» where
  srcDir := "extensions/predictive_engine"
  leanOptions := #[⟨`warningAsError, true⟩]
  roots := #[`PredictiveEngineCanonical]
