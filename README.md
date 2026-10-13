# Greenhouse Monitor: Mobile Technical Assessment

Thanks for taking the time to do this assessment. It mirrors the kind of work you would do day to day on our mobile team: picking up an existing codebase, fixing a bug reported by QA and shipping features on top of it.

**Greenhouse Monitor** is a small iOS app that shows soil moisture, temperature and humidity readings from sensors placed around a greenhouse. It talks to a small HTTP backend we host for you. The only setup is adding your email address (see "Backend setup" below).

## At a glance

| | |
|---|---|
| Time box | About **4 hours** in total. Please don't go much beyond that. |
| Required | iOS: Swift and SwiftUI |
| Optional | Flutter bonus task |
| Tasks | 1 bug fix, 1 small feature, 1 bigger feature, 1 optional bonus |
| Deliverable | **One pull request per task**, plus a small PR with your `SUBMISSION_NOTES.md` (see [Submitting](#submitting)) |

> **You are not expected to finish everything.** Prioritising, making trade-offs and telling us what you left out (and why) is part of what we assess. A well-reasoned, partly finished feature beats a rushed, complete one.

## Getting started

### Requirements

- Xcode 16 or newer
- iOS 17 simulator or newer
- Optional, for the bonus: Flutter 3.32 or newer (stable channel)

### Backend setup (required)

1. Open `ios/GreenhouseMonitor/Resources/Backend.plist`.
2. Set `CandidateEmail` to **the email address you applied with**. `BaseURL` is already filled in.

```xml
<key>CandidateEmail</key>
<string>you@example.com</string>
```

The app sends your email in the `X-Candidate-Token` header of every request. It keeps your data on the server separate from other candidates' data, and lets us see what your app sent while we review.

**Until your email is set, the app doesn't talk to the server.** Instead it:

- shows a red **"Using offline mock data"** banner on the main screen
- logs the reason to the Xcode console
- uses `MockGreenhouseAPI`, an in-process fake that behaves the same way

If the server doesn't recognise your email, requests fail with *"The server did not accept your email address"*. Check for typos, and contact us if it persists. The debug menu shows which backend is in use. Unit tests never touch the network.

### iOS

1. Open `ios/GreenhouseMonitor.xcodeproj`.
2. Select the `GreenhouseMonitor` scheme and any iPhone simulator.
3. Run (⌘R) or test (⌘U).

Or from the command line:

```bash
cd ios
xcodebuild test -project GreenhouseMonitor.xcodeproj -scheme GreenhouseMonitor \
  -destination 'platform=iOS Simulator,name=<an installed iPhone simulator>'
```

The project uses Xcode's folder-synchronised groups, so any file you add under `ios/GreenhouseMonitor/` or `ios/GreenhouseMonitorTests/` is part of the build automatically. There are no third-party dependencies, and you may add some if you can justify them.

### Flutter (only for the bonus)

```bash
cd flutter/greenhouse_monitor
flutter pub get
flutter test
flutter run
```

## How the app is put together

```
ios/GreenhouseMonitor/
  App/            Composition root (AppEnvironment) and app entry point
  Models/         Sensor, Reading
  Networking/     GreenhouseAPI protocol, LiveGreenhouseAPI (HTTP) and MockGreenhouseAPI (in-process fake)
  Services/       ReadingStore (local cache, persisted to disk), SyncService
  Features/       SensorList, SensorDetail, DebugMenu (SwiftUI views + @Observable view models)
ios/GreenhouseMonitorTests/   Unit tests (Swift Testing)
flutter/greenhouse_monitor/   A Flutter version of the list and detail screens
```

- **The backend** behaves like a real remote service: calls take time and can fail. It generates one reading per sensor per minute and keeps the last two hours. `LiveGreenhouseAPI` and `MockGreenhouseAPI` behave the same way, and the mock is what the tests use. Treat the backend as a server you don't own. You may read the client code, but please don't change how it behaves to make your tasks easier.
- **Debug menu** (ladybug icon on the main screen). Here you can:
  - simulate being offline
  - add latency and random failures (the live server applies them to your requests)
  - see the server-side counters for your email, and reset them
  - clear the local reading cache

  Your settings are kept across launches.

## Tasks

We suggest doing them in this order, though it's up to you.

### 1. Bug fix: duplicated readings

> **QA report:** "Every time I pull to refresh, the readings history gets longer than it should. The same readings (same time, same values) show up again and again. To reproduce: open a sensor and note the number in the History header, go back, pull to refresh on the list, then open the same sensor again. The count has jumped by far more than the one or two new readings that arrived. The duplicates stay, even after restarting the app."

- Find the root cause and fix it.
- Add a test that would have caught it.
- In the pull request description, briefly explain:
  - what the cause was
  - how you found it
  - why your fix addresses the cause and not just the symptom

### 2. Small feature: moisture thresholds

Different plants want different amounts of water. Let the user set an acceptable soil-moisture range for each sensor, and highlight sensors that are outside it.

**Acceptance criteria:**
- On the sensor detail screen the user can set a minimum and maximum soil moisture (%) for that sensor.
  - Invalid input is handled: min must be below max, and both must be between 0 and 100.
  - The user can clear the range.
- The thresholds survive an app relaunch. Any persistence approach is fine; tell us why you picked yours.
- On the sensor list, a sensor whose **latest** reading is outside its range shows a clear warning indicator. The indicator must work with VoiceOver, for example "Bench A1, soil moisture 18%, below minimum of 25%".
- User-facing strings go into the string catalog (`Localizable.xcstrings`). At least one of them has more than one argument and uses positional specifiers.
- The range-evaluation logic is unit tested.

### 3. Bigger feature: offline-first care log

Growers want to record what they did to a plant (watered it, fertilised it, moved it) right next to the sensor data. They are often in parts of the greenhouse with poor connectivity.

**Acceptance criteria:**
- **Logging an entry:**
  - From the sensor detail screen, the user can add a care log entry: a kind (`watered`, `fertilised`, `moved` or `other`) and an optional note.
  - The entry appears in the detail screen immediately, whether or not the device is online.
  - Entries are listed newest first.
- **Uploading:**
  - Entries are uploaded with `GreenhouseAPI.postCareLog(_:)`.
  - Each entry visibly shows its state: pending, synced, or failed (with a way to retry).
- **Persistence:** entries that haven't been uploaded yet are not lost when the app is killed and relaunched. They are uploaded later.
- **No duplicates on the server**, including under failures. Read the doc comment on `postCareLog` carefully, and remember that a request can fail after the server has already stored the entry. The debug menu's server stats help you check this.
- **No tight retry loops:** repeated failures must not hammer the server.
- The UI stays responsive while uploads are in progress.
- Tests cover the core upload and queue logic, including failure cases.

**Stretch goals (only if you have time):**
- Upload pending entries automatically when connectivity comes back (see `ConnectivityMonitoring`).
- Show a pending-uploads indicator on the sensor list.
- Anything else you think a real user would need. Tell us about it in the PR description.

### 4. Bonus (optional): Flutter

Implement **task 2 (moisture thresholds)** in the Flutter app under `flutter/greenhouse_monitor`. You may add packages, for example for persistence. Widget and unit tests are welcome. Skipping this costs you nothing.

## What we look at

- **Correctness:** does it work, including edge cases and failure paths?
- **Code quality and consistency:** is your code readable, and does it fit the existing structure and conventions? If you think the structure is wrong, say so and explain why.
- **Concurrency and robustness:** behaviour under latency, failures, offline mode and relaunches.
- **Testing:** meaningful tests for the logic that matters.
- **Prioritisation:** what you chose to do, skip or simplify, and why.
- **Communication:** your pull request descriptions, your commit history and `SUBMISSION_NOTES.md`. Please commit as you go in small, meaningful steps rather than in one big commit at the end, and keep each PR focused on its task.

We don't look at visual polish beyond "clear and usable", and we don't count how many lines you wrote.

## About AI tools

Using AI assistants (Copilot, ChatGPT, Claude, Cursor and so on) is **your choice**, and using them counts neither for nor against you. If you use them, tell us briefly in each PR description how you used them and where you had to correct them.

In the follow-up interview, we'll ask you to walk us through your code and make a small change to it live. Please make sure you understand and can explain everything you submit.

## Submitting

Submit your work as **pull requests** against `main` in the repository we gave you access to: **one pull request per task**.

1. **Create one branch per task, starting from `main`:**

   | Task | Branch | PR title |
   |---|---|---|
   | 1. Bug fix | `task-1-bug-fix` | `Task 1: Fix duplicated readings` |
   | 2. Moisture thresholds | `task-2-moisture-thresholds` | `Task 2: Moisture thresholds` |
   | 3. Offline-first care log | `task-3-care-log` | `Task 3: Offline-first care log` |
   | 4. Flutter bonus (optional) | `task-4-flutter-thresholds` | `Task 4: Flutter moisture thresholds` |
   | Submission notes | `submission-notes` | `Submission notes` |

2. **Open a pull request into `main` for each task branch.**
   - The PR description template appears automatically. Fill it in, because it is where we read your reasoning for that task.
   - The `submission-notes` PR only changes `SUBMISSION_NOTES.md`, with links to your other PRs.
3. **Keep PRs independent where you can.** If one task genuinely builds on another, for example the care log relying on your bug fix:
   - branch it from that task's branch and set that branch as the PR's base, so the diff only shows the new work
   - say so in the description under **Based on**
4. **Unfinished work still gets a PR.** List what's missing under **Left out or simplified**. Open a PR for every task you started, even if it's partial.
5. **Don't merge your PRs.** We review them as they are.
6. **Reply to our email when you're done** so we know your PRs are ready for review. Please don't push further changes after that.

Keep your repository and pull requests private. Don't publish the code elsewhere.

## FAQ

- **Something is ambiguous.** Make a reasonable assumption, write it down in the PR description and carry on.
- **I fixed something small outside the tasks.** Put it in its own small PR rather than mixing it into a task PR.
- **I found other bugs or things I'd improve.** Great! Write them down. Fix them only if it's quick and you have time left after the main tasks.
- **Can I restructure the existing code?** Yes, if it helps your solution. Explain why in the PR description.
- **Can I use UIKit?** Yes, where it makes sense, but the existing screens are SwiftUI.
- **Can I change `MockGreenhouseAPI` or `LiveGreenhouseAPI`?** Please don't change how they behave. Adding test seams is fine if you explain them.
- **The backend is down or unreachable.** Clear `CandidateEmail` to use the in-app mock, and let us know.
