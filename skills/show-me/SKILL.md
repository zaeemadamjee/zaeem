---
name: show-me
description: "Use for /show-me, requests to explain something visually, or topics where understanding depends on seeing a code path, state change, module relationship, or before-and-after shape. Produces concise diagrams, code-shape sketches, and focused HTML artifacts. Use show-me-your-work instead for audit logs and decision trails."
---

# Show me

Make the current point visual. Lead with the visual and keep the supporting prose brief. Pick the smallest form that makes the relationship clear.

## Pick the form

- Use pseudocode for logic and algorithms.
- Use a call tree for a short runtime path.
- Use a component tree for UI structure, state ownership, and package boundaries.
- Use a shallow file tree for module ownership or a proposed refactor.
- Use Mermaid for interaction, data flow, branching, or state transitions across several participants.
- Use a diff-shaped sketch when the surrounding structure exists and the point is what changes.
- Show the whole block when omitted context would hide ownership, order, or a copyable target shape.
- Use one focused HTML file for a visual UI, layout comparison, or concept that text and Mermaid cannot express clearly.

Skip the visual when a fact, one-step action, or short list is clearer on its own.

## Keep the shape honest

Use real symbols, paths, labels, states, and data from the current task. Keep only the details needed to answer the question. Do not add decorative branches, components, or metrics.

For a call tree, show nesting directly:

```text
handleRequest
  parseInput
  loadAccount
    readProfile
    readPermissions
  renderResponse
```

For an existing shape that changes, preserve its layout and mark only the change:

```diff
 src/
 ├── commands/
+│   └── inspect.ts
 ├── sessions/
-└── gateway.ts
+└── gateway/
+    ├── client.ts
+    └── stream.ts
```

Place each visual beside the sentence it supports. Use several visuals only when each one answers a different part of the question.

## Open HTML artifacts

Write HTML as one self-contained, task-local file. Match an existing product's colors, type, spacing, and components when the product is part of the question. Use real labels and data. Support desktop and mobile when the artifact represents a responsive interface.

Open the file with the host's available preview or browser tool. If the host cannot open it, return a path or link the user can open.
