# Kwenta — Cooking Fever Gameplay Reference (Revised)

**Status:** Current storefront presentation and interaction specification  
**Revised:** 2026-10-20 from the latest pasted reference  
**Authority:** This document supersedes the earlier exterior-facing storefront mockup. The current master context still governs story, campaign, trust, and product data unless this document explicitly changes presentation.

## Purpose

Capture the fast, readable customer/order rhythm of Cooking Fever in Kwenta’s own sari-sari store setting. Borrow only the broad interaction pattern: customers wait with icon orders, products stay visible in fixed locations, and the player serves customers by dragging items directly to them. Do not copy Cooking Fever’s art, interface skin, characters, names, or branding.

## Camera and composition

The camera is **inside the store**, behind the counter, looking out through a central window. Customers stand outside the window facing the player. The player’s shelves, hanging strips, jars, and cooler remain in the foreground.

Base viewport: **640 × 360**, landscape.

```text
┌──────────────────────────────────────────────────────────────┐
│ SUMMER · DAY 1           8:02 AM                  ₱150       │ HUD y 0–20
├─ side stock ─ hanging strips ─ WINDOW / STREET ─ strips ─ side┤ y 24–200
│                         customers + icon bubbles              │
├══════════════════════ sill / counter ═════════════════════════┤ y 200–222
│ shelf row A: noodles · biscuits · sardines · candy jar         │ y 224–285
│ shelf row B: red cooler / soft drinks · bottled water          │ y 288–352
└──────────────────────────────────────────────────────────────┘
```

- Window opening: approximately x=150–490, y=24–200. It shows the street outside.
- Hanging strips: top-left x=20–140 and top-right x=500–620, y=24–84. Keep strips clear of customer bubbles.
- Side walls below the strips are decorative, dim shelves only.
- The sill/counter separates customers from the player’s lower foreground shelves.
- Customers and their bubbles remain inside the window area. Product items remain below the sill or on the designated hanging strips.
- Background: crowded, warm, hand-built sari-sari setting: wood/bamboo shelves, painted concrete, thin grille only at window edges, red cooler, blue-lidded candy jar, a basket and small non-readable clutter. No people or UI baked into the background.
- No grille bars cross the middle of the window; any decorative frame is non-interactive.

## Fixed product locations

Every available item has one visible, touchable slot. Slot size determines the drawn sprite size; never draw an atlas texture at native size. Use generic original packaging with no real logos, product brands, or readable text. Back shelves and side walls may contain dim non-interactive filler stock.

| Product | Fixed spot | Visual cue |
|---|---|---|
| Chips | Top-left hanging strip | Orange/red foil packs |
| Coffee sachet | Top-left hanging strip | Small brown/gold packs |
| Shampoo sachet (optional unlock) | Top-left hanging strip | Pink/blue packs |
| Toothpaste sachet (optional unlock) | Top-right hanging strip | White/blue/red packs |
| Laundry sachet (Day 7) | Top-right hanging strip | Blue packs |
| Instant noodles | Shelf row A | Stacked packs/cups |
| Biscuits | Shelf row A | Yellow/red flat packs |
| Canned sardines (Day 4) | Shelf row A | Red/green cans |
| Candy | Shelf row A | Blue-lidded jar |
| Soft drink | Red cooler at left of row B | Bottles in rows |
| Bottled water | Row B beside cooler | Blue/clear bottles |

Day 1 shows the seven starting products; later or optional products are absent until unlocked, with their shelf/hook space left empty. Stock is unlimited: dragging lifts one copy and never empties the slot. At 640×360, shelf sprites are approximately 32–40 px tall, sachet units approximately 14×22 px, and bubble icons 20–24 px. A product must never render larger than a customer’s head. Drag preview is about 1.2× slot size.

## Customers and order bubbles

- Day 1 has two customers; progression raises the active cap to five.
- Customers enter from the left or right, stop across the window, and face the player.
- Each has an order bubble above/near their head with item icons only and `×N` for quantities. No product names.
- A bubble has a visible patience bar, green at full patience shifting through yellow to red as it drains.
- A delivered unit ticks, fades, or clears individually; duplicate units each require their own drag.
- Customer name/trust may appear in a small secondary tag but must not compete with the order.
- On timeout, the customer leaves sadly/angrily, their trust drops, and already-delivered goods are lost, as defined by campaign logic.

## Drag-and-drop behavior

1. Touch/drag a visible product; show a slightly enlarged copy with soft shadow while its fixed shelf sprite remains.
2. The whole customer body and order-bubble area accept drops and show a subtle hover highlight.
3. Correct product: tick/clear one requested unit with a small pop/sparkle; immediately allow the next drag.
4. Wrong product or already-complete unit: shake/bounce the product back and leave order state unchanged.
5. Dropping on empty space returns the item to its original slot without changing state.
6. When all requested units are served, pay automatically, show a coin pop and happy reaction, then have the customer leave so another can step in.
7. Other customers’ patience continues draining while serving one customer. There are no confirmation steps, blocking popups, or delays between drags.

## On-screen text and exclusions

The live gameplay screen contains only the thin HUD (day, time, cash, optional progress) and, at most, small customer name/trust tags. No scrolling, text product menu/list, active-play prices, lock labels, translucent customer cards, tutorial overlay, Mom’s Tips, stars/tips system, cooking/preparation minigame, or Cooking Fever equipment tree.

## Acceptance checklist

- [ ] Inside-store camera: central street window above the sill; player shelves and cooler occupy the lower foreground.
- [ ] Product sprites are visible in fixed locations at slot size; available items can be dragged without stock disappearing.
- [ ] Seven Day 1 products appear; scheduled and optional products appear only after unlocking.
- [ ] Customers arrive from either side, face the player, and fit in the window at counts 2–5.
- [ ] Icon-only order bubbles display quantities and a clear patience bar.
- [ ] Correct, wrong, empty-space, duplicate, and completed-order drops have the specified behavior.
- [ ] The grille does not cross the central window or block a drag.
- [ ] No real packaging brands/logos/readable text appear in game product art.
- [ ] The live screen has no product list, scrollbars, product prices, or oversized sprites.

## Implementation guidance

Keep the existing order, customer, shift, campaign, trust, and product data logic. Rebuild presentation around the 640×360 zones above. Treat the current source asset and previous screen as a prototype, not a layout constraint. Verify the new image import and all touch targets in Godot 4.7.2 before calling the scene runtime-tested.
