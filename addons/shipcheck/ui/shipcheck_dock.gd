@tool
extends VBoxContainer

const ShipCheckReportScript := preload("res://addons/shipcheck/data/shipcheck_report.gd")
const ShipCheckIgnoreScript := preload("res://addons/shipcheck/data/shipcheck_ignore.gd")
const ShipCheckConfigScript := preload("res://addons/shipcheck/data/shipcheck_config.gd")
const ShipCheckScannerRegistryScript := preload("res://addons/shipcheck/scanners/shipcheck_scanner_registry.gd")

const IGNORE_CONFIG_PATH := "res://shipcheck_ignore.cfg"
const SETTINGS_CONFIG_PATH := "res://shipcheck_config.cfg"

var editor_interface
var current_report: ShipCheckReport
var selected_issue: ShipCheckIssue
var ignore_rules: ShipCheckIgnore
var shipcheck_config: ShipCheckConfig

var score_label: Label
var status_label: Label
var issue_tree: Tree
var details: TextEdit
var search_box: LineEdit
var critical_filter: CheckBox
var error_filter: CheckBox
var warning_filter: CheckBox
var info_filter: CheckBox
var group_dropdown: OptionButton
var scan_button: Button
var export_button: Button
var open_button: Button
var copy_button: Button
var ignore_button: Button
var open_ignore_button: Button
var open_config_button: Button
var clear_button: Button
var built := false


func set_editor_interface(p_editor_interface) -> void:
	editor_interface = p_editor_interface


func _ready() -> void:
	if built:
		return
	built = true
	_build_ui()
	_set_empty_state()


func _build_ui() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	var title := Label.new()
	title.text = "ShipCheck Lite"
	title.add_theme_font_size_override("font_size", 18)
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Free pre-export project health checks"
	subtitle.modulate = Color(0.72, 0.76, 0.84)
	add_child(subtitle)

	var scan_row := HBoxContainer.new()
	add_child(scan_row)

	scan_button = Button.new()
	scan_button.text = "Scan"
	scan_button.tooltip_text = "Runs the Lite Default scan."
	scan_button.pressed.connect(func() -> void: _run_scan())
	scan_row.add_child(scan_button)

	clear_button = Button.new()
	clear_button.text = "Clear"
	clear_button.tooltip_text = "Clear the current ShipCheck results."
	clear_button.pressed.connect(_clear_results)
	scan_row.add_child(clear_button)

	score_label = Label.new()
	score_label.text = "Project Health: --"
	score_label.add_theme_font_size_override("font_size", 15)
	add_child(score_label)

	status_label = Label.new()
	status_label.text = "No scan run yet."
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.modulate = Color(0.72, 0.76, 0.84)
	add_child(status_label)

	var filter_label := Label.new()
	filter_label.text = "Filters"
	add_child(filter_label)

	var filter_row := HBoxContainer.new()
	add_child(filter_row)

	critical_filter = _make_filter_checkbox("Critical", true)
	error_filter = _make_filter_checkbox("Errors", true)
	warning_filter = _make_filter_checkbox("Warnings", true)
	info_filter = _make_filter_checkbox("Info", true)
	filter_row.add_child(critical_filter)
	filter_row.add_child(error_filter)
	filter_row.add_child(warning_filter)
	filter_row.add_child(info_filter)

	var view_row := HBoxContainer.new()
	add_child(view_row)

	var group_label := Label.new()
	group_label.text = "Group"
	view_row.add_child(group_label)

	group_dropdown = OptionButton.new()
	for option in ["Flat", "Severity", "Scanner", "File"]:
		group_dropdown.add_item(option)
	group_dropdown.item_selected.connect(func(_index: int) -> void: _refresh_issue_tree())
	view_row.add_child(group_dropdown)

	search_box = LineEdit.new()
	search_box.placeholder_text = "Search issues..."
	search_box.text_changed.connect(func(_text: String) -> void: _refresh_issue_tree())
	add_child(search_box)

	issue_tree = Tree.new()
	issue_tree.columns = 4
	issue_tree.column_titles_visible = true
	issue_tree.hide_root = true
	issue_tree.set_column_title(0, "Severity")
	issue_tree.set_column_title(1, "Issue")
	issue_tree.set_column_title(2, "File")
	issue_tree.set_column_title(3, "Line")
	issue_tree.set_column_expand(0, false)
	issue_tree.set_column_custom_minimum_width(0, 86)
	issue_tree.set_column_expand(1, true)
	issue_tree.set_column_expand(2, true)
	issue_tree.set_column_expand(3, false)
	issue_tree.set_column_custom_minimum_width(3, 48)
	issue_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	issue_tree.item_selected.connect(_on_issue_selected)
	add_child(issue_tree)

	var action_row := HBoxContainer.new()
	add_child(action_row)

	open_button = Button.new()
	open_button.text = "Open File"
	open_button.disabled = true
	open_button.pressed.connect(_on_open_file_pressed)
	action_row.add_child(open_button)

	copy_button = Button.new()
	copy_button.text = "Copy Path"
	copy_button.disabled = true
	copy_button.pressed.connect(_on_copy_path_pressed)
	action_row.add_child(copy_button)

	ignore_button = Button.new()
	ignore_button.text = "Ignore Issue"
	ignore_button.disabled = true
	ignore_button.pressed.connect(_on_ignore_issue_pressed)
	action_row.add_child(ignore_button)

	open_ignore_button = Button.new()
	open_ignore_button.text = "Open Ignore"
	open_ignore_button.tooltip_text = "Create or open res://shipcheck_ignore.cfg."
	open_ignore_button.pressed.connect(_on_open_ignore_pressed)
	action_row.add_child(open_ignore_button)

	open_config_button = Button.new()
	open_config_button.text = "Open Config"
	open_config_button.tooltip_text = "Create or open res://shipcheck_config.cfg."
	open_config_button.pressed.connect(_on_open_config_pressed)
	action_row.add_child(open_config_button)

	export_button = Button.new()
	export_button.text = "Export Markdown"
	export_button.disabled = true
	export_button.pressed.connect(_on_export_report_pressed)
	add_child(export_button)

	details = TextEdit.new()
	details.custom_minimum_size = Vector2(0, 180)
	details.size_flags_vertical = Control.SIZE_EXPAND_FILL
	details.editable = false
	details.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	add_child(details)


