extends Node
class_name ValidationEngine
const Document = preload("res://scripts/documents/Document.gd")

# Validation result structure
class ValidationResult:
        var is_valid: bool = true
        var violations: Array = []
        var warnings: Array = []

        func add_violation(code: String, details: String = ""):
                is_valid = false
                violations.append({"code": code, "details": details})

        func add_warning(code: String, details: String = ""):
                warnings.append({"code": code, "details": details})

# Current game rules (changes per day)
var current_rules = {
        "required_docs": {
                "DDR": ["personalausweis"],
                "BRD": ["reisepass", "transitvisum"],
                "Polen": ["reisepass", "visum"],
                "default": ["reisepass"]
        },
        "check_expiry": true,
        "check_photo": false,  # Enabled from day 3
        "check_pkz": false,     # Enabled from day 5
        "check_stamps": false,  # Enabled from day 7
        "check_watchlist": true,
        "check_pm12": false,    # Enabled from day 10
        "current_date": "1989-08-01"
}

# Watchlist database
var watchlist = [
        {"name": "Schmidt", "vorname": "Werner", "reason": "republikflucht_attempt"},
        {"name": "Mueller", "vorname": "Sabine", "reason": "west_contact"}
]

# Stamp validation database
var valid_stamp_patterns = {
        "einreise": ["Marienborn", "Friedrichstrasse", "Bornholmer"],
        "ausreise": ["Marienborn", "Friedrichstrasse", "Checkpoint_Charlie"]
}

# Main validation function
func validate_traveler(traveler_data: Dictionary, presented_docs: Array) -> ValidationResult:
        var result = ValidationResult.new()

        # Step 1: Determine required documents based on nationality
        var required_docs = _get_required_documents(traveler_data.get("nationality", "unknown"))

        # Step 2: Check if all required documents are present
        _check_required_documents(result, required_docs, presented_docs)

        # Step 3: Run parallel validation checks if documents present
        if result.violations.size() == 0:  # Only continue if docs are present
                for doc in presented_docs:
                        _validate_document(result, doc, traveler_data)

        # Step 4: Check against watchlist
        if current_rules.check_watchlist:
                _check_watchlist(result, traveler_data)

        # Step 5: DDR-specific checks
        _check_ddr_specific_rules(result, traveler_data, presented_docs)

        return result

# Get required documents based on nationality
func _get_required_documents(nationality: String) -> Array:
        if current_rules.required_docs.has(nationality):
                return current_rules.required_docs[nationality]
        return current_rules.required_docs["default"]

# Check if all required documents are present
func _check_required_documents(result: ValidationResult, required: Array, presented: Array):
        var presented_types = []
        for doc in presented:
                if doc is Document:
                        presented_types.append(doc.type)
                else:
                        presented_types.append(doc.get("type", "unknown"))

        for req_doc in required:
                if not req_doc in presented_types:
                        result.add_violation("missing_document", req_doc)

# Validate individual document
func _validate_document(result: ValidationResult, doc: Variant, traveler_data: Dictionary):
        var data: Dictionary = {}
        if doc is Document:
                data = doc.to_dict()
        else:
                data = doc
        var doc_type = data.get("type", "unknown")

        # Check expiry date
        if current_rules.check_expiry:
                _check_expiry_date(result, data, doc_type)

        # Check photo match
        if current_rules.check_photo and data.has("foto"):
                _check_photo_match(result, data, traveler_data)

        # Check personal data consistency
        _check_data_consistency(result, data, traveler_data)

        # Check PKZ (Personenkennzahl) for DDR documents
        if current_rules.check_pkz and doc_type == "personalausweis":
                _check_pkz(result, data, traveler_data)

        # Check stamps
        if current_rules.check_stamps and data.has("stamps"):
                _check_stamps(result, data)

        # Check for forgeries
        _check_forgery_indicators(result, data)

# Check document expiry
func _check_expiry_date(result: ValidationResult, doc: Dictionary, doc_type: String):
        if not doc.has("gueltig_bis"):
                result.add_violation("missing_expiry", doc_type)
                return

        var expiry = doc["gueltig_bis"]
        if _is_date_expired(expiry, current_rules.current_date):
                result.add_violation("expired_document", doc_type + " expired: " + expiry)

