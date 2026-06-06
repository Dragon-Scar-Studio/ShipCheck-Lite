# ShipCheck Lite

Free Godot editor addon for quick pre-export health checks.

ShipCheck Lite catches common release mistakes before you export: missing scripts, broken resource paths, InputMap issues, path casing mismatches, debug leftovers, oversized assets, project setting problems, export preset gaps, and basic release-risk issues like `.env` files or plain HTTP URLs.

## Install

1. Copy `addons/shipcheck` into a Godot 4 project.
2. Enable `ShipCheck Lite` in `Project > Project Settings > Plugins`.
3. Open the ShipCheck dock and press `Scan`.

Lite exports Markdown reports from the editor and supports project-level config plus ignore rules.

## Pro

ShipCheck Pro is the paid version with CI/CLI scans, baselines, JSON/HTML reports, advanced GDScript rules, scene connection checks, stale UID checks, asset hygiene checks, and performance hot-path checks.
