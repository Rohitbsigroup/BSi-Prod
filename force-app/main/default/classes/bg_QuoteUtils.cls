/********************************************************************
 * bg_QuoteUtils
 *
 * Utility methods to support Quote functions
 *
 *
 * Author: Richard Jimenez
 * Created: 02-09-2013
 * Changes: 02-10-2014 KM - Added method reset quote stages to allow
 *                          the customer to return to the first stage
 *          06-10-2014 RJ - Updated to use new QuoteV3 and NewQuoteGridV2 pages
 *          12-11-2014 KM - Added method GetMainQuote
 *                          Overloaded InternalCloneQuote, CloneQuote and CloneQuoteProducts
 *          06-11-2014 RJ - Add Multi-Instance configurator support
 *          06-05-2015 KM - Refactored QuotesSigned and ValidationComplete methods from doc utils
 *          06-07-2015 RJ - Added SiteEmployees__c field to CloneQuoteProducts
 *          20-07-2015 RJ - Added Operations Review
 *          24-02-2016 KM - Added Sync Error Message
 *          25-07-2016 JA - Added SetOfflineSignedQuoteToMainQuote
 *                          Updated SetMainQuotes to work in update triggers
 *          03-11-2016 ADS - SoW027
 *                         - Added Operations_Approval_Queue__c to list of fields retrieved in GetQuoteByIds
 *                         - Removed use of and references to Operations Team Approver
 *          15-11-2016 JT  - Added QuoteLanguage__c to list of fields retrieved in GetQuoteByIds (Case 27420)
 *          07-07-2017 IB - Return Phase and FeeType to GetQuoteParts to support Product Price filtering 
 *          10-07-2017 MJ - Updated to allow Registration Path to be blank for non-assurance products
 *          18-07-2017 IB - Add project__c to SaveQuoteProducts() and GetQuoteProducts() for PS implementation
 *          20-07-2017 SS - Added update quote functionality UpdateQuoteByLocationId() for swapping controlling location picklist values. 
 *      25-08-2107 IB - UAT fix - exclude Phase Quote Products from query to mark as unconfigured
 *          31/08/2017 ADS - Production Classification Fields; Division, Portoflio, Sector, Stream and Theme are now picklists
 *			11/09/2017 IB - New version of BuildQuoteBuilderURL() allowing edit mode param
 *          15/09/2017 RC - added extra check for training products.
 *          18/09/2017 RC - added extra fields to getQuote query, added extra funtion ResetPsProposalApprovalFields to
 *                          reset fields on the quote which are part of Proposal approval for PS users
 *          02/10/2017 RC - changed the way quote products were saved.
 *          03/10/2017 ADS - added UpdateQuoteRegPathFlags for a list of Quote Products
 *          26-02-2018 AV - GetQuoteByIds (Method) - Add "Configuration Completed" field on the query.
 ********************************************************************/
public class bg_QuoteUtils {

    public static string VF_PAGENAME_NEWQUOTE = 'QuoteBuilder';
    public static string VF_PAGENAME_NEWQUOTEGRID = 'QuoteBuilder';
    public static string VF_PAGENAME_QUOTEPARTGRID = 'QuotePartGrid';

    public static final string DEFAULT_TYPE_INITIAL_QUOTE = 'Initial Quote';
    public static final string QUOTE_STATUS_OPEN = 'Open';

    public static final string QUOTE_DISCOUNT_STATUS_NOT_SUBMITTED = 'Not Submitted';
    public static final string QUOTE_DISCOUNT_STATUS_PENDING = 'Pending';

    public static final string QUOTE_FINANCE_STATUS_PENDING = 'Pending';
    public static final string QUOTE_FINANCE_STATUS_NOT_SUBMITTED = 'Not Submitted';

    public static final string QUOTE_OPERATIONS_STATUS_PENDING = 'Pending';

    public static final string QUOTE_PS_PROPOSAL_STATUS_PENDING = 'Pending';


    public static final integer SYNC_STATUS_RUNNING = 1;
    public static final integer SYNC_STATUS_COMPLETE = 0;
    public static final integer SYNC_STATUS_ERROR = -1;

    public static final string DEFAULT_REGPATH_NONASSURANCE = 'Not Applicable';

    public static final String SYNC_ERROR_MESSAGE = Label.Sync_Error_Message;

    public static boolean recursiveFlag = false;

    public class QuoteException extends Exception {}
    public class QuoteSyncException extends Exception {}

    public static Quote__c GetNewQuote(Id accId, Id oppId) {
        Opportunity opp = bg_OpportunityUtils.GetOpportunityById(oppId);
        return GetNewQuote(accId, opp);
    }

    public static Quote__c GetNewQuote(Id accId, Opportunity opp) {

        boolean isMultiSite = false;
        boolean isTransient = false;
        boolean isNetwork = false;
        OpportunitySite__c hqSite;

        // Get opportunity sites
        list<OpportunitySite__c> oppSites = bg_SiteUtils.GetOpportunitySites(opp.Id);

        integer multiSiteCount = 0;
        for(OpportunitySite__c oppSite : oppSites) {
            if (oppSite.Site__r.RecordType.DeveloperName == bg_SiteUtils.RECORD_TYPE_NAME_NETWORK) {
                isNetwork = true;
            }
            else if (oppSite.Site__r.RecordType.DeveloperName == bg_SiteUtils.RECORD_TYPE_NAME_TRANSIENT) {
                isTransient = true;
            } else {
                multiSiteCount++;
            }

            if (oppSite.HQ__c) { hqSite = oppSite; }
        }

        // Set multisite flag
        isMultiSite = (multiSiteCount > 1);

        // Return net Quote
        return GetNewQuote(accId, opp, isMultiSite, isTransient, isNetwork, hqSite);
    }

    public static Quote__c GetNewQuote(Id accId, Opportunity opp,
                                boolean isMultiSite, boolean isTransient, boolean isNetwork,
                                OpportunitySite__c hqSite) {
        /*
            Return a new quote
        */
        Quote__c newQuote = new Quote__c();
        newQuote.Account__c = accId;
        newQuote.Opportunity_Name__c = opp.Id;
        newQuote.Quote_Date__c = Date.today();
        newQuote.Type__c = DEFAULT_TYPE_INITIAL_QUOTE;
        newQuote.Status__c = QUOTE_STATUS_OPEN;
        newQuote.Transient__c = isTransient;
        newQuote.Network__c = isNetwork;
        newQuote.ScopeOfRegistration__c = opp.ScopeofRegistration__c;
        newQuote.RegistrationPath__c = opp.RegistrationPath__c;

        // Set quote ISO Code to match opportunity
        newQuote.CurrencyIsoCode = opp.CurrencyIsoCode;

        if(opp.PrimaryContact__c != null) {
            newQuote.Contact__c = opp.PrimaryContact__c;
        }

        newQuote.PriceBook2Id__c = bg_PricebookUtils.GetUserDefaultPricebook().Id;
        newQuote.UseSiteContactDefaults__c = true;

        // check hqSite
        if(hqSite != null) {
            // Set quote finance director
            if(bg_CustomSettingsUtils.GetDefaultCountrySettings(hqSite.Site__r.Country_Code__c) != null) {
                newQuote.Finance_Director__c = bg_CustomSettingsUtils.GetDefaultCountrySettings(hqSite.Site__r.Country_Code__c).Finance_Director__c;
            }

            newQuote.Street__c = hqSite.Site__r.Street__c;
            newQuote.City__c = hqSite.Site__r.City__c;
            newQuote.State__c = hqSite.Site__r.State__c;
            newQuote.Country__c = hqSite.Site__r.Country__c;
            //newQuote.Country_Code__c = hqSite.Site__r.Country_Code__c;
            newQuote.Postcode__c = hqSite.Site__r.Postcode__c;

            newQuote.Booking__c = bg_ContactUtils.GetDefaultContactId(newQuote, hqSite.Id, newQuote.Contact__c, bg_ContactUtils.CONTACT_SITE_ROLE_BOOKING);
            newQuote.CreditCheck__c = bg_ContactUtils.GetDefaultContactId(newQuote, hqSite.Id, newQuote.Contact__c, bg_ContactUtils.CONTACT_SITE_ROLE_CREDIT_CHECK);
            newQuote.Invoice_Contact__c = bg_ContactUtils.GetDefaultContactId(newQuote, hqSite.Id, newQuote.Contact__c, bg_ContactUtils.CONTACT_SITE_ROLE_INVOICE);
        }
        return newQuote;
    }

    public static void SetFinanceDirector(Quote__c quote) {
        /*
            Set Finance Approver
        */
        OpportunitySite__c hqSite = bg_SiteUtils.GetOpportunityHQSite(quote.Opportunity_Name__c);
        SetFinanceDirector(quote, hqSite);
    }

    public static void SetFinanceDirector(Quote__c quote, OpportunitySite__c hqSite) {
        /*
            Set Finance Approver
        */
        if(bg_CustomSettingsUtils.GetDefaultCountrySettings(hqSite.Site__r.Country_Code__c) != null) {
            quote.Finance_Director__c = bg_CustomSettingsUtils.GetDefaultCountrySettings(hqSite.Site__r.Country_Code__c).Finance_Director__c;
        }
    }

    /*
        Set Operations Review Approver
    */
    public static void SetOperationsReviewApprover(Quote__c quote, Map<Id, User> userMap)
    {
        quote.OperationsTeamApprover__c = userMap.get(quote.OwnerId).OperationsTeamApprover__c;
    }

    public static Quote__c GetQuoteById(Id quoteId) {
        /* Return Quote by Id */
        return GetQuoteById(quoteId, false);
    }

