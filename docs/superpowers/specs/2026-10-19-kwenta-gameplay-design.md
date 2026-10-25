# Kwenta — Gameplay and Narrative Design (Draft)

**Status:** Approved for implementation; the revised 2026-10-20 seller-side gameplay reference is the layout authority.

## Intent

Kwenta is a pixel-art sari-sari store simulator with hands-on, time-managed order fulfillment. Its title theme is value: the protagonist begins by thinking mostly about avoiding responsibility, then learns that value includes money, work, family, education, and the relationships a neighborhood store builds.

The game should feel like an active shop game in the spirit of Papa's Pizzeria or Cooking Fever, not a static menu or click-to-add order form. The player physically drags products from the shelves to customers while managing several customers' orders and patience.

## Story

The protagonist is a high-school student who has been skipping school and earning poor grades because they have not taken their responsibilities seriously. During summer break, their parents put them in charge of the family sari-sari store so they can learn what daily work and accountability involve. The teen initially treats the shifts as punishment and expects the work to be easy.

**Story goal:** the family store needs its worn shelves replaced before the next school year. The teen is asked to help save toward that improvement over the summer. Returning customers gradually show that the store's worth is not measured by earnings alone: people rely on it, and the teen's actions affect whether they trust it. The teen does not become perfect or decide school is unimportant; they begin to understand that school, work, money, and relationships all require effort and follow-through.

### Suggested story beats

1. **Opening:** the parents discuss the teen's skipping and grades, then assign the summer store shifts. The teen assumes this will be an easy punishment.
2. **Early shifts:** the player learns product selection and customer patience. The teen is impatient and focused on closing time.
3. **Middle shifts:** regulars return and their individual trust becomes visible. A rushed mistake leads to a customer leaving; the loss prompts a conversation with the parents, who ask the teen to take responsibility rather than fixing it for them.
4. **Later shifts:** the teen begins preparing for busy periods and caring about both the store goal and returning customers. More products and simultaneous customers make the work harder.
5. **Final shift:** the last major rush happens before the school year. The family's conversation and the ending reflect the teen's follow-through, store progress, and relationships with customers.

The parents can appear in story scenes, but there is no “Mom's Tips” gameplay panel or tip/tutorial feature in this scope.

## Core shift loop

1. The store opens at 8:00 AM. A shift lasts about 5–10 real-time minutes; the in-game clock advances continuously and the day ends at closing time, 8:00 PM.
2. Customers arrive with orders. At the start of the campaign, no more than two customers are active at once; later difficulty can raise this to three through five.
3. Each customer has an individual order, patience timer, and trust value. Day 1 order size is randomized from one to three units. Later days can allow larger orders. Repeated units of the same product are allowed.
4. The player drags a product from the shelf directly to the customer who requested it, using either mouse or touch. A correct unit is accepted and displayed beside that customer. A wrong product returns to its shelf without counting toward the order.
5. When all requested units are delivered, the customer automatically collects them, pays, and leaves.
6. If patience reaches zero before completion, the customer leaves, trust with that customer decreases, and any units already delivered to them are lost. Lower trust makes that customer less likely to return.
7. Shift earnings and progression carry into the next day.

## Active counter presentation

The revised “Kwenta — Cooking Fever Gameplay Reference (Target Feel)” is the screen and interaction authority. It supersedes the previous street-side storefront mockup. Story, trust, campaign, and data rules in this document remain active. The detailed in-repo reference is `docs/Kwenta - Cooking Fever Gameplay Reference (Target Feel).md`.

### Single-screen composition

- Seller-side view from inside the sari-sari store looking out through the central window, at a fixed 640×360 landscape design resolution.
- A compact top strip shows day, time, cash, and optionally shelf-goal progress.
- The central window/customer area is approximately x=150–490, y=24–200, looking onto the street. Only thin grille bars at the window edges; no bars cross the center.
- Hanging strips occupy the top-left and top-right edges. Decorative side shelves fill around the window. The sill/counter spans roughly y=200–222.
- Player-side shelf row A occupies y≈224–285 and row B y≈288–352; a red cooler at lower-left and candy jar are visible in their fixed spots.
- Customers stand outside the window, face the player, enter from either side, and stop inside the central window area. The customer body and bubble form the drop target.
- Any grille/frame art is part of the non-interactive background and must never block dragging.
- No scrolling, text lists, or active-shift menus. Every currently sellable product is visible as a sprite in one fixed, touch-sized slot.

### Product display and unlocks

