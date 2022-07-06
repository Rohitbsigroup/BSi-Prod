/********************************************************************
 * bg_WrapperHelper
 *
 * Wrapper Helper Utility methods to wrapper functions
 * 
 * 
 * Author: Richard Jimenez
 * Created: 02-09-2013
 * Changes: 
 *         01-08-2015 RJ Added HQ Reg path site support
 *         05-09-2015 RJ Added fix for adding suggested products
 *         31/08/2017 ADS Production Classification Fields; Division, Portoflio, Sector, Stream and Theme are now picklists
 *         12-09-2017 CPE Added NULL Exception protection into CreateProjectWrapper,  CreateProjectWrappers and GetControllingLocations methods 
 *                        Updated CreateProjectWrapper and CreateProductWrapper to use static variables from bg_CustomMetadataUtils
 *                        and not free text
 *         26-09-2017 RC  Added to createQuoteProductWrapper to set iscontrollinglocation
 *         27-09-2017 RC  Modified GetRegistrationPathItems to pass in islocation instead of hq.
 *         02-10-2017 RC  changed CreateQuoteProductWrapper to set GridView
 *         10-10-2017 RC  change PopulateQuoteProductWrappers to set controlling location off the gridview.
 *         02-11-2017 BP  Change PopulateQuoteProductWrappers to include inactive products for existing parts
 *         13-11-2017 ADS Case 33437 Only Systems Certification Products should appear in the sampling map
 ********************************************************************/
public class bg_WrapperHelper {

    /**********************************************************************************/
    /* Create Wrappers                                                                */
    /**********************************************************************************/


    public class WrapperHelperException extends Exception{}

    public static list<bg_Wrappers.ProductWrapper> CreateProductWrappers(list<Product__c> products) {
        /* Build Product Wrappers */    
        return CreateProductWrappers(products, new set<string>());
    }

    public static list<bg_Wrappers.ProjectWrapper> CreateProjectWrappers(list<Project__c> projects) {
        /* Build Product Wrappers */    
        return CreateProjectWrappers(projects, new set<string>());
    }

    public static list<bg_Wrappers.ProductWrapper> CreateProductWrappers(list<Product__c> products, set<string> selectedProducts) {
        /*
            Build Product Wrappers and set selected items
        */      
        list<bg_Wrappers.ProductWrapper> productWrappers = new list<bg_Wrappers.ProductWrapper>();
        for(Product__c product : products) {
            productWrappers.add(CreateProductWrapper(product, selectedProducts));
        }
        return productWrappers;
    }

    public static list<bg_Wrappers.ProjectWrapper> CreateProjectWrappers(list<Project__c> projects, set<string> selectedProjects) {
        /*
            Build Product Wrappers and set selected items
        */      
        list<bg_Wrappers.ProjectWrapper> projectWrappers = new list<bg_Wrappers.ProjectWrapper>();
        if (projects != null)
        {
            for(Project__c project : projects) {
                projectWrappers.add(CreateProjectWrapper(project, selectedProjects));
            }
        }
        return projectWrappers;
    }

    public static bg_Wrappers.ProductWrapper CreateProductWrapper(Product__c product) {
        /* Create Product Wrapper */
        return  CreateProductWrapper(product, new set<string>());   
    }

    public static integer GetSamplingThreshold(decimal threshold) {
        /* Get Sampling Threshold */
        return bg_Utilities.getInteger(threshold, integer.valueOf(bg_CustomSettingsUtils.GetSiteSettings().SamplingThreshold__c));  
    }
    
    public static bg_Wrappers.ProductWrapper CreateProductWrapper(Product__c product, set<string> selectedProducts) {
        /*
            Create Product Wrapper
        */  
        bg_Wrappers.ProductWrapper pw = new bg_Wrappers.ProductWrapper();
        pw.Id = product.Id;
        pw.Name = product.Name;
        pw.AllowMultipleInstances = product.AllowMultipleInstances__c;
        pw.ShowClassificationName = product.ShowClassificationName__c;
        pw.SamplingThreshold = GetSamplingThreshold(product.Sampling_Threshold__c);
        pw.SamplingRule = product.Sampling_Rule__c;
        pw.Sampling1inN = bg_Utilities.getInteger(product.Sampling1inN__c);     
        pw.product = product;
        pw.Selected = selectedProducts.contains(product.Name);

        if(product.Product_Classification__c != null) {
            pw.Area = product.Product_Classification__r.Stream2__c; 
            pw.ProductClassification = product.Product_Classification__r;
            pw.ClassificationName = product.Product_Classification__r.Product__c;
        } else {
            pw.Area = product.Product_Stream__c;
            pw.ClassificationName = pw.Name;
            pw.ProductClassification = null;
        }

        // IB POC of dynamic columns
        pw.displayFields = new Map<String, Object>();
        
        Map<String, Object> fieldMap = new Map<String, Object>();
        List<Faceted_Search_Result_Fields__mdt> fieldsToQuery = bg_CustomMetadataUtils.GetSearchResultFields(bg_CustomMetadataUtils.PRODUCT_SEARCH_CONTAINER);
        
        Object fieldValue;
        for (Faceted_Search_Result_Fields__mdt f : fieldsToQuery)
        {
            try
            {
                fieldValue = TraverseLookupForFieldValue(f.Field_API_Name__c, product);
            }
            catch ( Exception e)
            {
                /**@TODO error handling !!! */ 
                
                System.debug('++++ e = ' + e);
            }
            
            pw.displayFields.put(f.Display_Name__c, fieldValue);
        }
        
        return pw;
    }

    public static bg_Wrappers.ProjectWrapper CreateProjectWrapper(Project__c project, set<string> selectedProjects) {
        
        /*
            Create Project Wrapper
        */  
        bg_Wrappers.ProjectWrapper pw = new bg_Wrappers.ProjectWrapper();
        pw.displayFields = new Map<String, Object>();

        if (project != null) // prevent null reference error if null project record supplied
        {
            pw.Id = project.Id;
            pw.Name = project.Name;
            pw.ProjectStatus = project.Project_Status__c;
            pw.ProjectType = project.Area_of_Practice__c;
            pw.Active = project.Active__c;
            pw.project = project;
            if (selectedProjects != null)
            {
                pw.Selected = selectedProjects.contains(project.Name);
            }
        
        
            Map<String, Object> fieldMap = new Map<String, Object>();
            
            List<Faceted_Search_Result_Fields__mdt> fieldsToQueryProject = bg_CustomMetadataUtils.GetSearchResultFields(bg_CustomMetadataUtils.PROJECT_SEARCH_CONTAINER);
            
            Object fieldValue;
            for (Faceted_Search_Result_Fields__mdt f : fieldsToQueryProject)
            {
            
                try
                {
                    fieldValue = TraverseLookupForFieldValue(f.Field_API_Name__c, project);
                }
                catch ( Exception e)
                {
            
                    
                    System.debug('++++ e = ' + e);
                }
                
                pw.displayFields.put(f.Display_Name__c, fieldValue);
            }
        }
        return pw;
    }
    
    private static Object TraverseLookupForFieldValue ( String fieldName, sObject queriedObject)
    {
        String[] pathArray = fieldName.split('\\.');
        
        Object objectToReturn = null; // use Object to avoid casting at this stage 
        sObject objectForGet = queriedObject;
        for (Integer i = 0; i < pathArray.size() - 1; i++) {
            objectForGet = objectForGet.getSobject(pathArray[i]);
            if ( objectForGet == null)
            {
                // relationship not populated so break and return null for target field
                break;
            }
        }
        
        if ( objectForGet != null)
        {
            objectToReturn = objectForGet.get(pathArray[pathArray.size() -1]);
        }
        
        if(objectToReturn == null)
        {
            // return an empty string to allow VF to call map without an error
            objectToReturn = '';
        }
        return objectToReturn;
    }

    /****************************************************************************************/
    public static list<bg_Wrappers.ProductWrapper> CreateProductWrappers(list<Product_Classification__c> pcList) {
        /* Build Product Wrappers */    
        list<bg_Wrappers.ProductWrapper> productWrappers = new list<bg_Wrappers.ProductWrapper>();
        for(Product_Classification__c pc : pcList) {
            productWrappers.add(CreateProductWrapper(pc));
        }
        return productWrappers;
    }

    public static bg_Wrappers.ProductWrapper CreateProductWrapper(Product_Classification__c pc) {
        /*
            Create Product Wrapper
        */  
        bg_Wrappers.ProductWrapper pw = new bg_Wrappers.ProductWrapper();
        pw.Id = pc.SF_Product__c;
        pw.Name = pc.SF_Product__r.Name;
        pw.ClassificationName = pc.Product__c;
        pw.AllowMultipleInstances = pc.SF_Product__r.AllowMultipleInstances__c;
        pw.ShowClassificationName = pc.SF_Product__r.ShowClassificationName__c;
        pw.product = pc.SF_Product__r;
        pw.productClassification = pc; 
        pw.StandardId = pc.Standard__c;
        pw.Area = pc.Stream2__c;
        pw.SamplingThreshold = GetSamplingThreshold(pc.SF_Product__r.Sampling_Threshold__c);
        pw.SamplingRule = pc.SF_Product__r.Sampling_Rule__c;
        pw.Sampling1inN = bg_Utilities.getInteger(pc.SF_Product__r.Sampling1inN__c);
        
        //pw.Selected = selectedProducts.contains(product.Name);

        return pw;
    }
    /****************************************************************************************/
        
