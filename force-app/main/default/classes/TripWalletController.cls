/**
 * @description Lightning Web Component Controller for Trip Wallet LWC.
 * @author TravelEasy Solution Team
 */
public with sharing class TripWalletController {

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getTripSummary(Id recordId) {
        if (recordId == null) {
            return new Map<String, Object>();
        }

        Travel_Request__c tr = [
            SELECT Id, Name, Destination__c, Purpose__c, Start_Date__c, End_Date__c,
                   Estimated_Cost__c, Actual_Cost__c, Budget_Variance__c, Variance_Percentage__c,
                   Budget_Status__c, Status__c, Approval_Status__c, Duration_Days__c,
                   Employee__r.Name
            FROM Travel_Request__c
            WHERE Id = :recordId
            LIMIT 1
        ];

        List<Expense_Report__c> reports = [
            SELECT Id, Name, Total_Amount__c, Total_Reimbursable_Amount__c, Status__c,
                   Validation_Status__c, Approval_Status__c, Reimbursement_Status__c, Has_Exception__c
            FROM Expense_Report__c
            WHERE Travel_Request__c = :recordId
            ORDER BY CreatedDate DESC
        ];

        Decimal estimated = tr.Estimated_Cost__c != null ? tr.Estimated_Cost__c : 0;
        Decimal actual = tr.Actual_Cost__c != null ? tr.Actual_Cost__c : 0;
        Decimal remaining = estimated - actual;
        Decimal utilization = (estimated > 0) ? ((actual / estimated) * 100).setScale(1) : 0;

        Map<String, Object> summary = new Map<String, Object>();
        summary.put('travelRequest', tr);
        summary.put('expenseReports', reports);
        summary.put('estimatedCost', estimated);
        summary.put('actualCost', actual);
        summary.put('remainingBudget', remaining);
        summary.put('budgetUtilization', utilization);
        summary.put('isOverBudget', actual > estimated);

        return summary;
    }

    @AuraEnabled(cacheable=true)
    public static List<Expense_Item__c> getExpenseItems(Id travelRequestId) {
        if (travelRequestId == null) {
            return new List<Expense_Item__c>();
        }
        return [
            SELECT Id, Name, Expense_Category__c, Amount__c, Expense_Date__c, Vendor__c,
                   Description__c, Validation_Status__c, Exception_Status__c, Policy_Result__c,
                   Policy_Result_Details__c, Receipt_Attached__c, Reimbursable_Amount__c
            FROM Expense_Item__c
            WHERE Travel_Request__c = :travelRequestId
            ORDER BY Expense_Date__c DESC
        ];
    }

    @AuraEnabled
    public static Expense_Item__c createExpenseItem(Id expenseReportId, String category, Decimal amount, Date expenseDate, String vendor, String description, Boolean receiptAttached) {
        if (expenseReportId == null || String.isBlank(category) || amount == null || amount <= 0) {
            throw new AuraHandledException('Invalid parameter values provided for expense creation.');
        }

        Expense_Report__c rep = [
            SELECT Id, Travel_Request__c FROM Expense_Report__c WHERE Id = :expenseReportId LIMIT 1
        ];

        Expense_Item__c item = new Expense_Item__c();
        item.Expense_Report__c = expenseReportId;
        item.Travel_Request__c = rep.Travel_Request__c;
        item.Expense_Category__c = category;
        item.Amount__c = amount;
        item.Expense_Date__c = expenseDate != null ? expenseDate : Date.today();
        item.Vendor__c = vendor;
        item.Description__c = description;
        item.Receipt_Attached__c = receiptAttached != null ? receiptAttached : false;

        insert item;

        return [
            SELECT Id, Name, Expense_Category__c, Amount__c, Expense_Date__c, Vendor__c,
                   Validation_Status__c, Exception_Status__c, Policy_Result__c, Policy_Result_Details__c,
                   Receipt_Attached__c, Reimbursable_Amount__c
            FROM Expense_Item__c
            WHERE Id = :item.Id
        ];
    }
}
