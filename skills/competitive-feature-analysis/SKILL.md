---
name: competitive-feature-analysis
description: Research how leading competitors and best-in-class products design and implement a specific feature by inspecting current product experiences in a web browser, capturing screenshot evidence, comparing patterns and tradeoffs, and recommending an approach for the user's original product or design prompt. Use for feature-level product or UX research when designing, scoping, improving, or validating a feature; studying UX conventions or best practices; benchmarking a workflow; or answering questions such as "how do competitors solve this?" and "what pattern should we use?" Do not use for generic company profiles, market sizing, or broad business-competitor analysis without a feature or user workflow to inspect.
---

# Competitive Feature Analysis

Produce evidence-based feature guidance from current, visually inspected product experiences. Compare the same user job across a small set of strong products, then translate the findings into a recommendation suited to the user's context rather than copying a competitor.

## 1. Frame the research question

Extract or infer:

- The feature, workflow, or decision to investigate
- The product category and closest competitive set
- The target user, platform, market, and key constraints
- The decision the research must help the user make

Use conversation and workspace context before asking questions. State reasonable assumptions and proceed. Ask only when ambiguity would materially change the comparison set or recommendation.

Reduce a broad prompt to a comparable user job, such as "invite a teammate and manage their role" rather than "collaboration." Define the states worth observing: entry point, main flow, completion, and any important empty, error, permission, upgrade, or recovery state.

## 2. Choose the comparison set

Research 3–5 products by default. Prefer quality and relevance over coverage.

Prioritize, in order:

1. Direct competitors known for mature product design or a strong implementation of the feature
2. Category leaders whose scale, customer segment, or business model resembles the user's product
3. Adjacent best-in-class products that solve the same user job especially well

Do not equate popularity with design quality or present "best in class" as an objective fact. Briefly explain why each product belongs in the set using current evidence such as product maturity, recognized design quality, adoption, or clear feature leadership. Label each product as direct competitor, category leader, adjacent analogue, or design exemplar. Exclude products whose audience, platform, or workflow makes the comparison misleading.

If the user names competitors, include them unless inaccessible or irrelevant, then add stronger exemplars when useful. If fewer than three credible examples exist, use the available set and disclose the limitation.

Stop when three credible implementations establish the important patterns, or after five products when another example would not change the conclusion. Do not pad the report with weak comparisons.

## 3. Inspect the actual experience

Use the available interactive browser-control skill and follow its setup and authentication guidance. Prefer the in-app browser unless the user explicitly requests Chrome or the task depends on an existing Chrome session. Use search for discovery, but open and visually inspect the sources that support the analysis.

If interactive browser control is unavailable, disclose that the required visual inspection and screenshot evidence cannot be completed. Follow the browser-control skill's prescribed recovery guidance, but stop after two consecutive setup or navigation failures after troubleshooting. Do not present search-only research as a full competitive feature analysis; offer a clearly labeled preliminary source review instead when it would still help. Cap browser-unverified functional findings at Medium confidence and current visual or interaction claims at Low confidence.

Use this evidence hierarchy:

1. Current live product UI
2. Official interactive demos, help documentation, release notes, and product pages
3. Official app-store media or first-party videos
4. Recent, reputable third-party walkthroughs when first-party evidence is unavailable

For every product, keep the platform and viewport comparable where possible, follow the same user job, and record:

- Discoverability and entry point
- Information architecture and step sequence
- Layout, controls, defaults, and progressive disclosure
- Microcopy and guidance
- Feedback, status, success, error, empty, and recovery states
- Permissions, collaboration, upgrade, or trust boundaries when relevant
- Responsive behavior and accessibility signals that are directly observable
- Notable strengths, weaknesses, and tradeoffs

Distinguish direct observation from inference. Label marketing claims, documentation-only findings, and potentially stale evidence. Record the inspected URL, access date, platform or viewport, native app versus mobile web, access tier, navigation path, and source publication or update date when available. An updated article may contain older interface images; note visible version mismatches or unknown image dates. Do not infer native-app behavior from mobile web or hidden implementation details from surface behavior. From static evidence alone, do not claim animation, responsive behavior, accessibility compliance, or unobserved edge-state behavior. Phrase negative findings as "not observed in the inspected flow" rather than claiming the product lacks a capability.

