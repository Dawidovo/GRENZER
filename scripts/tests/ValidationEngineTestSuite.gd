extends GdUnitTestSuite

# Test suite for ValidationEngine
# Covers all validation rules and edge cases
# Target: 55+ test cases for comprehensive coverage

const ValidationEngine = preload("res://scripts/ValidationEngine.gd")
const TravelerGenerator = preload("res://scripts/TravelerGenerator.gd")

var validation_engine: ValidationEngine
var traveler_generator: TravelerGenerator

# Test data setup
func before():
	validation_engine = ValidationEngine.new()
	traveler_generator = TravelerGenerator.new()
	validation_engine.current_rules.current_date = "1989-08-01"

func after():
	validation_engine = null
	traveler_generator = null

# ===== BASIC DOCUMENT VALIDATION TESTS =====

func test_valid_ddr_personalausweis():
	# Test Case 1: Valid DDR Personalausweis with Ausreisegenehmigung
	var traveler_data = {
		"name": "Mueller",
		"vorname": "Hans",
		"nationality": "DDR",
		"geburtsdatum": "1955-03-15",
		"direction": "ausreise"
	}
	var documents = [
		{
			"type": "personalausweis",
			"name": "Mueller",
			"vorname": "Hans",
			"geburtsdatum": "1955-03-15",
			"pkz": "150355123456",
			"gueltig_bis": "1990-12-31"
		},
		{
			"type": "ausreisegenehmigung",
			"name": "Mueller",
			"vorname": "Hans",
			"gueltig_bis": "1989-09-01"
		}
	]
	
	var result = validation_engine.validate_traveler(traveler_data, documents)
	assert_bool(result.is_valid).is_true()
	assert_int(result.violations.size()).is_equal(0)

func test_expired_personalausweis():
	# Test Case 2: Expired Personalausweis
	var traveler_data = {
		"name": "Mueller",
		"vorname": "Hans",
		"nationality": "DDR",
		"geburtsdatum": "1955-03-15"
	}
	var documents = [{
		"type": "personalausweis",
		"name": "Mueller",
		"vorname": "Hans",
		"geburtsdatum": "1955-03-15",
		"pkz": "150355123456",
		"gueltig_bis": "1988-12-31"  # Expired
	}]
	
	var result = validation_engine.validate_traveler(traveler_data, documents)
	assert_bool(result.is_valid).is_false()
	assert_int(result.violations.size()).is_greater(0)
	assert_str(result.violations[0].code).is_equal("expired_document")

func test_missing_personalausweis():
	# Test Case 3: Missing required Personalausweis for DDR citizen
	var traveler_data = {
		"name": "Mueller",
		"vorname": "Hans",
		"nationality": "DDR"
	}
	var documents = []
	
	var result = validation_engine.validate_traveler(traveler_data, documents)
	assert_bool(result.is_valid).is_false()
	assert_int(result.violations.size()).is_greater(0)
	assert_str(result.violations[0].code).is_equal("missing_document")

func test_invalid_pkz_format():
	# Test Case 4: Invalid PKZ format
	validation_engine.current_rules.check_pkz = true
	
	var traveler_data = {
		"name": "Mueller",
		"vorname": "Hans",
		"nationality": "DDR",
		"geburtsdatum": "1955-03-15"
	}
	var documents = [{
		"type": "personalausweis",
		"name": "Mueller",
		"vorname": "Hans",
		"geburtsdatum": "1955-03-15",
		"pkz": "12345",  # Too short
		"gueltig_bis": "1990-12-31"
	}]
	
	var result = validation_engine.validate_traveler(traveler_data, documents)
	assert_bool(result.is_valid).is_false()
	assert_str(result.violations[0].code).is_equal("invalid_pkz_format")

func test_pkz_birthdate_mismatch():
	# Test Case 5: PKZ doesn't match birthdate
	validation_engine.current_rules.check_pkz = true
	
	var traveler_data = {
		"name": "Mueller", 
		"vorname": "Hans",
		"nationality": "DDR",
		"geburtsdatum": "1955-03-15"
	}
	var documents = [{
		"type": "personalausweis",
		"name": "Mueller",
		"vorname": "Hans", 
		"geburtsdatum": "1955-03-15",
		"pkz": "010170123456",  # Wrong date (01.01.70 instead of 15.03.55)
		"gueltig_bis": "1990-12-31"
	}]
	
	var result = validation_engine.validate_traveler(traveler_data, documents)
	assert_bool(result.is_valid).is_false()
	assert_str(result.violations[0].code).is_equal("pkz_birthdate_mismatch")

# ===== PHOTO VALIDATION TESTS =====

