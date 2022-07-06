/********************************************************************
 * AddSiteToQuoteControllerTest 
 *
 * Test class for AddSiteToQuoteController
 * 
 * 
 * Author: Rob Earey
 * Created: 22-10-2013
 * Changes: 24-05-2017 - RC changed assert statements to take into 
 *                       account the auto creation of a default site.
 *            11-07-2017 - MJ - Renamed class from AddOptySiteControllerV2Test to AddSiteToQuoteControllerTest
 *            11-09-2017 - RC - Rewrote test class as part of PS project due to changes to addSitetoQuote
 *            04-12-2017 - ADS - Case 34308 - Country Code is required
 ********************************************************************/
@isTest 
private class AddSiteToQuoteControllerTest 
{
    /*
    *   setup data method for all test methods.
    */
    public static void setupTestData()
    {
        // Initialise Custom Settings
        bg_UnitTestHelper.SetupCustomSettings();
        // Set up test data
        Account acc = TestData.getTestAccount();
        insert acc;
        Contact con = TestData.getTestContact();
        con.AccountId = acc.Id;
        insert con;
        Opportunity opty = TestData.getTestOpty();
        opty.AccountId = acc.Id;
        insert opty;

        Site__c s1 = bg_UnitTestHelper.GetSite(acc, 'TestSite11', 'GB','NAMED', 'EC1 3NS');
        Site__c s2 = bg_UnitTestHelper.GetSite(acc, 'TestSite22', 'GB', 'NAMED', 'W14 9NN');     

        OpportunitySite__c os = new OpportunitySite__c();
        os.Site__c = s1.Id;
        os.Opportunity__c = opty.Id;
        os.ProposedScope__c = 'Test';
        insert os;
    }

    /*
    *   Test to make sure the redirect works when clicking save and quote button.
    */

    static testMethod void SaveAndQuoteTest()
    {
        setupTestData();

        Account acc = [Select Id from Account];
        Opportunity opty = [Select Id from Opportunity];

        Test.setCurrentPage(Page.AddSiteToQuote);
        ApexPages.currentPage().getParameters().put('oppid',opty.Id);
        AddSiteToQuoteController controller = new AddSiteToQuoteController();

        PageReference pr = controller.saveAndQuote();
        System.assert( pr.getUrl().contains('quotebuilder'));
    }

