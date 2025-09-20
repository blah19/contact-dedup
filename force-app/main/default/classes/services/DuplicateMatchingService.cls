public with sharing class DuplicateMatchingService {
	@TestVisible private CustomerLoader customerLoader = new CustomerLoader();
	@TestVisible private DuplicateMatchSaver duplicateMatchSaver = new DuplicateMatchSaver();

	public Integer runAndSavePending() {
		List<Customer__c> customers = customerLoader.selectAll();
		return runAndSavePendingInternal(customers);
	}

	public Integer runAndSavePending(Set<Id> customerIds) {
		if (customerIds == null || customerIds.isEmpty()) return 0;
		List<Customer__c> customers = new List<Customer__c>();
		List<Id> idList = new List<Id>(customerIds);
		Integer chunkSize = 2000;
		for (Integer i = 0; i < idList.size(); i += chunkSize) {
			Integer endIdx = Math.min(i + chunkSize, idList.size());
			Set<Id> chunk = new Set<Id>();
			for (Integer j = i; j < endIdx; j++) chunk.add(idList[j]);
			customers.addAll(customerLoader.selectByIds(chunk));
		}
		return runAndSavePendingInternal(customers);
	}

	private Integer runAndSavePendingInternal(List<Customer__c> customers) {
		// Buckets
		Map<String, List<Customer__c>> byEmail = new Map<String, List<Customer__c>>();
		Map<String, List<Customer__c>> byPhone = new Map<String, List<Customer__c>>();
		Map<String, List<Customer__c>> byLastPhone = new Map<String, List<Customer__c>>();

		for (Customer__c c : customers) {
			if (String.isNotBlank(c.Email__c)) {
				if (!byEmail.containsKey(c.Email__c)) byEmail.put(c.Email__c, new List<Customer__c>());
				byEmail.get(c.Email__c).add(c);
			}
			if (String.isNotBlank(c.Phone_Normalized__c)) {
				if (!byPhone.containsKey(c.Phone_Normalized__c)) byPhone.put(c.Phone_Normalized__c, new List<Customer__c>());
				byPhone.get(c.Phone_Normalized__c).add(c);
			}
			String lastPhoneKey = (String.isNotBlank(c.LastName__c) && String.isNotBlank(c.Phone_Normalized__c)) ? c.LastName__c.trim().toLowerCase() + '|' + c.Phone_Normalized__c : null;
			if (String.isNotBlank(lastPhoneKey)) {
				if (!byLastPhone.containsKey(lastPhoneKey)) byLastPhone.put(lastPhoneKey, new List<Customer__c>());
				byLastPhone.get(lastPhoneKey).add(c);
			}
		}

		// Pair scoring
		Map<String, Integer> pairScores = new Map<String, Integer>();
		Map<String, Map<String, List<Customer__c>>> buckets = new Map<String, Map<String, List<Customer__c>>>();
		buckets.put('email', byEmail);
		buckets.put('phone', byPhone);
		buckets.put('lastphone', byLastPhone);

		for (String bucketType : buckets.keySet()) {
			Map<String, List<Customer__c>> bucket = buckets.get(bucketType);
			for (String key : bucket.keySet()) {
				List<Customer__c> bucketList = bucket.get(key);
				if (bucketList.size() < 2) continue;
				// Generate unordered pairs
				for (Integer i = 0; i < bucketList.size(); i++) {
					for (Integer j = i + 1; j < bucketList.size(); j++) {
						Customer__c a = bucketList[i];
						Customer__c b = bucketList[j];
						if (a.Id == b.Id) continue;
						Id minId = a.Id < b.Id ? a.Id : b.Id;
						Id maxId = a.Id < b.Id ? b.Id : a.Id;
						String pairKey = String.valueOf(minId) + '|' + String.valueOf(maxId);
						Integer score = 0;
						if (bucketType == 'email') {
							score = 100;
						} else if (bucketType == 'phone') {
							if (fuzzyFirstName(a.FirstName__c, b.FirstName__c)) {
								score = 70;
							}
						} else if (bucketType == 'lastphone') {
							score = 50;
						}
						if (!pairScores.containsKey(pairKey) || score > pairScores.get(pairKey)) {
							pairScores.put(pairKey, score);
						}
					}
				}
			}
		}

		// Materialize Duplicate_Match__c rows
		List<Duplicate_Match__c> matches = new List<Duplicate_Match__c>();
		for (String pairKey : pairScores.keySet()) {
			Integer score = pairScores.get(pairKey);
			if (score > 0) {
				List<String> ids = pairKey.split('\u007C');
				matches.add(new Duplicate_Match__c(Customer_A__c = (Id)ids[0], Customer_B__c = (Id)ids[1], Match_Score__c = score, Status__c = 'Pending Review'));
			}
		}
		List<Database.SaveResult> results = duplicateMatchSaver.insertPending(matches);
		Integer successCount = 0;
		for (Database.SaveResult sr : results) {
			if (sr.isSuccess()) successCount++;
		}
		return successCount;
	}

	@TestVisible private static Boolean fuzzyFirstName(String a, String b) {
		String fa = String.isBlank(a) ? '' : a.trim().toLowerCase();
		String fb = String.isBlank(b) ? '' : b.trim().toLowerCase();
		return editDistance(fa, fb) <= 1;
	}

	@TestVisible private static Integer editDistance(String a, String b) {
		Integer m = a.length();
		Integer n = b.length();
		List<List<Integer>> dp = new List<List<Integer>>();
		for (Integer i = 0; i <= m; i++) {
			List<Integer> row = new List<Integer>();
			for (Integer j = 0; j <= n; j++) row.add(0);
			dp.add(row);
		}
		for (Integer i = 0; i <= m; i++) dp[i][0] = i;
		for (Integer j = 0; j <= n; j++) dp[0][j] = j;
		for (Integer i = 1; i <= m; i++) {
			for (Integer j = 1; j <= n; j++) {
				if (a.substring(i-1, i) == b.substring(j-1, j)) {
					dp[i][j] = dp[i-1][j-1];
				} else {
					dp[i][j] = 1 + Math.min(dp[i-1][j-1], Math.min(dp[i][j-1], dp[i-1][j]));
				}
			}
		}
		return dp[m][n];
	}
}