extends Control

# Load the DocumentUI component
const DocumentUI = preload("res://scenes/ui/DocumentUI.gd")

# UI Elemente
@onready var traveler_info: RichTextLabel = $MainHBoxContainer/LeftPanel/TravelerInfoPanel/TravelerInfoContent/TravelerInfo
@onready var document_container: VBoxContainer = $MainHBoxContainer/LeftPanel/DocumentsPanel/DocumentsContent/DocumentScrollContainer/DocumentArea
@onready var approve_button: Button = $MainHBoxContainer/LeftPanel/ButtonArea/ApproveButton
@onready var reject_button: Button = $MainHBoxContainer/LeftPanel/ButtonArea/RejectButton
@onready var rules_text: RichTextLabel = $MainHBoxContainer/RightPanel/RulebookPanel/RulebookContent/RulesScrollContainer/RulesText
@onready var status_info: RichTextLabel = $MainHBoxContainer/RightPanel/StatusPanel/StatusContent/StatusInfo
@onready var feedback_overlay: Control = $FeedbackOverlay
@onready var feedback_message: RichTextLabel = $FeedbackOverlay/FeedbackPanel/FeedbackContent/FeedbackMessage

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
var current_traveler_index = 0
var daily_quota = 10
var daily_travelers_processed = 0
var selected_document: DocumentUI = null

# Game Statistics
var game_stats = {
	"total_processed": 0,
	"correct_decisions": 0,
	"incorrect_decisions": 0,
	"accuracy_rate": 100.0,
	"detained": 0,
	"special_cases_handled": 0
}

# Document UI instances
var document_ui_instances: Array[DocumentUI] = []

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
	
	# Initialize systems first
	validation_engine = ValidationEngine.new()
	traveler_generator = TravelerGenerator.new()
	
	# Set initial rules for day 1
	validation_engine.update_rules_for_day(day_counter)
	
	# Wait one frame to ensure all @onready nodes are ready
	await get_tree().process_frame
	
	# Verify that all UI nodes are available
	if not _verify_ui_nodes():
		print("Error: Some UI nodes are not available!")
		return
	
	# Connect button signals
	approve_button.pressed.connect(_on_approve_pressed)
	reject_button.pressed.connect(_on_reject_pressed)
	
	# Setup UI
	_setup_button_styles()
	_update_rules_display()
	
	# Start game
	start_new_day()

func _verify_ui_nodes() -> bool:
	var nodes_ok = true
	
	if not traveler_info:
		print("Error: traveler_info not found")
		nodes_ok = false
	if not document_container:
		print("Error: document_container not found")
		nodes_ok = false
	if not approve_button:
		print("Error: approve_button not found")
		nodes_ok = false
	if not reject_button:
		print("Error: reject_button not found")
		nodes_ok = false
	if not rules_text:
		print("Error: rules_text not found")
		nodes_ok = false
	if not status_info:
		print("Error: status_info not found")
		nodes_ok = false
	if not feedback_overlay:
		print("Error: feedback_overlay not found")
		nodes_ok = false
	if not feedback_message:
		print("Error: feedback_message not found")
		nodes_ok = false
	
	return nodes_ok

func _setup_button_styles():
	if not approve_button or not reject_button:
		print("Warning: Buttons not available for styling")
		return
	
	# Style approve button
	var approve_style = StyleBoxFlat.new()
	approve_style.bg_color = Color(0.2, 0.6, 0.2, 1.0)  # Green
	approve_style.border_width_left = 2
	approve_style.border_width_right = 2
	approve_style.border_width_top = 2
	approve_style.border_width_bottom = 2
	approve_style.border_color = Color(0.1, 0.4, 0.1, 1.0)
	approve_style.corner_radius_top_left = 8
	approve_style.corner_radius_top_right = 8
	approve_style.corner_radius_bottom_left = 8
	approve_style.corner_radius_bottom_right = 8
	approve_button.add_theme_stylebox_override("normal", approve_style)
	
	var approve_hover = approve_style.duplicate()
	approve_hover.bg_color = Color(0.3, 0.7, 0.3, 1.0)
	approve_button.add_theme_stylebox_override("hover", approve_hover)
	
	# Style reject button
	var reject_style = StyleBoxFlat.new()
	reject_style.bg_color = Color(0.6, 0.2, 0.2, 1.0)  # Red
	reject_style.border_width_left = 2
	reject_style.border_width_right = 2
	reject_style.border_width_top = 2
	reject_style.border_width_bottom = 2
	reject_style.border_color = Color(0.4, 0.1, 0.1, 1.0)
	reject_style.corner_radius_top_left = 8
	reject_style.corner_radius_top_right = 8
	reject_style.corner_radius_bottom_left = 8
	reject_style.corner_radius_bottom_right = 8
	reject_button.add_theme_stylebox_override("normal", reject_style)
	
	var reject_hover = reject_style.duplicate()
	reject_hover.bg_color = Color(0.7, 0.3, 0.3, 1.0)
	reject_button.add_theme_stylebox_override("hover", reject_hover)

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
	_update_rules_display()
	_update_status_display()
	
	# Load first traveler
	load_next_traveler()

