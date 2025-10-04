class_name SoulData
extends Resource

## Represents a soul's data/properties

@export var id: String = ""
@export var name: String = ""
@export var era: String = ""
@export var tags: Array = []
@export var rarity: String = "common"  # common, rare, legendary
@export var condition: float = 1.0  # 0.0 to 1.0
@export var visual_color: Color = Color(0.5, 0.8, 1.0)

func _init(soul_id: String = "", soul_name: String = "", soul_era: String = "") -> void:
	id = soul_id
	name = soul_name
	era = soul_era

func _to_string() -> String:
	return "Soul: %s (ID: %s, Era: %s, Rarity: %s)" % [name, id, era, rarity]
