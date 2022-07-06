/********************************************************************
 * QuotePartGridController
 *
 * Visualforce Controller used to facilitate the quote part prices
 * 
 * Author: Richard Jimenez
 * Created: 01-12-2013
 * Changes: 26-01-2016 ASD BrightGen : Ref; 24056 - Setting showDecimals to be True and removing from VF page
 *                     adding roundDiscounts
 *      01-09-2017 IB  Brightgen : PS UAT make wrapper data transient to reduce view state
 *      04-09-2017 RC  Brightgen : Added error message for 0 pricebook entries.
 *      12-09-2017 IB  Brightgen : RemoveFilers() now recalculates totals to account of any discounts applied etc
 *                         CalculateGrandTotals() now takes quantity into account when calculating monetary value of total discount
 *      15-09-2017 CPE BrightGen : New methods to correctly handle individual line changes and bulk operations
 *          03-11-2017 ADS BrightGen : Case 33569 - True Discount Calculation
 ********************************************************************/
public with sharing class QuotePartGridController implements bg_FacetedSearchDelegate{

  // Class variables
  public Quote__c quote {get; private set;}
  public list<Quote_Part__c> quoteParts {get; set;}
  public map<string, decimal> productDiscountMap1 {get; private set;}
  public map<string, decimal> productDiscountMap2 {get; private set;}
  public boolean editMode {get; private set;}
  public list<ProductWrapper> ProductWrappers {get; set;}
  public map<Id, Quote_Product_Approval__c> qpaMap {get; private set;}
  public Map<Id, Product2> product2sById {get; set;}
  public boolean DisableQuickProductDiscount {get; private set;}
  public string selectedQuotePartId {get; set;}
  
  public string selectedDiscountProduct {get;set;}
  
  public decimal GrandTotalPrice {get; set;}
  public decimal GrandTotalDiscount {get; set;}
  public decimal GrandTotalDiscountAmount {get; set;}

  private boolean CanShowAllQuoteParts;
  public boolean HasHalfDays {get; private set;}
  public boolean ShowGlobalDiscountMsg {get; private set;}
  public boolean HasNoPriceBookEntryies {get; private set;}  

  private final string SHOW_ALL_PRODUCTS = 'ShowAll';
  private final string SHOW_ALL_SITES = 'ShowAll';

  public boolean showDecimals {get; set;}
  public boolean roundDiscounts {get; set;}
  public boolean showDiscountAmount {get; set;}

  // SETTINGS
  public QuoteSetting__c quoteSettings {get; private set;}
  
  @testVisible
  private Map <String, bg_FacetedSearchComponent> facetedSearchComponentMap;
  private Map<String, Set<SelectOption>> filterValueByFieldMap;
  private Map<String, map<String, List<Quote_Part__c>>> quotePartsByFilterValue;
  
  
  public bg_FacetedSearchDelegate searchController { get { return this; } }
  
  // Bundle Action 
  public List<SelectOption> referenceSettings;  
  public String selectedreferenceSetting {get; set; }
  public List<SelectOption> bundleActionOptions;  
  public String selectedBundleActionOption {get; set; }
  public Decimal bundleActionAmount {get; set; }
  // Display discount amounts as percentages or values
  public List<SelectOption> discountDisplayOptions;  
  public String selectedDiscountDisplayOption {get; set; }

  public class QuotePartException extends exception{}
  
  // Filters options
  private Set<SelectOption> productNames = new Set<SelectOption>();
  private Set<SelectOption> siteNames = new Set<SelectOption>();
  private Set<SelectOption> phases = new Set<SelectOption>();
  private Set<SelectOption> feeTypes = new Set<SelectOption>();
  private Boolean applyFilter = false;
      
  public QuotePartGridController() {
    /*
      QuotePartGridController Constructor
    */
    //try {
      //ASD 24056
      //showDiscountAmount = false;
      showDiscountAmount = true;

      HasNoPriceBookEntryies = false;
      ShowGlobalDiscountMsg = false;
      string userCountry = bg_UserUtils.GetUserById(UserInfo.getUserId()).OperationCountry__c;
      
      //REF; 24056 Initalise roundDiscounts
      roundDiscounts = false;
      
      // Populate lists
      Id quoteId = ApexPages.currentPage().getParameters().get(bg_QuoteUtils.URL_PARAM_QUO_ID);
      quoteParts = new list<Quote_Part__c>();
      
      HasHalfDays = bg_QuotePartUtils.HasHalfDayPrices(quoteId, new set<string>{bg_SiteUtils.COUNTRY_CODE_UK,
                                            bg_SiteUtils.COUNTRY_CODE_IRELAND});

      //Set showDecimals to True Ref; 24056
    showDecimals = true;      
    
    Set<String> productNameTemp = new Set<String>();
    List<Quote_Part__c> qps = [SELECT Project__r.Name, Product_Name__c, ProjectProductName__c, Quote_Product__r.Site__r.Name, Quote_Product__r.Site_Name__c, Quote_Product__r.Site__r.Country_Code__c FROM Quote_Part__c WHERE Quote_Ref__c = :quoteId AND IsQuestion__c = false];
    for(Quote_Part__c ar: qps){
        if(ar.Product_Name__c != null && productNameTemp.contains(ar.Product_Name__c) != null){
            if(ar.ProjectProductName__c == 'Product Certification Project Builder')
                productNames.add(new SelectOption(ar.Project__r.Name + ' : ' + ar.Product_Name__c, ar.Project__r.Name + ' : ' + ar.Product_Name__c));
            else
                productNames.add(new SelectOption(ar.Product_Name__c, ar.Product_Name__c));
            productNameTemp.add(ar.Product_Name__c);
        }
    }
    
    if(qps.size() > integer.valueOf(bg_CustomSettingsUtils.GetSystemSettings().QuotePartGridMaxParts__c)){
        applyFilter = true;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFo, 'As this Quote has more than 50 price lines, filters have been applied to ensure system performance is unaffected. Please apply different filters to view a smaller set of price lines'));  
    }
        
    productNameTemp = new Set<String>();
    for(Quote_Part__c ar: qps){
        if(ar.Quote_Product__r.Site_Name__c != null && productNameTemp.contains(ar.Quote_Product__r.Site_Name__c) != null){
            siteNames.add(new SelectOption(ar.Quote_Product__r.Site_Name__c, ar.Quote_Product__r.Site_Name__c));
            System.debug(ar.Quote_Product__r.Site_Name__c);
            productNameTemp.add(ar.Quote_Product__r.Site_Name__c);
        }
        
        if(ar.Quote_Product__r.Site__c != null && ar.Quote_Product__r.Site__r.Country_Code__c != userCountry)
            ShowGlobalDiscountMsg = true;
    }
    
    List<AggregateResult> phasesString = [SELECT Phase__c FROM Quote_Part__c WHERE Quote_Ref__c = :quoteId AND IsQuestion__c = false GROUP BY Phase__c];
    for(AggregateResult ar: phasesString){
        if(ar.get('Phase__c') != null)
            phases.add(new SelectOption((String)ar.get('Phase__c'), (String)ar.get('Phase__c')));
    }
    
    List<AggregateResult> feeTypesString = [SELECT FeeType__c FROM Quote_Part__c WHERE Quote_Ref__c = :quoteId AND IsQuestion__c = false GROUP BY FeeType__c];
    for(AggregateResult ar: feeTypesString){
        if(ar.get('FeeType__c') != null)
            feeTypes.add(new SelectOption((String)ar.get('FeeType__c'), (String)ar.get('FeeType__c')));
    }

      LoadQuoteData(quoteId);
      
          
      // Get Quote Settings (used by VF page)
      quoteSettings = bg_CustomSettingsUtils.GetQuoteSettings();
        
      // check quote status
      if(ApexPages.currentPage().getParameters().containsKey(bg_QuoteUtils.URL_PARAM_MODE) &&
         ApexPages.currentPage().getParameters().get(bg_QuoteUtils.URL_PARAM_MODE) == '0') {
           editMode = false;
      } else {          
        editMode = (quote.DiscountStatus__c != quoteSettings.StatusApproved__c &&
              quote.DiscountStatus__c != quoteSettings.StatusWaiting__c);
       }
       
  }
  
  private void LoadQuoteData(Id quoteId) {
    /*
      Load data
    */
    // Load Quote
    quote = bg_QuoteUtils.GetQuoteById(quoteId, true);

    // Load Product Discount Maps - for product discount and part discount comparisons
    productDiscountMap1 = bg_QuoteApprovalUtils.GetProductDiscountMap(quoteId);

    // Check number of quote parts
    integer maxGridParts = integer.valueOf(bg_CustomSettingsUtils.GetSystemSettings().QuotePartGridMaxParts__c);
    CanShowAllQuoteParts = bg_QuotePartUtils.CheckQuotePartsBelowGridMax(quoteId, maxGridParts);

    // Load quote part data
    List<String> pn = new List<String>();    
    for(SelectOption s : productNames) {
        pn.add(s.getLabel());
        break;
    }
    
    List<String> sn = new List<String>();
    for(SelectOption s : siteNames) {
        sn.add(s.getLabel());
        break;
    }
    
    if(applyFilter)
        LoadQuotePartData(quoteId, pn, sn, null, null);
    else
        LoadQuotePartData(quoteId, null, null, null, null);
  
  }
  
  private void LoadQuotePartData(Id quoteId, List<string> products, List<string> siteId, List<string> phases, List<string> feeTypes) {
    /*
      Load Quote Part Data
    */
    // Load Quote Parts
    product2sById = null;
    quoteParts = bg_QuoteUtils.GetQuoteParts(quoteId, false, products, siteId, phases, feeTypes);

    //REF 24056 Added check for a discounted quote part
    for(Quote_Part__c qp : quoteParts)
    {
      if(qp.Round_Discount_Amount__c)
      {
        roundDiscounts = true;
        break;
      }
    }

    integer maxGridParts = integer.valueOf(bg_CustomSettingsUtils.GetSystemSettings().QuotePartGridMaxParts__c);
    if(quoteParts.size() > maxGridParts) {
      ClearProducts();
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.TooManyQuotePartsWarning));
    } else {
      // Update exchange rates on the quote parts
      bg_QuotePartUtils.UpdateExchangeRates(quote, quoteParts, false);
  
      // Build Quote Part Wrappers to display
      BuildWrappers(quoteParts);
  
      // Calculate Grand Totals
      CalculateGrandTotals();
      
      // get all the filter values
      if (facetedSearchComponentMap != null)
      {
        GetFilterValues(quoteParts);
      }
    }      
  }

  private void ClearProducts() {
    /*
      Clear Products
    */
    if(productWrappers == null) {
      productWrappers = new list<ProductWrapper>();
    } else {
      productWrappers.Clear();
    }
    GrandTotalPrice = 0;
    GrandTotalDiscount = 0;
    GrandTotalDiscountAmount = 0;  
  } 




  /*
    Controls changing a pricebook for a line item.
    Called by onchange event for the QuotePart.Price_Book__c field.
    If a Pricebook is changed we may also need to update the currency field for the correct PriceBookEntry.  
    If a PBE does not exist for the current selected currency we need to update the Currency and link to the associated
    PBE for the default currency of that PriceBook
  */
  public void changeSinglePriceBook()
  {
    QuotePartWrapper toUpdate;
    Boolean updateSuccess = true; //assume success
    String errorMessage = '';
    // Validate we have a quotePartId and obtain the relevant wrapper record
    if (!bg_StringUtils.IsBlank(selectedQuotePartId))
    {
      toUpdate = getQuotePartWrapper(selectedQuotePartId);
      if (toUpdate != null)
      {
        updateSuccess = manageQuotePartWrapperPriceBookCurrencyChange(toUpdate);
        if (!updateSuccess)
        {
          errorMessage = Label.Quote_Part_Change_Error + ' - ' + Label.Unable_to_process_Price_Book_Change;
          toUpdate.QuotePart.Price_Book__c = null;
        }
      }
      else
      {
        updateSuccess = false;
        errorMessage = Label.Quote_Part_Change_Error + ' - ' + Label.Unable_to_Identify_Selected_QuotePart;
      }
      
    }
    else
    {
      updateSuccess = false;
      errorMessage = Label.Quote_Part_Change_Error + ' - ' + Label.Unable_to_Identify_Selected_QuotePart;
    }
    
    if (!updateSuccess)
    {
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, errorMessage));
    }
  }



  /*
    Controls changing a currency for a line item.
    Called by onchange event for the QuotePart.Currency field.
    If a Currency is changed we need to update the List and Unit Price fields
  */
  public void changeSingleCurrency()
  {
    QuotePartWrapper toUpdate;
    Boolean updateSuccess = true; //assume success
    String errorMessage = '';
    // Validate we have a quotePartId and obtain the relevant wrapper record
    if (!bg_StringUtils.IsBlank(selectedQuotePartId))
    {
      toUpdate = getQuotePartWrapper(selectedQuotePartId);
      if (toUpdate != null)
      {
        updateSuccess = manageQuotePartWrapperPriceBookCurrencyChange(toUpdate);
        if (!updateSuccess)
        {
          errorMessage = Label.Quote_Part_Change_Error + ' - ' + Label.Unable_to_process_Currency_Change;
          toUpdate.QuotePart.Price_Book__c = null;
        }
      }
      else
      {
        updateSuccess = false;
        errorMessage = Label.Quote_Part_Change_Error + ' - ' + Label.Unable_to_Identify_Selected_QuotePart;
      }
      
    }
    else
    {
      updateSuccess = false;
      errorMessage = Label.Quote_Part_Change_Error + ' - ' + Label.Unable_to_Identify_Selected_QuotePart;
    }
    
    if (!updateSuccess)
    {
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, errorMessage));
    }
  }


  /*
    Finds the QuotePartWrapper record based on the QuotePartId
  */
  private QuotePartWrapper getQuotePartWrapper(Id quotePartId)
  {
    QuotePartWrapper result = null;
    for (ProductWrapper pw : ProductWrappers) 
    {
      for (SiteWrapper sw : pw.SiteWrappers) 
      {
        for (QuotePartWrapper qpw : sw.QuotePartWrappers) 
        {
          if (qpw.QuotePart.Id == quotePartId)
          {
            result = qpw;
            break;
          }
        }
      }
    }
    return result;
  }
  
  /*
    Manages the update to QuatePartWrapper based on currently selected PriceBook and Currency
    Obtains PriceBook and available PricebookEntries and calls the updateQuotePart
    Updates: 
      Currency
      List price
      Unit Price
  */
  private Boolean manageQuotePartWrapperPriceBookCurrencyChange(QuotePartWrapper wrapperToUpdate)
  {
    Boolean result = true; //assume success
    Quote_Part__c quotePart = wrapperToUpdate.QuotePart;
    PriceBook2 selectedPriceBook;
    Map<Id, List<PricebookEntry>> availablePBEs = new Map<Id, List<PricebookEntry>>();
    Set<Id> priceBookIds = new Set<Id>();
    Set<Id> productIds = new Set<Id>();

    // First obtain PriceBook and PriceBookEntry records
    selectedPriceBook = bg_PricebookUtils.GetPricebookById(quotePart.Price_Book__c);
    priceBookIds.add(selectedPriceBook.Id);
    productIds.add(quotePart.Product2__c);
    availablePBEs.putAll(bg_PricebookUtils.GetPriceBookEntriesByPricebookProduct(priceBookIds, productIds));
    if (availablePBEs.containsKey(selectedPriceBook.Id))
    {
      updateQuotePart(quotePart, selectedPriceBook, availablePBEs.get(selectedPriceBook.Id));
      refreshAvailableCurrencies(wrapperToUpdate, availablePBEs.get(selectedPriceBook.Id));
    }
    else
    {
      result = false;
    }
    return result;
  }



  /*
    Refresh the available currencies for the Quote Part Wrapper
  */
  private void refreshAvailableCurrencies(QuotePartWrapper wrapperToUpdate, List<PricebookEntry> availableCurrencies)
  {
    wrapperToUpdate.AvailableCurrencies = new List<SelectOption>();
    for (PriceBookEntry pbe : availableCurrencies)
    {
      wrapperToUpdate.AvailableCurrencies.add(new SelectOption(pbe.CurrencyIsoCode, pbe.CurrencyIsoCode));
    }
  }


  /*
    Updates QuatePart based on currently selected PriceBook and Currency
    Does not check to ensure supplied availablePBEs paramater has values - this is the responsibility 
    of the calling method to ensure PriceBookEntry records exist before calling this method
    Updates: 
      Currency - if needed
      List price
      Unit Price
  */
  private void updateQuotePart(Quote_Part__c quotePartToUpdate, PriceBook2 selectedPriceBook, List<PricebookEntry> availablePBEs)
  {
    PricebookEntry newPricebookEntry;

    // Check for currently selected Currency
    newPricebookEntry = bg_PricebookUtils.FindPricebookEntryByCurrency(availablePBEs, quotePartToUpdate.CurrencyIsoCode);
    if (newPricebookEntry == null) //unable to find current selected currency - find default entry
    {
      if (selectedPriceBook.Default_Pricebook_Currency__c != null) 
      {
        newPricebookEntry = bg_PricebookUtils.FindPricebookEntryByCurrency(availablePBEs, selectedPriceBook.Default_Pricebook_Currency__c);
      }
      else // No default entry on PriceBook - use first availble PBE entry
      {
        newPricebookEntry = availablePBEs[0];
      }
    }
    bg_QuotePartUtils.UpdateQuotePartFromPricebookEntry(quotePartToUpdate, newPricebookEntry, quote.CurrencyISOCode);
  }

  public class ProductWrapper {
    /* Product Wrapper */
    public string Name {get; set;}
    public list<SiteWrapper> SiteWrappers {get; set;}
    public ProductWrapper (string productName) {
      Name = productName;
      SiteWrappers = new list<SiteWrapper>();
    }
  }
  
  private list<SelectOption> pricebookItems;

  public list<SelectOption> getPricebookItems() {
    // Return list of Countries 
    if(pricebookItems == null) {
      // only pricebooks for current year & customer, or global        
      pricebookItems = bg_ControllerUtils.CreateSelectOptions(bg_PricebookUtils.GetPricebooks(null, quote.Account__c, null, pricebookIds, false), 'Id', 'Name', true, false);
    }
    return pricebookItems;
  }
  
  public list<SelectOption> getSiteItems() {
    /* Return list of Countries */

    list<SelectOption> siteItems = new list<SelectOption>();

    list<Quote_Product__c> qpList = bg_QuoteUtils.GetQuoteProducts(quote.Id, true, null, null, true);
    
    siteItems = bg_ControllerUtils.CreateSelectOptions(qpList, 'Site__c', 'Site_Name__c', true, true);
    
    if(siteItems.size() > 1 && CanShowAllQuoteParts) {
      siteItems.add(1, new SelectOption(SHOW_ALL_SITES, 'All Sites')); //System.Label.AllSites
    }

    return siteItems;
  }
  
  public list<SelectOption> getCurrencyCodeItems() {
    /* Return list of Countries */    
    return bg_ControllerUtils.GetPicklistSelectOptions(quote, 'CurrencyIsoCode', true);
  }
  
  public pageReference toggleShowDiscountAmount() {
    showDiscountAmount = !showDiscountAmount;
    return null;  
  }

  public class SiteWrapper {
    /* Site Wrapper */
    public string Name {get; set;}
    public string Id {get; set;}
    public list<QuotePartWrapper> QuotePartWrappers {get; set;}
    public SiteWrapper (string siteId, string siteName) 
    {
      Name = siteName;
      Id = siteId;
      QuotePartWrappers = new list<QuotePartWrapper>();
    }
  }

  private void calculatePricebooksAndCurrencies(List<ProductWrapper> productWrappers)
  {
    Map<Id, List<PricebookEntry>> availablePricebookEntriesByProduct2Id = new Map<Id, List<PricebookEntry>>();
    Map<Id, List<PricebookEntry>> availablePricebookEntriesByPricebookId = new Map<Id, List<PricebookEntry>>();
    Map<String, List<Delegate_Discount_Rate__c>> delegateDiscountRatesByCountryCode = new Map<String, List<Delegate_Discount_Rate__c>>();
    Set<Id> allProduct2Ids = new Set<Id>();
    Set<String> allCountryCodes = new Set<String>();

    for(ProductWrapper productWrapper : productWrappers)
    {
      // loop over all quote parts and get a unique set of product2ids
      for(SiteWrapper siteWrapper : productWrapper.SiteWrappers)
      {
        for(QuotePartWrapper quotePartWrapper : siteWrapper.QuotePartWrappers)
        {
          allProduct2Ids.add(quotePartWrapper.QuotePart.Product2__c);
          if(null!=quotePartWrapper.QuotePart.Product2__r.Course_Country__c)
          {
            allCountryCodes.add(quotePartWrapper.QuotePart.Product2__r.Course_Country__c);
          }
        }
      }
    }

    // create maps of all active pricebook entries for the unique set of product2 ids
    for(PricebookEntry pbe : [SELECT Id, 
                     CurrencyIsoCode, 
                     Product2Id, 
                     Pricebook2Id,
                     UnitPrice 
                  FROM PricebookEntry 
                  WHERE IsActive = true
                  AND Product2Id IN :allProduct2Ids])
    {
      // pricebookId -> pricebookentries
      if(!availablePricebookEntriesByPricebookId.containsKey(pbe.Pricebook2Id ))
      {
        availablePricebookEntriesByPricebookId.put(pbe.Pricebook2Id, new List<PricebookEntry>());
      }
      availablePricebookEntriesByPricebookId.get(pbe.Pricebook2Id).add(pbe);

      // product2Id -> pricebookentries
      if(!availablePricebookEntriesByProduct2Id.containsKey(pbe.Product2Id ))
      {
        availablePricebookEntriesByProduct2Id.put(pbe.Product2Id, new List<PricebookEntry>());
      }
      availablePricebookEntriesByProduct2Id.get(pbe.Product2Id).add(pbe);
    }

    // get a list of active pricebook2 records for all unique pricebook2 ids referenced by the PBEs
    Map<Id,Pricebook2> priceBookrecordsByPricebookId = new Map<Id,Pricebook2>([SELECT Id,
                                              Name,
                                                Country_Code__c, 
                                                Year__c,
                                                Account__c,
                                                Default_Pricebook_Currency__c 
                                             FROM Pricebook2 
                                             WHERE Id IN: availablePricebookEntriesByPricebookId.keySet()  
                                             AND IsActive = true 
                                             AND AvailableForUse__c = true 
                                             AND IsStandard = false 
                                             ORDER BY Year__c DESC, 
                                                   Name ASC]);

    // build a map of delegate discount rates keyed by country code
    for(Delegate_Discount_Rate__c delegateDiscountRate : [SELECT Id,
                                   Country__c,
                                   Minimum_Delegates__c,
                                   Maximum_Delegates__c,
                                   Percentage_Discount__c
                                FROM Delegate_Discount_Rate__c
                                WHERE Active__c = true])
    {
      if(!delegateDiscountRatesByCountryCode.containsKey(delegateDiscountRate.Country__c))
      {
        delegateDiscountRatesByCountryCode.put(delegateDiscountRate.Country__c, new List<Delegate_Discount_Rate__c>());
      }
      delegateDiscountRatesByCountryCode.get(delegateDiscountRate.Country__c).add(delegateDiscountRate);
    }


    for(ProductWrapper productWrapper : productWrappers)
    {
      // loop over all quote parts and get a unique set of product2ids
      for(SiteWrapper siteWrapper : productWrapper.SiteWrappers)
      {
        // loop over all quote parts and map the available Pricebooks and Currencies for individual quote parts
        for(QuotePartWrapper quotePartWrapper : siteWrapper.QuotePartWrappers)
        {
          Id product2Id = quotePartWrapper.QuotePart.Product2__c;
          Id accountId = quotePartWrapper.MainQuote.Account__c;

          // get a unique set of pricebooks from the pricebook entries for the product2 record
          Map<Id, List<PricebookEntry>> pricebookEntriesByPricebookIdForQuotePart = new Map<Id, List<PricebookEntry>>();
          
          // get the available PBEs for the related Product2 record
          List<PricebookEntry> pricebookEntriesForProduct2 = new List<PricebookEntry>();
          if(availablePricebookEntriesByProduct2Id.containsKey(product2Id))
          {
            pricebookEntriesForProduct2 = availablePricebookEntriesByProduct2Id.get(product2Id);
          }

          // Map the pbes for this quotepart by pricebook2 id
          for(PricebookEntry pbe : pricebookEntriesForProduct2)
          {
            if(!pricebookEntriesByPricebookIdForQuotePart.containsKey(pbe.Pricebook2Id))
            {
              pricebookEntriesByPricebookIdForQuotePart.put(pbe.Pricebook2Id, new List<PricebookEntry>());
            }
            pricebookEntriesByPricebookIdForQuotePart.get(pbe.Pricebook2Id).add(pbe);
          }
          // write the pricebook entry map to the quote part wrapper, we will refer to this when the user changes the pricebook in the UI
          quotePartWrapper.pricebookEntriesByPricebookIdForQuotePart = pricebookEntriesByPricebookIdForQuotePart;

          // build a list of available pricebooks for this quote part - including MSA records if available
          Map<Id,Pricebook2> availablePricebooksForProductByPricebookId = new Map<Id,Pricebook2>();
          for(Id pricebookid : pricebookEntriesByPricebookIdForQuotePart.Keyset())
          {
            if(priceBookrecordsByPricebookId.containsKey(pricebookid))
            {
              Pricebook2 pricebook = priceBookrecordsByPricebookId.get(pricebookid);
              // add country pricebooks and any MSA pricebooks for this account
              if(null==pricebook.Account__c || accountId == pricebook.Account__c)
              {
                availablePricebooksForProductByPricebookId.put(pricebook.Id, pricebook);
              }
            }
          }
          // write the available pricebook map to the quote part wrapper, we will refer to this when the user changes the pricebook in the UI
          quotePartWrapper.availablePricebooksForProductByPricebookId = availablePricebooksForProductByPricebookId;
          
          // map pricebooks by country code - for use with local prices
          Map<String, List<Pricebook2>> pricebooksByCountryCode = new Map<String, List<Pricebook2>>();
          for(Pricebook2 pricebook : availablePricebooksForProductByPricebookId.Values())
          {
            if(!pricebooksByCountryCode.containsKey(pricebook.Country_Code__c))
            {
              pricebooksByCountryCode.put(pricebook.Country_Code__c, new List<Pricebook2>());
            }
            pricebooksByCountryCode.get(pricebook.Country_Code__c).add(pricebook);
          }

          // if we the user has not priced the quote parts via this screen, this flag is updated once the user has been through this process
          // the code in this bock will set the default pricebooks, currencies and pricing for the line items based on the logic supplied by BSI
          // essentially we ignore what BZ have sent us in the pricing fields of the quote parts.
          if(!quotePartWrapper.QuotePart.Pricing_Configured__c)
          {
            Boolean MSAPricebookSet = false;
            Boolean countryCodePricebookSet = false;
            Product2 quotePartProduct2 = product2sById.get(product2Id);
            // set this to true, once the page is saved we will no longer work out defaults we will load what the user saved last time round
            quotePartWrapper.QuotePart.Pricing_Configured__c = true;
            //set the default pricebook to use for the quotePart - check for MSA pricebooks first
            for(Pricebook2 pricebook : availablePricebooksForProductByPricebookId.Values())
            {
              // Is this pricebook related to this account - only MSA pricebooks are linked to an account, country specific pricebooks are not linked to an account
              if(null!=accountId && accountId == pricebook.Account__c)
              {
                quotePartWrapper.QuotePart.Price_Book__c = pricebook.Id;
                // filter through the pricebook entries for this pricebook and return the PBE which is in the primary currency for this pricebook
                // for example UK2017 should return GBP, ES2017 should return EUR, US2017 should return USD
                PricebookEntry defaultPricebookEntry = calculateDefaultPricebookEntry(pricebookEntriesByPricebookIdForQuotePart.get(pricebook.Id), pricebook.Default_Pricebook_Currency__c);
                quotePartWrapper.QuotePart.CurrencyIsoCode = defaultPricebookEntry.CurrencyISOCode;
                if(!quotePartWrapper.QuotePart.IsTraining__c)
                {
                  quotePartWrapper.QuotePart.List_Price__c = defaultPricebookEntry.UnitPrice;
                }
                else
                {
                  List<Delegate_Discount_Rate__c> delegateDiscountRatesForQuotePart = new List<Delegate_Discount_Rate__c>();
                  if(delegateDiscountRatesByCountryCode.containsKey(quotePartWrapper.QuotePart.Product2__r.Course_Country__c))
                  {
                    delegateDiscountRatesForQuotePart = delegateDiscountRatesByCountryCode.get(quotePartWrapper.QuotePart.Product2__r.Course_Country__c);
                  }
                  quotePartWrapper.QuotePart.List_Price__c = calculateTrainingListPrice(quotePartWrapper.QuotePart, quotePartProduct2, defaultPricebookEntry.UnitPrice, delegateDiscountRatesForQuotePart);
                }
                MSAPricebookSet = true;
              }
            }
            // if we didnt find an MSA pricebook, check if we are using local prices
            if(!MSAPricebookSet)
            {
              // if we are using local prices we want to default the pricebook to the country of the related site record
              if(quotePartWrapper.MainQuote.UseLocalPrices__c)
              {
                if(pricebooksByCountryCode.containsKey(quotePartWrapper.QuotePart.Country_Code__c))
                {
                  List<Pricebook2> countryPricebooks = pricebooksByCountryCode.get(quotePartWrapper.QuotePart.Country_Code__c);
                  if(!countryPricebooks.isEmpty())
                  {
                    // its possible we will have more than 1 pricebook for a country for example UK2016 and UK2017 given the sort order we should have the latest pricebook first in the list
                    Pricebook2 pricebook = countryPricebooks[0];
                    quotePartWrapper.QuotePart.Price_Book__c = pricebook.Id;
                    // filter through the pricebook entries for this pricebook and return the PBE which is in the primary currency for this pricebook
                    // for example UK2017 should return GBP, ES2017 should return EUR, US2017 should return USD
                    PricebookEntry defaultPricebookEntry = calculateDefaultPricebookEntry(pricebookEntriesByPricebookIdForQuotePart.get(pricebook.Id), pricebook.Default_Pricebook_Currency__c);
                    quotePartWrapper.QuotePart.CurrencyIsoCode = defaultPricebookEntry.CurrencyISOCode;
                    if(!quotePartWrapper.QuotePart.IsTraining__c)
                    {
                      quotePartWrapper.QuotePart.List_Price__c = defaultPricebookEntry.UnitPrice;
                    }
                    else
                    {
                      List<Delegate_Discount_Rate__c> delegateDiscountRatesForQuotePart = new List<Delegate_Discount_Rate__c>();
                      if(delegateDiscountRatesByCountryCode.containsKey(quotePartWrapper.QuotePart.Product2__r.Course_Country__c))
                      {
                        delegateDiscountRatesForQuotePart = delegateDiscountRatesByCountryCode.get(quotePartWrapper.QuotePart.Product2__r.Course_Country__c);
                      }
                      quotePartWrapper.QuotePart.List_Price__c = calculateTrainingListPrice(quotePartWrapper.QuotePart, quotePartProduct2, defaultPricebookEntry.UnitPrice, delegateDiscountRatesForQuotePart);
                    }
                    countryCodePricebookSet = true;
                  }
                }
              }
            }
            // if we havent set a MSA pricebook and we are not using local prices (or we didnt find a local pricebook) then try and default to the quotes preferred pricebook
            if(!MSAPricebookSet && !countryCodePricebookSet)
            {
              // check for default quote pricebook 
              if(availablePricebooksForProductByPricebookId.containsKey(quotePartWrapper.MainQuote.PriceBook2Id__c))
              {
                Pricebook2 pricebook = availablePricebooksForProductByPricebookId.get(quotePartWrapper.MainQuote.PriceBook2Id__c);
                quotePartWrapper.QuotePart.Price_Book__c = pricebook.Id;
                // filter through the pricebook entries for this pricebook and return the PBE which is in the primary currency for this pricebook
                // for example UK2017 should return GBP, ES2017 should return EUR, US2017 should return USD
                PricebookEntry defaultPricebookEntry = calculateDefaultPricebookEntry(pricebookEntriesByPricebookIdForQuotePart.get(pricebook.Id), pricebook.Default_Pricebook_Currency__c);
                quotePartWrapper.QuotePart.CurrencyIsoCode = defaultPricebookEntry.CurrencyISOCode;
                if(!quotePartWrapper.QuotePart.IsTraining__c)
                {
                  quotePartWrapper.QuotePart.List_Price__c = defaultPricebookEntry.UnitPrice;
                }
                else
                {
                  List<Delegate_Discount_Rate__c> delegateDiscountRatesForQuotePart = new List<Delegate_Discount_Rate__c>();
                  if(delegateDiscountRatesByCountryCode.containsKey(quotePartWrapper.QuotePart.Product2__r.Course_Country__c))
                  {
                    delegateDiscountRatesForQuotePart = delegateDiscountRatesByCountryCode.get(quotePartWrapper.QuotePart.Product2__r.Course_Country__c);
                  }
                  quotePartWrapper.QuotePart.List_Price__c = calculateTrainingListPrice(quotePartWrapper.QuotePart, quotePartProduct2, defaultPricebookEntry.UnitPrice, delegateDiscountRatesForQuotePart);
                }
              }
              // we are unable to find a MSA pricebook, Country Pricebook, or default pricebook for this product 
              // we will default this to the first pricebook available for this product, if one is not available we will not set a value
              // and the line item will be disabled, the user will then need to contact an admin at BSI as this would indicate no pricebook has been
              // setup for this product
              else
              {
                if(availablePricebooksForProductByPricebookId.Values().Size() > 0)
                {
                  Pricebook2 pricebook = availablePricebooksForProductByPricebookId.Values()[0];
                  quotePartWrapper.QuotePart.Price_Book__c = pricebook.Id;
                  // filter through the pricebook entries for this pricebook and return the PBE which is in the primary currency for this pricebook
                  // for example UK2017 should return GBP, ES2017 should return EUR, US2017 should return USD
                  PricebookEntry defaultPricebookEntry = calculateDefaultPricebookEntry(pricebookEntriesByPricebookIdForQuotePart.get(pricebook.Id), pricebook.Default_Pricebook_Currency__c);
                  quotePartWrapper.QuotePart.CurrencyIsoCode = defaultPricebookEntry.CurrencyISOCode;
                  if(!quotePartWrapper.QuotePart.IsTraining__c)
                  {
                    quotePartWrapper.QuotePart.List_Price__c = defaultPricebookEntry.UnitPrice;
                  }
                  else
                  {
                    List<Delegate_Discount_Rate__c> delegateDiscountRatesForQuotePart = new List<Delegate_Discount_Rate__c>();
                    if(delegateDiscountRatesByCountryCode.containsKey(quotePartWrapper.QuotePart.Product2__r.Course_Country__c))
                    {
                      delegateDiscountRatesForQuotePart = delegateDiscountRatesByCountryCode.get(quotePartWrapper.QuotePart.Product2__r.Course_Country__c);
                    }
                    quotePartWrapper.QuotePart.List_Price__c = calculateTrainingListPrice(quotePartWrapper.QuotePart, quotePartProduct2, defaultPricebookEntry.UnitPrice, delegateDiscountRatesForQuotePart);
                  }
                }
              }
            }
            quotePartWrapper.QuotePart.Converted_list_Price__c = bg_QuotePartUtils.getConvertedPriceInQuotePartCurrency(quotePartWrapper.QuotePart.List_Price__c, quotePartWrapper.QuotePart.CurrencyIsoCode, quote.CurrencyIsoCode);
            quotePartWrapper.QuotePart.Price__c = quotePartWrapper.QuotePart.Converted_list_Price__c;
          }
          else{
            quotePartWrapper.QuotePart.Converted_list_Price__c = bg_QuotePartUtils.getConvertedPriceInQuotePartCurrency(quotePartWrapper.QuotePart.List_Price__c, quotePartWrapper.QuotePart.CurrencyIsoCode, quote.CurrencyIsoCode);
          }
          // Added this for Sorting of the Pricebooks in select list
          List<PricebookWrapper> pbwList = new List<PricebookWrapper>();
          for(Pricebook2 pb : availablePricebooksForProductByPricebookId.Values()){
            // Pricebook Name will be like UK 2018 consider only UK for sorting
            PricebookWrapper pbw = new PricebookWrapper(pb.Id, pb.Name, Integer.valueOf(pb.Year__c));
            pbwList.add(pbw);
          }
          
          pbwList.sort();
          List<SelectOption> optionItems = new List<SelectOption>();
          
          for(PricebookWrapper pbw : pbwList){
            optionItems.add(new SelectOption(pbw.Id, pbw.fullName));
          }
          
          quotePartWrapper.AvailablePricebooks = optionItems;//bg_ControllerUtils.CreateSelectOptions(availablePricebooksForProductByPricebookId.Values(), 'Id', 'Name', true, false);
          quotePartWrapper.AvailableCurrencies = new List<SelectOption>();
          Set<String> isoCodes = new Set<String>();
          if(pricebookEntriesByPricebookIdForQuotePart.containsKey(quotePartWrapper.QuotePart.Price_Book__c))
          {
            for(PricebookEntry pbe : pricebookEntriesByPricebookIdForQuotePart.get(quotePartWrapper.QuotePart.Price_Book__c))
            {
              if(!isoCodes.contains(pbe.CurrencyIsoCode))
              {  
                isoCodes.add(pbe.CurrencyIsoCode);
                quotePartWrapper.AvailableCurrencies.add(new SelectOption(pbe.CurrencyIsoCode, pbe.CurrencyIsoCode));  
              }
              
            }
          }
          else
          {
            if(!quotePartWrapper.AvailablePricebooks.isEmpty())
            {
              if(pricebookEntriesByPricebookIdForQuotePart.containsKey(quotePartWrapper.AvailablePricebooks[0].getValue()))
              {
                for(PricebookEntry pbe : pricebookEntriesByPricebookIdForQuotePart.get(quotePartWrapper.AvailablePricebooks[0].getValue()))
                {
                  if(!isoCodes.contains(pbe.CurrencyIsoCode))
                  {  
                    isoCodes.add(pbe.CurrencyIsoCode);
                    quotePartWrapper.AvailableCurrencies.add(new SelectOption(pbe.CurrencyIsoCode, pbe.CurrencyIsoCode));
                  }
                }
              }
            }
          }
        }
      }
    }

    //do a check to see if all quote parts have pricebook otherwise flag an error.
    for(ProductWrapper productWrapper : productWrappers)
    {
      for(SiteWrapper siteWrapper : productWrapper.SiteWrappers)
      {
        for(QuotePartWrapper quotePartWrapper : siteWrapper.QuotePartWrappers)
        {
          //if they are null then no pricebook exists for product and therefore flag an error
          if(quotePartWrapper.QuotePart.Price_Book__c == null)
          {
            HasNoPriceBookEntryies = true;

          }
        }
      }
    }
  }

  public PricebookEntry calculateDefaultPricebookEntry(List<PricebookEntry> pricebookEntries, String pricebookDefaultCurrency)
  {
    PricebookEntry defaultPricebookEntryToReturn = null;
    for(PricebookEntry pbe : pricebookEntries)
    {
      if(pbe.CurrencyISOCode == pricebookDefaultCurrency)
      {
        defaultPricebookEntryToReturn = pbe;
      }
    }
    if(null==defaultPricebookEntryToReturn && !pricebookEntries.isEmpty())
    {
      defaultPricebookEntryToReturn = pricebookEntries[0];
    }
    return defaultPricebookEntryToReturn;
  } 


  /*
    In most cases we will return the list price from the pbe, Training product pricing needs to be calculated differently
    
    Training Pricing Description from Julie Skinner
    1)
    If Product2.Course_Delivery__c = In-House AND (OR (Product2.Pricing_Method__c = “Day Rate”, Product2.Bespoke_Event__c=TRUE))
    use the price from the valid price book and multiply it by the number of days (sent from BZ) to get the Total Price. (No Of Days is sent across as a textual string into InfoVal3__c) 
    Divide the Total Price by no of delegates and use for the Unit Price/Sales Price.
    
    2)
    If Product2.Course_Delivery__c = In-House AND Product2.Pricing_Method__c = “Delegate Rate” use the price 
    from the valid price book multiply by number of delegates (this is the number attribute on the quote part) to get the intial Total Price then check the 
    Delegate Discount Rates for the discount % to apply – based on country Code and min/max delegates in discount rate object.  
    Apply discount to get total price then divide by number of delegates to give Unit Price/Sales Price.
  */
  public Decimal calculateTrainingListPrice(Quote_part__c quotePart, Product2 quotePartProduct2, Decimal pbeUnitPrice, List<Delegate_Discount_Rate__c> delegateDiscountRates)
  {
    Decimal listPrice = pbeUnitPrice;
    // defaulted to blank strings to protect against using the Equals method on null
    String courseDelivery = '';
    String pricingMethod = '';
    Boolean isBespokeEvent = quotePartProduct2.Bespoke_Event__c;
    if(null!=quotePartProduct2.Course_Delivery__c)
    {
      courseDelivery = quotePartProduct2.Course_Delivery__c;
    }
    if(null!=quotePartProduct2.Pricing_Method__c)
    {
      pricingMethod = quotePartProduct2.Pricing_Method__c;
    }
    // 1)
    if(courseDelivery.Equals(bg_Constants.INHOUSE_PRODUCT) && ( pricingMethod.Equals(bg_Constants.PRICINGMETHOD_DAYRATE) || isBespokeEvent))
    {
      Decimal numberOfDelegates = quotePart.Number__c;
      Decimal numberOfDays = Decimal.ValueOf(bg_TrainingUtils.GetInfoValue(quotePart.InfoVal3__c));
      Decimal intialTotalPrice = (pbeUnitPrice * numberOfDays).setScale(2);
      listPrice = (intialTotalPrice / numberOfDelegates).setScale(2);
    }
    else
    {
      // 2)
      if(courseDelivery.Equals(bg_Constants.INHOUSE_PRODUCT) && pricingMethod.Equals(bg_Constants.PRICINGMETHOD_DELEGATERATE))
      {
        Decimal numberOfDelegates = quotePart.Number__c;
        Decimal intialTotalPrice = (pbeUnitPrice * numberOfDelegates).setScale(2);
        Delegate_Discount_Rate__c delegateDiscountRateToUse = null;
        for(Delegate_Discount_Rate__c delegateDiscountRate : delegateDiscountRates)
        {
          if(numberOfDelegates >= delegateDiscountRate.Minimum_Delegates__c && numberOfDelegates <= delegateDiscountRate.Maximum_Delegates__c)
          {
            delegateDiscountRateToUse = delegateDiscountRate;
          }
        }
        Decimal totalPrice = intialTotalPrice;
        if(null!=delegateDiscountRateToUse)
        {
          decimal discountAmount = (intialTotalPrice * (delegateDiscountRateToUse.Percentage_Discount__c / 100)).setScale(2);
          totalPrice = (intialTotalPrice - discountAmount);
        }
        listPrice = (totalPrice / numberOfDelegates).setScale(2);
      }  
    }
    return listPrice;
  }
  
  public class QuotePartWrapper {
    /* Quote Part Wrapper */
    public Quote_Part__c QuotePart {get; set;}
    public boolean showNotes {get; set;}
    public transient Quote__c MainQuote { get; set; }
    public Product2 product { get; set; }

    //************ changes July 2017 *******************//
    public List<SelectOption> AvailableCurrencies { get; set; }
    public list<SelectOption> AvailablePricebooks {get; set;}
    
    public transient Map<Id, List<PricebookEntry>> pricebookEntriesByPricebookIdForQuotePart {get; set;}
    public transient Map<Id,Pricebook2> availablePricebooksForProductByPricebookId {get; set;}
    //************ changes July 2017 *******************//

    // default checked, uncheck to exclude individual QPW from bundle action where it cannot be excluded by using filters
    public Boolean includeInBundleAction {get; set;} 

    public QuotePartWrapper (Quote_Part__c pQuotePart, Quote__c inputQuote, Product2 sfproduct) {
      QuotePart = pQuotePart;
      MainQuote = inputQuote;
      product = sfproduct;
      showNotes = !bg_StringUtils.IsBlank(QuotePart.Notes__c);
      includeInBundleAction = true;

      //************ changes July 2017 Jorge *******************// to avoid problems of old records
      //Avoid prices with null values
      if(QuotePart.List_Price__c == null)
      {
        QuotePart.List_Price__c = 0;
      }
      if(QuotePart.Price__c == null)
      {
        QuotePart.Price__c = 0;
      }
    }

    public decimal DiscountAmount {
            get {
                //return (Discount * Price * Qty).setScale(2);
                return (Discount * Price).setScale(2);
            }
            set {
                    discountAmount = value;
                //if(value != 0)
                //{
                    if(Price == 0)
                    {
                        QuotePart.Discount_Percentage__c = 0;
                    }else
                    {
                        QuotePart.Discount_Percentage__c = 100 - (((Price - value) / Price) * 100);
                    }
                    //QuotePart.Discount_Percentage__c = (100 - ((((Price * Qty) - value) / (Price * Qty)) * 100));
                //}
            }
        }

        public long RoundedDiscountAmount {
            get {
                return DiscountAmount.Round(System.RoundingMode.HALF_UP);
            }
            set {
                discountAmount = decimal.valueOf(value);
                //if(value != 0)
                //{
                    if(Price == 0)
                    {
                        QuotePart.Discount_Percentage__c = 0;
                    }else
                    {
                        QuotePart.Discount_Percentage__c = 100 - (((Price - value) / Price) * 100);
                    }
                    //QuotePart.Discount_Percentage__c = (100 - ((((Price * Qty) - value) / (Price * Qty)) * 100));
                //}
            }
        }
        
        public decimal Discount {
            get {
                return (bg_Utilities.getDecimal(QuotePart.Discount_Percentage__c) / 100);
            }
        }

        public decimal RoundedDiscount {
            get {
                return Discount.setScale(2);
            }
        }
            
        public long RoundedPrice {
            get {
                return Price.Round(System.RoundingMode.HALF_UP);
            }
            set {
                QuotePart.Price__c = decimal.valueOf(value);
                QuotePart.Cost__c  = QuotePart.Price__c * bg_Utilities.getDecimal(QuotePart.Exchange_Rate__c);
            }
        }

        public decimal Price {
            get {
                return bg_Utilities.getDecimal(QuotePart.Price__c);
            }
            set {
                QuotePart.Price__c = value;
                QuotePart.Cost__c  = QuotePart.Price__c * bg_Utilities.getDecimal(QuotePart.Exchange_Rate__c);              
            }           
        }

        public decimal Qty {
            get {
                return bg_Utilities.getDecimal(QuotePart.Number__c);
            }
        }

        public decimal Cost {
            get {
                return bg_Utilities.getDecimal(QuotePart.Cost__c);
            }
            
        }

        public decimal TotalPrice {
            get 
            {
                //REF 24056 Added If to use Runded Discount Amount (Original was jsut the return line return (Price * Qty) - DiscountAmount;)
                if(QuotePart.Round_Discount_Amount__c)
                {
                    return (Price - RoundedDiscountAmount)* Qty;
                }else
                {
                    //return (Price * Qty) - DiscountAmount;
                    return (Price - DiscountAmount)* Qty;
                }
            }
        }       

        public decimal TotalQuotePrice {
            get 
            {
                //REF 24056 Added If to use Runded Discount Amount (Original was jsut the return line return (discount * Cost * Qty);)
                if(QuotePart.Round_Discount_Amount__c)
                {
                    //return (Cost * Qty) - TotalQuoteDiscountAmount.Round(System.RoundingMode.HALF_UP);
                    return (Cost - TotalQuoteDiscountAmount.Round(System.RoundingMode.HALF_UP)) * Qty;
                }else
                {
                    //return (Cost * Qty) - TotalQuoteDiscountAmount;
                    return (Cost - TotalQuoteDiscountAmount) * Qty;
                }
            }
        }

        public decimal TotalQuoteDiscountAmount {
            get 
            {
                return (discount * Cost * Qty);
            }
        }
        
        public void ClearNotes() {
            showNotes = false;
            QuotePart.Notes__c = '';
        }
    }

  private set<Id> pricebookIds;
  
  private void BuildWrappers(list<Quote_Part__c> quoteParts) {
    /*
      Method to Build Wrappers for Quote Part data
    */
    ProductWrappers = new list<ProductWrapper>();
    map<string, ProductWrapper> productWrappersMap = new map<string, ProductWrapper>();
    map<string, SiteWrapper> productSiteWrappersMap = new map<string, SiteWrapper>();
    Set<Id> product2Ids = new Set<Id>();
    pricebookIds = new set<Id>();
    
    if(null==product2sById)
    {
      for(Quote_Part__c quotePart : quoteParts)
      {
        product2Ids.add(quotePart.Product2__c);
      }
      product2sById = bg_ProductUtils.getProductsById(product2Ids);
    }
    for(Quote_Part__c quotePart : quoteParts) {
      
      String productName = null;
      String location = null;
      String country = null;

      if(quotePart.Quote_Product__r.Is_Project_Phase__c)
      {
        productName = quotePart.Quote_Product__r.Project_Name__c;
        location = quotePart.Location__c;
        country = '';
      }
      else if(quotePart.ProjectProductName__c == 'Product Certification Project Builder')
      {
        productName = quotePart.Project__r.Name + ' - ' + quotePart.Product_Name__c;
        location = quotePart.Quote_Product__r.Site_Name__c;
        country = quotePart.Quote_Product__r.Site__r.Country__c;
      }          
      else if(quotePart.Quote_Product__r.Product_Name__r.RecordType.Name == 'Customized Audits')
      {
        productName = quotePart.Product_Name__c;
        location = quotePart.Quote_Product__r.Site_Name__c;
        country = quotePart.Quote_Product__r.ProjectSiteCountry__c;
      }
      else
      {
        productName = quotePart.Product_Name__c;
        location = quotePart.Quote_Product__r.Site_Name__c;
        country = quotePart.Quote_Product__r.Site__r.Country__c;
      }

      // Add Product Wrapper?
      if(!productWrappersMap.containsKey(productName)) {
        ProductWrapper pw = new ProductWrapper(productName);
        productWrappersMap.put(productName, pw);
        ProductWrappers.add(pw);
      } 
      ProductWrapper pw = productWrappersMap.get(productName);

      // Add Site Wrapper?
      if(!productSiteWrappersMap.containsKey(productName + location)) {
        SiteWrapper sw = new SiteWrapper(quotePart.Quote_Product__r.Site_Name__c, location + ( (String.isBlank(country) ? '' :  ', ' + country) ));
        productSiteWrappersMap.put(productName + quotePart.Quote_Product__r.Site_Name__c, sw);
        pw.SiteWrappers.add(sw);
      } 
      SiteWrapper sw = productSiteWrappersMap.get(productName + quotePart.Quote_Product__r.Site_Name__c);

      // Store pricebook Id
      pricebookIds.add(quotePart.Price_Book__c);
      
      // Quote Part Wrapper
      //************ changes July 2017 *******************//
      sw.QuotePartWrappers.add(new QuotePartWrapper(quotePart, quote, product2sById.get(quotePart.Product2__c)));
      //************ changes July 2017 *******************//
    }

    calculatePricebooksAndCurrencies(productWrappersMap.Values());
  }
  
  public PageReference Save() {
    /*
      Save (and Close)
    */
    if(SaveParts(false)) {
      return new PageReference('/' + quote.Id);
    }
    return null;  
  }

  private boolean SaveParts(boolean quickSave) {
    /*
      Save quote parts
    */
    boolean result = true;
    try {
      if(!quoteParts.isEmpty()) {
          Decimal price = 0, listPrice = 0;
          for(Quote_Part__c qp: quoteParts) {
              price = qp.Price__c != null ? qp.Price__c.setScale(0) : 0;
              listPrice = qp.Converted_list_Price__c != null ? qp.Converted_list_Price__c.setScale(0) : 0;
              
              if(price < listPrice) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Price cannot be less than the list price'));
                return false;
              }
          }      
      
        bg_QuoteUtils.SaveQuoteParts(quote, quoteParts);

        // Sync quote with opportunity
        bg_QuoteUtils.SyncQuoteWithOpportunity(quote.Id);      
      }
    } catch (exception ex) {
      result = false;
      ApexPages.addMessages(ex);
    }
    return result;
  }
  
  public PageReference QuickSave() {
    /*
      Quick Save
    */
    SaveParts(true);
    return null;  
  }

  public PageReference Cancel() {
    /*
      Cancel
    */
    return new PageReference('/' + quote.Id);  
  }

  /*--------------------------------------------*/
  /* DISCOUNT STATUS                            */  
  public boolean getDiscountStatusNA() {
    /* Return Discount Status NA */
    return quote.DiscountStatus__c == quoteSettings.StatusNA__c || bg_StringUtils.IsBlank(quote.DiscountStatus__c);
  }
  
  public boolean getDiscountStatusApproved() {
    /* Return Discount Status Approved */
    return quote.DiscountStatus__c == quoteSettings.StatusApproved__c;    
  }
  
  public boolean getDiscountStatusPending() {
    /* Return Discount Status Pending */
    return quote.DiscountStatus__c == quoteSettings.StatusWaiting__c;
  }
  
  public boolean getDiscountStatusRejected() {
    /* Return Discount Status Rejected */
    return quote.DiscountStatus__c == quoteSettings.StatusRejected__c;
  }
  
  public boolean getDiscountStatusDraft() {
    /* Return Discount Status Draft */
    return quote.DiscountStatus__c == quoteSettings.StatusDraft__c;
  }
  
  public decimal getNoDiscountableParts() {
    return bg_QuoteApprovalUtils.NO_DISCOUNTABLE_PRODUCTS;
  }

  
  public void CalculateGrandTotals() {
    /*
      Calculate Grand Totals
    */
    GrandTotalPrice = 0;
    GrandTotalDiscount = 0;
    GrandTotalDiscountAmount = 0;
    Decimal GrandTotalDiscountForPercentage = 0;
    Decimal GrandTotalPriceForPercentage = 0;
    Decimal priceAfterDiscount = 0;
    for(ProductWrapper pw : ProductWrappers) {
      for(SiteWrapper sw : pw.SiteWrappers) {
        for(QuotePartWrapper qpw : sw.QuotePartWrappers) 
        {
          //REF 24056 Added IF logic for calculating rounding
          if(roundDiscounts)
          {
            qpw.QuotePart.Round_Discount_Amount__c = true;
          }else
          {
            qpw.QuotePart.Round_Discount_Amount__c = false;
          }
          //************ 2017 **************/  
          //GrandTotalPrice += qpw.TotalQuotePrice;
          //GrandTotalDiscountAmount += qpw.TotalQuoteDiscountAmount;

          GrandTotalDiscountAmount += qpw.DiscountAmount * qpw.QuotePart.Number__c;
          GrandTotalPrice += qpw.TotalPrice;

          GrandTotalDiscountForPercentage += qpw.DiscountAmount * qpw.QuotePart.Number__c;
          GrandTotalPriceForPercentage += qpw.Price * qpw.QuotePart.Number__c;

          priceAfterDiscount = qpw.Price - qpw.DiscountAmount;

          //calculate the true discount
          if ((qpw.TotalPrice == 0 && qpw.DiscountAmount == 0) || 
                        qpw.Price == 0 || 
                        qpw.TotalPrice == null || 
                        qpw.Price == null || 
                        priceAfterDiscount > qpw.QuotePart.Converted_list_Price__c)
          {
            qpw.QuotePart.True_discount__c = 0;
            qpw.QuotePart.True_Discount_Amount__c = 0;
          }
          else
          {
            Decimal trueTotalPrice = qpw.TotalPrice/qpw.QuotePart.Number__c;
            System.debug(qpw.QuotePart);
            Decimal TrueDiscountAmount = qpw.QuotePart.Converted_list_Price__c - trueTotalPrice;
            qpw.QuotePart.True_Discount_Amount__c = TrueDiscountAmount * qpw.QuotePart.Number__c;
            qpw.QuotePart.True_discount__c = ((TrueDiscountAmount/qpw.QuotePart.Converted_list_Price__c)*100).setScale(2);
          }

          //************ 2017 **************/  
        }
      }
    }

        if(GrandTotalPrice + GrandTotalDiscountAmount > 0) {
          try
          {
            GrandTotalDiscount = ((GrandTotalDiscountForPercentage /GrandTotalPriceForPercentage) * 100).setScale(2);
        }catch(Exception e)
        {
          //Nothing to do here, avoid dividing by zero in case the list price is 0
        }    
        }
  }
        
  /* 
      FacetedSearchDelegate methods
    */
        
  public void addSearchComponent(String delegatorKey, bg_FacetedSearchComponent component)
    {   
      if(quoteParts.size() > integer.valueOf(bg_CustomSettingsUtils.GetSystemSettings().QuotePartGridMaxParts__c))
        return;
           
      if (facetedSearchComponentMap == null)
    {
      facetedSearchComponentMap = new Map<String, bg_FacetedSearchComponent>();
      filterValueByFieldMap = new Map<String, Set<SelectOption>>();      
    }
    facetedSearchComponentMap.put(delegatorKey, component);
      List<String> pn = new List<String>();    
    for(SelectOption s : productNames) {
        if(s.getLabel() != null && s.getLabel().indexOf(' : ') > 1)
            pn.add(s.getLabel().split(' : ')[1]);
        else        
            pn.add(s.getLabel());
        break;
    }
    
    List<String> sn = new List<String>();
    for(SelectOption s : siteNames) {
        sn.add(s.getLabel());
        break;
    }
    
    if(applyFilter){
        if(delegatorKey == 'Quote_Part__cProduct_Name__c')
            facetedSearchComponentMap.get('Quote_Part__cProduct_Name__c').setSelectedItems(pn);
        else if(delegatorKey == 'Quote_Part__cQuote_Product__r.Site_Name__c')
            facetedSearchComponentMap.get('Quote_Part__cQuote_Product__r.Site_Name__c').setSelectedItems(sn);
    }
    
    filterValueByFieldMap.put(component.getParamKey(), new Set<SelectOption>());
    
    getFilterValues(quoteParts, component);
    // create a Map containing all the Quote Arts for a Filter field / value
    //createPartByFilterValueMap();
  }
        
   public List<SelectOption> getAllOptions(String objectName, String fieldName)
   {

     
     List<SelectOption> selectOptions = new List<SelectOption>(filterValueByFieldMap.get(fieldName));
     // Create the first picklist placeholder value
    SelectOption option = GetSelectOptionForFieldPath ('Quote_Part__c', fieldName);
    
    //************ changes July 2017 *******************//
    if(selectOptions.isEmpty())
    {
      selectOptions.add(option);
    }else
    {
      selectOptions.add(0, option);
    }
    //Old logic:
    //selectOptions.add(0, option);
    //************ changes July 2017 *******************//
     
     return selectOptions;
   }
   
   /*
     Creates an outer map keyed by filter field containing a map keyed by each filter value
     with a List of the Quote parts that match that filter value. The full set of Quote Parts
     are indexed.
   */
   private void createPartByFilterValueMap()
   {
     quotePartsByFilterValue = new Map<String, map<String, List<Quote_Part__c>>>();
     // create empty child maps for every filter value
     for (String s : filterValueByFieldMap.keySet())
     {
       quotePartsByFilterValue.put(s, new map<String, List<Quote_Part__c>>());
     }
     
     // iterate over the quote parts and add each one into every map that applies
     for (Quote_part__c qp : quoteParts)
     {
       // for each filter add the quote part to the map for the filter
       for (String fieldName : filterValueByFieldMap.keyset())
       {
         for (SelectOption fieldValue : filterValueByFieldMap.get(fieldName))
         {
           String value = GetFieldForRelationshipPath(qp, fieldName);
           
           if (value != null)
           {
             if (quotePartsByFilterValue.get(fieldName).get(value) == null)
             {
               quotePartsByFilterValue.get(fieldName).put(value, new List<Quote_part__c>());
             }
             quotePartsByFilterValue.get(fieldName).get(value).add(qp);
           }
         }
       }
     }
   }
   
   /*
     Regenerate the filters when the quote parts in scope change but the faceted components have all been added
   */
   private void GetFilterValues(List<Quote_Part__c> quoteParts)
   {
     filterValueByFieldMap.put('Product_Name__c', productNames);
     filterValueByFieldMap.put('Quote_Product__r.Site_Name__c', siteNames);
     filterValueByFieldMap.put('Phase__c', phases);
     filterValueByFieldMap.put('FeeType__c', feeTypes);
     /*// clear down the existing maps
     for ( bg_FacetedSearchComponent c : facetedSearchComponentMap.Values())
     {
       filterValueByFieldMap.get(c.getParamKey()).clear();
     }
     
     
     for (Quote_Part__c qp : quoteParts)
     {
       // build a set of values for each filter
       for ( bg_FacetedSearchComponent c : facetedSearchComponentMap.Values())
       {         
         /*Object fieldValue = qp.get(s);

         */
        /*String fieldValue = GetFieldForRelationshipPath(qp, c.getParamKey());
        
        if (fieldValue != null)
         {
           SelectOption selectOption = new SelectOption((String)fieldValue, (String)fieldValue);
           filterValueByFieldMap.get(c.getParamKey()).add(selectOption);
         }
       }
     }*/
   }
   
   /*
     Add a new search component
   */
   private void getFilterValues(List<Quote_Part__c> quoteParts, bg_FacetedSearchComponent component)
   {
    filterValueByFieldMap.put('Product_Name__c', productNames);
     filterValueByFieldMap.put('Quote_Product__r.Site_Name__c', siteNames);
     filterValueByFieldMap.put('Phase__c', phases);
     filterValueByFieldMap.put('FeeType__c', feeTypes);
     /*for (Quote_Part__c qp : quoteParts)
     {
      String fieldValue = GetFieldForRelationshipPath(qp, component.getParamKey());
        
      if (fieldValue != null)
       {
         SelectOption selectOption = new SelectOption((String)fieldValue, (String)fieldValue);
         filterValueByFieldMap.get(component.getParamKey()).add(selectOption);
       }
     }*/
   }
   
   /*
    Clear all of the filters on all of the components
  */
  public void removeFilters()
  {
    Id quoteId = ApexPages.currentPage().getParameters().get(bg_QuoteUtils.URL_PARAM_QUO_ID);
    GetFilterValues(quoteParts);
    ClearProducts();
    // Iterate over all component controllers
    for (bg_FacetedSearchComponent c : facetedSearchComponentMap.values())
    {
      c.resetFilters();
    }
    
    if(applyFilter)
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFo, System.Label.TooManyQuotePartsWarning));
    else
        LoadQuotePartData(quoteId, null, null, null, null); 
    /*integer maxGridParts = integer.valueOf(bg_CustomSettingsUtils.GetSystemSettings().QuotePartGridMaxParts__c);
    if(quoteParts.size() > maxGridParts) {
      ClearProducts();
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.TooManyQuotePartsWarning));
    } 
    else
    {
      BuildWrappers(new List<Quote_Part__c>(quoteParts));
    }
  
    CalculateGrandTotals(); // while the filters were applied a change eg discount may have been applied*/
  
  }
  
  /*
    Apply the filters to the full set of Quote Parts 
  */
  public void applyFilters()
  {
    Id quoteId = ApexPages.currentPage().getParameters().get(bg_QuoteUtils.URL_PARAM_QUO_ID);
    
    List<String> productNames = new List<String>();
    
    if(facetedSearchComponentMap.get('Quote_Part__cProduct_Name__c').getSelectedItems() != null)
        for(String s: facetedSearchComponentMap.get('Quote_Part__cProduct_Name__c').getSelectedItems()) {
            if(s != null && s.indexOf(' : ') > 1)
                productNames.add(s.split(' : ')[1]);
            else        
                productNames.add(s);
        }
    
    LoadQuotePartData(quoteId, productNames, 
        facetedSearchComponentMap.get('Quote_Part__cQuote_Product__r.Site_Name__c').getSelectedItems(),
        facetedSearchComponentMap.get('Quote_Part__cPhase__c').getSelectedItems(),
        facetedSearchComponentMap.get('Quote_Part__cFeeType__c').getSelectedItems());
    
    /*Set<Quote_Part__c> quotePartsToDisplay = new Set<Quote_Part__c>(quoteParts);
    
    // ask each filter for it's current values and build a set of Quote Parts that match that filter
    for (bg_FacetedSearchComponent c : facetedSearchComponentMap.values())
    {
      Set<Quote_Part__c> matchingPartsForThisFilter = new Set<Quote_Part__c>();
      if (c.getSelectedItems() != null && c.getSelectedItems().size() > 0)
      {
        for (string s : c.getSelectedItems())
        {
          matchingPartsForThisFilter.addAll(quotePartsByFilterValue.get(c.getParamKey()).get(s));
        }
        // now remove the Quote Parts that do not match this filter
        quotePartsToDisplay.retainAll(matchingPartsForThisFilter);
      }
    }
    
    integer maxGridParts = integer.valueOf(bg_CustomSettingsUtils.GetSystemSettings().QuotePartGridMaxParts__c);
    if(quotePartsToDisplay.size() > maxGridParts) {
      ClearProducts();
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.TooManyQuotePartsWarning));
    } 
    else
    {
      BuildWrappers(new List<Quote_Part__c>(quotePartsToDisplay));
      GetFilterValues(new List<Quote_Part__c>(quotePartsToDisplay));
    }*/
  }
  
  private static String GetFieldForRelationshipPath(sObject objectToQuery, String fieldPath)
  {
    
     /** @TODO refactor - similar loop in wrapper helper */
     String returnVal = null;
     String[] pathArray = fieldPath.split('\\.');

     Object objectToReturn = null; // use Object to avoid casting at this stage 
    sObject objectForGet = objectToQuery;
    String fieldName = fieldPath;
    for (Integer i = 0; i < pathArray.size() -1; i++) 
    {
      objectForGet = objectForGet.getSobject(pathArray[i]);
          
      if ( objectForGet == null)
      {
        // relationship not populated so break and return null for target field
        break;
      }
    }
    if(null != objectForGet)
    {
      returnVal = (String)objectForGet.get(pathArray[pathArray.size() - 1]);
    }
    return returnVal;
  }

  
  private static SelectOption GetSelectOptionForFieldPath(String objectToQuery, String fieldPath)
  {
    Schema.SObjectType containingObject = GetObjectForFieldPath(objectToQuery, fieldPath);
    String fieldName = (fieldPath.lastIndexOf('.') == -1) ? fieldPath : fieldPath.substring(fieldPath.lastIndexOf('.') + 1);
    
    Schema.SObjectType targetType = GetObjectForFieldPath(objectToQuery, fieldPath);
    Map<String, Schema.SObjectField> fieldMap = targetType.getDescribe().fields.getMap();
    
    String fieldLabel = 'Select ' + fieldMap.get(fieldName).getDescribe().getLabel();
    return (new SelectOption(fieldLabel, fieldLabel));
    
  }
      
  private static Schema.SObjectType GetObjectForFieldPath(String objectToQuery, String fieldPath)
  {
    String[] pathArray = fieldPath.split('\\.');
    Schema.SObjectType targetType = Schema.getGlobalDescribe().get(objectToQuery);

    for (Integer i = 0; i < pathArray.size() -1; i++) 
    {  

      String fieldName = (pathArray[i].lastIndexOf('__r') == -1) ? pathArray[i] : pathArray[i].substring(0, pathArray[i].length() - 3) + '__c';
            
      Map<String, Schema.SObjectField> fieldMap = targetType.getDescribe().fields.getMap();
      targetType = fieldMap.get(fieldName).getDescribe().getReferenceTo()[0];
    }
    
    return targetType;
  }
  
  public List<SelectOption> getReferenceSettings()
  {
    if (referenceSettings == null)
    {
      referenceSettings = new List<SelectOption>();
      referenceSettings.add(new SelectOption('Select Reference Setting', 'Select Reference Setting'));
      //referenceSettings.add(new SelectOption('Currency', 'Currency'));
      referenceSettings.add(new SelectOption('Discount', 'Discount'));
      //referenceSettings.add(new SelectOption('Pricebook', 'Pricebook'));
      referenceSettings.add(new SelectOption('Sales Price', 'Sales Price'));
    }
    return referenceSettings;
  }
  /*
    If the selected bundle action has a dependent picklist then this method builds it 
  */  
  public List<SelectOption> getBundleActionOptions()
  {
    
    if (selectedReferenceSetting == Label.bg_Bundle_Action_Discount)
    {  
      bundleActionOptions = new List<SelectOption>();
      bundleActionOptions.add(new SelectOption('Value', 'Value'));
      bundleActionOptions.add(new SelectOption('%', '%'));
    }
    return bundleActionOptions;
  }
  
  /*
    Apply the bundle action to all of the rows in the filter's scope that still have the apply action checkbox ticked
  */
  public PageReference applyBundleAction() 
  {
    for (ProductWrapper pw : ProductWrappers)
    {
      for (SiteWrapper sw : pw.SiteWrappers)
      {
        for (QuotePartWrapper qpw : sw.QuotePartWrappers)
        {
          // has the row been exempted by unchecking the bundle action checkbox
          if (qpw.includeInBundleAction)
          {
            if (selectedReferenceSetting == Label.bg_Bundle_Action_Discount)
            {
              if (selectedBundleActionOption == '%' )
              {
                qpw.QuotePart.Discount_Percentage__c = bundleActionAmount;
              }
              else
              {
                qpw.DiscountAmount = bundleActionAmount;
              }
              CalculateGrandTotals();
            }
            
            if (selectedReferenceSetting == Label.bg_Bundle_Action_Sales_Price)
            {
              qpw.Price = bundleActionAmount;
            }
          }
          
        }
      }
    }
    
    // reset the bundle action fields
    //selectedReferenceSetting = Label.bg_Bundle_Action_Default;
    
    return null;  
  }
  
  public List<SelectOption> getDiscountDisplayOptions()
  {
    if (discountDisplayOptions == null)
    {
      discountDisplayOptions = new List<SelectOption>();
      discountDisplayOptions.add(new SelectOption(Label.bg_Discount_Option_Value, Label.bg_Discount_Option_Value));
      discountDisplayOptions.add(new SelectOption(Label.bg_Discount_Option_Percent, Label.bg_Discount_Option_Percent));
    }
    return discountDisplayOptions;
  }  
  
  public void resetBundleActionFields()
  {
    bundleActionAmount = null;
  }
  
  // Wrapper to sort the pricebooks
  public class PricebookWrapper implements Comparable {
    public String Id  {get; set;}
    public String fullName {get; set;}
    public String Name {get; set;}
    public Integer Year {get; set;}
    
    public PricebookWrapper(String Id, String Name, Integer Year){
      this.Id = Id;
      this.fullName = Name;
      this.Name = Name.substring(0, Name.lastIndexOf(' '));
      this.Year = Year;
    }
    
    public Integer compareTo(Object obj) {
      PricebookWrapper o = (PricebookWrapper)obj;
      
      if(Name == o.Name) {
        if (Year == o.Year){return 0;}
            if (Year < o.Year) {return 1;}

            return -1;
      } else {
        return Name.compareTo(o.Name);
      }
    }
  }
  
  
  //If Quote Parts are more than 100 do not show filters as its causing Apex Heap issues 
  public boolean getCanShowFilter() {
    return !(quoteParts.size() > 500);
  }
      
}