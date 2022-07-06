/********************************************************************
 * bg_DocumentUtils
 *
 * Utility methods to support Conga Mail Merge and EchoSoft document integration
 * Test Class = bg_DocumentUtilsTest
 * 
 * 
 * Author: Antony Daley
 * Created: 02-09-2013
 * Changes: 29-09-14 ASD BG : Implementing V2 of the URL Generator to include bg_TemplateSelection page which is part of phase 3
 *                          : Commented out old sections of code that have been either updated or no longer used.
 *          06-05-15 KM BG  : Refactored UpdateQuoteAgreementStatus and modified to update opp fields
 *          06-08-15 RJ BG  : Added handling of Non-main agreements signed
 *          23-09-15 ASD BG : Case 23353 Changed OFN (File Name) 
 *			05-10-15 ASD BG : Case 23281 Changed Server URL to beta-  appextremes and added to custom setting
 *			20-05-16 ASD BG : Adding in Country Culture
 *          23-05-16 JT BG  : Case 25679 Added GetCongaTemplate, GetCongaQueryIdsByTemplateID, getCountries, getLanguages and getCurrency methods
 *          13-07-16 JT BG  : SoW25 added logic in GetBaseDocumentUrlV2 to call upgrade URL if user is in 'Conga Upgrade Group' public group
 ********************************************************************/
public class bg_DocumentUtils {
    
    public class DocumentException extends Exception {}

    public static final string DOCUMENT_PREFIX_KEY_FACTS = 'KFD';
    public static final string DOCUMENT_PREFIX_PROPOSAL  = 'PRD';
    public static final string DOCUMENT_PREFIX_SOW       = 'SOW';

    public static final string FILE_TYPE_PDF = 'pdf';
    public static final string FILE_TYPE_DOC = 'doc';
    
    public static final string DOCUMENT_TYPE_FACT_VALIDATION = 'Fact Validation';
    public static final string DOCUMENT_TYPE_SALES_BRIEF     = 'Proposal';
    //NOTE - SALES BRIEF USES PROPOSAL TEMPLATE TYPE CURRENTLY - IDEA IS TO CHANGE CODE SO THAT METHOD ACCEPTS  TEMPALTETYPE AND CUSTOMSETTINGTYPE AS SALES BRIEF USES SAME QUERIES AS PROPOSAL
    public static final string DOCUMENT_TYPE_PROPOSAL        = 'Proposal';
    public static final string DOCUMENT_TYPE_TECH_REVIEW     = 'Tech Review';
    public static final string DOCUMENT_TYPE_SOW             = 'SOW';
    public static final string DOCUMENT_TEMPLATE_NOT_FOUND   = 'NOT_FOUND';
     
    public static final string DOCUMENT_STATUS_DRAFT        = 'Draft';
    public static final string DOCUMENT_STATUS_NOT_SENT     = 'Pre-Send';
    public static final string DOCUMENT_STATUS_PENDING      = 'Out for Signature';
    public static final string DOCUMENT_STATUS_SIGNED       = 'Signed';
    public static final string DOCUMENT_STATUS_REJECTED     = 'Cancelled / Declined';
    public static final string DOCUMENT_STATUS_PENDING_COUNTER_SIGNATURE = 'Waiting for Counter-Signature';
    
    public static final integer MAX_CONGA_QUERIES = 50;
    public static final integer CONGA_QUERY_LIMIT = 1500;

    public static final string DOCUMENT_EXPIRY_TYPE_HARD = 'Hard Expiry';
    public static final string DOCUMENT_EXPIRY_TYPE_SOFT = 'Soft Expiry';   

    public static final string TEMPLATE_TYPE_BUNDLE = 'Bundle';

    public static string GetTemplateId(string templateType, string templateLang) {
        /*
            Returns the ID for a Conga Merge Tempalte as a string based on the Type and Language passed in.
        */
        string templateId = DOCUMENT_TEMPLATE_NOT_FOUND;
        list<APXTConga4__Conga_Template__c> ctList = [SELECT Type__c, Language__c, Active__c 
                                                      FROM APXTConga4__Conga_Template__c 
                                                      WHERE Type__c = :templateType 
                                                        AND Language__c = :templateLang
                                                        AND Active__c = true];
        if(!ctList.isEmpty()) 
        {
            templateId = ctList[0].Id;
        }
        return templateId;          
    }

