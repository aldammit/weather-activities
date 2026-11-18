# Weather Activities

A native iOS app that ranks four activities (skiing, surfing, outdoor sightseeing and indoor sightseeing) for each of the next 7 days in any city, using Open-Meteo forecast data.

## a. Project overview

**Flow:** search for a city → pick the exact place among same-name matches (Paris, France vs. Paris, Texas) → see a 7-day forecast where every day scores and ranks all four activities, best first.

**Search screen**
- Recent searches (the last 5 places opened) while the query is shorter than 2 characters.
- Searching, results, "no results" and failure states. Failures offer Try Again.
- Each result shows region and country to tell same-name places apart.

**Forecast screen**
- One card per day: date, weather condition, high/low, and four activity tiles ordered by score. The best activity is highlighted with a crown.
- An activity without enough data shows "–" and ranks last (for example, surfing for an inland city).
- States: loading, loaded, empty (no usable days) and failed (full-screen error with Try Again).
- Pull to refresh, or tap the toolbar Refresh button, which appears once a forecast is loaded. The current forecast stays on screen while refreshing. If the refresh fails, a banner says so and keeps the earlier forecast.

## b. Platform and tooling

| Choice | Notes |
|---|---|
| iOS 27.0+, Xcode 27.1 | iPhone and iPad |
| Swift 6 language mode | Strict concurrency checking. `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` and approachable concurrency on the app target |
| SwiftUI + Observation | `@Observable` view models, `NavigationStack` |
| Swift Concurrency | `async`/`await`, `async let`, task cancellation. No Combine |
| Swift Testing for unit tests | See below |
| XCTest for the UI test | `XCUIApplication` is only available in XCTest |
| No third-party dependencies | Nothing to resolve or keep updated |

**Why Swift Testing rather than XCTest for unit tests.** The brief lists XCTest. I used Swift Testing, Apple's current test framework, which ships with Xcode and runs from the same scheme, test plan, ⌘U and `xcodebuild test`. It gave this project:
- Parameterized tests (`@Test(arguments:)`) for the error translations, the forecast corruption cases and the marine fallbacks.
- `#expect`/`#require` failure messages that show the values of each sub-expression.
- Tests that run in parallel by default, which brings out any state shared between them.

## c. Architecture and technical decisions

### Layers

```
weather-activities/
├── App/              Entry point, RootView (navigation), AppDependencies (composition root)
├── Presentation/
│   ├── Search/       SearchViewModel, SearchScreen and its subviews
│   ├── Forecast/     ForecastViewModel, ForecastScreen, day rows, activity tiles, refresh banner
│   ├── Shared/       Domain → UI mapping: names, SF Symbols, error messages, location detail
│   └── DesignSystem/ Card surface, sky background, error state view, format styles
├── Domain/           Models, ActivityRecommendationService, repository protocols, RepositoryError
├── Data/
│   ├── Networking/   HTTPTransport, OpenMeteoClient
│   ├── Geocoding/    OpenMeteoGeocodingRepository and its DTO
│   ├── Weather/      OpenMeteoWeatherRepository, DTOs, ForecastMapper, WMO code mapping
│   └── RecentLocationsStore.swift
└── PreviewSupport/   Stub repositories and sample data for SwiftUI previews
```

**Dependency rule:**
- Domain depends on nothing but Foundation. It never imports SwiftUI.
- Data implements Domain's repository protocols.
- View models depend on those protocols and never see an Open-Meteo type. The only Data type they use directly is `RecentLocationsStore` (see Dependency injection).
- Only `App` knows every layer, because it wires them together.

### MVVM with explicit state

Each screen has an `@Observable` view model that exposes a single state enum. Views `switch` over it, so an impossible combination (say, a spinner and an error at once) can't be represented.

```swift
enum SearchState {
    case idle                      // query < 2 characters: show recent searches
    case searching
    case results([Location])
    case empty(query: String)
    case failed(RepositoryError)
}

enum ForecastState {
    case loading
    case loaded(ForecastContent, refresh: RefreshStatus)  // content stays visible during and after a refresh
    case empty
    case failed(RepositoryError)
}

enum RefreshStatus { case idle, refreshing, failed(RepositoryError) }
```

Previews and tests can start a view model in any state through its initializer.

### Dependency injection

