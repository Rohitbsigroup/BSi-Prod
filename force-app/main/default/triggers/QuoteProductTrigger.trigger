/********************************************************************
 * QuoteProductTrigger
 *
 * Trigger that handles all events for Quote Products
 * 
 * Author : ?
 * Created: ?
 * Changes: ADS 30-09-2017 - Added UAT Extension - "Changes to grid post configuration"
 *        : ADS 02-10-2017 - Refactored to use trigger handler pattern consistent with other triggers
 ********************************************************************/
trigger QuoteProductTrigger on Quote_Product__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) 
{
    
    // refactoring to trigger handler pattern used across BSI Group for consistency
    QuoteProductTriggerHandler handler = new QuoteProductTriggerHandler(Trigger.isExecuting, Trigger.size);
    
    if (Trigger.isUpdate &&
       Trigger.isAfter)
    {
        handler.OnAfterUpdate(Trigger.new, Trigger.oldMap);
    }
    else if (Trigger.isDelete &&
            Trigger.isAfter)
    {
        handler.OnAfterDelete(Trigger.old, Trigger.oldMap);
    }
    else if (Trigger.isUndelete &&
            Trigger.isAfter)
    {
        handler.OnAfterUndelete(Trigger.old);
    }
    else if (Trigger.isInsert &&
            Trigger.isAfter)
    {
        handler.OnAfterInsert(Trigger.new);
    }

/* code refactored to QuoteProductTriggerHandler   
    Set<Id> quoteIds = new Set<Id>();
    Set<Id> qpIds = new Set<Id>();
    
    // UAT Extension - "Changes to grid post configuration" - start

    Map<Id, Set<Decimal>> postConfigurationGroupNumbersByQuote = new Map<Id, Set<Decimal>>(); // Group Numbers with post configuration changes by Quote
    Set<Decimal> uniquePostConfigurationGroupNumbers = new Set<Decimal>(); // unique Group Numbers with post configuration changes
    Set<Id> mainProductIds = new Set<Id>(); // Products with Product Type = 'Main'
    
    if (Trigger.isUpdate &&
       Trigger.isAfter)
    {
        Set<Id> productIds = new Set<Id>(); // a set of Product Ids referenced in the Quote Products
        
        for (Quote_Product__c qp: Trigger.New)
        {
            
            if (null != qp.Product_Name__c)
            {
                productIds.add(qp.Product_Name__c);                
            }
            
            Quote_Product__c oldQuoteProduct = Trigger.OldMap.get(qp.Id);
            
            if (null != oldQuoteProduct.Product_Name__c)
            {
                productIds.add(oldQuoteProduct.Product_Name__c);
            }
            
        }
                
        mainProductIds = new Map<Id, Product__c>(bg_ProductUtils.GetProductByIds(productIds)).keySet();
    }

    // UAT Extension - "Changes to grid post configuration" - finish

    for (Quote_Product__c qp : Trigger.isDelete ? Trigger.Old : Trigger.New)
    {
        // If adding or removing this product or the reg path has changed
        if (!Trigger.isUpdate ||
           Trigger.NewMap.get(qp.Id).Registration_Path__c != Trigger.OldMap.get(qp.Id).Registration_Path__c)
        {
            quoteIds.add(qp.Quote_Ref__c);
        }
        
        // UAT Extension - "Changes to grid post configuration" - start
        
        if (Trigger.isUpdate &&
           Trigger.isAfter)
        {   
            Quote_Product__c oldQuoteProduct = Trigger.OldMap.get(qp.Id);
            
            // is it post configuration?
            
            if (oldQuoteProduct.Configuration_Complete__c)
            {
                Quote_Product__c newQuoteProduct = Trigger.NewMap.get(qp.Id);
                
                // if the controlling location has changed or
                // if the registration path has changed or
                // if the risk level has changed or
                // if the sampling has changed
                                                
                if (mainProductIds.contains(oldQuoteProduct.Product_Name__c) != mainProductIds.contains(newQuoteProduct.Product_Name__c) ||
                   newQuoteProduct.Registration_Path__c != oldQuoteProduct.Registration_Path__c ||
                   newQuoteProduct.Risk_Level__c != oldQuoteProduct.Risk_Level__c ||
                   newQuoteProduct.Sampling_Applied__c != oldQuoteProduct.Sampling_Applied__c)
                {
                    
                    // for the list of unique Group Numbers
                    uniquePostConfigurationGroupNumbers.add(qp.GroupNumber__c);
                    
                    // for the Group Numbers for each Quote
                    if (!postConfigurationGroupNumbersByQuote.containsKey(qp.Quote_Ref__c))
                    {
                        Set<Decimal> groupNumbers = new Set<Decimal>();
                        groupNumbers.add(qp.GroupNumber__c);
                        postConfigurationGroupNumbersByQuote.put(qp.Quote_Ref__c, groupNumbers);
                    }
                    else
                    {
                        postConfigurationGroupNumbersByQuote.get(qp.Quote_Ref__c).add(qp.GroupNumber__c);
                    }
                    
                }
                
            }
            
        }
                
        // UAT Extension - "Changes to grid post configuration" - finish

        if(Trigger.isUpdate &&
          Trigger.isAfter)
        {
            //group number has changed when it is a project and therefore need to match it back up with its phase
            if(Trigger.OldMap.get(qp.Id).GroupNumber__c <> Trigger.NewMap.get(qp.Id).GroupNumber__c 
                && !qp.Is_Project_Phase__c && qp.Project__c!=null)
            {
                qpIds.add(qp.Id);

            }
        }
    }
    
    if (!quoteIds.isEmpty())
    {
        bg_QuoteUtils.UpdateQuoteRegPathFlags(quoteIds);        
    }

    if(!qpIds.isEmpty())
    {
        bg_QuoteProductUtils.MatchPhaseWithProjectGroupNumber(qpIds);
    }

    // UAT Extension - "Changes to grid post configuration" - start
 
    if (!postConfigurationGroupNumbersByQuote.isEmpty())
    {
        
        //@todo: push down to Apex utility?
        Map<Id, Quote_Product__c> quoteProductsToUpdate = new Map<Id, Quote_Product__c>();
        
        for (Quote_Product__c quoteProduct : [SELECT Id, Quote_Ref__c, GroupNumber__c
                                              FROM Quote_Product__c
                                              WHERE Quote_Ref__c IN :postConfigurationGroupNumbersByQuote.keySet()
                                              AND GroupNumber__c IN :uniquePostConfigurationGroupNumbers
                                              AND Configuration_Complete__c = true])
        {
            
            if (postConfigurationGroupNumbersByQuote.containsKey(quoteProduct.Quote_Ref__c))
            {
                Set<Decimal> groupNumbersForQuote = postConfigurationGroupNumbersByQuote.get(quoteProduct.Quote_Ref__c);
                
                if (groupNumbersForQuote.contains(quoteProduct.GroupNumber__c))
                {
                    Quote_Product__c quoteProductToUpdate = new Quote_Product__c();
                    quoteProductToUpdate.Id = quoteProduct.Id;
                    quoteProductToUpdate.Configuration_Complete__c = false;
                    quoteProductsToUpdate.put(quoteProductToUpdate.Id, quoteProductToUpdate);
                }
                
            }
            else
            {
                
                // this should not be possible as the criteria on the SOQL includes the keys
                System.debug(System.LoggingLevel.ERROR, quoteProduct.Quote_Ref__c + ' not found in post configuration Group Numbers for each Quote');
            }
            
        }
        
        if (!quoteProductsToUpdate.isEmpty())
        {
            
            //@todo: do the DML's need to be in a Savepoint or does this need SaveResult error handling?
            System.Savepoint theSavepoint = Database.setSavepoint();
            
            try
            {
                
                // resets the configuration for every Quote Product with the same Group Number for every Quote
                update quoteProductsToUpdate.values();

                // remove Quote Parts associated with all Quote Products in the same Group Number for every Quote, needs batch Apex to handle large deletions?
                delete [SELECT Id FROM Quote_Part__c WHERE Quote_Product__c IN :quoteProductsToUpdate.keySet()];
                
            }
            catch (System.DmlException e)
            {
                Database.rollback(theSavepoint);
            }
            
        }

    }
    
    // UAT Extension - "Changes to grid post configuration" - finish

*/
    
}