    public static string GetDocumentUrl(Id quoteId, string templateId, string templateType, boolean autoSend, boolean echoSign, boolean backGroundMode) {
        /* Get Document Url - Takes 6 arguments but only a single tempalteId */
        return GetDocumentUrl(quoteId, new list<string>{templateId}, templateType, null, null, autoSend, echoSign, backGroundMode, true);
    }

    public static string GetDocumentUrl(Id quoteId, string templateId, string templateType, list<Id> recipientContactIds, boolean autoSend, boolean echoSign, boolean backGroundMode) {
        /* Get Document Url - Takes 7 arguments but only a single tempalteId */
        return GetDocumentUrl(quoteId, new list<string>{templateId}, templateType, recipientContactIds, null, autoSend, echoSign, backGroundMode, true);
    }

    public static string GetDocumentUrl(Id quoteId, string templateId, string templateType, list<Id> recipientContactIds, list<string> copyToAddresses, boolean autoSend, boolean echoSign, boolean backGroundMode) {
        /* Get Document Url - Takes 8 arguments but only a single tempalteId */
        return GetDocumentUrl(quoteId, new list<string>{templateId}, templateType, recipientContactIds, copyToAddresses, autoSend, echoSign, backGroundMode, true);
    }
    
    public static string GetDocumentUrl(Id quoteId, list<string> templateIds, string templateType, boolean autoSend, boolean echoSign, boolean backGroundMode) {
        /* Get Document Url - Takes 6 arguments including a list of tempalte ids */
        return GetDocumentUrl(quoteId, templateIds, templateType, null, null, autoSend, echoSign, backGroundMode, true);
    }
    
    public static string GetDocumentUrl(Id quoteId, list<string> templateIds, string templateType, list<Id> recipientContactIds, boolean autoSend, boolean echoSign, boolean backGroundMode) {
        /* Get Document Url - Takes 7 arguments including a list of template ids */
        return GetDocumentUrl(quoteId, templateIds, templateType, recipientContactIds, null, autoSend, echoSign, backGroundMode, true);
    }
    
    public static string GetDocumentUrl(Id quoteId, list<string> templateIds, string templateType, list<Id> recipientContactIds, boolean autoSend, boolean echoSign, boolean backGroundMode, boolean allowTemplateSelection) 
    {
        /* Get Document Url - Takes 8 arguments including a list of template ids */
        return GetDocumentUrl(quoteId, templateIds, templateType, recipientContactIds, null, autoSend, echoSign, backGroundMode, allowTemplateSelection);
    }

