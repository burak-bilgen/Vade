# Contributing

Thank you for contributing to the Accessibility skill.

## What to Contribute

- New API patterns for accessibility features not yet covered
- Bug fixes for incorrect API names or availability
- Code examples for edge cases or advanced patterns
- Updates for new iOS/macOS/watchOS/tvOS/visionOS releases
- Corrections to Nutrition Label criteria as they get updated
- New before/after examples for common mistakes

## Guidelines

### Accuracy First

- Verify all API names against official documentation before submitting
- Specify platform availability for all APIs (e.g., iOS 17+)
- Nutrition Label criteria must match the official guidelines

### Code Examples

- All code must be valid Swift (no Objective-C)
- Examples should be minimal and focused
- Include SwiftUI, UIKit, and AppKit variants where applicable
- Add `// [VERIFY]` comments when a label or value is inferred from context
- Use `#available` guards for APIs introduced after iOS 15

### Reference Files

- Organize by feature area (not by platform)
- Include a Common Mistakes or Common Failures table at the end of each file
- Prefer concrete code examples over abstract descriptions

## Submitting Changes

1. Fork the repository
2. Create a branch: `git checkout -b feature/add-xyz-pattern`
3. Make your changes following the guidelines above
4. Submit a pull request with a clear description of what changed and why

## Reporting Issues

Open a GitHub Issue for:
- Incorrect API names or signatures
- Missing accessibility features
- Outdated information after SDK updates
- Code examples that don't compile