    public static map<string, bg_Wrappers.ProductWrapper> CreateProductWrappersMap(list<Product__c> products) {
        /*
            Build Product Wrappers Map
        */
        map<string, bg_Wrappers.ProductWrapper> productWrappers = new map<string, bg_Wrappers.ProductWrapper>();        
        for(Product__c product : products) {
            productWrappers.put(product.Name, CreateProductWrapper(product));
        }
        return productWrappers;
    }

    public static map<string, map<string, map<string, bg_Wrappers.ProductWrapper>>> CreateProductInterestsWrapperMap(map<string, bg_Wrappers.ProductWrapper> productWrapperMap) {
        /* Return product interest map with no list of selected items */
        return CreateProductInterestsWrapperMap(productWrapperMap, new set<string>());
    }

    public static map<string, map<string, map<string, bg_Wrappers.ProductWrapper>>> CreateProductInterestsWrapperMap(map<string, bg_Wrappers.ProductWrapper> productWrapperMap, list<string> selectedProducts) {
        /*
            Return product interest map with list of selected items
        */
        set<string> selectedProductSet = new set<string>(selectedProducts);
        return CreateProductInterestsWrapperMap(productWrapperMap, selectedProductSet);
    }

    public static map<string, map<string, map<string, bg_Wrappers.ProductWrapper>>> CreateProductInterestsWrapperMap(map<string, bg_Wrappers.ProductWrapper> productWrapperMap, set<string> selectedProducts) {
        /*
            Return product interest map with set of selected items
        */
        map<string, map<string, map<string, bg_Wrappers.ProductWrapper>>> productInterestMap = new map<string, map<string, map<string, bg_Wrappers.ProductWrapper>>>();     
        // loop through each product
        for(bg_Wrappers.ProductWrapper pw : productWrapperMap.values()) {
            if(!bg_StringUtils.IsBlank(pw.Product.Name) && 
                !bg_StringUtils.IsBlank(pw.Product.Portfolio_Interest__c) && 
                !bg_StringUtils.IsBlank(pw.Product.Product_Area_Interest__c)) 
            {                   
                // check if portfolio exists? - add portfolio
                if(!productInterestMap.containsKey(pw.Product.Portfolio_Interest__c)) {
                    productInterestMap.put(pw.Product.Portfolio_Interest__c, new map<string, map<string, bg_Wrappers.ProductWrapper>>());
                }
                // check if product area exists? - add product area
                map<string, map<string, bg_Wrappers.ProductWrapper>> portfolioMap = productInterestMap.get(pw.Product.Portfolio_Interest__c);
                if(!portfolioMap.containsKey(pw.Product.Product_Area_Interest__c)) {
                    portfolioMap.put(pw.Product.Product_Area_Interest__c, new map<string, bg_Wrappers.ProductWrapper>());
                }
                // check if product exists? - add product
                map<string, bg_Wrappers.ProductWrapper> productMap = portfolioMap.get(pw.Product.Product_Area_Interest__c);
                if(!productMap.containsKey(pw.Product.Name)) {
                    productMap.put(pw.Product.Name, pw);
                }

                if(selectedProducts.contains(pw.Product.Name)) {
                    pw.selected = true;
                }
            }               
        }       
        // return product interest map
        return productInterestMap;
    }

    public static bg_Wrappers.ProductSiteWrapper CreateProductSiteWrapper(Quote__c quote, bg_Wrappers.QuoteProductWrapper qpw, bg_Wrappers.SiteWrapper sw) {
        /* Create Site Product Wrapper */
        return CreateProductSiteWrapper(quote, qpw, sw, null);
    }

    public static bg_Wrappers.ProductSiteWrapper CreateProductSiteWrapper(Quote__c quote, bg_Wrappers.QuoteProductWrapper qpw, bg_Wrappers.SiteWrapper sw, Quote_Product__c qp) {
        /* Create Site Product Wrapper */
        return CreateProductSiteWrapper(quote, qpw, sw, qp, null);
    }
    
    public static bg_Wrappers.ProductSiteWrapper CreateProductSiteWrapper(Quote__c quote, bg_Wrappers.QuoteProductWrapper qpw, bg_Wrappers.SiteWrapper sw, Quote_Product__c qp, map<Id, Contact> contactMap) {
        return CreateProductSiteWrapper(quote, qpw, sw, qp, null, false);
    }
    
    public static bg_Wrappers.ProductSiteWrapper CreateProductSiteWrapper(Quote__c quote, bg_Wrappers.QuoteProductWrapper qpw, bg_Wrappers.SiteWrapper sw, Quote_Product__c qp, map<Id, Contact> contactMap, boolean setHQDefaultRegPath) {
        /*
            Create Site Product Wrapper
        */
        
        system.debug('CreateProductSiteWrapper');
            
        bg_Wrappers.ProductSiteWrapper psw = new bg_Wrappers.ProductSiteWrapper();
        psw.Selectable = false;
        psw.Product = qpw.Name;
        psw.SiteIndex = sw.Index;
        psw.QuoteProduct = qpw;
        psw.Site = sw;
        psw.contactMap = contactMap;

        psw.IsControllingLocation = (qpw.controllingLocationId == sw.Id);

        if(qp == null) {
            system.debug('New ProductSiteWrapper');
                    
            // New ProductSiteWrapper - set the defaults 
            PopulateProductSiteDefaults(psw, quote);
            
            system.debug('qpw.IsDefaultSelected: ' + qpw.IsDefaultSelected);
            system.debug('psw.SiteIndex: ' + psw.SiteIndex);

            if(!bg_StringUtils.IsBlank(sw.RiskLevel)) {
                psw.RiskLevel = sw.RiskLevel;
            } else {
                psw.RiskLevel = bg_SiteUtils.DEFAULT_RISK_LEVEL;
            }

            system.debug('setHQDefaultRegPath: ' + setHQDefaultRegPath);

            if(setHQDefaultRegPath && ((psw.Site.IsHQ && qpw.HQOnly) || !qpw.HQOnly)) 
            {
                if(psw.Site.IsHQ && !bg_StringUtils.IsBlank(quote.RegistrationPath__c) && qpw.RegistrationPaths.contains(quote.RegistrationPath__c)) { 
                    psw.RegistrationPath = quote.RegistrationPath__c;
                
                } else if (qpw.IsDefaultSelected) {
                    psw.RegistrationPath = qpw.DefaultRegistrationPath;
                }
                
                psw.Selected = !bg_StringUtils.IsBlank(psw.RegistrationPath);

                system.debug('psw.Selected: ' + psw.Selected);
                system.debug('psw.RegistrationPath: ' + psw.RegistrationPath);
            }
            if(qpw.Area == bg_ProductUtils.PRODUCT_STREAM_PS || !qpw.GridView)
            {
                psw.Selected = true;
                psw.RegistrationPath = bg_QuoteUtils.DEFAULT_REGPATH_NONASSURANCE;
            }
            
        } else {
            // Load values from Quote Product
            psw.qpId = qp.Id; 
            psw.RegistrationPath = qp.Registration_Path__c;
            psw.RiskLevel = qp.Risk_Level__c;
            psw.Selected = qp.Selected__c;
            psw.Completed = qp.Configuration_Complete__c;
            psw.CalculatedRiskLevel = qp.Calculated_Risk_Level__c;
            psw.FileUploaded = qp.FileUploaded__c;

            psw.PricebookId = qp.Price_Book__c;
            psw.PricebookName = qp.Price_Book_Name__c;
            psw.CurrencyCode = qp.CurrencyIsoCode;
            psw.SecondaryPricebookId = qp.Secondary_Price_Book__c;
            
            psw.ContactRoleMap.put(bg_ContactUtils.CONTACT_SITE_ROLE_PRIMARY, qp.Primary_Contact__c);
            psw.ContactRoleMap.put(bg_ContactUtils.CONTACT_SITE_ROLE_BOOKING, qp.Booking_Contact__c);
            psw.ContactRoleMap.put(bg_ContactUtils.CONTACT_SITE_ROLE_CREDIT_CHECK, qp.Credit_Check_Contact__c);
            psw.ContactRoleMap.put(bg_ContactUtils.CONTACT_SITE_ROLE_INVOICE, qp.Invoice_Contact__c);
        }
        return psw;
    }
    
    public static void PopulateProductSiteDefaults(bg_Wrappers.ProductSiteWrapper psw, Quote__c quote) {
        /* 
            Method to populate quote product defaults
        */
        // Set registration path to empty string
        psw.RegistrationPath = '';
        // Set as not selected
        psw.Selected = false;
        // Set default contacts
        PopulateProductSiteContactDefaults(psw, quote);
        // Set default currencies
        PopulateProductSiteCurrencyDefaults(psw, quote);
    }

