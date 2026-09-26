---
status: draft
---

# Phase 04 - Clean this repo into the guide

## Overview

After fala-language-tutor runs, this repo drops the product and becomes the guide. Shape only until the audit reports.

## Sketch

- Remove the `fala` and `drop` rows; turn `link` rows into links.
- README and `docs/getting-started.md` become the setup guide, headless and for a person.
- A pattern index listing only what another project uses, each entry either here or a link to where it lives.
- Distribution docs kept as approaches, since this app is not distributed.
- The working app is the gallery (Q6): router and navigation, basic pages, components, storage, and the on-device engine kept from the tutor (Q5), each item a screen that runs.
- Done when `scripts/check.sh` passes, nothing in the tree names the tutor except as a link, and a session asked to bootstrap a new app from this repo finds what it needs.
