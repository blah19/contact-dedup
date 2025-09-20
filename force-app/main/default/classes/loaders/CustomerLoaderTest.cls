@isTest(isParallel=false)
public class CustomerLoaderTest {
	@isTest
	static void testCustomerLoaderMethods() {
		Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
		User u = new User(
			Username = 'customerloaderuser-' + System.currentTimeMillis() + '@example.com',
			Email = 'customerloaderuser@example.com',
			Alias = 'cluser',
			LastName = 'test',
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
			Customer__c c1 = new Customer__c(FirstName__c='Alice', LastName__c='Smith', Email__c='alice@example.com', Phone__c='(123) 456-7890', Phone_Normalized__c='11234567890', SignupDate__c=Date.today());
			Customer__c c2 = new Customer__c(FirstName__c='Bob', LastName__c='Smith', Email__c='bob@example.com', Phone__c='(123) 456-7890', Phone_Normalized__c='11234567890', SignupDate__c=Date.today());
			Customer__c c3 = new Customer__c(FirstName__c='Carol', LastName__c='Jones', Email__c='carol@example.com', Phone__c='(999) 888-7777', Phone_Normalized__c='19998887777', SignupDate__c=Date.today());
			insert new List<Customer__c>{c1, c2, c3};
			CustomerLoader loader = new CustomerLoader();
			// selectAll
			List<Customer__c> all = loader.selectAll();
			System.assertEquals(3, all.size(), 'Should return all seeded customers');
			// selectByIds
			Set<Id> ids = new Set<Id>{c1.Id, c3.Id};
			List<Customer__c> byIds = loader.selectByIds(ids);
			System.assertEquals(2, byIds.size(), 'Should return customers by Id');
			// selectByEmail
			List<Customer__c> byEmail = loader.selectByEmail('alice@example.com');
			System.assertEquals(1, byEmail.size(), 'Should return customer by email');
			// selectByPhoneNormalized
			List<Customer__c> byPhone = loader.selectByPhoneNormalized('11234567890');
			System.assertEquals(2, byPhone.size(), 'Should return customers sharing normalized phone');
			// selectByLastNameAndPhoneNormalized
			List<Customer__c> byLastNamePhone = loader.selectByLastNameAndPhoneNormalized('Smith', '11234567890');
			System.assertEquals(2, byLastNamePhone.size(), 'Should return customers sharing last name and phone');
			// Empty results
			System.assertEquals(0, loader.selectByEmail('notfound@example.com').size(), 'Should return empty for no match');
		}
	}
}