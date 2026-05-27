# 📄 `docs/systems/app-controller.md`

# AppController

## Overview

Top-level application coordinator responsible for:

* app lifecycle
* initialization flow
* global service orchestration
* dependency bootstrap

This is the root orchestration layer of the application.

---

## Responsibilities

* Initialize application services
* Configure runtime environment
* Initialize LLM runtime
* Configure storage
* Configure routing
* Hold global app state

---

## Ownership & Lifetime

* Created at app startup
* Lives for entire app lifecycle
* Singleton/provider-managed

---

## Core State

Holds:

* initialization status
* runtime availability
* app-level error state
* current app mode

---

## Initialization Flow

```text id="app-init-flow"
App Launch
  ↓
Initialize Hive
  ↓
Initialize Runtime Adapter
  ↓
Validate Model Availability
  ↓
Initialize Services
  ↓
Navigate to Welcome Screen
```

---

## Interactions

### Uses

* LLMRuntimeAdapter
* StorageService
* ConversationRepository
* Router configuration

---

### Used By

* UI bootstrap
* Routing layer
* Global providers

---

## Constraints

* No UI rendering logic
* No conversation orchestration
* No model-specific logic

---

## Failure Handling

Must gracefully handle:

* runtime unavailable
* model load failure
* corrupted local storage

Fallback:

* show recoverable error UI

---

---

# 📄 `docs/systems/llm-runtime-adapter.md`

# LLMRuntimeAdapter

## Overview

Abstraction layer separating application logic from inference runtime implementation.

This is one of the most important architectural systems in the project.

---

## Responsibilities

* Standardize inference interface
* Hide backend implementation details
* Provide structured generation entrypoints
* Handle runtime lifecycle

---

## Initial Backend

Initial implementation:

* flutter_gemma

Future possible implementations:

* llama.cpp
* TFLite-native
* cloud adapters

---

## Core Design Principle

Application logic must never know:

* which runtime is used
* model file structure
* backend-specific APIs

---

## Public Interface (Conceptual)

```text id="runtime-api"
initialize()
generate()
generateStructured()
dispose()
isAvailable()
```

---

## Structured Generation Responsibilities

The adapter must support:

* prompt submission
* schema-aware generation
* retry pipeline hooks
* future constrained decoding support

---

## Runtime Lifecycle

### Initialization

* load model
* allocate runtime resources
* validate readiness

---

### Inference

* receive normalized request
* invoke backend
* stream or return output

---

### Shutdown

* release resources
* cleanup memory

---

## Constraints

* No UI logic
* No conversation history management
* No persistence logic

---

## Failure Handling

Must handle:

* runtime unavailable
* inference timeout
* malformed outputs
* model loading failures

---

---

# 📄 `docs/systems/conversation-controller.md`

# ConversationController

## Overview

Central orchestration layer for conversational interactions.

Owns:

* conversation state
* message flow
* orchestration pipeline
* interaction lifecycle

---

## Responsibilities

* Manage message history
* Send prompts
* Receive model outputs
* Coordinate structured validation
* Update conversation state

---

## Ownership & Lifetime

* Scoped to conversation session
* Riverpod-managed

---

## Core State

Holds:

* message history
* loading state
* generation state
* current runtime status
* validation state

---

## Conversation Flow

```text id="conversation-flow"
User Message
  ↓
Append To History
  ↓
Build Prompt Context
  ↓
Send To Runtime
  ↓
Receive Raw Output
  ↓
Validate Structured Output
  ↓
Retry/Fix If Needed
  ↓
Append Assistant Message
```

---

## Context Window Strategy

Initial v0.1:

* full history persisted
* rolling subset sent to model

Future:

* summarization
* retrieval
* semantic pruning

---

## Interactions

### Uses

* LLMRuntimeAdapter
* StructuredOutputValidator
* ConversationRepository

---

### Used By

* ConversationScreen
* Debug tools

---

## Constraints

* No widget rendering
* No runtime-specific logic
* No storage implementation details

---

## Failure Handling

Must gracefully handle:

* invalid outputs
* runtime failures
* retry exhaustion

---

---

# 📄 `docs/systems/structured-output-system.md`

# Structured Output System

## Overview

Responsible for transforming unreliable model outputs into validated typed application objects.

This system is mandatory.

---

## Responsibilities

* Define schemas
* Validate outputs
* Parse typed objects
* Retry/fix malformed outputs

---

## Design Philosophy

LLM outputs are treated as:

> untrusted external input

---

## Architecture

```text id="structured-system"
Prompt
  ↓
Model Output
  ↓
JSON Extraction
  ↓
Schema Validation
  ↓
Typed Model Parsing
  ↓
Validated Object
```

---

