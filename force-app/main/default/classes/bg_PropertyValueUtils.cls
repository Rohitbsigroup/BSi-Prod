/********************************************************************
 * bg_PropertyValueUtils
 *
 * Utility methods to support Property Value functions
 * 
 * 
 * Author: Richard Jimenez
 * Created: 06-01-2014
 * Changes: 21-08-2015 ASD-BG Adding in Consultant COmpnay, Name and Total Employees on Site - //SOW Template Requirements
 ********************************************************************/
public class bg_PropertyValueUtils {

    // Property Alias Values
    public static string PROPERTYALIAS_SCOPE            = 'NotesScope';              // Free-Text
    public static string PROPERTYALIAS_SITE_EMPLOYEES   = 'EffectiveEmployeeTotal';  // Number
    public static string PROPERTYALIAS_SITE_ACTIVITIES  = 'NotesEmployeeActivity';   // Free-Text
    public static string PROPERTYALIAS_ANNEX            = 'CommentsAnnex';               // Free-Text
    public static string PROPERTYALIAS_EMPLOYEE_RISK_CATEGORY    = 'EmployeeRiskCategory'; // Free-Text
    
    public static string PROPERTYALIAS_TRAININGATTENDEES    = 'TrainingAttendees'; //Number

    public static string PROPERTYALIAS_ACCREDITATION_TYPE_CMDCAS    = 'TypeCmdcas';
    public static string PROPERTYALIAS_ACCREDITATION_TYPE_DAKKS     = 'TypeDakks';
    public static string PROPERTYALIAS_ACCREDITATION_TYPE_SCC       = 'TypeScc';
    public static string PROPERTYALIAS_ACCREDITATION_TYPE_UKAS      = 'TypeUkas';
    
    public static string PROPERTYALIAS_CHECKSECURITY    = 'CheckSecurity'; //boolean
    public static string PROPERTYALIAS_CHECKCSR         = 'CheckCSR'; //boolean
    public static string PROPERTYALIAS_CHECKBCM         = 'CheckBCM'; //boolean
    public static string PROPERTYALIAS_CHECKQUALITY     = 'CheckQuality'; //boolean
    public static string PROPERTYALIAS_CHECKISMS        = 'CheckISMS'; //boolean
    public static string PROPERTYALIAS_CHECKEHS         = 'CheckEHS'; //boolean
    public static string PROPERTYALIAS_CHECKVERIFICATION        = 'CheckVerification'; //boolean
    public static string PROPERTYALIAS_CHECKSCREEN              = 'CheckScreen'; //boolean
    public static string PROPERTYALIAS_CHECKSCM                 = 'CheckSCM'; //boolean
    public static string PROPERTYALIAS_CHECKADVISORYSERVICES    = 'CheckAdvisoryServices'; //boolean
    public static string PROPERTYALIAS_CHECKMANAGEDSERVICES     = 'YesNoManagedServices'; //boolean
    
    // Entropy values
    public static string PROPERTYALIAS_COMPMGT = 'YesNoComplianceManagement'; // text
    public static string PROPERTYALIAS_KNOWMGT = 'YesNoKnowledgeManagement'; // text
    public static string PROPERTYALIAS_INCMGT = 'YesNoIncidentManagement'; // text
    public static string PROPERTYALIAS_RISKMGT = 'YesNoRiskManagement'; // text
    public static string PROPERTYALIAS_PERFMGT = 'YesNoPerformanceManagement'; // text
    public static string PROPERTYALIAS_NUMLANG = 'NumberLanguages'; // number
    public static string PROPERTYALIAS_LICENCEPREF = 'LicensePref'; // text
    public static string PROPERTYALIAS_HOSTING = 'HostingType'; // text
    public static string PROPERTYALIAS_LICSITES = 'NumSites'; // number
    public static string PROPERTYALIAS_LICACTIVE = 'NumberActiveUsers'; // number
    public static string PROPERTYALIAS_LICPASSIVE = 'PassiveUserLicenses'; // number
    public static string PROPERTYALIAS_NUMSUPP = 'NumberSuppliers'; // number
    public static string PROPERTYALIAS_TYPESETUP = 'TypeSetup'; // text
    public static string PROPERTYALIAS_ANNSUPPHOURS = 'AnnualSupportHours'; // number
    public static string PROPERTYALIAS_SUPTRAIN = 'YesNoSupervisorTraining'; // text
    public static string PROPERTYALIAS_ENDUSERTRAIN = 'YesNoEndUserTraining'; // text
    public static string PROPERTYALIAS_REMOTETRAIN = 'RemoteTraining'; // number
    public static string PROPERTYALIAS_FDATOOL = 'YesNoValidationToolkit'; // text
    public static string PROPERTYALIAS_FDAVAL = 'FDAServices'; // text
    