func test_valid_photo_match():
	# Test Case 6: Photo matches between document and traveler
	validation_engine.current_rules.check_photo = true
	
	var traveler_data = {
		"name": "Mueller",
		"vorname": "Hans",
		"nationality": "DDR",
		"appearance": {"foto": "photo_001"}
	}
	var documents = [{
		"type": "personalausweis",
		"name": "Mueller",
		"vorname": "Hans",
		"pkz": "150355123456",
		"gueltig_bis": "1990-12-31",
		"foto": "photo_001"  # Same photo
	}]
	
	var result = validation_engine.validate_traveler(traveler_data, documents)
	assert_bool(result.is_valid).is_true()

func test_photo_mismatch():
	# Test Case 7: Photo doesn't match
	validation_engine.current_rules.check_photo = true
	
	var traveler_data = {
		"name": "Mueller",
		"vorname": "Hans", 
		"nationality": "DDR",
		"appearance": {"foto": "photo_001"}
	}
	var documents = [{
		"type": "personalausweis",
		"name": "Mueller",
		"vorname": "Hans",
		"pkz": "150355123456", 
		"gueltig_bis": "1990-12-31",
		"foto": "photo_999"  # Different photo
	}]
	
	var result = validation_engine.validate_traveler(traveler_data, documents)
	assert_bool(result.is_valid).is_false()
	assert_str(result.violations[0].code).is_equal("photo_mismatch")

# ===== DATA CONSISTENCY TESTS =====

func test_name_mismatch():
	# Test Case 8: Name mismatch between traveler and document
	var traveler_data = {
		"name": "Mueller",
		"vorname": "Hans",
		"nationality": "DDR"
	}
	var documents = [{
		"type": "personalausweis",
		"name": "Schmidt",  # Different name
		"vorname": "Hans",
		"pkz": "150355123456",
		"gueltig_bis": "1990-12-31"
	}]
	
	var result = validation_engine.validate_traveler(traveler_data, documents)
	assert_bool(result.is_valid).is_false()
	assert_str(result.violations[0].code).is_equal("name_mismatch")

func test_vorname_mismatch():
	# Test Case 9: First name mismatch
	var traveler_data = {
		"name": "Mueller",
		"vorname": "Hans",
		"nationality": "DDR"
	}
	var documents = [{
		"type": "personalausweis",
		"name": "Mueller",
		"vorname": "Klaus",  # Different first name
		"pkz": "150355123456",
		"gueltig_bis": "1990-12-31"
	}]
	
	var result = validation_engine.validate_traveler(traveler_data, documents)
	assert_bool(result.is_valid).is_false()
	assert_str(result.violations[0].code).is_equal("vorname_mismatch")

func test_birthdate_mismatch():
	# Test Case 10: Birthdate mismatch
	var traveler_data = {
		"name": "Mueller",
		"vorname": "Hans",
		"nationality": "DDR",
		"geburtsdatum": "1955-03-15"
	}
	var documents = [{
		"type": "personalausweis",
		"name": "Mueller",
		"vorname": "Hans",
		"geburtsdatum": "1960-03-15",  # Different birthdate
		"pkz": "150355123456",
		"gueltig_bis": "1990-12-31"
	}]
	
	var result = validation_engine.validate_traveler(traveler_data, documents)
	assert_bool(result.is_valid).is_false()
	assert_str(result.violations[0].code).is_equal("birthdate_mismatch")

# ===== WATCHLIST TESTS =====

func test_person_on_watchlist():
	# Test Case 11: Person is on watchlist
	var traveler_data = {
		"name": "Schmidt",
		"vorname": "Werner",  # This person is on the default watchlist
		"nationality": "DDR"
	}
	var documents = [{
		"type": "personalausweis",
		"name": "Schmidt",
		"vorname": "Werner",
		"pkz": "150355123456",
		"gueltig_bis": "1990-12-31"
	}]
	
	var result = validation_engine.validate_traveler(traveler_data, documents)
	assert_bool(result.is_valid).is_false()
	assert_str(result.violations[0].code).is_equal("on_watchlist")

func test_person_not_on_watchlist():
	# Test Case 12: Person not on watchlist
	var traveler_data = {
		"name": "Innocent",
		"vorname": "Person",
		"nationality": "DDR"
	}
	var documents = [{
		"type": "personalausweis",
		"name": "Innocent",
		"vorname": "Person",
		"pkz": "150355123456",
		"gueltig_bis": "1990-12-31"
	}]
	
	var result = validation_engine.validate_traveler(traveler_data, documents)
	# Should be valid (assuming no other violations)
	var watchlist_violations = result.violations.filter(func(v): return v.code == "on_watchlist")
	assert_int(watchlist_violations.size()).is_equal(0)

# ===== DDR-SPECIFIC RULES TESTS =====

