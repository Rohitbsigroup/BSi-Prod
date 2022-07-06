/********************************************************************
 * bg_ApexPageUtils.cls
 *
 * Helper methods for apex page functionality
 * 
 * Test class at bg_ApexPageUtils_Test
 *
 * Author: Kieran Maguire
 * Created: 19-02-2016
 * Changes: 
 *          
 ********************************************************************/
public class bg_ApexPageUtils 
{
	/*
		Adds an error message to the page
	*/
	public static void AddErrorMessageToPage(String errorMessage)
	{
		AddMessageToPage(ApexPages.Severity.Error, errorMessage);
	}

	/*
		Adds a message to the page
	*/
	public static void AddMessageToPage(ApexPages.severity severity, String errorMessage)
	{
		ApexPages.AddMessage(new ApexPages.Message(severity, errorMessage));
	}
}