# Check photo match
func _check_photo_match(result: ValidationResult, doc: Dictionary, traveler_data: Dictionary):
        var doc_photo = doc.get("foto", "")
        var actual_photo = traveler_data.get("appearance", {}).get("foto", "")

        if doc_photo != actual_photo and doc_photo != "":
                result.add_violation("photo_mismatch", "Document photo doesn't match")

# Check data consistency across documents
func _check_data_consistency(result: ValidationResult, doc: Dictionary, traveler_data: Dictionary):
        # Check name consistency
        if doc.has("name") and traveler_data.has("name"):
                if doc["name"] != traveler_data["name"]:
                        result.add_violation("name_mismatch", "Name: " + doc["name"] + " vs " + traveler_data["name"])

        if doc.has("vorname") and traveler_data.has("vorname"):
                if doc["vorname"] != traveler_data["vorname"]:
                        result.add_violation("vorname_mismatch", "Vorname: " + doc["vorname"] + " vs " + traveler_data["vorname"])

        # Check birthdate consistency
        if doc.has("geburtsdatum") and traveler_data.has("geburtsdatum"):
                if doc["geburtsdatum"] != traveler_data["geburtsdatum"]:
                        result.add_violation("birthdate_mismatch", "Birthdate doesn't match")

# Check PKZ (DDR Personal ID number)
func _check_pkz(result: ValidationResult, doc: Dictionary, traveler_data: Dictionary):
        if not doc.has("pkz"):
                result.add_violation("missing_pkz", "PKZ required for DDR citizens")
                return

        var pkz = doc["pkz"]

        # PKZ format: DDMMYYXXXXXX (12 digits)
        if not pkz.match("^[0-9]{12}$"):
                result.add_violation("invalid_pkz_format", "PKZ must be 12 digits")
                return

        # Extract birthdate from PKZ
        var pkz_date = pkz.substr(0, 6)
        var birth = traveler_data.get("geburtsdatum", "").replace("-", "")

        # Convert YYYY-MM-DD to DDMMYY for comparison
        if birth.length() >= 8:
                var expected_pkz_date = birth.substr(6, 2) + birth.substr(4, 2) + birth.substr(2, 2)
                if pkz_date != expected_pkz_date:
                        result.add_violation("pkz_birthdate_mismatch", "PKZ doesn't match birthdate")

# Check stamps authenticity
func _check_stamps(result: ValidationResult, doc: Dictionary):
        var stamps = doc.get("stamps", [])

        for stamp in stamps:
                var stamp_type = stamp.get("type", "")
                var stamp_location = stamp.get("location", "")

                # Check if stamp location is valid
                if stamp_type in valid_stamp_patterns:
                        var valid_locations = valid_stamp_patterns[stamp_type]
                        if not stamp_location in valid_locations:
                                result.add_violation("invalid_stamp_location", stamp_type + " at " + stamp_location)

                # Check stamp date logic
                if stamp.has("date"):
                        if _is_date_expired(current_rules.current_date, stamp["date"]):
                                result.add_violation("future_stamp", "Stamp dated in future: " + stamp["date"])

# Check for forgery indicators
func _check_forgery_indicators(result: ValidationResult, doc: Dictionary):
        var forgery_signs = doc.get("forgery_indicators", [])

        for sign in forgery_signs:
                match sign:
                        "altered_date":
                                result.add_violation("forged_date", "Date appears altered")
                        "fake_stamp":
                                result.add_violation("forged_stamp", "Stamp appears counterfeit")
                        "photo_replaced":
                                result.add_violation("forged_photo", "Photo appears replaced")
                        "erased_text":
                                result.add_violation("forged_text", "Text has been erased/modified")
                        _:
                                result.add_violation("suspected_forgery", sign)

# Check against watchlist
func _check_watchlist(result: ValidationResult, traveler_data: Dictionary):
        var t_name = traveler_data.get("name", "")
        var t_vorname = traveler_data.get("vorname", "")

        for person in watchlist:
                if person.name == t_name and person.vorname == t_vorname:
                        result.add_violation("on_watchlist", person.reason)
                        break