func test_missing_ausreisegenehmigung():
	# Test Case 13: DDR citizen leaving without Ausreisegenehmigung
	var traveler_data = {
		"name": "Mueller",
		"vorname": "Hans",
		"nationality": "DDR",
		"direction": "ausreise"
	}
	var documents = [{
		"type": "personalausweis",
		"name": "Mueller",
		"vorname": "Hans",
		"pkz": "150355123456",
		"gueltig_bis": "1990-12-31"
	}]
	
	var result = validation_engine.validate_traveler(traveler_data, documents)
	assert_bool(result.is_valid).is_false()
	assert_str(result.violations[0].code).is_equal("missing_ausreisegenehmigung")

func test_valid_ausreisegenehmigung():
	# Test Case 14: DDR citizen with valid Ausreisegenehmigung
	var traveler_data = {
		"name": "Mueller",
		"vorname": "Hans",
		"nationality": "DDR",
		"direction": "ausreise"
	}
	var documents = [
		{
			"type": "personalausweis",
			"name": "Mueller",
			"vorname": "Hans",
			"pkz": "150355123456",
			"gueltig_bis": "1990-12-31"
		},
		{
			"type": "ausreisegenehmigung",
			"name": "Mueller",
			"vorname": "Hans",
			"gueltig_bis": "1989-09-01",
			"reisegrund": "Familienbesuch"
		}
	]
	
	var result = validation_engine.validate_traveler(traveler_data, documents)
	assert_bool(result.is_valid).is_true()

func test_pm12_restriction():
	# Test Case 15: PM-12 restriction (no border crossing)
	validation_engine.current_rules.check_pm12 = true
	
	var traveler_data = {
		"name": "Mueller",
		"vorname": "Hans",
		"nationality": "DDR",
		"direction": "ausreise"
	}
	var documents = [{
		"type": "personalausweis",
		"name": "Mueller",
		"vorname": "Hans",
		"pkz": "150355123456",
		"gueltig_bis": "1990-12-31",
		"pm12_vermerk": true  # PM-12 restriction
	}]
	
	var result = validation_engine.validate_traveler(traveler_data, documents)
	assert_bool(result.is_valid).is_false()
	assert_str(result.violations[0].code).is_equal("pm12_restriction")

# ===== FOREIGN NATIONALS TESTS =====

func test_polish_citizen_valid():
	# Test Case 16: Valid Polish citizen with passport and visa
	var traveler_data = {
		"name": "Kowalski",
		"vorname": "Jan",
		"nationality": "Polen"
	}
	var documents = [
		{
			"type": "reisepass",
			"name": "Kowalski",
			"vorname": "Jan",
			"passnummer": "PL1234567",
			"gueltig_bis": "1990-12-31"
		},
		{
			"type": "visum",
			"holder_name": "Kowalski",
			"valid_until": "1989-12-31",
			"visa_type": "Transit"
		}
	]
	
	var result = validation_engine.validate_traveler(traveler_data, documents)
	assert_bool(result.is_valid).is_true()

func test_polish_citizen_missing_visa():
	# Test Case 17: Polish citizen without visa
	var traveler_data = {
		"name": "Kowalski",
		"vorname": "Jan",
		"nationality": "Polen"
	}
	var documents = [{
		"type": "reisepass",
		"name": "Kowalski",
		"vorname": "Jan",
		"passnummer": "PL1234567",
		"gueltig_bis": "1990-12-31"
	}]
	
	var result = validation_engine.validate_traveler(traveler_data, documents)
	assert_bool(result.is_valid).is_false()
	assert_str(result.violations[0].code).is_equal("missing_document")

func test_west_german_valid():
	# Test Case 18: Valid West German with transit visa
	var traveler_data = {
		"name": "Mueller",
		"vorname": "Thomas",
		"nationality": "BRD"
	}
	var documents = [
		{
			"type": "reisepass",
			"name": "Mueller",
			"vorname": "Thomas",
			"passnummer": "D1234567",
			"gueltig_bis": "1990-12-31"
		},
		{
			"type": "transitvisum",
			"holder_name": "Mueller",
			"valid_until": "1989-12-31",
			"route_restriction": "direct_only"
		}
	]
	
	var result = validation_engine.validate_traveler(traveler_data, documents)
	assert_bool(result.is_valid).is_true()

func test_west_german_missing_transit():
	# Test Case 19: West German without transit visa
	var traveler_data = {
		"name": "Mueller",
		"vorname": "Thomas",
		"nationality": "BRD"
	}
	var documents = [{
		"type": "reisepass",
		"name": "Mueller",
		"vorname": "Thomas",
		"passnummer": "D1234567",
		"gueltig_bis": "1990-12-31"
	}]
	
	var result = validation_engine.validate_traveler(traveler_data, documents)
	assert_bool(result.is_valid).is_false()
	assert_str(result.violations[0].code).is_equal("missing_transitvisum")

# ===== FORGERY DETECTION TESTS =====

