# Specs Portal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish all AI-DLC specification documents on GitHub Pages (shoechoo.com/specs/) with Jekyll rendering and navigation from the landing page.

**Architecture:** Enable Jekyll on docs/ via `_config.yml` with minima theme. Copy aidlc-docs/ content to docs/specs/ preserving directory structure. Add a table-of-contents index page at docs/specs/index.md. Add "Documentation" links to existing landing pages.

**Tech Stack:** Jekyll (GitHub Pages built-in), minima theme, Markdown, HTML

---

## File Structure

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `docs/_config.yml` | Jekyll configuration |
| Create | `docs/specs/index.md` | Table of contents for all spec documents |
| Create | `docs/specs/architecture.md` | Copy of root ARCHITECTURE.md |
| Copy | `docs/specs/inception/**` | All inception phase documents (12 files) |
| Copy | `docs/specs/construction/**` | All construction phase documents (34 files) |
| Modify | `docs/index.html:194-198` | Add Documentation link to footer |
| Modify | `docs/ja.html:194-198` | Add Documentation link to footer |

---

### Task 1: Create Jekyll Configuration

**Files:**
- Create: `docs/_config.yml`

- [ ] **Step 1: Create `_config.yml`**

```yaml
title: Shoe Choo Editor
description: Distraction-free Markdown editor for macOS
theme: minima
baseurl: ""
exclude:
  - superpowers/
```

The `exclude` keeps the superpowers internal directory out of Jekyll's build. Existing HTML files (`index.html`, `ja.html`) pass through Jekyll unchanged.

- [ ] **Step 2: Verify Jekyll doesn't break existing pages**

Run locally if Jekyll is available:
```bash
cd docs && bundle exec jekyll serve
```
Or simply verify that `index.html` and `ja.html` do not contain Jekyll front matter (`---`) and will be served as-is. Both files are plain HTML without front matter, so they will pass through unchanged.

- [ ] **Step 3: Commit**

```bash
git add docs/_config.yml
git commit -m "feat: enable Jekyll on GitHub Pages with minima theme"
```

---

### Task 2: Copy Specification Documents to docs/specs/

**Files:**
- Create: `docs/specs/architecture.md`
- Copy: `docs/specs/inception/` (12 files from aidlc-docs/inception/)
- Copy: `docs/specs/construction/` (34 files from aidlc-docs/construction/)

- [ ] **Step 1: Create docs/specs directory structure**

```bash
mkdir -p docs/specs/inception/requirements
mkdir -p docs/specs/inception/user-stories
mkdir -p docs/specs/inception/plans
mkdir -p docs/specs/inception/application-design
mkdir -p docs/specs/construction/plans
mkdir -p docs/specs/construction/unit-1-core-editor/functional-design
mkdir -p docs/specs/construction/unit-1-core-editor/nfr-requirements
mkdir -p docs/specs/construction/unit-2-document-management/functional-design
mkdir -p docs/specs/construction/unit-2-document-management/nfr-requirements
mkdir -p docs/specs/construction/unit-3-focus-immersion/functional-design
mkdir -p docs/specs/construction/unit-3-focus-immersion/nfr-requirements
mkdir -p docs/specs/construction/unit-4-image-media/functional-design
mkdir -p docs/specs/construction/unit-4-image-media/nfr-requirements
mkdir -p docs/specs/construction/unit-5-export-polish/functional-design
mkdir -p docs/specs/construction/unit-5-export-polish/nfr-requirements
```

