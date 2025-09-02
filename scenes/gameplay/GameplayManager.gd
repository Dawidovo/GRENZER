extends Control

# UI Elemente
@onready var background = $Background
@onready var document_area = $DocumentArea
@onready var rulebook_panel = $RulebookPanel
@onready var approve_button = $ButtonArea/ApproveButton
@onready var reject_button = $ButtonArea/RejectButton
@onready var traveler_info = $TravelerInfo
@onready var status_info = $StatusInfo

# Core Systems
var validation_engine: ValidationEngine
var traveler_generator: TravelerGenerator
const ValidationEngine = preload("res://scripts/ValidationEngine.gd")
const TravelerGenerator = preload("res://scripts/TravelerGenerator.gd")
const DocumentFactory = preload("res://scripts/documents/DocumentFactory.gd")

# Game State
var current_traveler = {}
var day_counter = 1
var approved_count = 0
var rejected_count = 0
var mistakes_count = 0
var current_traveler_index = 0
var daily_quota = 10
var daily_travelers_processed = 0

# Game Statistics
var game_stats = {
	"total_processed": 0,
	"correct_decisions": 0,
	"incorrect_decisions": 0,
	"accuracy_rate": 100.0,
	"detained": 0,
	"special_cases_handled": 0
}

# Difficulty progression
var difficulty_settings = {
	1: {"quota": 10, "valid_ratio": 0.8, "use_predefined": true},
	2: {"quota": 12, "valid_ratio": 0.7, "use_predefined": true},
	3: {"quota": 15, "valid_ratio": 0.6, "use_predefined": false},
	4: {"quota": 18, "valid_ratio": 0.5, "use_predefined": false},
	5: {"quota": 20, "valid_ratio": 0.4, "use_predefined": false}
}

func _ready():
	print("=== DDR GRENZPOSTEN SIMULATOR ===")
	print("Tag %d beginnt..." % day_counter)
	
	# Initialize systems
	validation_engine = ValidationEngine.new()
	traveler_generator = TravelerGenerator.new()
	
	# Set initial rules for day 1
	validation_engine.update_rules_for_day(day_counter)
	
	# Setup UI
	await get_tree().process_frame
	setup_ui()
	
	# Start game
	start_new_day()
	
	# Connect button signals
	approve_button.pressed.connect(_on_approve_pressed)
	reject_button.pressed.connect(_on_reject_pressed)

func setup_ui():
	# Fullscreen UI
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Background
	background.color = Color(0.2, 0.3, 0.2, 1.0)  # DDR Green
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Document area
	document_area.position = Vector2(50, 100)
	document_area.size = Vector2(400, 400)
	
	# Rulebook panel
	rulebook_panel.position = Vector2(500, 50)
	rulebook_panel.size = Vector2(300, 400)
	
	# Buttons
	approve_button.text = "GENEHMIGEN"
	approve_button.position = Vector2(100, 520)
	approve_button.size = Vector2(120, 50)
	approve_button.modulate = Color(0.2, 0.8, 0.2)  # Green
	
	reject_button.text = "ABLEHNEN"
	reject_button.position = Vector2(280, 520)
	reject_button.size = Vector2(120, 50)
	reject_button.modulate = Color(0.8, 0.2, 0.2)  # Red
	
	# Info labels
	traveler_info.position = Vector2(50, 20)
	traveler_info.size = Vector2(400, 70)
	traveler_info.add_theme_font_size_override("font_size", 14)
	
	status_info.position = Vector2(500, 470)
	status_info.size = Vector2(300, 60)
	status_info.add_theme_font_size_override("font_size", 12)
	
	# Create rulebook
	create_rulebook()
	
	# Create document display area
	create_document_display()

func create_rulebook():
	# Clear existing children
	for child in rulebook_panel.get_children():
		child.queue_free()
	
	var rules_label = Label.new()
	rules_label.text = _get_current_rules_text()
	rules_label.position = Vector2(10, 10)
	rules_label.size = Vector2(280, 380)
	rules_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules_label.name = "RulesLabel"
	rules_label.add_theme_font_size_override("font_size", 11)
	rulebook_panel.add_child(rules_label)