    public static Quote__c GetQuoteById(Id quoteId, boolean full) {
        /* Return Quote by Id */
        return GetQuoteByIds(new set<Id>{quoteId}, full)[0];
/*
        string fieldList = 'Id, Name, OwnerId, Account__c, Opportunity_Name__c, Network__c, Transient__c, Contact__c, Invoice_Contact__c, Booking__c, CreditCheck__c, ' +
                            'PriceBook2Id__c, UseSiteContactDefaults__c, UseLocalPrices__c, RegistrationPath__c, Finance_Director__c, CurrencyIsoCode, ' +
                            'VF_ShowProductSearch__c, VF_ShowSelectionSummary__c, VF_ShowSiteSummary__c, IMS_Complete__c';
        // return full quote fields?
        if(full) {
            fieldList += ', ValidationStatus__c, DiscountStatus__c, CCodeStatus__c, Account__r.BillingCountry, Total_Price__c, ' +
                                'Salesman__c, Expiry_Type__c, Expiry_Days__c, ProposalSignedOffline__c, ' +
                                'OneScopeSystem__c, MoreCertificate__c, ExpireDate__c, ParentQuote__c, SentDate__c, ' +
                                'ManagerDiscount__c, DirectorDiscount__c, Proposal_Scope__c, Owner.Email, SkipTargetDate__c, SkipCustomer__c, SkippedDate__c, SkippedBy__c, ' +
                                'ValidationDate__c, ValidationCheck__c, ValidatedBy__c, Opportunity_Name__r.Name, SkipTechReview__c, SkippedTechReviewDate__c, SkippedTechReviewBy__c, ' +
                                'ConsultantInvolved__c, ConsultantName__c, OutsourcingDetails__c, Outsourcing__c, WholeCertAdvised__c, ScopeOfRegistration__c, ' +
                                'DiscountDateTimeSubmitted__c, DiscountDateTimeDeclined__c, DiscountDateTimeApproved__c, ' +
                                'Street__c, City__c, Postcode__c, State__c, Country__c, Tech_Review_Team__c, ' +
                                'FinanceDateTimeSubmitted__c, FinanceDateTimeDeclined__c, FinanceDateTimeApproved__c, FinanceStatus__c, ' +
                                'Total_Price_Year_3__c, Total_Opportunity_Amount__c, FinanceApprover__c ';
        }
        // build query string
        string query = 'SELECT ' + fieldList + ' FROM Quote__c WHERE Id = :quoteId' ;
        // run query
        return database.query(query);
*/
    }

    public static list<Quote__c> GetQuoteByIds(set<Id> quoteIds) {
        /* Return Quote by Id */
        return GetQuoteByIds(quoteIds, false);
    }

    public static list<Quote__c> GetQuoteByIds(set<Id> quoteIds, boolean full) {
        /*
            Return Quotes by Id
        */
        string fieldList = 'Id, Name, OwnerId, Main_Quote__c, Account__c, Account__r.Name, Opportunity_Name__c, Network__c, Transient__c, Contact__c, Invoice_Contact__c, Booking__c, CreditCheck__c, ' +
                            'PriceBook2Id__c, UseSiteContactDefaults__c, UseLocalPrices__c, RegistrationPath__c, Finance_Director__c, CurrencyIsoCode, ' +
                            'VF_ShowProductSearch__c, VF_ShowSelectionSummary__c, VF_ShowSiteSummary__c, IMS_Complete__c, QuoteLanguage__c';
        // return full quote fields?
        if(full) {
            fieldList += ', ValidationStatus__c, DiscountStatus__c, CCodeStatus__c, Account__r.BillingCountry, Total_Price__c, Total_Price_Discount__c, ' +
                                'Salesman__c, Expiry_Type__c, Expiry_Days__c, ProposalSignedOffline__c, ' +
                                'OneScopeSystem__c, MoreCertificate__c, ExpireDate__c, ParentQuote__c, SentDate__c, ' +
                                'ManagerDiscount__c, DirectorDiscount__c, Proposal_Scope__c, Owner.Email, SkipTargetDate__c, SkipCustomer__c, SkippedDate__c, SkippedBy__c, ' +
                                'ValidationDate__c, ValidationCheck__c, ValidatedBy__c, Opportunity_Name__r.Name, SkipTechReview__c, SkippedTechReviewDate__c, SkippedTechReviewBy__c, ' +
                                'ConsultantInvolved__c, ConsultantName__c, OutsourcingDetails__c, Outsourcing__c, WholeCertAdvised__c, ScopeOfRegistration__c, ' +
                                'OperationsToSendProposal__c, OperationsDateTimeSubmitted__c, OperationsDateTimeDeclined__c, OperationsDateTimeApproved__c, OperationsReviewStatus__c, ' +
                                'DiscountDateTimeSubmitted__c, DiscountDateTimeDeclined__c, DiscountDateTimeApproved__c, ' +
                                'Street__c, City__c, Postcode__c, State__c, Country__c, Tech_Review_Team__c, Configuration_Completed__c,' +
                                'FinanceDateTimeSubmitted__c, FinanceDateTimeDeclined__c, FinanceDateTimeApproved__c, FinanceStatus__c, ' +
                                'Total_Price_Year_3__c, Total_Opportunity_Amount__c, FinanceApprover__c, Is_Clonable__c, ' +
                                'Discount_PreApprover_1__c, Discount_Approver_1__c, Discount_Approver_2__c, Discount_Approver_3__c, Discount_Approver_4__c, Discount_Approver_5__c, ' +
                                'Discount_PreApprover_1__r.Name, Discount_Approver_1__r.Name, Discount_Approver_2__r.Name, Discount_Approver_3__r.Name, Discount_Approver_4__r.Name, Discount_Approver_5__r.Name, ' +
                                'Opportunity_Name__r.Can_Send_Proposal__c, PS_Proposal_Approval_Status__c, PS_Proposal_Approval_User__c, PS_Proposal_Approver__c, PsProposalDateTimeApproved__c, ' +
                                'Operations_Approval_Queue__c, PsProposalDateTimeDeclined__c, PsProposalDateTimeSubmitted__c';
        }
        // build query string
        string query = 'SELECT ' + fieldList + ' FROM Quote__c WHERE Id = :quoteIds' ;
        // run query
        return database.query(query);
    }

    public static Quote_Part__c GetQuoteQuestionPart(Id quoteId, string productName, integer instance) {
        /*
            Return Quote Question Part
        */

        Quote_Part__c qp;
        try {
            string partProductName = productName + bg_ProductUtils.QUESTION_PRODUCT_POSTFIX;
            qp = [SELECT Id, Price__c
                    FROM Quote_Part__c
                    WHERE Quote_Ref__c = :quoteId
                        AND Product_Name__c = :partProductName
                        AND IsQuestion__c = true
                        AND Quote_Product__r.Instance__c = :instance];
        } catch(exception e) {}
        return qp;
    }

    public static Quote_Part__c GetQuoteQuestionPart(Id quoteId, string productName) {
        /* Return Quote Question Part */
        return GetQuoteQuestionPart(quoteId, productName, null);
    }

    public static list<Quote_Product__c> GetQuoteProducts(Id quoteId) {
        /* Return list of quote products */
        return GetQuoteProducts(quoteId, false);
    }

    public static list<Quote_Product__c> GetQuoteProducts(Id quoteId, boolean selectedOnly) {
        /* Return list of quote products */
        return GetQuoteProducts(quoteId, false, null, null);
    }

    public static list<Quote_Product__c> GetQuoteProducts(Id quoteId, boolean selectedOnly, string productType) {
        /* Return list of quote products */
        return GetQuoteProducts(new set<Id>{quoteId}, false, productType, null);
    }

    public static list<Quote_Product__c> GetQuoteProducts(Id quoteId, boolean selectedOnly, string productType, string productName) {
        /* Return list of quote products */
        return GetQuoteProducts(new set<Id>{quoteId}, false, productType, productName);
    }

    public static map<Id, list<Quote_Product__c>> GetQuoteProductsMap(set<Id> quoteIds, boolean selectedOnly, string productType) {
        /* Return list of quote products */
        map<Id, list<Quote_Product__c>> quoteProductMap = new map<Id, list<Quote_Product__c>>();
        list<Quote_Product__c> quoteProducts = GetQuoteProducts(quoteIds, false, productType, null);
        for(Quote_Product__c qp : quoteProducts) {
            if(!quoteProductMap.containsKey(qp.Quote_Ref__c)) {
                quoteProductMap.put(qp.Quote_Ref__c, new list<Quote_Product__c>());
            }
            quoteProductMap.get(qp.Quote_Ref__c).add(qp);
        }
        return quoteProductMap;
    }

    public static map<Id, set<string>> GetMainQuoteProductNameMap(set<Id> quoteIds, boolean selectedOnly, string productType) {
        /* Return list of main quote products name map */
        map<Id, set<string>> quoteProductMap = new map<Id, set<string>>();
        list<Quote_Product__c> quoteProducts = GetQuoteProducts(quoteIds, false, productType, null);
        for(Quote_Product__c qp : quoteProducts) {
            if(!quoteProductMap.containsKey(qp.Quote_Ref__c)) {
                quoteProductMap.put(qp.Quote_Ref__c, new set<string>());
            }
        	quoteProductMap.get(qp.Quote_Ref__c).add(qp.Product_Name__r.Main_Product_Name__c);
        }
        return quoteProductMap;
    }

    public static list<Quote_Product__c> GetQuoteProducts(set<Id> quoteIds, boolean selectedOnly, string productType, string productName) {
        /* Return list of quote products */
        return GetQuoteProducts(quoteIds, selectedOnly, productType, productName, false);
    }

    public static list<Quote_Product__c> GetQuoteProducts(Id quoteId, boolean selectedOnly, string productType, string productName, boolean orderBySite) {
        /* Return list of quote products */
        return GetQuoteProducts(new set<Id>{quoteId}, selectedOnly, productType, productName, orderBySite);
    }

