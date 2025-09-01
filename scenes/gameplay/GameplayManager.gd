extends Control

# UI Elemente
@onready var background = $Background
@onready var document_area = $DocumentArea
@onready var rulebook_panel = $RulebookPanel
@onready var approve_button = $ButtonArea/ApproveButton
@onready var reject_button = $ButtonArea/RejectButton
@onready var traveler_info = $TravelerInfo
@onready var status_info = $StatusInfo

# NEU: Validation Engine
var validation_engine: ValidationEngine
var DocumentFactory = preload("res://scripts/documents/DocumentFactory.gd")

# Spiel-Daten
var current_traveler = {}
var day_counter = 1
var approved_count = 0
var rejected_count = 0
var current_traveler_index = 0

# ERWEITERTE DDR Reisende Datenbank (mehr Details hinzugefügt)
var travelers_database = [
	{
		"name": "Mueller",  # GEÄNDERT: Nachname zuerst
		"vorname": "Hans",  # NEU: Vorname separat
		"age": 34,
		"nationality": "DDR",
		"geburtsdatum": "1955-03-15",  # NEU: Für PKZ-Check
		"purpose": "Besuch bei Familie",
		"direction": "ausreise",  # NEU: Ein- oder Ausreise
		"documents_valid": true,
		"story": "Möchte seine Schwester in West-Berlin besuchen.",
		"appearance": {"foto": "photo_001"}  # NEU: Für Foto-Check
	},
	{
		"name": "Schmidt",
		"vorname": "Maria", 
		"age": 28,
		"nationality": "Polen",
		"geburtsdatum": "1961-07-22",
		"purpose": "Durchreise",
		"direction": "einreise",
		"documents_valid": false,
		"story": "Reisepass abgelaufen seit 2 Monaten.",
		"appearance": {"foto": "photo_002"}
	},
	{
		"name": "Weber",
		"vorname": "Klaus",
		"age": 45, 
		"nationality": "DDR",
		"geburtsdatum": "1944-01-10",
		"purpose": "Geschäftsreise",
		"direction": "ausreise",
		"documents_valid": true,
		"story": "Staatlich genehmigte Dienstreise nach Moskau.",
		"appearance": {"foto": "photo_003"}
	},
	{
		# NEU: Fahndungslisten-Test
		"name": "Schmidt",
		"vorname": "Werner",
		"age": 31,
		"nationality": "DDR",
		"geburtsdatum": "1958-05-20",
		"purpose": "Familienbesuch",
		"direction": "ausreise",
		"documents_valid": true,
		"story": "Auf Fahndungsliste wegen Republikfluchtversuch!",
		"appearance": {"foto": "photo_004"}
	}
]

func _ready():
	print("DDR Grenzposten bereit!")
	
	# NEU: ValidationEngine laden
	var ValidationEngineScript = load("res://scripts/ValidationEngine.gd")
	validation_engine = ValidationEngineScript.new()
	validation_engine.update_rules_for_day(day_counter)
	
	# Warten bis alle Nodes geladen sind
	await get_tree().process_frame
	setup_ui()
	load_next_traveler()
	
	# Button Signale verbinden
	approve_button.pressed.connect(_on_approve_pressed)
	reject_button.pressed.connect(_on_reject_pressed)

func setup_ui():
	# Vollbild UI
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Hintergrund
	background.color = Color(0.2, 0.3, 0.2, 1.0)  # DDR-Grün
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Dokument-Bereich
	document_area.position = Vector2(50, 100)
	document_area.size = Vector2(400, 300)
	
	# Regelwerk Panel
	rulebook_panel.position = Vector2(500, 50)
	rulebook_panel.size = Vector2(300, 400)
	
	# Buttons
	approve_button.text = "GENEHMIGEN"
	approve_button.position = Vector2(100, 450)
	approve_button.size = Vector2(120, 50)
	
	reject_button.text = "ABLEHNEN"
	reject_button.position = Vector2(280, 450)
	reject_button.size = Vector2(120, 50)
	
	# Info Labels
	traveler_info.position = Vector2(50, 50)
	traveler_info.size = Vector2(400, 40)
	
	status_info.position = Vector2(500, 470)
	status_info.size = Vector2(300, 30)
	
	# Regelwerk Text erstellen
	create_rulebook()

