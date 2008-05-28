Story: Create Data
	Scenario: Create Test Data
		Given: A mix of items, groups, and places
		Then: There are 8 virtual items
		Then: There are 2 virtual items for part Part1
	Scenario: Update data
		GivenScenario: Create Test Data
		When: Change Part1 to Part1a
		Then: There are 2 virtual items for part Part1a
		And: There are 0 virtual items for part Part1
