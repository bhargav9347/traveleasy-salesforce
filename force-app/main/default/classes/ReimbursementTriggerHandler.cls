/**
 * @description Trigger Handler for Reimbursement__c object.
 * @author TravelEasy Solution Team
 */
public with sharing class ReimbursementTriggerHandler {

    public static void beforeInsert(List<Reimbursement__c> rmbs) {
        Id currentUserId = UserInfo.getUserId();
        for (Reimbursement__c rmb : rmbs) {
            if (rmb.Employee__c == null) {
                rmb.Employee__c = currentUserId;
            }
            if (rmb.Reimbursement_Status__c == null) {
                rmb.Reimbursement_Status__c = 'Pending';
            }
            if (rmb.Processing_Date__c == null) {
                rmb.Processing_Date__c = Date.today();
            }
        }
    }
}
