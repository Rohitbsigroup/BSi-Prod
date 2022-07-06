/*
*          RJ 01-06-2014 Updated to use getTestSalesUser
*/
@isTest
private class LeadConversionScoreCalcTest {
	
	private static ConversionScore__c buildConversionScores(string name) {
		
		ConversionScore__c cs=new ConversionScore__c();
		cs.Name=name;
		cs.AreaOfInterestDoubleSelection__c=10;
		cs.AreaOfInterestEntropy__c=null;
		cs.AreaOfInterestSingleSelection__c=5;
		cs.BudgetAllocated__c=20;
		cs.CompanyNo__c=5;
		cs.DeliveryExpBand1__c=-1;
		cs.DeliveryExpBand1Max__c=2;
		cs.DeliveryExpBand1Min__c=0;
		cs.DeliveryExpBand2__c=10;
		cs.DeliveryExpBand2Max__c=4;
		cs.DeliveryExpBand2Min__c=1;
		cs.DeliveryExpBand3__c=20;
		cs.DeliveryExpBand3Max__c=7;
		cs.DeliveryExpBand3Min__c=3;
		cs.DeliveryExpBand4__c=10;
		cs.DeliveryExpBand4Max__c=13;
		cs.DeliveryExpBand4Min__c=6;
		cs.DeliveryExpBand5__c=5;
		cs.DeliveryExpBand5Max__c=9999;
		cs.DeliveryExpBand5Min__c=5;
		cs.DriverSpecified__c=20;
		cs.DriversTenders__c=10;
		cs.ExistingRegistrations__c=20;
		cs.ImplementationStarted__c=20;
		cs.LeadSourceBPM__c=30;
		cs.LeadSourceBSI__c=20;
		cs.LeadSourcePG__c=30;
		cs.NoOfEmployeeBand1__c=10;
		cs.NoOfEmployeeBand1Max__c=101;
		cs.NoOfEmployeeBand1Min__c=-1;
		cs.NoOfEmployeeBand2__c=156;
		cs.NoOfEmployeeBand2Max__c=2001;
		cs.NoOfEmployeeBand2Min__c=100;
		cs.NoOfEmployeeBand3__c=500;
		cs.NoOfEmployeeBand3Max__c=999999;
		cs.NoOfEmployeeBand3Min__c=2000;
		cs.NoOfEmployeeBand4__c=null;
		cs.NoOfEmployeeBand4Max__c=null;
		cs.NoOfEmployeeBand4Min__c=null;
		cs.NoOfEmployeeBand5__c=null;
		cs.NoOfEmployeeBand5Max__c=null;
		cs.NoOfEmployeeBand5Min__c=null;
		cs.NoOfSitesBand1__c=10;
		cs.NoOfSitesBand1Max__c=2;
		cs.NoOfSitesBand1Min__c=0;
		cs.NoOfSitesBand2__c=105;
		cs.NoOfSitesBand2Max__c=4;
		cs.NoOfSitesBand2Min__c=1;
		cs.NoOfSitesBand3__c=250;
		cs.NoOfSitesBand3Max__c=9999;
		cs.NoOfSitesBand3Min__c=3;
		cs.NoOfSitesBand4__c=null;
		cs.NoOfSitesBand4Max__c=null;
		cs.NoOfSitesBand4Min__c=null;
		cs.NoOfSitesBand5__c=null;
		cs.NoOfSitesBand5Max__c=null;
		cs.NoOfSitesBand5Min__c=null;
		cs.PositionDecisionMaker__c=10;
		cs.PositionInfluencer__c=10;
		cs.PreviousCustomer__c=10;
		cs.ProductAreaDoubleSelection__c=10;
		cs.ProductAreaSingleSelection__c=5;
		cs.Transfer__c=50;
		return cs;
	}

    static testMethod void testBasicScore() {
        
       	ConversionScore__c cs = buildConversionScores('AD');
       	insert cs;
       	
        User u = TestData.getTestStandardUser('BobSales', bg_UserUtils.PROFILE_NAME_BSI_SALESPERSON);

        Lead lead;
		
		Test.startTest();
		 
        System.runAs(u) {
            System.debug('Current User: ' + UserInfo.getUserName());
            System.debug('Current Profile: ' + UserInfo.getProfileId());
        
            lead = TestData.getTestLead();
            lead.Country='AD';
            lead.Position__c=null;
            insert lead;
            
            lead=[SELECT Id, ConversionScore__c FROM Lead WHERE Id = :lead.Id];
        	//system.assertEquals(265, lead.ConversionScore__c);// was 285
            
            lead.Position__c='Influencer';
            lead.PortfolioInterestArea2__c='anything';
            lead.ProductArea__c='Entropy';
            update lead;
            
            lead=[SELECT Id, ConversionScore__c FROM Lead WHERE Id = :lead.Id];
        	//system.assertEquals(285, lead.ConversionScore__c); // was 305
            
            lead.ProductArea2__c='anything';
            update lead;
            
            lead=[SELECT Id, ConversionScore__c FROM Lead WHERE Id = :lead.Id];
        	//system.assertEquals(290, lead.ConversionScore__c); // was 310
        }
        
        Test.stopTest();
    }
    
    static testMethod void testNoScore() {
        
        User u = TestData.getTestStandardUser('BobSales', bg_UserUtils.PROFILE_NAME_BSI_SALESPERSON);

        Lead lead;
		
		Test.startTest();
		 
        System.runAs(u) {
            System.debug('Current User: ' + UserInfo.getUserName());
            System.debug('Current Profile: ' + UserInfo.getProfileId());
        
            lead = TestData.getTestLead();
            lead.Country='AD';
            lead.Position__c=null;
            insert lead;
        }
        
        Test.stopTest();
        
        lead=[SELECT Id, ConversionScore__c FROM Lead WHERE Id = :lead.Id];
        system.assertEquals(null, lead.ConversionScore__c, 'No score setup for AD');
    }
}