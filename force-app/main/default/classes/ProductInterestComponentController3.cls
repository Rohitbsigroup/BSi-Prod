/********************************************************************
 * ProductInterestComponentController3
 *
 * Product Interest Component Controller
 * 
 * Author: Richard Jimenez
 * Created: 16/06/2015
 * Changes: 31/08/2017 ADS
 *            - Production Classification Fields; Division, Portoflio, Sector, Stream and Theme are now picklists
 ********************************************************************/
public with sharing class ProductInterestComponentController3 {

    // public variables
    private boolean isInitialised = false;
    public sObject objRecord {get; set;} 
    public boolean editMode {get; set;}

    // Suggest product filters
    public integer companySize {get; set;}
    public string country {get; set;}
    public string sector {get; set;}
    public string certStage {get; set;}
    public string customerBuyingStage {get; set;}
    public boolean showAllSuggestedProducts {get; set;}

    // public page selected values
    public string filterDivision {get; set;}    
    public string filterStream {get; set;}
    public string filterPortfolio {get; set;}
    public string filterTheme {get; set;}
    public string filterSector {get; set;}   

    public string searchText {get; set;}

    // TOP PAGE CONTROL
    public boolean reloadNeeded {get; private set;}
    public string reloadPageURL {get; private set;}

    private list<ResultWrapper> searchResultWrappers;
    private list<ResultWrapper> selectedResultWrappers;

    //public list<SelectOption> divisionFilterOptions       {get; set;}
    public list<SelectOption> streamFilterOptions       {get; set;}
    public list<SelectOption> portfolioFilterOptions    {get; set;}
    public list<SelectOption> themeFilterOptions        {get; set;}
    public list<SelectOption> sectorFilterOptions       {get; set;}

    public final integer MAX_ROWS = 6;

    public Integer searchResultsPageIndex {get; set;}
    public Integer selectedResultsPageIndex {get; set;}

    public string selectedId {get; set;}

    public integer viewMode {get; set;}
    public final integer VIEW_MODE_SEARCH = 1;
    public final integer VIEW_MODE_SELECTION = 2;

    @TestVisible private set<string> selectedDivisions;
    @TestVisible private set<string> selectedStreams;
    @TestVisible private set<string> selectedPortfolios;
    @TestVisible private set<string> selectedThemes;
    @TestVisible private set<string> selectedSectors;   
    @TestVisible private set<string> selectedProducts;

    public list<string> selectedSuggestedProducts {get; set;}

    /*
        Controller Constructor
    */
    public ProductInterestComponentController3() 
    {
        editMode = true;
        viewMode = VIEW_MODE_SEARCH;

        ResetSearchResults();           
        ResetSelectedResults();

        showAllSuggestedProducts = false;
        selectedSuggestedProducts = new list<string>();
    }

    /*
        Initialise variables 
    */
    @TestVisible private void Initialise()  
    {
        if(!isInitialised)  
        {
            isInitialised = true;

            LoadProductInterests();
            
            list<Product_Classification__c> pcList = GetProductsClassification('', '', '', '', '', '');
            PopulateFilterLists(pcList);
            PopulateSelectedWrappers(pcList);

            if(selectedResultWrappers.size() > 0)
            {
                viewMode = VIEW_MODE_SELECTION;
            }
        }
    }

    /*
        Populate filter lists using results
    */
    private void PopulateFilterLists(list<Product_Classification__c> pcList)
    {
        //divisionFilterOptions     = bg_ControllerUtils.CreateSelectOptions(pcList, 'Division2__c', 'Division2__c', true, true);
        streamFilterOptions     = bg_ControllerUtils.CreateSelectOptions(pcList, 'Stream2__c', 'Stream2__c', true, true);
        portfolioFilterOptions  = bg_ControllerUtils.CreateSelectOptions(pcList, 'Portfolio2__c', 'Portfolio2__c', true, true);
        themeFilterOptions      = bg_ControllerUtils.CreateSelectOptions(pcList, 'Family2__c', 'Family2__c', true, true);
        sectorFilterOptions     = bg_ControllerUtils.CreateSelectOptions(pcList, 'Sector2__c', 'Sector2__c', true, true);
        
           }

    /*
        Get Product Classification
    */
    public static list<Product_Classification__c> GetProductsClassification(string division, string stream, string portfolio, string theme, string sector, string searchText) 
    {
        // Build query
        string query = 'SELECT Stream2__c, Portfolio2__c, Family2__c, Sector2__c, Product__c ';
        query += 'FROM Product_Classification__c ';
        string whereClause = 'WHERE Product__c != NULL AND SF_Product__r.Active_In_SF__c = true AND ';
       
        // build wildcard string
        searchText = searchText.trim();
        string wildSearchText = '%' + searchText.replace('*','') + '%';

        // Wildcard Search      
        if(!String.IsBlank(searchText)) 
        {
            //whereClause += '(Division2__c LIKE :wildSearchText OR ';
            whereClause += '(Stream2__c    LIKE :wildSearchText OR ';
            whereClause += 'Portfolio2__c LIKE :wildSearchText OR ';
            whereClause += 'Family2__c    LIKE :wildSearchText OR ';
            whereClause += 'Sector2__c    LIKE :wildSearchText OR ';
            whereClause += 'Product__c   LIKE :wildSearchText) AND ';           
        }

        // Division
/*      
        if(!String.IsBlank(division)) 
        {
            whereClause += 'Division2__c = :division AND ';
        }
*/
        // Stream
        if(!String.IsBlank(stream)) 
        {
            whereClause += 'Stream2__c = :stream AND ';
        }
        
        // Portfolio
        if(!String.IsBlank(portfolio)) 
        {
            whereClause += 'Portfolio2__c = :portfolio AND ';
        }

        // Theme
        if(!String.IsBlank(theme)) 
        {
            whereClause += 'Family2__c = :theme AND ';
        }

        // Sector
        if(!String.IsBlank(sector)) 
        {
            whereClause += 'Sector2__c = :sector AND ';
        }
        
        query += whereClause.substring(0, whereClause.length()-4);

        query += 'ORDER BY Product__c ASC';
        return database.query(query);           
    }

    /*
        Select filter
    */
    public void SelectFilter() 
    {
        SearchProductInterest();
    }

    /*
        Reset Lists
    */  
    public void ClearAll() 
    { 
        ClearDivision();
        ClearStream();
        ClearPortfolio();
        ClearTheme();
        ClearSector();
    }

    /* 
        Reset Division 
    */
    public void ClearDivision() 
    { 
        filterDivision = '';
        SearchProductInterest();        
    }

    /* 
        Reset Stream 
    */  
    public void ClearStream() 
    {
        filterStream = '';
        SearchProductInterest();        
    }

    /* 
        Reset Portfolio 
    */  
    public void ClearPortfolio() 
    { 
        filterPortfolio = '';
        SearchProductInterest();        
    }

    /* 
        Reset Theme 
    */  
    public void ClearTheme() 
    { 
        filterTheme = '';
        SearchProductInterest();        
    }       

    /* 
        Reset Sector 
    */  
    public void ClearSector() { 
        filterSector = '';
        SearchProductInterest();        
    }       

    /*
        Reload Page
    */    
    @TestVisible private void ReloadPage() {
        reloadNeeded = true;
        reloadPageURL = getCurrentPageUrl();
    }

    /*
        Return the page URL
    */
    private string getCurrentPageUrl() {
        ApexPages.StandardController sc = new ApexPages.StandardController(objRecord);  
        PageReference pageRef = sc.view();
        return pageRef.getUrl();    
    }

    /*
        Add existing product interests in string sets
    */
    private set<string> LoadProductInterests(string fieldName)
    {
        set<string> values = new set<string>();
        if(!String.IsBlank((string)objRecord.get(fieldName))) 
        {
            values = new set<string>(((string)objRecord.get(fieldName)).split(';'));
        }
        return values;
    }

    /*
        Load Product and Training Interests
    */
    private void LoadProductInterests()
    {
        selectedDivisions = new set<string>();
        selectedStreams = new set<string>();
        selectedPortfolios = new set<string>();
        selectedThemes = new set<string>(); 
        selectedSectors = new set<string>();
        
        if((string)objRecord.get('Product_Stream__c') != null && (string)objRecord.get('Product_Stream__c') != 'Training In-house'
            && (string)objRecord.get('Product_Stream__c') != 'Training Public' 
            && (string)objRecord.get('Product_Stream__c') != 'Training In-house;Training Public')
            selectedProducts = LoadProductInterests('Product_Interests__c');
        else
            selectedProducts = new Set<String>();
        selectedProducts.addAll(LoadProductInterests('Training_Interests__c'));
    }

    /*
        Save Product Interests
    */
    public void Save()
    {
        selectedDivisions.Clear();
        selectedStreams.Clear();
        selectedPortfolios.Clear();
        selectedThemes.Clear();
        selectedSectors.Clear();
        selectedProducts.Clear();

        for(ResultWrapper rw : selectedResultWrappers)
        {
            PopulateSelectedProductInterests(rw.obj);
        }

        //objRecord.put('Product_Division__c', bg_StringUtils.ConvertToPicklistValue(selectedDivisions));
        objRecord.put('Product_Stream__c', bg_StringUtils.ConvertToPicklistValue(selectedStreams));
        objRecord.put('Portfolio_Interests__c', bg_StringUtils.ConvertToPicklistValue(selectedPortfolios));
        objRecord.put('Product_Area_Interests__c', bg_StringUtils.ConvertToPicklistValue(selectedThemes));
        objRecord.put('Sector_Interests__c', bg_StringUtils.ConvertToPicklistValue(selectedSectors));
        
        set<string> selectedTrainingProducts = new set<string>();
        set<string> selectedNonTrainingProducts = new set<string>();
        for(string product : selectedProducts)
        {
            if(product.startsWith('OT -') || product.startsWith('PT -'))
            { 
                selectedTrainingProducts.add(product);
            }
            else
            {
                selectedNonTrainingProducts.add(product);
            }
        }
        
        objRecord.put('Product_Interests__c', bg_StringUtils.ConvertToPicklistValue(selectedNonTrainingProducts));
        objRecord.put('Training_Interests__c', bg_StringUtils.ConvertToPicklistValue(selectedTrainingProducts));
            
        try {

            if(objRecord.getSObjectType() == Lead.sObjectType) 
            {
                bg_LeadUtils.SaveLead((Lead)objRecord); 
            }
            else if(objRecord.getSObjectType() == Opportunity.sObjectType) 
            {
                bg_OpportunityUtils.SaveOpportunity((Opportunity)objRecord);    
            }
            
            ReloadPage();
        } 
        catch (Exception ex) 
        {
            apexPages.addMessages(ex);
        }
    }

    /*
        Cancel changes
    */
    public void Cancel() {
        ReloadPage();
    }

    /*
        Populate Selected Wrappers
    */
    private void PopulateSelectedWrappers(list<Product_Classification__c> pcList)
    {
        for(Product_Classification__c pc : pcList)
        {
            if(selectedProducts.contains(pc.Product__c))
            {
                ResultWrapper rw = BuildResultWrapper(pc);
                rw.Selected = True;
                selectedResultWrappers.add(rw);             
            }
        }
    }

    /*
        Reset Search Results
    */
    private void ResetSearchResults()
    {
        searchResultWrappers = new list<ResultWrapper>();
        searchResultsPageIndex = 1;     
    }

    /*
        Reset Selected Search Results
    */
    private void ResetSelectedResults()
    {
        selectedResultWrappers = new list<ResultWrapper>();
        selectedResultsPageIndex = 1;       
    }

    /*
        Search Product Interests
    */
    public void SearchProductInterest()
    {       
        // Clear current search results
        ResetSearchResults();
        
        list<Product_Classification__c> pcList = new list<Product_Classification__c>();

        try 
        {
            pcList = GetProductsClassification(filterDivision,
                                                filterStream, 
                                                filterPortfolio, 
                                                filterTheme,
                                                filterSector,                                                                               
                                                searchText);        
        }
        catch (Exception ex) 
        {}
        PopulateFilterLists(pcList);
        searchResultWrappers = BuildResultsWrappers(pcList);    
    }

    /*
        Build Results Wrappers
    */
    private list<ResultWrapper> BuildResultsWrappers(list<Product_Classification__c> pcList)
    {
        list<ResultWrapper> rws = new list<ResultWrapper>();
        for(Product_Classification__c pc : pcList)
        {
            ResultWrapper rw = BuildResultWrapper(pc);
            rw.Selected = selectedProducts.Contains(pc.Product__c);
            rws.add(rw);
        }
        return rws;
    }

    private ResultWrapper BuildResultWrapper(Product_Classification__c pc)
    { 
        ResultWrapper rw = new ResultWrapper();
        rw.obj = pc;
        return rw;
    }

    public void Next()
    {
        pageIndex++;
    }
    
    public void Previous()
    {
        pageIndex--;
    }

    public void First()
    {
        pageIndex = 1;
    }

    public void Last()
    {
        pageIndex = totalPages;
    }
    
    public integer pageIndex
    {
        get {
                if(viewMode == VIEW_MODE_SEARCH)
                {
                    return searchResultsPageIndex;
                }
                else
                {
                    return selectedResultsPageIndex;
                }           
            }
        set { 
                if(viewMode == VIEW_MODE_SEARCH)
                {
                    searchResultsPageIndex = value;
                }
                else
                {
                    selectedResultsPageIndex = value;
                }               
        }
    }
    
    public boolean getHasNext()
    {
        return (totalPages > pageIndex);
    }

    public boolean getHasPrevious()
    {
        return pageIndex > 1;
    }
    
    private ResultWrapper GetResultWrapper(list<ResultWrapper> rws, string selectedId)
    {
        return GetResultWrapper(rws, selectedId, false);
    }
    
    private ResultWrapper RemoveResultWrapper(list<ResultWrapper> rws, string selectedId)
    {
        return GetResultWrapper(rws, selectedId, true);
    }
    
    private ResultWrapper GetResultWrapper(list<ResultWrapper> rws, string selectedId, boolean removeFromList)
    {
        ResultWrapper srw;
        for(integer i = 0 ; i < rws.size() ; i++)
        {
            if(rws[i].obj.Id == selectedId)
            {
                srw = rws[i];
                if(removeFromList) rws.remove(i);
                break;
            }
        }
        return srw;     
    }
    
    /*
        Select Product
    */
    public pageReference SelectProduct()
    {
        if(viewMode == VIEW_MODE_SEARCH)
        {
            ResultWrapper srw = GetResultWrapper(searchResultWrappers, selectedId);
            if(srw.Selected)
            {
                selectedResultWrappers.add(srw);
                selectedProducts.add(srw.obj.Product__c);
            }
            else
            {
                ResultWrapper rw = RemoveResultWrapper(selectedResultWrappers, selectedId);
                selectedProducts.remove(rw.obj.Product__c);
            }
        }
        else
        {
            ResultWrapper rw = RemoveResultWrapper(selectedResultWrappers, selectedId);
            selectedProducts.remove(rw.obj.Product__c);
        }
        return null;
    }

    /*
        Populate Selected Product Interests
    */
    private void PopulateSelectedProductInterests(Product_Classification__c pc)
    {
        //PopulateSelectedProductInterest(pc, selectedDivisions,    'Division2__c');
        PopulateSelectedProductInterest(pc, selectedStreams,    'Stream2__c');
        PopulateSelectedProductInterest(pc, selectedPortfolios, 'Portfolio2__c');
        PopulateSelectedProductInterest(pc, selectedThemes,     'Family2__c');
        PopulateSelectedProductInterest(pc, selectedSectors,    'Sector2__c');
        PopulateSelectedProductInterest(pc, selectedProducts,   'Product__c');      
    }

    /*
        Populate Selected Product Interest
    */
    private void PopulateSelectedProductInterest(Product_Classification__c pc, set<string> selectedItems, string fieldName)
    {
        if(!String.IsBlank((string)pc.get(fieldName)))
        {
            selectedItems.add((string)pc.get(fieldName));
        }
    }
        
    /*
        Result Wrapper Class
    */
    public class ResultWrapper
    {
        public ResultWrapper()
        {
            Selected = false;
        }
        
        public boolean Selected {get; set;}
        public Product_Classification__c obj {get; set;}
    }

    private list<ResultWrapper> resultWrappers
    {
        get {
            if(!isInitialised) { Initialise(); }
                        
            if(viewMode == VIEW_MODE_SEARCH)
            {
                return searchResultWrappers;
            }
            else
            {
                return selectedResultWrappers;
            }
        }
    }
    
    public list<ResultWrapper> pagedResultsWrappers
    {
        get {           
            list<ResultWrapper> tempResults = new list<ResultWrapper>();
            integer offset = (pageIndex-1) * MAX_ROWS;
            integer maxRows = (resultWrappers.size() >= offset + MAX_ROWS ? MAX_ROWS : resultWrappers.size() - offset); 
            for(integer i = offset; i < offset + maxRows ; i++) {
                tempResults.add(resultWrappers[i]);
            }
            return tempResults;             
        }
    }

    public integer TotalPages
    {   
        get {
            integer pages = integer.valueOf((decimal.valueOf(resultWrappers.size()) / MAX_ROWS).round(System.RoundingMode.CEILING));
            return (pages == 0 ? 1 : pages);
        }
    }

    public Integer recordCount
    {
        get {
            return resultWrappers.size();
        }
    }

    public void viewSelection()
    {
        viewMode = VIEW_MODE_SELECTION;
    }

    public void viewSearch()
    {
        viewMode = VIEW_MODE_SEARCH;
    }

    public list<SelectOption> getSuggestedProductItems() 
    {
        if(!isInitialised) { Initialise(); }

        list<SelectOption> optionItems;
                
        if(showAllSuggestedProducts) 
        {
            list<Product_Classification_Relationship__c> pcList = bg_ProductInterestUtils.GetSuggestedProductClassificationRelationships(new list<string>(selectedProducts));
            optionItems = bg_ControllerUtils.CreateSelectOptions(pcList, 'SuggestedProductClassificationName__c', 'SuggestedProductAndReason__c', true, false);
        } 
        else 
        {
            list<Product_Classification_Relationship__c> pcList = bg_ProductInterestUtils.GetSuggestedProductClassificationRelationships(new list<string>(selectedProducts), country, companySize, sector, certStage, customerBuyingStage);
            optionItems = bg_ControllerUtils.CreateSelectOptions(pcList, 'SuggestedProductClassificationName__c', 'SuggestedProductAndReason__c', true, false); 
        }

        return optionItems;
    }
    
    public void SelectSuggestedProduct()
    {
        list<Product_Classification__c> pcList = bg_ProductUtils.GetProductsByProductClassification(selectedSuggestedProducts, false);

        for(Product_Classification__c pc : pcList) 
        {
            if(!selectedProducts.contains(pc.Product__c))
            {
                ResultWrapper rw = BuildResultWrapper(pc);
                rw.Selected = true;
                selectedResultWrappers.add(rw);
                selectedProducts.add(pc.Product__c);
            }
        }
    }
}