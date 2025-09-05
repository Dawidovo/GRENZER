extends Control

# === EINFACHE NODE PFADE ===
@onready var traveler_info: RichTextLabel = $MainContainer/ContentContainer/LeftSide/TravelerPanel/TravelerInfo
@onready var document_container: VBoxContainer = $MainContainer/ContentContainer/LeftSide/DocumentPanel/DocumentScroll/DocumentArea
@onready var approve_button: Button = $MainContainer/ButtonContainer/ApproveButton
@onready var reject_button: Button = $MainContainer/ButtonContainer/RejectButton
@onready var rules_text: RichTextLabel = $MainContainer/ContentContainer/RightSide/RulesPanel/RulesText
@onready var status_info: RichTextLabel = $MainContainer/ContentContainer/RightSide/StatusPanel/StatusInfo
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
	
	# Test BBCode immediately
	if traveler_info:
		print("Testing BBCode on traveler_info...")
		traveler_info.text = "[b]TEST BOLD[/b] and [color=red]RED TEXT[/color]"
		print("BBCode enabled: ", traveler_info.bbcode_enabled)
	
	if rules_text:
		print("Testing BBCode on rules_text...")
		rules_text.text = "[center][b]REGEL TEST[/b][/center]\n[color=green]Grün[/color]"
		print("BBCode enabled: ", rules_text.bbcode_enabled)

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
		return
	
	# Clear old documents
	clear_documents()
	
	# Generate new traveler
	print("Generating traveler...")
	current_traveler = traveler_generator.get_random_predefined_traveler()
	
	if current_traveler.is_empty():
		print("ERROR: No traveler generated!")
		current_traveler = {
			"name": "Test",
			"vorname": "Person", 
			"age": 30,
			"nationality": "DDR",
			"purpose": "Test",
			"direction": "ausreise",
			"story": "Test traveler",
			"documents": [
				{
					"type": "personalausweis",
					"name": "Test",
					"vorname": "Person",
					"geburtsdatum": "1959-01-01",
					"pkz": "010159123456",
					"gueltig_bis": "1990-12-31"
				}
			]
		}
	
	daily_travelers_processed += 1
	
	print("Traveler loaded: ", current_traveler.get("name", "Unknown"))
	print("Documents: ", current_traveler.get("documents", []).size())
	
	# Update displays
	update_traveler_display()
	create_document_display()
	update_status_display()

func update_traveler_display():
	if not traveler_info:
		print("ERROR: traveler_info not found!")
		return
	
	print("Updating traveler display...")
	
	var text = "[center][b]REISENDER #%d[/b][/center]\n\n" % daily_travelers_processed
	text += "[b]Name:[/b] %s, %s\n" % [current_traveler.get("name", "?"), current_traveler.get("vorname", "?")]
	text += "[b]Alter:[/b] %d Jahre\n" % current_traveler.get("age", 0)
	text += "[b]Nationalität:[/b] %s\n" % current_traveler.get("nationality", "?")
	text += "[b]Zweck:[/b] %s\n" % current_traveler.get("purpose", "?")
	text += "[b]Richtung:[/b] %s\n\n" % current_traveler.get("direction", "?")
	
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
		var label = Label.new()
		label.text = "KEINE DOKUMENTE"
		label.add_theme_color_override("font_color", Color.RED)
		document_container.add_child(label)
		document_panels.append(label)
		return
	
	# Create document panels
	for i in range(documents.size()):
		var doc = documents[i]
		print("Creating panel for document ", i, ": ", doc.get("type", "unknown"))
		
		var panel = create_document_panel(doc)
		document_container.add_child(panel)
		document_panels.append(panel)
		
		await get_tree().create_timer(0.1).timeout

