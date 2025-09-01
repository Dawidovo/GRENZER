# Ausreisegenehmigung.gd
extends Document
class_name Ausreisegenehmigung

func _init(data: Dictionary = {}):
	type = "ausreisegenehmigung"
	required_fields = ["name", "vorname", "gueltig_bis"]
	super._init(data)