    public static string GetDocumentUrl(Id quoteId, list<string> templateIds, string templateType, list<Id> recipientContactIds, list<string> copyToAddresses, boolean autoSend, boolean echoSign, boolean backGroundMode, boolean allowTemplateSelection) {
        /*
            Builds up a conga URL for a basic template inclduing back ground mode, auto send and the template ID based on the 
            template type and language, enables echoSign and Backgorund mode if needed
        */
        system.debug('autoSend: ' + autoSend);
        system.debug('echoSign: ' + echoSign);
        system.debug('backGroundMode: ' + backGroundMode);
        
        Quote__c quote = bg_QuoteUtils.GetQuoteById(quoteId, true);
        //string retUrl = getBaseDocumentUrl(quoteId, templateType, quote, templateIds);
        
        string retUrl = getBaseDocumentUrlV2(quoteId, templateType, quote, templateIds);
        if(!backGroundMode)
        {
            //future proof - add addition boolean to check if were enforcing tempalte selection or allowing user to decide : retUrl += '&SelectTemplates=0';
            //allows selection of more than one template (1=on, 0=off)
            if(allowTemplateSelection)
            {
                retUrl += '&SelectTemplates=1';
            }else
            {
                retUrl += '&SelectTemplates=0';
                retUrl += '&DS4=1';
            }
            
        }
        if(backGroundMode) 
        {
            retUrl = BuildBackgroundModeToDocumentUrl(retUrl, autoSend, echoSign);
        }
        if(echoSign) 
        {
            retUrl = BuildEchoSignToDocumentUrl(retUrl, templateType, quote, recipientContactIds, copyToAddresses);
        }
        
        
        system.debug('retUrl: ' + retUrl);
        
        //return retUrl;
        
        //https://bsi--dev.cs8.my.salesforce.com/services/Soap/u/28.0/00DL000000283Jr
        
        /*String retUrl2 = 'https://www.appextremes.com/apps/Conga/PointMerge.aspx?sessionId='+UserInfo.getSessionId()+'&serverUrl=https://bsi--dev.cs8.my.salesforce.com/services/Soap/u/8.0/00DL000000283Jr&Id=a0sL0000001zhsA&QueryId=[AccCon]a0aL000000197hv&QueryId=[Opp]a0aL0000001guy9'+
        '&QueryId=[EntropyL1]a0aL0000001guzC&QueryId=[Transfer]a0aL0000001gvAA&QueryId=[Transfer1]a0aL0000001gvAF'+
        '&QueryId=[Portfolio]a0aL0000001gvCz'+
        '&QueryId=[Y1]a0aL0000001gvDT'+ 
        '&QueryId=[AddCost]a0aL0000001gvER'+ 
        '&QueryId=[ASSESSMENT1]a0aL0000001gvGD'+ 
        '&QueryId=[OpportunitySites]a0aL0000001984F'+ 
        '&QueryId=[QuoteProduct]a0aL0000001gvO6'+ 
        '&QueryId=[QuoteProduct2]a0aL0000001gvO6'+ 
        '&QueryId=[QuoteApprovers]a0aL0000001gvRV'+ 
        '&QueryId=[QuoteParts]a0aL000000198Oa'+ 
        '&QueryId=[QuotePartsNoTraining]a0aL0000001gvfQ'+ 
        '&QueryId=[QuotePartsTraining]a0aL0000001gvfV'+ 
        '&QueryId=[Achieving]a0aL0000001gvj6'+ 
        '&QueryId=[AddFee]a0aL0000001gvlW'+ 
        '&QueryId=[Optional]a0aL0000001gvlg'+ 
        '&QueryId=[AchievingY2andY3]a0aL0000001gvwZ'+ 
        '&TemplateGroup=Proposal'+ 
        '&SelectTemplates=1'+ 
        '&esvisible=1'+ 
        '&ESSignaturetype=2'+ 
        '&ESContactId={!Quote__c.ContactId__c}'+
        '&ESopportunityid={!Quote__c.Opportunity_NameId__c}'+ 
        '&ESCustomField=Quote__c'+ 
        '&ESCustomFieldValue=a0sL0000001zhsA'+
        '&ESAgreementName=[TEST]'+ 
        '&ESPreview=1';*/
    
        return retUrl;

    }
    
    /* Commented out as no longer used but may be used in future (updated by V2 method)
    private static string GetBaseDocumentUrl(Id quoteId, string templateType, Quote__c quote, list<string>templateIds) {
        
            Builds up a conga URL for a basic template
        
        SystemSetting__c ss = bg_CustomSettingsUtils.GetSystemSettings();
        string serverURL = ss.ServerURL__c + 'services/Soap/u/8.0/' + UserInfo.getOrganizationId();
        string encodedUserInfo = EncodingUtil.urlEncode(UserInfo.getSessionId(), 'UTF-8');
        string encodedServerURL = EncodingUtil.urlEncode(serverURL, 'UTF-8');
        
        string retUrl = 'https://www.appextremes.com/apps/Conga/PointMerge.aspx';
        //retUrl += '?sessionId=' + UserInfo.getSessionId();
        retUrl += '?sessionId=' + encodedUserInfo;
        retUrl += '&serverUrl=' + encodedServerURL;
        retUrl += '&Id=' + quoteId;
        system.debug('@BUILD CONGA: ' + retUrl);
        retUrl += GetCongaQueryIdsUrl(templateType);
        system.debug('@POST BUILD CONGA: ' + retUrl);
        retUrl += '&TemplateGroup='+ templateType;

        retUrl += '&OFN=' + templateType + ' ' + quote.Name;
        
        // Add Expiry Days when Hard expiry required.
        if(quote.Expiry_Type__c == DOCUMENT_EXPIRY_TYPE_HARD) {
            retUrl += '&ESExpireInXDays=' + quote.Expiry_Days__c;
        }
        
        if(!templateIds.isEmpty()) {
            string tempId = '';
            integer t = templateIds.size();
            integer i = 0;
            for(string s : templateIds) 
            {
                if(i < t)
                {
                    tempId = tempId + s +',';
                }else
                {
                    tempId = tempId + s;
                }
                i++;
            }
            retUrl += '&TemplateId=' + tempId;
        }

        return retUrl;
    }*/
    
