/********************************************************************
 * LeadReflag
 *
 * Trigger to create a lead copy if a Create_Lead__c is checked
 *
 * Test Class : reflagTest
 *
 * 
 * Author: Nebula - Robert Bedding
 * Created: 08-08-2016 
 ********************************************************************/
trigger ContactReflag on Contact (before insert, before update) {

  List<Lead> leadsToInsert = new List<Lead>();

  Map<Id, Account> interestingAccounts = new Map<Id,Account>();

  Map<String, Contact_to_Lead_Field_Map__c> conToLead = Contact_to_Lead_Field_Map__c.getAll();

  if (!conToLead.isEmpty()) {
    for (Contact c: Trigger.new) {
      if (c.Create_Lead__c == true) {
        interestingAccounts.put(c.AccountId, null);
      }
    }
    interestingAccounts = new Map<Id,Account>([
      SELECT Id, Name 
      FROM Account 
      WHERE Id IN :interestingAccounts.keySet()
    ]);
    
    for (Integer i = 0; i < Trigger.size; i++) {
      Contact currentContact = Trigger.new[i];
      if (Trigger.isUpdate && currentContact.Create_Lead__c && !Trigger.old[i].Create_Lead__c) {
        Lead newLead = new Lead();
        for (String field : conToLead.keyset()) {
          Contact_to_Lead_Field_Map__c fieldname = conToLead.get(field);
          String contactField = fieldname.Contact_Field__c;
          if (contactField == 'AccountId') {
            newLead.put(fieldname.Lead_Field__c ,interestingAccounts.get((Id)currentContact.get(contactField)).Name);
          } else {
            if (contactField != null && fieldname.Lead_Field__c != null) {
              newLead.put(fieldname.Lead_Field__c, currentContact.get(contactField));
            }
          }
        }
        newLead.LeadSource = System.Label.Pardot_Lead_Source;
        newLead.Source_Sub_Category__c = currentContact.Pardot_Trigger_Source_Sub_Category__c;
        
        leadsToInsert.add(newLead);
      }

      if (Trigger.isInsert && currentContact.Create_Lead__c == true) {
        currentContact.Create_Lead__c = false;
        currentContact.Pardot_Trigger_Source_Sub_Category__c = 'NULL';  // Setting this to NULL as requested on task: 11092845
      }
    }
    
    if (!leadsToInsert.isEmpty()) {
      insert leadsToInsert;
    }  
  }
}