/**
* Author:       Pawel Chrzanowski (K2)
* Date:         24/10/2018
* Description:  Enrollment Utilities Test class
*
* ******************* Change Log *******************
**/

@isTest
public class EnrollmentUtilsTest {

    @isTest
    static void enrollmentUtilsTest(){
        Enrollment__c e = TestDataUtility.insertEnrollmentWithDependancies(Date.today() + 5, true, Label.Enrollment_Booking_Status_Booked);
        
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        product.Course_Delivery__c = Label.Public;
        update product;

        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = product.Id, UnitPrice = 0.0, IsActive = true);
        insert pbe;
              
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        for(Integer i=0; i<5; i++){
            OpportunityLineItem oli = new OpportunityLineItem();
            oli.Training_Event__c = e.Training_Event__c;
            oli.PricebookEntryId = pbe.Id;
            oli.OpportunityId = opp.Id;
            oli.Product2Id = product.Id;
            oli.TotalPrice = 100;
            oli.Quantity = 1;
            oliList.add(oli);
        }
        insert oliList;
        
        for(OpportunityLineItem oli : oliList){
            oli.Enrollment__c = e.Id;
        }
        update oliList;
    }

}