    public static string PROPERTYALIAS_PRICESITES = 'PriceDisplayLicensedSites'; // number
    public static string PROPERTYALIAS_PRICEMODULES = 'PriceDisplayLicensedModules'; // number
    public static string PROPERTYALIAS_PRICELICSUPP = 'PriceDisplayLicensedSuppliers'; // number
    public static string PROPERTYALIAS_PRICEMAINTINIT = 'PriceDisplayMaintEnhancementInitial'; // number
    public static string PROPERTYALIAS_PRICESETUPCONFIG = 'PriceDisplaySetupConfig'; // number
    public static string PROPERTYALIAS_PRICEADDENTTRAIN = 'PriceDisplayAddEntropyTraining'; // number
    public static string PROPERTYALIAS_PRICEFDATOOLKIT = 'PriceDisplayFDAToolkit'; // number
    public static string PROPERTYALIAS_PRICEFDASERV = 'PriceDisplayFDAServices'; // number
    public static string PROPERTYALIAS_PRICECUSTSERV = 'PriceDisplayCustomServices'; // number
    public static string PROPERTYALIAS_PRICEREMSUPPINIT = 'PriceDisplayRemoteSupportInitial'; // number
    public static string PROPERTYALIAS_TOTALINITPRICE = 'TotalInitPrice'; // number
    public static string PROPERTYALIAS_PRICEMAINTYEAR2 = 'PriceDisplayMaintEnhancementYear2'; // number
    public static string PROPERTYALIAS_PRICEREMSUPPYEAR2 = 'PriceDisplayRemoteSupportYear2'; // number
    public static string PROPERTYALIAS_TOTALYEAR2PRICE = 'TotalYear2Price'; // number
    public static string PROPERTYALIAS_AVANNCOSTSITE = 'AvAnnTotalCostPerSite'; // number
    public static string PROPERTYALIAS_AVMONCOSTUSER = 'AvMonthCostPerUser'; // number
    public static string PROPERTYALIAS_AVMONCOSTEMP = 'AvMonthCostPerEmp'; // number
    public static string PROPERTYALIAS_PRICEACTIVEUSERLIC = 'PriceDisplayActiveUserLicenses'; // number
    public static string PROPERTYALIAS_PRICEANNSUPPLIC = 'PriceDisplayAnnualSupplierLicenses'; // number
    public static string PROPERTYALIAS_PRICESUBSYEAR2 = 'PriceDisplaySubscriptionYear2'; // number
    public static string PROPERTYALIAS_PRICEPASSIVEUSERLIC = 'PriceDisplayPassiveUserLicenses'; // number
    public static string PROPERTYALIAS_PRICEPROFSERV = 'PriceDisplayProfessionalServices'; // number
    public static string PROPERTYALIAS_TERM = 'Term'; // text
    
    //SOW Template Requirements
    public static string PROPERTYALIAS_TOTAL_SITE_EMPLOYEES = 'TotalEmployees'; // number
    public static string PROPERTYALIAS_CONSULTANT_COMPANY = 'ConsultantCompany'; // text
    public static string PROPERTYALIAS_CONSULTANT_NAME = 'ConsultantName'; // text

    public static boolean LockPropertyValueTrigger = false;
        
    private static set<string> GetPropertyAliasSet() {
        /*
            Method to return set of Property Alias
        */
        set<string> propertyAliasSet = new set<string>();
        
        /* Add Opportunity Site Property Alias's */
        propertyAliasSet.addAll(GetQuoteProductPAMap().keySet());
        
        return propertyAliasSet;
    }  
    
