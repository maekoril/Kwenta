# Parody Product Data and Three-State Asset Design

## Intent

Make Kwenta’s complete 23-item catalog use the supplied parody names while retaining distinct shelf, single-unit, and locked states.

## Product Rules

- Preserve existing prices where a product already exists.
- Use the approved defaults for new records: Wemby ₱8, Ticnap Notnac ₱15, and B-fresh Gum ₱5.
- Use existing branded source art as the visual basis for each parody item; no new raster assets are required.
- Storefront displays use stacked, rack, cooler, basket, tray, or jar textures; drag previews and customer bubbles resolve only single-unit textures/icons.
- Locked products do not create a product item at all, leaving their shelf or rail slot bare.

## Catalog Decisions

- Existing IDs are retained where possible so saved orders remain valid.
- New IDs: `sandwich_biscuits` (Wemby), `noodle_pack` (Ticnap Notnac), and `bubble_gum` (B-fresh Gum).
- Patos is assigned a rail strip slot, while Wemby, Ticnap Notnac, and B-fresh Gum receive Row A / countertop slots.
- The campaign catalog and its day-order pools include all 23 records only when their unlock day has passed.

## Verification

- A live Godot regression reads all catalog records, checks the exact parody names/prices/zone classifications, confirms each state texture exists, verifies locked entries are not instantiated, and verifies bubble/preview textures use the single state.
