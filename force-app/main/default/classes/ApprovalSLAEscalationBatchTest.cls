@IsTest
private class ApprovalSLAEscalationBatchTest {

    @IsTest
    static void testBatchAndSchedulableExecution() {
        Travel_Request__c tr = new Travel_Request__c();
        tr.Destination__c = 'Delhi';
        tr.Purpose__c = 'Partner Summit';
        tr.Start_Date__c = Date.today().addDays(1);
        tr.End_Date__c = Date.today().addDays(3);
        tr.Estimated_Cost__c = 25000;
        tr.Approval_Status__c = 'Pending Approval';
        insert tr;

        Test.startTest();
        // Execute batch directly
        Database.executeBatch(new ApprovalSLAEscalationBatch());

        // Test schedulable
        String cronExp = '0 0 0 15 3 ? 2030';
        String jobId = System.schedule('TestSLAEscalationSchedule', cronExp, new ApprovalSLAEscalationBatch());
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Job ID should be returned from schedule.');
    }
}
