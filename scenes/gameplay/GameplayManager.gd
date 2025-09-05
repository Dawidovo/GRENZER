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

# Watchlist UI elements
@onready var watchlist_button: Button = $MainContainer/ToolsContainer/WatchlistButton
@onready var watchlist_overlay: Control = $WatchlistOverlay
@onready var watchlist_text: RichTextLabel = $WatchlistOverlay/WatchlistPanel/WatchlistContent/WatchlistScroll/WatchlistText
@onready var close_watchlist_button: Button = $WatchlistOverlay/WatchlistPanel/WatchlistContent/WatchlistHeader/CloseButton

# Panel references for styling
@onready var traveler_panel: Panel = $MainContainer/ContentContainer/LeftSide/TravelerPanel
@onready var document_panel: Panel = $MainContainer/ContentContainer/LeftSide/DocumentPanel
@onready var rules_panel: Panel = $MainContainer/ContentContainer/RightSide/RulesPanel
@onready var status_panel: Panel = $MainContainer/ContentContainer/RightSide/StatusPanel
@onready var feedback_panel: Panel = $FeedbackOverlay/FeedbackPanel
@onready var watchlist_panel: Panel = $WatchlistOverlay/WatchlistPanel

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

# Enhanced Watchlist Database
var extended_watchlist = [
	{
		"name": "Schmidt",
		"vorname": "Werner",
		"reason": "Republikfluchtversuch",
		"date_added": "15.07.1989",
		"alert_level": "HOCH",
		"description": "Bereits 2x beim Fluchtversuch ertappt. Arbeitete als Elektriker."
	},
	{
		"name": "Mueller",
		"vorname": "Sabine",
		"reason": "Westkontakte",
		"date_added": "03.06.1989",
		"alert_level": "MITTEL",
		"description": "Schwester lebt in West-Berlin. Verdacht auf Informationsaustausch."
	},
	{
		"name": "Fischer",
		"vorname": "Klaus",
		"reason": "Staatsfeindliche Hetze",
		"date_added": "20.05.1989",
		"alert_level": "HOCH", 
		"description": "Verteilte westliche Propaganda. Ehemaliger Lehrer."
	},
	{
		"name": "Weber",
		"vorname": "Ingrid",
		"reason": "Devisenvergehen",
		"date_added": "10.04.1989",
		"alert_level": "NIEDRIG",
		"description": "Verdacht auf Handel mit D-Mark. Arbeitet im Einzelhandel."
	},
	{
		"name": "Kowalski",
		"vorname": "Jan",
		"reason": "Spionageverdacht",
		"date_added": "28.03.1989",
		"alert_level": "SEHR HOCH",
		"description": "Polnischer Staatsbürger. Verdacht auf Agententätigkeit."
	},
	{
		"name": "Hartmann",
		"vorname": "Thomas",
		"reason": "Republikfluchtversuch",
		"date_added": "15.02.1989",
		"alert_level": "HOCH",
		"description": "Familienoberhaupt. Plante Flucht mit Frau und 2 Kindern."
	},
	{
		"name": "Becker",
		"vorname": "Andrea",
		"reason": "Dokumentenfälschung",
		"date_added": "08.01.1989",
		"alert_level": "MITTEL",
		"description": "Expertin für gefälschte Ausweise. Sehr gefährlich!"
	},
	{
		"name": "Wagner",
		"vorname": "Dieter",
		"reason": "Fluchthelfer",
		"date_added": "22.12.1988",
		"alert_level": "SEHR HOCH",
		"description": "Organisierte Tunnelflucht. 15 Personen entkommen."
	},
	{
		"name": "Klein",
		"vorname": "Petra",
		"reason": "Republikfluchtversuch",
		"date_added": "05.11.1988",
		"alert_level": "MITTEL",
		"description": "Versuchte Flucht über Ungarn. Krankenschwester."
	},
	{
		"name": "Richter",
		"vorname": "Hans",
		"reason": "Staatsfeindliche Agitation",
		"date_added": "18.10.1988",
		"alert_level": "HOCH",
		"description": "Organisierte Proteste. Ehemaliger Kirchenvorstand."
	}
]

func _ready():
	print("\n" + "=".repeat(50))
	print("DDR GRENZPOSTEN SIMULATOR - STARTING")
	print("=".repeat(50))
	
	# Initialize systems
	validation_engine = ValidationEngine.new()
	traveler_generator = TravelerGenerator.new()
	validation_engine.update_rules_for_day(day_counter)
	
	# Update watchlist in validation engine
	update_validation_watchlist()
	
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
	if watchlist_button:
		watchlist_button.pressed.connect(_on_watchlist_pressed)
		print("✓ Watchlist button connected")
	if close_watchlist_button:
		close_watchlist_button.pressed.connect(_on_close_watchlist_pressed)
		print("✓ Close watchlist button connected")
	
	# Setup watchlist content
	setup_watchlist_content()
	
	# Start the game
	print("\n--- STARTING GAME ---")
	start_game()

