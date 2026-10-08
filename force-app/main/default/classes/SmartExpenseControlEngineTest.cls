@IsTest
private class SmartExpenseControlEngineTest {

    @TestSetup
    static void setupTestData() {
        Travel_Request__c tr = new Travel_Request__c();
        tr.Destination__c = 'Bangalore';
        tr.Purpose__c = 'Client Business Meeting';
        tr.Start_Date__c = Date.today();
        tr.End_Date__c = Date.today().addDays(3);
        tr.Estimated_Cost__c = 20000;
        tr.Status__c = 'Approved';
        tr.Approval_Status__c = 'Approved';
        insert tr;

        Expense_Report__c expReport = new Expense_Report__c();
        expReport.Travel_Request__c = tr.Id;
        expReport.Report_Date__c = Date.today();
        expReport.Status__c = 'Draft';
        insert expReport;
    }

    @IsTest
    static void testValidExpenseItemPassesValidation() {
        Expense_Report__c rep = [SELECT Id, Travel_Request__c FROM Expense_Report__c LIMIT 1];

        Test.startTest();
        Expense_Item__c item = new Expense_Item__c();
        item.Expense_Report__c = rep.Id;
        item.Travel_Request__c = rep.Travel_Request__c;
        item.Expense_Category__c = 'Taxi/Transportation';
        item.Amount__c = 500;
        item.Expense_Date__c = Date.today();
        item.Vendor__c = 'Uber';
        item.Receipt_Attached__c = true;
        insert item;
        Test.stopTest();

        Expense_Item__c insertedItem = [SELECT Id, Policy_Result__c, Validation_Status__c, Reimbursable_Amount__c FROM Expense_Item__c WHERE Id = :item.Id];
        System.assertEquals('PASS', insertedItem.Policy_Result__c, 'Valid taxi expense with receipt should PASS.');
        System.assertEquals('Validated', insertedItem.Validation_Status__c, 'Validation status should be Validated.');
        System.assertEquals(500, insertedItem.Reimbursable_Amount__c, 'Reimbursable amount should match expense amount.');
    }

    @IsTest
    static void testMissingReceiptFlagged() {
        Expense_Report__c rep = [SELECT Id, Travel_Request__c FROM Expense_Report__c LIMIT 1];

        Test.startTest();
        Expense_Item__c item = new Expense_Item__c();
        item.Expense_Report__c = rep.Id;
        item.Travel_Request__c = rep.Travel_Request__c;
        item.Expense_Category__c = 'Flight';
        item.Amount__c = 8000;
        item.Expense_Date__c = Date.today();
        item.Vendor__c = 'IndiGo';
        item.Receipt_Attached__c = false; // Missing receipt!
        insert item;
        Test.stopTest();

        Expense_Item__c insertedItem = [SELECT Id, Policy_Result__c, Validation_Status__c, Reimbursable_Amount__c FROM Expense_Item__c WHERE Id = :item.Id];
        System.assertEquals('MISSING_RECEIPT', insertedItem.Policy_Result__c, 'Flight without receipt should flag MISSING_RECEIPT.');
        System.assertEquals('Flagged', insertedItem.Validation_Status__c, 'Validation status should be Flagged.');
        System.assertEquals(0, insertedItem.Reimbursable_Amount__c, 'Reimbursable amount should be 0 on flagged items.');

        List<Expense_Exception__c> exceptions = [SELECT Id, Exception_Type__c FROM Expense_Exception__c WHERE Expense_Item__c = :item.Id];
        System.assertEquals(1, exceptions.size(), 'One Expense_Exception__c should be created.');
        System.assertEquals('Missing Receipt', exceptions[0].Exception_Type__c);
    }

    @IsTest
    static void testPolicyLimitExceededFlagged() {
        Expense_Report__c rep = [SELECT Id, Travel_Request__c FROM Expense_Report__c LIMIT 1];

        Test.startTest();
        Expense_Item__c item = new Expense_Item__c();
        item.Expense_Report__c = rep.Id;
        item.Travel_Request__c = rep.Travel_Request__c;
        item.Expense_Category__c = 'Meals';
        item.Amount__c = 50000; // Exceeds max meal limit of ₹2,500
        item.Expense_Date__c = Date.today();
        item.Vendor__c = 'Luxury Dining';
        item.Receipt_Attached__c = true;
        insert item;
        Test.stopTest();

        Expense_Item__c insertedItem = [SELECT Id, Policy_Result__c, Validation_Status__c FROM Expense_Item__c WHERE Id = :item.Id];
        System.assertEquals('POLICY_EXCEPTION', insertedItem.Policy_Result__c, 'Over limit meal expense should flag POLICY_EXCEPTION.');
        System.assertEquals('Flagged', insertedItem.Validation_Status__c);
    }

    @IsTest
    static void testDuplicateExpenseFlagged() {
        Expense_Report__c rep = [SELECT Id, Travel_Request__c FROM Expense_Report__c LIMIT 1];

        // Insert original expense
        Expense_Item__c item1 = new Expense_Item__c();
        item1.Expense_Report__c = rep.Id;
        item1.Travel_Request__c = rep.Travel_Request__c;
        item1.Expense_Category__c = 'Taxi/Transportation';
        item1.Amount__c = 450;
        item1.Expense_Date__c = Date.today();
        item1.Vendor__c = 'Ola Cabs';
        item1.Receipt_Attached__c = true;
        insert item1;

        Test.startTest();
        // Insert duplicate expense with same Category, Date, and Amount
        Expense_Item__c item2 = new Expense_Item__c();
        item2.Expense_Report__c = rep.Id;
        item2.Travel_Request__c = rep.Travel_Request__c;
        item2.Expense_Category__c = 'Taxi/Transportation';
        item2.Amount__c = 450;
        item2.Expense_Date__c = Date.today();
        item2.Vendor__c = 'Ola Cabs';
        item2.Receipt_Attached__c = true;
        insert item2;
        Test.stopTest();

        Expense_Item__c duplicateItem = [SELECT Id, Policy_Result__c, Validation_Status__c FROM Expense_Item__c WHERE Id = :item2.Id];
        System.assertEquals('POTENTIAL_DUPLICATE', duplicateItem.Policy_Result__c, 'Matching expense should flag POTENTIAL_DUPLICATE.');
    }
}
