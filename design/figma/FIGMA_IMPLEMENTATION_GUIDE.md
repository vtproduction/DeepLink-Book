# Figma Implementation Guide

## Scope and sources

This guide compares the final Figma redesign with the current Flutter application. It is an implementation reference, not a product specification: existing Riverpod state, repositories, Drift data, GoRouter routes, parser/builder behavior, history semantics, clipboard behavior, project relationships, import/export, and Developer Tools remain authoritative.

Inspected with Figma design context:

| Screen | Figma node |
| --- | --- |
| Home | `1:2` |
| History | `1:327` |
| Favorites | `1:654` |
| Projects | `1:919` |
| Project Detail | `1:1149` |
| Deeplink Editor | `1:1591` |
| Settings | `1:1364` |

The frames are designed at 390 px wide. Figma variable queries returned no variable definitions for the inspected nodes, so the tokens below are normalized from repeated raw values in the design context. They should become Flutter theme/constants only where they are reused.

## 1. Design tokens

### Color tokens

| Proposed token | Value | Use |
| --- | --- | --- |
| `canvas` | `#FFFFFF` | Default screen and card background |
| `canvasTint` | `#F8F9FF` | Home canvas and translucent navigation base |
| `surfaceSubtle` | `#EFF4FF` | Recessed wells, selected navigation item, utility panels |
| `surfaceStrong` | `#E5EEFF` | Chips, selected controls, icon containers |
| `surfaceBorder` | `#DCE9FF` | Hairlines and pale outlined surfaces |
| `textPrimary` | `#0B1C30` | Titles and primary data |
| `textSecondary` | `#3E4947` | Supporting labels and metadata |
| `textMuted` | `#6E7977` | Section labels and low-emphasis metadata |
| `accent` | `#005C55` | Selected state, primary action, active status |
| `accentStrong` | `#0F766E` | Strong icon fills and status accents |
| `accentContainer` | `#9CF2E8` | Active/success badges |
| `accentOnContainer` | `#00201D` | Text on the active container |
| `info` | `#005683` | Informational icons and links |
| `infoContainer` | `#CCE5FF` | Informational badge background |
| `danger` | `#BA1A1A` | Destructive text/actions |
| `dangerStrong` | `#93000A` | Text on destructive containers |
| `dangerContainer` | `#FFDAD6` | Failed/destructive status background |

Some frames also use `#565E74`, `#D3E4FE`, `#DAE2FD`, `#213145`, and `#131B2E` for low-frequency neutral/blue variants. Do not promote these to global tokens until a repeated Flutter use is confirmed.

### Spacing tokens

The design is predominantly a 4 px grid:

| Token | Value | Typical use |
| --- | --- | --- |
| `space1` | 2 px | Badge/selected-control inset |
| `space2` | 4 px | Tight icon/text gap, chip radius/inset |
| `space3` | 6 px | Metadata/status gap |
| `space4` | 8 px | Row gap, compact padding |
| `space5` | 12 px | Card/input padding |
| `space6` | 16 px | Horizontal screen padding, standard section gap |
| `space7` | 24 px | Major section separation |
| `topInset` | 56 px | Figma device/header content start |
| `bottomContentInset` | 96 px | Root-screen clearance for bottom navigation |

Use safe-area insets in Flutter rather than hard-coding the 56 px top inset. The stable design requirement is 16 px horizontal screen padding and 96 px bottom content clearance on root tabs.

### Radius tokens

| Token | Value | Use |
| --- | --- | --- |
| `radiusXs` | 2 px | Badges, compact buttons, icon containers |
| `radiusSm` | 4 px | Rows, navigation selection, segmented controls |
| `radiusMd` | 8 px | Primary cards, notices, input/inspector wells |
| `radiusRound` | 12 px | Status dots/avatars and pill-like small elements |

This is materially squarer than the current `AppRadius` values of 8/12/16 px.

### Elevation and borders

- Most surfaces are flat or use a 1 px pale border.
- Common shadows are deliberately faint: `0 1 1 rgba(0,0,0,.05)`, `0 1 2 rgba(0,0,0,.05)`, or a top hairline on navigation.
- Selected navigation items may have an inset 1 px outline at roughly `rgba(110,121,119,.18)`.
- Avoid the current large-radius, visibly elevated card treatment; hierarchy comes from pale blue surface shifts, hairlines, and dense typography.

## 2. Typography

The visual system uses Inter for readable UI copy and JetBrains Mono for technical/status data. A few generated layers report Nimbus Sans, Liberation Mono, or IPAGothic; these appear to be isolated fallback/font substitutions, not a consistent third type family. Map them to Inter or JetBrains Mono unless asset/font verification later proves otherwise.

