# Part Picker Context For Future Codex Chat

Use this file when opening a new chat about the PC Part Picker feature.

## Project

- Flutter app: `linh-kien-shop`
- Local path: `C:\Users\PREDATOR\Downloads\Programs\PRM\linh-kien-shop`
- Firebase project: `linh-kien-shop`
- Firestore is used for product/catalog data.
- Firebase service account key was moved to `.secrets/firebase-service-account.json`.
- `.secrets/` should stay ignored and must not be committed.

## Current Feature Goal

Build a simplified PCPartPicker-style feature for a school project.

The feature should let users choose PC parts, show selected parts, estimate total wattage, and report compatibility warnings/errors. It does not need to be as complex as the real PCPartPicker connector diagrams.

Entry point requested by user:

- Home screen category section should have the Part Picker action.
- Tapping it opens the Part Picker page.

## Implemented App Files

Main new feature files:

- `lib/features/part_picker/models/pc_build_model.dart`
- `lib/features/part_picker/models/compatibility_result.dart`
- `lib/features/part_picker/providers/pc_build_provider.dart`
- `lib/features/part_picker/services/compatibility_engine.dart`
- `lib/features/part_picker/services/wattage_calculator.dart`
- `lib/features/part_picker/screens/part_picker_screen.dart`
- `lib/features/part_picker/screens/part_selection_screen.dart`

Existing files touched:

- `lib/data/models/product_model.dart`
  - Added `compatibility: Map<String, dynamic>`
  - Reads/writes compatibility data from Firestore.
- `lib/routes/app_routes.dart`
  - Added `/part-picker`
  - Added `/part-picker/select`
- `lib/routes/app_router.dart`
  - Added routes for Part Picker and part selection.
- `lib/core/widgets/app_back_scope.dart`
  - Part selection back action returns to Part Picker.
- `lib/features/home/screens/home_screen.dart`
  - Home category action now goes to Part Picker.

## Current Part Categories

Configured in `pc_build_model.dart`.

Single-select:

- CPU
- CPU cooler
- Motherboard/mainboard
- Case
- PSU
- OS
- Keyboard
- Mouse

Multi-select:

- RAM
- Storage
- GPU
- Monitor

## Compatibility Rules Implemented

The simplified compatibility engine currently checks:

- CPU socket must match motherboard socket.
- CPU cooler must support CPU socket.
- RAM type must match motherboard memory type.
- Total RAM slots used must not exceed motherboard RAM slots.
- Total RAM capacity must not exceed motherboard max RAM.
- Mixed RAM speed gives a warning.
- M.2 storage count must not exceed motherboard M.2 slots.
- SATA storage count must not exceed motherboard SATA ports.
- Motherboard form factor must fit case supported form factors.
- GPU length must fit case max GPU length.
- CPU cooler height must fit case max cooler height.
- PSU form factor must match case PSU form factor.
- PSU wattage must cover estimated wattage.
- PSU wattage below recommended headroom gives warning.
- Multiple GPU gives warning.
- Multiple monitor gives warning.
- Windows 11 gives TPM/UEFI/Secure Boot warning.
- Legacy Windows gives old OS warning.

## Wattage Logic

Implemented in `wattage_calculator.dart`.

- Sums `compatibility.estimatedPowerWatts` from selected products.
- Uses 35 percent PSU headroom.
- Rounds recommended PSU to standard sizes:
  - 450, 550, 650, 750, 850, 1000, 1200, 1600

## Firestore/Data Work Already Done

Products were seeded from:

- `C:\Users\PREDATOR\Downloads\pc_parts_complete_build_catalog_2020_2026.xlsx`

The seed ignored stock because the app does not need stock counting for the demo.

Prices were intentionally made very cheap in VND for demo/testing.

Product documents were patched with compatibility fields such as:

- `compatibility.estimatedPowerWatts`
- `compatibility.powerEstimateSource`
- `compatibility.powerEstimateQuality`
- `compatibility.powerIncludedInPsuEstimate`
- `compatibility.gpuPowerWatts`
- `compatibility.ramSlotsUsed`
- `compatibility.storageSlotType`

OS products were also seeded from the pasted OS list attachment:

- category id: `os`
- category name: OS / Windows operating systems

Firestore config document was updated:

- `part_picker_config/defaults`
- `schemaVersion: 2`
- `multiSelectCategories: ram, storage, gpu, monitor`
- category order includes OS.

## Tests

Added:

- `test/part_picker_compatibility_test.dart`

It checks:

- CPU/motherboard socket mismatch
- multiple RAM kits slots/capacity
- M.2/SATA slot counting
- wattage and PSU headroom
- multiple GPU/monitor warnings

Last known verification:

```powershell
flutter test
flutter analyze
```

Both passed. Analyzer output ended with:

```text
No issues found!
```

## Git/GitHub Note

Do not spend time fixing local Git metadata for this feature unless the user asks.

The user plans to overwrite/push everything to the GitHub `PartPicker` branch later. Focus on making the local project work first.

## Suggested Next Steps

1. Run the app in Android Studio.
2. Open Home.
3. In the Home category section, tap the Part Picker action.
4. Choose parts in this order for best demo:
   - CPU
   - Motherboard
   - RAM
   - Storage
   - GPU
   - Case
   - PSU
   - OS
   - Monitor
5. Check whether incompatible products are hidden correctly in selection screens.
6. If Firestore asks for a composite index, either create the index from the Firebase console link or simplify the product query to filter client-side.
7. If the UI is cramped on mobile, improve only the Part Picker screens first.

## Prompt To Paste Into New Chat

```text
We are working on the Flutter project at:
C:\Users\PREDATOR\Downloads\Programs\PRM\linh-kien-shop

Please read PART_PICKER_CONTEXT.md first. The previous chat implemented a simplified PC Part Picker feature with Firebase-backed products, compatibility checks, wattage estimate, OS category, and multi-select RAM/storage/GPU/monitor. Last known `flutter test` and `flutter analyze` passed. Please verify the current files before making changes because the previous work was interrupted once.
```