func _make_filter_checkbox(label: String, pressed: bool) -> CheckBox:
	var checkbox := CheckBox.new()
	checkbox.text = label
	checkbox.button_pressed = pressed
	checkbox.toggled.connect(func(_pressed: bool) -> void: _refresh_issue_tree())
	return checkbox


func _set_empty_state() -> void:
	if issue_tree != null:
		issue_tree.clear()
	if details != null:
		details.text = "Run a scan to inspect this Godot project."


func _clear_results() -> void:
	current_report = null
	selected_issue = null
	if score_label != null:
		score_label.text = "Project Health: --"
	if status_label != null:
		status_label.text = "No scan run yet."
	if issue_tree != null:
		issue_tree.clear()
	if details != null:
		details.text = "Run a scan to inspect this Godot project."
	_set_action_buttons_disabled(true)
	_set_report_buttons_disabled(true)


func _run_scan() -> void:
	current_report = ShipCheckReportScript.new()
	current_report.profile_name = "Lite Default"
	selected_issue = null
	shipcheck_config = ShipCheckConfigScript.load_from_project()
	shipcheck_config.ensure_config_exists()

	var seed_ignore := ShipCheckIgnoreScript.new()
	seed_ignore.include_addons = shipcheck_config.should_include_addons()
	seed_ignore.ensure_config_exists()
	ignore_rules = ShipCheckIgnoreScript.load_from_project(shipcheck_config.should_include_addons())

	_set_action_buttons_disabled(true)
	_set_report_buttons_disabled(true)
	_set_scan_buttons_disabled(true)
	if status_label != null:
		status_label.text = "Scanning..."
	if issue_tree != null:
		issue_tree.clear()
	if details != null:
		details.text = "Scanning..."
	await get_tree().process_frame

	var scan_context := {
		"profile": current_report.profile_name,
		"ignore": ignore_rules,
		"config": shipcheck_config,
	}
	for scanner in ShipCheckScannerRegistryScript.instantiate_scanners("Lite Default", shipcheck_config):
		if status_label != null:
			status_label.text = "Running %s..." % scanner.get_scanner_name()
		await get_tree().process_frame
		var issues: Array[ShipCheckIssue] = scanner.scan("res://", scan_context)
		current_report.add_issues(_filter_ignored_issues(issues))

	current_report.issues.sort_custom(_compare_issues)
	_update_summary()
	_refresh_issue_tree()
	_set_report_buttons_disabled(false)
	_set_scan_buttons_disabled(false)


func _compare_issues(a: ShipCheckIssue, b: ShipCheckIssue) -> bool:
	if a.severity == b.severity:
		if a.file_path == b.file_path:
			return a.line_number < b.line_number
		return a.file_path < b.file_path
	return a.severity > b.severity


func _filter_ignored_issues(issues: Array[ShipCheckIssue]) -> Array[ShipCheckIssue]:
	var filtered: Array[ShipCheckIssue] = []
	for issue in issues:
		if ignore_rules != null and ignore_rules.is_issue_ignored(issue):
			continue
		filtered.append(issue)
	return filtered


