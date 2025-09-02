extends PanelContainer

signal document_clicked(document_data: Dictionary)
signal document_hovered(document_data: Dictionary)

var document_data: Dictionary = {}

@onready var content: RichTextLabel = RichTextLabel.new()

func _ready():
    add_child(content)
    content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    mouse_entered.connect(_on_mouse_entered)

func _gui_input(event):
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        emit_signal("document_clicked", document_data)

func set_document_data(data: Dictionary) -> void:
    document_data = data
    var text := "[b]%s[/b]\n" % document_data.get("type", "Dokument").to_upper()
    for key in document_data.keys():
        if key == "type":
            continue
        text += "%s: %s\n" % [key.capitalize(), str(document_data[key])]
    content.text = text

func set_selected(selected: bool) -> void:
    modulate = Color(1, 1, 1) if not selected else Color(0.8, 0.9, 1)

func highlight_error(_error_type: String) -> void:
    modulate = Color(1, 0.6, 0.6)

func animate_in() -> void:
    modulate.a = 0.0
    var tween = create_tween()
    tween.tween_property(self, "modulate:a", 1.0, 0.2)

func animate_out() -> void:
    var tween = create_tween()
    tween.tween_property(self, "modulate:a", 0.0, 0.2)
    await tween.finished
    queue_free()

func shake() -> void:
    var tween = create_tween()
    tween.tween_property(self, "position:x", position.x + 5, 0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    tween.tween_property(self, "position:x", position.x - 5, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    tween.tween_property(self, "position:x", position.x, 0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_mouse_entered() -> void:
    emit_signal("document_hovered", document_data)
