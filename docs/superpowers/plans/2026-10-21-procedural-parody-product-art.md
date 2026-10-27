# Procedural Parody Product Art Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Render all 23 parody products with unique pixel-art stack and single-unit textures.

**Architecture:** `ProductData` stores stable visual keys. `CounterArt` maps keys to recipes and creates cached `ImageTexture` assets for shelf, drag, and order uses. Existing layout and lock state logic continue to consume the same product IDs.

**Tech Stack:** Godot 4.7.2, GDScript, `Image`, `ImageTexture`.

**Spec:** `docs/superpowers/specs/2026-10-21-procedural-parody-product-art-design.md`

## Global Constraints

- Godot 4.7.2 syntax only.
- Preserve the 640x360 viewport and existing product IDs/prices/slot coordinates.
- No generic atlas fallback for catalog product stack, drag, or bubble art.

## Review Focus

- A missing recipe must return a safe, visibly distinct fallback rather than an invalid texture.
- A rail packet must remain a single unit when used in a bubble/preview.
- Stack and single texture caches must not return the same object.
- Locked product resources must retain both visual-key assignments without becoming visible.
- Generated textures must work in headless Godot tests.

### Task 1: Define visual-data contract and red test

**Files:**
- Modify: `scripts/product_data.gd`, `tests/parody_product_phase_2_test_runner.gd`

- [ ] Add failing assertions for two assigned visual keys and a structured visual recipe for every catalog product.
- [ ] Run the Phase 2 runner and observe the missing visual contract assertions.
- [ ] Add exported visual-key fields to `ProductData`.

### Task 2: Generate and cache pixel-art textures

**Files:**
- Modify: `scripts/counter_art.gd`, `scripts/product_drag_item.gd`

- [ ] Implement per-product visual recipes and separate cached 24x24 single / 48x48 stacked `ImageTexture` generation.
- [ ] Render rail displays from packet units and shelf displays from stacked textures.
- [ ] Run the Phase 2 runner and observe generated-art assertions pass.

### Task 3: Assign all product resources and verify runtime

**Files:**
- Modify: `data/products/*.tres`, `tests/parody_product_phase_2_test_runner.gd`

- [ ] Assign both texture keys to all 23 resources.
- [ ] Exercise every order bubble icon and all texture dimensions in the test runner.
- [ ] Run targeted, gameplay, layout, background, and runtime smoke checks.