func _update_summary() -> void:
	if current_report == null:
		return
	var critical := current_report.get_count(ShipCheckIssue.Severity.CRITICAL)
	var errors := current_report.get_count(ShipCheckIssue.Severity.ERROR)
	var warnings := current_report.get_count(ShipCheckIssue.Severity.WARNING)
	var info := current_report.get_count(ShipCheckIssue.Severity.INFO)
	if score_label != null:
		score_label.text = "Project Health: %d/100" % current_report.get_score()
	if status_label != null:
		status_label.text = "Scan complete: %d critical, %d errors, %d warnings, %d info" % [critical, errors, warnings, info]


func _refresh_issue_tree() -> void:
	if issue_tree == null:
		return

	issue_tree.clear()
	var root := issue_tree.create_item()
	if current_report == null:
		return

	var visible_count := 0
	var grouped_items := {}
	var group_mode := _get_group_mode()
	for issue in current_report.issues:
		if not _issue_passes_filters(issue):
			continue

		visible_count += 1
		var parent := root
		if group_mode != "Flat":
			var group_key := _get_issue_group_key(issue, group_mode)
			if not grouped_items.has(group_key):
				var group_item := issue_tree.create_item(root)
				group_item.set_text(0, group_mode)
				group_item.set_text(1, group_key)
				group_item.collapsed = false
				grouped_items[group_key] = group_item
			parent = grouped_items[group_key]

		var item := issue_tree.create_item(parent)
		var severity_color := _get_severity_color(issue.severity)
		item.set_text(0, issue.get_severity_label())
		item.set_text(1, issue.title)
		item.set_text(2, issue.file_path)
		item.set_text(3, str(issue.line_number) if issue.line_number > 0 else "")
		item.set_metadata(0, issue)
		for column in range(4):
			item.set_custom_color(column, severity_color)

	if visible_count == 0 and not current_report.issues.is_empty():
		if details != null:
			details.text = "No issues match the active filters."
	elif current_report.issues.is_empty():
		if details != null:
			details.text = "No issues found."


func _get_group_mode() -> String:
	if group_dropdown == null:
		return "Flat"
	return group_dropdown.get_item_text(group_dropdown.selected)


func _get_issue_group_key(issue: ShipCheckIssue, group_mode: String) -> String:
	match group_mode:
		"Severity":
			return issue.get_severity_label()
		"Scanner":
			return issue.scanner_name if issue.scanner_name != "" else issue.scanner_id
		"File":
			return issue.file_path if issue.file_path != "" else "Project"
		_:
			return "Issues"


func _issue_passes_filters(issue: ShipCheckIssue) -> bool:
	match issue.severity:
		ShipCheckIssue.Severity.CRITICAL:
			if critical_filter != null and not critical_filter.button_pressed:
				return false
		ShipCheckIssue.Severity.ERROR:
			if error_filter != null and not error_filter.button_pressed:
				return false
		ShipCheckIssue.Severity.WARNING:
			if warning_filter != null and not warning_filter.button_pressed:
				return false
		ShipCheckIssue.Severity.INFO:
			if info_filter != null and not info_filter.button_pressed:
				return false

	var query := ""
	if search_box != null:
		query = search_box.text.strip_edges().to_lower()
	if query == "":
		return true

	var haystack := "%s %s %s %s %s" % [
		issue.title,
		issue.message,
		issue.file_path,
		issue.detail,
		issue.fix_hint,
	]
	return haystack.to_lower().contains(query)


func _get_severity_color(severity: ShipCheckIssue.Severity) -> Color:
	match severity:
		ShipCheckIssue.Severity.CRITICAL:
			return Color(1.0, 0.25, 0.25)
		ShipCheckIssue.Severity.ERROR:
			return Color(1.0, 0.45, 0.35)
		ShipCheckIssue.Severity.WARNING:
			return Color(1.0, 0.75, 0.30)
		_:
			return Color(0.62, 0.78, 1.0)


func _on_issue_selected() -> void:
	var item := issue_tree.get_selected()
	if item == null:
		return

	selected_issue = item.get_metadata(0)
	_set_button_disabled(open_button, selected_issue == null or selected_issue.file_path == "")
	_set_button_disabled(copy_button, selected_issue == null or selected_issue.file_path == "")
	_set_button_disabled(ignore_button, selected_issue == null)
	if selected_issue == null:
		if details != null:
			details.text = ""
		return

	var location := selected_issue.file_path
	if selected_issue.line_number > 0:
		location += ":%d" % selected_issue.line_number

	var lines: Array[String] = []
	lines.append("%s: %s" % [selected_issue.get_severity_label(), selected_issue.title])
	if selected_issue.scanner_name != "":
		lines.append("Scanner: %s" % selected_issue.scanner_name)
	if selected_issue.rule_id != "":
		lines.append("Rule: %s" % selected_issue.get_rule_key())
	if location != "":
		lines.append("Location: %s" % location)
	lines.append("")
	lines.append("Problem:")
	lines.append(selected_issue.message)
	if selected_issue.why_this_matters != "":
		lines.append("")
		lines.append("Why This Matters:")
		lines.append(selected_issue.why_this_matters)
	if selected_issue.detail != "":
		lines.append("")
		lines.append("Detail:")
		lines.append(selected_issue.detail)
	if selected_issue.fix_hint != "":
		lines.append("")
		lines.append("Suggested Fix:")
		lines.append(selected_issue.fix_hint)

	if details != null:
		details.text = "\n".join(lines)


