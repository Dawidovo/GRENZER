extends Control

# === SIMPLE NODE PATHS ===
@onready var traveler_info: RichTextLabel = $MainContainer/ContentContainer/LeftSide/TravelerPanel/TravelerInfo
@onready var document_container: VBoxContainer = $MainContainer/ContentContainer/LeftSide/DocumentPanel/DocumentScroll/DocumentArea
@onready var approve_button: Button = $MainContainer/ButtonContainer/ApproveButton
@onready var reject_button: Button = $MainContainer/ButtonContainer/RejectButton
@onready var rules_text: RichTextLabel = $MainContainer/ContentContainer/RightSide/RulesPanel/RulesText
@onready var status_info: RichTextLabel = $MainContainer/ContentContainer/RightSide/StatusPanel/StatusInfo
@onready var feedback_overlay: Control = $FeedbackOverlay
@onready var feedback_message: RichTextLabel = $FeedbackOverlay/FeedbackPanel/FeedbackContent/FeedbackMessage
@onready var feedback_title: Label = $FeedbackOverlay/FeedbackPanel/FeedbackContent/FeedbackTitle

# Panel references for styling
@onready var traveler_panel: Panel = $MainContainer/ContentContainer/LeftSide/TravelerPanel
@onready var document_panel: Panel = $MainContainer/ContentContainer/LeftSide/DocumentPanel
@onready var rules_panel: Panel = $MainContainer/ContentContainer/RightSide/RulesPanel
@onready var status_panel: Panel = $MainContainer/ContentContainer/RightSide/StatusPanel
@onready var feedback_panel: Panel = $FeedbackOverlay/FeedbackPanel

# Core Systems
var validation_engine: ValidationEngine
var traveler_generator: TravelerGenerator
const ValidationEngine = preload("res://scripts/ValidationEngine.gd")
const TravelerGenerator = preload("res://scripts/TravelerGenerator.gd")

# Game State
var current_traveler = {}
var day_counter = 1
var approved_count = 0
var rejected_count = 0
var mistakes_count = 0
var daily_quota = 10
var daily_travelers_processed = 0

# Game Statistics
var game_stats = {
	"total_processed": 0,
	"correct_decisions": 0,
	"incorrect_decisions": 0
}

# Document UI instances
var document_panels: Array[Control] = []

func _ready():
	print("\n" + "=".repeat(50))
	print("DDR GRENZPOSTEN SIMULATOR - STARTING")
	print("=".repeat(50))
	
	# Initialize systems
	validation_engine = ValidationEngine.new()
	traveler_generator = TravelerGenerator.new()
	validation_engine.update_rules_for_day(day_counter)
	
	# Wait for nodes to be ready
	await get_tree().process_frame
	
	# Test all UI nodes
	print("\n--- UI NODE VERIFICATION ---")
	test_ui_nodes()
	
	# Setup styling
	setup_panel_styling()
	setup_button_styling()
	
	# Connect signals
	if approve_button:
		approve_button.pressed.connect(_on_approve_pressed)
		print("✓ Approve button connected")
	if reject_button:
		reject_button.pressed.connect(_on_reject_pressed)
		print("✓ Reject button connected")
	
	# Start the game
	print("\n--- STARTING GAME ---")
	start_game()

func test_ui_nodes():
	print("Checking traveler_info: ", traveler_info != null)
	print("Checking document_container: ", document_container != null)
	print("Checking approve_button: ", approve_button != null)
	print("Checking reject_button: ", reject_button != null)
	print("Checking rules_text: ", rules_text != null)
	print("Checking status_info: ", status_info != null)
	print("Checking feedback_overlay: ", feedback_overlay != null)
	print("Checking feedback_message: ", feedback_message != null)
	print("Checking feedback_title: ", feedback_title != null)

