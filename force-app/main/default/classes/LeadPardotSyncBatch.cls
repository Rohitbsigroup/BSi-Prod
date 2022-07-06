/********************************************************************
* LeadPardotSyncBatch
*
* Batch class for to refresh Lead
*
* Author: Nebula - Robert Bedding
* Created: 08-08-2016 
********************************************************************/
global class LeadPardotSyncBatch implements Database.Batchable<sObject>{
  
  global List<Lead> start(Database.BatchableContext BC){
    return [
      SELECT Id, Create_Lead__c, Pardot_Trigger_Source_Sub_Category__c 
      FROM Lead 
      WHERE Create_Lead__c = true
    ];
  }
  
  global void execute(Database.BatchableContext BC, List<Lead> scope){
    for (Lead l : scope) {
      l.Create_Lead__c = false;
      l.Pardot_Trigger_Source_Sub_Category__c = 'NULL';  // Setting this to NULL as requested on task: 11092845
    }
    update scope;
  }
  
  global void finish(Database.BatchableContext BC){
  }
  
}