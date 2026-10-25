# Kwenta Gameplay Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current tap-to-tray prototype with a 10-shift, mouse-and-touch sari-sari store game built around dragging requested products directly to customers, managing patience and individual trust, and progressing the teen’s summer story.

**Architecture:** Keep game rules in small GDScript state/manager classes that can be tested without loading the main scene. Keep `scenes/main.tscn` as the entry point, with reusable product and customer Controls handling drag/drop and presentation; connect these to the model through `scripts/main.gd`. Store product, customer, progression, and story content as data resources where practical, matching the repository’s data-driven rule.

**Tech Stack:** Godot 4.7.2 standard, GDScript, Godot Resources and Control nodes; no new addons or external dependencies.

**Spec:** `docs/superpowers/specs/2026-10-19-kwenta-gameplay-design.md`

## Global Constraints

- Godot 4.7.2 stable, standard (not .NET); GDScript.
- Android-first, 2D pixel-art, landscape game; support both mouse and touch dragging.
- Use the existing 640×360 base viewport, fractional viewport stretch, and expand aspect; keep essential taps inside the central area and anchor HUD to screen edges.
- Do not change Project Settings without discussing the change with the team.
- Products, customer order pools, and campaign/story content must be data-driven Resources, not hard-coded into UI nodes.
- No “Mom’s Tips” gameplay panel or tip feature.
- Stock is unlimited; completed correct orders pay automatically; timeout loses delivered items and reduces only that customer’s trust.
- The campaign has 10 story shifts; Day 1 starts with 7 products and randomized 1–3-unit orders; initial active-customer cap is 2, later rising to 3–5.
- Scheduled products unlock automatically on configured days; a separate set of purchase-only products unlock permanently with current cash.
- The end-of-summer goal is replacing worn shelves before school starts; progress is determined by current saved cash, not lifetime sales.

## Review Focus

- A wrong product or a completed order must not consume an extra requested unit or pay early — test in Task 1 and Task 4.
- Duplicate product requests must require one successful drag per requested unit — test in Task 1 and Task 4.
- A customer who timed out must not accept a late drop or pay; delivered units remain lost — test in Task 2 and Task 4.
- A product unlock purchase must not create negative cash or be purchasable twice — test in Task 3.
- The unlimited shelf must remain available and both mouse/touch drags must target the same customer at 640×360 — test stock in Task 4 and manually verify both inputs.

---

### Task 1: Product Order Model

**Files:**
- Create: `scripts/order_state.gd`
- Create: `scripts/order_factory.gd`
- Create: `scripts/order_data.gd`
- Create: `data/orders/order_pool_day_01.tres`
- Create: `tests/gameplay_test_runner.gd`

**Interfaces:**
- Produces `OrderState.new(requested: Dictionary)`, `try_deliver(product_id: String) -> int`, `is_complete() -> bool`, `remaining_quantity(product_id: String) -> int`, and `total_price(unit_prices: Dictionary) -> int`.
- `try_deliver` returns `OrderState.DeliveryResult.ACCEPTED`, `COMPLETED`, or `WRONG_PRODUCT`; each accepted call consumes exactly one unit.
- Produces `OrderFactory.make_order(order_data: OrderData, available_product_ids: Array[String], rng: RandomNumberGenerator) -> OrderState`; duplicate product IDs are allowed.
- `OrderData` is a Resource with `product_ids: Array[String]`, `minimum_units: int`, and `maximum_units: int`; `OrderFactory` filters to currently available product IDs and reads the order pool from a data Resource rather than hard-coding it in UI code.

- [ ] **Step 1: Add failing model assertions** for a correct product, a wrong product, duplicate quantities, completion only after all units, and a seeded Day 1 order between 1 and 3 units.
- [ ] **Step 2: Run the test runner** with the Godot 4.7.2 console executable: `godot --headless --path . --script res://tests/gameplay_test_runner.gd`. Expected: failing assertions for the not-yet-implemented model.
- [ ] **Step 3: Implement `OrderState` and `OrderFactory`** in their respective scripts, keeping them independent of scene nodes.
- [ ] **Step 4: Run the test runner again.** Expected: all order-model assertions pass.
- [ ] **Step 5: Commit the tested order model** with only its task files staged: `git add scripts/order_state.gd scripts/order_factory.gd scripts/order_data.gd data/orders/order_pool_day_01.tres tests/gameplay_test_runner.gd`; then `git commit -m "feat: model customer orders"`.