func create_document_display():
	# Clear existing documents
	for child in document_area.get_children():
		child.queue_free()
	
	# Title
	var title = Label.new()
	title.text = "DOKUMENTE"
	title.position = Vector2(10, 10)
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	document_area.add_child(title)
	
	# Document content area
	var doc_content = RichTextLabel.new()
	doc_content.name = "DocumentContent"
	doc_content.position = Vector2(10, 40)
	doc_content.size = Vector2(380, 350)
	doc_content.bbcode_enabled = true
	document_area.add_child(doc_content)

func _get_current_rules_text() -> String:
	var text = "[b]GRENZBESTIMMUNGEN DDR[/b]\n"
	text += "TAG %d - SCHICHT %02d:00\n\n" % [day_counter, 8 + (daily_travelers_processed / 2)]
	text += "[b]AKTIVE KONTROLLEN:[/b]\n"
	text += "• Dokumentengültigkeit prüfen\n"
	
	if day_counter >= 3:
		text += "• Foto-Vergleich durchführen\n"
	if day_counter >= 5:
		text += "• PKZ kontrollieren\n"
	if day_counter >= 7:
		text += "• Stempel prüfen\n"
	if day_counter >= 10:
		text += "• PM-12 Vermerk beachten\n"
	
	text += "\n[b]BESONDERE HINWEISE:[/b]\n"
	text += "• Polen: Visum erforderlich\n"
	text += "• BRD: Transitvisum prüfen\n"
	text += "• Fahndungsliste beachten\n"
	text += "• Bei Fluchtgefahr: FESTHALTEN\n"
	
	text += "\n[b]TAGESQUOTA:[/b] %d/%d\n" % [daily_travelers_processed, daily_quota]
	text += "[b]FEHLERQUOTE:[/b] %d\n" % mistakes_count
	
	if mistakes_count > 3:
		text += "\n[color=red]WARNUNG: Zu viele Fehler![/color]"
	
	return text

func start_new_day():
	print("\n=== TAG %d BEGINNT ===" % day_counter)
	
	# Reset daily counters
	daily_travelers_processed = 0
	current_traveler_index = 0
	mistakes_count = 0
	
	# Get difficulty settings
	var settings = difficulty_settings.get(day_counter, difficulty_settings[5])
	daily_quota = settings.quota
	
	# Update validation rules
	validation_engine.update_rules_for_day(day_counter)
	
	# Update UI
	update_status_display()
	
	# Load first traveler
	load_next_traveler()

func load_next_traveler():
	if daily_travelers_processed >= daily_quota:
		end_day()
		return
	
	# Generate traveler based on difficulty
	var settings = difficulty_settings.get(day_counter, difficulty_settings[5])
	
	if settings.use_predefined and daily_travelers_processed < 5:
		# Use predefined travelers for first few of early days
		current_traveler = traveler_generator.get_random_predefined_traveler()
	else:
		# Generate based on difficulty ratio
		var profile = "valid" if randf() < settings.valid_ratio else "invalid"
		if randf() < 0.1:  # 10% chance for edge case
			profile = "edge_case"
		current_traveler = traveler_generator.generate_traveler(profile, day_counter)
	
	daily_travelers_processed += 1
	update_traveler_display()
	update_document_display()

func update_traveler_display():
	var info_text = "[b]REISENDER #%d[/b]\n" % daily_travelers_processed
	info_text += "Name: %s, %s\n" % [
		current_traveler.get("name", "Unbekannt"),
		current_traveler.get("vorname", "")
	]
	info_text += "Alter: %d Jahre | Nationalität: %s\n" % [
		current_traveler.get("age", 0),
		current_traveler.get("nationality", "Unbekannt")
	]
	info_text += "Reisezweck: %s | Richtung: %s" % [
		current_traveler.get("purpose", "Unbekannt"),
		current_traveler.get("direction", "unbekannt")
	]
	
	traveler_info.text = info_text
	update_status_display()

