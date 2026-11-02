# Utang implementation

Paid purchase totals persist by customer from Day 1. Normal sales count their discounted bill, excluding tips and change errors. Credit principal counts when fully repaid; interest never counts as purchase history. Older saves retain story debts but cannot reconstruct purchase history that was never recorded.

Day 3 retains Paolo's interest-free ₱3 story exception and existing Day 6 repayment. Day 4 introduces Inay's rules. Day 5 reveals the older ledger and preserves Rosa's ₱320 balance and ₱110 partial payment.

Random credit requests are eligible on Days 4–6, with a 30% chance per eligible ordinary arrival and at most one request per day. Scripted customers and customers with outstanding debts are excluded. Baskets use available products, total ₱100–150 and contain at most 12 units. If a suitable basket cannot be made, the customer keeps their ordinary order.

One-time rates: 7% below ₱50 paid spending; 5% from ₱50; 3% from ₱100; 1.5% from ₱150. Charges round to whole pesos. The offer locks before approval. Declining removes the customer without trust loss. Finishing an approved order records debt without changing cash.

Due repayments appear as portrait dialogues at the next shift opening, independently of random spawning. Collecting credits cash exactly once and is counted separately from new sales. The UTANG button pauses the shift to inspect balances, showing older records only from Day 5. Retries restore debt and purchase totals with the start-of-shift state.

Validation: tests/utang_test_runner.gd covers rates, basket bounds, delayed income, purchase accounting, JSON persistence, duplicate collection prevention, scheduled repayment dialogue, decline, day gating and the ledger reveal. Existing Paolo, Rosa, Day 4 visitor, Day 5 opening and checkpoint runners cover story integration. Rates and request frequency remain initial playtest values.

The lending offer uses an item-card panel with product sprites, quantities, the next-day repayment total and expandable interest/purchase-history details. Approve and decline actions are guarded against repeated taps. Larger baskets scroll within the item area while the repayment total and actions remain visible.
