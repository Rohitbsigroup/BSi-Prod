/********************************************************************
 * bg_FacetedSearchDelegate
 *
 * An interface that allows a controller to act as the Search Delegate
 * and call methods on the interface bg_FacetedSearchComponent on 
 * the registered component(s)
 * 
 * Author: Ian Bowman
 * Created: 12/06/17
 * Changes:  
 *
 ********************************************************************/

public interface bg_FacetedSearchDelegate {
                   
    void addSearchComponent(String delegatorKey, bg_FacetedSearchComponent component); // delegator key allows the delegate to act for several delegates at once
    List<SelectOption> getAllOptions(String objectName, String fieldName);
    
}