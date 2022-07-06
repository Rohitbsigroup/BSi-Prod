/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         18/11/2011
* Description:  Visualforce Controller used to smooth the process of adding a new
*				opportunity site or link existing site from the related account.
*				It will also add a Contact Role for each different Primary Contat
*				specified on Opportunity Site (junction object). 
*
*       
**/
public without sharing class AddOptySiteController {
	
	public List<OpportunitySite__c> 	optySites 		{get; set;}
	public List<Contact_Opportunity__c> existingRoles 	{get; set;}
	public List<Contact_Opportunity__c> externalRoles 	{get; set;}
	public List<SiteList> 				optySitesNew 	{get; set;}
	public List<Site__c>				siteToLink		{get; set;}
	
	public Boolean			allCheck	{get; set;}
	public Boolean			showList	{get; set;}	
	public Boolean			noAccSite	{get; set;}
	public Boolean			noOptySite	{get; set;}
	public Boolean			goToQuote	{get; set;}
	public Boolean  		noExisting	{get; set;}
	
	public Set<Id>			existingIds	{get; set;}
	
	public List<SiteList>	accSites 	{get; set;}
	public Opportunity		mainOpty	{get; set;}
	public Account			mainAcc;		
	
	public Site__c			newSite		{get; set;}
	public String			newScope	{get; set;}
	public String			toRemove	{get; set;}
	public Integer			globalIndex {get; set;}
	
	public SiteSetting__c	setting		{get; set;}
	
	public String			siteType	{get; set;}
	public Map<String,Id> 	rtypeMap	{get; set;}
	
	public String 	errorMessage		{get; set;}
	public Boolean 	showError			{get; set;}
	
	public Boolean	showNewSection		{get; set;}
	
	public List<Contact>	contacts;
	
	public AddOptySiteController() {
		// Initializing...
		String oppId = ApexPages.currentPage().getParameters().get('oppid');
		mainOpty 	 = [SELECT Id, Name, AccountId, Account.Name, ScopeofRegistration__c, PrimaryContact__c, PrimaryContact__r.Name FROM Opportunity WHERE Id =:oppId];//(Opportunity)std.getRecord();
		accSites 	 = new List<SiteList>();
		siteToLink	 = new List<Site__c>();
		existingRoles= new List<Contact_Opportunity__c>();
		externalRoles= new List<Contact_Opportunity__c>();
		existingIds	 = new Set<Id>();
		newSite		 = new Site__c();
		rtypeMap	 = Utility.getRecordTypes('Site__c');
		newScope     = mainOpty.ScopeofRegistration__c;
		allCheck 	 = false;
		showList	 = false;
		optySitesNew = new List<SiteList>();
		setting		 = SiteSetting__c.getInstance();
		globalIndex  = 0;
		siteType	 = Utility.RTNAME_NAMED;
		showError	 = false;
		showNewSection = false;
		
		String primaryHQ = null;
		
		// Get all current contact roles
		existingRoles = [SELECT Contact__c, Contact__r.Name, OppRole__c, OppPrimary__c FROM Contact_Opportunity__c WHERE Opportunity__c =:oppId order by Contact__r.Name];
		noExisting = existingRoles.isEmpty();
		for (Contact_Opportunity__c curr : existingRoles) {
			existingIds.add(curr.Contact__c);
		}
		addExtContactRole(); // Add one empty line for external contact roles
		
		// List of all Account Contatcs
		contacts = [SELECT Name FROM Contact WHERE AccountId =:mainOpty.AccountId];
		
		// List of already linked site
		optySites = [SELECT Id, Site__c, Site__r.Name, Site__r.City__c, Site__r.Street__c, Site__r.Postcode__c, HQ__c,
					Site__r.Country__c, Site__r.RecordType.DeveloperName, Site__r.Type__c, Site__r.TypeIcon__c, 
					Site__r.State__c, ProposedScope__c, SitePrimaryContact__c, Site__r.NumberEmployees__c  
					FROM OpportunitySite__c WHERE Opportunity__c =:mainOpty.Id order by Site__r.TypeIcon__c desc];
		List<Id> linkedID = new List<Id>();
		for (OpportunitySite__c curr :optySites) {
			linkedID.add(curr.Site__c);
			if (curr.Site__r.Type__c == setting.HQLabel__c)
				primaryHQ = curr.SitePrimaryContact__c;
		}
		noOptySite = optySites.isEmpty();
		
		// List of related account site not linked to this opty
		List<Site__c> temp = [SELECT Id, Name, City__c, Street__c, State__c, Country__c, Postcode__c, Type__c, TypeIcon__c, 
							  RecordType.DeveloperName, PrimaryContact__c, TCodeDescr__c, Industry__c, NumberEmployees__c
							  FROM Site__c 
							  WHERE Account__c =:mainOpty.AccountId AND Id NOT IN :linkedID];
		// Seletc HQ Primary Contact if available - default all sites to this value		
		for (Site__c curr :temp) {
			if (curr.Type__c == setting.HQLabel__c) {
				primaryHQ = curr.PrimaryContact__c;
				break;
			}			
		}					  
		for (Site__c curr :temp) {
			SiteList sl = new SiteList(curr,false,false);
			sl.index    = String.valueOf(globalIndex);
			sl.scope	= mainOpty.ScopeofRegistration__c;
			sl.rtype	= curr.RecordType.DeveloperName;
			if (sl.site.PrimaryContact__c == null) sl.site.PrimaryContact__c = primaryHQ;
			if (curr.Type__c == setting.HQLabel__c) sl.quoteHQ = true;
			globalIndex ++;
			accSites.add(sl);
		}
		noAccSite = accSites.isEmpty();
		
		// Deafault value
		List<Account> optyAcc = [SELECT Name, TCodeDescr__c, Industry, BillingCountry FROM Account WHERE Id =:mainOpty.AccountId];
		if (!optyAcc.isEmpty()) {
			mainAcc = optyAcc.get(0);
			siteDefault();
		} else {
			mainAcc = new Account();
		}
	}
	
	// DEFAUL SITE VALUES
	public void siteDefault() {
		
		if (siteType == Utility.RTNAME_NAMED) {
			newSite = new Site__c();
			newSite.Name 			= mainAcc.Name;
			newSite.TCodeDescr__c 	= mainAcc.TCodeDescr__c;
			newSite.Industry__c 	= mainAcc.Industry;
			newSite.Country__c 		= mainAcc.BillingCountry;
			newSite.Type__c			= 'Ship To Address';	
			newSite.PrimaryContact__c = mainOpty.PrimaryContact__c;
		} else {
			newSite = new Site__c();
			newSite.Name = mainAcc.Name;
		}
	}
	
	// ADD NEW SITE
	public void addNew() {
		if (showNewSection) {	
		if (newSite.Name != null && newSite.Name != '' && (newSite.Postcode__c != null || newSite.Street__c != null || siteType != Utility.RTNAME_NAMED)) {
			// Add the new site to the list
			Site__c s = newSite.clone(false,true);
			s.Account__c = mainOpty.AccountId;
			s.RecordTypeId = rtypeMap.get(siteType);
			s.PrimaryContact__c = newSite.PrimaryContact__c;
			SiteList temp = new SiteList(s,true,true);
			temp.scope = mainOpty.ScopeofRegistration__c;
			temp.rtype = siteType;
			temp.index = String.valueOf(globalIndex);
			globalIndex ++;
			optySitesNew.add(temp);
			// Reset values
			siteDefault();
			// Contact Role
			//addContactRole(temp.site.PrimaryContact__c);
			if (!existingRoles.isEmpty()) noExisting = false;
			// Show list table
			showList = true;
			showError = false;
			showNewSection = false;
		} else if (newSite.Name == null || newSite.Name == '') { 
			errorMessage = Label.NameValidationSite;
			showError = true;
		} else {
			errorMessage = Label.AddressValidationPostcodeStreet;
			showError = true;
		}
		} else {
			showNewSection = true;
		}	
	}
	
	// ADD NEW CONTACT ROLE
	public void addContactRole(String contactId) {
		if (contactId != null && contactId != '' && !existingIds.contains(contactId)) {
			Contact_Opportunity__c co = new Contact_Opportunity__c();
			co.Contact__c 		= contactId;
			co.Opportunity__c 	= mainOpty.Id;
			existingRoles.add(co);
			existingIds.add(contactId);
		}
	}
	
	// ADD EXTERNAL CONTACT ROLE
	public void addExtContactRole() {
		Contact_Opportunity__c co = new Contact_Opportunity__c();
		co.Opportunity__c	= mainOpty.Id;
		externalRoles.add(co);
	}
	
	// LINK EXISTING SITE
	public void linkToOpty() {
		showError = false;
		for (SiteList curr:accSites) {
			if (curr.selected && curr.show) {
				if (curr.site.TCodeDescr__c != null) {
					optySitesNew.add(curr);
					//addContactRole(curr.site.PrimaryContact__c);
					if (!existingRoles.isEmpty()) noExisting = false;
					if (mainOpty.PrimaryContact__c == null && curr.quoteHQ) mainOpty.PrimaryContact__c = curr.site.PrimaryContact__c; 
					curr.show = false;
				} else {
					showError = true;
					errorMessage = Label.ManageSiteTCodeError;
				}
			}
		}
		
		showList = !optySitesNew.isEmpty();
	}
	
	// REMOVE FROM LINKED SITE (ONLY NOT SAVED)
	public void removeLink() {
		showError = false;
		Boolean existing = false;
		Integer i = 0;
		for (SiteList curr:optySitesNew) {
			if (curr.index == toRemove) {
				break;
			}
			i ++;
		}
		
		// Remove from list
		optySitesNew.remove(i);
		
		// Show as available the related record in accList
		for (SiteList curr:accSites) {
			if (curr.index == toRemove && !curr.show) {
				curr.show = true;
			}
		}
		
		showList = !optySitesNew.isEmpty();
	}
	
	// REMOVE FROM EXISTING
	public void removeOptySite() {
		Integer i = 0;
		for(OpportunitySite__c curr : optySites) {
			if (curr.Id == toRemove)
				break;
			i ++;
		}
		
		delete optySites.get(i);
		optySites.remove(i);
	}
	
	// PRIMARY CONTACT SELECTION - NEW SITE (Choose from Account Contacts)
	public List<SelectOption> getAccContacts() {
		List<SelectOption> optionList = new List<SelectOption>();
	    optionList.add(new SelectOption('','--None--'));
	    for (Contact c : contacts){
	    	optionList.add(new SelectOption(c.Id,c.Name));
	    }
	    return optionList;
	}
	// CONTACT ROLE SELECTION - NEW SITE
	public List<SelectOption> getRoles() {
		List<SelectOption> optionList = new List<SelectOption>();
		Schema.DescribeFieldResult fieldResult = Contact_Opportunity__c.OppRole__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
	    for (Schema.PicklistEntry p : ple){
	    	optionList.add(new SelectOption(p.getValue(),p.getValue()));
	    }
	    return optionList;
	}
	
	// SAVE AND LINK SELECTED SITES
	public Pagereference saveAll() {
		Pagereference pageO;
		
		List<Site__c> sToInsert = new List<Site__c>();
		List<OpportunitySite__c> osToInsert = new List<OpportunitySite__c>();
		List<Contact_Opportunity__c> rolesToInsert = new List<Contact_Opportunity__c>();
		
		Integer hqcount = 0;
		for (OpportunitySite__c curr:optySites) {
			if (curr.HQ__c) hqcount ++;
		}
		for (SiteList curr:optySitesNew) {
			if (curr.quoteHQ) hqcount ++;
		}
		Integer blankroles = 0;
		for (Contact_Opportunity__c curr : externalRoles) {
			if (curr.Contact__c != null && curr.OppRole__c == null)
				blankroles ++;
		}
		for (Contact_Opportunity__c curr : existingRoles) {
			if (curr.Contact__c != null && curr.OppRole__c == null)
				blankroles ++;
		}
		
		if (hqcount == 1 && blankroles == 0) {
		
		try {
			/*// Adding Primary Contact as a Contact Role and flag as primary
			if (mainOpty.PrimaryContact__c != null) {
				addContactRole(mainOpty.PrimaryContact__c);
				for (Contact_Opportunity__c curr : existingRoles) {
					if (curr.Contact__c == mainOpty.PrimaryContact__c)
						curr.OppPrimary__c = true;
				}
			}*/
			
			// Update existing Sites
			update optySites;
			// Update account Sites
			List<Site__c> accs = new List<Site__c>();
			for (SiteList curr:accSites) {
				accs.add(curr.site);
			}
			update accs;

			// First: insert new site to get Id
			for (SiteList curr :optySitesNew) {
				if (curr.isNew) {
					sToInsert.add(curr.site);
				}
			}
		
			Utility.isVisualforce = true;
			insert sToInsert;
			// Second: insert junction object and contact roles
			for (SiteList curr :optySitesNew) {
				OpportunitySite__c temp = new OpportunitySite__c();
				temp.Opportunity__c 	= mainOpty.Id;
				temp.Site__c			= curr.site.Id;
				temp.ProposedScope__c	= curr.scope;
				temp.HQ__c				= curr.quoteHQ;
				temp.SitePrimaryContact__c = curr.site.PrimaryContact__c;
				osToInsert.add(temp);
			}
			insert osToInsert;
			
			/*// Manage Contact Roles based on selection
			for (Contact_Opportunity__c curr : externalRoles) {
				if (curr.Contact__c != null && !existingIds.contains(curr.Contact__c)) rolesToInsert.add(curr);  
			}
			rolesToInsert.addAll(existingRoles);
			upsert rolesToInsert;*/
			update mainOpty; // just to update Primary Contact for Opportunity
			pageO = new Pagereference('/' + mainOpty.Id);
			
		} catch (DmlException dml) {
			Apexpages.addMessages(dml);
			pageO = null;
		}
		
		} else if (hqcount != 1) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,Label.ManageSiteHQError));
			pageO = null;
		} else if (blankroles != 0) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'You must select a role for all Contacts.'));
			pageO = null;
		}

		return pageO;
	}
	
	// SAVE ALL AND GO TO QUOTE PAGE
	public Pagereference saveAndQuote(){
		Pagereference retPage = saveAll();
		if (retPage != null) {
			retPage = new Pagereference('/apex/newQuote?accid=' + mainOpty.AccountId + '&oppid=' + mainOpty.Id);
		}		
		return retPage;
	}
	
	// BACK TO OPTY DETAIL
	public Pagereference back() {
		Pagereference pageO = new Pagereference('/' + mainOpty.Id);
		return pageO;
	}
	
	// MASSIVE FLAG SELECT-DESELECT
	public void selectAll()
	{
		for (SiteList curr :accSites) {
			if (curr.show) curr.selected = true;
		}
		allCheck = true;
	}
	
	public void deselectAll()
	{
		for (SiteList curr :accSites) {
			if (curr.show) curr.selected = false;
		}
		allCheck = false;
	}
	
	// CUSTOM CLASS TO MANAGE SITE SELECTION
	public class SiteList {
		public Boolean 	selected 	{get; set;}
		public Boolean  show		{get; set;}
		public Boolean	isNew		{get; set;}
		public Boolean	quoteHQ		{get; set;}
		public Site__c	site		{get; set;}
		public String	scope		{get; set;}
		public String	added		{get; set;}
		public String	index		{get; set;}
		public String	rtype		{get; set;}
				
		public String	role		{get; set;}
		//public String 	primaryC 	{get; set;}
		
		public SiteList(Site__c s, Boolean b, Boolean n) {
			this.selected 	= b;
			this.site		= s;
			this.isNew		= n;
			this.show		= true;
			this.quoteHQ	= false;
		}
	}
}