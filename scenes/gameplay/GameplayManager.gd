extends Control

# UI References
@onready var traveler_info: RichTextLabel = $VBoxContainer/HBoxContainer/LeftPanel/TravelerInfo
@onready var document_area: VBoxContainer = $VBoxContainer/HBoxContainer/LeftPanel/DocumentArea
@onready var rules_text: RichTextLabel = $VBoxContainer/HBoxContainer/RightPanel/RulesText
@onready var status_info: RichTextLabel = $VBoxContainer/HBoxContainer/RightPanel/StatusInfo
@onready var approve_button: Button = $VBoxContainer/ButtonArea/ApproveButton
@onready var reject_button: Button = $VBoxContainer/ButtonArea/RejectButton
@onready var debug_label: Label = $VBoxContainer/DebugLabel
@onready var feedback_overlay: Control = $FeedbackOverlay
@onready var feedback_title: Label = $FeedbackOverlay/FeedbackPanel/FeedbackVBox/FeedbackTitle
@onready var feedback_message: RichTextLabel = $FeedbackOverlay/FeedbackPanel/FeedbackVBox/FeedbackMessage

# Game state
var current_traveler = {}
var day_counter = 1
var traveler_counter = 0

func _ready():
	print("=== GAME STARTING ===")
	
	# Wait for all nodes to be ready
	await get_tree().process_frame
	
	# Check if all UI elements exist
	print("Checking UI elements...")
	print("- traveler_info: ", traveler_info != null)
	print("- document_area: ", document_area != null)  
	print("- rules_text: ", rules_text != null)
	print("- status_info: ", status_info != null)
	print("- approve_button: ", approve_button != null)
	print("- reject_button: ", reject_button != null)
	print("- debug_label: ", debug_label != null)
	
	# Set debug info
	if debug_label:
		debug_label.text = "✓ Spiel gestartet - Alle UI-Elemente geladen"
	
	# Connect buttons
	if approve_button:
		approve_button.pressed.connect(_on_approve)
		print("✓ Approve button connected")
	
	if reject_button:
		reject_button.pressed.connect(_on_reject)
		print("✓ Reject button connected")
	
	# Load content immediately
	_load_simple_content()

func _load_simple_content():
	print("=== LOADING SIMPLE CONTENT ===")
	
	# Create a simple test traveler
	current_traveler = {
		"name": "Mueller",
		"vorname": "Hans", 
		"age": 45,
		"nationality": "DDR",
		"purpose": "Familienbesuch",
		"direction": "ausreise",
		"documents": [
			{
				"type": "personalausweis",
				"name": "Mueller",
				"vorname": "Hans",
				"geburtsdatum": "1944-03-15",
				"pkz": "150344123456",
				"gueltig_bis": "1990-12-31"
			},
			{
				"type": "ausreisegenehmigung", 
				"name": "Mueller",
				"vorname": "Hans",
				"reisegrund": "Familienbesuch",
				"gueltig_bis": "1989-09-15"
			}
		]
	}
	
	traveler_counter += 1
	
	# Update all displays
	_update_traveler_info()
	_update_documents()
	_update_rules()
	_update_status()
	
	print("✓ Content loaded successfully")

func _update_traveler_info():
	if not traveler_info:
		print("ERROR: traveler_info not found!")
		return
	
	var text = "[center][b]REISENDER #%d[/b][/center]\n\n" % traveler_counter
	text += "[b]Name:[/b] %s, %s\n" % [current_traveler.name, current_traveler.vorname]
	text += "[b]Alter:[/b] %d Jahre\n" % current_traveler.age
	text += "[b]Nationalität:[/b] %s\n" % current_traveler.nationality
	text += "[b]Reisezweck:[/b] %s\n" % current_traveler.purpose
	text += "[b]Richtung:[/b] %s\n\n" % current_traveler.direction
	text += "[i]Ein DDR-Bürger möchte ausreisen, um Familie zu besuchen.[/i]"
	
	traveler_info.text = text
	print("✓ Traveler info updated")

func _update_documents():
	if not document_area:
		print("ERROR: document_area not found!")
		return
	
	# Clear existing documents
	for child in document_area.get_children():
		child.queue_free()
	
	print("Creating document panels...")
	
	# Create document panels
	var documents = current_traveler.get("documents", [])
	for i in range(documents.size()):
		var doc = documents[i]
		var panel = _create_document_panel(doc)
		document_area.add_child(panel)
		print("✓ Added document: ", doc.type)

func _create_document_panel(doc_data: Dictionary) -> Control:
	# Create main container
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(300, 140)
	
	# Create style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.95, 0.95, 1.0)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.3, 0.3, 0.7)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)
	
	# Create content
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	
	var content = RichTextLabel.new()
	content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.scroll_active = false
	
	# Build document text
	var doc_text = "[center][b]%s[/b][/center]\n" % doc_data.type.to_upper()
	doc_text += "[color=gray]━━━━━━━━━━━━━━━━━[/color]\n"
	
	# Add all fields
	for key in doc_data.keys():
		if key == "type":
			continue
		var display_key = _get_german_field_name(key)
		doc_text += "[b]%s:[/b] %s\n" % [display_key, str(doc_data[key])]
	
	content.text = doc_text
	margin.add_child(content)
	panel.add_child(margin)
	
	return panel

