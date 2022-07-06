/********************************************************************
 * PropertyValueTrigger
 *
 * Main Trigger that handles all events for PropertyValue.
 * 
 * 
 * Author: Richard Jimenez
 * Created: 06-01-2014
 * Changes: 
 ********************************************************************/
trigger PropertyValueTrigger on PropertyValue__c (after insert, after update) {
    PropertyValueTriggerHandler handler = new PropertyValueTriggerHandler(Trigger.isExecuting, Trigger.size);
    
    // AFTER INSERT
    if(Trigger.isInsert && Trigger.isAfter){
        handler.OnAfterInsert(Trigger.new);
    } 
    // AFTER DELETE
    //else if(Trigger.isDelete && Trigger.isAfter){
    //  handler.OnAfterDelete(Trigger.old, Trigger.oldMap);
    //}
    // AFTER UPDATE
    else if(Trigger.isUpdate && Trigger.isAfter){
        handler.OnAfterUpdate(Trigger.new, Trigger.oldMap);
    }
    // BEFORE INSERT
    //else 
    //if(Trigger.isInsert && Trigger.isBefore){
    //  handler.OnBeforeInsert(Trigger.new);
    //}
    // BEFORE UPDATE
    //else if(Trigger.isUpdate && Trigger.isBefore){
    //  handler.OnBeforeUpdate(Trigger.new, Trigger.oldMap);
    //}
}