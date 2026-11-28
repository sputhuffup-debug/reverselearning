# Analysis notes: <program name>

Copy this file once per program. Record addresses as offsets from the image base (Ghidra address − `0x140000000`). Method: [How to approach an unknown program](../primers/00-approach.md).

## Target

| Field | Value |
| --- | --- |
| File | `bin/dayN/<name>.exe` |
| Size (bytes) | |
| SHA-256 | |
| Date and analyst | |
| Goal | What you were asked to find |

## Triage

- **Kind:** PE32 or PE32+; console or window; `.exe` or `.dll`.
- **Sections:** anything unusual (names, W+X, size in file versus memory, entry point).
- **Packed?** yes / no / unsure, and why.
- **Imports that matter** (leave out runtime noise):
- **Strings that matter:**
- **First run** (input, output, exit code):

## Functions

| Offset | Name | Purpose | Confidence | How you know |
| --- | --- | --- | --- | --- |
| `0x0000` | `main` | | known / guess | |

## Hypotheses

| # | Hypothesis | Evidence | Test | Result |
| --- | --- | --- | --- | --- |
| H1 | | | | confirmed / refuted / open |

## Answer

The answer, and the shortest way to show it is right: an input and its output, or a register value at an address.

## Open questions

- Anything you saw but didn't explain.
