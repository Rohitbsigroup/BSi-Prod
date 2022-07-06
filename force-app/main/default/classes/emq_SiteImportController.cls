/**
*	Author		: Prasad JN
*	Description	: Handles site import from the CSV uploaded
*/
public with sharing class emq_SiteImportController {
    
    public Document CSVFile {get; set;}
    
    public String AccountId  {get; set;} 
    
    public List<Site__c> SitesToImport {get; set;}
    
    public List<String> Errors {get; set;}
    
    public String templateURL	{get; set;}
    
    public List<Country_Code__mdt> countries;
    
    public emq_SiteImportController(){
    	CSVFile = new Document();
    	SitesToImport= new List<Site__c>();
    	Errors = new List<String>();
    	countries = [SELECT Country_Name__c, ISO_Alpha_2_Country_Code__c FROM Country_Code__mdt ORDER BY Country_Name__c ASC];
    	
    	accountId = Apexpages.currentPage().getParameters().get('accountId');
    	
    	SystemSetting__c sys = SystemSetting__c.getInstance();
    	List<ContentVersion> template = [SELECT Id, VersionData, PathOnClient, Title FROM ContentVersion WHERE Title =:sys.SiteTemplateName__c AND isLatest = true];	
    	if (!template.isEmpty()) 
    		templateURL = sys.ContentURL__c + 'sfc/servlet.shepherd/version/download/' + template.get(0).Id + '?asPdf=false';
    }
    
    public void readFile(){
    	SitesToImport= new List<Site__c>();
    	Errors = new List<String>();
    	
    	String fileString = '';
    	
    	if(CSVFile.body != null)
      		fileString = CSVFile.body.toString();
      	else{
      		ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.Error,'Invalid file, download the template and upload only the CSV generated.');
            ApexPages.addMessage(errormsg);
            return;
      	}
      	
      	//If the column contains comma it will start with double quotes so replace all double quotes at the beginning	
      	fileString = fileString.replaceAll(',"""',',"DBLQT').replaceall('""",','DBLQT",');
		fileString = fileString.replaceAll('""','DBLQT');
		
		fileString = fileString.replaceAll('\n', '');
		String[] rows = fileString.split('\r');
		
		if (rows.size() < 2) {
			ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.Error,'File contains no data rows please check and try again.');
            ApexPages.addMessage(errormsg);
            return;
		} else if (rows.size() > 501){
			ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.Error,'We can process only 500 rows at a time, split your file and try again.');
            ApexPages.addMessage(errormsg);
            return;
		}
		
		List<String> dupeCheckIds = new List<String>();
		for (Integer rowCount = 1; rowCount < rows.size(); rowCount++) {
			//Check for first empty line with only commans and break
			if (rows[rowCount].replaceAll(',','').trim().length() == 0) 
				break;
				
			List<String> columns = new List<String>();
            columns = rows[rowCount].split(',');
            
            Site__c site = new Site__c();
            site.Account__c = AccountId;
            
            String parseError = ' ';
            String column = '';
            boolean validCountry = false;
            for (Integer columnCount=0; columnCount < columns.size(); columnCount++) {
            	column = cleanColumnQuotes(columns[columnCount]);
            	
            	if(columnCount == 0)
            		if(String.isNotEmpty(column))
            			site.Name = column;
            		else
            			parseError = parseError + 'Site Name is mandatory,';
            	else if(columnCount == 1)
            		if(String.isNotEmpty(column))
            			site.Street__c = column;
            		else
            			parseError = parseError + 'Street Address is mandatory,';
        		else if(columnCount == 2)
            		if(String.isNotEmpty(column))
            			site.City__c = column;
            		else
            			parseError = parseError + 'City is mandatory,';
        		else if(columnCount == 3)
        			if(String.isNotEmpty(column))
            			site.State__c = column;
            		else
            			parseError = parseError + 'State is mandatory,';
        		else if(columnCount == 4){
            		site.Country__c = column;
    				
    				validCountry = false;
		    		for(Country_Code__mdt country: countries){
		    			if(country.Country_Name__c == site.Country__c){
		    				site.Country_Code__c = country.ISO_Alpha_2_Country_Code__c;
		    				validCountry = true;
		    				break;
		    			}
		    		}
		    		
		    		if(!validCountry)
		    			parseError = parseError + 'Country selected in Invalid,';
        		}
        		else if(columnCount == 5)
            		site.PostCode__c = column;
        		else if(columnCount == 6)
            		site.SitePhone__c = column;
        		else if(columnCount == 7){
        			try{
            			site.NumberEmployees__c = Integer.valueof(column);
        			}catch(Exception e){
        				parseError = parseError + '. No of Employees is invalid. ';
        			}
        		}
            }
            
            site.DupeCheckId__c = generateSiteDupeCheckID(site);
            
            if(dupeCheckIds.contains(site.DupeCheckId__c))
            	parseError = parseError + 'Site is a duplicate of another uploaded.';
            else
            	dupeCheckIds.add(site.DupeCheckId__c);
            	
            SitesToImport.add(site);
            Errors.add(parseError);
		}
		
		return;
    }
    
    public PageReference importSites(){
    	// Separate lists for rows which can be imported and rows which are duplicate
    	List<Site__c> newSitesToImport = new List<Site__c>();
    	List<Site__c> duplicateSites = new List<Site__c>();
    	
    	Errors = new List<String>();
    	
		List<String> dupeCheckIds = new List<String>();
		Boolean hasErrors = false;
		
		// Generate dupe check id's and assigne it to site
		for(Site__c site: SitesToImport){
			site.DupeCheckId__c = generateSiteDupeCheckID(site);
			
			if(String.isNotEmpty(site.DupeCheckId__c))
				dupeCheckIds.add(site.DupeCheckId__c);
		}
		
		// Fetch existing sites with same dupe ids
		List<Site__c> existingSites = [SELECT DupeCheckID__c
							 FROM Site__c
							 WHERE DupeCheckID__c IN :dupeCheckIds];
		 
		dupeCheckIds = new List<String>();
		 	 
		if(existingSites != null){
			for (Integer rowCount = 0; rowCount < SitesToImport.size(); rowCount++) {
				hasErrors = false;
				
				if(!SitesToImport[rowCount].SkipDupeChecker__c){
					if(!dupeCheckIds.contains(SitesToImport[rowCount].DupeCheckId__c)) {
						dupeCheckIds.add(SitesToImport[rowCount].DupeCheckId__c);
					
						for(Site__c site: existingSites){
							if(SitesToImport[rowCount].DupeCheckId__c == site.DupeCheckId__c){
								hasErrors = true;
								break;
							}
						}
					} else
						hasErrors = true;
				}
				
				if(hasErrors){
					duplicateSites.add(SitesToImport[rowCount]);
					Errors.add('Site is a duplicate of an existing site.');
				} else {
					newSitesToImport.add(SitesToImport[rowCount]);
				}
			}
		}
		
		// Import new sites or sites with duplicate check on
    	insert newSitesToImport;
    	
    	// Assign the list to display for users with only duplicate sites
    	SitesToImport = duplicateSites;
    	
		if(duplicateSites.size() > 0){
			ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.Error,'The sites are duplicates of existing site, check Skip Dupe Check and click on Import again.');
            ApexPages.addMessage(errormsg);
			return null;
		}
    	
    	PageReference pageRef = new PageReference('/' + this.accountId);
        return pageRef;
    }
    
    public List<SelectOption> TCodeDescription{
    	get{
    		Schema.DescribeFieldResult tcode = Site__c.TCodeDescr__c.getDescribe();
    		List<Schema.PicklistEntry> tcodeValues = tcode.getPicklistValues();
    		
    		List<SelectOption> options = new List<SelectOption>();
    		options.add(new SelectOption('0', '--None--'));
    		for( Schema.PicklistEntry tcodeValue : tcodeValues)
            	options.add(new SelectOption(tcodeValue.getLabel(), tcodeValue.getValue()));
            	
			return options;
    	}
    } 
    
    public List<SelectOption> Type{
    	get{
    		Schema.DescribeFieldResult siteTypes = Site__c.Type__c.getDescribe();
    		List<Schema.PicklistEntry> siteTypeValues = siteTypes.getPicklistValues();
    		
    		List<SelectOption> options = new List<SelectOption>();
    		options.add(new SelectOption('0', '--None--'));
    		for( Schema.PicklistEntry siteTypeValue : siteTypeValues)
            	options.add(new SelectOption(siteTypeValue.getLabel(), siteTypeValue.getValue()));
            	
			return options;
    	}
    }
    
    public Boolean ShowImport{
    	get{
    		if(SitesToImport.size() == 0)
    			return false;
			else	    	
	    		return true;
    	}
    }
    
    public Boolean ShowSkipDupeCheck{
		get{
			if(Errors.size() == 0)
				return false;
			
			for(String s: Errors){
				if(s != ' ')
					return true;
			}
				
			return false;
		}    	
    }
    
    private String cleanColumnQuotes(String value){
    	if (value.startsWith('"') && value.endsWith('"'))
    		return value.replaceAll('"','').replaceAll('DBLQT','"');
    	else
    		return value;
    }
    
    /*
    * Generates dupe check ids as below:
    * 1. If postcode is not null DupeCheckId = AccountId + PostCode + SiteType
    * 2. If postcode is null & street not null DupeCheckId = AccountId + First 6 Chars of Street + SiteType
    */
    private String generateSiteDupeCheckID(Site__c site){
    	String dupeCheckId = '', postCode = site.PostCode__c, street = site.Street__c;
    	
    	if (!site.SkipDupeChecker__c) {
    		if (postCode != null && postCode != '') {
                postCode = postCode.replace(' ', '').toLowerCase();
                
                if (site.Account__c != null) 
                    dupeCheckId = site.Account__c + postCode + site.Type__c;
    		} else if (street!=null) {
    			street = street.replace(' ', '').toLowerCase();
                
                if (street.length() >= 6) 
                	street=street.substring(0,6);
                
                if (site.Account__c!=null)
                    dupeCheckId=site.Account__c+ street + site.Type__c;
    		}
    	}
    	return dupeCheckId;
    }
}