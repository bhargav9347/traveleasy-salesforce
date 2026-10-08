@IsTest
private class TravelPolicyServiceTest {

    @IsTest
    static void testGetActivePolicies() {
        Test.startTest();
        Map<String, Travel_Policy_Config__mdt> policies = TravelPolicyService.getActivePolicies();
        Test.stopTest();

        System.assertNotEquals(null, policies, 'Policies map should not be null.');
    }

    @IsTest
    static void testEvaluateExpensePass() {
        Test.startTest();
        TravelPolicyService.PolicyEvaluationResult res = TravelPolicyService.evaluateExpense('Flight', 5000, true);
        Test.stopTest();

        System.assertEquals(true, res.isPass, 'Valid flight expense should pass.');
        System.assertEquals('PASS', res.policyResultCode, 'Result code should be PASS.');
    }

    @IsTest
    static void testEvaluateExpenseLimitExceeded() {
        Test.startTest();
        TravelPolicyService.PolicyEvaluationResult res = TravelPolicyService.evaluateExpense('Flight', 999999, true);
        Test.stopTest();

        System.assertEquals(false, res.isPass, 'Over-limit expense should fail policy evaluation.');
        System.assertEquals('POLICY_EXCEPTION', res.policyResultCode, 'Result code should be POLICY_EXCEPTION.');
    }

    @IsTest
    static void testEvaluateExpenseMissingReceipt() {
        Test.startTest();
        TravelPolicyService.PolicyEvaluationResult res = TravelPolicyService.evaluateExpense('Flight', 5000, false);
        Test.stopTest();

        System.assertEquals(false, res.isPass, 'Expense missing required receipt should fail.');
        System.assertEquals('MISSING_RECEIPT', res.policyResultCode, 'Result code should be MISSING_RECEIPT.');
    }
}
