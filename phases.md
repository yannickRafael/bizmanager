# 📊 Farma — Phase Assessment

> Reviewed all files across every module against the [implementation plan](file:///home/yannickrafael/.gemini/antigravity/brain/f687e435-2e58-45fb-86b1-57490a4d1324/artifacts/implementation_plan.md).

---

## Current Position: Phases 5 + 6 — Screens Still Placeholders

The **backend** layers (models, repositories, providers) for both Cattle and Goats are **done**. But the **presentation** layer for both modules is still **100% placeholder** — identical 14-line "Em desenvolvimento" stubs.

This means **Phase 5 (Cattle) and Phase 6 (Goats) are only ~60% complete** each — the data layer is solid but users can't actually *use* these modules yet.

---

## Phase-by-Phase Breakdown

| Phase | Layer | Status | Notes |
|---|---|---|---|
| **1. Core Foundation** | Models, widgets, router, theme | ✅ **Complete** | All 12+ files present and functional |
| **2. Database & Repos** | Schema, migrations, FK cascades | ✅ **Complete** | v4 migration, all animal tables, `individual_animals` reserved |
| **3. Provider Split** | All 7 providers wired | ✅ **Complete** | `DataManager` no longer referenced (dead code remains in `lib/services/`) |
| **4. Poultry Migration** | Screens, forms, delete confirmations | ✅ **Complete** | 4 fully implemented screens (1,264 total lines) |
| **5. Cattle Module** | Backend ✅ / Screens ❌ | 🔶 **60%** | Models + repo + provider done. **All 4 screens are stubs** (14-15 lines each) |
| **6. Goat Module** | Backend ✅ / Screens ❌ | 🔶 **60%** | Models + repo + provider done. **All 4 screens are stubs** (14-15 lines each) |
| **7. Cross-Cutting** | Mixed | 🔶 **Partial** | HomeScreen ✅ (299 lines, fully wired). Settings ✅. Reports ❌ stub. Backup ❌ stub. Legacy cleanup ❌ |

---

## What Needs Building

### Phase 5 — Cattle Screens (4 files, ~1,100 lines estimated)

| File | What to build | Reference |
|---|---|---|
| [cattle_dashboard.dart](file:///home/yannickrafael/projet/bizmanager/lib/features/cattle/presentation/cattle_dashboard.dart) | KPI grid (batches, animals, revenue, expenses, profit, mortality) + quick actions + active batch preview | Mirror [poultry_dashboard.dart](file:///home/yannickrafael/projet/bizmanager/lib/features/poultry/presentation/poultry_dashboard.dart) |
| [cattle_batch_list.dart](file:///home/yannickrafael/projet/bizmanager/lib/features/cattle/presentation/cattle_batch_list.dart) | List + create modal (farm selector, purpose dropdown, qty, cost, breed) + delete/close actions | Mirror [poultry_batch_list.dart](file:///home/yannickrafael/projet/bizmanager/lib/features/poultry/presentation/poultry_batch_list.dart) with `CattlePurpose` instead of `BatchType` |
| [cattle_batch_detail.dart](file:///home/yannickrafael/projet/bizmanager/lib/features/cattle/presentation/cattle_batch_detail.dart) | 5 tabs: Summary, Expenses, Mortality, Production (milk + calf births), Sales | Mirror [poultry_batch_detail.dart](file:///home/yannickrafael/projet/bizmanager/lib/features/poultry/presentation/poultry_batch_detail.dart) — replace egg/slaughter tabs with milk production + calf births |
| [cattle_sales_screen.dart](file:///home/yannickrafael/projet/bizmanager/lib/features/cattle/presentation/cattle_sales_screen.dart) | 2 tabs: Cattle Sales + Milk Sales, with add/delete | Mirror [poultry_sales_screen.dart](file:///home/yannickrafael/projet/bizmanager/lib/features/poultry/presentation/poultry_sales_screen.dart) — 2 tabs instead of 3 |

### Phase 6 — Goat Screens (4 files, ~1,100 lines estimated)

| File | What to build | Reference |
|---|---|---|
| [goat_dashboard.dart](file:///home/yannickrafael/projet/bizmanager/lib/features/goats/presentation/goat_dashboard.dart) | Same pattern as cattle dashboard, goat colors + labels | Cattle dashboard (once built) |
| [goat_batch_list.dart](file:///home/yannickrafael/projet/bizmanager/lib/features/goats/presentation/goat_batch_list.dart) | Same pattern with `GoatPurpose` dropdown | Cattle batch list |
| [goat_batch_detail.dart](file:///home/yannickrafael/projet/bizmanager/lib/features/goats/presentation/goat_batch_detail.dart) | 5 tabs: Summary, Expenses, Mortality, Production (goat milk + kid births), Sales | Cattle batch detail |
| [goat_sales_screen.dart](file:///home/yannickrafael/projet/bizmanager/lib/features/goats/presentation/goat_sales_screen.dart) | 2 tabs: Goat Sales + Goat Milk Sales | Cattle sales screen |

### Phase 7 — Remaining Items

| Task | Status |
|---|---|
| `HomeScreen` (animal selector + global summary) | ✅ Done |
| `SettingsScreen` (currency selector) | ✅ Done |
| `ReportsScreen` (multi-animal) | ❌ Stub |
| `BackupScreen` (multi-animal) | ❌ Stub |
| Delete legacy `lib/models/`, `lib/screens/`, `lib/services/` | ❌ Not done |
| Rebrand pubspec.yaml to "farma" | ❓ Not verified |

---

## Recommended Execution Order

1. **Build Cattle screens** (Phase 5) — since goats mirror cattle, do cattle first as the template
2. **Build Goat screens** (Phase 6) — adapt cattle screens with goat-specific labels/enums
3. **Finish Phase 7** — Reports, Backup, legacy cleanup
4. **Build validation** — `flutter analyze` + test run

> [!TIP]
> Phases 5 and 6 are highly parallelizable since the backend is done. Each screen is a self-contained widget that maps directly to a poultry reference. Estimated total: **~2,200 lines across 8 files**.
