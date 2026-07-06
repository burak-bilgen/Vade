![Swift Accessibility Skill Cover](assets/cover.svg)

# Swift Accessibility Skill

An Agent Skill that makes accessibility a first-class part of **SwiftUI**, **UIKit**, and **AppKit** development.

Covers all **9 App Store Accessibility Nutrition Labels** across iOS, macOS, watchOS, tvOS, and visionOS.

Works with Claude, Codex, Cursor, and any tool that supports the Agent Skills standard.

---

## What it does

| Mode | Behavior |
|---|---|
| **Writing code** | Applies accessibility silently as you build. Inferred labels marked `[VERIFY]`. Compact summary after each generation. |
| **Auditing code** | Structured report: severity levels, device testing checklist, Nutrition Label readiness. |
| **Nutrition Labels** | Prepares App Store Accessibility Nutrition Label recommendations with pass/fail criteria for all 9 labels, support reasons, and blocked-label reasons. |

---

## Installation

### Claude Code

**Install with `marketplace` (recommended):**

```bash
/plugin marketplace add PasqualeVittoriosi/swift-accessibility-skill
/plugin install swift-accessibility-skill@swift-accessibility-skill
```

**Manual install:**

- User-wide: copy the `swift-accessibility-skill/` folder into `~/.claude/skills/`
- Project-local: copy the `swift-accessibility-skill/` folder into `.claude/skills/`

Add a memory reference in:
- Project: `./CLAUDE.md`
- User-wide: `~/.claude/CLAUDE.md`

by adding:

```md
# Accessibility
- Use `swift-accessibility-skill@swift-accessibility-skill` for SwiftUI/UIKit/AppKit accessibility implementation and audits.
```

### Codex

**Install with `skill-installer` (recommended):**

In Codex, ask it to run:

```text
$skill-installer install https://github.com/PasqualeVittoriosi/swift-accessibility-skill with --path . --name swift-accessibility-skill

```

Restart Codex to pick up the new skill.

**Manual install:**

- User-wide: copy the `swift-accessibility-skill/` folder into `~/.codex/skills/`
- Project-level: copy the `swift-accessibility-skill/` folder into `.codex/skills/`

### Cursor

**Manual install:**

- User-wide: copy the `swift-accessibility-skill/` folder into `~/.cursor/skills/`
- Project-local: copy the `swift-accessibility-skill/` folder into `.cursor/skills/`

### Install locations for other tools

These are the current docs-backed install locations I could verify. In each case, place the `swift-accessibility-skill/` folder inside that tool's `skills` directory.

| Tool | Project path | Global path | Official docs |
|---|---|---|---|
| Antigravity | `.agent/skills/` | `~/.gemini/antigravity/skills/` | [Antigravity Skills](https://antigravity.google/docs/skills) |
| Gemini CLI | `.gemini/skills/` | `~/.gemini/skills/` | [Gemini CLI Skills](https://geminicli.com/docs/cli/skills/) |
| GitHub Copilot | `.github/skills/` | `~/.copilot/skills/` | [Copilot Skills](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills) |
| OpenCode | `.opencode/skills/` | `~/.config/opencode/skills/` | [OpenCode Skills](https://opencode.ai/docs/skills) |
| Windsurf | `.windsurf/skills/` | `~/.codeium/windsurf/skills/` | [Windsurf Skills](https://docs.windsurf.com/windsurf/cascade/skills) |

---

## Usage

The skill **auto-activates** on any SwiftUI, UIKit, or AppKit code. No slash command needed.

Also triggers on: `VoiceOver` · `Voice Control` · `Dynamic Type` · `Reduce Motion` · `screen reader` · `a11y` · `WCAG` · `accessibility audit` · `Nutrition Label` · `accessibilityLabel` · `UIAccessibility` · `NSAccessibility` · `assistive technologies` · `Switch Control`

**Explicit:** `/swift-accessibility-skill`

**Audit:** _"Audit this view for accessibility"_ · _"How accessible is this code?"_ · _"Review the accessibility of MyAmazingView"_

---

## Coverage

### App Store Nutrition Labels

| Label | Reference |
|---|---|
| VoiceOver | `voiceover-swiftui.md` · `voiceover-uikit.md` |
| Voice Control | `voice-control.md` |
| Larger Text | `dynamic-type.md` |
| Dark Interface | `display-settings.md` |
| Differentiate Without Color | `display-settings.md` |
| Sufficient Contrast | `display-settings.md` |
| Reduced Motion | `display-settings.md` |
| Captions | `media-accessibility.md` |
| Audio Descriptions | `media-accessibility.md` |

### Also covers

Switch Control · Full Keyboard Access · AssistiveTouch · Semantic structure · Focus management · Custom rotors · Assistive Access (iOS 17+) · macOS NSAccessibility · watchOS · tvOS Focus Engine · visionOS

### Skill structure

```
swift-accessibility-skill/
├── SKILL.md                          # Main skill instructions
├── references/                       # API docs, code examples, common mistakes
│   ├── voiceover-swiftui.md
│   ├── voiceover-uikit.md
│   ├── voice-control.md
│   ├── dynamic-type.md
│   ├── display-settings.md
│   ├── semantic-structure.md
│   ├── media-accessibility.md
│   ├── motor-input.md
│   ├── nutrition-labels.md
│   ├── assistive-access.md
│   ├── platform-specifics.md
│   ├── testing-auditing.md
│   └── wcag-mapping.md
├── examples/                         # Before/after code
│   ├── before-after-swiftui.md
│   ├── before-after-uikit.md
│   └── before-after-appkit.md
└── resources/                       # Reusable templates & checklists
    ├── audit-template.swift
    └── qa-checklist.md
```

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT — see [LICENSE](LICENSE).
