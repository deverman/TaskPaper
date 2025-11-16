import XCTest
@testable import TaskPaper

class TaskPaperTests: XCTestCase {

	// MARK: - Basic Parsing Tests

	func testParseEmptyString() {
		let doc = TaskPaper("")
		XCTAssertEqual(doc.items.count, 0, "Empty string should produce no items")
	}

	func testParseSingleNote() {
		let doc = TaskPaper("This is a note\n")
		XCTAssertEqual(doc.items.count, 1)
		XCTAssertEqual(doc.items[0].type, .note)
		XCTAssertEqual(doc.items[0].children.count, 0)
	}

	func testParseSingleTask() {
		let doc = TaskPaper("- This is a task\n")
		XCTAssertEqual(doc.items.count, 1)
		XCTAssertEqual(doc.items[0].type, .task)
		XCTAssertEqual(doc.items[0].children.count, 0)
	}

	func testParseSingleProject() {
		let doc = TaskPaper("Project:\n")
		XCTAssertEqual(doc.items.count, 1)
		XCTAssertEqual(doc.items[0].type, .project)
		XCTAssertEqual(doc.items[0].children.count, 0)
	}

	func testParseMultipleRootItems() {
		let input = """
		First item
		- Second item
		Third item:
		"""
		let doc = TaskPaper(input)
		XCTAssertEqual(doc.items.count, 3)
		XCTAssertEqual(doc.items[0].type, .note)
		XCTAssertEqual(doc.items[1].type, .task)
		XCTAssertEqual(doc.items[2].type, .project)
	}

	// MARK: - Task Marker Tests

	func testTaskWithDashMarker() {
		let doc = TaskPaper("- Task with dash\n")
		XCTAssertEqual(doc.items[0].type, .task)
	}

	func testTaskWithAsteriskMarker() {
		let doc = TaskPaper("* Task with asterisk\n")
		XCTAssertEqual(doc.items[0].type, .task)
	}

	func testTaskWithPlusMarker() {
		let doc = TaskPaper("+ Task with plus\n")
		XCTAssertEqual(doc.items[0].type, .task)
	}

	func testTaskWithBackslashMarker() {
		let doc = TaskPaper("\\ Task with backslash\n")
		XCTAssertEqual(doc.items[0].type, .task)
	}

	// MARK: - Hierarchy Tests

	func testNestedItems() {
		let input = """
		Project:
			- Task one
			- Task two
		"""
		let doc = TaskPaper(input)
		XCTAssertEqual(doc.items.count, 1, "Should have 1 root item")
		XCTAssertEqual(doc.items[0].type, .project)
		XCTAssertEqual(doc.items[0].children.count, 2, "Project should have 2 children")
		XCTAssertEqual(doc.items[0].children[0].type, .task)
		XCTAssertEqual(doc.items[0].children[1].type, .task)
	}

	func testDeeplyNestedItems() {
		let input = """
		Level 1:
			Level 2:
				Level 3:
					- Level 4 task
		"""
		let doc = TaskPaper(input)
		XCTAssertEqual(doc.items.count, 1)

		let level1 = doc.items[0]
		XCTAssertEqual(level1.type, .project)
		XCTAssertEqual(level1.children.count, 1)

		let level2 = level1.children[0]
		XCTAssertEqual(level2.type, .project)
		XCTAssertEqual(level2.children.count, 1)

		let level3 = level2.children[0]
		XCTAssertEqual(level3.type, .project)
		XCTAssertEqual(level3.children.count, 1)

		let level4 = level3.children[0]
		XCTAssertEqual(level4.type, .task)
		XCTAssertEqual(level4.children.count, 0)
	}

	func testParentReferences() {
		let input = """
		Project:
			- Task
		"""
		let doc = TaskPaper(input)
		let project = doc.items[0]
		let task = project.children[0]

		XCTAssertNil(project.parent, "Root item should have no parent")
		XCTAssertNotNil(task.parent, "Child should have parent")
		XCTAssertTrue(task.parent === project, "Child's parent should be the project")
	}

	// MARK: - Tag Tests

	func testSimpleTag() {
		let doc = TaskPaper("- Task @done\n")
		let item = doc.items[0]
		XCTAssertEqual(item.tags.count, 1)

		let tag = item["done"]
		XCTAssertNotNil(tag)
		XCTAssertEqual(tag?.name, "done")
		XCTAssertNil(tag?.value)
	}

	func testTagWithValue() {
		let doc = TaskPaper("- Task @priority(high)\n")
		let item = doc.items[0]
		XCTAssertEqual(item.tags.count, 1)

		let tag = item["priority"]
		XCTAssertNotNil(tag)
		XCTAssertEqual(tag?.name, "priority")
		XCTAssertEqual(tag?.value, "high")
	}

	func testMultipleTags() {
		let doc = TaskPaper("- Task @done @priority(1) @today\n")
		let item = doc.items[0]
		XCTAssertEqual(item.tags.count, 3)

		XCTAssertNotNil(item["done"])
		XCTAssertNotNil(item["priority"])
		XCTAssertNotNil(item["today"])

		XCTAssertEqual(item["priority"]?.value, "1")
	}

	func testTagLookupNonExistent() {
		let doc = TaskPaper("- Task @done\n")
		let item = doc.items[0]
		XCTAssertNil(item["notfound"])
	}

	func testTagsOnProject() {
		let doc = TaskPaper("Project @archived:\n")
		let item = doc.items[0]
		XCTAssertEqual(item.type, .project)
		XCTAssertEqual(item.tags.count, 1)
		XCTAssertNotNil(item["archived"])
	}