    public static void PopulateObjectsWithPropertyValues(list<PropertyValue__c> propertyValues) {
        /*
            Method to populate main objects with property values
        */
        PopulateObjectsWithPropertyValues(propertyValues, null);    
    }   
    
    public static void PopulateObjectsWithPropertyValues(list<PropertyValue__c> propertyValues, map<Id, PropertyValue__c> oldMapPropertyValues) {
        /*
            Method to populate main objects with property values
        */
        
        try {
            system.debug('PopulateObjectsWithPropertyValues: ' + propertyValues);       
            
            // build list of alias's we are interested in
            set<string> propertyAlias = GetPropertyAliasSet();
            set<Id> qpIds = new set<Id>();
            
            // build map of values
            map<string, list<PropertyValue__c>> pvMap = new map<string, list<PropertyValue__c>>();  
            for(PropertyValue__c pv : propertyValues) {
                if(propertyAlias.contains(pv.ProductPropertyAlias__c)
                    && (oldMapPropertyValues == null || 
                        (pv.QuoteToProduct__c != null && oldMapPropertyValues.get(pv.Id).QuoteToProduct__c == null) ||
                        pv.Value__c     != oldMapPropertyValues.get(pv.Id).Value__c ||
                        pv.TextValue__c != oldMapPropertyValues.get(pv.Id).TextValue__c)) {
                    
                    if(!pvMap.containsKey(pv.ProductPropertyAlias__c)) {
                        pvMap.put(pv.ProductPropertyAlias__c, new list<PropertyValue__c>());
                    }
                    pvMap.get(pv.ProductPropertyAlias__c).add(pv);
                    qpIds.add(pv.QuoteToProduct__c);
                }
            }
    
            /* UPDATE MAIN OBJECTS WITH PROPERTY VALUE DATA */
            if(!pvMap.isEmpty()) {
                // Update Quote Products
                UpdateQuoteProducts(pvMap, qpIds);
            }
        } catch (Exception ex) {
            system.debug('Exception PopulateObjectsWithPropertyValues: ' + ex.getMessage());
        } 
    }

    private static integer TARGET_TYPE_TEXT = 1;
    private static integer TARGET_TYPE_NUMBER = 2;
    private static integer TARGET_TYPE_LIST = 3;
    private static integer TARGET_TYPE_BOOLEAN = 4;

    private class TransformWrapper {
        public string PropertyAlias;
        public string TargetField;
        public integer TargetType;
        public map<string, string> replacementMap;
        
        public string noValueString; 

        public TransformWrapper() {
            replacementMap = new map<string, string>();
        }

        public TransformWrapper(string pPropertyAlias, string pTargetField, integer pTargetType) {
            this();
            PropertyAlias = pPropertyAlias;
            TargetField = pTargetField;
            TargetType = pTargetType;
        } 

        public TransformWrapper(string pPropertyAlias, string pTargetField, integer pTargetType, string findString, string replaceWith) {
            this(pPropertyAlias, pTargetField, pTargetType);
            replacementMap.put(findString, replaceWith);
        }
        
        public string GetValue(string value) {
            /*
                Method to return string value
            */

            if(replacementMap.containsKey(value)) {
                return replacementMap.get(value);
            } else {
                return value;
            }
        }

        public decimal GetValue(decimal value) {
            /*
                Method to return decimal value
            */
            string stringValue = string.valueOf(value);
            if(replacementMap.containsKey(stringValue)) {
                return decimal.valueOf(replacementMap.get(stringValue));
            } else {
                return value;
            }
        }

        public set<string> GetValueSet(set<string> valueSet, string value) {
            /*
                Method to return updated set of values
            */
            if(!replacementMap.containsKey(value)) {
                for(string val : replacementMap.values()) {
                    valueSet.remove(val);
                }
            } else {
                valueSet.add(GetValue(value));
            }
            return valueSet;
        }
    }