func setup_panel_styling():
	# Traveler panel - light beige
	if traveler_panel:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.95, 0.95, 0.9, 1.0)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.7, 0.7, 0.6, 1.0)
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		traveler_panel.add_theme_stylebox_override("panel", style)
	
	# Document panel - light blue
	if document_panel:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.9, 0.95, 1.0, 1.0)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.6, 0.7, 0.9, 1.0)
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		document_panel.add_theme_stylebox_override("panel", style)
	
	# Rules panel - light orange
	if rules_panel:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(1.0, 0.95, 0.9, 1.0)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.9, 0.7, 0.6, 1.0)
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		rules_panel.add_theme_stylebox_override("panel", style)
	
	# Status panel - light green
	if status_panel:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.9, 1.0, 0.9, 1.0)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.6, 0.9, 0.6, 1.0)
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		status_panel.add_theme_stylebox_override("panel", style)
	
	# Feedback panel - white
	if feedback_panel:
		var style = StyleBoxFlat.new()
		style.bg_color = Color.WHITE
		style.border_width_left = 3
		style.border_width_right = 3
		style.border_width_top = 3
		style.border_width_bottom = 3
		style.border_color = Color(0.2, 0.2, 0.2, 1.0)
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_left = 12
		style.corner_radius_bottom_right = 12
		feedback_panel.add_theme_stylebox_override("panel", style)

func setup_button_styling():
	if approve_button:
		# Green approve button
		var approve_style = StyleBoxFlat.new()
		approve_style.bg_color = Color(0.2, 0.8, 0.2, 1.0)
		approve_style.border_width_left = 3
		approve_style.border_width_right = 3
		approve_style.border_width_top = 3
		approve_style.border_width_bottom = 3
		approve_style.border_color = Color(0.1, 0.6, 0.1, 1.0)
		approve_style.corner_radius_top_left = 8
		approve_style.corner_radius_top_right = 8
		approve_style.corner_radius_bottom_left = 8
		approve_style.corner_radius_bottom_right = 8
		approve_button.add_theme_stylebox_override("normal", approve_style)
		approve_button.add_theme_color_override("font_color", Color.WHITE)
		
		# Hover effect
		var approve_hover = approve_style.duplicate()
		approve_hover.bg_color = Color(0.1, 0.9, 0.1, 1.0)
		approve_button.add_theme_stylebox_override("hover", approve_hover)
	
	if reject_button:
		# Red reject button
		var reject_style = StyleBoxFlat.new()
		reject_style.bg_color = Color(0.8, 0.2, 0.2, 1.0)
		reject_style.border_width_left = 3
		reject_style.border_width_right = 3
		reject_style.border_width_top = 3
		reject_style.border_width_bottom = 3
		reject_style.border_color = Color(0.6, 0.1, 0.1, 1.0)
		reject_style.corner_radius_top_left = 8
		reject_style.corner_radius_top_right = 8
		reject_style.corner_radius_bottom_left = 8
		reject_style.corner_radius_bottom_right = 8
		reject_button.add_theme_stylebox_override("normal", reject_style)
		reject_button.add_theme_color_override("font_color", Color.WHITE)
		
		# Hover effect
		var reject_hover = reject_style.duplicate()
		reject_hover.bg_color = Color(0.9, 0.1, 0.1, 1.0)
		reject_button.add_theme_stylebox_override("hover", reject_hover)

func start_game():
	print("\n=== STARTING DAY ", day_counter, " ===")
	daily_travelers_processed = 0
	
	# Update UI first
	update_rules_display()
	update_status_display()
	
	# Load first traveler
	load_next_traveler()

func load_next_traveler():
	print("\n--- LOADING TRAVELER ", daily_travelers_processed + 1, " ---")
	
	if daily_travelers_processed >= daily_quota:
		print("Daily quota reached!")
		end_day()
		return
	
	# Clear old documents
	clear_documents()
	
	# Generate new traveler
	print("Generating traveler...")
	current_traveler = traveler_generator.get_random_predefined_traveler()
	
	if current_traveler.is_empty():
		print("ERROR: No traveler generated! Using fallback...")
		current_traveler = create_fallback_traveler()
	
	daily_travelers_processed += 1
	
	print("Traveler loaded: ", current_traveler.get("name", "Unknown"))
	print("Documents: ", current_traveler.get("documents", []).size())
	
	# Update displays
	update_traveler_display()
	create_document_display()
	update_status_display()