| Role | Family | Size / line height | Weight | Notes |
| --- | --- | --- | --- | --- |
| Screen title | Inter | 20 / 26 px | 600 | Seen on Favorites and Projects context headings |
| Primary row/card title | Inter | 16 / 22 px | 600 | Deeplink names, project names, settings actions |
| Compact action/row title | Inter | 14 / about 20 px | 500–600 | Dense table/card content |
| Body/description | Inter | 12 / 16–19.5 px | 400–500 | Descriptions and field supporting copy |
| Section/eyebrow | Inter or JetBrains Mono | 11 / 14 px | 600 | Uppercase, usually 0.44–0.55 px tracking |
| Technical URL | JetBrains Mono | 13 / 18 px | 400–500 | URI values, terminal output |
| Metadata | JetBrains Mono | 11 / 14 px | 400–500 | Time, branch, version, counts, statuses |
| Badge | JetBrains Mono | 11 / 14 px | 600 | Uppercase or compact status values |
| Navigation label | Inter | 11 / 14 px | 600 | Always visible |

Implementation note: the project currently declares no bundled custom fonts. Exact Inter/JetBrains Mono fidelity therefore requires font assets or an approved dependency in a later implementation task. Until then, map Inter roles to the platform sans `TextTheme` and technical roles to `monospace`; do not silently add a package during the visual refactor.

## 3. Colors by semantic role

- Background: white on most screens; Home uses `#F8F9FF`.
- Surface hierarchy: `#EFF4FF` for wells/selection and `#E5EEFF` for stronger chips/containers.
- Primary text: `#0B1C30`.
- Secondary text: `#3E4947`; muted section text: `#6E7977`.
- Accent/selected: `#005C55`; stronger teal: `#0F766E`.
- Border/divider: normally `#DCE9FF` or a translucent version of it.
- Success/active: teal accent or `#9CF2E8` container with `#00201D` text.
- Failure/destructive: `#FFDAD6` container, `#93000A`/`#BA1A1A` text.
- Informational/universal-link: `#CCE5FF` container with `#004B73`/`#005683` text.

The current app uses a generated teal Material color scheme plus hard-coded cyan, navy, slate, rose, and per-project accent colors. The redesign consolidates those into a restrained off-white/blue/teal system.

## 4. Spacing and layout

- Root screens: 16 px horizontal padding.
- Major sections: normally 16 or 24 px apart.
- Cards/rows: 8–12 px internal padding.
- Dense row/action gaps: 4–8 px.
- Header icon touch targets: 44 × 44 px even when glyphs are only about 15–17 px.
- Compact action buttons: commonly 28 px high; use adequate Flutter semantics/tap targets even if visual bounds are smaller.
- Root content reserves 96 px at the bottom; detail/editor screens use their own action areas rather than the root navigation.
- Projects is a two-column compact grid at 390 px, with much squarer tiles than the current cards.

## 5. Shape and controls

- Cards: 4 or 8 px radius, pale surface or hairline border, minimal shadow.
- Inputs: pale or white rectangular fields, 4 px radius, 12 px internal padding; labels are compact and technical rather than Material floating-label-heavy.
- Segmented controls: `#E5EEFF` track, 2 px outer inset, 4 px outer radius, 2 px selected-segment radius; selected segment is white with a faint shadow.
- Chips/badges: mostly 2 px radius, not full pills.
- Primary compact button: solid `#005C55`, white label, 2–4 px radius.
- Destructive controls remain red and require confirmation where the current app already confirms.

## 6. Icon and action conventions

Use one consistent outlined icon family with small 12–18 px visual glyphs inside accessible tap targets. The Figma export provides custom SVGs, but most glyphs map closely to Material Symbols/Icons. Reuse a Material icon only after visually checking the glyph; otherwise capture the exact exported asset during implementation because Figma asset URLs expire.

| Action | Figma treatment | Flutter behavior to preserve |
| --- | --- | --- |
| Open/Launch | Compact labeled primary button on rows | Existing launcher, history write, success/failure recording, usage update |
| Copy | Small icon-only utility action, sometimes labeled in terminal wells | Existing clipboard behavior and feedback |
| Edit | Row tap or overflow action; not always permanently visible | Existing edit route |
| Favorite | Star icon; unstar is icon-only on Favorites | Existing favorite mutation/loading state |
| More | Ellipsis icon-only action | Existing popup actions: edit, Developer Tools, duplicate, delete as applicable |
| Delete | Progressive disclosure through More, or explicit destructive Settings row | Existing confirmation and repository behavior |
| Add | “New Intent” in root header and floating add on Project Detail | Existing add route; wording may change visually, semantics must not |
| Search | 44 px icon-only root-header action; search field appears on activation | Reuse current `AppRootTopBar` search state/handlers |
| Settings | 44 px icon-only root-header action | Existing settings route |

