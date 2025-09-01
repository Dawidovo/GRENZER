extends Document
class_name Personalausweis

func _init(data: Dictionary = {}):
        type = "personalausweis"
        required_fields = ["name", "vorname", "geburtsdatum", "pkz", "gueltig_bis"]
        Document._init(data)
