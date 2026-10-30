# Supplier Shelf Render Repair Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Render the shop as the supplied Supplier's Shelf composition, with only live cash, purchase buttons, and close interaction layered over it.

**Architecture:** Treat `supplier_shelf_panel_v3.png` as the single visual source of truth for the frame, title, fixture cards, product art, and descriptions. `ShelfShopModal` remains responsible for data and interactions, but it stops stretching full-canvas chrome assets into per-fixture cards. Five transparent fixture interaction zones place the current 160×36 BUY/NEED buttons at deliberately mapped positions over the baked artwork.

**Tech Stack:** Godot 4.7.2, GDScript `Control` nodes, `TextureRect`, SceneTree test runner.

**Spec:** `docs/superpowers/specs/2026-10-29-shelf-shop-design.md`

## Global Constraints

- Preserve the `CampaignState.purchased_store_groups` format and the existing `purchase_requested(group_id, price)` signal.
- Keep fixture prices and product-group configuration in `data/store_config.json`.
- Keep the user-specified button copy: `BUY ₱[price]` and `NEED ₱[price]`.
- Render BUY and NEED action controls at the same fixed 160×36 size.
- Do not use `supplier_shop_card_chrome_v1.png` as a per-card background; it is a full artwork slice, not a reusable card skin.

## Review Focus

- An unaffordable shelf must use the linisin art with `NEED ₱[price]`, without changing its bounds.
- A purchasable shelf must use the ibigay art and emit exactly one group/price signal.
- Purchased shelves must remain disabled and must not overlap another fixture’s interaction area.
- The live cash label must sit inside the baked green cash tag at the panel’s scale.
- The close hit target must sit over the baked red X and remain usable without rendering a second X.

---

### Task 1: Lock the composed-panel contract in the shop regression

**Files:**
- Modify: `tests/shelf_shop_modal_test_runner.gd`

**Interfaces:**
- Consumes: `ShelfShopModal.configure(shop_config: Dictionary, owned_groups: Array, current_cash: int)`.
- Produces: regression coverage for a single composed panel background and five fixed action zones.

- [ ] **Step 1: Write a failing assertion that `SupplierShopPanel/PanelArt` uses `res://assets/sprites/ui/shop/supplier_shelf_panel_v3.png` at the full panel bounds.**

- [ ] **Step 2: Run the focused test to verify it fails.**

Run: `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/shelf_shop_modal_test_runner.gd`

Expected: FAIL because the modal still composes the frame and board separately.

- [ ] **Step 3: Add failing assertions that fixture action zones have no `CardChrome`, remain within the panel, and retain their existing 160×36 button bounds.**

- [ ] **Step 4: Run the focused test to verify it fails for the expected structural reason.**

### Task 2: Render the supplied panel as one visual layer

**Files:**
- Modify: `scripts/shelf_shop_modal.gd`

**Interfaces:**
- Consumes: `supplier_shelf_panel_v3.png` as `PANEL_ART_TEXTURE`.
- Produces: `SupplierShopPanel/PanelArt: TextureRect` and a transparent `FixtureGrid` that owns only live interaction controls.

- [ ] **Step 1: Replace the separate frame, paper, title, subtitle, cash-tag, and close-image render nodes in `_build_shell()` with one full-size `PanelArt` `TextureRect`.**

Keep the existing `PANEL_SIZE`/`PANEL_POSITION` scaling so the 1670×942 source art stays proportional in the 1510×850 modal.

- [ ] **Step 2: Add a transparent close `TextureButton` over the red X position without assigning it a texture.**

The baked X remains the only visible close icon; the button keeps the existing `CloseShop` node name, focus policy, tooltip, and `close` connection.

- [ ] **Step 3: Move the cash label into the baked green tag and remove its standalone chrome texture.**

Use the panel-art scale factor and a fixed mapped rectangle so `₱[cash]` remains centered in the tag.

- [ ] **Step 4: Run the focused test to verify the composed panel contract passes.**

### Task 3: Convert fixture cards into live action overlays

**Files:**
- Modify: `scripts/shelf_shop_modal.gd`
- Modify: `tests/shelf_shop_modal_test_runner.gd`

**Interfaces:**
- Consumes: `FIXTURES`, `_group_price(group_id: String, products: Dictionary) -> int`, and purchase state.
- Produces: `_make_fixture_card(...) -> Control` containing only an accessible 160×36 `BuyButton` placed over the matching baked fixture card.

- [ ] **Step 1: Write failing tests for the five explicit button positions and for the absence of duplicate product/name/description/card-chrome nodes.**

- [ ] **Step 2: Run the focused test to verify it fails.**

- [ ] **Step 3: Replace `CARD_SIZE`, card chrome, product previews, and duplicate labels with five transparent hit zones mapped from the V3 artwork.**

Place each action button in its fixture’s lower-right clear area; retain the existing BUY/NEED/PURCHASED state and signal behavior.

- [ ] **Step 4: Run the focused test to verify it passes.**

### Task 4: Validate the repaired panel in Godot

**Files:**
- Modify: `tests/shelf_shop_modal_test_runner.gd` only if a missing assertion is found during validation.

**Interfaces:**
- Consumes: the completed modal and focused test runner.
- Produces: evidence that no visual duplication or interaction regression remains.

- [ ] **Step 1: Run the focused shelf-shop regression.**

Run: `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/shelf_shop_modal_test_runner.gd`

Expected: `Shelf shop modal assertions passed.`

- [ ] **Step 2: Open the Shop at ₱150 and inspect the modal at the project’s 1280×720 display scale.**

Expected: one full Supplier's Shelf panel, no stretched shelf rails behind the copy, correctly aligned baked fixture art, two BUY controls, three NEED controls, centered cash, and one visible close X.

- [ ] **Step 3: Purchase a fixture and reopen the modal.**

Expected: cash updates, the owned fixture reads `PURCHASED`, and the other action buttons do not move or change size.

- [ ] **Step 4: Run `git diff --check` and the focused shelf-shop regression again.**

Expected: no whitespace errors and a passing focused test.
