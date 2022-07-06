/********************************************************************
 * bg_FacetedSearchComponentControllerTest
 *
 * Test class for bg_FacetedSearchComponentController
 *
 * Author: Ian Bowman
 * Created: 13/06/17
 * Changes:  
 *
 ********************************************************************/

@isTest
public with sharing class bg_FacetedSearchComponentControllerTest {
    
    /* 
    	Inner class to act as target of registerWithFacetedSearchDelegate()
    */
    private class TestDelegate implements bg_FacetedSearchDelegate
    {
    	public String delegatorKey;
    	public bg_FacetedSearchComponent component;
    	public List<SelectOption> allOptions { get; set; }
		public void addSearchComponent(String delegatorKey, bg_FacetedSearchComponent component)
		{
			this.delegatorKey = delegatorKey;
			this.component = component;
		}
		// stub to conform to interface
		public List<SelectOption> getAllOptions(String s, String s2)
		{
			return allOptions;
		}
    }

	private static testMethod void TestResetFilters()
	{

		TestDelegate delegate = new TestDelegate();
		
		bg_FacetedSearchComponentController controller = new bg_FacetedSearchComponentController();
		controller.searchDelegate = delegate;
		
		List<SelectOption> allOptions = new List<SelectOption>();
		allOptions.add(new SelectOption('Select a test value', 'Select a test value'));
		allOptions.add(new SelectOption('OptionOne', 'OptionOne'));
		allOptions.add(new SelectOption('OptionTwo', 'OptionTwo'));
		allOptions.add(new SelectOption('OptionThree', 'OptionThree'));		
		
		delegate.allOptions = allOptions;
		System.assertEquals(4, controller.allOptions.size());
		
		
		controller.selectedOption = 'OptionOne';
		controller.addTag();
		
		controller.selectedOption = 'OptionThree';
		controller.addTag();
		
		System.assertEquals(4, controller.allOptions.size());
		System.assertEquals(2, controller.getSelectedItems().size());
		System.assertEquals(2, controller.availableOptions.size());
		
		//reset the tags
		controller.resetFilters();
		System.assertEquals(4, controller.allOptions.size());
		System.assertEquals(0, controller.getSelectedItems().size());
		System.assertEquals(4, controller.availableOptions.size());

	}
	

	/*
		Test constructor, initialisation with component params, registerWithFacetedSearchDelegate(), addTag(), 
		removeTag() and getSelectedItems()
		
	*/	
	private static testMethod void TestAddTag()
	{
		TestDelegate delegate = new TestDelegate();
		
		bg_FacetedSearchComponentController controller = new bg_FacetedSearchComponentController();
		controller.searchDelegate = delegate;

		List<SelectOption> allOptions = new List<SelectOption>();
		allOptions.add(new SelectOption('Select a test value', 'Select a test value'));
		allOptions.add(new SelectOption('OptionOne', 'OptionOne'));
		allOptions.add(new SelectOption('OptionTwo', 'OptionTwo'));
		allOptions.add(new SelectOption('OptionThree', 'OptionThree'));		
		
		delegate.allOptions = allOptions;
		
		System.assertEquals(4, controller.availableOptions.size());
		System.assertEquals(null, controller.selectedItems);
		
		// select an option
		String tagToSelect = 'OptionTwo';
		controller.selectedOption = tagToSelect;
		controller.addTag();
		System.assertEquals(4, controller.allOptions.size());
		System.assertEquals(1, controller.getSelectedItems().size());
		System.assertEquals(tagToSelect, controller.getSelectedItems()[0]);
		System.assertEquals(3, controller.availableOptions.size());
		
		// addTag() will have called registerWithFacetedSearchDelegate
		//System.assertEquals(delegate.delegatorKey, 'OpportunityStageName');
		//System.assertEquals(delegate.component, controller);
		
		//remove an option
		controller.tagToRemove = tagToSelect;
		controller.removeTag();
		System.assertEquals(4, controller.allOptions.size());
		System.assertEquals(0, controller.getSelectedItems().size());
		System.assertEquals(4, controller.availableOptions.size());
			
	}
	
	/*
		Automatic properties required for VF, getters for delegate, test the getters
	*/
	private static testmethod void TestAccessors()
	{
		TestDelegate delegate = new TestDelegate();
		bg_FacetedSearchComponentController controller = new bg_FacetedSearchComponentController();
		controller.searchDelegate = delegate;
		// Use Opportunity Stage as there is a good chance of there being data
		controller.objectName = 'Opportunity';
		controller.paramKey = 'StageName';
		
		System.assertEquals('Opportunity', controller.getObjectName());
		System.assertEquals('StageName', controller.getParamKey());
		
	}
/*	
	private static testMethod void TestParamPropertyInvalidField()
	{

		TestDelegate delegate = new TestDelegate();
		
		bg_FacetedSearchComponentController controller = new bg_FacetedSearchComponentController();
		controller.searchDelegate = delegate;
		// Use Opportunity Stage as there is a good chance of there being data 
		controller.objectName = 'Opportunity';
		controller.paramKey = 'Name';
	}
	*/
	/*
	private static testmethod void TestCheckFilterMetadata ()
	{
		TestDelegate delegate = new TestDelegate();
		bg_FacetedSearchComponentController controller = new bg_FacetedSearchComponentController();
		controller.searchDelegate = delegate;
	    Boolean result = controller.checkFilterMetadata ( 'Opportunity', 'StageName');
	    System.assertEquals(true, result);
	    
	    // Try a field that does not exist
	   	Boolean expectedExceptionThrown = false;
	   	try
	   	{
	   		controller.checkFilterMetadata ( 'Opportunity', 'ThisDoesNotExist');
	   	}
	   	catch ( bg_FacetedSearchException fse)
	   	{
         	if (fse.getMessage().contains(Label.bg_Faceted_Search_Invalid_Fleld_Name))
            {
                expectedExceptionThrown = true;
            }	   	
        }
	    System.assertEquals(true, expectedExceptionThrown, 'Expected exception not thrown: ' + Label.bg_Faceted_Search_Invalid_Fleld_Name);
	    
	    // Try a field with an unsupported type
	    expectedExceptionThrown = false;
	   	try
	   	{
	   		controller.checkFilterMetadata ( 'Opportunity', 'Name');
	   	}
	   	catch ( bg_FacetedSearchException fse)
	   	{
         	if (fse.getMessage().contains(Label.bg_Faceted_Search_Invalid_Fleld_Type))
            {
                expectedExceptionThrown = true;
            }
        }
	    System.assertEquals(true, expectedExceptionThrown, 'Expected exception not thrown: ' + Label.bg_Faceted_Search_Invalid_Fleld_Type);
	}
	*/
	
}