func update_document_display():
	var doc_content = document_area.get_node("DocumentContent")
	if not doc_content:
		return
	
	var text = ""
	
	for doc in current_traveler.get("documents", []):
		text += "[b]%s[/b]\n" % doc.get("type", "Unbekannt").to_upper()
		text += "[color=#cccccc]"
		
		# Display relevant fields based on document type
		match doc.get("type", ""):
			"personalausweis":
				text += "Name: %s, %s\n" % [doc.get("name", ""), doc.get("vorname", "")]
				text += "Geboren: %s\n" % doc.get("geburtsdatum", "")
				text += "PKZ: %s\n" % doc.get("pkz", "")
				text += "Gültig bis: %s\n" % doc.get("gueltig_bis", "")
				if doc.get("pm12_vermerk", false):
					text += "[color=red]PM-12 VERMERK[/color]\n"
			"reisepass":
				text += "Name: %s, %s\n" % [doc.get("name", ""), doc.get("vorname", "")]
				text += "Pass-Nr: %s\n" % doc.get("passnummer", "")
				text += "Gültig bis: %s\n" % doc.get("gueltig_bis", "")
			"ausreisegenehmigung":
				text += "Für: %s, %s\n" % [doc.get("name", ""), doc.get("vorname", "")]
				text += "Grund: %s\n" % doc.get("reisegrund", "")
				text += "Gültig bis: %s\n" % doc.get("gueltig_bis", "")
			"visum":
				text += "Inhaber: %s\n" % doc.get("holder_name", "")
				text += "Typ: %s\n" % doc.get("visa_type", "")
				text += "Gültig bis: %s\n" % doc.get("valid_until", "")
			"transitvisum":
				text += "Inhaber: %s\n" % doc.get("holder_name", "")
				text += "Route: %s\n" % doc.get("route_restriction", "")
				text += "Gültig bis: %s\n" % doc.get("valid_until", "")
		
		text += "[/color]\n"
	
	# Add story/observation
	if current_traveler.has("story"):
		text += "\n[i]Beobachtung: %s[/i]" % current_traveler.story
	
	doc_content.text = text

func update_status_display():
	var accuracy = 100.0
	if game_stats.total_processed > 0:
		accuracy = (game_stats.correct_decisions * 100.0) / game_stats.total_processed
	
	var text = "Tag %d | Bearbeitet: %d/%d\n" % [day_counter, daily_travelers_processed, daily_quota]
	text += "Genehmigt: %d | Abgelehnt: %d | Fehler: %d\n" % [approved_count, rejected_count, mistakes_count]
	text += "Genauigkeit: %.1f%%" % accuracy
	
	status_info.text = text

func _on_approve_pressed():
	process_decision(true)

func _on_reject_pressed():
	process_decision(false)

func process_decision(approved: bool):
	game_stats.total_processed += 1
	
	# Validate the traveler
	var validation_result = validation_engine.validate_traveler(
		current_traveler, 
		current_traveler.get("documents", [])
	)
	
	var correct_decision = false
	var feedback_message = ""
	var feedback_color = Color.WHITE
	
	if approved:
		approved_count += 1
		if validation_result.is_valid:
			# Correct approval
			correct_decision = true
			feedback_message = "✓ Korrekt! Dokumente gültig."
			feedback_color = Color.GREEN
			game_stats.correct_decisions += 1
		else:
			# Incorrect approval
			mistakes_count += 1
			var reason = validation_engine.get_denial_reason_text(
				validation_result.violations[0].code
			)
			feedback_message = "✗ FEHLER! %s übersehen!" % reason
			feedback_color = Color.RED
			game_stats.incorrect_decisions += 1
	else:
		rejected_count += 1
		if not validation_result.is_valid:
			# Correct rejection
			correct_decision = true
			var reasons = ""
			for violation in validation_result.violations:
				reasons += validation_engine.get_denial_reason_text(violation.code) + ", "
			feedback_message = "✓ Korrekt abgelehnt! Grund: %s" % reasons.trim_suffix(", ")
			feedback_color = Color.GREEN
			game_stats.correct_decisions += 1
		else:
			# Incorrect rejection
			mistakes_count += 1
			feedback_message = "✗ FEHLER! Gültige Dokumente abgelehnt!"
			feedback_color = Color.RED
			game_stats.incorrect_decisions += 1
	
	# Check for special cases
	if current_traveler.get("on_watchlist", false):
		if not approved:
			feedback_message += "\n[Fahndungsliste erkannt!]"
			game_stats.special_cases_handled += 1
	
	if current_traveler.get("diplomatic_status", false):
		if approved:
			feedback_message += "\n[Diplomatische Immunität respektiert]"
			game_stats.special_cases_handled += 1
	
	# Show feedback
	show_feedback(feedback_message, feedback_color)
	
	# Continue after delay
	await get_tree().create_timer(2.0).timeout
	next_traveler()

