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
