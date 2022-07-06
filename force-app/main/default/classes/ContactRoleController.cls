/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         08/12/2011
* Description:  Visualforce Controller used to smooth the process of adding a new
*				contact role (custom entity) on the opportunity. 
*				NOT NEEDED ANYMORE
*       
**/
public with sharing class ContactRoleController {
	/*
	public List<Contact_Opportunity__c> 	existingRoles 	{get; set;}
	public List<SiteGroup>			 		siteGroups		{get; set;}
	
	public Map<String,Boolean>				mapPrimary		{get; set;}
	
	public Opportunity						mainOpty		{get; set;}
	
	public Set<Id>							existingIds		{get; set;}
	
	public Boolean  noExisting			{get; set;}
	public Boolean	noSites				{get; set;}

	public String	primaryName			{get; set;}
	public String	primaryId			{get; set;}
	public String	oppId;
	
	public ContactRoleController() {
		// Initializing...
		oppId = Apexpages.currentPage().getParameters().get('oppid');
		siteGroups = new List<SiteGroup>();
		existingRoles = new List<Contact_Opportunity__c>();
		existingIds = new Set<Id>();
		primaryName = 'None selected';
		primaryId = null;
		
		// Get the current primary contact
		mainOpty = [SELECT PrimaryContact__c, PrimaryContact__r.Name, OwnerId FROM Opportunity WHERE Id =:oppId];
		if (mainOpty.PrimaryContact__c != null) {
			primaryName = mainOpty.PrimaryContact__r.Name;
			primaryId = mainOpty.PrimaryContact__c;
		}
		
		// Get all current contact roles
		existingRoles = [SELECT Contact__c, Contact__r.Name, OppRole__c, OppPrimary__c FROM Contact_Opportunity__c WHERE Opportunity__c =:oppId order by Contact__r.Name];
		noExisting = existingRoles.isEmpty();
		for (Contact_Opportunity__c curr : existingRoles) {
			existingIds.add(curr.Contact__c);
		}
		
		// Get All sites related to the opportunity
		List<OpportunitySite__c> optysites = [SELECT Site__c FROM OpportunitySite__c WHERE Opportunity__c =:oppId AND Site__r.RecordType.DeveloperName =:Utility.RTNAME_NAMED];
		Set<Id> sIds = new Set<Id>();
		for (OpportunitySite__c os : optysites) {
			sIds.add(os.Site__c);
		}
		
		// Get Contact grouped by Site
		List<Site__c> sites = [SELECT Name, Street__c, City__c, Postcode__c, (SELECT Contact__c, Contact__r.Name FROM Contact_Sites__r) FROM Site__c WHERE Id IN :sIds];
		noSites = sites.isEmpty();
		for (Site__c s : sites) {
			List<ContactRole> crtemp = new List<ContactRole>();
			for (ContactSite__c cs : s.Contact_Sites__r) {
				ContactRole cr = new ContactRole(cs);
				crtemp.add(cr);
			}
			//if (!crtemp.isEmpty()) {
				SiteGroup sgtemp = new SiteGroup(s,crtemp);
				siteGroups.add(sgtemp);
			//}
		}
		
		//List<ContactSite__c> consites = [SELECT Contact__c, Contact__r.Name, Site__c, Site__r.Name, Site__r.City__c, Site__r.Street__c, Site__r.Postcode__c 
		//							FROM ContactSite__c WHERE Site__c IN :sIds order by Site__r.Name];
		// Display radio button or create button at row level in the list
		// to set the contact as primary-main - SelectOption and display ad radio
		// should work fine

	}
	
	// BACKTO OPPORTUNITY DETAIL
	public Pagereference back() {
		Pagereference pageO = new Pagereference('/' + oppId);
		return pageO;
	}
	
	// SAVE ALL CONTACT ROLE WITH A ROLE SELECTED AND SET PRIMARY ON OPPORTUNITY
	public Pagereference saveAll() {
		Pagereference pageO = null;
		Savepoint sp = Database.setSavepoint();
		// Save Opportunity Contact Roles
		List<Contact_Opportunity__c> coptys = new List<Contact_Opportunity__c>(); 
		//List<OpportunityContactRole> standardRoles = new List<OpportunityContactRole>(); 
		Set<String> selectedRoles = new Set<String>();
		for (SiteGroup sg : siteGroups) {
			for (ContactRole cr : sg.croles) {
				if (cr.role != null && cr.role != '') {
					Contact_Opportunity__c co = new Contact_Opportunity__c();
					co.Contact__c = cr.contact.Contact__c;
					co.Opportunity__c = oppId;
					co.OppRole__c = cr.role;
					co.OwnerId = mainopty.OwnerId;
					if (primaryId != '' && primaryId != null && cr.contact.Contact__c == primaryId) co.OppPrimary__c = true;
					coptys.add(co);
					selectedRoles.add(cr.contact.Contact__c);
				}
			}
		}
		// If the primary has not changed skip this section
		if (primaryId != String.valueOf(mainOpty.PrimaryContact__c)) {
		
			// Check if there is a primary
			if (primaryId != null && primaryId != '') {
				// Throw an error if there is a primary without a role selected
				if (!selectedRoles.contains(primaryId) && !existingIds.contains(primaryId)) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'You must select a role for the Primary Contact'));
	            	return null;
				}
				mainOpty.PrimaryContact__c = primaryId;
			// If the primaryId is 'null' this means that the primary contact must be blanked			
			} else {
				mainOpty.PrimaryContact__c = null;
			} 	
			try {
				if (!existingRoles.isEmpty()) {
					for (Contact_Opportunity__c curr : existingRoles) {
						if (String.valueOf(curr.Contact__c) == primaryId) curr.OppPrimary__c = true;
							else curr.OppPrimary__c = false;
					}
					//update existingRoles;
				}
				update mainOpty;
			} catch (DmlException dml) {
				Database.rollback(sp);
				Apexpages.addMessages(dml);
				pageO = null;
			}	
		
		}
	
		// Insert new contact Roles
		try {
			update existingRoles;
			insert coptys;
			pageO = new Pagereference('/' + oppId);
		} catch (DmlException dml) {
			Database.rollback(sp);
            ApexPages.addMessages(dml);
            pageO = null;
		}
		
		return pageO;
	}
	
	// ROLE SELECTION
    public List<SelectOption> getRoles() {
      	List<SelectOption> options = new List<SelectOption>();
        List<String> roles = new List<String>();
        
        Schema.DescribeFieldResult fieldResult = Contact_Opportunity__c.OppRole__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        options.add(new SelectOption('','-- Do not save --'));
        for(Schema.PicklistEntry pg : ple) {
        	options.add(new SelectOption(pg.getValue(),pg.getValue()));    
        }

        return options;
    } 
	
	// CLASS TO MANAGE GROUPING BY SITE - (if needed)
	public class SiteGroup {
		public Boolean				empty	{get; set;}
		public Site__c				site  	{get; set;}
		public List<ContactRole> 	croles	{get; set;}
		
		public SiteGroup(Site__c s, List<ContactRole> crs) {
			this.site 	= s;
			this.croles = crs;
			this.empty = croles.isEmpty();
		}	
	}
	
	// CLASS TO MANAGE CONTACT ROLES SELECTION
	public class ContactRole {
		public String				role		{get; set;}
		public ContactSite__c 		contact		{get; set;}
		
		public ContactRole(ContactSite__c c) {
			this.contact = c;
			this.role = '';
		}
	}
	
	*/
}