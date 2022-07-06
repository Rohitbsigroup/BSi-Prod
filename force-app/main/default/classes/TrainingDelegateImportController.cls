/********************************************************************
 * TrainingDelegateImportController 
 *
 * Controller extension for Lead Conversion
 * 
 * Orignial version written by Tquilla
 * 
 * Author: Alexis Lignereux
 * Created: 16-11-2014
 * Changes:  ASD BG 13-01-2016 Updated canIport to isConverted
 *           KM  BG 29-01-2016 Updated to remove the contact action 
 *                             create contact 
 *           PC  K2 05-10-2018 removed CSV template and moved XLS into Static Resource
 ********************************************************************/
public with sharing class TrainingDelegateImportController {


    public final static String ACTION_INSERT = 'Insert';
    public final static String ACTION_UPDATE = 'Update';
    public final static String ACTION_DELETE = 'Delete';
    public final static String ACTION_IGNORE = 'Ignore';
    public final static String ACTION_LINK = 'Link';
    public final static String ACTION_UPDATE_CONTACT = 'Update Contact';

    public String trainingBookingId {get; set;}
    public TrainingBooking__c trainingBooking {get; set;}
    public Training_Event__c trainingEvent {get; set;}
    public Account trainingBookingAccount {get; set;}
    public String nameFile {get; set;}
    public document docFile {get; set;}
    public List<String> columnList  {get; set;}
    public Boolean canImport {get; set;}
    public Boolean isConverted {get; set;}

    String[] filelines = new String[]{};
    List<TrainingDelegate__c> delegatesToUpload {get; set;}
    List<TrainingDelegate__c> delegatesAttachedToBooking {get; set;}
    List<Contact> contactsAttachedToBookingAccount {get; set;}
    List<Id> contactIds {get; set;}
    Map<Id,Contact> contactsAssignedToTrainingDelegates {get; set;}
    List<ValidatedDelegate> validatedDelegates {get; set;}

    public class ValidatedDelegate {
        public TrainingDelegate__c delegate {get; set;}
        public TrainingDelegate__c existingDelegate {get; set;}
        public Contact existingContact {get; set;}
        public String action {get; set;}
        public List<SelectOption> actions {get; set;}
        public String reason {get; set;}
        public Boolean updateContact {get; set;}
        public List<SelectOption> contacts {get; set;}
        public String contactAction {get; set;}
        public Boolean linked {get; set;}

        public ValidatedDelegate() {
            contacts = null;
            actions = new List<SelectOption>();
            linked = false;
        }
    }

    public TrainingDelegateImportController() {

        docFile = new Document();
        trainingBookingId = Apexpages.currentPage().getParameters().get('trainingBookingId');

        trainingBooking = [Select Can_Import__c, Event_Start_Date__c, Converted__c from TrainingBooking__c where id =:trainingBookingId];

        canImport = trainingBooking.Can_Import__c;
        isConverted = trainingBooking.Converted__c;
        if (isConverted) 
        {
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,'Event start date ' + trainingBooking.Event_Start_Date__c.format() + ' is in the past. Cannot import delegate'));
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,'Training Booking has already been converted. Cannot import delegates'));
        }
    }

    // PARSE THE CSV FILE
    public Pagereference readFile() {
        
        ApexPages.getMessages().clear();

        trainingBooking = [Select id, Training_Event__c, Number_of_Delegates__c, Event_Start_Date__c, Can_Import__c, Conversion_Account__c, (
            Select First_Name__c, Last_Name__c, Salutation__c, First_Name_English__c, Last_Name_English__c, Email_Address__c, Job_Title__c, 
                Mobile_Number__c, Social_Security_Number__c, Accommodation_Required__c, Accommodation_night_before__c, Conversion_Contact__c, 
                Conversion_Contact__r.Email, Conversion_Contact__r.FirstName, Conversion_Contact__r.LastName from Training_Delegates__r) 
            from TrainingBooking__c where id =:trainingBookingId];

        delegatesAttachedToBooking = trainingBooking.Training_Delegates__r;

        // get map of all contacts that are assigned to any delegate
        contactIds = new List<Id>();
        for (TrainingDelegate__c td : delegatesAttachedToBooking) {
            if (td.Conversion_Contact__c != null) {
                contactIds.add(td.Conversion_Contact__c);
            }
        }

        contactsAssignedToTrainingDelegates = new Map<Id,Contact>([Select Id, FirstName, LastName, Phone, Email from Contact where Id =: contactIds]);

        trainingEvent = [Select id, Max_Seats__c from Training_Event__c where id =:trainingBooking.Training_Event__c];

        if (trainingBooking.Conversion_Account__c != null) {
            trainingBookingAccount = [Select id, Name, OwnerId, BillingCountry, BillingStreet, BillingCity, BillingPostalCode, 
                (Select FirstName, LastName, Email, Phone from Contacts) from Account where id =: trainingBooking.Conversion_Account__c];

            contactsAttachedToBookingAccount = trainingBookingAccount.Contacts;
        }

        try {
            if(docFile.body != null) { 
                nameFile = docFile.body.toString();

                system.debug('nameFile: ' + nameFile);

                delegatesToUpload   = new List<TrainingDelegate__c>();

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
                    ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.Error,Label.DI_Errors_no_rows);
                    ApexPages.addMessage(errormsg);
                    delegatesToUpload   = new List<TrainingDelegate__c>();
                    validatedDelegates = new List<ValidatedDelegate>();
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
                    string errorString = string.format(Label.DI_Errors_max_row, new list<string>{string.valueOf(filelines.size())});
                    ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.WARNING,errorString);
                    ApexPages.addMessage(errormsg);
                    return null;
                } else if (cellsNum >= 20000) {
                    string errorString = string.format(Label.DI_Errors_max_cell, new list<string>{string.valueOf(filelines.size())});
                    ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.WARNING,errorString);
                    ApexPages.addMessage(errormsg);
                    return null;
                }

                map<string, Schema.SObjectField> objFieldMap = bg_Utilities.GetObjectFieldMap('TrainingDelegate__c');

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
                    
                    TrainingDelegate__c s = new TrainingDelegate__c();
                    s.Training_Booking__c = trainingBookingId;
                    Integer col = 0; // Column number
                    for (String field :fields) {
                        if (field.startsWith('"') && field.endsWith('"')) {
                            string value = field.replaceAll('"','').replaceAll('DBLQT','"');
                            if(!bg_StringUtils.IsBlank(value)) {
                                if(objFieldMap.get(fieldMap.get(col)).getDescribe().getType() == Schema.DisplayType.Double) {
                                    s.put(fieldMap.get(col), decimal.valueOf(value));
                                } else if (objFieldMap.get(fieldMap.get(col)).getDescribe().getType() == Schema.DisplayType.Boolean) {
                                    s.put(fieldMap.get(col), boolean.valueOf(value));
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
                                } else if (objFieldMap.get(fieldMap.get(col)).getDescribe().getType() == Schema.DisplayType.Boolean) {
                                    s.put(fieldMap.get(col), boolean.valueOf(value));
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
                                } else if (objFieldMap.get(fieldMap.get(col)).getDescribe().getType() == Schema.DisplayType.Boolean) {
                                    s.put(fieldMap.get(col), boolean.valueOf(value));
                                } else {
                                    s.put(fieldMap.get(col), value);
                                }
                            }
                            col++;
                        }
                    }
                    delegatesToUpload.add(s);
                }

                try {
                    // Create attachment
                    Attachment a = new Attachment();
                    a.Body = docFile.Body;
                    a.ContentType = docFile.ContentType;
                    a.Name = docFile.Name;
                    a.ParentId = trainingBookingId;
                    insert a;
                } catch (Exception e) {}
                
                try {
                    Utility.isVisualforce = true;

                    validatedDelegates = new List<ValidatedDelegate>();
                    for (TrainingDelegate__c td : delegatesToUpload) {
                        ValidatedDelegate vd = new ValidatedDelegate();
                        vd.delegate = td;
                        vd.reason = Label.DI_Reason_New_Delegate;
                        vd.action = ACTION_INSERT;
                        vd.actions = new List<SelectOption>();
                        vd.actions.add(new SelectOption(ACTION_INSERT,Label.DI_Action_Insert));
                        vd.actions.add(new SelectOption(ACTION_IGNORE,Label.DI_No_Action));

                        if (trainingBooking.Conversion_Account__c != null) {
                            vd.contacts = new List<SelectOption>();
                            //vd.contacts.add(new SelectOption(ACTION_INSERT,Label.DI_Reason_New_Contact));
                            vd.contactAction = ACTION_IGNORE;
                        }

                        for (Integer i = 0; i < delegatesAttachedToBooking.size(); i++) {
                            TrainingDelegate__c existingTd = delegatesAttachedToBooking[i];
                            if ( (existingTd.First_Name__c == td.First_Name__c && 
                                existingTd.Last_Name__c == td.Last_Name__c) || 
                                (existingTd.Email_Address__c == td.Email_Address__c) ||
                                (existingTd.Conversion_Contact__r.Email == td.Email_Address__c)) {
                                
                                vd.existingDelegate = existingTd;
                                vd.reason = '';

                                if (existingTd.First_Name__c == td.First_Name__c && 
                                existingTd.Last_Name__c == td.Last_Name__c) {
                                    vd.reason = Label.DI_Reason_Matched_on_First_and_Last_Name;
                                }

                                if (existingTd.Email_Address__c == td.Email_Address__c) {
                                    if (vd.reason != '') {
                                        vd.reason += ', ';
                                    }
                                    vd.reason += Label.DI_Reason_Email_on_Delegate;
                                }

                                if (existingTd.Conversion_Contact__c != null) {
                                    if ((existingTd.Conversion_Contact__r.Email == td.Email_Address__c) ||
                                        (existingTd.Conversion_Contact__r.FirstName == td.First_Name__c && existingTd.Conversion_Contact__r.LastName == td.Last_Name__c)) {

                                        vd.existingContact = contactsAssignedToTrainingDelegates.get(existingTd.Conversion_Contact__c);
                                        if (vd.reason != '') {
                                            vd.reason += ', ';
                                        }
                                        vd.reason += Label.DI_Reason_Existing_Contact_on_Delegate;
                                        vd.contacts.add(new SelectOption(ACTION_UPDATE_CONTACT, 'Update ' + existingTd.Conversion_Contact__r.FirstName + ' ' + existingTd.Conversion_Contact__r.LastName));
                                        vd.contactAction = ACTION_UPDATE_CONTACT;
                                        vd.linked = true;
                                    }
                                }

                                vd.action = ACTION_UPDATE;
                                vd.actions = new List<SelectOption>();
                                vd.actions.add(new SelectOption(ACTION_INSERT,Label.DI_Action_Insert));
                                vd.actions.add(new SelectOption(ACTION_UPDATE,Label.DI_Action_Update));
                                vd.actions.add(new SelectOption(ACTION_IGNORE,Label.DI_No_Action));
                                delegatesAttachedToBooking.remove(i);
                                break;
                            }
                        }

                        // only check against contacts that are assigned to account on booking if the delegate
                        // is not already linked to a contact
                        // What if it is related to a contact on a different account?
                        if (contactsAttachedToBookingAccount != null && !vd.linked) {
                            //// for through existing contact
                            for (Integer j = 0; j < contactsAttachedToBookingAccount.size(); j++) {
                                if (contactsAttachedToBookingAccount[j].email == td.Email_Address__c) {
                                    vd.existingContact = contactsAttachedToBookingAccount[j];
                                    if (vd.reason != '') {
                                        vd.reason += ', ';
                                    }
                                    vd.reason += Label.DI_Reason_Matched_Contact_on_Training_Booking_Account;
                                    vd.contacts.add(new SelectOption(ACTION_LINK,
                                        + 'Link with ' + contactsAttachedToBookingAccount[j].FirstName + ' ' + contactsAttachedToBookingAccount[j].LastName));
                                    vd.contactAction = ACTION_LINK;
                                    contactsAttachedToBookingAccount.remove(j);
                                    break;
                                }
                            }
                        }

                        // find duplicate in file only if vd.reason is New Delegate
                        if (vd.reason == Label.DI_Reason_New_Delegate) {
                            if (validatedDelegates.size() > 0) {
                                for (ValidatedDelegate alreadyVd : validatedDelegates) {
                                    if ( (vd.delegate.First_Name__c == alreadyVd.delegate.First_Name__c && vd.delegate.Last_Name__c == alreadyVd.delegate.Last_Name__c)
                                        || (vd.delegate.Email_Address__c == alreadyVd.delegate.Email_Address__c) ) {
                                        vd.reason = Label.DI_Reason_Found_in_file_more_than_once;
                                        vd.action = ACTION_IGNORE;
                                    }
                                }
                            }
                        }

                        // add ignore to contacts if account is associated with Booking
                        if (trainingBooking.Conversion_Account__c != null) {
                            if (vd.contacts != null) {
                                vd.contacts.add(new SelectOption(ACTION_IGNORE, Label.DI_No_Action));
                            }
                        }

                        validatedDelegates.add(vd);
                    }

                    // do we have any delegate left in delegatesAttachedToBooking to remove
                    if (delegatesAttachedToBooking.size() > 0) {
                        for (TrainingDelegate__c deleteTd : delegatesAttachedToBooking) {
                            ValidatedDelegate vd = new ValidatedDelegate();
                            vd.delegate = deleteTd;
                            vd.reason = Label.DI_Reason_Not_in_file_but_in_Training_Booking;
                            vd.action = ACTION_DELETE;
                            vd.actions.add(new SelectOption(ACTION_DELETE,Label.DI_Action_Delete));
                            vd.actions.add(new SelectOption(ACTION_IGNORE,Label.DI_No_Action));
                            vd.contacts = new List<SelectOption>();
                            //vd.contacts.add(new SelectOption(ACTION_INSERT,Label.DI_Reason_New_Contact));
                            vd.contacts.add(new SelectOption(ACTION_IGNORE, Label.DI_No_Action));
                            vd.contactAction = ACTION_IGNORE;
                            validatedDelegates.add(vd);
                        }
                    }

                } catch (Exception e) {
                    ApexPages.Message errormsg 
                        = new ApexPages.Message(ApexPages.severity.ERROR,Label.DI_Errors_occured + ' == ' + e.getMessage());
                    ApexPages.addMessage(errormsg);
                }
            } else {
                ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.WARNING,Label.DI_Errors_no_file);
                ApexPages.addMessage(errormsg);
            }
        } catch (Exception ex) {
            // Print user friendly error message
            ApexPages.Message errormsg;
            if (ex.getMessage().contains('UTF-8')) {
                errormsg = new ApexPages.Message(
                    ApexPages.severity.WARNING, Label.DI_Errors_file_format);
            } else {
                errormsg = new ApexPages.Message(ApexPages.severity.WARNING,Label.DI_Errors_error + ex.getMessage());
            }
            ApexPages.addMessage(errormsg);
        }
        docFile.body = null;
        return null;
    }

    // GET THE LIST OF SUCCESS
    public List<ValidatedDelegate> getDelegates() {
        if (validatedDelegates!= NULL) {
            if (validatedDelegates.size() > 0) {
                return validatedDelegates;
            } else {
                return null;
            }
        } else {
            return null;
        }
    }

    public Pagereference back() {
        Pagereference pageA = new Pagereference('/' + trainingBookingId);
        return pageA;
    }

    public Pagereference updateDelegates() {

        // go through the list of validatedDelegates inserted or update delegagte and contact accordingly
        List<TrainingDelegate__c> inserts = new List<TrainingDelegate__c>();
        List<TrainingDelegate__c> updates = new List<TrainingDelegate__c>();
        List<TrainingDelegate__c> deletes = new List<TrainingDelegate__c>();

        List<Contact> insertContacts = new List<Contact>();
        List<Contact> updateContacts = new List<Contact>();

        Map<TrainingDelegate__c,Contact> delegateContacts = new Map<TrainingDelegate__c,Contact>();

        for (ValidatedDelegate vd : validatedDelegates) {
            TrainingDelegate__c td = vd.delegate;
            Contact newContact = null;

            if (trainingBooking.Conversion_Account__c != null && vd.action != ACTION_IGNORE) {
                if (vd.contactAction == ACTION_INSERT) {
                    newContact = new Contact();
                    newContact.FirstName = vd.delegate.First_Name__c;
                    newContact.LastName = vd.delegate.Last_Name__c;
                    newContact.Phone = vd.delegate.Mobile_Number__c;
                    newContact.Email = vd.delegate.Email_Address__c;
                    newContact.MailingCountry = trainingBookingAccount.BillingCountry;
                    newContact.MailingCity = trainingBookingAccount.BillingCity;
                    newContact.MailingStreet = trainingBookingAccount.BillingStreet;
                    newContact.MailingPostalCode = trainingBookingAccount.BillingPostalCode;
                    newContact.Account = trainingBookingAccount;

                    insertContacts.add(newContact);
                    delegateContacts.put(td,newContact);
                }

                if (vd.contactAction == ACTION_LINK || vd.contactAction == ACTION_UPDATE_CONTACT) {
                    newContact = vd.existingContact;
                    newContact.Phone = vd.delegate.Mobile_Number__c;
                    newContact.Email = vd.delegate.Email_Address__c;

                    updateContacts.add(newContact);

                    td.Conversion_Contact__c = newContact.id;
                }
            }

            if (vd.action == ACTION_INSERT) {
                inserts.add(td);
            }

            if (vd.action ==  ACTION_UPDATE) {
                td.id = vd.existingDelegate.id;
                updates.add(td);
            }

            if (vd.action == ACTION_DELETE) {
                deletes.add(td);
            }

        }

        try {

            if (trainingBooking.Conversion_Account__c != null) {
                if (insertContacts.size() > 0) {
                    insert insertContacts;
                }

                if (updateContacts.size() > 0) {
                    update updateContacts;
                }
            }

            if (inserts.size() > 0) {
                insert inserts;
            }

            if (updates.size() > 0) {
                update updates;
            }

            if (deletes.size() > 0) {
                delete deletes;
            }

            if (delegateContacts.size() > 0) {
                updates = new List<TrainingDelegate__c>();
                for (TrainingDelegate__c td : delegateContacts.keySet()) {
                    Contact c = delegateContacts.get(td);

                    if (c != null)
                    {
                        td.Conversion_Contact__c = c.id;
                        updates.add(td);
                    }
                }

                if (updates.size() > 0) {
                    update updates;
                }
            }

            validatedDelegates = new List<ValidatedDelegate>();
            delegatesToUpload   = new List<TrainingDelegate__c>();

            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM,Label.DI_Update_success));
        } catch (DmlException e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,e.getMessage()));
        }

        return null;
    }
}