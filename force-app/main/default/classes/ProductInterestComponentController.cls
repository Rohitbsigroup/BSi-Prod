/********************************************************************
 * ProductInterestComponentController
 *
 * Product Interest Component Controller
 * 
 * Author: Rob Earey
 * Created: 10/10/2013
 * Changes: 23/10/2013 Richard Jimenez 
 *            - Added saving of multiple Portfolio / Area interests
 ********************************************************************/
public with sharing class ProductInterestComponentController {
	
	// public variables
    public sObject objRecord {get; set;} 
	public boolean editMode {get; set;}

	// public page selected values
    public string selectedPortfolio {get; set;}
	public string selectedProductArea {get; set;}    
	public string selectedProduct {get; set;}  
	public string selectedProductBundle {get; set;}  	

	private list<string> pUnselectProducts;
	public list<string> UnselectProducts {
		get {
			if(!isInitialised) { Initialise(); }	
			return pUnselectProducts;
		}
		set {
			pUnselectProducts = value;
		}	
	}

	private list<string> pbundleProducts;
 	public list<string> bundleProducts {
		get {
			if(!isInitialised) { Initialise(); }	
			return pbundleProducts;
		}
		set;
	}
	 		
	// Product Interest Maps
	private map<string, bg_Wrappers.ProductWrapper> productWrapperMap; // Product Wrapper Map	    
	private map<string, map<string, map<string, bg_Wrappers.ProductWrapper>>> ppiwMap;	
	
	public map<string, map<string, map<string, bg_Wrappers.ProductWrapper>>> piwMap {
		get {
			if(!isInitialised) { Initialise(); }	
			return ppiwMap;
		}
		set;
	}  // Product Interest Wrapper Map
	
    public ProductInterestComponentController() {
    	/*
    		Controller Constructor
    	*/
    	editMode = true;
    }

	boolean isInitialised = false;
	private void Initialise()  {
		if(!isInitialised)  {
			isInitialised = true;			
			pUnselectProducts = new list<string>();
			pbundleProducts = new list<string>();
			// load products & wrappers
			productWrapperMap = bg_WrapperHelper.CreateProductWrappersMap(bg_ProductUtils.GetProducts());		
			// create product interest map
			InitialisePIWrappersMap();
		}
	}
	    
    private void InitialisePIWrappersMap() {
    	/*
    		Initialise PI Wrappers Map
    	*/
		// convert selected products to list
		list<string> selectedProducts = bg_StringUtils.ConvertPicklistValueToList((string)objRecord.get('Product_Interests__c'));
		// create product interest map
		ppiwMap = bg_WrapperHelper.CreateProductInterestsWrapperMap(productWrapperMap, selectedProducts);			
    }
    
    public list<SelectOption> getPortfolioOptions() {
		/*
			Return Select Option list of Portfolios
		*/
		if(!isInitialised) { Initialise(); }
		
    	list<SelectOption> optionItems = bg_ControllerUtils.CreateSelectOptions(ppiwMap.keySet(), true, true);    	
    	return optionItems; // return list of select options
    }

    public list<SelectOption> getProductAreaOptions() {
		/*
			Return Select Option list of Product Areas
		*/    	
		if(!isInitialised) { Initialise(); }
    	
    	list<SelectOption> optionItems = new list<SelectOption>();
    	// check portfolio selected
    	if(!bg_StringUtils.IsBlank(selectedPortfolio)) {
    		optionItems = bg_ControllerUtils.CreateSelectOptions(ppiwMap.get(selectedPortfolio).keySet(), true, true);
    	}
    	return optionItems; // return list of select options
    }

 	public list<SelectOption> getProductBundleOptions() {
		/*
			Return Select Option list of Product Bundles
		*/ 
		if(!isInitialised) { Initialise(); }
		
 		list<SelectOption> optionItems = new list<SelectOption>();
 		list<Product_Bundle__c> bundles;
 	
 		if(!bg_StringUtils.IsBlank(selectedProduct)) {
			bundles = bg_ProductUtils.GetProductBundles(bg_ProductUtils.GetProductByName(selectedProduct).Id); 			
 		} else if (!bg_StringUtils.IsBlank(selectedProductArea)) {
 			bundles = bg_ProductUtils.GetProductBundles(bg_ProductUtils.GetProductMap(bg_ProductUtils.GetProductsByProductArea(selectedProductArea)).keySet());
 		} else if (!bg_StringUtils.IsBlank(selectedPortfolio)) {
 			bundles = bg_ProductUtils.GetProductBundles(bg_ProductUtils.GetProductMap(bg_ProductUtils.GetProductsByPortfolio(selectedPortfolio)).keySet());
 		} else {
 			bundles = bg_ProductUtils.GetProductBundles();
 		}

		optionItems = bg_ControllerUtils.CreateSelectOptions(bundles, 'Name', 'Name', true, true);
 		
 		return optionItems; // return list of select options
 	}
 	
 	public void SelectProductBundle() {
 		if(!bg_StringUtils.IsBlank(selectedProductBundle)) {
 			pbundleProducts = bg_ProductUtils.GetProductNamesInBundle(selectedProductBundle);
 		} else {
 			pbundleProducts.clear();
 		}
 	}

    public list<SelectOption> getProductOptions() {
		/*
			Return Select Option list of Products
		*/
		if(!isInitialised) { Initialise(); }
		   	
    	list<SelectOption> optionItems = new list<SelectOption>();
		// check portfolio and area selected
    	if(!bg_StringUtils.IsBlank(selectedPortfolio) && !bg_StringUtils.IsBlank(selectedProductArea)) {
    		optionItems = bg_ControllerUtils.CreateSelectOptions(ppiwMap.get(selectedPortfolio).get(selectedProductArea).keySet(), true, true);
    	} else if(!bg_StringUtils.IsBlank(selectedPortfolio)) {
    		
    		set<string> products = new set<string>();
    		for(string productArea : ppiwMap.get(selectedPortfolio).keySet()) {
	    		products.addAll(ppiwMap.get(selectedPortfolio).get(productArea).keySet());
    		}
    		optionItems = bg_ControllerUtils.CreateSelectOptions(products, true, true);
    		
    	} else if(bg_StringUtils.IsBlank(selectedPortfolio) && bg_StringUtils.IsBlank(selectedProductArea)) {

    		set<string> products = new set<string>();
    		for(string portfolio : ppiwMap.keySet()) {
    			for(string productArea : ppiwMap.get(portfolio).keySet()) {
		    		products.addAll(ppiwMap.get(portfolio).get(productArea).keySet());
	    		}
    			optionItems = bg_ControllerUtils.CreateSelectOptions(products, true, true);
    		}
    		
    	}
    	return optionItems; // return list of select options
    }

    public list<SelectOption> getSelectedProductsList() {
		/*
			Return list of selected products
		*/    	
		if(!isInitialised) { Initialise(); }
		
    	list<string> products = new list<string>();    
    	// loop through product wrappers and create selected list	
    	for(bg_Wrappers.ProductWrapper pw : productWrapperMap.values()) {
    		if(pw.Selected) {
    			products.add(pw.Name);
    		}
    	}
    	products.sort(); // sort alphabetical list
		// build selected product select list
    	list<SelectOption> optionItems = new list<SelectOption>();    	
    	for(string product : products) {
    		optionItems.add(new SelectOption(product, product));
    	}
    	return optionItems; // return list of select options    	
    }
    
    public void SelectPortfolio() {
    	/*
    		Select Portfolio
    	*/    	
    	selectedProductArea = '';	// reset selected product area
		selectedProduct = '';  		// reset selected product
		selectedProductBundle = ''; // reset selected product bundle
		pbundleProducts.Clear();		// reset selected product bundle
    }

    public void SelectProductArea(){
    	/*
    		Select Product Area
    	*/
		selectedProduct = '';       // reset selected product
		selectedProductBundle = ''; // reset selected product bundle
		pbundleProducts.Clear();		// reset selected product bundle		
    }

    public void SelectProduct() {
    	/*
    		Select Product
    	*/
		selectedProductBundle = ''; // reset selected product bundle
		pbundleProducts.Clear();		// reset selected product bundle	

		// set portfolio / product area
		if(productWrapperMap.containsKey(selectedProduct)) {
			selectedPortfolio = productWrapperMap.get(selectedProduct).Product.Portfolio_Interest__c;
			selectedProductArea = productWrapperMap.get(selectedProduct).Product.Product_Area_Interest__c;
			system.debug('selectedPortfolio: ' + selectedPortfolio);
			system.debug('selectedProductArea: ' + selectedProductArea);
		}
    }
    
    public void ClearProduct() { 
    	/*
    		Clear Product
    	*/
    	selectedPortfolio = '';
    	selectedProductArea = '';
		selectedProduct = '';       // reset selected product
		selectedProductBundle = ''; // reset selected product bundle
		pbundleProducts.Clear();		// reset selected product bundle		
    }
        
    public void AddProduct() {
		/*
			Add Product to list
		*/
		// Add selected product 
		if(!bg_StringUtils.IsBlank(selectedProduct)) {
			productWrapperMap.get(selectedProduct).Selected = true;
		}
    }

    public void AddBundle() {
		/*
			Add Product to list
		*/
		// Add bundle products
		if(pbundleProducts.size() > 0) {
			for(string bundleProduct : pbundleProducts) {
				productWrapperMap.get(bundleProduct).Selected = true;				
			}
		}
    }
    
    public void RemoveProduct() {
		/*
			Remove Product from list
		*/
		for(string product : pUnselectProducts) {
			if(productWrapperMap.containsKey(product)) {
				productWrapperMap.get(product).Selected = false;
			}
		}
		pUnselectProducts.clear();				
    }
    
    public void Save() {
		/*
			Save portfolio, product area & product selection
		*/
    	// build new list of portfolios
    	set<string> portfolios = new set<string>();
    	// build new list of product areas
    	set<string> productAreas = new set<string>();
    	// build new list of product
    	set<string> products = new set<string>();
    	// loop through products and build up lists
    	for(bg_Wrappers.ProductWrapper pw : productWrapperMap.values()) {
    		if(pw.Selected) {
    			portfolios.add(pw.product.Portfolio_Interest__c);
    			productAreas.add(pw.product.Product_Area_Interest__c);
    			products.add(pw.product.Name);
    		}
    	}
		// set object fields
		objRecord.put('Portfolio_Interests__c', bg_StringUtils.ConvertToPicklistValue(portfolios));
		objRecord.put('Product_Area_Interests__c', bg_StringUtils.ConvertToPicklistValue(productAreas));
		objRecord.put('Product_Interests__c', bg_StringUtils.ConvertToPicklistValue(products));
	
		// save (Lead or Opportunity depending on sObject type)
		try {
			if(objRecord.getSObjectType()==Lead.sObjectType) {
				bg_LeadUtils.SaveLead((Lead)objRecord);	
			}
			else if(objRecord.getSObjectType()==Opportunity.sObjectType) {
				bg_OpportunityUtils.SaveOpportunity((Opportunity)objRecord);	
			}
		} 
		catch (Exception ex) {
			apexPages.addMessages(ex);
		}
    }

	public void Cancel() {
		/*
			Cancel changes - Reinitialise PI Wrappers Map
		*/
		InitialisePIWrappersMap();
	}		
}