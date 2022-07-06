/********************************************************************
 * NewQuoteGridControllerV2
 *
 * Visualforce Controller used to facilitate the site & products information
 * 
 * Author: Richard Jimenez
 * Created: 08-10-2013
 * Changes: 07-02-2018 - ADS - Case 35482 - Asian Characters
 ********************************************************************/
public with sharing class NewQuoteGridControllerV2 {

	private Id accId {get; private set;}
	private Id oppId {get; private set;}
	private Id quoId {get; private set;}

	private Opportunity opp {get; private set;}
	private map<string, bg_Wrappers.QuoteProductWrapper> quoteProductMap;

	public Quote__c quote {get; private set;} 
	public list<bg_Wrappers.QuoteProductWrapper> Products {get; private set;}
	public list<bg_Wrappers.SiteWrapper> Sites {get; private set;}
	public boolean ViewContacts {get; private set;}

	private map<Id, Contact> contactMap;
	private map<Id, bg_Wrappers.QuoteProductWrapper> productMap;

	public boolean SaveError {get; private set;}
	public boolean editMode {get; private set;}
	
	public string selectedProductId      {get; set;}
	public string selectedQuoteProductId {get; set;}
	
	public NewQuoteGridControllerV2() {
		// Get page parameters
		accId = ApexPages.currentPage().getParameters().get('accId');
		oppId = ApexPages.currentPage().getParameters().get('oppid');
		quoId = ApexPages.currentPage().getParameters().get('quoId');
		opp = bg_OpportunityUtils.GetOpportunityById(oppid);
		editMode = (ApexPages.currentPage().getParameters().get('mode') != '0');
		SaveError = false;

		// Load Quote
		LoadQuote();
	}

	private void LoadQuote() {
		/*
			Load Quote and Products
		*/
		try {
			quote = bg_QuoteUtils.GetQuoteById(quoId);
		} catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Quote Id does not exist: ' + quoId));
		}

		if(quote != null) {
			list<Quote_Product__c> quoteProducts = bg_QuoteUtils.GetQuoteProducts(quoId, true);
			list<OpportunitySite__c> siteList = bg_SiteUtils.GetOpportunitySites(oppId, bg_SiteUtils.RECORD_TYPE_NAME_NAMED);
			
			sites = bg_WrapperHelper.CreateSiteWrappers(siteList);

			quoteProductMap = new map<string, bg_Wrappers.QuoteProductWrapper>();
			contactMap = bg_ContactUtils.GetContactsMap(bg_ContactUtils.GetQuoteProductContactIds(quoId));
			bg_WrapperHelper.PopulateQuoteProductWrappers(quote, quoteProductMap, sites, quoteProducts, true, contactMap);	

			products = new list<bg_Wrappers.QuoteProductWrapper>();
			productMap = new map<Id, bg_Wrappers.QuoteProductWrapper>();
			for(bg_Wrappers.QuoteProductWrapper qpw : quoteProductMap.values()) {
				products.add(qpw);
				productMap.put(qpw.Id, qpw);
			}
	
			// populate missing sites
			bg_WrapperHelper.CreateProductSiteWrappers(quote, quoteProductMap.values(), sites, false);				
		}
		
		// Show warnings if BSI membership is required for one of the products
		CheckBSIMembershipRequirement(quote, quoteProductMap.values());
	}

	/**********************************************************************************/
	/* Actions                                                                        */
	/**********************************************************************************/
	public pageReference Back() {
		/*
			Move to back page
		*/
		PageReference backPage = null;
		if(SaveQuote()) {
			backPage = new Pagereference('/' + bg_QuoteUtils.BuildNewQuoteURL(accId, oppId, quoId));
		}
		return backPage;
	}

	public pageReference ConfigureProduct() {
		/* Configure Product */
		Pagereference configurePage = null;
		if(SaveQuote()) {
			//configurePage = new Pagereference(bg_BluePrintUtils.BuildConfigureQuoteProductURL(editMode, quoId, selectedProductId, null, bg_QuoteUtils.BuildNewQuoteGridURL(accId, oppId, quoId, editMode)));
			configurePage = new Pagereference(bg_BluePrintUtils2.BuildConfigureURL(editMode, quoId, selectedProductId, bg_QuoteUtils.BuildNewQuoteGridURL(accId, oppId, quoId, editMode)));
		}
		return configurePage;
	}
	
	public pageReference UploadProduct() {
		/* Upload Product */
		Pagereference uploadFilePage = null;
		if(SaveQuote()) {
			system.debug('selectedProductId: ' + selectedProductId);
			system.debug('selectedQuoteProductId: ' + selectedQuoteProductId);
			uploadFilePage = new Pagereference(bg_BluePrintUtils.BuildUploadFileQuoteProductURL(quoId, selectedProductId, selectedQuoteProductId, bg_QuoteUtils.BuildNewQuoteGridURL(accId, oppId, quoId, editMode)));
			bg_QuoteUtils.UpdateQuoteProductUploaded(selectedQuoteProductId);
		}
		return uploadFilePage;
	}
	
	public void QuickSave() {
		/* Quick Save */
		SaveQuote();
	}

	public pageReference Save() {
		/* Save */
		Pagereference retPage = null;
		if(SaveQuote()) {
			retPage = new pageReference('/' + quoId);
		}
		return retPage;  
	}

	public pageReference Close() {
		/* Close */
		return new pageReference('/' + quoId); 
	}
	
	private boolean SaveQuote() {
		/*
			Save Quote Products
		*/
		boolean saveOK = true;
		try {
			bg_QuoteUtils.SaveQuoteProducts(quote, quoteProductMap);
		} catch (DmlException dml) {
        	Apexpages.addMessages(dml);
        	saveOK = false; 
		} catch (Exception ex) {
		    Apexpages.addMessages(ex);
		    saveOK = false;
		}
		return saveOK;
	}

	public pageReference ConfigureAll() {
		/* Save and Configure All */
		Pagereference configurePage = null;
		if(SaveQuote()) {
			//configurePage = new Pagereference(bg_BluePrintUtils.BuildConfigureQuoteProductURL(editMode, quoId, null, null, bg_QuoteUtils.BuildNewQuoteGridURL(accId, oppId, quoId)));
			configurePage = new Pagereference(bg_BluePrintUtils2.BuildConfigureURL(editMode, quoId, null, bg_QuoteUtils.BuildNewQuoteGridURL(accId, oppId, quoId)));
		}
		return configurePage;
	} 

	/*
		View Product Profile Button
	*/
	public pageReference ViewProductProfile()
	{
		Pagereference productProfilePage = null;
		string hqQuoteProductId;
		string imsQuoteProductId;
		string samplingQuoteProductId;

		bg_Wrappers.QuoteProductWrapper qpw = productMap.get(selectedProductId);		

		// IMS Enabled?
		if(qpw.IMS)
		{
			Quote_Product__c qp = bg_QuoteUtils.GetIMSQuestionProduct(qpw.Name, quoId, false);
			if(qp != null)
			{
				imsQuoteProductId = qp.Id;
			}
		}

		// Sampling Enabled?
		if(qpw.ValidForSampling)
		{
			Quote_Product__c qp = bg_QuoteUtils.GetSampleQuestionProduct(qpw.Name, quoId, false, qpw.Instance);
			if(qp != null)
			{
				samplingQuoteProductId = qp.Id;
			}
		}
		string retUrl = '';

		string quoteName = quote.Name + ' - ' + qpw.DisplayName;
		
		string docName = bg_BluePrintUtils.GetDocumentName(System.Label.DaysProfile, quoteName, bg_BluePrintUtils.TEMPLATE_DOC_EXT_PDF);
        
        string quoteLanguage = quote.QuoteLanguage__c;

		if(SaveQuote()) {
			productProfilePage = new Pagereference(bg_BluePrintUtils.BuildTemplateURL(bg_BluePrintUtils.TEMPLATE_NAME_PRODUCT_PROFILE, 
																							docName,
																							quoId,
																							hqQuoteProductId,
																							imsQuoteProductId,
																							samplingQuoteProductId,
                                                                                      		quoteLanguage,
																							retUrl));
		}
		return productProfilePage;			
	}
	
	/**********************************************************************************/
	/* Configurator URLs
	/**********************************************************************************/
	//public string GetConfigureAllUrl() {
		/* Return Configure All Url */
	//	return bg_BluePrintUtils.BuildConfigureQuoteProductURL(quoId);
	//}

	/**********************************************************************************/
	/* Hide / Show Contacts
	/**********************************************************************************/
	public void ShowContacts() {
		ViewContacts = true;
	} 
	public void HideContacts() {
		ViewContacts = false;
	} 
    
	/**********************************************************************************/
	/* Picklist values                                                                */
	/**********************************************************************************/
	public list<SelectOption> getContactItems() {
		/* Return list of Contacts */		
		return bg_ControllerUtils.CreateSelectOptions(bg_ContactUtils.GetAccountContacts(accId), 'Id', 'Name', true, true);		
	}

	public boolean getCheckPricebooksSet() {
		/*
			Check Pricebooks are all set - to enable configure buttons
		*/
		boolean result = true;
		for(bg_Wrappers.QuoteProductWrapper qpw : products) {
			for(bg_Wrappers.ProductSiteWrapper psw : qpw.SitesMap.values()) {
				if(psw.Selected) {
					if(bg_StringUtils.IsBlank(psw.PricebookId)) {
						result = false;
						//break;
					}

					if(!string.IsBlank(psw.PricebookId)) { pricebookIds.add(psw.PricebookId); }
					if(!string.IsBlank(psw.SecondaryPricebookId)) { pricebookIds.add(psw.SecondaryPricebookId); }					
				}
			}
		}
		return result;
	}
	
	private list<SelectOption> pricebookItems;
	private set<Id> pricebookIds = new set<Id>();
	
	public list<SelectOption> getPricebookItems() {
		/* Return list of Price books */
		if(pricebookItems == null) {
			boolean result = !getCheckPricebooksSet();		
			return bg_ControllerUtils.CreateSelectOptions(bg_PricebookUtils.GetPricebooks(null, quote.Account__c, null, pricebookIds, false), 'Id', 'Name', true, result);
		} else {
			return pricebookItems;
		}
	}

	public list<SelectOption> getCurrencyCodeItems() {
		/* Return list of Currency Codes */		
		return bg_ControllerUtils.GetPicklistSelectOptions(quote, 'CurrencyIsoCode', true);
	}

	private void CheckBSIMembershipRequirement(Quote__c quote, list<bg_Wrappers.QuoteProductWrapper> qpws) {
		/* 
			Display warning if BSI membership is required
		*/
		// Check if BSI Membership is required and show message
		string warningMessage = bg_QuoteUtils.GetBSIMembershipWarning(quote.Opportunity_Name__c, quote.Account__c, qpws);
		if(!string.isBlank(warningMessage)) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, warningMessage));
		}
	}
}