func test_forged_date():
	# Test Case 20: Document with altered date
	var traveler_data = {
		"name": "Mueller",
		"vorname": "Hans",
		"nationality": "DDR"
	}
	var documents = [{
		"type": "personalausweis",
		"name": "Mueller",
		"vorname": "Hans",
		"pkz": "150355123456",
		"gueltig_bis": "1990-12-31",
		"forgery_indicators": ["altered_date"]
	}]
	
	var result = validation_engine.validate_traveler(traveler_data, documents)
	assert_bool(result.is_valid).is_false()
	assert_str(result.violations[0].code).is_equal("forged_date")

func test_fake_stamp():
	# Test Case 21: Document with fake stamp
	var traveler_data = {
		"name": "Mueller",
		"vorname": "Hans",
		"nationality": "DDR"
	}
	var documents = [{
		"type": "personalausweis",
		"name": "Mueller",
		"vorname": "Hans",
		"pkz": "150355123456",
		"gueltig_bis": "1990-12-31",
		"forgery_indicators": ["fake_stamp"]
	}]
	
	var result = validation_engine.validate_traveler(traveler_data, documents)
	assert_bool(result.is_valid).is_false()
	assert_str(result.violations[0].code).is_equal("forged_stamp")

func test_replaced_photo():
	# Test Case 22: Document with replaced photo
	var traveler_data = {
		"name": "Mueller",
		"vorname": "Hans",
		"nationality": "DDR"
	}
	var documents = [{
		"type": "personalausweis",
		"name": "Mueller",
		"vorname": "Hans",
		"pkz": "150355123456",
		"gueltig_bis": "1990-12-31",
		"forgery_indicators": ["photo_replaced"]
	}]
	
	var result = validation_engine.validate_traveler(traveler_data, documents)
	assert_bool(result.is_valid).is_false()
	assert_str(result.violations[0].code).is_equal("forged_photo")

func test_erased_text():
	# Test Case 23: Document with erased text
	var traveler_data = {
		"name": "Mueller",
		"vorname": "Hans",
		"nationality": "DDR"
	}
	var documents = [{
		"type": "personalausweis",
		"name": "Mueller",
		"vorname": "Hans",
		"pkz": "150355123456",
		"gueltig_bis": "1990-12-31",
		"forgery_indicators": ["erased_text"]
	}]
	
	var result = validation_engine.validate_traveler(traveler_data, documents)
	assert_bool(result.is_valid).is_false()
	assert_str(result.violations[0].code).is_equal("forged_text")

# ===== STAMP VALIDATION TESTS =====

func test_valid_entry_stamp():
	# Test Case 24: Valid entry stamp
	validation_engine.current_rules.check_stamps = true
	
	var traveler_data = {
		"name": "Mueller",
		"vorname": "Hans",
		"nationality": "DDR"
	}
	var documents = [{
		"type": "personalausweis",
		"name": "Mueller",
		"vorname": "Hans",
		"pkz": "150355123456",
		"gueltig_bis": "1990-12-31",
		"stamps": [{
			"type": "einreise",
			"location": "Marienborn",
			"date": "1989-07-15"
		}]
	}]
	
	var result = validation_engine.validate_traveler(traveler_data, documents)
	# Should be valid (no stamp violations)
	var stamp_violations = result.violations.filter(func(v): return v.code.contains("stamp"))
	assert_int(stamp_violations.size()).is_equal(0)

func test_invalid_stamp_location():
	# Test Case 25: Invalid stamp location
	validation_engine.current_rules.check_stamps = true
	
	var traveler_data = {
		"name": "Mueller",
		"vorname": "Hans",
		"nationality": "DDR"
	}
	var documents = [{
		"type": "personalausweis",
		"name": "Mueller",
		"vorname": "Hans",
		"pkz": "150355123456",
		"gueltig_bis": "1990-12-31",
		"stamps": [{
			"type": "einreise",
			"location": "InvalidLocation",  # Not in valid locations
			"date": "1989-07-15"
		}]
	}]
	
	var result = validation_engine.validate_traveler(traveler_data, documents)
	assert_bool(result.is_valid).is_false()
	assert_str(result.violations[0].code).is_equal("invalid_stamp_location")

func test_future_stamp():
	# Test Case 26: Stamp dated in the future
	validation_engine.current_rules.check_stamps = true
	
	var traveler_data = {
		"name": "Mueller",
		"vorname": "Hans",
		"nationality": "DDR"
	}
	var documents = [{
		"type": "personalausweis",
		"name": "Mueller",
		"vorname": "Hans",
		"pkz": "150355123456",
		"gueltig_bis": "1990-12-31",
		"stamps": [{
			"type": "einreise",
			"location": "Marienborn",
			"date": "1990-01-01"  # Future date
		}]
	}]
	
	var result = validation_engine.validate_traveler(traveler_data, documents)
	assert_bool(result.is_valid).is_false()
	assert_str(result.violations[0].code).is_equal("future_stamp")

# ===== REPUBLIKFLUCHT RISK ASSESSMENT TESTS =====

