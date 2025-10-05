class_name SoulData
extends Resource

## Enums

enum Era { CLASSICAL, ANCIENT, PREHISTORIC, MODERN }
enum CauseOfDeath { BATTLE, ACCIDENT, NATURAL, POISON, ILLNESS, MURDERED, DROWNED, STARVED, FROZEN }
enum SoulAttribute { ARTISTIC, SCIENTIFIC, FUNNY, FAMOUS, RICH, BEAUTIFUL, GENEROUS, IMPACTFUL, POWERFUL, STRATEGIC }

## Represents a soul's data/properties

@export var id: String = ""
@export var name: String = ""
@export var era: Era = Era.MODERN
@export var causeOfDeath: CauseOfDeath = CauseOfDeath.NATURAL
@export var stats: Dictionary
@export var visual_color: Color = Color(0.5, 0.8, 1.0)

func _init(soul_id: String = "", soul_name: String = "", soul_era: Era = Era.MODERN) -> void:
	id = soul_id
	name = soul_name
	era = soul_era

func _to_string() -> String:
	return "Soul: %s (ID: %s, Era: %s)" % [name, id, era]
	
static func generate_random_soul() -> SoulData:
	var randomId = randi();
	var randomColor = _generate_random_hsv_color()

	var soul = SoulData.new()
	soul.id = "soul_%d" % (randomId)
	soul.era = RarityTables.generate_weighted_era()
	soul.name = NameGenerator.generate_soul_name(soul.era)  # Pass era for appropriate title
	soul.causeOfDeath = RarityTables.generate_weighted_death()
	soul.stats = _get_random_properties_for_soul()
	soul.visual_color = randomColor

	return soul
	
static func _get_random_properties_for_soul() -> Dictionary:
	var properties = {}

	var numProperties = (randi() % 3) + 1
	for x in numProperties:
		var attribute = SoulAttribute.values().pick_random()
		# check that its not already in properties
		var proficiency = clamp(randfn(0.5, 0.18), 0.0, 1.0) * 100
		properties[attribute] = proficiency
		
	return properties

static func _generate_random_hsv_color() -> Color:
	return Color.from_hsv(
		  randf(), # HUE
		  randf_range(0.5, 0.9), # SATURATION - Higher for more vibrant colors
		  randf_range(0.4, 0.7), # BRIGHTNESS - Lower to avoid washed out colors
	)
