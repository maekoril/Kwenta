# Utang implementation

Paid purchase totals persist by customer from Day 1. Normal sales count their discounted bill, excluding tips and change errors. Credit principal counts when fully repaid; interest never counts as purchase history. Older saves retain story debts but cannot reconstruct purchase history that was never recorded.

Day 3 retains Paolo's interest-free ₱3 exception, but Tonyo forgets to record it. During the Day 4 phone lesson, Tonyo sees Inay's older entries, remembers Paolo, and writes down the debt. New lending starts that shift. Day 5 keeps the wake-up and phone illustrations; the call now covers collecting payments and updating partial balances. Day 4 loans are due on Day 5. Rosa's ₱320 debt and ₱110 partial payment, and Paolo's Day 6 repayment, are preserved. Paolo stays hidden in the ledger until the Day 4 recording beat; later-day saves and debug starts assume that lesson is complete.

Random credit requests are eligible on Days 4–6, with a 30% chance per eligible ordinary arrival and at most one request per day. Scripted customers and customers with outstanding debts are excluded. Baskets use available products, total ₱100–150 and contain at most 12 units. If a suitable basket cannot be made, the customer keeps their ordinary order.

One-time rates: 7% below ₱50 paid spending; 5% from ₱50; 3% from ₱100; 1.5% from ₱150. Charges round to whole pesos. The offer locks before approval. Declining removes the customer without trust loss. Finishing an approved order records debt without changing cash.

Due repayments appear as portrait dialogues at the next shift opening, independently of random spawning. Collecting credits cash exactly once and is counted separately from new sales. The UTANG button pauses the shift to inspect balances, showing older records from Day 4. Retries restore debt and purchase totals with the start-of-shift state.

Validation: tests/utang_test_runner.gd covers rates, basket bounds, delayed income, purchase accounting, JSON persistence, duplicate collection prevention, scheduled repayment dialogue, decline, day gating and the ledger reveal. Existing Paolo, Rosa, Day 4 visitor, Day 5 opening and checkpoint runners cover story integration. Rates and request frequency remain initial playtest values.

The lending offer uses an item-card panel with product sprites, quantities, the next-day repayment total and expandable interest/purchase-history details. Approve and decline actions are guarded against repeated taps. Larger baskets scroll within the item area while the repayment total and actions remain visible.