- **Protocols only at real boundaries:** `GeocodingRepository` and `WeatherRepository` (what view models depend on) and `HTTPTransport` (what the networking client depends on). Tests replace each one.
- **Concrete types everywhere else.** `ActivityRecommendationService` is a pure function of its input, so `ForecastViewModel` creates its own. `RecentLocationsStore` is a struct around an injected `UserDefaults`, and tests pass an isolated suite.
- **Manual DI:** `AppDependencies.live()` builds the graph once at launch, and it's passed down through initializers. No container or service locator.

### Concurrency

- The app target defaults to `MainActor` isolation, so views and view models need no annotations.
- Domain and Data types are `nonisolated` and `Sendable` value types, safe to use from any thread.
- `OpenMeteoClient.get` is `@concurrent`, so networking *and* JSON decoding run off the main actor.
- `OpenMeteoWeatherRepository` fetches the forecast and the marine data in parallel with `async let`.
- Cancellation flows through: leaving the forecast screen cancels its `.task`, and `URLError.cancelled` is turned into `CancellationError` so it is never shown as a failure.

### Search behaviour

- Typing is debounced by 300 ms. Pressing Return searches immediately.
- Queries are trimmed. Anything shorter than 2 characters returns to recent searches without a request.
- Each new search cancels the previous one, and a response from a cancelled search is dropped, so a slow early response can't overwrite a newer one.
- Opening a place records it in recent searches: up to 5, most recent first, de-duplicated by geocoding ID.

### Refresh behaviour

- The forecast stays on screen while refreshing. The toolbar shows a spinner instead of the Refresh button.
- A failed refresh keeps the earlier forecast and shows a banner with Try Again.
- One fetch at a time: `load()` only runs from `.loading`, and `refresh()` only runs from a loaded state that isn't already refreshing.

### Error handling

`RepositoryError` is the only error type the UI sees, and each case has its own title, message and symbol:

| Case | Cause | Shown as |
|---|---|---|
| `connectivity` | No response: offline, timeout, DNS | "No Connection" |
| `httpStatus(Int)` | Non-2xx status | "Service Unavailable", with the status code |
| `decoding` | Body doesn't match the expected JSON | "Unexpected Data" |
| `malformedForecast` | Decoded but inconsistent: unknown time zone, unparseable date, uneven arrays | "Unexpected Data" |

