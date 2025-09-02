extends Node
class_name TravelerGenerator

# Document generation utilities
const DocumentFactory = preload("res://scripts/documents/DocumentFactory.gd")

# Random seed for reproducible testing
var rng = RandomNumberGenerator.new()

# Traveler generation statistics
var stats = {
	"total_generated": 0,
	"valid_cases": 0,
	"invalid_cases": 0,
	"edge_cases": 0
}

# Name databases
var ddr_surnames = ["Mueller", "Schmidt", "Weber", "Meyer", "Wagner", "Becker", "Schulz", "Hoffmann", "Koch", "Richter", "Klein", "Wolf", "Neumann", "Schwarz", "Zimmermann", "Krueger", "Braun", "Hofmann", "Hartmann", "Lange"]
var ddr_firstnames_m = ["Hans", "Klaus", "Werner", "Wolfgang", "Dieter", "Manfred", "Gerhard", "Horst", "Helmut", "Guenther", "Uwe", "Juergen", "Peter", "Karl", "Frank", "Thomas", "Michael", "Andreas", "Stefan", "Ralf"]
var ddr_firstnames_f = ["Ursula", "Ingrid", "Helga", "Christa", "Renate", "Monika", "Brigitte", "Karin", "Gisela", "Petra", "Sabine", "Gabriele", "Heike", "Angelika", "Martina", "Birgit", "Andrea", "Claudia", "Katrin", "Anja"]

var polish_surnames = ["Kowalski", "Nowak", "Wisniewski", "Wojcik", "Kowalczyk", "Kaminski", "Lewandowski", "Zielinski", "Szymanski", "Wozniak"]
var polish_firstnames_m = ["Jan", "Piotr", "Krzysztof", "Andrzej", "Stanislaw", "Tomasz", "Pawel", "Marcin", "Michal", "Marek"]
var polish_firstnames_f = ["Anna", "Maria", "Katarzyna", "Malgorzata", "Agnieszka", "Barbara", "Ewa", "Elzbieta", "Zofia", "Teresa"]

var brd_surnames = ["Müller", "Schneider", "Fischer", "Mayer", "Weber", "Schulze", "Wagner", "Bauer", "Schmitt", "Becker"]
var brd_firstnames_m = ["Thomas", "Michael", "Christian", "Peter", "Frank", "Stefan", "Martin", "Markus", "Andreas", "Jürgen"]
var brd_firstnames_f = ["Sabine", "Petra", "Claudia", "Andrea", "Susanne", "Anja", "Nicole", "Monika", "Brigitte", "Heike"]

# Photo IDs for consistency
var photo_ids = []