    private static string GetBaseDocumentUrlV2(Id quoteId, string templateType, Quote__c quote, list<string>templateIds) 
    {
        /*
            Builds up a conga URL for a basic template based on new VF page bg_TemplateSelection
        */
        SystemSetting__c ss = bg_CustomSettingsUtils.GetSystemSettings();
        string serverURL = ss.ServerURL__c + 'services/Soap/u/8.0/' + UserInfo.getOrganizationId();
        string encodedUserInfo = EncodingUtil.urlEncode(UserInfo.getSessionId(), 'UTF-8');
        string encodedServerURL = EncodingUtil.urlEncode(serverURL, 'UTF-8');
        
        //string retUrl = 'https://www.appextremes.com/apps/Conga/PointMerge.aspx';
        //ASD Case 00023281 05/10/15
        //string retUrl = 'https://beta-www.appextremes.com/apps/Conga/PointMerge.aspx';

        // JT SoW25 13/07/16
        // If user is in the public group use the 'Conga Upgrade URL'
        Id userId = UserInfo.getUserId();
        Id userRole = UserInfo.getUserRoleId();

        Group gp = [select id,relatedid,name from Group WHERE relatedid =:userRole][0];

        Id groupId = gp.Id;

        System.debug(gp.Id);
        System.debug(gp.relatedid);
        System.debug(gp.name);

        Integer groupCount = database.countQuery('select Count() from groupmember where (UserOrGroupId=:userId OR UserOrGroupId=:groupId) AND Group.developername = \'Conga_Upgrade_Group\'');
        string retUrl;
        if (groupCount > 0)
        {
            retUrl = ss.CongaUpgradeURL__c;
        }
        else
        {
            retUrl = ss.Conga_Server_URL__c;
        }
        //string retUrl = ss.Conga_Server_URL__c;
        retUrl += '?sessionId=' + encodedUserInfo;
        retUrl += '&serverUrl=' + encodedServerURL;
        retUrl += '&Id=' + quoteId;
        
        system.debug('@BUILD CONGA: ' + retUrl);
        retUrl += GetCongaQueryIdsByTemplateQuery(templateIds);
        system.debug('@POST BUILD CONGA: ' + retUrl);
        //retUrl += '&TemplateGroup='+ templateType;
        
        //ASD 23/09/15 Case 23353 
        //retUrl += '&OFN=' + templateType + ' ' + quote.Name;
        //retUrl += '&OFN=' + quote.Account__r.Name + ' ' + templateType + ' ' + quote.Name;
        system.debug('Account Name: ' + EncodingUtil.urlEncode(quote.Account__r.Name, 'UTF-8'));
        String accNameEncoded = EncodingUtil.urlEncode(quote.Account__r.Name, 'UTF-8');
        retUrl += '&OFN=' + accNameEncoded + ' ' + templateType + ' ' + quote.Name;
        
        //JNM 25/09/15 Case 23286 -- //ASD 01/10/15 Case 23286 - No longer required
        //retUrl += '&AWD=1';
        
        // Add Expiry Days when Hard expiry required.
        if(quote.Expiry_Type__c == DOCUMENT_EXPIRY_TYPE_HARD) 
        {
            retUrl += '&ESExpireInXDays=' + quote.Expiry_Days__c;
        }
        
        if(!templateIds.isEmpty()) 
        {
            string tempId = '';
            integer t = templateIds.size();
            integer i = 0;
            for(string s : templateIds) 
            {
                if(i < t)
                {
                    tempId = tempId + s +',';
                }else
                {
                    tempId = tempId + s;
                }
                i++;
            }
            retUrl += '&TemplateId=' + tempId;
        }
        
        // Case 28398
        retUrl += '&DefaultPDF=1';
        
        //retUrl += '&CurrencyCulture=en-GB';

        return retUrl;
    }
    
