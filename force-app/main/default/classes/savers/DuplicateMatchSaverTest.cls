@isTest
public with sharing class DuplicateMatchSaverTest {
	@isTest static void insertPending_ok() {
			TriggerControl.skipDuplicateMatchTrigger = true;
		Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
		User u = new User(
			Username = 'dedupuser-' + System.currentTimeMillis() + '@example.com',
			Email = 'dedupuser@example.com',
			Alias = 'dedup',
			TimeZoneSidKey = 'America/Los_Angeles',
			LocaleSidKey = 'en_US',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			ProfileId = p.Id,
			LastName = 'Dedup'
		);
		insert u;
		PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'DeduplicationUser' LIMIT 1];
		insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);
		System.runAs(u) {
			Customer__c cA1 = new Customer__c(FirstName__c='A', LastName__c='Alpha', Email__c='a@x.com');
			Customer__c cB1 = new Customer__c(FirstName__c='B', LastName__c='Beta', Email__c='b@x.com');
			Customer__c cA2 = new Customer__c(FirstName__c='C', LastName__c='Gamma', Email__c='c@x.com');
			Customer__c cB2 = new Customer__c(FirstName__c='D', LastName__c='Delta', Email__c='d@x.com');
			insert new List<Customer__c>{cA1, cB1, cA2, cB2};
			List<Duplicate_Match__c> records = new List<Duplicate_Match__c>{
				new Duplicate_Match__c(Customer_A__c = cA1.Id, Customer_B__c = cB1.Id, Match_Score__c = 0.95, Status__c = 'Pending Review'),
				new Duplicate_Match__c(Customer_A__c = cA2.Id, Customer_B__c = cB2.Id, Match_Score__c = 0.90, Status__c = 'Pending Review')
			};
			DuplicateMatchSaver saver = new DuplicateMatchSaver();
			List<Database.SaveResult> results = saver.insertPending(records);
			System.assertEquals(2, results.size(), 'Should return two SaveResults');
			for (Database.SaveResult sr : results) {
				System.assert(sr.isSuccess(), 'Both inserts should succeed');
			}
			List<Duplicate_Match__c> persisted = [SELECT Id, Status__c FROM Duplicate_Match__c WHERE Id IN :new List<Id>{results[0].getId(), results[1].getId()}];
			System.assertEquals(2, persisted.size(), 'Two rows should be persisted');
			for (Duplicate_Match__c dm : persisted) {
				System.assertEquals('Pending Review', dm.Status__c, 'Status__c should be Pending Review');
			}
				TriggerControl.skipDuplicateMatchTrigger = false;
		}
	}

	@isTest static void insertPending_partialFailure() {
		Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
		User u = new User(
			Username = 'dedupuser2-' + System.currentTimeMillis() + '@example.com',
			Email = 'dedupuser2@example.com',
			Alias = 'dedup2',
			TimeZoneSidKey = 'America/Los_Angeles',
			LocaleSidKey = 'en_US',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			ProfileId = p.Id,
			LastName = 'Dedup2'
		);
		insert u;
		PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'DeduplicationUser' LIMIT 1];
		insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);
		System.runAs(u) {
			Customer__c cA = new Customer__c(FirstName__c='A', LastName__c='Alpha', Email__c='a2@x.com');
			Customer__c cB = new Customer__c(FirstName__c='B', LastName__c='Beta', Email__c='b2@x.com');
			insert new List<Customer__c>{cA, cB};
			List<Duplicate_Match__c> records = new List<Duplicate_Match__c>{
				new Duplicate_Match__c(Customer_A__c = cA.Id, Customer_B__c = cB.Id, Match_Score__c = 0.88, Status__c = 'Pending Review'),
				new Duplicate_Match__c(Customer_A__c = null, Customer_B__c = cB.Id, Match_Score__c = 0.77, Status__c = 'Pending Review')
			};
			DuplicateMatchSaver saver = new DuplicateMatchSaver();
			List<Database.SaveResult> results = saver.insertPending(records);
			System.assertEquals(2, results.size(), 'Should return two SaveResults');
			System.assert(results[0].isSuccess(), 'First insert should succeed');
			System.assert(!results[1].isSuccess(), 'Second insert should fail');
		}
	}

	@isTest static void updateStatus_ok() {
		Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
		User u = new User(
			Username = 'dedupuser3-' + System.currentTimeMillis() + '@example.com',
			Email = 'dedupuser3@example.com',
			Alias = 'dedup3',
			TimeZoneSidKey = 'America/Los_Angeles',
			LocaleSidKey = 'en_US',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			ProfileId = p.Id,
			LastName = 'Dedup3'
		);
		insert u;
		PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'DeduplicationUser' LIMIT 1];
		insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);
		System.runAs(u) {
			Customer__c cA1 = new Customer__c(FirstName__c='A', LastName__c='Alpha', Email__c='a3@x.com');
			Customer__c cB1 = new Customer__c(FirstName__c='B', LastName__c='Beta', Email__c='b3@x.com');
			Customer__c cA2 = new Customer__c(FirstName__c='C', LastName__c='Gamma', Email__c='c3@x.com');
			Customer__c cB2 = new Customer__c(FirstName__c='D', LastName__c='Delta', Email__c='d3@x.com');
			insert new List<Customer__c>{cA1, cB1, cA2, cB2};
			List<Duplicate_Match__c> records = new List<Duplicate_Match__c>{
				new Duplicate_Match__c(Customer_A__c = cA1.Id, Customer_B__c = cB1.Id, Match_Score__c = 0.85, Status__c = 'Pending Review'),
				new Duplicate_Match__c(Customer_A__c = cA2.Id, Customer_B__c = cB2.Id, Match_Score__c = 0.80, Status__c = 'Pending Review')
			};
			insert records;
			Set<Id> ids = new Set<Id>{records[0].Id, records[1].Id};
			DuplicateMatchSaver saver = new DuplicateMatchSaver();
			List<Database.SaveResult> results = saver.updateStatus(ids, 'Ignored');
			System.assertEquals(2, results.size(), 'Should return two SaveResults');
			for (Database.SaveResult sr : results) {
				System.assert(sr.isSuccess(), 'Both updates should succeed');
			}
			List<Duplicate_Match__c> updated = [SELECT Id, Status__c FROM Duplicate_Match__c WHERE Id IN :ids];
			for (Duplicate_Match__c dm : updated) {
				System.assertEquals('Ignored', dm.Status__c, 'Status__c should be Ignored');
			}
		}
	}

	@isTest static void updateStatus_emptyInput() {
		Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
		User u = new User(
			Username = 'dedupuser4-' + System.currentTimeMillis() + '@example.com',
			Email = 'dedupuser4@example.com',
			Alias = 'dedup4',
			TimeZoneSidKey = 'America/Los_Angeles',
			LocaleSidKey = 'en_US',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			ProfileId = p.Id,
			LastName = 'Dedup4'
		);
		insert u;
		PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'DeduplicationUser' LIMIT 1];
		insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);
		System.runAs(u) {
			Integer beforeDml = Limits.getDmlStatements();
			DuplicateMatchSaver saver = new DuplicateMatchSaver();
			List<Database.SaveResult> results = saver.updateStatus(new Set<Id>(), 'Merged');
			System.assertEquals(0, results.size(), 'Should return empty SaveResult list');
			Integer afterDml = Limits.getDmlStatements();
			System.assertEquals(beforeDml, afterDml, 'No DML should be performed');
		}
	}

	@isTest static void upsertPending_withIds() {
		Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
		User u = new User(
			Username = 'dedupuser5-' + System.currentTimeMillis() + '@example.com',
			Email = 'dedupuser5@example.com',
			Alias = 'dedup5',
			TimeZoneSidKey = 'America/Los_Angeles',
			LocaleSidKey = 'en_US',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			ProfileId = p.Id,
			LastName = 'Dedup5'
		);
		insert u;
		PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'DeduplicationUser' LIMIT 1];
		insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);
		System.runAs(u) {
			Customer__c cA = new Customer__c(FirstName__c='A', LastName__c='Alpha', Email__c='a5@x.com');
			Customer__c cB = new Customer__c(FirstName__c='B', LastName__c='Beta', Email__c='b5@x.com');
			insert new List<Customer__c>{cA, cB};
			Duplicate_Match__c rec = new Duplicate_Match__c(Customer_A__c = cA.Id, Customer_B__c = cB.Id, Match_Score__c = 0.70, Status__c = 'Pending Review');
			insert rec;
			rec.Match_Score__c = 0.99;
			DuplicateMatchSaver saver = new DuplicateMatchSaver();
			List<Database.UpsertResult> results = saver.upsertPending(new List<Duplicate_Match__c>{rec});
			System.assertEquals(1, results.size(), 'Should return one UpsertResult');
			System.assert(results[0].isSuccess(), 'Upsert should succeed');
			Duplicate_Match__c updated = [SELECT Id, Match_Score__c FROM Duplicate_Match__c WHERE Id = :rec.Id];
			System.assertEquals(0.99, updated.Match_Score__c, 'Match_Score__c should be updated');
		}
	}
}