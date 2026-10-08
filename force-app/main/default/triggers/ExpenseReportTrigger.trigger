/**
 * @description Trigger on Expense_Report__c object
 * @author TravelEasy Solution Team
 */
trigger ExpenseReportTrigger on Expense_Report__c (before insert, before update, after update) {
    if (Trigger.isBefore && Trigger.isInsert) {
        ExpenseReportTriggerHandler.beforeInsert(Trigger.new);
    } else if (Trigger.isBefore && Trigger.isUpdate) {
        ExpenseReportTriggerHandler.beforeUpdate(Trigger.oldMap, Trigger.newMap);
    } else if (Trigger.isAfter && Trigger.isUpdate) {
        ExpenseReportTriggerHandler.afterUpdate(Trigger.oldMap, Trigger.newMap);
    }
}