func load_next_traveler():
	if daily_travelers_processed >= daily_quota:
		end_day()
		return
	
	# Clear previous documents
	_clear_document_display()
	
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
	
	# Ensure current_traveler is valid
	if current_traveler.is_empty():
		print("Warning: Generated empty traveler, using fallback")
		current_traveler = traveler_generator.generate_traveler("valid", day_counter)
	
	# Ensure traveler has documents
	if not current_traveler.has("documents") or current_traveler.documents.is_empty():
		print("Warning: Traveler has no documents, regenerating...")
		current_traveler = traveler_generator.generate_traveler("valid", day_counter)
	
	daily_travelers_processed += 1
	_update_traveler_display()
	_create_document_display()
	_update_status_display()

func _update_traveler_display():
	if not traveler_info:
		print("Warning: traveler_info not available")
		return
	
	var info_text = "[center][b]REISENDER #%d[/b][/center]\n\n" % daily_travelers_processed
	info_text += "[b]Name:[/b] %s, %s\n" % [
		current_traveler.get("name", "Unbekannt"),
		current_traveler.get("vorname", "")
	]
	info_text += "[b]Alter:[/b] %d Jahre\n" % current_traveler.get("age", 0)
	info_text += "[b]Nationalität:[/b] %s\n" % current_traveler.get("nationality", "Unbekannt")
	info_text += "[b]Reisezweck:[/b] %s\n" % current_traveler.get("purpose", "Unbekannt")
	info_text += "[b]Richtung:[/b] %s\n\n" % current_traveler.get("direction", "unbekannt")
	
	# Add story/observation
	if current_traveler.has("story"):
		info_text += "[i]Beobachtung:[/i]\n%s" % current_traveler.story
	
	# Add special flags
	if current_traveler.get("on_watchlist", false):
		info_text += "\n\n[color=red][b]⚠ AUF FAHNDUNGSLISTE ⚠[/b][/color]"
	
	if current_traveler.get("diplomatic_status", false):
		info_text += "\n\n[color=blue][b]🛡 DIPLOMATISCHE IMMUNITÄT[/b][/color]"
	
	traveler_info.text = info_text

func _create_document_display():
	if not document_container:
		print("Warning: document_container not available")
		return
	
	# Clear existing documents
	_clear_document_display()
	
	var documents = current_traveler.get("documents", [])
	
	if documents.is_empty():
		print("Warning: No documents found for traveler")
		return
	
	for i in range(documents.size()):
		var doc_data = documents[i]
		var doc_ui = DocumentUI.new()
		
		document_container.add_child(doc_ui)
		document_ui_instances.append(doc_ui)
		
		# Set document data
		doc_ui.set_document_data(doc_data)
		
		# Connect signals
		doc_ui.document_clicked.connect(_on_document_clicked)
		doc_ui.document_hovered.connect(_on_document_hovered)
		
		# Animate in with delay
		doc_ui.animate_in()
		await get_tree().create_timer(0.1 * i).timeout

func _clear_document_display():
	for doc_ui in document_ui_instances:
		if is_instance_valid(doc_ui):
			doc_ui.animate_out()
	
	document_ui_instances.clear()
	selected_document = null

