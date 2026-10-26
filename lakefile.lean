import Lake
open Lake DSL

package «cartograffect» where
  -- add package configuration options here

@[default_target]
lean_lib «Cartograffect» where
  leanOptions := #[⟨`warningAsError, true⟩]
