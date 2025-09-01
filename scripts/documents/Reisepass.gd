# Reisepass.gd
extends Document
class_name Reisepass

func _init(data: Dictionary = {}):
	type = "reisepass"
	required_fields = ["name", "vorname", "passnummer", "gueltig_bis"]
	super._init(data)