    static testMethod void addOptySiteTest() {
        
        setupTestData();

        Account acc = [Select Id from Account];
        Opportunity opty = [Select Id from Opportunity];


        Test.setCurrentPage(Page.AddSiteToQuote);
        ApexPages.currentPage().getParameters().put('oppid',opty.Id);
        AddSiteToQuoteController controller = new AddSiteToQuoteController();
        
        // Adding an existing site by selecting a site Wrapper should only be 1
        controller.accSiteWrappers[0].isSelected = true;
        System.assertEquals(1, controller.accSiteWrappers.size());

        //adding to the quote removes 1 from accSiteWrappers
        controller.addSiteToQuote();
        System.assertEquals(0, controller.accSiteWrappers.size());
        //should be 3 opportunity sites
        System.assertEquals(3, controller.oppSiteWrappers.size());

        //there should be 3 sites and 2 opportunity sites.  We are creating one by saving.
        List<Site__c> siteListBeforeSave = [Select id from Site__c];
        System.assertEquals(3, siteListBeforeSave.size());
        List<OpportunitySite__c> oppSiteBeforeSave  = [select id from OpportunitySite__c];
        System.assertEquals(2, oppSiteBeforeSave.size());
        
        //call save should create another opportunity site.
        controller.save();
        List<Site__c> siteListAfterSave = [Select id from Site__c where Account__c =:acc.Id];
        System.assertEquals(3, siteListAfterSave.size());
        List<OpportunitySite__c> oppSiteAfterSave = [select id from OpportunitySite__c where Opportunity__c=:opty.Id];
        System.assertEquals(3, oppSiteAfterSave.size());  
    }
    /*
    *   Test method to test adding a new site via the page.
    */
    static testMethod void AddNewSiteTest() 
    {
        setupTestData();
        Opportunity opty = [Select Id from Opportunity];

        Test.setCurrentPage(Page.AddSiteToQuote);
        ApexPages.currentPage().getParameters().put('oppid',opty.Id);
        AddSiteToQuoteController controller = new AddSiteToQuoteController();

        //call it once to get it to setup on the page.
        controller.addNewSite();

        //setup the new site with information
        controller.newSiteWrapper.Site.Name = 'test site'; 
        controller.newSiteWrapper.Site.Type__c = 'Datacentres';
        controller.newSiteWrapper.Site.Postcode__c = 'a';
        controller.newSiteWrapper.Site.Street__c = 'a';
        controller.newSiteWrapper.Site.Country__c = 'United Kingdom';
        // controller.newSiteWrapper.Site.Country_Code__c = 'GB';

        //call it again to insert the new site.
        controller.addNewSite();
        Site__c siteAfterSave = [Select id from Site__c where Name ='test site'];
        //make sure the site was created.
        System.assertNotEquals(null, siteAfterSave);

        //call new site again and then call cancel
        controller.addNewSite();
        system.assertEquals(true, controller.showNewSection);
        controller.cancelNewSite();
        system.assertEquals(false, controller.showNewSection);

        //call it again to test exceptions
        controller.newSiteWrapper.Site.Name = ''; 
        controller.newSiteWrapper.Site.Type__c = '';
        controller.newSiteWrapper.Site.Postcode__c = '';
        controller.newSiteWrapper.Site.Street__c = '';

        controller.addNewSite();
        controller.addNewSite();
        //check to see if the messages = the NameValidationSite label
        List<Apexpages.Message> msgs1 = ApexPages.getMessages();
        System.assertEquals(Label.NameValidationSite, msgs1[0].getDetail());

        //check to see if the message is TypeValidationSite label
        controller.newSiteWrapper.Site.Name = 'test site';
        controller.addNewSite();
        List<Apexpages.Message> msgs2 = ApexPages.getMessages();
        System.assertEquals(Label.TypeValidationSite, msgs2[1].getDetail());
        
        //check to see if the message is CountryCodeValidationSite
        controller.newSiteWrapper.Site.Type__c = 'Datacentres';
        controller.addNewSite();
        List<Apexpages.Message> msgs3 = ApexPages.getMessages();
        System.assertEquals(Label.CountryCodeValidationSite + ' \'null\'', msgs3[2].getDetail());

        //check to se if the message is AddressValidationPostcodeStreet label
        // controller.newSiteWrapper.Site.Country_Code__c = 'GB';
        controller.newSiteWrapper.Site.Country__c = 'United Kingdom';
        controller.addNewSite();
        List<Apexpages.Message> msgs4 = ApexPages.getMessages();
        System.assertEquals(Label.AddressValidationPostcodeStreet, msgs4[3].getDetail());

        controller.cancel();
    }


    /*
    *   Test method to test the removal of opportunity sites 
    */
    static testMethod void RemoveOppSiteTest() 
    {
        setupTestData();

        Account acc = [Select Id from Account];
        Opportunity opty = [Select Id from Opportunity];

        Site__c s1 = [select id from Site__c where Name ='TestSite11'];

        Test.setCurrentPage(Page.AddSiteToQuote);
        ApexPages.currentPage().getParameters().put('oppid',opty.Id);
        AddSiteToQuoteController controller = new AddSiteToQuoteController();

        //should remove 2 from oppsiteWrapper
        System.assertEquals(2, controller.oppSiteWrappers.size());
        //will add 1 to accsiteWrapper to control the liset
        System.assertEquals(1, controller.accSiteWrappers.size());

        //1 site does not have an opportunity site
        //remove a site from the list 
        controller.opportunitySiteIdToRemove = s1.Id;
        controller.removeOpportuntySiteFromQuote();
        //should remove 1 from oppsiteWrapper
        System.assertEquals(1, controller.oppSiteWrappers.size());
        //will add 2 to accsiteWrapper to control the liset
        System.assertEquals(2, controller.accSiteWrappers.size());

        //test the select all and deselect all functionality 
        controller.selectAll();
        for(AddSiteToQuoteController.SiteWrapper accSiteWrapper :controller.accSiteWrappers)
        {
            System.assertEquals(true, accSiteWrapper.isSelected);
        }

        controller.deselectAll();
        for(AddSiteToQuoteController.SiteWrapper accSiteWrapper :controller.accSiteWrappers)
        {
            System.assertEquals(false, accSiteWrapper.isSelected);
        }
    }

    /*
    *   Test method to test the exception when you don't supply a opporutnity url.
    */
    static testMethod void TestNoOppUrlParameter()
    {
        //don't set an opp id and a apex message should be produced.
        System.assertNotEquals(true, ApexPages.hasMessages());
        AddSiteToQuoteController controller = new AddSiteToQuoteController();
        List<Apexpages.Message> msgs1 = ApexPages.getMessages();
        System.assertEquals('Unable to derive the related opportunity', msgs1[0].getDetail());
    }
}