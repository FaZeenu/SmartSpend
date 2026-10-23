
import Testing
import Foundation

//  SmartSpend Unit Tests

struct SmartSpendTests {

    // Test 1: Total Income

    @Test
    func testTotalIncome() {

        // Sample income records.
        let incomes: [Double] = [
            10000,
            15000,
            5000
        ]

        // Calculate total income.
        let totalIncome = incomes.reduce(0, +)

        // Expected result: Rs. 30,000
        #expect(totalIncome == 30000)
    }

    // Test 2: Total Expenses

    @Test
    func testTotalExpenses() {

        // Sample expense records.
        let expenses: [Double] = [
            2000,
            3000,
            1000
        ]

        // Calculate total expenses.
        let totalExpenses = expenses.reduce(0, +)

        // Expected result: Rs. 6,000
        #expect(totalExpenses == 6000)
    }

    // Test 3: Remaining Balance

    @Test
    func testRemainingBalance() {

        let totalIncome = 50000.0
        let totalExpenses = 15000.0

        // Balance = Income - Expenses
        let remainingBalance =
            totalIncome - totalExpenses

        // Expected result: Rs. 35,000
        #expect(remainingBalance == 35000)
    }

    // Test 4: Budget Percentage

    @Test
    func testBudgetPercentage() {

        let spent = 8000.0
        let budgetLimit = 10000.0

        // Percentage = (Spent / Budget) * 100
        let percentage =
            (spent / budgetLimit) * 100

        // Expected result: 80%
        #expect(percentage == 80)
    }

    // Test 5: Budget Warning Threshold

    @Test
    func testBudgetWarning() {

        let spent = 8500.0
        let budgetLimit = 10000.0

        let percentage =
            (spent / budgetLimit) * 100

        // Warning should activate at 80%.
        let shouldShowWarning = percentage >= 80

        #expect(shouldShowWarning == true)
    }

    // Test 6: Budget Limit Reached

    @Test
    func testBudgetLimitReached() {

        let spent = 10500.0
        let budgetLimit = 10000.0

        let percentage =
            (spent / budgetLimit) * 100

        // Budget limit is reached at 100%.
        let isLimitReached = percentage >= 100

        #expect(isLimitReached == true)
    }

    // Test 7: Budget Below Warning Level

    @Test
    func testBudgetBelowWarning() {

        let spent = 5000.0
        let budgetLimit = 10000.0

        let percentage =
            (spent / budgetLimit) * 100

        // No warning should appear below 80%.
        let shouldShowWarning = percentage >= 80

        #expect(shouldShowWarning == false)
    }

    // Test 8: Zero Expenses

    @Test
    func testZeroExpenses() {

        let totalIncome = 20000.0
        let totalExpenses = 0.0

        let remainingBalance =
            totalIncome - totalExpenses

        // Balance should equal income.
        #expect(remainingBalance == 20000)
    }
}

