/********************************************************************
 * bg_QuoteBuilderController
 *
 * Visualforce Controller used to facilitate the selection of products
 * and sites. Created for PS Enhancements based on NewQuoteControllerV3
 * 
 * Test Class: bg_QuoteBuilderTest
 *
 * Author: Chris Bacon, Richard Cave, Ian Bowman
 * Created: 16-06-17
 * Changes: 14-07-17    SS  Create UpdateQuote() for quote products
 * Changes: 17-07-17    IB  Create QuoteProducts for projects
 *          04-09-17    CPE Moved meta-data constants to bg_CustomMetadataUtils updateQuote
 *          08-09-17    IB  brought ViewProductProfile() over from NewQuoteGridController
 *          13-09-17    RC  removed functions not in use and removed comments and debug statements
 *          25-09-17    RC  added functions to handle setting controlling location.
 *          27-09-17    RC  changed handleHQPaths to work off controlling location, also changed SetProductRiskLevelToAllSites
 *                          and SetProductRegPathToAllSites.
 *          08-12-17    TC  change product search to cover both product_Classification Product and SF Product
 *          07-02-18    ADS Case 35482 - Asian Characters
 ********************************************************************/
public with sharing class bg_QuoteBuilderController implements bg_FacetedSearchDelegate{

    // Record Ids
    private Id oppId; 
    private Id accId;
    private Id quoId;
    public  Id quoteProductWrapperIdToUpdate {get; set;}
    
    // Records
    public Opportunity opp {get; private set;}
    public Quote__c quote {get; private set;} 
    public User user {get; private set;}

    public boolean isNew {get;set;}                             // New Quote
    public boolean isEditMode {get;set;}                        // Edit Mode

    public boolean ShowSiteSummary {get;private set;}           // Show/Hide site summary
    public boolean ShowProductSearch {get;private set;}         // Show/Hide product search panel
    public boolean ShowSelectedOnly {get;private set;}          // Show/Hide selected products only
    public boolean ShowSelectionSummary {get;private set;}      // Show/Hide selection summary
    public boolean SampleWarnings {get; private set;}       // Highlight any selection warnings
    public boolean ShowCreditCheckContact {get; private set;}
    public boolean DisableConfigure {get; private set;}         // Can products be configured - sites must have T-Codes

    // Product Search variable
    public string searchProductPortfolio {get;set;}      // selected portfolio value
    public string searchProductArea {get;set;}           // selected product area value
    public string searchProductName {get;set;}           // selected product name value
    public list<string> searchProductCountries {get;set;} // selected countries

    // Project Search variable
    public string searchProjectName {get;set;}           // selected project name value

    public list<bg_Wrappers.ProductWrapper> ProductSearchResults {get; private set;}            // Product search results
    public list<bg_Wrappers.ProjectWrapper> ProjectSearchResults {get; private set;}            // Project search results
    public list<bg_Wrappers.ProjectWrapper> SelectedProjects {get; private set;}            // selected Project results
    public string selectedProject {get;set;}

    public list<bg_Wrappers.RelatedProductWrapper> SuggestedProductResults {get; private set;}  // suggested results
    
    
    // Selected values from VF page
    public string selectedProductArea {get;set;}
    public string selectedProduct {get;set;}
    public string selectedProductId {get;set;}
    public string selectedProjectId {get;set;}
    public string selectedIMSProduct {get;set;}
    public string selectedProdRegPath {get; set;}
    public string selectedProdRiskLevel {get; set;}
    public string selectedProductName {get; set;}


    public String selectedControllingLocationId {get;set;}
    public String selectedControllingLocationProduct{get;set;}
    
    public string selectedSiteProduct {get; set;}
    public string selectedSite {get; set;}

    public String selectedQuoteLanguage;
        
    // internal selected lists
    public set<string> selectedIMSProducts {get; set;}
    public set<string> allIMSProducts {get; set;}   
    private set<string> siteCountries;
    
    // Wrappers & Maps
    private map<boolean, bg_Wrappers.ProductAreaWrapper> productViewMap;
    public map<string, bg_Wrappers.QuoteProductWrapper> productMap {get; private set;}
    public map<string, bg_Wrappers.QuoteProductWrapper> projectProductMap {get; private set;} // QuoteProducts to enable Blue Zebra Configurator for Projects
    public list<bg_Wrappers.ProductAreaWrapper> productAreas {get;set;}
    public list<bg_Wrappers.SiteWrapper> sites {get;set;}
    public map<string, map<string, map<string, bg_Wrappers.RegPathSampleWrapper>>> samplingMap {get;private set;}   // by site type, by product, by product site types
    private Map<ID, Project__c> projectMap; // holds all of the projects so that we can find the Project for saved Quote Products 
    public boolean readyToQuote {get; private set;}

    public boolean missingSiteType {get;set;}
    public list <OpportunitySite__c> missingSiteTypes {get;set;}
    public boolean useDefaults {get;set;}
    public boolean skipPricebookCurrencyCheck {get;set;}

    private boolean hasSingletonProduct;
    
    // PS additions
    public List<List<Faceted_Search_Component__mdt>> components {get; set;} // all components to be displayed outer List is a row, inner List is the components in that row
    public bg_FacetedSearchDelegate searchController { get { return this; } }
    private Map <String, bg_FacetedSearchComponent> facetedSearchComponentMap; // those components that have called back as a selection haas been made
    /** @TODO refacator so that controller just passes list of components to utils class ? */
    private Map<String, Map<String, Set<String>>> selectedOptionsByObjectAndField; // All of the tags that have been selected as filters
    
    // Dynamic Search results POC
    public List<String> columns {get; set;}
    public List<String> columnsProject {get; set;}
    private List <Faceted_Search_Result_Fields__mdt> fieldsToQuery;
    private List <Faceted_Search_Result_Fields__mdt> fieldsToQueryProject;
    
    Public Map<Id,list<bg_Wrappers.ProjectWrapper>> mProjSelected;

    private set<Id> projectIds;
    
    public String configureButtonLabel {
        get {
            return isEditMode ? Label.Configure : 'View Configuration';
        }
    }
    
    /************************************************************************/
    /* Constructor                                                          */  
    /************************************************************************/
    public bg_QuoteBuilderController() {
        /*
            Class Constructor
        */

            // Page Section defaults
            ShowSiteSummary = true;
            ShowProductSearch = true;
            ShowSelectionSummary = false;
            ShowSelectedOnly = true;
            SampleWarnings = false;
            skipPricebookCurrencyCheck = false;
            hasSingletonProduct = false;
            ShowCreditCheckContact = bg_QuoteUtils.ShowCreditCheckContact(UserInfo.getUserId());
            SelectedProjects = new list<bg_Wrappers.ProjectWrapper>();
            DisableConfigure = false;

            // Get page parameters
            oppId = ApexPages.currentPage().getParameters().get('oppid');
            accId = ApexPages.currentPage().getParameters().get('accid');
            quoId = ApexPages.currentPage().getParameters().get('quoid');
            isEditMode = ApexPages.currentPage().getParameters().get('mode') != '0';
            
            // Initialise collections
            selectedIMSProducts = new set<string>();
            allIMSProducts = new set<string>();
            missingSiteTypes = new list<OpportunitySite__c>();
            searchProductCountries = new list<string>();
            
            // Load Opportunity
            opp = bg_OpportunityUtils.GetOpportunityById(oppId);
    
            // Load & Check opportunity sites
            list<OpportunitySite__c> siteList = bg_SiteUtils.GetOpportunitySites(oppId, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, bg_SiteUtils.RECORD_TYPE_NAME_DEFAULT);
            missingSiteType = CheckMissingSiteTypes(siteList, missingSiteTypes);
            siteCountries = bg_SiteUtils.GetOpportunitySiteCountries(siteList);

            for (OpportunitySite__c os : siteList) {
                if(os.SiteTCode__c==null) DisableConfigure = true;
            }

            productAreas = new list<bg_Wrappers.ProductAreaWrapper>();
            productViewMap = new map<boolean, bg_Wrappers.ProductAreaWrapper>();
            productMap = new map<string, bg_Wrappers.QuoteProductWrapper>();
            projectProductMap = new map<string, bg_Wrappers.QuoteProductWrapper>();
            
                                
            // Initialise Site Wrappers
            sites = bg_WrapperHelper.CreateSiteWrappers(siteList);
            samplingMap = bg_WrapperHelper.CreateSamplingMap(sites, productMap);
            
            mProjSelected = new Map<Id, list<bg_Wrappers.ProjectWrapper>>();
            projectIds = new set<Id>();
                    
            // Initialise Quote
            if(quoId == null) 
            {
                NewQuote();
            } else {
                LoadQuote();
            }

            // Case 27420
            // Initialise user (for default blueprint language settings) 
            LoadUser();
            
            // PS Enhancements - get the search components to be presented
            components = bg_CustomMetadataUtils.getFacetedSearchComponents(bg_CustomMetadataUtils.PRODUCT_SEARCH_CONTAINER);
            fieldsToQuery = bg_CustomMetadataUtils.GetSearchResultFields(bg_CustomMetadataUtils.PRODUCT_SEARCH_CONTAINER);
            fieldsToQueryProject = bg_CustomMetadataUtils.GetSearchResultFields(bg_CustomMetadataUtils.PROJECT_SEARCH_CONTAINER);
            
            // Dynamic Search results POC
            columns = new List<String>();
            // retrieve the columns from the custom metadata
            for (Faceted_Search_Result_Fields__mdt f : fieldsToQuery)
            {
                if (f.Display_Order__c > 0)
                {
                    columns.add(f.Display_Name__c);
                }
            }

            columnsProject = new List<String>();
            // retrieve the columns from project the custom metadata
            for (Faceted_Search_Result_Fields__mdt g : fieldsToQueryProject)
            {
                if (g.Display_Order__c > 5)
                {
                    columnsProject.add(g.Display_Name__c);

                }

            }
            searchProject();
    }

    public pageReference CheckManageSites() {
        /* Redirect to Manage Site if there are none selected */
        if(sites !=null && sites.isEmpty()) {
            return new pageReference('/' + bg_SiteUtils.BuildManageOpportunitySitesURL(oppId, bg_QuoteUtils.BuildNewQuoteURL(accId, oppId, quoId)));            
        } else {
            return null;
        }
    }

    public pageReference ConfigureProduct() {
        /* Configure Product */
        Pagereference configurePage = null;
        if(SaveQuote()) 
        {
            String productId = null;
            Boolean loadNewConfigurator = false;
            // do we have a project Id, if so get the quote product id from the wrapper
            // we only ever create 1 quote product per project, BZ will create others but they will not be in scope of this page
            // will have been created via the save process for new quotes
            if(!String.isEmpty(selectedProjectId))
            {
                for(bg_Wrappers.QuoteProductWrapper qpw : productMap.values()) {
                    if(qpw.ProjectId == selectedProjectId)
                    {
                        // will only be 1
                        for(bg_Wrappers.ProductSiteWrapper psw : qpw.SitesMap.values()) 
                        {
                            productId = psw.QuoteProduct.QuoteProduct.Id;
                        }
                    }
                }
                loadNewConfigurator = true;
            }
            else
            {
                productId = selectedProductId;
            }
            
            string quoteLanguage = quote.QuoteLanguage__c;
            
            if (!String.isEmpty(productId))
            {   
                configurePage = new Pagereference(bg_BluePrintUtils2.BuildConfigureURL(isEditMode, quoId, productId, quoteLanguage, bg_QuoteUtils.BuildQuoteBuilderURL(accId, oppId, quoId,isEditMode), loadNewConfigurator));
            }
            else
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Cannot derive the correct Id to pass to the configurator'));  
            }
            
        }
        System.debug(configurePage);
        return configurePage;
    }

    private void NewQuote() {
        /* 
            Create New Quote
        */
        isNew = true;
        useDefaults = true;     
        quote = bg_QuoteUtils.GetNewQuote(accId, oppId);
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
            List<Project__c> selectedProjectsOnLoad = new List<Project__c>();
            
            // get related projects by id
            Set<Id> projectIds = new Set<Id>();
            for(bg_Wrappers.QuoteProductWrapper qpw : productMap.values()) {
                if(!String.isEmpty(qpw.ProjectId))
                {
                    projectIds.add(qpw.ProjectId);
                }
            }

            Map<Id, Project__c> projectsById = bg_projectUtils.GetProjectsById(projectIds);

            // update selected product map
            for(bg_Wrappers.QuoteProductWrapper qpw : productMap.values()) {

                if(qpw.Selected) 
                {
                    bg_Wrappers.ProductAreaWrapper area;
                    if(!productViewMap.containsKey(qpw.GridView)) {
                        area = bg_WrapperHelper.CreateProductAreaWrapper(qpw.Area, qpw.GridView);
                    
                        productViewMap.put(qpw.GridView, area);
                        productAreas.add(area);
                        area.IsCollapsed = false;
                        qpw.ProductArea = area;

                    }
                    if(projectsById.containsKey(qpw.ProjectId))
                    {
                        qpw.Project = projectsById.get(qpw.ProjectId);  
                    }
                    productViewMap.get(qpw.GridView).SelectedProductCount++;                    
                    productViewMap.get(qpw.GridView).products.add(qpw);
                    
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

                    if(projectsById.containsKey(qpw.ProjectId))
                    {
                        productViewMap.get(qpw.GridView).Project = projectsById.get(qpw.ProjectId);
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

        //need to query opportunity contact roles as well
        List<Contact> accountContacts = bg_ContactUtils.GetAccountContacts(accId, 900);
        Set<Id> contactsOpps = bg_ContactUtils.GetOpportunityContactsFromContactRoles(oppid);

        //now debdupe the list by adding the other list to a set.
        for(Contact con : accountContacts)
        {
            contactsOpps.add(con.Id);
        }

        List<Contact> allContacts = [Select Id, Name FROM Contact where ID IN :contactsOpps ORDER BY NAME];

        return bg_ControllerUtils.CreateSelectOptions(allContacts, 'Id', 'Name', true, true);
    }
    
    public list<SelectOption> getPricebookItems() {
        /* Return list of Pricebook Items */        
        // only pricebooks for current year & customer, or global
        //also exclude MSA pricebooks
        set<Id> pricebookIds = new set<Id>{quote.PriceBook2Id__c};
        return bg_ControllerUtils.CreateSelectOptions(bg_PricebookUtils.GetPricebooks(null, accId, null, pricebookIds, true), 'Id', 'Name', true, false);       
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

    public void setControllingLocation()
    {
        bg_Wrappers.ProductSiteWrapper oldControllingLocationProductSiteWrapper = null;
        bg_Wrappers.ProductSiteWrapper newControllingLocationProductSiteWrapper = null;
        bg_Wrappers.QuoteProductWrapper qpw = productMap.get(selectedControllingLocationProduct);

        for(bg_Wrappers.ProductSiteWrapper productSiteWrapper : qpw.SitesMap.Values())
        {
            if(productSiteWrapper.IsControllingLocation)
            {
                oldControllingLocationProductSiteWrapper = productSiteWrapper;
            }
            if(productSiteWrapper.site.id == qpw.controllingLocationId)
            {
                newControllingLocationProductSiteWrapper = productSiteWrapper;
            }
            if(null!=oldControllingLocationProductSiteWrapper && null!=newControllingLocationProductSiteWrapper)
            {
                break;
            }
        }
        if(null!=oldControllingLocationProductSiteWrapper)
        {
            // remove the current controlling location from the sampling map
            bg_WrapperHelper.RemoveProductSiteFromSamplingMap(samplingMap, qpw, oldControllingLocationProductSiteWrapper.site, oldControllingLocationProductSiteWrapper);
        }
        if(null!=newControllingLocationProductSiteWrapper)
        {
            // remove the new controlling location from the sampling map
            bg_WrapperHelper.RemoveProductSiteFromSamplingMap(samplingMap, qpw, newControllingLocationProductSiteWrapper.site, newControllingLocationProductSiteWrapper);
        }

        List<bg_Wrappers.QuoteProductWrapper> quoteProductWrappers = new List<bg_Wrappers.QuoteProductWrapper>();
        quoteProductWrappers.add(qpw);
        setControllingLocation(quoteProductWrappers, qpw.controllingLocationId);
        setLayoutOrderForProductSiteWrappers(quoteProductWrappers);
        
        if(null!=oldControllingLocationProductSiteWrapper)
        {
            bg_WrapperHelper.AddProductSiteToSamplingMap(samplingMap, qpw, oldControllingLocationProductSiteWrapper.site, oldControllingLocationProductSiteWrapper);    
        }
        if(null!=newControllingLocationProductSiteWrapper)
        {
            bg_WrapperHelper.AddProductSiteToSamplingMap(samplingMap, qpw, newControllingLocationProductSiteWrapper.site, newControllingLocationProductSiteWrapper);
        }   
    }

    // TODO: CB - sampling in progress
    public void removeControllingLocationChangesFromSamplingMap(List<bg_Wrappers.QuoteProductWrapper> quoteProductWrappers)
    {
        for(bg_Wrappers.QuoteProductWrapper quoteProductWrapper : quoteProductWrappers)
        {
            bg_Wrappers.ProductSiteWrapper oldControllingLocationProductSiteWrapper = null;
            bg_Wrappers.ProductSiteWrapper newControllingLocationProductSiteWrapper = null;
            bg_Wrappers.QuoteProductWrapper qpw = productMap.get(selectedControllingLocationProduct);

            for(bg_Wrappers.ProductSiteWrapper productSiteWrapper : qpw.SitesMap.Values())
            {
                if(productSiteWrapper.IsControllingLocation)
                {
                    oldControllingLocationProductSiteWrapper = productSiteWrapper;
                }
                if(productSiteWrapper.site.id == qpw.controllingLocationId)
                {
                    newControllingLocationProductSiteWrapper = productSiteWrapper;
                }
                if(null!=oldControllingLocationProductSiteWrapper && null!=newControllingLocationProductSiteWrapper)
                {
                    break;
                }
            }
            // remove the current controlling location from the sampling map
            bg_WrapperHelper.RemoveProductSiteFromSamplingMap(samplingMap, qpw, oldControllingLocationProductSiteWrapper.site, oldControllingLocationProductSiteWrapper);
            // remove the new controlling location from the sampling map
            bg_WrapperHelper.RemoveProductSiteFromSamplingMap(samplingMap, qpw, newControllingLocationProductSiteWrapper.site, newControllingLocationProductSiteWrapper);
        }
    }

    public void setControllingLocationForAllProducts()
    {
        //work out if there is 1 product or many.
        bg_Wrappers.QuoteProductWrapper qpw = productMap.get(selectedControllingLocationProduct);
        bg_Wrappers.ProductAreaWrapper paw = productViewMap.get(qpw.gridview);
        setControllingLocation(paw.Products, qpw.controllingLocationId);
        setLayoutOrderForProductSiteWrappers(paw.Products);
    }

    public void setControllingLocation(List<bg_Wrappers.QuoteProductWrapper> quoteProductWrappers, String controllingLocationId)
    {
        for(bg_Wrappers.QuoteProductWrapper quotePartWrapper : quoteProductWrappers)
        {
            if(quotePartWrapper.controllingLocationId != controllingLocationId)
            {
                quotePartWrapper.controllingLocationId = controllingLocationId;
            }
            for(bg_Wrappers.ProductSiteWrapper psw : quotePartWrapper.SitesMap.values()) 
            {
                psw.IsControllingLocation = (psw.Site.Id == controllingLocationId);

                //set all the configuration complete to false as controlling location has changed.
                psw.Completed = false; 
            }
        }
    }


    public void setLayoutOrderForProductSiteWrappers(List<bg_Wrappers.QuoteProductWrapper> quoteProductWrappers)
    {

        for(bg_Wrappers.QuoteProductWrapper quotePartWrapper : quoteProductWrappers)
        {
            Integer controllingLocationIndex = 1;
            Integer currentIndex = 1;
            for(bg_Wrappers.ProductSiteWrapper psw : quotePartWrapper.SitesMap.values()) 
            {
                if(psw.IsControllingLocation)
                {
                    psw.SiteIndex = controllingLocationIndex;
                }
                else
                {
                    currentIndex++;
                    psw.SiteIndex = currentIndex;
                }
            }
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

    /* 
        PS Enhacements replacement for SearchProducts
    */
    public void facetedSearchProducts()
    {
        
        // clear the existing filter values and ask all of the registered search components for their filter values
        selectedOptionsByObjectAndField  = null;
        for (bg_FacetedSearchComponent c : facetedSearchComponentMap.values())
        {
            List<String> selectedTags = c.getSelectedItems();
            if (selectedTags != null && !selectedTags.isEmpty())
            {
                addSelectOption(c.getObjectName(), c.getParamKey(), c.getSelectedItems());
            }   
        }
        
        Set<String> fieldsToReturn = new Set<String>();
        for (Faceted_Search_Result_Fields__mdt f : fieldsToQuery)
        {
            fieldsToReturn.add(f.Field_API_Name__c);
        }
        
        Map<String, Set<String>> fieldsToReturnByObjectName = new Map<String, Set<String>>{'Product__c' => fieldsToReturn}; 
        
        String initialSearchTerm = 'Product_Type__c = \'' + bg_ProductUtils.PRODUCT_TYPE_MAIN +'\' AND ExcludefromProductCatalogue__c = False and Active_In_SF__c = true and Product_Classification__c != null AND RecordType.Name != \'Product Certification\' AND RecordType.Name != \'Customized Audits\'';
        
        // IB 22/8/2017 new initial search term following switch to PC to reintroduce product search
        if (!String.isBlank(searchProductName))
        {
            // TC 08/12/2017 change product search to cover both product_Classification Product and SF Product
//          initialSearchTerm = initialSearchTerm + ' and Product_Classification__r.Product_Group__c like \'%' + searchProductName.trim().replace('*','%') + '%\'';
            initialSearchTerm = initialSearchTerm + ' AND (Product_Classification__r.Product__c like \'%' + searchProductName.trim().replace('*','%') + '%\'' +
                    ' OR Product_Classification__r.SF_Product__r.Name like \'%' + searchProductName.trim().replace('*','%') + '%\'' +
                    ' OR Product_Classification__r.Product_Group__c like \'%' + searchProductName.trim().replace('*','%') + '%\')';
        }
        
        String queryString = bg_FacetedSearchComponentDelegateUtils.createQueryString(fieldsToReturnByObjectName, initialSearchTerm, selectedOptionsByObjectAndField);      
                
        List<Product__c> pList = Database.query(queryString);
        
        ProductSearchResults = new list<bg_Wrappers.ProductWrapper>();
        

        // Convert results to wrappers
        if(!pList.isEmpty()) {
            ProductSearchResults.addAll(bg_WrapperHelper.CreateProductWrappers(pList));
        }
    }

    /* 
        BSI - Centric Quoting Project Search Method
    */
    public void searchProject()
    {
        ProjectSearchResults = new List<bg_Wrappers.ProjectWrapper>();
        if(accId != null)
        {
            List<Project__c> pList =    [SELECT Id,
                                             Product__c,
                                             ProductId__c, 
                                             Name,
                                             Active__c,
                                             Account__c, 
                                             Area_of_Practice__c, 
                                             Project_End_Date__c, 
                                             Project_Family__c, 
                                             Project_Name__c, 
                                             Project_Start_Date__c, 
                                             Project_Status__c, 
                                             Project_Template__c,
                                             RecordType.Name
                                        FROM Project__c
                                        WHERE Active__c = true
                                        AND Account__c = :accId ORDER BY CreatedDate DESC];
            // Convert results to wrappers
            if(!pList.isEmpty())
            {
                ProjectSearchResults.addAll(bg_WrapperHelper.CreateProjectWrappers(pList));
            }
        }
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

                    if(!SelectProduct(qpw)) {
                        qpw.Selected = false;
                    }
                } else {
                    qpw.Selected = false;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'The C-Code level is required to quote for this product (' + productName + ')'));
                }
            }
        }
    }



    public void AddSelectedProjects() {
        /*
            Add Selected Projects to Grid
        */
        List<bg_Wrappers.ProjectWrapper> selectedProjectWrappers = new List<bg_Wrappers.ProjectWrapper>();

        for ( bg_Wrappers.ProjectWrapper projectWrapper : ProjectSearchResults)
        {
            if( projectWrapper.selected)
            {
                if(!projectIds.contains(projectWrapper.Id))
                {
                    selectedProjectWrappers.add(projectWrapper);
                    projectIds.add(projectWrapper.Id);
                }
                
            }
        }
        createProductWrapperForProjects(selectedProjectWrappers);
        
    }

    private void createProductWrapperForProjects(list<bg_Wrappers.ProjectWrapper> projectWrappers)
    {
        // IB create a product wrapper for each project
        for (bg_Wrappers.ProjectWrapper pw : projectWrappers)
        {
            Product__c product = bg_ProductUtils.GetProductById(pw.Project.Product__c);
            bg_Wrappers.QuoteProductWrapper qpw = bg_WrapperHelper.CreateQuoteProductWrapper(product, null, null, null);
            
            qpw.projectID = pw.project.Id;
            qpw.project = pw.project;
            AddSelectedProduct(qpw);
        }
    }
    
    private bg_Wrappers.QuoteProductWrapper GetQuoteProductWrapper(string productName, Product_Classification__c pc, Product2 standard) {
        /*
            Get Quote Product Wrapper
        */

        boolean result = true;
        // commit quote if it is new
        if(bg_StringUtils.IsBlank(quoId)) {
            result = SaveQuote(true); 
        }
        
        bg_Wrappers.QuoteProductWrapper qpw;
        if(result) {
            // get configurable product - main product
            Product__c product = bg_ProductUtils.GetProductByName(productName);

            qpw = bg_WrapperHelper.CreateQuoteProductWrapper(product, null, pc, standard);      
    
            if(CanSelectProduct(qpw)) {
                if(CheckRequiresContractReview(qpw, opp)) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'The selected standard product requires a completed contract review document'));
                } else {
                    if(!qpw.AllowMultipleInstances && productMap.containsKey(qpw.InstanceName)) {
                        qpw = productMap.get(qpw.InstanceName);
                    } else {
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
        //JORGE CHANGES
        //Get Project information to add:
        Project__c productProject;
        for(bg_Wrappers.ProjectWrapper pj:ProjectSearchResults)
        {
            if(pj.Id == qpw.projectID)
            {
                productProject = pj.Project;
            }
        }
        //JORGE CHANGES

        // Populate Quote Product & Create Product Site Wrappers
        if(qpw.SitesMap.isEmpty()) {
            bg_WrapperHelper.CreateProductSiteWrappers(quote, qpw, sites, true, true);
        }

        // Increment count && add to selected map
        bg_Wrappers.ProductAreaWrapper area;

        if(!productViewMap.containsKey(qpw.Gridview)) {
            area = bg_WrapperHelper.CreateProductAreaWrapper(qpw.Area, qpw.GridView);
            //JORGE CHANGES
            area.Project = productProject;
            //JORGE CHANGES
            productViewMap.put(qpw.Gridview, area);
            productAreas.add(area);
            qpw.ProductArea = area;
        }

        productViewMap.get(qpw.Gridview).products.add(qpw);
        productViewMap.get(qpw.Gridview).SelectedProductCount++;

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

            productViewMap.get(qpw.GridView).SelectedProductCount--;

            bg_WrapperHelper.RemoveProductFromSamplingMap(samplingMap, qpw);
            
            integer i = 0;
            list<bg_Wrappers.QuoteProductWrapper> products = productViewMap.get(qpw.GridView).products;
            for(bg_Wrappers.QuoteProductWrapper product : products) {
                if(product.InstanceName == qpw.InstanceName) 
                {
                    products.remove(i);
                    projectIds.remove(product.projectID);
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

        //set all the configuration complete to false as registrtion path has changed.
        for(bg_Wrappers.ProductSiteWrapper prodSiteWrapper : prod.sitesMap.values())
        {
            prodSiteWrapper.Completed = false;
        }   
            SelectRegistrationPath(prod, site);
            if(checkForSampling) {
                CheckForSamplingAvailable(prod);
            }
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
                
                if(!psw.IsControllingLocation)
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
        
        //HandleHQOnlyRegPaths(prod, psw.RegistrationPath);
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

        //set all the configuration complete to false as risk path has changed.
        for(bg_Wrappers.ProductSiteWrapper prodSiteWrapper : prod.sitesMap.values())
        {
            prodSiteWrapper.Completed = false;
        } 

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
        if(qpw != null) 
        {
            string regPath = '';
            //loop round site map to get the controlling location regpath
            for(bg_Wrappers.ProductSiteWrapper psw : qpw.SitesMap.values()) 
            {
                if(psw.IsControllingLocation)
                {
                    regPath = psw.RegistrationPath;
                }

            }

            for(integer Index : qpw.SitesMap.keySet()) 
            {
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
        if(qpw != null) 
        {
            string riskLevel = '';
            //loop round site map to get the controlling location RiskLevel
            for(bg_Wrappers.ProductSiteWrapper psw : qpw.SitesMap.values()) 
            {
                if(psw.IsControllingLocation)
                {
                    riskLevel = psw.RiskLevel;
                }

            }
            for(integer Index : qpw.SitesMap.keySet()) 
            {
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
            //JORGE HAS CHANGED THE FOLLOWING!!! START
            if(SaveQuote()) {
            //JORGE HAS CHANGED THE FOLLOWING!!! START
                if(quoId != null){
                    nextPage = returnToQuotePage();
                }
                else{
                    nextPage = new Pagereference('/' + bg_QuoteUtils.BuildNewQuoteGridURL(accId, oppId, quoId));    
                }
                
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
    public PageReference returnToQuotePage() {
        /*
            Return to Quote page
        */
        PageReference retPage;
        
            retPage = new PageReference('/' + quoId);
        
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

    /*
    *   Function that reset the contacts on quote creation page.
    */
    public void ResetContacts()
    {
        //reset all the contacts to select only if main quote
        if(quote.Main_Quote__c)
        {
            quote.Contact__c = null;
            quote.Invoice_Contact__c = null;
            quote.Booking__c = null;
            quote.CreditCheck__c = null;
        }
        else
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Only Main Quote Contacts can be Reset'));
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

        // Check products selected
        if(!quickSave) {
            if (productMap.isEmpty()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.bg_No_Product_Or_Project_Error));
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
        }
        
        // QUICK SAVE
        if(quickSave) 
        {
        }
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
        System.debug('bg_QuoteBuilderController: SaveQuote(boolean)' + quote);
        if(ValidateQuote(quickSave)) {
            try {
                // Save Quote
                quote.VF_ShowSiteSummary__c = ShowSiteSummary;
                quote.VF_ShowProductSearch__c = ShowProductSearch;
                quote.VF_ShowSelectionSummary__c = ShowSelectionSummary;
                quote.Configuration_Completed__c = true;
                System.debug('bg_QuoteBuilderController: ' + quote);
                System.debug('bg_QuoteBuilderController: ' + quote.Configuration_Completed__c);
                // Update Opportunity? 
                if(bg_OpportunityUtils.PopulateOpportunityDefaults(opp, isNew, quote.Contact__c)) {
                    bg_OpportunityUtils.SaveOpportunity(opp);
                }
                //bg_QuoteUtils.SaveQuote(quote, productMap, useDefaults, true);
                // IB concatenate productMap and projectProductMap to create QuoteProducts
                System.debug('Test 456' + productMap);
                bg_QuoteUtils.SaveQuote(quote, productMap, useDefaults, true);

                ClearDeleteQuoteProduct();
                
                useDefaults = false;
                quoId = quote.Id;
                result = true;          
            } catch (DmlException dml) {
                Apexpages.addMessages(dml);
            } catch (Exception ex) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage())); 
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
    
    /************************************************************************/
    /* FacetedSearchDelegate interface methods                              */  
    /************************************************************************/  
    public void addSearchComponent(String componentKey, bg_FacetedSearchComponent component)
    {
        if (facetedSearchComponentMap == null)
        {
            facetedSearchComponentMap = new Map<String, bg_FacetedSearchComponent>();
        }
        facetedSearchComponentMap.put(componentKey, component);
    }
  
    public List<SelectOption> getAllOptions(String objectName, String fieldPath)
    {
        
        String targetName = (fieldPath.lastIndexOf('.') == -1) ? objectName : fieldPath.substring(0, fieldPath.lastIndexOf('.') -1 ) + 'c';
        
        /** @TODO move implementation from faceted search controller */
        /** @TODO need to check that this is a picklist field, other valid option would be recordType */ 
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(targetName);
        // if the field is a lookup relationship then get just the field name
        String fieldName = (fieldPath.lastIndexOf('.') == -1) ? fieldPath : fieldPath.substring(fieldPath.lastIndexOf('.') + 1);
        /** @TODO check this is a picklist field type */
        List<SelectOption> allOptions = bg_Controllerutils.GetPicklistSelectOptions(targetType, fieldName);
                                            
        // add a placeholder value
        Map<String, Schema.SObjectField> fieldMap = targetType.getDescribe().fields.getMap();
        String selectFieldName = 'Select ' + fieldMap.get(fieldName).getDescribe().getLabel();
        allOptions.add(0, new SelectOption(selectFieldName, selectFieldName));
        return allOptions;
    }
      
    
    /************************************************************************/
    /* Additional methods to support Faceted Search                         */  
    /************************************************************************/  
    
    /*
        Reset to the User's last saved preferences
    */
    public void resetFilters()
    {
        /** @TODO */
    }
    
    /*
        Clear all of the filters on all of the components
    */
    public void removeFilters()
    {
        // Iterate over all component controllers
        for (bg_FacetedSearchComponent c : facetedSearchComponentMap.values())
        {
            c.resetFilters();
        }
    }
    
    
    public void addSelectOption(String objectName, String paramKey, List<String> selectedItems)
    {
        // get the map for this Object
        if (selectedOptionsByObjectAndField == null)
        {
            selectedOptionsByObjectAndField =  new Map<String, Map<String, Set<String>>>{objectName => new Map<String, Set<String>>()};
        }
        Map<String, Set<String>> objectMap = selectedOptionsByObjectAndField.get(objectName);
        if (objectMap == null)
        {
            objectMap = new Map<String, Set<String>>();
            selectedOptionsByObjectAndField.put(objectName, objectMap);
        }

        selectedOptionsByObjectAndField.get(objectName).put(paramKey, new Set<String>(selectedItems));

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

        bg_Wrappers.QuoteProductWrapper qpw = productMap.get(selectedProductName);
        // original version
        // hqQuoteProductId = qpw.qpId;         
        
        // change implemented 06/2018 which throws a npe
        // hqQuoteProductId = qpw.QuoteProduct.Id;      
        
        // restored version from 04/2018 back pre-dev sandbox refresh
        
        for (bg_Wrappers.ProductSiteWrapper site : qpw.SitesMap.values())
        {
            
            if (site.IsControllingLocation)
            {
                hqQuoteProductId = site.qpId;
            }
            
        }

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
        
        string docName = EncodingUtil.URLENCODE(bg_BluePrintUtils.GetDocumentName(System.Label.DaysProfile, quoteName, bg_BluePrintUtils.TEMPLATE_DOC_EXT_PDF),'UTF-8');
        
        string quoteLanguage = quote.QuoteLanguage__c;

        if(SaveQuote()) {
            productProfilePage = new Pagereference(bg_BluePrintUtils.BuildTemplateURL(bg_BluePrintUtils.TEMPLATE_NAME_PRODUCT_PROFILE, 
                                                                                            docName,
                                                                                            quoId,
                                                                                            hqQuoteProductId,
                                                                                            imsQuoteProductId,
                                                                                            samplingQuoteProductId,
                                                                                            quoteLanguage,
                                                                                            retUrl) + '&MergeMode=1');
        }
        return productProfilePage;          
    }
    
    
    public pageReference ViewProductProfileTest()
    {
        Pagereference productProfilePage = null;
        string hqQuoteProductId;
        string imsQuoteProductId;
        string samplingQuoteProductId;

        bg_Wrappers.QuoteProductWrapper qpw = productMap.get(selectedProductName);
        // original version
        // hqQuoteProductId = qpw.qpId;         
        
        // change implemented 06/2018 which throws a npe
        // hqQuoteProductId = qpw.QuoteProduct.Id;      
        
        // restored version from 04/2018 back pre-dev sandbox refresh
        
        for (bg_Wrappers.ProductSiteWrapper site : qpw.SitesMap.values())
        {
            
            if (site.IsControllingLocation)
            {
                hqQuoteProductId = site.qpId;
            }
            
        }

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
        
        string docName = EncodingUtil.URLENCODE(bg_BluePrintUtils.GetDocumentName(System.Label.DaysProfile, quoteName, bg_BluePrintUtils.TEMPLATE_DOC_EXT_PDF),'UTF-8');
        
        string quoteLanguage = quote.QuoteLanguage__c;

        if(SaveQuote()) {
            productProfilePage = new Pagereference(bg_BluePrintUtils.BuildTemplateURL('Days Profile', 
                                                                                            docName,
                                                                                            quoId,
                                                                                            hqQuoteProductId,
                                                                                            imsQuoteProductId,
                                                                                            samplingQuoteProductId,
                                                                                            quoteLanguage,
                                                                                            retUrl) + '&MergeMode=1');
        }
        return productProfilePage;          
    }
    
    
    
}