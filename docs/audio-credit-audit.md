# Audio credit audit — 2026-11-03

Compared runtime audio mappings and playback calls against the supplied credits screenshot. Creator names from the screenshot are user-supplied, not independently source-verified. No audio or in-game credits were changed by this audit.

## Already identified by the supplied list

| Use | Active file | Supplied credit |
| --- | --- | --- |
| Completed sale / accepted payment | `assets/audio/pixabay/sfx/cash_register_sale.wav` | Cash Register Sale — Dan_AudioFile (Freesound.org) |
| Fiesta BGM | `assets/audio/pixabay/music/intense_music.mp3` | Fiesta Day — AtlasAudio (Pixabay), matched by game use; confirm recording |
| Rain-day BGM | `assets/audio/pixabay/music/rainy_day.mp3` | Rainy Day — Monume (Pixabay), matched by game use |
| Normal-day BGM | `assets/audio/pixabay/music/normal_store_days.mp3` | Normal Day — sinneschlosen (Pixabay), matched by game use |

Important: `fiesta_day.mp3` exists but is not the active fiesta track. The active mapping is `intense_music.mp3`. Do not credit an unused recording merely because its filename resembles the supplied title. The folder named `pixabay` also does not establish a file's original platform; the sale sound is identified as Freesound in the screenshot.

## Identified in existing repository documentation

| Use | Active file | Existing credit |
| --- | --- | --- |
| Main menu (also campaign board) | `assets/audio/pixabay/music/calm_nature_ambience.mp3` | Calm Nature Ambience — zehendrew, according to `docs/audio-credits.md`; exact source URL remains unrecorded |

## Still need a creator/source match

| Use | Active file |
| --- | --- |
| Picking up a product | `assets/audio/pixabay/sfx/pick_up.mp3` |
| Correct product delivery | `assets/audio/pixabay/sfx/correct_item.wav` |
| Wrong product / insufficient payment | `assets/audio/pixabay/sfx/wrong_item.mp3` |
| Patience warning, timeout, angry customer alert | `assets/audio/pixabay/sfx/patience_warning.mp3` |
| Dialogue-start blip (pitch varied in code) | `assets/audio/pixabay/sfx/convo.mp3` |
| Starting / continuing the game | `assets/audio/pixabay/sfx/continue_or_start_game.wav` |
| Day 4 rain ambience, separate from music | `assets/audio/pixabay/ambience/rain.ogg` |
| Normal-day ambience when the store opens, separate from music | `assets/audio/pixabay/ambience/normal_day.ogg` |
| Story phone ringing | `assets/audio/pixabay/sfx/supplier_phone_ring.wav` |

The screenshot additionally identifies Button Click — SoundShelfStudio (Pixabay), Coin Pickup — Driken5482 (Pixabay), and Money Pickup — KRNBEATZ (platform not specified). These are identified contributors but cannot yet be reliably assigned to the renamed active files. Compare the original downloads or recordings before assigning them. There is no separately mapped generic button-click, coin-pickup, or money-pickup cue; game actions currently use the cue mappings listed above.

## Present but not referenced by runtime audio

- `sfx/sale_completed.mp3`
- `sfx/muffled_dialogue_blip.wav`
- `music/main_menu.wav`, `music/main_menu.ogg`
- `music/fiesta_day.mp3`
- `ambience/motorcycle.wav`
- `ambience/fiesta_day_bg.mp3`
- `ambience/rain.wav`, `ambience/normal_day.wav`: WAV counterparts; runtime plays OGG versions. Attribute the original recordings once, not separately for conversions.

All paths in this section are relative to `assets/audio/pixabay/`.

## Evidence

- `scripts/kwenta_audio.gd`: default cue/music paths; `timeout` and `angry` share one recording.
- `scripts/main.gd`: product/payment cue dispatch, day-dependent music and ambience, opening ambience, dialogue cue, and direct phone-ring load.
- `scripts/main_menu.gd`: menu music and persistent start/continue cue.
- `scripts/campaign_board.gd`: reuses existing music; introduces no new audio files.
- `scripts/credits.gd` and `scripts/ending_transition.gd`: introduce no new audio files.

Total: **14 distinct active recordings**. Four have credits supplied in the screenshot (music matches by use), one more has a creator named in repository documentation, and nine require a confirmed file-to-source match. The three additional SFX names may reduce those nine after matching. Exact source links are still absent from the repository records.
