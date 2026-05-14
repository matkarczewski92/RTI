extends Control

@onready var progress_bar = $ProgressBar
@onready var time_label = $TimeLabel
@onready var income_label = $IncomeLabel

func _ready() -> void:
	if EconomySystem.has_signal("income_progress_updated"):
		EconomySystem.income_progress_updated.connect(_on_progress_updated)
	_update_income_label()

func _on_progress_updated(progress: float, time_left: int) -> void:
	if progress_bar:
		progress_bar.value = progress * 100
	if time_label:
		time_label.text = LocalizationSystem.translate("income.in_seconds").replace("{seconds}", str(time_left))
	_update_income_label()

func _update_income_label() -> void:
	var total = EconomySystem.get_total_assigned_income_per_min()
	if total > 0:
		income_label.text = LocalizationSystem.translate("income.per_min").replace("{amount}", str(total))
	else:
		income_label.text = LocalizationSystem.translate("income.none")