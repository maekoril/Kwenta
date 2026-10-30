# Layered Store Scene Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the monolithic storefront rendering with the supplied layered store art, tappable product stickers, and in-scene unlock states without changing customer, order, patience, or HUD behavior.

**Architecture:** A `StoreLayerRenderer` Control will parse `slots.json` and `store_config.json`, render the background/customer/front/sticker/overlay stack, and expose slot interactions. It converts 1672×941 art coordinates into the existing 1920×1080 internal Godot viewport; because the project displays that canvas at 1280×720, this produces the requested on-screen scale of 1280/1672 while leaving existing HUD and customer systems at their current coordinates.

**Tech Stack:** Godot 4.7.2, GDScript, JSON data files, existing campaign state and product resources.

**Spec:** User request in this chat, 2026-10-25.

## Global Constraints

- Do not change `project.godot`, HUD, customer actor, order bubble, patience bar, or existing single-item drag/order sprites.
- Draw order is empty background, customer layer, front background, product stickers, lock/price overlays, then existing HUD.
- Treat 1672×941 as authored art coordinates; derive display positions from one uniform scale.
- Missing sticker assets must render a product-name placeholder and must not crash.
- Story items auto-stock on their configured day; buy items remain purchasable after their unlock day until bought.
- F1 toggles scaled `slot_rect` outlines.

## Review Focus

- A missing sticker PNG must show a label instead of failing scene construction (Task 2 test).
- Day 1 must expose only the five requested stock IDs and locks every other slot (Task 3 test).
- A later-day skipped purchase must retain its price overlay and interaction (Task 3 test).
- The three condiment stickers must use one shared lock/price target and one cash deduction (Task 3 test).
- Touch and mouse activation must share the same purchase path and insufficient-cash state must not mutate campaign money (Task 4 test).

---

### Task 1: Define store stock and unlock data

**Files:**
- Create: `data/store_config.json`
- Create: `tests/store_layer_config_test_runner.gd`

**Interfaces:**
- Produces `StoreConfig.load_config(path: String) -> Dictionary` data consumed by the renderer.
- Uses the asset IDs in `assets/store/kwenta_layer_pack/slots.json`.

- [ ] **Step 1: Write failing configuration tests**

Assert every slot has a config record; Day 1 stocks only `feeta`, `noodz`, `thang`, `cola_coca`, `egg_large`; and the condiment group is a single buy group at Day 3 / PHP 300.

- [ ] **Step 2: Run the configuration test to verify it fails**

Run: `godot --headless -s res://tests/store_layer_config_test_runner.gd`
Expected: FAIL because `store_config.json` and loader do not exist.

- [ ] **Step 3: Create editable `data/store_config.json` and minimal config loader**

Use the exact story and buy unlock schedule from the request. Assign `purchase_group: "condiments"` to `boss_toyo`, `pating`, and `real_suka`; retain all other product IDs as individual groups.

- [ ] **Step 4: Run the configuration test to verify it passes**

Run: `godot --headless -s res://tests/store_layer_config_test_runner.gd`
Expected: PASS.

### Task 2: Render layered background and stickers from authored slot data

**Files:**
- Create: `scripts/store_layer_renderer.gd`
- Create: `tests/store_layer_renderer_test_runner.gd`
- Modify: `scenes/main.tscn`
- Modify: `scripts/main.gd`

**Interfaces:**
- Consumes `slots.json`, `store_config.json`, and `CampaignState`.
- Produces `refresh(day: int, cash: int, purchased_groups: Array[String]) -> void` and `purchase_requested(group_id: String) -> void`.

- [ ] **Step 1: Write failing renderer tests**

Assert background nodes draw in the required order, sticker nodes use uniformly scaled `x/y/w/h`, each `slot_rect` produces an `Area2D` with a scaled rectangle shape, and a missing sticker produces a named fallback label.

- [ ] **Step 2: Run renderer tests to verify they fail**

Run: `godot --headless -s res://tests/store_layer_renderer_test_runner.gd`
Expected: FAIL because `StoreLayerRenderer` is absent.

- [ ] **Step 3: Implement `StoreLayerRenderer` and wire it into the main scene**

Render `bg_empty.png`, use the existing `customer_layer` between the two background pieces, then render `bg_front.png`, stickers, and overlays. Preserve existing customer nodes and their z-order by placing the renderer background/front on either side of the existing customer layer. Use `Sprite2D` sticker nodes with authored sticker dimensions and uniform coordinate scaling; build `Area2D` tap targets from `slot_rect`.

- [ ] **Step 4: Run renderer tests to verify they pass**

Run: `godot --headless -s res://tests/store_layer_renderer_test_runner.gd`
Expected: PASS.

### Task 3: Implement story/buy lock state and shared condiment purchase

**Files:**
- Modify: `scripts/store_layer_renderer.gd`
- Modify: `scripts/main.gd`
- Modify: `scripts/campaign_state.gd`
- Modify: `tests/store_layer_renderer_test_runner.gd`

**Interfaces:**
- `StoreLayerRenderer` emits `purchase_requested(group_id: String)`.
- `CampaignState.purchase_store_group(group_id: String, price: int, product_ids: Array[String]) -> bool` persists successful purchases.

- [ ] **Step 1: Write failing interaction-state tests**

Test story stock by day, locked Day labels before unlock days, PHP labels on available purchases, persistent successful purchases, insufficient-cash refusal, and the three-condiment one-price group.

- [ ] **Step 2: Run interaction-state tests to verify they fail**

Run: `godot --headless -s res://tests/store_layer_renderer_test_runner.gd`
Expected: FAIL because grouped store purchases and state overlays are missing.

- [ ] **Step 3: Implement state transitions and overlays**

Show stocked stickers as tappable. For locked entries hide stickers and draw a centered padlock plus `DAY N` or `PHP price`; use one overlay centered over the union of condiment slot rectangles. On insufficient cash, shake the lock and show a brief in-scene message; on success deduct once, persist the group, and refresh all associated stickers.

- [ ] **Step 4: Run interaction-state tests to verify they pass**

Run: `godot --headless -s res://tests/store_layer_renderer_test_runner.gd`
Expected: PASS.

### Task 4: Preserve customer/order behavior and add debug alignment overlay

**Files:**
- Modify: `scripts/main.gd`
- Modify: `scripts/store_layer_renderer.gd`
- Modify: `tests/store_asset_integration_test_runner.gd`
- Modify: `tests/gameplay_test_runner.gd`

**Interfaces:**
- `StoreLayerRenderer.toggle_slot_debug() -> void` toggles authored-rect diagnostics.
- Existing `ProductDragItem` remains the source for dragged items and order-bubble icons.

- [ ] **Step 1: Write failing regression tests**

Assert F1 toggles slot outlines, customer layer remains behind the front art, existing order icon textures still resolve from single-item textures, and a renderer purchase does not change existing delivery/order code paths.

- [ ] **Step 2: Run regression tests to verify they fail**

Run: `godot --headless -s res://tests/store_asset_integration_test_runner.gd` and `godot --headless -s res://tests/gameplay_test_runner.gd`
Expected: FAIL because no layered renderer integration/debug switch exists.

- [ ] **Step 3: Integrate F1 and refresh hooks without replacing gameplay item sprites**

Connect day/cash/purchase refreshes to the renderer; leave `ProductData.single_unit_texture`, order bubbles, customer delivery, and patience code unchanged. Route F1 to renderer debug outlines while preserving F10 debug skip.

- [ ] **Step 4: Run the full regression suite**

Run: every `tests/*_test_runner.gd` headlessly.
Expected: PASS with no parser errors or runtime warnings.
