# Parody Product Data and Three-State Asset Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Register all 23 parody products and guarantee their stacked storefront, single-unit interaction, and locked slot behavior.

**Architecture:** Product `.tres` resources remain the catalog authority. `StorefrontLayout` maps each ID to its shelf zone and visual state metadata. `CounterArt` maps each ID to an existing stack, single, and icon texture; product and customer controls consume the single texture only for previews/bubbles.

**Tech Stack:** Godot 4.7.2, GDScript, `.tres` resource data, existing raster sprites.

**Spec:** `docs/superpowers/specs/2026-10-21-parody-products-phase-2-design.md`

## Global Constraints

- Register exactly 23 catalog products using the supplied parody names.
- Preserve existing prices; use Wemby ₱8, Ticnap Notnac ₱15, and B-fresh Gum ₱5.
- Keep shelf assets intact while previews/bubbles use one unit.
- Do not instantiate locked products.

## Review Focus

- Every catalog ID must have a non-empty slot, icon, single texture, and display texture.
- Rail items must render as vertical connected strip displays and remain above the window.
- New product IDs must appear only in campaign order pools after unlock.
- Bubble icons must never resolve to a stacked display texture.
- An unlocked item must not overlap another fixed slot.

---

### Task 1: Add failing catalog/state regression coverage

**Files:**
- Create: `tests/parody_product_phase_2_test_runner.gd`

- [ ] Write and run a live catalog test for 23 IDs, exact display names/prices, zones, state texture separation, and locked absence.

### Task 2: Register data and layout metadata

**Files:**
- Modify: `data/products/*.tres`, `data/story/summer_campaign.tres`, `data/orders/*.tres`
- Modify: `scripts/storefront_layout.gd`

- [ ] Add the three missing records, rename all catalog entries, update pools, and allocate non-overlapping zones.

### Task 3: Map three state textures through the UI controls

**Files:**
- Modify: `scripts/counter_art.gd`, `scenes/product_drag_item.tscn`, `scenes/customer_slot.tscn`

- [ ] Map all IDs to single/icon/stack textures and preserve the controls’ single-state preview/bubble use.

### Task 4: Verify all Godot regression runners

- [ ] Run focused catalog, core gameplay, storefront layout, background, gameplay, and asset integration runners.
