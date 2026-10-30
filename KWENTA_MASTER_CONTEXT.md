# KWENTA — Master Project Context

**Purpose:** Give teammates and coding agents one reliable place to understand the game, agreed decisions, current implementation, and next steps.

**Last updated:** 2026-10-23
**Project:** Kwenta — Sari-Sari Store Simulator  
**Status:** Gameplay prototype in progress; the current storefront build still needs to be run and visually checked in Godot.

---

## 1. What this game is

Kwenta is a 2D, landscape, pixel-art sari-sari store game for Android. It is a hands-on time-management game inspired by the active customer/order flow of Papa's Pizzeria and Cooking Fever, while retaining its own Filipino setting, story, products, characters, and visual identity.

The title *Kwenta* means “value.” The game explores value as more than money: taking responsibility, doing work carefully, showing up for school and family, and earning the trust of neighbors.

The target feel is warm, lived-in, readable pixel art, in the general spirit of narrative pixel games such as *Until Then*. References are for broad direction only; do not copy another game's art, branding, characters, interface, or assets.

## 2. Story premise — agreed

The approved story is the seven-day Tonyo campaign. Tonyo is 12 years old and has been skipping school to play with his friends. When his mother, Aling Cora, must spend one week in the province caring for his sick Lola, she leaves Tonyo responsible for the family sari-sari store and gives him the notebook containing its prices, instructions, and utang.

Each day has a short scene before and after the playable store shift. Six key choices are remembered as flags rather than scored as right or wrong: playing on Day 1, returning Mang Berting's extra ₱50, helping Paolo with the missing ₱3, responding to the rainy-day invitation, handling Aling Nena's utang, and asking the kalaro for fiesta help. A smaller Day 2 haggling choice also receives a Day 6 callback.

The story ends with Tonyo choosing to play after finishing his work, then returning to class to present “Ang Tindahan ni Nanay.” The full campaign can be replayed to explore other choices. `data/story/kwenta_7_day_story.json` is the editable narrative source of truth and supersedes the older ten-shift summer/shelf-replacement story in historical specs and plans.

## 3. Core gameplay — agreed

1. The store opens at **8:00 AM** and closes at **8:00 PM**. The in-game day advances continuously during a short real-time shift.
2. Customers enter the scene from the **left or right**, walk toward the front of the store, and stop to place an order.
3. Each customer is a character in the scene, with their own order bubble, patience, and trust. They are not cards in a dashboard.
4. The player drags products directly from the lower shelf/counter onto the customer who requested them. Correct items advance only that customer's order.
5. A wrong product is rejected, does not advance the order, and returns to the shelf. Duplicate requests require a separate successful drag for each unit.
6. When the order is complete, the customer collects the order, pays automatically, and leaves.
7. If patience expires, that customer leaves, loses trust, and any units already given to them are lost. Trust belongs to each customer and affects how likely they are to return.
8. Day 1 has a maximum of two active customers. Later days raise the cap, up to five, to create busier shifts.
9. Product stock is unlimited. The available product range expands as the summer progresses. Optional store fixture upgrades can be bought between shifts with earnings.
10. The campaign has seven story shifts. Day 7 removes customer patience pressure and ends with notebook callbacks, the epilogue, final stats, and a replay option.

### Order and progression choices

- The requested quantity is randomized, not fixed. Day 1 orders contain 1–3 units; later days can allow larger orders.
- Multiple units of the same product can appear in one order.
- Scheduled products unlock on later days; optional fixture upgrades can grant early product access or improve drink prices.
- Upgrade spending counts toward the shelf replacement goal so improving the store does not reduce overall progress.

## 4. Storefront presentation — latest agreed direction

The revised “Kwenta — Cooking Fever Gameplay Reference (Target Feel)” is the current screen-layout and interaction source of truth. It explicitly replaces the earlier street-side camera. The camera is **inside the store**, looking out through the central window at customers outside. Keep the agreed story, trust, and campaign rules below.

