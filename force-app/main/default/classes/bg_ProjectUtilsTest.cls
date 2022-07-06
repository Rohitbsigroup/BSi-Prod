/********************************************************************
 * bg_ProjectUtilsTest
 *
 * Test methods for Project Utility class
 * 
 * 
 * Author: Ian Bowman
 * Created: 18-07-2017
 * Changes: 
 *		   05/09/2017 CPE	Created test methods 
 ********************************************************************/
@isTest
private class bg_ProjectUtilsTest 
{
    /*
    	Test for GetProjectForAccount
    	Null Account Id
    */
    static testMethod void testGetProjectForAccountNull()
    {
    	Boolean activeProjectFlag = true;
    	Account testAccount = bg_UnitTestHelper.GetAccount('Project Tests Account');
    	Integer projectCount = 5;
    	List<Project__c> testProjects = new List<Project__c>();
    	for (Integer iterator=0; iterator<projectCount; iterator++)
    	{
    		Project__c testProject = bg_UnitTestHelper.CreateProject(testAccount.Id, 'Test Project Name - ' + iterator, activeProjectFlag);
    		testProjects.add(testProject);
    	}
    	insert testProjects;
    	
    	Id accountId;

    	Map<Id, Project__c> results;
    	
    	results = bg_ProjectUtils.GetProjectForAccount(accountId, activeProjectFlag);
    	
		system.assertEquals(false, results == null);
		system.assertEquals(true, results.isEmpty());    	
    }


    /*
    	Test for GetProjectForAccount
    	No Projects
    */
    static testMethod void testGetProjectForAccountNoProjects()
    {
    	Boolean activeProjectFlag = true;
    	Account testAccount = bg_UnitTestHelper.GetAccount('Project Tests Account');
    	
    	Id accountId = testAccount.Id;

    	Map<Id, Project__c> results;
    	
    	results = bg_ProjectUtils.GetProjectForAccount(accountId, activeProjectFlag);
    	
		system.assertEquals(false, results == null);
		system.assertEquals(true, results.isEmpty());    	
    }    
    
    /*
    	Test for GetProjectForAccount
    	Active Projects
    */
    static testMethod void testGetProjectForAccountActive()
    {
    	Boolean activeProjectFlag = true;
    	Account testAccount = bg_UnitTestHelper.GetAccount('Project Tests Account');
    	Integer projectCount = 5;
    	List<Project__c> testProjectsActive = new List<Project__c>();
    	for (Integer iterator=0; iterator<projectCount; iterator++)
    	{
    		Project__c testProject = bg_UnitTestHelper.CreateProject(testAccount.Id, 'Test Project Name - ' + iterator, true);
    		testProjectsActive.add(testProject);
    	}
    	insert testProjectsActive;


    	List<Project__c> testProjectsInActive = new List<Project__c>();
    	for (Integer iterator=0; iterator<projectCount; iterator++)
    	{
    		Project__c testProject = bg_UnitTestHelper.CreateProject(testAccount.Id, 'Test Project Name - ' + iterator, false);
    		testProjectsInActive.add(testProject);
    	}
    	insert testProjectsInActive;
    	
    	Id accountId = testAccount.Id;

    	Map<Id, Project__c> results;
    	
    	results = bg_ProjectUtils.GetProjectForAccount(accountId, activeProjectFlag);
    	Map<Id, Project__c> resultsMap = new Map<Id, Project__c>();
    	resultsMap.putAll(results); 
    	
		system.assertEquals(false, results == null);
		system.assertEquals(false, results.isEmpty());
		system.assertEquals(projectCount, results.size());
		for (Project__c testProject : testProjectsActive)
		{
			system.assertEquals(true, resultsMap.containsKey(testProject.Id));
		}    	
		for (Project__c testProject : testProjectsInActive)
		{
			system.assertEquals(false, resultsMap.containsKey(testProject.Id));
		}    	
    }


    /*
    	Test for GetProjectForAccount
    	InActive Projects
    */
    static testMethod void testGetProjectForAccountInActive()
    {
    	Boolean activeProjectFlag = false;
    	Account testAccount = bg_UnitTestHelper.GetAccount('Project Tests Account');
    	Integer projectCount = 5;
    	List<Project__c> testProjectsActive = new List<Project__c>();
    	for (Integer iterator=0; iterator<projectCount; iterator++)
    	{
    		Project__c testProject = bg_UnitTestHelper.CreateProject(testAccount.Id, 'Test Project Name - ' + iterator, true);
    		testProjectsActive.add(testProject);
    	}
    	insert testProjectsActive;


    	List<Project__c> testProjectsInActive = new List<Project__c>();
    	for (Integer iterator=0; iterator<projectCount; iterator++)
    	{
    		Project__c testProject = bg_UnitTestHelper.CreateProject(testAccount.Id, 'Test Project Name - ' + iterator, false);
    		testProjectsInActive.add(testProject);
    	}
    	insert testProjectsInActive;
    	
    	Id accountId = testAccount.Id;

    	Map<Id, Project__c> results;
    	
    	results = bg_ProjectUtils.GetProjectForAccount(accountId, activeProjectFlag);
    	Map<Id, Project__c> resultsMap = new Map<Id, Project__c>();
    	resultsMap.putAll(results); 
    	
		system.assertEquals(false, results == null);
		system.assertEquals(false, results.isEmpty());
		system.assertEquals(projectCount, results.size());
		for (Project__c testProject : testProjectsActive)
		{
			system.assertEquals(false, resultsMap.containsKey(testProject.Id));
		}    	
		for (Project__c testProject : testProjectsInActive)
		{
			system.assertEquals(true, resultsMap.containsKey(testProject.Id));
		}    	
    }

