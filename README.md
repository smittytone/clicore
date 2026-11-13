# clicore 0.9.0

This repo contains core CLI functionality used by my Swift CLI apps and utilities.

## Installation (Swift PM)

* Add the package as a dependency in Xcode or your project’s own `Package.swift` file.

## Usage

Each file provides generic CLI functionality. Each includes a Swift struct containing zero or more subsidiary structs and enums. Functions are declared static so do not require a specific instance to be generated. Instead, think of the struct name as a namespace, a bit like C++, but with dot syntax rather than `::`.

### Examples

```swift
// Set up Ctrl-C handling
Stdio.enableCtrlHandler("utitool interrupted -- halting")
```

```swift
// Move up five lines
Stdio.report(Stdio.ShellCursor.up(lines: 5))
```

```swift
// Head output with emoji
Stdio.settings.useEmoji = true
```

## Ownership

`clicore` code is © 2026, Tony Smith (@smittytone). It is licensed under the terms of the [MIT Licence](LICENCE.md).

_This software was not written by a human. However, AI has been used to assist in research, code review and testing. Code suggested by AI has been reviewed and modified by a human._