    private static string GetCongaQueryIdsByTemplateQuery(list<string>templateIds)
    {
        string retUrl = '&QueryId=';
        Set<Id> queryIds = new Set<Id>();
        map<Id,String> queryIdToAlias = new map<Id,String>();
        
        List<Template_Queries__c> templateQueries = [SELECT Id, Conga_Query__c, Conga_Template__c, Conga_Query__r.ShortName__c
                                                     FROM Template_Queries__c
                                                     WHERE Conga_Template__c IN :templateIds];
        for(Template_Queries__c tq : templateQueries)
        {
            queryIds.add(tq.Conga_Query__c);
            queryIdToAlias.put(tq.Conga_Query__c,tq.Conga_Query__r.ShortName__c);
        }
        
        for(Id i : queryIds)
        {
            string alias = queryIdToAlias.get(i);
            if(!bg_StringUtils.IsBlank(alias)) 
            {
                if(alias.contains(','))
                {
                    for(String s : alias.split(',',0))
                    {
                        retUrl += '[' + s + ']' + i + ',';
                    }
                }else
                {
                    retUrl += '[' + alias + ']' + i + ',';
                }
            }else 
            {
                break; // queryId and alias are blank
            }
        }
        
        return retUrl;
        
        /* ORIGINAL Code - Commented out as no longer used but may be used in future
        string retUrl = '&QueryId=';
        List<Template_Queries__c> templateQueries = [SELECT Id, Conga_Query__c, Conga_Template__c, Conga_Query__r.ShortName__c
                                                     FROM Template_Queries__c
                                                     WHERE Conga_Template__c IN :templateIds];
        for(Template_Queries__c tq : templateQueries)
        {
            string queryId = tq.Conga_Query__c; 
            string alias = tq.Conga_Query__r.ShortName__c;
            if(!bg_StringUtils.IsBlank(queryId) && !bg_StringUtils.IsBlank(alias)) 
            {
                if(alias.contains(','))
                {
                    for(String s : alias.split(',',0))
                    {
                        retUrl += '[' + s + ']' + queryId + ',';
                    }
                }else
                {
                    retUrl += '[' + alias + ']' + queryId + ',';
                }
            }else 
            {
                break; // queryId and alias are blank
            }
        }
        
        return retUrl;*/
    }
    
    /* Commented out as no longer used but may be used in future
    private static string GetCongaQueryIdsUrl(string templateType) 
    {
         
            Method to return Query Ids URL from custom settings
        
        string retUrl = '&QueryId=';
        map<string, Schema.SObjectField> fieldMap = bg_Utilities.GetObjectFieldMap('congaQueryIds__c');     
        congaQueryIds__c cstSet = CongaQueryIds__c.getInstance(templateType);

        if(cstSet != null) 
        {
            for(integer i = 1; i <= MAX_CONGA_QUERIES; i++) 
            {
                system.debug('IN BUILD CONGA: ' + i);
                string fQueryName = 'QueryId' + i + '__c';
                string fAliasName = 'Alias' + i + '__c';                
                if (fieldMap.containsKey(fQueryName) && fieldMap.containsKey(fAliasName)) 
                {
                    string queryId = (string)cstSet.get(fQueryName); 
                    string alias = (string)cstSet.get(fAliasName);
                    if(!bg_StringUtils.IsBlank(queryId) && !bg_StringUtils.IsBlank(alias)) 
                    {
                        retUrl += '[' + alias + ']' + queryId + ',';
                        
                    } else {
                        break; // queryId and alias are blank
                    }
                } else 
                {
                 break; // cannot find field
                }
            }
            retUrl = retUrl.Substring(0,retUrl.length()-1);
        } else 
        {
            throw new DocumentException('The Conga Query Ids were not found for the template type: ' + templateType);
        }
        
        return retUrl;
    }
    */
    
    private static string BuildBackgroundModeToDocumentUrl(string retUrl, boolean autoSend, boolean echoSign) {
        /*
            Adds background modes to the base url depending on requirements
        */
        system.debug('retUrl: ' + retUrl);
        if(!retUrl.contains(DOCUMENT_TEMPLATE_NOT_FOUND)) {
            system.debug('ASD: echoSign ' + echoSign);
            system.debug('ASD: autoSend ' + autoSend);
            
            if(echoSign) {
                if(autoSend) {
                    // DS7 14 is the background mode and auto echosign agreement creation and the auto send
                    retUrl += '&DS7=14';
                    system.debug('ASD: &DS7=14 '); 
                } else {
                    // DS7 4 is background mode and auto echosign agreement creation
                    retUrl += '&DS7=4';
                    system.debug('ASD: &DS7=4 ');
                }
            } else if(autoSend) {
                retUrl += '&DS7=12';
            } else {
                retUrl += '&DS7=1&LG3=2';
            }
        }
        
        retUrl += '&BML=Generating+Document';
        return retUrl;
    }   

