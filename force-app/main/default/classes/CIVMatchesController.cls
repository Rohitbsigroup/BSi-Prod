/********************************************************************
 * CIVMatchesController
 *
 * Controller class for civMatches component
 * 
 * 
 * Author: Alexis Lignereux
 * Created: 15-09-2014
 * Changes: 
 ********************************************************************/
public with sharing class CIVMatchesController {

    private static Integer SEARCH_LIMIT                         = 20;

    public sObject record {get; set;}
    public string sourceObjectType {get; set;}
    public String recordNameValue {get; set;}
    public Boolean isNameValue {get; set;}
    public String recordCompanyValue {get; set;}
    public Boolean isCompanyValue {get; set;}
    public String recordPostcodeValue {get; set;}
    public Boolean isPostcodeValue {get; set;}
    public String recordEmailValue {get; set;}
    public Boolean isEmailValue {get; set;}
    public String recordPhoneValue {get; set;}
    public Boolean isPhoneValue {get; set;} 
    public Integer newLimit{get; set;}
    public Boolean refreshPage {get; set;}
    public String mergeUrl {get; set;}
    public String recordAccountId {get; set;}
    public String recordContactId {get; set;}

    public Boolean isLead {get; set;}
    public Boolean isContact {get; set;}
    public Boolean isAccount {get; set;}
    public Boolean isOpportunity {get; set;}
    
    // indicates whether there are more records after the current page set.
    public Boolean hasNext { get; set; }

    // indicates whether there are more records before the current page set.
    public Boolean hasPrevious { get; set; }

    // returns the page number of the current page set
    public Integer pageNumber { get; set; }
    
    // variable used for linkOrMerge
    public String actionString {get; set; }
    public Id linkId {get; set;}
    public String actionObjectType {get; set;}
    public Boolean reloadPage {get; set;}
    public Boolean isMerged {get; set;}
	
	private string orderBy;
	public boolean orderAsc {get; set;}
	
    public CIVMatchesController() {
        isLead = true;
        isContact = true;
        isAccount = true;
        isOpportunity = false;
        
        isNameValue = true;
        isCompanyValue = true;
        isEmailValue = true;
        isPhoneValue = true;
        isPostcodeValue = true;
        
        pageNumber = 1;

        reloadPage = false;
        isMerged = false;
        
        orderAsc = false;
        orderBy = bg_CIVUtils.SORTCOL_SCORE;
        sortColumnName = orderBy;
    }

    private boolean isInitialised = false;
    private void Initialise() {
        /*
            Initialise class variables
        */
        sourceObjectType = record.getSObjectType().getDescribe().getName();
        isInitialised = true;
    }

    public list<bg_CIVUtils.SearchResultWrapper> getSearchResults() {

        if(!isInitialised) { Initialise(); }

        list<bg_CIVUtils.SearchResultWrapper> searchResults = new list<bg_CIVUtils.SearchResultWrapper>();

        string soslString = bg_CIVUtils.createSoslString(isNameValue, recordNameValue, isCompanyValue, recordCompanyValue, isPostcodeValue, 
            recordPostcodeValue, isPhoneValue, recordPhoneValue, isEmailValue, recordEmailValue, isLead, isAccount, isContact, 
            isOpportunity, pageNumber, record.id);

        if (soslString != null) {
            list<list<sObject>> objs = search.query(soslString);
            
            map<string, string> valueMap = new map<string, string>();
            if(isNameValue) {
            	valueMap.put(bg_CIVUtils.SEARCH_TERM_NAME,		recordNameValue);
            }
            if(isCompanyValue) {            
            	valueMap.put(bg_CIVUtils.SEARCH_TERM_COMPANY,	recordCompanyValue);
            }
            if(isPhoneValue) {            
            	valueMap.put(bg_CIVUtils.SEARCH_TERM_PHONE,		recordPhoneValue);
            }
            if(isEmailValue) {            
            	valueMap.put(bg_CIVUtils.SEARCH_TERM_EMAIL,		recordEmailValue);
            }
            if(isPostcodeValue) {            
            	valueMap.put(bg_CIVUtils.SEARCH_TERM_POSTCODE,	recordPostcodeValue);
            }

			map<Id, CIV_Link__c> linkMap = bg_CIVLinkUtils.GetLinkMap(record.Id);
			
            searchResults = bg_CIVUtils.CreateSearchResultWrappers(objs, valueMap, sourceObjectType, recordAccountId, recordContactId, linkMap, orderBy, orderAsc);
            
            // ensure pagination link are being displayed correctly
            if (pageNumber > 1) {
                hasPrevious = true;
            } else {
                hasPrevious = false;
            }
            
            Integer loopLimit;
            if (searchResults.size() > (pageNumber*bg_CIVUtils.MAX_ROWS)) {
                hasNext = true;
                loopLimit = pageNumber*bg_CIVUtils.MAX_ROWS;
            } else {
                loopLimit = searchResults.size();
                hasNext = false;
            }
            searchResults.sort();

            List<bg_CIVUtils.SearchResultWrapper> newSearchResults = new list<bg_CIVUtils.SearchResultWrapper>();
            for (Integer i = ( (pageNumber-1)*bg_CIVUtils.MAX_ROWS); i < loopLimit; i++) {
                newSearchResults.add(searchResults[i]);
            }
            return newSearchResults;
        }
        return searchResults;
    }
    

    public PageReference filter() {

       if (!isLead && !isAccount && !isContact && !isOpportunity) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, Label.CIV_Filter_Error));
       }
        pageNumber = 1;
        return null;
    }
    
    public PageReference search() {
        if (!isNameValue && !isCompanyValue && !isEmailValue && !isPhoneValue && !isPostcodeValue) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, Label.CIV_Search_Error));
        } 
        pageNumber = 1;
        return null;
    }

    // returns the previous page of records
    public PageReference previous() {
        pageNumber--;
        return null;
    }

    // returns the next page of records
    public PageReference next() {
        pageNumber++;
        return null;
    }

    // returns the PageReference of the original page, if known, or the home page.
    public PageReference linkOrMerge() {

        system.debug('Alexis == ' + actionString);
        if (actionString == bg_CIVUtils.SYNC_ACTION) {
            reloadPage = true;
            overwrite(linkId, actionObjectType);

        } else if (actionString == bg_CIVUtils.LINK_ACTION) {
            // Link record together 
            bg_CIVLinkUtils.AddLink(record.id, linkId);

        } else if (actionString == bg_CIVUtils.UNLINK_ACTION) {
            // remove record together 
            bg_CIVLinkUtils.RemoveLink(linkId, record.Id);

        } else if (actionString == bg_CIVUtils.MERGE_ACTION) {
            //mergeUrl = bg_CIVUtils.LEAD_MERGE_WIZARD_URL + 'retURL=%2F' + record.id + '&id=' + record.id;
            mergeUrl = bg_CIVUtils.getLeadMergeURL((string)record.id, new list<string>{linkId});
            refreshPage = true;
            isMerged = true;
        }
        return null;
    }
    
    private void overwrite(Id linkId, String actionObjectType) {
        if (sourceObjectType == bg_CIVUtils.LEAD_OBJECT_TYPE_NAME) {
            Lead leadRecord = (Lead)record;
            if (actionObjectType == bg_CIVUtils.ACCOUNT_OBJECT_TYPE_NAME) {
                refreshPage=true;
                leadRecord.Existing_Customer_Account__c = linkId;
                update leadRecord;
            } else if (actionObjectType == bg_CIVUtils.CONTACT_OBJECT_TYPE_NAME) {
                refreshPage=true;
                leadRecord.Contact__c = linkId;
                update leadRecord;
            }
        }
    }
    
    public string sortColumnName {get; set;}
    public PageReference sortResults() {
    	if(sortColumnName == orderBy) {
    		orderAsc = !orderAsc;
    	} else {
    		orderBy = sortColumnName;
    		orderAsc = true;
    	}
     	return null;
    }
    
    
}