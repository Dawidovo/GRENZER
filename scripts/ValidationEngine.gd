extends Node
class_name ValidationEngine

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
		"UdSSR": ["reisepass"],
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
	
	# Null safety check
	if traveler_data == null or presented_docs == null:
		result.add_violation("null_data", "Traveler data or documents are null")
		return result
	
	# Step 1: Determine required documents based on nationality
	var required_docs = _get_required_documents(traveler_data.get("nationality", "unknown"))
	
	# Step 2: Check if all required documents are present
	_check_required_documents(result, required_docs, presented_docs)
	
	# Step 3: Run parallel validation checks if documents present
	if result.violations.size() == 0:  # Only continue if docs are present
		for doc in presented_docs:
			if doc != null:  # Null safety
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
		# Null safety check
		if doc != null and typeof(doc) == TYPE_DICTIONARY:
			presented_types.append(doc.get("type", "unknown"))
	
	for req_doc in required:
		if not req_doc in presented_types:
			result.add_violation("missing_document", req_doc)

# Validate individual document
func _validate_document(result: ValidationResult, doc: Dictionary, traveler_data: Dictionary):
	# Null safety
	if doc == null or typeof(doc) != TYPE_DICTIONARY:
		result.add_violation("invalid_document", "Document is null or invalid")
		return
		
	var doc_type = doc.get("type", "unknown")
	
	# *** FIXED: SPECIAL HANDLING for diplomatic documents ***
	if doc_type == "diplomatic_passport":
		# Diplomatic documents with full immunity bypass ALL checks
		if doc.get("immunity_status") == "full":
			return  # Skip all validation for full diplomatic immunity
		# If no full immunity, treat as regular passport
	
	# Regular document validation
	var doc_name = doc.get("name", "")
	var doc_vorname = doc.get("vorname", "")
	var traveler_name = traveler_data.get("name", "")
	var traveler_vorname = traveler_data.get("vorname", "")
	
	# Check document expiry
	if current_rules.check_expiry:
		var expiry_date = doc.get("gueltig_bis", doc.get("valid_until", ""))
		if expiry_date != "":
			if _is_date_expired(expiry_date, current_rules.current_date):
				result.add_violation("expired_document", doc_type + " expired")
		else:
			result.add_violation("missing_expiry", doc_type + " has no expiry date")
	
	# Check name match
	if doc_name != "" and traveler_name != "":
		if doc_name.to_lower() != traveler_name.to_lower():
			result.add_violation("name_mismatch", "Document name doesn't match")
	
	# Check vorname match
	if doc_vorname != "" and traveler_vorname != "":
		if doc_vorname.to_lower() != traveler_vorname.to_lower():
			result.add_violation("vorname_mismatch", "Document first name doesn't match")
	
	# Check birthdate match
	var doc_birthdate = doc.get("geburtsdatum", "")
	var traveler_birthdate = traveler_data.get("geburtsdatum", "")
	if doc_birthdate != "" and traveler_birthdate != "":
		if doc_birthdate != traveler_birthdate:
			result.add_violation("birthdate_mismatch", "Birthdate doesn't match")
	
	# Photo verification (if enabled)
	if current_rules.check_photo:
		_check_photo_match(result, doc, traveler_data)
	
	# PKZ validation (if enabled)
	if current_rules.check_pkz and doc_type == "personalausweis":
		_validate_pkz(result, doc, traveler_data)
	
	# Stamp validation (if enabled)
	if current_rules.check_stamps:
		_check_stamps(result, doc)
	
	# Check for forgery indicators
	_check_forgery_indicators(result, doc)

# Photo verification
func _check_photo_match(result: ValidationResult, doc: Dictionary, traveler_data: Dictionary):
	var doc_photo = doc.get("foto", "")
	var traveler_photo = traveler_data.get("appearance", {}).get("foto", "")
	
	if doc_photo != "" and traveler_photo != "":
		if doc_photo != traveler_photo:
			result.add_violation("photo_mismatch", "Photo doesn't match person")

# PKZ validation
func _validate_pkz(result: ValidationResult, doc: Dictionary, traveler_data: Dictionary):
	var pkz = doc.get("pkz", "")
	
	# Check PKZ format (should be 12 digits: DDMMYY + 6 digits)
	if pkz.length() != 12:
		result.add_violation("invalid_pkz_format", "PKZ must be 12 digits")
		return
	
	# Extract birthdate from PKZ
	var pkz_day = pkz.substr(0, 2)
	var pkz_month = pkz.substr(2, 2)
	var pkz_year = pkz.substr(4, 2)
	
	# Convert to full date format for comparison
	var pkz_birthdate = "19" + pkz_year + "-" + pkz_month + "-" + pkz_day
	var traveler_birthdate = traveler_data.get("geburtsdatum", "")
	
	if traveler_birthdate != "" and pkz_birthdate != traveler_birthdate:
		result.add_violation("pkz_birthdate_mismatch", "PKZ birthdate doesn't match")

