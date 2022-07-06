/********************************************************************
 * bg_FacetedSearchComponent
 *
 * Test class: NA
 * Author: Ian Bowman
 * Created: 12/06/17
 * Changes:  
 *
 * An interface that allows a component controller to register itself with a class that implements the 
 * Faceted Search Delegate Interface so that the Delegate can call back. Each component is responsible for
 * presenting the values of one field to be used in a filtered search and maintaining the values selected by the user.
 *
 ********************************************************************/


public interface bg_FacetedSearchComponent {
     
    /*
    	Return the list of currently selected options
    */              
    List<String> getSelectedItems();
    
    /*
    	Return the list of currently selected options
    */              
    void setSelectedItems(List<String> items);
    /*
    	Clear the currently selected options
    */
    void resetFilters();
    /*
    	Return the API name of the object that contains the field
    */
    String getObjectName();
    /*
    	Return the API name of the field that we are filtering on
    */
	String getParamKey();
    
}