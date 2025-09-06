extends Node

# Test suite for TravelerGenerator
const TravelerGenerator = preload("res://scripts/TravelerGenerator.gd")
const ValidationEngine = preload("res://scripts/ValidationEngine.gd")

var generator: TravelerGenerator
var validator: ValidationEngine
var test_results = {
	"passed": 0,
	"failed": 0,
	"tests": []
}

func _ready():
	print("=== STARTING TRAVELER GENERATOR TESTS ===\n")
	
	# Initialize components
	generator = TravelerGenerator.new()
	validator = ValidationEngine.new()
	validator.update_rules_for_day(5)  # Day 5 has most rules active
	
	# Run all tests
	await run_all_tests()
	
	# Print results
	print_test_results()
	
	# Quit after tests
	await get_tree().create_timer(2.0).timeout
	get_tree().quit()

func run_all_tests():
	print("Running comprehensive test suite...\n")
	
	# Test 1: Predefined travelers count
	test_predefined_count()
	
	# Test 2: Valid travelers
	await test_valid_travelers()
	
	# Test 3: Invalid travelers - Expired documents
	await test_expired_documents()
	
	# Test 4: Invalid travelers - Photo mismatch
	await test_photo_mismatch()
	
	# Test 5: Invalid travelers - Missing documents
	await test_missing_documents()
	
	# Test 6: Edge cases - Watchlist
	await test_watchlist_cases()
	
	# Test 7: Edge cases - PM12
	await test_pm12_cases()
	
	# Test 8: Edge cases - Special scenarios
	await test_special_edge_cases()
	
	# Test 9: Random generation
	await test_random_generation()
	
	# Test 10: Document generation consistency
	await test_document_consistency()

# Test 1: Check predefined travelers count
func test_predefined_count():
	var test_name = "Predefined Travelers Count"
	var predefined = generator.predefined_travelers
	var count = predefined.size()
	
	if count >= 30:
		record_test_pass(test_name, "Found %d predefined travelers (>= 30)" % count)
	else:
		record_test_fail(test_name, "Only %d predefined travelers (expected >= 30)" % count)

# Test 2: Valid travelers validation
func test_valid_travelers():
	var test_name = "Valid Travelers Validation"
	var valid_travelers = generator.get_travelers_by_category("valid_standard")
	var all_valid = true
	var failed_ids = []
	
	for traveler in valid_travelers:
		var result = validator.validate_traveler(traveler, traveler.documents)
		if not result.is_valid:
			all_valid = false
			failed_ids.append(traveler.get("id", "unknown"))
	
	if all_valid:
		record_test_pass(test_name, "All %d valid travelers passed validation" % valid_travelers.size())
	else:
		record_test_fail(test_name, "Valid travelers failed: %s" % str(failed_ids))

# Test 3: Expired documents
func test_expired_documents():
	var test_name = "Expired Documents Detection"
	var expired_travelers = generator.get_travelers_by_category("invalid_expired")
	var all_detected = true
	var undetected = []
	
	for traveler in expired_travelers:
		var result = validator.validate_traveler(traveler, traveler.documents)
		if result.is_valid:
			all_detected = false
			undetected.append(traveler.get("id", "unknown"))
		else:
			# Check if expiry was the reason
			var has_expiry_violation = false
			for violation in result.violations:
				if violation.code == "expired_document":
					has_expiry_violation = true
					break
			if not has_expiry_violation:
				all_detected = false
				undetected.append(traveler.get("id", "unknown") + " (wrong reason)")
	
	if all_detected:
		record_test_pass(test_name, "All expired documents detected correctly")
	else:
		record_test_fail(test_name, "Failed to detect expired: %s" % str(undetected))

# Test 4: Photo mismatch
func test_photo_mismatch():
	var test_name = "Photo Mismatch Detection"
	var photo_travelers = generator.get_travelers_by_category("invalid_photo")
	
	# Need to enable photo checking for this test
	var old_photo_check = validator.current_rules.check_photo
	validator.current_rules.check_photo = true
	
	var all_detected = true
	var undetected = []
	
	for traveler in photo_travelers:
		var result = validator.validate_traveler(traveler, traveler.documents)
		if result.is_valid:
			all_detected = false
			undetected.append(traveler.get("id", "unknown"))
		else:
			# Check if photo was the reason
			var has_photo_violation = false
			for violation in result.violations:
				if violation.code == "photo_mismatch":
					has_photo_violation = true
					break
			if not has_photo_violation:
				all_detected = false
				undetected.append(traveler.get("id", "unknown") + " (wrong reason)")
	
	validator.current_rules.check_photo = old_photo_check
	
	if all_detected:
		record_test_pass(test_name, "All photo mismatches detected")
	else:
		record_test_fail(test_name, "Failed to detect photo mismatch: %s" % str(undetected))

# Test 5: Missing documents
func test_missing_documents():
	var test_name = "Missing Documents Detection"
	var missing_travelers = generator.get_travelers_by_category("invalid_missing")
	var all_detected = true
	var undetected = []
	
	for traveler in missing_travelers:
		var result = validator.validate_traveler(traveler, traveler.documents)
		if result.is_valid:
			all_detected = false
			undetected.append(traveler.get("id", "unknown"))
		else:
			# Check if missing document was detected
			var has_missing_violation = false
			for violation in result.violations:
				if violation.code.begins_with("missing_"):
					has_missing_violation = true
					break
			if not has_missing_violation:
				all_detected = false
				undetected.append(traveler.get("id", "unknown") + " (wrong reason)")
	
	if all_detected:
		record_test_pass(test_name, "All missing documents detected")
	else:
		record_test_fail(test_name, "Failed to detect missing: %s" % str(undetected))

