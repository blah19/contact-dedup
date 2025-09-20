public with sharing class DuplicateMatchSaver implements ISaver {
	/**
	 * Inserts new Duplicate_Match__c records with Status__c='Pending Review'.
	 * Bulk-safe: single DML for all records.
	 * Returns per-row SaveResult.
	 */
	public List<Database.SaveResult> insertPending(List<Duplicate_Match__c> records) {
		if (records == null || records.isEmpty()) {
			return new List<Database.SaveResult>();
		}
		return Database.insert(records, false);
	}

	/**
	 * Updates Status__c for given Ids to newStatus.
	 * Bulk-safe: single DML for all records.
	 * Returns per-row SaveResult.
	 */
	public List<Database.SaveResult> updateStatus(Set<Id> ids, String newStatus) {
		if (ids == null || ids.isEmpty()) {
			return new List<Database.SaveResult>();
		}
		List<Duplicate_Match__c> updates = new List<Duplicate_Match__c>();
		for (Id idVal : ids) {
			updates.add(new Duplicate_Match__c(Id = idVal, Status__c = newStatus));
		}
		return Database.update(updates, false);
	}

	/**
	 * Upserts Duplicate_Match__c records (by Id if present).
	 * Bulk-safe: single DML for all records.
	 * Returns per-row UpsertResult.
	 */
	public List<Database.UpsertResult> upsertPending(List<Duplicate_Match__c> records) {
		if (records == null || records.isEmpty()) {
			return new List<Database.UpsertResult>();
		}
		return Database.upsert(records, false);
	}
}