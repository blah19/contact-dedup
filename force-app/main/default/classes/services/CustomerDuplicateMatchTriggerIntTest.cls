@isTest
public class CustomerDuplicateMatchTriggerIntTest {
    @isTest static void test_insert_creates_duplicate_matches() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User u = new User(
            Username = 'inttestuser-' + System.currentTimeMillis() + '@example.com',
            Email = 'inttestuser@example.com',
            Alias = 'inttest',
            LastName = 'IntTest',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert u;
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'DeduplicationUser' LIMIT 1];
        insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);
        System.runAs(u) {
            List<Customer__c> customers = new List<Customer__c>{
                new Customer__c(FirstName__c='Alice', LastName__c='Smith', Email__c='alice@example.com', Phone__c='1234567890', Phone_Normalized__c='1234567890', SignupDate__c=Date.today()),
                new Customer__c(FirstName__c='Alicia', LastName__c='Smith', Email__c='alice@example.com', Phone__c='1234567890', Phone_Normalized__c='1234567890', SignupDate__c=Date.today()),
                new Customer__c(FirstName__c='Bob', LastName__c='Smith', Email__c='bob@example.com', Phone__c='1234567890', Phone_Normalized__c='1234567890', SignupDate__c=Date.today())
            };
            insert customers;
            // After insert, trigger should create duplicate match records
            List<Duplicate_Match__c> matches = [SELECT Id, Customer_A__c, Customer_B__c, Match_Score__c, Status__c FROM Duplicate_Match__c WHERE Status__c = 'Pending Review'];
            System.assert(matches.size() > 0, 'Should create duplicate match records after insert');
                TriggerControl.skipDuplicateMatchTrigger = false;
        }
    }
}
