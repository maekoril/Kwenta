# Shelf UI Stocking Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make the store environment show the requested Day 1–5 stock progression and buyable shelf locks, aligned to the supplied layered artwork.

**Architecture:** Use `data/store_config.json` as the shelf catalogue by adding each product's layer texture path and slot ID to its existing unlock metadata. Replace the disconnected legacy `StoreRenderer` with the existing `StoreLayerRenderer`, then refresh it when a day starts or a shelf purchase succeeds. Existing `CampaignState` remains the in-session owner of day, cash, and purchased groups; no save or money-system changes are in this branch.

**Tech Stack:** Godot 4.7, GDScript, JSON configuration, existing `CampaignState`.

**Spec:** User request in this chat, 2026-10-25; user follow-up scopes out money/save work.

## Global Constraints

- Keep the existing scene and HUD structure.
- Use the supplied 1672×941 layer coordinates and product art without changing their authored positions.
- Story products auto-stock by unlock day; unpurchased buyable products remain locked on subsequent days.
- Do not add disk persistence or modify the money system in this branch.
- Keep the existing debug `SKIP DAY` control as the day-jump test path.

## Review Focus

- Day 1 renders exactly the five requested story products.
- Each buyable shows `DAY N` before its day and a price after that day.
- The condiment trio has one shared purchase target and becomes visible together.
- Day changes refresh stock without touching customer/order delivery behavior.
- The Day 5 renderer uses the authored full-stock positions and scale.

---

### Task 1: Make the shelf catalogue self-contained

**Files:**
- Modify: `data/store_config.json`
- Modify: `scripts/store_config.gd`
- Modify: `tests/store_layer_config_test_runner.gd`

- [ ] Add `texture_path` and `slot_id` to all 23 products, retaining the requested story/buyable day and price schedule.
- [ ] Extend configuration tests to require every product record to reference its matching product art and authored slot.
- [ ] Run `godot --headless -s res://tests/store_layer_config_test_runner.gd` and confirm it passes.
- [ ] Commit: `feat: centralize shelf stock configuration`.

### Task 2: Activate the layered shelf manager

**Files:**
- Modify: `scripts/main.gd`
- Modify: `scripts/store_layer_renderer.gd`
- Modify: `tests/store_layer_renderer_test_runner.gd`

- [ ] Make `main.gd` instantiate `StoreLayerRenderer` and preserve the existing background/customer/product/UI draw order.
- [ ] Render story items only when stocked; render buyable padlocks only for buyable products that remain unpurchased.
- [ ] Center one shared condiment padlock over the three condiment assets.
- [ ] Run `godot --headless -s res://tests/store_layer_renderer_test_runner.gd` and confirm it passes.
- [ ] Commit: `feat: render day-based shelf stock`.

### Task 3: Verify the in-session shop UI

**Files:**
- Modify: `tests/store_layer_renderer_test_runner.gd`
- Modify: `tests/store_asset_integration_test_runner.gd`
- Modify: `scripts/main.gd` only if a test exposes an integration defect

- [ ] Test Day 1, Day 2, Day 3, Day 4, and Day 5 stock states; test a skipped buyable; test grouped condiment purchase and insufficient cash.
- [ ] Use the existing `SKIP DAY` debug control to verify day refresh behavior manually.
- [ ] Run all relevant headless test runners and inspect the Day 5 UI against `preview_all_unlocked.png`.
- [ ] Commit: `test: cover shelf stocking states`.
