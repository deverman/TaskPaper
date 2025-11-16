import Foundation
import Testing
@testable import TaskPaper

@Suite("TaskPaper Parser Tests")
struct TaskPaperTests {

	// MARK: - Basic Parsing Tests

	@Test("Parse empty string")
	func parseEmptyString() {
		let doc = TaskPaper("")
		#expect(doc.items.count == 0)
	}

	@Test("Parse single note")
	func parseSingleNote() {
		let doc = TaskPaper("This is a note\n")
		#expect(doc.items.count == 1)
		#expect(doc.items[0].type == .note)
		#expect(doc.items[0].children.count == 0)
	}

	@Test("Parse single task")
	func parseSingleTask() {
		let doc = TaskPaper("- This is a task\n")
		#expect(doc.items.count == 1)
		#expect(doc.items[0].type == .task)
		#expect(doc.items[0].children.count == 0)
	}

	@Test("Parse single project")
	func parseSingleProject() {
		let doc = TaskPaper("Project:\n")
		#expect(doc.items.count == 1)
		#expect(doc.items[0].type == .project)
		#expect(doc.items[0].children.count == 0)
	}

	@Test("Parse multiple root items")
	func parseMultipleRootItems() {
		let input = """
		First item
		- Second item
		Third item:
		"""
		let doc = TaskPaper(input)
		#expect(doc.items.count == 3)
		#expect(doc.items[0].type == .note)
		#expect(doc.items[1].type == .task)
		#expect(doc.items[2].type == .project)
	}

	// MARK: - Task Marker Tests

	@Test("Task with dash marker")
	func taskWithDashMarker() {
		let doc = TaskPaper("- Task with dash\n")
		#expect(doc.items[0].type == .task)
	}

	@Test("Task with asterisk marker")
	func taskWithAsteriskMarker() {
		let doc = TaskPaper("* Task with asterisk\n")
		#expect(doc.items[0].type == .task)
	}

	@Test("Task with plus marker")
	func taskWithPlusMarker() {
		let doc = TaskPaper("+ Task with plus\n")
		#expect(doc.items[0].type == .task)
	}

	@Test("Task with backslash marker")
	func taskWithBackslashMarker() {
		let doc = TaskPaper("\\ Task with backslash\n")
		#expect(doc.items[0].type == .task)
	}

	// MARK: - Hierarchy Tests

	@Test("Nested items")
	func nestedItems() {
		let input = """
		Project:
			- Task one
			- Task two
		"""
		let doc = TaskPaper(input)
		#expect(doc.items.count == 1)
		#expect(doc.items[0].type == .project)
		#expect(doc.items[0].children.count == 2)
		#expect(doc.items[0].children[0].type == .task)
		#expect(doc.items[0].children[1].type == .task)
	}

	@Test("Deeply nested items")
	func deeplyNestedItems() {
		let input = """
		Level 1:
			Level 2:
				Level 3:
					- Level 4 task
		"""
		let doc = TaskPaper(input)
		#expect(doc.items.count == 1)

		let level1 = doc.items[0]
		#expect(level1.type == .project)
		#expect(level1.children.count == 1)

		let level2 = level1.children[0]
		#expect(level2.type == .project)
		#expect(level2.children.count == 1)

		let level3 = level2.children[0]
		#expect(level3.type == .project)
		#expect(level3.children.count == 1)

		let level4 = level3.children[0]
		#expect(level4.type == .task)
		#expect(level4.children.count == 0)
	}

	@Test("Parent references")
	func parentReferences() {
		let input = """
		Project:
			- Task
		"""
		let doc = TaskPaper(input)
		let project = doc.items[0]
		let task = project.children[0]

		#expect(project.parent == nil)
		#expect(task.parent != nil)
		#expect(task.parent === project)
	}

	// MARK: - Tag Tests

	@Test("Simple tag")
	func simpleTag() {
		let doc = TaskPaper("- Task @done\n")
		let item = doc.items[0]
		#expect(item.tags.count == 1)

		let tag = item["done"]
		#expect(tag != nil)
		#expect(tag?.name == "done")
		#expect(tag?.value == nil)
	}

	@Test("Tag with value")
	func tagWithValue() {
		let doc = TaskPaper("- Task @priority(high)\n")
		let item = doc.items[0]
		#expect(item.tags.count == 1)

		let tag = item["priority"]
		#expect(tag != nil)
		#expect(tag?.name == "priority")
		#expect(tag?.value == "high")
	}

	@Test("Multiple tags")
	func multipleTags() {
		let doc = TaskPaper("- Task @done @priority(1) @today\n")
		let item = doc.items[0]
		#expect(item.tags.count == 3)

		#expect(item["done"] != nil)
		#expect(item["priority"] != nil)
		#expect(item["today"] != nil)

		#expect(item["priority"]?.value == "1")
	}

	@Test("Tag lookup non-existent")
	func tagLookupNonExistent() {
		let doc = TaskPaper("- Task @done\n")
		let item = doc.items[0]
		#expect(item["notfound"] == nil)
	}

	@Test("Tags on project")
	func tagsOnProject() {
		let doc = TaskPaper("Project @archived:\n")
		let item = doc.items[0]
		#expect(item.type == .project)
		#expect(item.tags.count == 1)
		#expect(item["archived"] != nil)
	}

