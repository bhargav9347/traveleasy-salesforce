/**
 * @description Trigger on Reimbursement__c object
 * @author TravelEasy Solution Team
 */
trigger ReimbursementTrigger on Reimbursement__c (before insert) {
    if (Trigger.isBefore && Trigger.isInsert) {
        ReimbursementTriggerHandler.beforeInsert(Trigger.new);
    }
}