    private static string BuildEchoSignToDocumentUrl(string retUrl, string templateType, Quote__c quote, list<Id> recipientContactIds, list<String> copyToAddresses) 
    {
        /*
            Adds echosign functionality
        */
        //Below are all EchoSign paramenters
        retUrl += '&esvisible=1';
        retUrl += '&ESSignaturetype=2';

        // Add Recipient Contacts
        if(recipientContactIds != null && !recipientContactIds.isEmpty()) 
        {
            for(integer i = 0 ; i < 6 ; i++) 
            {
                // TODO: Add code the set each contact parameter 
                if(i > recipientContactIds.size() - 1) 
                { 
                    break; 
                }
                if(i == 0)
                {
                    retUrl += '&ESContactId=' + recipientContactIds[i];
                }else
                {
                    retUrl += '&ESContactId' + i + '=' + recipientContactIds[i];
                }
            }
        }
        
        if(copyToAddresses != null && !copyToAddresses.isEMpty())
        {
            Integer i = 0;
            for(String s : copyToAddresses)
            {
                if(i == 0)
                {
                    retUrl += '&ESCopyTo=' + s;
                }else
                {
                    retUrl += ',' + s;
                }
                i++;
            }
        }

        retUrl += '&ESopportunityid=' + quote.Opportunity_Name__c;
        retUrl += '&ESCustomField=Quote__c';
        retUrl += '&ESCustomFieldValue=' + quote.Id;
        retUrl += '&ESCustomField1=Template_Type__c';
        retUrl += '&ESCustomFieldValue1=' + templateType;
        retUrl += '&ESPreview=' + 1;
        

        return retUrl;
    }

    public static echosign_dev1__SIGN_Agreement__c GetLatestAgreement(Id quoteId, string templateType) {
        /* 
            Return latest agreement
        */
        echosign_dev1__SIGN_Agreement__c agreement;
        list<echosign_dev1__SIGN_Agreement__c> agreements = GetAgreements(quoteId, templateType, true);
        if(!agreements.isEmpty()) { agreement = agreements[0]; }
        return agreement;
    }

    public static list<echosign_dev1__SIGN_Agreement__c> GetAgreements(Id quoteId, string templateType, boolean latestOnly) {
        /* 
            Return list of agreements
        */
        string query = 'SELECT Name, echosign_dev1__Status__c, CreatedDate, echosign_dev1__DateSent__c, echosign_dev1__DateSigned__c, echosign_dev1__DateViewed__c, echosign_dev1__DaysUnsigned__c ' +  
                        'FROM echosign_dev1__SIGN_Agreement__c ' + 
                        'WHERE Quote__c = :quoteId ';
        // type ?       
        if(!bg_StringUtils.IsBlank(templateType)) {
            //name += '%'; 
            query += 'AND Template_Type__c = :templateType ';
        }
        // order by             
        query += 'ORDER BY CreatedDate DESC ';
        // first one only       
        if(latestOnly) { query += 'LIMIT 1 '; }
        // return attachments
        return database.query(query);       
    }

    public static boolean CheckDocumentStatus(echosign_dev1__SIGN_Agreement__c agreement, string docStatus) {
        /* Return document status check */
        return CheckDocumentStatus(agreement, new set<string>{docStatus});
    }
    
    public static boolean CheckDocumentStatus(echosign_dev1__SIGN_Agreement__c agreement, set<string> docStatus) {
        /* Return document status check */
        return docStatus.contains(agreement.echosign_dev1__Status__c);
    }

    public static list<String> GetRecipientContactIds(string templateType, Quote__c quote) {
        /*
            Method to return list of contacts based on template Type
            29-09-14 Changed ID to String
        */
        list<String> recipientContactIds = new list<String>();

        // TECHNICAL REVIEW DOCUMENT
        if (templateType == DOCUMENT_TYPE_TECH_REVIEW) {
            recipientContactIds.add(quote.Tech_Review_Team__c);
        // ALL OTHER TEMPLATES
        } else {
            recipientContactIds.add(quote.Contact__c);
            
        }
        return recipientContactIds;
    }
    
    public static void UpdateQuoteAgreementStatus(list<echosign_dev1__SIGN_Agreement__c> agreements, map<Id, echosign_dev1__SIGN_Agreement__c> oldMap) {
        /*
            Method to update opportunity and quote with proposal / fact validation status
        */
        map<Id, echosign_dev1__SIGN_Agreement__c> signedAgreementMap = new map<Id, echosign_dev1__SIGN_Agreement__c>();
        map<Id, echosign_dev1__SIGN_Agreement__c> sentAgreementMap = new map<Id, echosign_dev1__SIGN_Agreement__c>();
        set<Id> contactIds = new set<Id>();

        for(echosign_dev1__SIGN_Agreement__c agreement : agreements) {
            // FACTS / PROPOSAL - SIGNED
            if(AgreementChangedToSigned(agreement, oldMap)) {
                signedAgreementMap.put(agreement.Quote__c, agreement);
                contactIds.add(agreement.echosign_dev1__Recipient__c);

            // PROPOSAL - OUT TO CUSTOMER (PENDING)         
            } else if(ProposalChangedToOutToCustomer(agreement, oldMap)) {
                sentAgreementMap.put(agreement.Quote__c, agreement);
            }
        }

        // Handle any agreements signed for non-main quotes 
        // RJ: REMOVED FROM SCOPE   
        //HandleSignedNonMainQuotes(signedAgreementMap);

        // SIGNED - UPDATE QUOTE AND CREATE CHATTER POST
        if(!signedAgreementMap.isEmpty()) {
            HandleQuotesSigned(signedAgreementMap, contactIds);
        }

        // PROPOSAL OUT FOR SIGNATURE - UPDATE OPPORTUNITY
        if(!sentAgreementMap.isEmpty()) {
            HandleQuotesOutForSignature(sentAgreementMap);
        }
    }