func _on_document_clicked(document_data: Dictionary):
	# Deselect all documents
	for doc_ui in document_ui_instances:
		if is_instance_valid(doc_ui):
			doc_ui.set_selected(false)
	
	# Select clicked document
	for doc_ui in document_ui_instances:
		if is_instance_valid(doc_ui) and doc_ui.document_data == document_data:
			doc_ui.set_selected(true)
			selected_document = doc_ui
			break

func _on_document_hovered(document_data: Dictionary):
	# Could add hover effects or tooltips here
	pass

func _update_rules_display():
	if not rules_text:
		print("Warning: rules_text not available")
		return
	
	var text = "[center][b]GRENZBESTIMMUNGEN DDR[/b][/center]\n"
	text += "[center]TAG %d - SCHICHT %02d:00[/center]\n\n" % [day_counter, 8 + (daily_travelers_processed / 2)]
	
	text += "[b]AKTIVE KONTROLLEN:[/b]\n"
	text += "• Dokumentengültigkeit prüfen\n"
	
	if day_counter >= 3:
		text += "• [color=yellow]Foto-Vergleich durchführen[/color]\n"
	if day_counter >= 5:
		text += "• [color=yellow]PKZ kontrollieren[/color]\n"
	if day_counter >= 7:
		text += "• [color=yellow]Stempel prüfen[/color]\n"
	if day_counter >= 10:
		text += "• [color=red]PM-12 Vermerk beachten[/color]\n"
	
	text += "\n[b]BESONDERE HINWEISE:[/b]\n"
	text += "• [color=orange]Polen:[/color] Visum erforderlich\n"
	text += "• [color=orange]BRD:[/color] Transitvisum prüfen\n"
	text += "• [color=red]Fahndungsliste beachten[/color]\n"
	text += "• [color=red]Bei Fluchtgefahr: FESTHALTEN[/color]\n"
	
	text += "\n[b]DOKUMENTTYPEN:[/b]\n"
	text += "• [color=#4d7fff]Personalausweis DDR[/color]\n"
	text += "• [color=#994d4d]Reisepass[/color]\n"
	text += "• [color=#4d994d]Ausreisegenehmigung[/color]\n"
	text += "• [color=#b3804d]Visum[/color]\n"
	text += "• [color=#804db3]Transitvisum[/color]\n"
	
	if mistakes_count > 3:
		text += "\n[color=red][b]WARNUNG: Zu viele Fehler![/b][/color]"
	
	rules_text.text = text

func _update_status_display():
	if not status_info:
		print("Warning: status_info not available")
		return
	
	var accuracy = 100.0
	if game_stats.total_processed > 0:
		accuracy = (game_stats.correct_decisions * 100.0) / game_stats.total_processed
	
	var text = "[center][b]SCHICHT STATUS[/b][/center]\n\n"
	text += "[b]Tag:[/b] %d\n" % day_counter
	text += "[b]Bearbeitet:[/b] %d/%d\n" % [daily_travelers_processed, daily_quota]
	text += "[b]Genehmigt:[/b] %d\n" % approved_count
	text += "[b]Abgelehnt:[/b] %d\n" % rejected_count
	text += "[b]Fehler heute:[/b] %d\n" % mistakes_count
	text += "[b]Genauigkeit:[/b] %.1f%%\n\n" % accuracy
	
	# Performance indicator
	if accuracy >= 90:
		text += "[color=green]🏆 Ausgezeichnet[/color]"
	elif accuracy >= 75:
		text += "[color=yellow]👍 Gut[/color]"
	elif accuracy >= 60:
		text += "[color=orange]⚠ Verbesserung nötig[/color]"
	else:
		text += "[color=red]❌ Unzureichend[/color]"
	
	status_info.text = text

func _on_approve_pressed():
	if current_traveler.is_empty():
		return
	
	# Disable buttons during processing
	approve_button.disabled = true
	reject_button.disabled = true
	
	process_decision(true)

func _on_reject_pressed():
	if current_traveler.is_empty():
		return
	
	# Disable buttons during processing
	approve_button.disabled = true
	reject_button.disabled = true
	
	process_decision(false)

