# MobileScreenBuddy
Mobile Component for COP4331 Group 15's project, ScreenBuddy. Screenbuddy aims to give the user an engaging way to track their screen time, and reward them for using their phone less.

## The Stack

Git/Github
Flutter/Dart
MongoDB

## Deploying

On your android device, enable developer mode and allow usb debugging

`flutter` will build it, and adb will install it.

`adb devices` to see your phone connected

`flutter build apk` is builds the apk, use `--debug` for testing and `--release` for demos and releases

`adb install </path/to/apk>` stream installs the app onto the phone