func show_feedback(message: String, color: Color):
	# Create feedback popup
	var feedback = Label.new()
	feedback.text = message
	feedback.modulate = color
	feedback.position = Vector2(250, 300)
	feedback.size = Vector2(300, 100)
	feedback.add_theme_font_size_override("font_size", 16)
	add_child(feedback)
	
	# Remove after delay
	await get_tree().create_timer(2.0).timeout
	feedback.queue_free()

func next_traveler():
	current_traveler_index += 1
	load_next_traveler()

func end_day():
	print("\n=== TAG %d BEENDET ===" % day_counter)
	
	var accuracy = 100.0
	if daily_travelers_processed > 0:
		accuracy = ((daily_travelers_processed - mistakes_count) * 100.0) / daily_travelers_processed
	
	# Show day summary
	var summary = "TAG %d ABGESCHLOSSEN\n\n" % day_counter
	summary += "Bearbeitet: %d Reisende\n" % daily_travelers_processed
	summary += "Genehmigt: %d\n" % approved_count
	summary += "Abgelehnt: %d\n" % rejected_count
	summary += "Fehler: %d\n" % mistakes_count
	summary += "Genauigkeit: %.1f%%\n\n" % accuracy
	
	if mistakes_count <= 2:
		summary += "Ausgezeichnete Arbeit, Genosse!"
	elif mistakes_count <= 4:
		summary += "Akzeptable Leistung."
	else:
		summary += "Mehr Aufmerksamkeit erforderlich!"
	
	traveler_info.text = summary
	
	# Disable buttons temporarily
	approve_button.disabled = true
	reject_button.disabled = true
	
	# Prepare next day
	await get_tree().create_timer(3.0).timeout
	
	day_counter += 1
	if day_counter > 5:
		show_game_over()
	else:
		# Reset for new day
		approved_count = 0
		rejected_count = 0
		approve_button.disabled = false
		reject_button.disabled = false
		
		# Update rulebook
		var rules_label = rulebook_panel.get_node("RulesLabel")
		if rules_label:
			rules_label.text = _get_current_rules_text()
		
		start_new_day()

func show_game_over():
	var final_accuracy = 100.0
	if game_stats.total_processed > 0:
		final_accuracy = (game_stats.correct_decisions * 100.0) / game_stats.total_processed
	
	var ending_text = "=== SPIEL BEENDET ===\n\n"
	ending_text += "Gesamtstatistik:\n"
	ending_text += "Tage gearbeitet: 5\n"
	ending_text += "Reisende bearbeitet: %d\n" % game_stats.total_processed
	ending_text += "Korrekte Entscheidungen: %d\n" % game_stats.correct_decisions
	ending_text += "Fehler: %d\n" % game_stats.incorrect_decisions
	ending_text += "Genauigkeit: %.1f%%\n" % final_accuracy
	ending_text += "Spezialfälle: %d\n\n" % game_stats.special_cases_handled
	
	if final_accuracy >= 90:
		ending_text += "AUSZEICHNUNG: Vorbildlicher Grenzbeamter!"
	elif final_accuracy >= 75:
		ending_text += "BEWERTUNG: Zufriedenstellende Leistung"
	elif final_accuracy >= 60:
		ending_text += "BEWERTUNG: Verbesserung erforderlich"
	else:
		ending_text += "BEWERTUNG: Unzureichend - Nachschulung erforderlich"
	
	traveler_info.text = ending_text
	print(ending_text)