### Task 2: Customer State, Patience, and Trust

**Files:**
- Create: `scripts/customer_state.gd`
- Modify: `tests/gameplay_test_runner.gd`

**Interfaces:**
- Produces `CustomerState.new(customer_id: String, order: OrderState, patience_seconds: float, trust: float = 100.0)`.
- Produces `receive_product(product_id: String) -> int`, returning the corresponding `OrderState.DeliveryResult` or `CustomerState.DeliveryResult.INACTIVE`.
- Produces `advance_time(delta_seconds: float) -> bool`, which returns `true` only on the transition to timed out; timeout deactivates the customer and reduces that customer’s trust by the configurable default `25` points exactly once.
- Produces `get_return_weight() -> float`, calculated as `trust / 100.0` clamped to `[0.0, 1.0]`, so lower trust directly reduces that customer's chance of returning.

- [ ] **Step 1: Add failing assertions** for patience countdown, timeout transition, exactly-once trust reduction, lower return weight after trust loss, and rejection of a delivery after timeout.
- [ ] **Step 2: Run the test runner.** Expected: customer-state assertions fail until the class exists.
- [ ] **Step 3: Implement `CustomerState`** as plain state logic with no UI dependency.
- [ ] **Step 4: Run the test runner.** Expected: all order and customer-state assertions pass.
- [ ] **Step 5: Commit the tested customer state** with only its task files staged: `git add scripts/customer_state.gd tests/gameplay_test_runner.gd`; then `git commit -m "feat: track customer patience and trust"`.

### Task 3: Product Catalog and Campaign Progression Data

**Files:**
- Modify: `scripts/product_data.gd`
- Modify: `data/products/instant_noodles.tres`
- Modify: `data/products/soft_drink.tres`
- Modify: `data/products/chips.tres`
- Create: `data/products/biscuits.tres`, `data/products/bottled_water.tres`, `data/products/candy.tres`, and `data/products/coffee_sachet.tres` for the four additional Day 1 items
- Create: scheduled products `data/products/canned_sardines.tres` (Day 4) and `data/products/laundry_sachet.tres` (Day 7)
- Create: purchase-only products `data/products/shampoo_sachet.tres` and `data/products/toothpaste_sachet.tres`
- Create: `data/orders/order_pool_day_04.tres` and `data/orders/order_pool_day_07.tres`
- Create: `scripts/campaign_state.gd`
- Create: `scripts/campaign_config.gd`
- Create: `data/story/summer_campaign.tres`
- Modify: `tests/gameplay_test_runner.gd`

**Interfaces:**
- Extend `ProductData` with `unlock_day: int` and `unlock_cost: int`. Scheduled products have `unlock_day >= 1` and `unlock_cost = 0`; purchase-only products have `unlock_day = 0` and `unlock_cost > 0`.
- `CampaignConfig` is a Resource containing initial cash, the 10-day customer-cap schedule, max order sizes, day order pools, 480-second default shift length, configurable customer spawn interval and patience duration, shelf replacement goal, trusted-regular thresholds, and customer IDs.
- Produces `CampaignState.new(config: CampaignConfig)` with `day: int`, `cash: int`, `unlocked_product_ids: Array[String]`, `customer_trust: Dictionary`, `get_active_customer_limit() -> int`, `get_max_order_units() -> int`, `get_available_product_ids() -> Array[String]`, `get_order_data_for_day(day: int) -> OrderData`, `get_customer_trust(customer_id: String) -> float`, `save_customer_trust(customer_id: String, trust: float) -> void`, `count_trusted_regulars() -> int`, `is_product_available(product: ProductData) -> bool`, `purchase_unlock(product: ProductData) -> bool`, and `advance_day() -> void`.
- Day 1: 7 products available, maximum 2 active customers, randomized orders of 1–3 units. Suggested pacing: customer caps of 2/3/4/5 on Days 1–3/4–5/6–7/8–10; max order sizes of 3/4/5 on Days 1–3/4–6/7–10. Two additional products unlock on days 4 and 7; two optional purchase-only products are available from the start. All values remain editable in data/config.
- Paid product unlocks are permanent and use current cash. Only scheduled products become available automatically; buying a purchase-only product adds its ID once to `unlocked_product_ids`. The end-of-summer shelf-replacement goal uses current saved cash, so buying optional products delays that goal.

