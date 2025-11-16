
import Foundation

/// Represents a tag in a TaskPaper document.
///
/// Tags are metadata annotations in the format `@tagname` or `@tagname(value)`.
/// They can appear anywhere in a line and provide a way to categorize and filter items.
///
/// ## Examples
/// - `@done` - A simple tag without a value
/// - `@priority(high)` - A tag with a value
/// - `@due(2024-12-31)` - A tag with a date value
///
/// Tags are hashed and compared based on their name only, allowing efficient lookups
/// in sets and dictionaries.
public final class Tag {

	/// The name of the tag (without the @ prefix).
	///
	/// For example, in `@priority(high)`, the name is `"priority"`.
	public var name: String

	/// The optional value associated with the tag.
	///
	/// For tags like `@priority(high)`, the value is `"high"`.
	/// For tags like `@done`, the value is `nil`.
	public var value: String?

	/// The location of this tag in the original source text.
	///
	/// This range includes the @ symbol, name, and any value with parentheses.
	public var sourceRange: NSRange

	/// Creates a new tag with the specified name, optional value, and source range.
	///
	/// - Parameters:
	///   - name: The tag name (without the @ prefix)
	///   - value: The optional tag value (defaults to nil)
	///   - sourceRange: The location of this tag in the source text
	public init(name: String, value: String?=nil, sourceRange: NSRange) {
		self.name = name
		self.value = value
		self.sourceRange = sourceRange
	}

}

extension Tag: CustomStringConvertible {
	
	public var description: String {
		let valueString = value ?? "nil"
		return "\(type(of: self))(name: \(name), value: \(valueString), sourceRange: NSRange(location: \(sourceRange.location), length: \(sourceRange.length)))"
	}
	
}

extension Tag: Hashable {

	public func hash(into hasher: inout Hasher) {
		hasher.combine(name)
	}

	public static func ==(lhs: Tag, rhs: Tag) -> Bool {
		return lhs.name == rhs.name
	}

}