- **Cancellation is never shown.** Repositories throw only `RepositoryError` or `CancellationError`, and view models ignore the latter.
- **Marine data is optional.** Any marine failure other than cancellation means "no waves", so surfing is unscored while the rest of the forecast still shows.
- **Incomplete days are dropped.** A day without a weather code (or with one that WMO doesn't define), a high or a low is skipped. Other missing values stay `nil` and are never treated as zero. A forecast with no usable days shows the empty state.

### Time zones

The forecast is requested with `timezone=auto`. Each day is parsed as midnight in the *city's* time zone, and the UI formats dates in that zone (passed through the SwiftUI environment). "Tue 17 Nov" is therefore the city's Tuesday, even when the device is elsewhere.

### Accessibility

- Each day card is one VoiceOver element. The label reads "Tuesday, 17 November, Sunny, high 18°, low 12°", and the value lists the ranking: "Outdoor sightseeing 100 %, Surfing 92 %, …".
- At accessibility text sizes, day cards stack vertically and the activity tiles become a 2×2 grid. Fixed sizes scale with the text through `@ScaledMetric`.
- Section titles are marked as headers, and decorative images are hidden from VoiceOver.
- Colours come from asset catalog colours with dark variants.

## d. How to build and run

1. Open `weather-activities.xcodeproj` in Xcode 27.1 or later.
2. Select the `weather-activities` scheme and any iOS 27 simulator.
3. Press ⌘R.

To run on a device, select your own team under *Signing & Capabilities* (and change the bundle identifier if needed).

There's no API key to configure and no package to resolve.

## e. How to run tests and testing strategy

Press ⌘U in Xcode, or run:

```sh
xcodebuild test \
  -project weather-activities.xcodeproj \
  -scheme weather-activities \
  -destination 'platform=iOS Simulator,name=iPhone Duo'
```

Replace `iPhone Duo` with any iOS 27 simulator from `xcrun simctl list devices`. The UI test makes no network requests, so the whole suite runs offline.

### What is tested

| Suite | Covers |
|---|---|
| `ActivityRecommendationServiceTests` | Each activity wins in its weather (dry and warm, rainy, fresh snow, good waves). A thunderstorm rules out surfing. Missing data leaves an activity unscored and last. Ties follow declaration order. Scores stay in 0…1. Days keep forecast order |
| `ForecastViewModelTests` | Load, failure then retry, a refresh that fails (keeps content) or succeeds (replaces it), refresh ignored unless loaded or while already refreshing, empty forecast |
| `SearchViewModelTests` | Minimum length (including whitespace), results, empty and failure, retry, clearing returns to idle, debounce (only the final query is searched), Return skips the debounce, stale responses ignored, recent searches |
| `OpenMeteoGeocodingRepositoryTests` | Mapping live JSON, missing region, missing `results` key, query encoding, HTTP/connectivity/decoding failures, cancellation |
| `OpenMeteoWeatherRepositoryTests` | With `ForecastMapper`: dates are midnights in the city's time zone, live values, `null`s stay `nil`, incomplete days skipped, 4 kinds of malformed forecast, HTTP failure, waves matched by date, every kind of unusable marine response means no waves, a cancelled marine request cancels the whole fetch, exact request parameters |
| `RecentLocationsStoreTests` | Order, de-duplication, capacity, persistence across instances, same name with different IDs, unreadable data |
| `LaunchUITests` (XCTest) | The app launches to the search screen |

### Test doubles

- **`ScriptedGeocodingRepository` / `ScriptedWeatherRepository`** return scripted results in order and record what was asked for.
- **`ControlledGeocodingRepository`** holds each search until the test answers it, so responses can arrive out of order. That's how the stale-response test works.
- **`StubTransport`** replaces `HTTPTransport`, so repository tests run the real client, decoding and mapping code. It records every request, so tests can check the exact URL parameters.
  - Its responses are **live Open-Meteo JSON captured on 2026-11-17**: a Paris search, Singapore (no region), a search with no matches, forecasts for Paris TX and San Francisco, and waves for San Francisco and inland Chamonix (all `null`).
  - The `ForecastJSON` and `MarineJSON` builders start from those live values. Tests edit them to add `null`s, unknown codes and corrupt data.
- **`IsolatedDefaults`** gives each test its own `UserDefaults` suite and deletes it afterwards.

### Previews

27 SwiftUI previews cover every screen state with stub repositories and sample data modelled on real responses: coastal and inland forecasts, loading, failed, refresh failed, accessibility text sizes and dark mode. I used them to review each state visually during development.

### Not tested

- **No snapshot tests**, so visual regressions are caught only by reviewing previews.
- **No live API contract test.** The fixtures prove the app handles responses as they were on 2026-11-17, but not that Open-Meteo still sends them.
- **UI tests stop at the launch smoke test**, because driving the real UI further needs network data or a stub injected at launch (see j).

## f. API usage notes

| Endpoint | Purpose | Parameters |
|---|---|---|
| `https://geocoding-api.open-meteo.com/v1/search` | City search | `name`, `count=10`, `language=<device language>`, `format=json` |
| `https://api.open-meteo.com/v1/forecast` | Daily forecast | `latitude`, `longitude`, `daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,snowfall_sum,wind_speed_10m_max`, `timezone=auto`, `forecast_days=7` |
| `https://marine-api.open-meteo.com/v1/marine` | Wave heights | `latitude`, `longitude`, `daily=wave_height_max`, `timezone=auto`, `forecast_days=7` |

Default units: °C, mm of precipitation, cm of snowfall, km/h of wind, m of wave height.

**Why the Marine API.** The brief names the Geocoding and Forecast APIs, but the Forecast API has no wave data, and surfing can't be judged without it. The Marine API comes from the same provider, takes the same coordinates and runs in parallel with the forecast request. It is treated as optional (see Error handling).

**Observed behaviour**, checked against live responses that are kept as test fixtures:
- When nothing matches, the geocoding response has **no `results` key** at all, rather than an empty array.
- One-character queries return nothing, hence the 2-character minimum.
- For inland locations, the Marine API answers **HTTP 200 with every `wave_height_max` set to `null`**, not an error.
- Any daily value can be `null`, so every measurement is optional in the DTOs.

**Terms of use** (from Open-Meteo's documentation):
- No API key needed.
- The free API is for **non-commercial use only**, and under **10,000 calls a day**.
- Data must be attributed to Open-Meteo. Marine data must also be attributed to the German Weather Service (**DWD**, ICON Wave model).

The app doesn't show this attribution yet (see i and j).

## g. Activity recommendation logic

All scoring lives in `Domain/ActivityRecommendationService.swift`, a pure function of the forecast.

Each activity gets a score from 0 (unsuitable) to 1 (ideal) for each day. It gets `nil` when the day lacks a measurement it depends on.

### The `ramp` helper

```
ramp(value, from: a, to: b) = clamp((value − a) / (b − a), 0, 1)
```

It's 0 at `a`, 1 at `b` and linear in between. `b` may be below `a` for "lower is better".

### Outdoor sightseeing (needs precipitation and wind)

| Factor | Formula | Meaning |
|---|---|---|
| comfort | `min(ramp(high, 5 → 16), ramp(high, 34 → 26))` | 1 from 16 to 26 °C; 0 at 5 °C or below and 34 °C or above |
| dry | `ramp(precipitation, 10 → 0)` | 1 when dry; 0 at 10 mm or more |
| calm | `ramp(wind, 50 → 20)` | 1 at 20 km/h or less; 0 at 50 km/h or more |

`score = 0.45 × comfort + 0.4 × dry + 0.15 × calm`, then ×0.8 in fog and ×0.3 in a thunderstorm.

### Indoor sightseeing

`score = 0.35 + 0.6 × (1 − outdoor sightseeing)`, so it ranges from **0.35** on a perfect day outside to **0.95** on the worst. Indoor sightseeing is always possible, so it never scores 0, but it is most worth recommending when outside is miserable. It is `nil` whenever outdoor sightseeing is.

### Surfing (needs wave height and wind)

A thunderstorm scores **0**. Otherwise:

| Factor | Formula | Meaning |
|---|---|---|
| waves | `min(ramp(wave, 0.3 → 1), ramp(wave, 3.5 → 2.5))` | 1 from 1 to 2.5 m; flat at 0.3 m or less, too big at 3.5 m or more |
| calm | `ramp(wind, 40 → 15)` | 1 at 15 km/h or less; 0 at 40 km/h or more |
| warm | `ramp(high, 8 → 20)` | 1 at 20 °C or more; 0 at 8 °C or less |

`score = waves × (0.6 + 0.4 × calm) × (0.5 + 0.5 × warm)`. Waves decide whether surfing is possible at all, while wind and temperature can each cost up to 40% and 50% of the score.

### Skiing (needs snowfall)

| Factor | Formula | Meaning |
|---|---|---|
| cold | `ramp(high, 8 → 0)` | 1 at 0 °C or below; 0 at 8 °C or above |
| fresh snow | `ramp(snowfall, 0 → 10)` | 1 at 10 cm or more of new snow |

`score = cold × (0.3 + 0.7 × fresh snow)`

### Ranking

- Activities are sorted by score, best first. Unscored (`nil`) activities go last.
- Ties keep declaration order (surfing, outdoor sightseeing, indoor sightseeing, skiing), because Swift's `sorted(by:)` is stable.
- The top activity is highlighted as the day's best, but only if it has a score.

### Weather conditions (WMO codes)

| Codes | Condition |
|---|---|
| 0 | Clear |
| 1, 2 | Partly cloudy |
| 3 | Overcast |
| 45, 48 | Fog |
| 51–57 | Drizzle |
| 61–67, 80–82 | Rain |
| 71–77, 85, 86 | Snow |
| 95–99 | Thunderstorm |

Any other code drops the day. Only fog and thunderstorm affect scores. The rest are for display.

**Worked example.** San Francisco, partly cloudy, 18 °C high, no rain, 14 km/h wind, 1.6 m waves:
- Outdoor sightseeing: comfort 1, dry 1, calm 1, so **1.00**.
- Surfing: waves 1 × calm 1 × (0.5 + 0.5 × 0.83), so **0.92**.
- Indoor sightseeing: 0.35 + 0.6 × 0, so **0.35**.
- Skiing: cold 0, so **0**.

## h. Assumptions

- **The daily maximum stands for the day's temperature.** It's the temperature during daytime activities.
- **Snowfall stands in for ski conditions.** The forecast has no snow depth or slope elevation, so freshly fallen snow is the best available signal. As a result, a freezing day with no new snow still scores 0.3: skiable, not ideal.
- **Waves at the city's coordinates represent nearby surf.** Open-Meteo answers with the marine grid cell nearest the city (for San Francisco, about 4 km away). The app doesn't look for the nearest surf spot.
- **"A ranked list of activities over the next 7 days" means a ranking for each day**, not one ranking for the week. Conditions change day to day, and a per-day ranking answers "what should I do on Saturday?".
- **Dates are the city's local dates**, not the device's.
- **Place names are in the device language.** The geocoding request passes the device's language code.

## i. Trade-offs and omissions

- **No persistent or offline cache.** An in-memory cache was built and then removed, because it added more code and tests than it saved at this scope. An offline cache is the first production item (see j).
- **10 search results.** That's enough to choose among same-name places without a scrolling list.
- **Daily rather than hourly data.** It's simpler to reason about and test. The cost is that a dry morning followed by a stormy afternoon looks like one rainy day.
- **Hand-tuned heuristics.** The thresholds are reasonable and documented, not learned from data.
- **One UI smoke test, no snapshot tests.** Logic and state are covered by unit tests, and visual states by previews.
- **English only**, although every user-facing string is a `LocalizedStringResource` or `String(localized:)` with translator comments. Adding a String Catalog extracts them.
- **iOS 27 only**, which limits reach. The UI relies on iOS 26 APIs such as Liquid Glass, so iOS 26 is the earliest realistic target, but I haven't tested below iOS 27.
- **No in-app data attribution yet**, which Open-Meteo's terms require.

## j. Production-readiness notes

What I would add before shipping:

- **Offline cache:** persist the last forecast for each place and show it immediately, labelled with when it was last updated.
- **Attribution** to Open-Meteo and DWD in the app.
- **A commercial Open-Meteo plan, or self-hosting**, since the free tier is non-commercial and limited to 10,000 calls a day.
- **Networking hardening:** explicit request timeouts, and retry with exponential backoff for connectivity errors and 5xx responses.
- **Observability:** `os.Logger` with categories, crash reporting, and metrics for API failures.
- **CI** that builds and tests every pull request, plus SwiftLint/SwiftFormat.
- **A privacy manifest** declaring the `UserDefaults` API with reason `CA92.1`.
- **Localization**, **snapshot tests**, and **UI tests against stubbed network data**, with the stub selected through a launch argument.
- **Remotely tunable scoring thresholds**, so recommendations can be adjusted without an app release.

## k. Cross-platform delivery notes

### Android equivalent

The architecture maps 1:1 onto Android:

| iOS | Android |
|---|---|
| SwiftUI | Jetpack Compose |
| `@Observable` view model with a state enum | `ViewModel` exposing `StateFlow` of a sealed state class |
| Debounce and cancel in `SearchViewModel` | Flow `debounce` + `flatMapLatest` |
| `OpenMeteoClient` + `Codable` DTOs | Ktor or Retrofit + kotlinx.serialization |
| Repository protocols | Repository interfaces |
| `AppDependencies` | Hilt, or the same manual DI |
| `RecentLocationsStore` (`UserDefaults`) | DataStore |
| Swift Testing + test doubles | JUnit + Turbine (+ fakes) |

### Sharing code

- **Kotlin Multiplatform** could share Domain and Data (models, scoring, DTOs, mapping, repositories) and keep the UI native. That's worth it once the shared logic grows.
- **At this size, I'd recommend two native apps sharing artifacts instead of code:**
  - A written scoring spec, which section g of this README already is.
  - Golden test vectors: forecast days in, expected scores and rankings out.
  - The captured API fixtures.

  Both apps run the same vectors in their unit tests, so their recommendations can't drift apart, and neither team takes on a cross-platform toolchain.

## l. AI usage disclosure

I built this project with Claude Code (Anthropic) as a pair programmer: planning, writing code and tests, code review, and drafting this README.

How I verified the work:
- **I approved every plan before it was implemented.** Architecture, state modelling and scoring decisions were mine to accept, change or reject.
- **Every change was built with 0 warnings** in Swift 6 language mode, and the full unit test suite was run on it.
- **Every UI state was checked in SwiftUI previews,** including accessibility text sizes and dark mode.
- **The app was run on a physical iPhone.**
- **API behaviour was checked against live Open-Meteo responses,** which are now kept as test fixtures, so the edge cases above (missing `results`, `null` waves inland) are pinned by tests rather than assumed.
