# PM12.gd
extends Document
class_name DDRPM12

func _init(data: Dictionary = {}):
	type = "pm12"
	required_fields = ["name", "vorname", "issued_on"]
	super._init(data)
