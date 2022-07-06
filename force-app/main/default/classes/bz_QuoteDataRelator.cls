public with sharing class bz_QuoteDataRelator {
	
	public static Boolean AlreadyProcessed = false;
	
	@future
	public static void RelateProductToProperty(Set<Id> p2pList)
	{
		AlreadyProcessed = true;
		
		// system.debug('BZ: RelateProdToProp Running.');
		//Get the list of ProductToProperties to use the property guid to look up sfid for the property and the product
		Map<Id, ProductToProperty__c> ProdToPropMap = new Map<Id, ProductToProperty__c>( 
			[SELECT Id, Guid__c, PropertyGuid__c, ProductGuid__c, Product__c, Property__c FROM ProductToProperty__c WHERE Id IN :p2pList]
		);
		
		// system.debug(ProdToPropMap);
		
		set<string> propertyGuidSet = new set<string>();	
		set<string> productGuidSet = new set<string>();	
		
		//Get the list of guids
		for(ProductToProperty__c p2p : ProdToPropMap.values())
		{
			// system.debug('BZ: p2p prop: ' + p2p.PropertyGuid__c);
		    propertyGuidSet.add(p2p.PropertyGuid__c);
		    // system.debug('BZ: p2p prod: ' + p2p.ProductGuid__c);
		    productGuidSet.add(p2p.ProductGuid__c);
		}
		
		// system.debug('BZ: PropertyGuidSet');
		// system.debug(propertyGuidSet);			
		// system.debug('BZ: ProductGuidSet');
		// system.debug(productGuidSet);
		
		//Map the property object to the guid
		Map<string, Property__c> propMap = new Map<string, Property__c>();
		for (Property__c prop : [SELECT Guid__c From Property__c WHERE Guid__c IN :propertyGuidSet] )
		{
			propMap.put( prop.Guid__c, prop );
		}
		
		// system.debug('BZ: Len: ' + [SELECT Guid__c From Product__c WHERE Guid__c IN :productGuidSet].size());
		
		//Map the product objects to the guid
		Map<string, Product__c> prodMap = new Map<string, Product__c>();
		for (Product__c prod : [SELECT Guid__c From Product__c WHERE Guid__c IN :productGuidSet] )
		{
			prodMap.put( prod.Guid__c, prod );
		}
		
		List<ProductToProperty__c> prodToPropToUpdate = new List<ProductToProperty__c>();
		
		Map<Id, ProductToProperty__c> prodToPropToUpdateMap = new Map<Id, ProductToProperty__c>();
		
		for (ProductToProperty__c prodToPropFromList : ProdToPropMap.values())
		{
		    // system.debug('BZ: propMap:');
		    // system.debug( propMap );
		    // system.debug('BZ: prodMap:');
		    // system.debug( prodMap );
		    
		    // Check if we've already updated this one
		    ProductToProperty__c prodToProp = prodToPropToUpdateMap.get(prodToPropFromList.Id);
		    if (prodToProp == null)
		    {
		    	prodToProp = prodToPropFromList;
		    }
		    
		    //Properties
		    if(prodToProp.PropertyGuid__c == null)
		    {
		     	if( prodToProp.Property__c != null )
		     	{
		     		// system.debug('BZ: Clearing Property');
		     		prodToProp.Property__c = null;
		     		prodToPropToUpdateMap.put(prodToProp.Id, prodToProp);
		     	}
		    }
		    else
		    {
		   		if(propMap.get(prodToProp.PropertyGuid__c) != null)
		   		{
				    Id propId = propMap.get(prodToProp.PropertyGuid__c).Id;
					if (propId != null)
					{
						prodToProp.Property__c = propId;
						prodToPropToUpdateMap.put(prodToProp.Id, prodToProp);
					}
		    	}
		    	else
		    	{
		    		// Else we don't have a guid to match it to, so ignore.
		    		// system.debug('BZ:No match for guid:');
		    		// system.debug(prodToProp.PropertyGuid__c);
		    	}
		    }
		    
		    // Products
		    if(prodToProp.ProductGuid__c == null)
		    {
		     	if( prodToProp.Product__c != null )
		     	{
		     		// system.debug('BZ: Clearing Product');
		     		prodToProp.Product__c = null;
		     		prodToPropToUpdateMap.put(prodToProp.Id, prodToProp);
		     	}
		    }
		    else
		    {
		   		if(prodMap.get(prodToProp.ProductGuid__c) != null)
		   		{
				    Id prodId = prodMap.get(prodToProp.ProductGuid__c).Id;
					if (prodId != null)
					{
						prodToProp.Product__c = prodId;
						prodToPropToUpdateMap.put(prodToProp.Id, prodToProp);
					}
		    	}
		    	else
		    	{
		    		// Else we don't have a guid to match it to, so ignore.
		    		// system.debug('BZ:No match for guid:');
		    		// system.debug(prodToProp.ProductGuid__c);
		    	}
		    }
		}
		
		prodToPropToUpdate = prodToPropToUpdateMap.values();
		
		// system.debug('BZ: prodToPropToUpdate');
		// system.debug(prodToPropToUpdate);
		
		update prodToPropToUpdate;
	}
	
	@future
	public static void RelatePropertyValue(Set<Id> pvList)
	{
		AlreadyProcessed = true;
		
		// system.debug('BZ: RelatePropertyValue Running.');
		//Get the list of PropertyValues to use the ??
		Map<Id, PropertyValue__c> PropValMap = new Map<Id, PropertyValue__c>( 
			[SELECT Id, Guid__c, ProductToPropertyGuid__c, ProductToProperty__c, 
			QuoteToProductGuid__c, QuoteToProduct__c, EnumTranslation__c, PromptTranslation__c, Value__c,
			RelatedPropertyValue__c, RelatedPropertyValueGuid__c  
			FROM PropertyValue__c WHERE Id IN :pvList]
		);
		
		// system.debug(PropValMap);
		
		set<string> propToPropGuidSet = new set<string>();
		set<string> quoteToProdGuidSet = new set<string>();
		set<string> relatedPVGuidSet = new set<string>();
		
		Map<Id, PropertyValue__c> propValToUpdateMap = new Map<Id, PropertyValue__c>();
		
		//Get the list of guids
		for(PropertyValue__c pv : PropValMap.values())
		{
			// system.debug('BZ: pv prop: ' + pv.ProductToPropertyGuid__c);
			propToPropGuidSet.add(pv.ProductToPropertyGuid__c);
			// system.debug('BZ: pv quote: ' + pv.QuoteToProductGuid__c);
			quoteToProdGuidSet.add(pv.QuoteToProductGuid__c);
			
            // 03/05/2018 ADS - Case 35400 - Don't include null values
			// relatedPVGuidSet.add(pv.RelatedPropertyValueGuid__c);
			
			//This is to reset any existing propertyValues which were previously set, but no longer are.
			if(pv.RelatedPropertyValueGuid__c == null)
			{
				// system.debug('BZ: found null rpvGuid');
				// system.debug('BZ: rpv:');
				// system.debug(pv.RelatedPropertyValue__c);
				if (pv.RelatedPropertyValue__c != null)
				{
					pv.RelatedPropertyValue__c = null;
					propValToUpdateMap.put(pv.Id, pv);
				}
			}
            else
            {
                relatedPVGuidSet.add(pv.RelatedPropertyValueGuid__c);
            }
            
		}
		
		// system.debug('BZ: propToPropGuidSet');
		// system.debug(propToPropGuidSet);
		// system.debug('BZ: quoteToProdGuidSet');
		// system.debug(quoteToProdGuidSet);
		
		//Map the property object to the guid
		Map<string, ProductToProperty__c> p2pMap = new Map<string, ProductToProperty__c>();
		for (ProductToProperty__c prop : [SELECT Guid__c From ProductToProperty__c WHERE Guid__c IN :propToPropGuidSet] )
		{
			p2pMap.put( prop.Guid__c, prop );
		}
		
		//Map the property object to the guid
		Map<string, Quote_Product__c> q2pMap = new Map<string, Quote_Product__c>();
		for (Quote_Product__c quote : [SELECT Guid__c From Quote_Product__c WHERE Guid__c IN :quoteToProdGuidSet] )
		{
			q2pMap.put( quote.Guid__c, quote );
		}
		
		//Language Resource map for Prompts
		Map<string, Language_Resource__c> lrMap = new Map<string, Language_Resource__c>();
		for (Language_Resource__c prop : [SELECT ObjectGuid__c From Language_Resource__c WHERE ObjectGuid__c IN :propToPropGuidSet] )
		{
			lrMap.put( prop.ObjectGuid__c, prop );
		}			
		
		//Related PV map
		Map<string, PropertyValue__c> relatedPVMap = new Map<string, PropertyValue__c>();
        
        // 03/05/2018 ADS - Case 35400 - Don't run the query if the Set is empty
        
        if (!relatedPVGuidSet.isEmpty())
        {
            
            for (PropertyValue__c rPV : [SELECT Guid__c From PropertyValue__c WHERE Guid__c IN :relatedPVGuidSet] )
            {
                relatedPVMap.put( rPV.Guid__c, rPV );
            }		
            
        }
		
		List<PropertyValue__c> propValToUpdate = new List<PropertyValue__c>();
		
		
		for (PropertyValue__c propValFromList : PropValMap.values())
		{
			// system.debug('BZ: p2pMap:');
			// system.debug( p2pMap );
			// system.debug('BZ: q2pMap:');
			// system.debug( q2pMap );
			// system.debug('BZ: relatedPVMap:');
			// system.debug( relatedPVMap );
			
			
			
			// Check if we've already updated this one
			PropertyValue__c propVal = propValToUpdateMap.get(propValFromList.Id);
			if (propVal == null)
			{
				propVal = propValFromList;
			}
			
			//Properties
			if(propVal.ProductToPropertyGuid__c == null)
			{
				if( propVal.ProductToProperty__c != null )
				{
					// system.debug('BZ: Clearing Product To Property');
					propVal.ProductToProperty__c = null;
					propValToUpdateMap.put(propVal.Id, propVal);
				}
			}
			else
			{
				if(p2pMap.get(propVal.ProductToPropertyGuid__c) != null)
				{
					Id propId = p2pMap.get(propVal.ProductToPropertyGuid__c).Id;
					if (propId != null)
					{
						propVal.ProductToProperty__c = propId;
						propValToUpdateMap.put(propVal.Id, propVal);
					}
				}
				else
				{
					// Else we don't have a guid to match it to, so ignore.
					// system.debug('BZ:No match for guid:');
					// system.debug(propVal.ProductToPropertyGuid__c);
				}
			}
			
			//Quote
			if(propVal.QuoteToProductGuid__c == null)
			{
				if( propVal.QuoteToProduct__c != null )
				{
					// system.debug('BZ: Clearing Product To Property');
					propVal.QuoteToProduct__c = null;
					propValToUpdateMap.put(propVal.Id, propVal);
				}
			}
			else
			{
				if(q2pMap.get(propVal.QuoteToProductGuid__c) != null)
				{
					Id q2pId = q2pMap.get(propVal.QuoteToProductGuid__c).Id;
					if (q2pId != null)
					{
						propVal.QuoteToProduct__c = q2pId;
						propValToUpdateMap.put(propVal.Id, propVal);
					}
				}
				else
				{
					// Else we don't have a guid to match it to, so ignore.
					// system.debug('BZ:No match for guid:');
					// system.debug(propVal.QuoteToProductGuid__c);
				}
			}
				
				
			//RelatedPropertyValues
			if(propVal.RelatedPropertyValueGuid__c == null)
			{
				// system.debug('BZ: RelatedPV null GUID');				
			}
			else
			{
				// system.debug('BZ: RelatedPV NOT null GUID');
				if(relatedPVMap.get(propVal.RelatedPropertyValueGuid__c) != null)
				{
					Id propId = relatedPVMap.get(propVal.RelatedPropertyValueGuid__c).Id;
					if (propId != null)
					{
						propVal.RelatedPropertyValue__c = propId;
						propValToUpdateMap.put(propVal.Id, propVal);
					}
				}
				else
				{
					// Else we don't have a guid to match it to, so ignore.
					// system.debug('BZ:No match for RelatedPV guid:');
					// system.debug(propVal.RelatedPropertyValueGuid__c);
				}
			}	
				
			//PromptTranslation
			//Use the productToPropertyGuid to find the languageResource
			if(lrMap.get(propVal.ProductToPropertyGuid__c) != null)
			{
				//Get the language Resource Id
				Id langResourceId = lrMap.get(propVal.ProductToPropertyGuid__c).Id;
				
				//Update if we found a match
				if (langResourceId != null)
				{
					propVal.PromptTranslation__c = langResourceId;
					propValToUpdateMap.put(propVal.Id, propVal);
				}
			}
			else
			{
				// Else we don't have a guid to match it to, so ignore.
				// system.debug('BZ:No match for guid:');
				// system.debug(propVal.ProductToPropertyGuid__c);
			}
		}
		
		propValToUpdate = propValToUpdateMap.values();
		
		// system.debug('BZ: propValToUpdate');
		// system.debug(propValToUpdate);
		
		update propValToUpdate;
		
		RelateEnumValueTranslations(pvList);
	}
	
	@future
	public static void RelateEnumValue(Set<Id> enumValList)
	{
		AlreadyProcessed = true;
		
		// system.debug('BZ: RelateEnumValue Running.');
		//Get the list of EnumVals
		Map<Id, EnumValue__c> EnumValMap = new Map<Id, EnumValue__c>( 
			[SELECT Id, Guid__c, PropertyGuid__c FROM EnumValue__c WHERE Id IN :enumValList]
		);
		
		// system.debug(EnumValMap);
		
		set<string> evToPropGuidSet = new set<string>();	
		
		//Get the list of Property guids
		for(EnumValue__c  ev : EnumValMap.values())
		{
			// system.debug('BZ: ev Prop: ' + ev.PropertyGuid__c);
			evToPropGuidSet.add(ev.PropertyGuid__c);
		}
		
		// system.debug('BZ: evToPropGuidSet');
		// system.debug(evToPropGuidSet);
		
		//Map the property object to the guid
		Map<string, Property__c> pMap = new Map<string,Property__c>();
		for (Property__c prop : [SELECT Guid__c From Property__c WHERE Guid__c IN :evToPropGuidSet] )
		{
			pMap.put( prop.Guid__c, prop );
		}
			
		List<EnumValue__c> evToUpdate = new List<EnumValue__c>();
		Map<Id, EnumValue__c> evUpdateMap = new Map<Id, EnumValue__c>();
		
		for (EnumValue__c enumValFromList : EnumValMap.values())
		{
			// system.debug('BZ: enumValFromList:');
			// system.debug( enumValFromList );
			
			// Check if we've already updated this one
			EnumValue__c enumVal = evUpdateMap.get(enumValFromList.Id);
			if (enumVal == null)
			{
				enumVal = enumValFromList;
			}
			
			//Properties
			if(enumVal.PropertyGuid__c == null)
			{
				if( enumVal.Property__c != null )
				{
					// system.debug('BZ: Clearing Product To Property');
					enumVal.Property__c = null;
					evUpdateMap.put(enumVal.Id, enumVal);
				}
			}
			else
			{
				if(pMap.get(enumVal.PropertyGuid__c) != null)
				{
					Id propId = pMap.get(enumVal.PropertyGuid__c).Id;
					if (propId != null)
					{
						enumVal.Property__c = propId;
						evUpdateMap.put(enumVal.Id, enumVal);
					}
				}
				else
				{
					// Else we don't have a guid to match it to, so ignore.
					// system.debug('BZ:No match for guid:');
					// system.debug(enumVal.PropertyGuid__c);
				}
			}
						
		}
		
		evToUpdate = evUpdateMap.values();
		
		// system.debug('BZ: evToUpdate');
		// system.debug(evToUpdate);
		
		update evToUpdate;
			
	}
	
	private static void RelateEnumValueTranslations(Set<Id> pvList)
	{
		//List for the property values that need updating
		List<PropertyValue__c> propValToUpdate = new List<PropertyValue__c>();
		
		//Restrict list of property values to enum properties only as this is all we are dealing with here
		List<PropertyValue__c> pvList2 = new List<PropertyValue__c>(
			[SELECT producttoproperty__r.property__c, Value__c 
			 FROM PropertyValue__c where producttoproperty__r.property__r.Type__c = 2 AND Id IN:pvList]);
	    
	    //Get a set of the properties as we will need this to get the enum values
	    Set<Id> propertyList = new Set<Id>();
		
		// system.debug('BZ: Setting up propertyList for matching EnumTranslations');
		for(PropertyValue__c  pv : pvList2)
		{			
			propertyList.Add(pv.producttoproperty__r.property__c);			
		}
									
		//Set up the map of enum values for the properties in use and 
		//the set of enum value guids used to make the language resource map
		Map<string,EnumValue__c> evMap = new Map<string, EnumValue__c>();
		set<string> evGuidSet = new set<string>();
		
		// system.debug('BZ: Setting up evMap and evGuidSet for matching EnumTranslations');
		for (EnumValue__c ev : [SELECT Id, property__c, value__c, Guid__c From EnumValue__c WHERE property__c IN :propertyList] )
		{
			// system.debug('BZ: Put in evMap, key:' + ev.property__c + ':' + ev.value__c + ' EnumTRanslations');
			evMap.put( ev.property__c + ':' + ev.value__c, ev );
			evGuidSet.add(ev.Guid__c);
		}
		
		// system.debug('BZ: Setting up Language Resource Map for matching EnumTranslations');
		//Map of language Resources for the Enums
		Map<string,Language_Resource__c> lrMap = new Map<string, Language_Resource__c>();
		
		for (Language_Resource__c prop : [SELECT ObjectGuid__c From Language_Resource__c WHERE ObjectGuid__c IN :evGuidSet] )
		{
			// system.debug('BZ: Adding to lrmap Enum Value Id:' + prop.ObjectGuid__c + ' EnumTranslation');
			lrMap.put( prop.ObjectGuid__c, prop );
		}	
		
		// system.debug('BZ: Start of loop for linking EnumTranslations');
		//Go through the list and lookup the related EnumValue id to use as the key into the language resource map
		for(PropertyValue__c  pv : pvList2)
		{								
			EnumValue__c thisEv = evMap.Get(pv.producttoproperty__r.property__c + ':' + pv.Value__c.IntValue());
			// system.debug('BZ: Get from evMap, key:' + pv.producttoproperty__r.property__c + ':' + pv.Value__c.IntValue() + ' EnumTRanslations');
			if (thisEv != null)
			{
				// system.debug('BZ: Found Enum Value EnumTranslation');
				// system.debug('BZ: Looking for Enum Value Id:' + thisEv.Id + 'EnumTranslation');
				//Get the language Resource and link to the property value
				Language_Resource__c thisLr = lrMap.Get(thisEv.Guid__c);
				
				if (thisLr != null)
				{
			      // system.debug('BZ: Found EnumTranslation');
				  pv.EnumTranslation__c = thisLr.Id;
				
				  //Add it to the update list
				  propValToUpdate.Add(pv);
				}
				else
				{
					// system.debug('BZ: No EnumTranslation Found');
				}				
			}	
			else
			{
				// system.debug('BZ: No EnumValue Found');
			}		
		}
		
		//Update
		update propValToUpdate;				
	}	
}