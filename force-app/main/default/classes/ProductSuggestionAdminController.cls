/********************************************************************
 * ProductSuggestionAdminController
 *
 * Product Suggestion Admin Controller
 * 
 * Author: Richard Jimenez
 * Created: 10-11-2013	
 * Changes: 
 ********************************************************************/
public class ProductSuggestionAdminController {

	public string selectedProductId {get; set;}
	public string selectedRegion {get; set;}
	public string selectedOrderBy {get; set;}

	public list<SelectOption> selectOrderByItems {get; set;}
	public list<SelectOption> selectProductItems {get; set;}
	public list<SelectOption> productItems {get; set;}
	public string deleteSuggestedProductId {get; set;}
	public list<SuggestedProductWrapper> suggestedProductWrappers {get; set;}
	private list<Product_Classification_Relationship__c> suggestedProducts {get; set;}
	public boolean withSuggestionsOnly {get; set;}

	public class SuggestedProductWrapper {
		public Product_Classification_Relationship__c obj {get; set;}

		public boolean getCanEdit() {
			return (obj.CanEditRecord__c || obj.Id == null);
		}
		
		
	}
	
	public ProductSuggestionAdminController() {
		withSuggestionsOnly = true;
		selectProductItems = GetProductList(withSuggestionsOnly);
		productItems = GetProductList(false);
		suggestedProductWrappers = new list<SuggestedProductWrapper>();
		selectOrderByItems = GetOrderByList();
		selectedOrderBy = 'Ranking__c';
	}

	private list<SelectOption> GetOrderByList() {
		list<SelectOption> orderByList = new list<SelectOption>();
		orderByList.add(new SelectOption('Ranking__c', 'Ranking'));
		orderByList.add(new SelectOption('Region__c', 'Region'));
		orderByList.add(new SelectOption('SuggestedProductClassification__r.Product__c', 'Product'));
		return orderByList;				
	}
	
	public void PopulateProductList() {
		selectProductItems = GetProductList(withSuggestionsOnly);
	}

	private list<SelectOption> GetProductList(boolean withSuggestionsOnly) {
		/*
			Get Product Items
		*/
		string query = 'SELECT Id, Product__c ';
		query += 'FROM Product_Classification__c ';
		query += 'WHERE Product__c != \'\' ';
		if(withSuggestionsOnly) { 
			query += 'AND Id IN (SELECT ProductClassification__c FROM Product_Classification_Relationship__c) ';
		}
		query += 'ORDER BY Product__c';

		list<Product_Classification__c> values = database.query(query);
		return bg_ControllerUtils.CreateSelectOptions(values, 'Id', 'Product__c', true, true);		
	}

	public list<SelectOption> getSelectRegionItems() {
		/*
			Get Region List Items
		*/
		list<SelectOption> regionList = bg_ControllerUtils.GetPicklistSelectOptions(Product_Classification_Relationship__c.getSObjectType(), 'Region__c', true);
		regionList.add(0, new SelectOption('', '-- SELECT --'));
		return regionList;
	}

	public void Save() {
		/*
			Get Suggested Product
		*/
		try {
			if(!suggestedProducts.isEmpty()) {
				upsert suggestedProducts;
			}
			GetSuggestedProducts();
		} catch (Exception e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Failed to save - ' + e.getMessage()));
		}		
	}

	public void Cancel() {
		/*
			Cancel - return to product classification tab
		*/
		GetSuggestedProducts();		
	}
    
    public void RefreshSuggestedProducts() {
    	GetSuggestedProducts();
    }
          
	public void DeleteSuggestedProduct() {
		/*
			Delete Suggested Product
		*/
		if(!bg_StringUtils.IsBlank(deleteSuggestedProductId)) {		
			Product_Classification_Relationship__c deleteSR = new Product_Classification_Relationship__c(Id = deleteSuggestedProductId);
			delete deleteSR;
		}
		GetSuggestedProducts();
	}
	
    public void GetSuggestedProducts() {
		/*
			Get Suggested Product
		*/
		string query = 'SELECT SuggestedProductClassification__c, Region__c, Country__c, CompanySizeMin__c, CompanySizeMax__c, BSIReadiness__c, ' + 
    					'SuggestedProductClassificationName__c, Sector__c, CustomerBuyingStage__c, ReasonsForSuggestion__c, Ranking__c, CanEditRecord__c ' + 
    					'FROM Product_Classification_Relationship__c ' +
    					'WHERE ProductClassification__c = :selectedProductId '; 

		// check for a region
		if(!string.IsBlank(selectedRegion)) {
			query += 'AND Region__c = :selectedRegion ';
		}

    	query += 'ORDER BY ' + selectedOrderBy + ' ASC, SuggestedProductClassification__r.Product__c ASC';

		suggestedProducts = database.query(query);

		suggestedProductWrappers.clear();
		for(Product_Classification_Relationship__c pcr : suggestedProducts) {
			suggestedProductWrappers.add(CreateSuggestedProductWrapper(pcr));
		}    					
    }
    
    public void AddSuggestedProduct() {
		/*
			Add Suggested Product
		*/
		Product_Classification_Relationship__c newSR = new Product_Classification_Relationship__c();
		newSR.Region__c = selectedRegion;
		newSR.ProductClassification__c = selectedProductId;
		suggestedProducts.add(newSR);
		suggestedProductWrappers.add(CreateSuggestedProductWrapper(newSR));	
    }

    private SuggestedProductWrapper CreateSuggestedProductWrapper(Product_Classification_Relationship__c obj) {
		/*
			Create Suggested Product Wrapper
		*/
    	SuggestedProductWrapper spw = new SuggestedProductWrapper();
    	spw.obj = obj;
    	return spw;
    }
}