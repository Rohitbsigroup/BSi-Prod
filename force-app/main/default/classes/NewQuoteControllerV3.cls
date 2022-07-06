/********************************************************************
 * NewQuoteControllerV3
 *
 * Visualforce Controller used to facilitate the selection of products
 * and sites
 * 
 * Author: Richard Jimenez
 * Created: 28-08-2014
 * Changes: 16-11-16 - Case 27420 JT - Added getBluePrintLanguages, getSelectedQuoteLanguage and setSelectedQuoteLanguage methods
 ********************************************************************/
public with sharing class NewQuoteControllerV3 {

	// Record Ids
	private Id oppId;
	private Id accId;
	private Id quoId;
	
	// Records
	public Opportunity opp {get; private set;}
	public Quote__c quote {get; private set;} 
	public User user {get; private set;}

	public boolean isNew {get;set;}								// New Quote
//	public boolean isEditMode {get;set;}						// Edit Mode

	public boolean ShowSiteSummary {get;private set;}			// Show/Hide site summary
	public boolean ShowProductSearch {get;private set;}			// Show/Hide product search panel
	public boolean ShowSelectedOnly {get;private set;}			// Show/Hide selected products only
	public boolean ShowSelectionSummary {get;private set;}		// Show/Hide selection summary
	public boolean SampleWarnings {get; private set;}		// Highlight any selection warnings
	public boolean ShowCreditCheckContact {get; private set;}

	// Product Search variable
	public string searchProductPortfolio {get;set;}		 // selected portfolio value
	public string searchProductArea {get;set;}			 // selected product area value
	public string searchProductName {get;set;}			 // selected product name value
	public list<string> searchProductCountries {get;set;} // selected countries

	public list<bg_Wrappers.ProductWrapper> ProductSearchResults {get; private set;}			// search results
	public list<bg_Wrappers.RelatedProductWrapper> SuggestedProductResults {get; private set;}	// suggested results
	
	// Selected values from VF page
	public string selectedProductArea {get;set;}
	public string selectedProduct {get;set;}
	public string selectedIMSProduct {get;set;}
	public string selectedProdRegPath {get; set;}
	public string selectedProdRiskLevel {get; set;}
	
	public string selectedSiteProduct {get; set;}
	public string selectedSite {get; set;}

	public String selectedQuoteLanguage;
		
	// internal selected lists
	public set<string> selectedIMSProducts {get; set;}
	public set<string> allIMSProducts {get; set;}	
	private set<string> siteCountries;
	
	// Wrappers & Maps
	private map<string, bg_Wrappers.ProductAreaWrapper> productAreasMap;
	public map<string, bg_Wrappers.QuoteProductWrapper> productMap {get; private set;}
	public list<bg_Wrappers.ProductAreaWrapper> productAreas {get;set;}
	public list<bg_Wrappers.SiteWrapper> sites {get;set;}
	public map<string, map<string, map<string, bg_Wrappers.RegPathSampleWrapper>>> samplingMap {get;private set;} 	// by site type, by product, by product site types
 
	public boolean readyToQuote {get; private set;}

	public boolean missingSiteType {get;set;}
	public list <OpportunitySite__c> missingSiteTypes {get;set;}
	public boolean useDefaults {get;set;}
	public boolean skipPricebookCurrencyCheck {get;set;}

	private boolean hasSingletonProduct;
	
	/************************************************************************/
	/* Constructor                                                          */	
	/************************************************************************/
	public NewQuoteControllerV3() {
		/*
			Class Constructor
		*/
//		try {
			// Page Section defaults
			ShowSiteSummary = true;
			ShowProductSearch = true;
			ShowSelectionSummary = false;
			ShowSelectedOnly = true;
			SampleWarnings = false;
			skipPricebookCurrencyCheck = false;
			hasSingletonProduct = false;
			ShowCreditCheckContact = bg_QuoteUtils.ShowCreditCheckContact(UserInfo.getUserId());
			
			// Get page parameters
			oppId = ApexPages.currentPage().getParameters().get('oppid');
	        accId = ApexPages.currentPage().getParameters().get('accid');
	        quoId = ApexPages.currentPage().getParameters().get('quoid');
	
			// Initialise collections
			selectedIMSProducts = new set<string>();
			allIMSProducts = new set<string>();
			missingSiteTypes = new list<OpportunitySite__c>();
			searchProductCountries = new list<string>();
			
			// Load Opportunity
			opp = bg_OpportunityUtils.GetOpportunityById(oppId);
	
			// Load & Check opportunity sites
			list<OpportunitySite__c> siteList = bg_SiteUtils.GetOpportunitySites(oppId, bg_SiteUtils.RECORD_TYPE_NAME_NAMED);
			missingSiteType = CheckMissingSiteTypes(siteList, missingSiteTypes);
			siteCountries = bg_SiteUtils.GetOpportunitySiteCountries(siteList);

			productAreas = new list<bg_Wrappers.ProductAreaWrapper>();
			productAreasMap = new map<string, bg_Wrappers.ProductAreaWrapper>();
			productMap = new map<string, bg_Wrappers.QuoteProductWrapper>();
									
			// Initialise Site Wrappers
			sites = bg_WrapperHelper.CreateSiteWrappers(siteList);
			samplingMap = bg_WrapperHelper.CreateSamplingMap(sites, productMap);
	
			system.debug('1: ' + (quoId == null));
					
			// Initialise Quote
			if(quoId == null) {
				system.debug('2: ' + quote);
				NewQuote();
			} else {
				LoadQuote();
			}

			// Case 27420
			// Initialise user (for default blueprint language settings) 
			LoadUser();

//		} catch (Exception e) {
//            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Initialising error - ' + e.getMessage()));
//		}
	}

	public pageReference CheckManageSites() {
		/* Redirect to Manage Site if there are none selected */
		if(sites !=null && sites.isEmpty()) {
			return new pageReference('/' + bg_SiteUtils.BuildManageOpportunitySitesURL(oppId, bg_QuoteUtils.BuildNewQuoteURL(accId, oppId, quoId)));
		} else {
			return null;
		}
	}

	private void NewQuote() {
		/* 
			Create New Quote
		*/
		isNew = true;
		useDefaults = true;		
		quote = bg_QuoteUtils.GetNewQuote(accId, oppId);
		system.debug('NewQuote 3: ' + quote);			
	}

	private void LoadQuote() {
		/*
			Load Quote and Products
		*/
		try {
			quote = bg_QuoteUtils.GetQuoteById(quoId);
			isNew = false;
			useDefaults = false;
			ShowSiteSummary = quote.VF_ShowSiteSummary__c;
			ShowProductSearch = quote.VF_ShowProductSearch__c;
			ShowSelectionSummary = quote.VF_ShowSelectionSummary__c;
		} catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Quote Id does not exist: ' + quoId));
		}
		
		if(quote != null) {
			list<Quote_Product__c> quoteProducts = bg_QuoteUtils.GetQuoteProducts(quoId);
			bg_WrapperHelper.PopulateQuoteProductWrappers(quote, productMap, sites, quoteProducts);

			// update selected product map
			for(bg_Wrappers.QuoteProductWrapper qpw : productMap.values()) {
				if(qpw.Selected) {
					bg_Wrappers.ProductAreaWrapper area;
					if(!productAreasMap.containsKey(qpw.area)) {
						area = bg_WrapperHelper.CreateProductAreaWrapper(qpw.Area, qpw.GridView);
						productAreasMap.put(qpw.area, area);
						productAreas.add(area);
						area.IsCollapsed = false;
						qpw.ProductArea = area;
					}
					productAreasMap.get(qpw.area).SelectedProductCount++;					
					productAreasMap.get(qpw.area).products.add(qpw);

					// Add new product site to sampling map
					for(integer index : qpw.sitesMap.keySet()) {
						bg_Wrappers.ProductSiteWrapper psw = qpw.sitesMap.get(index);
						bg_Wrappers.SiteWrapper site = sites[index-1];
						bg_WrapperHelper.AddProductSiteToSamplingMap(samplingMap, qpw, site, psw);
					}
					// populate missing sites
					bg_WrapperHelper.CreateProductSiteWrappers(quote, qpw, sites, true, false);
					
					// update IMS lists
					if(qpw.SupportsIMS) { 
						allIMSProducts.add(qpw.InstanceName);
						bg_WrapperHelper.PopulateIMSFields(qpw, quoId);
					}
					if(qpw.IMS) { 
						selectedIMSProducts.add(qpw.InstanceName); 
					}
				}
			}

			// Check for sampling
			CheckForSamplingAvailable(productMap.values());
		}
	}
	
	// Case 27420
	private void LoadUser() 
	{
		/*
			Load user settings
		*/
		user = bg_UserUtils.GetUserById(UserInfo.getUserId());
	}

	public OpportunitySite__c SiteHQ {
		/* Return HQ Site */
		get {
			list<OpportunitySite__c> siteList = bg_SiteUtils.GetOpportunitySites(oppId, null, true);
			if(siteList.isEmpty()) {
				return null;
			} else {
				return siteList[0];
			}
		}
	}
	
	public OpportunitySite__c SiteNetwork {
		get {
			/* Return first Network Site */
			list<OpportunitySite__c> siteList = bg_SiteUtils.GetOpportunitySites(oppId, bg_SiteUtils.RECORD_TYPE_NAME_NETWORK);
			if(siteList.isEmpty()) {
				return null;
			} else {
				return siteList[0];
			}
		}
	}

	public OpportunitySite__c SiteTransient {
		get {
			/* Return first transient site */
			list<OpportunitySite__c> siteList = bg_SiteUtils.GetOpportunitySites(oppId, bg_SiteUtils.RECORD_TYPE_NAME_TRANSIENT);
			if(siteList.isEmpty()) {
				return null;
			} else {
				return siteList[0];
			}		
		}
	}

	private boolean CheckMissingSiteTypes(list<OpportunitySite__c> siteList, list<OpportunitySite__c> missingSiteTypes) {
		/*
			Check for missing site types
		*/
		missingSiteTypes.addAll((list<OpportunitySite__c>)bg_StringUtils.GetBlankValuesList(siteList, 'SiteType__c'));
		return missingSiteTypes.size() > 0;
	}

	public boolean IsMultiSite {
		get {
			return (sites.size() > 0);
		}		
	}

	public list<SelectOption> getContactItems() {
		/* Return list of Contacts */		
		return bg_ControllerUtils.CreateSelectOptions(bg_ContactUtils.GetAccountContacts(accId), 'Id', 'Name', true, true);
	}
	
	public list<SelectOption> getPricebookItems() {
		/* Return list of Pricebook Items */		
		// only pricebooks for current year & customer, or global
		set<Id> pricebookIds = new set<Id>{quote.PriceBook2Id__c};
		return bg_ControllerUtils.CreateSelectOptions(bg_PricebookUtils.GetPricebooks(null, accId, null, pricebookIds, false), 'Id', 'Name', true, false);		
	}

	public list<SelectOption> getCurrencyCodeItems() {
		/* Return list of Countries */
		return bg_ControllerUtils.GetPicklistSelectOptions(quote, 'CurrencyIsoCode', true);
	}

	public boolean hasMessages {
		get {
			return ApexPages.hasMessages();
		}
	}

	//Case 27420
	public List<SelectOption> getBluePrintLanguages()
	{	    
		return bg_ControllerUtils.GetPicklistSelectOptions(user, 'BluePrint_Language__c', true); 
	}

	public String getSelectedQuoteLanguage()
	{
		if (String.isBlank(quote.QuoteLanguage__c))
		{
			selectedQuoteLanguage = user.blueprint_language__c;
		}
		else 
		{
			selectedQuoteLanguage = quote.QuoteLanguage__c;
		}
		return selectedQuoteLanguage;
	}

	public void setSelectedQuoteLanguage(String so)
	{
		quote.QuoteLanguage__c = so;
	}

	/************************************************************************/
	/* Product Search Methods                                               */	
	/************************************************************************/	
	public list<SelectOption> getProductPortfolioItems() {
		/* Return list of Product Portfolios */
		return bg_ControllerUtils.CreateSelectOptions(bg_ProductUtils.GetProductPortfolios(), true, true);
	}

	public list<SelectOption> getProductAreaItems() {
		/* Return list of Product Areas */		
		return bg_ControllerUtils.CreateSelectOptions(bg_ProductUtils.GetProductAreas(searchProductPortfolio), true, true);
	}

	public list<SelectOption> getProductCountryItems() {
		/* Return list of Countries */		
		return bg_ControllerUtils.CreateSelectOptions(siteCountries, true, false);
	}

	public void ToggleProductSearch() {
		/* Show / Hide Product Search */
		ShowProductSearch = !ShowProductSearch;
	}

	//public boolean ShowConfiguredProducts {get; set;}
	public void SearchProducts() {
		/*
			Search Products
		*/
		list<Product_Classification__c> pcList;
		list<Product__c> pList;
		
		if(!bg_StringUtils.IsBlank(searchProductName)) {
			// Search by name
			pcList = bg_ProductUtils.GetProductsClassification(null, null, new set<string>(searchProductCountries), searchProductName);
			pList = bg_ProductUtils.GetProductsByName(searchProductName, new set<string>(searchProductCountries));
		} else {
			// search by portfolio / product area
			pcList = bg_ProductUtils.GetProductsClassification(searchProductPortfolio, searchProductArea, new set<string>(searchProductCountries), null);
			pList = bg_ProductUtils.GetProducts(searchProductPortfolio, searchProductArea, null, new set<string>(searchProductCountries));
		}

		set<Id> productIds = new set<Id>();
		for(Product_Classification__c pc : pcList) {
			productIds.add(pc.SF_Product__c);
		}

		integer j = 0;
		while (j < pList.size()) {
  			if(productIds.contains(pList.get(j).Id)) {
    			pList.remove(j);
  			} else {
    			j++;
  			}
		}

		ProductSearchResults = new list<bg_Wrappers.ProductWrapper>();
		// Convert results to wrappers
		if(!pList.isEmpty()) {
			ProductSearchResults.addAll(bg_WrapperHelper.CreateProductWrappers(pList));
		}	

		if(!pcList.isEmpty()) {
			ProductSearchResults.addAll(bg_WrapperHelper.CreateProductWrappers(pcList));	
		}
					
		// Clear Suggested results
		SuggestedProductResults = new list<bg_Wrappers.RelatedProductWrapper>();
	}
	
	public void GetSuggestedProducts() {
		/*
			Get list of suggested products
		*/
		UpdateSuggestedProducts(bg_WrapperHelper.GetSelectedProductWrappersMap(ProductSearchResults).keySet());
	}
	
	public void AddProductInterests() {
		/*
			Add Product Interests
		*/		
		if(!bg_StringUtils.IsBlank(opp.Product_Interests__c)) {
			list<string> productInterests = bg_StringUtils.ConvertPicklistValueToList(opp.Product_Interests__c);
			list<Product_Classification__c> pcList = bg_ProductUtils.GetProductsByProductClassification(productInterests);
			
			set<Id> productIds = new set<Id>();
			for(Product_Classification__c pc : pcList) {
				string productName = pc.SF_Product__r.Name;
				AddSelectedProduct(productName, pc);
			}
			
			// Update selected products
			if(!productIds.isEmpty()) { UpdateSuggestedProducts(productIds); }
		}	
	}

	public void AddStandardProduct() {
		/*
			Add Standard Product
		*/
		if(!bg_StringUtils.IsBlank(opp.Full_Standard__c)) {
			Product2 standard = [SELECT Id, Name, RequiresContractReview__c, Division__c, 
									ProductConfigurator__r.Name,
									ProductConfigurator2__r.Name,
									ProductConfigurator3__r.Name 
								FROM Product2 
								WHERE Id = :opp.Full_Standard__c];
			// try add configurator 1
			if(standard.ProductConfigurator__r != null) {
				AddSelectedProduct(standard.ProductConfigurator__r.Name, standard);
			}
			// try add configurator 2
			if(standard.ProductConfigurator2__r != null) {
				AddSelectedProduct(standard.ProductConfigurator2__r.Name, standard);
			}
			// try add configurator 3
			if(standard.ProductConfigurator3__r != null) {
				AddSelectedProduct(standard.ProductConfigurator3__r.Name, standard);
			}

		}
	}

	public void ShowSuggestedProductsFromGrid() {
		/*
			Show Suggested Products From Grid 
		*/
		ShowProductSearch = true;
		UpdateSuggestedProducts(bg_WrapperHelper.GetSelectedProductWrappersMap(productMap.values()).keySet());
	}
	
	private void UpdateSuggestedProducts(set<Id> productIds) {
		// Update Suggested Products
		list<Product_Relationship__c> relatedProducts = bg_ProductUtils.GetSuggestedProducts(productIds, new set<string>(searchProductCountries));
		SuggestedProductResults = bg_WrapperHelper.CreateRelatedProductWrappers(relatedProducts);	
	}
	
	public void ClearSuggestions() {
		/* Clear Suggested Product Results */
		SuggestedProductResults = new list<bg_Wrappers.RelatedProductWrapper>();
	}

	public void AddSelectedProducts() {
		/*
			Add Selected Products to Grid
		*/
		AddSelectedProducts(ProductSearchResults);
		AddSelectedProducts(SuggestedProductResults);
	}

	private void AddSelectedProducts(list<bg_Wrappers.ProductWrapper> productWrappers) {
		/*
			Add Selected Products to Grid
		*/
		if(productWrappers != null && productWrappers.size() > 0) {
			for(bg_Wrappers.ProductWrapper prw : productWrappers) {
				if(prw.Selected) {
					AddSelectedProduct(prw.Name, prw.ProductClassification);
				}
			}
		}
	}

	private void AddSelectedProduct(string productName) {
		AddSelectedProduct(productName, null, null);
	}

	private void AddSelectedProduct(string productName, Product_Classification__c pc) {
		AddSelectedProduct(productName, pc, null);
	}

	private void AddSelectedProduct(string productName, Product2 standard) {
		AddSelectedProduct(productName, null, standard);
	}

	private void AddSelectedProduct(string productName, Product_Classification__c pc, Product2 standard) {
		/*
			Add Selected Product
		*/
		bg_Wrappers.QuoteProductWrapper qpw = GetQuoteProductWrapper(productName, pc, standard);
		
		if(qpw != null) {
			if(productMap.containsKey(qpw.InstanceName)) {
				if(bg_QuoteUtils.CanUserQuoteProduct(qpw.Id, quote.OwnerId)) {				
					qpw.Selected = true;
					if(SelectProduct(qpw)) {
						productAreasMap.get(qpw.Area).IsCollapsed = false;
					} else {
						qpw.Selected = false;
					}
					
				} else {
					qpw.Selected = false;
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'The C-Code level is required to quote for this product (' + productName + ')'));
				}
			}
		}
	}

	private bg_Wrappers.QuoteProductWrapper GetQuoteProductWrapper(string productName, Product_Classification__c pc, Product2 standard) {
		/*
			Get Quote Product Wrapper
		*/

		boolean result = true;
		if(bg_StringUtils.IsBlank(quoId)) {
			result = SaveQuote(true); 
		}
		
		system.debug('GetQuoteProductWrapper - result:' + result);
		
		bg_Wrappers.QuoteProductWrapper qpw;
		if(result) {
	        Product__c product = bg_ProductUtils.GetProductByName(productName);
			system.debug('GetQuoteProductWrapper - product:' + product);

	        qpw = bg_WrapperHelper.CreateQuoteProductWrapper(product, null, pc, standard);		
			system.debug('GetQuoteProductWrapper - qpw:' + qpw);
	
			if(CanSelectProduct(qpw)) {
				if(CheckRequiresContractReview(qpw, opp)) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'The selected standard product requires a completed contract review document'));
				} else {
			        if(!qpw.AllowMultipleInstances && productMap.containsKey(qpw.InstanceName)) {
						qpw = productMap.get(qpw.InstanceName);
			        } else {
			        	system.debug('AddSelectedProduct' + qpw);
			        	AddSelectedProduct(qpw);
			        }

					// Update Single Sell Flag
					UpdateSingleSellProductFlag(qpw, true);			        
				}
			}
		}
		return qpw;	        
	}

	private boolean CheckRequiresContractReview(bg_Wrappers.QuoteProductWrapper qpw, Opportunity opp) {
		/*
			Check Requires Contract Review
		*/
		return qpw.RequiresContractReview &&
		       qpw.StandardId != null &&
				(!opp.Contract_Review_Completed__c ||
				  opp.Full_Standard__c == null || 
				  opp.Full_Standard__c != qpw.StandardId && opp.Contract_Review_Completed__c);
	}

	private void AddSelectedProduct(bg_Wrappers.QuoteProductWrapper qpw) {
		/*
			Add Selected Product
		*/
		// Populate Quote Product & Create Product Site Wrappers
		qpw.Instance = GetNextInstanceNumber(qpw);
		qpw.Selected = true;
		productMap.put(qpw.InstanceName, qpw);

		// Populate Quote Product & Create Product Site Wrappers
		if(qpw.SitesMap.isEmpty()) {
			bg_WrapperHelper.CreateProductSiteWrappers(quote, qpw, sites, true, true);
		}
				
		// Increment count && add to selected map
		bg_Wrappers.ProductAreaWrapper area;
		if(!productAreasMap.containsKey(qpw.area)) {
			area = bg_WrapperHelper.CreateProductAreaWrapper(qpw.Area, qpw.GridView);
			productAreasMap.put(qpw.area, area);
			productAreas.add(area);
			qpw.ProductArea = area;
		}

		productAreasMap.get(qpw.area).products.add(qpw);
		productAreasMap.get(qpw.area).SelectedProductCount++;

		// If registation path is default selected add product to sampling map
		if(!bg_StringUtils.IsBlank(qpw.sitesMap.get(1).RegistrationPath)) {
			bg_Wrappers.ProductSiteWrapper psw = qpw.sitesMap.get(1);
			bg_Wrappers.SiteWrapper site = sites[0];					
			bg_WrapperHelper.AddProductSiteToSamplingMap(samplingMap, qpw, site, psw);
		}
				
		if(qpw.SupportsIMS) {
			bg_WrapperHelper.PopulateIMSFields(qpw, quoId);
			allIMSProducts.add(qpw.InstanceName);
		}
	}
	
	private integer GetNextInstanceNumber(bg_Wrappers.QuoteProductWrapper newQPW) {
		/*
			Get Next Instance Number
		*/
		integer instance = 1;
		if(newQPW.AllowMultipleInstances) {
			for(bg_Wrappers.QuoteProductWrapper qpw : productMap.values()) {
		 		if(qpw.name == newQPW.name && instance <= qpw.instance) {
		 			instance = qpw.instance + 1;
		 		}
			}
		}
		return instance;
	}
	
	/************************************************************************/
	/* Product Grid Methods                                                 */	
	/************************************************************************/	
	public void ToggleShowSelectedOnly() {
		/* Show / Hide Selected Only */
		ShowSelectedOnly = !ShowSelectedOnly;
	}

	public void SelectProductArea() {
		/*
			Select Product Area
		*/
		bg_Wrappers.ProductAreaWrapper prodArea = productAreasMap.get(selectedProductArea);
		if(prodArea != null) {
			prodArea.IsCollapsed = !prodArea.IsCollapsed;
		}
	}
	
	public void SelectProduct() {
		/*
			Select Product
		*/
		SelectProduct(selectedProduct, false);
	}

	public boolean SelectProduct(string productName) {
		/*
			Select Product
		*/		
		return SelectProduct(productName, true);
	}
	
	private boolean SelectProduct(string productName, boolean isNew) {
		/*
			Select Product by name
		*/

		bg_Wrappers.QuoteProductWrapper qpw;
		if(isNew) {	
        	qpw = GetQuoteProductWrapper(productName, null, null);
		} else {
			qpw = productMap.get(productName);
		}
		
		if(qpw != null) {
			return SelectProduct(qpw);
		} else {
			return false;	
		}
	}
		
	private boolean SelectProduct(bg_Wrappers.QuoteProductWrapper qpw) {
		/*
			Select Product by ProductWrapper
		*/
		boolean result = true;
		if(qpw != null) {
			if(!qpw.Selected) {
				UnselectedProduct(qpw);					
			}
		}
		return result;	
	}

	private void UpdateSingleSellProductFlag(bg_Wrappers.QuoteProductWrapper qpw, boolean selected) {
		/* 
			Update Single Sell Flag to control only 1 single sell product on the quote 
		*/
		if(qpw.SingleSellProduct && selected) {
			hasSingletonProduct = true;
		} else if(qpw.SingleSellProduct && !selected) {
			hasSingletonProduct = false;
		}
	}
	
	private boolean CanSelectProduct(bg_Wrappers.QuoteProductWrapper qpw) {
		/*
			Check to see if product can be selected
		*/
		boolean result = true;
		
		// singleton already selected
		if(hasSingletonProduct) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.AdditionalProductsCannotBeAdded));
			result = false;			

		// other product have been selected
		} else if (qpw.SingleSellProduct && productMap.size() > 0) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.ProductCanNotBeAddedWithOtherProducts));
			result = false;
		}
		return result;
	}

	public void ClearProductSelection() {
		/*
			Clear Product Selection
		*/
		for(bg_Wrappers.QuoteProductWrapper prod : productMap.values()) {
			UnselectedProduct(prod);
			prod.SitesMap.clear();
		}
	}

	private void ClearSelectedIMSProducts() {
		/* Clear Select IMS Products */
		for(string name : selectedIMSProducts) {
			productMap.get(name).IMS = false;
		}
		selectedIMSProducts.clear();		
	}

	private void UnselectedProduct(bg_Wrappers.QuoteProductWrapper qpw) {
		/*
			Unselect Product
		*/
		if(productMap.containsKey(qpw.InstanceName)) {
			qpw.Selected = false;
			productMap.remove(qpw.InstanceName);
			qpw.IMS = false;
			selectedIMSProducts.remove(qpw.InstanceName);
			allIMSProducts.remove(qpw.InstanceName);

			// if there is one remaining select IMS product then remove it flag
			if(selectedIMSProducts.size() == 1) {
				ClearSelectedIMSProducts();
			}

			productAreasMap.get(qpw.area).SelectedProductCount--;

			bg_WrapperHelper.RemoveProductFromSamplingMap(samplingMap, qpw);
			
			integer i = 0;
			list<bg_Wrappers.QuoteProductWrapper> products = productAreasMap.get(qpw.area).products;
			for(bg_Wrappers.QuoteProductWrapper product : products) {
				if(product.InstanceName == qpw.InstanceName) {
					products.remove(i);
					break;
				}
				i++;
			}

			// Update Single Sell Flag
			UpdateSingleSellProductFlag(qpw, false);			
		}
	}

	public boolean HasMultipleIMSProducts {
		get {
			return allIMSProducts.size() > 1;
		}
	}

	public void SelectIMSProduct() {
		/* Select IMS Product */
		bg_Wrappers.QuoteProductWrapper qpw = productMap.get(selectedIMSProduct);
		if(qpw.IMS) {
			selectedIMSProducts.add(selectedIMSProduct);
		} else {
			selectedIMSProducts.remove(selectedIMSProduct);
		}
	}

	public void SelectRegistrationPath() {
		/*
			Select Registration Path
		*/
		SelectRegistrationPath(selectedSiteProduct, selectedSite, true);
	}

	private void SelectRegistrationPath(string product, string siteIndex, boolean checkForSampling) {
		/*
			Select Registration Path by product and site names
		*/		
		bg_Wrappers.QuoteProductWrapper prod = productMap.get(product);
		bg_Wrappers.SiteWrapper site = sites[integer.valueOf(siteIndex)-1];
		SelectRegistrationPath(prod, site, checkForSampling);
	}

	private void SelectRegistrationPath(bg_Wrappers.QuoteProductWrapper prod, bg_Wrappers.SiteWrapper site, boolean checkForSampling) {
		/*
			Select Registration Path by product and site wrappers
		*/		
		//if(prod != null && site != null) {
			SelectRegistrationPath(prod, site);
			//HandleHQOnlyRegPath(prod, qpw.sitesMap.get(site.Index).RegistrationPath, checkForSampling);
			if(checkForSampling) {
				CheckForSamplingAvailable(prod);
			}
		//}
	}

	private void SelectRegistrationPath(bg_Wrappers.QuoteProductWrapper qpw, bg_Wrappers.SiteWrapper site, boolean updateSampling, string registrationPath) {
		/*
			Select Registration Path
		*/
		bg_Wrappers.ProductSiteWrapper psw = qpw.sitesMap.get(site.Index);
		psw.RegistrationPath = registrationPath;
		SelectRegistrationPath(qpw, site);

		if(updateSampling) {
			UpdateSampling(qpw);
		}
	}	

	private void HandleHQOnlyRegPaths(bg_Wrappers.QuoteProductWrapper qpw, string registrationPath)
	{
		if(bg_Globals.HQ_ONLY_REG_PATHS.contains(registrationPath))
		{
			for(bg_Wrappers.ProductSiteWrapper psw : qpw.sitesMap.values())
			{
				if(!psw.site.isHQ)
				{
					SelectRegistrationPath(qpw, psw.site, true, '');
				}
			}
		}
	}	

	private void SelectRegistrationPath(bg_Wrappers.QuoteProductWrapper prod, bg_Wrappers.SiteWrapper site) {
		/*
			Select Registration Path
		*/
		bg_Wrappers.ProductSiteWrapper psw = prod.sitesMap.get(site.Index);
		if(bg_StringUtils.IsBlank(psw.RegistrationPath)) {
			psw.Selected = false;
			psw.Selectable = false;
		} else {
			psw.Selected = true;
		}

		// Remove old registration path for sampling map
		bg_WrapperHelper.RemoveProductSiteFromSamplingMap(samplingMap, prod, site, psw);
		// Add new product site to sampling map
		bg_WrapperHelper.AddProductSiteToSamplingMap(samplingMap, prod, site, psw);
		
		HandleHQOnlyRegPaths(prod, psw.RegistrationPath);
	}

	public void SelectRiskLevel() {
		/*
			Select Risk Level
		*/
		SelectRiskLevel(selectedSiteProduct, selectedSite, true);
	}
	
	private void SelectRiskLevel(string product, string siteIndex, boolean checkForSampling) {
		/*
			Select Registration Path by product and site names
		*/		
		bg_Wrappers.QuoteProductWrapper prod = productMap.get(product);
		bg_Wrappers.SiteWrapper site = sites[integer.valueOf(siteIndex)-1];
		SelectRiskLevel(prod, site, checkForSampling);
	}
	
	private void SelectRiskLevel(bg_Wrappers.QuoteProductWrapper prod, bg_Wrappers.SiteWrapper site, boolean checkForSampling) {
		/*
			Select Registration Path by product and site wrappers
		*/		
		//if(prod != null && site != null) {
			SelectRiskLevel(prod, site);
			if(checkForSampling) {
				CheckForSamplingAvailable(prod);
			}
		//}
	}
	
	private void SelectRiskLevel(bg_Wrappers.QuoteProductWrapper qpw, bg_Wrappers.SiteWrapper site, boolean updateSampling, string riskLevel) {
		/*
			Select Risk Level
		*/
		bg_Wrappers.ProductSiteWrapper psw = qpw.sitesMap.get(site.Index);
		psw.RiskLevel = riskLevel;
		SelectRiskLevel(qpw, site);
		if(updateSampling) {
			UpdateSampling(qpw);
		}
	}	
	
	private void SelectRiskLevel(bg_Wrappers.QuoteProductWrapper prod, bg_Wrappers.SiteWrapper site) {
		/*
			Select Risk Level
		*/
		bg_Wrappers.ProductSiteWrapper psw = prod.sitesMap.get(site.Index);
		// Remove old registration path for sampling map
		bg_WrapperHelper.RemoveProductSiteFromSamplingMap(samplingMap, prod, site, psw);
		// Add new product site to sampling map
		bg_WrapperHelper.AddProductSiteToSamplingMap(samplingMap, prod, site, psw);
	}
	
	public void SetProductRegPathToAllSites() {
		/*
			Set Product Registration Path To All Sites
		*/
		bg_Wrappers.QuoteProductWrapper qpw = productMap.get(selectedProdRegPath);
		if(qpw != null) {
			string regPath = qpw.SitesMap.get(1).RegistrationPath; // get first site from map
			for(integer Index : qpw.SitesMap.keySet()) {
				bg_Wrappers.SiteWrapper site = sites[Index-1];
				SelectRegistrationPath(qpw, site, false, regPath);
			}
			UpdateSampling(qpw);
		}
	}

	public void SetProductRiskLevelToAllSites() {
		/*
			Set Product Registration Path To All Sites
		*/
		bg_Wrappers.QuoteProductWrapper qpw = productMap.get(selectedProdRiskLevel);
		if(qpw != null) {
			string riskLevel = qpw.SitesMap.get(1).RiskLevel; // get first site from map
			for(integer Index : qpw.SitesMap.keySet()) {
				bg_Wrappers.SiteWrapper site = sites[Index-1];
				SelectRiskLevel(qpw, site, false, riskLevel);
			}
			UpdateSampling(qpw);
		}
	}
	
	public list<SelectOption> getRiskLevelItems() {
		/* Return list of Risk Level */		
		list<SelectOption> options = new list<SelectOption>();
		options = bg_ControllerUtils.GetPicklistSelectOptions(Quote_Product__c.sObjectType, 'Risk_Level__c');
		//options.add(0, new SelectOption('', '--' + Label.None + '--'));				
		return options;
	}

	public PageReference Next() {
		/*
			Move to next page
		*/
		PageReference nextPage;
		try {
			if(SaveQuote()) {
				nextPage = new Pagereference('/' + bg_QuoteUtils.BuildNewQuoteGridURL(accId, oppId, quoId));
			}
		} catch (exception ex) {
			ApexPages.addMessages(ex);
		}
		return nextPage;
	}

	public PageReference Cancel() {
		/*
			Move to opportunity page
		*/
		PageReference retPage;
		if(bg_StringUtils.IsBlank(quoId)) {
			retPage = new PageReference('/' + oppId);
		} else {
			retPage = new PageReference('/' + quoId);
		}
		return retPage;
	}

	public PageReference ManageSites() {
		/*
			Redirect to Manage Sites page (and perform a quick save)
		*/
		if(SaveQuote(true)) {
			// redirect to manage sites
	    	return new Pagereference('/' + bg_SiteUtils.BuildManageOpportunitySitesURL(oppId, bg_QuoteUtils.BuildNewQuoteURL(accId, oppId, quoId)));
		} else {
			return null; // Quick Save error
		}
	}

	public void QuickSave() {
		SaveQuote(true);
	}
	
	public boolean ValidateQuote (boolean quickSave) {
		/*
			Validate Quote
		*/
		boolean result = true;

		if(!skipPricebookCurrencyCheck && !bg_PricebookUtils.CheckPricebookSupportsCurrency(quote.PriceBook2Id__c, quote.CurrencyIsoCode)) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'The quote pricebook \'' + bg_PricebookUtils.GetPricebookById(quote.PriceBook2Id__c).Name + '\' does not support the opportunity currency \'' + quote.CurrencyIsoCode + '\''));
			result = false;
		}

        // Check products selected
        if(!quickSave) {
	        if (productMap.isEmpty()) {
	            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must select at least one product'));
				result = false;
	        }

	        // Check Sampling answers / questions
	        if(SampleWarnings) {
	        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must confirm all your sampling selections'));
				result = false;        	
	        }

	        if (selectedIMSProducts.size() == 1) {
	            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must select at least two products for IMS '));
				result = false;
	        }

			// Check Quote contacts selected
			if (bg_StringUtils.IsBlank(quote.Contact__c) || 
					bg_StringUtils.IsBlank(quote.Invoice_Contact__c) || 
					bg_StringUtils.IsBlank(quote.Booking__c)|| 
					bg_StringUtils.IsBlank(quote.CreditCheck__c)) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must select all the contacts'));
				ShowSiteSummary = true;
				result = false;
	        }
        }
		
		// QUICK SAVE
		if(quickSave) {
			// Check Quote contacts selected
			if (bg_StringUtils.IsBlank(quote.Contact__c)) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Primary Contact must be selected'));
				ShowSiteSummary = true;
				result = false;
	        }
		}

		system.debug('ApexPages: ' + ApexPages.getMessages());
        return result;
	}
	
	public boolean SaveQuote() {
		/* full save quote */
		return SaveQuote(false);
	}	
	
	public boolean SaveQuote(boolean quickSave) {
		/*
			Save Quote
		*/
		boolean result = false;
		
		if(ValidateQuote(quickSave)) {
			try {
				// Save Quote
			 	quote.VF_ShowSiteSummary__c = ShowSiteSummary;
				quote.VF_ShowProductSearch__c = ShowProductSearch;
			 	quote.VF_ShowSelectionSummary__c = ShowSelectionSummary;

				// Update Opportunity? 
				if(bg_OpportunityUtils.PopulateOpportunityDefaults(opp, isNew, quote.Contact__c)) {
					bg_OpportunityUtils.SaveOpportunity(opp);
				}

				bg_QuoteUtils.SaveQuote(quote, productMap, useDefaults, true);
				
				ClearDeleteQuoteProduct();
				
				useDefaults = false;
				quoId = quote.Id;
				result = true;
			
			} catch (DmlException dml) {
	        	Apexpages.addMessages(dml);
			} catch (Exception ex) {
	        	Apexpages.addMessages(ex);	        	
			}		
		}
		return result;
	} 
	
	public void ClearDeleteQuoteProduct() {
		/*
			Clear any deleted Quote Products
		*/
		for(bg_Wrappers.QuoteProductWrapper qpw : productMap.values()) {
			if(!qpw.Selected) {
				for(bg_Wrappers.ProductSiteWrapper psw: qpw.SitesMap.values()) {
					if(!bg_StringUtils.IsBlank(psw.qpId)) {
						psw.qpId = null;
					}
				}
			}
		}		
	}
	
	/************************************************************************/
	/* Sampling  Summary Methods                                            */	
	/************************************************************************/	
	public string selectedSamplingProduct {get;set;}
	public void UseSampling() {
		/*
			Apply Sampling?
		*/
		bg_Wrappers.QuoteProductWrapper prod = productMap.get(selectedSamplingProduct);
		ApplySampling(prod);
	}