    public static list<Quote_Product__c> GetQuoteProducts(set<Id> quoteIds, boolean selectedOnly, string productType, string productName, boolean orderBySite) {
        /*
            Return list of quote products
        */
        list<Quote_Product__c> quoteProducts = new list<Quote_Product__c>();
        set<string> productTypes = new set<string>();

        // Add product Types
        if(productType == null) {
            productTypes = new set<string>{bg_ProductUtils.PRODUCT_TYPE_MAIN, bg_ProductUtils.PRODUCT_TYPE_SITE};
        } else {
            productTypes = new set<string>{productType};
        }

        string query = 'SELECT Id, Quote_Ref__c, Name, Product_Name__c, Product_Name__r.Name, Instance__c, Product_Name__r.AllowMultipleInstances__c, Product_Name__r.ShowClassificationName__c, Product_Name__r.Product_Type__c, Site_Name__c, FileUploaded__c, ' +
                                'Product_Name__r.RecordType.Name, Product_Name__r.Product_Classification__r.Stream2__c, Product_Name__r.Sampling_Threshold__c, Product_Name__r.Sampling_Rule__c, Product_Name__r.Sampling1inN__c, ' +
                                'Registration_Path__c, CurrencyIsoCode, Price_Book__c, Price_Book_Name__c, Secondary_Price_Book__c, Selected__c, Product_Name__r.CCode__c, ' +
                                'Site__c, Opportunity_Site__c, Opportunity_Site__r.Type__c, Site__r.Name, Risk_Level__c, Calculated_Risk_Level__c, ' +
                                'Sampling_Applied__c, Sampling_Available__c, Sampling_Verified__c, Included_in_IMS__c, Configuration_Complete__c, ' +
                                'Primary_Contact__c, Booking_Contact__c, Credit_Check_Contact__c, Invoice_Contact__c, Product_Name__r.Main_Product_Name__c, ' +
                                'Product_Classification__c, Product_Classification__r.Stream2__c, Product_Classification__r.Product__c, Product_Classification__r.Standard__c, Product2__c, ' +
                                'Product2__r.Name, Product2__r.RequiresContractReview__c, Product2__r.Division__c, ' +
                                'Product_Classification__r.Standard__r.Name, Product_Classification__r.Standard__r.RequiresContractReview__c, Product_Classification__r.Standard__r.Division__c, GroupNumber__c, Product_Name__r.GridView__c, ' +
                                'Project__c, Project__r.ProductId__r.Main_Product_Name__c, Project__r.Name, Project__r.RecordType.Name ' +
                            'FROM Quote_Product__c '+
                            'WHERE Quote_Ref__c IN :quoteIds '+ 
                            'AND Is_Project_Phase__c = false ';

        // Selected Only
        if(selectedOnly) { query += 'AND Selected__c = :selectedOnly '; }
        // Product Name
        if(!bg_StringUtils.IsBlank(productName)) { query += 'AND (Product_Name__r.Main_Product_Name__c = :productName OR Project__r.ProductId__r.Main_Product_Name__c = :productName)'; }
        // Product types
        query += 'AND Product_Name__r.Product_Type__c IN :productTypes ';

        // Exclude Quote products where the site has been deleted
        query += 'AND Opportunity_Site__c != null ';
        query += 'AND Deleted__c = false ';

        // ORDER BY Product Name, HQ, Site Type and Site Name
        if(orderBySite) {
            query += 'ORDER BY Opportunity_Site__r.HQ__c DESC, Site_Name__c ASC ';
        } else {
            query += 'ORDER BY Product_Name__r.Main_Product_Name__c, Opportunity_Site__r.HQ__c DESC, Opportunity_Site__r.SiteType__c ASC, Opportunity_Site__r.SiteName__c ASC ';
        }

        quoteProducts.addAll((list<Quote_Product__c>)database.query(query));

        return quoteProducts;
    }

    public static list<Quote_Part__c> GetQuoteParts(Id quoteId) {
        /* Return list of quote parts */
        return GetQuoteParts(quoteId, false);
    }

    public static list<Quote_Part__c> GetQuoteParts(Id quoteId, boolean discountOnly) {
        /* Return list of quote parts */
        return GetQuoteParts(quoteId, discountOnly, null);
    }

    public static list<Quote_Part__c> GetQuoteParts(Id quoteId, string quoteProductId) {
        /* Return list of quote parts */
        return GetQuoteParts(quoteId, false, null, quoteProductId);
    }

    public static list<Quote_Part__c> GetQuoteParts(Id quoteId, boolean discountOnly, set<string> products) {
        /* Return list of quote parts */
        return GetQuoteParts(quoteId, discountOnly, products, null);
    }

    public static list<Quote_Part__c> GetQuoteParts(Id quoteId, boolean discountOnly, set<string> products, string quoteProductId) {
        /* Return list of quote parts */
        return GetQuoteParts(quoteId, discountOnly, products, quoteProductId, null);
    }

    public static list<Quote_Part__c> GetQuoteParts(Id quoteId, string product, string siteId) {
        /* Return list of quote parts */
        set<string> products = new set<string>();
        if(!bg_StringUtils.IsBlank(product)) {
            products.add(product);
        }
        return GetQuoteParts(quoteId, false, products, null, siteId);
    }

    public static list<Quote_Part__c> GetQuoteParts(Id quoteId, boolean discountOnly, set<string> products, string quoteProductId, string siteId) {
        /*
            Return list of quote parts
        */
        string query = 'SELECT Name, Number__c, Description__c, Customer_Code__c, IsDiscountable__c, Country_Code__c, BOMOrder__c, Exchange_Rate__c, ' +
                                'True_discount__c, Converted_list_Price__c, Quote_Ref__r.Account__c, Cost__c, List_Price__c, Discount_Percentage__c, Price__c, Total_Price__c, Product_Name__c, Info__c, IsTraining__c, ' +
                                'Total_Price_In_Currency__c, Quote_Product__r.Site__c, Quote_Product__r.Site__r.Name, Product2__r.IsPriceCalculated__c, ' +
                                'Quote_Product__r.Site__r.Country__c, CurrencyIsoCode, Price_Book__c, Product2__c, Quote_Product__r.Price_Book__c, ' +
                                'PrimaryPricebookId__c, SecondaryPricebookId__c, Quote_Ref__c, Notes__c, IsPartBuilder__c, Round_Discount_Amount__c , Phase__c, FeeType__c, ' +
                                'Quote_Product__r.Is_Project_Phase__c, Quote_Product__r.Project_Name__c, Pricing_Configured__c, Location__c, True_Discount_Amount__c, InfoVal3__c, Product2__r.Course_Country__c, ' +
                                'ProjectProductName__c, Project__r.Name, Quote_Product__r.Product_Name__r.RecordType.Name, SiteName__c, Quote_Product__r.Site_Name__c, Quote_Product__r.ProjectSiteCountry__c ' +
                       'FROM Quote_Part__c ' +
                       'WHERE Quote_Ref__c = :quoteId '  +
                                'AND IsQuestion__c = false ';
        // Discount only prodicts
        if(discountOnly) {
            query += 'AND IsDiscountable__c = :discountOnly ';
        }

        // Product names
        if(products != null && !products.isEmpty()) {
            query += 'AND Product_Name__c IN :products ';
        }

        if(!bg_StringUtils.IsBlank(quoteProductId)) {
            query += 'AND Quote_Product__c = :quoteProductId ';
        }

        if(!bg_StringUtils.IsBlank(siteId)) {
            query += 'AND Quote_Product__r.Site__c = :siteId ';
        }

        // ORDER BY
        query += 'ORDER BY Product_Name__c, BOMOrder__c ';

        return database.query(query);
    }
    
    public static list<Quote_Part__c> GetQuoteParts(Id quoteId, boolean discountOnly, List<string> products, List<string> siteId, List<string> phases, List<string> feeTypes) {
        /*
            Return list of quote parts
        */
        string query = 'SELECT Name, Number__c, Description__c, Customer_Code__c, IsDiscountable__c, Country_Code__c, BOMOrder__c, Exchange_Rate__c, ' +
                                'True_discount__c, Converted_list_Price__c, Quote_Ref__r.Account__c, Cost__c, List_Price__c, Discount_Percentage__c, Price__c, Total_Price__c, Product_Name__c, Info__c, IsTraining__c, ' +
                                'Total_Price_In_Currency__c, Quote_Product__r.Site__c, Quote_Product__r.Site__r.Name, Product2__r.IsPriceCalculated__c, ' +
                                'Quote_Product__r.Site__r.Country__c, CurrencyIsoCode, Price_Book__c, Product2__c, Quote_Product__r.Price_Book__c, ' +
                                'PrimaryPricebookId__c, SecondaryPricebookId__c, Quote_Ref__c, Notes__c, IsPartBuilder__c, Round_Discount_Amount__c , Phase__c, FeeType__c, ' +
                                'Quote_Product__r.Is_Project_Phase__c, Quote_Product__r.Project_Name__c, Pricing_Configured__c, Location__c, True_Discount_Amount__c, InfoVal3__c, Product2__r.Course_Country__c, ' +
                       			'ProjectProductName__c, Project__r.Name, Quote_Product__r.Product_Name__r.RecordType.Name, SiteName__c, Quote_Product__r.Site_Name__c, Quote_Product__r.ProjectSiteCountry__c ' +
                       'FROM Quote_Part__c ' +
                       'WHERE Quote_Ref__c = :quoteId '  +
                                'AND IsQuestion__c = false ';
        // Discount only prodicts
        if(discountOnly) {
            query += 'AND IsDiscountable__c = :discountOnly ';
        }

        // Product names
        if(products != null && !products.isEmpty()) {
            query += 'AND (Product_Name__c IN :products OR ProjectProductName__c IN :products)';
        }

        if(siteId != null && !siteId.isEmpty()) {
            query += 'AND Quote_Product__r.Site_Name__c IN :siteId ';
        }
        
        if(phases != null && !phases.isEmpty()) {
            query += 'AND Phase__c IN :phases ';
        }
        
        if(feeTypes != null && !feeTypes.isEmpty()) {
            query += 'AND FeeType__c IN :feeTypes ';
        }

        // ORDER BY
        query += 'ORDER BY Product_Name__c, BOMOrder__c ';

        return database.query(query);
    }

    public static void SaveQuote(Quote__c quote) {
        /* Method to save Quote */
        SaveQuote(quote, null, bg_StringUtils.IsBlank(quote.Id));
    }

    public static void SaveQuote(Quote__c quote, map<string, bg_Wrappers.QuoteProductWrapper> selectedProductsMap) {
        /* Method to save Quote */
        SaveQuote(quote, selectedProductsMap, bg_StringUtils.IsBlank(quote.Id), false);
    }

    public static void SaveQuote(Quote__c quote, map<string, bg_Wrappers.QuoteProductWrapper> selectedProductsMap, boolean ignorePricebookError) {
        /* Method to save Quote */
        SaveQuote(quote, selectedProductsMap, bg_StringUtils.IsBlank(quote.Id), ignorePricebookError);
    }

    public static void SaveQuote(Quote__c quote, boolean applyDefaults) {
        /* Method to save Quote */
        SaveQuote(quote, null, applyDefaults);
    }

    public static void SaveQuote(Quote__c quote, map<string, bg_Wrappers.QuoteProductWrapper> selectedProductsMap, boolean applyDefaults, boolean ignorePricebookError) {
        /*
            Method to save Quote
        */
        // check pricebook support quote currency
        //if(!bg_PricebookUtils.CheckPricebookSupportsCurrency(quote.PriceBook2Id__c, quote.CurrencyIsoCode)) {
        //  throw new QuoteException('The default quote pricebook does not support ' + quote.CurrencyIsoCode + ' (' + quote.PriceBook2Id__c + ')');
        //}

        try {
            // insert / update quote
            upsert quote;

            System.debug ('bg_QuoteUtils: ' + quote.Configuration_Completed__c);
            // save quote contacts to opportunity
            bg_ContactUtils.SaveOpportunityContacts(quote);
            // save quote products (if passed in)
            if(selectedProductsMap != null) {
                SaveQuoteProducts(quote, selectedProductsMap, applyDefaults, ignorePricebookError);
            }
        } catch (system.QueryException ex) {
            if(ex.getMessage().contains('Record Currently Unavailable')) {
                string userName = GetQuoteLastModifiedByName(quote.Id);
                throw new QuoteException(system.label.RecordInUseError.replaceAll('{0}', userName));
            } else {
                throw ex;
            }
        }
    }