func create_fallback_traveler() -> Dictionary:
	return {
		"name": "Mueller",
		"vorname": "Hans", 
		"age": 45,
		"nationality": "DDR",
		"purpose": "Familienbesuch",
		"direction": "ausreise",
		"story": "Standard DDR Buerger mit allen gültigen Dokumenten",
		"documents": [
			{
				"type": "personalausweis",
				"name": "Mueller",
				"vorname": "Hans",
				"geburtsdatum": "1944-03-15",
				"pkz": "150344123456",
				"gueltig_bis": "1990-12-31"
			}
		]
	}

func update_traveler_display():
	if not traveler_info:
		print("ERROR: traveler_info not found!")
		return
	
	print("Updating traveler display...")
	
	var text = "[center][b][font_size=20]REISENDER #%d[/font_size][/b][/center]\n\n" % daily_travelers_processed
	text += "[b]Name:[/b] %s, %s\n" % [current_traveler.get("name", "?"), current_traveler.get("vorname", "?")]
	text += "[b]Alter:[/b] %d Jahre\n" % current_traveler.get("age", 0)
	text += "[b]Nationalitaet:[/b] [color=%s]%s[/color]\n" % [get_nationality_color(current_traveler.get("nationality", "")), current_traveler.get("nationality", "?")]
	text += "[b]Zweck:[/b] %s\n" % current_traveler.get("purpose", "?")
	text += "[b]Richtung:[/b] [color=%s]%s[/color]\n\n" % [get_direction_color(current_traveler.get("direction", "")), current_traveler.get("direction", "?").to_upper()]
	
	if current_traveler.has("story"):
		text += "[i]Beobachtung:[/i]\n%s" % current_traveler.story
	
	traveler_info.text = text
	print("Traveler display updated!")

func get_nationality_color(nationality: String) -> String:
	match nationality:
		"DDR": return "red"
		"Polen": return "blue"
		"BRD": return "green"
		"UdSSR": return "purple"
		_: return "gray"

func get_direction_color(direction: String) -> String:
	match direction:
		"ausreise": return "red"
		"einreise": return "green"
		_: return "gray"

func create_document_display():
	if not document_container:
		print("ERROR: document_container not found!")
		return
	
	print("Creating document display...")
	
	var documents = current_traveler.get("documents", [])
	print("Number of documents to display: ", documents.size())
	
	if documents.is_empty():
		print("No documents - creating placeholder")
		var panel = create_no_documents_panel()
		document_container.add_child(panel)
		document_panels.append(panel)
		return
	
	# Create document panels with simple animation
	for i in range(documents.size()):
		var doc = documents[i]
		print("Creating panel for document ", i, ": ", doc.get("type", "unknown"))
		
		var panel = create_document_panel(doc)
		document_container.add_child(panel)
		document_panels.append(panel)
		
		# Simple animation
		panel.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(panel, "modulate:a", 1.0, 0.3)

func create_no_documents_panel() -> Control:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(300, 100)
	
	# Error styling
	var style = StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.9, 0.9, 1.0)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color.RED
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	panel.add_theme_stylebox_override("panel", style)
	
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.text = "[center][color=red][b]KEINE DOKUMENTE[/b][/color][/center]"
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 10
	label.offset_top = 10
	label.offset_right = -10
	label.offset_bottom = -10
	
	panel.add_child(label)
	return panel

