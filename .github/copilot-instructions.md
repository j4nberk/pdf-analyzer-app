# Copilot Instructions

## Project Overview

`pdf-analyzer-app` is an iOS application built with Swift that allows users to analyze PDF documents. The app provides functionality to load, display, and extract information from PDF files.

## Tech Stack

- **Language**: Swift
- **Platform**: iOS
- **UI Framework**: SwiftUI (preferred) or UIKit
- **PDF Handling**: PDFKit (Apple's native framework)
- **Package Manager**: Swift Package Manager (SPM)
- **Minimum Deployment Target**: iOS 16+

## Project Structure

```
pdf-analyzer-app/
├── Sources/          # Swift source files
├── Tests/            # Unit and UI tests
├── Resources/        # Assets, storyboards, and other resources
└── Package.swift     # Swift Package Manager manifest (if applicable)
```

## Coding Conventions

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use `camelCase` for variable and function names, `PascalCase` for types
- Prefer `struct` over `class` unless reference semantics are needed
- Use `async/await` for asynchronous operations
- Avoid force-unwrapping (`!`); use `guard let` or `if let` for optional handling
- Write descriptive names — avoid abbreviations unless widely understood (e.g., `URL`, `PDF`)
- Keep functions short and focused on a single responsibility
- Add `// MARK: -` comments to organize code sections within files

## Architecture

- Follow the **MVVM** (Model-View-ViewModel) pattern
- Keep Views free of business logic — delegate to ViewModels
- Use the Combine framework or `@Observable` / `ObservableObject` for reactive state management

## Building and Testing

```bash
# Build using Xcode command line tools
xcodebuild -scheme pdf-analyzer-app -destination 'platform=iOS Simulator,name=iPhone 15' build

# Run tests
xcodebuild -scheme pdf-analyzer-app -destination 'platform=iOS Simulator,name=iPhone 15' test
```

## Key Guidelines for Copilot

- **PDFKit usage**: Always use `PDFKit` for rendering and interacting with PDF documents. Avoid third-party PDF libraries unless there is a clear justification.
- **Permissions**: When accessing the file system or user documents, ensure proper usage of `UIDocumentPickerViewController` or `FileImporter` (SwiftUI).
- **Error handling**: Use Swift's `throws`/`try`/`catch` pattern for error-prone operations such as file loading and PDF parsing.
- **Testing**: Write unit tests for ViewModels and business logic. Use `XCTest` for all tests.
- **Accessibility**: Ensure new UI components include accessibility labels and support Dynamic Type.
- **Privacy**: Do not store or transmit PDF content externally without explicit user consent.
