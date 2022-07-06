/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Description:  Batch Apex to refresh Territories. 
*
* Changes: 		ASD BG - Added !Test.isRunningTest() to send email to fix unit tests in sandboxes       
**/
global class TerritoryRefreshBatch implements Database.Batchable<sObject>{
	
	public String 		query;
	public String 		objectType;
	public String		territoryName;
	public DateTime		lastmodified;
	
	global Database.querylocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query + ' AND LastModifiedDate < :lastmodified');
	}
	
	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		update scope;
	}
	
	global void finish(Database.BatchableContext BC){
		AsyncApexJob a 	= [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
      						FROM AsyncApexJob 
      						WHERE Id =:BC.getJobId()];
		
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		
		mail.setToAddresses(new String[] {'bsi.sfdc@brightgen.com'});
		mail.setSenderDisplayName('Territory Refresh');
		mail.setSubject('Refresh Completed for ' + territoryName + ' on ' + objectType);
		mail.setPlainTextBody('Batch Process has completed for ' + objectType + ' \nTotal jobs: ' + a.TotalJobItems + ' \nFailures: ' + a.NumberOfErrors);
		
		if(!Test.isRunningTest())
		{
			Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
		}
	}
}