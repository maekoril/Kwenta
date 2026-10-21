# Kwenta Storefront Rebuild Implementation Plan

> Superseded by `2026-10-20-kwenta-inside-store-rebuild.md` after the revised reference clarified that the camera is inside the store and products belong on the player-side lower shelves.

> **For agentic workers:** Use the `superpowers:executing-plans` workflow inline. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Turn the current storefront prototype into a single-screen, Cooking Fever-like sari-sari window interaction with fixed draggable product sprites, icon-only customer orders, and customers below the ledge.

**Architecture:** Keep the existing order/campaign/shift models. Add deterministic storefront slot geometry and order-bubble presentation helpers, test those helpers in the existing Godot SceneTree test runner, then rebuild only the presentation controls around them. Product sprites stay in persistent window slots; customer actors are the only order drop targets.

**Tech Stack:** Godot 4.7.2 stable standard, GDScript, Control nodes, Resources, existing product/customer atlases, generated raster background.

**Spec:** `docs/superpowers/specs/2026-10-19-kwenta-gameplay-design.md`, updated with the storefront reference requirements.

## Global Constraints

- Preserve the 640×360 landscape base viewport and Android touch support.
- Preserve the ten-shift summer story, customer trust, patience, timed closing, order logic, product data, scheduled unlocks, and optional permanent product unlocks.
- Do not add cooking, a Mom's Tips feature, a cooking-equipment upgrade tree, or Cooking Fever assets/branding.
- The active shift screen has no scrollbars, text product lists, prices, product names, or modal confirmations.
- The grille is decorative and must not consume mouse/touch input.
- Do not stage or commit changes unless the user asks; leave unrelated work intact.

## Review Focus

- A locked scheduled product must not appear as a draggable sprite before its unlock day.
- An optional cash-unlock product must not silently spend money during an active shift; it can be unlocked between shifts, then appears in its permanent slot.
- A drag over the grille must still reach the product/customer controls.
- Delivering one of several duplicate units must reduce only the visible remaining count, without consuming the shelf sprite.
- When a customer leaves, remaining characters must stay in bounds and the next arrival must get a distinct target position.

---

### Task 1: Deterministic Storefront Geometry and Window Art

**Files:**
- Create: `scripts/storefront_layout.gd`
- Create: `assets/backgrounds/kwenta_store_window_background.png`
- Modify: `tests/gameplay_test_runner.gd`
- Modify: `scripts/main.gd`

**Interfaces:**
- `StorefrontLayout.get_product_slot(product_id: String) -> Rect2` returns the fixed, touch-sized product hit area or an empty rectangle for unknown IDs.
- `StorefrontLayout.get_customer_x_positions(count: int, viewport_width: float = 640.0, actor_width: float = 124.0) -> Array[float]` spaces 1–5 customers evenly without clipping.
- The window occupies approximately x=20..620 and y=24..170; the concrete ledge is around y=170..195; customers stand below it.

- [ ] Write tests for all eleven product slots being unique, inside the window, and at least 32×32; write literal position/bounds assertions for 1, 2, and 5 customer positions.
- [ ] Run `godot --headless --path . --script res://tests/gameplay_test_runner.gd`; verify the new layout tests fail because `StorefrontLayout` is missing.
- [ ] Generate a project-owned pixel-art window background with empty fixed hooks/shelf spaces, steel grille area, cooler, concrete ledge, and street; no people, brand logos, readable text, or UI.
- [ ] Implement the tested geometry helper and switch the main scene background/layer setup to the new asset.
- [ ] Re-run the SceneTree test runner and `git diff --check`.

### Task 2: Fixed Product Sprites in the Store Window

**Files:**
- Modify: `scripts/product_drag_item.gd`
- Modify: `scenes/product_drag_item.tscn`
- Modify: `scripts/main.gd`
- Modify: `tests/gameplay_test_runner.gd`

**Interfaces:**
- `ProductDragItem.configure(product: ProductData, icon_texture: Texture2D, can_drag: bool)` configures a sprite-only control.
- `ProductDragItem.play_reject() -> void` gives the source sprite a short return/shake animation after a wrong drop; the shelf slot remains stocked.
- Available products use their fixed `StorefrontLayout` rectangles. Day-locked products are absent from the active window; optional purchases happen only from the between-shift summary, without an active-shift popup or price list.

