/********************************************************************
 * bg_ProjectUtils
 *
 * Utility methods to support Project functions
 *
 *
 * Author: Ian Bowman
 * Created: 18-07-2017
 * Changes:  
 *			CB 07-08-2017 - Added GetProjectsById
 *********************************************************************/
public with sharing class bg_ProjectUtils {
	
	public static Map<ID, Project__c> GetProjectForAccount(ID accountID, Boolean active)
	{
		Map<ID, Project__c> projectMap = new Map<ID, Project__c>([SELECT Id, Name, Active__c, Account__c, 
											 Area_of_Practice__c, Project_End_Date__c, Project_Family__c, Project_Name__c, 
											 Project_Start_Date__c,  Project_Status__c, Project_Template__c FROM Project__c
												WHERE Active__c = :active AND Account__c = :accountID]);
									 
		return projectMap;
	}

	public static Map<ID, Project__c> GetProjectsById(Set<Id> projectIds)
	{
		Map<ID, Project__c> projectMap = new Map<ID, Project__c>([SELECT Id, 
																		 Name, 
																		 Active__c, 
																		 Account__c, 
											 							 Area_of_Practice__c, 
											 							 Project_End_Date__c, 
											 							 Project_Family__c, 
											 							 Project_Name__c, 
											 							 Project_Start_Date__c,  
											 							 Project_Status__c, 
											 							 Project_Template__c ,
											 							 RecordType.Name
									 							  FROM Project__c
																  WHERE Id IN :projectIds]);
									 
		return projectMap;
	}
    
}