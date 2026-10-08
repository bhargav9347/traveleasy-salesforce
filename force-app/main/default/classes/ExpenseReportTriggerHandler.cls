/**
 * @description Trigger Handler for Expense_Report__c following One-Trigger-Per-Object pattern.
 * @author TravelEasy Solution Team
 */
public with sharing class ExpenseReportTriggerHandler {

    public static void beforeInsert(List<Expense_Report__c> reports) {
        Id currentUserId = UserInfo.getUserId();
        for (Expense_Report__c rep : reports) {
            if (rep.Employee__c == null) {
                rep.Employee__c = currentUserId;
            }
            if (rep.Status__c == null) {
                rep.Status__c = 'Draft';
            }
            if (rep.Validation_Status__c == null) {
                rep.Validation_Status__c = 'Pending';
            }
            if (rep.Approval_Status__c == null) {
                rep.Approval_Status__c = 'Not Submitted';
            }
            if (rep.Reimbursement_Status__c == null) {
                rep.Reimbursement_Status__c = 'Not Applicable';
            }
        }
    }

    public static void beforeUpdate(Map<Id, Expense_Report__c> oldMap, Map<Id, Expense_Report__c> newMap) {
        for (Expense_Report__c rep : newMap.values()) {
            Expense_Report__c oldRep = oldMap.get(rep.Id);
            if (rep.Approval_Status__c == 'Approved' && oldRep.Approval_Status__c != 'Approved') {
                rep.Status__c = 'Approved';
            } else if (rep.Approval_Status__c == 'Rejected' && oldRep.Approval_Status__c != 'Rejected') {
                rep.Status__c = 'Rejected';
            } else if (rep.Approval_Status__c == 'Pending Approval' && oldRep.Approval_Status__c != 'Pending Approval') {
                rep.Status__c = 'Submitted';
            }
        }
    }

    public static void afterUpdate(Map<Id, Expense_Report__c> oldMap, Map<Id, Expense_Report__c> newMap) {
        List<Id> newlyApprovedReportIds = new List<Id>();
        for (Expense_Report__c rep : newMap.values()) {
            Expense_Report__c oldRep = oldMap.get(rep.Id);
            if ((rep.Status__c == 'Approved' || rep.Approval_Status__c == 'Approved') &&
                (oldRep.Status__c != 'Approved' && oldRep.Approval_Status__c != 'Approved') &&
                rep.Reimbursement_Status__c != 'Reimbursed') {
                newlyApprovedReportIds.add(rep.Id);
            }
        }

        if (!newlyApprovedReportIds.isEmpty()) {
            ReimbursementService.processApprovedExpenseReports(newlyApprovedReportIds);
        }
    }
}