func create_document_panel(doc_data: Dictionary) -> Control:
	print("Creating document panel for: ", doc_data.get("type", "unknown"))
	
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(300, 200)
	
	# Document type styling
	var bg_color = get_document_bg_color(doc_data.get("type", ""))
	var border_color = get_document_border_color(doc_data.get("type", ""))
	
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = border_color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)
	
	# Create content
	var content = RichTextLabel.new()
	content.bbcode_enabled = true
	content.scroll_active = true
	
	# Set anchors to fill panel with margins
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 15
	content.offset_top = 15
	content.offset_right = -15
	content.offset_bottom = -15
	
	# Build document text
	var text = get_document_content(doc_data)
	content.text = text
	panel.add_child(content)
	
	print("Document panel created successfully")
	return panel

func get_document_bg_color(doc_type: String) -> Color:
	match doc_type:
		"personalausweis": return Color(1.0, 0.98, 0.94, 1.0)
		"reisepass": return Color(0.94, 0.98, 1.0, 1.0)
		"ausreisegenehmigung": return Color(0.98, 1.0, 0.94, 1.0)
		"visum": return Color(1.0, 0.94, 0.98, 1.0)
		"transitvisum": return Color(0.98, 0.94, 1.0, 1.0)
		_: return Color(0.98, 0.98, 0.98, 1.0)

func get_document_border_color(doc_type: String) -> Color:
	match doc_type:
		"personalausweis": return Color(0.8, 0.6, 0.2, 1.0)
		"reisepass": return Color(0.2, 0.4, 0.8, 1.0)
		"ausreisegenehmigung": return Color(0.2, 0.8, 0.2, 1.0)
		"visum": return Color(0.8, 0.2, 0.6, 1.0)
		"transitvisum": return Color(0.6, 0.2, 0.8, 1.0)
		_: return Color(0.5, 0.5, 0.5, 1.0)

func get_document_content(doc_data: Dictionary) -> String:
	var doc_type = doc_data.get("type", "DOKUMENT")
	var text = "[center][b][font_size=16]%s[/font_size][/b][/center]\n\n" % doc_type.to_upper()
	
	# Add all fields with simple formatting
	for key in doc_data.keys():
		if key == "type":
			continue
			
		var value = str(doc_data[key])
		var formatted_key = format_field_name(key)
		var formatted_value = format_field_value(key, value)
		
		text += "[b]%s:[/b] %s\n" % [formatted_key, formatted_value]
	
	return text

func format_field_name(key: String) -> String:
	match key:
		"name": return "Familienname"
		"vorname": return "Vorname"
		"geburtsdatum": return "Geburtsdatum"
		"pkz": return "PKZ"
		"gueltig_bis": return "Gueltig bis"
		"passnummer": return "Passnummer"
		"reisegrund": return "Reisegrund"
		"zielland": return "Zielland"
		"valid_until": return "Gueltig bis"
		"visa_type": return "Visa-Typ"
		_: return key.capitalize()

func format_field_value(key: String, value: String) -> String:
	match key:
		"gueltig_bis", "valid_until":
			if is_date_expired(value):
				return "[color=red][b]%s (ABGELAUFEN)[/b][/color]" % value
			elif is_date_expiring_soon(value):
				return "[color=orange][b]%s (BALD ABGELAUFEN)[/b][/color]" % value
			else:
				return "[color=green]%s[/color]" % value
		"pkz":
			if value.length() != 12:
				return "[color=red][b]%s (UNGUELTIG)[/b][/color]" % value
			else:
				return value
		_:
			return value

func is_date_expired(date_str: String) -> bool:
	var current_date = "1989-08-01"
	return date_str < current_date

func is_date_expiring_soon(date_str: String) -> bool:
	var current_date = "1989-08-01"
	var warning_date = "1989-09-01"
	return date_str >= current_date and date_str <= warning_date

func clear_documents():
	print("Clearing old documents...")
	for panel in document_panels:
		if is_instance_valid(panel):
			panel.queue_free()
	document_panels.clear()

