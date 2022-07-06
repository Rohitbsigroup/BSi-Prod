/*
* Mimeo Document Trigger
* Created: PC K2 (June 2020)
*
* changelog 
*/

trigger MimeoDocumentTrigger on Mimeo_Document__c (after insert, after update) {

    //trigger handler
    MimeoDocumentTriggerHandler handler = MimeoDocumentTriggerHandler.getInstance();

    if(Trigger.isInsert){
        //handle Mimeo Document
        handler.handleMimeoDocuments(null, Trigger.newMap);
    }

    if(Trigger.isUpdate){
        //handle Mimeo Document
        handler.handleMimeoDocuments(Trigger.oldMap, Trigger.newMap);
    }

}