	func testTagsOnNote() {
		let doc = TaskPaper("Note with @tag\n")
		let item = doc.items[0]
		XCTAssertEqual(item.type, .note)
		XCTAssertEqual(item.tags.count, 1)
		XCTAssertNotNil(item["tag"])
	}

	// MARK: - Tag Scanner Tests

	func testTagRegex() {
		let str = "@a(b) c @d @e" as NSString
		let results = scanForTags(in: str, range: NSMakeRange(0, str.length))

		XCTAssertEqual(results.count, 3, "Should find 3 tags")

		// First tag: @a(b)
		XCTAssertEqual(str.substring(with: results[0][1]), "a")
		XCTAssertEqual(str.substring(with: results[0][2]), "b")

		// Second tag: @d
		XCTAssertEqual(str.substring(with: results[1][1]), "d")

		// Third tag: @e
		XCTAssertEqual(str.substring(with: results[2][1]), "e")
	}

	// MARK: - Traversal Tests

	func testEnumerateFlat() {
		let input = """
		First
		Second
		Third
		"""
		let doc = TaskPaper(input)
		var count = 0
		for item in doc.items {
			item.enumerate { _ in
				count += 1
			}
		}
		XCTAssertEqual(count, 3, "Should enumerate all 3 items")
	}

	func testEnumerateNested() {
		let input = """
		Project:
			- Task 1
			- Task 2
				Note under task 2
		"""
		let doc = TaskPaper(input)
		var count = 0
		doc.items[0].enumerate { _ in
			count += 1
		}
		XCTAssertEqual(count, 4, "Should enumerate project + 2 tasks + 1 note = 4 items")
	}

	func testEnumerateOrder() {
		let input = """
		A:
			B
				C
			D
		"""
		let doc = TaskPaper(input)
		var visited: [String] = []

		// Extract first letter of content for tracking order
		doc.items[0].enumerate { item in
			let str = input as NSString
			let content = str.substring(with: item.contentRange).trimmingCharacters(in: .whitespaces)
			if let first = content.first {
				visited.append(String(first))
			}
		}

		XCTAssertEqual(visited, ["A", "B", "C", "D"], "Should visit in depth-first order")
	}

	// MARK: - Source Range Tests

	func testSourceRangeIncludingChildren() {
		let input = """
		Project:
			Child 1
			Child 2
		Next item
		"""
		let doc = TaskPaper(input)
		let project = doc.items[0]
		let range = project.sourceRangeIncludingChildren

		let str = input as NSString
		let extracted = str.substring(with: range)

		XCTAssertTrue(extracted.contains("Project:"))
		XCTAssertTrue(extracted.contains("Child 1"))
		XCTAssertTrue(extracted.contains("Child 2"))
		XCTAssertFalse(extracted.contains("Next item"))
	}

	// MARK: - Option Tests

	func testNormalizeOption() {
		// Test with Windows-style line endings
		let input = "Line 1\r\nLine 2\r\nLine 3"
		let doc = TaskPaper(input, options: .normalize)
		XCTAssertEqual(doc.items.count, 3, "Should parse 3 lines even with \\r\\n endings")
	}

	// MARK: - Complex Document Test

	func testComplexDocument() {
		let input = """
		Shopping List @today:
			Groceries:
				- Milk @priority(high)
				- Bread
				- Eggs @organic
			Hardware Store:
				- Screwdriver
				- Paint @color(blue)
		Work @context(office):
			- Finish report @due(2024-12-31)
			- Email client
				Follow up next week
		"""

		let doc = TaskPaper(input)

		// Verify structure
		XCTAssertEqual(doc.items.count, 2, "Should have 2 root items")

		// Shopping List checks
		let shopping = doc.items[0]
		XCTAssertEqual(shopping.type, .project)
		XCTAssertNotNil(shopping["today"])
		XCTAssertEqual(shopping.children.count, 2)

		let groceries = shopping.children[0]
		XCTAssertEqual(groceries.type, .project)
		XCTAssertEqual(groceries.children.count, 3)
		XCTAssertEqual(groceries.children[0].type, .task)
		XCTAssertNotNil(groceries.children[0]["priority"])

		// Work checks
		let work = doc.items[1]
		XCTAssertEqual(work.type, .project)
		XCTAssertNotNil(work["context"])
		XCTAssertEqual(work["context"]?.value, "office")

		// Count all items via enumeration
		var totalItems = 0
		for root in doc.items {
			root.enumerate { _ in totalItems += 1 }
		}
		XCTAssertEqual(totalItems, 13, "Should have 13 total items in the tree")
	}

	// MARK: - Edge Cases

	func testEmptyLines() {
		let input = """
		First


		Second
		"""
		let doc = TaskPaper(input)
		// Empty lines are still parsed as notes
		XCTAssertEqual(doc.items.count, 4)
	}

	func testProjectWithoutColon() {
		let doc = TaskPaper("Not a project\n")
		XCTAssertEqual(doc.items[0].type, .note, "Line without colon should be a note")
	}

	func testTaskWithoutSpace() {
		let doc = TaskPaper("-NoSpace\n")
		// Should be a note since there's no space after the dash
		XCTAssertEqual(doc.items[0].type, .note)
	}

	// MARK: - Performance Test

	func testBenchmark() {
		let str = "one:\n\t- two\n\t\t- three\n\t- four\n five\n\t- six\n seven:\n\t eight\n\t- nine\n- ten\n"
		var input = str

		for _ in 0..<10000 {
			input += str
		}

		measure {
			let _ = TaskPaper(input)
		}
	}

}