func process_decision(approved: bool):
	game_stats.total_processed += 1
	
	# Validate the traveler
	var validation_result = validation_engine.validate_traveler(
		current_traveler, 
		current_traveler.get("documents", [])
	)
	
	var correct_decision = false
	var feedback_title = ""
	var feedback_text = ""
	var feedback_color = Color.WHITE
	
	if approved:
		approved_count += 1
		if validation_result.is_valid:
			# Correct approval
			correct_decision = true
			feedback_title = "✓ GENEHMIGT"
			feedback_text = "[color=green][b]Korrekt![/b][/color]\nDokumente sind gültig."
			feedback_color = Color.GREEN
			game_stats.correct_decisions += 1
		else:
			# Incorrect approval - show what was missed
			mistakes_count += 1
			feedback_title = "✗ FEHLER!"
			feedback_text = "[color=red][b]Falsche Genehmigung![/b][/color]\n\n"
			feedback_text += "[b]Übersehen:[/b]\n"
			for violation in validation_result.violations:
				feedback_text += "• %s\n" % validation_engine.get_denial_reason_text(violation.code)
				_highlight_error_in_documents(violation.code)
			feedback_color = Color.RED
			game_stats.incorrect_decisions += 1
	else:
		rejected_count += 1
		if not validation_result.is_valid:
			# Correct rejection
			correct_decision = true
			feedback_title = "✓ ABGELEHNT"
			feedback_text = "[color=green][b]Korrekt abgelehnt![/b][/color]\n\n"
			feedback_text += "[b]Gründe:[/b]\n"
			for violation in validation_result.violations:
				feedback_text += "• %s\n" % validation_engine.get_denial_reason_text(violation.code)
			feedback_color = Color.GREEN
			game_stats.correct_decisions += 1
		else:
			# Incorrect rejection
			mistakes_count += 1
			feedback_title = "✗ FEHLER!"
			feedback_text = "[color=red][b]Falsche Ablehnung![/b][/color]\n\n"
			feedback_text += "Die Dokumente waren gültig!"
			feedback_color = Color.RED
			game_stats.incorrect_decisions += 1
			
			# Shake all documents to show they were valid
			for doc_ui in document_ui_instances:
				if is_instance_valid(doc_ui):
					doc_ui.shake()
	
	# Check for special cases
	if current_traveler.get("on_watchlist", false):
		if not approved:
			feedback_text += "\n[color=yellow][b]Bonus:[/b] Fahndungsliste erkannt![/color]"
			game_stats.special_cases_handled += 1
	
	if current_traveler.get("diplomatic_status", false):
		if approved:
			feedback_text += "\n[color=blue][b]Info:[/b] Diplomatische Immunität respektiert[/color]"
			game_stats.special_cases_handled += 1
	
	# Show feedback
	_show_feedback(feedback_title, feedback_text, feedback_color)
	
	# Continue after delay
	await get_tree().create_timer(3.0).timeout
	
	# Re-enable buttons
	approve_button.disabled = false
	reject_button.disabled = false
	
	# Continue to next traveler
	next_traveler()

func _highlight_error_in_documents(violation_code: String):
	# Highlight specific document that has the error
	var error_type = _get_error_type_from_violation(violation_code)
	
	for doc_ui in document_ui_instances:
		if is_instance_valid(doc_ui):
			if _document_has_error_type(doc_ui.document_data, error_type):
				doc_ui.highlight_error(error_type)

func _get_error_type_from_violation(code: String) -> String:
	match code:
		"expired_document":
			return "ABGELAUFEN"
		"photo_mismatch":
			return "FOTO FALSCH"
		"pm12_restriction":
			return "PM-12 VERMERK"
		"on_watchlist":
			return "FAHNDUNGSLISTE"
		"missing_document":
			return "FEHLENDES DOKUMENT"
		_:
			return "FEHLER"

func _document_has_error_type(doc_data: Dictionary, error_type: String) -> bool:
	match error_type:
		"ABGELAUFEN":
			var expiry = doc_data.get("gueltig_bis", "")
			return expiry != "" and expiry < "1989-08-01"
		"PM-12 VERMERK":
			return doc_data.get("pm12_vermerk", false)
		"FOTO FALSCH":
			return doc_data.has("foto")
		_:
			return true