    private static string GetQuoteLastModifiedByName(Id quoteId) {
        /*
            Get Quote Last Modified By
        */
        string lastModifiedByName;
        try {
            if(quoteId != null) {
                lastModifiedByName = [SELECT LastModifiedBy.Name FROM Quote__c WHERE Id = :quoteId].LastModifiedBy.Name;
            }
        } catch (Exception ex) {}
        return lastModifiedByName;
    }

    public static void SaveQuoteProducts(Quote__c quote, map<string, bg_Wrappers.QuoteProductWrapper> selectedProductsMap) {
        /* Save / Update Quote Products */
        SaveQuoteProducts(quote, selectedProductsMap, false);
    }

    public static void SaveQuoteProducts(Quote__c quote, map<string, bg_Wrappers.QuoteProductWrapper> selectedProductsMap, boolean applyDefaults) {
        /* Save / Update Quote Products */
        SaveQuoteProducts(quote, selectedProductsMap, applyDefaults, false);
    }

    public static void SaveQuoteProducts(Quote__c quote, map<string, bg_Wrappers.QuoteProductWrapper> selectedProductsMap, boolean applyDefaults, boolean ignorePricebookError) {
        /*
            Save / Update Quote Products
        */

        // Load site products Map
         set<string> mainProductNames = new set<string>();
        for(bg_Wrappers.QuoteProductWrapper qpw : selectedProductsMap.values()) {
            mainProductNames.add(qpw.Name);
        }
    

        Map<Id, Product__c> mainProductsById = new Map<Id, Product__c>(bg_ProductUtils.GetMainProducts(mainProductNames));
        map<string, Product__c> siteProductsMap = bg_ProductUtils.GetProductNameMap(bg_ProductUtils.GetSiteProducts(mainProductNames));
        map<bg_Wrappers.ProductSiteWrapper, Quote_Product__c> updQuoteProducts = new map<bg_Wrappers.ProductSiteWrapper, Quote_Product__c>();
        set<Id> existingIds = new set<Id>();

        integer groupNo = 1;
        
        for(bg_Wrappers.QuoteProductWrapper qpw : selectedProductsMap.values()) {


            if (qpw.controllingLocationId == null && qpw.GridView)
            {
                throw new QuoteException('A controlling location must be set for each selected product');   

            }
            /*  get the main product from the product map
                check if the product is professional services
                if it is take the first site from the sites map and build a product site wrapper
            */
            if(!mainProductsById.containsKey(qpw.Id))
            {
                throw new QuoteException('The following product id is not a main product: ' + qpw.Id);   
            }
            Product__c mainProduct = mainProductsById.get(qpw.Id);
            for(bg_Wrappers.ProductSiteWrapper psw : qpw.SitesMap.values()) {
                // create Quote Product
                if(bg_StringUtils.IsBlank(psw.RegistrationPath) && qpw.GridView && psw.IsControllingLocation)
                {
                    throw new QuoteException('At least one registration path must be selected for each selected product');

                }
                

                Quote_Product__c qp = new Quote_Product__c();
                psw.QuoteProduct.QuoteProduct = qp;
                if(bg_StringUtils.IsBlank(psw.qpId)) 
                {
                    // new quote product
                    qp.Quote_Ref__c = quote.Id;
                    if(psw.Site != null) {
                        qp.SiteEmployees__c = psw.Site.NoEmployees;
                    }
                } 
                else 
                {
                    // existing QP
                    qp.Id = psw.qpId;
                } 

                
              
                    //if its the controlling location or its the list view
                    if(psw.Site.Id == qpw.controllingLocationId || !mainProduct.GridView__c) 
                    {
                        // Main Product Id
                        qp.Product_Name__c = qpw.Id;
                    } else 
                    {
                        // Site Product
                        string siteProductName = bg_ProductUtils.GetSiteProductName(qpw.Name);
                        if(siteProductsMap.containsKey(siteProductName)) 
                        {
                            qp.Product_Name__c = siteProductsMap.get(siteProductName).Id;
                        } 
                        else 
                        {
                            throw new QuoteException('Site product cannot be found: ' + siteProductName);
                        }
                    }
                    System.debug('###RC ' + psw.Selected);

                    qp.Selected__c = psw.Selected;
                    qp.SiteTabLabel__c = psw.Site.Name;
                   
                    qp.GroupNumber__c = groupNo;
                    

                    qp.LayoutOrder__c = psw.SiteIndex;
                    qp.Registration_Path__c = psw.RegistrationPath;
                    qp.Site__c = psw.Site.Id;
                    qp.Opportunity_Site__c = psw.Site.OppSiteId;

                    qp.Sampling_Available__c = qpw.SamplingAvailable;
                    qp.Sampling_Applied__c = qpw.UseSampling;
                    qp.Sampling_Verified__c = qpw.VerifiedForSampling;

                    qp.Included_in_IMS__c = qpw.IMS;

                    qp.Instance__c = qpw.Instance;
                    qp.Product2__c = qpw.StandardId;
                    qp.Project__c = qpw.ProjectId;

                    if(qpw.ProductClassification != null) {
                        qp.Product_Classification__c = qpw.ProductClassification.Id;
                    }

                    if(applyDefaults || bg_StringUtils.IsBlank(qp.Id)) {
                        bg_WrapperHelper.PopulateProductSiteContactDefaults(psw, quote);
                        bg_WrapperHelper.PopulateProductSiteCurrencyDefaults(psw, quote);
                    }

                    qp.Price_Book__c = quote.PriceBook2Id__c;
                    qp.Price_Book_Name__c = bg_PricebookUtils.GetPricebookById(quote.PriceBook2Id__c).Name;
                    qp.CurrencyIsoCode = quote.CurrencyIsoCode;
                    qp.Secondary_Price_Book__c = psw.SecondaryPricebookId;

                    qp.Primary_Contact__c = psw.ContactRoleMap.get(bg_ContactUtils.CONTACT_SITE_ROLE_PRIMARY);
                    qp.Booking_Contact__c = psw.ContactRoleMap.get(bg_ContactUtils.CONTACT_SITE_ROLE_BOOKING);
                    qp.Credit_Check_Contact__c = psw.ContactRoleMap.get(bg_ContactUtils.CONTACT_SITE_ROLE_CREDIT_CHECK);
                    qp.Invoice_Contact__c = psw.ContactRoleMap.get(bg_ContactUtils.CONTACT_SITE_ROLE_INVOICE);
                    qp.Country_Code__c = psw.Site.Country;
                    qp.Risk_Level__c = psw.RiskLevel;

                    updQuoteProducts.put(psw, qp);
                    if(qp.Id != null) { existingIds.add(qp.Id); }

               
            }
            groupNo++;
        }
        
        // flag products that need to be reconfigured
        if([SELECT Id
            FROM Quote_Part__c
            WHERE Quote_Ref__c = :quote.Id AND IsQuestion__c = false AND
                (Quote_Product__r.Product_Name__r.Product_Type__c = :bg_ProductUtils.PRODUCT_TYPE_MAIN OR
                 Quote_Product__r.Product_Name__r.Product_Type__c = :bg_ProductUtils.PRODUCT_TYPE_SITE)
                AND Quote_Product__c NOT IN :existingIds
                AND Quote_Product__r.Is_Project_Phase__c = false
            LIMIT 1].size() > 0) {
            // Reset the configuration flag if a product is removed that had quote parts.
            for(Quote_Product__c qp : updQuoteProducts.values()) {
                qp.Configuration_Complete__c = false;
            }
        }

        // Insert / update quote products
        if(!updQuoteProducts.isEmpty()) {
            // Ignore Pricebook Error?
            if(!ignorePricebookError) {
                upsert updQuoteProducts.values();

            } else {
                // codes to handle pricebook errors?
                database.UpsertResult[] results = database.upsert(updQuoteProducts.values(), false);
                list<Quote_Product__c> updRetry = new list<Quote_Product__c>();
                for(integer i = 0; i < results.size() ; i++) {
                    database.UpsertResult result = results[i];
                    if(!result.isSuccess()) {
                        // Clear Pricebook fields
                        Quote_Product__c qp = updQuoteProducts.values()[i];
                        qp.Price_Book__c = null;
                        //qp.Price_Book_Name__c = null;
                        updRetry.add(qp);
                    }
                }
                // Retry save without pricebooks
                if(!updRetry.isEmpty()) {
                    upsert updRetry;
                }
            }

            // Update Id on wrapper
            for(bg_Wrappers.ProductSiteWrapper psw : updQuoteProducts.keySet()) {
                if(bg_StringUtils.IsBlank(psw.qpId) && !bg_StringUtils.IsBlank(updQuoteProducts.get(psw).Id)) {
                    psw.qpId = updQuoteProducts.get(psw).Id;
                }
            }
        }

        // Deselect products?
        map<Id, Quote_Product__c> updateQuoteProductsMap = new map<Id, Quote_Product__c>(updQuoteProducts.values());
        DeselectQuoteProducts(quote.Id, updateQuoteProductsMap.keySet(), true);
    }

    public static void DeselectQuoteProducts(Id quoteId, set<Id> ignoreIds, boolean deleteRecords) {

        list<Quote_Product__c> toDeselect;

        try {
            // Get list of quote products no longer selected (site & main)
            toDeselect = new list<Quote_Product__c>([SELECT Id
                                                    FROM Quote_Product__c
                                                    WHERE Quote_Ref__c = :quoteId
                                                        AND (Product_Name__r.Product_Type__c = :bg_ProductUtils.PRODUCT_TYPE_MAIN OR
                                                            Product_Name__r.Product_Type__c = :bg_ProductUtils.PRODUCT_TYPE_SITE)
                                                        AND Id NOT IN :ignoreIds
                                                        AND Deleted__c = false
                                                        AND Is_Project_Phase__c = false]);

            System.debug('###RC delected list =  ' + toDeselect);
            for(Quote_Product__c qp : toDeselect) {
                qp.Selected__c = false;
                qp.Deleted__c = true;
            }
        } catch (Exception e) {}

        // delete removed products
        if(!toDeselect.isEmpty()) {
            update toDeselect;
            map<Id, Quote_Product__c> toDeselectMap = new map<Id, Quote_Product__c>(toDeselect);
            DeleteQuoteProducts(toDeselectMap.keySet());
        }

    }

