# ShipCheck Lite

ShipCheck Lite is a Godot editor plugin for quick pre-export project health checks. It looks for the common stuff that can break a build or make a release look messy: missing scripts, broken `res://` paths, InputMap mistakes, path casing issues, debug leftovers, oversized assets, project setting problems, export preset gaps, and basic release-risk issues.

It is designed to drop into a Godot 4 project and run from the editor dock. Lite does not delete or rewrite project files.

Verified with Godot `4.6.2.stable.official.71f334935`.

## Features

- Editor dock with Scan and Export Scan actions
- Clear button for resetting current results
- Health score based on issue severity
- Missing script reference scan
- Broken `res://` resource reference scan
- InputMap mismatch scan, including direct string calls, common `event.is_action_pressed(...)` calls, and simple string constants
- Project settings and autoload scan
- Case-sensitive path mismatch scan
- Release-risk scan for secrets, private keys, `.gitignore` gaps, `.gdignore` traps, export credentials, and plain HTTP URLs
- Large asset scan
- Debug code scan for `print`, `printerr`, `breakpoint`, `TODO`, `FIXME`, and similar markers
- Export preset check for missing `export_presets.cfg` and blank export paths
- Project-level scanner settings via `res://shipcheck_config.cfg`
- Commented recommended defaults in `res://addons/shipcheck/shipcheck_defaults.cfg`
- Project-level ignore rules via `res://shipcheck_ignore.cfg`
- Inline ignores with `# shipcheck: ignore`
- Severity filters and issue search
- Issue detail panel
- Open file, copy path, ignore issue, open ignore config, and open settings config actions
- Script issues open at the reported line when possible
- Markdown report export to `res://shipcheck_report.md`
- Shared file-list cache inside each scan run for better performance on larger projects

## Install

1. Copy the `addons/shipcheck` folder into your Godot project.
2. Open the project in Godot 4.
3. Go to `Project > Project Settings > Plugins`.
4. Enable `ShipCheck`.
5. Open the `ShipCheck` dock and run a scan.

## Recommended First Demo

Make a small messy Godot project and intentionally add:

- A scene that references a missing script
- A script with `print("debug")`
- An undefined or old resource path
- An `export_presets.cfg` preset with no export path

Run ShipCheck, fix one issue, then rescan. That gives you a clean demo video loop: problem found, fix applied, score improves.

## Scanner Config

Click `Open Config` in the dock to create or edit `res://shipcheck_config.cfg`.

The plugin also includes a commented reference config at `res://addons/shipcheck/shipcheck_defaults.cfg`. New project configs are created from that file so the recommended settings include short explanations.

This file controls global scanner behavior. Example:

```ini
[scanners]
large_asset=true
debug_code=true
input_map=true
release_risk=true

[debug_code]
print_enabled=true
print_severity="INFO"
prints_enabled=true
prints_severity="INFO"
printerr_enabled=true
printerr_severity="WARNING"
push_error_enabled=true
push_error_severity="WARNING"
todo_enabled=true
todo_severity="INFO"

[large_assets]
enabled=true
default_threshold_mb=25
png_mb=8
wav_mb=12
mp3_mb=20
extra_extensions=[]

[input_map]
report_undefined_actions=true
report_unused_actions=true
ignore_ui_actions=true

[project_settings]
require_main_scene=true
no_main_scene_severity="WARNING"
main_scene_missing_severity="CRITICAL"
check_project_icon=true
project_icon_missing_severity="WARNING"
check_autoloads=true
autoload_missing_severity="CRITICAL"
project_name_missing_severity="INFO"

[release_risk]
report_sensitive_files=true
sensitive_file_severity="CRITICAL"
report_secret_literals=true
secret_literal_severity="WARNING"
report_vcs_ignore=true
report_gdignore_issues=true
report_plain_http_urls=true
```

## Ignore Rules

Click `Ignore Issue` in the dock to add one issue to `res://shipcheck_ignore.cfg`. ShipCheck writes this file in a readable multi-line format.

You can also create or edit the config manually:

```ini
[paths]
ignore=[
	"res://addons/",
	"res://art/source_files/",
	"res://some_folder/*"
]

[scanners]
ignore=[
	"Debug Code Scanner"
]

[issues]
ignore_ids=[]
```

Add `# shipcheck: ignore` to a line to silence scanners that inspect that exact line.

## Roadmap

Next useful features:

- Quarantine system for possibly unused files
- Scene dependency graph and impact view
- Export profile checks for input maps, remaps, permissions, and audio buses
- Stale ignore cleanup suggestions

## Product Positioning

Do not pitch this as an unused asset cleaner. Pitch it as a release-readiness tool:

> Run a pre-export health check and catch broken references, bad settings, debug leftovers, oversized assets, and release-risk mistakes before release.

The strongest pitch is the release-risk angle: ShipCheck catches the dull mistakes that often get noticed only after a build, a CI failure, or a public upload.

## Safety Notes

This MVP does not delete files. That is intentional. Future cleanup features should use quarantine and backup workflows before permanent deletion.

## Pro

ShipCheck Pro adds CI/CLI scans, baselines, JSON/HTML reports, advanced GDScript rules, scene connection checks, stale UID checks, asset hygiene checks, and performance hot-path checks.

Pro repo: [Dragon-Scar-Studio/ShipCheck-Pro](https://github.com/Dragon-Scar-Studio/ShipCheck-Pro)

## License

ShipCheck Lite is proprietary software owned by Dragon Scar Studio, LLC. You may use and modify it for your own projects, but you may not redistribute it or claim it as your own. See `LICENSE.txt`.
