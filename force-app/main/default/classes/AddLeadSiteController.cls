/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         15/11/2011
* Description:  Visualforce Controller used to smooth the process of adding a new
*				lead site within the standard detail page. 
*
*       
**/
public with sharing class AddLeadSiteController {

	public string notEntered = '-';
	
	public Integer	globalIndex;
	
	public Lead 	mainLead				{get; set;}
	public String	toRemove				{get; set;}
	public String	toEdit					{get; set;}
	public Site__c	site					{get; set;}
	public List<SiteList> newSites			{get; set;}
	
	public String 	pageURL 				{set;}
	public Boolean 	reloadNeeded 			{get; set;}
	public Boolean	isEdit					{get; set;}
	
	public String errorMessage				{get; set;}
	public Boolean showError				{get; set;}
	public Boolean isDisabled				{get; set;}
	
	// CONSTRUCTOR
	public AddLeadSiteController(ApexPages.StandardController std) {
		// Initializing
		mainLead 		= [SELECT Id, OtherAddresses__c, TCodeDescr__c, Industry, Country, 
							Street, City, PostalCode, State, Company, Existing_Customer_Account__c 
							FROM Lead WHERE Id =:std.getId()];	 
		globalIndex 	= 0;
		reloadNeeded 	= false;
		site 			= new Site__c();
		newSites 		= new List<SiteList>();
		isEdit			= false;
		showError      	= false;
		// Default value
		siteDefault();
		
		// Query existing sites	
		List<Site__c> sites = [SELECT Id, Name, SkipDupeChecker__c, Type__c, Street__c, State__c, 
								Country__c, Country_Code__c, City__c, Postcode__c, NumberEmployees__c, 
								Industry__c, TCodeDescr__c, Account__c
								FROM Site__c 
								WHERE Lead__c =:std.getId()];
		
		if(!bg_StringUtils.IsBlank(mainLead.Existing_Customer_Account__c)) {
			sites.addAll([SELECT Id, Name, SkipDupeChecker__c, Type__c, Street__c, State__c, 
									Country__c, Country_Code__c, City__c, Postcode__c, NumberEmployees__c, 
									Industry__c, TCodeDescr__c, Account__c
									FROM Site__c 
									WHERE Account__c = :mainLead.Existing_Customer_Account__c]);
		}

		for (Site__c curr :sites) {
			newSites.add(new SiteList(curr,String.valueOf(globalIndex)));
			globalIndex ++;
		}
		
		// Make site section less visible if no address on the lead
		isDisabled = (mainLead.Street == null && mainLead.PostalCode == null && mainLead.City == null && mainLead.State == null)? true : false;
		
		/*if (sites.size() > 0) {
			mainLead.OtherAddresses__c = true;
		} else {
			mainLead.OtherAddresses__c = false;
		}*/
	}
	
	// DEFAUL SITE VALUES
	private void siteDefault() {
		site.Name 			= mainLead.Company;
		site.TCodeDescr__c 	= mainLead.TCodeDescr__c;
		site.Industry__c 	= mainLead.Industry;
		site.Country__c 	= mainLead.Country;
		site.Country_Code__c = mainLead.Country;
		SetStreet(site);
	}
	
	
	
	// ADD A NEW SITE TO THE LEAD
	public void addSite() {
		// Validation: Postcode or Street required
		if (site.Postcode__c != null || site.Street__c != null) { 
			Site__c temp = site.clone(false,true);
			temp.Lead__c = mainLead.Id;
			//temp.SkipDupeChecker__c=true;//added via lead no easy way to do and need t add logic to match agianst account
			if (!newSites.isEmpty()) {
				newSites.add(0,new SiteList(temp,String.valueOf(globalIndex)));
			} else {
				newSites.add(new SiteList(temp,String.valueOf(globalIndex)));
			}
			globalindex ++;
			
			site = new Site__c();
			// Default value
			siteDefault();
			showError = false;
		} else {
			// Display an error
			errorMessage = Label.AddressValidationPostcodeStreet;
			showError = true;
		}
	}
	
	// EDIT A SITE
	public void editSite() {
		showError = false;
		isEdit = true;
		for (SiteList curr :newSites) {
			if (curr.index == toEdit) {
				site = curr.site;
				SetStreet(site);
				break;
			}
		}
	}
	
	private void SetStreet(Site__c site) {
		if(bg_stringUtils.IsBlank(site.Street__c)) {
			site.Street__c = notEntered;
		}		
	}	

	// COMPLETE EDIT
	public void editComplete() {
		site = new Site__c();
		isEdit = false;
		// Default value
		siteDefault();
	}
	
	// SAVE ALL SITES
	public void saveAll() {
		List<Site__c> toUpsert = new List<Site__c>();
		try {
			for (SiteList curr:newSites) {
				if(curr.site.street__c == notEntered) {
					curr.site.street__c = '';
				}

				//if (String.valueOf(curr.site.Id) == null || String.valueOf(curr.site.Id) == '')
					toUpsert.add(curr.site);
			}
			Utility.isVisualforce = true;
			upsert toUpsert;
			/*// Update Lead field if there are no more sites
			if (newSites.isEmpty()) {
				mainLead.OtherAddresses__c = false;
			}
			update mainLead;*/
			reloadNeeded = true;
		} catch (DmlException dml) {
			Apexpages.addMessages(dml);
		}
	}
	
	// REMOVE FROM LIST (DELETE IF ALREADY INSERTED)
	public void removeSite() {
		Boolean existing = false;
		Integer i = 0;
		for (SiteList curr:newSites) {
			if (curr.index == toRemove) {
				if (String.valueOf(curr.site.Id) != null && String.valueOf(curr.site.Id) != '') 
					existing = true;
				break;
			}
			i ++;
		}
		// Remove from list (delete if existing record)
		if (existing) {
			delete newSites.get(i).site;
			newSites.remove(i);
		} else {
			newSites.remove(i);
		}
	}
	
	// RELOAD THE FULL PAGE TO DISPLAY UPDATED RECORD
	public String getPageURL() {
		ApexPages.StandardController sc = new ApexPages.StandardController(mainLead);	
		PageReference pageRef = sc.view();
		return pageRef.getUrl();	
	}
	
	// CUSTOM INNER CLASS: MANAGE INDEX FOR REMOVING FROM LIST
	public class SiteList {
		
		public String 	index 	{get; set;}
		public Site__c	site	{get; set;}
		
		public SiteList(Site__c s, String i) {
			this.index 	= i;
			this.site 	= s;
		}
	}
}