func create_rulebook():
	var rules_label = Label.new()
	# NEU: Tag-basierte Regeln
	var rules_text = _get_current_rules_text()
	rules_label.text = rules_text
	rules_label.position = Vector2(10, 10)
	rules_label.size = Vector2(280, 380)
	rules_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules_label.name = "RulesLabel"  # NEU: Name für späteren Zugriff
	rulebook_panel.add_child(rules_label)

# NEU: Regeltext basierend auf Tag
func _get_current_rules_text() -> String:
	var text = "GRENZBESTIMMUNGEN DDR - TAG %d\n\n" % day_counter
	text += "• Gültige Dokumente erforderlich\n"
	
	if day_counter >= 3:
		text += "• NEU: Foto-Vergleich durchführen\n"
	if day_counter >= 5:
		text += "• NEU: PKZ kontrollieren\n"
	if day_counter >= 7:
		text += "• NEU: Stempel prüfen\n"
	
	text += "• Polen: Visum kontrollieren\n"
	text += "• Geschäftsreisen: Genehmigung prüfen\n"
	text += "• Verdächtige Personen melden\n"
	text += "• Fluchtgefahr beachten\n"
	text += "\nTagesquota: %d Reisende" % [10 + (day_counter * 2)]
	
	return text

func load_next_traveler():
	if current_traveler_index >= travelers_database.size():
		end_day()
		return
	
	current_traveler = travelers_database[current_traveler_index]
	update_traveler_display()

func update_traveler_display():
	# ERWEITERT: Mehr Details anzeigen
	var info_text = "Reisender: %s, %s (%d Jahre)\n" % [
		current_traveler.get("name", "Unbekannt"),
		current_traveler.get("vorname", ""),
		current_traveler.age
	]
	info_text += "Nationalität: %s\n" % current_traveler.nationality
	info_text += "Zweck: %s\n" % current_traveler.purpose
	info_text += "Richtung: %s" % current_traveler.get("direction", "unbekannt")
	
	traveler_info.text = info_text
	update_status_display()

func update_status_display():
	status_info.text = "Tag %d | Genehmigt: %d | Abgelehnt: %d" % [day_counter, approved_count, rejected_count]

# KOMPLETT NEU: Approve mit ValidationEngine
func _on_approve_pressed():
	print("GENEHMIGT: " + current_traveler.get("name", "Unbekannt"))
	
	# Hole Dokumente und validiere
	var traveler_docs = _get_current_documents()
	var validation_result = validation_engine.validate_traveler(current_traveler, traveler_docs)
	
	if validation_result.is_valid:
		approved_count += 1
		show_feedback("Richtige Entscheidung!", Color.GREEN)
	else:
		# Zeige ersten Fehler
		var violation = validation_result.violations[0]
		var reason = validation_engine.get_denial_reason_text(violation.code)
		show_feedback("FEHLER! " + reason + " übersehen!", Color.RED)
	
	next_traveler()

# KOMPLETT NEU: Reject mit ValidationEngine
func _on_reject_pressed():
	print("ABGELEHNT: " + current_traveler.get("name", "Unbekannt"))
	
	# Hole Dokumente und validiere
	var traveler_docs = _get_current_documents()
	var validation_result = validation_engine.validate_traveler(current_traveler, traveler_docs)
	
	if not validation_result.is_valid:
		rejected_count += 1
		# Bei mehreren Fehlern: Zeige alle
		var reasons = "Ablehnungsgründe:\n"
		for violation in validation_result.violations:
			var reason_text = validation_engine.get_denial_reason_text(violation.code)
			reasons += "• " + reason_text + "\n"
		show_feedback("Korrekt! " + reasons, Color.GREEN)
	else:
		show_feedback("FEHLER! Gültige Dokumente abgelehnt!", Color.RED)
	
	next_traveler()

