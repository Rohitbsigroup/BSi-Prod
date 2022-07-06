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
trigger LeadReflag on Lead (before insert, before update) {
  List<Lead> leadsToInsert = new List<Lead>();

  Map<String, Contact_to_Lead_Field_Map__c> conToLead = Contact_to_Lead_Field_Map__c.getAll();
  
  if (!conToLead.isEmpty()) {
    for (Integer i = 0; i < Trigger.size; i++) {
      Lead currentLead = Trigger.new[i];
      if (Trigger.isUpdate && currentLead.Create_Lead__c && !Trigger.old[i].Create_Lead__c) {
        Lead newLead = new Lead();
        for (Contact_to_Lead_Field_Map__c field : conToLead.values()) {
          String leadField = field.Lead_Field__c;
          if (leadField != null) {
            newLead.put(leadField, currentLead.get(leadField));
          }
        }
        newLead.LeadSource = System.Label.Pardot_Lead_Source;
        newLead.Source_Sub_Category__c = currentLead.Pardot_Trigger_Source_Sub_Category__c;
        leadsToInsert.add(newLead);
      } 
      if (Trigger.isInsert && currentLead.Create_Lead__c) {
        currentLead.Create_Lead__c = false;
        currentLead.Pardot_Trigger_Source_Sub_Category__c = 'NULL';  // Setting this to NULL as requested on task: 11092845
      }
    }
    if(!leadsToInsert.isEmpty()) {
      insert leadsToInsert;
    }
  }
}