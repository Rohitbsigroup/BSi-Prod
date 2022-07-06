public with sharing class CiSearchController {

    // Criteria
    public CI_Search__c criteria { get; set; }

    // Results
    public ApexPages.StandardSetController ciAccountsCtrl { get; set; }
    public List<CI_Account__c> ciAccounts { get; set; }
    public ApexPages.StandardSetController ciSitesCtrl { get; set; }
    public List<CI_Site__c> ciSites { get; set; }
    public ApexPages.StandardSetController ciEndorsementsCtrl { get; set; }
    public List<CI_Endorsement__c> ciEndorsements { get; set; }

    // Constructor
    public CiSearchController()
    {
        // Initialize criteria
        this.criteria = new CI_Search__c();
        this.criteria.Show_Accounts__c = true;
        this.criteria.Show_Sites__c = true;
        this.criteria.Show_Endorsements__c = true;

        // Initialize results
        this.ciAccountsCtrl = new ApexPages.StandardSetController(new List<CI_Account__c>());
        this.ciAccounts = new List<CI_Account__c>();
        this.ciSitesCtrl = new ApexPages.StandardSetController(new List<CI_Site__c>());
        this.ciSites = new List<CI_Site__c>();
        this.ciEndorsementsCtrl = new ApexPages.StandardSetController(new List<CI_Endorsement__c>());
        this.ciEndorsements = new List<CI_Endorsement__c>();
    }

    // Perform a search
    public PageReference find()
    {
        // Validate criteria I
        if (!this.criteria.Show_Accounts__c && !this.criteria.Show_Sites__c && !this.criteria.Show_Endorsements__c) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Please include Accounts, Sites or Endorsements'));
            return null;
        }

        // Generate the WHERE clauses
        String accountCriteria = '';
        String siteCriteria = '';
        String endorsementCriteria = '';

        // Has name been specified?
        if (String.isNotBlank(this.criteria.Name_Contains__c)) {
            String myName = '%' + this.criteria.Name_Contains__c + '%';
            accountCriteria += (accountCriteria == '' ? '' : ' AND ') + 'Name LIKE :myName';
            siteCriteria += (siteCriteria == '' ? '' : ' AND ') + 'Name LIKE :myName';
            endorsementCriteria += (endorsementCriteria == '' ? '' : ' AND ') + 'CI_Account__r.Name LIKE :myName';
        }

        // Has sector been specified?
        if (String.isNotBlank(this.criteria.Secondary_Sector__c)) {
            String mySector2 = this.criteria.Secondary_Sector__c;
            accountCriteria += (accountCriteria == '' ? '' : ' AND ') + 'Secondary_Sector__c = :mySector2';
            siteCriteria += (siteCriteria == '' ? '' : ' AND ') + 'Secondary_Sector__c = :mySector2';
            endorsementCriteria += (endorsementCriteria == '' ? '' : ' AND ') + 'CI_Account__r.Secondary_Sector__c = :mySector2';
        }
        else if (String.isNotBlank(this.criteria.Sector__c)) {
            String mySector1 = this.criteria.Sector__c;
            accountCriteria += (accountCriteria == '' ? '' : ' AND ') + 'Sector__c = :mySector1';
            siteCriteria += (siteCriteria == '' ? '' : ' AND ') + 'Sector__c = :mySector1';
            endorsementCriteria += (endorsementCriteria == '' ? '' : ' AND ') + 'CI_Account__r.Sector__c = :mySector1';
        }

        // Has country been specified?
        if (String.isNotBlank(this.criteria.Country__c)) {
            String myCountry = this.criteria.Country__c;
            accountCriteria += (accountCriteria == '' ? '' : ' AND ') + 'Location_s__c= :myCountry';
            siteCriteria += (siteCriteria == '' ? '' : ' AND ') + 'Country__c = :myCountry';
            endorsementCriteria += (endorsementCriteria == '' ? '' : ' AND ') + 'CI_Account__r.Location_s__c= :myCountry';
        }

        // Has employee size been specified?
        if (String.isNotBlank(this.criteria.Size_Employees__c)) {
            String myEmployees = this.criteria.Size_Employees__c;
            accountCriteria += (accountCriteria == '' ? '' : ' AND ') + 'Size_Employees__c = :myEmployees';
            siteCriteria += (siteCriteria == '' ? '' : ' AND ') + 'Size_Employees__c = :myEmployees';
            endorsementCriteria += (endorsementCriteria == '' ? '' : ' AND ') + 'CI_Account__r.Size_Employees__c = :myEmployees';
        }

        // Has spend band been specified?
        if (String.isNotBlank(this.criteria.Spend_Band__c)) {
            String mySpend = this.criteria.Spend_Band__c;
            accountCriteria += (accountCriteria == '' ? '' : ' AND ') + 'Spend_Band__c = :mySpend';
            siteCriteria += (siteCriteria == '' ? '' : ' AND ') + 'Spend_Band__c = :mySpend';
            endorsementCriteria += (endorsementCriteria == '' ? '' : ' AND ') + 'CI_Account__r.Spend_Band__c = :mySpend';
        }

        // Parse the substream options
        List<String> substreamList = new List<String>();
        Boolean substreamAnd = false;
        if (String.isNotBlank(this.criteria.Substream_s__c)) {
            substreamList = this.criteria.Substream_s__c.split(';');
            if (this.criteria.Substream_Logic__c == 'All of...' && substreamList.size() > 1) substreamAnd = true;

            // Build account query
            if (this.criteria.Show_Accounts__c) {

            	// Statement for each AND
            	if (substreamAnd) {
                	AggregateResult[] groupedResults = [SELECT CI_Account__c FROM CI_Transaction__c WHERE Substream__c IN :subStreamList GROUP BY CI_Account__c HAVING COUNT_DISTINCT(SubStream__c) = :subStreamList.size()];
                	List<Id> ids1 = new List<Id>();
                	for (AggregateResult ar : groupedResults) ids1.add((Id)ar.get('CI_Account__c'));
                	accountCriteria += (accountCriteria == '' ? '' : ' AND ') + 'Id IN :ids1';

	            } else {

    	            // One statement for OR
        	        accountCriteria += (accountCriteria == '' ? '' : ' AND ') + 'Id IN (SELECT CI_Account__c FROM CI_Transaction__c WHERE Substream__c IN :subStreamList)';
	            }
            }

            // Build site query
            if (this.criteria.Show_Sites__c) {

            	// Statement for each AND
            	if (substreamAnd) {
	                AggregateResult[] groupedResults = [SELECT CI_Site__c FROM CI_Transaction__c WHERE Substream__c IN :subStreamList GROUP BY CI_Site__c HAVING COUNT_DISTINCT(SubStream__c) = :subStreamList.size()];
    	            List<Id> ids2 = new List<Id>();
        	        for (AggregateResult ar : groupedResults) ids2.add((Id)ar.get('CI_Site__c'));
            	    siteCriteria += (siteCriteria == '' ? '' : ' AND ') + 'Id IN :ids2';

	            } else {

    	            // One statement for OR
        	        siteCriteria += (siteCriteria == '' ? '' : ' AND ') + 'Id IN (SELECT CI_Site__c FROM CI_Transaction__c WHERE Substream__c IN :subStreamList)';
            	}
            }

            // Build endorsement query
            if (this.criteria.Show_Endorsements__c) {

            	// ('AAA;BBB') means "All of...", ('AAA','CCC') means "Any of..."
            	String mySubs = '';
            	if (substreamAnd) {
                	mySubs = '\'' + this.criteria.Substream_s__c + '\'';
            	} else {
                	for (String s : substreamList) mySubs += (mySubs == '' ? '' : ', ') +  '\'' + s + '\'';
            	}
            	endorsementCriteria += (endorsementCriteria == '' ? '' : ' AND ') + 'Substreams__c INCLUDES (' + mySubs + ')';
            }
        }

        // Parse the family options
        List<String> familyList = new List<String>();
        Boolean familyAnd = false;
        if (String.isNotBlank(this.criteria.Families__c)) {
            familyList = this.criteria.Families__c.split(';');
            if (this.criteria.Family_Logic__c == 'All of...' && familyList.size() > 1) familyAnd = true;

            // Build account query
            if (this.criteria.Show_Accounts__c) {

            	// Statement for each AND
	            if (familyAnd) {
        	        AggregateResult[] groupedResults = [SELECT CI_Account__c FROM CI_Transaction__c WHERE Family__c IN :familyList GROUP BY CI_Account__c HAVING COUNT_DISTINCT(Family__c) = :familyList.size()];
	                List<Id> ids3 = new List<Id>();
    	            for (AggregateResult ar : groupedResults) ids3.add((Id)ar.get('CI_Account__c'));
            	    accountCriteria += (accountCriteria == '' ? '' : ' AND ') + 'Id IN :ids3';

	            } else {

                	// One statement for OR
                	accountCriteria += (accountCriteria == '' ? '' : ' AND ') + 'Id IN (SELECT CI_Account__c FROM CI_Transaction__c WHERE Family__c IN :familyList)';
            	}
            }

            // Build site query
            if (this.criteria.Show_Sites__c) {

            	// Statement for each AND
	            if (familyAnd) {
	                AggregateResult[] groupedResults = [SELECT CI_Site__c FROM CI_Transaction__c WHERE Family__c IN :familyList GROUP BY CI_Site__c HAVING COUNT_DISTINCT(Family__c) = :familyList.size()];
    	            List<Id> ids4 = new List<Id>();
        	        for (AggregateResult ar : groupedResults) ids4.add((Id)ar.get('CI_Site__c'));
            	    siteCriteria += (siteCriteria == '' ? '' : ' AND ') + 'Id IN :ids4';

            	} else {

                	// One statement for OR
                	siteCriteria += (siteCriteria == '' ? '' : ' AND ') + 'Id IN (SELECT CI_Site__c FROM CI_Transaction__c WHERE Family__c IN :familyList)';
	            }
            }

            // Build endorsement query
            if (this.criteria.Show_Endorsements__c) {

            	// ('AAA;BBB') means "All of...", ('AAA','CCC') means "Any of..."
	            String myFams = '';
    	        if (familyAnd) {
        	        myFams = '\'' + this.criteria.Families__c + '\'';
            	} else {
                	for (String s : familyList) myFams += (myFams == '' ? '' : ', ') +  '\'' + s + '\'';
            	}
            	endorsementCriteria += (endorsementCriteria == '' ? '' : ' AND ') + 'Families__c INCLUDES (' + myFams + ')';
        	}
        }

        // Validate criteria II
        if (String.isBlank(accountCriteria) && String.isBlank(siteCriteria) && String.isBlank(endorsementCriteria)) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Please specify at least one filter'));
            return null;
        }

        // Execute the account query
        if (this.criteria.Show_Accounts__c) {
            String accountQuery = 'SELECT Id, Name, Size_Employees_Link__c, Spend_Band__c, Region_Owner__c, Cluster_Owner__c, Country_Owner__c, Current_Holdings__c, Location_s__c, Sector_Link__c, Secondary_Sector__c, SIC_Code__c, SIC_Description__c FROM CI_Account__c WHERE ' + accountCriteria + ' ORDER BY Name LIMIT 1000'; 
            System.debug(accountQuery);
            this.ciAccountsCtrl = new ApexPages.StandardSetController(Database.getQueryLocator(accountQuery));
            this.ciAccountsCtrl.setPageSize(5);
            this.ciAccounts = (List<Ci_Account__c>)this.ciAccountsCtrl.getRecords();
        }

        // Execute the site query
        if (this.criteria.Show_Sites__c) {
            String siteQuery = 'SELECT Id, Name, CI_Account__c, CI_Account__r.Id, CI_Account__r.Name, Size_Employees_Link__c, Spend_Band__c, Country__c, Current_Holdings__c, Sector_Link__c, Secondary_Sector__c, SIC_Code__c, SIC_Description__c FROM CI_Site__c WHERE ' + siteCriteria + ' ORDER BY Name LIMIT 1000'; 
            //System.debug(siteQuery);
            this.ciSitesCtrl = new ApexPages.StandardSetController(Database.getQueryLocator(siteQuery));
            this.ciSitesCtrl.setPageSize(5);
            this.ciSites = (List<Ci_Site__c>)this.ciSitesCtrl.getRecords();
        }

        // Execute the endorsement query
        if (this.criteria.Show_Endorsements__c) {
            String endorsementQuery = 'SELECT Id, Name, CI_Account__c, CI_Account__r.Id, CI_Account__r.Name, Format__c, Language__c, Availability__c, Document_Type__c, Valid_From__c, Valid_To__c FROM CI_Endorsement__c WHERE ' + endorsementCriteria + ' ORDER BY Name LIMIT 1000';
            //System.debug(endorsementQuery);
            this.ciEndorsementsCtrl = new ApexPages.StandardSetController(Database.getQueryLocator(endorsementQuery));
            this.ciEndorsementsCtrl.setPageSize(5);
            this.ciEndorsements = (List<Ci_Endorsement__c>)this.ciEndorsementsCtrl.getRecords();
        }

        // Validate criteria III
        if (this.ciAccounts.isEmpty() && this.ciSites.isEmpty() && this.ciEndorsements.isEmpty()) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, 'No results were found'));
            return null;
        }

        return null;
    }

    // Pagination ================================================================================================================================================

    public void firstAccount() {
        ciAccountsCtrl.first();
        this.ciAccounts = (List<Ci_Account__c>)this.ciAccountsCtrl.getRecords();
    }

    public void lastAccount() {
        ciAccountsCtrl.last();
        this.ciAccounts = (List<Ci_Account__c>)this.ciAccountsCtrl.getRecords();
    }

    public void previousAccount() {
        ciAccountsCtrl.previous();
        this.ciAccounts = (List<Ci_Account__c>)this.ciAccountsCtrl.getRecords();
    }

    public void nextAccount() {
        ciAccountsCtrl.next();
        this.ciAccounts = (List<Ci_Account__c>)this.ciAccountsCtrl.getRecords();
    }

    public void firstSite() {
        ciSitesCtrl.first();
        this.ciSites = (List<Ci_Site__c>)this.ciSitesCtrl.getRecords();
    }

    public void lastSite() {
        ciSitesCtrl.last();
        this.ciSites = (List<Ci_Site__c>)this.ciSitesCtrl.getRecords();
    }

    public void previousSite() {
        ciSitesCtrl.previous();
        this.ciSites = (List<Ci_Site__c>)this.ciSitesCtrl.getRecords();
    }

    public void nextSite() {
        ciSitesCtrl.next();
        this.ciSites = (List<Ci_Site__c>)this.ciSitesCtrl.getRecords();
    }

    public void firstEndorsement() {
        ciEndorsementsCtrl.first();
        this.ciEndorsements = (List<Ci_Endorsement__c>)this.ciEndorsementsCtrl.getRecords();
    }

    public void lastEndorsement() {
        ciEndorsementsCtrl.last();
        this.ciEndorsements = (List<Ci_Endorsement__c>)this.ciEndorsementsCtrl.getRecords();
    }

    public void previousEndorsement() {
        ciEndorsementsCtrl.previous();
        this.ciEndorsements = (List<Ci_Endorsement__c>)this.ciEndorsementsCtrl.getRecords();
    }

    public void nextEndorsement() {
        ciEndorsementsCtrl.next();
        this.ciEndorsements = (List<Ci_Endorsement__c>)this.ciEndorsementsCtrl.getRecords();
    }
}