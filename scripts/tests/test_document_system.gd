extends Node
const DocumentFactory = preload("res://scripts/documents/DocumentFactory.gd")

func _ready():
        var data = {
                "type": "personalausweis",
                "name": "Test",
                "vorname": "T",
                "geburtsdatum": "1980-01-01",
                "pkz": "010180123456",
                "gueltig_bis": "1990-01-01"
        }
        var doc = DocumentFactory.from_dict(data)
        assert(doc.get_field("name") == "Test")
        assert(doc.is_valid())
        print("Document system ok")
        get_tree().quit()
