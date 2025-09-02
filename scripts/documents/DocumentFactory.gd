extends Object
class_name DocumentFactory
const DDRPersonalausweis = preload("res://scripts/documents/Personalausweis.gd")
const DDRReisepass = preload("res://scripts/documents/Reisepass.gd")
const DDRPM12 = preload("res://scripts/documents/PM12.gd")
const DDRAusreisegenehmigung = preload("res://scripts/documents/Ausreisegenehmigung.gd")
const Document = preload("res://scripts/documents/Document.gd")

static func from_dict(data: Dictionary) -> Document:
	var doc_type = data.get("type", "")
	match doc_type:
		"personalausweis":
			return DDRPersonalausweis.new(data)
		"reisepass":
			return DDRReisepass.new(data)
		"pm12":
			return DDRPM12.new(data)
		"ausreisegenehmigung":
			return DDRAusreisegenehmigung.new(data)
		_:
			return Document.new(data)
