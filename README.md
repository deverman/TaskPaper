# TaskPaper

A modern Swift library for parsing TaskPaper formatted plain text documents. This library provides a clean, type-safe API for working with TaskPaper outlines, tasks, and tags.

## Features

- **Swift 6.2.1** fully compatible with complete concurrency safety
- **Cross-platform**: Works on macOS, iOS, tvOS, watchOS, and Linux
- **Fast parsing** based on the [birch-outline](https://github.com/jessegrosjean/birch-outline) algorithm
- **Tree structure** with parent-child relationships
- **Tag support** with optional values
- **AST capabilities** with precise source ranges
- **Comprehensive test coverage**
- **Full API documentation**

## Requirements

- Swift 6.0 or later (tested with Swift 6.2.1)
- macOS 13.0+ / iOS 16.0+ / tvOS 16.0+ / watchOS 9.0+ (when using Apple platforms)
- Linux (Ubuntu 20.04+)

## Installation

### Swift Package Manager

Add TaskPaper as a dependency in your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/deverman/TaskPaper.git", from: "1.0.0")
]
```

Then add it to your target dependencies:

```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["TaskPaper"])
]
```

### Xcode

1. In Xcode, select **File → Add Package Dependencies...**
2. Enter the repository URL: `https://github.com/deverman/TaskPaper.git`
3. Select the version you want to use
4. Add the package to your target

## Usage

### Basic Parsing

```swift
import TaskPaper

let document = TaskPaper("""
    Shopping List:
        - Buy milk @today
        - Get bread
        - Eggs @organic
    """)

for item in document.items {
    print(item.type) // .project, .task, or .note
}
```

### Understanding Item Types

TaskPaper recognizes three types of items:

- **Tasks**: Lines starting with `- `, `* `, `+ `, or `\ `
- **Projects**: Lines ending with `:`
- **Notes**: All other lines

```swift
let doc = TaskPaper("""
    Project Name:
        - This is a task
        This is a note
    """)

print(doc.items[0].type) // .project
print(doc.items[0].children[0].type) // .task
print(doc.items[0].children[1].type) // .note
```

### Working with Tags

Tags are metadata annotations in the format `@tagname` or `@tagname(value)`:

```swift
let doc = TaskPaper("""
    - Finish report @due(2024-12-31) @priority(high) @done
    """)

let task = doc.items[0]

if let dueTag = task["due"] {
    print(dueTag.name)  // "due"
    print(dueTag.value) // "2024-12-31"
}

if let _ = task["done"] {
    print("Task is complete!")
}

print(task.tags.count) // 3
```

### Traversing the Tree

Each `Item` can have child items, forming a hierarchical tree structure:

```swift
let doc = TaskPaper("""
    Project:
        - Task 1
            Note under task 1
        - Task 2
    """)

let project = doc.items[0]
print(project.children.count) // 2

// Recursive traversal
project.enumerate { item in
    print(item.type)
}
// Output: .project, .task, .note, .task
```

### Parent-Child Relationships

```swift
let doc = TaskPaper("""
    Parent:
        Child item
    """)

let parent = doc.items[0]
let child = parent.children[0]

print(child.parent === parent) // true
print(parent.parent == nil)    // true (root items have no parent)
```

### Working with Source Ranges

Each item tracks its location in the original text, useful for syntax highlighting, AST manipulation, or text editors:

```swift
let text = """
    Project:
        - Task
    """
let doc = TaskPaper(text)
let item = doc.items[0]

print(item.sourceRange) // Full line range including newline
print(item.contentRange) // Just "Project" (excluding ":" and whitespace)

// Get range including all descendants
let fullRange = item.sourceRangeIncludingChildren
let str = text as NSString
let extracted = str.substring(with: fullRange)
print(extracted) // "Project:\n    - Task\n"
```

### Parsing Options

```swift
// Normalize line endings (converts \r\n and \r to \n)
let doc = TaskPaper(windowsText, options: .normalize)
```

## TaskPaper Format

The TaskPaper format is a simple, human-readable plain text format:

```
Project Name:
    - Task item
        Note item (indented under task)
    - Another task @tag @tag(value)

Another Project:
    Regular note
    - Task with multiple @tags @priority(high) @due(tomorrow)
```

### Indentation

- Use **tabs** (not spaces) for indentation
- Items are nested based on their indentation level
- Children must be indented one level more than their parent

### Tags

- Tags start with `@` followed by an alphanumeric name
- Tags can have optional values in parentheses: `@tagname(value)`
- Multiple tags can appear on the same line
- Tags typically appear at the end of a line but can appear anywhere

## Examples

### Todo List Manager

```swift
let todos = TaskPaper("""
    Today @date(2024-11-16):
        - Review pull requests @priority(high) @done
        - Write documentation @priority(medium)
        - Team meeting @time(14:00)

    This Week:
        - Plan sprint
        - Update roadmap
    """)

// Find all incomplete tasks
for item in todos.items {
    item.enumerate { task in
        if task.type == .task && task["done"] == nil {
            let text = extractContent(from: task)
            print("TODO: \(text)")
        }
    }
}
```

### Project Analyzer

```swift
func analyzeProject(_ doc: TaskPaper) {
    var taskCount = 0
    var completedCount = 0
    var highPriority = 0

    for item in doc.items {
        item.enumerate { item in
            if item.type == .task {
                taskCount += 1
                if item["done"] != nil {
                    completedCount += 1
                }
                if item["priority"]?.value == "high" {
                    highPriority += 1
                }
            }
        }
    }

    print("Tasks: \(taskCount)")
    print("Completed: \(completedCount)")
    print("High Priority: \(highPriority)")
}
```

## API Documentation

### `TaskPaper`

The main parser struct.

- `init(_ string: String, options: Options = [])` - Parse a TaskPaper document
- `var items: [Item]` - Root-level items

### `Item`

Represents a single item in the document.

- `var type: ItemType` - The type (.note, .project, or .task)
- `var parent: Item?` - Parent item (nil for root items)
- `var children: [Item]` - Child items
- `var tags: Set<Tag>` - Tags attached to this item
- `var sourceRange: NSRange` - Full line range in source text
- `var contentRange: NSRange` - Content range (excluding syntax and tags)
- `func enumerate(_ handler: (Item) -> Void)` - Recursively traverse descendants
- `subscript(_ tagName: String) -> Tag?` - Look up a tag by name
- `var sourceRangeIncludingChildren: NSRange` - Range spanning item and all descendants

### `Tag`

Represents a tag annotation.

- `var name: String` - Tag name (without @ prefix)
- `var value: String?` - Optional tag value
- `var sourceRange: NSRange` - Location in source text

## Contributing

Contributions are welcome! Please feel free to submit pull requests, report bugs, or suggest new features.

## License

This project is a fork of [dmcarth/TaskPaper](https://github.com/dmcarth/TaskPaper), modernized for Swift 6.0+.

## Credits

Based on the parsing algorithm from [birch-outline](https://github.com/jessegrosjean/birch-outline) by Jesse Grosjean.