    public static void PopulateProductSiteContactDefaults(bg_Wrappers.ProductSiteWrapper psw, Quote__c quote) {
        /* 
            Method to populate quote product contact defaults
        */
        psw.ContactRoleMap.put(bg_ContactUtils.CONTACT_SITE_ROLE_PRIMARY, GetDefaultContactId(quote, psw.site.Id, quote.Contact__c, bg_ContactUtils.CONTACT_SITE_ROLE_PRIMARY));
        psw.ContactRoleMap.put(bg_ContactUtils.CONTACT_SITE_ROLE_BOOKING, GetDefaultContactId(quote, psw.site.Id, quote.Booking__c, bg_ContactUtils.CONTACT_SITE_ROLE_BOOKING));
        psw.ContactRoleMap.put(bg_ContactUtils.CONTACT_SITE_ROLE_CREDIT_CHECK, GetDefaultContactId(quote, psw.site.Id, quote.CreditCheck__c, bg_ContactUtils.CONTACT_SITE_ROLE_CREDIT_CHECK));
        psw.ContactRoleMap.put(bg_ContactUtils.CONTACT_SITE_ROLE_INVOICE, GetDefaultContactId(quote, psw.site.Id, quote.Invoice_Contact__c, bg_ContactUtils.CONTACT_SITE_ROLE_INVOICE));
    }
    
    private static Id GetDefaultContactId(Quote__c quote, Id siteId, Id quoteContactId, string role) {
        /*
            Return default contact
        */
        if(quote.UseSiteContactDefaults__c) {
            return bg_ContactUtils.GetDefaultContactId(quote, siteId, quoteContactId, role);
        } else {
            return quoteContactId;
        }
    }
    
    public static void PopulateProductSiteCurrencyDefaults(bg_Wrappers.ProductSiteWrapper psw, Quote__c quote) {
        /* 
            Method to populate quote product contact defaults
        */
        string countryCode = psw.site.Country;
        if(quote.UseLocalPrices__c && !bg_StringUtils.IsBlank(countryCode)) {
            // Set default currency to quote currency
            psw.CurrencyCode = bg_PricebookUtils.GetCurrencyCodeByCountry(countryCode, quote.CurrencyIsoCode);
            // Set default pricebook name
            map<string, Pricebook2> oppSitePbMap =  bg_PricebookUtils.GetPricebookByOpportunitySites(quote.Opportunity_Name__c);
            if(oppSitePbMap.containsKey(countryCode)) {
                psw.PricebookId = oppSitePbMap.get(countryCode).Id;
                psw.PricebookName = oppSitePbMap.get(countryCode).Name;
            } else {
                psw.PricebookId = quote.PriceBook2Id__c;
                psw.PricebookName = bg_PricebookUtils.GetPricebookById(quote.PriceBook2Id__c).Name;
            }
        } else {
            // Set default currency to quote currency
            psw.CurrencyCode = quote.CurrencyIsoCode;
            // Set default pricebook name
            psw.PricebookId = quote.PriceBook2Id__c;
            psw.PricebookName = bg_PricebookUtils.GetPricebookById(quote.PriceBook2Id__c).Name;
        }
        // Default secondary pricebook book to primary
        psw.SecondaryPricebookId = psw.PricebookId;
    }

    public static bg_Wrappers.IMSWrapper CreateIMSWrapper(string product, set<string> imsProducts, set<string> selectedProducts, set<string> selectedIMSProducts, set<string> allSelectedIMS) {
        /*
            Create IMS Wrapper
        */
        bg_Wrappers.IMSWrapper imsw = new bg_Wrappers.IMSWrapper();     
        imsw.Product = product;
        imsw.IMSProducts = imsProducts;
        imsw.SelectedProducts = selectedProducts;
        imsw.SelectedIMSProducts = selectedIMSProducts;
        imsw.AllProducts = (imsProducts.size() == 1 && imsProducts.contains('All'));
        imsw.AllSelectedIMS = allSelectedIMS;
        return imsw;
    }

    public static bg_Wrappers.QuoteProductWrapper CreateQuoteProductWrapper(Product__c product) {
        /* Create Quote Product Wrapper */
        return CreateQuoteProductWrapper(product, null, null);
    }

    public static bg_Wrappers.QuoteProductWrapper CreateQuoteProductWrapper(Product_Classification__c pc) {
        /*
            Create Quote Product Wrapper
        */      
        Product__c product = bg_ProductUtils.GetProductById(pc.SF_Product__c);
        bg_Wrappers.QuoteProductWrapper qpw = CreateQuoteProductWrapper(product);
        qpw.Name = pc.Product__c;
        qpw.Area = pc.Stream2__c;
        return qpw;
    }

    public static bg_Wrappers.QuoteProductWrapper CreateQuoteProductWrapper(Product__c product, Product_Classification__c pc) {
        /* Create Quote Product Wrapper */
        return CreateQuoteProductWrapper(product, null, pc);
    }   
    
    public static bg_Wrappers.QuoteProductWrapper CreateQuoteProductWrapper(Product__c product, bg_Wrappers.ProductAreaWrapper prodArea) {
        /* Create Quote Product Wrapper */
        return CreateQuoteProductWrapper(product, prodArea, null);
    }   

    public static bg_Wrappers.QuoteProductWrapper CreateQuoteProductWrapper(Product__c product, bg_Wrappers.ProductAreaWrapper prodArea, Product_Classification__c pc) {
        return CreateQuoteProductWrapper(product, prodArea, null, null);
    }

    public static bg_Wrappers.QuoteProductWrapper CreateQuoteProductWrapper(Product__c product, bg_Wrappers.ProductAreaWrapper prodArea, Product_Classification__c pc, Product2 standard) {
        /*
            Create Quote Product Wrapper
        */
        bg_Wrappers.QuoteProductWrapper qpw = new bg_Wrappers.QuoteProductWrapper();        
        qpw.Name = product.Name;
        qpw.Id = product.Id;
        qpw.ProductArea = prodArea;

        
        
        Product_Classification__c selectedPC;
        if(pc != null) {
            selectedPC = pc;
        } else if(product.Product_Classification__r != null) {
            selectedPC = product.Product_Classification__r;
        }

        if(selectedPC != null) {
            qpw.Area = selectedPC.Stream2__c;   
            qpw.ProductClassification = selectedPC;
            qpw.ClassificationName = selectedPC.Product__c;
            if(standard == null && selectedPC.Standard__c != null) {
                qpw.StandardId = selectedPC.Standard__c;
                qpw.RequiresContractReview = selectedPC.Standard__r.RequiresContractReview__c;
                qpw.Area = selectedPC.Standard__r.Division__c;  
            }
        } else {
            qpw.Area = product.Product_Stream__c;
        }

        // standard
        if(standard != null) {
            qpw.StandardId = standard.Id;
            qpw.ClassificationName = standard.Name + ' (' + product.Name + ')';
            qpw.RequiresContractReview = standard.RequiresContractReview__c;
            qpw.Area = standard.Division__c;    
        }

        if(product.Related_Products__r.size() == 1 && product.Related_Products__r[0].All_Products_Relations__c) {
            qpw.IMSProducts = new set<string>{'All'};
        } else {
            qpw.IMSProducts = bg_StringUtils.GetObjectStringSet(product.Related_Products__r, 'Related_Product_Name__c');            
        }

        qpw.UseSampling = true;
        qpw.SamplingAvailable = false;
        qpw.HQOnly = product.HQ_Only__c;
        qpw.CCode = product.CCode__c;
        qpw.SupportsIMS = product.IMS__c;
        qpw.RegistrationPaths = product.RegistrationPaths__c;
        qpw.RiskType = product.Type__c;
        qpw.FileUpload = product.FileUpload__c;
        qpw.SingleSellProduct = product.SingleSellProduct__c;
        qpw.CountriesRequiringBSIMembership = product.CountriesRequiringBSIMembership__c;        
        qpw.AllowMultipleInstances = product.AllowMultipleInstances__c;
        qpw.ShowClassificationName = product.ShowClassificationName__c;
        qpw.SamplingThreshold = GetSamplingThreshold(product.Sampling_Threshold__c);
        qpw.SamplingRule = product.Sampling_Rule__c;
        qpw.Sampling1inN = bg_Utilities.getInteger(product.Sampling1inN__c);
        qpw.GridView = product.GridView__c;
        System.debug(1123345 + '--' + qpw);
        return qpw;
    }

    public static bg_Wrappers.ProductAreaWrapper CreateProductAreaWrapper(string title, boolean GridView) {
        /*
            Create Product Area Wrapper
        */      
        bg_Wrappers.ProductAreaWrapper prodAreaWrapper = new bg_Wrappers.ProductAreaWrapper();
        prodAreaWrapper.Title = title;
        prodAreaWrapper.GridView = GridView;
        return prodAreaWrapper;
    }

    public static bg_Wrappers.SiteWrapper CreateSiteWrapper(integer index, OpportunitySite__c oppSite, boolean isHQ) {
        /*
            Create Site Wrapper
        */      
        bg_Wrappers.SiteWrapper siteWrapper = CreateSiteWrapper(index, oppSite.Site__r , isHQ);     
        siteWrapper.OppSiteId = oppSite.Id;
        //siteWrapper.Type = oppSite.Type__c;
        //siteWrapper.Industry = oppSite.Industry__c;
        //siteWrapper.TCode = oppSite.SiteTCode__c;
        return siteWrapper;
    }

