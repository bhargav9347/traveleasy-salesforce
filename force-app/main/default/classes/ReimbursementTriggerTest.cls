@IsTest
private class ReimbursementTriggerTest {

    @IsTest
    static void testReimbursementTriggerInsert() {
        Travel_Request__c tr = new Travel_Request__c();
        tr.Destination__c = 'Pune';
        tr.Purpose__c = 'Client Workshop';
        tr.Start_Date__c = Date.today();
        tr.End_Date__c = Date.today().addDays(1);
        tr.Estimated_Cost__c = 5000;
        insert tr;

        Expense_Report__c expReport = new Expense_Report__c();
        expReport.Travel_Request__c = tr.Id;
        expReport.Report_Date__c = Date.today();
        insert expReport;

        Test.startTest();
        Reimbursement__c rmb = new Reimbursement__c();
        rmb.Expense_Report__c = expReport.Id;
        rmb.Approved_Amount__c = 3500;
        insert rmb;
        Test.stopTest();

        Reimbursement__c insertedRmb = [SELECT Id, Reimbursement_Status__c, Processing_Date__c, Employee__c FROM Reimbursement__c WHERE Id = :rmb.Id];
        System.assertEquals('Pending', insertedRmb.Reimbursement_Status__c, 'Default status should be Pending.');
        System.assertNotEquals(null, insertedRmb.Employee__c, 'Employee should default to current user.');
    }
}
