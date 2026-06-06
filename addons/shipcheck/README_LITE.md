# ShipCheck Lite

ShipCheck Lite is the free edition of ShipCheck for Godot 4.6 projects.

It focuses on low-noise release-readiness checks that help most Godot users before export:

- Missing script references
- Broken `res://` references
- Case-sensitive path mismatches
- Main scene, icon, and autoload setting problems
- InputMap actions used in code but missing from Project Settings
- Debug leftovers such as prints, breakpoints, TODOs, and FIXMEs
- Basic export preset checks
- Large asset warnings
- Basic release-risk checks for `.env`, secrets, `.gdignore`, plain HTTP URLs, and VCS gaps
- Markdown report export
- Editor dock with open/copy/ignore actions

Lite ignores `res://addons/` by default so third-party addons do not drown out your project issues. Turn on `include_addons=true` in `res://shipcheck_config.cfg` if you intentionally want to scan addon code.

ShipCheck Lite is useful by itself. ShipCheck Pro adds automation, baselines, JSON/HTML reports, advanced style/quality rules, performance hot-path checks, scene connection checks, stale UID checks, and CI workflows.
