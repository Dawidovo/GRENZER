extends Document
class_name PM12

func _init(data: Dictionary = {}):
        type = "pm12"
        required_fields = ["name", "vorname", "issued_on"]
        Document._init(data)
