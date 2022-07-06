/********************************************************************
 * bz_PartInUseMessageTest
 *
 * Test methods for PartInUseMessage class
 * 
 * 
 * Author: Richard Wood
 * Created: 06-05-2016 
 ********************************************************************/
@isTest(SeeAllData=true)
public class bz_PartInUseMessageTest
{
    static testmethod void testPartInUse()
    {
        //Get a product we know is in use in BP
        //ISO 50001 - Application Fee (Additional Certificate)
        Product2 prod = [SELECT id, Name FROM Product2 where id = '01tD0000004oajqIAA'];
    
        //Create a new instance of standard controller
        ApexPages.StandardController sc = new ApexPages.standardController(prod);

        bz_PartInUseMessage controller = new bz_PartInUseMessage(sc);
                
        //Check the messages
        for(ApexPages.Message msg :  ApexPages.getMessages()) 
        {
            System.debug('We have a message');
            System.assertEquals('This Product is in use by Blueprint. Please do not delete.', msg.getSummary());
        }   
    }    
}