# NEU: Funktion um Dokumente zu simulieren
func _get_current_documents() -> Array:
	var docs = []
	
	# Basierend auf Nationalität verschiedene Dokumente
	if current_traveler.nationality == "DDR":
                docs.append(DocumentFactory.from_dict({
                        "type": "personalausweis",
                        "name": current_traveler.get("name", "Mueller"),
                        "vorname": current_traveler.get("vorname", "Max"),
                        "geburtsdatum": current_traveler.get("geburtsdatum", "1955-03-15"),
                        "pkz": _generate_pkz(current_traveler.get("geburtsdatum", "1955-03-15")),
                        "gueltig_bis": "1990-12-31" if current_traveler.documents_valid else "1988-01-01",
                        "foto": current_traveler.get("appearance", {}).get("foto", "photo_001"),
                        "pm12_vermerk": false
                }))
	elif current_traveler.nationality == "Polen":
                docs.append(DocumentFactory.from_dict({
                        "type": "reisepass",
                        "name": current_traveler.get("name", "Kowalski"),
                        "vorname": current_traveler.get("vorname", "Jan"),
                        "passnummer": "PL1234567",
                        "gueltig_bis": "1990-12-31" if current_traveler.documents_valid else "1988-01-01",
                        "foto": current_traveler.get("appearance", {}).get("foto", "photo_001")
                }))
		# Polen brauchen auch Visum
		if current_traveler.documents_valid:
                        docs.append(DocumentFactory.from_dict({
                                "type": "visum",
                                "holder_name": current_traveler.get("name", "Kowalski"),
                                "valid_until": "1989-12-31"
                        }))
	else:  # BRD oder andere
                docs.append(DocumentFactory.from_dict({
                        "type": "reisepass",
                        "name": current_traveler.get("name", "Müller"),
                        "vorname": current_traveler.get("vorname", "Hans"),
                        "passnummer": "D1234567",
                        "gueltig_bis": "1990-12-31" if current_traveler.documents_valid else "1988-01-01"
                }))
                if current_traveler.nationality == "BRD":
                        docs.append(DocumentFactory.from_dict({
                                "type": "transitvisum",
                                "holder_name": current_traveler.get("name", "Müller"),
                                "route_restriction": "direct_only"
                        }))
	
	return docs

# NEU: PKZ aus Geburtsdatum generieren
func _generate_pkz(birthdate: String) -> String:
	# Format: DDMMYYXXXXXX
	# birthdate format: YYYY-MM-DD
	var parts = birthdate.split("-")
	if parts.size() == 3:
		var day = parts[2]
		var month = parts[1]
		var year = parts[0].substr(2, 2)  # Nur letzte 2 Ziffern
		return day + month + year + "123456"  # Rest ist Dummy
	return "010170123456"  # Fallback

func show_feedback(message: String, color: Color):
	print("Feedback: " + message)
	status_info.text = message
	status_info.modulate = color
	
	# Timer für Feedback
	await get_tree().create_timer(2.0).timeout
	status_info.modulate = Color.WHITE
	update_status_display()

func next_traveler():
	current_traveler_index += 1
	load_next_traveler()

func end_day():
	print("Tag beendet!")
	traveler_info.text = "TAG BEENDET\n\nGenehmigt: %d\nAbgelehnt: %d" % [approved_count, rejected_count]
	approve_button.disabled = true
	reject_button.disabled = true
	
	# NEU: Option für nächsten Tag
	await get_tree().create_timer(3.0).timeout
	_start_new_day()

# NEU: Nächster Tag
func _start_new_day():
	day_counter += 1
	if day_counter > 5:  # Nur 5 Tage für MVP
		traveler_info.text = "SPIEL BEENDET!\n\nGlückwunsch!"
		return
	
	# Reset für neuen Tag
	current_traveler_index = 0
	approved_count = 0
	rejected_count = 0
	
	# Update Regeln
	validation_engine.update_rules_for_day(day_counter)
	
	# Update UI
	approve_button.disabled = false
	reject_button.disabled = false
	
	# Update Regelwerk
	var rules_label = rulebook_panel.get_node("RulesLabel")
	if rules_label:
		rules_label.text = _get_current_rules_text()
	
	# Lade ersten Reisenden
	load_next_traveler()
