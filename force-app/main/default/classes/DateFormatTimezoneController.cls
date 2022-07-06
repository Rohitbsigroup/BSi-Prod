/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         09/05/2012
* Description:  Apex Component that displays local date time formatting based
* 				on user's locale timezone.
*
*       
**/
public class DateFormatTimezoneController {
	
	public DateTime		dateTimeFormat	{get; set;}
	public Id			receiverId		{get; set;}
	
	public String getTimeZoneDateTime() {
		String userId = receiverId == null ? UserInfo.getUserId() : receiverId;
		User current = [SELECT TimeZoneSidKey,LocaleSidKey FROM User WHERE Id =:userId];
		String formatted = null;
		if (dateTimeFormat != null) formatted = dateTimeFormat.format(Utility.dateFormat.get(current.LocaleSidKey),current.TimeZoneSidKey);
		return formatted;
	}

}