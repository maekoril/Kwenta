# KWENTA — Master Project Context

**Purpose:** Handoff reference for teammates and coding agents. Read this before changing gameplay, story, UI, or Android delivery.

**Last updated:** 2026-10-30
**Current branch:** `feature/product-selection`
**Current remote-aligned commit when updated:** `26e9023 Resolve merge conflicts and integrate game features`
**Working-tree note:** `tmp/` is intentionally untracked. Never commit it.
**Status:** The merged Android-first Godot prototype has working story, shop, tutorials, sukli, notebook panels, and seven-day pacing.

---

## 1. Game overview

**Kwenta** is a landscape, pixel-art Android sari-sari store management game. The player controls Tonyo as he runs his family store over a seven-day story campaign. Core play combines touch drag-and-drop serving, multiple-item orders, sukli/change-making, shelf purchases, customer patience and trust, and choice-based narrative events.

Primary player loop:

1. Read story dialogue and the pre-shift notebook briefing.
2. Review the day focus, stock, closing time, and optional daily goal.
3. Optionally shop for shelf/product groups.
4. Serve products to customers and make correct sukli.
5. Manage pressure, trust, story interruptions, and simultaneous customers.
6. Finish outro/callback dialogue, read the day summary notebook, then advance.

The game is mobile-first: use taps, drag-and-drop, and finger-drag scrolling. Do not add desktop-only interaction requirements.

---

## 2. Technology and Android delivery

- **Engine:** Godot 4.7.2 Stable, standard build—not .NET.
- **Language:** GDScript. No custom Kotlin or Java source modules exist in the repository.
- **Android package:** `com.uri.kwenta`.
- **Toolchain:** JDK 17; Android API/platform 35; Build Tools 35.0.1; NDK 28.1.13356709; CMake 3.10.2.4988404.
- **Renderer:** Godot GL Compatibility; ETC2/ASTC texture compression enabled.
- **Display:** 1920×1080 internal viewport; 1280×720 window override; landscape; `viewport` stretch mode; `expand` aspect.
- **Jetpack/native integrations:** None directly. Godot generates the Android wrapper.
- **Hardware:** Touch input only—tap, drag/drop, and touch scrolling. No CameraX, GPS, BLE, camera, gyroscope, accelerometer, microphone capture, or biometric APIs.

`export_presets.cfg` is not versioned. Developers create Android export presets locally, so do not claim a committed minSdk setting.

---

## 3. Story source of truth

The editable story source is `data/story/kwenta_7_day_story.json`. Campaign configuration lives in `data/story/summer_campaign.tres`, `scripts/campaign_config.gd`, and `scripts/story_progression.gd`.

The current campaign is Tonyo’s seven-day story. JSON supports intro/outro beats, pre-shift `intro_choices`, after-shift choices, conditional callbacks, cash consequences, patience modifiers, and in-shift events. Do not restore older story text from historical specifications.

### Story systems that must remain connected

- `StoryProgression` loads story JSON, tracks choices, filters conditional beats, provides cash deltas and modifiers.
- `ShiftStoryEvents` runs scripted customers, interruptions, haggles, hover remarks, helper mix-ups, and popup input blocking.
- Story popups freeze the shift while active and block underlying customer/product/cash/store input.
- Pre-shift choices resolve before the notebook briefing/store flow.
- Post-shift outro and callback dialogue must complete before the summary notebook appears.
- Day 7 is the finale/replay endpoint; customers have effectively unlimited patience.

Key files: `scripts/main.gd`, `scripts/story_progression.gd`, `scripts/shift_story_events.gd`, `scripts/Dialogue_bubble.gd`, `scripts/pause_menu.gd`.

---

## 4. Seven-day progression (current)

| Day | Shift end | Real duration | Customer cap | Main focus |
|---|---:|---:|---:|---|
| 1 | 12:00 PM | 160 sec | 1 | Drag serving and multiple-item orders; tutorial |
| 2 | 5:00 PM | 360 sec | 2 | Shop and sukli; tutorial |
| 3 | 6:00 PM | 400 sec | 2 | Multi-item practice; sukli stays visible |
| 4 | 6:00 PM | 400 sec | 3 | Rain and faster decisions |
| 5 | 8:00 PM | 480 sec | 4 | Trust and regulars |
| 6 | 8:00 PM | 480 sec | 5 | Fiesta rush, story events, brownout |
| 7 | 8:00 PM | 480 sec | 4 | Finale; no practical patience loss |

Current values from `summer_campaign.tres`:

- Initial cash: ₱150.
- Close minutes: `[240, 540, 600, 600, 720, 720, 720]` from an 8:00 AM start.
- Spawn intervals: `[18, 16, 14, 12, 9, 6, 12]` seconds.
- Patience: `[999, 50, 40, 32, 28, 25, 999999]` seconds.
- Maximum order units: `[2, 3, 3, 4, 4, 5, 5]`.
- Trust loss after timeout: 25.
- Trusted regular threshold: 80 trust.

**Critical:** `ShiftManager.start_shift()` must call `CampaignState.get_shift_length_seconds()` and `CampaignState.get_shift_close_minutes()`. Do not revert to the old fixed 480-second/600-minute shift calculation.

---

## 5. Core systems and non-negotiable behavior

### Serving

- Customers have unique IDs, order bubbles, patience, and trust.
- Products are dragged onto the intended customer.
- Wrong products are rejected. Duplicate product quantities require separate deliveries.
- Product stock is unlimited; `CampaignState.stocked_product_ids` defines the available gameplay catalog.
- State belongs in `OrderState`, `OrderFactory`, `CustomerState`, `CampaignState`, and `ShiftManager`, not duplicated in UI code.

### Sukli

- Sukli starts on **Day 2** (`SukliRules.FIRST_CHANGE_DAY = 2`).
- Day 1 has no change-making requirement.
- Cash tray progress/selected total remains visible after Day 2; only helper wording fades.
- Day 2’s spotlight guides denominations → exact total → `IBIGAY`; too much points to `LINISIN`.
- Keep these cash-tray node names exactly, as the tutorial finds them dynamically:
  - `Denomination%d`
  - `GiveChangeButton`
  - `ClearChangeButton`
- `cash_tray.gd` emits `denomination_selected` and `change_amount_changed`; `main.gd` consumes them for the tutorial.

Key files: `scripts/cash_tray.gd`, `scripts/sukli_rules.gd`, `scripts/payment_state.gd`, `scripts/main.gd`.

### Daily goals

Goals are optional and have no failure penalty. They display in the HUD, pre-shift notebook, and end-of-day notebook.

- `scripts/daily_goal.gd` — goal definitions/progress/rewards.
- `scripts/main.gd` — lifecycle, HUD refresh, event tracking, finalization.

### Shop and stock

- Supplier shop data: `data/store_config.json`.
- Buyable fixtures: `hanging_strip`, `water_shelf`, `condiments`, `oil_shelf`, `rice_shelf`.
- Purchase must deduct cash, record `purchased_store_groups`, refresh storefront art, rebuild draggable stock, update the shop cash label, and change the button to `PURCHASED`.
- Store art is owned by `StoreLayerRenderer`; transparent interactive drag targets are rebuilt in `main.gd`.
- The shop icon must remain above the dialogue bubble in draw **and input** order. `_refresh_shop_button()` moves it to the root’s final child position while visible.
- After a shift starts, the shop remains available for **60 real seconds** through `SHOP_GRACE_DURATION_SECONDS`; then the rush locks it.

Key files: `scripts/shelf_shop_modal.gd`, `scripts/store_layer_renderer.gd`, `scripts/store_config.gd`, `scripts/campaign_state.gd`, `scripts/main.gd`.

---

## 6. Tutorials and notebook panels

### Interactive tutorials

`InteractiveTutorialOverlay` is the required tutorial approach: dimmed backdrop, spotlight cutout, and target-specific guidance.

- Day 1: highlight product, then customer.
- Day 2: highlight shop, denominations, clear, and give controls.
- `TutorialStep` is defined in `main.gd`.
- Do not replace this with plain static text.

Files: `scripts/interactive_tutorial_overlay.gd`, `scripts/main.gd`.

### Notebook panels

- **Pre-shift:** `main.gd._show_pre_shift_briefing()` uses `DayBriefing`; shows focus, starting shelf/unlocks, shift details, and optional goal. Day 1 title is **YOUR FIRST SHIFT**, not “WHAT CHANGED.”
- **Post-shift:** `_show_shift_summary()` captures results; `_show_pending_shift_summary()` displays them only after the last story/callback line.
- Long notebook content must support finger-drag scrolling.
- Section tags use `wooden_tag.png`; action buttons use `ibigay_button.png` as background.

Files:

- `scripts/main.gd`
- `scripts/day_briefing.gd`
- `scripts/notebook_summary.gd`
- `scripts/notebook_scroll.gd`
- `scripts/daily_goal.gd`

---

## 7. UI/layering rules

- `StoreLayerRenderer` draws storefront layers.
- Customer/product interaction layers sit above the relevant art.
- HUD is about z-index 30.
- Cash tray is above HUD but below story/notebook panels.
- Dialogue bubble is intentionally moved to the top for story interactions.
- Visible shop icon must be moved after the bubble, or the bubble will consume its taps.
- Shop modal moves itself to the top when opened and uses z-index 60.
- Story popup input blocking includes customer layer, product layer, cash tray, and store renderer; do not block the active popup itself.

