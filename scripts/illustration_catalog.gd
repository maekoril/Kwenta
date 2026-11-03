extends RefCounted

# Only illustrations actually used in the story, not unused art variants.
const ENTRIES := [
	{"id": "day7_project", "day": 7, "file": "day7_tonyo_miniature.png", "title": "Ang Tindahan Namin", "caption": "Ang miniature ni Tonyo para sa project niya.", "seen_only": true},
	{"id": "day7_presenting", "day": 7, "file": "day7_tonyo_presenting.png", "title": "Sa Harap ng Klase", "caption": "Ibinahagi ni Tonyo ang kanyang project sa klase.", "seen_only": true},
	{"id": "day7_classmates", "day": 7, "file": "day7_classmates_listening.png", "title": "Nakikinig ang Klase", "caption": "Nakinig ang mga kaklase ni Tonyo sa kanyang kwento.", "seen_only": true},
	{"id": "bedroom", "day": 1, "file": "tonyo_bedroom.png", "title": "Kwarto ni Tonyo", "caption": "Dito nagsimula ang linggo ni Tonyo."},
	{"id": "box", "day": 2, "file": "day2_box_fall.png", "title": "Tumingin sa dinadaanan", "caption": "Bagong araw, bagong aayusin sa tindahan."},
	{"id": "berting", "day": 2, "file": "berting_counter_50.png", "title": "Mang Berting's 50 pesos", "caption": "Naiwan ni Mang Berting ang kanyang ₱50."},
	{"id": "paolo_coins", "day": 3, "file": "day3_paolo_coins_casual.png", "title": "Tatlong Piso", "caption": "Binilang ni Paolo ang mga baryang dala niya.", "seen_only": true},
	{"id": "project_box", "day": 3, "file": "day3_project_box.png", "title": "Karton", "caption": "Naghihintay pa sa ilalim ng kama ang project ni Tonyo.", "seen_only": true},
	{"id": "corner", "day": 4, "file": "day4_alfa_save_corner.png", "title": "Bagong karibal", "caption": "May bagong karatula sa kabilang tindahan."},
	{"id": "umbrella", "day": 4, "file": "day4_tonyo_lends_umbrella_stocked_tonyo.png", "title": "Payong ni Inay", "caption": "Ipinahiram ni Tonyo ang payong ni Aling Cora kay Kuya Dodong."},
	{"id": "lina", "day": 4, "file": "day4_lina_alfa_corner.png", "title": "Sayang, hindi naabutan", "caption": "Pagbalik ni Tonyo mula sa laro, paalis na si Aling Lina.", "choice": "day4_rain", "value": "join"},
	{"id": "shelter", "day": 4, "file": "day4_friends_shelter.png", "title": "Feeta & Friends", "caption": "Nagsalo ang magkakaibigan habang hinihintay tumila ang ulan.", "choice": "day4_rain", "value": "shelter"},
	{"id": "day6_powerline", "day": 6, "file": "day6_fiesta_powerline.png", "title": "Brownout sa Fiesta", "caption": "Pumutok ang linya sa poste at nagdilim ang kalsada.", "seen_only": true},
	{"id": "day6_fireworks", "day": 6, "file": "day6_fiesta_fireworks.png", "title": "Paputok sa Fiesta", "caption": "Sabay-sabay pinanood nina Tonyo ang paputok mula sa tindahan.", "seen_only": true},
	{"id": "day5_wakes", "day": 5, "file": "day5_tonyo_wakes.png", "title": "Bagong Umaga", "caption": "Nagising si Tonyo sa panibagong araw.", "seen_only": true},
	{"id": "day5_rosa_payment", "day": 5, "file": "day5_rosa_payment.png", "title": "Hulog ni Lola Rosa", "caption": "Nag-abot si Lola Rosa ng pambayad sa utang niya.", "seen_only": true},
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
