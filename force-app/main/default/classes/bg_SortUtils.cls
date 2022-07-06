/********************************************************************
 * bg_SortUtils
 *
 * Utility methods for column sort functionality
 *
 * Test Class : bg_SortUtilsTest
 *
 * 
 * Author: Nick Fisher
 * Created: 09-12-2014 
 ********************************************************************/
public class bg_SortUtils 
{
	public static integer getSortResult(string val1, string val2, boolean orderAsc) {
		/* Return Comparable - getSortResult for strings  */
    	if (val1 == val2) return 0;
    	if(orderAsc) {
    		if (val1 > val2) return 1;
    	} else {
    		if (val1 < val2) return 1;
    	}
    	return -1;			
	}
	
	public static integer getSortResult(date val1, date val2, boolean orderAsc) {
		/* Return Comparable - getSortResult for Dates  */
		if(val1 == null) { val1 = Date.newInstance(1900, 1, 1); }
		if(val2 == null) { val2 = Date.newInstance(1900, 1, 1); }
				
    	if (val1 == val2) return 0;
    	if(orderAsc) {
    		if (val1 > val2) return 1;
    	} else {
    		if (val1 < val2) return 1;
    	}
    	return -1;			
	}

	public static integer getSortResult(integer val1, integer val2, boolean orderAsc) {
		/* Return Comparable - getSortResult for Integers  */		
    	if (val1 == val2) return 0;
    	if(orderAsc) {
    		if (val1 > val2) return 1;
    	} else {
    		if (val1 < val2) return 1;
    	}
    	return -1;			
	}
	
	public static integer getSortResult(datetime val1, datetime val2, boolean orderAsc) {
		/* Return Comparable - getSortResult for Datetimes  */
		if(val1 == null) { val1 = DateTime.newInstance(1900, 1, 1); }
		if(val2 == null) { val2 = DateTime.newInstance(1900, 1, 1); }

    	if (val1 == val2) return 0;
    	if(orderAsc) {
    		if (val1 > val2) return 1;
    	} else {
    		if (val1 < val2) return 1;
    	}
    	return -1;			
	}
	
	public static integer getSortResult(boolean val1, boolean val2, boolean orderAsc) {
		/* Return Comparable - getSortResult for Booleans  */
    	if (val1 == val2) return 0;
    	if(orderAsc) {
    		if (integer.valueOf(val1) > integer.valueOf(val2)) return 1;
    	} else {
    		if (integer.valueOf(val1) < integer.valueOf(val2)) return 1;
    	}
    	return -1;			
	}				
}