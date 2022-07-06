/**
* Author:       Pawel Chrzanowski (K2)
* Date:         24/10/2018
* Description:  Enrollment Utilities
*
* ******************* Change Log *******************
**/

public class EnrollmentUtils {

    public static Id recordType_ELearning;

    static {
        recordType_ELearning = [SELECT Id FROM RecordType WHERE SobjectType = 'Enrollment__c' AND Name = 'E-Learning'].Id;
    }

    //method to calculate Sales Price based on related OpportunityLineItems
    public static void calculateSalesPrice(Set<Id> enrollmentIds){
        System.debug('### EnrollmentUtils.calculateSalesPrice');
        if(enrollmentIds.isEmpty()) return;
    
        /* MD REMOVED 20190121 - NO LONGER USED, SEE BELOW
        Map<Id, Enrollment__c> enrollmentMap = new Map<Id, Enrollment__c>([SELECT Accommodation_Cost__c FROM Enrollment__c WHERE Id IN :enrollmentIds]); */
    
        Map<Id, List<OpportunityLineItem>> enrollmentOLIsMap = new Map<Id, List<OpportunityLineItem>>();
        for(OpportunityLineItem oli : [SELECT Enrollment__c, Item_Cancelled__c, TotalPrice, Product2.Course_Delivery__c FROM OpportunityLineItem WHERE Enrollment__c IN :enrollmentIds]){
            if(enrollmentOLIsMap.containsKey(oli.Enrollment__c)){
                enrollmentOLIsMap.get(oli.Enrollment__c).add(oli);
            }else{
                enrollmentOLIsMap.put(oli.Enrollment__c, new List<OpportunityLineItem>{oli});
            }
        }
        
        List<Enrollment__c> enrollmentsToUpdate = new List<Enrollment__c>();
        for(Id enrId : enrollmentIds){
            //reset Sales Price - MD CHANGED 20190116: Now initialises to 0 as Accommodation included via olis
            //Enrollment__c e = new Enrollment__c(Id = enrId, Sales_Price__c = enrollmentMap.get(enrId).Accommodation_Cost__c);
            Enrollment__c e = new Enrollment__c(Id = enrId, Sales_Price__c = 0);

            //if Enrollment has related OLIs
            if(enrollmentOLIsMap.containsKey(enrId)){
                for(OpportunityLineItem oli : enrollmentOLIsMap.get(enrId)){
                    if(!oli.Item_Cancelled__c && (oli.Product2.Course_Delivery__c == Label.Public)){
                        e.Sales_Price__c += oli.TotalPrice;
                    }
                }
            }
            enrollmentsToUpdate.add(e);
        }
        update enrollmentsToUpdate;
    }
}