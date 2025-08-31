extends Control

# UI Elemente
@onready var background = $Background
@onready var document_area = $DocumentArea
@onready var rulebook_panel = $RulebookPanel
@onready var approve_button = $ButtonArea/ApproveButton
@onready var reject_button = $ButtonArea/RejectButton
@onready var traveler_info = $TravelerInfo
@onready var status_info = $StatusInfo

# Spiel-Daten
var current_traveler = {}
var day_counter = 1
var approved_count = 0
var rejected_count = 0

# DDR Reisende Datenbank
var travelers_database = [
	{
		"name": "Hans Mueller",
		"age": 34,
		"nationality": "DDR",
		"purpose": "Besuch bei Familie",
		"documents_valid": true,
		"story": "Möchte seine Schwester in West-Berlin besuchen."
	},
	{
		"name": "Maria Schmidt", 
		"age": 28,
		"nationality": "Polen",
		"purpose": "Durchreise",
		"documents_valid": false,
		"story": "Reisepass abgelaufen seit 2 Monaten."
	},
	{
		"name": "Klaus Weber",
		"age": 45, 
		"nationality": "DDR",
		"purpose": "Geschäftsreise",
		"documents_valid": true,
		"story": "Staatlich genehmigte Dienstreise nach Moskau."
	}
]

var current_traveler_index = 0

func _ready():
	print("DDR Grenzposten bereit!")
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
	rules_label.text = "GRENZBESTIMMUNGEN DDR\n\n• Gültige Dokumente erforderlich\n• Polen: Visum kontrollieren\n• Geschäftsreisen: Genehmigung prüfen\n• Verdächtige Personen melden\n• Fluchtgefahr beachten"
	rules_label.position = Vector2(10, 10)
	rules_label.size = Vector2(280, 380)
	rules_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rulebook_panel.add_child(rules_label)

func load_next_traveler():
	if current_traveler_index >= travelers_database.size():
		end_day()
		return
	
	current_traveler = travelers_database[current_traveler_index]
	update_traveler_display()

func update_traveler_display():
	var info_text = "Reisender: %s (%d Jahre)\nNationalität: %s\nZweck: %s" % [
		current_traveler.name,
		current_traveler.age, 
		current_traveler.nationality,
		current_traveler.purpose
	]
	traveler_info.text = info_text
	update_status_display()

func update_status_display():
	status_info.text = "Tag %d | Genehmigt: %d | Abgelehnt: %d" % [day_counter, approved_count, rejected_count]

func _on_approve_pressed():
	print("GENEHMIGT: " + current_traveler.name)
	
	if current_traveler.documents_valid:
		approved_count += 1
		show_feedback("Richtige Entscheidung!", Color.GREEN)
	else:
		show_feedback("FEHLER! Ungültige Dokumente übersehen!", Color.RED)
	
	next_traveler()

func _on_reject_pressed():
	print("ABGELEHNT: " + current_traveler.name)
	
	if not current_traveler.documents_valid:
		rejected_count += 1
		show_feedback("Richtige Entscheidung!", Color.GREEN)
	else:
		show_feedback("FEHLER! Gültige Dokumente abgelehnt!", Color.RED)
	
	next_traveler()

func show_feedback(message: String, color: Color):
	print("Feedback: " + message)
	# Einfaches Feedback ohne Tween
	var temp_status = status_info.text
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