func update_validation_watchlist():
	# Convert extended watchlist to format validation engine expects
	validation_engine.watchlist.clear()
	for person in extended_watchlist:
		validation_engine.watchlist.append({
			"name": person.name,
			"vorname": person.vorname,
			"reason": person.reason.to_lower().replace(" ", "_")
		})

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
	print("Checking watchlist_button: ", watchlist_button != null)
	print("Checking watchlist_overlay: ", watchlist_overlay != null)
	print("Checking watchlist_text: ", watchlist_text != null)

func setup_panel_styling():
	# Traveler panel - light beige with dark text
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
	
	# Document panel - light blue with dark text
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
	
	# Rules panel - light orange with dark text
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
	
	# Status panel - light green with dark text
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
	
	# Feedback panel - white with dark text
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
	
	# Watchlist panel - military style
	if watchlist_panel:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.95, 0.95, 0.85, 1.0)  # Military paper color
		style.border_width_left = 4
		style.border_width_right = 4
		style.border_width_top = 4
		style.border_width_bottom = 4
		style.border_color = Color(0.6, 0.1, 0.1, 1.0)  # Dark red border
		style.corner_radius_top_left = 5
		style.corner_radius_top_right = 5
		style.corner_radius_bottom_left = 5
		style.corner_radius_bottom_right = 5
		watchlist_panel.add_theme_stylebox_override("panel", style)

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
	
	if watchlist_button:
		# Orange watchlist button
		var watchlist_style = StyleBoxFlat.new()
		watchlist_style.bg_color = Color(0.9, 0.6, 0.1, 1.0)
		watchlist_style.border_width_left = 2
		watchlist_style.border_width_right = 2
		watchlist_style.border_width_top = 2
		watchlist_style.border_width_bottom = 2
		watchlist_style.border_color = Color(0.7, 0.4, 0.0, 1.0)
		watchlist_style.corner_radius_top_left = 5
		watchlist_style.corner_radius_top_right = 5
		watchlist_style.corner_radius_bottom_left = 5
		watchlist_style.corner_radius_bottom_right = 5
		watchlist_button.add_theme_stylebox_override("normal", watchlist_style)
		watchlist_button.add_theme_color_override("font_color", Color.WHITE)
		
		# Hover effect
		var watchlist_hover = watchlist_style.duplicate()
		watchlist_hover.bg_color = Color(1.0, 0.7, 0.2, 1.0)
		watchlist_button.add_theme_stylebox_override("hover", watchlist_hover)
	
	if close_watchlist_button:
		# Gray close button
		var close_style = StyleBoxFlat.new()
		close_style.bg_color = Color(0.5, 0.5, 0.5, 1.0)
		close_style.border_width_left = 2
		close_style.border_width_right = 2
		close_style.border_width_top = 2
		close_style.border_width_bottom = 2
		close_style.border_color = Color(0.3, 0.3, 0.3, 1.0)
		close_style.corner_radius_top_left = 5
		close_style.corner_radius_top_right = 5
		close_style.corner_radius_bottom_left = 5
		close_style.corner_radius_bottom_right = 5
		close_watchlist_button.add_theme_stylebox_override("normal", close_style)
		close_watchlist_button.add_theme_color_override("font_color", Color.WHITE)

func setup_watchlist_content():
	if not watchlist_text:
		print("ERROR: watchlist_text not found!")
		return
	
	# Set dark text color for readability
	watchlist_text.add_theme_color_override("default_color", Color.BLACK)
	
	var content = "[center][b][font_size=18][color=red]⚠ FAHNDUNGSLISTE ⚠[/color][/font_size][/b][/center]\n"
	content += "[center][font_size=14]MINISTERIUM FÜR STAATSSICHERHEIT[/font_size][/center]\n"
	content += "[center][font_size=12]Ausgabe: 01.08.1989 - STRENG VERTRAULICH[/font_size][/center]\n\n"
	content += "[b]ANWEISUNG:[/b] Personen auf dieser Liste sind SOFORT festzunehmen!\n\n"
	
	# Sort by alert level for display
	var sorted_list = extended_watchlist.duplicate()
	sorted_list.sort_custom(func(a, b): return get_alert_priority(a.alert_level) > get_alert_priority(b.alert_level))
	
	for person in sorted_list:
		var alert_color = get_alert_color(person.alert_level)
		content += "[table=3]\n"
		content += "[cell][b]%s, %s[/b][/cell][cell][color=%s][b]%s[/b][/color][/cell][cell]%s[/cell]\n" % [
			person.name, person.vorname, alert_color, person.alert_level, person.date_added
		]
		content += "[cell colspan=3][i]Grund:[/i] %s[/cell]\n" % person.reason
		content += "[cell colspan=3][font_size=10]%s[/font_size][/cell]\n" % person.description
		content += "[/table]\n"
		content += "─".repeat(60) + "\n\n"
	
	content += "[center][font_size=10][i]Bei Sichtung einer gesuchten Person unverzüglich Meldung an den Schichtleiter![/i][/font_size][/center]"
	
	watchlist_text.text = content

func get_alert_priority(level: String) -> int:
	match level:
		"SEHR HOCH": return 4
		"HOCH": return 3
		"MITTEL": return 2
		"NIEDRIG": return 1
		_: return 0