# Pre-defined test travelers (30+ cases)
var predefined_travelers = [
	# === VALID CASES (10) ===
	{
		"id": "valid_001",
		"name": "Mueller",
		"vorname": "Hans",
		"age": 45,
		"nationality": "DDR",
		"geburtsdatum": "1944-03-15",
		"geschlecht": "M",
		"purpose": "Familienbesuch",
		"direction": "ausreise",
		"documents_valid": true,
		"story": "Besucht seine Schwester in West-Berlin zum Geburtstag.",
		"appearance": {"foto": "photo_001"},
		"test_category": "valid_standard"
	},
	{
		"id": "valid_002",
		"name": "Schmidt",
		"vorname": "Ingrid",
		"age": 32,
		"nationality": "DDR",
		"geburtsdatum": "1957-07-22",
		"geschlecht": "F",
		"purpose": "Geschäftsreise",
		"direction": "ausreise",
		"documents_valid": true,
		"story": "Staatlich genehmigte Dienstreise nach Leipzig.",
		"appearance": {"foto": "photo_002"},
		"test_category": "valid_business"
	},
	{
		"id": "valid_003",
		"name": "Kowalski",
		"vorname": "Jan",
		"age": 28,
		"nationality": "Polen",
		"geburtsdatum": "1961-01-10",
		"geschlecht": "M",
		"purpose": "Transit",
		"direction": "einreise",
		"documents_valid": true,
		"story": "Durchreise nach Westdeutschland mit gültigem Visum.",
		"appearance": {"foto": "photo_003"},
		"test_category": "valid_foreign"
	},
	{
		"id": "valid_004",
		"name": "Weber",
		"vorname": "Klaus",
		"age": 55,
		"nationality": "DDR",
		"geburtsdatum": "1934-05-20",
		"geschlecht": "M",
		"purpose": "Rentnerreise",
		"direction": "ausreise",
		"documents_valid": true,
		"story": "Rentner mit Erlaubnis für Westreise.",
		"appearance": {"foto": "photo_004"},
		"test_category": "valid_pensioner"
	},
	{
		"id": "valid_005",
		"name": "Nowak",
		"vorname": "Maria",
		"age": 41,
		"nationality": "Polen",
		"geburtsdatum": "1948-09-03",
		"geschlecht": "F",
		"purpose": "Handel",
		"direction": "einreise",
		"documents_valid": true,
		"story": "Handelsvertreterin mit Geschäftsvisum.",
		"appearance": {"foto": "photo_005"},
		"test_category": "valid_trade"
	},
	{
		"id": "valid_006",
		"name": "Müller",
		"vorname": "Thomas",
		"age": 35,
		"nationality": "BRD",
		"geburtsdatum": "1954-02-14",
		"geschlecht": "M",
		"purpose": "Familienbesuch",
		"direction": "einreise",
		"documents_valid": true,
		"story": "West-Berliner besucht Verwandte in Ost-Berlin.",
		"appearance": {"foto": "photo_006"},
		"test_category": "valid_west"
	},
	{
		"id": "valid_007",
		"name": "Becker",
		"vorname": "Helga",
		"age": 48,
		"nationality": "DDR",
		"geburtsdatum": "1941-11-30",
		"geschlecht": "F",
		"purpose": "Kulturreise",
		"direction": "ausreise",
		"documents_valid": true,
		"story": "Mitglied einer Kulturdelegation.",
		"appearance": {"foto": "photo_007"},
		"test_category": "valid_culture"
	},
	{
		"id": "valid_008",
		"name": "Wagner",
		"vorname": "Dieter",
		"age": 38,
		"nationality": "DDR",
		"geburtsdatum": "1951-06-25",
		"geschlecht": "M",
		"purpose": "Sportveranstaltung",
		"direction": "ausreise",
		"documents_valid": true,
		"story": "Sportler mit Genehmigung für Wettkampf.",
		"appearance": {"foto": "photo_008"},
		"test_category": "valid_sport"
	},
	{
		"id": "valid_009",
		"name": "Klein",
		"vorname": "Monika",
		"age": 29,
		"nationality": "DDR",
		"geburtsdatum": "1960-04-18",
		"geschlecht": "F",
		"purpose": "Medizinische Behandlung",
		"direction": "ausreise",
		"documents_valid": true,
		"story": "Sondergenehmigung für medizinische Behandlung.",
		"appearance": {"foto": "photo_009"},
		"test_category": "valid_medical"
	},
	{
		"id": "valid_010",
		"name": "Hoffmann",
		"vorname": "Peter",
		"age": 42,
		"nationality": "DDR",
		"geburtsdatum": "1947-12-05",
		"geschlecht": "M",
		"purpose": "Wissenschaftliche Konferenz",
		"direction": "ausreise",
		"documents_valid": true,
		"story": "Wissenschaftler mit Konferenzeinladung.",
		"appearance": {"foto": "photo_010"},
		"test_category": "valid_academic"
	},
	
	# === INVALID CASES - Expired Documents (5) ===
	{
		"id": "invalid_expired_001",
		"name": "Schulz",
		"vorname": "Werner",
		"age": 36,
		"nationality": "DDR",
		"geburtsdatum": "1953-08-12",
		"geschlecht": "M",
		"purpose": "Familienbesuch",
		"direction": "ausreise",
		"documents_valid": false,
		"story": "Personalausweis seit 6 Monaten abgelaufen.",
		"appearance": {"foto": "photo_011"},
		"test_category": "invalid_expired",
		"error_type": "expired_personalausweis"
	},
	{
		"id": "invalid_expired_002",
		"name": "Wisniewski",
		"vorname": "Piotr",
		"age": 31,
		"nationality": "Polen",
		"geburtsdatum": "1958-03-28",
		"geschlecht": "M",
		"purpose": "Transit",
		"direction": "einreise",
		"documents_valid": false,
		"story": "Visum gestern abgelaufen.",
		"appearance": {"foto": "photo_012"},
		"test_category": "invalid_expired",
		"error_type": "expired_visa"
	},
	{
		"id": "invalid_expired_003",
		"name": "Meyer",
		"vorname": "Brigitte",
		"age": 44,
		"nationality": "DDR",
		"geburtsdatum": "1945-10-15",
		"geschlecht": "F",
		"purpose": "Geschäftsreise",
		"direction": "ausreise",
		"documents_valid": false,
		"story": "Ausreisegenehmigung überschritten.",
		"appearance": {"foto": "photo_013"},
		"test_category": "invalid_expired",
		"error_type": "expired_ausreise"
	},
	{
		"id": "invalid_expired_004",
		"name": "Fischer",
		"vorname": "Michael",
		"age": 39,
		"nationality": "BRD",
		"geburtsdatum": "1950-01-20",
		"geschlecht": "M",
		"purpose": "Transit",
		"direction": "einreise",
		"documents_valid": false,
		"story": "Transitvisum abgelaufen.",
		"appearance": {"foto": "photo_014"},
		"test_category": "invalid_expired",
		"error_type": "expired_transit"
	},
	{
		"id": "invalid_expired_005",
		"name": "Wolf",
		"vorname": "Christa",
		"age": 52,
		"nationality": "DDR",
		"geburtsdatum": "1937-06-08",
		"geschlecht": "F",
		"purpose": "Rentnerreise",
		"direction": "ausreise",
		"documents_valid": false,
		"story": "Reisepass seit einem Jahr ungültig.",
		"appearance": {"foto": "photo_015"},
		"test_category": "invalid_expired",
		"error_type": "expired_reisepass"
	},
	
	# === INVALID CASES - Photo Mismatch (3) ===
	{
		"id": "invalid_photo_001",
		"name": "Neumann",
		"vorname": "Karl",
		"age": 47,
		"nationality": "DDR",
		"geburtsdatum": "1942-04-22",
		"geschlecht": "M",
		"purpose": "Familienbesuch",
		"direction": "ausreise",
		"documents_valid": false,
		"story": "Foto stimmt nicht mit Person überein.",
		"appearance": {"foto": "photo_016"},
		"document_foto": "photo_099",
		"test_category": "invalid_photo",
		"error_type": "photo_mismatch"
	},
	{
		"id": "invalid_photo_002",
		"name": "Kaminski",
		"vorname": "Anna",
		"age": 26,
		"nationality": "Polen",
		"geburtsdatum": "1963-09-14",
		"geschlecht": "F",
		"purpose": "Studium",
		"direction": "einreise",
		"documents_valid": false,
		"story": "Verwendet Ausweis ihrer Schwester.",
		"appearance": {"foto": "photo_017"},
		"document_foto": "photo_098",
		"test_category": "invalid_photo",
		"error_type": "photo_switched"
	},
	{
		"id": "invalid_photo_003",
		"name": "Schwarz",
		"vorname": "Uwe",
		"age": 33,
		"nationality": "DDR",
		"geburtsdatum": "1956-11-03",
		"geschlecht": "M",
		"purpose": "Fluchtversuch",
		"direction": "ausreise",
		"documents_valid": false,
		"story": "Gefälschtes Foto im Ausweis.",
		"appearance": {"foto": "photo_018"},
		"document_foto": "photo_097",
		"test_category": "invalid_photo",
		"error_type": "photo_forged"
	},
	
	# === INVALID CASES - Missing Documents (3) ===
	{
		"id": "invalid_missing_001",
		"name": "Zimmermann",
		"vorname": "Frank",
		"age": 30,
		"nationality": "DDR",
		"geburtsdatum": "1959-02-28",
		"geschlecht": "M",
		"purpose": "Ausreise",
		"direction": "ausreise",
		"documents_valid": false,
		"story": "Keine Ausreisegenehmigung vorhanden.",
		"appearance": {"foto": "photo_019"},
		"test_category": "invalid_missing",
		"error_type": "missing_ausreise"
	},
	{
		"id": "invalid_missing_002",
		"name": "Lewandowski",
		"vorname": "Krzysztof",
		"age": 34,
		"nationality": "Polen",
		"geburtsdatum": "1955-05-10",
		"geschlecht": "M",
		"purpose": "Arbeit",
		"direction": "einreise",
		"documents_valid": false,
		"story": "Visum fehlt.",
		"appearance": {"foto": "photo_020"},
		"test_category": "invalid_missing",
		"error_type": "missing_visa"
	},
	{
		"id": "invalid_missing_003",
		"name": "Schneider",
		"vorname": "Petra",
		"age": 27,
		"nationality": "BRD",
		"geburtsdatum": "1962-07-18",
		"geschlecht": "F",
		"purpose": "Transit",
		"direction": "einreise",
		"documents_valid": false,
		"story": "Transitvisum nicht vorhanden.",
		"appearance": {"foto": "photo_021"},
		"test_category": "invalid_missing",
		"error_type": "missing_transit"
	},
	
	# === EDGE CASES (9) ===
	{
		"id": "edge_watchlist_001",
		"name": "Schmidt",
		"vorname": "Werner",
		"age": 31,
		"nationality": "DDR",
		"geburtsdatum": "1958-05-20",
		"geschlecht": "M",
		"purpose": "Familienbesuch",
		"direction": "ausreise",
		"documents_valid": true,
		"story": "Auf Fahndungsliste wegen Republikfluchtversuch!",
		"appearance": {"foto": "photo_022"},
		"test_category": "edge_watchlist",
		"on_watchlist": true
	},
	{
		"id": "edge_pm12_001",
		"name": "Krueger",
		"vorname": "Manfred",
		"age": 40,
		"nationality": "DDR",
		"geburtsdatum": "1949-08-30",
		"geschlecht": "M",
		"purpose": "Ausreise",
		"direction": "ausreise",
		"documents_valid": true,
		"story": "PM-12 Vermerk - keine Grenzüberquerung erlaubt.",
		"appearance": {"foto": "photo_023"},
		"test_category": "edge_pm12",
		"pm12_vermerk": true
	},
	{
		"id": "edge_child_001",
		"name": "Braun",
		"vorname": "Lisa",
		"age": 8,
		"nationality": "DDR",
		"geburtsdatum": "1981-03-15",
		"geschlecht": "F",
		"purpose": "Familienreise",
		"direction": "ausreise",
		"documents_valid": true,
		"story": "Minderjährige reist mit Eltern.",
		"appearance": {"foto": "photo_024"},
		"test_category": "edge_minor",
		"traveling_with": ["Braun, Thomas", "Braun, Sabine"]
	},
	{
		"id": "edge_diplomat_001",
		"name": "Petrov",
		"vorname": "Alexei",
		"age": 45,
		"nationality": "UdSSR",
		"geburtsdatum": "1944-01-12",
		"geschlecht": "M",
		"purpose": "Diplomatische Mission",
		"direction": "einreise",
		"documents_valid": true,
		"story": "Sowjetischer Diplomat mit Immunität.",
		"appearance": {"foto": "photo_025"},
		"test_category": "edge_diplomatic",
		"diplomatic_status": true
	},
	{
		"id": "edge_expired_today_001",
		"name": "Hofmann",
		"vorname": "Gisela",
		"age": 37,
		"nationality": "DDR",
		"geburtsdatum": "1952-06-20",
		"geschlecht": "F",
		"purpose": "Geschäftsreise",
		"direction": "ausreise",
		"documents_valid": false,
		"story": "Ausweis läuft heute ab.",
		"appearance": {"foto": "photo_026"},
		"test_category": "edge_expiry_today",
		"expires_today": true
	},
	{
		"id": "edge_republikflucht_001",
		"name": "Hartmann",
		"vorname": "Familie",
		"age": 35,
		"nationality": "DDR",
		"geburtsdatum": "1954-09-10",
		"geschlecht": "M",
		"purpose": "Urlaub",
		"direction": "ausreise",
		"documents_valid": true,
		"story": "Ganze Familie mit viel Gepäck - Fluchtgefahr!",
		"appearance": {"foto": "photo_027"},
		"test_category": "edge_republikflucht_risk",
		"family_members": 4,
		"luggage_count": 8,
		"return_date": ""
	},
	{
		"id": "edge_forged_001",
		"name": "Lange",
		"vorname": "Stefan",
		"age": 29,
		"nationality": "DDR",
		"geburtsdatum": "1960-12-24",
		"geschlecht": "M",
		"purpose": "Ausreise",
		"direction": "ausreise",
		"documents_valid": false,
		"story": "Professionell gefälschte Dokumente.",
		"appearance": {"foto": "photo_028"},
		"test_category": "edge_forgery",
		"forgery_indicators": ["altered_date", "fake_stamp"]
	},
	{
		"id": "edge_wrong_pkz_001",
		"name": "Koch",
		"vorname": "Andreas",
		"age": 32,
		"nationality": "DDR",
		"geburtsdatum": "1957-04-15",
		"geschlecht": "M",
		"purpose": "Familienbesuch",
		"direction": "ausreise",
		"documents_valid": false,
		"story": "PKZ stimmt nicht mit Geburtsdatum überein.",
		"appearance": {"foto": "photo_029"},
		"test_category": "edge_pkz_mismatch",
		"wrong_pkz": "010155123456"
	},
	{
		"id": "edge_multiple_nationalities_001",
		"name": "Mueller-Smith",
		"vorname": "John-Hans",
		"age": 38,
		"nationality": "DDR/USA",
		"geburtsdatum": "1951-07-04",
		"geschlecht": "M",
		"purpose": "Unbekannt",
		"direction": "ausreise",
		"documents_valid": true,
		"story": "Doppelte Staatsbürgerschaft - komplizierter Fall.",
		"appearance": {"foto": "photo_030"},
		"test_category": "edge_dual_nationality",
		"nationalities": ["DDR", "USA"]
	}
]

