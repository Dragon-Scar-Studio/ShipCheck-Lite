@tool
extends RefCounted
class_name ShipCheckIssue

enum Severity {
	INFO,
	WARNING,
	ERROR,
	CRITICAL
}

var severity: Severity = Severity.INFO
var title: String = ""
var message: String = ""
var file_path: String = ""
var line_number: int = -1
var fix_hint: String = ""
var scanner_name: String = ""
var scanner_id: String = ""
var rule_id: String = ""
var category: String = ""
var detail: String = ""
var why_this_matters: String = ""
var context_key: String = ""
var evidence: String = ""
var stable_id: String = ""
var legacy_id: String = ""
var suppressed: bool = false
var suppression_reason: String = ""


static func create(
	p_severity: Severity,
	p_title: String,
	p_message: String,
	p_file_path: String = "",
	p_line_number: int = -1,
	p_fix_hint: String = "",
	p_scanner_name: String = "",
	p_detail: String = "",
	p_scanner_id: String = "",
	p_rule_id: String = "",
	p_context_key: String = "",
	p_evidence: String = "",
	p_category: String = "",
	p_why_this_matters: String = ""
) -> ShipCheckIssue:
	var issue := ShipCheckIssue.new()
	issue.severity = p_severity
	issue.title = p_title
	issue.message = p_message
	issue.file_path = p_file_path
	issue.line_number = p_line_number
	issue.fix_hint = p_fix_hint
	issue.scanner_name = p_scanner_name
	issue.detail = p_detail
	issue.scanner_id = p_scanner_id if p_scanner_id != "" else _scanner_name_to_id(p_scanner_name)
	issue.rule_id = p_rule_id if p_rule_id != "" else _title_to_rule_id(p_title)
	issue.context_key = p_context_key
	issue.evidence = p_evidence if p_evidence != "" else p_detail
	issue.category = p_category
	issue.why_this_matters = p_why_this_matters
	issue.legacy_id = issue._build_legacy_id()
	issue.stable_id = issue._build_stable_id()
	return issue


func get_severity_label() -> String:
	match severity:
		Severity.CRITICAL:
			return "CRITICAL"
		Severity.ERROR:
			return "ERROR"
		Severity.WARNING:
			return "WARNING"
		_:
			return "INFO"


func get_issue_id() -> String:
	if stable_id == "":
		stable_id = _build_stable_id()
	return stable_id


func get_legacy_issue_id() -> String:
	if legacy_id == "":
		legacy_id = _build_legacy_id()
	return legacy_id


func get_rule_key() -> String:
	if scanner_id == "":
		scanner_id = _scanner_name_to_id(scanner_name)
	if rule_id == "":
		rule_id = _title_to_rule_id(title)
	return "%s.%s" % [scanner_id, rule_id]


func to_markdown() -> String:
	var location := file_path
	if line_number > 0:
		location += ":%d" % line_number

	var parts: Array[String] = []
	parts.append("### %s: %s" % [get_severity_label(), title])
	if scanner_name != "":
		parts.append("- Scanner: %s" % scanner_name)
	if rule_id != "":
		parts.append("- Rule: %s" % get_rule_key())
	if location != "":
		parts.append("- Location: %s" % location)
	if message != "":
		parts.append("- Problem: %s" % message)
	if why_this_matters != "":
		parts.append("- Why this matters: %s" % why_this_matters)
	if detail != "":
		parts.append("- Detail: %s" % detail)
	if fix_hint != "":
		parts.append("- Suggested fix: %s" % fix_hint)
	return "\n".join(parts)


func _build_legacy_id() -> String:
	return "%s:%s:%s:%s" % [scanner_name, title, file_path, str(line_number)]


func _build_stable_id() -> String:
	var normalized_file := file_path.replace("\\", "/").to_lower()
	var scanner_key := scanner_id if scanner_id != "" else _scanner_name_to_id(scanner_name)
	var rule_key := rule_id if rule_id != "" else _title_to_rule_id(title)
	var context := context_key
	if context == "":
		context = detail
	if context == "":
		context = title
	var evidence_text := evidence
	if evidence_text == "":
		evidence_text = detail
	if evidence_text == "" and line_number > 0:
		evidence_text = "line:%d" % line_number
	return "v2:%s:%s:%s:%s:%s" % [
		scanner_key,
		rule_key,
		normalized_file,
		_hash_text(context),
		_hash_text(evidence_text)
	]


static func _scanner_name_to_id(value: String) -> String:
	var normalized := value.strip_edges().to_lower()
	normalized = normalized.replace(" scanner", "")
	return _slug(normalized)


static func _title_to_rule_id(value: String) -> String:
	return _slug(value.strip_edges().to_lower())


static func _slug(value: String) -> String:
	var result := ""
	var previous_underscore := false
	for i in range(value.length()):
		var ch := value.substr(i, 1)
		var code := ch.unicode_at(0)
		var is_word := (code >= 97 and code <= 122) or (code >= 48 and code <= 57)
		if is_word:
			result += ch
			previous_underscore = false
		elif not previous_underscore:
			result += "_"
			previous_underscore = true
	result = result.strip_edges()
	while result.begins_with("_"):
		result = result.substr(1)
	while result.ends_with("_"):
		result = result.substr(0, result.length() - 1)
	return result if result != "" else "rule"


static func _hash_text(value: String) -> String:
	var unsigned_hash := int(value.hash()) & 0x7fffffff
	return str(unsigned_hash)
