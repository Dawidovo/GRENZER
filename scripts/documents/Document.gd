extends Reference
class_name Document

var type: String = ""
var fields: Dictionary = {}
var required_fields: Array = []

func _init(data: Dictionary = {}):
        fields = data.duplicate()

func get_field(name: String):
        return fields.get(name)

func to_dict() -> Dictionary:
        var d = fields.duplicate()
        d["type"] = type
        return d

func is_valid() -> bool:
        for f in required_fields:
                if not fields.has(f) or fields[f] == null:
                        return false
        return true