func update_rules_display():
	if not rules_text:
		print("ERROR: rules_text not found!")
		return
	
	var text = "[center][b][font_size=18]GRENZBESTIMMUNGEN DDR[/font_size][/b][/center]\n"
	text += "[center]TAG %d - SCHICHT 08:00 UHR[/center]\n\n" % day_counter
	text += "[b]AKTIVE KONTROLLEN:[/b]\n"
	text += "• Dokumentengueltigkeit pruefen\n"
	
	if day_counter >= 3:
		text += "• Fotouebereinstimmung pruefen\n"
	if day_counter >= 5:
		text += "• PKZ-Validierung aktiv\n"
	if day_counter >= 7:
		text += "• Stempelkontrolle aktiv\n"
	if day_counter >= 10:
		text += "• PM-12 Ueberpruefung aktiv\n"
	
	text += "\n[b]LAENDER-BESTIMMUNGEN:[/b]\n"
	text += "• [color=red]DDR:[/color] Personalausweis + Ausreisegenehmigung\n"
	text += "• [color=blue]Polen:[/color] Reisepass + Visum erforderlich\n"
	text += "• [color=green]BRD:[/color] Reisepass + Transitvisum\n"
	text += "• [color=purple]UdSSR:[/color] Diplomatenstatus beachten\n"
	
	text += "\n[b]BESONDERE HINWEISE:[/b]\n"
	text += "• [color=red]Fahndungsliste beachten[/color]\n"
	text += "• [color=orange]Republikflucht-Verdacht melden[/color]\n"
	text += "• [color=purple]PM-12 = Absolutes Reiseverbot[/color]\n"
	
	rules_text.text = text
	print("Rules display updated!")

func update_status_display():
	if not status_info:
		print("ERROR: status_info not found!")
		return
	
	var accuracy = 100.0
	if game_stats.total_processed > 0:
		accuracy = (game_stats.correct_decisions * 100.0) / game_stats.total_processed
	
	var text = "[center][b][font_size=18]SCHICHT STATUS[/font_size][/b][/center]\n\n"
	text += "[b]Tag:[/b] %d\n" % day_counter
	text += "[b]Bearbeitet:[/b] %d/%d\n" % [daily_travelers_processed, daily_quota]
	text += "[b]Genehmigt:[/b] [color=green]%d[/color]\n" % approved_count
	text += "[b]Abgelehnt:[/b] [color=red]%d[/color]\n" % rejected_count
	text += "[b]Genauigkeit:[/b] [color=%s]%.1f%%[/color]\n\n" % [get_accuracy_color(accuracy), accuracy]
	
	if accuracy >= 90:
		text += "[color=green][b]Status: AUSGEZEICHNET[/b][/color]"
	elif accuracy >= 75:
		text += "[color=blue][b]Status: GUT[/b][/color]"
	elif accuracy >= 60:
		text += "[color=orange][b]Status: AKZEPTABEL[/b][/color]"
	else:
		text += "[color=red][b]Status: VERBESSERUNG NOETIG[/b][/color]"
	
	status_info.text = text
	print("Status display updated!")

func get_accuracy_color(accuracy: float) -> String:
	if accuracy >= 90: return "green"
	elif accuracy >= 75: return "blue"
	elif accuracy >= 60: return "orange"
	else: return "red"

func _on_approve_pressed():
	print("\n=== APPROVE BUTTON PRESSED ===")
	process_decision(true)

func _on_reject_pressed():
	print("\n=== REJECT BUTTON PRESSED ===")
	process_decision(false)

