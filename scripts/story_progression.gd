class_name StoryProgression
extends RefCounted

enum EndingVariant { BALANCED_SUCCESS, MIXED_PROGRESS, HOPEFUL_SECOND_CHANCE }

var config: CampaignConfig

func _init(campaign_config: CampaignConfig) -> void:
	config = campaign_config

func get_intro_text() -> String:
	return config.story_intro

func get_day_transition_text(completed_day: int) -> String:
	if config.story_transition_texts.is_empty():
		return "A new day begins at the store."
	var index := clampi(completed_day - 1, 0, config.story_transition_texts.size() - 1)
	return config.story_transition_texts[index]

func get_ending_variant(cash: int, trusted_regular_count: int, repair_goal_amount: int, trusted_regular_goal: int) -> int:
	var reached_repair_goal := cash >= repair_goal_amount
	var kept_regulars := trusted_regular_count >= trusted_regular_goal
	if reached_repair_goal and kept_regulars:
		return EndingVariant.BALANCED_SUCCESS
	if reached_repair_goal or kept_regulars:
		return EndingVariant.MIXED_PROGRESS
	return EndingVariant.HOPEFUL_SECOND_CHANCE

func get_ending_text(ending: int) -> String:
	match ending:
		EndingVariant.BALANCED_SUCCESS:
			return config.ending_balanced_success
		EndingVariant.MIXED_PROGRESS:
			return config.ending_mixed_progress
		_:
			return config.ending_hopeful_second_chance
