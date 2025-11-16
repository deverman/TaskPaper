
import Foundation

/// Represents a single item in a TaskPaper document.
///
/// Items form a tree structure where each item can have child items.
/// Each item has a type (note, project, or task), content, and optional tags.
///
/// ## Item Types
/// - **Task**: Lines starting with `- `, `* `, `+ `, or `\ `
/// - **Project**: Lines ending with `:`
/// - **Note**: All other lines
///
/// ## Example
/// ```
/// Project One:
///     - Task with @tag
///         Note with details
///     - Another task @done
/// ```
public final class Item {

	/// The type of this item.
	public enum ItemType {
		/// A plain text note (no special syntax)
		case note
		/// A project heading (ends with `:`)
		case project
		/// A task item (starts with `- `, `* `, `+ `, or `\ `)
		case task
	}

	/// The parent item in the tree structure, or nil if this is a root item.
	///
	/// This is a weak reference to prevent retain cycles in the tree.
	public weak var parent: Item?

	/// The child items nested under this item.
	///
	/// Children are ordered as they appear in the source document.
	public var children: [Item] = []

	/// The type of this item (note, project, or task).
	public var type: ItemType

	/// The range of the complete line in the original source text.
	///
	/// This includes indentation, content, tags, and the newline character.
	public var sourceRange: NSRange

	/// The range of the item's content, excluding leading syntax and trailing tags.
	///
	/// For a task `- Buy milk @today`, this range would cover `"Buy milk "`.
	public var contentRange: NSRange

	/// The set of tags attached to this item.
	///
	/// Use the subscript operator to look up tags by name: `item["priority"]`
	public var tags: Set<Tag> = []

	/// Creates a new item with the specified type and source ranges.
	///
	/// - Parameters:
	///   - type: The type of item (note, project, or task)
	///   - sourceRange: The range of the complete line in the source text
	///   - contentRange: The range of the content, excluding syntax and tags
	public init(type: ItemType, sourceRange: NSRange, contentRange: NSRange) {
		self.type = type
		self.sourceRange = sourceRange
		self.contentRange = contentRange
	}

}

extension Item {

	func addChild(_ child: Item) {
		child.parent = self

		children.append(child)
	}

	/// Recursively traverses this item and all its descendants in depth-first order.
	///
	/// The handler is called for this item first, then recursively for each child.
	///
	/// - Parameter handler: A closure called for each item in the tree
	///
	/// ## Example
	/// ```swift
	/// item.enumerate { descendant in
	///     print(descendant.type)
	/// }
	/// ```
	public func enumerate(_ handler: (Item)->Void) {
		handler(self)

		for child in children {
			child.enumerate(handler)
		}
	}

}

extension Item {

	/// The source range spanning this item and all its descendants.
	///
	/// This range starts at this item's location and extends to the end of the
	/// last descendant item in the tree.
	///
	/// - Returns: An NSRange covering this item and all children
	public var sourceRangeIncludingChildren: NSRange {
		var length = sourceRange.length

		if let lastChildRange = children.last?.sourceRangeIncludingChildren {
			length = NSMaxRange(lastChildRange) - sourceRange.location
		}

		return NSMakeRange(sourceRange.location, length)
	}

}

extension Item {

	/// Looks up a tag by name.
	///
	/// - Parameter tagName: The name of the tag to find (without the @ prefix)
	/// - Returns: The tag if found, or nil if this item has no tag with that name
	///
	/// ## Example
	/// ```swift
	/// if let priority = item["priority"] {
	///     print("Priority: \(priority.value ?? "none")")
	/// }
	/// ```
	public subscript(_ tagName: String) -> Tag? {
		return tags.first { $0.name == tagName }
	}

	func addTags(_ newTags: [Tag]) {
		tags.formUnion(newTags)
	}

}
