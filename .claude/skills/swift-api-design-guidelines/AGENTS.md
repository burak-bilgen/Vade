# API Design Guidelines Skill Authoring Guide

## Core Principles
- Optimize for clarity at the point of use.
- Treat clarity as more important than brevity.
- Keep instructions factual, specific, and testable in code review.
- Prefer Swift-native idioms over personal style preferences.
- Keep the skill focused on API design, naming, labels, and documentation quality.

## Content Guidelines
- Keep `SKILL.md` procedural and concise.
- Put detailed rule explanations and examples in `references/`.
- Organize content by decision points the agent can apply while reviewing or writing code.
- Use concrete "good vs bad" examples for naming and labels.
- Avoid duplicating the same rule in multiple files unless needed for quick-reference context.

## What To Include
- Swift API naming rules and argument-label guidance.
- Documentation comment rules and symbol-markup usage.
- Mutating/nonmutating naming pairs and side-effect naming patterns.
- Conventions for terminology, casing, overload design, and default parameters.
- Review checklists and action-oriented guidance for code changes.

## What To Exclude
- App architecture prescriptions (MVVM/VIPER/etc.).
- Style debates unrelated to API surface design.
- Language features not relevant to API clarity.
- Long historical commentary or rationale not needed for implementation decisions.
- Duplicate reference material across multiple files.

## Language And Tone
- Use direct, technical language.
- Use imperative instructions for actionable rules.
- Prefer short paragraphs and bullet lists over prose-heavy explanations.
- Keep examples compact and realistic.
- Avoid motivational or opinionated language.

## Examples
- Include paired examples where possible:
  - Ambiguous vs clear API names.
  - Redundant vs concise naming.
  - Incorrect vs correct argument labels.
  - Overload ambiguity vs explicit method naming.
- Prefer examples that reveal point-of-use readability, not declaration-only quality.

## Updating The Skill
- Update `SKILL.md` first when workflow or review process changes.
- Update only the affected `references/*.md` files when a rule changes.
- Preserve section structure so other agents can find guidance predictably.
- Keep `references/` filenames stable; add new files only for genuinely new topics.
- Validate checklists against the references after each update.

## Summary
This skill should help agents design and review Swift APIs that read clearly at call sites, follow established Swift naming and labeling conventions, and maintain high documentation quality with minimal ambiguity.
