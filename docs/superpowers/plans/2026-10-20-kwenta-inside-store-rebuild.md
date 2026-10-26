# Kwenta Inside-Store Rebuild Implementation Plan

> **For agentic workers:** Use `superpowers:executing-plans` to implement this plan inline. Steps use checkbox syntax for tracking.

**Goal:** Rebuild the storefront to the revised reference: seller-side camera, customer window above, fixed products on the lower shelves, and direct drag-to-customer play.

**Architecture:** Preserve campaign/order logic. Replace the generated exterior background with a new inside-store background and deterministic foreground slot layout. Render available generic product sprites at fixed slot dimensions, place small customer actors in the window area, and keep the HUD and between-shift campaign screen.

**Tech Stack:** Godot 4.7.2 standard, GDScript, 640×360 viewport, existing product/customer atlases and model tests.

**Spec:** `docs/Kwenta - Cooking Fever Gameplay Reference (Target Feel).md`

## Global constraints

- Base viewport remains 640×360, landscape, Android touch.
- Camera is inside the store, looking through a central window.
- Window/customer area is x≈150–490, y=24–200; counter y=200–222; shelves y=224–352.
- Day 1 has seven available products; scheduled/optional products remain hidden until unlocked.
- No text product list, gameplay prices, scroll views, brands/logos, or cooking minigame.
- Preserve current user changes; do not stage or commit.

## Review focus

- Five customers and their bubbles must fit inside the window without obscuring shelf products.
- Product hitboxes must be distinct and stay on the fixed art slots.
- Layers must allow drag pickup across decorative window/frame pixels.
- Empty and wrong drops must not change orders or payment; duplicates decrement one unit at a time.
- Optional purchases remain between shifts only; scheduled products appear after their configured day.

---

### Task 1: Layout geometry and acceptance tests

**Files:** `scripts/storefront_layout.gd`, `tests/gameplay_test_runner.gd`

- [x] Add assertions for player-side product slot bounds/sizes, 1–5 actor positions within the window, and slot/display geometry.
- [ ] Run the Godot SceneTree test runner. The attempt returned “godot is not recognized” in this shell; runtime test results remain pending.
- [x] Implement constants/helpers for window rect, shelf/hanging slots, customer positions and icon order entries.
- [ ] Run the SceneTree tests; run `git diff --check` after the full implementation.

### Task 2: Seller-side background and product art

**Files:** `assets/store/kwenta_layer_pack/bg_empty.png`, `assets/sprites/kwenta_generic_products.png`, `scripts/counter_art.gd`

- [x] Generate a 16:9 inside-store view with an empty central window, edge-only grille, sill, hanging-strip edges, blank shelf-row A, empty red cooler at row B, and candy jar. No people, UI, text, brands, or sellable stock in interaction slots.
- [x] Generate original unbranded product sprites and map their atlas regions.
- [x] Inspect composition/dimensions and confirm the product atlas background is transparent; exact runtime crop still needs Godot/editor review.
- [x] Keep old artwork as sibling assets; do not overwrite it.

### Task 3: Scene layers and fixed product sprites

**Files:** `scripts/main.gd`, `scripts/storefront_layout.gd`, `scripts/product_drag_item.gd`, `scenes/product_drag_item.tscn`

- [x] Add an assertion that available Day 1 products receive fixed slots and all slot rectangles are non-overlapping.
- [x] Position sprites on player-side shelf/hanging-strip areas, not the window; include all row A/B and cooler products.
- [x] Draw each cropped atlas icon centered and aspect-fit to its explicit visible art size, separate from its touch target.
- [x] Keep hidden products absent before unlock; purchase-only controls stay in between-shift summary.
- [ ] Run the test runner and `git diff --check`.

### Task 4: Window customers and drag feedback

**Files:** `scripts/main.gd`, `scripts/customer_slot.gd`, `scenes/customer_slot.tscn`

- [x] Add assertions for customer positions within x=150–490 and order entries for partial, completed and duplicate quantities.
- [x] Reposition customer actors into the central window and resize portraits/bubbles for up to five actors.
- [x] Implement patience color, subtle hover, correct bubble pop, wrong shake/return, empty-drop no-op, and completion coin/happy exit.
- [x] Remove code-drawn grille bars across the central window; the edge-only frame is in the non-interactive background.
- [ ] Run the test runner and `git diff --check`.

### Task 5: Context and verification

**Files:** `KWENTA_MASTER_CONTEXT.md`, `docs/Kwenta - Cooking Fever Gameplay Reference (Target Feel).md`

- [x] Update the master context to say seller-side camera is the authoritative layout.
- [x] Record implemented pieces and mark runtime verification pending.
- [ ] Run final static checks and verify branch/working tree; do not stage/commit.
- [ ] Import and manually check all acceptance items in Godot; runtime verification is pending because Godot is unavailable in this shell.