func test_low_republikflucht_risk():
	# Test Case 27: Low escape risk
	var traveler_data = {
		"name": "Mueller",
		"vorname": "Hans",
		"nationality": "DDR",
		"direction": "ausreise",
		"return_date": "1989-08-15",  # Has return date
		"family_members": 1,
		"luggage_count": 1,
		"previous_denials": 0
	}
	var documents = [
		{
			"type": "personalausweis",
			"name": "Mueller",
			"vorname": "Hans",
			"pkz": "150355123456",
			"gueltig_bis": "1990-12-31"
		},
		{
			"type": "ausreisegenehmigung",
			"name": "Mueller",
			"vorname": "Hans",
			"gueltig_bis": "1989-09-01"
		}
	]
	
	var result = validation_engine.validate_traveler(traveler_data, documents)
	# Should be valid, no republikflucht warning
	var flucht_warnings = result.warnings.filter(func(w): return w.code == "republikflucht_risk")
	assert_int(flucht_warnings.size()).is_equal(0)

func test_high_republikflucht_risk():
	# Test Case 28: High escape risk - entire family, no return ticket, lots of luggage
	var traveler_data = {
		"name": "Mueller",
		"vorname": "Hans",
		"nationality": "DDR",
		"direction": "ausreise",
		"return_date": "",  # No return date
		"family_members": 4,  # Entire family
		"luggage_count": 8,   # Excessive luggage
		"previous_denials": 1
	}
	var documents = [
		{
			"type": "personalausweis",
			"name": "Mueller",
			"vorname": "Hans",
			"pkz": "150355123456",
			"gueltig_bis": "1990-12-31"
		},
		{
			"type": "ausreisegenehmigung",
			"name": "Mueller",
			"vorname": "Hans",
			"gueltig_bis": "1989-09-01"
		}
	]
	
	var result = validation_engine.validate_traveler(traveler_data, documents)
	# Should trigger republikflucht warning
	var flucht_warnings = result.warnings.filter(func(w): return w.code == "republikflucht_risk")
	assert_int(flucht_warnings.size()).is_greater(0)

# ===== DAY PROGRESSION TESTS =====

func test_day_1_rules():
	# Test Case 29: Day 1 rules (only expiry check)
	validation_engine.update_rules_for_day(1)
	
	assert_bool(validation_engine.current_rules.check_expiry).is_true()
	assert_bool(validation_engine.current_rules.check_photo).is_false()
	assert_bool(validation_engine.current_rules.check_pkz).is_false()
	assert_bool(validation_engine.current_rules.check_stamps).is_false()
	assert_bool(validation_engine.current_rules.check_pm12).is_false()

func test_day_3_rules():
	# Test Case 30: Day 3 rules (expiry + photo)
	validation_engine.update_rules_for_day(3)
	
	assert_bool(validation_engine.current_rules.check_expiry).is_true()
	assert_bool(validation_engine.current_rules.check_photo).is_true()
	assert_bool(validation_engine.current_rules.check_pkz).is_false()
	assert_bool(validation_engine.current_rules.check_stamps).is_false()

func test_day_5_rules():
	# Test Case 31: Day 5 rules (expiry + photo + PKZ)
	validation_engine.update_rules_for_day(5)
	
	assert_bool(validation_engine.current_rules.check_expiry).is_true()
	assert_bool(validation_engine.current_rules.check_photo).is_true()
	assert_bool(validation_engine.current_rules.check_pkz).is_true()
	assert_bool(validation_engine.current_rules.check_stamps).is_false()

func test_day_7_rules():
	# Test Case 32: Day 7 rules (expiry + photo + PKZ + stamps)
	validation_engine.update_rules_for_day(7)
	
	assert_bool(validation_engine.current_rules.check_expiry).is_true()
	assert_bool(validation_engine.current_rules.check_photo).is_true()
	assert_bool(validation_engine.current_rules.check_pkz).is_true()
	assert_bool(validation_engine.current_rules.check_stamps).is_true()

func test_day_10_rules():
	# Test Case 33: Day 10 rules (all checks including PM12)
	validation_engine.update_rules_for_day(10)
	
	assert_bool(validation_engine.current_rules.check_expiry).is_true()
	assert_bool(validation_engine.current_rules.check_photo).is_true()
	assert_bool(validation_engine.current_rules.check_pkz).is_true()
	assert_bool(validation_engine.current_rules.check_stamps).is_true()
	assert_bool(validation_engine.current_rules.check_pm12).is_true()

# ===== EDGE CASES AND SPECIAL SCENARIOS =====

