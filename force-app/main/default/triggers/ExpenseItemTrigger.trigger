/**
 * @description Trigger on Expense_Item__c object
 * @author TravelEasy Solution Team
 */
trigger ExpenseItemTrigger on Expense_Item__c (before insert, before update, after insert, after update) {
    if (Trigger.isBefore && Trigger.isInsert) {
        ExpenseItemTriggerHandler.beforeInsert(Trigger.new);
    } else if (Trigger.isBefore && Trigger.isUpdate) {
        ExpenseItemTriggerHandler.beforeUpdate(Trigger.oldMap, Trigger.newMap);
    } else if (Trigger.isAfter && Trigger.isInsert) {
        ExpenseItemTriggerHandler.afterInsert(Trigger.new);
    } else if (Trigger.isAfter && Trigger.isUpdate) {
        ExpenseItemTriggerHandler.afterUpdate(Trigger.oldMap, Trigger.newMap);
    }
}
