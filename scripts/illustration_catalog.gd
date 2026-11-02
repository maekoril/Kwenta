extends RefCounted

# Only illustrations actually used in the story, not unused art variants.
const ENTRIES := [
	{"id": "day7_project", "day": 7, "file": "day7_tonyo_miniature.png", "title": "Ang Tindahan Namin", "caption": "Ang miniature ni Tonyo para sa project niya.", "seen_only": true},
	{"id": "bedroom", "day": 1, "file": "tonyo_bedroom.png", "title": "Kwarto ni Tonyo", "caption": "Dito nagsimula ang linggo ni Tonyo."},
	{"id": "box", "day": 2, "file": "day2_box_fall.png", "title": "Tumingin sa dinadaanan", "caption": "Bagong araw, bagong aayusin sa tindahan."},
	{"id": "berting", "day": 2, "file": "berting_counter_50.png", "title": "Mang Berting's 50 pesos", "caption": "Naiwan ni Mang Berting ang kanyang ₱50."},
	{"id": "paolo_coins", "day": 3, "file": "day3_paolo_coins_casual.png", "title": "Kulang ng Tatlo", "caption": "Binilang ni Paolo ang mga baryang dala niya.", "seen_only": true},
	{"id": "project_box", "day": 3, "file": "day3_project_box.png", "title": "Karton Pa Lang", "caption": "Naghihintay pa sa ilalim ng kama ang project ni Tonyo.", "seen_only": true},
	{"id": "corner", "day": 4, "file": "day4_alfa_save_corner.png", "title": "Bagong karibal", "caption": "May bagong karatula sa kabilang tindahan."},
	{"id": "umbrella", "day": 4, "file": "day4_tonyo_lends_umbrella_stocked_tonyo.png", "title": "Payong ni Inay", "caption": "Ipinahiram ni Tonyo ang payong ni Aling Cora kay Kuya Dodong."},
	{"id": "lina", "day": 4, "file": "day4_lina_alfa_corner.png", "title": "Sayang, hindi naabutan", "caption": "Pagbalik ni Tonyo mula sa laro, paalis na si Aling Lina.", "choice": "day4_rain", "value": "join"},
	{"id": "shelter", "day": 4, "file": "day4_friends_shelter.png", "title": "Feeta & Friends", "caption": "Nagsalo ang magkakaibigan habang hinihintay tumila ang ulan.", "choice": "day4_rain", "value": "shelter"},
	{"id": "phone", "day": 5, "file": "day5_tonyo_phone_v2.png", "title": "Pangangamusta", "caption": "Tumawag si Nanay para mangamusta."},
]

static func record_seen(story, path: String) -> void:
	if story == null:
		return
	for entry in ENTRIES:
		if path == "res://assets/story/" + entry.file:
			story.choices["gallery_seen_" + entry.id] = true
			return

static func is_unlocked(story, entry: Dictionary) -> bool:
	if story == null:
		return false
	if bool(story.choices.get("gallery_seen_" + entry.id, false)):
		return true
	if entry.get("seen_only", false):
		return false
	# Older saves predate seen flags. Completed diary days establish which
	# scenes played; only restore branch art matching the recorded choice.
	if str(story.choices.get("diary_day_%d" % entry.day, "")).is_empty():
		return false
	return not entry.has("choice") or story.get_choice(entry.choice) == entry.value