- Central window/street/customer area: approximately x=150–490, y=24–200. Customers fit in this window and face the player.
- The sill/counter spans y=200–222. Player-side product shelves occupy the lower portion, around y=224–352.
- Sachet strips hang at the top-left and top-right frame edges. Row A holds noodles, biscuits, sardines, and the candy jar; row B holds the red cooler/soft drinks and water.
- Every available product has one fixed visible touch slot. Product scales are tuned per item; candy and the Coke cooler are each drawn as a single stocked composition, while drag previews use one product sprite.
- Customer order bubbles use product icons only, quantity marks for multiples, and a visible green→yellow→red patience meter. Names/trust are small secondary tags.
- A light grille is limited to the window edges and never intercepts a drag. No bars cross the clear customer/window area.
- Day 1 shows four starting products. Scheduled and optional products remain absent until unlocked; only empty hook/shelf space shows before then.
- Live gameplay has only the thin HUD and optional small customer tags: no scrolling, text product lists, active-shift prices, lock labels, or modal feedback popups.
- Keep optional fixture purchases between shifts; preserve customer movement, patience/trust, wrong-item rejection, automatic payment, and completion departure.
- Original generic packaging only: no real brand names/logos or readable text. No Mom’s Tips, tutorial overlay, cooking minigame, tips/stars, or equipment upgrade tree.

## 5. Product and customer content

### Starting products (4)

- Instant Noodles — ₱15
- Biscuits — ₱8
- Bottled Water — ₱12
- Candy — ₱5
- Instant Noodles — ₱15

### Scheduled products

- Day 2: Chips, Coffee Sachet
- Day 3: Soft Drink
- Day 4: Canned Sardines, Tang Orange Sachet
- Day 5: Bread, Eggs
- Day 6: Soy Sauce, Vinegar, Fish Sauce
- Day 7: Laundry Sachet, Nestea Lemon Sachet
- Day 8: Cooking Oil
- Day 9: Jasmine Rice

### Optional fixture upgrades

- After Day 2: Sachet Hanging Rail — ₱100; unlocks Shampoo and Toothpaste Sachets
- After Day 3: Drink Cooler — ₱180; adds ₱5 to Soft Drink and ₱3 to Water sale prices
- After Day 3: Extra Shelf — ₱250; early access to Bread and Eggs
- After Day 4: Condiment Rack — ₱300; early access to Soy Sauce, Vinegar, and Fish Sauce
- After Day 7: Bulk Goods Crates — ₱400; early access to Cooking Oil and Jasmine Rice

Product names, prices, unlocks, order pools, customer caps, and story text should stay data-driven in `data/` Resources/configuration rather than being duplicated in UI logic.

### Customers

The playable customer roster uses the approved cast: Aling Nena, Mang Berting, Bea, Paolo, Kuya Dodong, and Jun-jun. Mikay, Bogs, Tonyo, and Aling Cora appear in dialogue scenes. Existing portrait art is reused for simple static poses. Trust remains tracked per playable customer.

## 6. Current campaign configuration snapshot

Values currently in `data/story/summer_campaign.tres` and `scripts/campaign_config.gd`:

- Initial cash: **₱150**
- Full-day shift length: **480 seconds** (8 real-time minutes mapped to 8:00 AM–8:00 PM)
- Closing times by day: **12 PM, 5 PM, 6 PM, 6 PM, 8 PM, 8 PM, 8 PM** (Days 1–7)
- Customer spawn intervals by day: **18, 16, 14, 12, 9, 6, 12 seconds**
- Customer patience by day: **tutorial/no pressure, 50, 40, 32, 28, 25, finale/no loss seconds**
- Trust loss on timeout: **25 points**
- Shelf replacement goal: **₱1,500**
- Trusted regular goal: **3 customers** at **80% trust or more**
- Campaign length: **7 days**
- Active customer caps by day: **1, 2, 2, 3, 4, 5, 4**
- Maximum order units by day: **2, 3, 3, 4, 4, 5, 5**

These are tunable prototype values, not immutable design laws.

## 7. Current implementation snapshot

The project currently contains the model and prototype for:

- `OrderState` and `OrderFactory`: randomized order creation, duplicate quantities, correct/wrong item validation, completion, and totals.
- `CustomerState`: individual order, patience, timeout, and trust behavior.
- `CampaignState` / `CampaignConfig`: seven-day pacing, product unlocks, optional purchases, and customer trust.
- `StoryProgression`: data-driven dialogue beats, validated choice flags, conditional callbacks, and replay reset support.
- `ShiftManager`: customer arrivals, timer, direct delivery validation, payment on completion, timeout handling, and shift close.
- `scripts/main.gd`: HUD, seven-day dialogue/choice flow, simple portrait poses, campaign replay, fixed product sprites, customer arrival/departure, and between-shift cash unlocks.
- `scripts/storefront_layout.gd`: inside-window customer positions, player-side product slots, and icon-only order entry data.
- `scripts/product_drag_item.gd`: fixed-slot product sprite, scaled preview, and rejection shake.
- `scripts/customer_slot.gd`: compact window customer, icon-only bubble, patience meter, and drop feedback.
- Product and customer art atlases in `assets/sprites/`.
- The runtime storefront uses the layered art in `assets/store/kwenta_layer_pack/`; `bg_empty.png` and `bg_front.png` frame the customer layer.
- `assets/sprites/kwenta_generic_products.png` is the current transparent generic product atlas; its in-game crop and display sizes need editor review.