func process_decision(approved: bool):
	print("Processing decision: ", "APPROVED" if approved else "REJECTED")
	
	# Validate using the validation engine
	var documents = current_traveler.get("documents", [])
	var validation_result = validation_engine.validate_traveler(current_traveler, documents)
	
	var should_approve = validation_result.is_valid
	var is_correct = (approved == should_approve)
	
	var feedback_text = ""
	var title = ""
	
	if is_correct:
		game_stats.correct_decisions += 1
		if approved:
			title = "RICHTIG GENEHMIGT"
			feedback_text = "[color=green][b]KORREKTE ENTSCHEIDUNG![/b][/color]\n\nReisender hatte gueltige Dokumente und durfte passieren."
			approved_count += 1
		else:
			title = "RICHTIG ABGELEHNT"
			feedback_text = "[color=green][b]KORREKTE ENTSCHEIDUNG![/b][/color]\n\nVerstoesse erkannt:\n"
			for violation in validation_result.violations:
				feedback_text += "• %s\n" % validation_engine.get_denial_reason_text(violation.code)
			rejected_count += 1
	else:
		game_stats.incorrect_decisions += 1
		mistakes_count += 1
		if approved:
			title = "FALSCH GENEHMIGT"
			feedback_text = "[color=red][b]FEHLER![/b][/color]\n\nReisender hatte UNGUELTIGE Dokumente:\n"
			for violation in validation_result.violations:
				feedback_text += "• %s\n" % validation_engine.get_denial_reason_text(violation.code)
			feedback_text += "\n[color=orange]Dieser Fehler koennte Konsequenzen haben![/color]"
			approved_count += 1
		else:
			title = "FALSCH ABGELEHNT"
			feedback_text = "[color=red][b]FEHLER![/b][/color]\n\nReisender hatte GUELTIGE Dokumente!\n\n"
			feedback_text += "[color=orange]Unnotige Ablehnung kann zu Beschwerden fuehren![/color]"
			rejected_count += 1
	
	game_stats.total_processed += 1
	
	show_feedback(title, feedback_text)
	
	# Continue after delay
	await get_tree().create_timer(3.0).timeout
	hide_feedback()
	
	# Load next traveler
	load_next_traveler()

func show_feedback(title: String, message: String):
	if not feedback_overlay or not feedback_message or not feedback_title:
		print("ERROR: Feedback UI not found!")
		return
	
	print("Showing feedback: ", title)
	
	feedback_title.text = title
	feedback_message.text = message
	feedback_overlay.visible = true
	
	# Simple fade in
	feedback_overlay.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(feedback_overlay, "modulate:a", 1.0, 0.3)

func hide_feedback():
	if feedback_overlay:
		var tween = create_tween()
		tween.tween_property(feedback_overlay, "modulate:a", 0.0, 0.2)
		await tween.finished
		feedback_overlay.visible = false

func end_day():
	print("\n=== DAY ", day_counter, " COMPLETED ===")
	
	var final_accuracy = 0.0
	if game_stats.total_processed > 0:
		final_accuracy = (game_stats.correct_decisions * 100.0) / game_stats.total_processed
	
	var summary = "[center][b][font_size=20]TAG %d ABGESCHLOSSEN[/font_size][/b][/center]\n\n" % day_counter
	summary += "[b]TAGESBILANZ:[/b]\n"
	summary += "• Reisende bearbeitet: %d/%d\n" % [daily_travelers_processed, daily_quota]
	summary += "• Genehmigungen: %d\n" % approved_count
	summary += "• Ablehnungen: %d\n" % rejected_count
	summary += "• Genauigkeit: %.1f%%\n\n" % final_accuracy
	
	if final_accuracy >= 90:
		summary += "[color=#66ff66][b]AUSGEZEICHNETE LEISTUNG![/b][/color]\nSie haben den Tag mit Bravour gemeistert!"
	elif final_accuracy >= 75:
		summary += "[color=#66aaff][b]GUTE ARBEIT![/b][/color]\nSolide Leistung an der Grenze."
	elif final_accuracy >= 60:
		summary += "[color=#ffaa66][b]AKZEPTABEL[/b][/color]\nEs gibt Raum fuer Verbesserungen."
	else:
		summary += "[color=#ff6666][b]UEBERPRUEFUNG ERFORDERLICH[/b][/color]\nIhre Leistung erfordert zusaetzliche Schulung."
	
	show_feedback("TAGESENDE", summary)
	
	# Wait and start next day
	await get_tree().create_timer(5.0).timeout
	hide_feedback()
	
	day_counter += 1
	validation_engine.update_rules_for_day(day_counter)
	approved_count = 0
	rejected_count = 0
	start_game()