/*
	public void ApplySampling() {
		/ *
			Apply Sampling
		* /
		bg_Wrappers.QuoteProductWrapper qpw = productMap.get(selectedProduct);
		ApplySampling(qpw);
	}
*/
	private void UpdateSampling(bg_Wrappers.QuoteProductWrapper qpw) {
		/*
			Update Sampling Plan
		*/		
		CheckForSamplingAvailable(qpw);
		ApplySampling(qpw);
	}
	
	private void ApplySampling(bg_Wrappers.QuoteProductWrapper qpw) {
		/*
			Apply Sampling
		*/
		bg_WrapperHelper.ApplySampling(qpw.SamplingThreshold, samplingMap, qpw);		
	}

	private void CheckForSamplingAvailable(list<bg_Wrappers.QuoteProductWrapper> qpWrappers) {
		for(bg_Wrappers.QuoteProductWrapper qpw : qpWrappers) {
			CheckForSamplingAvailable(qpw);
		}
	}

	public void CheckForIMSAvailableQuestion() {
		/* Check For IMS Available Question */
		bg_QuoteUtils.PopulateIMSFields(quote);
	}

	public void CheckForSamplingAvailableQuestion() {
		/* Check For Sampling Available */
		CheckForSamplingAvailable(selectedProduct, true);
	}

	public void CheckForSamplingAvailable() {
		/* Check For Sampling Available */
		CheckForSamplingAvailable(selectedProduct, false);
	}

	private void CheckForSamplingAvailable(string prodName) {
		/* Check For Sampling Available */
		CheckForSamplingAvailable(prodName, false);
	}

	private void CheckForSamplingAvailable(string prodName, boolean checkProductQuestion) {
		/* Check For Sampling Available */
		bg_Wrappers.QuoteProductWrapper qpw = productMap.get(prodName);
		CheckForSamplingAvailable(qpw, checkProductQuestion);
		if(checkProductQuestion) { ApplySampling(qpw); }
	}

	private void CheckForSamplingAvailable(bg_Wrappers.QuoteProductWrapper qpw) {
		/* Check For Sampling Available */
		CheckForSamplingAvailable(qpw, false);
	}
	private void CheckForSamplingAvailable(bg_Wrappers.QuoteProductWrapper qpw, boolean checkProductQuestion) {
		/*
			Check For Sampling Available
		*/		
		SampleWarnings = bg_WrapperHelper.CheckForSamplingAvailable(quoId, qpw.samplingThreshold, samplingMap, qpw, checkProductQuestion);
		
		if(!qpw.SamplingAvailable) {
			for(bg_Wrappers.ProductSiteWrapper psw : qpw.SitesMap.values()) {
				if(!psw.Selected && !bg_StringUtils.IsBlank(psw.RegistrationPath)) {
					psw.Selected = !bg_StringUtils.IsBlank(psw.RegistrationPath);
				}
			}
		}
		if(SampleWarnings) { ShowSelectionSummary = true; }		
	}

	public void CreateSamplingQuestion() {
		/* Create Sampling Question Product */
		if(!bg_StringUtils.IsBlank(selectedSamplingProduct)) {
			integer instance = productMap.get(selectedSamplingProduct).Instance;
			bg_QuoteUtils.GetSampleQuestionProduct(selectedSamplingProduct, quoId, true, instance);
		}
	}

	public void CreateIMSQuestion() {
		/* Create IMS Question Product */
		if(!bg_StringUtils.IsBlank(selectedIMSProduct)) {
			bg_QuoteUtils.GetIMSQuestionProduct(selectedIMSProduct, quoId, true);
		}
	}
	
	/************************************************************************/
	/* Selection Summary Methods                                            */	
	/************************************************************************/	
	public void ToggleSelectionSummary() {
		ShowSelectionSummary = !ShowSelectionSummary;
	}	

	/************************************************************************/
	/* Site Summary Methods                                                 */	
	/************************************************************************/	
	public void ToggleSiteSummary() {
		ShowSiteSummary = !ShowSiteSummary;
	}
}