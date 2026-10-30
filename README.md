# Godot Android Core

A lightweight Godot 4.7.2 project for reproducible Android integration and reusable runtime components.

## Components

- Deterministic grid-layout generation and validation.
- AStar3D route construction over connected cells.
- A standalone 3D rendering smoke test.
- Headless automated checks and an Android export pipeline.

## Local checks

Install Godot 4.7.2, then run:

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/test_core.gd
```

Open `project.godot` to inspect the reference scene.

## Android export

The `Android core build` GitHub Actions workflow provides a reproducible validation and debug-export reference. It uses official Godot export templates and the Android SDK.

## Integration

The scripts under `scripts/` use Godot built-in types and can be included in another Godot project as a pinned Git dependency. Keep their corresponding tests when updating the integration.

## Requirements

- Godot 4.7.2
- Android SDK and JDK 17 for Android exports