    private static map<string, TransformWrapper> GetQuoteProductPAMap() {
        /*
            Method to return Quote Product Property Alias
        */
        map<string, TransformWrapper> propertyAliasSet = new map<string, TransformWrapper>();
        
        propertyAliasSet.put(PROPERTYALIAS_EMPLOYEE_RISK_CATEGORY,           new TransformWrapper(PROPERTYALIAS_EMPLOYEE_RISK_CATEGORY,           'Employee_Risk_Category__c',                 TARGET_TYPE_TEXT));
        propertyAliasSet.put(PROPERTYALIAS_SCOPE,           new TransformWrapper(PROPERTYALIAS_SCOPE,           'Scope__c',                 TARGET_TYPE_TEXT));
        propertyAliasSet.put(PROPERTYALIAS_SITE_ACTIVITIES, new TransformWrapper(PROPERTYALIAS_SITE_ACTIVITIES,     'Site_Activities__c', TARGET_TYPE_TEXT));
        propertyAliasSet.put(PROPERTYALIAS_SITE_EMPLOYEES,  new TransformWrapper(PROPERTYALIAS_SITE_EMPLOYEES,  'SiteEmployees__c',         TARGET_TYPE_NUMBER));
        propertyAliasSet.put(PROPERTYALIAS_ANNEX,           new TransformWrapper(PROPERTYALIAS_ANNEX,           'Annex__c',              TARGET_TYPE_TEXT));
        
        propertyAliasSet.put(PROPERTYALIAS_TRAININGATTENDEES,   new TransformWrapper(PROPERTYALIAS_TRAININGATTENDEES,           'TrainingAttendees__c',              TARGET_TYPE_NUMBER));

        propertyAliasSet.put(PROPERTYALIAS_ACCREDITATION_TYPE_CMDCAS, new TransformWrapper(PROPERTYALIAS_ACCREDITATION_TYPE_CMDCAS,     'Accreditation__c',             TARGET_TYPE_LIST,   'true', 'CMDCAS'));
        propertyAliasSet.put(PROPERTYALIAS_ACCREDITATION_TYPE_DAKKS,  new TransformWrapper(PROPERTYALIAS_ACCREDITATION_TYPE_DAKKS,  'Accreditation__c',             TARGET_TYPE_LIST,   'true', 'DAKKS'));
        propertyAliasSet.put(PROPERTYALIAS_ACCREDITATION_TYPE_SCC,    new TransformWrapper(PROPERTYALIAS_ACCREDITATION_TYPE_SCC,    'Accreditation__c',             TARGET_TYPE_LIST,   'true', 'SCC'));
        propertyAliasSet.put(PROPERTYALIAS_ACCREDITATION_TYPE_UKAS,   new TransformWrapper(PROPERTYALIAS_ACCREDITATION_TYPE_UKAS,   'Accreditation__c',             TARGET_TYPE_LIST,   'true', 'UKAS'));


        propertyAliasSet.put(PROPERTYALIAS_CHECKSECURITY, new TransformWrapper(PROPERTYALIAS_CHECKSECURITY, 'checkSecurity__c', TARGET_TYPE_BOOLEAN));
        propertyAliasSet.put(PROPERTYALIAS_CHECKCSR, new TransformWrapper(PROPERTYALIAS_CHECKCSR, 'checkCSR__c', TARGET_TYPE_BOOLEAN));
        propertyAliasSet.put(PROPERTYALIAS_CHECKBCM, new TransformWrapper(PROPERTYALIAS_CHECKBCM, 'checkBCM__c', TARGET_TYPE_BOOLEAN));
        propertyAliasSet.put(PROPERTYALIAS_CHECKQUALITY, new TransformWrapper(PROPERTYALIAS_CHECKQUALITY, 'checkQuality__c', TARGET_TYPE_BOOLEAN));
        propertyAliasSet.put(PROPERTYALIAS_CHECKISMS, new TransformWrapper(PROPERTYALIAS_CHECKISMS, 'checkISMS__c', TARGET_TYPE_BOOLEAN));
        propertyAliasSet.put(PROPERTYALIAS_CHECKEHS, new TransformWrapper(PROPERTYALIAS_CHECKEHS, 'checkEHS__c', TARGET_TYPE_BOOLEAN));
        propertyAliasSet.put(PROPERTYALIAS_CHECKVERIFICATION, new TransformWrapper(PROPERTYALIAS_CHECKVERIFICATION, 'checkVerification__c', TARGET_TYPE_BOOLEAN));
        propertyAliasSet.put(PROPERTYALIAS_CHECKSCREEN, new TransformWrapper(PROPERTYALIAS_CHECKSCREEN, 'checkScreen__c', TARGET_TYPE_BOOLEAN));
        propertyAliasSet.put(PROPERTYALIAS_CHECKSCM, new TransformWrapper(PROPERTYALIAS_CHECKSCM, 'checkSCM__c', TARGET_TYPE_BOOLEAN));
        propertyAliasSet.put(PROPERTYALIAS_CHECKADVISORYSERVICES, new TransformWrapper(PROPERTYALIAS_CHECKADVISORYSERVICES, 'checkAdvisoryServices__c', TARGET_TYPE_BOOLEAN));
        
        propertyAliasSet.put(PROPERTYALIAS_CHECKMANAGEDSERVICES, new TransformWrapper(PROPERTYALIAS_CHECKMANAGEDSERVICES, 'checkManagedServices__c', TARGET_TYPE_BOOLEAN, 'YES', 'True'));
    
        propertyAliasSet.put(PROPERTYALIAS_COMPMGT, new TransformWrapper(PROPERTYALIAS_COMPMGT, 'compMgt__c', TARGET_TYPE_TEXT));
        propertyAliasSet.put(PROPERTYALIAS_KNOWMGT, new TransformWrapper(PROPERTYALIAS_KNOWMGT, 'knowMgt__c', TARGET_TYPE_TEXT));
        propertyAliasSet.put(PROPERTYALIAS_INCMGT, new TransformWrapper(PROPERTYALIAS_INCMGT, 'incMgt__c', TARGET_TYPE_TEXT));
        propertyAliasSet.put(PROPERTYALIAS_RISKMGT, new TransformWrapper(PROPERTYALIAS_RISKMGT, 'riskMgt__c', TARGET_TYPE_TEXT));
        propertyAliasSet.put(PROPERTYALIAS_PERFMGT, new TransformWrapper(PROPERTYALIAS_PERFMGT, 'perfMgt__c', TARGET_TYPE_TEXT));
        propertyAliasSet.put(PROPERTYALIAS_NUMLANG, new TransformWrapper(PROPERTYALIAS_NUMLANG, 'numLang__c', TARGET_TYPE_NUMBER));
        propertyAliasSet.put(PROPERTYALIAS_LICENCEPREF, new TransformWrapper(PROPERTYALIAS_LICENCEPREF, 'licencePref__c', TARGET_TYPE_TEXT));
        propertyAliasSet.put(PROPERTYALIAS_HOSTING, new TransformWrapper(PROPERTYALIAS_HOSTING, 'hosting__c', TARGET_TYPE_TEXT));
        propertyAliasSet.put(PROPERTYALIAS_LICSITES, new TransformWrapper(PROPERTYALIAS_LICSITES, 'licSites__c', TARGET_TYPE_NUMBER));
        propertyAliasSet.put(PROPERTYALIAS_LICACTIVE, new TransformWrapper(PROPERTYALIAS_LICACTIVE, 'licActive__c', TARGET_TYPE_NUMBER));
        propertyAliasSet.put(PROPERTYALIAS_LICPASSIVE, new TransformWrapper(PROPERTYALIAS_LICPASSIVE, 'licPassive__c', TARGET_TYPE_NUMBER));
        propertyAliasSet.put(PROPERTYALIAS_NUMSUPP, new TransformWrapper(PROPERTYALIAS_NUMSUPP, 'numSupp__c', TARGET_TYPE_NUMBER));
        propertyAliasSet.put(PROPERTYALIAS_TYPESETUP, new TransformWrapper(PROPERTYALIAS_TYPESETUP, 'typeSetup__c', TARGET_TYPE_TEXT));
        propertyAliasSet.put(PROPERTYALIAS_ANNSUPPHOURS, new TransformWrapper(PROPERTYALIAS_ANNSUPPHOURS, 'annSuppHours__c', TARGET_TYPE_NUMBER));
        propertyAliasSet.put(PROPERTYALIAS_SUPTRAIN, new TransformWrapper(PROPERTYALIAS_SUPTRAIN, 'supTrain__c', TARGET_TYPE_TEXT));
        propertyAliasSet.put(PROPERTYALIAS_ENDUSERTRAIN, new TransformWrapper(PROPERTYALIAS_ENDUSERTRAIN, 'endUserTrain__c', TARGET_TYPE_TEXT));
        propertyAliasSet.put(PROPERTYALIAS_REMOTETRAIN, new TransformWrapper(PROPERTYALIAS_REMOTETRAIN, 'remoteTrain__c', TARGET_TYPE_NUMBER));
        propertyAliasSet.put(PROPERTYALIAS_FDAVAL, new TransformWrapper(PROPERTYALIAS_FDAVAL, 'fdaVal__c', TARGET_TYPE_TEXT));
        propertyAliasSet.put(PROPERTYALIAS_FDATOOL, new TransformWrapper(PROPERTYALIAS_FDATOOL, 'fdaTool__c', TARGET_TYPE_TEXT));
    
        propertyAliasSet.put(PROPERTYALIAS_PRICESITES, new TransformWrapper(PROPERTYALIAS_PRICESITES, 'PriceSites__c', TARGET_TYPE_NUMBER));
        propertyAliasSet.put(PROPERTYALIAS_PRICEMODULES, new TransformWrapper(PROPERTYALIAS_PRICEMODULES, 'PriceModules__c', TARGET_TYPE_NUMBER));
        propertyAliasSet.put(PROPERTYALIAS_PRICELICSUPP, new TransformWrapper(PROPERTYALIAS_PRICELICSUPP, 'PriceLicSupp__c', TARGET_TYPE_NUMBER));
        propertyAliasSet.put(PROPERTYALIAS_PRICEMAINTINIT, new TransformWrapper(PROPERTYALIAS_PRICEMAINTINIT, 'PriceMaintInit__c', TARGET_TYPE_NUMBER));
        propertyAliasSet.put(PROPERTYALIAS_PRICESETUPCONFIG, new TransformWrapper(PROPERTYALIAS_PRICESETUPCONFIG, 'PriceSetupConfig__c', TARGET_TYPE_NUMBER));
        propertyAliasSet.put(PROPERTYALIAS_PRICEADDENTTRAIN, new TransformWrapper(PROPERTYALIAS_PRICEADDENTTRAIN, 'PriceAddEntTrain__c', TARGET_TYPE_NUMBER));
        propertyAliasSet.put(PROPERTYALIAS_PRICEFDATOOLKIT, new TransformWrapper(PROPERTYALIAS_PRICEFDATOOLKIT, 'PriceFDAToolkit__c', TARGET_TYPE_NUMBER));
        propertyAliasSet.put(PROPERTYALIAS_PRICEFDASERV, new TransformWrapper(PROPERTYALIAS_PRICEFDASERV, 'PriceFDAServ__c', TARGET_TYPE_NUMBER));
        propertyAliasSet.put(PROPERTYALIAS_PRICECUSTSERV, new TransformWrapper(PROPERTYALIAS_PRICECUSTSERV, 'PriceCustServ__c', TARGET_TYPE_NUMBER));
        propertyAliasSet.put(PROPERTYALIAS_PRICEREMSUPPINIT, new TransformWrapper(PROPERTYALIAS_PRICEREMSUPPINIT, 'PriceRemSuppInit__c', TARGET_TYPE_NUMBER));
        propertyAliasSet.put(PROPERTYALIAS_TOTALINITPRICE, new TransformWrapper(PROPERTYALIAS_TOTALINITPRICE, 'TotalInitPrice__c', TARGET_TYPE_NUMBER));
        propertyAliasSet.put(PROPERTYALIAS_PRICEMAINTYEAR2, new TransformWrapper(PROPERTYALIAS_PRICEMAINTYEAR2, 'PriceMaintYear2__c', TARGET_TYPE_NUMBER));
        propertyAliasSet.put(PROPERTYALIAS_PRICEREMSUPPYEAR2, new TransformWrapper(PROPERTYALIAS_PRICEREMSUPPYEAR2, 'PriceRemSuppYear2__c', TARGET_TYPE_NUMBER));
        propertyAliasSet.put(PROPERTYALIAS_TOTALYEAR2PRICE, new TransformWrapper(PROPERTYALIAS_TOTALYEAR2PRICE, 'TotalYear2Price__c', TARGET_TYPE_NUMBER));
        propertyAliasSet.put(PROPERTYALIAS_AVANNCOSTSITE, new TransformWrapper(PROPERTYALIAS_AVANNCOSTSITE, 'AvAnnCostSite__c', TARGET_TYPE_NUMBER));
        propertyAliasSet.put(PROPERTYALIAS_AVMONCOSTUSER, new TransformWrapper(PROPERTYALIAS_AVMONCOSTUSER, 'AvMonCostUser__c', TARGET_TYPE_NUMBER));
        propertyAliasSet.put(PROPERTYALIAS_AVMONCOSTEMP, new TransformWrapper(PROPERTYALIAS_AVMONCOSTEMP, 'AvMonCostEmp__c', TARGET_TYPE_NUMBER));
        propertyAliasSet.put(PROPERTYALIAS_PRICEACTIVEUSERLIC, new TransformWrapper(PROPERTYALIAS_PRICEACTIVEUSERLIC, 'PriceActiveUserLic__c', TARGET_TYPE_NUMBER));
        propertyAliasSet.put(PROPERTYALIAS_PRICEANNSUPPLIC, new TransformWrapper(PROPERTYALIAS_PRICEANNSUPPLIC, 'PriceAnnSuppLic__c', TARGET_TYPE_NUMBER));
        propertyAliasSet.put(PROPERTYALIAS_PRICESUBSYEAR2, new TransformWrapper(PROPERTYALIAS_PRICESUBSYEAR2, 'PriceSubYear2__c', TARGET_TYPE_NUMBER));
        propertyAliasSet.put(PROPERTYALIAS_PRICEPASSIVEUSERLIC, new TransformWrapper(PROPERTYALIAS_PRICEPASSIVEUSERLIC, 'PricePassiveUserLic__c', TARGET_TYPE_NUMBER));
        propertyAliasSet.put(PROPERTYALIAS_PRICEPROFSERV, new TransformWrapper(PROPERTYALIAS_PRICEPROFSERV, 'PriceProfServ__c', TARGET_TYPE_NUMBER));
        propertyAliasSet.put(PROPERTYALIAS_TERM, new TransformWrapper(PROPERTYALIAS_TERM, 'Term__c', TARGET_TYPE_TEXT));
        
        //SOW Template Requirements
        propertyAliasSet.put(PROPERTYALIAS_TOTAL_SITE_EMPLOYEES,  new TransformWrapper(PROPERTYALIAS_TOTAL_SITE_EMPLOYEES,  'Total_Employees_On_Site__c',     TARGET_TYPE_NUMBER));
        propertyAliasSet.put(PROPERTYALIAS_CONSULTANT_COMPANY,    new TransformWrapper(PROPERTYALIAS_CONSULTANT_COMPANY,    'Consultant_Company__c',          TARGET_TYPE_TEXT));
        propertyAliasSet.put(PROPERTYALIAS_CONSULTANT_NAME,       new TransformWrapper(PROPERTYALIAS_CONSULTANT_NAME,       'Consultant_Name__c',             TARGET_TYPE_TEXT));
        
    
        return propertyAliasSet;
    }
    
    
    private static void UpdateQuoteProducts(map<string, list<PropertyValue__c>> pvMap, set<Id> qpIds) {
        /*
            Method to update Quote Product with property values 
        */
        
        map<string, TransformWrapper> paMap = GetQuoteProductPAMap();       

        // make dynamic using by soqling out of fields required for list value updates
        map<Id, Quote_Product__c> qpMap = new map<Id, Quote_Product__c>([SELECT Id, Accreditation__c 
                                            FROM Quote_Product__c
                                            WHERE Id IN :qpIds]);

        for(string propertyAlias : paMap.keySet()) {            
            if(pvMap.containsKey(propertyAlias)) {
                list<PropertyValue__c> pvList = pvMap.get(propertyAlias);
                for(PropertyValue__c pv : pvList) {
                    if(!qpMap.containsKey(pv.QuoteToProduct__c)) {
                        Quote_Product__c qp = new Quote_Product__c(Id = pv.QuoteToProduct__c);
                        qpMap.put(pv.QuoteToProduct__c, qp);
                    }

                    TransformWrapper tw = paMap.get(propertyAlias);
                    if(tw.TargetType == TARGET_TYPE_NUMBER) {
                        qpMap.get(pv.QuoteToProduct__c).put(tw.TargetField, tw.GetValue(pv.Value__c));

                    } else if(tw.TargetType == TARGET_TYPE_TEXT) {
                        qpMap.get(pv.QuoteToProduct__c).put(tw.TargetField, tw.GetValue(pv.TextValue__c));

                    } else if(tw.TargetType == TARGET_TYPE_LIST) {
                        set<string> valueSet = bg_StringUtils.ConvertPicklistValueToSet((string)qpMap.get(pv.QuoteToProduct__c).get(tw.TargetField), ',');
                        qpMap.get(pv.QuoteToProduct__c).put(tw.TargetField, bg_StringUtils.ConvertToPicklistValue(tw.GetValueSet(valueSet, pv.TextValue__c), ','));
                    } else if(tw.TargetType == TARGET_TYPE_BOOLEAN) {
                        system.debug('ASD###' + qpMap);
                        system.debug('ASD###' + qpMap.get(pv.QuoteToProduct__c));
                        system.debug('ASD###' + tw);
                        qpMap.get(pv.QuoteToProduct__c).put(tw.TargetField, Boolean.valueOf(tw.GetValue(pv.TextValue__c)));

                    }
                }
            }
        }

        // Update Quote Product records
        if(!qpMap.isEmpty()) {
            system.debug('UpdateQuoteProducts: ' + qpMap);
            update qpMap.values();
        }
    }
    
