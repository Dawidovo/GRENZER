# Personalausweis.gd
extends Document
class_name DDRPersonalausweis

func _init(data: Dictionary = {}):
	type = "personalausweis"
	required_fields = ["name", "vorname", "geburtsdatum", "pkz", "gueltig_bis"]
	super._init(data)