    @future
    public static void DeleteQuoteProducts(set<Id> deleteIds) {

        list<Quote_Part__c> toDeleteParts;
            try {
                toDeleteParts = new list<Quote_Part__c>([SELECT Id
                                                        FROM Quote_Part__c
                                                        WHERE Quote_Product__c IN :deleteIds]);
            } catch (Exception e) {}

        list<Quote_Product__c> toDeleteProducts;
        try {
            // Get list of quote products no longer selected (site & main)
            toDeleteProducts = new list<Quote_Product__c>([SELECT Id
                                                    FROM Quote_Product__c
                                                    WHERE Id IN :deleteIds]);
        } catch (Exception e) {}

        // delete removed products
        if(!toDeleteParts.isEmpty()) {
            delete toDeleteParts;
            Database.emptyRecycleBin(toDeleteParts);
        }

        // delete removed products
        if(!toDeleteProducts.isEmpty()) {
            delete toDeleteProducts;
            Database.emptyRecycleBin(toDeleteProducts);
        }
    }

    //private static set<Id> quoteTriggerIgnoreIds;
    public static boolean IgnoreQuoteId(Id quoteId) {
        return false;
        //system.debug('quoteTriggerIgnoreIds: ' + quoteTriggerIgnoreIds);
        //return quoteTriggerIgnoreIds != null && quoteTriggerIgnoreIds.contains(quoteId);
    }

    public static void SaveQuoteParts(Quote__c quote, list<Quote_Part__c> quoteParts) {
        /*
            Method to save Quote Parts
        */
        //if(quoteTriggerIgnoreIds == null) {
        //  quoteTriggerIgnoreIds = new set<Id>();
        //}
        //quoteTriggerIgnoreIds.add(quoteId);
        // insert / update quote parts

        //bg_QuotePartUtils.RecalculateQuotePartPrices(quote, quoteParts);
        upsert quoteParts;

        //quoteTriggerIgnoreIds.remove(quoteId);
        //update new Quote__c(Id=quoteId);
    }

    public static Quote_Product__c GetSampleQuestionProduct(string productName, Id quoteId, boolean createIfMissing) {
        return GetSampleQuestionProduct(productName, quoteId, createIfMissing, null);
    }

    public static Quote_Product__c GetSampleQuestionProduct(string productName, Id quoteId, boolean createIfMissing, integer instance) {
        /*
            Get Sampling Question Product
        */
        Product__c questionProd = bg_ProductUtils.GetQuestionProductByName(productName);
        if(questionProd == null) {
            return null;
        } else {
            return GetQuestionProduct(quoteId, createIfMissing, questionProd, instance);
        }
    }

    public static Quote_Product__c GetIMSQuestionProduct(string productName, Id quoteId, boolean createIfMissing) {
        /*
            Get IMS Product
        */
        Product__c questionProd = bg_ProductUtils.GetQuestionProductByName(bg_ProductUtils.QUESTION_PRODUCT_IMS);
        if(questionProd == null) {
            return null;
        } else {
            return GetQuestionProduct(quoteId, createIfMissing, questionProd);
        }
    }

    private static Quote_Product__c GetQuestionProduct(Id quoteId, boolean createIfMissing, Product__c qProduct) {
        /* Create Question Product */
        return GetQuestionProduct(quoteId, createIfMissing, qProduct, null);
    }

    private static Quote_Product__c GetQuestionProduct(Id quoteId, boolean createIfMissing, Product__c qProduct, integer instance) {
        /* Create Question Product */
        return GetQuestionProduct(quoteId, createIfMissing, qProduct.Id, instance);
    }

    public static Quote_Product__c GetQuestionProduct(Id quoteId, boolean createIfMissing, Id qProductId, integer instance) {
        /*
            Create Question Product
        */
        // check if question product already exists?
        Quote_Product__c qp;

        // Does question quote product exist?
        try {
            qp = [SELECT Id, Price__c, Product_Name__c
                    FROM Quote_Product__c
                    WHERE Quote_Ref__c = :quoteId
                        AND Product_Name__c = :qProductId
                        AND Instance__c = :instance];
            return qp;
        } catch (Exception e) {}

        // create question quote product
        if(createIfMissing && qp == null) {
            qp = new Quote_Product__c();
            qp.Quote_Ref__c = quoteId;
            qp.Product_Name__c = qProductId;
            qp.Price_Book_Name__c = bg_CustomSettingsUtils.GetDefaultCountrySettings().DefaultPriceBookName__c;
            qp.GroupNumber__c = 1;
            qp.Selected__c = true;
            if(instance != null) {
                qp.Instance__c = instance;
            }
            insert qp;
        }

        return qp;
    }

    public static void RemoveSamplingQuestionProduct(string productName, Id quoteId) {
        /* Delete Sampling Question Product */
        RemoveSamplingQuestionProduct(productName, quoteId, null);
    }

    public static void RemoveSamplingQuestionProduct(string productName, Id quoteId, integer instance) {
        /*
            Delete Sampling Question Product
        */

        Quote_Part__c quotePart;
        try {
            // Do not error if part cannot be found
            string partProductName = productName + bg_ProductUtils.QUESTION_PRODUCT_POSTFIX;
            quotePart = [SELECT Id, Quote_Product__c
                        FROM Quote_Part__c
                        WHERE Quote_Ref__c = :quoteId
                            AND Product_Name__c = :partProductName
                            AND IsQuestion__c = true
                            AND Quote_Product__r.Instance__c = :instance];
        } catch (exception e) {}
        if(quotePart != null) { delete quotePart; }

        Product__c questionProduct = bg_ProductUtils.GetQuestionProductByName(productName);
        Quote_Product__c quoteProduct;
        try {
            // Do not error if product cannot be found
            quoteProduct = [SELECT Id
                            FROM Quote_Product__c
                            WHERE Quote_Ref__c = :quoteId
                                AND Product_Name__c = :questionProduct.Id
                                AND Instance__c = :instance];
        } catch (exception e) {}
        if(quoteProduct != null) { delete quoteProduct; }
    }

    public static string BuildNewQuoteURL(string accId, string oppId) {
        /* Return new quote URL */
        return BuildNewQuoteURL(accId, oppId, null);
    }

    public static string BuildNewQuoteURL(string accId, string oppId, string quoId) {
        /* Return new quote URL */
        return BuildQuoteURL(VF_PAGENAME_NEWQUOTE, accId, oppId, quoId, true, false);
    }

    public static string BuildQuoteBuilderURL(string accId, string oppId, string quoId)
    {
        return BuildQuoteURL(VF_PAGENAME_NEWQUOTE, accId, oppId, quoId, false, true);
    }
    
    public static string BuildQuoteBuilderURL(string accId, string oppId, string quoId, boolean editMode)
    {
        return BuildQuoteURL(VF_PAGENAME_NEWQUOTE, accId, oppId, quoId, editMode, true);
    }

    public static string BuildNewQuoteGridURL(string accId, string oppId, string quoId) {
        /* Return new quote URL */
        return BuildQuoteURL(VF_PAGENAME_NEWQUOTEGRID, accId, oppId, quoId, true, false);
    } 

    public static string BuildNewQuoteGridURL(string accId, string oppId, string quoId, boolean editMode) {
        /* Return new quote URL */
        return BuildQuoteURL(VF_PAGENAME_NEWQUOTEGRID, accId, oppId, quoId, editMode, false);
    }

    public static string BuildQuotePartGridURL(string quoId) {
        /* Return quote part grid URL */
        return BuildQuoteURL(VF_PAGENAME_QUOTEPARTGRID, null, null, quoId, true, false);
    }

    public static string BuildQuotePartGridURL(string quoId, boolean editMode) {
        /* Return quote part grid URL */
        return BuildQuoteURL(VF_PAGENAME_QUOTEPARTGRID, null, null, quoId, editMode, false);
    }

    public static final string URL_PARAM_ACC_ID = 'accid';
    public static final string URL_PARAM_OPP_ID = 'oppid';
    public static final string URL_PARAM_QUO_ID = 'quoid';
    public static final string URL_PARAM_MODE = 'mode';

    private static string BuildQuoteURL(string VF_PageName, string accId, string oppId, string quoId, boolean editMode, boolean addUrl) {
        /* Return new quote URL */
        String url = '';
        if(addURL)
        {
            url = System.URL.getSalesforceBaseUrl().toExternalForm() + '/apex/' + VF_PageName + '?';
        }
        else
        {
             url = 'apex/' + VF_PageName + '?';
        }
        
        if(!bg_StringUtils.IsBlank(accId)) {
            url += URL_PARAM_ACC_ID + '=' + accId + '&';
        }
        if(!bg_StringUtils.IsBlank(oppId)) {
            url += URL_PARAM_OPP_ID + '=' + oppId + '&';
        }
        if(!bg_StringUtils.IsBlank(quoId)) {
            url += URL_PARAM_QUO_ID + '=' + quoId + '&';
        }
        if(!editMode) {
            url += URL_PARAM_MODE + '=' + 0 + '&';
        }
        return url;
    }

    public static list<Product__c> GetProducts(list<Quote_Product__c> quoteProducts) {
        /*
            Return list of products from Quote Product list
        */
        set<Id> prodIds = new set<Id>();
        for(Quote_Product__c qp : quoteProducts) {
            prodIds.add(qp.Product_Name__c);
        }
        return bg_ProductUtils.GetProductByIds(prodIds);
    }

    public static list<Product__c> GetMainProducts(list<Quote_Product__c> quoteProducts) {
        /*
            Return list of products from Quote Product list
        */
        set<string> prods = new set<string>();
        for(Quote_Product__c qp : quoteProducts) {
            prods.add(bg_ProductUtils.GetMainProductName(qp.Product_Name__r));
        }
        return bg_ProductUtils.GetMainProducts(prods);
    }

    public static void PopulateIMSFields(Quote__c quote) {
        /*
            Re-populate IMS fields
        */
        quote.IMS_Complete__c = GetQuoteById(quote.Id).IMS_Complete__c;
    }

    public static Id GetMainQuoteId(Id opportunityId) {
        /*
            Return the main quote ID for an opportunity
        */
        List<Quote__c> quoteList = new List<Quote__c>([ SELECT id
                                                        FROM Quote__c
                                                        WHERE Opportunity_Name__c = :opportunityId
                                                        AND Main_Quote__c = true]);
        return (quoteList.isEmpty() ? null : quoteList.get(0).id);
    }

