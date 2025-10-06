class_name MachineData
extends Resource

## Defines research machines for soul analysis

enum MachineType {
	BASIC_ANALYZER,       # Starter: Slow but free - Discover 1 random property (60s)
	RANDOM_PROPERTY,      # Machine 1: Discover 1 random undiscovered property
	SPECIFIC_RANGE_WIDE,  # Machine 2: Discover specific property within 20-40 points
	RANDOM_RANGE_NARROW,  # Machine 3: Discover random property within 20 points
	MULTI_PROPERTY,       # Machine 4: Discover all of 6 specific properties if present
	ELIMINATE_OPTIONS,    # Machine 5: Remove 2 possibilities from Era or Cause of Death
	REVEAL_INFO          # Machine 6: Discover Era or Cause of Death
}

static func get_machine_name(type: MachineType) -> String:
	match type:
		MachineType.BASIC_ANALYZER:
			return "Basic Analyzer"
		MachineType.RANDOM_PROPERTY:
			return "Property Finder"
		MachineType.SPECIFIC_RANGE_WIDE:
			return "Wide Range Analyzer"
		MachineType.RANDOM_RANGE_NARROW:
			return "Narrow Range Analyzer"
		MachineType.MULTI_PROPERTY:
			return "Multi-Property Scanner"
		MachineType.ELIMINATE_OPTIONS:
			return "Elimination Filter"
		MachineType.REVEAL_INFO:
			return "Info Revealer"
	return "Unknown"

static func get_machine_description(type: MachineType) -> String:
	match type:
		MachineType.BASIC_ANALYZER:
			return "Slow but reliable - Discover 1 random undiscovered property\n(Starter machine - already owned)"
		MachineType.RANDOM_PROPERTY:
			return "Discover 1 random undiscovered property"
		MachineType.SPECIFIC_RANGE_WIDE:
			return "Discover the value of a specific property within 15-40 points\ne.g. Scientific 55 → \"Scientific 52-82\""
		MachineType.RANDOM_RANGE_NARROW:
			return "Discover the value of a random property within 20 points\ne.g. Scientific 55 → \"Scientific 52-72\""
		MachineType.MULTI_PROPERTY:
			return "Discover all of 6 specific properties, if present\ne.g. discover Scientific, Artistic, Strategic, etc."
		MachineType.ELIMINATE_OPTIONS:
			return "Remove 2 possibilities from Era or Cause of Death\nCan be run repeatedly to remove 2 more"
		MachineType.REVEAL_INFO:
			return "Discover Era or Cause of Death"
	return "Unknown"

static func get_machine_cost(type: MachineType) -> int:
	match type:
		MachineType.BASIC_ANALYZER:
			return 0  # Starter machine - free
		MachineType.RANDOM_PROPERTY:
			return 150
		MachineType.SPECIFIC_RANGE_WIDE:
			return 100
		MachineType.RANDOM_RANGE_NARROW:
			return 350
		MachineType.MULTI_PROPERTY:
			return 300
		MachineType.ELIMINATE_OPTIONS:
			return 100
		MachineType.REVEAL_INFO:
			return 250
	return 0

static func get_machine_duration(type: MachineType) -> int:
	match type:
		MachineType.BASIC_ANALYZER:
			return 60  # 2x slower than Property Finder
		MachineType.RANDOM_PROPERTY:
			return 30
		MachineType.SPECIFIC_RANGE_WIDE:
			return 50
		MachineType.RANDOM_RANGE_NARROW:
			return 80
		MachineType.MULTI_PROPERTY:
			return 90
		MachineType.ELIMINATE_OPTIONS:
			return 25
		MachineType.REVEAL_INFO:
			return 65
	return 0
