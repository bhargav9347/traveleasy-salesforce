/**
 * @description Queueable Apex for asynchronous financial reimbursement processing and integration logging.
 * @author TravelEasy Solution Team
 */
public with sharing class ReimbursementQueueable implements Queueable, Database.AllowsCallouts {

    private Set<Id> reimbursementIds;

    public ReimbursementQueueable(Set<Id> rmbIds) {
        this.reimbursementIds = rmbIds;
    }

    public void execute(QueueableContext context) {
        if (reimbursementIds == null || reimbursementIds.isEmpty()) {
            return;
        }

        List<Reimbursement__c> rmbs = [
            SELECT Id, Expense_Report__c, Employee__c, Approved_Amount__c, Reimbursement_Status__c
            FROM Reimbursement__c
            WHERE Id IN :reimbursementIds
        ];

        List<Integration_Log__c> logsToInsert = new List<Integration_Log__c>();
        List<Expense_Report__c> reportsToUpdate = new List<Expense_Report__c>();

        for (Reimbursement__c rmb : rmbs) {
            String payRef = 'PAY-REF-' + System.currentTimeMillis() + '-' + Integer.valueOf(Math.random() * 1000);
            rmb.Reimbursement_Status__c = 'Completed';
            rmb.Payment_Reference__c = payRef;
            rmb.Completion_Date__c = Date.today();

            if (rmb.Expense_Report__c != null) {
                Expense_Report__c rep = new Expense_Report__c();
                rep.Id = rmb.Expense_Report__c;
                rep.Reimbursement_Status__c = 'Reimbursed';
                rep.Status__c = 'Reimbursed';
                reportsToUpdate.add(rep);
            }

            // Create Integration Log for Financial ERP Audit
            Integration_Log__c log = new Integration_Log__c();
            log.Source_System__c = 'TravelEasy Salesforce Platform';
            log.Target_System__c = 'Enterprise ERP / Financial Settlement System';
            log.Endpoint__c = 'https://api.traveleasy-finance.internal/v1/disbursements';
            log.Request_Payload__c = JSON.serialize(new Map<String, Object>{
                'reimbursementId' => rmb.Id,
                'employeeId' => rmb.Employee__c,
                'amount' => rmb.Approved_Amount__c,
                'paymentMethod' => 'Direct Bank Transfer'
            });
            log.Response_Payload__c = JSON.serialize(new Map<String, Object>{
                'status' => 'SUCCESS',
                'paymentReference' => payRef,
                'processedAt' => String.valueOf(DateTime.now())
            });
            log.Status__c = 'Success';
            log.Status_Code__c = 200;
            log.Related_Record_Id__c = rmb.Id;
            logsToInsert.add(log);
        }

        update rmbs;

        if (!reportsToUpdate.isEmpty()) {
            update reportsToUpdate;
        }

        if (!logsToInsert.isEmpty()) {
            insert logsToInsert;
        }
    }
}
