# Tatami Day

Private iPhone training calendar for one athlete. The home-screen name is **Tatami Day**. It signs in with Apple and opens only for **idan.shoshany.2011@gmail.com**.

This folder was built on Windows. A Mac with Xcode 16 or newer has to compile it. Xcode is not available on this PC, so the project has not been compiled here.

## What it does

- Edge-to-edge day, week, and month calendar
- Every hour of the day, with 60, 30, 15, or 10 minute slots
- Divide any hour into 2, 3, 4, or 6 blocks
- Overlapping sessions sit in columns
- Topics and colors for judo, randori, newaza, running, walking, strength, conditioning, mobility, recovery, sport, food, sleep, and topics you add
- Local notifications before a session, when it ends, and in the morning while it is still open
- A session that requires a mark stays open until you tap Mark done
- A sample training week you can drop onto the current week
- Export and import of a JSON backup
- Delete account, which wipes the on-device sign-in and the sessions

There is no server. Sessions stay on the iPhone.

## Install it on your iPhone

1. Enroll in the Apple Developer Program with **idan.shoshany.2011@gmail.com**. Sign in with Apple will not work on a free Personal Team.
2. Copy this folder to a Mac.
3. Open `TatamiDay.xcodeproj`.
4. Select the Tatami Day target, then Signing & Capabilities, and choose your team. The Sign in with Apple entitlement is already in the project. Leave the bundle id as `com.idan.shoshany.tatamiday` unless Apple says it is taken.
5. Plug in your iPhone, pick it as the run destination, and press Run.
6. On the Apple prompt, choose **Share My Email**. Hide My Email is refused. If you already hid the email, go to Settings → Apple ID → Sign in with Apple → Tatami Day → Stop Using Apple ID, then sign in again and share the email.
7. Allow notifications when the app asks. That is what reminds you to mark a session done.

That install is private. It is not on the public App Store.

## Upload a build without making it public

1. On the Mac, choose Product → Archive.
2. Distribute App → App Store Connect → Upload.
3. In App Store Connect, wait until the build finishes processing.
4. TestFlight → Internal Testing. The Apple ID on the developer account can install it from the TestFlight app. Internal testing is not a public listing and does not go through App Review.

Do not submit this binary for App Store Review. Reviewers sign in with their own Apple ID, the app will refuse them, and the submission will fail. The same is true for an unlisted app, because unlisted apps are still reviewed.

## If you later want a public or unlisted listing

`AppStore/listing.md` has the name, subtitle, description, keywords, privacy answers, age rating, and review notes.

Host these at public https addresses and paste the URLs into App Store Connect:

- `AppStore/privacy-policy.html`
- `AppStore/support.html`

Screenshots at Apple’s required sizes are in `AppStore/screenshots`. They are composed references of the interface. Before a real review, replace them with screenshots from the iOS Simulator. The app icon is `AppStore/icons/AppIcon-1024.png` and is already in the asset catalog.

Export compliance is already answered in the app: it does not use non-exempt encryption.

## First session

Open the + menu and choose **Add a training week**, or tap an empty slot and write your own. Hold an hour label to divide that hour.
