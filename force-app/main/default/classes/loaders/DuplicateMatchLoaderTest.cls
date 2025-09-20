@isTest
public class DuplicateMatchLoaderTest {
	@isTest
	static void testDuplicateMatchLoaderMethods() {
		Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
		User u = new User(
			Username = 'testloaderadmin@example.com',
            lastName = 'Admin',
			Email = 'testloaderadmin@example.com',
			Alias = 'tadmin',
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
			// Seed customers
			Customer__c cA = new Customer__c(FirstName__c='A', Email__c='a@x.com', Phone__c='(111) 111-1111', Phone_Normalized__c='11111111111', SignupDate__c=Date.today(), LastName__c='Alpha');
			Customer__c cB = new Customer__c(FirstName__c='B', Email__c='b@x.com', Phone__c='(222) 222-2222', Phone_Normalized__c='12222222222', SignupDate__c=Date.today(), LastName__c='Beta');
			insert new List<Customer__c>{cA, cB};
			// Seed matches
            Duplicate_Match__c m1 = new Duplicate_Match__c(Customer_A__c=cA.Id, Customer_B__c=cB.Id, Match_Score__c=100, Status__c='Pending');
            Duplicate_Match__c m2 = new Duplicate_Match__c(Customer_A__c=cB.Id, Customer_B__c=cA.Id, Match_Score__c=50, Status__c='Merged');
            Duplicate_Match__c m3 = new Duplicate_Match__c(Customer_A__c=cA.Id, Customer_B__c=cB.Id, Match_Score__c=70, Status__c='Pending');
			insert new List<Duplicate_Match__c>{m1, m2, m3};
			DuplicateMatchLoader loader = new DuplicateMatchLoader();
			// selectByIds
			Set<Id> ids = new Set<Id>{m1.Id, m2.Id};
			List<Duplicate_Match__c> byIds = loader.selectByIds(ids);
			Assert.areEqual(2, byIds.size(), 'Should return matches by Id');
			// selectPending
			List<Duplicate_Match__c> pending = loader.selectPending();
			Assert.areEqual(2, pending.size(), 'Should return only pending matches');
			Assert.areEqual(100, pending[0].Match_Score__c, 'Pending matches ordered by score desc');
			Assert.areEqual(70, pending[1].Match_Score__c, 'Pending matches ordered by score desc');
			// selectByCustomer
			List<Duplicate_Match__c> byCustomerA = loader.selectByCustomer(cA.Id);
			Assert.areEqual(3, byCustomerA.size(), 'Should return all matches for customer A');
			List<Duplicate_Match__c> byCustomerB = loader.selectByCustomer(cB.Id);
			Assert.areEqual(3, byCustomerB.size(), 'Should return all matches for customer B');
			// Empty results
			Assert.areEqual(0, loader.selectByIds(new Set<Id>()).size(), 'Should return empty for no match');
		}
	}
}