    public static bg_Wrappers.SiteWrapper CreateSiteWrapper(integer index, Site__c site, boolean isHQ) {
        /*
            Create Site Wrapper
        */
        bg_Wrappers.SiteWrapper sw = new bg_Wrappers.SiteWrapper();     
        sw.Id = site.Id;
        sw.Index = index;
        sw.Name = site.Name;
        sw.Type = site.Type__c;
        sw.IsHQ = isHQ;
        sw.TCode = site.TCodeDescr__c;
        sw.Country = site.Country_Code__c;      
        sw.SCode = site.S_Code__c;
        sw.RiskLevel = site.Risk_Level__c;
        sw.NoEmployees = integer.valueOf(bg_Utilities.getDecimal(site.NumberEmployees__c));
        
        return sw;
    }

    public static list<bg_Wrappers.ProductAreaWrapper> CreateProductAreaWrappers(list<Product__c> products) {
        /*
            Create Product Areas Wrappers
        */
        list<bg_Wrappers.ProductAreaWrapper> productAreas = new list<bg_Wrappers.ProductAreaWrapper>();     
        map<string, bg_Wrappers.ProductAreaWrapper> areaMap = new map<string, bg_Wrappers.ProductAreaWrapper>();
        
        bg_Wrappers.ProductAreaWrapper prodArea;
        for(Product__c product : products) {
            if(!areaMap.containsKey(product.Product_Stream__c)) {
                prodArea = CreateProductAreaWrapper(product.Product_Stream__c, product.GridView__c);
                productAreas.add(prodArea);
                areaMap.put(product.Product_Stream__c, prodArea);
            }
            prodArea = areaMap.get(product.Product_Stream__c);
            prodArea.products.add(CreateQuoteProductWrapper(product, prodArea));            
        }       
        return productAreas;
    }

    public static list<bg_Wrappers.QuoteProductWrapper> CreateQuoteProductWrappers(list<Product__c> products) {
        /* Create Quote Product Wrappers */
        System.debug(1123345);
        return CreateQuoteProductWrappers(products, null);
    }

    public static list<bg_Wrappers.QuoteProductWrapper> CreateQuoteProductWrappers(list<Product__c> products, bg_Wrappers.ProductAreaWrapper prodArea) {
        /*
            Create Quote Product Wrappers
        */
        list<bg_Wrappers.QuoteProductWrapper> quoteProductWrappers = new list<bg_Wrappers.QuoteProductWrapper>();
        for(Product__c product : products) {
            quoteProductWrappers.add(CreateQuoteProductWrapper(product, prodArea));
        }
        return quoteProductWrappers;
    }

    public static map<string, bg_Wrappers.ProductAreaWrapper> CreateProductAreaWrappersMap(list<bg_Wrappers.ProductAreaWrapper> productAreaWrappers) {
        /*
            Create Product Areas Wrappers Map
        */
        map<string, bg_Wrappers.ProductAreaWrapper> productAreaWrappersMap = new map<string, bg_Wrappers.ProductAreaWrapper>();
        for(bg_Wrappers.ProductAreaWrapper paw : productAreaWrappers) {
            productAreaWrappersMap.put(paw.Title, paw);
        }
        return productAreaWrappersMap;
    }

    public static map<string, bg_Wrappers.QuoteProductWrapper> CreateQuoteProductWrappersMap(list<bg_Wrappers.ProductAreaWrapper> productAreaWrappers) {
        /* 
            Create Quote Product Wrappers Map 
        */
        map<string, bg_Wrappers.QuoteProductWrapper> productWrappersMap = new map<string, bg_Wrappers.QuoteProductWrapper>();               
        for(bg_Wrappers.ProductAreaWrapper paw : productAreaWrappers) {
            productWrappersMap.putAll(CreateQuoteProductWrappersMap(paw.Products));
        }
        return productWrappersMap;      
    }
    
    public static map<string, bg_Wrappers.QuoteProductWrapper> CreateQuoteProductWrappersMap(list<bg_Wrappers.QuoteProductWrapper> qpWrappers) {
        /*
            Create Quote Product Wrappers Map
        */      
        map<string, bg_Wrappers.QuoteProductWrapper> productWrappersMap = new map<string, bg_Wrappers.QuoteProductWrapper>();
        for(bg_Wrappers.QuoteProductWrapper pw : qpWrappers) {
            productWrappersMap.put(pw.InstanceName, pw);
        }
        return productWrappersMap;      
    }

    public static list<bg_Wrappers.SiteWrapper> CreateSiteWrappers(list<OpportunitySite__c> oppSites) {
        /*
            Create Site Wrappers
        */
        list<bg_Wrappers.SiteWrapper> siteWrappers = new list<bg_Wrappers.SiteWrapper>();       
        for(OpportunitySite__c oppSite : oppSites) {
            siteWrappers.add(CreateSiteWrapper(siteWrappers.Size()+1, oppSite, false));
        }
        return siteWrappers;
    }

    public static bg_Wrappers.SiteWrapper GetHQSite(list<bg_Wrappers.SiteWrapper> sites) {
        /*
            Return HQ Site Wrapper
        */
        for(bg_Wrappers.SiteWrapper sw : sites) {
            if(sw.IsHQ) {
                return sw;
            }
        }
        return null;
    }

    public static map<string, map<string, map<string, bg_Wrappers.RegPathSampleWrapper>>> CreateSamplingMap(list<bg_Wrappers.SiteWrapper> sites, map<string, bg_Wrappers.ProductWrapper> productMap) {
        /*
            Create Sampling Map
        */
        map<string, map<string, map<string, bg_Wrappers.RegPathSampleWrapper>>> samplingMap = new map<string, map<string, map<string, bg_Wrappers.RegPathSampleWrapper>>>();
        return samplingMap;
    }

    public static void CreateProductSiteWrappers(Quote__c quote, list<bg_Wrappers.QuoteProductWrapper> quoteProducts, list<bg_Wrappers.SiteWrapper> sites) {
        /* Create Product Site Wrappers */
        CreateProductSiteWrappers(quote, quoteProducts, sites, true);
    }

    public static void CreateProductSiteWrappers(Quote__c quote, list<bg_Wrappers.QuoteProductWrapper> quoteProducts, list<bg_Wrappers.SiteWrapper> sites, boolean createMissingProductSites) {
        /*
            Create Product Site Wrappers
        */          
        CreateProductSiteWrappers(quote, quoteProducts, sites, true, false);
    }

    public static void CreateProductSiteWrappers(Quote__c quote, list<bg_Wrappers.QuoteProductWrapper> quoteProducts, list<bg_Wrappers.SiteWrapper> sites, boolean createMissingProductSites, boolean setHQDefaultRegPath) {
        /*
            Create Product Site Wrappers
        */          
        for(bg_Wrappers.QuoteProductWrapper qpw : quoteProducts) {
            // populate missing sites
            bg_WrapperHelper.CreateProductSiteWrappers(quote, qpw, sites, createMissingProductSites, setHQDefaultRegPath);
        }
    }
    
    public static void CreateProductSiteWrappers(Quote__c quote, bg_Wrappers.QuoteProductWrapper quoteProduct, list<bg_Wrappers.SiteWrapper> sites) {
        /* Create Product Site Wrappers */
        CreateProductSiteWrappers(quote, quoteProduct, sites, true);
    }
    
    public static void CreateProductSiteWrappers(Quote__c quote, bg_Wrappers.QuoteProductWrapper quoteProduct, list<bg_Wrappers.SiteWrapper> sites, boolean createMissingProductSites) {
        /* Create Product Site Wrappers */
        CreateProductSiteWrappers(quote, quoteProduct, sites, true, true);
    }
        
    public static void CreateProductSiteWrappers(Quote__c quote, bg_Wrappers.QuoteProductWrapper quoteProduct, list<bg_Wrappers.SiteWrapper> sites, boolean createMissingProductSites, boolean setHQDefaultRegPath) {
        /*
            Create Product Site Wrappers
        */
        List<bg_Wrappers.SiteWrapper> siteWrappersToProcess = new List<bg_Wrappers.SiteWrapper>();
        // if the quoteProductWrapper is for professional services we only want to create 1 product site wrapper,
        // The area attribute on the wrapper is set to the product stream when created, we check this value  
        // this will ensure we only get 1 quote product when we run through the save quote process.
        // It does not matter which site gets linked to the quote product, we need to specify a site to keep the same structure to prevent a rewrite of wrappers and process
        if(!quoteProduct.GridView)
        {
            siteWrappersToProcess.add(sites[0]);
        }
        else
        {
            siteWrappersToProcess.addall(sites);    
        }
        for(bg_Wrappers.SiteWrapper site : siteWrappersToProcess) {
            if(!quoteProduct.SitesMap.containsKey(site.Index)) {
                bg_Wrappers.ProductSiteWrapper psw;
                if(createMissingProductSites) {
                    psw = CreateProductSiteWrapper(quote, quoteProduct, site, null, null, setHQDefaultRegPath);
                } else {
                    psw = new bg_Wrappers.ProductSiteWrapper();
                }
                quoteProduct.SitesMap.put(site.Index, psw);
            }
        }
        system.debug('##CB quoteProductWrapper Sites Map: '+quoteProduct.SitesMap);
    }

