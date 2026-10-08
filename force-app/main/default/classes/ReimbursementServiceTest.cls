@IsTest
private class ReimbursementServiceTest {

    @IsTest
    static void testReimbursementFlowOnApproval() {
        Travel_Request__c tr = new Travel_Request__c();
        tr.Destination__c = 'Mumbai';
        tr.Purpose__c = 'Quarterly Business Review';
        tr.Start_Date__c = Date.today();
        tr.End_Date__c = Date.today().addDays(2);
        tr.Estimated_Cost__c = 15000;
        tr.Status__c = 'Approved';
        tr.Approval_Status__c = 'Approved';
        insert tr;

        Expense_Report__c expReport = new Expense_Report__c();
        expReport.Travel_Request__c = tr.Id;
        expReport.Report_Date__c = Date.today();
        expReport.Status__c = 'Draft';
        insert expReport;

        Expense_Item__c item = new Expense_Item__c();
        item.Expense_Report__c = expReport.Id;
        item.Travel_Request__c = tr.Id;
        item.Expense_Category__c = 'Taxi/Transportation';
        item.Amount__c = 1200;
        item.Expense_Date__c = Date.today();
        item.Vendor__c = 'Uber';
        item.Receipt_Attached__c = true;
        insert item;

        Test.startTest();
        // Approve Expense Report
        expReport.Approval_Status__c = 'Approved';
        update expReport;
        Test.stopTest();

        List<Reimbursement__c> rmbs = [SELECT Id, Approved_Amount__c, Reimbursement_Status__c, Payment_Reference__c FROM Reimbursement__c WHERE Expense_Report__c = :expReport.Id];
        System.assertEquals(1, rmbs.size(), 'Reimbursement record should be generated upon Expense Report approval.');
        System.assertEquals('Completed', rmbs[0].Reimbursement_Status__c, 'Reimbursement status should be Completed after Queueable executes in Test.stopTest().');
        System.assertNotEquals(null, rmbs[0].Payment_Reference__c, 'Payment reference should be generated.');

        List<Integration_Log__c> logs = [SELECT Id, Status__c FROM Integration_Log__c WHERE Related_Record_Id__c = :rmbs[0].Id];
        System.assertEquals(1, logs.size(), 'Integration Log audit record should be created.');
        System.assertEquals('Success', logs[0].Status__c);
    }
}
