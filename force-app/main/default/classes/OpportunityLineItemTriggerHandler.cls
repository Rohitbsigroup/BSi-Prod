/**
*
* Author:       Carmine Barbuto
* Company:      Tquila
* Date:         07/12/2011
* Description:  Handler class for OpportunityLineItem Trigger.
*       
**/
public without sharing class OpportunityLineItemTriggerHandler {
    
    private Boolean lt_isExecuting = false;
    private Integer BatchSize = 0;
    
    //Used as a flag during sync from quote
    public static Boolean syncOppLines = false;
    
    // CONSTRUCTOR
    public OpportunityLineItemTriggerHandler(Boolean isExecuting, Integer size){
        lt_isExecuting = isExecuting;
        BatchSize = size;
    }
    
    // AFTER INSERT
    public void OnAfterInsert(OpportunityLineItem[] newOptyLines){
        // NO LONGER USED
        //familyTypes(newOptyLines,false);
    }
    
    // AFTER UPDATE
    public void onAfterUpdate(Map<Id,OpportunityLineItem> oldMap, Map<Id,OpportunityLineItem> newMap){
        Set<Id> enrollmentIdsToUpdate = new Set<Id>();

        for(OpportunityLineItem oli : newMap.values()){
            //OLI is linked, re-linked or de-linked from Enrollment
            if(oli.Enrollment__c != oldMap.get(oli.Id).Enrollment__c){
                enrollmentIdsToUpdate.add(oli.Enrollment__c);
            }
            //OLI is cancelled - JS 20190320 Added '&& oli.Enrollment__c != null' below to prevent error with cancelling other opportunities
            if(oli.Item_Cancelled__c != oldMap.get(oli.Id).Item_Cancelled__c && oli.Enrollment__c != null){
                enrollmentIdsToUpdate.add(oli.Enrollment__c);
            }
        }
        if(!enrollmentIdsToUpdate.isEmpty()) EnrollmentUtils.calculateSalesPrice(enrollmentIdsToUpdate);
        
        updateFulfillmentStatusRecord(newMap.values());
    }

    // AFTER DELETE
    public void OnAfterDelete(OpportunityLineItem[] deletedOptyLines, Map<ID, OpportunityLineItem> optySiteMap){
        // NO LONGER USED
        //familyTypes(deletedOptyLines,true);
    }
    
    // BEFORE DELETE
    public void OnBeforeDelete(OpportunityLineItem[] deletedOptyLines){
        for(OpportunityLineItem oli: deletedOptyLines){
            if(!oli.Opportunity.Sync_in_Progress__c){
                //oli.addError('You do not have permission to delete this record');
            }
        }
    }
    
    // -------- BUSINESS LOGIC ----------
    
    // Update the family summary field on Opportunity based on the actual line items families
    public void familyTypes(OpportunityLineItem[] optyLines, Boolean isDelete) {
        
        // Get the family for each opty line
        Map<String,Set<String>> familyMap = new Map<String,Set<String>>();
        //Set<Id> oldLines
        for (OpportunityLineItem ol :optyLines) {
            if (ol.ShortName__c != null)
                if (familyMap.containsKey(ol.OpportunityId)) {
                    familyMap.get(ol.OpportunityId).add(ol.ShortName__c);
                } else {
                    Set<String> f = new Set<String>();
                    f.add(ol.ShortName__c);
                    familyMap.put(ol.OpportunityId,f);
                }
        }
        
        List<Opportunity> optys;
        
        // DELETE CASE
        if (isDelete) {
            // Get the family for each old-existing opty line
            List<OpportunityLineItem> oldlines = [SELECT Id, ShortName__c, OpportunityId FROM OpportunityLineItem 
                                                 WHERE OpportunityId IN :familyMap.keySet() 
                                                 AND Id NOT IN :optyLines];
            optys = [SELECT Id, ProductFamily__c FROM Opportunity WHERE Id IN :familyMap.keySet()];
            Map<String,Set<String>> oldfamilyMap = new Map<String,Set<String>>();
            for (OpportunityLineItem ol :oldLines) {
                if (ol.ShortName__c != null)
                    if (oldfamilyMap.containsKey(ol.OpportunityId)) {
                        oldfamilyMap.get(ol.OpportunityId).add(ol.ShortName__c);
                    } else {
                        Set<String> f = new Set<String>();
                        f.add(ol.ShortName__c);
                        oldfamilyMap.put(ol.OpportunityId,f);
                    }
            }
            
            for (Opportunity opty : optys) {
                for (String family : familyMap.get(opty.Id)) {
                    // Check if there are other lines with the same family
                    // If not, then erase the family from the summary
                    // If you are deleting all the lines then reset summary
                    if (oldfamilyMap.get(opty.Id) == null || !oldfamilyMap.get(opty.Id).contains(family)) {
                        // Check if it's not empty
                        if (opty.ProductFamily__c != null) { 
                            // Check if is the last value in the summary (no ";")
                            if (opty.ProductFamily__c.contains(family + ';')) {
                                opty.ProductFamily__c = opty.ProductFamily__c.replace(family+';','');
                            } else {
                                opty.ProductFamily__c = opty.ProductFamily__c.replace(family,'');
                            }
                        }
                    }
                }
            }                     
        
        } 
        // INSERT CASE
        else {
            // Add the new familie to the optys
            optys = [SELECT Id, ProductFamily__c FROM Opportunity WHERE Id IN :familyMap.keySet()];
            for (Opportunity opty : optys) {
                // Check if the family is already in the summary
                for (String family : familyMap.get(opty.Id)) {
                    if (opty.ProductFamily__c != null) {
                        if (!String.valueOf(opty.ProductFamily__c).contains(family)) {
                            opty.ProductFamily__c = opty.ProductFamily__c + ';' + family;
                        }
                    } else {
                        opty.ProductFamily__c = family;
                    } 
                }
            }
        }
        update optys;
            
    }
    
    public void updateFulfillmentStatusRecord(List<opportunityLineItem> lineItems){
        
        // Get all opportunity line item ids and load the Sync In Progress column
        List<Id> lineItemIds = new List<Id>(new Map<Id, opportunityLineItem>(lineItems).keySet());
        lineItems = [SELECT Id, OpportunityId, Opportunity.Sync_in_Progress__c FROM OpportunityLineItem WHERE Id = :lineItemIds];

        Set<String> oliIds = new Set<String>();        
        for(OpportunityLineItem oli:lineItems) {
            // If sync in progress do not do anything for fulfillment status
            if(!oli.Opportunity.Sync_in_Progress__c)
                oliIds.add(oli.Id);
        }
        
        if(oliIds.size() == 0)
            return;
        
        List<OpportunityLineItem> oppLineItems = [SELECT SMONumber__c, SMO_Cancelled__c, TotalPrice, Product_Group__c, Product_Name__r.Main_Product_Name__c, 
            Opportunity.CurrencyISOCode, Quote_Part__r.Quote_Product_Group_Number__c, LastModifiedDate
            FROM OpportunityLineItem WHERE Id = :oliIds];
        
        Set<String> oppIds = new Set<String>();
        for(OpportunityLineItem oli:oppLineItems) {
            List<Fulfillment_Status__c> fsItems = [SELECT Id FROM Fulfillment_Status__c WHERE Opportunity__c = :oli.Opportunity.Id 
                    and Group_Number__c = :oli.Quote_Part__r.Quote_Product_Group_Number__c AND RecordType.Name = 'Fulfillment Status'];
                    
            if(fsItems != null && fsItems.size() > 0){
                oppIds.add(oli.Opportunity.Id);
                for(Fulfillment_Status__c fs:fsItems) {
                    fs.Modified_Date__c = oli.LastModifiedDate;
                    
                    if(oli.SMONumber__c != null && !oli.SMO_Cancelled__c)
                        fs.Status__c = 'Scheduled';
                    else if(oli.SMO_Cancelled__c)
                        fs.Status__c = 'Cancelled';
                }
            }
            
            update fsItems; 
        }
        
        /*Map<Id, Opportunity> oppItems = new Map<Id, Opportunity>([SELECT Id, Open_Amount__c, Scheduled_Amount__c, Cancelled_Amount__c FROM Opportunity WHERE Id = :oppIds]);
        for(Id id:oppItems.keySet()){
            oppItems.get(id).Open_Amount__c = 0;
            oppItems.get(id).Scheduled_Amount__c = 0;
            oppItems.get(id).Cancelled_Amount__c = 0;
        }
        
        List<Fulfillment_Status__c> fsItems = [SELECT Id, Amount__c, Status__c, Opportunity__c FROM Fulfillment_Status__c WHERE Opportunity__c = :oppIds AND RecordType.Name = 'Fulfillment Status'];
        
        for(Fulfillment_Status__c fs:fsItems) {
            if(fs.Status__c == 'Open')
                oppItems.get(fs.Opportunity__c).Open_Amount__c = oppItems.get(fs.Opportunity__c).Open_Amount__c + fs.Amount__c;
            else if(fs.Status__c == 'Scheduled')
                oppItems.get(fs.Opportunity__c).Scheduled_Amount__c = oppItems.get(fs.Opportunity__c).Scheduled_Amount__c + fs.Amount__c;
            else if(fs.Status__c == 'Cancelled')
                oppItems.get(fs.Opportunity__c).Cancelled_Amount__c = oppItems.get(fs.Opportunity__c).Cancelled_Amount__c + fs.Amount__c;
        }
        
        update oppItems.values();*/
    }
}