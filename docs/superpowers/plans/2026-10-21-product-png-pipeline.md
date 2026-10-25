# Product PNG Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Serve all storefront, drag, and order product art from assigned transparent PNG resources.

**Architecture:** ProductData holds `Texture2D` stack/single references. CounterArt resolves those catalog resources by ID. ProductDragItem uses the supplied textures with nearest filtering and keeps its shadow behind the sprite.

**Tech Stack:** Godot 4.7.2 GDScript, PNG `Texture2D` resources.

**Spec:** `docs/superpowers/specs/2026-10-21-product-png-pipeline-design.md`

## Global Constraints

- Product rendering must not create `Image` or `ImageTexture` at runtime.
- All 46 assigned product texture paths must be under `res://assets/products/`.
- Product IDs, prices, campaign unlocks, and slot coordinates remain unchanged.

### Task 1: Build red PNG-assignment test

- [ ] Assert every catalog record owns two non-null `.png` Texture2Ds under `assets/products`.
- [ ] Assert CounterArt resolves the exact resource texture and contains no procedural fallback.

### Task 2: Populate PNG folders and resource references

- [ ] Copy existing detailed source art into category folders with parody asset names.
- [ ] Generate the missing transparent single sachet PNGs.
- [ ] Add `Texture2D` exported properties and attach all 46 references in `data/products`.

### Task 3: Remove generated rendering

- [ ] Replace CounterArt’s generated-image methods with catalog texture lookup.
- [ ] Make Main pass resource textures directly to product controls.
- [ ] Run focused, gameplay, layout, background, and runtime verification.
