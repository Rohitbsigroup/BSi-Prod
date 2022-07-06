/**
*  Author    : Prasad JN
*  Description  : To display only the rolled up fulfillment status for the opportunity
*/
public with sharing class emq_FulfillmentStatusRelatedList {
    
    public List<Fulfillment_Status__c> fsList { get; set; }
    
    public emq_FulfillmentStatusRelatedList(ApexPages.StandardController controller) {
      Id id = controller.getRecord().id;
      fsList = [SELECT Id, Product_Type__c, Product_Name__c, Registration_Path__c, ScheduleCycle__c, Phase__c, FeeType__c, Amount__c, Status__c, Forecast_Date__c
       FROM Fulfillment_Status__c WHERE Opportunity__c = :id AND RecordType.Name = 'Fulfillment Status'];
    }
    
    public PageReference edit() {
      String id = Apexpages.currentpage().getParameters().get('fsid');
      PageReference pageRef = new PageReference('/' + id + '/e?retURL=' + Apexpages.currentpage().getParameters().get('id'));  

        return pageRef;  
      
    }
}