/********************************************************************
 * bg_QuoteApprovalUtils
 *
 * Utility methods to support Quote Approval functions
 *
 *
 * Author : ?
 * Created: 26-02-2014
 * Changes: 03-11-2016 ADS - SoW027
 *                         - Added IsQuoteOperationsApprovalQueueMember
 *                         - Removed use of and references to Operations Team Approver
 *                         - Added APPROVAL_STATUS_DECLINED
 * 
 ********************************************************************/
public with sharing class bg_QuoteApprovalUtils {

    public class DiscountException extends Exception {}
    
    public static final integer DISCOUNT_APPROVER_NA       = -1;
    public static final integer DISCOUNT_APPROVER_NONE     = 0;
    public static final integer DISCOUNT_APPROVER_MANAGER  = 1;
    public static final integer DISCOUNT_APPROVER_DIRECTOR = 2;
    
    public static final string CCODE_PROFILE_TYPE_TRAINEE = 'Trainee';
    public static final string CCODE_PROFILE_TYPE_QUALIFIED = 'Qualified';
    public static final string CCODE_PROFILE_TYPE_APPROVER = 'Approver';
    
    public static final integer MAX_DISCOUNT_LEVELS = 10;
    public static final integer MAX_DISCOUNT_LEVEL_APPROVERS = 10;
    public static final integer DISCOUNT_DIRECTOR_LEVEL = 2;
    
    public static final string DISCOUNT_LINE_MANAGER = 'LINE_MANAGER';
    public static final string DISCOUNT_PRODUCT_MANAGER = 'PRODUCT_MANAGER';

    public static final decimal NO_DISCOUNT_DIFFERENCE = -1;
    public static final decimal NO_DISCOUNTABLE_PRODUCTS = -2;

    public static final string APPROVAL_STATUS_SUBMITTED = 'Submitted';
    public static final string APPROVAL_STATUS_NOT_SUBMITTED = 'Not Submitted';
    public static final string APPROVAL_STATUS_PENDING = 'Pending';
    public static final string APPROVAL_STATUS_APPROVED = 'Approved';
    public static final string APPROVAL_STATUS_DECLINED = 'Declined';

    public static list<Quote_Product_Approval__c> GetQuoteProductApprovals(Id quoteId) { 
        /* Return list of quote product approvals */
        return GetQuoteProductApprovals(new set<Id>{quoteId});
    }

    public static list<Quote_Product_Approval__c> GetQuoteProductApprovals(set<Id> quoteIds) { 
        /*
            Return list of quote product approvals
        */
        list<Quote_Product_Approval__c> quoteProductApprovals = new list<Quote_Product_Approval__c>();
        quoteProductApprovals.addAll([SELECT Id, Quote__c, Product__c, Product_Name__c, Product__r.Name, Product__r.CCode__c, CCodeApprover__c, CCodeStatus__c,
                                CCodeDateTimeSubmitted__c, CCodeDateTimeApproved__c, CCodeDateTimeDeclined__c, Discount_Percentage__c 
                            FROM Quote_Product_Approval__c 
                            WHERE Quote__c IN :quoteIds]);
        return quoteProductApprovals;       
    }

    public static map<Id, Quote_Product_Approval__c> GetQuoteProductApprovalsMap(Id quoteId) {
        /*
            Return list of quote product approvals map
        */
        map<Id, Quote_Product_Approval__c> qpaMap = new map<Id, Quote_Product_Approval__c>();
        list<Quote_Product_Approval__c> qpas = GetQuoteProductApprovals(quoteId);
        for(Quote_Product_Approval__c qpa : qpas) {
            qpaMap.put(qpa.Product__c, qpa);
        }
        return qpaMap;
    }

    public static map<Id, map <Id, Quote_Product_Approval__c>> GetQuoteProductApprovalsMap2(set<Id> quoteIds) {
        /*
            Return list of quote product approvals map
        */
        map<Id, map <Id, Quote_Product_Approval__c>> qpaMap = new map<Id, map <Id, Quote_Product_Approval__c>>();
        list<Quote_Product_Approval__c> qpas = GetQuoteProductApprovals(quoteIds);
        for(Quote_Product_Approval__c qpa : qpas) {
            if(!qpaMap.containsKey(qpa.Quote__c)) {
                qpaMap.put(qpa.Quote__c, new map<Id, Quote_Product_Approval__c>());
            }
            qpaMap.get(qpa.Quote__c).put(qpa.Product__c, qpa);
        }
        return qpaMap;
    }

    public static void CreateQuoteProductApprovalLines(list<Quote__c> quotes) {
        /*
            Create quote product approval lines
        */
        // quote to update quote approval records
        if (!quotes.isEmpty()) {
            // convert list to quote map
            map<Id, Quote__c> quoteMap = new map<Id, Quote__c>(quotes);         
            // List of QPA to insert
            list<Quote_Product_Approval__c> insQPAs = new list<Quote_Product_Approval__c>();        
            // List of QPA to delete
            list<Quote_Product_Approval__c> delQPAs = new list<Quote_Product_Approval__c>();

            // Get map of existing quote product approvals
            map<Id, map<Id, Quote_Product_Approval__c>> qpaMap = GetQuoteProductApprovalsMap2(quoteMap.keySet());
            // Get quote product name map
            map<Id, set<string>> quoteProductNameMap = bg_QuoteUtils.GetMainQuoteProductNameMap(quoteMap.keySet(), true, null);

            // Build list of main product names from quote products
            set<string> mainProductNames = new set<string>();
            for(set<string> quoteProductNames : quoteProductNameMap.values()) {
                mainProductNames.addAll(quoteProductNames);
            }

            // Build list of main product map   
            map<string, Id> mainProductMap = new map<string, Id>();
            for(Product__c prod : [SELECT Id, Name FROM Product__c WHERE Name IN :mainProductNames]) {
                mainProductMap.put(prod.name, prod.Id);
            }

            // loop through each quote      
            for(Quote__c quote : quotes) {
                if(quoteProductNameMap.containsKey(quote.Id)) {
                    set<string> quoteProductNames = quoteProductNameMap.get(quote.Id);
                    // loop through each product name
                    for(string productName : quoteProductNames) {
                        if(productName != null && mainProductMap.containsKey(productName)) {
                            // build list to insert
                            Id mainProductId = mainProductMap.get(productName);                         
                            if(!qpaMap.containsKey(quote.Id) || !qpaMap.get(quote.Id).containsKey(mainProductId)) {                             
                                Quote_Product_Approval__c qpa = new Quote_Product_Approval__c();
                                qpa.Quote__c = quote.Id;
                                qpa.Product__c = mainProductId;
                                insQPAs.add(qpa);
                            } else {
                                // exists, remove from map - items left in list will be deleted
                                qpaMap.get(quote.Id).remove(mainProductId);
                            }
                        }
                    }
                }
                // Add items left in map (to delete)
                if(qpaMap.containsKey(quote.Id)) {
                    delQPAs.addAll(qpaMap.get(quote.Id).values());
                }
            }
            // Insert new QPAs
            if(!insQPAs.isEmpty()) { insert insQPAs; }
            // Delete old QPAs
            if(!delQPAs.isEmpty()) { delete delQPAs; }
        }
    
    }

    public static set<Id> GetDiscountLevelApproverIds(QuoteSetting__c qs, integer level, string country, User owner) {
        /*
            Method to return discount user level map (based on country code)
        */              
        // Get object field map
        map<string, Schema.SObjectField> fieldMap = bg_Utilities.GetObjectFieldMap('ConversionScore__c');

        // Get list from default country settings
        ConversionScore__c cs = bg_CustomSettingsUtils.GetDefaultCountrySettings(country);
        
        set<Id> userIds = new set<Id>(); 
        for (integer i = 1; i < MAX_DISCOUNT_LEVEL_APPROVERS; i++) {
            string fname = GetDiscountLevelUserFieldName(level, i);
            if (fieldMap.containsKey(fname)) {
                if (cs.get(fname) != null)
                    if(cs.get(fname) == DISCOUNT_LINE_MANAGER) {
                        Id managerId = GetUserManagerId(qs, owner);
                        if(managerId != null) { userIds.add(managerId); }
// RJ: 18/06/2014
// Product Manager change removed until discount approval have been reviewed
//                  } else if(cs.get(fname) == DISCOUNT_PRODUCT_MANAGER) {
//                      Id managerId = GetUserProductManagerId(qs, owner);
//                      if(managerId != null) { userIds.add(managerId); }                       
                    } else {
                        userIds.add((Id)cs.get(fname));
                    }
            } else {
                break;
            }
        }
        return userIds;
    }

    private static string GetDiscountLevelUserFieldName(integer level, integer userNo) {
        /* Return GetDiscountLevelUserFieldName */
        return 'DiscountLevel' + level + 'User' + userNo + '__c';
    }
    
    private static string GetDiscountLevelFieldName(integer level) {
        /* Return GetDiscountLevelUserFieldName */
        return 'DiscountLevel' + level + '__c';
    }
    
    public static map<string, set<CCode_Profile__c>> GetCCodeApprovers(set<string> ccodes) {
        /* Method to return list of C Code approvers */
        return GetCCodeApprovers(ccodes, null);
    }

    public static map<string, set<CCode_Profile__c>> GetCCodeApprovers(set<string> ccodes, Id userId) {
        /* Method to return list of C Code approvers */
        return GetCCodeApprovers(ccodes, userId, null);
        
    }

    public static map<string, set<CCode_Profile__c>> GetCCodeApprovers(set<string> ccodes, Id userId, string countryCode) {
        /*
            Method to return list of C Code approvers
        */
        set<string> codeLevels = new set<string>{CCODE_PROFILE_TYPE_APPROVER};
        if(!bg_StringUtils.IsBlank(userId)) {
            codeLevels.add(CCODE_PROFILE_TYPE_QUALIFIED);
            codeLevels.add(CCODE_PROFILE_TYPE_TRAINEE);
        }       

        list<CCode_Profile__c> ccodeProfiles = GetUserCCodeProfiles(ccodes, codeLevels, userId, countryCode);
        
        map<string, set<CCode_Profile__c>> approversMap = new map<string, set<CCode_Profile__c>>();
        for(CCode_Profile__c ccp : ccodeProfiles) {
            for (string ccode : ccodes) {
                String ccode_key = removeSpecialCharsinCCode(ccode);
                if(ccp.get(ccode_key + '__c') != null && codeLevels.contains((string)ccp.get(ccode_key + '__c'))) {
                    if(!approversMap.containsKey(ccode)) {
                        approversMap.put(ccode, new set<CCode_Profile__c>());
                    }
                    approversMap.get(ccode).add(ccp);
                }
            }
        }

        return approversMap;        
    }
    
    public static CCode_Profile__c GetUserCCodeProfile(Id userId) {
        /* Return User C-Code Profile */
        list<CCode_Profile__c> ccodeProfiles = GetUserCCodeProfiles(null, null, userId, null);
        if(!ccodeProfiles.isEmpty()) {
            return ccodeProfiles[0];
        } else {
            return new CCode_Profile__c(User__c = userId, Active__c = false);
        }
    }

    public static list<CCode_Profile__c> GetUserCCodeProfiles(set<string> ccodes, set<string> codeLevels, Id userId, string countryCode) {
        /*
            Return user CCode Profile
        */
        map<string, Schema.SObjectField> fieldMap = bg_Utilities.GetObjectFieldMap('CCode_Profile__c');

        string query = 'SELECT User__c, User__r.Name, Active__c ';
        if(ccodes != null && !ccodes.isEmpty()) {
            for(string ccode : ccodes) {
                string fname = removeSpecialCharsinCCode(ccode) + '__c';
                if(fieldMap.containsKey(fname)) { query += ', ' + fname + ' '; }
            }
        }
        query += 'FROM CCode_Profile__c ' +
                 'WHERE User__c != null ';
        
        // filter by user Id
        if(!bg_StringUtils.IsBlank(userId)) {
            query += ' AND User__c = :userId ';
        }

        // filter by country code
        if(!bg_StringUtils.IsBlank(countryCode)) {
            if(countryCode == 'AU' || countryCode == 'NZ')
                query += ' AND User__r.OperationCountry__c IN (\'AU\', \'NZ\') ';
            else
                query += ' AND User__r.OperationCountry__c = :countryCode ';            
        }
    
        // filter by C-Codes
        string ccodeFilter = '';
        if(bg_StringUtils.IsBlank(userId) && ccodes != null && !ccodes.isEmpty()) {
            for(string ccode : ccodes) {
                string fname = removeSpecialCharsinCCode(ccode) + '__c';
                if(fieldMap.containsKey(fname)) {
                    ccodeFilter += fname + ' IN :codeLevels OR ';
                }
            }
            if(ccodeFilter.length() > 0) {
                query += ' AND (' + ccodeFilter.removeEnd(' OR ') + ')';
            }
        }

        query = query + ' ORDER BY User__r.Name ASC';
        return database.query(query);   
    }
    
    public static map<string, set<Quote_Product__c>> GetCCodeProductMap(Id quoteId) {
        /*
            Return map of Product C Codes
        */
        map<string, set<Quote_Product__c>> ccodeProductMap = new map<string, set<Quote_Product__c>>();
        list<Quote_Product__c> quoteProducts = bg_QuoteUtils.GetQuoteProducts(quoteId, true, bg_ProductUtils.PRODUCT_TYPE_MAIN);

        for(Quote_Product__c qp : quoteProducts) {
            if(!bg_StringUtils.IsBlank(qp.Product_Name__r.CCode__c)) {
                if(!ccodeProductMap.containsKey(qp.Product_Name__r.CCode__c)) {
                    ccodeProductMap.put(qp.Product_Name__r.CCode__c, new set<Quote_Product__c>());                  
                }
                ccodeProductMap.get(qp.Product_Name__r.CCode__c).add(qp);
            }
        }
        
        return ccodeProductMap;
    }
    
    public static set<string> UpdateCCodeStatus(Quote__c quote, map<string, set<CCode_Profile__c>> userCCodes, set<string> cCodes, list<Quote_Product_Approval__c> quoteProductApprovals) {
        /*
            Method to update CCode approval fields
        */      
        QuoteSetting__c qs = bg_CustomSettingsUtils.GetQuoteSettings();

        set<string> ccodesRequired = new set<string>();
        string quoteCCodeStatus = qs.StatusNA__c;
        
        CCode_Profile__c usercodeProfile = GetUserCCodeProfile(quote.ownerId);
        
        for(Quote_Product_Approval__c qpa : quoteProductApprovals) {
            if(bg_StringUtils.IsBlank(qpa.CCodeStatus__c) || qpa.CCodeStatus__c == qs.StatusNA__c || qpa.CCodeStatus__c == qs.StatusDraft__c) {
                string level = '';
                if(userCCodes.containsKey(qpa.Product__r.CCode__c)) {
                    string fname = removeSpecialCharsinCCode(qpa.Product__r.CCode__c) + '__c';
                    level = (string)(new list<CCode_Profile__c>(userCCodes.get(qpa.Product__r.CCode__c))[0].get(fname));
                }

                // Check if C-Code review is required
                if(!usercodeProfile.Active__c || bg_StringUtils.IsBlank(qpa.Product__r.CCode__c) 
                    || level == CCODE_PROFILE_TYPE_QUALIFIED || level == CCODE_PROFILE_TYPE_APPROVER) {
                    // C-Code not applicable
                    qpa.CCodeStatus__c = qs.StatusNA__c;
                } else {
                    // C-Code review required                   
                    ccodesRequired.add(qpa.Product__r.CCode__c);
                    qpa.CCodeStatus__c = qs.StatusDraft__c;
                    qpa.IsOwnerTrainee__c = (level == CCODE_PROFILE_TYPE_TRAINEE);
                }
            }

            // Waiting for an approval?
            if((quoteCCodeStatus != qs.StatusRejected__c || quoteCCodeStatus != qs.StatusDraft__c) 
                    && qpa.CCodeStatus__c == qs.StatusWaiting__c)  {
                quoteCCodeStatus = qs.StatusWaiting__c;
            // Rejected?
            } else if(qpa.CCodeStatus__c != qs.StatusDraft__c && qpa.CCodeStatus__c == qs.StatusRejected__c) {
                quoteCCodeStatus = qs.StatusRejected__c;
            // Approved?
            } else if(quoteCCodeStatus == qs.StatusNA__c && qpa.CCodeStatus__c == qs.StatusApproved__c) {
                quoteCCodeStatus = qs.StatusApproved__c;
            // Draft?
            } else if(qpa.CCodeStatus__c == qs.StatusDraft__c) {
                quoteCCodeStatus = qs.StatusDraft__c;
            }
        }
        
        // Check if CCode status is different
        if(quoteCCodeStatus != quote.CCodeStatus__c) {
            quote.CCodeStatus__c = quoteCCodeStatus;
        }
        
        return ccodesRequired; // Return if C-Code review is required.
    }
    
    public static Boolean CheckQuoteApprovalsPending(List<Quote_Product_Approval__c> productApprovalsToUpdate){
        /*
            Returns true if any product approval is pending
        */
        //List<Quote_Product_Approval__c> productApprovalsToUpdate = GetQuoteProductApprovals(quoteId);
        Boolean returnVal = false;
        
        for(Quote_Product_Approval__c productApproval : productApprovalsToUpdate){
            if(productApproval.CCodeStatus__c == APPROVAL_STATUS_PENDING){
                returnVal = true;
                break;
            }
        }
        return returnVal;       
    }
    
    public static Boolean CheckQuoteApprovalsPending(Set<Id> quoteId){
        /*
            Returns true if any product approval is pending
        */
        List<Quote_Product_Approval__c> productApprovalsToUpdate = GetQuoteProductApprovals(quoteId);

        return CheckQuoteApprovalsPending(productApprovalsToUpdate);        
    }
    
    public static Boolean CheckQuoteApprovalsPending(Id quoteId){
        /*
            Returns true if any product approval is pending     
        */
        return CheckQuoteApprovalsPending(new Set<Id> {quoteId});
    }
    
    public static void ResetQuoteApprovalFields(Quote_Product_Approval__c productApproval){
        /*
            Sets the quote approval back to its default state
        */
        productApproval.CCodeStatus__c = null;
        productApproval.CCodeApprover__c = null;
        productApproval.CCodeDateTimeApproved__c = null;
        productApproval.CCodeDateTimeDeclined__c = null;
        productApproval.CCodeDateTimeSubmitted__c = null;
    }
    
    public static void ResetQuoteApprovalsByQuoteId(Set<Id> quoteId){
        /*
            Sets the approval status for each approval that matches the quotes to not submitted
            Throws an error if the status is set to pending
        */
        List<Quote_Product_Approval__c> productApprovalsToUpdate = GetQuoteProductApprovals(quoteId);
        if(CheckQuoteApprovalsPending(productApprovalsToUpdate)){
            throw new QuoteApprovalException(Label.Quote_Reset_Approval_Pending);
        }
        
        for(Quote_Product_Approval__c productApproval : productApprovalsToUpdate){
            /*if(APPROVAL_STATUS_PENDING == productApproval.CCodeStatus__c){
                throw new QuoteApprovalException(Label.Quote_Reset_Approval_Pending);
            }*/
            ResetQuoteApprovalFields(productApproval);
        }
        update productApprovalsToUpdate;
    }

    public static void ResetQuoteApprovalsByQuoteId(Id quoteId){
        /*
            Sets the approval status for each approval that matches the quote to not submitted
            Throws an error if the status is set to pending
        */
        ResetQuoteApprovalsByQuoteId(new Set<Id> {quoteId});        
    }

    public static integer PopulateDiscountApprovers(Quote__c quote, string countryCode, User owner, set<Id> approverIds) {
        /* Method to update discount approvers */       
        decimal maxProductDiscount = bg_QuoteUtils.GetMaxProductDiscountTotal(quote.Id);
        return PopulateDiscountApprovers(quote, countryCode, owner, approverIds, maxProductDiscount);
    }
    
    public static integer PopulateDiscountApprovers(Quote__c quote, string countryCode, User owner, set<Id> approverIds, decimal maxProductDiscount) {
        /*
            Method to update discount approvers
        */
        QuoteSetting__c qs = bg_CustomSettingsUtils.GetQuoteSettings();
        ConversionScore__c cs = bg_CustomSettingsUtils.GetDefaultCountrySettings(countryCode);
        integer result = DISCOUNT_APPROVER_NA;
        
        if(cs != null) {                                                
            if(cs.UseDiscountBandApprovers__c) {        
                result = ApplyDiscountBandApprovers(quote, maxProductDiscount, qs, cs, owner);
            } else if(cs.UseDiscountLevelApprovers__c) {
                result = ApplyDiscountLevelsApprovers(quote, maxProductDiscount, qs, cs, countryCode, owner, approverIds);
            } else {
                throw new DiscountException('The default country discount setting has no bands/levels enabled (' + countryCode + ')');
            }
        } else {
            throw new DiscountException('The default country discount setting does not exist (' + countryCode + ')');
        }
        return result;
    }

    public static integer ApplyDiscountLevelsApprovers(Quote__c quote, decimal discountAmount, QuoteSetting__c qs, ConversionScore__c cs, string countryCode, User owner, set<Id> approverIds) {
        /*
            Apply Discount Levels Approvers
        */
        boolean isDirector = false;

        // Get object field map
        map<string, Schema.SObjectField> fieldMap = bg_Utilities.GetObjectFieldMap('ConversionScore__c');
                    
        if(bg_StringUtils.IsBlank(quote.DiscountStatus__c) && discountAmount == 0) {
            if(bg_QuoteUtils.OverrideQuoteStatus(quote.DiscountStatus__c)) { quote.DiscountStatus__c = qs.StatusNA__c; }
        } else {
            // loop through each level
            decimal lastDiscountLevel = 0;

            for (integer level = 1; level < MAX_DISCOUNT_LEVELS; level++) {
                string fname = GetDiscountLevelFieldName(level);
                if (fieldMap.containsKey(fname)) {
                    if (cs.get(fname) != null) {
                        decimal levelDiscount = (decimal)(cs.get(fname));
                        if(discountAmount >= lastDiscountLevel && discountAmount < levelDiscount) {
                            if((level-1) > 0) { // level must be over 0
                                approverIds.addAll(GetDiscountLevelApproverIds(qs, level-1, countryCode, owner));
                                isDirector = (level-1 >= DISCOUNT_DIRECTOR_LEVEL);
                                if(bg_QuoteUtils.OverrideQuoteStatus(quote.DiscountStatus__c)) { quote.DiscountStatus__c = qs.StatusDraft__c; }
                            } else {
                                if(bg_QuoteUtils.OverrideQuoteStatus(quote.DiscountStatus__c)) { quote.DiscountStatus__c = qs.StatusNA__c; }
                            }
                            break;
                        }
                        lastDiscountLevel = levelDiscount;
                    } else {
                        if(discountAmount >= lastDiscountLevel && level-1 > 0) {
                            // discount Amount more than last level
                            approverIds.addAll(GetDiscountLevelApproverIds(qs, level-1, countryCode, owner));
                            isDirector = (level-1 >= DISCOUNT_DIRECTOR_LEVEL);
                            if(bg_QuoteUtils.OverrideQuoteStatus(quote.DiscountStatus__c)) { quote.DiscountStatus__c = qs.StatusDraft__c; }
                        } else { 
                            if(bg_QuoteUtils.OverrideQuoteStatus(quote.DiscountStatus__c)) { quote.DiscountStatus__c = qs.StatusNA__c; }
                        }
                    }
                } else {
                    if(discountAmount >= lastDiscountLevel && level-1 > 0) {
                        // discount Amount more than last level
                        approverIds.addAll(GetDiscountLevelApproverIds(qs, level-1, countryCode, owner));
                        isDirector = (level-1 >= DISCOUNT_DIRECTOR_LEVEL); // Director at level 2
                        if(bg_QuoteUtils.OverrideQuoteStatus(quote.DiscountStatus__c)) { quote.DiscountStatus__c = qs.StatusDraft__c; }
                    } else {
                        if(bg_QuoteUtils.OverrideQuoteStatus(quote.DiscountStatus__c)) { quote.DiscountStatus__c = qs.StatusNA__c; }                        
                    }
                    break;
                }
            }
        }
        // return result
        if(quote.DiscountStatus__c == qs.StatusNA__c) {
            return DISCOUNT_APPROVER_NA;            
        } else if(approverIds.isEmpty()) {
            return DISCOUNT_APPROVER_NONE;          
        } else if(!isDirector) {
            if(approverIds.size() == 1) { quote.ManagerDiscount__c = new list<Id>(approverIds)[0];}
            return DISCOUNT_APPROVER_MANAGER;
        } else  {
            if(approverIds.size() == 1) { quote.DirectorDiscount__c = new list<Id>(approverIds)[0];}
            return DISCOUNT_APPROVER_DIRECTOR;
        }
    }

    private static Id GetDelegatedManagerId(QuoteSetting__c qs, User owner) {
        Id userId;
        // No Manager, use Delegated Approver
        if(!bg_StringUtils.IsBlank(owner.DelegatedApproverId)) {    
            userId = owner.DelegatedApproverId;
        // No Delegated, use Global Discount Approver   
        } else if(!bg_StringUtils.IsBlank(qs.GlobalDiscountApprover__c)) {
            userId = qs.GlobalDiscountApprover__c;
        }
        return userId;  
    }
/*  
    public static Id GetUserProductManagerId(QuoteSetting__c qs, User owner) {
        / *
            Return User Product Manager Id
        * /
        Id userId;
        // Manager on User is available
        if(!bg_StringUtils.IsBlank(owner.ProductManager__c)) { 
            userId = owner.ProductManager__c;
        // No Manager, use Delegated Approver
        } else {
            userId = GetDelegatedManagerId(qs, owner);
        }
        return userId;  
    }
*/  
    public static Id GetUserManagerId(QuoteSetting__c qs, User owner) {
        /*
            Return User Manager Id
        */
        Id userId;
        // Manager on User is available
        if(!bg_StringUtils.IsBlank(owner.ManagerId)) { 
            userId = owner.ManagerId;
        // No Manager, use Delegated Approver
        } else {
            userId = GetDelegatedManagerId(qs, owner);
        }
        return userId;      
    }

    public static integer ApplyDiscountBandApprovers(Quote__c Quote, decimal discountTotal, QuoteSetting__c qs, ConversionScore__c cs, User owner) {
        /*
            Apply Discount Band Approvers
        */
        if (discountTotal == null) {
            if(bg_QuoteUtils.OverrideQuoteStatus(quote.DiscountStatus__c)) { quote.DiscountStatus__c = qs.StatusNA__c; }
        } else if(discountTotal < cs.DiscountBandManager__c) {
            if(bg_StringUtils.IsBlank(quote.DiscountStatus__c)) { quote.DiscountStatus__c = qs.StatusNA__c; }
        } else if(discountTotal >= cs.DiscountBandManager__c && discountTotal < cs.DiscountBandDirector__c) {
            quote.ManagerDiscount__c = GetUserManagerId(qs, owner);
            quote.DirectorDiscount__c = null;
            if(bg_QuoteUtils.OverrideQuoteStatus(quote.DiscountStatus__c)) { quote.DiscountStatus__c = qs.StatusDraft__c; }
        } else if(discountTotal >= cs.DiscountBandDirector__c) {
            quote.DirectorDiscount__c = cs.Director__c;
            quote.ManagerDiscount__c = null;
            if(bg_QuoteUtils.OverrideQuoteStatus(quote.DiscountStatus__c)) { quote.DiscountStatus__c = qs.StatusDraft__c; }
        }
        
        // return result
        if(!bg_StringUtils.IsBlank(quote.ManagerDiscount__c)) {
            return DISCOUNT_APPROVER_MANAGER;
        } else if(!bg_StringUtils.IsBlank(quote.DirectorDiscount__c)) {
            return DISCOUNT_APPROVER_DIRECTOR;
        } else if(quote.DiscountStatus__c == qs.StatusNA__c) {
            return DISCOUNT_APPROVER_NA;
        } else {
            return DISCOUNT_APPROVER_NONE;
        }       
    }
    
    public static void SaveQuoteProductApprovals(list<Quote_Product_Approval__c> QPAs) {
        /*
            Save Quote Product Approval records
        */
        
        // Get Quote Settings (used by VF page)
        QuoteSetting__c cs = bg_CustomSettingsUtils.GetQuoteSettings();
        // build list of records to update
        list<Quote_Product_Approval__c> updQPAs = new list<Quote_Product_Approval__c>();
        for(Quote_Product_Approval__c qpa : QPAs) {
            if(qpa.CCodeStatus__c != cs.StatusWaiting__c) {
                updQPAs.add(qpa);
            }
        }
        // Save records
        if(!updQPAs.isEmpty()) {
            update updQPAs;
        }
    }
    
    
    public static void UpdateDiscounts(Id quoteId, map<Id, Quote_Product_Approval__c> qpaMap) {
        /*
            Update Discount Values
        */
        set<string> products = new set<string>();
        map<string, Quote_Product_Approval__c> qpaProdMap = new map<string, Quote_Product_Approval__c>();

        for(Quote_Product_Approval__c qpa : [SELECT Id, Discount_Percentage__c, Product__r.Name 
                                             FROM Quote_Product_Approval__c 
                                             WHERE Id IN :qpaMap.keySet()]) {
            // discount changed?
            if(qpaMap.containsKey(qpa.Id)) { //&& qpaMap.get(qpa.Id).Discount_Percentage__c != qpa.Discount_Percentage__c
                // Update quote approval records
                qpa.Discount_Percentage__c = qpaMap.get(qpa.Id).Discount_Percentage__c;
                qpaProdMap.put(qpa.Product__r.Name, qpa);
            }               
        }

        // Update Discounts on Quote Parts
        if(!qpaProdMap.isEmpty()) {
            UpdatePartDiscounts(quoteId, qpaProdMap);
        }

        // update discounts     
        if(!qpaProdMap.isEmpty()) {
            update qpaProdMap.values();
        }
    }

    public static void UpdatePartDiscounts(Id quoteId, map<string, Quote_Product_Approval__c> qpaProdMap) {
        /*
            Update Quote Part Discount Percentage
        */
        list<Quote_Part__c> qps = bg_QuoteUtils.GetQuoteParts(quoteId, true, qpaProdMap.keySet());
        list<Quote_Part__c> updQPS = new list<Quote_Part__c>();
        
        for(Quote_Part__c qp : qps) {
            decimal discount = qpaProdMap.get(qp.Product_Name__c).Discount_Percentage__c;
            if(qp.Discount_Percentage__c != discount) {
                Quote_Part__c updQP = new Quote_Part__c(Id = qp.Id);
                updQP.Discount_Percentage__c = discount;
                updQPS.add(updQP);
            }
        }
        
        // Update Quote Parts with new discount
        if(!updQPS.isEmpty()) {
            update updQPS;
        }
    }
    
    public static Approval.ProcessResult SubmitForApproval(Id objectId, string comment) {
        /*
            Submit record for approval
        */
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments(comment);
        req.setObjectId(objectId);
        Approval.ProcessResult result = Approval.process(req);
        return result;
    }
    
    public static boolean AllDiscountsSet(Id quoteId) {
        /*
            Method to check if any discounts have been set yet?
        */
        integer discountedParts = [SELECT Id FROM Quote_Part__c 
                                    WHERE Quote_Ref__c = :quoteId
                                        AND IsDiscountable__c = true
                                        AND Discount_Percentage__c != null
                                        AND IsQuestion__c = false
                                    LIMIT 1].size();

        integer discountedQuoteApprovals = [SELECT Id FROM Quote_Product_Approval__c
                                            WHERE Quote__c = :quoteId
                                                AND Discount_Percentage__c != null
                                            LIMIT 1].size();    

        return (discountedParts > 0 || discountedQuoteApprovals > 0);       
    }

    public static map<string, decimal> GetProductDiscountMap(Id quoteId) {
        /* Get Product Discount Map */
        list<Quote_Product_Approval__c> qpas = GetQuoteProductApprovals(quoteId);
        return GetProductDiscountMap(quoteId, false, qpas);
    }

    public static map<string, decimal> GetProductDiscountMap(Id quoteId, boolean checkParts, list<Quote_Product_Approval__c> qpas) {
        /*
            Check if there are discountable that have been overriden.
        */
        map<string, decimal> productDiscountMap = new map<string, decimal>();
        // get list of quote product approval records
        for(Quote_Product_Approval__c qpa : qpas) {
            productDiscountMap.put(qpa.Product__r.Name, bg_Utilities.getDecimal(qpa.Discount_Percentage__c));
            if(checkParts) {
                // Check there are discountable products?
                list<Quote_Part__c> results = new list<Quote_Part__c>();
                results.addAll([SELECT Id
                                FROM Quote_Part__c 
                                WHERE Quote_Ref__c = :quoteId 
                                    AND (Product_Name__c = :qpa.Product__r.Name OR ProjectProductName__c = :qpa.Product__r.Name)
                                    AND IsDiscountable__c = true]);
                if(results.size() == 0) {
                    productDiscountMap.put(qpa.Product__r.Name, NO_DISCOUNTABLE_PRODUCTS);
                } else { 
                    results.clear();
                    results.addAll([SELECT Id
                                    FROM Quote_Part__c 
                                    WHERE Quote_Ref__c = :quoteId 
                                        AND (Product_Name__c = :qpa.Product__r.Name OR ProjectProductName__c = :qpa.Product__r.Name)
                                        AND IsDiscountable__c = true 
                                        AND Discount_Percentage__c != null 
                                        AND Discount_Percentage__c != :qpa.Discount_Percentage__c]);
                    if(results.size() > 0) {
                        productDiscountMap.put(qpa.Product__r.Name, NO_DISCOUNT_DIFFERENCE);
                    }
                }
            }
        }
        return productDiscountMap;
    }
    
    public static boolean IsTechReviewRequired(Quote__c quote) {
        /*
            Check if Tech Review is required
        */
        // Based of country of sales person - operation country
        User owner = bg_UserUtils.GetUserById(quote.OwnerId);
        
        // Get Tech Review Region
        string techRegion = bg_CustomSettingsUtils.GetDefaultCountrySettings(owner.OperationCountry__c).Technical_Review_Region__c;
        
        if(techRegion == bg_Globals.REGION_EMEA) {
            //Quote contains: All CE Marking and ISO 13485
            return bg_QuoteUtils.QuoteContainsProducts(quote.Id, new set<string>{
                                                bg_ProductUtils.PRODUCT_NAME_CE_MARKING, 
                                                bg_ProductUtils.PRODUCT_NAME_ISO_13485});           
        } 
        else if (techRegion == bg_Globals.REGION_US) {
            // Quote has: UKAS ISO 13485 and CE marking products/services
            return ((bg_QuoteUtils.QuoteContainsProducts(quote.Id, new set<string>{
                                                bg_ProductUtils.PRODUCT_NAME_CE_MARKING})) ||

                    (bg_QuoteUtils.QuoteContainsProducts(quote.Id, new set<string>{
                                                bg_ProductUtils.PRODUCT_NAME_ISO_13485}) &&                                             
                    bg_QuotePartUtils.GetQuoteProductValues(quote.Id, bg_ProductUtils.PRODUCT_NAME_ISO_13485, 
                                                bg_QuotePartUtils.PROPERTYALIAS_CERTIFICATION_BODY_UKAS, 
                                                bg_QuotePartUtils.PROPERTYVALUE_CERTIFICATION_BODY_UKAS).size() > 0));
        } else {
            return false;
        }
    }
    
    public class QuoteApprovalException extends Exception{}
     
    public static boolean IsFinanceApprovalRequired(Quote__c quote) {
        /*
            Check if Finance Approval is required?
        */

        // Get HQ Site
        string countryCode;
        try {       
            // Get financial approval amount from custom settings       
            countryCode = bg_SiteUtils.GetOpportunityHQSite(quote.Opportunity_Name__c).Site__r.Country_Code__c;     
        } catch (Exception ex) {
            throw new QuoteApprovalException('Unable to find country code for HQ site');
        }

        // Get country defaults
        ConversionScore__c cs = bg_CustomSettingsUtils.GetDefaultCountrySettings(countryCode);

        if(cs == null || cs.Finance_Approval_Amount__c == null) {
            // Default to US Approval amount & Approver
            cs = bg_CustomSettingsUtils.GetDefaultCountrySettings(bg_SiteUtils.COUNTRY_CODE_US);
        }

        if(cs != null && cs.Finance_Approval_Amount__c != null) {
            //string currencyCode = cs.CurrencyIsoCode;
            decimal approvalAmount = cs.Finance_Approval_Amount__c;

            // system.debug('quote.Total_Price_Year_3__c: ' + quote.Total_Price_Year_3__c);
            // system.debug('quote.Total_Opportunity_Amount__c: ' + quote.Total_Opportunity_Amount__c);         
            // system.debug('approvalAmount: ' + approvalAmount);
            
            return (quote.Total_Price_Year_3__c > 0 && 
                    quote.Total_Opportunity_Amount__c > approvalAmount);
                    
        } else {
            return false;
        }
    }
    
    /*
        Check if Operations Review is required
    */  
    public static boolean IsOperationsReviewRequired(Quote__c quote) 
    {
        // Based on operations review user on user record
        return bg_UserUtils.GetUserById(quote.OwnerId).Requires_Operations_Approval__c;
    }       

    /*
        Queries the Quote Operation Approval Queue to see if the current User is a Queue Member
    */            
    public static boolean IsQuoteOperationsApprovalQueueMember(final Quote__c theQuote)
    {
        return IsQuoteOperationsApprovalQueueMember(theQuote, UserInfo.getUserId());
    }    

    /*
        Queries the Quote Operation Approval Queue to see if the specified User is a Queue Member
    */                    
    public static boolean IsQuoteOperationsApprovalQueueMember(final Quote__c theQuote, final Id theUserId)
    {
        
        try
        {
            return ![SELECT Group.Name
                     FROM GroupMember
                     WHERE UserOrGroupId = :theUserId
                     AND Group.Type = 'Queue'
                     AND Group.Name = :theQuote.Operations_Approval_Queue__c].isEmpty();
        }
        catch (Exception e)
        {
            throw new QuoteApprovalException('Unable to find Operations Approval Queue');            
        }

    }
    
    private static String removeSpecialCharsinCCode(String ccode){System.debug('----' + ccode.replaceAll(' ', '').replaceAll('-', '').replaceAll('&', '').replaceAll('/', ''));
        return ccode.replaceAll(' ', '').replaceAll('-', '').replaceAll('&', '').replaceAll('/', '');
    }
    
}