- [ ] **Step 2: Copy ARCHITECTURE.md to docs/specs/**

```bash
cp ARCHITECTURE.md docs/specs/architecture.md
```

- [ ] **Step 3: Copy all inception documents**

```bash
cp aidlc-docs/inception/vision.md docs/specs/inception/
cp aidlc-docs/inception/technical-environment.md docs/specs/inception/
cp aidlc-docs/inception/requirements/requirements.md docs/specs/inception/requirements/
cp aidlc-docs/inception/requirements/requirements-questions.md docs/specs/inception/requirements/
cp aidlc-docs/inception/user-stories/personas.md docs/specs/inception/user-stories/
cp aidlc-docs/inception/user-stories/stories.md docs/specs/inception/user-stories/
cp aidlc-docs/inception/plans/execution-plan.md docs/specs/inception/plans/
cp aidlc-docs/inception/plans/story-generation-plan.md docs/specs/inception/plans/
cp aidlc-docs/inception/plans/application-design-plan.md docs/specs/inception/plans/
cp aidlc-docs/inception/plans/user-stories-assessment.md docs/specs/inception/plans/
cp aidlc-docs/inception/application-design/application-design.md docs/specs/inception/application-design/
cp aidlc-docs/inception/application-design/components.md docs/specs/inception/application-design/
cp aidlc-docs/inception/application-design/component-methods.md docs/specs/inception/application-design/
cp aidlc-docs/inception/application-design/component-dependency.md docs/specs/inception/application-design/
cp aidlc-docs/inception/application-design/services.md docs/specs/inception/application-design/
cp aidlc-docs/inception/application-design/unit-of-work.md docs/specs/inception/application-design/
cp aidlc-docs/inception/application-design/unit-of-work-dependency.md docs/specs/inception/application-design/
cp aidlc-docs/inception/application-design/unit-of-work-story-map.md docs/specs/inception/application-design/
```

- [ ] **Step 4: Copy all construction documents**

```bash
cp aidlc-docs/construction/plans/unit-1-functional-design-plan.md docs/specs/construction/plans/

for unit in unit-1-core-editor unit-2-document-management unit-3-focus-immersion unit-4-image-media unit-5-export-polish; do
  cp aidlc-docs/construction/$unit/functional-design/domain-entities.md docs/specs/construction/$unit/functional-design/
  cp aidlc-docs/construction/$unit/functional-design/business-logic-model.md docs/specs/construction/$unit/functional-design/
  cp aidlc-docs/construction/$unit/functional-design/business-rules.md docs/specs/construction/$unit/functional-design/
  cp aidlc-docs/construction/$unit/functional-design/frontend-components.md docs/specs/construction/$unit/functional-design/
  cp aidlc-docs/construction/$unit/nfr-requirements/nfr-requirements.md docs/specs/construction/$unit/nfr-requirements/
  cp aidlc-docs/construction/$unit/nfr-requirements/tech-stack-decisions.md docs/specs/construction/$unit/nfr-requirements/
done
```

- [ ] **Step 5: Add Jekyll front matter to each Markdown file**

Each `.md` file under `docs/specs/` needs Jekyll front matter so it gets rendered. Add a minimal front matter block to every file:

```bash
for f in $(find docs/specs -name '*.md'); do
  if ! head -1 "$f" | grep -q '^---'; then
    sed -i '' '1s/^/---\nlayout: default\n---\n\n/' "$f"
  fi
done
```

This prepends `---\nlayout: default\n---\n\n` to each file that doesn't already have front matter.

- [ ] **Step 6: Verify file count**

```bash
find docs/specs -name '*.md' | wc -l
```

Expected: 47 files (1 architecture + 12 inception + 1 construction plan + 30 unit functional-design/nfr + 3 possible extras = ~47)

- [ ] **Step 7: Commit**

```bash
git add docs/specs/
git commit -m "feat: copy all AI-DLC spec documents to docs/specs/ for GitHub Pages"
```

---

### Task 3: Create Table of Contents Index Page

**Files:**
- Create: `docs/specs/index.md`

- [ ] **Step 1: Create `docs/specs/index.md`**

```markdown
---
layout: default
title: Shoe Choo Specifications
---

# Shoe Choo Specifications

Complete project specifications generated through the AI-DLC (AI-Driven Development Life Cycle) methodology.

[Back to Home](/)

---

## Architecture

- [System Architecture](architecture) — Tech stack, component diagram, data flow, concurrency model, and design decisions

---

## Inception Phase

### Vision & Requirements

- [Vision Document](inception/vision) — Product vision, target users, MVP features, competitive landscape
- [Requirements](inception/requirements/requirements) — Intent analysis, functional and non-functional requirements
- [Requirements Questions](inception/requirements/requirements-questions) — Open questions and decisions from requirements analysis

### User Stories

- [Personas](inception/user-stories/personas) — Target user profiles (Haruka, Kenji, Mei)
- [User Stories](inception/user-stories/stories) — Full user story backlog with acceptance criteria

### Planning

- [Execution Plan](inception/plans/execution-plan) — AI-DLC stage execution plan
- [Story Generation Plan](inception/plans/story-generation-plan) — User story generation methodology
- [Application Design Plan](inception/plans/application-design-plan) — Application design approach
- [User Stories Assessment](inception/plans/user-stories-assessment) — Story quality and coverage assessment

### Application Design

- [Application Design Overview](inception/application-design/application-design) — High-level application architecture
- [Components](inception/application-design/components) — Component breakdown and responsibilities
- [Component Methods](inception/application-design/component-methods) — Public interfaces and method signatures
- [Component Dependencies](inception/application-design/component-dependency) — Dependency graph between components
- [Services](inception/application-design/services) — Service layer design (Export, File, Image)
- [Units of Work](inception/application-design/unit-of-work) — Development unit definitions
- [Unit Dependencies](inception/application-design/unit-of-work-dependency) — Build order and unit dependencies
- [Unit–Story Map](inception/application-design/unit-of-work-story-map) — Mapping of user stories to development units

### Technical Environment

- [Technical Environment](inception/technical-environment) — Development tools, platform requirements, dependencies

---

## Construction Phase

### Planning

- [Unit 1 Functional Design Plan](construction/plans/unit-1-functional-design-plan) — Functional design approach for Unit 1

### Unit 1: Core Editor Engine

- [Domain Entities](construction/unit-1-core-editor/functional-design/domain-entities) — EditorNode, BlockKind, InlineRun, EditorNodeModel
- [Business Logic](construction/unit-1-core-editor/functional-design/business-logic-model) — Parse, render, active-block resolution, formatting
- [Business Rules](construction/unit-1-core-editor/functional-design/business-rules) — Validation rules and constraints
- [Frontend Components](construction/unit-1-core-editor/functional-design/frontend-components) — ShoechooTextView, WYSIWYGTextView, EditorView
- [NFR Requirements](construction/unit-1-core-editor/nfr-requirements/nfr-requirements) — Performance, reliability, usability targets
- [Tech Stack Decisions](construction/unit-1-core-editor/nfr-requirements/tech-stack-decisions) — Technology choices and rationale

### Unit 2: Document Management

- [Domain Entities](construction/unit-2-document-management/functional-design/domain-entities) — MarkdownDocument, file I/O model
- [Business Logic](construction/unit-2-document-management/functional-design/business-logic-model) — Open, save, auto-save, snapshot management
- [Business Rules](construction/unit-2-document-management/functional-design/business-rules) — File handling rules and constraints
- [Frontend Components](construction/unit-2-document-management/functional-design/frontend-components) — DocumentGroup, sidebar, recent files
- [NFR Requirements](construction/unit-2-document-management/nfr-requirements/nfr-requirements) — File I/O performance, data integrity
- [Tech Stack Decisions](construction/unit-2-document-management/nfr-requirements/tech-stack-decisions) — ReferenceFileDocument, NSLock approach

### Unit 3: Focus & Immersion

- [Domain Entities](construction/unit-3-focus-immersion/functional-design/domain-entities) — Focus mode, typewriter scrolling state
- [Business Logic](construction/unit-3-focus-immersion/functional-design/business-logic-model) — Dimming, scroll centering, full-screen
- [Business Rules](construction/unit-3-focus-immersion/functional-design/business-rules) — Focus mode activation rules
- [Frontend Components](construction/unit-3-focus-immersion/functional-design/frontend-components) — Focus overlay, typewriter scroll view
- [NFR Requirements](construction/unit-3-focus-immersion/nfr-requirements/nfr-requirements) — Animation smoothness, responsiveness
- [Tech Stack Decisions](construction/unit-3-focus-immersion/nfr-requirements/tech-stack-decisions) — NSTextView extension approach

### Unit 4: Image & Media

- [Domain Entities](construction/unit-4-image-media/functional-design/domain-entities) — Image reference, assets directory model
- [Business Logic](construction/unit-4-image-media/functional-design/business-logic-model) — Drag-and-drop, paste, filename generation
- [Business Rules](construction/unit-4-image-media/functional-design/business-rules) — Supported formats, path validation
- [Frontend Components](construction/unit-4-image-media/functional-design/frontend-components) — Drop zone, image preview
- [NFR Requirements](construction/unit-4-image-media/nfr-requirements/nfr-requirements) — Import speed, file size limits
- [Tech Stack Decisions](construction/unit-4-image-media/nfr-requirements/tech-stack-decisions) — NSImage, UTType approach

### Unit 5: Export & Polish

- [Domain Entities](construction/unit-5-export-polish/functional-design/domain-entities) — Export configuration, output formats
- [Business Logic](construction/unit-5-export-polish/functional-design/business-logic-model) — HTML generation, PDF rendering pipeline
- [Business Rules](construction/unit-5-export-polish/functional-design/business-rules) — Export format rules, CSS embedding
- [Frontend Components](construction/unit-5-export-polish/functional-design/frontend-components) — Export dialog, preferences
- [NFR Requirements](construction/unit-5-export-polish/nfr-requirements/nfr-requirements) — Export speed, output fidelity
- [Tech Stack Decisions](construction/unit-5-export-polish/nfr-requirements/tech-stack-decisions) — WKWebView PDF, MarkupWalker HTML
```

- [ ] **Step 2: Commit**

```bash
git add docs/specs/index.md
git commit -m "feat: add specs table of contents page"
```

---

### Task 4: Add Documentation Links to Landing Pages

**Files:**
- Modify: `docs/index.html:194-198` (footer section)
- Modify: `docs/ja.html:194-198` (footer section)

- [ ] **Step 1: Add Documentation link to `docs/index.html` footer**

Change the footer from:

```html
<footer>
  <a href="https://github.com/yoshidashingo/shoechoo">GitHub</a> ·
  <a href="https://github.com/yoshidashingo/shoechoo/releases">Releases</a> ·
  <a href="https://github.com/yoshidashingo/shoechoo/blob/main/LICENSE">MIT License</a>
</footer>
```

To:

```html
<footer>
  <a href="https://github.com/yoshidashingo/shoechoo">GitHub</a> ·
  <a href="https://github.com/yoshidashingo/shoechoo/releases">Releases</a> ·
  <a href="specs/">Documentation</a> ·
  <a href="https://github.com/yoshidashingo/shoechoo/blob/main/LICENSE">MIT License</a>
</footer>
```

- [ ] **Step 2: Add Documentation link to `docs/ja.html` footer**

Change the footer from:

```html
<footer>
  <a href="https://github.com/yoshidashingo/shoechoo">GitHub</a> ·
  <a href="https://github.com/yoshidashingo/shoechoo/releases">リリース</a> ·
  <a href="https://github.com/yoshidashingo/shoechoo/blob/main/LICENSE">MIT License</a>
</footer>
```

To:

```html
<footer>
  <a href="https://github.com/yoshidashingo/shoechoo">GitHub</a> ·
  <a href="https://github.com/yoshidashingo/shoechoo/releases">リリース</a> ·
  <a href="specs/">ドキュメント</a> ·
  <a href="https://github.com/yoshidashingo/shoechoo/blob/main/LICENSE">MIT License</a>
</footer>
```

- [ ] **Step 3: Commit**

```bash
git add docs/index.html docs/ja.html
git commit -m "feat: add Documentation link to landing page footer"
```

---

### Task 5: Verify Deployment

- [ ] **Step 1: Check all files are staged correctly**

```bash
git status
git log --oneline -5
```

Expected: 4 new commits (Jekyll config, spec docs copy, TOC page, footer links).

- [ ] **Step 2: Push to trigger GitHub Pages build**

```bash
git push origin main
```

- [ ] **Step 3: Verify GitHub Pages build succeeds**

```bash
gh run list --limit 3
```

Wait for the pages-build-deployment workflow to complete successfully.

- [ ] **Step 4: Verify pages are accessible**

After deployment completes, verify:
- `https://shoechoo.com/` still loads correctly
- `https://shoechoo.com/specs/` shows the table of contents
- `https://shoechoo.com/specs/architecture` renders the architecture doc
- `https://shoechoo.com/specs/inception/vision` renders the vision doc
- Footer links on both `index.html` and `ja.html` point to `/specs/`