    public static map<string, bg_Wrappers.IMSWrapper> CreateIMSProductMap(map<string, bg_Wrappers.QuoteProductWrapper> productMap, set<string> selectedProducts, set<string> selectedIMSProducts, set<string> allSelectedIMS) {
        /*
            Create IMS Wrapper Product Map
        */  
        map<string, bg_Wrappers.IMSWrapper> imsProductMap = new map<string, bg_Wrappers.IMSWrapper>();
        for(bg_Wrappers.QuoteProductWrapper product : productMap.values()) {
            imsProductMap.put(product.Name, CreateIMSWrapper(product.Name, product.IMSProducts, selectedProducts, selectedIMSProducts, allSelectedIMS));
        }
        return imsProductMap;
    }

    public static void UpdateIMSProductMap(Id quoteId, map<string, bg_Wrappers.IMSWrapper> IMSProductMap, bg_Wrappers.QuoteProductWrapper product, set<string> selectedProducts, set<string> selectedIMSProducts, set<string> allSelectedIMS) {
        /* Update IMS Wrapper Product Map */    
        map<string, bg_Wrappers.QuoteProductWrapper> productMap = new map<string, bg_Wrappers.QuoteProductWrapper>();
        productMap.put(product.Name, product);
        UpdateIMSProductMap(quoteId, IMSProductMap, productMap, selectedProducts, selectedIMSProducts, allSelectedIMS);
    }

    public static void UpdateIMSProductMap(Id quoteId, map<string, bg_Wrappers.IMSWrapper> IMSProductMap, map<string, bg_Wrappers.QuoteProductWrapper> productMap, set<string> selectedProducts, set<string> selectedIMSProducts, set<string> allSelectedIMS) {
        /*
            Update IMS Wrapper Product Map
        */
        system.debug('UpdateIMSProductMap - productMap: ' + productMap);
        for(bg_Wrappers.QuoteProductWrapper qpw : productMap.values()) {
            if(qpw.Selected && !imsProductMap.containsKey(qpw.Name)) {
                imsProductMap.put(qpw.Name, CreateIMSWrapper(qpw.Name, qpw.IMSProducts, selectedProducts, selectedIMSProducts, allSelectedIMS));
                PopulateIMSFields(qpw, quoteId);
                if(qpw.IMS && !selectedIMSProducts.contains(qpw.Name)) { selectedIMSProducts.add(qpw.Name); }
            } else if (!qpw.Selected && imsProductMap.containsKey(qpw.Name)) {
                imsProductMap.remove(qpw.Name);
                if(!qpw.IMS && selectedIMSProducts.contains(qpw.Name)) { selectedIMSProducts.remove(qpw.Name); }
            }
        }
    }
    
    public static list<bg_Wrappers.RelatedProductWrapper> CreateRelatedProductWrappers(list<Product_Relationship__c> relatedProducts) {
        /*
            Create Relateted Product Wrappers
        */
        list<bg_Wrappers.RelatedProductWrapper> relatedProductWrappers = new list<bg_Wrappers.RelatedProductWrapper>();
        for(Product_Relationship__c relatedProduct : relatedProducts) {
            relatedProductWrappers.add(CreateRelatedProductWrapper(relatedProduct));
        }
        return relatedProductWrappers;
    }

    public static bg_Wrappers.RelatedProductWrapper CreateRelatedProductWrapper(Product_Relationship__c relatedProduct) {
        /*
            Create Relateted Product Wrapper
        */
        bg_Wrappers.RelatedProductWrapper relatedProductWrapper = new bg_Wrappers.RelatedProductWrapper();
        relatedProductWrapper.Product = relatedProduct.Related_Product__r;
        relatedProductWrapper.RelationshipType = relatedProduct.Type__c;
        relatedProductWrapper.name = relatedProduct.Related_Product__r.Name;
        return relatedProductWrapper;
    }

    public static list<bg_Wrappers.RelatedProductWrapper> CreateRelatedProductWrappers(list<Product_Classification_Relationship__c> relatedProducts) {
        /*
            Create Relateted Product Wrappers
        */
        list<bg_Wrappers.RelatedProductWrapper> relatedProductWrappers = new list<bg_Wrappers.RelatedProductWrapper>();
        for(Product_Classification_Relationship__c relatedProduct : relatedProducts) {
            relatedProductWrappers.add(CreateRelatedProductWrapper(relatedProduct));
        }
        return relatedProductWrappers;
    }

    public static bg_Wrappers.RelatedProductWrapper CreateRelatedProductWrapper(Product_Classification_Relationship__c relatedProduct) {
        /*
            Create Relateted Product Wrapper
        */
        bg_Wrappers.RelatedProductWrapper relatedProductWrapper = new bg_Wrappers.RelatedProductWrapper();
        relatedProductWrapper.Product = relatedProduct.SuggestedProductClassification__r.SF_Product__r;
        //relatedProductWrapper.RelationShip = relatedProduct;
        //relatedProductWrapper.Classification = relatedProduct.SuggestedProductClassificationName__c;
        //relatedProductWrapper.RelationshipType = relatedProduct.Type__c;
        return relatedProductWrapper;
    }

    public static boolean IsSelectedIMSProducts(string product, set<string> SelectedProducts, set<string> SelectedIMSProducts, set<string> IMSProducts) {
        /*
            Check Is Selected IMS Products
        */  
        // No Ims Products selected?
        if(SelectedIMSProducts.size() == 0) {
            // check for any IMS products
            for(string imsProduct : IMSProducts) {
                if(SelectedProducts.contains(imsProduct)) {
                    system.debug('IsSelectedIMSProducts 1: ' + SelectedProducts);
                    return true;
                }
            }
        } else {
            // there is an IMS product already selected
            if(SelectedIMSProducts.size() == 1 && new list<string>(SelectedIMSProducts)[0] == product) {
                // this is the only selected IMS product
                system.debug('IsSelectedIMSProducts 2: ' + SelectedIMSProducts);                
                return true;
            } else {
                // there are some IMS selected
                for(string selectedIMS : SelectedIMSProducts) {
                    if(selectedIMS != product && !IMSProducts.contains(selectedIMS)) {
                        return false;
                    }                       
                }
                for(string imsProduct : IMSProducts) {
                    if(SelectedIMSProducts.contains(imsProduct)) {
                        system.debug('IsSelectedIMSProducts 3: ' + SelectedIMSProducts);                
                        return true;
                    }
                }
            }
        }
        system.debug('IsSelectedIMSProducts 4: ' + false);
        return false;
    }

    public static map<Id, bg_Wrappers.ProductWrapper> GetSelectedProductWrappersMap(list<bg_Wrappers.ProductWrapper> productWrappers) {
        /*
            Return a Selected Product Wrappers Map
        */
        map<Id, bg_Wrappers.ProductWrapper> selectedProductsMap = new map<Id, bg_Wrappers.ProductWrapper>();
        for(bg_Wrappers.ProductWrapper pw : productWrappers) {
            if(pw.Selected) {
                selectedProductsMap.put(pw.Id, pw);
            }
        }
        return selectedProductsMap;
    }

    /************************************************************************/
    /* Populate Methods                                                     */  
    /************************************************************************/  
    public static void PopulateProductSiteWrappers(Quote__c quote, list<bg_Wrappers.SiteWrapper> siteWrappers, bg_Wrappers.QuoteProductWrapper quoteProductWrapper) {
        /*
            Populate Product Site Wrappers
        */      
        for(bg_Wrappers.SiteWrapper site : siteWrappers) {
            quoteProductWrapper.SitesMap.put(site.Index, CreateProductSiteWrapper(quote, quoteProductWrapper, site));
        }
    }

    public static map<Id, bg_Wrappers.SiteWrapper> GetSiteMap(list<bg_Wrappers.SiteWrapper> sites) {
        /*
            Get Site Map
        */
        map<Id, bg_Wrappers.SiteWrapper> siteMap = new map<Id, bg_Wrappers.SiteWrapper>();
        for(bg_Wrappers.SiteWrapper site : sites) {
            siteMap.put(site.Id, site);
        }
        return siteMap;
    }

    public static void PopulateSamplingFields(bg_Wrappers.QuoteProductWrapper qpw, Id quoteId) {
        /*
            Populate Sampling Fields
        */
        Product__c questionProd = bg_ProductUtils.GetQuestionProductByName(qpw.Name);
        PopulateSampleQuestionURL(qpw, quoteId, questionProd);
        PopulateSamplingVerified(qpw, quoteId);
    }
    
