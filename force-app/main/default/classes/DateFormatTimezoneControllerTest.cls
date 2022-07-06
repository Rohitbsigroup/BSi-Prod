/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         09/05/2012
* Description:  TEST CLASS: DateFormatTimezoneController
*
* ------------------
* TESTING:		100%
* ------------------
*          RJ 01-06-2014 Updated to use getTestSalesUser     
**/
@isTest
private class DateFormatTimezoneControllerTest {

    static testMethod void dateFormattingTest() {
        User testuser = TestData.getTestSalesUser();
		insert testuser;

        DateFormatTimezoneController controller = new DateFormatTimezoneController();
        controller.dateTimeFormat = DateTime.now();
        controller.receiverId = testUser.Id;
        controller.getTimeZoneDateTime();
    }
}