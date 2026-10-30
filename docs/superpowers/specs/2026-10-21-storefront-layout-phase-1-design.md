# Storefront Layout Phase 1 Design

## Intent

Ground customer portraits in the street-facing service window while keeping the product shelves and counter legible at the 640x360 reference resolution.  Orders must be compact, readable and easy to target during a drag interaction.

## Scope

- Keep customers within the centre window (`x=150..490`, `y=24..200`) and occlude their lower edge with a foreground crop of the existing concrete sill.
- Replace the large order card with a dynamic, minimal-margin icon panel and a separate patience bar.
- Place the name/trust information inside a dark, rounded tag near each portrait.
- Record named, fixed storefront zones for rails, countertop, shelf rows and customer window; product slots remain the single source of truth for drag positions.
- Retain existing product resources, order pools and branded-art choices unchanged.

## Non-goals

- No product catalogue, price, parody-item, campaign, or story edits.
- No replacement background art or new external assets.
- No change to delivery rules or customer state.

## Layout Decisions

- `main.tscn` owns invisible reference-slot controls and the cropped foreground sill. The sill is drawn above customers but below draggable products.
- `StorefrontLayout` owns viewport-space zone rectangles, item slots, customer bounds, and contact-shadow metadata.
- A customer actor uses a 68px-wide, 126px-high target beginning at `y=80`; this keeps its bubble and portrait target below the overhead rails, while the bottom edge is covered by the sill at about `y=195`.
- Order cells are 20px square, with 2px panel padding. The panel recalculates from the count of distinct requested products and stays no wider than 64px.
- The patience bar is a sibling immediately below that panel so its bottom alignment remains correct as rows are added.
