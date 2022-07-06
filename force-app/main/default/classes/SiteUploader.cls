/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         21/11/2011
* Description:  Visualforce Controller used to upload multiple Sites from
*				a csv file with a fixed template 
*
*       
**/
public class SiteUploader 
{
    public String 	nameFile		{get; set;}
    public document docFile {get; set;}

    public List<String> columnList	{get; set;}
    
    public String 		countryCodesURL	{get; set;}
    
    public String 		templateURL	{get; set;}
    public String 		customer	{get; set;}
    
    public Boolean		showResult	{get; set;}
    public Boolean		emailSent	{get; set;}
    public Boolean		showCSV		{get; set;}
    
    public Account		acc;		
    
    public String 	accountId	{get; set;}	
    String[] filelines = new String[]{};
    
    List<Site__c> sitesToUpload;
    List<Site__c> successSites;
    List<String> errorSites;
    
    List<ContentVersion> template;
    //Map<Id,Contact>      contacts;
    
    SystemSetting__c sys;
    
    // CONSTRUCTOR
    public SiteUploader() {

    	docFile = new Document();
    	
    	showResult = false;
    	emailSent  = false;
    	accountId = Apexpages.currentPage().getParameters().get('accountId');
    	acc = [SELECT BillingCountry FROM Account WHERE Id =:accountId];
    	//contacts = new Map<Id,Contact>([SELECT Name, Email FROM Contact WHERE AccountId = :acc.Id order by Name]);
    	sys = SystemSetting__c.getInstance();
    	// Link to the template
    	template = [SELECT Id, VersionData, PathOnClient, Title FROM ContentVersion WHERE Title =:sys.SiteTemplateName__c AND isLatest = true];	
    	if (!template.isEmpty()) templateURL = sys.ContentURL__c + 'sfc/servlet.shepherd/version/download/' + template.get(0).Id + '?asPdf=false';
    	showCSV = !template.isEmpty();

    	list<ContentVersion> countryCodesList = [SELECT Id, VersionData, PathOnClient, Title FROM ContentVersion WHERE Title = :sys.CountryCodesList__c AND isLatest = true];	
    	if (!countryCodesList.isEmpty()) countryCodesURL = sys.ContentURL__c + 'sfc/servlet.shepherd/version/download/' + countryCodesList.get(0).Id + '?asPdf=false';
    }
    
