/********************************************************************
 * SiteUploaderControllerV2
 *
 * Controller Account Site upload

 * Orignial version written by Tquilla
 * 
 * Author: Alexis Lignereux
 * Created: 26-09-2014
 * Changes: 
 ********************************************************************/
public with sharing class SiteUploaderControllerV2 {
	
	public final static String ACTION_INSERT_NEW_SITE = 'Insert New Site';
	public final static String ACTION_UPDATE_EXISTING_SITE = 'Update Existing Site';
	public final static String ACTION_IGNORE = 'Ignore';
	public final static String ACTION_IGNORE_DUPE = 'Ignore Dupe';
	public final static String ACTION_INSERT_UPDATE = 'Insert Update';
	
	public String nameFile {get; set;}
    public document docFile {get; set;}

    public List<String> columnList  {get; set;}

    public String countryCodesURL {get; set;}

    public String templateURL {get; set;}
    public String customer {get; set;}
    
    public Boolean showResult {get; set;}
    public Boolean emailSent {get; set;}
    public Boolean showCSV {get; set;}

    public Account acc;

    public String accountId {get; set;} 
    String[] filelines = new String[]{};

    List<Site__c> sitesToUpload;
    List<String> sitesToUploadNames;
    List<ValidatedSite> validatedSites;

    List<ContentVersion> template;

    SystemSetting__c sys;

    public class ValidatedSite {
        public Site__c site {get; set;}
        public Site__c existingSite {get; set;}
        public String action {get; set;}
        public Boolean newSite {get; set;}
        public Boolean dupeSite {get; set;}
        public Boolean updateSite {get; set;}
        public List<SelectOption> actions {get; set;}
        public String reason {get; set;}

        
        public ValidatedSite() {
            newSite = false;
            dupeSite = false;
            updateSite = false;
            actions = new List<SelectOption>();
        }
    }

    // CONSTRUCTOR
    public SiteUploaderControllerV2() {

        docFile = new Document();

        showResult = false;
        emailSent  = false;
        accountId = Apexpages.currentPage().getParameters().get('accountId');
        acc = [SELECT BillingCountry FROM Account WHERE Id =:accountId];

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

            // Add CSV as attachment
            List<Messaging.Emailfileattachment> attachs = new List<Messaging.Emailfileattachment>();

            Blob attachBody;

            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            attachBody = template.get(0).VersionData;
            String str = template.get(0).PathOnClient.substring(template.get(0).PathOnClient.indexOf('.') + 1,template.get(0).PathOnClient.length());
            efa.fileName = template.get(0).Title+'.' + str;
            efa.Body = attachBody;
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
    public Pagereference readFile() {
    	
    	ApexPages.getMessages().clear();
    	
        try {
            if(docFile.body != null) { 
                nameFile = docFile.body.toString();

                system.debug('nameFile: ' + nameFile);

                sitesToUpload   = new List<Site__c>();
                sitesToUploadNames = new List<String>();

                // Replace instances where a double quote begins a field containing a comma
                nameFile = nameFile.replaceAll(',"""',',"DBLQT').replaceall('""",','DBLQT",');

                // Replace all remaining double quotes
                nameFile = nameFile.replaceAll('""','DBLQT');

                // Split the file
                system.debug('nameFile: ' + nameFile);

                nameFile    = nameFile.replaceAll('\n', '');
                filelines   = nameFile.split('\r'); // Use \r instead of \n because works on windows, unix and mac

                System.debug('FILELINES: ' + filelines);
                System.debug('FILELINES SIZE: ' + filelines.size());
                
                if (filelines.size()<=2)  {
                    ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.Error,Label.SU_Errors_no_rows);
                    ApexPages.addMessage(errormsg);
                    sitesToUpload   = new List<Site__c>();
                    sitesToUploadNames = new List<String>();
                    validatedSites = new List<ValidatedSite>();
                    return null;
                }

                // Create columns map
                // Column 1: Field unique name
                // Integer: column index | String: field unique name
                Map<Integer,String> fieldMap = new Map<Integer,String>();
                String[] fieldNames = filelines[0].split(',');
                String[] fieldLabels = filelines[1].split(',');

                for (Integer i = 0; i < fieldNames.size(); i++) {
                    fieldMap.put(i,fieldNames[i].trim());   
                }

                Integer cellsNum = fieldMap.values().size()*filelines.size();
                if(filelines.size() >= 1000) {
                	string errorString = string.format(Label.SU_Errors_max_row, new list<string>{string.valueOf(filelines.size())});
                    ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.WARNING,errorString);
                    ApexPages.addMessage(errormsg);
                    return null;
                } else if (cellsNum >= 20000) {
                	string errorString = string.format(Label.SU_Errors_max_cell, new list<string>{string.valueOf(filelines.size())});
                    ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.WARNING,errorString);
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
                    
                    Site__c s = new Site__c();
                    s.Account__c = accountId;
                    s.Industry__c   = null; // Blank the field to avoid Validation Rule (Check if required)
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
                    if(s.Country__c == null || s.Country__c == '') s.Country__c = acc.BillingCountry;
                    sitesToUpload.add(s);
                    sitesToUploadNames.add(s.Name);
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

                    Map<Site__c,Site__c> siteErrors = bg_LeadUtils.checkDuplicateSitesV2(sitesToUpload);

                    validatedSites = new List<ValidatedSite>();

                    for (Integer i = 0; i < sitesToUpload.size(); i++) {
                        ValidatedSite vs = new ValidatedSite();
                        vs.site = sitesToUpload[i];

                        if (siteErrors.containsKey(vs.site)) {
                            vs.actions.add(new SelectOption(ACTION_IGNORE_DUPE,Label.SU_Action_Insert));
                            vs.actions.add(new SelectOption(ACTION_IGNORE,Label.SU_No_Action));
                            vs.dupeSite = true;
                            vs.reason = Label.SU_Postcode_matched;
                            vs.existingSite = siteErrors.get(sitesToUpload[i]);

                            if (vs.existingSite.id != null) {
                                vs.actions.add(new SelectOption(ACTION_UPDATE_EXISTING_SITE,Label.SU_Action_Update));
                                vs.reason = Label.SU_Postcode_matched;
                                vs.action = ACTION_UPDATE_EXISTING_SITE;
                            } else {
                                vs.reason = Label.SU_Postcode_Matched_In_File;
                                vs.action = ACTION_IGNORE_DUPE;
                            }

                        } else {
                            vs.actions.add(new SelectOption(ACTION_INSERT_NEW_SITE,Label.SU_Action_Insert));
                            vs.actions.add(new SelectOption(ACTION_IGNORE, Label.SU_No_Action));
                            vs.action = ACTION_INSERT_NEW_SITE;
                            vs.newSite = true;
                            vs.reason = Label.SU_Not_Matched;
                        }

                        validatedSites.add(vs);
                    }

                    List<Site__c> matchingSites = [SELECT id, Name from Site__c where name in :sitesToUploadNames and Account__c = :accountId];

                    for (ValidatedSite vs : validatedSites) {
                        Site__c site = vs.site;
                        for (Site__c foundSite : matchingSites) {
                            if (site.name == foundSite.Name) {
                                site.id = foundSite.id;
                                vs.updateSite = true;
                                vs.dupeSite = false;
                                vs.newSite = false;
                                vs.actions = new List<SelectOption>();
                                vs.actions.add(new SelectOption(ACTION_UPDATE_EXISTING_SITE,Label.SU_Action_Update));
                                vs.actions.add(new SelectOption(ACTION_INSERT_UPDATE,Label.SU_Action_Insert));
	                        	vs.actions.add(new SelectOption(ACTION_IGNORE,Label.SU_No_Action));
	                        	vs.action = ACTION_UPDATE_EXISTING_SITE;
                                vs.reason = Label.SU_Site_Name_Matched;
                                vs.existingSite = foundSite;
                                break;
                            }
                        }
                    }

                }
                catch (Exception e) {
                    ApexPages.Message errormsg 
                        = new ApexPages.Message(ApexPages.severity.ERROR,Label.SU_Errors_occurred);
                    ApexPages.addMessage(errormsg);
                }
            } else {
                ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.WARNING,Label.SU_Errors_no_file);
                ApexPages.addMessage(errormsg);
            }
        } catch (Exception ex) {
            // Print user friendly error message
            ApexPages.Message errormsg;
            if (ex.getMessage().contains('UTF-8')) {
                errormsg = new ApexPages.Message(
                    ApexPages.severity.WARNING, Label.SU_Errors_file_format);
            } else {
                errormsg = new ApexPages.Message(ApexPages.severity.WARNING,Label.SU_Errors_error + ex.getMessage());
            }
            ApexPages.addMessage(errormsg);
        }
        docFile.body = null;
        return null;
    }

    // GET THE LIST OF SUCCESS
    public List<ValidatedSite> getSuccess() {
        if (validatedSites!= NULL) {
            if (validatedSites.size() > 0) {
                return validatedSites;
            } else {
                return null;
            }
        } else {
            return null;
        }
    }

    // BACK TO ACCOUNT PAGE
    public Pagereference back() {
        Pagereference pageA = new Pagereference('/' + accountId);
        return pageA;
    }

    public Pagereference updateSites() {

        // go through the list of validatedSites and inserted or update accordingly
        List<Site__c> inserts = new List<Site__c>();
        List<Site__c> updates = new List<Site__c>();
        for (ValidatedSite vs : validatedSites) {
            Site__c site = vs.site;
            
            if (vs.action == ACTION_INSERT_NEW_SITE || vs.action == ACTION_INSERT_UPDATE) {
                site.id = null;

                // ignore the possible found duplicate, so to be able to insert it needs have
                // flag set
                if (vs.action == ACTION_INSERT_UPDATE) {
                    site.SkipDupeChecker__c = vs.dupeSite;
                }

                try {
                   inserts.add(site);
                } catch (DMLException e) {
                    String errorString = string.format(Label.SU_Failed_insert, new List<string>{site.Name});
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,errorString + e.getMessage()));
                    return null;
                }
            }

            if (vs.action == ACTION_IGNORE_DUPE) {
                site.SkipDupeChecker__c = vs.dupeSite;
                try {
                    inserts.add(site);
                } catch (DMLException e) {
                    String errorString = string.format(Label.SU_Failed_insert_dupe, new List<string>{site.Name});
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, errorString + e.getMessage()));
                    return null;
                }
            }

            if (vs.action == ACTION_UPDATE_EXISTING_SITE) {
                try {
                    site.id = vs.existingSite.id;
                    updates.add(site);
                } catch (DMLException e) {
                    String errorString = string.format(Label.SU_Failed_update, new List<string>{site.Name});
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, errorString + e.getMessage()));
                    return null;
                }
            }
        }

        if (inserts.size() > 0) {
            insert inserts;
        }

        if (updates.size() > 0) {
            update updates;
        }

        validatedSites = new List<ValidatedSite>();
        sitesToUpload   = new List<Site__c>();
        sitesToUploadNames = new List<String>();

        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM,Label.SU_Update_success));

        return null;
    }
}