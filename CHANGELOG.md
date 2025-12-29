## Release Notes

- 0.4.0 *Unreleased*
    - Make `Stdio.ShellCursor` functions Struct functions (ie. static).
    - Rename `Stdio.ShellStyle` and `Stdio.ShellColour` private `tostring()` functions `string()` (non-breaking).
    - Rename `Stdio.ShellCursor.toColumn(column)` function `Stdio.ShellCursor.to(column)` (non-breaking as old form is preserved, but deprecated).
    - Add initial tests.
- 0.3.0 *15 December 2025*
    - Add new `cls()` function to `Stdio` via `Stdio.ShellCursor`.
- 0.2.1 *31 October 2025*
    - Adhere to Unix LF-only end-of-line convention for output.
- 0.2.0 *14 September 2025*
    - Handle assigment arguments.
- 0.1.0 *19 August 2025*
    - Initial public release.
