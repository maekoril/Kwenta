# Core Gameplay Loop Design

## Intent

Turn the existing shelf and customer presentation into a complete, direct-manipulation sales loop for the 640x360 Kwenta storefront. A player drags an unlimited shelf item to an active customer, earns immediately when the order is complete, and races each customer’s patience bar during the 8:00 AM–6:00 PM shift.

## Scope

- Shelf items create one cursor-following drag preview while the shelf display remains visible.
- Releasing over a customer actor delivers the selected product; releases elsewhere and incorrect deliveries bounce the preview to its shelf origin.
- A customer actor’s full rectangle remains the drop target, covering portrait, bubble, and patience bar while staying below the sachet rails.
- The shift permits at most two visible customers, uses a fresh random 5–12 second interval per arrival, and creates customers with 25 seconds of patience.
- Existing `ShiftManager` remains the only owner of money, order progression, trust, and shift time. Its small configuration hooks support the presentation loop without duplicating state in `Main`.
- Existing day, product, campaign, and art data remain unchanged.

## Interaction Decisions

- Mouse and touch both start a drag from the product item’s GUI input. A single preview Control is attached to the viewport while active, scaled to 1.15 and drawn with a compact shadow.
- Main resolves release coordinates against each customer actor’s global rectangle. Successful drops destroy the preview; rejected/outside drops tween it back to the source item center before freeing it.
- Patience colors are discrete: green at 50% and above, yellow from 25% through 49%, and red below 25%.
- Cash and clock remain signal-driven from `ShiftManager`; Main adds a brief cash-label pop only when the balance changes upward.

## Verification

- A live Godot test covers the drag source lifecycle, customer color thresholds, two-customer queue cap, random delay bounds, 25-second patience setup, payout, and 6:00 PM clock.
- Existing storefront regression suites remain green.
