# Procedural Parody Product Art Design

## Intent

Replace generic product artwork with deterministic pixel-art textures for every one of Kwenta's 23 parody products. Each product must communicate its parody identity at the small 640x360 storefront scale and retain a distinct single unit for drag previews and customer orders.

## Decisions

- Generate textures at runtime with Godot `Image` and `ImageTexture`; do not require an external sprite-generation or download step.
- Add `stacked_texture_key` and `single_unit_texture_key` to `ProductData`. Every product resource assigns both keys to its stable product ID.
- `CounterArt` owns a compact visual recipe per product: category, primary/accent colors, and a semantic mark. It builds a 24x24 single unit and 48x48 stack display from that recipe.
- Rail products render their single packet four times as a connected strip. Shelf products use their generated 48x48 display, including crates, racks, sacks, trays, jars, and packages.
- Locked products remain absent because Main only instantiates currently available `ProductData` items.

## Required visual language

- Sachets use the specified parody palettes and marks: citrus, leaf, coffee bean, cyan hygiene, red/white tube, detergent green, and red/yellow chip pack.
- Row A uses readable packaging silhouettes: packets, cup, loaf, cans, glass jar, gum box, and eggs.
- Row B uses heavy-goods silhouettes: cooler/crate bottles, condiment rack, and burlap sack.

## Verification

The test runner verifies all 23 resources assign both texture keys, every recipe has a palette/mark, the generated single and stacked textures are distinct sizes/objects, and all order bubbles use the generated single texture.