- [ ] **Step 1: Add failing assertions** for the seven Day 1 products, scheduled availability, permanent purchase-only unlocks, insufficient-cash rejection, double-purchase rejection, customer-cap pacing, and order-size pacing.
- [ ] **Step 2: Run the test runner.** Expected: catalog/progression assertions fail before implementation.
- [ ] **Step 3: Add the catalog metadata and implement `CampaignState`** without UI dependencies; keep new product names and prices consistent with the game’s Filipino store setting.
- [ ] **Step 4: Run the test runner.** Expected: catalog/progression assertions pass; existing order and customer tests remain green.
- [ ] **Step 5: Commit the tested catalog progression** with only its task files staged: `git add scripts/product_data.gd scripts/campaign_state.gd scripts/campaign_config.gd data/products/instant_noodles.tres data/products/soft_drink.tres data/products/chips.tres data/products/biscuits.tres data/products/bottled_water.tres data/products/candy.tres data/products/coffee_sachet.tres data/products/canned_sardines.tres data/products/laundry_sachet.tres data/products/shampoo_sachet.tres data/products/toothpaste_sachet.tres data/orders/order_pool_day_04.tres data/orders/order_pool_day_07.tres data/story/summer_campaign.tres tests/gameplay_test_runner.gd`; then `git commit -m "feat: add product and campaign progression"`.

### Task 4: Shift Manager and Customer Delivery UI

**Files:**
- Create: `scripts/shift_manager.gd`
- Create: `scripts/product_drag_item.gd`
- Create: `scripts/customer_slot.gd`
- Create: `scenes/product_drag_item.tscn`
- Create: `scenes/customer_slot.tscn`
- Modify: `scripts/main.gd`
- Modify: `scenes/main.tscn`
- Modify: `tests/gameplay_test_runner.gd`

**Interfaces:**
- Produces `ShiftManager.new(campaign_state: CampaignState, products_by_id: Dictionary, rng: RandomNumberGenerator)` and methods `start_shift() -> void`, `advance_time(delta_seconds: float) -> void`, `deliver_product(customer_id: String, product_id: String) -> int`, `get_active_customers() -> Array[CustomerState]`, and `finish_shift() -> void`, plus a `shift_completed` signal emitted once when the 480-second shift ends.
- `ProductDragItem` drag payload is a dictionary with `product_id: String`; `CustomerSlot` sends that ID to `ShiftManager` for validation.
- A wrong product gives feedback and returns visually to its shelf; a correct product appears beside only the targeted customer. The customer collects the displayed units and pays only after the order is complete.
- A customer who times out leaves without payment; their delivered units are removed and unrecoverable, and their individual trust drops.
- Shift clock maps 8:00 AM–8:00 PM to an 8-minute default real-time shift; customer patience continues while the shift clock runs.

