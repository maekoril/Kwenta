# Fiesta routes

Day 6 offers two explicit choices with identical crowds and normal ordering patience (25 seconds). The former helper mix-ups and help/solo patience multipliers are removed.

- Help: Select Mikay, then a customer waiting for change, to handle the exact amount. The ability starts ready and recharges over 20 seconds of active shift time; story pauses and game pauses do not consume recharge time. Select Jun-jun and then an ordering customer to deliver the entire remaining order, with a 60-second cooldown. Select Bogs to complete all eligible current orders, with a 120-second cooldown. Customers waiting for change still need their change; each cooldown is displayed on the helper portrait. The helpers do not appear as random customers on this route. Automated change does not generate a speed tip.
- Solo: Inay grants 20% of completed, paid goods bills after discounts, rounded to a whole peso. Tips, debt repayments and unpaid credit orders do not count. The amount accumulates visibly and is granted once when the shift completes, before campaign saving. It is itemized separately in the closing summary. Change errors do not alter the goods bill used as the basis.

Tonyo recalls Inay’s earlier promise before the choice; she is absent from the store. Friends arrive and offer help directly. Both options state their effects. Friends can support the brownout response on either route. Earlier customer callbacks remain.

Day 5's phone call establishes Inay's offer and her encouragement to ask for help. On Day 6, the brownout interrupts the shift at game minute 630 (6:30 PM), pauses customer patience, and shows different dialogue for each route. Mikay's flashlight and Jun-jun's candle illuminate the store on either route; on the solo route Tonyo still handles orders and change. The power remains out through the 8:00 PM closing. After the friends bring the lights, shoppers from Alfa-Save arrive more frequently until closing. Paolo's ₱3 repayment happens during the shift on the credit branch; on the refusal branch he returns to buy the original soft drink. Debug mode can preview either the repayment or brownout directly.

Retry restores start-of-shift cash and campaign state, then resets the ability, sales basis and reward when the shift restarts. No bonus is granted on game over.

Validation: fiesta_routes_test_runner.gd checks bonus exclusions, rounding, single payment, cooldown, target selection, pause behavior and resets. day_six_shift_start_test_runner.gd checks both story choices through briefing and live gameplay, and exercises the helper button through the cash tray.
