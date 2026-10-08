/**
 * @description Batch and Schedulable Apex for monitoring pending approval SLAs and escalating overdue requests.
 * @author TravelEasy Solution Team
 */
public with sharing class ApprovalSLAEscalationBatch implements Database.Batchable<sObject>, Schedulable, Database.Stateful {

    public Integer escalatedCount = 0;

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new ApprovalSLAEscalationBatch(), 50);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        DateTime cutOffTime = DateTime.now().addHours(-24);
        return Database.getQueryLocator([
            SELECT Id, Name, Status__c, Approval_Status__c, CreatedDate, Approver__c
            FROM Travel_Request__c
            WHERE Approval_Status__c = 'Pending Approval'
            AND CreatedDate <= :cutOffTime
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Travel_Request__c> scope) {
        List<Integration_Log__c> slaLogs = new List<Integration_Log__c>();

        for (Travel_Request__c tr : scope) {
            escalatedCount++;
            Integration_Log__c log = new Integration_Log__c();
            log.Source_System__c = 'TravelEasy SLA Monitor';
            log.Target_System__c = 'Approval Escalation Engine';
            log.Endpoint__c = 'internal://sla/escalate';
            log.Request_Payload__c = 'Travel Request ' + tr.Name + ' (ID: ' + tr.Id + ') pending approval > 24 hours.';
            log.Response_Payload__c = 'Escalation alert triggered for Approver ID: ' + tr.Approver__c;
            log.Status__c = 'Warning';
            log.Status_Code__c = 300;
            log.Related_Record_Id__c = tr.Id;
            slaLogs.add(log);
        }

        if (!slaLogs.isEmpty()) {
            insert slaLogs;
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('ApprovalSLAEscalationBatch finished. Total escalated requests: ' + escalatedCount);
    }
}
