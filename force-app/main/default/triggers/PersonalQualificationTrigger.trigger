//This trigger create competencys afer insert new personal qualification//
// currently not working after update , after delete//
 //TODO ::  Introducing Utility Class with corresponding methods.
 
//PC K2, December 2020 - trigger reactivated and commented out, added tracelabs integration
trigger PersonalQualificationTrigger on Personal_Qualification__c (after insert, after update) {

    /*
    // set data type stores all the qualification ids //
   Set<ID> qualificationIds = new Set<ID>();
   // Step through each record in the trigger//
   
   for(Personal_Qualification__c pQ:Trigger.new)
      {
      qualificationIds.add(pQ.Qualification__c);  
      } 
      
   // get id, qualification, unit from qualification_unit//    
   List<Qualification_Unit__c> qUnits= 
     [select Id,Qualification__c,Unit__c from Qualification_Unit__c 
     where Unit__r.Release_Status__c = 'Current' and Qualification__c IN: qualificationIds];
  
   // put all the personal _qualification ids and associated units to pQAndUnits//  
   Map<ID,Set<Id>> pQAndUnits = new Map<ID,Set<Id>>();
   for(Personal_Qualification__c pQ:Trigger.new)
      {
      Set<Id> units = new Set<Id>(); 
      for(Qualification_Unit__c qUnits1:qUnits)
         {
         if(qUnits1.Qualification__c == pQ.Qualification__c)
           {  
           units.add(qUnits1.Unit__c);
           }
   
         pQAndUnits.put(pQ.Id,units);
         } 
     }
    // Create new Competency for Personal_qualification//   
    List<Competency__c> comps = new  List<Competency__c>();
    for(Personal_Qualification__c pQ:Trigger.new)
    
    //If (pQ.Qualification__c != 'XXXXXXXXXXXXXXXXXX') //  //  conditional to skip trying to find unit and add competencies if Qualification is the UK - XXX43901ENUK - Certified Auditor.
    //to change ID and un-comment conditional statement once one available
    //{
       {
       for(Id unit : pQAndUnits.get(pQ.Id))
          {
          Competency__c comp = new Competency__c();
          comp.Personal_Qualification__c = pq.id;
          comp.unit__c = unit;
          comps.add(comp);
          }
       }
      //} 
     insert comps;    
     */
     
    // Instantiate handler
    PersonalQualificationHandler handler = new PersonalQualificationHandler();
    
    // After update
    if(Trigger.isUpdate && Trigger.isAfter){
        handler.onAfterUpdate(Trigger.oldMap, Trigger.newMap);
    }
}