func _init():
	rng.seed = 12345  # Fixed seed for testing
	# Generate photo IDs
	for i in range(100):
		photo_ids.append("photo_%03d" % i)

# Get a predefined traveler by ID
func get_predefined_traveler(traveler_id: String) -> Dictionary:
	for traveler in predefined_travelers:
		if traveler.id == traveler_id:
			return _generate_complete_traveler(traveler)
	return {}

# Get all predefined travelers of a specific category
func get_travelers_by_category(category: String) -> Array:
	var result = []
	for traveler in predefined_travelers:
		if traveler.test_category == category:
			result.append(_generate_complete_traveler(traveler))
	return result

# Get random predefined traveler
func get_random_predefined_traveler() -> Dictionary:
	if predefined_travelers.size() > 0:
		var index = rng.randi() % predefined_travelers.size()
		return _generate_complete_traveler(predefined_travelers[index])
	return {}

# Main generation function
func generate_traveler(profile: String = "random", day: int = 1) -> Dictionary:
	stats.total_generated += 1
	
	match profile:
		"valid":
			stats.valid_cases += 1
			return _generate_valid_traveler(day)
		"invalid":
			stats.invalid_cases += 1
			return _generate_invalid_traveler(day)
		"edge_case":
			stats.edge_cases += 1
			return _generate_edge_case_traveler(day)
		"predefined":
			return get_random_predefined_traveler()
		_:
			var rand = rng.randf()
			if rand < 0.5:
				return generate_traveler("valid", day)
			elif rand < 0.8:
				return generate_traveler("invalid", day)
			else:
				return generate_traveler("edge_case", day)

