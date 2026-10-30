# Shelf Shop Design

## Intent

Replace direct shelf-lock purchases with a one-time shelf shop. Story products continue to unlock automatically by campaign day. Optional shelf groups are bought with campaign cash and unlock every product in that group immediately and permanently.

## Player Flow

1. The player clicks a Shop button in the upper-right HUD at any point during a shift.
2. A modal lists every purchasable shelf, its included products, purchase cost, and the player’s current cash.
3. The player can buy a shelf once when they have sufficient cash. The modal refreshes and the products become draggable and orderable immediately.
4. A purchased shelf remains available across later campaign days and saved sessions.

## Inventory and Costs

All shelves are offered from Day 1.

- Right Hanging Strip: Champ Powder, Clean, Rizz-Up — PHP 150.
- Water Shelf: Bato Spring Water — PHP 120.
- Condiment Shelf: Boss Toyo, Pating, Real Suka — PHP 250.
- Oil Shelf: Golden State Warriors Oil — PHP 200.
- Rice Shelf: Jasmine Rice — PHP 300.

## Constraints

- Do not change story product day unlocks.
- Do not allow product locks in the storefront to trigger purchases.
- Keep the existing `CampaignState.purchased_store_groups` save format.
- Remove the Drink Cooler; it is not part of the story.
