# Core Gameplay Loop Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver a reliable mouse/touch product fulfilment loop with timed customers, capped arrivals, and immediate cash/clock feedback.

**Architecture:** `ShiftManager` keeps campaign state authoritative and gains narrow runtime pacing overrides. `ProductDragItem` owns its cursor-following preview and emits one release event; `Main` maps that release to a customer actor and then asks `ShiftManager` to deliver. `CustomerSlot` renders patience state and exposes its actor rectangle as the drop target.

**Tech Stack:** Godot 4.7.2, GDScript, headless SceneTree regression runners.

**Spec:** `docs/superpowers/specs/2026-10-21-core-gameplay-loop-design.md`

## Global Constraints

- Preserve the 640x360 viewport and existing product/campaign resource data.
- Support mouse and touch input.
- Keep shelf items visible and stationary while a single preview is dragged.
- Limit visible active customers to two; arrival delays must be 5–12 seconds.
- Use a 25-second customer patience duration and green/yellow/red thresholds at 50% and 25%.

## Review Focus

- A release outside every customer must return and free the preview without changing state.
- A wrong product over an actor must not pay, fulfil, or consume shelf stock.
- A completed order must pay exactly once and promptly remove its actor.
- A timed-out customer must leave unpaid and reject later drops.
- Clock updates must reach 6:00 PM before shift completion.

---

### Task 1: Add observable gameplay-loop regression coverage

**Files:**
- Create: `tests/core_gameplay_loop_test_runner.gd`
- Modify: `tests/gameplay_test_runner.gd`

**Interfaces:**
- Consumes: real `ShiftManager`, `CustomerSlot`, and `ProductDragItem` instances.
- Produces: failing assertions for queue cap/pacing, patience colors, and drag-preview completion.

- [ ] **Step 1: Write failing runtime tests**

Cover a two-customer cap, 5–12 second queued arrival delay, 25-second spawned patience, 6:00 PM clock, discrete patience colors, and one preview which reports a release coordinate.

- [ ] **Step 2: Run tests and observe expected failures**

Run: Godot 4.7.2 headless test runners.
Expected: failures for missing queue override, preview release lifecycle, and color thresholds.

### Task 2: Add queue pacing and customer feedback

**Files:**
- Modify: `scripts/shift_manager.gd`
- Modify: `scripts/customer_slot.gd`
- Modify: `scripts/storefront_layout.gd`

**Interfaces:**
- Consumes: runtime limits assigned by `Main`.
- Produces: `active_customer_limit_override`, `spawn_delay_min_seconds`, `spawn_delay_max_seconds`, `patience_seconds_override`, `contains_drop_point`, and layout timing constants.

- [ ] **Step 1: Implement minimal authoritative pacing changes**

Use one selected delay after every arrival, honour the two-customer override, and use the patience override for new `CustomerState` instances.

- [ ] **Step 2: Render discrete patience thresholds and an annoyed departure reaction**

Keep rendering read-only with respect to `CustomerState`.

- [ ] **Step 3: Run the focused test and observe it pass**

### Task 3: Implement mouse/touch drag preview and release routing

**Files:**
- Modify: `scenes/product_drag_item.tscn`
- Modify: `scripts/product_drag_item.gd`
- Modify: `scripts/main.gd`

**Interfaces:**
- Consumes: `ProductDragItem.product_released(product_id, viewport_position, source)`.
- Produces: one preview, source-preserving drag behavior, customer resolution, fulfilled/returned result handling, and cash pop animation.

- [ ] **Step 1: Implement one pointer-managed preview per source drag**

Start from mouse/touch press; follow motion; emit release; return rejected/outside previews using a spring tween.

- [ ] **Step 2: Route releases through `ShiftManager.deliver_product`**

Resolve actor hit rectangles in Main, preserve `ShiftManager` as state owner, and animate feedback without duplicating payout logic.

- [ ] **Step 3: Run focused and existing regression runners**

Run: Godot 4.7.2 focused core, gameplay, and storefront regressions.

### Task 4: Verify the shipped loop

**Files:**
- Test: `tests/core_gameplay_loop_test_runner.gd`

- [ ] **Step 1: Run formatting and all available Godot regression runners**

- [ ] **Step 2: Inspect editor preview for input/layer errors**