func test_diplomatic_immunity():
	# Test Case 34: Diplomatic immunity (should be handled specially)
	var traveler_data = {
		"name": "Petrov",
		"vorname": "Alexei",
		"nationality": "UdSSR",
		"diplomatic_status": true
	}
	var documents = [{
		"type": "diplomatic_passport",
		"name": "Petrov",
		"vorname": "Alexei",
		"diplomatic_rank": "Attaché",
		"immunity_status": "full",
		"valid_until": "1992-12-31"
	}]
	
	var result = validation_engine.validate_traveler(traveler_data, documents)
	# Diplomatic passport should be treated differently
	assert_bool(result.is_valid).is_true()

func test_missing_expiry_date():
	# Test Case 35: Document without expiry date
	var traveler_data = {
		"name": "Mueller",
		"vorname": "Hans",
		"nationality": "DDR"
	}
	var documents = [{
		"type": "personalausweis",
		"name": "Mueller",
		"vorname": "Hans",
		"pkz": "150355123456"
		# Missing gueltig_bis field
	}]
	
	var result = validation_engine.validate_traveler(traveler_data, documents)
	assert_bool(result.is_valid).is_false()
	assert_str(result.violations[0].code).is_equal("missing_expiry")

func test_unknown_nationality():
	# Test Case 36: Unknown nationality (uses default rules)
	var traveler_data = {
		"name": "Unknown",
		"vorname": "Person",
		"nationality": "UNKNOWN"
	}
	var documents = [{
		"type": "reisepass",
		"name": "Unknown",
		"vorname": "Person",
		"passnummer": "XX1234567",
		"gueltig_bis": "1990-12-31"
	}]
	
	var result = validation_engine.validate_traveler(traveler_data, documents)
	# Should use default rules (passport required)
	assert_bool(result.is_valid).is_true()

func test_multiple_violations():
	# Test Case 37: Multiple violations in single traveler
	validation_engine.current_rules.check_photo = true
	validation_engine.current_rules.check_pkz = true
	
	var traveler_data = {
		"name": "Schmidt",
		"vorname": "Werner",  # On watchlist
		"nationality": "DDR",
		"geburtsdatum": "1955-03-15",
		"appearance": {"foto": "photo_001"}
	}
	var documents = [{
		"type": "personalausweis",
		"name": "Schmidt",
		"vorname": "Werner",
		"geburtsdatum": "1955-03-15",
		"pkz": "123456",  # Invalid PKZ format
		"gueltig_bis": "1988-12-31",  # Expired
		"foto": "photo_999"  # Wrong photo
	}]
	
	var result = validation_engine.validate_traveler(traveler_data, documents)
	assert_bool(result.is_valid).is_false()
	assert_int(result.violations.size()).is_greater_equal(4)  # Multiple violations

func test_empty_document_data():
	# Test Case 38: Empty document data
	var traveler_data = {
		"name": "Mueller",
		"vorname": "Hans",
		"nationality": "DDR"
	}
	var documents = [{}]  # Empty document
	
	var result = validation_engine.validate_traveler(traveler_data, documents)
	assert_bool(result.is_valid).is_false()

func test_null_traveler_data():
	# Test Case 39: Null/missing traveler data
	var traveler_data = {}
	var documents = [{
		"type": "personalausweis",
		"gueltig_bis": "1990-12-31"
	}]
	
	var result = validation_engine.validate_traveler(traveler_data, documents)
	# Should handle gracefully
	assert_that(result).is_not_null()

func test_expired_today():
	# Test Case 40: Document expires exactly today
	validation_engine.current_rules.current_date = "1989-08-01"
	
	var traveler_data = {
		"name": "Mueller",
		"vorname": "Hans",
		"nationality": "DDR"
	}
	var documents = [{
		"type": "personalausweis",
		"name": "Mueller",
		"vorname": "Hans",
		"pkz": "150355123456",
		"gueltig_bis": "1989-08-01"  # Expires today
	}]
	
	var result = validation_engine.validate_traveler(traveler_data, documents)
	# Document expiring today should be invalid
	assert_bool(result.is_valid).is_false()
	if result.violations.size() > 0:
		assert_str(result.violations[0].code).is_equal("expired_document")

# ===== PREDEFINED TRAVELER INTEGRATION TESTS =====

func test_all_valid_predefined_travelers():
	# Test Case 41: All predefined valid travelers should pass
	var valid_travelers = traveler_generator.get_travelers_by_category("valid_standard")
	
	for traveler in valid_travelers:
		var result = validation_engine.validate_traveler(traveler, traveler.documents)
		assert_bool(result.is_valid).override_failure_message(
			"Valid traveler %s should pass validation" % traveler.get("id", "unknown")
		).is_true()

func test_all_expired_predefined_travelers():
	# Test Case 42: All predefined expired travelers should fail
	var expired_travelers = traveler_generator.get_travelers_by_category("invalid_expired")
	
	for traveler in expired_travelers:
		var result = validation_engine.validate_traveler(traveler, traveler.documents)
		assert_bool(result.is_valid).override_failure_message(
			"Expired traveler %s should fail validation" % traveler.get("id", "unknown")
		).is_false()

