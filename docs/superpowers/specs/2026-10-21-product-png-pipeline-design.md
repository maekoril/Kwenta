# Product PNG Pipeline Design

## Goal

Replace runtime-generated product blocks with PNG-backed shelf and single-unit art for all 23 parody products.

## Approach

- Create `assets/products/sachets`, `assets/products/shelf_goods`, and `assets/products/bottles`.
- Reuse the project’s existing detailed redesign PNGs for every product that already has a matching stacked and isolated source art file.
- Generate only the three missing isolated sachet packet PNGs (Clean, Rizz-Up Toothpaste, Champ Powder) with transparent backgrounds and crisp pixel-art styling.
- Add `Texture2D` resource properties to `ProductData`; every `.tres` references one stacked PNG and one isolated single PNG.
- `CounterArt` resolves catalog resources and returns only assigned PNG textures. It contains no procedural Image/ImageTexture generation or generic-product fallback.

## Rendering

- ProductDragItem uses nearest-neighbour filtering, assigned stack PNGs for shelves, assigned single PNGs for drag previews, and existing drawn contact shadows underneath.
- Rail controls repeat their assigned single packet to form the hook strip while their resource still owns a dedicated strip PNG for static stack state.
- Order bubbles use the assigned single PNG.

## Verification

Tests assert every catalog product owns two PNG Texture2D resources under `res://assets/products/`, validates alpha-backed textures are non-null and distinct, and checks that CounterArt has no procedural texture creation path.
