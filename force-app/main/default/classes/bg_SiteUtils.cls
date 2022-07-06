/********************************************************************
 * bg_SiteUtils
 *
 * Utility methods to support site functions
 * 
 * Author: Richard Jimenez
 * Created: 
 * Changes:  
 *
 ********************************************************************/
public class bg_SiteUtils {

    // CONSTANT VALUES
    public final static string RECORD_TYPE_NAME_NETWORK     = 'NETWORK';
    public final static string RECORD_TYPE_NAME_TRANSIENT   = 'TRANSIENT';
    public final static string RECORD_TYPE_NAME_NAMED       = 'NAMED';
    public final static string RECORD_TYPE_NAME_DEFAULT     = 'DEFAULT';

    public final static string COUNTRY_CODE_UK = 'GB';  
    public final static string COUNTRY_CODE_US = 'US';
    public final static string COUNTRY_CODE_IRELAND = 'IE';
    
    public final static string VF_PAGENAME_ADDOPTYSITE = 'AddSiteToQuote';

    public static final string DEFAULT_RISK_LEVEL = 'Low';
    
    public static string BuildManageOpportunitySitesURL(string oppId, string retUrl) {
        /* Return Manage Opportunity Sites URL */
        return 'apex/' + VF_PAGENAME_ADDOPTYSITE + '?oppid=' + oppId + '&returl=/' + EncodingUtil.urlEncode(retUrl, 'UTF-8');
    }
    
    /****************************************************************************/
    /* Account Sites                                                            */
    public static map<Id, Site__c> GetAccountSitesMap(Id accId) {
        /* Return list of account sites */      
        return new map<Id, Site__c>(GetAccountSites(accId));
    }

    public static list<Site__c> GetAccountSites(Id accId) {
        /* Return list of account sites */
        return [SELECT Id, Name, City__c, Street__c, State__c, Country__c, Country_Code__c, Postcode__c, Type__c, TypeIcon__c, 
                          RecordType.DeveloperName, PrimaryContact__c, TCodeDescr__c, Industry__c, NumberEmployees__c
                  FROM Site__c 
                  WHERE Account__c = :accId];
    }

    /****************************************************************************/
    /* Opportunity Sites                                                        */
    public static list<OpportunitySite__c> GetOpportunitySites(Id oppId) {
        return GetOpportunitySites(oppId, null);
    }

    public static list<OpportunitySite__c> GetOpportunitySites(Id oppId, string siteType) {
        return GetOpportunitySites(oppId, siteType, null, null);
    }

    public static list<OpportunitySite__c> GetOpportunitySites(Id oppId, String siteType, String secondSiteType)
    {
        return GetOpportunitySites(oppId, siteType, null, secondSiteType);
    }
    public static list<OpportunitySite__c> GetOpportunitySites(Id oppId, string siteType, boolean isHQ)
    {
        return GetOpportunitySites(oppId, siteType, isHQ, null);
    }

    public static list<OpportunitySite__c> GetOpportunitySites(Id oppId, string siteType, boolean isHQ, String secondSiteType) {
        /*
            Get opportunity Sites
        */
        string query = 'SELECT Site__c, Site__r.RecordTypeId, Site__r.RecordType.DeveloperName, Site__r.Name, ' + 
                            'Type__c, TCodeDescr__c, SiteTCode__c, ' + //Industry__c,
                            'SiteName__c, SiteType__c, Site__r.S_Code__c, Site__r.Risk_Level__c, Site__r.NumberEmployees__c, ' +
                            'Site__r.Postcode__c, Site__r.Country__c, Site__r.Country_Code__c, Site__r.Street__c, ' +
                            'Site__r.City__c, HQ__c, Site__r.Description__c, ' +
                            'Site__r.SecurityIssue__c, Site__r.GeographicIssue__c, ' + 
                            'Site__r.State__c, Site__r.Type__c, Site__r.TCodeDescr__c ' +
                        'FROM OpportunitySite__c ' + 
                        'WHERE Opportunity__c = :oppId ';

        // Filter by HQ
        /*if(isHQ != null) {
            query += 'AND HQ__c = :isHQ ';
        }*/
        
        // Filter by site type only by 1st site type
        if(!bg_StringUtils.IsBlank(siteType) && bg_StringUtils.IsBlank(secondSiteType)) 
        {
            query += 'AND Site__r.RecordType.DeveloperName = :siteType ';
        }

        //if they both been set to something then 
        if(!bg_StringUtils.IsBlank(siteType) && !bg_StringUtils.IsBlank(secondSiteType)) 
        {
            query += 'AND (Site__r.RecordType.DeveloperName = :siteType  OR Site__r.RecordType.DeveloperName = :secondSiteType) ';
        }


        
        // Order by HQ & Site Type
        query += 'ORDER BY SiteType__c ASC';

        System.debug('query = ' + query);

        // Execute query
        return database.query(query);
    }
    
    public static set<string> GetOpportunitySiteCountries(list<OpportunitySite__c> oppSites) {
        /*
            Return set of countries
        */
        set<string> siteCountries = new set<string>();      
        for (OpportunitySite__c oppSite : oppSites) {
            siteCountries.add(oppSite.Site__r.Country_Code__c);
        }
        return siteCountries;
    }
    
    public static OpportunitySite__c GetOpportunityHQSite(Id oppId) {
        /*
            Return Opportunity HQ Site
        */
        OpportunitySite__c hqSite;
        list<OpportunitySite__c> sites = GetOpportunitySites(oppId, null, true);
        if(!sites.isEmpty()) {
            hqSite = sites[0];
        }
        return hqSite;
    }

    public static void createDefaultSite(List<Account> accounts)
    {
        List<Site__c> defaultSites = new List<Site__c>();
        Map<String,Id> rtypeMap = Utility.getRecordTypes('Site__c');
        Id defaultSiteRecordTypeId = null;
        if(rtypeMap.containsKey(Utility.RTNAME_DEFAULT))
        {
            defaultSiteRecordTypeId = rtypeMap.get(Utility.RTNAME_DEFAULT);
        }
        if(null!=defaultSiteRecordTypeId)
        {
            for(Account acc : accounts)
            {
                if(null!=acc.BillingCountry && acc.BillingCountry.length() == 2)
                {
                    String StateProvince = '';
                    if(null!=acc.BillingState)
                    {
                        StateProvince = acc.BillingState.LEFT(40);
                    }
                    Site__c defaultSite = new Site__c();
                    defaultSite.RecordTypeId = defaultSiteRecordTypeId;
                    defaultSite.Account__c = acc.Id;
                    defaultSite.City__c = acc.BillingCity;
                    defaultSite.Country__c = acc.BillingCountry;
                    defaultSite.Country_Code__c = acc.BillingCountry;
                    defaultSite.Name = acc.Name.LEFT(80);
                    defaultSite.NumberEmployees__c = acc.NumberOfEmployees;
                    defaultSite.Postcode__c = acc.BillingPostalCode;
                    defaultSite.State__c = StateProvince;
                    defaultSite.Street__c = acc.BillingStreet;
                    defaultSite.Type__c = 'HQ';
                    defaultSites.add(defaultSite);
                }
            }
        }
        insert defaultSites; 
    }
}