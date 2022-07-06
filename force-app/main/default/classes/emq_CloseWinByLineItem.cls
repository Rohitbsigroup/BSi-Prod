/**
*  Author    : Prasad JN
*  Description  : Custom Edit for Opportunity Win CLose by Line Item
*/
public with sharing class emq_CloseWinByLineItem {
    
  public Fulfillment_Status__c item {get; set;}
  
  public Boolean canEdit {get; set;}
  
  public List<SelectOption> statuses {get; set;}
    
    public emq_CloseWinByLineItem(ApexPages.StandardController stdController){
      statuses = new List<SelectOption>();
      
      item = (Fulfillment_Status__c)stdController.getRecord();
      
      item = [SELECT Id, Name, Account__c, Amount__c, Forecast_Date__c, Group_Number__c, Modified_Date__c, Opportunity__c, Product_Group__c, 
            Product_Name__c,  Quotes_Orders__c, Status__c FROM Fulfillment_Status__c WHERE Id = :item.Id];  
            
      if(item.Status__c == 'Open') {
        statuses.add(new SelectOption('Open', 'Open'));
        statuses.add(new SelectOption('Scheduled', 'Scheduled'));
        statuses.add(new SelectOption('Cancelled', 'Cancelled'));
      } else if(item.Status__c == 'Scheduled') {
        statuses.add(new SelectOption('Scheduled', 'Scheduled'));
        statuses.add(new SelectOption('Cancelled', 'Cancelled'));
      } else if(item.Status__c == 'Cancelled') {
        statuses.add(new SelectOption('Cancelled', 'Cancelled'));
      }
      
      canEdit = bg_CustomSettingsUtils.GetPermissionSettings().Can_Edit_Fulfillment_Status__c;
    }
    
    public PageReference save() {
      update item;
      return new ApexPages.StandardController(item).view();
    }
}