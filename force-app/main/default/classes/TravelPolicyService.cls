/**
 * @description Service class for retrieving and evaluating Travel Policy Configurations from Custom Metadata.
 * @author TravelEasy Solution Team
 */
public with sharing class TravelPolicyService {

    private static Map<String, Travel_Policy_Config__mdt> policyMapCache;

    /**
     * @description Retrieves active Travel Policy Configurations indexed by Expense Category.
     * @return Map of Category string to Travel_Policy_Config__mdt record.
     */
    public static Map<String, Travel_Policy_Config__mdt> getActivePolicies() {
        if (policyMapCache != null) {
            return policyMapCache;
        }

        policyMapCache = new Map<String, Travel_Policy_Config__mdt>();
        for (Travel_Policy_Config__mdt config : [
            SELECT DeveloperName, MasterLabel, Category__c, Max_Amount_Limit__c,
                   Receipt_Required__c, Receipt_Required_Above_Amount__c,
                   Employee_Grade__c, Requires_Management_Approval__c,
                   Is_Active__c, Approval_Threshold__c
            FROM Travel_Policy_Config__mdt
            WHERE Is_Active__c = true
        ]) {
            if (String.isNotBlank(config.Category__c)) {
                policyMapCache.put(config.Category__c, config);
            }
        }
        return policyMapCache;
    }

    /**
     * @description Evaluates an individual Expense Item against applicable Custom Metadata Policy.
     * @param category Expense Category
     * @param amount Expense Amount
     * @param hasReceipt Whether receipt is attached
     * @return PolicyEvaluationResult wrapper containing pass/fail, result code, and reason details.
     */
    public static PolicyEvaluationResult evaluateExpense(String category, Decimal amount, Boolean hasReceipt) {
        PolicyEvaluationResult result = new PolicyEvaluationResult();
        result.isPass = true;
        result.policyResultCode = 'PASS';
        result.details = 'Expense meets all standard policy criteria.';

        Map<String, Travel_Policy_Config__mdt> policies = getActivePolicies();
        if (!policies.containsKey(category)) {
            return result; // Default pass if no specific policy restriction
        }

        Travel_Policy_Config__mdt policy = policies.get(category);

        // Check Max Amount Limit
        if (policy.Max_Amount_Limit__c != null && amount > policy.Max_Amount_Limit__c) {
            result.isPass = false;
            result.policyResultCode = 'POLICY_EXCEPTION';
            result.details = 'Amount ₹' + amount + ' exceeds maximum policy limit of ₹' + policy.Max_Amount_Limit__c + ' for category ' + category + '.';
            return result;
        }

        // Check Missing Receipt requirement
        Boolean receiptRequired = policy.Receipt_Required__c;
        if (policy.Receipt_Required_Above_Amount__c != null && amount < policy.Receipt_Required_Above_Amount__c) {
            receiptRequired = false;
        }

        if (receiptRequired && (hasReceipt == null || !hasReceipt)) {
            result.isPass = false;
            result.policyResultCode = 'MISSING_RECEIPT';
            result.details = 'Receipt is required for ' + category + ' expenses exceeding ₹' + (policy.Receipt_Required_Above_Amount__c != null ? policy.Receipt_Required_Above_Amount__c : 0) + '.';
            return result;
        }

        return result;
    }

    public class PolicyEvaluationResult {
        public Boolean isPass { get; set; }
        public String policyResultCode { get; set; }
        public String details { get; set; }
    }
}
