public with sharing class LeadConversionScoreCalc {
	
	private static decimal checkNull(decimal value) {
		if (value==null) {
			return 0;
		} else {
			return value;
		}
	}
	
	public static void calcConvScore(List<Lead> newLeads) {
		/*
		method receives a list of leads and calculates the score
		from the custom setting based on the Country code of the assigned territry
		*/
		
		for (Lead lead:newLeads) {
			if (lead.Country==null) continue;//this is a required field 
			ConversionScore__c cs=ConversionScore__c.getInstance(lead.Country);
			if (cs==null) {
				lead.ConversionScore__c=-1; 
				continue;
			}
			
			system.debug('cs...' + cs);
			
			decimal score=0;
			
			if (lead.Position__c=='Influencer') score+=checkNull(cs.PositionInfluencer__c);
			if (lead.Position__c=='Decision Maker') score+=checkNull(cs.PositionDecisionMaker__c);
			system.debug('cs...Position__c...' + score);
			
			if (lead.CoRegNo__c!=null||lead.CharityRegNo__c!=null) score+=checkNull(cs.CompanyNo__c);
			system.debug('cs...CoRegNo__c...' + score);
			
			//No of Employee
			system.debug('TotalEmployees__c...' + lead.TotalEmployees__c);
			if (cs.NoOfEmployeeBand1Min__c!=null&&cs.NoOfEmployeeBand1Max__c!=null) {
				if (lead.TotalEmployees__c>cs.NoOfEmployeeBand1Min__c&&lead.TotalEmployees__c<cs.NoOfEmployeeBand1Max__c) score+=checkNull(cs.NoOfEmployeeBand1__c);
			}
			if (cs.NoOfEmployeeBand2Min__c!=null&&cs.NoOfEmployeeBand2Max__c!=null) {
				if (lead.TotalEmployees__c>cs.NoOfEmployeeBand2Min__c&&lead.TotalEmployees__c<cs.NoOfEmployeeBand2Max__c) score+=checkNull(cs.NoOfEmployeeBand2__c);
			}
			if (cs.NoOfEmployeeBand3Min__c!=null&&cs.NoOfEmployeeBand3Max__c!=null) {
				if (lead.TotalEmployees__c>cs.NoOfEmployeeBand3Min__c&&lead.TotalEmployees__c<cs.NoOfEmployeeBand3Max__c) score+=checkNull(cs.NoOfEmployeeBand3__c);
			}
			if (cs.NoOfEmployeeBand4Min__c!=null&&cs.NoOfEmployeeBand4Max__c!=null) {
				if (lead.TotalEmployees__c>cs.NoOfEmployeeBand4Min__c&&lead.TotalEmployees__c<cs.NoOfEmployeeBand4Max__c) score+=checkNull(cs.NoOfEmployeeBand4__c);
			}
			if (cs.NoOfEmployeeBand5Min__c!=null&&cs.NoOfEmployeeBand5Max__c!=null) {
				if (lead.TotalEmployees__c>cs.NoOfEmployeeBand5Min__c&&lead.TotalEmployees__c<cs.NoOfEmployeeBand5Max__c) score+=checkNull(cs.NoOfEmployeeBand5__c);
			}
			system.debug('cs...EmployeeNumber__c...' + score);
			
			//No of Sites
			if (cs.NoOfSitesBand1Min__c!=null&&cs.NoOfSitesBand1Max__c!=null) {
				if (lead.SitesNumber__c>cs.NoOfSitesBand1Min__c&&lead.SitesNumber__c<cs.NoOfSitesBand1Max__c) score+=checkNull(cs.NoOfSitesBand1__c);
			}
			if (cs.NoOfSitesBand2Min__c!=null&&cs.NoOfSitesBand2Max__c!=null) {
				if (lead.SitesNumber__c>cs.NoOfSitesBand2Min__c&&lead.SitesNumber__c<cs.NoOfSitesBand2Max__c) score+=checkNull(cs.NoOfSitesBand2__c);
			}
			if (cs.NoOfSitesBand3Min__c!=null&&cs.NoOfSitesBand3Max__c!=null) {
				if (lead.SitesNumber__c>cs.NoOfSitesBand3Min__c&&lead.SitesNumber__c<cs.NoOfSitesBand3Max__c) score+=checkNull(cs.NoOfSitesBand3__c);
			}
			if (cs.NoOfSitesBand4Min__c!=null&&cs.NoOfSitesBand4Max__c!=null) {
				if (lead.SitesNumber__c>cs.NoOfSitesBand4Min__c&&lead.SitesNumber__c<cs.NoOfSitesBand4Max__c) score+=checkNull(cs.NoOfSitesBand4__c);
			}
			if (cs.NoOfSitesBand5Min__c!=null&&cs.NoOfSitesBand1Max__c!=null) {
				if (lead.SitesNumber__c>cs.NoOfSitesBand5Min__c&&lead.SitesNumber__c<cs.NoOfSitesBand5Max__c) score+=checkNull(cs.NoOfSitesBand5__c);
			}
			system.debug('cs...SitesNumber__c...' + score);
			
			if (lead.PortfolioInterestArea__c!=null&&lead.PortfolioInterestArea2__c==null) {//single selection
				score+=checkNull(cs.AreaOfInterestSingleSelection__c);
			} else if (lead.PortfolioInterestArea__c!=null&&lead.PortfolioInterestArea2__c!=null) {//double selection
				score+=checkNull(cs.AreaOfInterestDoubleSelection__c);
			}
			system.debug('cs...PortfolioAreaOfInterest__c...' + score);
			
			if (lead.ProductArea__c!=null&&lead.ProductArea2__c==null) {//single selection
				score+=checkNull(cs.ProductAreaSingleSelection__c);
			} else if (lead.ProductArea__c!=null&&lead.ProductArea2__c!=null) {//double selection
				score+=checkNull(cs.ProductAreaDoubleSelection__c);
			}
			system.debug('cs...ProductArea__c...' + score);
			
			if (lead.ProductArea__c=='Entropy'||lead.ProductArea2__c=='Entropy') score+=checkNull(cs.AreaOfInterestEntropy__c);
			system.debug('cs...Entropy...' + score);
			
			if (lead.PortfolioInterestArea__c=='Healthcare Medical Devices'||lead.PortfolioInterestArea2__c=='Healthcare Medical Devices') score+=checkNull(cs.ProductIsHealthcare__c);
			system.debug('cs...Healthcare...' + score);
			
			if (lead.Drivers__c=='Specified Requirement from existing customer') score+=checkNull(cs.DriverSpecified__c);
			if (lead.Drivers__c=='Tenders') score+=checkNull(cs.DriversTenders__c);
			if (lead.Drivers__c=='Business Growth') score+=checkNull(cs.DriversBusiness__c);
			if (lead.Drivers__c=='Quality') score+=checkNull(cs.DriversQuality__c);
			if (lead.Drivers__c=='Internal') score+=checkNull(cs.DriversInternal__c);
			system.debug('cs...Drivers__c...' + score);
			
			if (lead.Existing_Registrations__c) score+=checkNull(cs.ExistingRegistrations__c);
			system.debug('cs...Existing_Registrations__c...' + score);
			
			if (lead.RegistrationPath__c=='Transfer') score+=checkNull(cs.Transfer__c);
			system.debug('cs...Transfer__c...' + score);
			
			if (lead.ImplementationStarted__c=='Yes') score+=checkNull(cs.ImplementationStarted__c);
			system.debug('cs...ImplementationStarted__c...' + score);
			
			if (lead.BudgetAllocated__c=='Yes') score+=checkNull(cs.BudgetAllocated__c);
			system.debug('cs...BudgetAllocated__c...' + score);
			
			if (lead.PrevCustomer__c == 'Yes') score+=checkNull(cs.PreviousCustomer__c);
			system.debug('cs...PreviousCustomer__c...' + score);

			if (lead.LeadSource=='PG') score+=checkNull(cs.LeadSourcePG__c);			
			if (lead.LeadSource=='BPM') score+=checkNull(cs.LeadSourceBPM__c);
			if (lead.LeadSource=='Self Generated') score+=checkNull(cs.LeadSourceBSI__c);
			system.debug('cs...LeadSource...' + score);
			
			if (lead.Delivery__c!=null) { 
				integer numberDays=system.today().monthsBetween(lead.Delivery__c);
				system.debug('numberDays...' + numberDays);
				
				if (cs.DeliveryExpBand1Min__c!=null&&cs.DeliveryExpBand1Max__c!=null) {
					if (numberDays>cs.DeliveryExpBand1Min__c&&numberDays<cs.DeliveryExpBand1Max__c) score+=checkNull(cs.DeliveryExpBand1__c);
				}
				if (cs.DeliveryExpBand2Min__c!=null&&cs.DeliveryExpBand2Max__c!=null) {
					if (numberDays>cs.DeliveryExpBand2Min__c&&numberDays<cs.DeliveryExpBand2Max__c) score+=checkNull(cs.DeliveryExpBand2__c);
				}
				if (cs.DeliveryExpBand3Min__c!=null&&cs.DeliveryExpBand3Max__c!=null) {
					if (numberDays>cs.DeliveryExpBand3Min__c&numberDays<cs.DeliveryExpBand3Max__c) score+=checkNull(cs.DeliveryExpBand3__c);
				}
				if (cs.DeliveryExpBand4Min__c!=null&&cs.DeliveryExpBand4Max__c!=null) {
					if (numberDays>cs.DeliveryExpBand4Min__c&&numberDays<cs.DeliveryExpBand4Max__c) score+=checkNull(cs.DeliveryExpBand4__c);
				}
				if (cs.DeliveryExpBand5Min__c!=null&&cs.DeliveryExpBand1Max__c!=null) {
					if (numberDays>cs.DeliveryExpBand5Min__c&&numberDays<cs.DeliveryExpBand5Max__c) score+=checkNull(cs.DeliveryExpBand5__c);
				}
			}
			system.debug('cs...Delivery__c...' + score);

			system.debug('score...' + score);
			
			lead.ConversionScore__c=score;
		}
	}

}