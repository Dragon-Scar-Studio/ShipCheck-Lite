# Changelog

## 0.10.0

- Added Lite/Pro edition foundation.
- Added shared scanner registry used by the dock.
- Added scanner metadata for edition, category, defaults, and descriptions.
- Added stable issue IDs with legacy ID compatibility for existing ignores.
- Added ShipCheck inline ignore directives for `.gd` files.
- Fixed first-scan ignore consistency by applying built-in defaults even before `shipcheck_ignore.cfg` exists.
- Added `include_addons=false` default so third-party addons are not scanned unless requested.
- Fixed Broken Resource false positives from pure GDScript comments/doc comments.
- Hardened `res://` extraction around BBCode/Markdown wrappers and trailing punctuation.
- Improved scan status timing and disabled scan buttons while a scan is running.
- Kept casing mismatches owned by the Case-Sensitive Path scanner rather than double-counting as broken resources.

## 0.9.2

- Fixed Linux/Windows casing double-count behavior in Broken Resource scanner.
- Improved fixture determinism.

## 0.9.1

- Added hidden-file release-risk coverage for `.env` and `.gdignore`.
- Added CI pre-import guidance.