Progressive disclosure is central: a row should expose the high-frequency Open/Launch and Copy actions, with edit/duplicate/delete/Developer Tools under More. Do not remove currently supported actions merely because a single mock state omits them.

## 7. Bottom navigation specification

- Applies only to Home/Studio, History, Favorites, and Projects.
- Fixed to the bottom; 390 px frame width, 56 px visual height.
- Background: white at about 95% opacity (`#F8F9FF` at about 90% on Home), with 12 px backdrop blur where supported.
- Top separation: a faint 1 px line/shadow; no dark bar.
- Four equal navigation destinations with approximately 4 px outer horizontal inset and 37.5 px inter-item spacing in the 390 px reference.
- Each destination is at least 56 px wide and 44 px high, with a 4 px radius.
- Icons are approximately 15–17 px; labels are always visible, Inter 11/14 semibold.
- Selected destination: pale blue surface (`#EFF4FF`; Home context also uses `#E5EEFF`), teal icon/text `#005C55`, optional faint inset outline.
- Unselected destination: transparent background with `#3E4947` icon/text.
- Labels are `Studio`, `History`, `Favorites`, `Projects`; `Studio` maps to the existing Home branch and does not change the route.
- Flutter mapping: keep `StatefulNavigationShell` and `goBranch`. Visually refactor `AppShell`; a customized `NavigationBar` theme may be insufficient for the compact 56 px geometry, so a small custom row is acceptable if it retains Material semantics, tooltips, safe-area handling, and branch behavior.

Major current difference: `AppTheme` defines a 72 px dark navy `NavigationBar` with cyan selected state and Material pill indicator. The Figma navigation is 56 px, light/translucent, compact, square, and teal.

## 8. Shared component patterns

### Root header

Reuse and visually refactor `AppRootTopBar` rather than creating per-screen headers. It already owns search activation and Settings navigation. Figma uses a compact brand/title/context cluster, a small uppercase route label, 44 px Search and Settings actions, and a 32 px trailing brand/status mark.

### Deeplink row/card

- Primary name in Inter 14–16 semibold.
- Protocol/status badge near the title.
- URL in JetBrains Mono 13, usually one line with ellipsis.
- Metadata in JetBrains Mono 11: usage count, relative time, project, result.
- High-frequency actions visible; secondary/destructive actions in More.
- Pale divider or subtle surface shift rather than a large elevated card.

Reuse `DeeplinkListItem` for Favorites and Project Detail. The Home dashboard has denser variants (`_FavoriteDashboardItem`, `_HistoryDashboardItem`) that should share the same tokens but can retain their compact layout.

### History row

- Grouped under technical date headers.
- Success/failure glyph and badge lead the row.
- Name, monospace URL, timestamp/result, target/app metadata.
- Open/Retry and Copy remain immediate; Delete stays in overflow.

Reuse `HistoryListItem`; visually refactor it and the existing `_HistoryGroupHeader`/`_HistoryPageHeader`.

### Project item

- Two-column grid.
- Compact square tile with count, project name, branch/status, recency, and open chevron/action.
- New Project is a first-class grid tile.

Reuse `ProjectGridItem` and `NewProjectGridItem`. Replace the current rotating accent palette with the shared teal/blue tokens unless a project color is backed by actual data.

### URL/terminal well

- `#EFF4FF` recessed surface, 8 px radius, 12 px padding.
- Uppercase 11 px label/status row.
- JetBrains Mono 13 px URL/command.
- Copy is a compact trailing action.

Reuse the current URL preview and terminal/developer-tool widgets; do not duplicate parser or command-building logic.

### Editor sections

- Compact status strip and Raw/Builder segmented switch.
- Live compiled URI well before form sections.
- Basic Info, URL Structure, and Query Parameters use dense labeled surfaces.
- Sticky bottom Cancel/Save bar.

Reuse `DeeplinkForm`, `DeeplinkBuilderEditor`, and existing controllers/validation. Only restructure their presentation.

### Settings section

- Uppercase monospace section label.
- Flat grouped rows with 32 px icon containers, title/subtitle, optional badge/value, and hairline separators.
- Destructive row uses semantic red.

Reuse `_SettingsSection`, `_SettingsActionTile`, `_SettingsInfoTile`, and `_SettingsIcon`.

## 9. Figma-to-Flutter mapping

