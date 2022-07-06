/********************************************************************
 * ProductInterestComponentController2
 *
 * Product Interest Component Controller
 * 
 * Author: Rob Earey
 * Created: 10/10/2013
 * Changes: 23/10/2013 Richard Jimenez 
 *            - Added saving of multiple Portfolio / Area interests
 *        : 31/08/2017 ADS
 *            - Production Classification Fields; Division, Portoflio, Sector, Stream and Theme are now picklists
 ********************************************************************/
public with sharing class ProductInterestComponentController2 {
	
	private final integer DIR_NONE = 0;
    private final integer DIR_DOWN = 1;
    private final integer DIR_UP = 2;
    
	// public variables
	private boolean isInitialised = false;
    public sObject objRecord {get; set;} 
	public boolean editMode {get; set;}

	// public page selected values
	public string selectedStream {get; set;}
    public string selectedSubStream {get; set;}
    public string selectedPortfolio {get; set;}
	public string selectedFamily {get; set;}    
	public string selectedProduct {get; set;}  
 	
	public list<string> selectedStreams {get; set;}
	public list<string> selectedSubStreams {get; set;}
	public list<string> selectedPortfolios {get; set;}
	public list<string> selectedFamilies {get; set;}
	public list<string> selectedProducts {get; set;}

	private list<string> shadowSelectedStreams {get; set;}
	private list<string> shadowSelectedSubStreams {get; set;}
	private list<string> shadowSelectedPortfolios {get; set;}
	private list<string> shadowSelectedFamilies {get; set;}
	private list<string> shadowSelectedProducts {get; set;}
	
	public boolean showAllStreams {get; set;}
	public boolean showAllSubStreams {get; set;}	
	public boolean showAllPortfolios {get; set;}
	public boolean showAllFamilies {get; set;}
	public boolean showAllProducts {get; set;}

	// TOP PAGE CONTROL
	public boolean reloadNeeded {get; private set;}
	public string reloadPageURL {get; private set;}

    public ProductInterestComponentController2() {
    	/*
    		Controller Constructor
    	*/
    	editMode = true;
    }

	public void Initialise()  {
		/*
			Initialise 
		*/
		if(!isInitialised)  {
			isInitialised = true;

			SetupSelectionLists();

			showAllStreams = false;
			showAllSubStreams = false;
			showAllPortfolios = false;
			showAllFamilies = false;
			showAllProducts = false;
		}
	}

	private void SetupSelectionLists() {
		/*
			Setup Selection Lists
		*/
		selectedStreams = new list<string>();
		selectedSubStreams = new list<string>();
		selectedPortfolios = new list<string>();
		selectedFamilies = new list<string>();
		selectedProducts = new list<string>();

		shadowSelectedStreams = new list<string>();
		shadowSelectedSubStreams = new list<string>();
		shadowSelectedPortfolios = new list<string>();
		shadowSelectedFamilies = new list<string>();
		shadowSelectedProducts = new list<string>();
		
		if(!bg_StringUtils.IsBlank((string)objRecord.get('Product_Stream__c'))) {
			selectedStreams = ((string)objRecord.get('Product_Stream__c')).split(';');
			shadowSelectedStreams.addAll(selectedStreams);
		}
		if(!bg_StringUtils.IsBlank((string)objRecord.get('Product_SubStream__c'))) {
			selectedSubStreams = ((string)objRecord.get('Product_SubStream__c')).split(';');
			shadowSelectedSubStreams.addAll(selectedSubStreams);
		}
		if(!bg_StringUtils.IsBlank((string)objRecord.get('Portfolio_Interests__c'))) {
			selectedPortfolios = ((string)objRecord.get('Portfolio_Interests__c')).split(';');
			shadowSelectedPortfolios.addAll(selectedPortfolios);
		}
		if(!bg_StringUtils.IsBlank((string)objRecord.get('Product_Area_Interests__c'))) {
			selectedFamilies = ((string)objRecord.get('Product_Area_Interests__c')).split(';');
			shadowSelectedFamilies.addAll(selectedFamilies);			
		}
		if(!bg_StringUtils.IsBlank((string)objRecord.get('Product_Interests__c'))) {
			selectedProducts = ((string)objRecord.get('Product_Interests__c')).split(';');
			shadowSelectedProducts.addAll(selectedProducts);
		}
	}
	
	public void ShowStreams() {
		/*	Toggle Show Streams */
		showAllStreams = !showAllStreams;
	}
	public void ShowSubStreams() {
		/*	Toggle Show Streams */
		showAllSubStreams = !showAllSubStreams;
	}
	public void ShowPortfolios() {
		/*	Toggle Show Streams */
		showAllPortfolios = !showAllPortfolios;
	}
	public void ShowFamilies() {
		/*	Toggle Show Streams */
		showAllFamilies = !showAllFamilies;
	}
	public void ShowProducts() {
		/*	Toggle Show Streams */
		showAllProducts = !showAllProducts;
	}

    public list<SelectOption> getStreamOptions() {
		/*
			Return Select Option list of Stream
		*/
		if(!isInitialised) { Initialise(); }
    	
    	list<AggregateResult> values = GetOptionValues('Stream2__c', '', selectedSubstream, selectedPortfolio, selectedFamily, selectedProduct);
    	list<SelectOption> optionItems = bg_ControllerUtils.CreateSelectOptions(values, 'Stream2__c', 'Stream2__c', true, true);
    	return optionItems; // return list of select options
    }
    
    public list<SelectOption> getSubStreamOptions() {
		/*
			Return Select Option list of SubStream
		*/
		if(!isInitialised) { Initialise(); }

    	list<AggregateResult> values = GetOptionValues('SubStream__c', selectedStream, '', selectedPortfolio, selectedFamily, selectedProduct);
    	list<SelectOption> optionItems = bg_ControllerUtils.CreateSelectOptions(values, 'SubStream__c', 'SubStream__c', true, true);  	
    	return optionItems; // return list of select options
    }
    
    public list<SelectOption> getPortfolioOptions() {
		/*
			Return Select Option list of Portfolios
		*/
		if(!isInitialised) { Initialise(); }

		list<AggregateResult> values = GetOptionValues('Portfolio2__c', selectedStream, selectedSubStream, '', selectedFamily, selectedProduct);
    	list<SelectOption> optionItems = bg_ControllerUtils.CreateSelectOptions(values, 'Portfolio2__c', 'Portfolio2__c', true, true);  			
    	return optionItems; // return list of select options
    }

    public list<SelectOption> getFamilyOptions() {
		/*
			Return Select Option list of Families
		*/    	
		if(!isInitialised) { Initialise(); }
    	
		list<AggregateResult> values = GetOptionValues('Family2__c', selectedStream, selectedSubstream, selectedPortfolio, '', selectedProduct);
    	list<SelectOption> optionItems = bg_ControllerUtils.CreateSelectOptions(values, 'Family2__c', 'Family2__c', true, true);  			
    	return optionItems; // return list of select options
    }

   public list<SelectOption> getProductOptions() {
		/*
			Return Select Option list of Products
		*/
		if(!isInitialised) { Initialise(); }
    	
		list<AggregateResult> values = GetOptionValues('Product__c', selectedStream, selectedSubstream, selectedPortfolio, selectedFamily, '');
    	list<SelectOption> optionItems = bg_ControllerUtils.CreateSelectOptions(values, 'Product__c', 'Product__c', true, true);  			
    	return optionItems; // return list of select options
    }
    
    private list<AggregateResult> GetOptionValues(string fieldname, string stream, string substream, string portfolio, string family, string product) {
    	/*
    		Method to return unique list of values from Product Classification object
    	*/
    	
    	string query = 'SELECT ' + fieldname + ' FROM Product_Classification__c ';    	
    	string whereClause = 'WHERE ';
    	if(!bg_StringUtils.IsBlank(stream)) {
    		whereClause += 'Stream2__c = :stream AND ';
    	}
    	if(!bg_StringUtils.IsBlank(substream)) {
    		whereClause += 'SubStream__c = :substream AND ';
    	} 
   	    if(!bg_StringUtils.IsBlank(portfolio)) {
    		whereClause += 'Portfolio2__c = :portfolio AND ';
    	}
   	    if(!bg_StringUtils.IsBlank(family)) {
    		whereClause += 'Family2__c = :family AND ';
    	}
		if(!bg_StringUtils.IsBlank(product)) {
    		whereClause += 'Product__c = :product AND ';
    	}
    	string groupBy = 'GROUP BY ' + fieldname;
    	
    	if(whereClause.length() > 6) { 
    		query += whereClause.substring(0, whereClause.length()-4) + groupBy;
    	} else {
    		query += groupBy;
    	}
    	
    	system.debug('query: ' + query);

    	return (list<AggregateResult>)database.query(query);
    }

    public void SelectStream() {
    	/* Select Stream */
    	SelectStream(DIR_DOWN);

    }
    
    public void SelectStream(integer direction) {
    	/*
    		Select Stream
    	*/   	
    	if(!bg_StringUtils.IsBlank(selectedStream)) {
	    	if(direction == DIR_DOWN) {
	    		list<AggregateResult> results = GetOptionValues('SubStream__c', selectedStream, '', '', '', '');
		    	if(1 == results.size()) {
		    		selectedSubStream = (string)results[0].get('SubStream__c');	    	
		    		SelectSubStream(DIR_DOWN);
		    	}
	    	}
		} else {
	    	ClearSubStream();
    	}
    }

    public void SelectSubStream() {
    	SelectSubStream(DIR_NONE);
    }
    
    public void SelectSubStream(integer direction) {
    	/*
    		Select Sub Stream
    	*/
    	if(!bg_StringUtils.IsBlank(selectedSubStream)) {
    		if(direction == DIR_DOWN || direction == DIR_NONE) {
	    		list<AggregateResult> results = GetOptionValues('Portfolio2__c', selectedStream, selectedSubStream, '', '', '');
		    	if(1 == results.size()) {
		    		selectedPortfolio = (string)results[0].get('Portfolio2__c');	    	
		    		SelectPortfolio(DIR_DOWN);
		    	}
    		}

    		if(direction == DIR_UP || direction == DIR_NONE) {
    			if(!bg_StringUtils.IsBlank(selectedStream)) {
		    		SelectStream(DIR_UP);
    			} else {
		    		list<SelectOption> optionItems = getStreamOptions();
		    		list<AggregateResult> results = GetOptionValues('Stream2__c', '', selectedSubStream, selectedPortfolio, selectedFamily, selectedProduct);
			    	if(1 == results.size()) {	  	    		
						selectedStream = (string)results[0].get('Stream2__c');
						SelectStream(DIR_UP);
			    	}
    			}

    		}   		
    	} else {
			ClearPortfolio();
    	}
    }
    
    public void SelectPortfolio() {
    	/* Select Portfolio */    	
    	SelectPortfolio(DIR_NONE);    	
    }
    
    public void SelectPortfolio(integer direction) {
    	/*
    		Select Portfolio
    	*/
    	if(!bg_StringUtils.IsBlank(selectedPortfolio)) {
    		if(direction == DIR_DOWN || direction == DIR_NONE) {
	    		list<AggregateResult> results = GetOptionValues('Family2__c', selectedStream, selectedSubStream, selectedPortfolio, '', '');
		    	if(1 == results.size()) {
		    		selectedFamily = (string)results[0].get('Family2__c');	    	
		    		SelectFamily(DIR_DOWN);
		    	}
    		}    		    		

    		if(direction == DIR_UP || direction == DIR_NONE) {
    			if(!bg_StringUtils.IsBlank(selectedSubStream)) {
    				SelectSubStream(DIR_UP);
    			} else {
		    		list<AggregateResult> results = GetOptionValues('SubStream__c', '', '', selectedPortfolio, selectedFamily, selectedProduct);
			    	if(1 == results.size()) {	    	
			    		selectedSubStream = (string)results[0].get('SubStream__c');
			    		SelectSubStream(DIR_UP);
			    	}
    			}
    		} 		
    	} else {
			ClearFamily();
    	}   	
    }

    public void SelectFamily(){
		/* Select Family */
    	SelectFamily(DIR_NONE);
    }
    
    public void SelectFamily(integer direction){
    	/*
    		Select Family
    	*/
    	if(!bg_StringUtils.IsBlank(selectedFamily)) {
    		if(direction == DIR_DOWN || direction == DIR_NONE) {
	    		list<AggregateResult> results = GetOptionValues('Product__c', selectedStream, selectedSubStream, selectedPortfolio, selectedFamily, '');
		    	if(1 == results.size()) {
		    		selectedProduct = (string)results[0].get('Product__c');
		    		SelectProduct();	    	
		    	}
    		}   	 

    		if(direction == DIR_UP || direction == DIR_NONE) {
    			if(!bg_StringUtils.IsBlank(selectedPortfolio)) {
    				SelectPortfolio(DIR_UP);
    			} else {
		    		list<AggregateResult> results = GetOptionValues('Portfolio2__c', '', '', '', selectedFamily, selectedProduct);
			    	if(1 == results.size()) {	    	
			    		selectedPortfolio = (string)results[0].get('Portfolio2__c');
			    		SelectPortfolio(DIR_UP);
			    	}
    			}
    		}
    	} else {
			ClearProduct();
    	}  	
    }

    public void SelectProduct() {
    	/*
    		Select Product
    	*/
    	if(!bg_StringUtils.IsBlank(selectedProduct)) {
	    	Product_Classification__c pc = [SELECT Stream2__c, Substream__c, Portfolio2__c, Family2__c 
	    									FROM Product_Classification__c 
	    									WHERE Product__c = :selectedProduct];
	    	selectedStream = pc.Stream2__c;
	    	selectedSubStream = pc.SubStream__c;
	    	selectedPortfolio = pc.Portfolio2__c;
	    	selectedFamily = pc.Family2__c;
    	}
    }
    
    public void ClearAll() { 
    	/*
    		Reset Lists
    	*/	
    	ClearStream();
    	ClearSubStream();
    	ClearPortfolio();
    	ClearFamily();
    	ClearProduct();
    }

    public void ClearStream() { 
    	/* Reset Product */	
    	selectedStream = '';
    	ClearSubStream();
    	ClearPortfolio();
    	ClearFamily();
    	ClearProduct();
    }

    public void ClearSubStream() { 
    	/* Reset Product */	
    	selectedSubStream = '';
    	ClearPortfolio();
    	ClearFamily();
    	ClearProduct();    	
    }

    public void ClearPortfolio() { 
    	/* Reset Product */	
    	selectedPortfolio = '';
    	ClearFamily();
    	ClearProduct();    	
    }

    public void ClearFamily() { 
    	/* Reset Product */	
    	selectedFamily = '';
		ClearProduct();    	
    }

    public void ClearProduct() { 
    	/* Reset Product */	
    	selectedProduct = '';
    }
	
	public void SelectListProduct() {
		/*
			Select List Product
		*/
		if(selectedProducts.size() > shadowSelectedProducts.size()) {				
			for(Product_Classification__c pc : [SELECT Stream2__c, SubStream__c, Portfolio2__c, Family2__c, Product__c 
												FROM Product_Classification__c 
												WHERE Product__c IN :selectedProducts]) {
				AddSelection(pc.Stream2__c, pc.SubStream__c, pc.Portfolio2__c, pc.Family2__c, pc.Product__c);
			}
		}
		shadowSelectedProducts.Clear();
		shadowSelectedProducts.addAll(selectedProducts);
	}
	
	public void SelectListFamily() {
		/*
			Select List Product
		*/		
		if(selectedFamilies.size() > shadowSelectedFamilies.size()) {
			for(Product_Classification__c pc : [SELECT Stream2__c, SubStream__c, Portfolio2__c, Family2__c 
												FROM Product_Classification__c 
												WHERE Family2__c IN :selectedFamilies]) {
				AddSelection(pc.Stream2__c, pc.SubStream__c, pc.Portfolio2__c, pc.Family2__c, '');
			}
		}
		shadowSelectedFamilies.Clear();
		shadowSelectedFamilies.addAll(selectedFamilies);									
	}

	public void SelectListPortfolio() {
		/*
			Select List Product
		*/
		if(selectedPortfolios.size() > shadowSelectedPortfolios.size()) {
			for(Product_Classification__c pc : [SELECT Stream2__c, SubStream__c, Portfolio2__c 
												FROM Product_Classification__c 
												WHERE Portfolio2__c IN :selectedPortfolios]) {
				AddSelection(pc.Stream2__c, pc.SubStream__c, pc.Portfolio2__c, '', '');
			}
		}
		shadowSelectedPortfolios.Clear();
		shadowSelectedPortfolios.addAll(selectedPortfolios);				
	}
	
	public void SelectListSubStream() {
		/*
			Select List Product
		*/
		if(selectedSubStreams.size() > shadowSelectedSubStreams.size()) {
			for(Product_Classification__c pc : [SELECT Stream2__c, SubStream__c 
												FROM Product_Classification__c 
												WHERE SubStream__c IN :selectedSubStreams]) {
				AddSelection(pc.Stream2__c, pc.SubStream__c, '', '', '');
			}
		}
		shadowSelectedSubStreams.Clear();
		shadowSelectedSubStreams.addAll(selectedSubStreams);
	}
	
    public void AddSelection() {
		/*
			Add Selection to lists
		*/
		AddSelection(selectedStream, selectedSubStream, selectedPortfolio, selectedFamily, selectedProduct);		
    }

	public void RemoveAll() {
		/* Remove All */
		selectedStreams.Clear();
		shadowSelectedStreams.Clear();
		selectedSubStreams.Clear();
		shadowSelectedSubStreams.Clear();
		selectedPortfolios.Clear();
		shadowSelectedPortfolios.Clear();
		selectedFamilies.Clear();
		shadowSelectedFamilies.Clear();
		selectedProducts.Clear();
		shadowSelectedProducts.Clear();
	}
	
	private void AddSelection(string stream, string substeam, string portfolio, string family, string product) {
		/*
			Method to add values to selection
		*/
		if(!bg_StringUtils.IsBlank(stream) && !(new set<string>(selectedStreams).contains(stream))) {
			selectedStreams.add(stream);
			shadowSelectedStreams.add(stream);
		}
		if(!bg_StringUtils.IsBlank(substeam) && !(new set<string>(selectedSubStreams).contains(substeam))) {
			selectedSubStreams.add(substeam);
			shadowSelectedSubStreams.add(substeam);
		}
		if(!bg_StringUtils.IsBlank(portfolio) && portfolio!='None' && !(new set<string>(selectedPortfolios).contains(portfolio))) {
			selectedPortfolios.add(portfolio);
			shadowSelectedPortfolios.add(portfolio);
		}
		if(!bg_StringUtils.IsBlank(family) && family!='None' && !(new set<string>(selectedFamilies).contains(family))) {
			selectedFamilies.add(family);
			shadowSelectedFamilies.add(family);
		}
		if(!bg_StringUtils.IsBlank(product) && !(new set<string>(selectedProducts).contains(product))) {
			selectedProducts.add(product);
			shadowSelectedProducts.add(product);
		}
	}
    
	private void ReloadPage() {
		/*
			Reload Page
		*/
		reloadNeeded = true;
		reloadPageURL = getCurrentPageUrl();
	}
	
	private string getCurrentPageUrl() {
		/*
			Reload the full page
		*/
		ApexPages.StandardController sc = new ApexPages.StandardController(objRecord);	
		PageReference pageRef = sc.view();
		return pageRef.getUrl();	
	}
	
    public void Save() {
		/*
			Save selection
		*/
		
		objRecord.put('Product_Stream__c', bg_StringUtils.ConvertToPicklistValue(selectedStreams));
		objRecord.put('Product_SubStream__c', bg_StringUtils.ConvertToPicklistValue(selectedSubStreams));
		objRecord.put('Portfolio_Interests__c', bg_StringUtils.ConvertToPicklistValue(selectedPortfolios));
		objRecord.put('Product_Area_Interests__c', bg_StringUtils.ConvertToPicklistValue(selectedFamilies));
		objRecord.put('Product_Interests__c', bg_StringUtils.ConvertToPicklistValue(selectedProducts));

		// save (Lead or Opportunity depending on sObject type)
		try {
			if(objRecord.getSObjectType() == Lead.sObjectType) {
				bg_LeadUtils.SaveLead((Lead)objRecord);	
			}
			else if(objRecord.getSObjectType() == Opportunity.sObjectType) {
				bg_OpportunityUtils.SaveOpportunity((Opportunity)objRecord);	
			}
			
			ReloadPage();
		} catch (Exception ex) {
			apexPages.addMessages(ex);
		}
    }

	public void Cancel() {
		/*
			Cancel changes
		*/
		SetupSelectionLists();
	}
	
   public list<SelectOption> getStreamItems() {
		/*
			Return Select Option list of Products
		*/
		if(!isInitialised) { Initialise(); }
    	
    	list<SelectOption> optionItems;
    	if(showAllStreams) {
			list<AggregateResult> values = GetOptionValues('Stream2__c', '', '', '', '', '');
    		optionItems = bg_ControllerUtils.CreateSelectOptions(values, 'Stream2__c', 'Stream2__c', true, false);  			
    	} else {
    		optionItems = bg_ControllerUtils.CreateSelectOptions(selectedStreams, true, false); 
    	}
    	return optionItems; // return list of select options
	}			
    
	public list<SelectOption> getSubStreamItems() {
		/*
			Return Select Option list of Products
		*/
		if(!isInitialised) { Initialise(); }
    	
    	list<SelectOption> optionItems;
    	if(showAllSubStreams) {
			list<AggregateResult> values = GetOptionValues('SubStream__c', '', '', '', '', '');
    		optionItems = bg_ControllerUtils.CreateSelectOptions(values, 'SubStream__c', 'SubStream__c', true, false);
    	} else {
    		optionItems = bg_ControllerUtils.CreateSelectOptions(selectedSubStreams, true, false); 
    	}  			
    	return optionItems; // return list of select options
    }			

	public list<SelectOption> getPortfolioItems() {
		/*
			Return Select Option list of Products
		*/
		if(!isInitialised) { Initialise(); }
    	
    	list<SelectOption> optionItems;
    	if(showAllPortfolios) {
			list<AggregateResult> values = GetOptionValues('Portfolio2__c', '', '', '', '', '');
    		optionItems = bg_ControllerUtils.CreateSelectOptions(values, 'Portfolio2__c', 'Portfolio2__c', true, false);
    	} else {
    		optionItems = bg_ControllerUtils.CreateSelectOptions(selectedPortfolios, true, false); 
    	}  	  			
    	return optionItems; // return list of select options
    }			

	public list<SelectOption> getFamilyItems() {
		/*
			Return Select Option list of Products
		*/
		if(!isInitialised) { Initialise(); }
    	
    	list<SelectOption> optionItems;
    	if(showAllFamilies) {
			list<AggregateResult> values = GetOptionValues('Family2__c', '', '', '', '', '');
    		optionItems = bg_ControllerUtils.CreateSelectOptions(values, 'Family2__c', 'Family2__c', true, false);
    	} else {
    		optionItems = bg_ControllerUtils.CreateSelectOptions(selectedFamilies, true, false); 
    	}  	
    	return optionItems; // return list of select options
    }
    
	public list<SelectOption> getProductItems() {
		/*
			Return Select Option list of Products
		*/
		if(!isInitialised) { Initialise(); }
    	
    	list<SelectOption> optionItems;
    	if(showAllProducts) {
			list<AggregateResult> values = GetOptionValues('Product__c', '', '', '', '', '');
    		optionItems = bg_ControllerUtils.CreateSelectOptions(values, 'Product__c', 'Product__c', true, false);
    	} else {
    		optionItems = bg_ControllerUtils.CreateSelectOptions(selectedProducts, true, false); 
    	}     	  			
    	return optionItems; // return list of select options
    }

	public void ClearSelectedStreams() {
		/* Clear Selected Streams */
		selectedStreams.Clear();
		shadowSelectedStreams.Clear();
	}
	
	public void ClearSelectedSubStreams() {
		/* Clear Selected SubStreams */
		selectedSubStreams.Clear();
		shadowSelectedSubStreams.Clear();
	}
	
	public void ClearSelectedPortfolios() {
		/* Clear Selected SubStreams */
		selectedPortfolios.Clear();
		shadowSelectedPortfolios.Clear();		
	}
	
	public void ClearSelectedFamilies() {
		/* Clear Selected Families */
		selectedFamilies.Clear();
		shadowSelectedFamilies.Clear();
	}
	
	public void ClearSelectedProducts() {
		/* Clear Selected Products */
		selectedProducts.Clear();
		shadowSelectedProducts.Clear();		
	}	
}