# Storefront Layout Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ground and layer customers correctly in the 640x360 storefront while providing compact order UI and fixed, named layout zones.

**Architecture:** The `.tscn` supplies named, non-interactive layout markers plus a cropped foreground sill. `StorefrontLayout` remains the viewport-space layout authority. Customer actors calculate their own compact UI sizes; main-layer z indices establish background → customer → sill → products → HUD ordering.

**Tech Stack:** Godot 4.7.2, GDScript, Control nodes, existing headless GDScript test runner.

**Spec:** `docs/superpowers/specs/2026-10-21-storefront-layout-phase-1-design.md`

## Global Constraints

- Preserve the 640x360 viewport and existing product, campaign, story, and order data.
- Keep customer drop targets inside the centre window and clear of both overhead rails.
- Use existing artwork only; foreground occlusion comes from the current storefront background.
- Keep all visual interaction controls pixel-art friendly (nearest filtering and minimal UI margins).

## Review Focus

- A five-customer lineup must remain wholly within `x=150..490` and below the rail zones.
- Three-icon rows must fit inside a 68px customer target without clipping.
- Two-row orders must move the patience bar down exactly with the speech bubble.
- The sill must occlude customer lower bodies but never countertop/shelf product displays.
- Rails, countertop, shelf rows and contact-shadow data must remain inside the 640x360 viewport.

---

### Task 1: Define named storefront zones and grounding data

**Files:**
- Modify: `scripts/storefront_layout.gd`
- Test: `tests/storefront_layout_phase_1_test_runner.gd`

**Interfaces:**
- Produces: `STOREFRONT_ZONES`, `CUSTOMER_DROP_RECT`, `CONTACT_SHADOW_HEIGHT`, `get_storefront_zone(zone_id)`, and `get_customer_drop_rect(customer_x)`.

- [ ] **Step 1: Write failing zone and customer-bound tests**

Assert rail, counter, Shelf A, Shelf B and customer-drop rectangles stay inside the viewport; assert five customer targets stay below the rail boundary.

- [ ] **Step 2: Run the zone test to verify it fails**

Run: `godot --headless --path . --script res://tests/storefront_layout_phase_1_test_runner.gd`

Expected: FAIL because the named-zone/customer-drop interface is absent.

- [ ] **Step 3: Implement fixed zones and customer geometry in `scripts/storefront_layout.gd`**

Use viewport-space `Rect2` constants: rails at `x=20..140` and `500..620`, `y=24..84`; countertop at `y=198..222`; Shelf A at `y=224..285`; Shelf B at `y=288..352`; and a 1–2px contact shadow height.

- [ ] **Step 4: Run the zone test to verify it passes**

Run: `godot --headless --path . --script res://tests/storefront_layout_phase_1_test_runner.gd`

Expected: PASS.

### Task 2: Build the foreground layout tree and draw-order layers

**Files:**
- Modify: `scenes/main.tscn`
- Modify: `scripts/main.gd`
- Test: `tests/storefront_layout_phase_1_test_runner.gd`

**Interfaces:**
- Consumes: `StorefrontLayout.STOREFRONT_ZONES` and `CUSTOMER_Y`.
- Produces: named layout-marker nodes and `ForegroundCounterSill` over the customer layer.

- [ ] **Step 1: Extend the failing scene test**

Assert the packed main scene contains `StorefrontLayout`, its named zone markers, and `ForegroundCounterSill` with a higher z index than customers.

- [ ] **Step 2: Run the scene test to verify it fails**

Run: `godot --headless --path . --script res://tests/storefront_layout_phase_1_test_runner.gd`

Expected: FAIL because the foreground sill and marker nodes do not exist.

- [ ] **Step 3: Add fixed marker controls and a cropped counter-sill overlay**

Add non-interactive rail, counter, shelf and customer-window controls in `scenes/main.tscn`. Set main runtime layers to background → customers → sill → products → HUD/summary, retaining products above the sill.

- [ ] **Step 4: Run the scene test to verify it passes**

Run: `godot --headless --path . --script res://tests/storefront_layout_phase_1_test_runner.gd`

Expected: PASS.

### Task 3: Refactor the customer actor UI and drag target

**Files:**
- Modify: `scenes/customer_slot.tscn`
- Modify: `scripts/customer_slot.gd`
- Test: `tests/storefront_layout_phase_1_test_runner.gd`

**Interfaces:**
- Consumes: customer geometry and compact-icon constants from `StorefrontLayout`.
- Produces: `get_drop_target_rect()` and dynamic compact bubble layout.

- [ ] **Step 1: Extend the failing actor test**

Instantiate the customer scene with a one-item and multi-item order; assert the bubble is tightly sized, the patience bar begins directly below it, and the returned drop target encloses portrait and bubble.

- [ ] **Step 2: Run the actor test to verify it fails**

Run: `godot --headless --path . --script res://tests/storefront_layout_phase_1_test_runner.gd`

Expected: FAIL because the actor has no dynamic compact-layout/drop-target interface.

- [ ] **Step 3: Implement the compact bubble, sibling patience bar and pill tag**

Use 20px item cells with 2px panel padding; calculate bubble rows/columns in `refresh_display()`, anchor the bar one pixel below it, and replace the raw name label with a dark rounded `PanelContainer` tag. Keep all child controls mouse-ignoring so the actor remains the one drop target.

- [ ] **Step 4: Run the targeted visual-model test and project script check**

Run: `godot --headless --path . --script res://tests/storefront_layout_phase_1_test_runner.gd`

Expected: PASS.

### Task 4: Run regression and visual verification

**Files:**
- Test: `tests/gameplay_test_runner.gd`

- [ ] **Step 1: Run the existing model suite**

Run: `godot --headless --path . --script res://tests/gameplay_test_runner.gd`

Expected: `All gameplay model assertions passed.`

- [ ] **Step 2: Load the main scene in headless mode**

Run: `godot --headless --path . --editor --quit`

Expected: no scene or GDScript parser errors.

- [ ] **Step 3: Inspect the 640x360 game view**

Confirm the portrait lower edge disappears behind the sill, all draggable shelf goods remain above it, and customer targets leave the rail zones unobstructed.