func create_document_panel(doc_data: Dictionary) -> Control:
	print("Creating document panel for: ", doc_data)
	
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(300, 200)
	
	# Style panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color.BLACK
	panel.add_theme_stylebox_override("panel", style)
	
	# Create content
	var content = RichTextLabel.new()
	content.bbcode_enabled = true
	content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.scroll_active = true
	
	# Set anchors to fill panel
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 10
	content.offset_top = 10
	content.offset_right = -10
	content.offset_bottom = -10
	
	# Build document text
	var text = "[center][b]%s[/b][/center]\n\n" % doc_data.get("type", "DOKUMENT").to_upper()
	
	# Add all fields
	for key in doc_data.keys():
		if key == "type":
			continue
		text += "[b]%s:[/b] %s\n" % [key.capitalize(), str(doc_data[key])]
	
	content.text = text
	panel.add_child(content)
	
	print("Document panel created with text: ", text.substr(0, 100), "...")
	
	return panel

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
	
	var text = "[center][b]GRENZBESTIMMUNGEN DDR[/b][/center]\n"
	text += "[center]TAG %d - SCHICHT 08:00[/center]\n\n" % day_counter
	text += "[b]AKTIVE KONTROLLEN:[/b]\n"
	text += "• Dokumentengültigkeit prüfen\n"
	text += "\n[b]BESONDERE HINWEISE:[/b]\n"
	text += "• [color=orange]Polen:[/color] Visum erforderlich\n"
	text += "• [color=orange]BRD:[/color] Transitvisum prüfen\n"
	text += "• [color=red]Fahndungsliste beachten[/color]\n"
	
	rules_text.text = text
	print("Rules display updated!")

func update_status_display():
	if not status_info:
		print("ERROR: status_info not found!")
		return
	
	var accuracy = 100.0
	if game_stats.total_processed > 0:
		accuracy = (game_stats.correct_decisions * 100.0) / game_stats.total_processed
	
	var text = "[center][b]SCHICHT STATUS[/b][/center]\n\n"
	text += "[b]Tag:[/b] %d\n" % day_counter
	text += "[b]Bearbeitet:[/b] %d/%d\n" % [daily_travelers_processed, daily_quota]
	text += "[b]Genehmigt:[/b] %d\n" % approved_count
	text += "[b]Abgelehnt:[/b] %d\n" % rejected_count
	text += "[b]Genauigkeit:[/b] %.1f%%\n\n" % accuracy
	text += "[color=green]🏆 Status: OK[/color]"
	
	status_info.text = text
	print("Status display updated!")

func _on_approve_pressed():
	print("\n=== APPROVE BUTTON PRESSED ===")
	process_decision(true)

func _on_reject_pressed():
	print("\n=== REJECT BUTTON PRESSED ===")
	process_decision(false)

func process_decision(approved: bool):
	print("Processing decision: ", "APPROVED" if approved else "REJECTED")
	
	# Simple validation for now
	var is_valid = true
	var feedback_text = ""
	
	if approved:
		approved_count += 1
		feedback_text = "[color=green][b]GENEHMIGT![/b][/color]\nReisender darf passieren."
	else:
		rejected_count += 1
		feedback_text = "[color=red][b]ABGELEHNT![/b][/color]\nReisender wurde zurückgewiesen."
	
	game_stats.total_processed += 1
	game_stats.correct_decisions += 1
	
	show_feedback("Entscheidung", feedback_text)
	
	# Continue after delay
	await get_tree().create_timer(2.0).timeout
	hide_feedback()
	
	# Load next traveler
	load_next_traveler()

func show_feedback(title: String, message: String):
	if not feedback_overlay or not feedback_message:
		print("ERROR: Feedback UI not found!")
		return
	
	print("Showing feedback: ", title)
	
	var title_label = feedback_overlay.get_node("FeedbackPanel/FeedbackContent/FeedbackTitle")
	if title_label:
		title_label.text = title
	
	feedback_message.text = message
	feedback_overlay.visible = true

func hide_feedback():
	if feedback_overlay:
		feedback_overlay.visible = false
