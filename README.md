# GRENZER


# DDR Papers Game - Datenarchitektur

```mermaid
# DOKUMENT-SYSTEM
Document:
├── document_id: string
├── document_type: enum (Personalausweis, Reisepass, Arbeitserlaubnis, Ausreisegenehmigung, Transitvisum, Diplomatenpass)
├── person_data:
│   ├── name: string
│   ├── vorname: string  
│   ├── geburtsdatum: date
│   ├── geburtsort: string
│   ├── wohnort: string
│   ├── beruf: string
│   ├── foto: texture
│   └── geschlecht: enum
├── validity_data:
│   ├── ausstellungsdatum: date
│   ├── ablaufdatum: date
│   ├── ausstellende_behörde: string
│   └── document_nummer: string
├── stamps_seals:
│   ├── official_stamps[]: array
│   ├── entry_stamps[]: array
│   ├── signatures[]: array
│   └── special_markings[]: array
├── authenticity:
│   ├── is_forged: bool
│   ├── is_expired: bool
│   ├── is_stolen: bool
│   └── discrepancies[]: array

# PERSONEN-SYSTEM  
Traveler:
├── traveler_id: string
├── personal_info:
│   ├── full_name: string
│   ├── age: int
│   ├── nationality: string
│   ├── occupation: string
│   ├── appearance_description: string
│   └── photo_reference: texture
├── travel_info:
│   ├── origin_country: string
│   ├── destination: string
│   ├── travel_purpose: enum (Geschäft, Besuch, Rückkehr, Transit, Flucht)
│   ├── duration_of_stay: int
│   └── previous_visits: int
├── documents_carried[]: array<Document>
├── background_story:
│   ├── story_text: string
│   ├── dialogue_responses[]: array
│   ├── nervous_behavior_level: int
│   └── consistency_flags[]: array
├── flags:
│   ├── is_on_watchlist: bool
│   ├── is_wanted_criminal: bool
│   ├── is_family_member: bool
│   ├── is_suspicious: bool
│   └── special_story_character: bool

# REGELWERK-SYSTEM
ValidationRules:
├── daily_rules:
│   ├── current_date: date
│   ├── active_restrictions[]: array
│   ├── required_documents_per_purpose: dict
│   ├── banned_countries[]: array
│   ├── special_alerts[]: array
│   └── quota_requirements: dict
├── document_validation:
│   ├── mandatory_fields_per_doctype: dict
│   ├── valid_issuing_authorities[]: array  
│   ├── acceptable_age_ranges: dict
│   ├── cross_reference_requirements[]: array
│   └── stamp_requirements: dict
├── political_rules:
│   ├── wanted_persons[]: array
│   ├── restricted_occupations[]: array
│   ├── suspicious_travel_patterns[]: array
│   ├── family_separation_cases[]: array
│   └── defection_risk_factors[]: array

# SPIELZUSTAND-MANAGEMENT
GameState:
├── progression:
│   ├── current_day: int
│   ├── current_shift_hour: int
│   ├── total_days_worked: int
│   └── story_chapter: int
├── performance:
│   ├── daily_approvals: int
│   ├── daily_rejections: int
│   ├── accuracy_rating: float
│   ├── speed_rating: float
│   └── weekly_performance_average: float
├── player_status:
│   ├── reputation_with_authorities: int
│   ├── family_wellbeing: int
│   ├── personal_moral_standing: int
│   ├── financial_situation: int
│   └── stress_level: int
├── unlocked_content:
│   ├── available_document_types[]: array
│   ├── known_contraband_methods[]: array
│   ├── story_paths_opened[]: array
│   └── character_relationships[]: array

# EVENT-SYSTEM
GameEvent:
├── event_id: string
├── event_type: enum (StoryEvent, RandomEvent, ConsequenceEvent)
├── trigger_conditions:
│   ├── day_requirement: int
│   ├── performance_requirement: dict
│   ├── previous_choices[]: array
│   └── probability: float
├── event_data:
│   ├── title: string
│   ├── description: string
│   ├── dialogue_tree: DialogueNode
│   ├── consequences[]: array
│   └── affects_story_branch: bool

# UI-DATEN-MANAGEMENT
UIState:
├── workspace_layout:
│   ├── document_inspection_area: rect
│   ├── rulebook_panel: rect
│   ├── approval_buttons: rect
│   └── information_displays: rect
├── current_session:
│   ├── active_traveler: Traveler
│   ├── displayed_documents[]: array
│   ├── inspection_notes[]: array
│   ├── timer_state: dict
│   └── help_system_state: dict
├── player_actions:
│   ├── document_examination_history[]: array
│   ├── decision_reasoning[]: array
│   ├── time_spent_per_case[]: array
│   └── mistakes_made[]: array

# AUDIO-VISUAL-ASSETS  
AssetManager:
├── document_templates[]: dict<string, texture>
├── character_portraits[]: dict<string, texture>  
├── background_images[]: dict<string, texture>
├── ui_elements[]: dict<string, texture>
├── sound_effects[]: dict<string, audio_stream>
├── background_music[]: dict<string, audio_stream>
└── fonts[]: dict<string, font_resource>
