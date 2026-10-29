# Kwenta Audio Pass Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a small, licensed, event-driven first audio pass to the Kwenta prototype.

**Architecture:** `KwentaAudio` will own named cue streams and one-shot/loop playback, leaving gameplay classes to emit or request semantic cues. `main.gd` will route existing delivery, sale, timeout, and environment transitions through it; assets and credits remain data-only additions.

**Tech Stack:** Godot 4.7.2, GDScript, OGG/WAV external audio assets, existing SceneTree test runners.

**Spec:** `docs/superpowers/specs/2026-10-27-audio-pass-design.md`

## Global Constraints

- Keep gameplay semantics unchanged; audio failures must be non-fatal.
- Record source URL, creator, and license for every downloaded asset in `docs/audio-credits.md`.
- Prefer CC0 assets; do not include non-commercial assets.

## Review Focus

- A missing or unloaded audio stream must safely do nothing.
- One interaction must emit one cue, including drop handling that reaches `_resolve_product_delivery` through two input paths.
- Rain and fiesta ambience must not both loop at once.
- Day 6 brownout must retain fiesta ambience rather than restart or stack it.
- Headless tests must not require an audio device.

---

### Task 1: Semantic cue player

**Files:**
- Create: `scripts/kwenta_audio.gd`
- Create: `tests/kwenta_audio_test_runner.gd`

**Interfaces:**
- Produces: `KwentaAudio.play_cue(cue_name: String) -> bool`, `KwentaAudio.set_ambience(cue_name: String) -> bool`, and `KwentaAudio.current_ambience: String`.

- [ ] **Step 1: Write the failing tests** for an unregistered cue, registered one-shot cue, and ambience replacement.
- [ ] **Step 2: Run the new test runner** and verify it fails because `KwentaAudio` is absent.
- [ ] **Step 3: Implement `KwentaAudio`** with semantic cue registration, safe one-shot playback, and a single ambience player.
- [ ] **Step 4: Run the new test runner** and verify it passes.

### Task 2: Licensed audio assets and audit record

**Files:**
- Create: `assets/audio/sfx/`
- Create: `assets/audio/ambience/`
- Create: `docs/audio-credits.md`
- Modify: `scripts/kwenta_audio.gd`

**Interfaces:**
- Consumes: `KwentaAudio.register_default_cues() -> void`.
- Produces: semantic streams for `pickup`, `correct`, `reject`, `sale`, `timeout`, `rain`, and `fiesta`.

- [ ] **Step 1: Write a failing asset-registration test** that expects the seven named cues to resolve.
- [ ] **Step 2: Run it** and verify it fails before assets/default registrations exist.
- [ ] **Step 3: Download only CC0 or commercial-use assets** and add source/license records.
- [ ] **Step 4: Register the assets as default cues** in `KwentaAudio`.
- [ ] **Step 5: Run the audio test runner** and verify every default cue resolves.

### Task 3: Gameplay and environment integration

**Files:**
- Modify: `scripts/main.gd`
- Modify: `tests/gameplay_test_runner.gd`

**Interfaces:**
- Consumes: `KwentaAudio.play_cue` and `KwentaAudio.set_ambience`.

- [ ] **Step 1: Write failing tests** for the audio cue selected by correct/wrong delivery and environmental day.
- [ ] **Step 2: Run the relevant test runner** and verify the new expectations fail.
- [ ] **Step 3: Route existing delivery, sale, timeout, and day environment paths** to semantic audio cues without changing the existing gameplay result.
- [ ] **Step 4: Run both audio and gameplay test runners** and verify they pass.

### Task 4: Full verification

**Files:**
- Modify: `docs/audio-credits.md` if validation reveals an omission.

- [ ] **Step 1: Run every existing Godot test runner** and verify no regressions.
- [ ] **Step 2: Inspect the scene in Godot** for import errors and duplicated looping ambience.
- [ ] **Step 3: Run `git diff --check`** and record any pre-existing warnings separately from new work.
