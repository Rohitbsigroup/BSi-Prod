/********************************************************************
 * QuoteProductApprovalExt
 *
 * Visualforce Controller used to facilitate the site & product approval
 * 
 * Author: Richard Jimenez
 * Created: 10-11-2013
 * Changes: 
 ********************************************************************/
public with sharing class QuoteProductApprovalExt {

    private map<string, bg_Wrappers.QuoteProductWrapper> quoteProductMap;

    public Quote_Product_Approval__c qpaExt {get; private set;}
    public Quote__c quote {get; private set;} 
    public list<bg_Wrappers.QuoteProductWrapper> Products {get; private set;}
    public list<bg_Wrappers.SiteWrapper> Sites {get; private set;}
    public string selectedProductId {get; set;}
    private map<Id, Contact> contactMap;
        
    public QuoteProductApprovalExt(ApexPages.StandardController controller) {
        // store record
        qpaExt = (Quote_Product_Approval__c)controller.getRecord(); // store record
        // Load Quote
        LoadQuote();
    }

    private void LoadQuote() {
        /*
            Load Quote and Products
        */
        Id quoId = qpaExt.Quote__c;
        Id oppId = qpaExt.Quote__r.Opportunity_Name__c;

        try {
            quote = bg_QuoteUtils.GetQuoteById(quoId);
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Quote Id does not exist: ' + quoId));
        }

        if(quote != null) {
            list<Quote_Product__c> quoteProducts = bg_QuoteUtils.GetQuoteProducts(quoId, true, null, qpaExt.Product__r.Name);System.debug(quoteProducts + ' QuoteProducts1');
            list<OpportunitySite__c> siteList = bg_SiteUtils.GetOpportunitySites(oppId, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, bg_SiteUtils.RECORD_TYPE_NAME_DEFAULT);
            list<Product__c> productList = bg_QuoteUtils.GetMainProducts(quoteProducts);
            
            //Unique product logic ends here- DO NOT REMOVE
            //Logic added to remove duplicate products. As the main product is searched based on the name it gives two products
            Map<String, Product__c> uniqueProductList = new Map<String, Product__c>();
            for(Product__c prod: productList) {
                if(uniqueProductList.get(prod.Name) == null) {
                    uniqueProductList.put(prod.Name, prod);
                }
            }
            productList = uniqueProductList.values();
            //Unique product logic ends here
            
            sites = bg_WrapperHelper.CreateSiteWrappers(siteList);
            products = bg_WrapperHelper.CreateQuoteProductWrappers(productList);
            
            quoteProductMap = bg_WrapperHelper.CreateQuoteProductWrappersMap(products);
            contactMap = bg_ContactUtils.GetContactsMap(bg_ContactUtils.GetQuoteProductContactIds(quoId));
            bg_WrapperHelper.PopulateQuoteProductWrappers(quote, quoteProductMap, sites, quoteProducts, true, contactMap);  
            
            // populate missing sites
            bg_WrapperHelper.CreateProductSiteWrappers(quote, quoteProductMap.values(), sites, false);     
            
            /*Additional code to check if the configurator URL is sent as readonly*/
            for(bg_Wrappers.QuoteProductWrapper qpw: products) {
                if(qpw.ConfigureUrl != null && qpw.ConfigureUrl.indexOf('&mode=') == -1) {
                   qpw.ConfigureUrl = qpw.ConfigureUrl + '&mode=0';
                }
            }    
        }
    }

    /**********************************************************************************/
    /* Actions                                                                        */
    /**********************************************************************************/
    public void ConfigureProduct() {
        /* Configure Product */
    //  Save(); // page is going to redirect!
    }

    /**********************************************************************************/
    /* Configurator URLs
    /**********************************************************************************/
    public string GetConfigureAllUrl() {
        /* Return Configure All Url */
        //return bg_BluePrintUtils.BuildConfigureQuoteProductURL(quoId);
        return null;
    }    
}