- [ ] Add a failing assertion that the seven Day 1 products resolve to seven distinct visible slots, while scheduled products do not enter the Day 1 visible set.
- [ ] Run the SceneTree test runner and verify the assertion fails before the layout/presentation interface exists.
- [ ] Replace the scrolling grid and text rows with fixed `TextureButton` product sprites over the window/cooler; remove names, prices, “unlimited,” lock labels, and the active-shift product panel.
- [ ] Preserve unlimited stock and permanent cash unlocks; expose purchase buttons only in the between-shift summary and show the item in its fixed slot after purchase/day unlock.
- [ ] Run all model/layout tests and `git diff --check`.

### Task 3: Icon-Only Order Bubbles and Customer Street Positions

**Files:**
- Modify: `scripts/customer_slot.gd`
- Modify: `scenes/customer_slot.tscn`
- Modify: `scripts/main.gd`
- Modify: `scripts/storefront_layout.gd`
- Modify: `tests/gameplay_test_runner.gd`

**Interfaces:**
- `StorefrontLayout.get_order_icon_entries(requested: Dictionary, delivered: Dictionary) -> Array[Dictionary]` returns one entry per product with `product_id`, `remaining`, and `completed` fields.
- Customer actors stand below the ledge, face the player, and use the whole character/bubble area as their drop target. Their order bubbles display product icons and remaining quantities only.
- Patience is shown beside/under the bubble and changes green → yellow → red as it drains; customer name/trust remains a small secondary tag.

- [ ] Add failing assertions for an order with two different products, a duplicate quantity, one partial delivery, and one completed product; assert remaining unit counts and completion flags.
- [ ] Run the SceneTree test runner and verify those assertions fail before implementing the presentation helper.
- [ ] Implement the helper, render atlas icons and compact ×N badges in bubbles, visually clear delivered quantities, and move actor sprites to the street below the ledge.
- [ ] Confirm 1–5 customers fit without overlapping order bubbles or covering product slots.
- [ ] Run the full SceneTree test runner and `git diff --check`.

### Task 4: Drag Feedback and Runtime Acceptance

**Files:**
- Modify: `scripts/product_drag_item.gd`
- Modify: `scripts/customer_slot.gd`
- Modify: `scripts/main.gd`
- Modify: `tests/gameplay_test_runner.gd`

**Interfaces:**
- Correct drops update the targeted bubble immediately; the source shelf sprite remains in place.
- Wrong drops give the customer a subtle shake/highlight response and return the source to its slot; empty-space drops leave state unchanged.
- Completed orders show a short happy/coin reaction, then move the customer out so the next arrival can use the open lane.
- Grille overlay has `mouse_filter = Control.MOUSE_FILTER_IGNORE` and never intercepts drag/touch input.

- [ ] Add any model assertions required to ensure rejected/empty drops cannot advance orders or pay; run them before changing behavior.
- [ ] Implement subtle hover, rejected-item shake, correct-item bubble feedback, completion reaction, and non-blocking grille layering without adding instructional popups or sound assets.
- [ ] Run `godot --headless --path . --script res://tests/gameplay_test_runner.gd` and `git diff --check`.
- [ ] In Godot 4.7.2, verify import/parse and manually test: both arrival directions, 2 and 5 customers, correct/wrong/duplicate drags, dragging across grille, day unlocks, optional between-day purchase, and closing.

### Task 5: Keep Project Context in Sync

**Files:**
- Modify: `docs/superpowers/specs/2026-10-19-kwenta-gameplay-design.md`
- Modify: `KWENTA_MASTER_CONTEXT.md`

- [ ] Record the attached storefront reference as the authoritative layout/interaction direction while retaining story, trust, and campaign decisions.
- [ ] Update implementation and verification status only to what was actually tested.
- [ ] Review the final Git status; do not stage/commit unless asked.

## Execution Notes

- The existing `scripts/customer_slot.gd` filename is legacy naming; it can remain for this bounded presentation rebuild unless a rename is needed to make resource references safer.
- Do not overwrite or delete the existing background; this plan adds a new sibling asset.
- Godot may not be on PATH. Search likely installed locations before concluding runtime tests are unavailable; never claim the scene runs unless an actual Godot command/editor run confirms it.