    /*
        Set non-main quotes opportunities to Check signed quote = true
        and do not change the status of the opportunity 
    */
/*  
    private static void HandleSignedNonMainQuotes(map<Id, echosign_dev1__SIGN_Agreement__c> signedAgreementMap) 
    {
        list<Opportunity> updOpps = new list<Opportunity>();
        // Loop through quotes related to the agreement
        for(Quote__c q : [SELECT Id, Main_Quote__c, Opportunity_Name__c
                          FROM Quote__c
                          WHERE Id IN : signedAgreementMap.keySet()])
        {
            // Is non-main quote?
            if(!q.Main_Quote__c)
            {
                // prep opp for update
                Opportunity opp = new Opportunity(Id = q.Opportunity_Name__c);
                opp.Check_signed_quote__c = true; // set flag
                updOpps.add(opp);
                // remove from signed list
                signedAgreementMap.remove(q.Id);
            }
        }
        
        update updOpps;
    }
*/
    public static void HandleQuotesOutForSignature(map<Id, echosign_dev1__SIGN_Agreement__c> sentAgreementMap) {
        /*
            Sets the sent date on the quote
        */
        map<Id, Quote__c> oppToQuote = new map<Id, Quote__c>();
        // Update Quote - Proposal Sent Date
        list<Quote__c> quotes = [SELECT Proposal_Sent_Date__c, Opportunity_Name__c, Expiry_Days__c
                                 FROM Quote__c
                                 WHERE Id IN :sentAgreementMap.keySet()];

        for(Quote__c quote : quotes) {
            quote.Proposal_Sent_Date__c = DateTime.Now();
            oppToQuote.put(quote.Opportunity_Name__c, quote);   
        }
        // update quotes
        Utility.lockQuoteTrigger = true;
        update quotes;

        bg_OpportunityUtils.UpdateOpportunitiesOutForSignature(oppToQuote);
    }
    
    public static void HandleQuotesSigned(map<Id, echosign_dev1__SIGN_Agreement__c> signedAgreementMap, set<Id> contactIds) {
        /*
            When a quote is signed
                set the validation fields
                set the opportunity stage to close processing
                create a chatter post
        */
        // GET THE RECIPIENTS
        list<Contact> recipients = [SELECT Id, Name FROM Contact WHERE Id IN :contactIds];
        map<Id, string> contactNamesMap = new map<Id, string>();
        for(Contact con : recipients) {
            contactNamesMap.put(con.Id, con.Name);
        }


        set<Id> oppIds = bg_QuoteUtils.QuotesSigned(signedAgreementMap, contactNamesMap);

        bg_OpportunityUtils.SetOppsClosedProcessing(oppIds);    

        try {
            // CHATTER POST WHEN NEW DEAL IS SIGNED
            list<FeedItem> feedItems = new list<FeedItem>(); 
            for (Opportunity opp : [SELECT Id, Name, Account.OwnerId 
                                        FROM Opportunity WHERE Id IN :oppIds]) {
                
                // build list of feed items
                feedItems.add(bg_ChatterUtils.GetChatterPost(opp.Account.OwnerId, 
                                                                opp.Name, 
                                                                '/' + opp.Id, 
                                                                bg_ChatterUtils.CHATTER_POSTTYPE_LINKPOST, 
                                                                Label.ChatterPostNewDeal));
            }
            insert feedItems;
        } catch (Exception ex) {
            // Ignore any errors
            system.debug('Failed to insert chatter post: feedItems: ' + ex);
        }
    }
    
