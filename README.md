# DDR Papers Game

Ein "Papers Please" Klon im DDR-Setting

## Datenarchitektur

```mermaid
erDiagram
    DOCUMENT {
        string document_id
        enum document_type
        date ausstellungsdatum
        date ablaufdatum
        string document_nummer
        bool is_forged
        bool is_expired
        bool is_stolen
    }
    
    PERSON_DATA {
        string name
        string vorname
        date geburtsdatum
        string geburtsort
        string wohnort
        string beruf
        texture foto
        enum geschlecht
    }
    
    TRAVELER {
        string traveler_id
        string full_name
        int age
        string nationality
        string occupation
        string origin_country
        string destination
        enum travel_purpose
        int duration_of_stay
        bool is_on_watchlist
        bool is_wanted_criminal
        bool is_suspicious
    }
    
    VALIDATION_RULES {
        date current_date
        int quota_requirements
        float accuracy_threshold
        bool special_alert_active
    }
    
    GAME_STATE {
        int current_day
        int current_shift_hour
        int daily_approvals
        int daily_rejections
        float accuracy_rating
        int reputation_with_authorities
        int family_wellbeing
        int stress_level
    }
    
    GAME_EVENT {
        string event_id
        enum event_type
        int day_requirement
        float probability
        string title
        string description
        bool affects_story_branch
    }
    
    STAMPS_SEALS {
        string stamp_id
        string issuing_authority
        date stamp_date
        bool is_authentic
        string stamp_type
    }
    
    BACKGROUND_STORY {
        string story_text
        int nervous_behavior_level
        int consistency_score
        bool has_hidden_agenda
    }
    
    UI_STATE {
        rect document_inspection_area
        rect rulebook_panel
        rect approval_buttons
        bool timer_active
        int session_time_remaining
    }
    
    ASSET_MANAGER {
        dict document_templates
        dict character_portraits
        dict background_images
        dict sound_effects
        dict background_music
    }
    
    POLITICAL_FLAGS {
        bool is_family_separation_case
        bool defection_risk
        bool western_contact
        bool restricted_occupation
        int surveillance_level
    }
    
    DDR_SPECIFIC_DOCS {
        string arbeitserlaubnis_nummer
        string wohnberechtigung
        string reisegrund_details
        bool has_ausreisegenehmigung
        string sponsor_in_west
    }

    DOCUMENT ||--|| PERSON_DATA : "contains"
    DOCUMENT ||--o{ STAMPS_SEALS : "has_stamps"
    TRAVELER ||--o{ DOCUMENT : "carries"
    TRAVELER ||--|| BACKGROUND_STORY : "has_story"
    TRAVELER ||--|| POLITICAL_FLAGS : "has_political_status"
    
    GAME_STATE ||--o{ VALIDATION_RULES : "applies"
    GAME_STATE ||--o{ GAME_EVENT : "triggers"
    GAME_STATE ||--|| UI_STATE : "controls"
    
    VALIDATION_RULES ||--o{ DOCUMENT : "validates"
    VALIDATION_RULES ||--o{ TRAVELER : "checks_against"
    
    UI_STATE ||--|| ASSET_MANAGER : "uses_assets"
    
    TRAVELER ||--o{ GAME_EVENT : "can_trigger"
    DOCUMENT ||--o{ GAME_EVENT : "influences"
    DOCUMENT ||--o| DDR_SPECIFIC_DOCS : "may_contain"