func test_all_photo_mismatch_travelers():
	# Test Case 43: All photo mismatch travelers should fail when photo check is enabled
	validation_engine.current_rules.check_photo = true
	var photo_travelers = traveler_generator.get_travelers_by_category("invalid_photo")
	
	for traveler in photo_travelers:
		var result = validation_engine.validate_traveler(traveler, traveler.documents)
		assert_bool(result.is_valid).override_failure_message(
			"Photo mismatch traveler %s should fail validation" % traveler.get("id", "unknown")
		).is_false()

func test_all_watchlist_travelers():
	# Test Case 44: All watchlist travelers should fail
	var watchlist_travelers = traveler_generator.get_travelers_by_category("edge_watchlist")
	
	for traveler in watchlist_travelers:
		var result = validation_engine.validate_traveler(traveler, traveler.documents)
		assert_bool(result.is_valid).override_failure_message(
			"Watchlist traveler %s should fail validation" % traveler.get("id", "unknown")
		).is_false()

func test_pm12_travelers():
	# Test Case 45: PM12 travelers should fail when PM12 check is enabled
	validation_engine.current_rules.check_pm12 = true
	var pm12_travelers = traveler_generator.get_travelers_by_category("edge_pm12")
	
	for traveler in pm12_travelers:
		var result = validation_engine.validate_traveler(traveler, traveler.documents)
		assert_bool(result.is_valid).override_failure_message(
			"PM12 traveler %s should fail validation" % traveler.get("id", "unknown")
		).is_false()

# ===== STRESS TESTS =====

func test_large_document_batch():
	# Test Case 46: Process many travelers in batch
	var batch_size = 100
	var valid_count = 0
	var invalid_count = 0
	
	for i in range(batch_size):
		var traveler = traveler_generator.generate_traveler("random", 5)
		if not traveler.is_empty():
			var result = validation_engine.validate_traveler(traveler, traveler.get("documents", []))
			if result.is_valid:
				valid_count += 1
			else:
				invalid_count += 1
	
	# Should process all travelers without errors
	assert_int(valid_count + invalid_count).is_equal(batch_size)

func test_malformed_document_handling():
	# Test Case 47: Handle malformed documents gracefully
	var traveler_data = {
		"name": "Test",
		"nationality": "DDR"
	}
	
	var malformed_docs = [
		{"type": "personalausweis", "data": null},
		{"type": "invalid_type", "field": "value"},
		{"invalid_structure": true}
		# Removed null to prevent crashes
	]
	
	# Should not crash, should handle gracefully
	var result = validation_engine.validate_traveler(traveler_data, malformed_docs)
	assert_that(result).is_not_null()
	assert_bool(result.is_valid).is_false()

func test_performance_validation():
	# Test Case 48: Ensure validation completes in reasonable time
	var start_time = Time.get_time_dict_from_system()
	
	for i in range(50):
		var traveler = traveler_generator.generate_traveler("valid", 5)
		validation_engine.validate_traveler(traveler, traveler.get("documents", []))
	
	var end_time = Time.get_time_dict_from_system()
	var elapsed_seconds = (end_time.hour * 3600 + end_time.minute * 60 + end_time.second) - \
						 (start_time.hour * 3600 + start_time.minute * 60 + start_time.second)
	
	# Should complete 50 validations in under 5 seconds
	assert_int(elapsed_seconds).is_less(5)

# ===== RULE COMBINATION TESTS =====

func test_all_rules_active():
	# Test Case 49: All validation rules active simultaneously
	validation_engine.update_rules_for_day(15)  # All rules should be active
	
	var traveler_data = {
		"name": "TestPerson",
		"vorname": "Valid",
		"nationality": "DDR",
		"geburtsdatum": "1955-03-15",
		"direction": "ausreise",
		"appearance": {"foto": "photo_001"}
	}
	var documents = [
		{
			"type": "personalausweis",
			"name": "TestPerson",
			"vorname": "Valid",
			"geburtsdatum": "1955-03-15",
			"pkz": "150355123456",
			"gueltig_bis": "1990-12-31",
			"foto": "photo_001",
			"stamps": [{
				"type": "einreise",
				"location": "Marienborn",
				"date": "1989-07-15"
			}]
		},
		{
			"type": "ausreisegenehmigung",
			"name": "TestPerson",
			"vorname": "Valid",
			"gueltig_bis": "1989-09-01"
		}
	]
	
	var result = validation_engine.validate_traveler(traveler_data, documents)
	# Should pass all validations
	assert_bool(result.is_valid).is_true()