---

## 8. Important file map

### Main and models

- `scenes/main.tscn`
- `scripts/main.gd`
- `scripts/campaign_config.gd`
- `scripts/campaign_state.gd`
- `scripts/shift_manager.gd`
- `scripts/customer_state.gd`
- `scripts/order_state.gd`
- `scripts/order_factory.gd`
- `scripts/payment_state.gd`
- `scripts/sukli_rules.gd`

### Story

- `data/story/kwenta_7_day_story.json`
- `data/story/summer_campaign.tres`
- `scripts/story_progression.gd`
- `scripts/shift_story_events.gd`
- `scripts/Dialogue_bubble.gd`
- `scripts/pause_menu.gd`

### Store and UI

- `data/store_config.json`
- `scripts/store_config.gd`
- `scripts/store_layer_renderer.gd`
- `scripts/shelf_shop_modal.gd`
- `scripts/product_drag_item.gd`
- `scenes/product_drag_item.tscn`
- `scripts/customer_slot.gd`
- `scenes/customer_slot.tscn`
- `scripts/interactive_tutorial_overlay.gd`
- `scripts/cash_tray.gd`
- `scripts/day_briefing.gd`
- `scripts/notebook_summary.gd`
- `scripts/notebook_scroll.gd`
- `scripts/daily_goal.gd`

### Assets

- `assets/store/kwenta_layer_pack/` — storefront art and slot layout.
- `assets/sprites/ui/sukli/sized/` — cash art, tags, notebook buttons, progress art.
- `assets/sprites/ui/shop/` — shop panel/icon art.
- `assets/sprites/customer_portraits_v2.png` — portraits.

---

## 9. Tests and verification

Test runners are in `tests/`:

- `gameplay_test_runner.gd`
- `core_gameplay_loop_test_runner.gd`
- `shelf_shop_modal_test_runner.gd`
- `store_layer_renderer_test_runner.gd`
- `store_layer_config_test_runner.gd`
- `dialogue_audio_test_runner.gd`
- `kwenta_audio_test_runner.gd`

Use Godot 4.7.2 headless when possible:

```powershell
& 'F:\USTI DOWNLOAD\Personal\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe' --headless --path . --script res://tests/gameplay_test_runner.gd
```

This Windows setup can emit a sandboxed `user://logs/godot.log` write warning in headless mode. Do not mistake it for a parser/gameplay failure. Confirm critical paths in Godot editor/device when practical.

Regression checklist after relevant edits:

1. Parse/load `main.gd`.
2. Verify Day 1 drag tutorial.
3. Verify Day 2 shop and sukli spotlights, including `IBIGAY`/`LINISIN` targets.
4. Verify Day 1 noon, Day 2 5 PM, Days 3–4 6 PM, Days 5–7 8 PM.
5. Verify purchases update shop state, storefront art, and draggables.
6. Verify shop icon works above dialogue and survives the 60-second grace window.
7. Verify summary appears after final outro/callback dialogue.
8. Verify notebook finger-drag scrolling.

---

## 10. Git and collaboration rules

- Do not commit directly to `main`.
- The integration branch is `feature/product-selection`.
- It contains both teammate story/assets/story-event work and product-data shop/tutorial/notebook/progression work.
- Be extremely careful merging `scripts/main.gd`, `scripts/shift_manager.gd`, and `scripts/cash_tray.gd`; they contain cross-branch dependencies and were previously damaged by conflict resolution.
- After merges, search for `<<<<<<<`, `=======`, and `>>>>>>>` markers.
- Never commit `tmp/`, local export presets, APK/AAB builds, signing keys, or machine-specific editor files unless explicitly directed by the team.
- Do not use `git add .`; stage intended files only.
- Preserve unrelated worktree changes; never reset or delete them casually.

## 11. Handoff cautions

1. Do not revert per-day timing to a fixed full-day shift.
2. Do not remove the cash tray’s tutorial lookup names.
3. Do not place shop behind dialogue.
4. Do not show summary before all outro/callback dialogue.
5. Do not hide sukli progress after Day 2.
6. Do not hard-code story content in UI; use JSON and `StoryProgression`.
7. Do not claim Android sensors not present in the codebase.

## 12. Recommended first actions for the next AI

1. Read this file, `README.md`, and `git status -sb`.
2. Read `scripts/main.gd` before changing UI flow; it is the integration hub.
3. Trace bugs from `main.gd` into model/data sources before editing.
4. Add focused regression coverage before production behavior changes.
5. Use `apply_patch`, validate with Godot, and stage only intended files.
