@isTest
private class DuplicateMatchingServiceTest {
	@isTest static void test_runAndSavePending_all() {
			TriggerControl.skipDuplicateMatchTrigger = true;
		Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
		User u = new User(
			Username = 'dedupsvcuser-' + System.currentTimeMillis() + '@example.com',
			Email = 'dedupsvcuser@example.com',
			Alias = 'dedupsvc',
			LastName = 'DedupSvc',
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
			// Setup test data
			List<Customer__c> customers = new List<Customer__c>{
				new Customer__c(FirstName__c='Alice', LastName__c='Smith', Email__c='alice@example.com', Phone__c='1234567890', Phone_Normalized__c='1234567890', SignupDate__c=Date.today()),
				new Customer__c(FirstName__c='Alicia', LastName__c='Smith', Email__c='alice@example.com', Phone__c='1234567890', Phone_Normalized__c='1234567890', SignupDate__c=Date.today()),
				new Customer__c(FirstName__c='Bob', LastName__c='Smith', Email__c='bob@example.com', Phone__c='1234567890', Phone_Normalized__c='1234567890', SignupDate__c=Date.today()),
				new Customer__c(FirstName__c='Carol', LastName__c='Jones', Email__c='carol@example.com', Phone__c='9998887777', Phone_Normalized__c='9998887777', SignupDate__c=Date.today())
			};
			insert customers;
			// Re-query to get valid Ids
			List<Customer__c> queried = [SELECT Id, FirstName__c, LastName__c, Email__c, Phone__c, Phone_Normalized__c, SignupDate__c FROM Customer__c WHERE Id IN :customers];

			Test.startTest();
			DuplicateMatchingService svc = new DuplicateMatchingService();
			Integer result = svc.runAndSavePending();
			Test.stopTest();
			System.assertEquals(3, result, 'Should find and save 3 candidate pairs');
			// Optionally, verify inserted Duplicate_Match__c records
			List<Duplicate_Match__c> matches = [SELECT Id, Status__c FROM Duplicate_Match__c WHERE Status__c = 'Pending Review'];
			System.assertEquals(3, matches.size(), 'Should have 3 pending review matches');
				TriggerControl.skipDuplicateMatchTrigger = false;
		}
	}

	@isTest static void test_runAndSavePending_subset() {
			TriggerControl.skipDuplicateMatchTrigger = true;
		Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
		User u = new User(
			Username = 'dedupsvcuser2-' + System.currentTimeMillis() + '@example.com',
			Email = 'dedupsvcuser2@example.com',
			Alias = 'dedup2',
			LastName = 'DedupSvc2',
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
				new Customer__c(FirstName__c='Bob', LastName__c='Smith', Email__c='bob@example.com', Phone__c='1234567890', Phone_Normalized__c='1234567890', SignupDate__c=Date.today()),
				new Customer__c(FirstName__c='Carol', LastName__c='Jones', Email__c='carol@example.com', Phone__c='9998887777', Phone_Normalized__c='9998887777', SignupDate__c=Date.today())
			};
			insert customers;
			// Re-query to get valid Ids
			List<Customer__c> queried = [SELECT Id FROM Customer__c WHERE Id IN :customers];

			Set<Id> ids = new Set<Id>{queried[0].Id, queried[1].Id};
			DuplicateMatchingService svc = new DuplicateMatchingService();
			Integer result = svc.runAndSavePending(ids);
			System.assertEquals(1, result, 'Should find and save 1 candidate pair for subset');
			List<Duplicate_Match__c> matches = [SELECT Id, Status__c FROM Duplicate_Match__c WHERE Status__c = 'Pending Review'];
			System.assertEquals(1, matches.size(), 'Should have 1 pending review match');
				TriggerControl.skipDuplicateMatchTrigger = false;
		}
	}

	// No mocks needed; use real classes and DML
}