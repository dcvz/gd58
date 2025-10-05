extends Node

## Manages owned research machines and active jobs

signal machine_purchased(machine_type: MachineData.MachineType)
signal machines_changed()
signal job_started(job: MachineJob)
signal job_completed(job: MachineJob)

var owned_machines: Array[MachineData.MachineType] = []
var active_jobs: Array[MachineJob] = []

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	_check_completed_jobs()

## Check if a machine is owned
func has_machine(type: MachineData.MachineType) -> bool:
	return owned_machines.has(type)

## Purchase a machine
func purchase_machine(type: MachineData.MachineType) -> bool:
	if has_machine(type):
		print("Machine already owned!")
		return false

	var cost = MachineData.get_machine_cost(type)
	var currency_manager = get_node("/root/Root/Gameplay/CurrencyManager")

	if not currency_manager.can_afford(cost):
		print("Cannot afford machine! Need %d KP" % cost)
		return false

	if currency_manager.spend_kp(cost):
		owned_machines.append(type)
		machine_purchased.emit(type)
		machines_changed.emit()
		print("Purchased %s for %d KP" % [MachineData.get_machine_name(type), cost])
		return true

	return false

## Get all owned machines
func get_owned_machines() -> Array[MachineData.MachineType]:
	return owned_machines.duplicate()

## Get all available machines to purchase
func get_available_machines() -> Array[MachineData.MachineType]:
	var available: Array[MachineData.MachineType] = []
	for type in MachineData.MachineType.values():
		if not has_machine(type):
			available.append(type)
	return available

## Start a machine job on a soul
func start_job(soul_id: String, soul: SoulData, machine_type: MachineData.MachineType) -> bool:
	if not has_machine(machine_type):
		print("Machine not owned!")
		return false

	# Check if soul already has a job running
	if is_soul_being_analyzed(soul_id):
		print("Soul is already being analyzed!")
		return false

	var duration = MachineData.get_machine_duration(machine_type)
	var job = MachineJob.new(soul_id, machine_type, Time.get_ticks_msec() / 1000.0, duration)
	active_jobs.append(job)
	job_started.emit(job)
	print("Started %s on soul %s (duration: %ds)" % [MachineData.get_machine_name(machine_type), soul_id, duration])
	return true

## Check if a soul is being analyzed
func is_soul_being_analyzed(soul_id: String) -> bool:
	for job in active_jobs:
		if job.soul_id == soul_id and not job.completed:
			return true
	return false

## Get active job for a soul (if any)
func get_soul_job(soul_id: String) -> MachineJob:
	for job in active_jobs:
		if job.soul_id == soul_id and not job.completed:
			return job
	return null

## Get all active jobs
func get_active_jobs() -> Array[MachineJob]:
	return active_jobs.filter(func(job): return not job.completed)

## Check for completed jobs and process them
func _check_completed_jobs() -> void:
	var current_time = Time.get_ticks_msec() / 1000.0

	for job in active_jobs:
		if not job.completed and job.is_complete(current_time):
			job.completed = true
			_process_completed_job(job)
			job_completed.emit(job)

## Process a completed job and apply discoveries
func _process_completed_job(job: MachineJob) -> void:
	var discovery_manager = get_node("/root/Root/Gameplay/DiscoveryManager")
	var inventory_manager = get_node("/root/Root/Gameplay/InventoryManager")
	var soul = inventory_manager.get_soul_by_id(job.soul_id)

	if not soul:
		print("Soul not found for completed job!")
		return

	# Apply machine-specific discovery logic
	match job.machine_type:
		MachineData.MachineType.RANDOM_PROPERTY:
			_discover_random_property(job.soul_id, soul, discovery_manager)
		MachineData.MachineType.SPECIFIC_RANGE_WIDE:
			# TODO: This needs user input for which stat
			pass
		MachineData.MachineType.RANDOM_RANGE_NARROW:
			_discover_random_stat_narrow_range(job.soul_id, soul, discovery_manager)
		MachineData.MachineType.MULTI_PROPERTY:
			# TODO: This needs user input for which 6 stats
			pass
		MachineData.MachineType.ELIMINATE_OPTIONS:
			_eliminate_era_or_death_options(job.soul_id, soul, discovery_manager)
		MachineData.MachineType.REVEAL_INFO:
			_reveal_era_or_death(job.soul_id, soul, discovery_manager)

## Machine 1: Discover 1 random undiscovered property
func _discover_random_property(soul_id: String, soul: SoulData, discovery_manager: Node) -> void:
	var disc_log = discovery_manager.get_discovery_log(soul_id)
	var undiscovered_stats = []

	for stat_key in soul.stats.keys():
		if not disc_log.knows_stat(stat_key):
			undiscovered_stats.append(stat_key)

	if undiscovered_stats.size() > 0:
		var stat_key = undiscovered_stats.pick_random()
		discovery_manager.discover_stat(soul_id, stat_key, soul.stats[stat_key])

## Machine 3: Discover random property within 20 points
func _discover_random_stat_narrow_range(soul_id: String, soul: SoulData, discovery_manager: Node) -> void:
	var disc_log = discovery_manager.get_discovery_log(soul_id)
	var undiscovered_stats = []

	for stat_key in soul.stats.keys():
		if not disc_log.knows_stat(stat_key):
			undiscovered_stats.append(stat_key)

	if undiscovered_stats.size() > 0:
		var stat_key = undiscovered_stats.pick_random()
		var actual_value = soul.stats[stat_key]
		var min_range = max(0, actual_value - 10)
		var max_range = min(100, actual_value + 10)
		var hint = "%d-%d" % [int(min_range), int(max_range)]
		discovery_manager.add_stat_hint(soul_id, stat_key, hint)

## Machine 5: Remove 2 possibilities from Era or Cause of Death
func _eliminate_era_or_death_options(soul_id: String, soul: SoulData, discovery_manager: Node) -> void:
	var disc_log = discovery_manager.get_discovery_log(soul_id)

	if randf() < 0.5 and not disc_log.known_era:
		# Eliminate 2 era options
		var all_eras = SoulData.Era.values()
		all_eras.erase(soul.era)  # Don't eliminate the correct one
		all_eras.shuffle()
		for i in range(min(2, all_eras.size())):
			var hint = "Not %s" % SoulData.Era.keys()[all_eras[i]]
			discovery_manager.add_era_hint(soul_id, hint)
	elif not disc_log.known_death:
		# Eliminate 2 death options
		var all_deaths = SoulData.CauseOfDeath.values()
		all_deaths.erase(soul.causeOfDeath)  # Don't eliminate the correct one
		all_deaths.shuffle()
		for i in range(min(2, all_deaths.size())):
			var hint = "Not %s" % SoulData.CauseOfDeath.keys()[all_deaths[i]]
			discovery_manager.add_death_hint(soul_id, hint)

## Machine 6: Discover Era or Cause of Death
func _reveal_era_or_death(soul_id: String, soul: SoulData, discovery_manager: Node) -> void:
	var disc_log = discovery_manager.get_discovery_log(soul_id)

	if randf() < 0.5 and not disc_log.known_era:
		discovery_manager.discover_era(soul_id)
	elif not disc_log.known_death:
		discovery_manager.discover_death(soul_id)
	elif not disc_log.known_era:
		discovery_manager.discover_era(soul_id)
	else:
		discovery_manager.discover_death(soul_id)
