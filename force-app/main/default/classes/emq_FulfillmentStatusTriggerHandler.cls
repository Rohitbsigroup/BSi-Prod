/********************************************************************
 * 
 * Trigger to udpate Open, Scheduled and Cancelled Amount on Opportunity 
 * 
 * Author   : Prasad J N
 * Created  : 01-07-2019
 ********************************************************************/
public with sharing class emq_FulfillmentStatusTriggerHandler {
    public static Boolean isFirstTime = true;
    
    public void afterUpdate(Map<Id, Fulfillment_Status__c> oldMap, Map<Id, Fulfillment_Status__c> newMap) {
      for(Fulfillment_Status__c fs:newMap.values()){
        //if(fs.Status__c != oldMap.get(fs.Id).Status__c) {
          Opportunity opp = [SELECT Id, Open_Amount__c, Scheduled_Amount__c, Cancelled_Amount__c FROM Opportunity WHERE Id = :fs.Opportunity__c];
          
          List<Fulfillment_Status__c> fsList = [SELECT Id, Status__c , Amount__c FROM Fulfillment_Status__c WHERE Opportunity__c = :fs.Opportunity__c AND RecordType.Name = 'Fulfillment Status'];
          opp.Open_Amount__c = 0;
        opp.Scheduled_Amount__c = 0;
        opp.Cancelled_Amount__c = 0;
        
          for(Fulfillment_Status__c opFs:fsList) {
            if(opFs.Status__c == 'Open')
            opp.Open_Amount__c = opp.Open_Amount__c + opFs.Amount__c;
          else if(opFs.Status__c == 'Scheduled')
            opp.Scheduled_Amount__c = opp.Scheduled_Amount__c + opFs.Amount__c;
          else if(opFs.Status__c == 'Cancelled')
            opp.Cancelled_Amount__c = opp.Cancelled_Amount__c + opFs.Amount__c;
          }
          System.debug('Test----Test');
          //Query and update all Fulfillment Status Line Items
          fsList = [SELECT Id, Status__c, Forecast_Date__c FROM Fulfillment_Status__c WHERE Opportunity__c = :fs.Opportunity__c AND RecordType.Name = 'Fulfillment Status Line Items' AND Group_Number__c = :fs.Group_Number__c];
          System.debug(fsList .size()  + '----Test');
          for(Fulfillment_Status__c opFs:fsList) {
            opFs.Forecast_Date__c = fs.Forecast_Date__c;
            opFs.Status__c = fs.Status__c;
            System.debug(opFs.Forecast_Date__c  + '----Test');
          }
          
          update fsList;        
          update opp;
        //}
      }  
    }
}