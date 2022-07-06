/****************************************************************************************************************************
 * bg_PriceBookBatch.cls
 *
 * @description: Class to deactivate pricebook that have gone past their end date 
 *               
 *
 * @author Richard Cave
 * Created: 23-05-2017 
 * Changes:
 *****************************************************************************************************************************/
global class bg_PriceBookBatch implements Database.Batchable<sObject>, Schedulable 
{
    global Database.QueryLocator start(Database.BatchableContext BC) 
    {
        //query all active pricebooks
        return Database.getQueryLocator('SELECT Id, RecordType.DeveloperName, End_Date__c FROM PriceBook2 where IsActive=true');
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope) 
    {
        List<PriceBook2> pricebooks = scope;

        List<PriceBook2> pricebooksToUpdate = new List<PriceBook2>();

        for(PriceBook2 pb : pricebooks)
        {
            if(pb.End_Date__c < Date.Today() && pb.RecordType.DeveloperName.equals(Label.BG_MSA_DEVELOPER_NAME))
            {
                //deactivate the pricebook as the date has changed.
                pb.IsActive=false;
                pricebooksToUpdate.add(pb);
            }
        }

        if(!pricebooksToUpdate.isEmpty())
        {
            update pricebooksToUpdate;
        }
        
    }
    
    global void finish(Database.BatchableContext BC) 
    {
        
    }

    global void execute(SchedulableContext sc) 
    {
       bg_PriceBookBatch b =new bg_PriceBookBatch();
       Database.executeBatch(b,200);
       
   }

}