    private static void PopulateSampleQuestionURL(bg_Wrappers.QuoteProductWrapper qpw, Id quoteId, Product__c questionProd) {
        /*
            Populate Quote Product Question URL
        */          
        if(qpw.SamplingAvailable && bg_StringUtils.IsBlank(qpw.SampleQuestionURL)) {
            if(questionProd != null) {  
                if(qpw.AllowMultipleInstances) {
                    Quote_Product__c qp = bg_QuoteUtils.GetQuestionProduct(quoteId, true, questionProd.Id, qpw.Instance);
                    qpw.SampleQuestionURL = bg_BluePrintUtils2.BuildConfigureURL(quoteId, qp.Id);                                           
                } else {                
                    qpw.SampleQuestionURL = bg_BluePrintUtils2.BuildConfigureURL(quoteId, questionProd.Id);
                }
            } else {
                qpw.SamplingAvailable = false;
                system.debug('PopulateSampleQuestionURL - qpw.SamplingAvailable: ' + qpw.SamplingAvailable);
            } 
        }
    }

    public static void PopulateProductConfigureUrl(bg_Wrappers.QuoteProductWrapper qpw, Id quoteId) {
        /*
            Populate Configure Url
        */
        //qpw.ConfigureUrl = bg_BluePrintUtils.BuildConfigureQuoteProductURL(quoteId, qpw.Id);
        if(qpw.AllowMultipleInstances) {
            if(qpw.project.ProductId__r.Main_Product_Name__c == 'Product Certification Project Builder')
                qpw.ConfigureUrl = bg_BluePrintUtils2.BuildConfigureURL(false, quoteId, qpw.qpId, null, null, true);
            else
                qpw.ConfigureUrl = bg_BluePrintUtils2.BuildConfigureURL(quoteId, qpw.qpId);
        } else {
        	if(qpw.project.ProductId__r.Main_Product_Name__c == 'Product Certification Project Builder')
                qpw.ConfigureUrl = bg_BluePrintUtils2.BuildConfigureURL(false, quoteId, qpw.qpId, null, null, true);
            else
            	qpw.ConfigureUrl = bg_BluePrintUtils2.BuildConfigureURL(quoteId, qpw.Id);
        }
    }
    
    public static void PopulateIMSFields(bg_Wrappers.QuoteProductWrapper qpw, Id quoteId) {
        /*
            Populate IMS Fields
        */
        Product__c imsProd = bg_ProductUtils.GetQuestionProductByName(bg_ProductUtils.QUESTION_PRODUCT_IMS);
        PopulateIMSQuestionURL(qpw, quoteId, imsProd);
    }
    
    private static void PopulateIMSQuestionURL(bg_Wrappers.QuoteProductWrapper qpw, Id quoteId, Product__c questionProd) {
        /*
            Populate Quote Product Question URL
        */      
        if(bg_StringUtils.IsBlank(qpw.IMSQuestionURL)) {
            if(questionProd != null) {      
                //qpw.IMSQuestionURL = bg_BluePrintUtils.BuildConfigureQuoteProductURL(quoteId, questionProd.Id);
                qpw.IMSQuestionURL = bg_BluePrintUtils2.BuildConfigureURL(quoteId, questionProd.Id);
            } else {
                //qpw.IMSAvailable = false;
            } 
        }
    }

    public static void PopulateSamplingVerified(bg_Wrappers.QuoteProductWrapper qpw, Id quoteId) {
        /*
            Populate Quote Product Sampling Verified
        */
        if(qpw.SamplingAvailable) {
            Quote_Part__c qQuotePart = bg_QuoteUtils.GetQuoteQuestionPart(quoteId, qpw.Name, qpw.Instance);
            if(qQuotePart != null) {
                qpw.VerifiedForSampling = (qQuotePart.Price__c != null && qQuotePart.Price__c == 1);    
            } else {
                qpw.VerifiedForSampling = false;
            }
        } else {
            qpw.VerifiedForSampling = false;    
        }   
    }

    public static void PopulateQuoteProductWrappers(Quote__c quote, map<string, bg_Wrappers.QuoteProductWrapper> quoteProductMap, list<bg_Wrappers.SiteWrapper> sites, list<Quote_Product__c> quoteProducts) {
        /* Populate Quote Product Wrappers */       
        PopulateQuoteProductWrappers(quote, quoteProductMap, sites, quoteProducts, false);
    }

    public static void PopulateQuoteProductWrappers(Quote__c quote, map<string, bg_Wrappers.QuoteProductWrapper> quoteProductMap, list<bg_Wrappers.SiteWrapper> sites, list<Quote_Product__c> quoteProducts, boolean configureUrl) {
        /* Populate Quote Product Wrappers */       
        PopulateQuoteProductWrappers(quote, quoteProductMap, sites, quoteProducts, configureUrl, null);
    }

    private static string GetInstanceName(string productName, integer instance) {
        /* Return instance name */
        return productName + ' (' + string.valueOf(instance) + ')'; 
    }
    
    public static void  PopulateQuoteProductWrappers(Quote__c quote, map<string, bg_Wrappers.QuoteProductWrapper> quoteProductMap, list<bg_Wrappers.SiteWrapper> sites, list<Quote_Product__c> quoteProducts, boolean configureUrl, map<Id, Contact> contactMap) {
        /*
            Populate Quote Product Wrappers
        */
        Set<Id> mainProductIds = new Set<Id>();
        Map<Id, Product__c> mainProductsById = new Map<Id, Product__c>();
        Map<String, Product__c> mainProductsByName = new Map<String, Product__c>();
        for(Quote_Product__c qp : quoteProducts) {
            if(qp.Product_Name__r.Product_Type__c == bg_ProductUtils.PRODUCT_TYPE_MAIN)
            {
                mainProductIds.add(qp.Product_Name__c);
            }
        }
        // Case 31498 - Made this allow inactive for e.g. view configuration on quote with existing parts
        List<Product__c> mainProducts = bg_ProductUtils.getProducts(false, null, null, null, null, null, mainProductIds);
        for(Product__c product : mainProducts)
        {
            mainProductsById.put(product.id, product);
            mainProductsByName.put(product.name, product);
        }

        map<Id, bg_Wrappers.SiteWrapper> siteMap = GetSiteMap(sites);
        for(Quote_Product__c qp : quoteProducts) {

            string productName = bg_ProductUtils.GetMainProductName(qp.Product_Name__r);
            string instanceName = productName;

            if(qp.Product_Name__r.AllowMultipleInstances__c && qp.Instance__c != null) {
                instanceName = GetInstanceName(productName, integer.valueOf(qp.Instance__c));
            }

            bg_Wrappers.QuoteProductWrapper qpw;
            if(!quoteProductMap.containsKey(instanceName)) {
            	Product__c product = null;
                if(qp.Product_Name__r.RecordType.Name != 'Product Certification' && mainProductsByName.containsKey(productName))
                {
                    product = mainProductsByName.get(productName);

                } else if (qp.Product_Name__r.RecordType.Name == 'Product Certification') {
                	product = mainProductsById.get(qp.Product_Name__c);
                }
                else
                {
                    throw new WrapperHelperException('Could not find main product name in product map: '+ productName);
                }
                
                //bg_ProductUtils.GetProductByName(productName);
                qpw = CreateQuoteProductWrapper(product, null, qp.Product_Classification__r, qp.Product2__r);
                qpw.qpId = qp.Id;
                qpw.Instance = bg_Utilities.getInteger(qp.Instance__c, 1);
                quoteProductMap.put(qpw.InstanceName, qpw);
                qpw.projectID = qp.project__c;
                qpw.project = qp.project__r;
                qpw.GridView = product.GridView__c;
            }
            qpw = quoteProductMap.get(instanceName);

            if(!qpw.Selected) {
                qpw.Selected = true;
                qpw.IMS = qp.Included_in_IMS__c;
                    
                qpw.SamplingAvailable = qp.Sampling_Available__c;
                qpw.UseSampling = qp.Sampling_Applied__c;
                qpw.VerifiedForSampling = qp.Sampling_Verified__c;
                qpw.Instance = bg_Utilities.getInteger(qp.Instance__c);
                qpw.StandardId = qp.Product2__c;
                qpw.projectID = qp.project__c;
				qpw.project = qp.project__r;

                if(qpw.ProductArea != null) {
                    qpw.ProductArea.IsCollapsed = false;
                    qpw.ProductArea.SelectedProductCount++;                 
                }
            }
                
            // Populate Product Configure URL?
            if(configureUrl && bg_StringUtils.IsBlank(qpw.ConfigureUrl)) {
                PopulateProductConfigureUrl(qpw, quote.Id);
            }

            // set the controlling location id
            if(mainProductsById.containsKey(qp.Product_Name__c))
            {
                Product__c mainProduct = mainProductsById.get(qp.Product_Name__c);
                if(mainProduct.GridView__c)
                {
                    qpw.controllingLocationId = qp.Site__c;
                }
            }
            
                
            // get site
            if(siteMap.containsKey(qp.Site__c)) {                   
                bg_Wrappers.SiteWrapper site = siteMap.get(qp.Site__c);
                qpw.SitesMap.put(site.Index, CreateProductSiteWrapper(quote, qpw, site, qp, contactMap));
            } else {
                //site not found - else delete product??
            }
            
            
            qpw.QuoteProduct = qp;
        }   
    }

