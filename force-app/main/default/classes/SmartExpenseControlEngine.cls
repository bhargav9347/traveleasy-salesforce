/**
 * @description Smart Expense Control Engine - Explainable deterministic validation engine for TravelEasy.
 * Evaluates expense line items against policy limits, missing receipts, duplicate claims, and budget overruns.
 * Automatically generates auditable Expense_Exception__c records for human review.
 * @author TravelEasy Solution Team
 */
public with sharing class SmartExpenseControlEngine {

    /**
     * @description Evaluates Expense Items before save (in before insert / before update context).
     * Modifies fields on Trigger.new records directly.
     */
    public static void evaluateBeforeSave(List<Expense_Item__c> items) {
        if (items == null || items.isEmpty()) {
            return;
        }

        Set<Id> itemIds = new Set<Id>();
        Set<Id> reportIds = new Set<Id>();
        Set<String> categories = new Set<String>();
        Set<Date> expenseDates = new Set<Date>();
        Set<Decimal> amounts = new Set<Decimal>();

        for (Expense_Item__c item : items) {
            if (item.Id != null) {
                itemIds.add(item.Id);
            }
            if (item.Expense_Report__c != null) {
                reportIds.add(item.Expense_Report__c);
            }
            if (String.isNotBlank(item.Expense_Category__c)) {
                categories.add(item.Expense_Category__c);
            }
            if (item.Expense_Date__c != null) {
                expenseDates.add(item.Expense_Date__c);
            }
            if (item.Amount__c != null) {
                amounts.add(item.Amount__c);
            }
        }

        // Fetch parent Expense Reports for context
        Map<Id, Expense_Report__c> reportMap = new Map<Id, Expense_Report__c>();
        if (!reportIds.isEmpty()) {
            reportMap = new Map<Id, Expense_Report__c>([
                SELECT Id, Travel_Request__c, Travel_Request__r.Estimated_Cost__c, Travel_Request__r.Actual_Cost__c, Employee__c
                FROM Expense_Report__c
                WHERE Id IN :reportIds
            ]);
        }

        // Duplicate Detection Query
        Map<String, Expense_Item__c> existingItemsMap = new Map<String, Expense_Item__c>();
        if (!categories.isEmpty() && !expenseDates.isEmpty() && !amounts.isEmpty()) {
            for (Expense_Item__c existing : [
                SELECT Id, Expense_Report__c, Expense_Report__r.Employee__c, Expense_Category__c, Expense_Date__c, Amount__c
                FROM Expense_Item__c
                WHERE Expense_Category__c IN :categories
                AND Expense_Date__c IN :expenseDates
                AND Amount__c IN :amounts
                AND Id NOT IN :itemIds
            ]) {
                String key = existing.Expense_Report__r.Employee__c + '_' + existing.Expense_Category__c + '_' + String.valueOf(existing.Expense_Date__c) + '_' + existing.Amount__c;
                existingItemsMap.put(key, existing);
            }
        }

        for (Expense_Item__c item : items) {
            Expense_Report__c parentReport = reportMap.get(item.Expense_Report__c);
            Id employeeId = (parentReport != null) ? parentReport.Employee__c : UserInfo.getUserId();
            Id travelReqId = (item.Travel_Request__c != null) ? item.Travel_Request__c : (parentReport != null ? parentReport.Travel_Request__c : null);

            if (item.Travel_Request__c == null && travelReqId != null) {
                item.Travel_Request__c = travelReqId;
            }

            Boolean isExceptionDetected = false;
            String policyCode = 'PASS';
            String policyDetails = 'Expense passed automated policy control checks.';

            // 1. Policy Limit & Receipt Check
            TravelPolicyService.PolicyEvaluationResult policyRes = TravelPolicyService.evaluateExpense(
                item.Expense_Category__c, item.Amount__c, item.Receipt_Attached__c
            );

            if (!policyRes.isPass) {
                isExceptionDetected = true;
                policyCode = policyRes.policyResultCode;
                policyDetails = policyRes.details;
            }

            // 2. Duplicate Check
            if (!isExceptionDetected && employeeId != null && item.Expense_Date__c != null && item.Amount__c != null) {
                String dupKey = employeeId + '_' + item.Expense_Category__c + '_' + String.valueOf(item.Expense_Date__c) + '_' + item.Amount__c;
                if (existingItemsMap.containsKey(dupKey)) {
                    isExceptionDetected = true;
                    policyCode = 'POTENTIAL_DUPLICATE';
                    policyDetails = 'Potential duplicate detected: Matching expense item exists for date ' + item.Expense_Date__c + ' and amount ₹' + item.Amount__c + '.';
                }
            }

            // 3. Budget Overrun Check
            if (!isExceptionDetected && parentReport != null && parentReport.Travel_Request__r != null) {
                Decimal estimatedCost = parentReport.Travel_Request__r.Estimated_Cost__c;
                Decimal currentActualCost = parentReport.Travel_Request__r.Actual_Cost__c != null ? parentReport.Travel_Request__r.Actual_Cost__c : 0;
                if (estimatedCost != null && (currentActualCost + item.Amount__c) > estimatedCost) {
                    isExceptionDetected = true;
                    policyCode = 'BUDGET_OVERRUN';
                    policyDetails = 'Adding this expense of ₹' + item.Amount__c + ' causes total travel cost (₹' + (currentActualCost + item.Amount__c) + ') to exceed approved estimated budget of ₹' + estimatedCost + '.';
                }
            }

            item.Policy_Result__c = policyCode;
            item.Policy_Result_Details__c = policyDetails;

            if (isExceptionDetected) {
                item.Validation_Status__c = 'Flagged';
                item.Exception_Status__c = 'Pending Review';
                item.Reimbursable_Amount__c = 0;
            } else {
                item.Validation_Status__c = 'Validated';
                item.Exception_Status__c = 'None';
                item.Reimbursable_Amount__c = item.Amount__c;
            }
        }
    }

    /**
     * @description Creates Expense_Exception__c records and updates parent Expense Reports in after save context.
     */
    public static void createExceptionsAfterSave(List<Expense_Item__c> items) {
        if (items == null || items.isEmpty()) {
            return;
        }

        List<Expense_Exception__c> exceptionsToInsert = new List<Expense_Exception__c>();
        Set<Id> reportIds = new Set<Id>();
        Set<Id> reportsWithExceptions = new Set<Id>();

        for (Expense_Item__c item : items) {
            if (item.Expense_Report__c != null) {
                reportIds.add(item.Expense_Report__c);
            }

            if (item.Validation_Status__c == 'Flagged') {
                reportsWithExceptions.add(item.Expense_Report__c);

                String exceptionType = 'Policy Exception';
                String severity = 'Medium';

                if (item.Policy_Result__c == 'MISSING_RECEIPT') {
                    exceptionType = 'Missing Receipt';
                } else if (item.Policy_Result__c == 'POTENTIAL_DUPLICATE') {
                    exceptionType = 'Potential Duplicate';
                    severity = 'High';
                } else if (item.Policy_Result__c == 'BUDGET_OVERRUN') {
                    exceptionType = 'Budget Overrun';
                }

                Expense_Exception__c exc = new Expense_Exception__c();
                exc.Expense_Item__c = item.Id;
                exc.Expense_Report__c = item.Expense_Report__c;
                exc.Travel_Request__c = item.Travel_Request__c;
                exc.Exception_Type__c = exceptionType;
                exc.Severity__c = severity;
                exc.Status__c = 'Open';
                exc.Explanation_Notes__c = item.Policy_Result_Details__c;
                exceptionsToInsert.add(exc);
            }
        }

        if (!exceptionsToInsert.isEmpty()) {
            insert exceptionsToInsert;
        }

        if (!reportIds.isEmpty()) {
            List<Expense_Report__c> reportsToUpdate = [
                SELECT Id, Validation_Status__c, Has_Exception__c
                FROM Expense_Report__c
                WHERE Id IN :reportIds
            ];
            for (Expense_Report__c rep : reportsToUpdate) {
                if (reportsWithExceptions.contains(rep.Id)) {
                    rep.Has_Exception__c = true;
                    rep.Validation_Status__c = 'Policy Exception';
                } else {
                    rep.Validation_Status__c = 'Passed';
                }
            }
            update reportsToUpdate;
        }
    }
}
