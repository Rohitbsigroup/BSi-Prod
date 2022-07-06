/********************************************************************
 * bg_DateUtilsTest
 *
 * Test class for bg_DateUtils
 * 
 * 
 * Author: Richard Jimenez
 * Created: 26-01-2015
 * Changes: 
 * 
 ********************************************************************/
@isTest
private class bg_DateUtilsTest {

	private static testMethod void testConvertStringToDate() {
		date testDate = date.newInstance(2015, 1, 27);

		system.assertEquals(testDate, bg_DateUtils.ConvertStringToDate('27 JAN 2015', bg_DateUtils.DATEFORMAT_01));
		system.assertEquals(testDate, bg_DateUtils.ConvertStringToDate('2015-01-27', bg_DateUtils.DATEFORMAT_01));
		system.assertEquals(testDate, bg_DateUtils.ConvertStringToDate('2015-01-27', 'ANYTHING'));
	}
}