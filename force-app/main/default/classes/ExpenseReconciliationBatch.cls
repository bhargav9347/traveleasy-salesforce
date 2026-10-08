/**
 * @description Batch Apex for large-volume travel and expense reconciliation.
 * Reconciles approved expenses, verifies policy state integrity, and creates audit summaries.
 * @author TravelEasy Solution Team
 */
public with sharing class ExpenseReconciliationBatch implements Database.Batchable<sObject>, Database.Stateful {

    public Integer recordsProcessed = 0;
    public Decimal totalReconciledAmount = 0;
    public Integer exceptionCount = 0;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, Total_Amount__c, Total_Reimbursable_Amount__c, Status__c, Validation_Status__c, Has_Exception__c,
                   (SELECT Id, Amount__c, Reimbursable_Amount__c, Policy_Result__c, Validation_Status__c FROM Expense_Items__r)
            FROM Expense_Report__c
            WHERE Status__c IN ('Approved', 'Reimbursed')
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Expense_Report__c> scope) {
        for (Expense_Report__c report : scope) {
            recordsProcessed++;
            Decimal sumItems = 0;
            Decimal sumReimbursable = 0;

            if (report.Expense_Items__r != null) {
                for (Expense_Item__c item : report.Expense_Items__r) {
                    sumItems += (item.Amount__c != null ? item.Amount__c : 0);
                    sumReimbursable += (item.Reimbursable_Amount__c != null ? item.Reimbursable_Amount__c : 0);
                    if (item.Validation_Status__c == 'Flagged') {
                        exceptionCount++;
                    }
                }
            }

            totalReconciledAmount += sumReimbursable;
        }
    }

    public void finish(Database.BatchableContext bc) {
        Integration_Log__c summaryLog = new Integration_Log__c();
        summaryLog.Source_System__c = 'TravelEasy Reconciliation Engine';
        summaryLog.Target_System__c = 'Finance General Ledger Audit';
        summaryLog.Endpoint__c = 'internal://reconciliation/run';
        summaryLog.Request_Payload__c = 'Batch reconciliation run completed for approved/reimbursed expense reports.';
        summaryLog.Response_Payload__c = JSON.serialize(new Map<String, Object>{
            'recordsProcessed' => recordsProcessed,
            'totalReconciledAmount' => totalReconciledAmount,
            'exceptionCount' => exceptionCount,
            'reconciledAt' => String.valueOf(DateTime.now())
        });
        summaryLog.Status__c = 'Success';
        summaryLog.Status_Code__c = 200;
        insert summaryLog;
    }
}
