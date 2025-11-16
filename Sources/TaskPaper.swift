
import Foundation

/// A parser for TaskPaper formatted plain text documents.
///
/// TaskPaper is a simple, plain text format for creating outlines and to-do lists.
/// Documents consist of items organized in a hierarchical structure using indentation (tabs).
///
/// ## Parsing
/// Create a TaskPaper instance by passing a string to parse:
///
/// ```swift
/// let document = TaskPaper("""
///     Shopping:
///         - Buy milk @today
///         - Get bread
///     Work:
///         - Finish report @due(2024-12-31)
///     """)
/// ```
///
/// ## Item Structure
/// The parser creates a tree of `Item` objects accessible via the `items` property.
/// Each item can have:
/// - A type (task, project, or note)
/// - Child items (nested items)
/// - Tags for metadata
/// - Source ranges for AST applications
///
/// ## Traversing Items
/// ```swift
/// for item in document.items {
///     item.enumerate { descendant in
///         print(descendant.type)
///     }
/// }
/// ```
public struct TaskPaper {

	/// Options for parsing TaskPaper documents.
	public struct Options: OptionSet {
		public let rawValue: Int

		public init(rawValue: Int) {
			self.rawValue = rawValue
		}

		/// Normalize line endings to Unix style (\\n) before parsing.
		///
		/// This converts Windows (\\r\\n) and classic Mac (\\r) line endings to Unix (\\n).
		public static let normalize = Options(rawValue: 1 << 0)
	}

	/// The root-level items in the parsed document.
	///
	/// Items that are not indented appear at this level. Items that are indented
	/// are children of other items and can be accessed via the `children` property.
	public var items: [Item] = []

	/// Parses a TaskPaper formatted string into a structured document.
	///
	/// The parser processes the input line-by-line, building a tree structure based on indentation.
	/// Each line becomes an `Item` with an appropriate type (task, project, or note).
	///
	/// - Parameters:
	///   - string: The TaskPaper formatted text to parse
	///   - options: Parsing options (defaults to empty, no special processing)
	///
	/// ## Example
	/// ```swift
	/// let doc = TaskPaper("""
	///     Project:
	///         - Task @done
	///         Note text
	///     """)
	/// print(doc.items.count) // 1 (the project)
	/// print(doc.items[0].children.count) // 2 (task and note)
	/// ```
	public init(_ string: String, options: Options=[]) {
		var input = string

		if options.contains(.normalize) {
			input = (string as NSString).replacingOccurrences(of: "(\r\n|\n|\r)", with: "\n", options: .regularExpression, range: NSMakeRange(0, (string as NSString).length))
		}

		parse(input as NSString)
	}

}

extension TaskPaper {
	
	mutating func parse(_ input: NSString) {
		
		for (lineRange, line) in input.lines {
			let indentRange = scanForIndent(in: input, range: lineRange)[0]
			var bodyRange = NSMakeRange(NSMaxRange(indentRange), lineRange.length - indentRange.length)
			
			// trim newlines
			let newlineRange = input.rangeOfCharacter(from: CharacterSet.newlines, options: .backwards, range: lineRange)
			if newlineRange.location != NSNotFound, NSMaxRange(newlineRange) == NSMaxRange(lineRange) {
				bodyRange.length -= newlineRange.length
			}
			
			// parse tags first, since bodyRange excludes trailing tags
			let tags = tagsForLine(input: input, lineRange: lineRange)
			
			// remove trailing tags from bodyRange
			if let trailingRange = trailingRangeForLine(input: input, bodyRange: bodyRange, tags: tags) {
				bodyRange.length -= trailingRange.length
			}
			
			// parse item and add attributes
			let item = itemForLine(input: input, line: line, lineRange: lineRange, indentRange: indentRange, bodyRange: bodyRange)
			item.addTags(tags)
			
			attachItem(item, itemLevel: indentRange.length)
		}
		
	}
	
	func tagsForLine(input: NSString, lineRange: NSRange) -> [Tag] {
		var tags: [Tag] = []
		
		for result in scanForTags(in: input, range: lineRange) {
			let name = input.substring(with: result[1])
			var value: String? = nil
			if result[2].location != NSNotFound {
				value = input.substring(with: result[2])
			}
			
			let tag = Tag(name: name, value: value, sourceRange: result.range)
			
			tags.append(tag)
		}
		
		return tags
	}
	
	func trailingRangeForLine(input: NSString, bodyRange: NSRange, tags: [Tag]) -> NSRange? {
		guard let lastTag = tags.last else {
			return nil
		}
		
		guard NSMaxRange(lastTag.sourceRange) == NSMaxRange(bodyRange) else {
			return nil
		}
		
		var trailRange = lastTag.sourceRange
		for tag in tags.reversed() {
			if NSMaxRange(tag.sourceRange) == trailRange.location {
				trailRange.location = tag.sourceRange.location
				trailRange.length += tag.sourceRange.length
			} else {
				break
			}
		}
		
		return trailRange
	}
	
	func itemForLine(input: NSString, line: NSString, lineRange: NSRange, indentRange: NSRange, bodyRange: NSRange) -> Item {
		if let taskRange = scanForTask(in: input, range: bodyRange)?[0] {
			let contentRange = NSMakeRange(NSMaxRange(taskRange), NSMaxRange(bodyRange) - NSMaxRange(taskRange))
			
			return Item(type: .task, sourceRange: lineRange, contentRange: contentRange)
		}
		
		if let _ = scanForProject(in: input, range: bodyRange)?[0] {
			let contentRange = NSMakeRange(NSMaxRange(indentRange), NSMaxRange(bodyRange) - 1 - NSMaxRange(indentRange))
			
			return Item(type: .project, sourceRange: lineRange, contentRange: contentRange)
		}
		
		let contentRange = NSMakeRange(NSMaxRange(indentRange), NSMaxRange(bodyRange) - NSMaxRange(indentRange))
		
		return Item(type: .note, sourceRange: lineRange, contentRange: contentRange)
	}
	
	mutating func attachItem(_ item: Item, itemLevel: Int) {
		var container: Item? = nil
		var containerLevel = 0
		
		// find container
		if let lastItem = items.last {
			
			if containerLevel < itemLevel {
				container = lastItem
				containerLevel += 1
			}
			
			while let lastChild = container?.children.last {
				if containerLevel < itemLevel {
					container = lastChild
					containerLevel += 1
				} else {
					break
				}
			}
			
		}
		
		// attach
		if let container = container {
			container.addChild(item)
		} else {
			items.append(item)
		}
	}
	
}