- Product sprites are original, generic, unbranded packaging. Do not reproduce real packaging, logos, Cooking Fever assets, or reference-game UI.
- Put chips, coffee, shampoo, toothpaste, and laundry sachets on designated top-edge hanging strips; noodles, biscuits, sardines, and candy on shelf/jar row A; soft drinks in the red cooler and water beside it on row B.
- Exactly one fixed slot belongs to each product. Stock is unlimited: dragging lifts a copy and never empties the slot.
- Shelf sprites are about 32–40 px tall; sachet art about 14×22 px. Touch slots remain at least 28 px wide for hanging strips and at least 32×32 px for shelf items. Dim back-shelf filler is decorative and not draggable. Hit areas must not overlap.
- Day 1 begins with seven products; later scheduled unlocks fill their empty shelf/hanging slots. Locked scheduled products are absent, leaving a visibly empty spot.
- Optional permanent cash unlocks remain part of the campaign. To avoid active-shift text/menus, purchases are offered between shifts; after purchase, the product appears in its assigned slot.

### Customer order bubbles

- Show product icons only, with a small ×N when a customer requests multiple units. Do not write product names in the bubble.
- On each correct delivery, clear/check one requested unit. Wrong products do not change the bubble.
- Attach a visible patience bar to or immediately under the bubble; color it green → yellow → red as time runs down.
- Customer name/trust may appear as a small, secondary tag. The order and patience remain the priority.

### Drag response and moment-to-moment feel

- Drag from a product's fixed player-side slot directly to the requested customer's character or bubble, without confirmation or waiting steps.
- Pickup lifts a visual copy with a subtle shadow; the permanent slot stays stocked.
- Correct drop updates the bubble immediately. Wrong drop gives a quick shake/bounce and returns to the source slot. Drop on empty space returns without changing the order.
- Completed orders pay automatically, show a small happy/coin response, then the customer walks away. Other customers' patience continues draining.
- Customers who time out leave; delivered items are lost and that customer's trust decreases.
- Keep feedback brief and action-driven; avoid text popups during the active shift.

The goal is Cooking Fever's clear two-point eye movement and satisfying order rhythm translated into a Filipino sari-sari window—not copied art, branding, characters, UI skin, or cooking stations. Products are ready to hand over.

## Products and progression

- Product stock is unlimited; there is no restocking or stockout mechanic.
- The store starts with seven products available on Day 1.
- Additional products unlock automatically on configured campaign days, and a separate set of products can be permanently unlocked by spending earnings. Scheduled and purchase-unlocked products are distinct paths.
- Product prices and sale revenue are visible to the player. No dynamic pricing system is specified in this draft.
- The end-of-summer store improvement is replacing the worn shelves before school starts. It is measured against current saved cash, so product purchases delay that goal.

## Difficulty and campaign shape

Difficulty rises through the campaign by increasing product variety, possible order size, customer arrival pressure, and the maximum number of active customers. Keep early shifts readable; later shifts should create the multitasking challenge expected from the genre. Trust is per customer, so a player can lose one regular without losing all returning customers.

The campaign has 10 story shifts across summer, with early, middle, and late story beats distributed across them.

## Ending direction

There should be a narrative ending after the summer campaign, not an endless-only mode. Use performance to vary the final scene rather than making one mistake permanently fail the story. The ending should consider the store's progress toward replacing the shelves and which customers still trust the store. Optional product unlock purchases reduce current cash available toward the repair. The ending may vary in tone and result, but should not give the teen a harsh failure ending. The intended message is that money matters, but it is not the only measure of worth.

## Goals and non-goals

### Goals

- Make product drag-and-drop, customer targeting, and order completion the main interaction.
- Make simultaneous customers legible and gradually more challenging.
- Give customers persistent individual trust and return behavior.
- Connect day-to-day gameplay and product progression to the teen's summer growth.
- Support mouse and touch input.
- Use pixel-art presentation suited to a Filipino sari-sari store.

### Non-goals for this gameplay slice

- A Mom's Tips panel or dialogue-based tip system.
- Cooking or preparation minigames; products are ready to hand over.
- Product stock limits, restocking, or inventory shortages.
- A full school-life simulation, grades minigame, or free-roaming 3D world.
- A final narrative script with all customer names and dialogue; those can follow after this design is approved.

## Reasonable implementation choices after approval

Once the remaining decisions are approved, the builder may choose the exact scene/node structure, customer data representation, animation timing, UI layout, touch-drag thresholds, and implementation details, provided they preserve the behaviors above.
