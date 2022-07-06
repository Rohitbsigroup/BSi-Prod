/*
 *
 * bg_TemplateSelectionController
 *
 * Test class = bg_TemplateSelectionController_Test
 *
 * Controller class doe bg_TemplateSelection page, this page is designed to build up a select list of templates and generate a conga URL
 * There is a hard limit of 50 queries and 10 templates allowed and there are methods in palce to calculate the number of queries used
 *
 * Author   : ASD BrightGen
 * Date     : 25/09/2014
 * Changes  : 15/10/2014 - Addedd SOW Template Type 
 *            08/09/2015 RPJ - Added Template bundles
 *            05/02/2018 ADS - Case 35399 - Default Filters on Conga Template Page
 */
public with sharing class bg_TemplateSelectionController
{
    public static final Decimal MIN_NO_OF_QUERIES = 0;
    public static final Decimal MAX_NO_OF_QUERIES = 70;
    public static final String CHOOSE_AT_LEAST_ONE_TEMPLATE = system.Label.CTS_CHOOSE_AT_LEAST_ONE_TEMPLATE;
    public static final String CHOOSEN_TOO_MANY_TEMPLATE_QUERIES = system.Label.CTS_CHOOSEN_TOO_MANY_TEMPLATE_QUERIES;
    public static final String CHOOSEN_TOO_MANY_TEMPLATES = system.Label.CTS_CHOOSEN_TOO_MANY_TEMPLATES;
    
    public Id quoteId {get;set;}
    public String docType {get;set;}
    public List<Id> recipientContactIds {get;set;}
    
    public list<String> CurrentRightList {get;set;}
    public list<String> LeftSelectedList {get;set;}
    public list<String> RightSelectedList {get;set;}
    public map<String, APXTConga4__Conga_Template__c> LeftOptionMap = new map<String, APXTConga4__Conga_Template__c>();
    public map<String, APXTConga4__Conga_Template__c> RightOptionMap = new map<String, APXTConga4__Conga_Template__c>();
    public map<Id, Set<Id>> ctToCongaQueriesSet = new map<Id, Set<Id>>();
    public Decimal currentNoQueriesUsed {get;set;}
    public APXTConga4__Conga_Template__c tempCT {get;set;}
    
    public String languageFilterString {get;set;}
    public String typeFilterString {get;set;}
    
    public String countryFilterString
    {
        get
        {

            if (String.isBlank(countryFilterString))
            {
                final Id theUserId = UserInfo.getUserId();
                final Map<Id, User> theUserCountryMap = bg_UserUtils.GetCountryMap(new Set<Id> { theUserId });
                
                if (theUserCountryMap.containsKey(theUserId))
                {
                    countryFilterString = theUserCountryMap.get(theUserId).OperationCountry__c;
                }

            }
            
            return countryFilterString;
        }
        set;
    }
    
    public String templateNameString {get;set;}
    public String productTypeFilterString {get;set;}
    //public boolean bundlesOnly {get;set;}

    // TOP PAGE CONTROL
    public boolean reloadNeeded {get; private set;}
    public string reloadPageURL {get; private set;}

    public bg_TemplateSelectionController() 
    {
        /* Controller - instantiate lists, gets URL paremeters from the button and runs the find() method */
        tempCT = new APXTConga4__Conga_Template__c();
        system.debug(logginglevel.error,'quoteId ' + ApexPages.currentPage().getParameters().get('quoteId'));
        system.debug(logginglevel.error,'docType ' + ApexPages.currentPage().getParameters().get('docType'));
        system.debug(logginglevel.error,'recCont ' + ApexPages.currentPage().getParameters().get('recCont'));
        //system.debug(logginglevel.error,'recipientContactIds ' + recipientContactIds);

        reloadNeeded = false;
        quoteId = ApexPages.currentPage().getParameters().get('quoteId');
        docType = ApexPages.currentPage().getParameters().get('docType');
        recipientContactIds = bg_StringUtils.convertStringToListOfIds(ApexPages.currentPage().getParameters().get('recCont'));
        
        LeftSelectedList = new list<String>();
        RightSelectedList = new list<String>();
        CurrentRightList = new list<String>();
        currentNoQueriesUsed = 0;
        //bundlesOnly = false;

        // Set template type to as default filter
        if(!string.IsBlank(docType)) {    
            typeFilterString = docType;
        }

        setupCalculateQueries();
        Find();
    }
    
    private void calculateQueriesUsed()
    {
        /* Calculates the number of Queries used */
        system.debug(logginglevel.error,'### In calculateQueriesUsed');
        Set<Id> queryIds = new Set<Id>();
        if(!CurrentRightList.isEmpty())
        {
            for(String ctId : CurrentRightList)
            {
                if(ctToCongaQueriesSet.get(ctId) != null) 
                {   
                    queryIds.addAll(ctToCongaQueriesSet.get(ctId));
                }
            }
        }
        system.debug(logginglevel.error,'### In currentNoQueriesUsed = queryIds.size() : ' + queryIds.size());
        system.debug(logginglevel.error,'### In queryIds : ' + queryIds);
        currentNoQueriesUsed = queryIds.size();
    }
    
    private void setupCalculateQueries()
    {
        /* Builds up a map of Tempaltes with a Set of Conga Query Ids used by this template, this is used to help track how many queries have currently been selected */
        system.debug(logginglevel.error,'### In setupCalculateQueries');
        //get a map of TQ > Set of Conga
        List<Template_Queries__c> allTemplateQueries = [SELECT Id, Conga_Query__c, Conga_Template__c 
                                                        FROM Template_Queries__c];
        system.debug(logginglevel.error,'### allTemplateQueries ' + allTemplateQueries);    
                                                    
        for(Template_Queries__c tq : allTemplateQueries)
        {
            system.debug(logginglevel.error,'### tq ' + tq);
            system.debug(logginglevel.error,'### ctToCongaQueriesSet ' + ctToCongaQueriesSet);
            system.debug(logginglevel.error,'### tq.Conga_Template__c ' + tq.Conga_Template__c);
            
            //add to map
            if(ctToCongaQueriesSet.containsKey(tq.Conga_Template__c))
            {
                ctToCongaQueriesSet.get(tq.Conga_Template__c).add(tq.Conga_Query__c);
                system.debug(logginglevel.error,'### add to map ' + ctToCongaQueriesSet);
            }else
            {
                Set<Id> queryIds = new Set<Id>();
                queryIds.add(tq.Conga_Query__c);
                ctToCongaQueriesSet.put(tq.Conga_Template__c, queryIds);
                system.debug(logginglevel.error,'### create map ' + ctToCongaQueriesSet);
            }
        }   
        system.debug(logginglevel.error,'### ctToCongaQueriesSet : ' + ctToCongaQueriesSet);                                                    
    }
    
    public PageReference ClickRight()
    {
        /* ClickRight - Right pointing arrow was clicked. Move selected options to the right box.*/
        RightSelectedList.clear();
        for(String templateId : LeftSelectedList)
        {
            APXTConga4__Conga_Template__c selectedTemplate = LeftOptionMap.get(templateId);
            if(selectedTemplate != null)
            {
                if(selectedTemplate.APXTConga4__Template_Type__c == bg_DocumentUtils.TEMPLATE_TYPE_BUNDLE)
                {
                    list<APXTConga4__Conga_Template__c> templates = getBundleTemplates(selectedTemplate.Id);
                    for(APXTConga4__Conga_Template__c ct : templates)
                    {
                        RightOptionMap.put(ct.Id, ct);
                        currentNoQueriesUsed += ct.Number_Of_Queries_Used_Max_Allowed_50__c;
                        LeftOptionMap.remove(ct.Id);                    
                    }
                }
                else
                {
                    RightOptionMap.put(templateId, selectedTemplate);  
                    currentNoQueriesUsed += selectedTemplate.Number_Of_Queries_Used_Max_Allowed_50__c;    
                    LeftOptionMap.remove(templateId);
                }
            }
        }
        return null;
    }

    public PageReference ClickLeft()
    {
        /* ClickLeft - Left pointing arrow was clicked. Move selected options to the left box. */  
        LeftSelectedList.clear();
        for(String s : RightSelectedList)
        {
            if (RightOptionMap.containsKey(s)) 
            {
                LeftOptionMap.put(s, RightOptionMap.get(s));
                currentNoQueriesUsed -= LeftOptionMap.get(s).Number_Of_Queries_Used_Max_Allowed_50__c;
            }
          RightOptionMap.remove(s);
        }
        return null;
    }
     
    public list<SelectOption> getLeftOptionList()
    {
        /* getLeftOptionList - return SelectOptions for the left/unselected box */ 
        list<SelectOption> TempOptionList = new list<SelectOption>();
        list<string> TempValueList = new list<string>();
        map<string, Id> TempValueMap = new map<string, Id>();  

        for (APXTConga4__Conga_Template__c ct : LeftOptionMap.values()) {
            TempValueList.add(ct.APXTConga4__Name__c);
            TempValueMap.put(ct.APXTConga4__Name__c, ct.Id);
        }
        TempValueList.sort();

        for(string templateName : TempValueList) {
            TempOptionList.add(new SelectOption(TempValueMap.get(templateName), templateName));
        }

        //Call Calculate queries used
        calculateQueriesUsed();

        return TempOptionList;
    }
     
    public list<SelectOption> getRightOptionList()
    {
        /* getRightOptionList - return SelectOptions for the right/selected box */ 
        system.debug(LoggingLevel.error,'### getRightOptionList');
        
        list<SelectOption> TempOptionList = new list<SelectOption>();
        list<string> TempValueList = new list<string>();
        map<string, Id> TempValueMap = new map<string, Id>();  
     
        //clear is used instead of new list, so the list maintains the pointer to the ExamplePageController list
        CurrentRightList.clear();  

        for (APXTConga4__Conga_Template__c ct : RightOptionMap.values()) {
            TempValueList.add(ct.APXTConga4__Name__c);
            TempValueMap.put(ct.APXTConga4__Name__c, ct.Id);
            CurrentRightList.add(ct.Id);
        }
        TempValueList.sort();

        for(string templateName : TempValueList) {
            TempOptionList.add(new SelectOption(TempValueMap.get(templateName), templateName));
        }
        
        //Call Calculate queries used
        calculateQueriesUsed();
            
        return TempOptionList;
    }
     
    public PageReference Find()
    {
        /* Find - Search for Conga Templates that are used by TQs, and add them to the left box for selection */
        String TempSearchText;
        list<APXTConga4__Conga_Template__c> TemplateList;
     
        TemplateList = GetTemplateList();
        
        system.debug(LoggingLevel.error,'### Find ' );
        system.debug(LoggingLevel.error,'### TemplateList : ' + TemplateList);
        
        LeftOptionMap.clear();
        for (APXTConga4__Conga_Template__c ct : TemplateList) 
        {
            if (!RightOptionMap.containsKey(ct.Id)) 
            {
                system.debug(LoggingLevel.error,'### ct.APXTConga4__Name__c : ' + ct.APXTConga4__Name__c);
                LeftOptionMap.put(ct.Id, ct);
            }
        }
        return null;
    }

    /*
        Returns the select query
    */
    private string GetTemplateSelectQuery()
    {
        String query;
        query = 'SELECT APXTConga4__Name__c, Id, Number_Of_Queries_Used_Max_Allowed_50__c, Type__c, APXTConga4__Template_Group__c, Language__c, Country__c, Product_Type__c, APXTConga4__Template_Type__c';
        query += ', (Select Id From Attachments)';
        query += ' FROM APXTConga4__Conga_Template__c';
        query += ' WHERE Active__c = true';
        return query;       
    }
    
    public String BuildQueryString()
    {
        /* Builds up a SOQL string based on filters selected. Note Additional lines after SELECT must start with a space */
        String query = GetTemplateSelectQuery();
        
        if(!String.isBlank(typeFilterString))
        {
            system.debug(LoggingLevel.error,'### typeFilterString ' + typeFilterString );
            system.debug(LoggingLevel.error,'### Add to query '  );
            query += ' AND APXTConga4__Template_Group__c LIKE \'%' + typeFilterString + '%\'';
        }
        
        if(!String.isBlank(languageFilterString))
        {
            system.debug(LoggingLevel.error,'### languageFilterString ' + languageFilterString );
            system.debug(LoggingLevel.error,'### Add to list '  );
            query += ' AND Language__c = \'' + languageFilterString + '\'';
        }
        
        if(!String.isBlank(templateNameString))
        {
            system.debug(LoggingLevel.error,'### templateNameString ' + templateNameString );
            system.debug(LoggingLevel.error,'### Add to list '  );
            query += ' AND APXTConga4__Name__c LIKE \'%' + templateNameString + '%\'';
        }
        
        if(!String.isBlank(countryFilterString))
        {
            system.debug(LoggingLevel.error,'### countryFilterString ' + countryFilterString );
            system.debug(LoggingLevel.error,'### Add to query '  );
            query += ' AND Country__c INCLUDES (\'' + countryFilterString + '\')';
        }
        
        if(!String.isBlank(productTypeFilterString))
        {
            system.debug(LoggingLevel.error,'### productTypeFilterString ' + productTypeFilterString );
            system.debug(LoggingLevel.error,'### Add to query '  );
            query += ' AND Product_Type__c = \'' + productTypeFilterString + '\'';
        }
/*          
        if(bundlesOnly)
        {
            query += ' AND APXTConga4__Template_Type__c = \'' + bg_DocumentUtils.TEMPLATE_TYPE_BUNDLE + '\'';
        }
*/
        query += ' ORDER BY APXTConga4__Name__c ASC';
        //query += ' WHERE Active__c = true';
        
        system.debug(LoggingLevel.error,'### Query ' + query );
        return query;
    }
    
    
    public list<APXTConga4__Conga_Template__c> GetTemplateList()
    {
        /* Retruns a list of Conga Tempaltes that are used by TemplateQuery Objects and are Active */
        list<APXTConga4__Conga_Template__c> TemplateList;
        list<APXTConga4__Conga_Template__c> ListToReturn = new list<APXTConga4__Conga_Template__c>();
     
        //TemplateList = [SELECT APXTConga4__Name__c, Id, Number_Of_Queries_Used_Max_Allowed_50__c, Type__c, APXTConga4__Template_Group__c, Language__c
        //              FROM APXTConga4__Conga_Template__c
        //              WHERE Active__c = true AND Number_Of_Queries_Used_Max_Allowed_50__c != 0
        //              limit 500];
        TemplateList = Database.query(BuildQueryString());
        for(APXTConga4__Conga_Template__c ct :TemplateList)
        {
            if((ct.attachments != null && ct.attachments.size() > 0) 
                || ct.APXTConga4__Template_Type__c == bg_DocumentUtils.TEMPLATE_TYPE_BUNDLE)
            {
                ListToReturn.add(ct);
            }
        }
        return ListToReturn;        
        //return TemplateList;
    }
    
    public PageReference GenerateURL()
    {
        /* 
            Generate a URL that points to the conga page to generate document, however checks to ensure no more then 50 queiries have been selected 
        */
        PageReference retPage = null;
        
        if(currentNoQueriesUsed == MIN_NO_OF_QUERIES)
        {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, CHOOSE_AT_LEAST_ONE_TEMPLATE));
        }else if(currentNoQueriesUsed > MAX_NO_OF_QUERIES)
        {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, CHOOSEN_TOO_MANY_TEMPLATE_QUERIES));
        }else if(CurrentRightList.size() > 10)
        {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, CHOOSEN_TOO_MANY_TEMPLATES));
        }else
        {
            retPage = new pageReference(bg_DocumentUtils.GetDocumentURL(quoteId, CurrentRightList, docType, recipientContactIds, false, true, false, false));
        }
        
        return retPage;
    }
    
    public List<SelectOption> getLanguageFilter()
    {
        /*
            Sets up a custom picklist for the "Lanugage" picklist by getting the values from the Language__c field on Conga Template
        */
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', '--No Filter--'));
                
        Schema.sObjectType objType = APXTConga4__Conga_Template__c.getSObjectType(); 
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();       
        map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap(); 
        list<Schema.PicklistEntry> values = fieldMap.get('Language__c').getDescribe().getPickListValues();
        
        for (Schema.PicklistEntry a : values)
        { 
            options.add(new SelectOption(a.getLabel(), a.getValue())); 
        }
        
        return options;
    }
    
    public List<SelectOption> getTypeFilter()
    {
        /*
            Sets up a custom picklist for the "Type' picklist by using the fields created in bg_DocumentUtils
        */
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', '--No Filter--'));
                
        options.add(new SelectOption(bg_DocumentUtils.DOCUMENT_TYPE_FACT_VALIDATION, bg_DocumentUtils.DOCUMENT_TYPE_FACT_VALIDATION)); 
        options.add(new SelectOption(bg_DocumentUtils.DOCUMENT_TYPE_PROPOSAL, bg_DocumentUtils.DOCUMENT_TYPE_PROPOSAL)); 
        options.add(new SelectOption(bg_DocumentUtils.DOCUMENT_TYPE_TECH_REVIEW, bg_DocumentUtils.DOCUMENT_TYPE_TECH_REVIEW)); 
        //options.add(new SelectOption(bg_DocumentUtils.DOCUMENT_TYPE_SALES_BRIEF, bg_DocumentUtils.DOCUMENT_TYPE_SALES_BRIEF));    *CURRENTLY NOT IN USE* 
        options.add(new SelectOption(bg_DocumentUtils.DOCUMENT_TYPE_SOW, bg_DocumentUtils.DOCUMENT_TYPE_SOW));
        
        
        return options;
    }
    
    public List<SelectOption> getCountryFilter()
    {
        /*
            Sets up a custom picklist for the "Country" picklist by getting the values from the Country__c field on CongaTemplate
        */
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', '--No Filter--'));
                
        Schema.sObjectType objType = APXTConga4__Conga_Template__c.getSObjectType(); 
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();       
        map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap(); 
        list<Schema.PicklistEntry> values = fieldMap.get('Country__c').getDescribe().getPickListValues();
        
        for (Schema.PicklistEntry a : values)
        { 
            options.add(new SelectOption(a.getLabel(), a.getValue())); 
        }
        
        return options;
    }   
    
    public List<SelectOption> getProductTypeFilter()
    {
        /*
            Sets up a custom picklist for the "Product Type" picklist by getting the values from the Product_Type__c field on CongaTemplate
        */
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', '--No Filter--'));
                
        Schema.sObjectType objType = APXTConga4__Conga_Template__c.getSObjectType(); 
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();       
        map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap(); 
        list<Schema.PicklistEntry> values = fieldMap.get('Product_Type__c').getDescribe().getPickListValues();
        
        for (Schema.PicklistEntry a : values)
        { 
            options.add(new SelectOption(a.getLabel(), a.getValue())); 
        }
        
        return options;
    }

    public void Cancel() 
    {
        /*
            Return to record page
        */
        reloadNeeded = true;
        Pagereference retPage = new Pagereference('/' + quoteId);
        reloadPageURL = retPage.getURL();
    }
    
    /*
        If the selected template is a bundle, add the bundle templates to the options
    */
    private list<APXTConga4__Conga_Template__c> GetBundleTemplates(string bundleId)
    {
        String queryBT;
        queryBT = 'SELECT Conga_Template__c';
        queryBT += ' FROM Bundle_Template__c';
        queryBT += ' WHERE Bundle_Template__c = :bundleId';
        queryBT += ' ORDER BY order__c ASC';

        string query = GetTemplateSelectQuery();
        query += ' AND Id IN (SELECT Conga_Template__c FROM Bundle_Template__c WHERE Bundle_Template__c =: bundleId)';
        map<Id, APXTConga4__Conga_Template__c> ctMap = new map<Id, APXTConga4__Conga_Template__c>();
        ctMap.putAll((list<APXTConga4__Conga_Template__c>)Database.query(query));

        list<APXTConga4__Conga_Template__c> templates = new list<APXTConga4__Conga_Template__c>();
        for(Bundle_Template__c bt : Database.query(queryBT))
        {
            if(ctMap.get(bt.Conga_Template__c).attachments.size() > 0)
            {               
                templates.add(ctMap.get(bt.Conga_Template__c));
            }
        }
        return templates;
    }
}