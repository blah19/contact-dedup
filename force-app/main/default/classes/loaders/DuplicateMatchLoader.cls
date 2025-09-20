public with sharing class DuplicateMatchLoader {
	public List<Duplicate_Match__c> selectByIds(Set<Id> ids) {
		if (ids == null || ids.isEmpty()) return new List<Duplicate_Match__c>();
		return [SELECT Id, Customer_A__c, Customer_B__c, Match_Score__c, Status__c FROM Duplicate_Match__c WHERE Id IN :ids WITH USER_MODE ORDER BY Id];
	}
	public List<Duplicate_Match__c> selectPending() {
		return [
			SELECT Id, Customer_A__c, Customer_B__c, Match_Score__c, Status__c
			FROM Duplicate_Match__c
			WHERE Status__c = 'Pending'
			WITH USER_MODE
			ORDER BY Id
		];
	}
	public List<Duplicate_Match__c> selectByCustomer(Id customerId) {
		if (customerId == null) return new List<Duplicate_Match__c>();
		return [SELECT Id, Customer_A__c, Customer_B__c, Match_Score__c, Status__c FROM Duplicate_Match__c WHERE Customer_A__c = :customerId OR Customer_B__c = :customerId WITH USER_MODE ORDER BY Id];
	}
}