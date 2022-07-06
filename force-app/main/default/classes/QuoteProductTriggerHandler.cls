/********************************************************************
 * QuoteProductTriggerHandler
 *
 * Handler class for Quote Product Trigger
 *
 *
 * Author : ADS
 * Created: 02-10-2017
 * Changes:
 ********************************************************************/
public without sharing class QuoteProductTriggerHandler 
{
    
    // constants
    
    private final Boolean isExecuting;
    private final Integer batchSize;
    
    // constructors
    
    public QuoteProductTriggerHandler(final Boolean isExecuting, final Integer batchSize)
    {
        this.isExecuting = isExecuting;
        this.batchSize = batchSize;
    } // constructor
    
    // methods
    
    public void OnAfterDelete(final List<Quote_Product__c> deletedQuoteProducts, final Map<Id, Quote_Product__c> quoteProductMap)
    {
        
        // if removing Quote Products
        
        bg_QuoteUtils.UpdateQuoteRegPathFlags(deletedQuoteProducts);
        
        // Delete quote signature records when a quote product is deleted
        List<QuoteSignature__c> signatureList = [SELECT Id FROM QuoteSignature__c WHERE QuoteProduct__c = :quoteProductMap.keySet()];
        delete signatureList;
    } // OnAfterDelete
    
    public void OnAfterUndelete(final List<Quote_Product__c> restoredQuoteProducts)
    {
        
        // if adding Quote Products

        bg_QuoteUtils.UpdateQuoteRegPathFlags(restoredQuoteProducts);
    } // OnAfterUndelete

	
	// OnAfterInsert
	public void OnAfterInsert(final List<Quote_Product__c> newQuoteProducts) {
		List<QuoteSignature__c> signatureList = new List<QuoteSignature__c>();
		for (Quote_Product__c quoteProduct : newQuoteProducts) {
			if(quoteProduct.Project__c != null) {
				Project__c project = [SELECT QuoteSignature__c FROM Project__c WHERE Id = :quoteProduct.Project__c];
				if(project.QuoteSignature__c != null) {
					List<String> signatures = project.QuoteSignature__c.split(';');
					
					for(String s:signatures) {
						if(String.isNotBlank(s)) {						
							QuoteSignature__c signature = new QuoteSignature__c();
							signature.QuoteProduct__c = quoteProduct.Id;
							signature.Signature__c = s;
							signatureList.add(signature);
						}
					}
				}
			}
		}
		
		if(signatureList.size() > 0)
			insert signatureList;
	}

    public void OnAfterUpdate(final List<Quote_Product__c> updateQuoteProducts, final Map<Id, Quote_Product__c> oldQuoteProductMap)
    {
        final Set<Id> productIds = new Set<Id>(); // a set of product Ids referenced in the quote products
        
        final List<Quote_Product__c> quoteProductsWithRegistrationPathChange = new List<Quote_Product__c>();
        final Set<Id> quoteProductIdsWithGroupNumberChanges = new Set<Id>();
        
        for (Quote_Product__c updateQuoteProduct : updateQuoteProducts)
        {
            Quote_Product__c oldQuoteProduct = oldQuoteProductMap.get(updateQuoteProduct.Id);
            
            // if the registration path has changed
            
            if (updateQuoteProduct.Registration_Path__c != oldQuoteProduct.Registration_Path__c)
            {
                quoteProductsWithRegistrationPathChange.add(updateQuoteProduct);
            }
            
            // if the group number has changed when it is a project, need to match it back up with its phase
            
            if (updateQuoteProduct.GroupNumber__c != oldQuoteProduct.GroupNumber__c &&
                !updateQuoteProduct.Is_Project_Phase__c &&
                null != updateQuoteProduct.Project__c)
            {
                quoteProductIdsWithGroupNumberChanges.add(updateQuoteProduct.Id);
            }
                        
            // add to the set of products
            
            if (null != updateQuoteProduct.Product_Name__c)
            {
                productIds.add(updateQuoteProduct.Product_Name__c);                
            }
                        
            if (null != oldQuoteProduct.Product_Name__c)
            {
                productIds.add(oldQuoteProduct.Product_Name__c);
            }
            
        }
        
        Set<Id> mainProductIds = new Set<Id>(); // products with product type = 'Main'
        
        if (!productIds.isEmpty())
        {
            mainProductIds = new Map<Id, Product__c>(bg_ProductUtils.GetProductByIds(productIds)).keySet();
        }
        
        final Map<Id, Set<Decimal>> postConfigurationGroupNumbersByQuote = new Map<Id, Set<Decimal>>(); // group numbers with post configuration changes by quote
        final Set<Decimal> uniquePostConfigurationGroupNumbers = new Set<Decimal>(); // unique group numbers with post configuration changes
                
        for (Quote_Product__c updateQuoteProduct : updateQuoteProducts)
        {
            final Quote_Product__c oldQuoteProduct = oldQuoteProductMap.get(updateQuoteProduct.Id);
            
            // is it post configuration?
            
            if (oldQuoteProduct.Configuration_Complete__c)
            {
                
                // if the controlling location has changed or
                // if the registration path has changed or
                // if the risk level has changed or
                // if the sampling has changed

                if (mainProductIds.contains(oldQuoteProduct.Product_Name__c) != mainProductIds.contains(updateQuoteProduct.Product_Name__c) ||
                   updateQuoteProduct.Registration_Path__c != oldQuoteProduct.Registration_Path__c ||
                   updateQuoteProduct.Risk_Level__c != oldQuoteProduct.Risk_Level__c ||
                   updateQuoteProduct.Sampling_Applied__c != oldQuoteProduct.Sampling_Applied__c)
                {
                    
                    // the list of unique group numbers
                    
                    uniquePostConfigurationGroupNumbers.add(updateQuoteProduct.GroupNumber__c);
                    
                    // the group numbers for each quote
                    
                    if (!postConfigurationGroupNumbersByQuote.containsKey(updateQuoteProduct.Quote_Ref__c))
                    {
                        final Set<Decimal> groupNumbers = new Set<Decimal>();
                        groupNumbers.add(updateQuoteProduct.GroupNumber__c);
                        postConfigurationGroupNumbersByQuote.put(updateQuoteProduct.Quote_Ref__c, groupNumbers);
                    }
                    else
                    {
                        postConfigurationGroupNumbersByQuote.get(updateQuoteProduct.Quote_Ref__c).add(updateQuoteProduct.GroupNumber__c);
                    }
                    
                }
                
            }
            
        }
            
        if (!quoteProductsWithRegistrationPathChange.isEmpty())
        {
            bg_QuoteUtils.UpdateQuoteRegPathFlags(quoteProductsWithRegistrationPathChange);        
        }
        
        if (!quoteProductIdsWithGroupNumberChanges.isEmpty())
        {
            bg_QuoteProductUtils.MatchPhaseWithProjectGroupNumber(quoteProductIdsWithGroupNumberChanges);
        }
        
        if (!postConfigurationGroupNumbersByQuote.isEmpty())
        {                 
            final Map<Id, Quote_Product__c> quoteProductsToUpdate = new Map<Id, Quote_Product__c>();
            
            for (Quote_Product__c quoteProduct : [SELECT Id, Quote_Ref__c, GroupNumber__c
                                                  FROM Quote_Product__c
                                                  WHERE Quote_Ref__c IN :postConfigurationGroupNumbersByQuote.keySet()
                                                  AND GroupNumber__c IN :uniquePostConfigurationGroupNumbers
                                                  AND Configuration_Complete__c = true])
            {
                
                if (postConfigurationGroupNumbersByQuote.containsKey(quoteProduct.Quote_Ref__c))
                {
                    final Set<Decimal> groupNumbersForQuote = postConfigurationGroupNumbersByQuote.get(quoteProduct.Quote_Ref__c);
                    
                    if (groupNumbersForQuote.contains(quoteProduct.GroupNumber__c))
                    {
                        final Quote_Product__c quoteProductToUpdate = new Quote_Product__c();
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
                
                //@todo: do the DML statements need to be in a Savepoint or does this need SaveResult error handling?
                
                final System.Savepoint theSavepoint = Database.setSavepoint();
                
                try
                {

                    // remove quote parts associated with all quote products in the same group number for every quote, needs batch Apex to handle large deletions?
                    
                    delete [SELECT Id FROM Quote_Part__c WHERE Quote_Product__c IN :quoteProductsToUpdate.keySet()];
                                        
                    // resets the configuration for every quote product with the same group number for every quote
                    
                    update quoteProductsToUpdate.values();
                }
                catch (System.DmlException e)
                {
                    System.debug(System.LoggingLevel.ERROR, e.getMessage());                    
                    Database.rollback(theSavepoint);
                    throw e;
                }
                
            }
            
        }
        
    } // OnAfterUpdate
                
} // QuoteProductTriggerHandler

// file