    public static void AddProductSiteToSamplingMap(map<string, map<string, map<string, bg_Wrappers.RegPathSampleWrapper>>> samplingMap, bg_Wrappers.QuoteProductWrapper qpw, bg_Wrappers.SiteWrapper site, bg_Wrappers.ProductSiteWrapper psw) {
        
        if (qpw.GridView)
        {
            
            /* Add Product Site To Sampling Map */
            if(!bg_StringUtils.IsBlank(psw.RegistrationPath)) {
                
                string typeOrRisk = GetTypeOrRisk(qpw, psw, site, psw.RiskLevel);
                
                // Add Risk Level / type
                if(!samplingMap.containsKey(typeOrRisk)) {
                    samplingMap.put(typeOrRisk, new map<string, map<string, bg_Wrappers.RegPathSampleWrapper>>());
                }
                
                /// ADD Product?
                if(!samplingMap.get(typeOrRisk).containsKey(qpw.InstanceName)) {
                    samplingMap.get(typeOrRisk).put(qpw.InstanceName, new map<string, bg_Wrappers.RegPathSampleWrapper>());
                }
                
                /// ADD NEW REG PATH
                if(!samplingMap.get(typeOrRisk).get(qpw.InstanceName).containsKey(psw.RegistrationPath)) {
                    samplingMap.get(typeOrRisk).get(qpw.InstanceName).put(psw.RegistrationPath, new bg_Wrappers.RegPathSampleWrapper());
                }
                // Add Product Site Wrapper
                samplingMap.get(typeOrRisk).get(qpw.InstanceName).get(psw.RegistrationPath).pswMap.put(psw.SiteIndex, psw); // add to type map
            }
            // Set Old registration Path
            psw.OldRegistrationPath = psw.RegistrationPath;
            psw.OldRiskLevel = psw.RiskLevel;                       
        }
        
    }

    public static void RemoveProductFromSamplingMap(map<string, map<string, map<string, bg_Wrappers.RegPathSampleWrapper>>> samplingMap, bg_Wrappers.QuoteProductWrapper qpw) {
        /*
            Remove Product from Sampling Map
        */ 
        for(bg_Wrappers.ProductSiteWrapper psw : qpw.sitesMap.values()) {
            RemoveProductSiteFromSamplingMap(samplingMap, qpw, psw.site, psw, psw.RegistrationPath, psw.RiskLevel);
        }
    }

    private static string GetTypeOrRisk(bg_Wrappers.QuoteProductWrapper qpw, bg_Wrappers.ProductSiteWrapper psw, bg_Wrappers.SiteWrapper site, string riskLevel) {
        /*
            Get Type or Risk
        */
        string typeOrRisk;
        if(psw.IsControllingLocation) {
            typeOrRisk = 'Controlling Location';//System.Label.HQ;
        }
        else
        {
            if(qpw.RiskType == bg_ProductUtils.PRODUCT_TYPE_RISK) {
                typeOrRisk = System.Label.RiskLevel + ' - ' + riskLevel;
            } else {
                typeOrRisk = site.Type; 
            }
        }
        return typeOrRisk;
    }

    public static void RemoveProductSiteFromSamplingMap(map<string, map<string, map<string, bg_Wrappers.RegPathSampleWrapper>>> samplingMap, bg_Wrappers.QuoteProductWrapper qpw, bg_Wrappers.SiteWrapper site, bg_Wrappers.ProductSiteWrapper psw) {
        /*
            Remove Product Site To Sampling Map
        */
        // REMOVE OLD REG PATH
        RemoveProductSiteFromSamplingMap(samplingMap, qpw, site, psw, psw.OldRegistrationPath, psw.OldRiskLevel);
    }

    public static void RemoveProductSiteFromSamplingMap(map<string, map<string, map<string, bg_Wrappers.RegPathSampleWrapper>>> samplingMap, bg_Wrappers.QuoteProductWrapper qpw, bg_Wrappers.SiteWrapper site, bg_Wrappers.ProductSiteWrapper psw, string regPath, string riskLevel) {

        if (qpw.GridView)
        {
            
            /* Remove Product Site To Sampling Map */
            system.debug('### RemoveProductSiteFromSamplingMap: site: '+site);
            system.debug('### RemoveProductSiteFromSamplingMap: riskLevel: '+riskLevel);
            system.debug('### RemoveProductSiteFromSamplingMap: regPath: '+regPath);
            system.debug('### RemoveProductSiteFromSamplingMap: psw: '+psw);
            // REMOVE OLD REG PATH
            if(!bg_StringUtils.IsBlank(regPath)) {
                string typeOrRisk = GetTypeOrRisk(qpw, psw, site, riskLevel);
                system.debug('### RemoveProductSiteFromSamplingMap: typeOrRisk: '+typeOrRisk);
                system.debug('### RemoveProductSiteFromSamplingMap: samplingMap.containsKey(typeOrRisk): '+samplingMap.containsKey(typeOrRisk));
                system.debug('### RemoveProductSiteFromSamplingMap: samplingMap.get(typeOrRisk).containsKey(qpw.InstanceName): '+samplingMap.get(typeOrRisk).containsKey(qpw.InstanceName));
                system.debug('### RemoveProductSiteFromSamplingMap: samplingMap.get(typeOrRisk).get(qpw.InstanceName).containsKey(regPath): '+samplingMap.get(typeOrRisk).get(qpw.InstanceName).containsKey(regPath));
                
                if(samplingMap.containsKey(typeOrRisk) &&
                   samplingMap.get(typeOrRisk).containsKey(qpw.InstanceName) &&
                   samplingMap.get(typeOrRisk).get(qpw.InstanceName).containsKey(regPath)) {
                       
                       system.debug('### RemoveProductSiteFromSamplingMap: removing index');
                       system.debug('### RemoveProductSiteFromSamplingMap: psw.SiteIndex: '+psw.SiteIndex);
                       system.debug('### RemoveProductSiteFromSamplingMap: samplingMap.get(typeOrRisk).get(qpw.InstanceName).get(regPath).pswMap: '+samplingMap.get(typeOrRisk).get(qpw.InstanceName).get(regPath).pswMap.get(psw.SiteIndex));         
                       samplingMap.get(typeOrRisk).get(qpw.InstanceName).get(regPath).pswMap.remove(psw.SiteIndex); // remove from to type map
                       system.debug('### RemoveProductSiteFromSamplingMap: Removed Site Index');
                       if(samplingMap.get(typeOrRisk).get(qpw.InstanceName).get(regPath).pswMap.size() == 0) {
                           system.debug('### RemoveProductSiteFromSamplingMap: Nothing here for controlling location');
                           samplingMap.get(typeOrRisk).get(qpw.InstanceName).remove(regPath);
                           system.debug('### RemoveProductSiteFromSamplingMap: Removed Reg Path from '+qpw.InstanceName);
                           if(samplingMap.get(typeOrRisk).get(qpw.InstanceName).size() == 0) {
                               samplingMap.get(typeOrRisk).remove(qpw.InstanceName);
                               if(samplingMap.get(typeOrRisk).size() == 0) {
                                   samplingMap.remove(typeOrRisk); 
                               }
                           }
                       }
                   }
            }
            system.debug('### samplingMap: '+samplingMap.Keyset());            
        }
        
    }


    public static boolean CheckForSamplingAvailable(Id quoId, integer samplingThreshold, map<string, map<string, map<string, bg_Wrappers.RegPathSampleWrapper>>> samplingMap, bg_Wrappers.QuoteProductWrapper qpw, boolean checkProductQuestion) {
        boolean SampleWarnings = false;
        
        if (qpw.GridView)
        {
            
            /* Check For Sampling Available */
            if(checkProductQuestion) {
                // Check Product Question & Result
                bg_WrapperHelper.PopulateSamplingVerified(qpw, quoId);
            }
            
            // CheckForSamplingAvailable
            boolean originalValue = qpw.SamplingAvailable;
            qpw.SamplingAvailable = false;
            
            system.debug('1. CheckForSamplingAvailable: ');
            
            for(string siteType : samplingMap.keySet()) {
                system.debug('2. CheckForSamplingAvailable - siteType: ' + siteType);
                
                if(samplingMap.get(siteType).containsKey(qpw.InstanceName)) {
                    system.debug('3. CheckForSamplingAvailable - qpw.InstanceName: ' + qpw.InstanceName);
                    
                    map<string, bg_Wrappers.RegPathSampleWrapper> regPathMap = samplingMap.get(siteType).get(qpw.InstanceName);
                    for(string regPath : regPathMap.keySet()) {
                        
                        system.debug('4. CheckForSamplingAvailable - regPath: ' + regPath);
                        
                        bg_Wrappers.RegPathSampleWrapper regPathSW = regPathMap.get(regPath);
                        map<integer, bg_Wrappers.ProductSiteWrapper> productSiteMap = regPathSW.pswMap;
                        
                        boolean samplingAvailable = (productSiteMap.values().size() > samplingThreshold);
                        
                        regPathSW.MinSampleSize = CalculateMinSampleSize(productSiteMap.values().size(), qpw);
                        
                        system.debug('5. CheckForSamplingAvailable - productSiteMap.values().size() - regPath: ' + productSiteMap.values().size());
                        system.debug('6. CheckForSamplingAvailable - samplingAvailable: ' + samplingAvailable);
                        system.debug('6.1. CheckForSamplingAvailable - regPathSW.MinSampleSize: ' + regPathSW.MinSampleSize);
                        
                        integer selectedCount = 0;                  
                        for(bg_Wrappers.ProductSiteWrapper psw : productSiteMap.values()) {
                            if(psw.Selected) { selectedCount++; }
                            psw.Selectable = samplingAvailable;
                            system.debug('7. CheckForSamplingAvailable - psw.Selectable: ' + psw.Selectable);
                        }
                        regPathSW.SelectionValid = (selectedCount >= regPathSW.MinSampleSize);                  
                        
                        if(samplingAvailable && !qpw.SamplingAvailable) {
                            qpw.SamplingAvailable = true;
                        }
                        
                        // Set warnings flag
                        if(!SampleWarnings && qpw.UseSampling && qpw.ValidForSampling && !regPathSW.SelectionValid) {
                            SampleWarnings = true;
                        }                   
                    }
                }
            }
            
            // Update sampling question
            if(qpw.SamplingAvailable && (!originalValue || bg_StringUtils.IsBlank(qpw.SampleQuestionURL))) {
                PopulateSamplingFields(qpw, quoId);
                //} else if(originalValue && !prod.SamplingAvailable) {
                //  bg_QuoteUtils.RemoveSamplingQuestionProduct(prod.InstanceName, quoId);
            }
            
        }
        
        return SampleWarnings;
    }
    
