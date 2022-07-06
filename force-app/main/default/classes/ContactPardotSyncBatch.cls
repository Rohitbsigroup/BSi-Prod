/********************************************************************
* ContactPardotSyncBatch
*
* Batch class for to refresh Contact
*
* Author: Nebula - Robert Bedding
* Created: 08-08-2016 
********************************************************************/
global class ContactPardotSyncBatch implements Database.Batchable<sObject>{
  
  global List<Contact> start(Database.BatchableContext BC) {
    return [
      SELECT Id, Create_Lead__c, Pardot_Trigger_Source_Sub_Category__c 
      FROM Contact 
      WHERE Create_Lead__c = true
    ];
  }
  
  global void execute(Database.BatchableContext BC, List<Contact> scope) {
    for(Contact c : scope) {
      c.Create_Lead__c = false;
      c.Pardot_Trigger_Source_Sub_Category__c = 'NULL';  // Setting this to NULL as requested on task: 11092845
    }
    update scope;
  }
  
  global void finish(Database.BatchableContext BC){
  }

}