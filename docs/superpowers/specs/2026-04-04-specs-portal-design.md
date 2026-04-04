# Specification Documentation Portal Design

**Date:** 2026-04-04
**Status:** Approved

## Problem

The shoechoo project has comprehensive specification documents in `aidlc-docs/` (52 files covering inception through construction phases), but none of them are accessible from the public website (shoechoo.com). Contributors and users have no way to discover or browse project specifications without navigating the GitHub repository directly.

## Solution

Enable Jekyll on GitHub Pages and publish all AI-DLC specification documents under `docs/specs/`, with a table-of-contents index page and navigation links from the existing landing pages.

## Architecture

### Jekyll Configuration

- Add `docs/_config.yml` with `minima` theme (GitHub Pages built-in, no extra setup)
- Existing `index.html` and `ja.html` continue to work as-is in Jekyll environment
- Only Markdown files under `specs/` are rendered by Jekyll

### Directory Structure

```
docs/
├── _config.yml                  # Jekyll config (new)
├── index.html                   # Existing landing page (add Documentation link)
├── ja.html                      # Existing Japanese landing page (add link)
├── CNAME
├── icon.png
└── specs/
    ├── index.md                 # Table of contents (new)
    ├── architecture.md          # Copy of root ARCHITECTURE.md
    ├── inception/
    │   ├── vision.md
    │   ├── requirements/
    │   │   ├── requirements.md
    │   │   └── requirements-questions.md
    │   ├── user-stories/
    │   │   ├── personas.md
    │   │   └── stories.md
    │   ├── plans/
    │   │   ├── execution-plan.md
    │   │   ├── story-generation-plan.md
    │   │   ├── application-design-plan.md
    │   │   └── user-stories-assessment.md
    │   ├── application-design/
    │   │   ├── application-design.md
    │   │   ├── components.md
    │   │   ├── component-methods.md
    │   │   ├── component-dependency.md
    │   │   ├── services.md
    │   │   ├── unit-of-work.md
    │   │   ├── unit-of-work-dependency.md
    │   │   └── unit-of-work-story-map.md
    │   └── technical-environment.md
    └── construction/
        ├── plans/
        │   └── unit-1-functional-design-plan.md
        ├── unit-1-core-editor/
        │   ├── functional-design/
        │   └── nfr-requirements/
        ├── unit-2-document-management/
        │   ├── functional-design/
        │   └── nfr-requirements/
        ├── unit-3-focus-immersion/
        │   ├── functional-design/
        │   └── nfr-requirements/
        ├── unit-4-image-media/
        │   ├── functional-design/
        │   └── nfr-requirements/
        └── unit-5-export-polish/
            ├── functional-design/
            └── nfr-requirements/
```

### Landing Page Changes

- Add a "Documentation" link to `docs/index.html` (in the footer area)
- Add a "ドキュメント" link to `docs/ja.html` (same position)
- Minimal change: single anchor element pointing to `/specs/`

### Table of Contents Page (specs/index.md)

Organized by AI-DLC lifecycle phase:

1. **Inception** — Vision, Requirements, User Stories, Application Design
2. **Construction** — Functional Design and NFR Requirements for all 5 units
3. **Architecture** — System architecture overview

Each section lists documents with brief descriptions and relative links.

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Jekyll theme | minima | GitHub Pages built-in, zero config |
| Document location | Copy to docs/specs/ | GitHub Pages serves from docs/, aidlc-docs/ is not served |
| Landing page change | Add link only | Minimal risk to existing design |
| Document structure | Mirror aidlc-docs/ layout | Familiar to contributors, easy to maintain |

## Out of Scope

- Search functionality within docs
- Custom Jekyll theme or layout
- Automated sync between aidlc-docs/ and docs/specs/
- Localized (Japanese) versions of spec documents
