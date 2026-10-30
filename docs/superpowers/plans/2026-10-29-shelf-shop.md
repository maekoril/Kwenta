# Shelf Shop Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Provide an upper-right modal shop for permanent, one-time optional shelf purchases while preserving story day unlocks.

**Architecture:** Keep product availability and save persistence in `StoreConfig` and `CampaignState`. Define every optional shelf as one `purchase_group` in `store_config.json`; use a new programmatic `ShelfShopModal` to present those groups and let `main.gd` execute purchases. The storefront renderer becomes display-only for locked items.

**Tech Stack:** Godot 4.7, GDScript, JSON configuration, SceneTree test runners.

**Spec:** `docs/superpowers/specs/2026-10-29-shelf-shop-design.md`

## Global Constraints

- Story products retain their existing automatic unlock day behavior.
- Optional shelves are all offered on Day 1 and unlock their complete product group immediately after a one-time cash purchase.
- The storefront must not purchase shelves when a locked product is tapped.
- `CampaignState.purchased_store_groups` remains the persisted purchase state.
- The Drink Cooler remains removed.

## Review Focus

- Insufficient cash leaves cash and owned groups unchanged; cover in the campaign-state test.
- A second purchase of an owned group cannot spend cash again; cover in the campaign-state test.
- Each purchased group stocks every configured product immediately regardless of story day; cover in the store-config test.
- Story products still stock on their scheduled days without any purchase; cover in the store-config test.
- Locked storefront taps no longer emit a purchase signal; cover in the renderer test.

---

### Task 1: Configure permanent shelf groups

**Files:**
- Modify: `data/store_config.json`
- Modify: `data/upgrades/sachet_rail.tres`
- Modify: `data/upgrades/extra_shelf.tres`
- Modify: `data/upgrades/condiment_rack.tres`
- Modify: `data/upgrades/bulk_crates.tres`
- Test: `tests/store_layer_config_test_runner.gd`

**Interfaces:**
- Consumes: `StoreConfig.get_stocked_entries(config, day, purchased_groups)`.
- Produces: five Day-1 optional purchase groups: `hanging_strip`, `water_shelf`, `condiments`, `oil_shelf`, and `rice_shelf`.

- [ ] **Step 1: Write failing configuration assertions**

Assert the five group IDs, product membership, Day-1 offers, exact costs, immediate purchased stocking, and unchanged story product day-one stock.

- [ ] **Step 2: Run the configuration runner to verify the assertions fail**

Run: `godot --headless --path . --script res://tests/store_layer_config_test_runner.gd`
Expected: FAIL because the existing groups and dates differ.

- [ ] **Step 3: Update shelf-group data**

Set buyable `store_config.json` entries to the five groups and costs from the spec with `unlock_day: 1`. Align upgrade resources to the same groups, product IDs, costs, and Day-1 offers.

- [ ] **Step 4: Run the configuration runner to verify it passes**

Run: `godot --headless --path . --script res://tests/store_layer_config_test_runner.gd`
Expected: PASS.

### Task 2: Make locked storefront products non-purchasable

**Files:**
- Modify: `scripts/store_layer_renderer.gd`
- Test: `tests/store_layer_renderer_test_runner.gd`

**Interfaces:**
- Consumes: `StoreLayerRenderer.configure(day, cash, purchased_groups)`.
- Produces: locked product visuals with no `purchase_requested` or `purchase_denied` emission on input.

- [ ] **Step 1: Write a failing renderer assertion**

Instantiate a configured renderer, click a locked buyable slot, and assert no purchase signal emits.

- [ ] **Step 2: Run the renderer runner to verify it fails**

Run: `godot --headless --path . --script res://tests/store_layer_renderer_test_runner.gd`
Expected: FAIL because a locked buyable slot currently emits a purchase signal.

- [ ] **Step 3: Remove direct locked-slot purchase handling**

Keep locked product rendering but make `_slot_input` return for unstocked products.

- [ ] **Step 4: Run the renderer runner to verify it passes**

Run: `godot --headless --path . --script res://tests/store_layer_renderer_test_runner.gd`
Expected: PASS.

### Task 3: Build the shelf shop modal and connect it to gameplay

**Files:**
- Create: `scripts/shelf_shop_modal.gd`
- Modify: `scripts/main.gd`
- Test: `tests/gameplay_test_runner.gd`

**Interfaces:**
- Consumes: `CampaignState.purchase_store_group(group_id: String, price: int) -> bool`, `StoreConfig.load_config(path) -> Dictionary`.
- Produces: `ShelfShopModal.configure(config: Dictionary, purchased_groups: Array, cash: int)` and a `purchase_requested(group_id: String, price: int)` signal.

- [ ] **Step 1: Write failing model assertions**

Assert an offered group deducts its configured cost once, persists in `purchased_store_groups`, and contributes all group products to the available stock.

- [ ] **Step 2: Run the gameplay runner to verify it fails**

Run: `godot --headless --path . --script res://tests/gameplay_test_runner.gd`
Expected: FAIL until shelf group data and purchase-path behavior match the spec.

- [ ] **Step 3: Implement `ShelfShopModal` and the HUD shop button**

Use a dimming backdrop, current-cash header, shelf cards, Buy/Not Enough/Purchased states, and Close button. Position the Shop button at the upper-right inside the HUD. Have `main.gd` rebuild the shelf and refresh cash/modal state after a successful modal purchase.

- [ ] **Step 4: Run the gameplay runner to verify it passes**

Run: `godot --headless --path . --script res://tests/gameplay_test_runner.gd`
Expected: PASS.

### Task 4: Verify the complete shop flow

**Files:**
- Test: `tests/store_layer_config_test_runner.gd`
- Test: `tests/store_layer_renderer_test_runner.gd`
- Test: `tests/gameplay_test_runner.gd`

- [ ] **Step 1: Run all focused SceneTree test runners**

Run each Task 1-3 runner and `git diff --check`.
Expected: all runners pass and no whitespace errors.

- [ ] **Step 2: Run the Godot project parser**

Run: `godot --headless --editor --quit`
Expected: exit 0 with no GDScript parse errors.