    public static void UpdatePropertyValuesSequence(Id quoteId)
    {
        UpdatePropertyValuesSequence(quoteId, 'Fact Validation');
    }
    
    public static void UpdatePropertyValuesSequence(Id quoteId, String templateType) 
    {
        /*  
            Add Property Value sequence for Fact Validation output
        */
        integer intOrder = 0;
        list<PropertyValue__c> updPVs = new list<PropertyValue__c>();
        string FactOrderFieldName = 'FactOrderNo__c';
        string TechOrderfieldName = 'TechOrderNo__c';
        string selectedFieldName;

        if(templateType == bg_DocumentUtils.DOCUMENT_TYPE_FACT_VALIDATION) {        
            selectedFieldName = FactOrderFieldName;
        } else if(templateType == bg_DocumentUtils.DOCUMENT_TYPE_TECH_REVIEW) {        
            selectedFieldName = TechOrderfieldName;
        }

        for(PropertyValue__c pv : [SELECT Id, FactOrderNo__c, TechOrderNo__c
                                    FROM PropertyValue__c 
                                    WHERE QuoteToProduct__r.Quote_Ref__c = :quoteId
                                        AND OverridePrompt__c != '' 
                                        AND ProductPropertyAlias__c != '' 
                                        AND ProductToProperty__r.Template_Type__c INCLUDES (:templateType) 
                                        AND IsVisible__c = true 
                                    ORDER BY QuoteToProduct__r.Product_Name__r.Name ASC, 
                                        QuoteToProduct__r.Opportunity_Site__r.HQ__c ASC, 
                                        QuoteToProduct__r.Opportunity_Site__r.Name ASC, 
                                        ValueOrder__c ASC]) {
            intOrder++;    
            pv.put(selectedFieldName, intOrder);
            updPVs.add(pv);                     
        }

        if(!updPVs.isEmpty()) {         
            LockPropertyValueTrigger = true;
            bz_QuoteDataRelator.AlreadyProcessed = true;
            update updPVs;
        }
    }   
}