@IsTest
private class TripWalletControllerTest {

    @IsTest
    static void testTripWalletControllerMethods() {
        Travel_Request__c tr = new Travel_Request__c();
        tr.Destination__c = 'Kolkata';
        tr.Purpose__c = 'Client Pitch';
        tr.Start_Date__c = Date.today();
        tr.End_Date__c = Date.today().addDays(4);
        tr.Estimated_Cost__c = 30000;
        tr.Status__c = 'Approved';
        tr.Approval_Status__c = 'Approved';
        insert tr;

        Expense_Report__c expReport = new Expense_Report__c();
        expReport.Travel_Request__c = tr.Id;
        expReport.Report_Date__c = Date.today();
        expReport.Status__c = 'Draft';
        insert expReport;

        Test.startTest();
        Map<String, Object> summary = TripWalletController.getTripSummary(tr.Id);
        List<Expense_Item__c> itemsBefore = TripWalletController.getExpenseItems(tr.Id);

        Expense_Item__c newItem = TripWalletController.createExpenseItem(
            expReport.Id, 'Flight', 12000, Date.today(), 'Air India', 'Kolkata Flight', true
        );
        List<Expense_Item__c> itemsAfter = TripWalletController.getExpenseItems(tr.Id);
        Test.stopTest();

        System.assertNotEquals(null, summary.get('travelRequest'), 'Trip summary should contain travel request.');
        System.assertEquals(0, itemsBefore.size());
        System.assertEquals(1, itemsAfter.size());
        System.assertEquals(newItem.Id, itemsAfter[0].Id);
    }
}