    public static integer CalculateMinSampleSize(integer selectedSize, bg_Wrappers.QuoteProductWrapper qpw) {
        /*
            Calculate the sampling size
        */      

        // Check to see if sampling can be used
        if(selectedSize > qpw.SamplingThreshold) {

            // 1 IN 5 - SAMPLING RULE
            if(qpw.SamplingRule == bg_Wrappers.SAMPLING_RULE_1INN) {
                return CalculateMinSampleSize_1inN(selectedSize, qpw.SamplingThreshold, qpw.Sampling1inN);

            // DEFAULT - SQUARE ROOT - SAMPLING RULE
            } else {
                return CalculateMinSampleSize_Sqrt(selectedSize);
            }

        } else {
            return 0; // Sampling not available
        }
        
    }

    public static integer CalculateMinSampleSize_1inN(integer selectedSize, integer sampleThreshold, integer Sampling1inN) {
        /* Calculate Sample Size - 1 in N */
        return sampleThreshold + integer.valueOf((decimal.valueOf(selectedSize-sampleThreshold) / Sampling1inN).round(System.RoundingMode.CEILING));
    }

    public static integer CalculateMinSampleSize_Sqrt(integer selectedSize) {
        /* Calculate Sample Size - Square Root */
        return integer.valueOf(Math.sqrt(decimal.valueOf(selectedSize)).round(System.RoundingMode.UP));
    }

    public static void ApplySampling(integer samplingThreshold, map<string, map<string, map<string, bg_Wrappers.RegPathSampleWrapper>>> samplingMap, bg_Wrappers.QuoteProductWrapper qpw) {
        /*
            Apply Sampling
        */
        boolean useSampling = qpw.ValidForSampling;
        for(string siteType : samplingMap.keySet()) {
            if(samplingMap.get(siteType).containsKey(qpw.InstanceName)) {

                map<string, bg_Wrappers.RegPathSampleWrapper> regPathMap = samplingMap.get(siteType).get(qpw.InstanceName);
                for(string regPath : regPathMap.keySet()) {
                    
                    bg_Wrappers.RegPathSampleWrapper regPathSW = regPathMap.get(regPath);
                    map<integer, bg_Wrappers.ProductSiteWrapper> productSiteMap = regPathSW.pswMap;

                    system.debug('useSampling: ' + useSampling);
                    system.debug('productSiteMap.values().size(): ' + productSiteMap.values().size());
                    system.debug('samplingThreshold: ' + samplingThreshold);
                    
                    if(useSampling && productSiteMap.values().size() > samplingThreshold) {
                        
                        list<integer> siteKeys = GetSiteKeys(productSiteMap.keyset(), false);
                        integer counter = 0;
                        
                        system.debug('siteKeys: ' + siteKeys);
                        for(integer key : siteKeys) {
                            bg_Wrappers.ProductSiteWrapper psw = productSiteMap.get(key);
                            counter++;
                            system.debug('counter: ' + counter);
                            system.debug('regPathSW.MinSampleSize: ' + regPathSW.MinSampleSize);
                            psw.Selected = (counter <=  regPathSW.MinSampleSize); 
                        }                       

                    } else {
                        for(bg_Wrappers.ProductSiteWrapper psw : productSiteMap.values()) {
                            psw.Selected = true;
                        }
                    }
                }
            }               
        }
    }
    
    public static list<integer> GetSiteKeys(set<integer> siteIndexes, boolean sortSiteIndex) {
        /*
            return site keys in sorted or random order
        */
        list<integer> sortedSiteIndexes = new list<integer>();
        
        system.debug('GetSiteKeys: ' + siteIndexes);
        
        sortedSiteIndexes.addAll(siteIndexes);

        // Sort indexes
        if(sortSiteIndex) {
            //sortedSiteIndexes.addAll(siteIndexes);
            sortedSiteIndexes.Sort();

        // randomize order
        } else {
            
            integer currentIndex = sortedSiteIndexes.size();
            integer temporaryValue;
            integer randomIndex;
            // While there remain elements to shuffle...
            while (0 != currentIndex) 
            {
                // Pick a remaining element...
                randomIndex = integer.valueOf(Math.floor(Math.random() * currentIndex));
                currentIndex -= 1;
                // And swap it with the current element.
                temporaryValue = sortedSiteIndexes[currentIndex];
                sortedSiteIndexes[currentIndex] = sortedSiteIndexes[randomIndex];
                sortedSiteIndexes[randomIndex] = temporaryValue;
            }
        }   

        return sortedSiteIndexes;
    }

    public static list<SelectOption> GetRegistrationPathItems(boolean IsDefaultSelected, string RegistrationPaths) {
        return GetRegistrationPathItems(IsDefaultSelected, RegistrationPaths, true);
    }

    public static list<SelectOption> GetRegistrationPathItems(boolean IsDefaultSelected, string RegistrationPaths, boolean isHQ) {      
        return GetRegistrationPathItems(IsDefaultSelected, RegistrationPaths, isHQ, '', false);
    }
        
    public static list<SelectOption> GetRegistrationPathItems(boolean IsDefaultSelected, string RegistrationPaths, 
        boolean isControllingLocation, string controllingLocationRegPath, boolean transitionExists) {       
        /*
            Method to return registation path items
        */
        List<SelectOption> regPathSelectOptions = new List<SelectOption>();
        if(!isControllingLocation && transitionExists && bg_Globals.HQ_ONLY_REG_PATHS.contains(controllingLocationRegPath))
        {
            regPathSelectOptions.add(new SelectOption('', '-- SELECT --'));    
            regPathSelectOptions.add(new SelectOption(bg_Globals.REGISTRAION_PATH_TRANSITION, bg_Globals.REGISTRAION_PATH_TRANSITION));           
        }
        else
        {
            List<String> regPaths = RegistrationPaths.split(';');
            regPathSelectOptions = bg_ControllerUtils.CreateSelectOptions(regPaths, false, true); // pass in IsDefaultSelected

            if(!isControllingLocation)
            {
                for(Integer i = 0; i<regPathSelectOptions.Size(); i++)
                {
                    if(bg_Globals.HQ_ONLY_REG_PATHS.contains(regPathSelectOptions[i].getValue()))
                    {
                        regPathSelectOptions.remove(i);
                    }
                }
            }   
        }
        return regPathSelectOptions;
    }

    public static list<SelectOption> GetControllingLocations(List<bg_Wrappers.ProductSiteWrapper> productSiteWrappers) {        
        /*
            Method to return controlling locations
        */
        
        list<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', '--' + Label.None + '--'));
        if (productSiteWrappers != null)
        {
            for(bg_Wrappers.ProductSiteWrapper prodSiteWrapper : productSiteWrappers)
            {
                bg_Wrappers.SiteWrapper site = prodSiteWrapper.site;
                options.add(new SelectOption(site.Id, site.Name));
            }
        }
        return options;
    }
    
    public static string GetContactsRoleString(map<string, Id> ContactRoleMap, map<Id, Contact> ContactMap) {
        /*
            Method to return Contact Roles string (formated for VF Page / HTML title string)
        */
        string contacts = '';
        if(contactMap != null) {
            for(string role : ContactRoleMap.keySet()) {
                if(!bg_StringUtils.IsBlank(ContactRoleMap.get(role)) && contactMap.containsKey(ContactRoleMap.get(role))) {
                    contacts += role + ' - ' + contactMap.get(ContactRoleMap.get(role)).Name + '\r\n';
                } 
            }
        }
        return contacts;
    } 

    /************************************************************************/
    /* TEST METHODS - bg_WrapperHelperTest                                  */  
    /************************************************************************/  
}