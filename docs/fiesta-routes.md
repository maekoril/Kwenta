# Fiesta routes

Day 6 offers two explicit choices with identical crowds and normal ordering patience (25 seconds). The former helper mix-ups and help/solo patience multipliers are removed.

- Help: Mikay handles exact change for the customer whose cash tray is open. The ability starts ready and recharges over 20 seconds of active shift time; story pauses and game pauses do not consume recharge time. Jun-jun brings stock within reach and Bogs organizes the queue. Their roles are established in dialogue and displayed with portraits. Automated change does not generate a speed tip.
- Solo: Inay grants 20% of completed, paid goods bills after discounts, rounded to a whole peso. Tips, debt repayments and unpaid credit orders do not count. The amount accumulates visibly and is granted once when the shift completes, before campaign saving. It is itemized separately in the closing summary. Change errors do not alter the goods bill used as the basis.

Tonyo recalls Inay’s earlier promise before the choice; she is absent from the store. Friends arrive and offer help directly. Both options state their effects. Friends can support the brownout response on either route. Earlier customer callbacks remain.

Retry restores start-of-shift cash and campaign state, then resets the ability, sales basis and reward when the shift restarts. No bonus is granted on game over.

Validation: fiesta_routes_test_runner.gd checks bonus exclusions, rounding, single payment, cooldown, target selection, pause behavior and resets. day_six_shift_start_test_runner.gd checks both story choices through briefing and live gameplay, and exercises the helper button through the cash tray.