The current source uses the seller-side composition: product sprites sit on the player's lower shelves/edge strips, while customers and icon order bubbles fit inside the center window. The seven-day story overlay reuses the same palette, panels, and portrait atlas; it does not replace the established storefront or product art direction.

### Verification status

- All six automated Godot test suites passed on 2026-10-23 after the seven-day story integration.
- The dialogue overlay and static portrait layout were rendered at 1920×1080 in Godot 4.7.2 and visually checked for clipping and alignment.
- On first open after adding the new images, let Godot import them before running the scene.

## 8. Project setup and technical constraints

Read `README.md` for the full setup walkthrough. Key project constraints:

- Godot **4.7.2 stable**, standard (not .NET); use GDScript.
- Android-first target; landscape 2D.
- Base viewport: **640 × 360**; stretch mode `viewport`, aspect `expand`; keep essential controls within the central design area.
- Android package name in the setup README: `com.uri.kwenta`.
- JDK 17 and the Android SDK versions in `README.md` are the team's documented export setup.
- Do not upgrade Godot or change shared display/render/input settings without coordinating with the team.
- Products/orders/campaign content are data-driven Resources.

## 9. Git and team workflow

- Never commit directly to `main`; use a feature branch and PR.
- Pull before beginning new team work.
- Coordinate scene ownership before editing another teammate's `.tscn` file.
- Never commit export presets, APK/AAB builds, or signing keys.
- Avoid broad staging (`git add .`) while the working tree contains other unfinished work; review `git status` and stage only intended files.
- The last recorded local working branch for this prototype was `codex/product-selection` (snapshot from 2026-10-20). This is a branch inside the local repository; it does not itself create or update a GitHub branch/PR.
- A prior screenshot showed team branches named `feature/art-characters-products`, `feature/art-store`, `feature/audio`, `feature/customer-spawner`, `feature/main-menu`, `feature/money-rewards`, `feature/order-system`, `feature/patience-timer`, `feature/payment-change`, `feature/product-data`, `feature/product-selection`, `feature/shift-system`, `feature/store-scene`, `feature/ui-hud`, and `develop`. Their current remote status/contents have not been verified here.

## 10. Important working files

- Main scene: `scenes/main.tscn`
- Gameplay/UI orchestration: `scripts/main.gd`
- Product drag control: `scripts/product_drag_item.gd`, `scenes/product_drag_item.tscn`
- Customer drop-target scene/script: `scenes/customer_slot.tscn`, `scripts/customer_slot.gd` (the script/node is now being used as a moving customer actor, despite the legacy “slot” filename)
- Shift/customer/order logic: `scripts/shift_manager.gd`, `scripts/customer_state.gd`, `scripts/order_state.gd`, `scripts/order_factory.gd`
- Campaign/story logic and data: `scripts/campaign_state.gd`, `scripts/campaign_config.gd`, `scripts/story_progression.gd`, `data/story/summer_campaign.tres`, `data/story/kwenta_7_day_story.json`
- Product/order data: `data/products/`, `data/orders/`
- Gameplay checks: `tests/gameplay_test_runner.gd`
- Approved design: `docs/superpowers/specs/2026-10-19-kwenta-gameplay-design.md`
- Implementation notes: `docs/superpowers/plans/2026-10-19-kwenta-gameplay.md`
- Current storefront reference: `docs/Kwenta - Cooking Fever Gameplay Reference (Target Feel).md`
- Storefront rebuild plan: `docs/superpowers/plans/2026-10-20-kwenta-inside-store-rebuild.md`

## 11. Next actions

1. Open the project in Godot 4.7.2 and verify new image imports and GDScript parsing.
2. Check that products occupy only the lower shelf/edge-strip zones and remain small enough for the new reference.
3. Test 2–5 customers and icon bubbles in the center window, including patience and direct correct/wrong drops.
4. Check scheduled/optional unlocks, empty-space return, coin feedback, and end-of-day story flow.
5. Update implementation/verification status only after those runtime checks; inspect Git status before any later staging.

## 12. Keep these distinctions clear

- **Design decision:** what the team has agreed the game should do.
- **Implementation status:** what is currently present in the project, which may still be a prototype.
- **Reference image/document text:** inspiration or context, not automatic instructions to copy or implement every visual detail.

If a new proposal changes an agreed gameplay rule, flag it as a proposal and get team agreement before treating it as the new source of truth.