    private static Quote__c GetCloneQuote(Id quoteId) {
        /*
            Return Quote to clone - has all fields to clone
        */
        return [SELECT ParentQuote__c, Opportunity_Name__c, Account__c, Contact__c, Invoice_Contact__c, Booking__c, CreditCheck__c, //, DiscountStatus__c,
                    Salesman__c, RegistrationPath__c, Transient__c, Network__c, OneScopeSystem__c, Pricebook2Id__c,
                    MoreCertificate__c, ExpireDate__c, OwnerId, ConsultantInvolved__c, ConsultantName__c, Outsourcing__c,
                    OutsourcingDetails__c, WholeCertAdvised__c, ScopeOfRegistration__c, Street__c, City__c, Postcode__c, State__c, Country__c
                FROM Quote__c
                WHERE Id = :quoteId];
    }

    private static list<Quote_Product__c> GetCloneQuoteProducts(Id quoteId) {
        /*
            Return Quote Products to clone - has all fields to clone
        */
        return [SELECT Product_Name__c, Instance__c, Product2__c, Description__c, Number__c, Cost__c, Discount_Percentage__c, Price__c, LayoutOrder__c, GroupNumber__c, SiteTabLabel__c,
                    Product_Note__c, Price_Book_Name__c, Price_Book__c, Secondary_Price_Book__c, Registration_Path__c, Site__c, Included_in_IMS__c, Country_Code__c, Selected__c, Sampling_Available__c, Sampling_Applied__c,
                    Primary_Contact__c, Credit_Check_Contact__c, Booking_Contact__c, Invoice_Contact__c, Opportunity_Site__c, Sampling_Verified__c, CurrencyIsoCode, SiteEmployees__c, Product_Classification__c
                FROM Quote_Product__c
                WHERE Quote_Ref__c = :quoteId];
    }

    public static Quote__c CloneQuote(Id quoteId) {
        /* Method to return a cloned quote */
        return CloneQuote(quoteId, false);
    }

    public static Quote__c CloneQuote(Id quoteId, boolean cloneQuoteProducts) {
        /* Method to return a cloned quote and products */
        return CloneQuote(quoteId, cloneQuoteProducts, false);
    }

    public static Quote__c CloneQuote(Id quoteId, boolean cloneQuoteProducts, boolean cloneQuoteProductApprovals) {
        /* Method to return a cloned quote, quote products */
        return CloneQuote(quoteId, cloneQuoteProducts, cloneQuoteProductApprovals, null);
    }

    public static Quote__c CloneQuote(Id quoteId, boolean cloneQuoteProducts, boolean cloneQuoteProductApprovals, Id newOpportunityId) {
        /* Method to return a cloned quote, quote products */
        return CloneQuote(quoteId, cloneQuoteProducts, cloneQuoteProductApprovals, newOpportunityId, new map<Id, OpportunitySite__c>());
    }

    public static Quote__c CloneQuote(Id quoteId, boolean cloneQuoteProducts, boolean cloneQuoteProductApprovals, Id newOpportunityId, map<Id, OpportunitySite__c> oldToNewSites) {
        /*
            Method to return a cloned quote, quote products
        */
        Quote__c cloneQuote;
        Savepoint sp = Database.setSavepoint();
        try {
            // Clone Quote
            cloneQuote = InternalCloneQuote(quoteId, newOpportunityId);
            // Clone Quote Product?
            if(cloneQuoteProducts) {
                cloneQuote.Quote_Products__r.addAll(CloneQuoteProducts(quoteId, cloneQuote.Id, oldToNewSites));
            }

            // Clone Quote Product Approvals
/*
            if(cloneQuoteProductApprovals) {
                CloneQuoteProductApprovals(quoteId, cloneQuote.Id);
            }
*/
        } catch (Exception ex) {
            // Clone Error?
            Database.rollback(sp);
            throw ex;
        }
        return cloneQuote;
    }

    private static Quote__c InternalCloneQuote(Id quoteId, Id newOpportunityId) {
        /*
            Clone Quote
            if opportunityID isn't null, the quote opportunity will be set
        */
        // Get quote to clone
        Quote__c quote = GetCloneQuote(quoteId);

        // Create quote clone - reset special values
        Quote__c cloneQuote = quote.Clone(false, true);
        if(newOpportunityId != null){
            cloneQuote.Opportunity_Name__c = newOpportunityId;
        }
        cloneQuote.Main_Quote__c = true;
        cloneQuote.ParentQuote__c = (quote.ParentQuote__c == null?quote.Id:quote.ParentQuote__c);
        // Reset Discount Status
        //QuoteSetting__c cs = bg_CustomSettingsUtils.GetQuoteSettings();
        //if (quote.DiscountStatus__c == cs.StatusRejected__c) {
        //  quote.DiscountStatus__c = cs.StatusDraft__c;
        //}
        // insert new quote
        insert cloneQuote;
        return  cloneQuote;
    }

    public static list<Quote_Product__c> CloneQuoteProducts(Id quoteId, Id cloneQuoteId) {
        /* Method to return a cloned quote products - KM: Now calls the overloaded method */
        return CloneQuoteProducts(quoteId, cloneQuoteId, new Map<Id, OpportunitySite__c>());
    }

    public static list<Quote_Product__c> CloneQuoteProducts(Id quoteId, Id cloneQuoteId, Map<Id, OpportunitySite__c> oldToNewSites) {
        /*
            Method to return a list of cloned quote products
            Reparent sites
        */
        // Get quote to clone
        list<Quote_Product__c> quoteProducts = GetCloneQuoteProducts(quoteId);
        list<Quote_Product__c> cloneQuoteProducts = new list<Quote_Product__c>();

        // Create quote clone - reset special values
        for(Quote_Product__c quoteProduct : quoteProducts) {
            Quote_Product__c cloneQuoteProduct = quoteProduct.Clone(false, true);
            cloneQuoteProduct.CopyFromSFID__c = quoteProduct.Id;
            cloneQuoteProduct.Quote_Ref__c = cloneQuoteId;
            if(oldToNewSites != null && oldToNewSites.containsKey(cloneQuoteProduct.Opportunity_Site__c)){
                cloneQuoteProduct.Site__c = oldToNewSites.get(cloneQuoteProduct.Opportunity_Site__c).Site__c;
                cloneQuoteProduct.Opportunity_Site__c = oldToNewSites.get(cloneQuoteProduct.Opportunity_Site__c).Id;
            }
            cloneQuoteProducts.add(cloneQuoteProduct);
        }
        // insert quote products
        if(!cloneQuoteProducts.isEmpty()) {
            insert cloneQuoteProducts;
        }
        return cloneQuoteProducts;
    }

/*
    public static void CloneQuoteProductApprovals(Id quoteId, Id cloneQuoteId) {
        / *
            Method to clone the quote Product Approvals
        * /
        map<Id, Quote_Product_Approval__c> qpaMap = bg_QuoteApprovalUtils.GetQuoteProductApprovalsMap(quoteId);
        map<Id, Quote_Product_Approval__c> cloneQPAMap = bg_QuoteApprovalUtils.GetQuoteProductApprovalsMap(cloneQuoteId);

        for(Id productId : cloneQPAMap.keySet()) {
            if(qpaMap.containsKey(productId)) {
                // Copy Discount Percentage
                cloneQPAMap.get(productId).Discount_Percentage__c = qpaMap.get(productId).Discount_Percentage__c;
            }
        }

        // Update Quote Product Approvals
        if(!cloneQPAMap.isEmpty()) {
            update cloneQPAMap.values();
        }
    }
*/

    public static boolean OverrideQuoteStatus(string status) {
        /*
            Method to return if Quote Status can be overriden
        */
        QuoteSetting__c cs = bg_CustomSettingsUtils.GetQuoteSettings();
        return (bg_StringUtils.IsBlank(status) || status == cs.StatusNA__c || status == cs.StatusDraft__c);
    }

    public static void ResetValidationFields(Quote__c quote)
    {
        /*
            Reset the fields related to validation
        */
        quote.ValidationStatus__c = bg_CustomSettingsUtils.GetQuoteSettings().StatusDraft__c;
        quote.ValidationCheck__c = false;
        quote.ValidationDate__c = null;
        quote.ValidatedBy__c = null;
    }

    public static void ResetSkipCustomerFields(Quote__c quote)
    {
        /*
            Reset the fields in the customer skip section
        */
        quote.SkipCustomer__c = false;
        quote.SkippedDate__c = null;
        quote.SkippedBy__c = null;
        quote.Configuration_Completed__c = false;
    }

    public static void ResetFinanceFields(Quote__c quote)
    {
        /*
            Reset the fields related to finance
        */
        quote.FinanceStatus__c = null;
    }

    public static void ResetDiscountFields(Quote__c quote)
    {
        /*
            Reset the fields in the discount section
        */
        quote.DiscountStatus__c = null;
        quote.ManagerDiscount__c = null;
        quote.DirectorDiscount__c = null;
        quote.DiscountDateTimeSubmitted__c = null;
        quote.DiscountDateTimeDeclined__c = null;
        quote.DiscountDateTimeApproved__c = null;
    }

    public static void ResetTechReviewFields(Quote__c quote)
    {
        /*
            Reset the fields in the tech review section
        */
        quote.SkipTechReview__c = false;
        quote.SkippedTechReviewBy__c = null;
        quote.SkippedTechReviewDate__c = null;
    }

    public static void ResetProposalSentFields(Quote__c quote)
    {
        /*
            Reset the fields in the proposal sent section
        */
        quote.Proposal_Sent_Date__c = null;
    }
    /*
    *   Reset the fields in the proposal approval section
    */
    public static void ResetPsProposalApprovalFields(Quote__c quote)
    {
        quote.PsProposalDateTimeApproved__c = null;
        quote.PsProposalDateTimeDeclined__c = null;
        quote.PsProposalDateTimeSubmitted__c = null;
        quote.PS_Proposal_Approver__c = null;
        quote.PS_Proposal_Approval_Status__c = null;  
    }

    public static void ResetQuoteStages(Quote__c quote) {
        /*
            Reset quote stages clears quote fields to move back to stage 1
        */

        // Reset the Customer Validation fields
        ResetSkipCustomerFields(quote);

        // Reset the quote approval records
        bg_QuoteApprovalUtils.ResetQuoteApprovalsByQuoteId(quote.id);

        // Reset Fact Validation fields on the quote
        ResetValidationFields(quote);

        // Reset finance fields on the quote
        ResetFinanceFields(quote);

        // Reset Discount fields on the quote
        ResetDiscountFields(quote);

        // Reset the tech review fields on the quote
        ResetTechReviewFields(quote);

        // Reset the proposal sent section of fields on the quote
        ResetProposalSentFields(quote);

        ResetPsProposalApprovalFields(quote);

        

        update quote;
    }

