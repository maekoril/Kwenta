# Campaign level replays

The Campaign Board selects Days 1–7 and launches `scenes/main.tscn` in a separate replay session. It uses the regular day intro, customers, goals, purchases, choices, closing story, and results. Day 7 retains its classroom ending and credits. The old dialogue-only chapter reader has been removed.

Players unlock the board by finishing the campaign. Debug → Campaign Board bypasses that requirement for playtesting; release-build replays do not depend on debug mode.

Replays do not write campaign progress, tutorial completion, cash, choices, medals, or day-start checkpoints. Completing Days 1–6 returns to the board from the results screen; Day 7 returns through credits. Pause and the replay Game Over screen also offer Campaign Board. Retry remains within the selected day.

Normal campaign saves now retain day-start checkpoints, including cash, purchased store groups, previous choices, and tutorial state. Existing saves remain compatible. Where an older save has no checkpoint for a day, replay uses the day's story-unlocked stock, a fixed starting budget of ₱150 plus ₱150 per prior day, and prior saved story choices with defaults for missing choices. It does not copy end-of-campaign wealth or future choices into an earlier level. Future normal campaigns record the actual starting setup instead.

Validation: `level_replay_test_runner.gd` exercises all seven gameplay launches, real shift/customer initialization, checkpoint restoration, retry, summary/credits/pause/game-over returns, debug launch, and byte-for-byte campaign-save isolation. The responsive board test checks landscape, wide, 4:3, and portrait layouts. Campaign save/continue, tutorial checkpoint, credits, classroom transition, and ending-input tests also pass.

The broader core gameplay loop test has an existing failure expecting a buying customer immediately at Day 1 opening; the current Day 1 story visitor runs first. The same assertion fails using the pre-change main script.
