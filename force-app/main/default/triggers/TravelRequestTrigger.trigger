/**
 * @description Trigger on Travel_Request__c object
 * @author TravelEasy Solution Team
 */
trigger TravelRequestTrigger on Travel_Request__c (before insert, before update) {
    if (Trigger.isBefore && Trigger.isInsert) {
        TravelRequestTriggerHandler.beforeInsert(Trigger.new);
    } else if (Trigger.isBefore && Trigger.isUpdate) {
        TravelRequestTriggerHandler.beforeUpdate(Trigger.oldMap, Trigger.newMap);
    }
}