func _on_open_file_pressed() -> void:
	if selected_issue == null or selected_issue.file_path == "":
		return

	var path := selected_issue.file_path
	if editor_interface != null:
		if path.get_extension().to_lower() == "gd" and FileAccess.file_exists(path):
			var script := load(path)
			if script is Script:
				var editor_line := selected_issue.line_number if selected_issue.line_number > 0 else -1
				editor_interface.edit_script(script, editor_line, 0, true)
				return

		if ResourceLoader.exists(path):
			var resource := load(path)
			if resource != null:
				editor_interface.edit_resource(resource)
				return

		if editor_interface.has_method("select_file"):
			editor_interface.select_file(path)
			return

	var global_path := ProjectSettings.globalize_path(path)
	if global_path != "":
		OS.shell_open(global_path)


func _on_copy_path_pressed() -> void:
	if selected_issue == null or selected_issue.file_path == "":
		return
	DisplayServer.clipboard_set(selected_issue.file_path)


func _on_ignore_issue_pressed() -> void:
	if selected_issue == null:
		return

	var include_addons := shipcheck_config != null and shipcheck_config.should_include_addons()
	var rules: ShipCheckIgnore = ShipCheckIgnoreScript.load_from_project(include_addons)
	var error := rules.add_issue_ignore(selected_issue)
	if error != OK:
		if details != null:
			details.text = "Could not update res://shipcheck_ignore.cfg."
		_update_summary()
		return

	_refresh_editor_filesystem()
	ignore_rules = ShipCheckIgnoreScript.load_from_project(include_addons)
	if current_report != null:
		current_report.issues.erase(selected_issue)
		selected_issue = null
		_set_action_buttons_disabled(true)
		_update_summary()
		_refresh_issue_tree()
		if details != null:
			details.text = "Ignored issue. Edit res://shipcheck_ignore.cfg to manage ignore rules."


func _on_open_ignore_pressed() -> void:
	var rules := ShipCheckIgnoreScript.new()
	if shipcheck_config == null:
		shipcheck_config = ShipCheckConfigScript.load_from_project()
	rules.include_addons = shipcheck_config.should_include_addons()
	var error := rules.ensure_config_exists()
	if error != OK:
		if details != null:
			details.text = "Could not create res://shipcheck_ignore.cfg."
		_update_summary()
		return

	_refresh_editor_filesystem()
	_open_plain_text_project_file(IGNORE_CONFIG_PATH)


func _on_open_config_pressed() -> void:
	var settings := ShipCheckConfigScript.new()
	var error := settings.ensure_config_exists()
	if error != OK:
		if details != null:
			details.text = "Could not create res://shipcheck_config.cfg."
		_update_summary()
		return

	_refresh_editor_filesystem()
	_open_plain_text_project_file(SETTINGS_CONFIG_PATH)


func _open_plain_text_project_file(path: String) -> void:
	var global_path := ProjectSettings.globalize_path(path)
	if global_path != "":
		OS.shell_open(global_path)
	_update_summary()


func _refresh_editor_filesystem() -> void:
	if editor_interface == null or not editor_interface.has_method("get_resource_filesystem"):
		return
	var filesystem = editor_interface.get_resource_filesystem()
	if filesystem != null and filesystem.has_method("scan"):
		filesystem.scan()


func _on_export_report_pressed() -> void:
	if current_report == null:
		return

	var path := "res://shipcheck_report.md"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		if details != null:
			details.text = "Could not write %s" % path
		_update_summary()
		return

	file.store_string(current_report.to_markdown())
	file.close()
	_refresh_editor_filesystem()
	_update_summary()


func _set_action_buttons_disabled(disabled: bool) -> void:
	_set_button_disabled(open_button, disabled)
	_set_button_disabled(copy_button, disabled)
	_set_button_disabled(ignore_button, disabled)


func _set_report_buttons_disabled(disabled: bool) -> void:
	_set_button_disabled(export_button, disabled)


func _set_scan_buttons_disabled(disabled: bool) -> void:
	_set_button_disabled(scan_button, disabled)
	_set_button_disabled(clear_button, disabled)


func _set_button_disabled(button: Button, disabled: bool) -> void:
	if button != null:
		button.disabled = disabled
