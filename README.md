# TodoApp

A simple SwiftUI ToDo app for testing iOS builds on Linux with [xtool](https://github.com/xtool-org/xtool).

## Dependencies

| Library | Used for |
|---|---|
| swift-identified-collections (+ swift-collections) | `IdentifiedArrayOf<Todo>` in the store |
| Alamofire | Importing sample todos from jsonplaceholder.typicode.com |
| Defaults | Persisting settings (hide completed, sort order) |
| ConfettiSwiftUI | Confetti when a todo is completed |
| Kingfisher (vendored in `Vendor/Kingfisher`) | Remote image in the empty state |

## Build

```sh
xtool dev build            # debug .app -> xtool/TodoApp.app
xtool dev build -c release
xtool dev                  # build + install + run on a connected device
```

## Known xtool issue: cross-import overlays

On Linux, xtool (1.22.2, Swift 6.4.1, iPhoneOS 27.1 SDK) does not resolve Swift
cross-import overlays. For example, `import PhotosUI` + `import SwiftUI` should
implicitly load `_PhotosUI_SwiftUI` (where `PhotosPickerItem` lives), but it
does not:

```
error: cannot find type 'PhotosPickerItem' in scope
```

Upstream Kingfisher 8.x fails because of this
(`PhotosPickerItemImageDataProvider.swift`). The workaround is to pass
`-Xfrontend -enable-cross-import-overlays`. SwiftPM rejects `unsafeFlags` in
remote dependencies, and xtool ignores `swift package edit`, so Kingfisher is
vendored as a local path package with this flag added to its `Package.swift`.
