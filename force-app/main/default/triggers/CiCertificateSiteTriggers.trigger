trigger CiCertificateSiteTriggers on CI_Certificate_Site__c (after delete, after insert, after undelete, after update) {
	
	// Identify all the affected CI Sites
	Set<Id> affectedSites = new Set<Id>();
	for (Integer i = 0; i < Trigger.size; i++) {
	
		if (Trigger.isInsert || Trigger.isUndelete || Trigger.isUpdate) {
			Id siteId = Trigger.new[i].CI_Site__c;
			if (siteId != null) affectedSites.add(siteId);
		}
		if (Trigger.IsDelete || Trigger.isUpdate) {
			Id siteId = Trigger.old[i].CI_Site__c;
			if (siteId != null) affectedSites.add(siteId);
		}
	}
	
	// Only process if required
	if (!affectedSites.isEmpty()) {

		// Create a Map to count the COIs for each CI Site		
		Map<Id, Integer> siteCounts = new Map<Id, Integer>();
		for (Id s : affectedSites) siteCounts.put(s, 0);

		// Query all the CI Certificate Sites for the related CI Sites
		for (CI_Certificate_Site__c cs : [
			SELECT	CI_Site__c
			FROM	CI_Certificate_Site__c
			WHERE	CI_Site__c IN :affectedSites AND COI_Risk__c = TRUE
		]) {
			siteCounts.put(cs.CI_Site__c, siteCounts.get(cs.CI_Site__c) + 1);
		}
		
		// Update CI Sites if required
		List<CI_Site__c> toUpdate = new List<CI_Site__c>();
		for (CI_Site__c s : [
			SELECT	Id, COI_Count__c
			FROM	CI_Site__c
			WHERE	Id IN :affectedSites
		]) {
			if (s.COI_Count__c != siteCounts.get(s.Id)) toUpdate.add(new CI_Site__c(Id = s.Id, COI_Count__c = siteCounts.get(s.Id)));
		}		
		if (!toUpdate.isEmpty()) update toUpdate;
	}
}