    /*
    	Test for GetProjectForAccount
    	Active Projects - only inactive exists
    */
    static testMethod void testGetProjectForAccountNoActive()
    {
    	Boolean activeProjectFlag = true;
    	Account testAccount = bg_UnitTestHelper.GetAccount('Project Tests Account');
    	Integer projectCount = 5;

    	List<Project__c> testProjectsInActive = new List<Project__c>();
    	for (Integer iterator=0; iterator<projectCount; iterator++)
    	{
    		Project__c testProject = bg_UnitTestHelper.CreateProject(testAccount.Id, 'Test Project Name - ' + iterator, false);
    		testProjectsInActive.add(testProject);
    	}
    	insert testProjectsInActive;
    	
    	Id accountId = testAccount.Id;

    	Map<Id, Project__c> results;
    	
    	results = bg_ProjectUtils.GetProjectForAccount(accountId, activeProjectFlag);
    	Map<Id, Project__c> resultsMap = new Map<Id, Project__c>();
    	resultsMap.putAll(results); 
    	
		system.assertEquals(false, results == null);
		system.assertEquals(true, results.isEmpty());
    }

    /*
    public static Map<ID, Project__c> GetProjectsById(Set<Id> projectIds)
    */
	
    /*
    	Test for GetProjectsById
    	Empty projectId list
    */
    static testMethod void testGetProjectsByIdNull()
    {
    	Account testAccount = bg_UnitTestHelper.GetAccount('Project Tests Account');
    	Integer projectCount = 5;
    	List<Project__c> testProjects = new List<Project__c>();
    	for (Integer iterator=0; iterator<projectCount; iterator++)
    	{
    		Project__c testProject = bg_UnitTestHelper.CreateProject(testAccount.Id, 'Test Project Name - ' + iterator, true);
    		testProjects.add(testProject);
    	}
    	insert testProjects;
    	
    	Set<Id> projectIds;

    	Map<Id, Project__c> results;
    	
    	results = bg_ProjectUtils.GetProjectsById(projectIds);
    	
		system.assertEquals(false, results == null);
		system.assertEquals(true, results.isEmpty());    	
    }

    /*
    	Test for GetProjectsById
    	Single projectId 
    */
    static testMethod void testGetProjectsByIdSingle()
    {
    	Account testAccount = bg_UnitTestHelper.GetAccount('Project Tests Account');
    	Integer projectCount = 5;
    	List<Project__c> testProjects = new List<Project__c>();
    	for (Integer iterator=0; iterator<projectCount; iterator++)
    	{
    		Project__c testProject = bg_UnitTestHelper.CreateProject(testAccount.Id, 'Test Project Name - ' + iterator, true);
    		testProjects.add(testProject);
    	}
    	insert testProjects;
    	
    	Set<Id> projectIds = new Set<Id>();
		
		projectIds.add(testProjects[0].Id);
		
    	Map<Id, Project__c> results;
    	
    	results = bg_ProjectUtils.GetProjectsById(projectIds);
    	
		system.assertEquals(false, results == null);
		system.assertEquals(false, results.isEmpty());
		system.assertEquals(1, results.size());
		system.assertEquals(true, results.containsKey(testProjects[0].Id));    	
    }
    
    /*
    	Test for GetProjectsById
    	Multi projectIds 
    */
    static testMethod void testGetProjectsByIdMultiple()
    {
    	Account testAccount = bg_UnitTestHelper.GetAccount('Project Tests Account');
    	Integer projectCount = 5;
    	List<Project__c> testProjects = new List<Project__c>();
    	for (Integer iterator=0; iterator<projectCount; iterator++)
    	{
    		Project__c testProject = bg_UnitTestHelper.CreateProject(testAccount.Id, 'Test Project Name - ' + iterator, true);
    		testProjects.add(testProject);
    	}
    	insert testProjects;

    	List<Project__c> testProjectsInActive = new List<Project__c>();
    	for (Integer iterator=0; iterator<projectCount; iterator++)
    	{
    		Project__c testProject = bg_UnitTestHelper.CreateProject(testAccount.Id, 'Test Project Name - ' + iterator, false);
    		testProjectsInActive.add(testProject);
    	}
    	insert testProjectsInActive;
    	    	
    	Map<Id, Project__c> projectIds = new Map<Id, Project__c>();
		
		projectIds.putAll(testProjects);
		
    	Map<Id, Project__c> results;
    	
    	results = bg_ProjectUtils.GetProjectsById(projectIds.keySet());
    	
		system.assertEquals(false, results == null);
		system.assertEquals(false, results.isEmpty());
		system.assertEquals(projectCount, results.size());
		for (Project__c project : testProjects)
		{
			system.assertEquals(true, results.containsKey(project.Id));
		}
		for (Project__c project : testProjectsInActive)
		{
			system.assertEquals(false, results.containsKey(project.Id));
		}
    }    



}