trigger EnrollmentTriggers on Enrollment__c (before insert, after insert, before update, after update) {

    // Instantiate handler
    EnrollmentTrigHandler handler = new EnrollmentTrigHandler(Trigger.isExecuting, Trigger.size);

    // Before insert 
    if(Trigger.isInsert && Trigger.isBefore){
        handler.OnBeforeInsert(Trigger.new);
    }
    
    // After insert
    if(Trigger.isInsert && Trigger.isAfter){
        handler.OnAfterInsert(Trigger.new, Trigger.newMap);
    }
 
    // Before update
    if(Trigger.isUpdate && Trigger.isBefore){
        handler.OnBeforeUpdate(Trigger.oldMap, Trigger.newMap);
    }
 
    // After update
    if(Trigger.isUpdate && Trigger.isAfter){
        handler.OnAfterUpdate(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
        handler.manageMimeoKeyAssignment(Trigger.oldMap, Trigger.newMap);
        handler.manageMimeoRevokeKey(Trigger.oldMap, Trigger.newMap);
    }
 
    /*
    if(trigger.IsAfter){
        //TrainingSurveyTriggerHandler.Enrollment_AVG_Cal(trigger.new);
    }
    */
     
    // Before delete
    //else if(Trigger.isDelete && Trigger.isBefore)
    //{
    //  handler.OnBeforeDelete(Trigger.old, Trigger.oldMap);
    //}
    
    // After delete
    //else if(Trigger.isDelete && Trigger.isAfter)
    //{
    //handler.OnAfterDelete(Trigger.old, Trigger.oldMap);
    //}
 
    // After undelete
    //else if(Trigger.isUnDelete)
    //{
    //  handler.OnUndelete(Trigger.new); 
    //}
}