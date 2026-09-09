/**
 * Tests for CaseSpamDeletionDemo. Also exercises the before-save flow
 * "Case - Before Save - Spam Auto Close" end to end: inserting a Case with
 * Spam__c = true relies on the flow to close it and assign it to the Spam Queue.
 */
@isTest
private class CaseSpamDeletionDemoTest {

    @testSetup
    static void makeData() {
        // Queues are setup objects: visible to tests without SeeAllData, but creating
        // one alongside Cases needs runAs to avoid MIXED_DML_OPERATION.
        List<Group> spamQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Spam_Queue'];
        if (spamQueue.isEmpty()) {
            System.runAs(new User(Id = UserInfo.getUserId())) {
                Group q = new Group(Name = 'Spam Queue', DeveloperName = 'Spam_Queue', Type = 'Queue');
                insert q;
                insert new QueueSobject(QueueId = q.Id, SobjectType = 'Case');
            }
        }

        insert new List<Case>{
            new Case(Subject = 'You won a free cruise!!!', Origin = 'Email', Spam__c = true),
            new Case(Subject = 'Crypto doubling offer', Origin = 'Email', Spam__c = true),
            new Case(Subject = 'Legitimate support request', Origin = 'Email', Spam__c = false)
        };
    }

    @isTest
    static void beforeSaveFlowClosesAndReassignsFlaggedCases() {
        // Owner.Name is asserted via OwnerId + the formula field: polymorphic Owner.Name
        // does not resolve for queue owners inside test context.
        Group spamQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Spam_Queue' LIMIT 1];
        List<Case> flagged = [SELECT Status, OwnerId, Case_Owner_Name__c, ClosedDate FROM Case WHERE Spam__c = true];
        System.assertEquals(2, flagged.size(), 'Both spam Cases should exist');
        for (Case c : flagged) {
            System.assertEquals('Closed', c.Status, 'Flow should close flagged Cases');
            System.assertEquals(spamQueue.Id, c.OwnerId, 'Flow should assign flagged Cases to the Spam Queue');
            System.assertEquals('Spam Queue', c.Case_Owner_Name__c, 'Owner-name formula should resolve the queue name');
            System.assertNotEquals(null, c.ClosedDate, 'Closing should stamp ClosedDate');
        }
    }

    @isTest
    static void previewListsEligibleCasesWithoutDeleting() {
        Test.startTest();
        List<Case> eligibleNow = CaseSpamDeletionDemo.preview(0);
        List<Case> eligibleAtRetention = CaseSpamDeletionDemo.preview();
        Test.stopTest();

        System.assertEquals(2, eligibleNow.size(), 'Demo mode should see both freshly closed spam Cases');
        System.assertEquals(0, eligibleAtRetention.size(),
            'Freshly closed Cases are inside the 2-day retention, so the scheduled run would delete nothing');
        System.assertEquals(3, [SELECT COUNT() FROM Case], 'preview must not delete anything');
    }

    @isTest
    static void scheduledRunKeepsCasesInsideRetention() {
        Test.startTest();
        Integer deleted = CaseSpamDeletionDemo.run();
        Test.stopTest();

        System.assertEquals(0, deleted, 'Cases closed today are inside the 2-day retention');
        System.assertEquals(3, [SELECT COUNT() FROM Case], 'No Case should be deleted');
    }

    @isTest
    static void demoRunDeletesOnlyFlaggedCasesInSpamQueue() {
        Test.startTest();
        Integer deleted = CaseSpamDeletionDemo.run(0);
        Test.stopTest();

        System.assertEquals(2, deleted, 'Demo mode should delete both closed spam Cases');
        List<Case> remaining = [SELECT Subject, Spam__c FROM Case];
        System.assertEquals(1, remaining.size(), 'Only the legitimate Case should remain');
        System.assertEquals('Legitimate support request', remaining[0].Subject);
        System.assertEquals(false, remaining[0].Spam__c);
    }
}
