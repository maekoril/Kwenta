# Kwenta art (1080p placeholders, behind-the-counter view, 20 products)

The camera is the player's eyes behind the counter, looking out a service window.
Customers stand in the window. Product shelves are on the left and right walls.
Fridge and hanging-rack zones are separate screens reached with the arrows.

## Rules
- Base resolution 1920x1080 (16:9). Godot: stretch mode viewport, aspect keep.
- Final art must keep the same **file names and pixel sizes** as these placeholders so scenes don't need changes.
- snake_case names, size in the name (`single_noodles_180x240.png`).
- Brands: generic/fictional only. Text is never baked into art; use Labels with a pixel font.
- Placeholders use only `res://assets/sprites/palette/kwenta.gpl` (27 colors) and are chunky (each placeholder pixel is 3x3).
  Texture filter and palette are still open team decisions for the final art.
- Stock is infinite. The stack is purely decorative, always 4 copies deep.

## The 20 products (3 sprites each)
- Main shelves (12): noodles, canned_goods, chips, biscuits, bread, rice, eggs, cooking_oil, soy_sauce, vinegar, laundry_soap, dishwashing_liquid
- Fridge (4): softdrink, bottled_water, iced_tea, ice_candy
- Hanging rack (4): coffee_sachet, shampoo_sachet, candy, load_card (these hang from the top of their canvas)

Per product:
- `res://assets/sprites/products/single/single_<name>_180x240.png` the item the player picks up and drops on the counter
- `res://assets/sprites/products/stack/stack_<name>_210x276.png` the shelf view: front item plus 3 rear copies (+10px right, -9px up, one step darker)
- `res://assets/sprites/products/icon/icon_<name>_48x48.png` order-bubble icon

## Slots (see `res://data/layout.json`, all in 1920x1080 px)
- 20 enclosures: main 12 (2 per row, 3 rows, each wall), fridge 4 (2x2), rack 4 (2 per rod, 2 rods)
- Each slot has x, y of the stack canvas and an anchor (bottom = sits on the board, top = hangs from the rod)
- Locked slots use `res://assets/sprites/locked/locked_slot_cover_210x276.png`; add price text with a Label. `res://assets/sprites/ui/price_tag_blank_132x48.png` and `res://assets/sprites/ui/icon_padlock_48x48.png` are for the unlock UI
- Zones: `res://assets/sprites/scene/zone_fridge_1920x1080.png`, `res://assets/sprites/scene/zone_rack_1920x1080.png`; navigation arrows in `res://assets/sprites/ui/arrow_*_96x96.png`

## Other folders
- `res://assets/sprites/scene/` main-view layers; `res://assets/sprites/customers/` 192x336 busts; `res://assets/sprites/props/` cash box, calculator, coins, bills, label plate
- `res://assets/sprites/ui/` 9-slice bubble/panel/button (72x72, margin 12), patience bar frame + fills, icons, mom portrait
- `preview/` composed from the real files: main view, both zones, and a sheet of all 20 single items

## Notes
- The mom-tips panel is a transient popup. It covers right-wall slots while shown.
- The counter's bottom corners overlap the lowest shelf row by a few pixels on both walls.
- Touch targets: tappable area at least 120x120 px, even if the sprite is smaller.

## Where this lives in the repo
Art: `res://assets/sprites/` (scene, ui, palette, products, customers, props, locked). Slot data: `res://data/layout.json`. This file: `res://assets/sprites/README_art.md`.
