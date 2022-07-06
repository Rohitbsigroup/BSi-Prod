/********************************************************************
 * bg_CongaTemplateCloneControllerTest
 *
 * Test class for bg_CongaTemplateCloneWithItemsController
 * 
 * 
 * Author: James Thornton
 * Created: 18-05-2016
 * Changes: 
 ********************************************************************/

@isTest
public class bg_CongaTemplateCloneControllerTest 
{
    static Integer NUMBER_OF_QUERIES = 5;

    static testMethod void testCloneController_TemplateOnly() 
    {
       // setup a reference to the page the controller is expecting with the parameters
        PageReference pref = Page.CongaTemplateClone;
        Test.setCurrentPage(pref);

        // setup a Conga Template 
        APXTConga4__Conga_Template__c masterTemplate = bg_UnitTestHelper.GetTemplate('GB_EN Template');
        insert masterTemplate;

        // Construct the standard controller
        ApexPages.StandardController con = new ApexPages.StandardController(masterTemplate);

        // create the controller
        bg_CongaTemplateCloneWithItemsController ext = new bg_CongaTemplateCloneWithItemsController(con);

        // Switch to test context
        Test.startTest();

        // call the save method
        PageReference ref = ext.save();
        
        System.assertNotEquals(null, ext.getCountries());
        System.assertNotEquals(null, ext.getCurrency());
        System.assertNotEquals(null, ext.getLanguages());
        
        // check that the new Conga Template was created successfully
        APXTConga4__Conga_Template__c newTemplate = [select id from APXTConga4__Conga_Template__c where id = :ext.newRecordId];
        System.assertNotEquals(newTemplate, null);
        
        // Switch back to runtime context
        Test.stopTest();

    }

    static testMethod void testCloneController_TemplateAndQueries() 
    {
       // setup a reference to the page the controller is expecting with the parameters
        PageReference pref = Page.CongaTemplateClone;
        Test.setCurrentPage(pref);

        // setup a Conga Template 
        APXTConga4__Conga_Template__c masterTemplate = bg_UnitTestHelper.GetTemplate('GB_EN Template');
        insert masterTemplate;

        // create new Conga Query records
        List<APXT_CMQR__Conga_Merge_Query__c> masterCongaQueryList = bg_UnitTestHelper.GetQueries('test query', NUMBER_OF_QUERIES);
        insert masterCongaQueryList;
        System.assertEquals(NUMBER_OF_QUERIES, masterCongaQueryList.size());

        // create new Template Query record for each Conga Query
        List<Template_Queries__c> templateQueryList = new List<Template_Queries__c>();
        for (APXT_CMQR__Conga_Merge_Query__c query : masterCongaQueryList)
        {
            Template_Queries__c templateQuery = bg_UnitTestHelper.GetTemplateQuery('template query test', masterTemplate.id, query.id);
            templateQueryList.add(templateQuery);
        }
        insert templateQueryList;
        System.assertEquals(NUMBER_OF_QUERIES, templateQueryList.size());

        // Construct the standard controller
        ApexPages.StandardController con = new ApexPages.StandardController(masterTemplate);

        // create the controller
        bg_CongaTemplateCloneWithItemsController ext = new bg_CongaTemplateCloneWithItemsController(con);

        // Switch to test context
        Test.startTest();

        // call the save method
        PageReference ref = ext.save();

        System.assertNotEquals(null, ext.getCountries());
        System.assertNotEquals(null, ext.getCurrency());
        System.assertNotEquals(null, ext.getLanguages());
        
        // check that the new Conga Template was created successfully
        APXTConga4__Conga_Template__c newTemplate = [select id from APXTConga4__Conga_Template__c where id = :ext.newRecordId];
        System.assertNotEquals(newTemplate, null);
        // check that the Template Query items were created
        List<Template_Queries__c> newTemplateQueries = [Select Id From Template_Queries__c where Conga_Template__c = :ext.newRecordId];
        System.assertEquals(NUMBER_OF_QUERIES, newTemplateQueries.size());

        // Switch back to runtime context
        Test.stopTest();

    }
}