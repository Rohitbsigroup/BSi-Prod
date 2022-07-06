/********************************************************************
 * bg_DateUtils
 *
 * Apex utilities for date functionality
 * 
 * Unit Tests: bg_DateUtilsTEST
 *
 * Author: Richard Jimenez
 * Created: 26-01-2014
 * Changes: 
 ********************************************************************/
public class bg_DateUtils {

	// List of date formats
	public static final string DATEFORMAT_01 = 'DD MMM YYYY';
	// EXAMPLE: public static final string DATEFORMAT_02 = 'DD MMM YYYY';
	
	public static map<string, integer> MonthsMap = new map<string, integer>();
    static {
        MonthsMap.put('JAN', 1);
		MonthsMap.put('FEB', 2);
		MonthsMap.put('MAR', 3);
		MonthsMap.put('APR', 4);
		MonthsMap.put('MAY', 5);
		MonthsMap.put('JUN', 6);
		MonthsMap.put('JUL', 7);
		MonthsMap.put('AUG', 8);
		MonthsMap.put('SEP', 9);
		MonthsMap.put('OCT', 10);
		MonthsMap.put('NOV', 11);
		MonthsMap.put('DEC', 12);        
    }

    public static date ConvertStringToDate(string strDate, string dateformat) {
    	try {
			if(dateformat == DATEFORMAT_01) {
				return ConvertStringToDate_1(strDate);
			} else {
				// default date parser
				return date.parse(strDate);
			}
    	} catch (Exception ex) {
    		return date.valueOf(strDate);
    	}
    }
        
    public static date ConvertStringToDate_1(string strDate) {
    	/*
    		Convert string to date 'DD MMM YYYY'
    	*/
    	string[] dateParts = strDate.split(' ');
    	return date.newInstance(integer.valueOf(dateParts[2]), MonthsMap.get(dateParts[1].toUpperCase()), integer.valueOf(dateParts[0])); 
    }
}