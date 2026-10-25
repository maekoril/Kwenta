# Product Progression Implementation Plan

> **For agentic workers:** Native implementation in this task; use this plan task-by-task.

**Goal:** Stage the store catalog across ten days, add five optional fixture upgrades, and count upgrade investment toward the shelf goal.

**Architecture:** Keep product timing in `ProductData`, model optional fixture purchases as `StoreUpgradeData`, and let `CampaignState` own purchase, price, and goal-progress accounting. The between-shift panel offers the upgrades; the shelf keeps using its existing product rendering path.

**Tech Stack:** Godot 4 GDScript and Resource data.

**Spec:** Approved progression in the conversation dated 2026-10-21.

## Global Constraints

- Use the existing data-driven campaign and product Resource patterns.
- Keep the ten-day summer campaign and the current shelf replacement goal.
- Increase store product display scale from 1.4× to 1.6×.

## Review Focus

- Purchased upgrades stay unlocked and cannot be charged twice.
- Upgrades become available after their configured offer day.
- Buying upgrades does not reduce total shelf-goal progress.
- Products appear on their scheduled day even when an upgrade is skipped.

---

### Task 1: Product and upgrade progression

**Files:**
- Create: `scripts/store_upgrade_data.gd`
- Create: `data/upgrades/*.tres`
- Create: `data/products/*.tres` for the scheduled products not already cataloged
- Modify: `data/story/summer_campaign.tres`, `scripts/campaign_config.gd`, `scripts/campaign_state.gd`, `scripts/shift_manager.gd`, `scripts/main.gd`, `scripts/counter_art.gd`, `scripts/storefront_layout.gd`, and `scripts/product_drag_item.gd`

- [x] Set automatic unlock days to the approved schedule.
- [x] Add optional fixture purchases and early unlock/price bonus behavior.
- [x] Count upgrade spending toward shelf goal progress.
- [x] Increase product display scale to 1.6×.
- [ ] Perform a Godot project parse check and inspect the changed files.