- [ ] **Step 1: Add failing shift assertions** for pay-after-completion, no pay for wrong/incomplete orders, unlimited shelf stock remaining unchanged, timeout loss, replacement customer admission under the active-customer cap, and shift completion exactly once at closing.
- [ ] **Step 2: Run the test runner.** Expected: shift assertions fail before manager behavior is implemented.
- [ ] **Step 3: Implement `ShiftManager`** using `OrderState`, `CustomerState`, and `CampaignState`; connect product drags to per-customer drop targets.
- [ ] **Step 4: Replace the static tray/buttons** in `scripts/main.gd` with the live shelf, separate active customer slots, order bubbles, patience/trust indicators, cash HUD, and shift clock while preserving the pixel-art background.
- [ ] **Step 5: Change the background reference** to `res://assets/backgrounds/kwenta_store_background.png` so the project no longer depends on an absolute machine path.
- [ ] **Step 6: Run the headless model tests and launch the main scene in Godot.** Expected: model tests pass; the scene opens without parse/import errors.
- [ ] **Step 7: Manually verify with mouse, then Android touch:** correct drag, wrong drag returns, duplicate item delivery, two simultaneous Day 1 customers, and a customer timing out. Confirm all required controls fit within the central 640×360 area.
- [ ] **Step 8: Commit the tested shift interaction** with only its files staged: `git add scripts/shift_manager.gd scripts/product_drag_item.gd scripts/customer_slot.gd scenes/product_drag_item.tscn scenes/customer_slot.tscn scripts/main.gd scenes/main.tscn tests/gameplay_test_runner.gd assets/backgrounds/kwenta_store_background.png assets/backgrounds/kwenta_store_background.png.import`; then `git commit -m "feat: add customer drag and drop gameplay"`.

### Task 5: Ten-Shift Narrative, Repair Goal, and Endings

**Files:**
- Create: `scripts/story_progression.gd`
- Create: `scenes/day_summary.tscn`
- Modify: `scripts/campaign_config.gd`
- Modify: `data/story/summer_campaign.tres`
- Modify: `scripts/main.gd`
- Modify: `tests/gameplay_test_runner.gd`

**Interfaces:**
- Produces `StoryProgression.get_intro_text() -> String`, `get_day_transition_text(completed_day: int) -> String`, and `get_ending_variant(cash: int, trusted_regular_count: int, repair_goal_amount: int, trusted_regular_goal: int) -> StoryProgression.EndingVariant`.
- Ending rules: `BALANCED_SUCCESS` when cash meets `repair_goal_amount` and trusted regulars meet the configured goal; `MIXED_PROGRESS` when exactly one condition is met; `HOPEFUL_SECOND_CHANCE` when neither is met. All three preserve the supportive self-growth arc.
- `CampaignConfig` stores `repair_goal_amount`, `trusted_regular_goal` (default 3), `trusted_regular_minimum` (default 80 on a 0–100 trust scale), and shift dialogue beats.
- The 10 shifts cover the agreed story: reluctant opening; early learning; returning customers; a mid-summer mistake and reflection; growing initiative; final rush; supportive ending variation.
- The family’s goal is to replace worn shelves before school starts. Ending tone varies by saved current cash and returning customers’ trust, with no harsh game-over ending.

- [ ] **Step 1: Add failing story assertions** for intro, day-transition beat availability, final shift completion, and all three ending categories using fixture thresholds of 3 trusted regulars at trust ≥80 and a configured repair amount.
- [ ] **Step 2: Run the test runner.** Expected: story assertions fail before `StoryProgression` is implemented.
- [ ] **Step 3: Implement story progression data and state** using the approved story beats; leave customer names and dialogue details easy to edit in the Resource.
- [ ] **Step 4: Add a day-summary view** for earnings, repair-goal progress, customer trust changes, and the transition into the next shift.
- [ ] **Step 5: Run all model tests and manually play the campaign through the final shift.** Expected: each day advances once, the end scene reflects saved cash and trust, and no branch blocks the teen’s supportive self-growth arc.
- [ ] **Step 6: Commit the tested summer campaign** with only its task files staged: `git add scripts/story_progression.gd scripts/campaign_config.gd data/story/summer_campaign.tres scenes/day_summary.tscn scripts/main.gd tests/gameplay_test_runner.gd`; then `git commit -m "feat: add summer campaign story"`.

## Execution Note

The current shell does not resolve a `godot` command. The test command above assumes Godot 4.7.2 console executable is available on PATH; if not, run the same arguments using the installed executable’s full path. No Project Settings changes are included.

For Tasks 3–5, commit only the paths listed under that task; do not use `git add .` because the working tree already contains other project changes.
