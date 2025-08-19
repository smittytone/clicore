# clicore 0.1.0

This repo contains core CLI functionality used by my Swift CLI apps and utilities.

## Installation

* `cd /path/to/project`
* `git submodule add https://github.com/smittytone/clicore`
* Add the files you require to your project, eg. in Xcode.
    * Make sure you select **Reference files in place**.

## Usage

Each file provides generic CLI functionality. Each includes a Swift struct containing zero or more subsidiary structs and enums. Functions are declared static so do not require a specific instance to be generated. Instead, think of the struct name as a namespace, a bit like C++, but with dot syntax rather than `::`.

### Example

```swift
// Set up Ctrl-C handling
Stdio.enableCtrlHandler("utitool interrupted -- halting")
```