    public static Boolean CheckAnyQuoteStatusPending(Quote__c quote){
        /*
            Returns true if finance, validation or discount status are set to pending
        */
        return  quote.FinanceStatus__c == QUOTE_FINANCE_STATUS_PENDING ||
                quote.ValidationStatus__c == QUOTE_DISCOUNT_STATUS_PENDING ||
                quote.DiscountStatus__c == QUOTE_DISCOUNT_STATUS_PENDING ||
                quote.OperationsReviewStatus__c == QUOTE_OPERATIONS_STATUS_PENDING ||
                quote.PS_Proposal_Approval_Status__c == QUOTE_PS_PROPOSAL_STATUS_PENDING;
    }

    public static void SkipFactsValidationByCustomer(Quote__c quote) {
        /*
            Skip Fact validation by customer
        */
        QuoteSetting__c qs = bg_CustomSettingsUtils.GetQuoteSettings();
        quote.SkipCustomer__c = true;
        quote.SkippedDate__c = dateTime.now();
        quote.ValidationStatus__c = qs.StatusApproved__c;
        quote.SkippedBy__c = UserInfo.getName();
        update quote;
    }

    public static void SkipDiscounts(Id quoteId, map<Id, Quote_Product_Approval__c> qpaMap) {
        /*
            Skip Discounts
        */
        // Clear Discounts
        for(Quote_Product_Approval__c qpa : qpaMap.values()) {
            qpa.Discount_Percentage__c = 0;
        }
        // Update discounts
        bg_QuoteApprovalUtils.UpdateDiscounts(quoteId, qpaMap);
    }

    public static void SkipTechReview(Quote__c quote) {
        /*
            Skip Tech Review
        */
        quote.SkipTechReview__c = true;
        quote.SkippedTechReviewDate__c = dateTime.now();
        quote.SkippedTechReviewBy__c = UserInfo.getName();
        update quote;
    }

    public static boolean CanUserQuoteProduct(Id productId, Id UserId) {
        /*
            Check to see if user can quote for product
        */
        boolean result = true;
        Product__c product = bg_ProductUtils.GetProductById(productId);
        if(product.RequiresCCodeToQuote__c) {
            // Get users C-Code
            map<string, set<CCode_Profile__c>> ccodeApproversMap = bg_QuoteApprovalUtils.GetCCodeApprovers(new set<string>{product.CCode__c}, userId, null);
            system.debug('ccodeApproversMap: ' + ccodeApproversMap);
            return ccodeApproversMap.size() > 0;
        }
        return result;
    }

    public static void SetOfflineSignedQuoteToMainQuote(List<Quote__C> quotes)
    {
        SetOfflineSignedQuoteToMainQuote(quotes, true);
    }

    public static void SetOfflineSignedQuoteToMainQuote(List<Quote__C> quotes, Boolean updateContext)
    {
        /*
            Set Quotes signed offline to be main Quotes
            updateContext is true if method will be called within an update trigger
        */
        if(!recursiveFlag) // Prevent rerunning on newly ticked quotes, or they will detect themselves and error
        {
            recursiveFlag = true;
            // Check quotes in same opportunity that are main quotes
            Map<Id, List<Quote__c>> quotesByOppId = new Map<Id, List<Quote__c>>();
            for (Quote__c quote : quotes)
            {
                if (quotesByOppId.containsKey(quote.Opportunity_Name__c))
                {
                    quotesByOppId.get(quote.Opportunity_Name__c).add(quote);
                }
                else
                {
                    quotesByOppId.put(quote.Opportunity_Name__c, new List<Quote__c> {quote});
                }
            }
            //System.debug('JA** quotesByOppId : '+quotesByOppId);
            List<Quote__c> mainQuotes = [SELECT Id, Opportunity_Name__c, ProposalSignedOffline__c FROM Quote__c WHERE Opportunity_Name__c IN :quotesByOppId.keySet() AND Main_Quote__c = true];
            //System.debug('JA** mainQuotes: '+mainQuotes);
            // Check if any main quotes are signed, if so they should remain the main quotes.
            // Otherwise, quotes where the opportunity has no other signed quotes should become the main quote.
            List<echosign_dev1__SIGN_Agreement__c> signedAgreements = [SELECT Id, Quote__c FROM echosign_dev1__SIGN_Agreement__c WHERE echosign_dev1__Status__c = 'Signed'];
            Set<Id> signedAgreementQuoteIds = new Set<Id>();
            for (echosign_dev1__SIGN_Agreement__c signedAggs : signedAgreements)
            {
                signedAgreementQuoteIds.add(signedAggs.Quote__c);
            }
            //System.debug('JA** signedAgreementQuoteIds: '+ signedAgreementQuoteIds);

            for (Quote__c mainQuote : mainQuotes)
            {
                // If already signed, offline (checkbox) or online (via EchoSign), we can ignore quotes related to that opportunity and return an error for those instead
                //System.debug('JA** Signed Quote Check ' + mainQuote.Id + ' : Online '+signedAgreementQuoteIds.contains(mainQuote.Id)+' | Offline '+mainQuote.ProposalSignedOffline__c);
                if (signedAgreementQuoteIds.contains(mainQuote.Id) || mainQuote.ProposalSignedOffline__c)
                {
                    //System.debug('JA** Removing ('+mainQuote.Opportunity_Name__c+'):'+quotesbyOppId.get(mainQuote.Opportunity_Name__c));
                    //List<Quote__c> quotesToError = quotesByOppId.get(mainQuote.Opportunity_Name__c);
                    for (Quote__c quoteToError : quotesByOppId.get(mainQuote.Opportunity_Name__c))
                    {
                        quoteToError.addError('Another Quote on this Opportunity has already been signed');
                    }
                    quotesByOppId.remove(mainQuote.Opportunity_Name__c);
                }
            }
            //System.debug('JA** quotesByOppId B : '+quotesByOppId);

            // For opportunities without signed quotes, make the quotes fed in into Main Quotes
            List<Quote__c> quotesToSetMain = new List<Quote__c>();
            for (List<Quote__c> quotelist : quotesByOppId.values())
            {
                quotesToSetMain.addAll(quoteList);
            }

            SetMainQuotes(quotesToSetMain,updateContext);
        }
    }

    public static void SetMainQuotes(List<Quote__c> quotes)
    {
        SetMainQuotes(quotes,false);
    }

    public static void SetMainQuotes(List<Quote__c> quotes, Boolean updateContext)
    {
        /*
            Set Main Quotes flags
            updateContext is true if method will be called within an update trigger
        */
        map<Id, Quote__c> oppMap = new map<Id, Quote__c>();
        for(Quote__c q : quotes) {
            q.Main_Quote__c = true;
            if(oppMap.containsKey(q.Opportunity_Name__c))
            {
                // only set last quote as main quote
                oppMap.get(q.Opportunity_Name__c).Main_Quote__c = false;
            }
            oppMap.put(q.Opportunity_Name__c, q);
        }

        // Get existing main quotes
        list<Quote__c> allQuotes = [SELECT Id
                                    FROM Quote__c
                                    WHERE Opportunity_Name__c IN :oppMap.keySet()
                                    AND Main_Quote__c = true
                                    AND ID NOT IN :quotes];

        // Set Quote Main to false
        for (Quote__c q : allQuotes) {
            q.Main_Quote__c = false;
        }

        if (!updateContext)
        {
            allQuotes.addAll(quotes);
        }

        System.debug('JA** AllQuotes : ' + allQuotes);
        if(!allQuotes.isEmpty()) {

            // Update quotes
            update allQuotes;
        }
    }

    public static boolean QuoteContainsProducts(Id quoteId, set<string> products) {
        /*
            Method to return if quote contains specific product names
        */
        return [SELECT COUNT()
                FROM Quote_Product__c
                WHERE Quote_Ref__c = :quoteId
                    AND Product_Name__r.Main_Product_Name__c IN :products] > 0;
    }

    public static boolean IsQuoteMultiCurrency(Id quoteId) {
        /*
            Method to return if quote contains multi-products
        */
        return [SELECT CurrencyISOCode
                FROM Quote_Product__c
                WHERE  Quote_Ref__c = :quoteId
                GROUP BY CurrencyISOCode].size() > 1;
    }

    public static boolean ContainsUnconfiguredProducts(Id quoteId) {
        /*
            Method to return if quote contains unconfigured products
        */
        return [SELECT COUNT()
                FROM Quote_Product__c
                WHERE  Quote_Ref__c = :quoteId
                    AND Selected__c = true
                    AND Configuration_Complete__c = false
                    AND Product_Name__r.Product_Type__c IN (:bg_ProductUtils.PRODUCT_TYPE_MAIN, :bg_ProductUtils.PRODUCT_TYPE_SITE)] > 0;
    }

    public static boolean ShowCreditCheckContact(Id userId) {
        /*
            Method to return if credit check contact is required
        */
        return (bg_UserUtils.GetUserById(userId).OperationCountry__c == bg_SiteUtils.COUNTRY_CODE_UK);
    }

    public static void CheckQuoteSyncStatus(Id quoteId) {
        /*
            Check if quote is syncing data
        */
        if(quoteId != null) {
            integer syncStatus = GetQuoteSyncStatus(quoteId);

            if(syncStatus == SYNC_STATUS_RUNNING) {
                throw new QuoteSyncException('Quote is syncing product configuration. Please try again.');
            } else if (syncStatus == SYNC_STATUS_ERROR) {
                throw new QuoteSyncException('Product configuration sync has failed. Please open the Product configurator and re-save.');
            }
        }
    }

    public static Integer GetQuoteSyncStatus(Id quoteId) {
        /*
            Check if quote is syncing data
        */
        Integer syncStatus;

        if(quoteId != null) {
            Quote__c quote = [SELECT Sync_In_Progress__c
                                FROM Quote__c
                                WHERE Id = :quoteId];

            // convert any nulls to decimal (zero)
            syncStatus = integer.valueOf(bg_Utilities.getDecimal(quote.Sync_In_Progress__c));

        }
        return syncStatus;
    }

    public static void SyncQuoteWithOpportunity(Id quoteId) {
        /*
            Sync Quote with opportunity line items
        */
        Quote__c syncQuote = new Quote__c(Id = quoteId);
        syncQuote.SyncWithOpportunity__c = true;
        update syncQuote;
    }