    // SEND EMAIL WITH CSV TO THE CUSTOMER
    public Pagereference sendCSV() {
    	
    	if (!template.isEmpty()) { 
    		
    	EmailTemplate emailTemp = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'NotificationCSVFile'];
		Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
		String senderEmail = [SELECT Email FROM User WHERE Id =:UserInfo.getUserId()].Email;
		
		// Parameter setting
		mail.setReplyTo(senderEmail);
		mail.setSenderDisplayName('BSI Support');
		mail.setTemplateId(emailTemp.Id);
		mail.setTargetObjectId(customer);
		mail.setWhatId(acc.Id);	
		//mail.setSaveAsActivity(true);
		
		// Add CSV as attachment
		List<Messaging.Emailfileattachment> attachs = new List<Messaging.Emailfileattachment>();
		
		Blob attachBody;
 
        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
        attachBody 		= template.get(0).VersionData;
        String str 		= template.get(0).PathOnClient.substring(template.get(0).PathOnClient.indexOf('.') + 1,template.get(0).PathOnClient.length());
        efa.fileName 	= template.get(0).Title+'.' + str;
        efa.Body		= attachBody;
        efa.setContentType('text/csv');
        efa.setInline(false);
        
        attachs.add(efa);
		mail.setFileAttachments(attachs);
			
		// Send email to customer
		List<Messaging.Sendemailresult> results;
		try{
			results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
		}catch(Exception ex){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,Utility.friendlyMessage(ex.getMessage())));
			return null;
		}
		
		// Email result
		emailSent = results.get(0).isSuccess();
		
    	}
    	return null;
    }
    
    // GET LIST OF CONTACTS
    public List<SelectOption> getCustomers() {
      	List<SelectOption> optionList = new List<SelectOption>(); 
	    for (Contact c : [SELECT Name, Email FROM Contact WHERE AccountId = :acc.Id order by Name]){	    	
	    	if (c.Email != null) optionList.add(new SelectOption(c.Id,c.Name + ' (' + c.Email + ')'));
	    }		 
      	return optionList;
    }
    
    // PARSE THE CSV FILE
    public Pagereference readFile()
    {   
    	Map<Id,Site__c> mapSites = new Map<Id,Site__c>();
    	try {
    	if(docFile.body != null) { 
			nameFile = docFile.body.toString();

	        //nameFile		= contentFile.toString();
	        system.debug('nameFile: ' + nameFile);
	        
	        sitesToUpload 	= new List<Site__c>();
	        // Replace instances where a double quote begins a field containing a comma
			nameFile = nameFile.replaceAll(',"""',',"DBLQT').replaceall('""",','DBLQT",');
			// Replace all remaining double quotes
			nameFile = nameFile.replaceAll('""','DBLQT');
			// Split the file
			system.debug('nameFile: ' + nameFile);

			nameFile 	= nameFile.replaceAll('\n', '');
	        filelines 	= nameFile.split('\r'); // Use \r instead of \n because works on windows, unix and mac

	        System.debug('FILELINES: ' + filelines);
	        System.debug('FILELINES SIZE: ' + filelines.size());
	        
	        if (filelines.size()<=2)  {
	        	ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.Error,'An error has occurred. It appears the file contains no data rows please check and try again.');
	            ApexPages.addMessage(errormsg);
	            return null;
	        }
	        
	        // Create columns map
	        // Column 1: Field unique name
	        Map<Integer,String> fieldMap = new Map<Integer,String>(); // Integer: column index | String: field unique name
	       	String[] fieldNames = filelines[0].split(',');
	       	String[] fieldLabels = filelines[1].split(',');
	       	
	       	/*check template has first two header rows 
	       	
	       	
	       	string fieldName_Name = fieldNames[0].replaceAll('"','').replaceAll('DBLQT','"');
	       	string fieldLabel_SiteName = fieldLabels[0].replaceAll('"','').replaceAll('DBLQT','"');
	       	
	       	system.debug('fieldName_Name...' + fieldName_Name);
	       	system.debug('fieldLabel_SiteName...' + fieldLabel_SiteName);
	       	system.debug('fieldNames[0]...' + fieldNames[0]);
	       	system.debug('fieldLabels[0]...' + fieldLabels[0]);
	       	
	       	if (fieldName_Name=='Name' && fieldLabel_SiteName=='Site Name') {
	       		ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.Error,'An error has occurred. It appears the file does not match the template.  When adding data rows to the template please leave the first two rows.');
	            ApexPages.addMessage(errormsg);
	            return null;
	            
	       	}
	       	/*END check template has first two header rows */
	       	
	        for (Integer i = 0; i < fieldNames.size(); i++) {
	        	fieldMap.put(i,fieldNames[i].trim());	
	        }
	        Integer cellsNum = fieldMap.values().size()*filelines.size();
	        if(filelines.size() >= 10000) {
	        	ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.WARNING,'Max number of rows is 10.000: actual number ['+filelines.size()+'].');
            	ApexPages.addMessage(errormsg);
	        	return null;
	        } else if (cellsNum >= 20000) {
	        	ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.WARNING,'Max number of cells is 20.000: actual number ['+cellsNum+'].');
            	ApexPages.addMessage(errormsg);
	        	return null;
	        }
	        
	        map<string, Schema.SObjectField> objFieldMap = bg_Utilities.GetObjectFieldMap('Site__c');
	        
	        columnList = fieldMap.values();
	        // Column 2: Field label
	        for (Integer i = 2; i < filelines.size(); i++) {	            
	            // Check for blank CSV lines (only commas)
				if (filelines[i].replaceAll(',','').trim().length() == 0) break;
	            List<String> fields = new List<String>();
	            fields = filelines[i].split(',');
	            System.debug('FIELDS: ' + fields);
	            System.debug('FIELDS SIZE: ' + fields.size());
	            // Reconstruct field with comma
	            Boolean makeCompositeField = false;
	            String compositeField;
	            
	            Site__c s 		= new Site__c();
	            s.Account__c 	= accountId;	        
	            s.Industry__c	= null; // Blank the field to avoid Validation Rule (Check if required)
	            Integer col = 0; // Column number
	            for (String field :fields) {
	            	if (field.startsWith('"') && field.endsWith('"')) {
						string value = field.replaceAll('"','').replaceAll('DBLQT','"');
						if(!bg_StringUtils.IsBlank(value)) {
							if(objFieldMap.get(fieldMap.get(col)).getDescribe().getType() == Schema.DisplayType.Double) {
								s.put(fieldMap.get(col), decimal.valueOf(value));
		            		} else {
		            			s.put(fieldMap.get(col), value);
		            		}
						}
						col ++;
					} else if (field.startsWith('"')) {
						makeCompositeField = true;
						compositeField = field.replaceAll('"','');
					} else if (field.endsWith('"')) {
						compositeField += ',' + field.replaceAll('"','');
						//s.put(fieldMap.get(col),compositeField.replaceAll('"','').replaceAll('DBLQT','"'));
						string value = compositeField.replaceAll('"','').replaceAll('DBLQT','"');
						if(!bg_StringUtils.IsBlank(value)) {
							if(objFieldMap.get(fieldMap.get(col)).getDescribe().getType() == Schema.DisplayType.Double) {
								s.put(fieldMap.get(col), decimal.valueOf(value));
		            		} else {
		            			s.put(fieldMap.get(col), value);
		            		}
						}	            								
						makeCompositeField = false;
						col++;
					} else if (makeCompositeField) {
						compositeField +=  ',' + field.replaceAll('"','');
					} else {
						//s.put(fieldMap.get(col),field.replaceAll('"','').replaceAll('DBLQT','"'));
						string value = field.replaceAll('"','').replaceAll('DBLQT','"');
						if(!bg_StringUtils.IsBlank(value)) {
							if(objFieldMap.get(fieldMap.get(col)).getDescribe().getType() == Schema.DisplayType.Double) {
								s.put(fieldMap.get(col), decimal.valueOf(value));
		            		} else {
		            			s.put(fieldMap.get(col), value);
		            		}
						}
						col++;
					}
	            }
				if(s.Country__c == null || s.Country__c == '') s.Country__c	= acc.BillingCountry;
	            sitesToUpload.add(s);
	        }
	        
	        try {
    			// Create attachment
				Attachment a = new Attachment();
				a.Body = docFile.Body;
				a.ContentType = docFile.ContentType;
				a.Name = docFile.Name;
				a.ParentId = acc.Id;
				insert a;
	        } catch (Exception e) {}
	        
	        try {
	        	Utility.isVisualforce = true;
	        	//insert sitesToUpload;
	        	showResult = true;
	        	Database.SaveResult[] result = Database.Insert(sitesToUpload,false);
	        	for (Site__c s : sitesToUpload) {
	        		if (s.Id != null) mapSites.put(s.Id,s);
	        	}
	        	errorSites = new List<String>();
	        	successSites = new List<Site__c>();
	        	for (Database.SaveResult curr : result) {
	        		if(!curr.isSuccess()) {
	        			errorSites.add(curr.getErrors().get(0).getMessage());
	        		} else {
	        			if (mapSites.get(curr.getId()) != null) successSites.add(mapSites.get(curr.getId()));
	        		}
	        	}
	        }
	        catch (Exception e) {
	            ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR,'An error has occurred. Please check the template or try again later');
	            ApexPages.addMessage(errormsg);
	        }  
        
    	} else {
    		ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.WARNING,'Please upload a file.');
            ApexPages.addMessage(errormsg);
    	}     	
    	} catch (Exception ex) {
    		// Print user friendly error message
    		ApexPages.Message errormsg;
    		if (ex.getMessage().contains('UTF-8')) {
    			errormsg = new ApexPages.Message(ApexPages.severity.WARNING, 'Please check file content and format. (e.g. pasting content from a website, trying to upload an Excel file)');
    		} else {
    			errormsg = new ApexPages.Message(ApexPages.severity.WARNING,'An Error has occurred: ' + ex.getMessage());
    		}
            ApexPages.addMessage(errormsg);
    	}
    	docFile.body = null;
        return null;
    }

    // GET THE LIST OF SITES
    public List<Site__c> getuploadedSites()
    {
        if (sitesToUpload!= NULL) {
            if (sitesToUpload.size() > 0) {
            	List<Site__c> firstResults = new List<Site__c>();
            	Integer i = 0;
            	for (Site__c s :sitesToUpload) {
            		if (i < 20) {
            			firstResults.add(s);
            			i++;
            		}
            		else break;
            	}
                return firstResults;
            } else
                return null;                    
        } else
            return null;
    }
    
    // GET THE LIST OF SUCCESS
    public List<Site__c> getSuccess()
    {
        if (successSites!= NULL) {
            if (successSites.size() > 0) {
            	List<Site__c> firstResults = new List<Site__c>();
            	Integer i = 0;
            	for (Site__c s :successSites) {
            		if (i < 20) {
            			firstResults.add(s);
            			i++;
            		}
            		else break;
            	}
                return firstResults;
            } else
                return null;                    
        } else
            return null;
    }
    
    // GET THE LIST OF ERRORS
    public List<String> getErrors()
    {
        if (errorSites!= NULL) {
            if (errorSites.size() > 0) {
            	List<String> firstResults = new List<String>();
            	Integer i = 0;
            	for (String s :errorSites) {
            		if (i < 20) {
            			firstResults.add(s);
            			i++;
            		}
            		else break;
            	}
                return firstResults;
            } else
                return null;                    
        } else
            return null;
    }          
    
    // BACK TO ACCOUNT PAGE
    public Pagereference back() {
    	Pagereference pageA = new Pagereference('/' + accountId);
    	return pageA;
    }
}