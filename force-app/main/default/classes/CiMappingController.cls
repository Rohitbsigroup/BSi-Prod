public with sharing class CiMappingController
{
	// Passed values for nearby-based
	public Id passedId { get; set; }
	public String retURL { get; set; }
	public String passedName { get; set; }
	public Decimal passedLat { get; set; }
	public Decimal passedLng { get; set; }
	
	// Passed values for set-based
	public List<sObject> passedIds { get; set; }
	public String passedType { get; set; }
	public List<sObject> siteIds { get; set; }

	// User options
	public Integer distance { get; set; }
	public Boolean showSites { get; set; }
	public Boolean showAssessors { get; set; }
	public Boolean showVisits { get; set; }
	public Boolean showEvents { get; set; }
	public CI_Visit__c dateStore { get; set; }
	public String categoryName { get; set; }
	public Category selectedCategory { get; set; }
	
	// Returned results (some transient to reduce viewstate)
	public Configuration config { get; set; }
	public transient Boolean isValid { get; set; }
	public transient Boolean hasRecords { get; set; }
	private transient List<Id> filteredSiteIds { get; set; }
	public transient List<SiteWrapper> sitesList { get; set; }
	public transient List<AssessorWrapper> assessorsList { get; set; }
	public transient List<VisitWrapper> visitsList { get; set; }
	public transient List<EventWrapper> eventsList { get; set; }
	public transient List<ColourWrapper> coloursList { get; set; }

	// Track map status
	private Integer oldDistance { get; set; }
	public Integer mapZoom { get; set; }
	public Double mapLat { get; set; }
	public Double mapLng { get; set; }

	// Constructor for nearby-based
	public CiMappingController()
	{
		// Set defaults
		this.isValid = true;
		this.hasRecords = false;
		this.showSites = true;
		this.showAssessors = false;
		this.showVisits = false;
		this.showEvents = false;
		this.distance = 5;
		this.oldDistance = this.distance;
		this.dateStore = new CI_Visit__c();
		this.dateStore.Start_Date__c = Date.today();
		this.dateStore.End_Date__c = Date.today().addMonths(1);
		this.categoryName = '';
		this.config = new Configuration();

		// Get URL to return to after cancel
		this.retURL = Apexpages.currentPage().getParameters().get('retUrl');

		// Get passed id
		this.passedId = Apexpages.currentPage().getParameters().get('Id');
		if (this.passedId == null)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No record found! Please click Cancel to go back.'));
			this.isValid = false;
			return;
		}

		// Determine passed type
		if (this.passedId.getSObjectType() == CI_Account__c.sObjectType)
		{
			this.passedType = 'account';
    		CI_Account__c a = [
    			SELECT	a.Name 
    			FROM	CI_Account__c a 
    			WHERE	a.Id = :this.passedId
			];
			this.passedName = a.Name;
		}
		else if (this.passedId.getSObjectType() == CI_Site__c.sObjectType)
		{
			this.passedType = 'site';
    		CI_Site__c s = [
    			SELECT	s.Location__Latitude__s, s.Location__Longitude__s 
    			FROM	CI_Site__c s 
    			WHERE	s.Id = :this.passedId
			];
			this.passedLat = s.Location__Latitude__s;
			this.passedLng = s.Location__Longitude__s;
		}
		else if (this.passedId.getSObjectType() == CI_Contact__c.sObjectType)
		{
			this.passedType = 'contact';
    		CI_Contact__c c = [
    			SELECT	c.CI_Site__r.Location__Latitude__s, c.CI_Site__r.Location__Longitude__s 
    			FROM	CI_Contact__c c 
    			WHERE	c.Id = :this.passedId
			];
			this.passedLat = c.CI_Site__r.Location__Latitude__s;
			this.passedLng = c.CI_Site__r.Location__Longitude__s;
		}

		// Check we have a latitude and longitude		
		if (this.passedType != 'account' && (this.passedLat == null || this.passedLng == null))
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'The selected record cannot be mapped! Please click Cancel to go back.'));
			this.isValid = false;
			return;
		}
	}
	
	// Constructor for set-based
	public CiMappingController(ApexPages.StandardSetController std)
	{
		// Set defaults
		this.isValid = true;
		this.hasRecords = false;
		this.showSites = true;
		this.showAssessors = false;
		this.showVisits = false;
		this.showEvents = false;
		this.dateStore = new CI_Visit__c();
		this.dateStore.Start_Date__c = Date.today();
		this.dateStore.End_Date__c = Date.today().addMonths(1);
		this.categoryName = '';
		this.config = new Configuration();
		std.setPageSize(2000);

		// Get passed set of Ids
		this.passedIds = new List<sObject>();
		if (std.getSelected().size() > 0)
		{
			// Get selected records only
			this.passedIds.addAll(std.getSelected());
		}
		else
		{
			// Get all records from source view
			this.passedIds.addAll(std.getRecords());
			while (std.getHasNext() && this.passedIds.size() < 6000)
			{
				// Handle multiple pages
				std.next();
				this.passedIds.addAll(std.getRecords());
			}
		}
		
		// Send error if no records have been selected
		if (this.passedIds.isEmpty())
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No records specified! Please click Cancel and make a selection.'));
			this.isValid = false;
			return;
		}

		// Determine passed type
		if (this.passedIds[0].getSObjectType() == CI_Site__c.sObjectType)
		{
			this.passedType = 'site';
			this.siteIds = this.passedIds;
		}
		else if (this.passedIds[0].getSObjectType() == CI_Contact__c.sObjectType)
		{
			this.passedType = 'contact';
			this.siteIds = new List<sObject>();
			for (CI_Contact__c t : [
				SELECT	t.CI_Site__r.Id
				FROM	CI_Contact__c t
				WHERE	t.Id IN :this.passedIds
			]) this.siteIds.add(new CI_Site__c(Id = t.CI_Site__r.Id));
		}
		
		// Display warning if 6000 limit applies
		if (std.getResultSize() > 6000 && std.getSelected().size() == 0)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Too many records specified!  Only the first 6,000 will be available.'));
			return;
		}
	}

	// Cancel back to calling page
	public PageReference customCancel()
	{
		PageReference pr = new PageReference(this.retURL);
		return pr;
	}

	// Retrieve account-based records
	public PageReference AccountBased()
	{
		// Initialize returned values
		Initialize();
		
		// Validate parameters
		if (this.showVisits && (this.dateStore.Start_Date__c == null || this.dateStore.End_Date__c == null || this.dateStore.Start_Date__c > this.dateStore.End_Date__c))
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must specify a valid date range for visits.'));
			this.hasRecords = false;
			return null;
		}

		// Always apply the site filters
		for (CI_Site__c site : [
			SELECT	s.Id, 
					s.Name, 
					s.Size_Employees__c, 
					s.Needs_Segment__c, 
					s.Territory__c, 
					s.Spend_Band__c, 
					s.Sector__c, 
					s.Current_Holdings__c, 
					s.Product_Count__c, 
					s.Live_Customer_Type__c, 
					s.CI_Site_Type__c, 
					s.Key_Account__c, 
					s.Site_Role__c, 
					s.Portfolios__c, 
					s.Substreams__c, 
					s.Location__Latitude__s, 
					s.Location__Longitude__s
   			FROM	CI_Site__c s 
   			WHERE	s.CI_Account__c = :this.passedId 
   					AND s.Location__Latitude__s <> null]) 
    	{
    		SiteWrapper sw = new SiteWrapper(site, this.config, this.selectedCategory);
    		if (sw.site != null)
			{
				// Add the site to the list to display and to use in subsequent queries
				if (this.showSites) this.sitesList.add(sw);
				this.filteredSiteIds.add(site.Id);
			}
	   	}

		// Get all the selected visits
        if (this.showVisits)
        {
			for (CI_Visit__c visit : [
				SELECT	v.Id, 
						v.Name, 
						v.Start_Date__c, 
						v.End_Date__c, 
						v.Assessors__c, 
						v.SMO_Number__c, 
						v.CI_Certificate_Site__r.CI_Site__r.Name, 
						v.CI_Certificate_Site__r.CI_Site__r.Current_Holdings__c, 
						v.CI_Certificate_Site__r.CI_Site__r.Size_Employees__c, 
						v.CI_Certificate_Site__r.CI_Site__r.CI_Site_Type__c, 
						v.CI_Certificate_Site__r.CI_Site__r.Key_Account__c, 
						v.CI_Certificate_Site__r.CI_Site__r.Site_Role__c, 
						v.CI_Certificate_Site__r.CI_Site__r.Location__Latitude__s, 
						v.CI_Certificate_Site__r.CI_Site__r.Location__Longitude__s
    			FROM	CI_Visit__c v 
    			WHERE	v.CI_Certificate_Site__r.CI_Site__r.Id IN :this.filteredSiteIds 
    					AND v.Status__c <> 'Cancelled' 
    					AND v.Order_Type__c = 'BS02' 
    					AND v.Start_Date__c <= :this.dateStore.End_Date__c 
    					AND v.End_Date__c >= :this.dateStore.Start_Date__c]) this.visitsList.add(new VisitWrapper(visit));
        }    	

		// Display message if nothing has been selected
		if (this.sitesList.isEmpty() && this.visitsList.isEmpty())
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'No records found! Please amend your selection criteria.'));
			this.hasRecords = false;
		}

		return null;
	}
	
	// Retrieve selected set-based records
	public PageReference SiteBased()
	{
		// Initialize returned values
		Initialize();
		
		// Validate parameters
		if (this.showVisits && (this.dateStore.Start_Date__c == null || this.dateStore.End_Date__c == null || this.dateStore.Start_Date__c > this.dateStore.End_Date__c))
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must specify a valid date range for visits.'));
			this.hasRecords = false;
			return null;
		}

		// Always apply the site filters
		for (CI_Site__c site : [
			SELECT	s.Id, 
					s.Name, 
					s.Size_Employees__c, 
					s.Needs_Segment__c, 
					s.Territory__c, 
					s.Spend_Band__c, 
					s.Sector__c, 
					s.Current_Holdings__c, 
					s.Product_Count__c, 
					s.Live_Customer_Type__c, 
					s.CI_Site_Type__c, 
					s.Key_Account__c, 
					s.Site_Role__c, 
					s.Portfolios__c, 
					s.Substreams__c, 
					s.Location__Latitude__s, 
					s.Location__Longitude__s
   			FROM	CI_Site__c s 
   			WHERE	s.Id IN :this.siteIds 
   					AND s.Location__Latitude__s <> null]) 
    	{
    		SiteWrapper sw = new SiteWrapper(site, this.config, this.selectedCategory);
    		if (sw.site != null)
			{
				// Add the site to the list to display and to use in subsequent queries
				if (this.showSites) this.sitesList.add(sw);
				this.filteredSiteIds.add(site.Id);
			}
	   	}

		// Get all the selected visits
        if (this.showVisits)
        {
			for (CI_Visit__c visit : [
				SELECT	v.Id, 
						v.Name, 
						v.Start_Date__c, 
						v.End_Date__c, 
						v.Assessors__c, 
						v.SMO_Number__c, 
						v.CI_Certificate_Site__r.CI_Site__r.Name, 
						v.CI_Certificate_Site__r.CI_Site__r.Current_Holdings__c, 
						v.CI_Certificate_Site__r.CI_Site__r.Size_Employees__c, 
						v.CI_Certificate_Site__r.CI_Site__r.CI_Site_Type__c, 
						v.CI_Certificate_Site__r.CI_Site__r.Key_Account__c, 
						v.CI_Certificate_Site__r.CI_Site__r.Site_Role__c, 
						v.CI_Certificate_Site__r.CI_Site__r.Location__Latitude__s, 
						v.CI_Certificate_Site__r.CI_Site__r.Location__Longitude__s
    			FROM	CI_Visit__c v 
    			WHERE	v.CI_Certificate_Site__r.CI_Site__r.Id IN :this.filteredSiteIds 
    					AND v.Status__c <> 'Cancelled' 
    					AND v.Order_Type__c = 'BS02' 
    					AND v.Start_Date__c <= :this.dateStore.End_Date__c 
    					AND v.End_Date__c >= :this.dateStore.Start_Date__c]) this.visitsList.add(new VisitWrapper(visit));
        }    	

		// Display message if nothing has been selected
		if (this.sitesList.isEmpty() && this.visitsList.isEmpty())
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'No records found! Please amend your selection criteria.'));
			this.hasRecords = false;
		}

		return null;
	}

	// Retrieve nearby records
	public PageReference NearbyBased()
	{
		// Initialize returned values
		Initialize();
		
		// Validate parameters
		if ((this.showVisits || this.showEvents) && (this.dateStore.Start_Date__c == null || this.dateStore.End_Date__c == null || this.dateStore.Start_Date__c > this.dateStore.End_Date__c))
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must specify a valid date range for visits or events.'));
			this.hasRecords = false;
			return null;
		}
		
        // Build a dynamic DISTANCE query for sites
        if (this.passedLat != null)
        {
    		String qry = 'SELECT s.Id, s.Name, s.Needs_Segment__c, s.Territory__c, s.Spend_Band__c, s.Sector__c, s.Current_Holdings__c, s.Size_Employees__c, s.Product_Count__c, s.Live_Customer_Type__c, s.CI_Site_Type__c,	s.Key_Account__c, s.Site_Role__c, s.Portfolios__c, s.Substreams__c, s.Location__Latitude__s, s.Location__Longitude__s'; 
    		qry += ' FROM CI_Site__c s'; 
    		qry += ' WHERE DISTANCE(s.Location__c, GEOLOCATION(' + String.valueOf(this.passedLat) + ', ' + String.valueOf(this.passedLng) + '), \'mi\') < ' + String.valueOf(this.distance);	
    		qry += ' ORDER BY DISTANCE(s.Location__c, GEOLOCATION(' + String.valueOf(this.passedLat) + ', ' + String.valueOf(this.passedLng) + '), \'mi\') ASC';	
    		qry += ' LIMIT 6000';
 
        	// Add to the sites list
    		for (CI_Site__c site : Database.query(qry))
    		{
	    		SiteWrapper sw = new SiteWrapper(site, this.config, this.selectedCategory);
	    		if (sw.site != null)
				{
					// Add the site to the list to display and to use in subsequent queries
					if (this.showSites) this.sitesList.add(sw);
					this.filteredSiteIds.add(site.Id);
				}
	    	}
        }

        // Build a dynamic DISTANCE query for assessors
        if (this.passedLat != null && this.showAssessors)
        {
    		String qry = 'SELECT a.Id, a.Name, a.Job_Title__c, a.Cost_Centre__c, a.Location__Latitude__s, a.Location__Longitude__s'; 
    		qry += ' FROM CI_Assessor__c a'; 
    		qry += ' WHERE DISTANCE(a.Location__c, GEOLOCATION(' + String.valueOf(this.passedLat) + ', ' + String.valueOf(this.passedLng) + '), \'mi\') < ' + String.valueOf(this.distance);
    		qry += ' ORDER BY DISTANCE(a.Location__c, GEOLOCATION(' + String.valueOf(this.passedLat) + ', ' + String.valueOf(this.passedLng) + '), \'mi\') ASC';
    		qry += ' LIMIT 6000';

        	// Add to the assessors list
    		for (CI_Assessor__c assessor : Database.query(qry)) this.assessorsList.add(new AssessorWrapper(assessor));
        }
		
        // Use site list to query for visits
        if (this.passedLat != null && this.showVisits)
        {
			for (CI_Visit__c visit : [
				SELECT	v.Id, 
						v.Name, 
						v.Start_Date__c, 
						v.End_Date__c, 
						v.Assessors__c, 
						v.SMO_Number__c, 
						v.CI_Certificate_Site__r.CI_Site__r.Name, 
						v.CI_Certificate_Site__r.CI_Site__r.Current_Holdings__c, 
						v.CI_Certificate_Site__r.CI_Site__r.Size_Employees__c, 
						v.CI_Certificate_Site__r.CI_Site__r.CI_Site_Type__c, 
						v.CI_Certificate_Site__r.CI_Site__r.Key_Account__c, 
						v.CI_Certificate_Site__r.CI_Site__r.Site_Role__c, 
						v.CI_Certificate_Site__r.CI_Site__r.Location__Latitude__s, 
						v.CI_Certificate_Site__r.CI_Site__r.Location__Longitude__s
    			FROM	CI_Visit__c v 
    			WHERE	v.CI_Certificate_Site__r.CI_Site__r.Id IN :this.filteredSiteIds 
    					AND v.Status__c <> 'Cancelled' 
    					AND v.Order_Type__c = 'BS02' 
    					AND v.Start_Date__c <= :this.dateStore.End_Date__c 
    					AND v.End_Date__c >= :this.dateStore.Start_Date__c 
	    		LIMIT	6000]) this.visitsList.add(new VisitWrapper(visit));
        }

        // Build a dynamic DISTANCE query for events
        if (this.passedLat != null && this.showEvents)
        {
    		String qry = 'SELECT e.Id, e.Name, e.Start_Date__c, e.End_Date_of_Section_1__c, e.Start_Date_of_Section_2__c, e.End_Date__c, e.Training_Venue__r.Location__Latitude__s, e.Training_Venue__r.Location__Longitude__s, e.Trainer__r.Name, e.Residential__c, e.Enrollment_Count__c, e.Course__r.Category__c, e.Course__r.Course_Level__c, e.Course__r.Product_Name_Local__c'; 
    		qry += ' FROM Training_Event__c e'; 
    		qry += ' WHERE DISTANCE(e.Training_Venue__r.Location__c, GEOLOCATION(' + String.valueOf(this.passedLat) + ', ' + String.valueOf(this.passedLng) + '), \'mi\') < ' + String.valueOf(this.distance);
    		qry += ' AND e.Start_Date__c <= ' + String.valueOf(this.dateStore.End_Date__c) +' AND e.End_Date__c >= ' + String.valueOf(this.dateStore.Start_Date__c);	
    		qry += ' ORDER BY DISTANCE(e.Training_Venue__r.Location__c, GEOLOCATION(' + String.valueOf(this.passedLat) + ', ' + String.valueOf(this.passedLng) + '), \'mi\') ASC';
    		qry += ' LIMIT 6000';

        	// Add to the events list
    		for (Training_Event__c event : Database.query(qry)) this.eventsList.add(new EventWrapper(event));
        }
		
		// Display message if nothing has been selected
		if (this.sitesList.size() == 0 && this.assessorsList.size() == 0 && this.visitsList.size() == 0 && this.eventsList.size() == 0)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'No records found! Please amend your selection criteria.'));
			this.hasRecords = false;
			return null;
		}
		
		// Reset zoom if selected distance has changed
		if (this.distance != this.oldDistance)
		{
			this.mapZoom = 0;
			this.oldDistance = this.distance;
		}

		return null;
	}

	// Initialize the returned values
	private void Initialize()
	{
		// Initialize
		this.hasRecords = true;
		this.filteredSiteIds = new List<Id>();
		this.sitesList = new List<SiteWrapper>();
		this.assessorsList = new List<AssessorWrapper>();
		this.visitsList = new List<VisitWrapper>();
		this.eventsList = new List<EventWrapper>();

		// Copy category valueList (which may have been edited) to ValueMap to preserve filtering
		for (Category cat : this.config.categoryMap.values())
		{
			// Only add entries when the category is not selected or filtered
			Boolean selectedOrFiltered = (this.selectedCategory != null && cat.field == this.selectedCategory.field);
			cat.valueMap.clear();
			for (ColourWrapper cw : cat.valueList)
			{
				cat.ValueMap.put(cw.label, cw);
				if (!cw.include) selectedOrFiltered = true;
			}
			if (!selectedOrFiltered) cat.valueMap.clear();
		}
	}

	// Switch between category keys/selections
	public void SwitchCategories()
	{
		this.selectedCategory = String.isNotBlank(this.categoryName) ? this.config.categoryMap.get(this.categoryName) : null;
	}
	
	// Wrapper class for CI Site
	public class SiteWrapper
	{
		public CI_Site__c site { get; set; }
		public String label { get; set; }
		public String colour { get; set; }
	
		public SiteWrapper (CI_Site__c mySite, Configuration config, Category myCategory)
		{
			// Check whether site is filtered out
			this.colour = 'red';
			Boolean include = true;

			// Step through every category to check whether filtered out			
			for (Category cat : config.categoryMap.values())
			{
				if (!cat.valueMap.isEmpty())
				{
					if (cat.multipick) // Multipick (no colours)
					{
						// Need a tristate flag (null/true/false)
						Boolean ok = null;
						
						// Get the picked values into a List
						String picksField = String.ValueOf(mySite.get(cat.field));
						List<String> picks = String.isBlank(picksField) ? new List<String>() : picksField.split(';');

						// Check against all values for multipick
						for (String pick : picks)
						{
							// Check one value
							ok = cat.valueMap.containsKey(pick) ? cat.valueMap.get(pick).include : cat.valueMap.get('Unspecified').include;
							if (ok) break;
						}
						
						// Only check undefined if we haven't had an include or exlude
						if (ok == null) ok = cat.valueMap.get('Unspecified').include;
						
						// Update include
						include = ok;
					}
					else // Singleton
					{
						// Start with a default that the value is unspecified
						include = cat.valueMap.get('Unspecified').include;
						if (myCategory != null && cat.field == myCategory.field) this.colour = 'red';
				
						// Check against all values for singletons
						if (cat.valueMap.containsKey(String.valueOf(mySite.get(cat.field))))
						{
							include = cat.valueMap.get(String.valueOf(mySite.get(cat.field))).include;
							if (myCategory != null && cat.field == myCategory.field) this.colour = cat.valueMap.get(String.valueOf(mySite.get(cat.field))).colour;
						}
					}					
				
					// Break if filtered out by this category
					if (!include) break;
				}
			}
			
			// Send back null if not to be included
			if (include)
			{
				this.site = mySite;
				this.label = (mySite.Name +
					'\n\nSite Type: ' + (String.isNotBlank(mySite.CI_Site_Type__c) ? mySite.CI_Site_Type__c : '') +
					'\nSize (employees): ' + (String.isNotBlank(mySite.Size_Employees__c) ? mySite.Size_Employees__c : '') +
					'\nKey Account: ' + (mySite.Key_Account__c != null && mySite.Key_Account__c ? 'Yes' : '') +
					'\nHoldings: ' + (String.isNotBlank(mySite.Current_Holdings__c) ? mySite.Current_Holdings__c : '')).escapeEcmaScript();
			}
		}
	}

	// Wrapper class for CI Assessor
	public class AssessorWrapper
	{
		public CI_Assessor__c assessor { get; set; }
		public String label { get; set; }
	
		public AssessorWrapper (CI_Assessor__c myAssessor)
		{
			this.assessor = myAssessor;
			this.label = (myAssessor.Name + 
				'\n\nJob Title: ' + (String.isNotBlank(myAssessor.Job_Title__c) ? myAssessor.Job_Title__c : '') +
				'\nCost Centre: ' + (String.isNotBlank(myAssessor.Cost_Centre__c) ? myAssessor.Cost_Centre__c : '')).escapeEcmaScript();			
		}
	}

	// Wrapper class for CI Visit
	public class VisitWrapper
	{
		public CI_Visit__c visit { get; set; }
		public String label { get; set; }
		public Boolean highlight { get; set; }
	
		public VisitWrapper (CI_Visit__c myVisit)
		{
			this.visit = myVisit;
			this.label = (myVisit.CI_Certificate_Site__r.CI_Site__r.Name +
				'\n\nSite Type: ' + (String.isNotBlank(myVisit.CI_Certificate_Site__r.CI_Site__r.CI_Site_Type__c) ? myVisit.CI_Certificate_Site__r.CI_Site__r.CI_Site_Type__c : '') +
				'\nSize (employees): ' + (String.isNotBlank(myVisit.CI_Certificate_Site__r.CI_Site__r.Size_Employees__c) ? myVisit.CI_Certificate_Site__r.CI_Site__r.Size_Employees__c : '') +
				'\nKey Account: ' + (myVisit.CI_Certificate_Site__r.CI_Site__r.Key_Account__c != null && myVisit.CI_Certificate_Site__r.CI_Site__r.Key_Account__c ? 'Yes' : '') +
				'\nHoldings: ' + (String.isNotBlank(myVisit.CI_Certificate_Site__r.CI_Site__r.Current_Holdings__c) ? myVisit.CI_Certificate_Site__r.CI_Site__r.Current_Holdings__c : '') +
				'\n\n' + myVisit.Name +
				'\nStart Date: ' + myVisit.Start_Date__c.format() +
				'\nEnd Date: ' + myVisit.End_Date__c.format() +
				'\nAssessors: ' + (String.isNotBlank(myVisit.Assessors__c) ? myVisit.Assessors__c : '')).escapeEcmaScript();			
			this.highlight = (String.isNotBlank(myVisit.Name) && myVisit.Name.startsWith('Re-certification'));
		}
	}

	// Wrapper class for Training Event
	public class EventWrapper
	{
		public Training_Event__c event { get; set; }
		public String label { get; set; }
		public Boolean highlight { get; set; }
	
		public EventWrapper (Training_Event__c myEvent)
		{
			this.event = myEvent;
			this.label = (myEvent.Course__r.Product_Name_Local__c +
				'\n\nDates: ' + myEvent.Start_Date__c.format() +
				(myEvent.End_Date_of_Section_1__c != null ? ' - ' + myEvent.End_Date_of_Section_1__c.format() + ' & ' + myEvent.Start_Date_of_Section_2__c.format() : '') +
				' - ' + myEvent.End_Date__c.format() +
				'\nCategory: ' + (String.isNotBlank(myEvent.Course__r.Category__c) ? myEvent.Course__r.Category__c : '') +
				'\nInstructor: ' + (String.isNotBlank(myEvent.Trainer__r.Name) ? myEvent.Trainer__r.Name : '') +
				'\nEnrolments: ' + myEvent.Enrollment_Count__c +
				'\nResidential: ' + (myEvent.Residential__c != null && myEvent.Residential__c ? 'Yes' : '')).escapeEcmaScript();			
			this.highlight = (String.isNotBlank(myEvent.Course__r.Course_Level__c) && myEvent.Course__r.Course_Level__c == 'Implementation');
		}
	}

	// Class for the application configuration
	public class Configuration
	{
		public List<Selectoption> categoryList{ get; set;}
		public Map<String, Category> categoryMap { get; set; }
		
		public Configuration()
		{
			// Get the XML category data
       		StaticResource xmlFile = [
           		SELECT  s.Body 
           		FROM    StaticResource s 
           		WHERE   s.Name = 'CI_Categories'
           		];
       		DOM.Document xmlConfig = new DOM.Document();
       		xmlConfig.load(xmlFile.Body.toString());
       		DOM.Xmlnode xmlRoot = xmlConfig.getRootElement();
        
       		// Build drop-down options for categories
       		this.categoryList = new List<Selectoption>();
       		this.categoryList.add(new Selectoption('', 'Select filters...'));
       		this.categoryMap = new Map<String, Category>();
       		for (DOM.Xmlnode xmlCategory : xmlRoot.getChildElements())
       		{
       			// Process one category
       			this.categoryList.add(new Selectoption(xmlCategory.getAttributeValue('description', null), xmlCategory.getAttributeValue('description', null)));
       			this.categoryMap.put(xmlCategory.getAttributeValue('description', null), new Category(xmlCategory));
       		}
		}
	}
	
	// Class for one category
	public class Category
	{
		public String field { get; set; }
		public List<ColourWrapper> valueList { get; set; }
		public Map<String, ColourWrapper> valueMap { get; set; }
		public Boolean multipick { get; set; }
		
		public Category(DOM.Xmlnode xmlCategory)
		{
			this.field = xmlCategory.getAttributeValue('field', null);
			this.multipick = Boolean.valueOf(xmlCategory.getAttributeValue('multipick', null));

			// Populate the valueList (adding an Unspecified value)
			this.valueList = new List<ColourWrapper>();
			for (DOM.Xmlnode xmlValue : xmlCategory.getChildElements())
       		{
       			this.valueList.add(new ColourWrapper(xmlValue.getAttributeValue('description', null), xmlValue.getAttributeValue('colour', null), Boolean.valueOf(xmlValue.getAttributeValue('default', null))));
       		}
   			this.valueList.add(new ColourWrapper('Unspecified', 'red', Boolean.valueOf(xmlCategory.getAttributeValue('unspecifiedDefault', null))));

			// The valueMap is empty to start with 
			this.valueMap = new Map<String, ColourWrapper>();
		}
	}
	
	// Wrapper class for colour key
	public class ColourWrapper
	{
		public String label { get; set; }
		public String colour { get; set; }
		public Boolean include { get; set; }
		
		public ColourWrapper(String myLabel, String myColour, Boolean myInclude)
		{
			this.label = myLabel;
			this.colour = myColour;
			this.include = myInclude;
		}
	}
}