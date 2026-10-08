/**
 * @description Trigger Handler for Travel_Request__c following One-Trigger-Per-Object pattern.
 * @author TravelEasy Solution Team
 */
public with sharing class TravelRequestTriggerHandler {

    public static void beforeInsert(List<Travel_Request__c> newRequests) {
        Id currentUserId = UserInfo.getUserId();
        for (Travel_Request__c tr : newRequests) {
            if (tr.Employee__c == null) {
                tr.Employee__c = currentUserId;
            }
            if (tr.Status__c == null) {
                tr.Status__c = 'Draft';
            }
            if (tr.Approval_Status__c == null) {
                tr.Approval_Status__c = 'Not Submitted';
            }
        }
    }

    public static void beforeUpdate(Map<Id, Travel_Request__c> oldMap, Map<Id, Travel_Request__c> newMap) {
        for (Travel_Request__c tr : newMap.values()) {
            Travel_Request__c oldTr = oldMap.get(tr.Id);

            // Sync Status with Approval Status
            if (tr.Approval_Status__c == 'Approved' && oldTr.Approval_Status__c != 'Approved') {
                tr.Status__c = 'Approved';
            } else if (tr.Approval_Status__c == 'Rejected' && oldTr.Approval_Status__c != 'Rejected') {
                tr.Status__c = 'Rejected';
            } else if (tr.Approval_Status__c == 'Pending Approval' && oldTr.Approval_Status__c != 'Pending Approval') {
                tr.Status__c = 'Submitted';
            }
        }
    }
}
