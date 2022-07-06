/********************************************************************
 * bz_PartInUseMessage 
 *
 * Used to display if the part is in use in Blueprint in vf page
 * 
 * 
 * Author: Richard Wood
 * Created: 06-05-2016 
 ********************************************************************/
public with sharing class bz_PartInUseMessage 
{

    public bz_PartInUseMessage(ApexPages.StandardController controller) 
    {
       //Check if there are any records in the INUse Object
      //If there are any then display the message
            
      //integer numberOfRecords = [SELECT COUNT() FROM PartUsedInBlueprint__c where Product2__c = :ApexPages.currentPage().getParameters().get('id')];
      Product2 current = (Product2)controller.getRecord();      
        
      integer numberOfRecords = [SELECT COUNT() FROM PartUsedInBlueprint__c where Product2__c = :current.Id];
                
      if (numberOfRecords > 0)
      {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'This Product is in use by Blueprint. Please do not delete.'));
        hasMessages = 'true';
      }
      else
      {
        hasMessages = 'false';
      }
    }


    public String hasMessages { get; set; }
   
}