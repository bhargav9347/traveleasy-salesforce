/**
 * @description Service class to orchestrate Reimbursement creation and asynchronous processing.
 * @author TravelEasy Solution Team
 */
public with sharing class ReimbursementService {

    /**
     * @description Creates Reimbursement records for approved Expense Reports and triggers Queueable processing.
     * @param reportIds List of approved Expense Report IDs.
     * @return List of created Reimbursement__c records.
     */
    public static List<Reimbursement__c> processApprovedExpenseReports(List<Id> reportIds) {
        if (reportIds == null || reportIds.isEmpty()) {
            return new List<Reimbursement__c>();
        }

        List<Expense_Report__c> approvedReports = [
            SELECT Id, Employee__c, Total_Reimbursable_Amount__c, Reimbursement_Status__c
            FROM Expense_Report__c
            WHERE Id IN :reportIds
            AND Status__c = 'Approved'
        ];

        if (approvedReports.isEmpty()) {
            return new List<Reimbursement__c>();
        }

        List<Reimbursement__c> reimbursementsToInsert = new List<Reimbursement__c>();
        List<Expense_Report__c> reportsToUpdate = new List<Expense_Report__c>();

        for (Expense_Report__c report : approvedReports) {
            Reimbursement__c rmb = new Reimbursement__c();
            rmb.Expense_Report__c = report.Id;
            rmb.Employee__c = report.Employee__c;
            rmb.Approved_Amount__c = report.Total_Reimbursable_Amount__c != null ? report.Total_Reimbursable_Amount__c : 0;
            rmb.Reimbursement_Status__c = 'Pending';
            rmb.Processing_Date__c = Date.today();
            rmb.Comments__c = 'Automated reimbursement initiated upon expense report approval.';
            reimbursementsToInsert.add(rmb);

            report.Reimbursement_Status__c = 'Pending Reimbursement';
            reportsToUpdate.add(report);
        }

        if (!reimbursementsToInsert.isEmpty()) {
            insert reimbursementsToInsert;
            update reportsToUpdate;

            // Collect created Reimbursement IDs and launch Queueable Async Job
            Set<Id> rmbIds = new Map<Id, Reimbursement__c>(reimbursementsToInsert).keySet();
            System.enqueueJob(new ReimbursementQueueable(rmbIds));
        }

        return reimbursementsToInsert;
    }
}
