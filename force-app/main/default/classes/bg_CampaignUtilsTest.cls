/********************************************************************
 * bg_CampaignUtilsTest
 *
 * Test methods for Campaign Utility class
 * 
 * Author: Rob Earey
 * Created: 16-10-2013
 * Changes: 
 ********************************************************************/
@isTest 
private class bg_CampaignUtilsTest 
{
	public static testMethod void TestRollup1()
	{	
		// Test of single parent and child relationship and roll up to parent
		//set up parent campaign
		Campaign camP = bg_UnitTestHelper.GetCampaign('RollupP');
		//set up child campaign
		Campaign camC = bg_UnitTestHelper.GetCampaign('RollupC', camP.Id);
		//set up values on child campaign
		camC.Expected_Leads__c = 10;
		camC.ExpectedRevenue = 1000;
		camC.ExpectedResponse = 25.0;
		camC.BudgetedCost = 2000;
		camC.ActualCost = 4000;
		// update child campaign
		update camC;
		//query back the parent campaign
		Campaign camCheck = [SELECT id, Name, Expected_Leads__c, ExpectedRevenue, ExpectedResponse, BudgetedCost, ActualCost, 
							  Total_Expected_Leads__c, Total_Expected_Revenue__c, Average_Expected_Response__c, Total_Budgeted_Cost__c,
							   Total_Actual_Cost__c 
							 FROM Campaign 
							 WHERE id=:camP.Id];
		//check the parent values					 
		System.assertEquals(10,camCheck.Total_Expected_Leads__c);
		System.assertEquals(1000,camCheck.Total_Expected_Revenue__c);
		System.assertEquals(12.5,camCheck.Average_Expected_Response__c);
		System.assertEquals(2000,camCheck.Total_Budgeted_Cost__c);
		System.assertEquals(4000,camCheck.Total_Actual_Cost__c);											 	
	}
	
	public static testMethod void TestRollup2()
	{	
		// Test of single parent and multi child relationship and roll up to parent
		//set up parent campaign
		Campaign camP = bg_UnitTestHelper.GetCampaign('RollupP');
		//set up child campaign #1
		Campaign camC1 = bg_UnitTestHelper.GetCampaign('RollupC1', camP.Id);
		//set up values on child campaign #1
		camC1.Expected_Leads__c = 15;
		camC1.ExpectedRevenue = 1000;
		camC1.ExpectedResponse = 20.0;
		camC1.BudgetedCost = 2500;
		camC1.ActualCost = 4500;
		// update child campaign
		update camC1;
		//set up child campaign #2
		Campaign camC2 = bg_UnitTestHelper.GetCampaign('RollupC2', camP.Id);
		//set up values on child campaign #2
		camC2.Expected_Leads__c = 19;
		camC2.ExpectedRevenue = 2000;
		camC2.ExpectedResponse = 25.0;
		camC2.BudgetedCost = 2000;
		camC2.ActualCost = 4000;
		// update child campaign
		update camC2;
		//query back the parent campaign
		Campaign camCheck = [SELECT id, Name, Expected_Leads__c, ExpectedRevenue, ExpectedResponse, BudgetedCost, ActualCost, 
							  Total_Expected_Leads__c, Total_Expected_Revenue__c, Average_Expected_Response__c, Total_Budgeted_Cost__c,
							   Total_Actual_Cost__c 
							 FROM Campaign 
							 WHERE id=:camP.Id];
		//check the parent values					 
		System.assertEquals(34,camCheck.Total_Expected_Leads__c);
		System.assertEquals(3000,camCheck.Total_Expected_Revenue__c);
		System.assertEquals(15,camCheck.Average_Expected_Response__c);
		System.assertEquals(4500,camCheck.Total_Budgeted_Cost__c);
		System.assertEquals(8500,camCheck.Total_Actual_Cost__c);											 	
	}
	
	public static testMethod void TestRollup3()
	{	
		// Test of single parent and multi child relationship and roll up to parent followed by a child deletion
		//set up parent campaign
		Campaign camP = bg_UnitTestHelper.GetCampaign('RollupP');
		//set up child campaign #1
		Campaign camC1 = bg_UnitTestHelper.GetCampaign('RollupC1', camP.Id);
		//set up values on child campaign #1
		camC1.Expected_Leads__c = 15;
		camC1.ExpectedRevenue = 1000;
		camC1.ExpectedResponse = 20.0;
		camC1.BudgetedCost = 2500;
		camC1.ActualCost = 4500;
		// update child campaign
		update camC1;
		//set up child campaign #2
		Campaign camC2 = bg_UnitTestHelper.GetCampaign('RollupC2', camP.Id);
		//set up values on child campaign #2
		camC2.Expected_Leads__c = 19;
		camC2.ExpectedRevenue = 2000;
		camC2.ExpectedResponse = 25.0;
		camC2.BudgetedCost = 2000;
		camC2.ActualCost = 4000;
		// update child campaign
		update camC2;
		//query back the parent campaign
		Campaign camCheck = [SELECT id, Name, Expected_Leads__c, ExpectedRevenue, ExpectedResponse, BudgetedCost, ActualCost, 
							  Total_Expected_Leads__c, Total_Expected_Revenue__c, Average_Expected_Response__c, Total_Budgeted_Cost__c,
							   Total_Actual_Cost__c 
							 FROM Campaign 
							 WHERE id=:camP.Id];
		//check the parent values					 
		System.assertEquals(34,camCheck.Total_Expected_Leads__c);
		//delete the first child Campaign
		delete camC1;
		//query back the parent campaign
		Campaign camCheck2 = [SELECT id, Name, Expected_Leads__c, ExpectedRevenue, ExpectedResponse, BudgetedCost, ActualCost, 
							  Total_Expected_Leads__c, Total_Expected_Revenue__c, Average_Expected_Response__c, Total_Budgeted_Cost__c,
							   Total_Actual_Cost__c 
							 FROM Campaign 
							 WHERE id=:camP.Id];
		System.assertEquals(19,camCheck2.Total_Expected_Leads__c);		
		System.assertEquals(2000,camCheck2.Total_Expected_Revenue__c);
		System.assertEquals(12.5,camCheck2.Average_Expected_Response__c);
		System.assertEquals(2000,camCheck2.Total_Budgeted_Cost__c);
		System.assertEquals(4000,camCheck2.Total_Actual_Cost__c);											 	
	}
	
}