# Check stamps
func _check_stamps(result: ValidationResult, doc: Dictionary):
	var stamps = doc.get("stamps", [])
	
	for stamp_data in stamps:
		if stamp_data == null or typeof(stamp_data) != TYPE_DICTIONARY:
			continue
			
		var stamp_type = stamp_data.get("type", "")
		var stamp_location = stamp_data.get("location", "")
		
		# Check valid stamp locations
		if valid_stamp_patterns.has(stamp_type):
			if not stamp_location in valid_stamp_patterns[stamp_type]:
				result.add_violation("invalid_stamp_location", "Invalid stamp location: " + stamp_location)
		
		# Check for future-dated stamps
		if stamp_data.has("date"):
			if _is_date_expired(current_rules.current_date, stamp_data["date"]):
				result.add_violation("future_stamp", "Stamp dated in future: " + stamp_data["date"])

# Check for forgery indicators
func _check_forgery_indicators(result: ValidationResult, doc: Dictionary):
	var forgery_signs = doc.get("forgery_indicators", [])
	
	for forgery_indicator in forgery_signs:
		match forgery_indicator:
			"altered_date":
				result.add_violation("forged_date", "Date appears altered")
			"fake_stamp":
				result.add_violation("forged_stamp", "Stamp appears counterfeit")
			"photo_replaced":
				result.add_violation("forged_photo", "Photo appears replaced")
			"erased_text":
				result.add_violation("forged_text", "Text has been erased/modified")
			_:
				result.add_violation("suspected_forgery", forgery_indicator)

# Check against watchlist
func _check_watchlist(result: ValidationResult, traveler_data: Dictionary):
	var t_name = traveler_data.get("name", "")
	var t_vorname = traveler_data.get("vorname", "")
	
	for person in watchlist:
		if person.name == t_name and person.vorname == t_vorname:
			result.add_violation("on_watchlist", person.reason)
			break

# *** FIXED: DDR-specific rules - ALL TYPOS CORRECTED ***
func _check_ddr_specific_rules(result: ValidationResult, traveler_data: Dictionary, docs: Array):
	var nationality = traveler_data.get("nationality", "")
	
	# Check PM-12 restriction (no border crossing)
	if current_rules.check_pm12 and nationality == "DDR":
		for doc in docs:
			if doc != null and doc.get("type") == "personalausweis":
				if doc.get("pm12_vermerk", false):
					result.add_violation("pm12_restriction", "Border crossing prohibited")
	
	# Check Ausreisegenehmigung for DDR citizens leaving
	if nationality == "DDR" and traveler_data.get("direction", "") == "ausreise":
		var has_ausreise = false
		for doc in docs:
			if doc != null and doc.get("type") == "ausreisegenehmigung":
				has_ausreise = true
				break
		
		if not has_ausreise:
			result.add_violation("missing_ausreisegenehmigung", "DDR citizens need exit permit")
	
	# *** COMPLETELY FIXED: Check transit visa for West Germans ***
	if nationality == "BRD":
		var has_transit = false
		for doc in docs:
			if doc != null and doc.get("type") == "transitvisum":
				has_transit = true
				if doc.get("route_restriction", "") == "direct_only":
					result.add_warning("transit_restriction", "Must use direct route only")
				break
		
		if not has_transit:
			result.add_violation("missing_transitvisum", "West Germans need transit visa")
	
	# Check for republikflucht risk indicators
	if nationality == "DDR":
		_check_republikflucht_risk(result, traveler_data, docs)

# Check for potential escape attempt
func _check_republikflucht_risk(result: ValidationResult, traveler_data: Dictionary, _docs: Array):
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
		# In GDScript we join arrays differently
		var factors_text = ""
		for i in range(risk_factors.size()):
			factors_text += risk_factors[i]
			if i < risk_factors.size() - 1:
				factors_text += ", "
		result.add_warning("republikflucht_risk", factors_text)

# Utility: Check if date is expired
func _is_date_expired(date1: String, date2: String) -> bool:
	# Simple string comparison works for ISO date format YYYY-MM-DD
	# date1 is expired if it's earlier than or equal to date2
	return date1 <= date2

# Update rules for new day
func update_rules_for_day(day: int):
	# Reset rules first
	current_rules.check_expiry = true  # Always enabled
	current_rules.check_photo = false
	current_rules.check_pkz = false
	current_rules.check_stamps = false
	current_rules.check_pm12 = false
	
	# Progressive difficulty
	if day >= 3:
		current_rules.check_photo = true
	if day >= 5:
		current_rules.check_pkz = true
	if day >= 7:
		current_rules.check_stamps = true
	if day >= 10:
		current_rules.check_pm12 = true
	
	# Extended rules for later days
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
		"missing_transitvisum": "Fehlendes Transitvisum",  # *** COMPLETELY FIXED ***
		"forged_document": "Gefälschte Dokumente",
		"invalid_pkz_format": "Ungültige Personenkennzahl",
		"republikflucht_risk": "Fluchtgefahr"
	}
	
	return reasons.get(violation_code, "Verstoß gegen Grenzbestimmungen")
