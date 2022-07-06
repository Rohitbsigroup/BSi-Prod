global class bg_BatchCreateDefaultSites implements Database.Batchable<sObject> {
	
	String query {get; set;}
	Map<String,Id> rtypeMap {get; set;}
	Id defaultSiteRecordTypeId {get; set;}
	
	global bg_BatchCreateDefaultSites() {
		this.rtypeMap = Utility.getRecordTypes('Site__c');
		if(this.rtypeMap.containsKey(Utility.RTNAME_DEFAULT))
		{
			this.defaultSiteRecordTypeId = this.rtypeMap.get(Utility.RTNAME_DEFAULT);
			this.query = 'SELECT Id, Name, BillingCity, BillingCountry, NumberOfEmployees, BillingPostalCode, BillingState, BillingStreet FROM Account WHERE Id NOT IN (SELECT Account__c FROM Site__c WHERE RecordTypeId = :defaultSiteRecordTypeId)';
		}
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) 
   	{
		bg_SiteUtils.createDefaultSite(scope);	
	}
	
	global void finish(Database.BatchableContext BC) {
		
	}	
}