func _show_feedback(title: String, message: String, color: Color):
	if not feedback_overlay or not feedback_message:
		print("Warning: Feedback UI elements not available")
		return
	
	var feedback_title_label = feedback_overlay.get_node("FeedbackPanel/FeedbackContent/FeedbackTitle")
	
	if not feedback_title_label:
		print("Error: Could not find FeedbackTitle node")
		return
	
	feedback_title_label.text = title
	feedback_title_label.add_theme_color_override("font_color", color)
	
	feedback_message.text = message
	
	# Show overlay with animation
	feedback_overlay.visible = true
	feedback_overlay.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(feedback_overlay, "modulate:a", 1.0, 0.3)

func next_traveler():
	if not feedback_overlay:
		print("Warning: feedback_overlay not available")
		current_traveler_index += 1
		load_next_traveler()
		return
	
	# Hide feedback
	var tween = create_tween()
	tween.tween_property(feedback_overlay, "modulate:a", 0.0, 0.3)
	await tween.finished
	feedback_overlay.visible = false
	
	current_traveler_index += 1
	load_next_traveler()

func end_day():
	print("\n=== TAG %d BEENDET ===" % day_counter)
	
	var accuracy = 100.0
	if daily_travelers_processed > 0:
		accuracy = ((daily_travelers_processed - mistakes_count) * 100.0) / daily_travelers_processed
	
	# Show day summary
	var summary = "[center][b]TAG %d ABGESCHLOSSEN[/b][/center]\n\n" % day_counter
	summary += "[b]Bearbeitet:[/b] %d Reisende\n" % daily_travelers_processed
	summary += "[b]Genehmigt:[/b] %d\n" % approved_count
	summary += "[b]Abgelehnt:[/b] %d\n" % rejected_count
	summary += "[b]Fehler:[/b] %d\n" % mistakes_count
	summary += "[b]Genauigkeit:[/b] %.1f%%\n\n" % accuracy
	
	if mistakes_count <= 2:
		summary += "[color=green]🏆 Ausgezeichnete Arbeit, Genosse![/color]"
	elif mistakes_count <= 4:
		summary += "[color=yellow]👍 Akzeptable Leistung.[/color]"
	else:
		summary += "[color=red]⚠ Mehr Aufmerksamkeit erforderlich![/color]"
	
	if traveler_info:
		traveler_info.text = summary
	
	# Disable buttons temporarily
	approve_button.disabled = true
	reject_button.disabled = true
	
	# Prepare next day
	await get_tree().create_timer(4.0).timeout
	
	day_counter += 1
	if day_counter > 5:
		show_game_over()
	else:
		# Reset for new day
		approved_count = 0
		rejected_count = 0
		approve_button.disabled = false
		reject_button.disabled = false
		
		# Update UI for new day
		_update_rules_display()
		
		start_new_day()

func show_game_over():
	var final_accuracy = 100.0
	if game_stats.total_processed > 0:
		final_accuracy = (game_stats.correct_decisions * 100.0) / game_stats.total_processed
	
	var ending_text = "[center][b]=== SPIEL BEENDET ===[/b][/center]\n\n"
	ending_text += "[b]Gesamtstatistik:[/b]\n"
	ending_text += "Tage gearbeitet: 5\n"
	ending_text += "Reisende bearbeitet: %d\n" % game_stats.total_processed
	ending_text += "Korrekte Entscheidungen: %d\n" % game_stats.correct_decisions
	ending_text += "Fehler: %d\n" % game_stats.incorrect_decisions
	ending_text += "Genauigkeit: %.1f%%\n" % final_accuracy
	ending_text += "Spezialfälle: %d\n\n" % game_stats.special_cases_handled
	
	if final_accuracy >= 90:
		ending_text += "[color=gold]🏆 AUSZEICHNUNG: Vorbildlicher Grenzbeamter![/color]"
	elif final_accuracy >= 75:
		ending_text += "[color=green]🎖 BEWERTUNG: Zufriedenstellende Leistung[/color]"
	elif final_accuracy >= 60:
		ending_text += "[color=orange]📋 BEWERTUNG: Verbesserung erforderlich[/color]"
	else:
		ending_text += "[color=red]📝 BEWERTUNG: Unzureichend - Nachschulung erforderlich[/color]"
	
	if traveler_info:
		traveler_info.text = ending_text
	print(ending_text)
