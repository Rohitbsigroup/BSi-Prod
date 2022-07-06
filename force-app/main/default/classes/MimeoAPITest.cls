/*
* Created By:  PC K2 - May 2020
* Purpose: Test class for MimeoAPI
*
* changelog
* ------------------------------------------------
*/

@isTest
public class MimeoAPITest {

    @isTest static void mimeoAPITest(){
        insert new Mimeo_Settings__c(API__c = 'test');
        
        MimeoAPI mAPI = new MimeoAPI('UK');
        System.assert(mAPI.apiURL != null);
    }
    
    @isTest static void findDocumentsTest(){
        insert new Mimeo_Settings__c(API__c = 'test');

        MimeoAPI mAPI = new MimeoAPI('UK');

        //null        
        MimeoAPI.FindDocumentsResponse fdr1 = mAPI.findDocuments(null);
        System.assertEquals(null, fdr1.Data);
        
        //success
        MimeoAPI.FindDocumentsResponse fdr2 = mAPI.findDocuments('test');
        System.assert(!String.isBlank(fdr2.Data.get(0).DigitalAssetId));
    }
    
    @isTest static void createDistributionTest(){
        insert new Mimeo_Settings__c(API__c = 'test');
        
        Training_Event__c event = TestDataUtility.insertTrainingEvent(Date.today() + 5, true);
        
        Product2 course = new Product2(Id = event.Course__c);
        course.Training_Taxonomy_Code__c = 'testUK';
        update course;

        insert new Mimeo_Document__c(Course__c = course.Id, Name = 'test1', Active__c = true);
        insert new Mimeo_Document__c(Course__c = course.Id, Name = 'test2', Active__c = true);
        insert new Mimeo_Document__c(Course__c = course.Id, Name = 'test3', Active__c = false);
        insert new Mimeo_Document__c(Course__c = null, Name = 'test4', Active__c = true);
        
        Test.startTest();
            MimeoAPI mAPI = new MimeoAPI('UK');
            
            //null
            MimeoAPI.CreateDistributionResponse cdr1 = mAPI.createDistribution(null);
            System.assertEquals(false, cdr1.Success);
            
            //success
            MimeoAPI.CreateDistributionResponse cdr2 = mAPI.createDistribution(event.Id);
            System.assert(cdr2.Success);
            System.debug(cdr2);
        Test.stopTest();
    }

    @isTest static void assignKeysToUsersTest(){
        insert new Mimeo_Settings__c(API__c = 'test');

        Test.startTest();
            MimeoAPI mAPI = new MimeoAPI('UK');
            
            //null
            MimeoAPI.ResponseWrapper responseWrapper1 = mAPI.assignKeysToUsers(null, 'John', 'Smith', 'distributionId');
            System.assertEquals(null, responseWrapper1.json);
            
            //success
            MimeoAPI.ResponseWrapper responseWrapper2 = mAPI.assignKeysToUsers('test@test.com', 'John', 'Smith', 'distributionId');
            List<MimeoAPI.AssignKeysResponse200> responseList = (List<MimeoAPI.AssignKeysResponse200>)JSON.deserialize(responseWrapper2.json, List<MimeoAPI.AssignKeysResponse200>.class);
            System.assertEquals(responseList[0].Status, 'Success');
        Test.stopTest();
    }

    @isTest static void revokeKeysFromDistributionTest(){
        insert new Mimeo_Settings__c(API__c = 'test');

        Test.startTest();
            MimeoAPI mAPI = new MimeoAPI('UK');
            
            //null
            MimeoAPI.ResponseWrapper responseWrapper1 = mAPI.revokeKeysFromDistribution(null);
            System.assertEquals(null, responseWrapper1.json);
            
            //success
            MimeoAPI.ResponseWrapper responseWrapper2 = mAPI.revokeKeysFromDistribution('key');
            System.assertEquals(responseWrapper2.statusCode, 200);
        Test.stopTest();
    }
}