# Generate complete traveler with documents
func _generate_complete_traveler(base_data: Dictionary) -> Dictionary:
	var traveler = base_data.duplicate(true)
	
	# Generate documents based on traveler data
	traveler.documents = _generate_documents_for_traveler(traveler)
	
	# Add metadata
	traveler.generated_at = Time.get_datetime_string_from_system()
	traveler.validation_expected = traveler.get("documents_valid", true)
	
	return traveler

# Generate valid traveler
func _generate_valid_traveler(__Array: -> Dictionary:
	var nationality = _pick_nationality()
	var gender = _pick_gender()
	var names = _generate_names(nationality, gender)
	var age = rng.randi_range(18, 65)
	var birthdate = _generate_birthdate(age)
	var photo = photo_ids[rng.randi() % photo_ids.size()]
	
	var traveler = {
		"name": names.surname,
		"vorname": names.firstname,
		"age": age,
		"nationality": nationality,
		"geburtsdatum": birthdate,
		"geschlecht": gender,
		"purpose": _pick_travel_purpose(nationality),
		"direction": _pick_direction(nationality),
		"documents_valid": true,
		"story": _generate_story(nationality, true),
		"appearance": {"foto": photo},
		"test_category": "generated_valid"
	}
	
	# Generate valid documents
	traveler.documents = _generate_valid_documents(traveler, day)
	
	return traveler

# Generate invalid traveler
func _generate_invalid_traveler(__Array: -> Dictionary:
	var traveler = _generate_valid_traveler(day)
	traveler.documents_valid = false
	traveler.story = _generate_story(traveler.nationality, false)
	traveler.test_category = "generated_invalid"
	
	# Introduce errors
	var error_type = rng.randi() % 5
	match error_type:
		0:  # Expired documents
			_make_documents_expired(traveler)
			traveler.error_type = "expired"
		1:  # Photo mismatch
			_make_photo_mismatch(traveler)
			traveler.error_type = "photo_mismatch"
		2:  # Missing documents
			_remove_required_document(traveler)
			traveler.error_type = "missing_document"
		3:  # Forged documents
			_add_forgery_indicators(traveler)
			traveler.error_type = "forgery"
		4:  # Wrong PKZ
			_corrupt_pkz(traveler)
			traveler.error_type = "pkz_error"
	
	return traveler

# Generate edge case traveler
func _generate_edge_case_traveler(__Array: -> Dictionary:
	var edge_cases = [
		_generate_watchlist_person,
		_generate_pm12_restricted,
		_generate_republikflucht_risk,
		_generate_diplomatic_immunity,
		_generate_child_traveler,
		_generate_expired_today,
		_generate_multiple_nationalities
	]
	
	var selected = edge_cases[rng.randi() % edge_cases.size()]
	var traveler = selected.call(day)
	traveler.test_category = "generated_edge_case"
	return traveler

# --- Document Generation ---

func _generate_documents_for_traveler(traveler: Dictionary) -> Array:
	var docs = []
	
	# Handle different error types
	if traveler.has("error_type"):
		match traveler.error_type:
			"missing_ausreise":
				# Generate all docs except Ausreisegenehmigung
				docs = _generate_ddr_documents(traveler, false)
			"missing_visa":
				# Generate passport but no visa
				docs.append(_create_reisepass(traveler, true))
			"expired_personalausweis":
				docs = _generate_ddr_documents(traveler, true)
				_expire_document(docs[0])
			"photo_mismatch":
				docs = _generate_documents_by_nationality(traveler)
				if docs.size() > 0 and traveler.has("document_foto"):
					docs[0]["foto"] = traveler.document_foto
			"forgery":
				docs = _generate_documents_by_nationality(traveler)
				if docs.size() > 0 and traveler.has("forgery_indicators"):
					docs[0]["forgery_indicators"] = traveler.forgery_indicators
			_:
				docs = _generate_documents_by_nationality(traveler)
	else:
		docs = _generate_documents_by_nationality(traveler)
	
	# Handle special cases
	if traveler.has("pm12_vermerk") and traveler.pm12_vermerk:
		for doc in docs:
			if doc.get("type") == "personalausweis":
				doc["pm12_vermerk"] = true
	
	if traveler.has("wrong_pkz"):
		for doc in docs:
			if doc.get("type") == "personalausweis":
				doc["pkz"] = traveler.wrong_pkz
	
	if traveler.has("expires_today"):
		for doc in docs:
			if doc.has("gueltig_bis"):
				doc["gueltig_bis"] = "1989-08-01"  # Current date
	
	return docs

func _generate_documents_by_nationality(traveler: Dictionary) -> Array:
	var docs = []
	
	match traveler.nationality:
		"DDR":
			docs = _generate_ddr_documents(traveler, traveler.get("direction") == "ausreise")
		"Polen":
			docs = _generate_polish_documents(traveler)
		"BRD":
			docs = _generate_brd_documents(traveler)
		"UdSSR":
			docs = _generate_soviet_documents(traveler)
		_:
			docs.append(_create_reisepass(traveler, true))
	
	return docs

func _generate_ddr_documents(traveler: Dictionary, needs_ausreise: bool) -> Array:
	var docs = []
	
	# Personalausweis
	docs.append(_create_personalausweis(traveler))
	
	# Ausreisegenehmigung if needed
	if needs_ausreise and not traveler.has("error_type"):
		docs.append(_create_ausreisegenehmigung(traveler))
	
	return docs

func _generate_polish_documents(traveler: Dictionary) -> Array:
	var docs = []
	
	# Reisepass
	docs.append(_create_reisepass(traveler, true))
	
	# Visum (unless it's missing on purpose)
	if not traveler.has("error_type") or traveler.error_type != "missing_visa":
		docs.append(_create_visum(traveler))
	
	return docs

func _generate_brd_documents(traveler: Dictionary) -> Array:
	var docs = []
	
	# Reisepass
	docs.append(_create_reisepass(traveler, true))
	
	# Transitvisum
	if not traveler.has("error_type") or traveler.error_type != "missing_transit":
		docs.append(_create_transitvisum(traveler))
	
	return docs

func _generate_soviet_documents(traveler: Dictionary) -> Array:
	var docs = []
	
	# Reisepass
	docs.append(_create_reisepass(traveler, true))
	
	# Diplomatic passport if applicable
	if traveler.get("diplomatic_status", false):
		docs.append(_create_diplomatic_passport(traveler))
	
	return docs

# --- Document Creation Functions ---

func _create_personalausweis(traveler: Dictionary) -> Dictionary:
	var valid = traveler.get("documents_valid", true)
	var expiry = "1990-12-31" if valid else "1988-01-01"
	
	if traveler.has("expires_today"):
		expiry = "1989-08-01"
	
	return {
		"type": "personalausweis",
		"name": traveler.get("name", "Mueller"),
		"vorname": traveler.get("vorname", "Hans"),
		"geburtsdatum": traveler.get("geburtsdatum", "1955-03-15"),
		"pkz": _generate_pkz(traveler.get("geburtsdatum", "1955-03-15")),
		"gueltig_bis": expiry,
		"foto": traveler.get("appearance", {}).get("foto", "photo_001"),
		"ausstellungsort": "Berlin",
		"ausstellungsdatum": "1985-01-15"
	}

func _create_reisepass(traveler: Dictionary, valid: bool) -> Dictionary:
	var expiry = "1991-12-31" if valid else "1988-06-01"
	
	if traveler.has("expires_today"):
		expiry = "1989-08-01"
	
	var pass_prefix = {
		"DDR": "DD",
		"Polen": "PL",
		"BRD": "D",
		"UdSSR": "SU"
	}
	
	var prefix = pass_prefix.get(traveler.get("nationality", "DDR"), "XX")
	
	return {
		"type": "reisepass",
		"name": traveler.get("name", "Mueller"),
		"vorname": traveler.get("vorname", "Hans"),
		"passnummer": prefix + str(rng.randi_range(1000000, 9999999)),
		"gueltig_bis": expiry,
		"foto": traveler.get("appearance", {}).get("foto", "photo_001"),
		"ausstellungsland": traveler.get("nationality", "DDR"),
		"ausstellungsdatum": "1986-03-20"
	}

func _create_ausreisegenehmigung(traveler: Dictionary) -> Dictionary:
	var valid = traveler.get("documents_valid", true)
	var expiry = "1989-09-01" if valid else "1989-07-01"
	
	return {
		"type": "ausreisegenehmigung",
		"name": traveler.get("name", "Mueller"),
		"vorname": traveler.get("vorname", "Hans"),
		"gueltig_bis": expiry,
		"reisegrund": traveler.get("purpose", "Familienbesuch"),
		"zielland": "BRD",
		"ausstellungsbehörde": "Volkspolizei Berlin",
		"genehmigungsnummer": "AG-" + str(rng.randi_range(10000, 99999))
	}

func _create_visum(traveler: Dictionary) -> Dictionary:
	var valid = traveler.get("documents_valid", true)
	var expiry = "1989-12-31" if valid else "1989-07-31"
	
	return {
		"type": "visum",
		"holder_name": traveler.get("name", "Kowalski"),
		"valid_until": expiry,
		"visa_type": "Transit" if traveler.get("purpose") == "Transit" else "Besuch",
		"entry_points": ["Marienborn", "Friedrichstrasse"],
		"visa_number": "V-" + str(rng.randi_range(100000, 999999))
	}

func _create_transitvisum(traveler: Dictionary) -> Dictionary:
	var valid = traveler.get("documents_valid", true)
	var expiry = "1989-08-15" if valid else "1989-07-25"
	
	return {
		"type": "transitvisum",
		"holder_name": traveler.get("name", "Mueller"),
		"valid_until": expiry,
		"route_restriction": "direct_only",
		"entry_point": "Checkpoint Charlie",
		"exit_point": "Marienborn",
		"transit_number": "T-" + str(rng.randi_range(10000, 99999))
	}

func _create_diplomatic_passport(traveler: Dictionary) -> Dictionary:
	return {
		"type": "diplomatic_passport",
		"name": traveler.get("name", "Petrov"),
		"vorname": traveler.get("vorname", "Alexei"),
		"diplomatic_rank": "Attaché",
		"immunity_status": "full",
		"issuing_country": traveler.get("nationality", "UdSSR"),
		"valid_until": "1992-12-31"
	}

# --- Helper Functions ---

func _pick_nationality() -> String:
	var nations = ["DDR", "DDR", "DDR", "Polen", "BRD", "UdSSR", "CSSR"]
	return nations[rng.randi() % nations.size()]

func _pick_gender() -> String:
	return "M" if rng.randf() < 0.6 else "F"

func _generate_names(nationality: String, gender: String) -> Dictionary:
	var surname = ""
	var firstname = ""
	
	match nationality:
		"DDR":
			surname = ddr_surnames[rng.randi() % ddr_surnames.size()]
			if gender == "M":
				firstname = ddr_firstnames_m[rng.randi() % ddr_firstnames_m.size()]
			else:
				firstname = ddr_firstnames_f[rng.randi() % ddr_firstnames_f.size()]
		"Polen":
			surname = polish_surnames[rng.randi() % polish_surnames.size()]
			if gender == "M":
				firstname = polish_firstnames_m[rng.randi() % polish_firstnames_m.size()]
			else:
				firstname = polish_firstnames_f[rng.randi() % polish_firstnames_f.size()]
		"BRD":
			surname = brd_surnames[rng.randi() % brd_surnames.size()]
			if gender == "M":
				firstname = brd_firstnames_m[rng.randi() % brd_firstnames_m.size()]
			else:
				firstname = brd_firstnames_f[rng.randi() % brd_firstnames_f.size()]
		_:
			surname = ddr_surnames[rng.randi() % ddr_surnames.size()]
			firstname = "Ivan" if gender == "M" else "Natasha"
	
	return {"surname": surname, "firstname": firstname}

func _generate_birthdate(age: int) -> String:
	var year = 1989 - age
	var month = rng.randi_range(1, 12)
	var day = rng.randi_range(1, 28)
	return "%04d-%02d-%02d" % [year, month, day]

func _generate_pkz(birthdate: String) -> String:
	# Format: DDMMYYXXXXXX
	var parts = birthdate.split("-")
	if parts.size() == 3:
		var day = parts[2]
		var month = parts[1]
		var year = parts[0].substr(2, 2)
		var random_part = str(rng.randi_range(100000, 999999))
		return day + month + year + random_part
	return "010170123456"

func _pick_travel_purpose(nationality: String) -> String:
	var purposes = {
		"DDR": ["Familienbesuch", "Geschäftsreise", "Kulturreise", "Sportveranstaltung"],
		"Polen": ["Transit", "Handel", "Studium", "Arbeit"],
		"BRD": ["Familienbesuch", "Transit", "Geschäft", "Tourismus"],
		"UdSSR": ["Diplomatische Mission", "Handel", "Militär", "Wissenschaft"]
	}
	
	var nation_purposes = purposes.get(nationality, ["Besuch"])
	return nation_purposes[rng.randi() % nation_purposes.size()]

func _pick_direction(nationality: String) -> String:
	if nationality == "DDR":
		return "ausreise" if rng.randf() < 0.7 else "einreise"
	else:
		return "einreise" if rng.randf() < 0.8 else "ausreise"

func _generate_story(_nationality: String, valid:) -> String:
	if valid:
		var stories = [
			"Routinebesuch bei Verwandten.",
			"Geschäftlich unterwegs mit allen Genehmigungen.",
			"Rentner mit Reiseerlaubnis.",
			"Kulturdelegation auf dem Weg zur Veranstaltung.",
			"Sportler mit offizieller Einladung."
		]
		return stories[rng.randi() % stories.size()]
	else:
		var stories = [
			"Dokumente sind verdächtig.",
			"Nervöses Verhalten bei der Kontrolle.",
			"Widersprüchliche Angaben zum Reisezweck.",
			"Möglicherweise gefälschte Papiere.",
			"Person verhält sich auffällig."
		]
		return stories[rng.randi() % stories.size()]

# --- Error Introduction Functions ---

func _make_documents_expired(traveler: Dictionary):
	if traveler.documents.size() > 0:
		var doc = traveler.documents[0]
		doc["gueltig_bis"] = "1989-01-01"  # 7 months ago

func _expire_document(doc: Dictionary):
	if doc.has("gueltig_bis"):
		doc["gueltig_bis"] = "1989-01-01"

func _make_photo_mismatch(traveler: Dictionary):
	if traveler.documents.size() > 0:
		var doc = traveler.documents[0]
		if doc.has("foto"):
			var wrong_photo = photo_ids[rng.randi() % photo_ids.size()]
			while wrong_photo == doc["foto"]:
				wrong_photo = photo_ids[rng.randi() % photo_ids.size()]
			doc["foto"] = wrong_photo

func _remove_required_document(traveler: Dictionary):
	if traveler.nationality == "DDR" and traveler.documents.size() > 1:
		# Remove Ausreisegenehmigung
		for i in range(traveler.documents.size() - 1, -1, -1):
			if traveler.documents[i].get("type") == "ausreisegenehmigung":
				traveler.documents.remove_at(i)
				break
	elif traveler.documents.size() > 1:
		# Remove last document (usually visa)
		traveler.documents.pop_back()

func _add_forgery_indicators(traveler: Dictionary):
	if traveler.documents.size() > 0:
		var doc = traveler.documents[0]
		doc["forgery_indicators"] = ["altered_date", "fake_stamp", "erased_text"]

func _corrupt_pkz(traveler: Dictionary):
	for doc in traveler.documents:
		if doc.get("type") == "personalausweis" and doc.has("pkz"):
			# Generate wrong PKZ that doesn't match birthdate
			doc["pkz"] = "999999" + str(rng.randi_range(100000, 999999))

# --- Edge Case Generators ---

func _generate_watchlist_person(__Array: -> Dictionary:
	var traveler = _generate_valid_traveler(day)
	traveler["name"] = "Schmidt"
	traveler["vorname"] = "Werner"
	traveler["on_watchlist"] = true
	traveler["story"] = "Person steht auf Fahndungsliste!"
	return traveler

func _generate_pm12_restricted(__Array: -> Dictionary:
	var traveler = _generate_valid_traveler(day)
	traveler["nationality"] = "DDR"
	traveler["pm12_vermerk"] = true
	traveler["story"] = "PM-12 Vermerk - keine Grenzüberquerung erlaubt."
	return traveler

func _generate_republikflucht_risk(__Array: -> Dictionary:
	var traveler = _generate_valid_traveler(day)
	traveler["nationality"] = "DDR"
	traveler["family_members"] = 4
	traveler["luggage_count"] = 8
	traveler["return_date"] = ""
	traveler["story"] = "Ganze Familie mit viel Gepäck - Fluchtgefahr!"
	return traveler

func _generate_diplomatic_immunity(__Array: -> Dictionary:
	var traveler = _generate_valid_traveler(day)
	traveler["nationality"] = "UdSSR"
	traveler["diplomatic_status"] = true
	traveler["story"] = "Diplomat mit Immunität."
	return traveler

func _generate_child_traveler(__Array: -> Dictionary:
	var traveler = _generate_valid_traveler(day)
	traveler["age"] = rng.randi_range(5, 12)
	traveler["geburtsdatum"] = _generate_birthdate(traveler["age"])
	traveler["traveling_with"] = ["Elternteil 1", "Elternteil 2"]
	traveler["story"] = "Minderjähriger reist mit Familie."
	return traveler

func _generate_expired_today(__Array: -> Dictionary:
	var traveler = _generate_valid_traveler(day)
	traveler["expires_today"] = true
	traveler["documents_valid"] = false
	traveler["story"] = "Dokumente laufen heute ab."
	return traveler

func _generate_multiple_nationalities(__Array: -> Dictionary:
	var traveler = _generate_valid_traveler(day)
	traveler["nationalities"] = ["DDR", "USA"]
	traveler["nationality"] = "DDR/USA"
	traveler["story"] = "Doppelte Staatsbürgerschaft - komplizierter Fall."
	return traveler

# --- Document Validation Helper ---

func _generate_valid_documents(traveler: Dictionary, Array: -> Array:
	return _generate_documents_for_traveler(traveler)

# --- Statistics Functions ---

func get_statistics() -> Dictionary:
	return stats

func reset_statistics():
	stats.total_generated = 0
	stats.valid_cases = 0
	stats.invalid_cases = 0
	stats.edge_cases = 0

# Get test summary
func get_test_summary() -> String:
	var summary = "=== TRAVELER GENERATOR TEST SUMMARY ===\n"
	summary += "Predefined Travelers: %d\n" % predefined_travelers.size()
	summary += "- Valid Cases: 10\n"
	summary += "- Invalid Cases: 11\n"
	summary += "- Edge Cases: 9\n"
	summary += "\nGenerated Travelers: %d\n" % stats.total_generated
	summary += "- Valid: %d\n" % stats.valid_cases
	summary += "- Invalid: %d\n" % stats.invalid_cases
	summary += "- Edge Cases: %d\n" % stats.edge_cases
	return summary
