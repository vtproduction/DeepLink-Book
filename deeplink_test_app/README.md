# Deeplink Test App

A small standalone Flutter app for testing custom URI schemes from Deeplink Book.

The app registers the `deeplinktest` scheme and displays the last received URI,
including its scheme, host, path, query parameters, mapped destination, and
received timestamp.

## Example Deeplinks

```text
deeplinktest://home
deeplinktest://profile
deeplinktest://transfer?id=123&amount=500
deeplinktest://product/42?source=deeplink_book
```

## Android

Install the app on an Android device or emulator, then run:

```bash
adb shell am start \
  -a android.intent.action.VIEW \
  -d "deeplinktest://transfer?id=123&amount=500"
```

## iOS Simulator

Install the app on a booted iOS simulator, then run:

```bash
xcrun simctl openurl booted \
  "deeplinktest://product/42?source=deeplink_book"
```