func get_alert_color(level: String) -> String:
	match level:
		"SEHR HOCH": return "red"
		"HOCH": return "orange"
		"MITTEL": return "blue"
		"NIEDRIG": return "green"
		_: return "gray"

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
	
	# Set dark text color for readability
	traveler_info.add_theme_color_override("default_color", Color.BLACK)
	
	var text = "[center][b][font_size=20]REISENDER #%d[/font_size][/b][/center]\n\n" % daily_travelers_processed
	text += "[b]Name:[/b] %s, %s\n" % [current_traveler.get("name", "?"), current_traveler.get("vorname", "?")]
	text += "[b]Alter:[/b] %d Jahre\n" % current_traveler.get("age", 0)
	text += "[b]Nationalitaet:[/b] %s\n" % current_traveler.get("nationality", "?")
	text += "[b]Zweck:[/b] %s\n" % current_traveler.get("purpose", "?")
	text += "[b]Richtung:[/b] %s\n\n" % current_traveler.get("direction", "?").to_upper()
	
	if current_traveler.has("story"):
		text += "[i]Beobachtung:[/i]\n%s" % current_traveler.story
	
	traveler_info.text = text
	print("Traveler display updated!")

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
	label.add_theme_color_override("default_color", Color.BLACK)
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
	content.add_theme_color_override("default_color", Color.BLACK)
	
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
	
	# Add all fields with neutral formatting
	for key in doc_data.keys():
		if key == "type":
			continue
			
		var value = str(doc_data[key])
		var formatted_key = format_field_name(key)
		
		# NO HINTS! Show everything neutrally
		text += "[b]%s:[/b] %s\n" % [formatted_key, value]
	
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
	
	# Set dark text color for readability
	rules_text.add_theme_color_override("default_color", Color.BLACK)
	
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
	text += "• DDR: Personalausweis + Ausreisegenehmigung\n"
	text += "• Polen: Reisepass + Visum erforderlich\n"
	text += "• BRD: Reisepass + Transitvisum\n"
	text += "• UdSSR: Diplomatenstatus beachten\n"
	
	text += "\n[b]BESONDERE HINWEISE:[/b]\n"
	text += "• Fahndungsliste beachten\n"
	text += "• Republikflucht-Verdacht melden\n"
	text += "• PM-12 = Absolutes Reiseverbot\n"
	
	rules_text.text = text
	print("Rules display updated!")

func update_status_display():
	if not status_info:
		print("ERROR: status_info not found!")
		return
	
	# Set dark text color for readability
	status_info.add_theme_color_override("default_color", Color.BLACK)
	
	var accuracy = 100.0
	if game_stats.total_processed > 0:
		accuracy = (game_stats.correct_decisions * 100.0) / game_stats.total_processed
	
	var text = "[center][b][font_size=18]SCHICHT STATUS[/font_size][/b][/center]\n\n"
	text += "[b]Tag:[/b] %d\n" % day_counter
	text += "[b]Bearbeitet:[/b] %d/%d\n" % [daily_travelers_processed, daily_quota]
	text += "[b]Genehmigt:[/b] %d\n" % approved_count
	text += "[b]Abgelehnt:[/b] %d\n" % rejected_count
	text += "[b]Genauigkeit:[/b] %.1f%%\n\n" % accuracy
	
	if accuracy >= 90:
		text += "[b]Status: AUSGEZEICHNET[/b]"
	elif accuracy >= 75:
		text += "[b]Status: GUT[/b]"
	elif accuracy >= 60:
		text += "[b]Status: AKZEPTABEL[/b]"
	else:
		text += "[b]Status: VERBESSERUNG NOETIG[/b]"
	
	status_info.text = text
	print("Status display updated!")

func _on_approve_pressed():
	print("\n=== APPROVE BUTTON PRESSED ===")
	process_decision(true)

func _on_reject_pressed():
	print("\n=== REJECT BUTTON PRESSED ===")
	process_decision(false)

func _on_watchlist_pressed():
	print("=== WATCHLIST BUTTON PRESSED ===")
	show_watchlist()

func _on_close_watchlist_pressed():
	print("=== CLOSE WATCHLIST BUTTON PRESSED ===")
	hide_watchlist()

func show_watchlist():
	if not watchlist_overlay:
		print("ERROR: watchlist_overlay not found!")
		return
	
	print("Showing watchlist...")
	watchlist_overlay.visible = true
	
	# Simple fade in
	watchlist_overlay.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(watchlist_overlay, "modulate:a", 1.0, 0.3)

func hide_watchlist():
	if not watchlist_overlay:
		return
	
	print("Hiding watchlist...")
	var tween = create_tween()
	tween.tween_property(watchlist_overlay, "modulate:a", 0.0, 0.2)
	await tween.finished
	watchlist_overlay.visible = false

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
	
	# Set dark text color for feedback
	feedback_title.add_theme_color_override("font_color", Color.BLACK)
	feedback_message.add_theme_color_override("default_color", Color.BLACK)
	
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
	update_validation_watchlist()  # Update watchlist for new day
	approved_count = 0
	rejected_count = 0
	start_game()
