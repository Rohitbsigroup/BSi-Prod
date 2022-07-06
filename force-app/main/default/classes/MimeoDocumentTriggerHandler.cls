/*
* Mimeo Document Trigger Handler
* Created: PC K2 (June 2020)
*
* changelog 
*/

public with sharing class MimeoDocumentTriggerHandler {

    private static MimeoDocumentTriggerHandler instance;

    public static Boolean isHandleMimeoDocumentsFirstRun = true;

    public static MimeoDocumentTriggerHandler getInstance(){
        if(instance == null) instance = new MimeoDocumentTriggerHandler();
        return instance;
    }

    //handle document change
    public void handleMimeoDocuments(Map<Id, Mimeo_Document__c> oldMap, Map<Id, Mimeo_Document__c> newMap){
        System.debug('### MimeoDocumentTriggerHandler.handleMimeoDocuments');
        
        if(isHandleMimeoDocumentsFirstRun) isHandleMimeoDocumentsFirstRun = false;
        else return;
        
        for(Id docId : newMap.keySet()){
            if(oldMap == null || (oldMap != null && (newMap.get(docId).Name != oldMap.get(docId).Name || newMap.get(docId).Active__c != oldMap.get(docId).Active__c))){
                Mimeo_Document__c doc = newMap.get(docId);
                updateMimeoDocument(doc.Id, doc.Course_Country__c, doc.Name);
            }
        }
    }

    //Mimeo findDocuments
    @future (callout=true)
    public static void updateMimeoDocument(String documentId, String countryCode, String documentName){
        System.debug('### MimeoDocumentTriggerHandler.updateMimeoDocument: ' + documentId + ', ' + countryCode + ', ' + documentName);
        if(String.isBlank(documentId) || String.isBlank(countryCode)){
            System.debug('### MimeoDocumentTriggerHandler.updateMimeoDocument error - documentId, countryCode cannot be empty');
            return;
        }

        try{
            MimeoAPI mAPI = new MimeoAPI(countryCode);
            MimeoAPI.FindDocumentsResponse fdr = mAPI.findDocuments(documentName);
            String assetId = fdr.Data.get(0).DigitalAssetId;
            
            MimeoDocumentTriggerHandler.isHandleMimeoDocumentsFirstRun = false;
            System.debug('### add Asset Id for Mimeo Document: ' + documentId + ', ' + assetId);
            update new Mimeo_Document__c(Id = documentId, Asset_Id__c = assetId, Error__c = null);
        }catch(Exception e){
            System.debug('### add Asset Id error: ' + e.getMessage());
            update new Mimeo_Document__c(Id = documentId, Asset_Id__c = null, Error__c = e.getMessage());
        }
    }
}