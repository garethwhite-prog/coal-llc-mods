# Elemental Tick Upgrades (`gareth-tick_upgrade_mod`)

**Author:** Gareth White  
**Original Architecture & Credit:** Der-Floh (`der_floh-tick_upgrade_mod`)  
**Compatibility:** Coal LLC v1.4.1.1+ (ModLoader 7.0.1)

---

## Overview
This mod provides dynamic tick rate acceleration for poison and burn damage-over-time status effects applied to subterranean rock strata.

---

## Credit & Enhancements Over Original
This package is an enhanced fork of the original `der_floh-tick_upgrade_mod`. We express full credit and appreciation to **Der-Floh** for designing the foundational tick acceleration engine.

### Key Modifications:
1. **Packaging & Archive Normalization:** Repackaged with strict POSIX forward slashes and root `manifest.json` placement, eliminating ModLoader 7.0.1 directory parsing errors.
2. **Safe Passive Selection:** Overrides `choose_passive.gd` hook routines to preserve all 32 base passives when starting custom classes (like Knight or Void Siphon) with empty `unlocked_passives` arrays.
3. **Class Compatibility Whitelists:** Integrated with the Universal Mod Manager to respect per-class weapon restrictions and runtime mutator toggles.