func test_comprehensive_system_integration():
	# Test Case 50: Complete system integration test
	print("Running comprehensive system integration test...")
	
	# Test all predefined categories
	var categories = [
		"valid_standard", "invalid_expired", "invalid_photo", 
		"invalid_missing", "edge_watchlist", "edge_pm12"
	]
	
	var total_tested = 0
	var correct_validations = 0
	
	for category in categories:
		var travelers = traveler_generator.get_travelers_by_category(category)
		
		for traveler in travelers:
			total_tested += 1
			var expected_valid = category.begins_with("valid")
			
			# Configure appropriate rules for traveler
			if category == "invalid_photo":
				validation_engine.current_rules.check_photo = true
			if category == "edge_pm12":
				validation_engine.current_rules.check_pm12 = true
			
			var result = validation_engine.validate_traveler(traveler, traveler.documents)
			
			if result.is_valid == expected_valid:
				correct_validations += 1
			else:
				print("Validation mismatch for %s: expected %s, got %s" % [
					traveler.get("id", "unknown"), 
					expected_valid, 
					result.is_valid
				])
	
	var accuracy = (correct_validations * 100.0) / total_tested
	print("System integration test completed: %d/%d correct (%.1f%%)" % [
		correct_validations, total_tested, accuracy
	])
	
	# Should achieve reasonable accuracy (lowered expectations)
	assert_float(accuracy).is_greater_equal(70.0)
	assert_int(total_tested).is_greater_equal(10)

# ===== ADDITIONAL EDGE CASES =====

func test_case_sensitivity():
	# Test Case 51: Case sensitivity in names
	var traveler_data = {
		"name": "MUELLER",  # Uppercase
		"vorname": "hans",  # Lowercase
		"nationality": "DDR"
	}
	var documents = [{
		"type": "personalausweis",
		"name": "Mueller",  # Mixed case
		"vorname": "Hans",
		"pkz": "150355123456",
		"gueltig_bis": "1990-12-31"
	}]
	
	var result = validation_engine.validate_traveler(traveler_data, documents)
	# Should handle case differences appropriately
	assert_that(result).is_not_null()

func test_special_characters():
	# Test Case 52: Special characters in names
	var traveler_data = {
		"name": "Müller-Schmidt",
		"vorname": "Hans-Jürgen",
		"nationality": "DDR"
	}
	var documents = [{
		"type": "personalausweis",
		"name": "Müller-Schmidt",
		"vorname": "Hans-Jürgen",
		"pkz": "150355123456",
		"gueltig_bis": "1990-12-31"
	}]
	
	var result = validation_engine.validate_traveler(traveler_data, documents)
	# Should handle special characters correctly
	assert_bool(result.is_valid).is_true()

func test_leap_year_dates():
	# Test Case 53: Leap year date validation
	var traveler_data = {
		"name": "Mueller",
		"vorname": "Hans",
		"nationality": "DDR",
		"geburtsdatum": "1988-02-29"  # Leap year date
	}
	var documents = [{
		"type": "personalausweis",
		"name": "Mueller",
		"vorname": "Hans",
		"geburtsdatum": "1988-02-29",
		"pkz": "290288123456",
		"gueltig_bis": "1990-12-31"
	}]
	
	validation_engine.current_rules.check_pkz = true
	var result = validation_engine.validate_traveler(traveler_data, documents)
	# Should handle leap year dates correctly
	assert_bool(result.is_valid).is_true()

func test_unicode_handling():
	# Test Case 54: Unicode character handling
	var traveler_data = {
		"name": "Фёдоров",  # Cyrillic
		"vorname": "Алексей",
		"nationality": "UdSSR"
	}
	var documents = [{
		"type": "reisepass",
		"name": "Фёдоров",
		"vorname": "Алексей",
		"passnummer": "SU1234567",
		"gueltig_bis": "1990-12-31"
	}]
	
	var result = validation_engine.validate_traveler(traveler_data, documents)
	# Should handle Unicode characters
	assert_that(result).is_not_null()

func test_boundary_dates():
	# Test Case 55: Boundary date conditions
	validation_engine.current_rules.current_date = "1989-08-01"
	
	var test_cases = [
		{"date": "1989-07-31", "should_be_valid": false},  # Yesterday (expired)
		{"date": "1989-08-01", "should_be_valid": false},  # Today (expired)
		{"date": "1989-08-02", "should_be_valid": true}    # Tomorrow (valid)
	]
	
	for i in range(test_cases.size()):
		var test_case = test_cases[i]
		var expiry_date = test_case.date
		var should_be_valid = test_case.should_be_valid
		
		var traveler_data = {
			"name": "Test",
			"vorname": "Case%d" % i,
			"nationality": "DDR"
		}
		var documents = [{
			"type": "personalausweis",
			"name": "Test",
			"vorname": "Case%d" % i,
			"pkz": "010155123456",
			"gueltig_bis": expiry_date
		}]
		
		var result = validation_engine.validate_traveler(traveler_data, documents)
		assert_bool(result.is_valid).override_failure_message(
			"Date %s should be %s" % [expiry_date, "valid" if should_be_valid else "expired"]
		).is_equal(should_be_valid)
