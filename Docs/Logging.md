# Logging

To aid with logging, Alchemy provides a thin wrapper on top of `swift-log`.

You can conveniently log to the various levels via the `Log` struct.

```swift
Log.trace("Here")
Log.debug("Testing")
Log.info("Hello")
Log.notice("FYI")
Log.warning("Hmmm")
Log.error("Uh oh")
Log.critical("Houston, we have a problem")
```
