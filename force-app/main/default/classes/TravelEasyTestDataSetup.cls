/**
 * @description Test Data Generator utility to populate realistic demo data in Salesforce Playground.
 * @author TravelEasy Solution Team
 */
public with sharing class TravelEasyTestDataSetup {

    public static void generateSampleData() {
        // Create Sample Travel Request 1 - Normal Scenario
        Travel_Request__c tr1 = new Travel_Request__c();
        tr1.Destination__c = 'Chennai → Bangalore';
        tr1.Purpose__c = 'Annual Developer Catalyst Hackathon & Tech Conference';
        tr1.Start_Date__c = Date.today();
        tr1.End_Date__c = Date.today().addDays(3);
        tr1.Estimated_Cost__c = 25000;
        tr1.Travel_Type__c = 'Domestic';
        tr1.Department__c = 'Engineering';
        tr1.Status__c = 'Approved';
        tr1.Approval_Status__c = 'Approved';
        tr1.Business_Justification__c = 'Demonstrating 2027 NPN TravelEasy Intelligent Spend Control Platform.';
        insert tr1;

        Expense_Report__c exp1 = new Expense_Report__c();
        exp1.Travel_Request__c = tr1.Id;
        exp1.Report_Date__c = Date.today();
        exp1.Comments__c = 'Hackathon attendance & hotel expenses';
        exp1.Status__c = 'Draft';
        insert exp1;

        Expense_Item__c item1 = new Expense_Item__c();
        item1.Expense_Report__c = exp1.Id;
        item1.Travel_Request__c = tr1.Id;
        item1.Expense_Category__c = 'Flight';
        item1.Amount__c = 12000;
        item1.Expense_Date__c = Date.today();
        item1.Vendor__c = 'IndiGo Airlines';
        item1.Paid_By__c = 'Employee Personal';
        item1.Receipt_Attached__c = true;
        insert item1;

        Expense_Item__c item2 = new Expense_Item__c();
        item2.Expense_Report__c = exp1.Id;
        item2.Travel_Request__c = tr1.Id;
        item2.Expense_Category__c = 'Hotel';
        item2.Amount__c = 8000;
        item2.Expense_Date__c = Date.today();
        item2.Vendor__c = 'Marriott Bengaluru';
        item2.Paid_By__c = 'Employee Personal';
        item2.Receipt_Attached__c = true;
        insert item2;

        // Create Sample Travel Request 2 - Exception Scenario
        Travel_Request__c tr2 = new Travel_Request__c();
        tr2.Destination__c = 'Mumbai → Delhi';
        tr2.Purpose__c = 'Quarterly Executive Strategy Review';
        tr2.Start_Date__c = Date.today();
        tr2.End_Date__c = Date.today().addDays(2);
        tr2.Estimated_Cost__c = 15000;
        tr2.Travel_Type__c = 'Domestic';
        tr2.Department__c = 'Sales';
        tr2.Status__c = 'Approved';
        tr2.Approval_Status__c = 'Approved';
        insert tr2;

        Expense_Report__c exp2 = new Expense_Report__c();
        exp2.Travel_Request__c = tr2.Id;
        exp2.Report_Date__c = Date.today();
        exp2.Comments__c = 'Strategy meeting expenses';
        insert exp2;

        Expense_Item__c excItem = new Expense_Item__c();
        excItem.Expense_Report__c = exp2.Id;
        excItem.Travel_Request__c = tr2.Id;
        excItem.Expense_Category__c = 'Meals';
        excItem.Amount__c = 4500; // Exceeds Meal Limit of 2500 -> POLICY_EXCEPTION
        excItem.Expense_Date__c = Date.today();
        excItem.Vendor__c = 'Taj Fine Dining';
        excItem.Paid_By__c = 'Employee Personal';
        excItem.Receipt_Attached__c = true;
        insert excItem;
    }
}
