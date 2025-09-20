@isTest
public class DuplicateMatchLoaderTest {
	@isTest
	static void testDuplicateMatchLoaderMethods() {
		// Seed customers
		Customer__c cA = new Customer__c(FirstName__c='A', LastName__c='Alpha', Email__c='a@x.com', Phone__c='(111) 111-1111', Phone_Normalized__c='11111111111', SignupDate__c=Date.today());
		Customer__c cB = new Customer__c(FirstName__c='B', LastName__c='Beta', Email__c='b@x.com', Phone__c='(222) 222-2222', Phone_Normalized__c='12222222222', SignupDate__c=Date.today());
		insert new List<Customer__c>{cA, cB};
		// Seed matches
		Duplicate_Match__c m1 = new Duplicate_Match__c(Customer_A__c=cA.Id, Customer_B__c=cB.Id, Match_Score__c=100, Status__c='Pending Review');
		Duplicate_Match__c m2 = new Duplicate_Match__c(Customer_A__c=cB.Id, Customer_B__c=cA.Id, Match_Score__c=50, Status__c='Merged');
		Duplicate_Match__c m3 = new Duplicate_Match__c(Customer_A__c=cA.Id, Customer_B__c=cB.Id, Match_Score__c=70, Status__c='Pending Review');
		insert new List<Duplicate_Match__c>{m1, m2, m3};
		DuplicateMatchLoader loader = new DuplicateMatchLoader();
		// selectByIds
		Set<Id> ids = new Set<Id>{m1.Id, m2.Id};
		List<Duplicate_Match__c> byIds = loader.selectByIds(ids);
		System.assertEquals(2, byIds.size(), 'Should return matches by Id');
		// selectPending
		List<Duplicate_Match__c> pending = loader.selectPending();
		System.assertEquals(2, pending.size(), 'Should return only pending matches');
		System.assertEquals(100, pending[0].Match_Score__c, 'Pending matches ordered by score desc');
		System.assertEquals(70, pending[1].Match_Score__c, 'Pending matches ordered by score desc');
		// selectByCustomer
		List<Duplicate_Match__c> byCustomerA = loader.selectByCustomer(cA.Id);
		System.assertEquals(3, byCustomerA.size(), 'Should return all matches for customer A');
		List<Duplicate_Match__c> byCustomerB = loader.selectByCustomer(cB.Id);
		System.assertEquals(3, byCustomerB.size(), 'Should return all matches for customer B');
		// Empty results
		System.assertEquals(0, loader.selectByIds(new Set<Id>()).size(), 'Should return empty for no match');
	}
}