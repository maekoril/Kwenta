# Kwenta Audio Pass Design

## Intent

Give the existing sari-sari store gameplay clear, warm feedback and a lived-in neighbourhood sound bed without obscuring touch interaction or dialogue.

## Goals

- Add a small, useful first audio set: pickup, correct delivery, rejection, completed sale, customer timeout, rain ambience, and fiesta ambience.
- Use freely licensed external assets from the approved research sources; preserve each asset URL, creator, and license in the repository.
- Keep gameplay code independent of individual audio files by addressing sounds through named cues.
- Make all effects work when an asset is missing, so the prototype still runs.

## Non-goals

- No final soundtrack, voice acting, or dynamic music system in this pass.
- No generic tropical stereotype or copied game audio.
- No new gameplay rules or UI controls.

## Audio direction

Feedback is short and gentle: paper/plastic movement for pickup, a compact bright confirmation for correct delivery, a muted wooden rejection, and a small coin/cash sound for sales. Rain and fiesta are looped low-volume ambience, selected by the existing day/environment state.

## Constraints

- Godot 4.7.2 standard; Android-first landscape project.
- Sound files live in `assets/audio/`; prefer compact OGG/WAV source assets that Godot imports natively.
- Sources must be CC0 or otherwise commercially usable, with the exact license recorded in `docs/audio-credits.md`.
- Sound effects must not block or alter shift, order, payment, timeout, or story flow.

## Acceptance criteria

- Correct and wrong product delivery trigger distinct cues exactly once per interaction.
- A completed cash sale triggers a sale cue, and a timeout triggers a timeout cue.
- Day 4 enables rain ambience; Day 6 enables fiesta ambience; other days are silent by default.
- Automated tests cover cue-name routing and tolerate a missing stream without a runtime error.
