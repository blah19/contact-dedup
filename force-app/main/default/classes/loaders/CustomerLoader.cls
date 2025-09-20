public with sharing class CustomerLoader {
	public List<Customer__c> selectAll() {
		return [SELECT Id, FirstName__c, LastName__c, Email__c, Phone__c, Phone_Normalized__c, SignupDate__c FROM Customer__c WITH USER_MODE ORDER BY Id];
	}
	public List<Customer__c> selectByIds(Set<Id> ids) {
		if (ids == null || ids.isEmpty()) return new List<Customer__c>();
		return [SELECT Id, FirstName__c, LastName__c, Email__c, Phone__c, Phone_Normalized__c, SignupDate__c FROM Customer__c WHERE Id IN :ids WITH USER_MODE ORDER BY Id];
	}
	public List<Customer__c> selectByEmail(String email) {
		if (String.isBlank(email)) return new List<Customer__c>();
		return [SELECT Id, FirstName__c, LastName__c, Email__c, Phone__c, Phone_Normalized__c, SignupDate__c FROM Customer__c WHERE Email__c = :email WITH USER_MODE ORDER BY Id];
	}
	public List<Customer__c> selectByPhoneNormalized(String phone) {
		if (String.isBlank(phone)) return new List<Customer__c>();
		return [SELECT Id, FirstName__c, LastName__c, Email__c, Phone__c, Phone_Normalized__c, SignupDate__c FROM Customer__c WHERE Phone_Normalized__c = :phone WITH USER_MODE ORDER BY Id];
	}
	public List<Customer__c> selectByLastNameAndPhoneNormalized(String lastName, String phone) {
		if (String.isBlank(lastName) || String.isBlank(phone)) return new List<Customer__c>();
		return [SELECT Id, FirstName__c, LastName__c, Email__c, Phone__c, Phone_Normalized__c, SignupDate__c FROM Customer__c WHERE LastName__c = :lastName AND Phone_Normalized__c = :phone WITH USER_MODE ORDER BY Id];
	}
}