# Vendored code notice

`NSScreen+Notch.swift` and `NotchPanel.swift` adapt notch-geometry and
borderless-panel recipes from **DynamicNotchKit** by MrKai77, MIT-licensed.

Per the foundation decision (issue #3), these two files are copied rather than
consumed as a SwiftPM dependency — DynamicNotchKit is transient-by-design and its
geometry/panel internals are `internal`, so a dependency cannot call them.

Upstream: https://github.com/MrKai77/DynamicNotchKit (MIT License)
