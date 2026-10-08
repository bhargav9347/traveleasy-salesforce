@IsTest
private class TravelEasyE2ETest {

    @IsTest
    static void testEndToEndNormalAndExceptionScenarios() {
        // ==========================================
        // SCENARIO 1: NORMAL SUCCESSFUL JOURNEY
        // ==========================================
        Travel_Request__c tr1 = new Travel_Request__c();
        tr1.Destination__c = 'Chennai to Bangalore';
        tr1.Purpose__c = 'Hackathon Presentation & Client Summit';
        tr1.Start_Date__c = Date.today();
        tr1.End_Date__c = Date.today().addDays(3);
        tr1.Estimated_Cost__c = 20000;
        tr1.Travel_Type__c = 'Domestic';
        tr1.Department__c = 'Engineering';
        insert tr1;

        // Submit Travel Request for Approval
        tr1.Approval_Status__c = 'Pending Approval';
        update tr1;
        System.assertEquals('Submitted', [SELECT Status__c FROM Travel_Request__c WHERE Id = :tr1.Id].Status__c);

        // Manager Approves Travel Request
        tr1.Approval_Status__c = 'Approved';
        update tr1;
        System.assertEquals('Approved', [SELECT Status__c FROM Travel_Request__c WHERE Id = :tr1.Id].Status__c);

        // Employee Creates Expense Report
        Expense_Report__c expReport1 = new Expense_Report__c();
        expReport1.Travel_Request__c = tr1.Id;
        expReport1.Report_Date__c = Date.today();
        expReport1.Comments__c = 'Normal business travel expenses';
        insert expReport1;

        // Employee Adds Valid Expense Items
        Expense_Item__c flightItem = new Expense_Item__c();
        flightItem.Expense_Report__c = expReport1.Id;
        flightItem.Travel_Request__c = tr1.Id;
        flightItem.Expense_Category__c = 'Flight';
        flightItem.Amount__c = 8500;
        flightItem.Expense_Date__c = Date.today();
        flightItem.Vendor__c = 'IndiGo Airlines';
        flightItem.Paid_By__c = 'Employee Personal';
        flightItem.Receipt_Attached__c = true;
        insert flightItem;

        Expense_Item__c hotelItem = new Expense_Item__c();
        hotelItem.Expense_Report__c = expReport1.Id;
        hotelItem.Travel_Request__c = tr1.Id;
        hotelItem.Expense_Category__c = 'Hotel';
        hotelItem.Amount__c = 6500;
        hotelItem.Expense_Date__c = Date.today();
        hotelItem.Vendor__c = 'Taj Hotels';
        hotelItem.Paid_By__c = 'Employee Personal';
        hotelItem.Receipt_Attached__c = true;
        insert hotelItem;

        // Verify Smart Control Validation Results
        Expense_Item__c validatedFlight = [SELECT Policy_Result__c, Validation_Status__c, Reimbursable_Amount__c FROM Expense_Item__c WHERE Id = :flightItem.Id];
        System.assertEquals('PASS', validatedFlight.Policy_Result__c);
        System.assertEquals('Validated', validatedFlight.Validation_Status__c);
        System.assertEquals(8500, validatedFlight.Reimbursable_Amount__c);

        // Expense Report Approval
        Test.startTest();
        expReport1.Approval_Status__c = 'Approved';
        update expReport1;
        Test.stopTest(); // Executes ReimbursementQueueable

        // Verify Reimbursement Disbursement
        Reimbursement__c rmb1 = [SELECT Reimbursement_Status__c, Payment_Reference__c, Approved_Amount__c FROM Reimbursement__c WHERE Expense_Report__c = :expReport1.Id LIMIT 1];
        System.assertEquals('Completed', rmb1.Reimbursement_Status__c);
        System.assertEquals(15000, rmb1.Approved_Amount__c);
        System.assertNotEquals(null, rmb1.Payment_Reference__c);

        // ==========================================
        // SCENARIO 2: POLICY EXCEPTION JOURNEY
        // ==========================================
        Travel_Request__c tr2 = new Travel_Request__c();
        tr2.Destination__c = 'Mumbai';
        tr2.Purpose__c = 'Executive Conference';
        tr2.Start_Date__c = Date.today();
        tr2.End_Date__c = Date.today().addDays(2);
        tr2.Estimated_Cost__c = 15000;
        insert tr2;

        Expense_Report__c expReport2 = new Expense_Report__c();
        expReport2.Travel_Request__c = tr2.Id;
        expReport2.Report_Date__c = Date.today();
        insert expReport2;

        // Expense item missing receipt
        Expense_Item__c missingReceiptItem = new Expense_Item__c();
        missingReceiptItem.Expense_Report__c = expReport2.Id;
        missingReceiptItem.Travel_Request__c = tr2.Id;
        missingReceiptItem.Expense_Category__c = 'Hotel';
        missingReceiptItem.Amount__c = 7000;
        missingReceiptItem.Expense_Date__c = Date.today();
        missingReceiptItem.Vendor__c = 'Grand Hyatt';
        missingReceiptItem.Receipt_Attached__c = false; // Trigger MISSING_RECEIPT
        insert missingReceiptItem;

        Expense_Item__c flaggedItem = [SELECT Policy_Result__c, Validation_Status__c, Reimbursable_Amount__c FROM Expense_Item__c WHERE Id = :missingReceiptItem.Id];
        System.assertEquals('MISSING_RECEIPT', flaggedItem.Policy_Result__c);
        System.assertEquals('Flagged', flaggedItem.Validation_Status__c);
        System.assertEquals(0, flaggedItem.Reimbursable_Amount__c);

        List<Expense_Exception__c> exceptions = [SELECT Id, Status__c, Exception_Type__c FROM Expense_Exception__c WHERE Expense_Item__c = :missingReceiptItem.Id];
        System.assertEquals(1, exceptions.size());
        System.assertEquals('Open', exceptions[0].Status__c);

        // Manager/Finance Resolves Exception
        Expense_Exception__c exc = exceptions[0];
        exc.Status__c = 'Resolved - Approved';
        exc.Resolution_Notes__c = 'Receipt verified offline via direct hotel voucher.';
        update exc;

        System.assertEquals('Resolved - Approved', [SELECT Status__c FROM Expense_Exception__c WHERE Id = :exc.Id].Status__c);
    }
}