    public class ProductDiscountWrapper {
        private decimal TotalGrossPrice;
        private decimal TotalDiscountPrice;
        public ProductDiscountWrapper(decimal pTotalGrossPrice, decimal pTotalDiscountPrice) {
            TotalGrossPrice = pTotalGrossPrice;
            TotalDiscountPrice = pTotalDiscountPrice;
        }
        public void AddTotals(decimal pTotalGrossPrice, decimal pTotalDiscountPrice) {
            TotalGrossPrice += pTotalGrossPrice;
            TotalDiscountPrice += pTotalDiscountPrice;
        }
    }

    public static decimal GetMaxProductDiscountTotal(Id quoteId) {
        /*
            Get Max Product Discount Total
        */
        decimal maxDiscount = 0;

        if(quoteId != null) {
            map<string, ProductDiscountWrapper> productDiscountTotalsMap = new map<string, ProductDiscountWrapper>();

            set<string> productTypes = new set<string>{bg_ProductUtils.PRODUCT_TYPE_MAIN, bg_ProductUtils.PRODUCT_TYPE_SITE};

            for(Quote_Product__c qp : [SELECT Product_Name__r.Main_Product_Name__c, Total_Gross_Price__c, Total_Discounted_Price__c
                                        FROM Quote_Product__c
                                        WHERE Quote_Ref__c = :quoteId
                                            AND Product_Name__r.Product_Type__c IN :productTypes
                                            AND Opportunity_Site__c != null
                                            AND Deleted__c = false]) {

                if(!productDiscountTotalsMap.containsKey(qp.Product_Name__r.Main_Product_Name__c)) {
                    productDiscountTotalsMap.put(qp.Product_Name__r.Main_Product_Name__c, new ProductDiscountWrapper(qp.Total_Gross_Price__c, qp.Total_Discounted_Price__c));
                } else {
                    ProductDiscountWrapper pdw = productDiscountTotalsMap.get(qp.Product_Name__r.Main_Product_Name__c);
                    pdw.AddTotals(qp.Total_Gross_Price__c, qp.Total_Discounted_Price__c);
                }
            }

            for(ProductDiscountWrapper pdw : productDiscountTotalsMap.values())  {
                decimal grossTotal = pdw.TotalGrossPrice;
                decimal discountTotal = pdw.TotalDiscountPrice;
                decimal discount = 0;

                if((grossTotal - discountTotal) > 0) {
                    discount = ((grossTotal - discountTotal) / grossTotal) * 100;
                }

                if(discount > maxDiscount) {
                    maxDiscount = discount;
                }
            }
        }
        return maxDiscount;
    }
    
    public static void UpdateQuoteRegPathFlags(final List<Quote_Product__c> quoteProducts)
    {
        final Set<Id> quoteIds = new Set<Id>();
        
        for (Quote_Product__c quoteProduct : quoteProducts)
        {
            quoteIds.add(quoteProduct.Quote_Ref__c);
        }
        
        if (!quoteIds.isEmpty())
        {
            UpdateQuoteRegPathFlags(quoteIds);        
        }
        
    } // UpdateQuoteRegPathFlags

    public static void UpdateQuoteRegPathFlags(Set<Id> quoteIds) {
        /*
            Set delimited list of distinct product reg paths on quote
        */
        if (quoteIds.size() > 0) {
            List<Quote__c> quotes = [SELECT Id,ProductRegPaths__c FROM Quote__c WHERE Id IN :quoteIds];
            Map<Id, List<Quote_Product__c>> productsByQuoteId = new Map<Id, List<Quote_Product__c>>();
            for (Quote_Product__c qp : [SELECT Id,Quote_Ref__c,Registration_Path__c FROM Quote_Product__c WHERE Quote_Ref__c IN :quoteIds]) {
                if (!productsByQuoteId.containsKey(qp.Quote_Ref__c)) {
                    productsByQuoteId.put(qp.Quote_Ref__c, new List<Quote_Product__c>());
                }
                productsByQuoteId.get(qp.Quote_Ref__c).add(qp);
            }
            for (Quote__c quote : quotes) {
                List<Quote_Product__c> products = productsByQuoteId.get(quote.Id);
                String regPathList = '';
                if (products != null && products.size() > 0) {
                    for (Quote_Product__c product : products) {
                        if (product.Registration_Path__c <> null && product.Registration_Path__c <> '') {
                            if (!regPathList.contains(product.Registration_Path__c)) {
                                if (regPathList <> '') {
                                    regPathList += ';';
                                }
                                regPathList += product.Registration_Path__c;
                            }
                        }
                    }
                }
                quote.ProductRegPaths__c = regPathList;
            }
            update quotes;
        }
    }

    public static void UpdateQuoteProductUploaded(string quoteProductId) {
        /*
            Set Quote Product Uploaded Flag
        */
        Quote_Product__c qp = new Quote_Product__c(Id = quoteProductId);
        qp.FileUploaded__c = true;
        update qp;
    }

    public static string GetBSIMembershipWarning(Id oppId, Id accId, list<bg_Wrappers.QuoteProductWrapper> qpws) {
        /*
            Method to return BSI Membership Warning for quoting products requiring membership in some countries
        */
        // Get opportunity site countries
        list<OpportunitySite__c> siteList = bg_SiteUtils.GetOpportunitySites(oppId, bg_SiteUtils.RECORD_TYPE_NAME_NAMED);
        set<string> siteCountries = bg_SiteUtils.GetOpportunitySiteCountries(siteList);

        // get list of countries for sites and compare to sites requirining membership against the product
        set<string> reqBSIMembershipCountries = new set<string>();
        for(bg_Wrappers.QuoteProductWrapper qpw : qpws) {
            reqBSIMembershipCountries.addAll(bg_StringUtils.ConvertPicklistValueToSet(qpw.CountriesRequiringBSIMembership));
        }

        // Check selected countries vs countries flagged against products requiring BSI Membership
        boolean bsiMembershipRequired = false;
        for(string siteCountry : siteCountries) {
            if(reqBSIMembershipCountries.contains(siteCountry)) {
                bsiMembershipRequired = true;
                break;
            }
        }

        // Check if BSI Membership is required and show message
        string warningMessage;
        if(bsiMembershipRequired) {
            Account acc = bg_AccountUtils.GetAccountBSIMembership(accId);
            if(string.isBlank(acc.BSIMembershipNo__c)) {
                // -- include link to account?
                warningMessage = string.valueOf(Label.CustomerHasNoBSIMembership);
            } else {
                // -- show membership no, expiry and link to account?
                warningMessage = string.format(Label.CustomerHasBSIMembership, new string[]{acc.BSIMembershipNo__c, acc.BSIMembershipExpiryDate__c.format()});
            }
        }

        return warningMessage;
    }

    public static set<Id> QuotesSigned(map<Id, echosign_dev1__SIGN_Agreement__c> signedAgreementMap, map<Id, string> contactNamesMap) {
        /*
            Queries the related quotes to the agreements
            Builds a set of opportunities for signed proposals
            sets the validation fields for signed proposals or fact validations
            Updates the quotes
            Returns a list of opportunity ids where the quote is a proposal
            - 23414 BrightGen Updated to include has signed agreement
        */
        // Get Quotes
        list<Quote__c> quotes = [SELECT ValidationStatus__c, ValidationCheck__c, ValidationDate__c, ValidatedBy__c,
                                    SkipCustomer__c, Opportunity_Name__c, Opportunity_Name__r.hasSignedAgreement__c
                                 FROM Quote__c
                                 WHERE Id IN :signedAgreementMap.keySet()];

        Set<Id> oppIds = QuotesSigned(signedAgreementMap, contactNamesMap, quotes);

        // update quotes
        Utility.lockQuoteTrigger = true;
        update quotes;
        return oppIds;
    }

    public static set<Id> QuotesSigned(map<Id, echosign_dev1__SIGN_Agreement__c> signedAgreementMap, map<Id, string> contactNamesMap, list<Quote__c> quotes) {
        /*
            Builds a set of opportunities for signed proposals
            sets the validation fields for signed proposals or fact validations
            Returns a list of opportunity ids where the quote is a proposal
        */
        Set<Id> oppIds = new set<Id>();
        QuoteSetting__c setting = QuoteSetting__c.getInstance();
        for(Quote__c quote : quotes) {
            //For fact validations and proposals, fill in the validation complete fields
            if(signedAgreementMap.get(quote.Id).Template_Type__c == bg_DocumentUtils.DOCUMENT_TYPE_FACT_VALIDATION ||
            (signedAgreementMap.get(quote.Id).Template_Type__c == bg_DocumentUtils.DOCUMENT_TYPE_PROPOSAL && quote.SkipCustomer__c)) {
                String name = contactNamesMap.get(signedAgreementMap.get(quote.Id).echosign_dev1__Recipient__c);
                bg_QuoteUtils.ValidationComplete(quote, name, setting);
            }

            //for proposals, build a list of opportunity id's to return
            //23414 Extended to check hasSIgnedAgreement is false.
            if (signedAgreementMap.get(quote.Id).Template_Type__c == bg_DocumentUtils.DOCUMENT_TYPE_PROPOSAL &&
                quote.Opportunity_Name__r.hasSignedAgreement__c == False)
                {
                oppIds.add(quote.Opportunity_Name__c);
            }
        }
        return oppIds;
    }

    public static void ValidationComplete(Quote__c quote, String validatedBy, QuoteSetting__c setting) {
        /*
            Sets the validation fields on the quote
        */
        quote.ValidationStatus__c = setting.StatusApproved__c;
        quote.ValidationCheck__c = true;
        quote.ValidationDate__c = DateTime.now();
        quote.ValidatedBy__c = validatedBy;
    }
    
    /* 
      Set the default controlling location
      1) if there is only one site then use that
      2) if there are multiple sites and only one of them is of type default then use that, otherwise leave as none
  */
  
    public static ID getDefaultControllingLocation(Opportunity opp)
    {
    ID defaultControllingLocation = null;
    Integer numberOfDefaultSites = 0;
    ID defaultSiteID = null;
    
    List<OpportunitySite__c> oppSites = bg_SiteUtils.GetOpportunitySites(opp.Id);
    if (oppSites.size() == 1)
    {
      defaultControllingLocation = oppSites[0].Site__c;
    }
    else
    {
      for (OpportunitySite__c s :  oppSites)
      {
        if (s.Site__r.RecordType.DeveloperName == bg_SiteUtils.RECORD_TYPE_NAME_DEFAULT)
        {
          defaultSiteID = s.Site__c;
          numberOfDefaultSites++;
        }
      }
    }
    
    if (numberOfDefaultSites == 1)
    {
      defaultControllingLocation = defaultSiteID;
    }
    
    return defaultControllingLocation;
    }
        
}