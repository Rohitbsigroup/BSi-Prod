@isTest 
private class PersonalQualificationTest  {
//    static testMethod void singlePersonalQualificationTest() {
//         Unit__c unit = new Unit__c();
//         unit.Name='TestUnit1';
//        unit.CurrencyIsoCode='AUD';
//         unit.Release_Status__c='Current';
//        insert Unit;
//         Qualification__c Qual = new Qualification__c(Name='TestQualification',CurrencyIsoCode='AUD',Release_Status__c='Current');
//         insert Qual;
         
//           Qualification_Unit__c QualUnit = new Qualification_Unit__c();
//                QualUnit.Qualification__c = Qual.ID;
//                QualUnit.Unit__c = Unit.ID;  
//                insert QualUnit;
                
//          Personal_Qualification__c personalQ = new Personal_Qualification__c();
//                personalQ.Qualification__c = Qual.id;
//                personalQ.CurrencyIsoCode = 'AUD';
//                insert personalQ; 
//                }
//    static testMethod void multiplePersonalQualificationTest() {
//           List<Qualification_Unit__c> qualificationUnits = new List<Qualification_Unit__c>();
//           List<Qualification__c> qualifications= new List<Qualification__c>();
//           List<Unit__c> units = new List<Unit__c>();
           
//           Qualification_Unit__c qualificationUnit;
//           Qualification__c qualification;
//           Unit__c unit;
           
//           for(integer i=0; i<200; i++){
             //Create Qualifications.
//             qualification = new Qualification__c();
//             qualification .Name='TestQualification'+i;
//             qualification.CurrencyIsoCode='AUD';   
//             qualification.Release_Status__c = 'Current';
//             qualifications.add(qualification);
             // Create Units
//             unit = new Unit__c();
//             unit.Name = 'TestUnit'+i;
//             unit.CurrencyIsoCode='AUD';
//             unit.Release_Status__c='Current';   
//             units.add(unit);
//             }
//             insert units;
//             insert qualifications;
//             for(integer i =0; i < 200; i++){
//                 qualificationUnit = new Qualification_Unit__c();
//                 qualificationUnit.Qualification__c  = qualifications.get(i).id;
//                 qualificationUnit.Unit__c = units.get(i).id;
//                 qualificationUnits.add(qualificationUnit);
//             }
//             insert qualificationUnits;
             
//             List<Personal_Qualification__c> personalQ = new List<Personal_Qualification__c>();
//                 for(integer i =0; i < 200; i++){
//                       Personal_Qualification__c pQualification = new Personal_Qualification__c();
//                            pQualification.Qualification__c = qualifications[i].id;
//                            pQualification.CurrencyIsoCode = 'AUD';
//                            personalQ.add(pQualification);
  //               }
  //              insert personalQ;
    
//    }
}