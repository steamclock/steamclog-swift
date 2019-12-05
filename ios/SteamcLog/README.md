# SteamcLog

SteamcLog is a wrapper around [XCGLogger](https://github.com/DaveWoodCom/XCGLogger) intended to standardize logging practices between Steamclock projects across both iOS and Android.

### Installation

SteamcLog is available through the Swift Package Manager. Add the following entry to your dependencies:
```
.Package(url: COMING SOON)
```

### Usage

SteamcLog is designed to be dropped into new projects and for the most part ignored.

In your `AppDelegate.swift`, create a new global `log` object to call, optionally providing a debug level:
```
#if DEBUG
var log = SteamcLog(.verbose)
#else
var log = SteamcLog(.verbose)
#endif
```

Now you can log pretty much anything, using the familiar XCGLogger syntax:
```swift
log.debug("Hi there!")
log.debug(true)
log.debug(CGPoint(x: 1.1, y: 2.2))
log.debug(MyEnum.Option)
log.debug((4, 2))
log.debug(["Device": "iPhone", "Version": 7])
```


