/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Description:  Visualforce Controller used to refresh territories after a change. 
*
*       
**/
public with sharing class TerritoryRefreshController {
	
	public Territory__c terr 			{get; set;}
	public Integer		accEstimate		{get; set;}
	public Integer		conEstimate		{get; set;}
	public Integer		leaEstimate		{get; set;}
	public Integer		oppEstimate		{get; set;}
	public Integer		sitEstimate		{get; set;}

	//public Integer 		percentage		{get; set;}
	
	public Boolean		accPending		{get; set;}
	public Boolean		conPending		{get; set;}
	public Boolean		leaPending		{get; set;}
	public Boolean		oppPending		{get; set;}
	public Boolean		sitPending		{get; set;}
	
	public DateTime		lastmodified	{get; set;}
	
	public TerritoryRefreshController(ApexPages.StandardController std) {
		accPending = false;
		conPending = false;
		leaPending = false;
		oppPending = false;
		sitPending = false;
		
		terr = [SELECT Name, Country__c, LastModifiedDate FROM Territory__c WHERE Id =:std.getId()];
		lastmodified = terr.LastModifiedDate - (1/24);	
		
		accEstimate = [SELECT Id FROM Account WHERE LastModifiedDate <:lastmodified AND BillingCountry =:terr.Country__c limit 10000].size();
		conEstimate = [SELECT Id FROM Contact WHERE LastModifiedDate <:lastmodified AND MailingCountry =:terr.Country__c limit 10000].size();
		leaEstimate = [SELECT Id FROM Lead WHERE IsConverted = false AND LastModifiedDate <:lastmodified AND Country =:terr.Country__c limit 10000].size();
		oppEstimate = [SELECT Id FROM Opportunity WHERE IsClosed= false AND LastModifiedDate <:lastmodified AND Account.BillingCountry =:terr.Country__c limit 10000].size();
		sitEstimate = [SELECT Id FROM Site__c WHERE LastModifiedDate <:lastmodified AND Country__c =:terr.Country__c limit 10000].size();		
		
	}
	
	public BatchJob getJob() {
		BatchJob bj = new BatchJob();
		List<AsyncApexJob> a = [SELECT ApexClass.Name, Id, Status, JobItemsProcessed, TotalJobItems, CompletedDate, NumberOfErrors FROM AsyncApexJob WHERE CreatedDate = today order by CreatedDate desc limit 1];
		
		if (!a.isEmpty()) {
			if (a.get(0) != null) {
				Double itemsProcessed 	= a.get(0).JobItemsProcessed;
        		Double totalItems 		= a.get(0).TotalJobItems;
				bj.job = a.get(0);
				bj.percentage = 0;
				if (totalItems != 0)
					bj.percentage = ((itemsProcessed  / totalItems) * 100.0).intValue();
			}
		}
		return bj;
	}
	
	public void refreshAccount() {
		TerritoryRefreshBatch refresh = new TerritoryRefreshBatch();
		refresh.query = 'SELECT Id FROM Account WHERE BillingCountry = \'' + terr.Country__c + '\'';
		refresh.objectType = 'Account';
		refresh.territoryName = terr.Name;
		refresh.lastmodified = lastmodified;
		if(!Test.isRunningTest()) ID batchprocessid = Database.executeBatch(refresh);
		accPending = true;
	}
	
	public void refreshContact() {
		TerritoryRefreshBatch refresh = new TerritoryRefreshBatch();
		refresh.query = 'SELECT Id FROM Contact WHERE MailingCountry = \'' + terr.Country__c + '\'';
		refresh.objectType = 'Contact';
		refresh.territoryName = terr.Name;
		refresh.lastmodified = lastmodified;
		if(!Test.isRunningTest()) ID batchprocessid = Database.executeBatch(refresh);
		conPending = true;
	}
	
	public void refreshSite() {
		TerritoryRefreshBatch refresh = new TerritoryRefreshBatch();
		refresh.query = 'SELECT Id FROM Site__c WHERE Country__c = \'' + terr.Country__c + '\'';
		refresh.objectType = 'Site';
		refresh.territoryName = terr.Name;
		refresh.lastmodified = lastmodified;
		if(!Test.isRunningTest()) ID batchprocessid = Database.executeBatch(refresh);
		sitPending = true;
	}
	
	public void refreshLead() {
		TerritoryRefreshBatch refresh = new TerritoryRefreshBatch();
		refresh.query = 'SELECT Id FROM Lead WHERE IsConverted = false AND Country = \'' + terr.Country__c + '\'';
		refresh.objectType = 'Lead';
		refresh.territoryName = terr.Name;
		refresh.lastmodified = lastmodified;
		if(!Test.isRunningTest()) ID batchprocessid = Database.executeBatch(refresh);
		leaPending = true;
	}
	
	public void refreshOpportunity() {
		TerritoryRefreshBatch refresh = new TerritoryRefreshBatch();
		refresh.query = 'SELECT Id FROM Opportunity WHERE IsClosed = false AND Account.BillingCountry = \'' + terr.Country__c + '\'';
		refresh.objectType = 'Opportunity';
		refresh.territoryName = terr.Name;
		refresh.lastmodified = lastmodified;
		if(!Test.isRunningTest()) ID batchprocessid = Database.executeBatch(refresh);
		oppPending = true;
	}
	
	public Class BatchJob {
        public AsyncApexJob job {get; set;}
        public Integer percentage {get; set;}
    }

}