/********************************************************************
 * AddSiteToQuoteController
 *
 * Visualforce Controller used to add a new
 * opportunity site or link existing site from the related account.
 * It will also add a Contact Role for each different Primary Contat
 * specified on Opportunity Site (junction object).
 * 
 * Author: Richard Jimenez
 * Created: 02-09-2013
 * Changes: 
 *			15-08-15 - RJ - TCode description is mandatory on sites
 *			07-07-2017 - MJ - Type and TCode description no longer mandatory on sites
 *			11-07-2017 - MJ - Renamed class from AddOptySiteControllerV2 to AddSiteToQuoteController
 *			18-07-2017 - CB - Full rewrite to remove old functionality and old processes and cater for new functionality/processes
 *			08/09/2017 - CPE - Rework in AddSiteToQuoteController to populate linkedOpportunitySites from bg_OpporutnitySiteUtils
 *								methods rather than the erroneously created methods in bg_OpportunityUtils
 *			04/12/2017 - ADS - Case 34308 - Country Code is required
 ********************************************************************/
public without sharing class AddSiteToQuoteController {
	
	public Boolean allCheck {get; set;}
	public Boolean showNewSection {get; set;}
	public Account acc {get; private set;}
	public PageReference returnPage {get; set;}
	public SiteWrapper newSiteWrapper {get; set;}
	public Opportunity opp {get; private set;}
	public List<Contact> accContacts {get; set;}
	public List<Site__c> allAccountSites {get; private set;}
	public List<SiteWrapper> accSiteWrappers {get; set;}
	public List<OpportunitySiteWrapper> oppSiteWrappers  {get; set;}
	public List<OpportunitySite__c> opportunitySitesToDelete {get; set;}
	public List<OpportunitySite__c> linkedOpportunitySites {get; private set;}
	public Id opportunitySiteIdToRemove {get; set;}
	public Map<Id, Site__c> allAccountSitesById {get; set;}
	private Map<Id, List<Quote_Product__c>> configuredQuoteProductsByOpportunitySiteId {get; set;}

	private Map<String, String> pageParameters {get; set;}

	private static final String PARAM_OPPID = 'oppId';
	private static final String PARAM_ACCID = 'accId'; 
	private static final String PARAM_RETURL = 'returl'; 
	
	public AddSiteToQuoteController() {
		// Set IE10 page params
		Apexpages.currentPage().getHeaders().put('X-UA-Compatible', 'IE=10');
		
		pageParameters = ApexPages.currentPage().getParameters();

		if(pageParameters.containsKey(PARAM_OPPID))
		{
			// get Opportunity Record
			opp = bg_OpportunityUtils.GetOpportunityById(pageParameters.get(PARAM_OPPID));
			// get related Account
			acc = bg_AccountUtils.getAccount(opp.AccountId);
			// get account contacts
			accContacts = [SELECT Id, Name FROM Contact WHERE AccountId =:acc.Id ORDER BY LastModifiedDate DESC LIMIT 100];
			
			// set the return page to the specified return URL if specified
			if(ApexPages.currentPage().getParameters().containsKey(PARAM_RETURL))
			{
				// Set return page to the specified return URL
				returnPage = new PageReference(ApexPages.currentPage().getParameters().get(PARAM_RETURL));
			}
			
			// get opportunity sites for opportunityId
			Map<Id, List<OpportunitySite__c>> sitesByOppId;
			Set<Id> oppIds = new Set<Id>();
			oppIds.add(opp.Id);
			sitesByOppId = bg_OpportunitySiteUtils.getOpportunitySiteMapByOppId(oppIds);
			
			linkedOpportunitySites = sitesByOppId.get(opp.Id);  // Do not need to check the map keyset as the method called ensures the opp.Id will be in the keyset
			

			// get a set of opportunity site ids so we can fetch configured quote products by opp site id
			Set<Id> opportunitySiteIds = new Set<Id>();

			// map opportunity sites by siteId, build set of opp site ids
			Map<Id, OpportunitySite__c> opportunitySitesBySiteId = new Map<Id, OpportunitySite__c>(); 
			for(OpportunitySite__c opportunitySite : linkedOpportunitySites)
			{
				opportunitySitesBySiteId.put(opportunitySite.Site__c, opportunitySite);
				opportunitySiteIds.add(opportunitySite.Id);
			}

			// get all quote products for the opportunity sites, we will use this to prevent the user from removing an opp site from the basket if it is linked to a configured quote product
			configuredQuoteProductsByOpportunitySiteId = bg_QuoteProductUtils.getConfiguredQuoteProductsByOpportunitySiteIds(opportunitySiteIds);
			
			// get all account sites
			allAccountSitesById = bg_SiteUtils.GetAccountSitesMap(acc.Id);
			accSiteWrappers = new List<SiteWrapper>();

			// build account site wrapper list - exclude sites which are already linked via opportunity sites (Sites in basket)
			for(Site__c accSite : allAccountSitesById.values())
			{
				if(!opportunitySitesBySiteId.containsKey(accSite.Id))
				{
					accSiteWrappers.add(new SiteWrapper(accSite, accContacts));
				}
			}

			// build opportunity site wrappers
			oppSiteWrappers = new List<OpportunitySiteWrapper>();
			for(Id siteId : opportunitySitesBySiteId.keySet())
			{
				Site__c linkedSite = allAccountSitesById.get(siteId);
				OpportunitySite__c opportunitySite = opportunitySitesBySiteId.get(siteId);
				oppSiteWrappers.add(new OpportunitySiteWrapper(linkedSite, opportunitySite));
			}

			newSiteWrapper = setupSiteDeafultValues();
			opportunitySitesToDelete = new List<OpportunitySite__c>();
			showNewSection = false;
		}
		else
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to derive the related opportunity'));
		}
	}

	// Add site to the quote
	public void addSiteToQuote() {
		for(Integer i = 0; i < accSiteWrappers.Size(); i++)
		{
			SiteWrapper siteWrapper = accSiteWrappers[i];
			if(siteWrapper.isSelected)
			{
				// Add the site to the collection of opportunity site wrappers
				Site__c accountSite = siteWrapper.Site;
				OpportunitySite__c opportunitySite = createOpportunitySiteFromSiteWrapper(accountSite);
				oppSiteWrappers.add(new OpportunitySiteWrapper(accountSite, opportunitySite));

				// remove from the account site wrapper, decrease the counter to ensure we still process the rest of the collection
				accSiteWrappers.remove(i);
				i--;
			}
		}
	}

	// create new opportunity site wrapper from account site
	public OpportunitySite__c createOpportunitySiteFromSiteWrapper(Site__c accountSite)
	{
		OpportunitySite__c newOpportunitySite = new OpportunitySite__c();
		newOpportunitySite.Opportunity__c = opp.Id;
		newOpportunitySite.Site__c = accountSite.Id;
		newOpportunitySite.SitePrimaryContact__c = accountSite.PrimaryContact__c;
		return newOpportunitySite;
	}

	// remove opportunity site from the quote
	public void removeOpportuntySiteFromQuote() {
		for(Integer i = 0; i < oppSiteWrappers.Size(); i++)
		{
			OpportunitySiteWrapper oppSiteWrapper = oppSiteWrappers[i];
			// the VF page will set the site id to remove when the user tries to remove an opportunity site
			// as the opp site may not have been committed - sites will always be committed
			if(oppSiteWrapper.Site.Id == opportunitySiteIdToRemove)
			{
				// check this opp site is not related to a configured quote product, we cannot remove if it is linked to 1 or more configured quote products
				if(configuredQuoteProductsByOpportunitySiteId.containsKey(oppSiteWrapper.OpportunitySite.Id))
				{
					// the value list contains configured quote products for this opp site
					if(configuredQuoteProductsByOpportunitySiteId.get(oppSiteWrapper.OpportunitySite.Id).Size() > 0	)
					{
						throw new addSiteToQuoteException('This opportunity site is related to a configured quote product, you cannot remove this from the basket please remove the product via the quote builder page'); 
					}
				}
				// take the site from the opportunity site and add into the collection of account site wrappers
				accSiteWrappers.add(new SiteWrapper(oppSiteWrapper.site, accContacts));
				// remove the opportunity site wrapper from the collection
				oppSiteWrappers.remove(i);
				// if the opportunity site we are removing has an id we need to add it to our list of opportunity sites to delete
				if(null!=oppSiteWrapper.opportunitySite.Id)
				{
					opportunitySitesToDelete.add(oppSiteWrapper.opportunitySite);
				}
			}
		}
	}
	// cancel - return to opportunity unless a ret val was provided
	public PageReference cancel()
	{
		if(null==returnPage)
		{
			returnPage = new PageReference('/'+opp.Id);
		}
		return returnPage;
	}

	// Save current configuration and return to opportunity or return val
	public PageReference save()
	{
		PageReference pageToReturn = null;
		// check the page saves correctly, if it fails a page message will be added
		if(saveAll())
		{
			// check if the return page has already been initalised from the return url
			if(null==returnPage)
			{
				// page has not been initialised with a return url, build url back to the opp
				returnPage = new PageReference('/'+opp.Id);
			}
			pageToReturn = returnPage;
		}
		return pageToReturn;
	}

	// Save and go to new quote, if a rerturn val is present return this
	public PageReference saveAndQuote()
	{
		PageReference pageToReturn = null;
		// check the page saves correctly, if it fails a page message will be added
		if(saveAll())
		{
			// check if the return page has already been initalised from the return url
			if(null==returnPage)
			{
				// page has not been initialised with a return url, build PageReference for creating a new quote
				returnPage = Page.QuoteBuilder;
				returnPage.getParameters().put(PARAM_OPPID, opp.Id);
				returnPage.getParameters().put(PARAM_ACCID, acc.Id);
			}
			pageToReturn = returnPage;
		}
		return pageToReturn;
	}

	// return true if save was successful
	public Boolean saveAll()
	{
		Boolean saveSuccessful = false;
		List<Site__c> accSitesToInsert = new List<Site__c>();
		List<OpportunitySite__c> opportunitySitesToInsert = new List<OpportunitySite__c>();
		for(OpportunitySiteWrapper opportunitySiteWrapper : oppSiteWrappers)
		{
			if(null==opportunitySiteWrapper.opportunitySite.Id)
			{
				opportunitySitesToInsert.add(opportunitySiteWrapper.opportunitySite);
			}
		}
		for(SiteWrapper siteWrapper : accSiteWrappers)
		{
			if(null==siteWrapper.Site.Id)
			{
				accSitesToInsert.add(siteWrapper.Site);
			}
		}
		try
		{
			insert accSitesToInsert;
			delete opportunitySitesToDelete;
			insert opportunitySitesToInsert;
			update allAccountSitesById.values();
			saveSuccessful = true;
		}
		catch(Exception ex)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to save: ' + ex.getMessage() + ' StackTrace: '+ex.getStackTraceString()));
		}
		return saveSuccessful;
	}

	// Setup default values for a new site
	private SiteWrapper setupSiteDeafultValues()
	{
		Site__c newSite = new Site__c();
		newSite.Account__c = acc.Id;
		SiteWrapper newSiteWrapper = new SiteWrapper(newSite, accContacts);
		return newSiteWrapper;
	}
	
	// Either display the new site section or commit the new site and add to the ste wrapper
	public void addNewSite() {
		if (showNewSection) 
		{
            
            // Country Code to be hidden and auto-populate based on the User's selection in the Country field
            newSiteWrapper.Site.Country_Code__c = bg_CustomMetadataUtils.getCountryCodeByCountryName(newSiteWrapper.Site.Country__c);
            
			if (!bg_StringUtils.IsBlank(newSiteWrapper.Site.Name)  
				&& !string.IsBlank(newSiteWrapper.Site.Type__c) 
				&& !string.IsBlank(newSiteWrapper.Site.Postcode__c) 
				&& !string.IsBlank(newSiteWrapper.Site.Street__c)
                && !string.IsBlank(newSiteWrapper.Site.Country_Code__c)) 
			{
                
                try
                {
                    
                    // insert new site
                    insert (newSiteWrapper.Site);
                    // Add the new site to the Account list
                    accSiteWrappers.add(newSiteWrapper);
                    // Reset new site values
                    newSiteWrapper = setupSiteDeafultValues();
                    // hide the new site section
                    showNewSection = false;                    
                }
                catch (Exception e)
                {
                    System.debug(System.LoggingLevel.ERROR, e.getMessage());
                    // ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Add Duplicate Site Error Message Here'));
                }
                
			} else if (string.IsBlank(newSiteWrapper.Site.Name)) 
			{
				// Address name 
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.NameValidationSite));
			} else if (string.IsBlank(newSiteWrapper.Site.Type__c)) 
			{
				// Site Type must be selected
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.TypeValidationSite));
			}
            else if (string.IsBlank(newSiteWrapper.Site.Country_Code__c))
            {
                // Country selected must have a Country Code
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.CountryCodeValidationSite + ' \'' + newSiteWrapper.Site.Country__c + '\''));
            }
			else 
			{
			 	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.AddressValidationPostcodeStreet));
			}
		} else 
		{
			showNewSection = true;
		}
	}

	// Hide the new site section
	public void cancelNewSite() {
		showNewSection = false;
	}
	
	// Select All Account Sites
	public void selectAll()
	{
		for (SiteWrapper accSiteWrapper :accSiteWrappers) {
			accSiteWrapper.isSelected = true;
		}
		allCheck = true;
	}
	
	// Unselect All Account Sites
	public void deselectAll()
	{
		for (SiteWrapper accSiteWrapper :accSiteWrappers) {
			accSiteWrapper.isSelected = false;
		}
		allCheck = false;
	}
	
	// Site Wrapper for the UI
	public class SiteWrapper {
		public Boolean isSelected {get; set;}
		public Site__c site {get; set;}
		public List<SelectOption> contacts {get; set;}

		public SiteWrapper(Site__c accSite, List<Contact> accContacts)
		{
			this.isSelected = false;
			this.site = accSite;
			this.contacts = bg_ControllerUtils.CreateSelectOptions(accContacts,'Id', 'Name', false, true);
		}
	}

	// Opportunity Site Wrapper for the UI
	public class OpportunitySiteWrapper{
		public Site__c site {get; set;}
		public OpportunitySite__c opportunitySite {get; set;}

		public OpportunitySiteWrapper(Site__c accSite, OpportunitySite__c oppSite)
		{
			this.site = accSite;
			this.opportunitySite = oppSite;
		}
	}

	public class addSiteToQuoteException extends Exception{}
}