	@Test("Tags on note")
	func tagsOnNote() {
		let doc = TaskPaper("Note with @tag\n")
		let item = doc.items[0]
		#expect(item.type == .note)
		#expect(item.tags.count == 1)
		#expect(item["tag"] != nil)
	}

	// MARK: - OmniFocus Compatibility Tests

	@Test("OmniFocus defer tag")
	func omniFocusDeferTag() {
		let doc = TaskPaper("- Task @defer(2024-12-25)\n")
		let item = doc.items[0]
		#expect(item["defer"]?.value == "2024-12-25")
	}

	@Test("OmniFocus due tag")
	func omniFocusDueTag() {
		let doc = TaskPaper("- Task @due(2024-12-31)\n")
		let item = doc.items[0]
		#expect(item["due"]?.value == "2024-12-31")
	}

	@Test("OmniFocus flagged tag")
	func omniFocusFlaggedTag() {
		let doc = TaskPaper("- Task @flagged\n")
		let item = doc.items[0]
		#expect(item["flagged"] != nil)
		#expect(item["flagged"]?.value == nil)
	}

	@Test("OmniFocus estimate tag")
	func omniFocusEstimateTag() {
		let doc = TaskPaper("- Task @estimate(2h)\n")
		let item = doc.items[0]
		#expect(item["estimate"]?.value == "2h")
	}

	@Test("OmniFocus parallel tag")
	func omniFocusParallelTag() {
		let doc = TaskPaper("Project @parallel(true):\n")
		let item = doc.items[0]
		#expect(item["parallel"]?.value == "true")
	}

	@Test("OmniFocus tags parameter")
	func omniFocusTagsParameter() {
		let doc = TaskPaper("- Task @tags(work, urgent)\n")
		let item = doc.items[0]
		#expect(item["tags"]?.value == "work, urgent")
	}

	// MARK: - Tag Scanner Tests

	@Test("Tag scanner")
	func tagScanner() {
		let str = "@a(b) c @d @e" as NSString
		let results = scanForTags(in: str, range: NSMakeRange(0, str.length))

		#expect(results.count == 3)

		// First tag: @a(b)
		#expect(str.substring(with: results[0][1]) == "a")
		#expect(str.substring(with: results[0][2]) == "b")

		// Second tag: @d
		#expect(str.substring(with: results[1][1]) == "d")

		// Third tag: @e
		#expect(str.substring(with: results[2][1]) == "e")
	}

	// MARK: - Traversal Tests

	@Test("Enumerate flat structure")
	func enumerateFlat() {
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
		#expect(count == 3)
	}

	@Test("Enumerate nested structure")
	func enumerateNested() {
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
		#expect(count == 4)
	}

	@Test("Enumerate order is depth-first")
	func enumerateOrder() {
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

		#expect(visited == ["A", "B", "C", "D"])
	}

	// MARK: - Source Range Tests

	@Test("Source range including children")
	func sourceRangeIncludingChildren() {
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

		#expect(extracted.contains("Project:"))
		#expect(extracted.contains("Child 1"))
		#expect(extracted.contains("Child 2"))
		#expect(!extracted.contains("Next item"))
	}

	// MARK: - Option Tests

	@Test("Normalize option handles Windows line endings")
	func normalizeOption() {
		// Test with Windows-style line endings
		let input = "Line 1\r\nLine 2\r\nLine 3"
		let doc = TaskPaper(input, options: .normalize)
		#expect(doc.items.count == 3)
	}

	// MARK: - Complex Document Test

	@Test("Complex document parsing")
	func complexDocument() {
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
		#expect(doc.items.count == 2)

		// Shopping List checks
		let shopping = doc.items[0]
		#expect(shopping.type == .project)
		#expect(shopping["today"] != nil)
		#expect(shopping.children.count == 2)

		let groceries = shopping.children[0]
		#expect(groceries.type == .project)
		#expect(groceries.children.count == 3)
		#expect(groceries.children[0].type == .task)
		#expect(groceries.children[0]["priority"] != nil)

		// Work checks
		let work = doc.items[1]
		#expect(work.type == .project)
		#expect(work["context"] != nil)
		#expect(work["context"]?.value == "office")

		// Count all items via enumeration
		var totalItems = 0
		for root in doc.items {
			root.enumerate { _ in totalItems += 1 }
		}
		#expect(totalItems == 12)
	}

	// MARK: - Edge Cases

	@Test("Empty lines are parsed as notes")
	func emptyLines() {
		let input = """
		First


		Second
		"""
		let doc = TaskPaper(input)
		// Empty lines are still parsed as notes
		#expect(doc.items.count == 4)
	}

	@Test("Project without colon is a note")
	func projectWithoutColon() {
		let doc = TaskPaper("Not a project\n")
		#expect(doc.items[0].type == .note)
	}

	@Test("Task without space after marker is a note")
	func taskWithoutSpace() {
		let doc = TaskPaper("-NoSpace\n")
		// Should be a note since there's no space after the dash
		#expect(doc.items[0].type == .note)
	}

	// MARK: - Performance Test

	@Test("Benchmark parsing performance", .timeLimit(.minutes(1)))
	func benchmark() {
		let str = "one:\n\t- two\n\t\t- three\n\t- four\n five\n\t- six\n seven:\n\t eight\n\t- nine\n- ten\n"
		var input = str

		for _ in 0..<10000 {
			input += str
		}

		// Parse the large document
		let _ = TaskPaper(input)

		// Performance is measured by the time limit trait
	}

}
