@IsTest
private class ExpenseReconciliationBatchTest {

    @IsTest
    static void testReconciliationBatchExecution() {
        Travel_Request__c tr = new Travel_Request__c();
        tr.Destination__c = 'Hyderabad';
        tr.Purpose__c = 'Tech Workshop';
        tr.Start_Date__c = Date.today();
        tr.End_Date__c = Date.today().addDays(2);
        tr.Estimated_Cost__c = 10000;
        tr.Status__c = 'Approved';
        tr.Approval_Status__c = 'Approved';
        insert tr;

        Expense_Report__c expReport = new Expense_Report__c();
        expReport.Travel_Request__c = tr.Id;
        expReport.Report_Date__c = Date.today();
        expReport.Status__c = 'Approved';
        expReport.Approval_Status__c = 'Approved';
        insert expReport;

        Expense_Item__c item = new Expense_Item__c();
        item.Expense_Report__c = expReport.Id;
        item.Travel_Request__c = tr.Id;
        item.Expense_Category__c = 'Hotel';
        item.Amount__c = 4000;
        item.Expense_Date__c = Date.today();
        item.Vendor__c = 'Marriott';
        item.Receipt_Attached__c = true;
        insert item;

        Test.startTest();
        Database.executeBatch(new ExpenseReconciliationBatch());
        Test.stopTest();

        List<Integration_Log__c> logs = [SELECT Id, Source_System__c, Status__c FROM Integration_Log__c WHERE Source_System__c = 'TravelEasy Reconciliation Engine'];
        System.assertEquals(1, logs.size(), 'Reconciliation summary log should be generated.');
        System.assertEquals('Success', logs[0].Status__c);
    }
}