func _get_german_field_name(key: String) -> String:
	var translations = {
		"name": "Nachname",
		"vorname": "Vorname", 
		"geburtsdatum": "Geburtsdatum",
		"pkz": "Personenkennzahl",
		"gueltig_bis": "Gültig bis",
		"reisegrund": "Reisegrund",
		"ausstellungsdatum": "Ausgestellt",
		"passnummer": "Pass-Nr"
	}
	return translations.get(key, key.capitalize())

func _update_rules():
	if not rules_text:
		print("ERROR: rules_text not found!")
		return
	
	var text = "[center][b]🏛 GRENZBESTIMMUNGEN DDR[/b][/center]\n"
	text += "[center][color=gray]Tag %d - Schicht 08:00[/color][/center]\n\n" % day_counter
	
	text += "[b]📋 AKTUELLE KONTROLLEN:[/b]\n"
	text += "• ✓ Dokumentengültigkeit prüfen\n"
	text += "• ✓ Personalausweis für DDR-Bürger\n"
	text += "• ✓ Ausreisegenehmigung erforderlich\n\n"
	
	text += "[b]⚠ BESONDERE HINWEISE:[/b]\n"
	text += "• [color=orange]Polen:[/color] Visum erforderlich\n"
	text += "• [color=orange]BRD:[/color] Transitvisum prüfen\n"
	text += "• [color=red]Fahndungsliste beachten![/color]\n\n"
	
	text += "[b]📄 GÜLTIGE DOKUMENTE:[/b]\n"
	text += "• [color=#2d5aa0]Personalausweis DDR[/color]\n"
	text += "• [color=#a02d2d]Reisepass[/color]\n"
	text += "• [color=#2da02d]Ausreisegenehmigung[/color]"
	
	rules_text.text = text
	print("✓ Rules updated")

func _update_status():
	if not status_info:
		print("ERROR: status_info not found!")
		return
	
	var text = "[center][b]📊 SCHICHT STATUS[/b][/center]\n\n"
	text += "[b]🗓 Tag:[/b] %d\n" % day_counter
	text += "[b]👥 Bearbeitet:[/b] %d/10\n" % traveler_counter
	text += "[b]✅ Genehmigt:[/b] 0\n"
	text += "[b]❌ Abgelehnt:[/b] 0\n"
	text += "[b]⚠ Fehler:[/b] 0\n"
	text += "[b]🎯 Genauigkeit:[/b] 100%\n\n"
	
	text += "[color=green]🏆 Bereit für Kontrolle![/color]"
	
	status_info.text = text
	print("✓ Status updated")

func _on_approve():
	print("=== APPROVE PRESSED ===")
	
	if debug_label:
		debug_label.text = "🟢 GENEHMIGT - Reisender darf passieren"
	
	_show_feedback("✅ GENEHMIGT", "[color=green]Dokumente wurden akzeptiert![/color]", Color.GREEN)

func _on_reject():
	print("=== REJECT PRESSED ===")
	
	if debug_label:
		debug_label.text = "🔴 ABGELEHNT - Reisender wurde zurückgewiesen"
	
	_show_feedback("❌ ABGELEHNT", "[color=red]Dokumente wurden abgelehnt![/color]", Color.RED)

func _show_feedback(title: String, message: String, color: Color):
	print("Showing feedback: ", title)
	
	if not feedback_overlay or not feedback_title or not feedback_message:
		print("Feedback UI not available - showing in debug instead")
		if debug_label:
			debug_label.text = title + " - " + message
		return
	
	feedback_title.text = title
	feedback_title.add_theme_color_override("font_color", color)
	feedback_message.text = message
	
	feedback_overlay.visible = true
	feedback_overlay.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(feedback_overlay, "modulate:a", 1.0, 0.3)
	
	# Hide after 2 seconds
	await get_tree().create_timer(2.0).timeout
	
	tween = create_tween()
	tween.tween_property(feedback_overlay, "modulate:a", 0.0, 0.3)
	await tween.finished
	feedback_overlay.visible = false
	
	print("Feedback hidden")

func _input(event):
	# Debug key to reload content
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			print("=== RELOADING CONTENT (R pressed) ===")
			_load_simple_content()
		elif event.keycode == KEY_D:
			print("=== DEBUG INFO (D pressed) ===")
			print("Current traveler: ", current_traveler)
			print("UI elements status:")
			print("- traveler_info: ", traveler_info != null)
			print("- document_area children: ", document_area.get_child_count() if document_area else "null")