## Validation Strategy

Hybrid layered approach:

1. Prompt-level formatting instructions
2. JSON extraction
3. Schema validation
4. Retry/fix loop
5. Future constrained decoding support

---

## Schema Strategy

Generated typed models using:

* `freezed`
* `json_serializable`

---

## Initial Schema Size

Small schema (~5 fields).

Example fields:

* reply
* confidence
* intent
* follow_up_question
* emotional_tone

---

## Constraints

* No UI logic
* No runtime ownership
* No persistence logic

---

## Failure Handling

Must handle:

* invalid JSON
* partial JSON
* hallucinated fields
* missing required fields

---

---

# 📄 `docs/systems/conversation-repository.md`

# ConversationRepository

## Overview

Persistence abstraction for conversation storage.

Separates storage implementation from business logic.

---

## Responsibilities

* Save conversations
* Load conversations
* Update conversation history
* Persist metadata

---

## Storage Backend

Initial backend:

* Hive

---

## Stored Data

### Messages

* user messages
* assistant messages

---

### Metadata

* timestamps
* runtime info
* validation status

---

## Public Interface (Conceptual)

```text id="repository-api"
saveConversation()
loadConversation()
appendMessage()
deleteConversation()
```

---

## Constraints

* No UI logic
* No inference logic
* No validation logic

---

## Future Expansion

Possible future support:

* multi-conversation management
* search
* embeddings
* summaries

---

---

# 📄 `docs/systems/runtime-model-manager.md`

# RuntimeModelManager

## Overview

Responsible for model asset lifecycle management.

Separates model handling from inference orchestration.

---

## Responsibilities

* Detect installed models
* Validate model compatibility
* Manage model loading metadata
* Handle future model switching

---

## Initial Scope

v0.1:

* single bundled model
* single runtime backend

---

## Future Scope

Possible future features:

* downloadable models
* multiple models
* model capability registry

---

## Constraints

* No inference logic
* No conversation orchestration

---

---

# 📄 `docs/systems/welcome-screen.md`

# Welcome Screen

## Responsibilities

* Initial application entry screen
* Display runtime readiness
* Start conversation session

---

## UI Elements

* App title
* Start button
* Runtime status
* Optional debug info

---

## States

* Initializing
* Ready
* Error

---

## Navigation

```text id="welcome-nav"
Welcome Screen
  ↓
Conversation Screen
```

---

## Constraints

* No inference logic
* No conversation orchestration

---

---

# 📄 `docs/systems/conversation-screen.md`

# Conversation Screen

## Responsibilities

Primary interaction interface for tutoring conversations.

---

## UI Elements

* Message list
* User input field
* Send button
* Loading/generation indicator

---

## Rendering Requirements

* Efficient scrolling
* Incremental updates
* Mobile-safe layout

---

## Interaction Flow

```text id="screen-flow"
Input
  ↓
Send
  ↓
Generation State
  ↓
Structured Response
  ↓
Render Assistant Message
```

---

## Constraints

* UI-only responsibilities
* No runtime ownership
* No persistence ownership

---

---

# 📄 `docs/systems/generated-models.md`

# Generated Typed Models

## Overview

Application data models generated using:

* `freezed`
* `json_serializable`

---

## Responsibilities

* Immutable DTOs
* JSON serialization
* Validation-friendly typing

---

## Initial Models

### ConversationMessage

Represents:

* role
* content
* timestamp

---

### StructuredTutorResponse

Represents:

* reply
* confidence
* intent
* follow_up_question
* emotional_tone

---

## Constraints

* Pure data only
* No business logic
* No UI logic

---

# 📄 `docs/implementation-roadmap-v0.1.md`

# Implementation Roadmap – v0.1

## Phase 1 — Bootstrap

Goals:

* Flutter app runs
* Riverpod configured
* GoRouter configured
* Hive initialized

---

## Phase 2 — UI Skeleton

Goals:

* Welcome screen
* Conversation screen
* Navigation flow

---

## Phase 3 — Local Runtime Integration

Goals:

* flutter_gemma integration
* model loading
* simple inference

---

## Phase 4 — Structured Output Pipeline

Goals:

* schema definitions
* validation pipeline
* retry/fix loop

---

## Phase 5 — Persistence

Goals:

* conversation persistence
* history loading
* metadata persistence

---

## Phase 6 — UX Stabilization

Goals:

* loading states
* error handling
* smooth interaction flow

---

# ✅ Current State

You now have:

* functional architecture
* runtime abstraction
* structured output architecture
* persistence architecture
* implementation roadmap
* AI-compatible project structure

At this point, you are ready to:

1. create repository
2. scaffold Flutter app
3. configure dependencies
4. begin implementation systematically
