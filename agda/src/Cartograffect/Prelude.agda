{-# OPTIONS --safe --without-K #-}
-- Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
-- SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
-- Author: Manuel Cabelguen

module Cartograffect.Prelude where

open import Agda.Builtin.Bool public using (Bool; true; false)
open import Agda.Builtin.Nat public using (Nat; zero; suc; _+_; _-_; _*_; _==_; _<_; div-helper; mod-helper)
open import Agda.Builtin.Int public using (Int; pos; negsuc)
open import Agda.Builtin.Equality public using (_≡_; refl)
open import Agda.Builtin.List public using (List; []; _∷_)
open import Agda.Builtin.String public using (String)

-- ---------------------------------------------------------------------------
-- Constructive logic, products, sums, decidability
-- ---------------------------------------------------------------------------
data ⊥ : Set where

⊥-elim : ∀ {ℓ} {A : Set ℓ} → ⊥ → A
⊥-elim ()

record ⊤ : Set where
  constructor tt

¬_ : Set → Set
¬ A = A → ⊥

data _⊎_ (A B : Set) : Set where
  inj₁ : A → A ⊎ B
  inj₂ : B → A ⊎ B

infixr 1 _⊎_

record _×_ (A B : Set) : Set where
  constructor _,_
  field
    fst : A
    snd : B

open _×_ public
infixr 2 _,_
infixr 4 _×_

record Σ (A : Set) (B : A → Set) : Set where
  constructor _,,_
  field
    proj₁ : A
    proj₂ : B proj₁

open Σ public
infixr 2 _,,_

data Dec (P : Set) : Set where
  yes : P → Dec P
  no  : ¬ P → Dec P

-- ---------------------------------------------------------------------------
-- Equality combinators
-- ---------------------------------------------------------------------------
sym : ∀ {ℓ} {A : Set ℓ} {x y : A} → x ≡ y → y ≡ x
sym refl = refl

trans : ∀ {ℓ} {A : Set ℓ} {x y z : A} → x ≡ y → y ≡ z → x ≡ z
trans refl q = q

cong : ∀ {ℓ₁ ℓ₂} {A : Set ℓ₁} {B : Set ℓ₂} (f : A → B) {x y : A} → x ≡ y → f x ≡ f y
cong f refl = refl

cong₂ : ∀ {ℓ₁ ℓ₂ ℓ₃} {A : Set ℓ₁} {B : Set ℓ₂} {C : Set ℓ₃}
        (f : A → B → C) {x₁ x₂ : A} {y₁ y₂ : B} → x₁ ≡ x₂ → y₁ ≡ y₂ → f x₁ y₁ ≡ f x₂ y₂
cong₂ f refl refl = refl

subst : ∀ {ℓ₁ ℓ₂} {A : Set ℓ₁} (P : A → Set ℓ₂) {x y : A} → x ≡ y → P x → P y
subst P refl px = px

-- ---------------------------------------------------------------------------
-- Boolean combinators
-- ---------------------------------------------------------------------------
not : Bool → Bool
not true = false
not false = true

_∧b_ : Bool → Bool → Bool
true ∧b b = b
false ∧b _ = false
infixr 6 _∧b_

_∨b_ : Bool → Bool → Bool
true ∨b _ = true
false ∨b b = b
infixr 5 _∨b_

if_then_else_ : ∀ {ℓ} {A : Set ℓ} → Bool → A → A → A
if true  then x else _ = x
if false then _ else y = y
infix 0 if_then_else_

-- ---------------------------------------------------------------------------
-- Order and arithmetic on Nat
-- ---------------------------------------------------------------------------
data _≤ℕ_ : Nat → Nat → Set where
  z≤n : ∀ {n} → zero ≤ℕ n
  s≤s : ∀ {m n} → m ≤ℕ n → suc m ≤ℕ suc n

_<ℕ_ : Nat → Nat → Set
m <ℕ n = suc m ≤ℕ n

infix 4 _≤ℕ_ _<ℕ_

≤ℕ-refl : ∀ n → n ≤ℕ n
≤ℕ-refl zero = z≤n
≤ℕ-refl (suc n) = s≤s (≤ℕ-refl n)

≤ℕ-trans : ∀ {a b c} → a ≤ℕ b → b ≤ℕ c → a ≤ℕ c
≤ℕ-trans z≤n _ = z≤n
≤ℕ-trans (s≤s p) (s≤s q) = s≤s (≤ℕ-trans p q)

≤ℕ-antisym : ∀ {a b} → a ≤ℕ b → b ≤ℕ a → a ≡ b
≤ℕ-antisym z≤n z≤n = refl
≤ℕ-antisym (s≤s p) (s≤s q) = cong suc (≤ℕ-antisym p q)

<ℕ-trans : ∀ {a b c} → a <ℕ b → b <ℕ c → a <ℕ c
<ℕ-trans p q = ≤ℕ-trans p (≤ℕ-trans (≤-step (≤ℕ-refl _)) q)
  where
    ≤-step : ∀ {m n} → m ≤ℕ n → m ≤ℕ suc n
    ≤-step z≤n = z≤n
    ≤-step (s≤s h) = s≤s (≤-step h)

≤-step-r : ∀ {m n} → m ≤ℕ n → m ≤ℕ suc n
≤-step-r z≤n = z≤n
≤-step-r (s≤s h) = s≤s (≤-step-r h)

<ℕ-to-≤ℕ : ∀ {m n} → m <ℕ n → m ≤ℕ n
<ℕ-to-≤ℕ (s≤s h) = ≤-step-r h

<ℕ-irrefl : ∀ {n} → ¬ (n <ℕ n)
<ℕ-irrefl (s≤s h) = <ℕ-irrefl h

suc-≤-injective : ∀ {m n} → suc m ≤ℕ suc n → m ≤ℕ n
suc-≤-injective (s≤s p) = p

≤ℕ-total : ∀ m n → (m ≤ℕ n) ⊎ (n ≤ℕ m)
≤ℕ-total zero _ = inj₁ z≤n
≤ℕ-total (suc _) zero = inj₂ z≤n
≤ℕ-total (suc m) (suc n) with ≤ℕ-total m n
... | inj₁ h = inj₁ (s≤s h)
... | inj₂ h = inj₂ (s≤s h)

≤ℕ-dec : ∀ m n → Dec (m ≤ℕ n)
≤ℕ-dec zero _ = yes z≤n
≤ℕ-dec (suc _) zero = no (λ ())
≤ℕ-dec (suc m) (suc n) with ≤ℕ-dec m n
... | yes p = yes (s≤s p)
... | no np = no (λ h → np (suc-≤-injective h))

≡ℕ-dec : ∀ (m n : Nat) → Dec (m ≡ n)
≡ℕ-dec zero zero = yes refl
≡ℕ-dec zero (suc _) = no (λ ())
≡ℕ-dec (suc _) zero = no (λ ())
≡ℕ-dec (suc m) (suc n) with ≡ℕ-dec m n
... | yes p = yes (cong suc p)
... | no np = no (λ eq → np (cong predℕ eq))
  where
    predℕ : Nat → Nat
    predℕ zero = zero
    predℕ (suc x) = x

≤ℕ-pi : ∀ {m n} (p q : m ≤ℕ n) → p ≡ q
≤ℕ-pi z≤n z≤n = refl
≤ℕ-pi (s≤s p) (s≤s q) = cong s≤s (≤ℕ-pi p q)

minℕ : Nat → Nat → Nat
minℕ a b with ≤ℕ-dec a b
... | yes _ = a
... | no  _ = b

maxℕ : Nat → Nat → Nat
maxℕ a b with ≤ℕ-dec a b
... | yes _ = b
... | no  _ = a

clampℕ : Nat → Nat → Nat → Nat
clampℕ lo hi v = minℕ hi (maxℕ lo v)

-- Addition / Multiplication lemmas on Nat
+-zero-r : ∀ n → n + 0 ≡ n
+-zero-r zero = refl
+-zero-r (suc n) = cong suc (+-zero-r n)

+-suc-r : ∀ m n → m + suc n ≡ suc (m + n)
+-suc-r zero _ = refl
+-suc-r (suc m) n = cong suc (+-suc-r m n)

+-assoc : ∀ a b c → (a + b) + c ≡ a + (b + c)
+-assoc zero _ _ = refl
+-assoc (suc a) b c = cong suc (+-assoc a b c)

+-comm : ∀ m n → m + n ≡ n + m
+-comm zero n = sym (+-zero-r n)
+-comm (suc m) n = trans (cong suc (+-comm m n)) (sym (+-suc-r n m))

+-cancel-l : ∀ k {a b} → k + a ≡ k + b → a ≡ b
+-cancel-l zero eq = eq
+-cancel-l (suc k) eq = +-cancel-l k (cong pred eq)
  where
    pred : Nat → Nat
    pred zero = zero
    pred (suc x) = x

+-mono-≤ : ∀ {a b c d} → a ≤ℕ b → c ≤ℕ d → (a + c) ≤ℕ (b + d)
+-mono-≤ {zero} {b} z≤n c≤d = ≤ℕ-trans c≤d (add-l b _)
  where
    add-l : ∀ x y → y ≤ℕ x + y
    add-l zero y = ≤ℕ-refl y
    add-l (suc x) y = ≤-step-r (add-l x y)
+-mono-≤ (s≤s a≤b) c≤d = s≤s (+-mono-≤ a≤b c≤d)

≤ℕ-add-r : ∀ a b → a ≤ℕ a + b
≤ℕ-add-r zero _ = z≤n
≤ℕ-add-r (suc a) b = s≤s (≤ℕ-add-r a b)

≤ℕ-add-l : ∀ a b → b ≤ℕ a + b
≤ℕ-add-l a b rewrite +-comm a b = ≤ℕ-add-r b a

*-zero-r : ∀ n → n * 0 ≡ 0
*-zero-r zero = refl
*-zero-r (suc n) = *-zero-r n

*-suc-r : ∀ m n → m * suc n ≡ m + m * n
*-suc-r zero _ = refl
*-suc-r (suc m) n = cong suc (
  trans (cong (n +_) (*-suc-r m n))
        (trans (sym (+-assoc n m (m * n)))
               (trans (cong (_+ (m * n)) (+-comm n m))
                      (+-assoc m n (m * n)))))

*-comm : ∀ m n → m * n ≡ n * m
*-comm zero n = sym (*-zero-r n)
*-comm (suc m) n = trans (cong (n +_) (*-comm m n)) (sym (*-suc-r n m))

*-distrib-r-+ : ∀ a b c → (a + b) * c ≡ a * c + b * c
*-distrib-r-+ zero _ _ = refl
*-distrib-r-+ (suc a) b c = trans (cong (c +_) (*-distrib-r-+ a b c)) (sym (+-assoc c (a * c) (b * c)))

*-distrib-l-+ : ∀ a b c → a * (b + c) ≡ a * b + a * c
*-distrib-l-+ a b c rewrite *-comm a (b + c) | *-comm a b | *-comm a c = *-distrib-r-+ b c a

*-assoc : ∀ a b c → (a * b) * c ≡ a * (b * c)
*-assoc zero _ _ = refl
*-assoc (suc a) b c = trans (*-distrib-r-+ b (a * b) c) (cong (b * c +_) (*-assoc a b c))

*-mono-≤ : ∀ {a b c d} → a ≤ℕ b → c ≤ℕ d → (a * c) ≤ℕ (b * d)
*-mono-≤ z≤n _ = z≤n
*-mono-≤ (s≤s p) q = +-mono-≤ q (*-mono-≤ p q)

-- Minus lemmas
-ℕ-cancel : ∀ a b → (a + b) - a ≡ b
-ℕ-cancel zero b = refl
-ℕ-cancel (suc a) b = -ℕ-cancel a b

-ℕ-zero : ∀ n → n - 0 ≡ n
-ℕ-zero zero = refl
-ℕ-zero (suc _) = refl

≤ℕ-ex-diff : ∀ {a b} → a ≤ℕ b → Σ Nat (λ k → a + k ≡ b)
≤ℕ-ex-diff z≤n = _ ,, refl
≤ℕ-ex-diff (s≤s h) with ≤ℕ-ex-diff h
... | k ,, eq = k ,, cong suc eq

+-minus-assoc : ∀ {a b c} → b ≤ℕ a → (a - b) + c ≡ (a + c) - b
+-minus-assoc {zero} {zero} _ = refl
+-minus-assoc {suc a} {zero} {c} _ = trans (cong (λ lhs → lhs + c) refl) (sym (-ℕ-zero (suc a + c)))
+-minus-assoc {suc a} {suc b} {c} (s≤s h) = +-minus-assoc h

≤-minus-mono : ∀ {a b} (c : Nat) → a ≤ℕ b → (a - c) ≤ℕ (b - c)
≤-minus-mono {a} {b} zero h = subst₂ (sym (-ℕ-zero a)) (sym (-ℕ-zero b)) h
  where
    subst₂ : ∀ {x₁ x₂ y₁ y₂} → x₁ ≡ x₂ → y₁ ≡ y₂ → x₁ ≤ℕ y₁ → x₂ ≤ℕ y₂
    subst₂ refl refl p = p
≤-minus-mono {zero} {b} (suc c) _ = z≤n
≤-minus-mono {suc a} {suc b} (suc c) (s≤s h) = ≤-minus-mono c h

-- ---------------------------------------------------------------------------
-- Fast GMP-backed Nat div & mod + constructive Euclidean proof
-- ---------------------------------------------------------------------------
_÷_ : Nat → Nat → Nat
_ ÷ zero = zero
n ÷ suc d = div-helper zero d n d

_%_ : Nat → Nat → Nat
n % zero = n
n % suc d = mod-helper zero d n d

infixl 7 _÷_ _%_

div-mod-helper-eq :
  ∀ kd km d n j → km + j ≡ d →
  div-helper kd d n j * suc d + mod-helper km d n j ≡ kd * suc d + km + n
div-mod-helper-eq kd km d zero j inv rewrite +-zero-r (kd * suc d + km) = refl
div-mod-helper-eq kd km d (suc n) zero inv =
  trans (div-mod-helper-eq (suc kd) zero d n d refl)
        (trans (cong (_+ n) (trans (+-zero-r (suc d + kd * suc d)) (trans (+-comm (suc d) (kd * suc d)) (+-suc-r (kd * suc d) d))))
               (trans (sym (+-suc-r (kd * suc d + d) n))
                      (cong (λ x → kd * suc d + x + suc n) (sym (trans (sym (+-zero-r km)) inv)))))
div-mod-helper-eq kd km d (suc n) (suc j) inv =
  trans (div-mod-helper-eq kd (suc km) d n j (trans (sym (+-suc-r km j)) inv))
        (trans (cong (_+ n) (+-suc-r (kd * suc d) km))
               (sym (+-suc-r (kd * suc d + km) n)))

mod-helper-< :
  ∀ km d n j → km + j ≡ d → mod-helper km d n j <ℕ suc d
mod-helper-< km d zero j inv rewrite sym inv = s≤s (≤ℕ-add-r km j)
mod-helper-< km d (suc n) zero _ = mod-helper-< zero d n d refl
mod-helper-< km d (suc n) (suc j) inv = mod-helper-< (suc km) d n j (trans (sym (+-suc-r km j)) inv)

div-mod-eq : ∀ n d → 0 <ℕ d → (n ÷ d) * d + (n % d) ≡ n
div-mod-eq n (suc d) _ = div-mod-helper-eq 0 0 d n d refl

mod-< : ∀ n d → 0 <ℕ d → (n % d) <ℕ d
mod-< n (suc d) _ = mod-helper-< 0 d n d refl

lt-of-≤-neq : ∀ {x y} → x ≤ℕ y → ¬ (x ≡ y) → x <ℕ y
lt-of-≤-neq {zero} {zero} z≤n neq = ⊥-elim (neq refl)
lt-of-≤-neq {zero} {suc _} z≤n _ = s≤s z≤n
lt-of-≤-neq (s≤s p) neq = s≤s (lt-of-≤-neq p (λ eq → neq (cong suc eq)))

div-gap-absurd :
  ∀ {q1 q2 d r1 r2} → q2 <ℕ q1 → r2 <ℕ d → ¬ (q1 * d + r1 ≤ℕ q2 * d + r2)
div-gap-absurd {q1} {q2} {d} {r1} {r2} q2<q1 r2<d h =
  <ℕ-irrefl (≤ℕ-trans stepLt (≤ℕ-trans stepMul (≤ℕ-trans (≤ℕ-add-r (q1 * d) r1) h)))
  where
    stepLt : suc (q2 * d + r2) ≤ℕ q2 * d + d
    stepLt = subst (_≤ℕ q2 * d + d) (+-suc-r (q2 * d) r2) (+-mono-≤ (≤ℕ-refl (q2 * d)) r2<d)

    stepMul : q2 * d + d ≤ℕ q1 * d
    stepMul = subst (_≤ℕ q1 * d) (+-comm d (q2 * d)) (*-mono-≤ q2<q1 (≤ℕ-refl d))

÷-mono-≤ : ∀ {a b d} → a ≤ℕ b → 0 <ℕ d → (a ÷ d) ≤ℕ (b ÷ d)
÷-mono-≤ {a} {b} {d} a≤b dpos with ≤ℕ-total (a ÷ d) (b ÷ d)
... | inj₁ ok = ok
... | inj₂ q≥ with ≡ℕ-dec (a ÷ d) (b ÷ d)
...   | yes eq = subst (_≤ℕ (b ÷ d)) (sym eq) (≤ℕ-refl (b ÷ d))
...   | no neq =
  ⊥-elim (div-gap-absurd (lt-of-≤-neq q≥ (λ e → neq (sym e))) (mod-< b d dpos)
    (subst₂ _≤ℕ_ (sym (div-mod-eq a d dpos)) (sym (div-mod-eq b d dpos)) a≤b))
  where
    subst₂ : ∀ {A : Set} (R : A → A → Set) {x₁ x₂ y₁ y₂} → x₁ ≡ x₂ → y₁ ≡ y₂ → R x₁ y₁ → R x₂ y₂
    subst₂ _ refl refl r = r

÷-≤-of-≤-* : ∀ {a b q} → 0 <ℕ b → a ≤ℕ b * q → (a ÷ b) ≤ℕ q
÷-≤-of-≤-* {a} {b} {q} bpos h with ≤ℕ-total (a ÷ b) q
... | inj₁ ok = ok
... | inj₂ q≤ with ≡ℕ-dec (a ÷ b) q
...   | yes eq = subst (_≤ℕ q) (sym eq) (≤ℕ-refl q)
...   | no neq =
  ⊥-elim (div-gap-absurd (lt-of-≤-neq q≤ (λ e → neq (sym e))) bpos leCombined)
  where
    leCombined : (a ÷ b) * b + (a % b) ≤ℕ q * b + 0
    leCombined = subst₂ (sym (div-mod-eq a b bpos)) (trans (*-comm b q) (sym (+-zero-r (q * b)))) h
      where
        subst₂ : ∀ {x₁ x₂ y₁ y₂} → x₁ ≡ x₂ → y₁ ≡ y₂ → x₁ ≤ℕ y₁ → x₂ ≤ℕ y₂
        subst₂ refl refl p = p

÷-<-of-<-* : ∀ {a b q} → 0 <ℕ b → a <ℕ b * q → (a ÷ b) <ℕ q
÷-<-of-<-* {a} {b} {q} bpos h with ≤ℕ-total (a ÷ b) q
... | inj₁ a≤q with ≡ℕ-dec (a ÷ b) q
...   | no neq = lt-of-≤-neq a≤q neq
...   | yes eq =
  ⊥-elim (<ℕ-irrefl (≤ℕ-trans h (≤ℕ-trans (step1 (subst (_≤ℕ (a ÷ b)) eq (≤ℕ-refl (a ÷ b)))) step2)))
  where
    step1 : q ≤ℕ (a ÷ b) → b * q ≤ℕ (a ÷ b) * b
    step1 q≤ = subst (b * q ≤ℕ_) (*-comm b (a ÷ b)) (*-mono-≤ (≤ℕ-refl b) q≤)
    step2 : (a ÷ b) * b ≤ℕ a
    step2 = subst ((a ÷ b) * b ≤ℕ_) (div-mod-eq a b bpos) (≤ℕ-add-r ((a ÷ b) * b) (a % b))
÷-<-of-<-* {a} {b} {q} bpos h | inj₂ q≤ =
  ⊥-elim (<ℕ-irrefl (≤ℕ-trans h (≤ℕ-trans step1 step2)))
  where
    step1 : b * q ≤ℕ (a ÷ b) * b
    step1 = subst (b * q ≤ℕ_) (*-comm b (a ÷ b)) (*-mono-≤ (≤ℕ-refl b) q≤)
    step2 : (a ÷ b) * b ≤ℕ a
    step2 = subst ((a ÷ b) * b ≤ℕ_) (div-mod-eq a b bpos) (≤ℕ-add-r ((a ÷ b) * b) (a % b))

div-mul-add-exact : ∀ q d r → r <ℕ d → (q * d + r) ÷ d ≡ q
div-mul-add-exact q zero r ()
div-mul-add-exact q (suc d') r r<d =
  ≤ℕ-antisym q'≤q q≤q'
  where
    d = suc d'
    n = q * d + r
    dpos : 0 <ℕ d
    dpos = s≤s z≤n
    q' = n ÷ d
    eq : q' * d + (n % d) ≡ n
    eq = div-mod-eq n d dpos
    q'≤q : q' ≤ℕ q
    q'≤q with ≤ℕ-total q' q
    ... | inj₁ ok = ok
    ... | inj₂ q≤ with ≡ℕ-dec q' q
    ...   | yes e = subst (_≤ℕ q) (sym e) (≤ℕ-refl q)
    ...   | no ne = ⊥-elim (div-gap-absurd (lt-of-≤-neq q≤ (λ e → ne (sym e))) r<d (subst (_≤ℕ n) (sym eq) (≤ℕ-refl n)))
    q≤q' : q ≤ℕ q'
    q≤q' with ≤ℕ-total q q'
    ... | inj₁ ok = ok
    ... | inj₂ q'≤ with ≡ℕ-dec q' q
    ...   | yes e = subst (q ≤ℕ_) (sym e) (≤ℕ-refl q)
    ...   | no ne = ⊥-elim (div-gap-absurd (lt-of-≤-neq q'≤ ne) (mod-< n d dpos) (subst (n ≤ℕ_) (sym eq) (≤ℕ-refl n)))

-- ---------------------------------------------------------------------------
-- Integers (Agda.Builtin.Int) & List utilities
-- ---------------------------------------------------------------------------
absNat : Int → Nat
absNat (pos n) = n
absNat (negsuc n) = suc n

-ℤ_ : Int → Int
-ℤ pos zero = pos zero
-ℤ pos (suc n) = negsuc n
-ℤ negsuc n = pos (suc n)

-ℤ-invol : ∀ x → -ℤ (-ℤ x) ≡ x
-ℤ-invol (pos zero) = refl
-ℤ-invol (pos (suc _)) = refl
-ℤ-invol (negsuc _) = refl

subNatℤ : Nat → Nat → Int
subNatℤ a zero = pos a
subNatℤ zero (suc b) = negsuc b
subNatℤ (suc a) (suc b) = subNatℤ a b

_+ℤ_ : Int → Int → Int
pos a +ℤ pos b = pos (a + b)
pos a +ℤ negsuc b = subNatℤ a (suc b)
negsuc a +ℤ pos b = subNatℤ b (suc a)
negsuc a +ℤ negsuc b = negsuc (suc (a + b))

_-ℤ_ : Int → Int → Int
x -ℤ y = x +ℤ (-ℤ y)

_*ℤ_ : Int → Int → Int
pos a *ℤ pos b = pos (a * b)
pos zero *ℤ negsuc _ = pos zero
pos (suc a) *ℤ negsuc b = negsuc (predMul (suc a) (suc b))
  where
    predMul : Nat → Nat → Nat
    predMul x y = (x * y) - 1
negsuc _ *ℤ pos zero = pos zero
negsuc a *ℤ pos (suc b) = negsuc (((suc a) * (suc b)) - 1)
negsuc a *ℤ negsuc b = pos ((suc a) * (suc b))

infixl 6 _+ℤ_ _-ℤ_
infixl 7 _*ℤ_

≡ℤ-dec : ∀ (x y : Int) → Dec (x ≡ y)
≡ℤ-dec (pos a) (pos b) with ≡ℕ-dec a b
... | yes eq = yes (cong pos eq)
... | no ne = no (λ eq → ne (cong unPos eq))
  where
    unPos : Int → Nat
    unPos (pos n) = n
    unPos (negsuc _) = zero
≡ℤ-dec (pos _) (negsuc _) = no (λ ())
≡ℤ-dec (negsuc _) (pos _) = no (λ ())
≡ℤ-dec (negsuc a) (negsuc b) with ≡ℕ-dec a b
... | yes eq = yes (cong negsuc eq)
... | no ne = no (λ eq → ne (cong unNeg eq))
  where
    unNeg : Int → Nat
    unNeg (pos _) = zero
    unNeg (negsuc n) = n

intNonNegB : Int → Bool
intNonNegB (pos _) = true
intNonNegB (negsuc _) = false

intPosB : Int → Bool
intPosB (pos (suc _)) = true
intPosB _ = false

intNegB : Int → Bool
intNegB (negsuc _) = true
intNegB _ = false

-- List utilities
_++_ : ∀ {ℓ} {A : Set ℓ} → List A → List A → List A
[] ++ ys = ys
(x ∷ xs) ++ ys = x ∷ (xs ++ ys)
infixr 5 _++_

length : ∀ {ℓ} {A : Set ℓ} → List A → Nat
length [] = zero
length (_ ∷ xs) = suc (length xs)

map : ∀ {ℓ₁ ℓ₂} {A : Set ℓ₁} {B : Set ℓ₂} → (A → B) → List A → List B
map _ [] = []
map f (x ∷ xs) = f x ∷ map f xs

data All {A : Set} (P : A → Set) : List A → Set where
  []  : All P []
  _∷_ : ∀ {x xs} → P x → All P xs → All P (x ∷ xs)

data _∈_ {A : Set} (x : A) : List A → Set where
  here  : ∀ {xs} → x ∈ (x ∷ xs)
  there : ∀ {y xs} → x ∈ xs → x ∈ (y ∷ xs)

All-lookup : ∀ {A : Set} {P : A → Set} {xs : List A} {x : A} → All P xs → x ∈ xs → P x
All-lookup (px ∷ _) here = px
All-lookup (_ ∷ pxs) (there hx) = All-lookup pxs hx