# Test 6: Watchlist cases
func test_watchlist_cases():
	var test_name = "Watchlist Detection"
	var watchlist_travelers = generator.get_travelers_by_category("edge_watchlist")
	var all_detected = true
	var undetected = []
	
	for traveler in watchlist_travelers:
		var result = validator.validate_traveler(traveler, traveler.documents)
		if result.is_valid:
			all_detected = false
			undetected.append(traveler.get("id", "unknown"))
		else:
			# Check if watchlist was the reason
			var has_watchlist_violation = false
			for violation in result.violations:
				if violation.code == "on_watchlist":
					has_watchlist_violation = true
					break
			if not has_watchlist_violation:
				all_detected = false
				undetected.append(traveler.get("id", "unknown") + " (not on watchlist)")
	
	if all_detected:
		record_test_pass(test_name, "All watchlist persons detected")
	else:
		record_test_fail(test_name, "Failed to detect watchlist: %s" % str(undetected))

# Test 7: PM12 restriction
func test_pm12_cases():
	var test_name = "PM12 Restriction Detection"
	var pm12_travelers = generator.get_travelers_by_category("edge_pm12")
	
	# Enable PM12 checking
	var old_pm12_check = validator.current_rules.check_pm12
	validator.current_rules.check_pm12 = true
	
	var all_detected = true
	var undetected = []
	
	for traveler in pm12_travelers:
		var result = validator.validate_traveler(traveler, traveler.documents)
		if result.is_valid:
			all_detected = false
			undetected.append(traveler.get("id", "unknown"))
		else:
			# Check if PM12 was detected
			var has_pm12_violation = false
			for violation in result.violations:
				if violation.code == "pm12_restriction":
					has_pm12_violation = true
					break
			if not has_pm12_violation:
				all_detected = false
				undetected.append(traveler.get("id", "unknown") + " (PM12 not detected)")
	
	validator.current_rules.check_pm12 = old_pm12_check
	
	if all_detected:
		record_test_pass(test_name, "All PM12 restrictions detected")
	else:
		record_test_fail(test_name, "Failed to detect PM12: %s" % str(undetected))

# Test 8: Special edge cases
func test_special_edge_cases():
	var test_name = "Special Edge Cases"
	var test_cases = [
		"edge_republikflucht",
		"edge_diplomatic",
		"edge_minor",
		"edge_forgery",
		"edge_pkz_mismatch",
		"edge_dual_nationality"
	]
	
	var results = {}
	for case_type in test_cases:
		var travelers = generator.get_travelers_by_category(case_type)
		results[case_type] = travelers.size() > 0
	
	var all_present = true
	var missing = []
	for case_type in results:
		if not results[case_type]:
			all_present = false
			missing.append(case_type)
	
	if all_present:
		record_test_pass(test_name, "All special edge cases present")
	else:
		record_test_fail(test_name, "Missing edge cases: %s" % str(missing))

# Test 9: Random generation
func test_random_generation():
	var test_name = "Random Generation"
	var generation_works = true
	var errors = []
	
	# Test each generation type
	var types = ["valid", "invalid", "edge_case", "random"]
	
	for gen_type in types:
		var traveler = generator.generate_traveler(gen_type, 5)
		if traveler.is_empty():
			generation_works = false
			errors.append("Failed to generate: " + gen_type)
		elif not traveler.has("documents"):
			generation_works = false
			errors.append("No documents for: " + gen_type)
		elif traveler.documents.size() == 0:
			generation_works = false
			errors.append("Empty documents for: " + gen_type)
	
	if generation_works:
		record_test_pass(test_name, "All generation types working")
	else:
		record_test_fail(test_name, str(errors))

# Test 10: Document consistency
func test_document_consistency():
	var test_name = "Document Consistency"
	var consistent = true
	var issues = []
	
	# Generate multiple travelers and check document consistency
	for i in range(10):
		var traveler = generator.generate_traveler("valid", 5)
		
		# Check that personal data matches across documents
		var names_match = true
		var first_name = ""
		var first_vorname = ""
		
		for doc in traveler.documents:
			if doc.has("name"):
				if first_name == "":
					first_name = doc["name"]
				elif doc["name"] != first_name:
					names_match = false
					issues.append("Name mismatch in traveler %d" % i)
					break
			
			if doc.has("vorname"):
				if first_vorname == "":
					first_vorname = doc["vorname"]
				elif doc["vorname"] != first_vorname:
					names_match = false
					issues.append("Vorname mismatch in traveler %d" % i)
					break
		
		if not names_match:
			consistent = false
	
	if consistent:
		record_test_pass(test_name, "Document data consistent across all travelers")
	else:
		record_test_fail(test_name, str(issues))

# Helper functions
func record_test_pass(test_name: String, message: String):
	test_results.passed += 1
	test_results.tests.append({
		"name": test_name,
		"result": "PASS",
		"message": message
	})
	print("✓ %s: %s" % [test_name, message])

func record_test_fail(test_name: String, message: String):
	test_results.failed += 1
	test_results.tests.append({
		"name": test_name,
		"result": "FAIL",
		"message": message
	})
	print("✗ %s: %s" % [test_name, message])

func print_test_results():
	print("\n" + generator.get_test_summary())
	print("\n=== TEST RESULTS ===")
	print("Total Tests: %d" % (test_results.passed + test_results.failed))
	print("Passed: %d" % test_results.passed)
	print("Failed: %d" % test_results.failed)
	
	if test_results.failed == 0:
		print("\n✓✓✓ ALL TESTS PASSED ✓✓✓")
	else:
		print("\n✗✗✗ SOME TESTS FAILED ✗✗✗")
		print("Failed tests:")
		for test in test_results.tests:
			if test.result == "FAIL":
				print("  - %s: %s" % [test.name, test.message])
