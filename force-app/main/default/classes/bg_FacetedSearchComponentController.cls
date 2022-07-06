/********************************************************************
 * bg_FacetedSearchComponentController
 *
 * Test class: bg_FacetedSearchComponentControllerTest
 * Author: Ian Bowman
 * Created: 12/06/17
 * Changes:  
 *
 ********************************************************************/

public with sharing class bg_FacetedSearchComponentController implements bg_FacetedSearchComponent{
    
    private Boolean registeredWithDelegate = false;  
	public String objectName { get; set; }
	public String getObjectName()
	{
		return objectName;
	}
	
	public String getParamKey()
	{
		return paramKey;
	}
	
	public String tagToRemove {get; 
        set{
            tagToRemove = value;
        }} 
	
	
	public String paramKey { get; set; }


	public bg_FacetedSearchDelegate searchDelegate { get; set; }
	public List<SelectOption> allOptions { 	get 
											{ 
												if(!registeredWithDelegate)
												{
													registerWithFacetedSearchDelegate(searchDelegate);
													registeredWithDelegate = true;
												}
												return searchDelegate.getAllOptions(objectName, paramKey);
											}
		 									set; 
		 								}
	public List<SelectOption> availableOptions { get
													{
														// Rebuild availableOptions every time as allOptions minus currently selected, allOptions can change
														// after each search - the controller could just be presenting values that are in the currently result set
														availableOptions = allOptions.clone();

														if (selectedItems != null && selectedItems.size() != 0 )
														{
															Set<String> selectedItemSet = new Set<String>(selectedItems);
															Integer i = 0;
															List<Integer> optionsToRemove = new List<Integer>();
														
															for (SelectOption so : availableOptions)
															{
																if (selectedItemSet.contains(so.getValue()))
																{
																	optionsToRemove.add(i);
																}
																i++;
															}
														
															for (Integer j = optionsToRemove.size() ; j > 0 ; j-- )
															{
																availableOptions.remove(optionsToRemove.get(j - 1));
															}
														}
														return availableOptions;
													}
													set; 
												}
	
	public List<String> selectedItems { get; set; }
	public String selectedOption {get; set; } 
	
	public bg_FacetedSearchComponentController()
	{
	}
	
	// bg_FacetedSearchComponent interface methods 
	
	
	/*
		The component when added to the page will be aware of the class to act as it's delegate, this method registers
		this instance of the controller with the delegate so that the delegate can call back to invoke the other interface 
		methods and clear or retrieve the filter values
	*/
		
	public void registerWithFacetedSearchDelegate(bg_FacetedSearchDelegate searchDelegate)
	{
		// construct compound key to identify this component, the delegate will need to call back to several delegates
		this.searchDelegate = searchDelegate;
		/** review once components register immediately in all cases */
		String key =  (objectName != null) ? objectName + paramKey : paramKey;
		System.debug('++++ key = ' + key);
		searchDelegate.addSearchComponent(key, this);
	}
	
	/*
		Reset the filters, allows the controller to clear all selected values for this filter
	*/
	public void resetFilters()
	{
		selectedItems = new List<String>();	
	}
	
	/*
		Return all of the filter values currently set
	*/
	public List<String> getSelectedItems()
	{
		return this.selectedItems;
	}
	
	/*
		Return all of the filter values currently set
	*/
	public void setSelectedItems(List<String> items)
	{
		this.selectedItems = items;
	}
	
	// methods to support the component
	
	/*
		Adds a 'tag' to the list of selected filter values and removes it from the list still
		available for selection
	*/
	public void addTag()
	{

		for(integer i=0;i<availableOptions.Size();i++)
		{
			if(availableOptions[i].getValue() == selectedOption)
       		{
            	availableOptions.remove(i);
       		}									
		}			

		if ( selectedItems == null)
		{
			selectedItems = new List<String>();
		}
		//searchDelegate.addSelectOption(objectName, paramKey, selectedOption);
		selectedItems.add(selectedOption);
	}
	
		
	/*
		Allows the removal of a single previously set value for this filter
	*/
	public void removeTag()
    {
    	
    	// remove the first element ( the select filter value ) and save it to be reinserted after sort
    	SelectOption firstItem = availableOptions.get(0);
    	availableOptions.remove(0);
    	
        for(Integer i = 0; i<selectedItems.Size(); i++)
        {
            String tag = selectedItems[i];
            
            if(tag.Equals(tagToRemove))
            {
                selectedItems.remove(i);
                availableOptions.add(new SelectOption(tagToRemove, tagToRemove));
            }
        }
        availableOptions.sort();
        availableOptions.add(0, firstItem);
    }
    
    /*
    	Confirm that the filter metadata is set to a valid field
    	1) Field exists on object
    	2) Field is of the valid types; picklist
    */
    /** @TODO extract to utils class - refactor to relevant controller */
    /*
    @testVisible private Boolean checkFilterMetadata ( String objectName, String paramKey)
    {
    	
    	Boolean isValid = true;
    	// @TODO need to check that this is a picklist field, other valid option would be recordType  
		Schema.SObjectType targetType = Schema.getGlobalDescribe().get(objectName);
		// if the field is a lookup relationship then get just the field name
		String fieldName = (paramKey.lastIndexOf('.') == -1) ? paramKey : paramKey.substring(paramKey.lastIndexOf('.') + 1);
		// @TODO check this is a picklist field type 
		Schema.DescribeSObjectResult objDescribe = targetType.getDescribe();       
		
		map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap(); 
		
		
		if (!fieldMap.containsKey(fieldName))
		{
			// raise an invalid field error
			throw new bg_FacetedSearchException(LAbel.bg_Faceted_Search_Invalid_Fleld_Name);
		}
		Schema.DescribeFieldResult dfr = fieldMap.get(fieldName).getDescribe();
		if (dfr.getType() != Schema.DisplayType.Picklist)
		{
			// raise an invalid field type error
			throw new bg_FacetedSearchException(LAbel.bg_Faceted_Search_Invalid_Fleld_Type);
		}
		
		//list<Schema.PicklistEntry> values = fieldMap.get(fieldName).getDescribe().getPickListValues();
		
		return isValid;
    } 
	*/
}