Remain read-only unless the user authorizes an interaction that changes external state. Do not purchase, subscribe, start a trial, publish, invite people, or submit consequential forms. When completing the flow would create or change data, inspect through the last safe step, then use pre-existing test state or first-party documentation for the resulting state. Never bypass authentication, paywalls, CAPTCHAs, or access controls. If sign-in is essential, ask the user to sign in using the selected browser and continue when they confirm.

## 4. Capture screenshot evidence

Capture screenshots during browser inspection, not from search-result thumbnails. Capture each decision-relevant state: one image may be enough for a simple pattern, while a multi-step flow commonly needs 2–4. Favor focused evidence over full-page clutter and stop when another image would not support a new claim.

When live UI is inaccessible, an image embedded in current first-party documentation may be included as secondary evidence. Caption it explicitly as a documentation image, include the document and image date when known, and never describe it as a live UI capture.

For each screenshot:

- Show the feature, state, or pattern being discussed
- Avoid exposing personal, confidential, or unrelated account information
- Provide a caption with product, surface/state, what the image demonstrates, source URL, and access date
- Reference the screenshot directly beside the corresponding analysis
- Preserve the original capture if creating a crop or annotation

Do not fabricate, substitute, or imply screenshots that were not captured. If a product blocks capture or is not visually accessible, say so and use the strongest available source with a lower confidence rating.

Ensure every capture has a durable path or artifact handle that can be rendered in the final report. If delegating product inspections, give each worker the same rubric and require accessible screenshot artifacts plus captions, source URLs, dates, platform or viewport, access tier, and observation-versus-inference labels before synthesis.

## 5. Synthesize before recommending

Compare products against common criteria instead of writing disconnected summaries. Identify:

- Convergent patterns that appear to be category conventions
- Meaningful differences and the product assumptions behind them
- One-off innovations worth considering
- Recurring usability risks or anti-patterns
- Gaps none of the reviewed products solve well

Treat repeated patterns as evidence, not proof of best practice. Evaluate each pattern against the user's target user, product maturity, technical constraints, business model, accessibility needs, and desired differentiation.

Build the recommendation from the findings. Make clear which evidence supports each major choice. Prefer a specific proposed flow or behavior over generic advice, and call out what not to copy. Separate low-cost baseline decisions from higher-risk experiments that require validation.

## 6. Deliver the report

Return a concise report in the response unless the user requests a separate artifact. Use this structure:

### Recommendation

Lead with the proposed approach and the decision it resolves. Include the recommended flow, key design choices, and important tradeoffs.

### Executive summary

Summarize 3–5 findings that most influenced the recommendation.

### Scope and comparison set

State the user job, platform and audience assumptions, products reviewed, why they were selected, evidence quality, and research date.

### Comparison matrix

Use a compact table with products as rows and common criteria as columns. Keep cells analytical and comparable.

### Product findings

For each product, include:

- Screenshot(s) with captions
- A short description of the observed solution
- Strengths, weaknesses, and distinctive choices
- Source links and whether evidence came from live UI, first-party material, or a secondary source

### Cross-competitor patterns

Explain conventions, meaningful divergences, notable innovations, and gaps.

### Proposed feature direction

Translate the evidence into:

1. Recommended entry point and user flow
2. Essential states, controls, defaults, and microcopy principles
3. Patterns to adopt, adapt to the user's context, avoid, or defer
4. Open questions and a small validation plan

### Confidence and limitations

State inaccessible products, missing states, regional or account-tier differences, stale evidence risks, inspectability bias, and which conclusions are inferred. Use High, Medium, or Low confidence for consequential recommendations.

Keep factual claims traceable to links or screenshots. Make the final answer self-contained even if progress updates were provided during research.

For a preliminary source review, label the report as such, include only source-verified functional findings, identify documentation images explicitly, omit claims of live visual coverage, and retain the confidence and limitations section.
