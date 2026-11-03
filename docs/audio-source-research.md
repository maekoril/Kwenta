# Audio source research — 2026-11-03

Checked embedded ID3/RIFF/Vorbis metadata, Git audio history, top-level Downloads audio files, and public source pages. Most MP3s have no title/artist tags. No original downloads were found at the top level of Downloads. Git records already-renamed files, without additional source URLs.

## Newly identified: correct delivery

`assets/audio/pixabay/sfx/correct_item.wav` embeds the title **Item or Material Pickup Pop 1 of 3**, artist **Final Boss**, album **Fun Stuff**, year **2022**. It is 6,566 bytes, mono 44.1 kHz/16-bit PCM, 3,136 samples (0.071111 seconds).

[Item or Material Pickup Pop 1 of 3 — el_boss](https://freesound.org/people/el_boss/sounds/665183/) agrees on title, duration, format, approximate size, and year. High-confidence identification from metadata and technical details; no byte-for-byte comparison performed. The source page lists Creative Commons 0. Suggested recognition: “Item or Material Pickup Pop 1 of 3 — el_boss (Freesound).” This is another contributor beyond the screenshot's three pending SFX entries.

## Source pages recovered for already named recordings

- [Calm Nature Ambience — zehendrew](https://pixabay.com/sound-effects/nature-calm-nature-ambience-379478/): matches the title/creator in repository documentation for `music/calm_nature_ambience.mp3`. Pixabay Content License is listed on the page. It is categorized as a sound effect despite being used on the game's Music bus. Local association is supported by documentation, not binary comparison.
- [Cash Register,Sale Sound, old shop.stereo.wav — Dan_AudioFile](https://freesound.org/people/Dan_AudioFile/sounds/633232/): matches the screenshot's creator and repository description of the trimmed register hit. The page lists Attribution 4.0. Suggested record: “Cash Register,Sale Sound, old shop.stereo.wav — Dan_AudioFile, Freesound, CC BY 4.0; trimmed to a short hit and converted to mono.” No comparison to original PCM performed.

## Candidates only — do not assign to a file yet

- [UI Button Click Mechanical — SoundShelfStudio](https://pixabay.com/sound-effects/film-special-effects-ui-button-click-mechanical-515078/). This creator has multiple button sounds; the screenshot does not distinguish which recording.
- [Retro Coin 1 — Driken5482](https://pixabay.com/sound-effects/film-special-effects-retro-coin-1-236677/), [Retro coin 3](https://pixabay.com/sound-effects/film-special-effects-retro-coin-3-236679/), [Retro coin 4](https://pixabay.com/sound-effects/film-special-effects-retro-coin-4-236671/). Multiple plausible sources; none matched to a local file.
- KRNBEATZ has “8-Bit Retro Coin” and “8bit_coin_pickup” on Pixabay, but the exact recording corresponding to “Money Pickup” is not established.
- [Retro Arcade Game Music 2 — Monume](https://pixabay.com/music/electronic-retro-arcade-game-music-2-498031/) is a duration-based lead for rainy-day BGM, not a confirmed match. Duration and creator alone cannot identify a recording.

## Still unresolved

Eight of the earlier nine unknown active recordings remain without a reliable file-to-source match:

1. `sfx/pick_up.mp3`
2. `sfx/wrong_item.mp3`
3. `sfx/patience_warning.mp3`
4. `sfx/convo.mp3`
5. `sfx/continue_or_start_game.wav`
6. `ambience/rain.ogg` / `rain.wav` original
7. `ambience/normal_day.ogg` / `normal_day.wav` original
8. `sfx/supplier_phone_ring.wav`

Paths are relative to `assets/audio/pixabay/`. Rain contains a Logic Pro export timestamp (2014-02-01), but no reliable artist identity. Start/continue has DAW/cue information without identifying artist/title. Phone has no identifying metadata; its feature commit does not establish whether it was generated or downloaded.

The exact source tracks for screenshot BGM credits also remain unverified; those creator names are user-supplied. `intense_music.mp3` is the active fiesta track, while `fiesta_day.mp3` is unused. No match was claimed based only on a similar filename or duration.

Original download filenames, download/license records, or saved source links are the best remaining evidence. There is no automatic reverse-audio recognition tool available in this session. In-game credits remain unchanged.

## Mixkit follow-up

The team identified Mixkit as a likely source. Direct comparison confirmed:

| Local recording | Mixkit title | Catalog ID | Evidence |
| --- | --- | --- | --- |
| `assets/audio/pixabay/ambience/rain.wav` (converted to active `rain.ogg`) | Light rain loop | 2393 | Downloaded original WAV is byte-for-byte identical |

Source: [Mixkit rain catalog](https://mixkit.co/free-sound-effects/rain/) — select **Light rain loop**, **0:15** (there is also a different 0:39 recording with the same title). Download filename: `mixkit-light-rain-loop-2393.wav`.

Both SHA-256 hashes: `0e90fa5f678cca6966e66477b75b8fe608bf845d54e4b3e3efff839b9cc6805e`.

Suggested recognition: **“Light rain loop — Mixkit.”** The listing does not identify an individual creator. Use the [Mixkit Sound Effects license](https://mixkit.co/license/#sfxFree) as the source license record rather than attributing the file to Pixabay because of its local folder name.

The Mixkit “Urban city ambience at night” (#2678) candidate was rejected: neither its original file nor decoded waveform matches `normal_day.wav`. Compared 93 public notification, game, and interface previews against local SFX after decoding to mono 8 kHz PCM and checking time-offset correlation; none produced a reliable match. This does not rule out other Mixkit recordings, edits, or versions outside that sample.

Remaining unresolved active file associations are now **seven**: pickup, wrong-item, patience warning, dialogue blip, start/continue, normal-day ambience, and phone ring. The exact BGM source recordings also still need verification as described above. In-game credits have not been changed.
