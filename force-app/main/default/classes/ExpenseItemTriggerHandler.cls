/**
 * @description Trigger Handler for Expense_Item__c following One-Trigger-Per-Object pattern.
 * Triggers the Smart Expense Control Engine validation before save and exception generation after save.
 * @author TravelEasy Solution Team
 */
public with sharing class ExpenseItemTriggerHandler {

    public static void beforeInsert(List<Expense_Item__c> items) {
        SmartExpenseControlEngine.evaluateBeforeSave(items);
    }

    public static void beforeUpdate(Map<Id, Expense_Item__c> oldMap, Map<Id, Expense_Item__c> newMap) {
        SmartExpenseControlEngine.evaluateBeforeSave(newMap.values());
    }

    public static void afterInsert(List<Expense_Item__c> items) {
        SmartExpenseControlEngine.createExceptionsAfterSave(items);
    }

    public static void afterUpdate(Map<Id, Expense_Item__c> oldMap, Map<Id, Expense_Item__c> newMap) {
        SmartExpenseControlEngine.createExceptionsAfterSave(newMap.values());
    }
}
