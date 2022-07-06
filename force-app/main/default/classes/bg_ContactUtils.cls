/********************************************************************
 * bg_ContactUtils
 *
 * Utility methods to support Contact functions
 *
 * 
 * Author: Richard Jimenez
 * Created: 02-09-2013
 * Changes: 
 ********************************************************************/
public with sharing class bg_ContactUtils {

	public static final string RECORD_TYPE_NAME_CLIENTS 			= 'Clients';
	public static final string RECORD_TYPE_NAME_CONSULTANT			= 'Consultants';
	public static final string RECORD_TYPE_NAME_TECH_REVIEW_TEAM	= 'Tech_Review_Team';

	public static final string CONTACT_SITE_ROLE_PRIMARY 		= 'Primary';
	public static final string CONTACT_SITE_ROLE_BOOKING 		= 'Booking';
	public static final string CONTACT_SITE_ROLE_CREDIT_CHECK 	= 'Credit Check';
	public static final string CONTACT_SITE_ROLE_INVOICE		= 'Invoice';
	
	public static final string CONTACT_OPP_ROLE_DECISION_MAKER	= 'Decision Maker';
	public static final string CONTACT_OPP_ROLE_INVOICING		= 'Invoicing';
	public static final string CONTACT_OPP_ROLE_BOOKING			= 'Booking';
	public static final string CONTACT_OPP_ROLE_CREDIT_CHECK	= 'Credit Check';	
	
    public static map<Id, Contact> GetAccountContactMap(Id accId) {
		/* Method to return map of contacts on an account */
		return new map<Id, Contact>(GetAccountContacts(accId));
    }
    
    public static list<Contact> GetAccountContacts(Id accId) {
		/*
			Method to return list of contacts on an account
		*/
		list<Contact> contacts = new list<Contact>();
      	if(!bg_StringUtils.IsBlank(accId)) {
	        contacts.addAll([SELECT Id, Name 
	        			FROM Contact c 
	        			WHERE c.AccountId = :accId 
	        				AND RecordType.DeveloperName != :RECORD_TYPE_NAME_CONSULTANT
	        			ORDER BY Name]);

     	}
      	return contacts;
    }
    
    public static list<Contact> GetAccountContacts(Id accId, integer recordLimit) {
		/*
			Method to return list of contacts on an account
		*/
		list<Contact> contacts = new list<Contact>();
      	if(!bg_StringUtils.IsBlank(accId)) {
	        contacts.addAll([SELECT Id, Name 
	        			FROM Contact c 
	        			WHERE c.AccountId = :accId 
	        				AND RecordType.DeveloperName != :RECORD_TYPE_NAME_CONSULTANT
	        			ORDER BY LastModifiedDate DESC LIMIT :recordLimit]);

     	}
     	contacts.sort();
      	return contacts;
    } 

   	private static map<Id, map<Id, map<string, Contact>>> accountSiteContactMap;
	public static map<Id, map<string, Contact>> GetSiteContactMap(Id accId) {
		/*
			Method to return list of site contacts 
		*/
		if(accountSiteContactMap == null || !accountSiteContactMap.containsKey(accId)) {
			// Get Account Sites
			map<Id, Site__c> siteMap = bg_SiteUtils.GetAccountSitesMap(accId);
			// Build map of site contacts
			map<Id, map<string, Contact>> siteContactMap = new map<Id, map<string, Contact>>();
		    for(ContactSite__c cs :[SELECT Site__c, Contact_Role__c, Contact__c, Contact__r.Id, Contact__r.Name 
		        					FROM ContactSite__c 
		        					WHERE Site__c IN :siteMap.keySet()]){
				if(!siteContactMap.containsKey(cs.Site__c)) {
					siteContactMap.put(cs.Site__c, new map<string, Contact>());
				}
				siteContactMap.get(cs.Site__c).put(cs.Contact_Role__c, cs.Contact__r);
	     	}
	     	
	     	if(accountSiteContactMap == null) { accountSiteContactMap = new map<Id, map<Id, map<string, Contact>>>(); }
	     	accountSiteContactMap.put(accId, siteContactMap);
		}		
      	return accountSiteContactMap.get(accId);
	}

	public static Contact_Opportunity__c GetOpportunityContact(string oppId, string contactId, string role) {
		/*
			Creat Opportunity Contact
		*/
    	Contact_Opportunity__c co = new Contact_Opportunity__c();
		co.Contact__c = contactId;
   		co.Opportunity__c = oppId;
   		co.OppRole__c = role;
   		co.OppPrimary__c = (role == CONTACT_OPP_ROLE_DECISION_MAKER);
   		return co;
    }

    public static Set<Id> GetOpportunityContactsFromContactRoles(Id oppId) 
    {
    	List<OpportunityContactRole> contactsRolesLst = [Select id, Contact.Name, Contact.Id FROM OpportunityContactRole 
    	Where OpportunityId=:oppId ];

    	Set<Id> contactId = new Set<Id>();
    	for(OpportunityContactRole ocr : contactsRolesLst)
    	{
    		contactId.add(ocr.Contact.Id);
    	}
		return contactId;
    }
  
	public static map<string, set<Id>> GetOpportunityContactRoleMap(Id oppId) {
		/*
			Return Opportunity Contact Role Map
		*/
		list<Contact_Opportunity__c> oppCons = GetOpportunityContacts(oppId);
		map<string, set<Id>> oppConMap = new map<string, set<Id>>();
		for (Contact_Opportunity__c con : oppCons) {
			if(!oppConMap.containsKey(con.OppRole__c)) {
				oppConMap.put(con.OppRole__c, new set<Id>());
			}
			oppConMap.get(con.OppRole__c).add(con.Contact__c);
		}		
		return oppConMap;
	}	
	
	public static map<Id, Contact> GetContactsMap(set<Id> conIds) {
		/* Return map of contacts */
		return new map<Id, Contact>(GetContacts(conIds));
	}
		
	public static list<Contact> GetContacts(set<Id> conIds) {
		/* Return list of contacts */
		list<Contact> contacts = new list<Contact>();
		contacts.addAll([SELECT Id, Name 
    					FROM Contact
    					WHERE Id IN :conIds
    					ORDER BY Name]);
    	return contacts;
	}

	public static list<Contact> GetContactsByRecordType(string recordTypeName) {
		/* Return list of contact by Record Type Name */
		list<Contact> contacts = new list<Contact>();
		contacts.addAll([SELECT Id, Name 
    					FROM Contact
    					WHERE RecordType.DeveloperName = :recordTypeName
    					ORDER BY Name]);
    	return contacts;
			
	}
	
	public static list<Contact_Opportunity__c> GetOpportunityContacts(Id oppId) {
		/* Return list of opportunity contacts */
		list<Contact_Opportunity__c> oppContacts =
			[SELECT Contact__c, Contact__r.Name, OppRole__c, OppPrimary__c 
				FROM Contact_Opportunity__c 
				WHERE Opportunity__c = :oppId];
		return oppContacts;
	}

	public static set<Id> GetQuoteProductContactIds(Id quoteId) {
		/* Return set of quote product contact Ids */
		return GetQuoteProductContactIds(quoteId, true);
	} 
	
	public static set<Id> GetQuoteProductContactIds(Id quoteId, boolean selectedOnly) {
		/* Return set of quote product contact Ids */
		set<Id> qpContactIds = new set<Id>();
		for(Quote_Product__c qp : [SELECT Primary_Contact__c, Invoice_Contact__c, Booking_Contact__c, Credit_Check_Contact__c
									FROM Quote_Product__c
							  		WHERE Quote_Ref__c = :quoteId
							  			AND (Selected__c = true OR Selected__c = :selectedOnly)]) 
		{
			if(qp.Primary_Contact__c != null) { qpContactIds.add(qp.Primary_Contact__c); }
			if(qp.Invoice_Contact__c != null) { qpContactIds.add(qp.Invoice_Contact__c); }
			if(qp.Booking_Contact__c != null) { qpContactIds.add(qp.Booking_Contact__c); }
			if(qp.Credit_Check_Contact__c != null) {qpContactIds.add(qp.Credit_Check_Contact__c); }
		}
		return qpContactIds;
	}

	public static Id GetDefaultContactId(Quote__c quote, Id siteId, Id quoteContactId, string role) {
		/*
			Return default contact
		*/
		map<Id, map<string, Contact>> siteContactMap = bg_ContactUtils.GetSiteContactMap(quote.Account__c);
		if(siteContactMap.containsKey(siteId) && siteContactMap.get(siteId).containsKey(role)) {
			return siteContactMap.get(siteId).get(role).Id;
		} else {
			return quoteContactId;
		}
	}
	
	public static void SaveOpportunityContacts(Quote__c quote) 
	{
		//delete the contact roles if any of the contacts are blank on save to keep them in sync with the main quote

		List<Contact_Opportunity__c> contactOppsToDelete = new List<Contact_Opportunity__c>();

		List<Contact_Opportunity__c> ContactOppsQuery = [Select Id, OppRole__c FROM Contact_Opportunity__c 
														WHERE Opportunity__c =: quote.Opportunity_Name__c];

		//loop round list once and find contact opps to delete
		for(Contact_Opportunity__c copp : ContactOppsQuery)
		{
			if(bg_StringUtils.IsBlank(quote.Contact__c) && copp.OppRole__c==CONTACT_OPP_ROLE_DECISION_MAKER)
			{
				contactOppsToDelete.add(copp);
			}

			if(bg_StringUtils.IsBlank(quote.Invoice_Contact__c) && copp.OppRole__c==CONTACT_OPP_ROLE_INVOICING)
			{
				contactOppsToDelete.add(copp);
			}

			if(bg_StringUtils.IsBlank(quote.Booking__c) && copp.OppRole__c==CONTACT_OPP_ROLE_BOOKING)
			{
				contactOppsToDelete.add(copp);
			}

			if(bg_StringUtils.IsBlank(quote.CreditCheck__c) && copp.OppRole__c==CONTACT_OPP_ROLE_CREDIT_CHECK)
			{
				contactOppsToDelete.add(copp);
			}
		}

		if(!contactOppsToDelete.isEmpty())
		{
			delete contactOppsToDelete;
		}

		/*
			Save Opportunity Contacts
		*/
		map<string, set<Id>> oppConMap = bg_ContactUtils.GetOpportunityContactRoleMap(quote.Opportunity_Name__c);
		list<Contact_Opportunity__c> cos = new List<Contact_Opportunity__c>();
		// DECISION MAKER
		if(!bg_StringUtils.IsBlank(quote.Contact__c) && !CheckOppContactRoleMap(oppConMap, CONTACT_OPP_ROLE_DECISION_MAKER, quote.Contact__c)) {
			cos.add(GetOpportunityContact(quote.Opportunity_Name__c, quote.Contact__c, CONTACT_OPP_ROLE_DECISION_MAKER));
		}
		// INVOICING CONTACT
		if(!bg_StringUtils.IsBlank(quote.Invoice_Contact__c) && !CheckOppContactRoleMap(oppConMap, CONTACT_OPP_ROLE_INVOICING, quote.Invoice_Contact__c)) {
			cos.add(GetOpportunityContact(quote.Opportunity_Name__c, quote.Invoice_Contact__c, CONTACT_OPP_ROLE_INVOICING));
		}
		// BOOKING CONTACT
		if(!bg_StringUtils.IsBlank(quote.Booking__c) && !CheckOppContactRoleMap(oppConMap, CONTACT_OPP_ROLE_BOOKING, quote.Booking__c)) {
			cos.add(GetOpportunityContact(quote.Opportunity_Name__c, quote.Booking__c, CONTACT_OPP_ROLE_BOOKING));
		}
		// CREDIT CHECK CONTACT
		if(!bg_StringUtils.IsBlank(quote.CreditCheck__c) && !CheckOppContactRoleMap(oppConMap, CONTACT_OPP_ROLE_CREDIT_CHECK, quote.CreditCheck__c)) {
			cos.add(GetOpportunityContact(quote.Opportunity_Name__c, quote.CreditCheck__c, CONTACT_OPP_ROLE_CREDIT_CHECK));
		}
		// Insert Opportunity Contacts
		insert cos;
	}
	
	private static boolean CheckOppContactRoleMap(map<string, set<Id>> oppConMap, string role, string contactId) {
		/* Check if Opp Contact Role Map contains role / contact */
		return oppConMap.containsKey(role) && oppConMap.get(role).contains(contactId);
	}
	
	public static list<string> GetContactEmailList(list<Contact> contacts) {
		/*
			Return list of Contact Email Addresses
		*/
		list<string> emailList = new list<string>();
		for(Contact con : contacts) {
			if(!bg_StringUtils.IsBlank(con.Email)) {
				emailList.add(con.Email);
			}
		}
		return emailList;
	}
	
	public static list<Contact> GetOtherAccountContacts(list<Id> contactIds) {
		/*
			Method to return list of contacts associated to the same account as the 
			contact list passed in
		*/
		set<Id> accountIds = new set<Id>();
		for(Contact contact : [SELECT AccountId FROM Contact WHERE Id IN :contactIds]) {
			accountIds.add(contact.AccountId);
		}

		list<Contact> contacts = new list<Contact>();
		contacts.addAll([SELECT Id, Email
						FROM Contact
						WHERE AccountId IN :accountIds
							AND Id NOT IN :contactIds]);
		return contacts;
	}
}