# DDR-specific rules
func _check_ddr_specific_rules(result: ValidationResult, traveler_data: Dictionary, docs: Array):
        var nationality = traveler_data.get("nationality", "")

        # Check PM-12 restriction (no border crossing)
        if current_rules.check_pm12 and nationality == "DDR":
                for doc in docs:
                        var d = doc.to_dict() if doc is Document else doc
                        if d.get("type") == "personalausweis":
                                if d.get("pm12_vermerk", false):
                                        result.add_violation("pm12_restriction", "Border crossing prohibited")

        # Check Ausreisegenehmigung for DDR citizens leaving
        if nationality == "DDR" and traveler_data.get("direction", "") == "ausreise":
                var has_ausreise = false
                for doc in docs:
                        var d2 = doc.to_dict() if doc is Document else doc
                        if d2.get("type") == "ausreisegenehmigung":
                                has_ausreise = true
                                break

                if not has_ausreise:
                        result.add_violation("missing_ausreisegenehmigung", "DDR citizens need exit permit")

        # Check transit visa for West Germans
        if nationality == "BRD":
                var has_transit = false
                for doc in docs:
                        var d3 = doc.to_dict() if doc is Document else doc
                        if d3.get("type") == "transitvisum":
                                has_transit = true
                                if d3.get("route_restriction", "") == "direct_only":
                                        result.add_warning("transit_restriction", "Must use direct route only")
                                break

                if not has_transit:
                        result.add_violation("missing_transitvisum", "West Germans need transit visa")

        # Check for republikflucht risk indicators
        if nationality == "DDR":
                _check_republikflucht_risk(result, traveler_data, docs)

# Check for potential escape attempt
func _check_republikflucht_risk(result: ValidationResult, traveler_data: Dictionary, docs: Array):
        var risk_score = 0
        var risk_factors = []

        # One-way ticket
        if traveler_data.get("return_date", "") == "":
                risk_score += 2
                risk_factors.append("no_return_ticket")

        # Traveling with entire family
        if traveler_data.get("family_members", 0) > 2:
                risk_score += 1
                risk_factors.append("entire_family")

        # Suspicious amount of luggage
        if traveler_data.get("luggage_count", 0) > 3:
                risk_score += 1
                risk_factors.append("excessive_luggage")

        # Previous denials
        if traveler_data.get("previous_denials", 0) > 0:
                risk_score += 2
                risk_factors.append("previous_denials")

        if risk_score >= 3:
                result.add_warning("republikflucht_risk", risk_factors.join(", "))

# Utility: Check if date is expired
func _is_date_expired(date1: String, date2: String) -> bool:
        # Simple string comparison works for ISO date format YYYY-MM-DD
        return date1 < date2

# Update rules for new day
func update_rules_for_day(day: int):
        # Progressive difficulty
        match day:
                1, 2:
                        current_rules.check_expiry = true
                        current_rules.check_photo = false
                        current_rules.check_pkz = false
                3, 4:
                        current_rules.check_photo = true
                5, 6:
                        current_rules.check_pkz = true
                7, 8, 9:
                        current_rules.check_stamps = true
                _:
                        if day >= 10:
                                current_rules.check_pm12 = true
                        if day >= 15:
                                # Add more nationalities
                                current_rules.required_docs["UdSSR"] = ["reisepass", "visum"]
                        if day >= 20:
                                # Increase scrutiny
                                current_rules.required_docs["DDR"] = ["personalausweis", "arbeitsbuch"]

# Get denial reasons for UI
func get_denial_reason_text(violation_code: String) -> String:
        var reasons = {
                "missing_document": "Fehlende Dokumente",
                "expired_document": "Abgelaufene Dokumente",
                "photo_mismatch": "Foto stimmt nicht überein",
                "name_mismatch": "Name stimmt nicht überein",
                "on_watchlist": "Person auf Fahndungsliste",
                "pm12_restriction": "PM-12 Vermerk - Keine Grenzüberquerung",
                "missing_ausreisegenehmigung": "Keine Ausreisegenehmigung",
                "forged_document": "Gefälschte Dokumente",
                "invalid_pkz_format": "Ungültige Personenkennzahl",
                "republikflucht_risk": "Fluchtgefahr"
        }

        return reasons.get(violation_code, "Verstoß gegen Grenzbestimmungen")
