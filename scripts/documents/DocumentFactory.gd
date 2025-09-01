extends Object
class_name DocumentFactory
const Personalausweis = preload("res://scripts/documents/Personalausweis.gd")
const Reisepass = preload("res://scripts/documents/Reisepass.gd")
const PM12 = preload("res://scripts/documents/PM12.gd")
const Ausreisegenehmigung = preload("res://scripts/documents/Ausreisegenehmigung.gd")
const Document = preload("res://scripts/documents/Document.gd")

static func from_dict(data: Dictionary) -> Document:
		var doc_type = data.get("type", "")
		match doc_type:
				"personalausweis":
						return Personalausweis.new(data)
				"reisepass":
						return Reisepass.new(data)
				"pm12":
						return PM12.new(data)
				"ausreisegenehmigung":
						return Ausreisegenehmigung.new(data)
				_:
						return Document.new(data)