    private static Boolean AgreementChangedToSigned(echosign_dev1__SIGN_Agreement__c agreement, map<Id, echosign_dev1__SIGN_Agreement__c> mapToOldAgreements) {
        /*
            Agreement status has changed to signed and is a proposal/fact validation
        */
        return agreement.echosign_dev1__Status__c != mapToOldAgreements.get(agreement.Id).echosign_dev1__Status__c 
                && agreement.echosign_dev1__Status__c == DOCUMENT_STATUS_SIGNED
                && (agreement.Template_Type__c == DOCUMENT_TYPE_FACT_VALIDATION || 
                    agreement.Template_Type__c == DOCUMENT_TYPE_PROPOSAL);
    }
    
    private static Boolean ProposalChangedToOutToCustomer(echosign_dev1__SIGN_Agreement__c agreement, map<Id, echosign_dev1__SIGN_Agreement__c> mapToOldAgreements) {
        /*
            Agreement status has changed to pending and is a proposal
        */
        return agreement.echosign_dev1__Status__c != mapToOldAgreements.get(agreement.Id).echosign_dev1__Status__c 
                && agreement.echosign_dev1__Status__c == DOCUMENT_STATUS_PENDING
                && agreement.Template_Type__c == DOCUMENT_TYPE_PROPOSAL;
    }
    
    public static boolean CheckFactsExceedsDocLimit(Id quoteId) {
        /*
            Check if Fact Validation records exceeds limit
        */
        if(quoteId != null) {
            integer maxRecords = bg_DocumentUtils.CONGA_QUERY_LIMIT;
            QuoteSetting__c cs = bg_CustomSettingsUtils.GetQuoteSettings();
            if(cs.MaxFactValidationRecordsLimit__c != null && cs.MaxFactValidationRecordsLimit__c > 0) {
                maxRecords = integer.valueOf(cs.MaxFactValidationRecordsLimit__c);
            }
    
            AggregateResult ar = [SELECT MAX(FactOrderNo__c) maxFactOrderNo
                                    FROM PropertyValue__c 
                                    WHERE QuoteToProduct__r.Quote_Ref__c = :quoteId
                                        AND FactOrderNo__c != null];
    
            return (integer.valueOf(ar.get('maxFactOrderNo')) > maxRecords);
        } else {
            return false;   
        }
    }   

    public static APXTConga4__Conga_Template__c GetCongaTemplate(Id congaTemplateId)   
    {
        APXTConga4__Conga_Template__c congaTemplate = [SELECT Id, Name, APXTConga4__Name__c, APXTConga4__Template_Group__c, APXTConga4__Template_Type__c, Type__c, 
                                    Language__c, Country__c, Product_Type__c, APXTConga4__Description__c, CurrencyIsoCode, 
                                    APXTConga4__Master_Field_to_Set_1__c, APXTConga4__Master_Field_to_Set_2__c, APXTConga4__Master_Field_to_Set_3__c 
                                FROM APXTConga4__Conga_Template__c 
                                WHERE id = :congaTemplateId];
        return congaTemplate;
    }

    public static List<Template_Queries__c> GetCongaQueryIdsByTemplateID(Id congaTemplateId)   
    {
        List<Template_Queries__c> congaQueries = [SELECT Id, Name, Query_Name__c, Template_Name__c, Conga_Query__c, Conga_Template__c 
                                                        FROM Template_Queries__c 
                                                        WHERE Conga_Template__c = :congaTemplateId];
        return congaQueries;
    }
    public static List<SelectOption> getCountries()
    {
        List<SelectOption> options = new List<SelectOption>();
            
        Schema.DescribeFieldResult fieldResult = APXTConga4__Conga_Template__c.Country__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            
        for( Schema.PicklistEntry f : ple)
        {
            options.add(new SelectOption(f.getValue(), f.getLabel()));
        }       
        return options;
    }

    public static List<SelectOption> getLanguages()
    {
        List<SelectOption> options = new List<SelectOption>();
            
        Schema.DescribeFieldResult fieldResult = APXTConga4__Conga_Template__c.Language__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            
        for( Schema.PicklistEntry f : ple)
        {
            options.add(new SelectOption(f.getValue(), f.getLabel()));
        }       
        return options;
    }

    public static List<SelectOption> getCurrency()
    {
        List<SelectOption> options = new List<SelectOption>();
            
        Schema.DescribeFieldResult fieldResult = APXTConga4__Conga_Template__c.CurrencyIsoCode.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            
        for( Schema.PicklistEntry f : ple)
        {
            options.add(new SelectOption(f.getValue(), f.getLabel()));
        }       
        return options;
    }
}