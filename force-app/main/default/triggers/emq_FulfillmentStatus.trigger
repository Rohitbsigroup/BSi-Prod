/********************************************************************
 * 
 * Trigger to udpate Open, Scheduled and Cancelled Amount on Opportunity 
 * 
 * Author   : Prasad J N
 * Created  : 01-12-2018
 ********************************************************************/
trigger emq_FulfillmentStatus on Fulfillment_Status__c (after update) {
  emq_FulfillmentStatusTriggerHandler triggerHandler = new emq_FulfillmentStatusTriggerHandler();
  
    if(Trigger.isUpdate && Trigger.isAfter && emq_FulfillmentStatusTriggerHandler.isFirstTime) {
      emq_FulfillmentStatusTriggerHandler.isFirstTime = false;
      triggerHandler.afterUpdate(Trigger.oldMap, Trigger.newMap);
    }
}