| Figma pattern/node | Existing Flutter component | Required change |
| --- | --- | --- |
| Shared root header | `AppRootTopBar`, `AppBrandIcon` | Compact typography, pale/square icon actions, route-context treatment |
| Bottom navigation | `AppShell`, `AppTheme.navigationBarTheme` | Light 56 px navigation, selected rectangular surface, renamed Home label to Studio |
| Home sections | `_HomeDashboard`, `DashboardSection` | Denser technical rows, tokenized surfaces, reduced elevation/radius |
| Clipboard notice | `QuickLinkCard` | Match 8 px notice surface and compact action hierarchy |
| Recently opened | `_HistoryDashboardItem` | Figma row spacing, metadata, Open/Copy/More treatment |
| Favorites preview | `_FavoriteDashboardItem` | Figma row spacing and badges |
| Recent projects | `_ProjectDashboardItem` | Compact link-row styling |
| Direct dispatcher well | `_TerminalDispatchCard`, command builder | Visual refactor only; retain existing command logic |
| History list | `HistoryScreen`, `HistoryListItem` | Telemetry/header styling, dense grouped rows, action hierarchy |
| Favorites list | `FavoritesScreen`, `DeeplinkListItem` | Filter/header styling and flatter rows; preserve all current actions |
| Projects grid | `ProjectListScreen`, `ProjectGridItem`, `NewProjectGridItem` | Compact grid tiles and shared palette |
| Project detail | `ProjectDetailScreen`, `DeeplinkListItem` | Technical summary, filter/action bar, compact link cards, add FAB styling |
| Editor | `EditDeeplinkScreen`, `DeeplinkForm`, `DeeplinkBuilderEditor` | Reorder/present existing fields to match status, preview, sections, sticky actions |
| Settings groups | `SettingsScreen` private section/tile widgets | Squarer grouped rows, badges, metadata, diagnostics-inspired styling only where backed by data |
| Empty/loading/error | `AppEmptyState`, `AppLoadingState`, `AppErrorState` | Apply new tokens; retain explicit states |

Likely theme files to change in a later implementation: `app_theme.dart`, `app_spacing.dart`, and `app_radius.dart`. Avoid a parallel “Figma” widget tree or duplicate business components.

## 10. Implementation risks and deviations

1. **No Figma variables are exposed.** The inspected nodes returned empty variable definitions. Raw repeated values are reliable, but token names and semantic grouping in this guide are inferred.
2. **Font availability differs.** Inter and JetBrains Mono are not bundled in the current Flutter package. Exact fidelity needs a deliberate font-asset decision; do not depend on generated fallback families such as Nimbus Sans, Liberation Mono, or IPAGothic.
3. **Exported icon URLs expire.** Figma context assets are temporary. During implementation, compare Material icons with the design and commit only the exact exported assets that have no faithful native equivalent.
4. **Figma contains illustrative/mock-only controls and data.** Examples include simulator/ADB status, History Export/Purge and CLI mirror, Favorites batch execution, project repository sync/locked state, editor draft/version/test-intent metadata, Settings export bundle, theme/protocol/sniffer switches, schema/licenses, and runtime diagnostics. These must not create new features or fabricated state in a visual-only task. Map only to existing functionality; omit or present static app information only if already truthful.
5. **Content labels differ from route semantics.** `Studio` is the redesigned label for the existing Home branch. `New Intent`/`Compose Link` map to the existing add-deeplink route. Keep route names and navigation behavior unchanged.
6. **Reference frame is fixed at 390 px.** Flutter must remain responsive and honor safe areas, text scaling, keyboard insets, and platform tap-target/accessibility rules. Do not reproduce absolute positioning.
7. **Figma compact controls can be smaller than accessible targets.** Preserve the 28 px visual button height where useful, but wrap it in at least a 44–48 px semantic/tap region.
8. **Home background differs from other frames.** Prefer one coherent theme surface strategy, with `canvasTint` used intentionally on Home, rather than accidental per-screen color drift.
9. **Current dark theme has no matching final Figma frames.** Preserve current dark-theme support functionally unless product direction explicitly removes it; the supplied values specify the light redesign only.
10. **Settings mock exceeds current behavior.** Current Settings implements import and clear history and shows limited theme/app information. Export exists elsewhere in the product, but the Figma “Export Workspace Bundle” wording and additional runtime controls must be mapped to actual existing flows before being shown.

## Major visual differences from the current app

- Dark 72 px bottom navigation becomes a light/translucent 56 px navigation bar.
- Large 8/12/16 px radii become a squarer 2/4/8 px hierarchy.
- Cyan/navy/slate card styling becomes off-white/pale-blue/teal.
- Default Material typography becomes a deliberate Inter plus JetBrains Mono split.
- Cards become denser and flatter, with technical metadata and hairline separation.
- Primary row actions remain visible while editing, duplication, Developer Tools, and deletion move behind More.
- Project tiles lose the rotating decorative palette in favor of the shared visual system.
- Editor and Settings become structured technical workbenches while retaining the current underlying behavior.
