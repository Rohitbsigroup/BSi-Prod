@isTest
public with sharing class CiTestUtility
{
	public static CI_Account__c createTestAccount(string uniqueId)
	{
		CI_Account__c testAccount = new CI_Account__c();
		testAccount.Account_Id__c = uniqueId;
		testAccount.Cluster_Owner__c = 'UK';
		testAccount.Country_Owner__c = 'UK';
		testAccount.Current_Holdings__c = 'Product Certification';
		testAccount.Location_s__c = 'United Kingdom';
		testAccount.Name = 'Test CI Account';
		testAccount.Region_Owner__c = 'EMEA';
		testAccount.Sector__c = 'Wholesale / Retail';
		testAccount.SIC_Code__c = '5072';
		testAccount.SIC_Description__c = 'Hardware';
		testAccount.Size_Employees__c = '21 to 49';
		testAccount.Spend_Band__c = '£3,000-£10,000';	
		insert testAccount;

		// Get current object 
		testAccount = [
			SELECT	s.Id, 
					s.Account_Id__c,
					s.Cluster_Owner__c,
					s.Country_Owner__c,
					s.Current_Holdings__c,
					s.Location_s__c,
					s.Name,
					s.Region_Owner__c,
					s.Sector__c,
					s.SIC_Code__c,
					s.SIC_Description__c,
					s.Size_Employees__c,
					s.Spend_Band__c,
					s.COI_Count__c,
					s.COI_Risk__c
			FROM	CI_Account__c s
    		WHERE 	s.Id = :testAccount.Id];
    		
		return testAccount;
	}

	public static CI_Site__c createTestSite(CI_Account__c testAccount, string uniqueId)
	{
		CI_Site__c testSite = new CI_Site__c();
		testSite.CI_Account__c = testAccount.Id;
		testSite.City__c = 'London';
		testSite.Country__c = 'United Kingdom';
		testSite.Country_Code__c = 'GB';
		testSite.Current_Holdings__c = 'Product Certification';
		testSite.Fax__c = '0208 996 9001';
		testSite.Geocoding__c = '';
		testSite.Location__Latitude__s = 51.49079;
		testSite.Location__Longitude__s = -0.273457;
		testSite.Live_Customer_Type__c = 'Retained';
		testSite.Name = 'Test CI Site';
		testSite.Phone__c = '0208 996 9000';
		testSite.Postcode__c = 'W4 4AL';
		testSite.Product_Count__c = 'Multi Product';
		testSite.Region__c = '';
		testSite.Rev_Customer_Type__c = 'Retained';
		testSite.Sector__c = 'Wholesale / Retail';
		testSite.SIC_Code__c = '5072';
		testSite.SIC_Description__c = 'Hardware';
		testSite.Site_Id__c = uniqueId;
		testSite.Size_Employees__c = '21 to 49';
		testSite.Spend_Band__c = '£3,000-£10,000';
		testSite.Street__c = '389 Chiswick High Rd.';
		testSite.Web_Address__c = 'http://www.bsigroup.com';	
		insert testSite;

		// Get current object 
		testSite = [
			SELECT	s.Id, 
					s.CI_Account__c,
					s.City__c,
					s.Country__c,
					s.Country_Code__c,
					s.Current_Holdings__c,
					s.Fax__c,
					s.Geocoding__c,
					s.Location__Latitude__s,
					s.Location__Longitude__s,
					s.Live_Customer_Type__c,
					s.Name,
					s.Phone__c,
					s.Postcode__c,
					s.Product_Count__c,
					s.Region__c,
					s.Rev_Customer_Type__c,
					s.Sector__c,
					s.SIC_Code__c,
					s.SIC_Description__c,
					s.Site_Id__c,
					s.Size_Employees__c,
					s.Spend_Band__c,
					s.Street__c,
					s.Web_Address__c,
					s.COI_Count__c,
					s.COI_Risk__c
			FROM	CI_Site__c s
    		WHERE 	s.Id = :testSite.Id];
    		
		return testSite;
	}

	public static CI_Contact__c createTestContact(CI_Site__c testSite, string uniqueId)
	{
		CI_Contact__c testCont = new CI_Contact__c();
		testCont.CI_Account__c = testSite.CI_Account__c;
		testCont.CI_Site__c = testSite.Id;
		testCont.City__c = 'London';
		testCont.Contact_Id__c = uniqueId;
		testCont.Country__c = 'United Kingdom';
		testCont.Country_Code__c = 'GB';
		testCont.Email__c = 'test@test.com';
		testCont.Fax__c = '0208 996 9001';
		testCont.First_Name__c = 'Test';
		testCont.Job_Title__c = 'Test Title';
		testCont.Last_Name__c = 'Contact';
		testCont.Name = 'Test Contact';
		testCont.Phone__c = '0208 996 9000';
		testCont.Postcode__c = 'W4 4AL';
		testCont.Region__c = '';
		testCont.Street__c = '386 Chiswick High Rd';
		testCont.Title__c = 'Mr';
		insert testCont;
		
		testCont = [
			SELECT	s.Id,
					s.CI_Account__c,
					s.CI_Site__c,
					s.City__c,
					s.Contact_Id__c,
					s.Country__c,
					s.Country_Code__c,
					s.Email__c,
					s.Fax__c,
					s.First_Name__c,
					s.Job_Title__c,
					s.Last_Name__c,
					s.Name,
					s.Phone__c,
					s.Postcode__c,
					s.Region__c,
					s.Street__c,
					s.Title__c
			FROM	CI_Contact__c s
			WHERE	s.Id = :testCont.Id];
			
		return testCont;
	}

	public static CI_Assessor__c createTestAssessor(string uniqueId)
	{
		CI_Assessor__c testAssessor = new CI_Assessor__c();
		testAssessor.Name = 'Test Assessor';
		testAssessor.AssessorId__c = uniqueId;
		testAssessor.Job_Title__c = 'Client Manager';
		testAssessor.Cost_Centre__c = '9999';
		testAssessor.Location__Latitude__s = 51.49079;
		testAssessor.Location__Longitude__s = -0.273457;
		insert testAssessor;

		// Get current object 
		testAssessor = [
			SELECT	a.Id, 
					a.Name,
					a.AssessorId__c,
					a.Job_Title__c,
					a.Cost_Centre__c
			FROM	CI_Assessor__c a
    		WHERE 	a.Id = :testAssessor.Id];
    		
		return testAssessor;
	}
		
	public static CI_Certificate__c createTestCertificate(CI_Account__c testAcc, string uniqueId)
	{
		CI_Certificate__c testCert = new CI_Certificate__c();
		testCert.Certificate_Id__c = uniqueId;
		testCert.CI_Account__c = testAcc.Id;
		testCert.Expiry_Date__c = date.newInstance(2010, 1, 1);
		testCert.Name = 'FM12345'; 
		testCert.Portfolio__c = 'Quality';
		testCert.Product__c = 'ISO900';
		testCert.Re_issue_Date__c = date.newInstance(2050, 1, 1);
		testCert.Status__c = 'Active';
		testCert.COI_Risk__c = true;
		insert testCert;

		// Get current object 
		testCert = [
			SELECT	s.Id, 
					s.Certificate_Id__c,
					s.CI_Account__c,
					s.Company__c,
					s.Expiry_Date__c,
					s.Name,
					s.Portfolio__c,
					s.Product__c,
					s.Re_issue_Date__c,
					s.Status__c,
					s.COI_Risk__c
					
			FROM	CI_Certificate__c s
    		WHERE 	s.Id = :testCert.Id];
    		
		return testCert;		
	}

	public static CI_Certificate_Site__c createTestCertificateSite(CI_Certificate__c testCert, CI_Site__c testSite, string uniqueId)
	{
		CI_Certificate_Site__c testCertSite = new CI_Certificate_Site__c();
		testCertSite.CI_Certificate__c = testCert.Id;
		testCertSite.CI_Site__c = testSite.Id;
		testCertSite.Measuring_Point_Id__c = uniqueId;
		testCertSite.Name = 'FM12355/JGJGJ-92173972131-000';
		testCertSite.Status__c = 'Active';
		testCertSite.COI_Risk__c = true;
		insert testCertSite;

		// Get current object 
		testCertSite = [
			SELECT	s.Id, 
					s.CI_Certificate__c,
					s.CI_Site__c,
					s.Measuring_Point_Id__c,
					s.Name,
					s.Status__c,
					s.COI_Risk__c
			FROM	CI_Certificate_Site__c s
    		WHERE 	s.Id = :testCertSite.Id];
    		
		return testCertSite;		
	}
	
	public static CI_Visit__c createTestVisit(CI_Certificate_Site__c testCertSite, string uniqueId)
	{
		CI_Visit__c testVis = new CI_Visit__c();
		testVis.Assessors__c = 'John Smith';
		testVis.CI_Certificate_Site__c = testCertSite.Id;
		testVis.CI_Site__c = testCertSite.CI_Site__c;
		testVis.End_Date__c = date.today();
		testVis.Job_Type__c = 'CAV';
		testVis.Name = 'CAV';
		testVis.SMO_Number__c = uniqueId;
		testVis.Start_Date__c = date.today();
		testVis.Status__c = 'Booked'; 
    	testVis.Order_Type__c = 'BS02';
		insert testVis;
		
		// Get current object 
		testVis = [
			SELECT	s.Id, 
					s.Assessors__c,
					s.CI_Certificate_Site__c,
					s.CI_Site__c,
					s.End_Date__c,
					s.Job_Type__c,
					s.Name,
					s.SMO_Number__c,
					s.Start_Date__c,
					s.Status__c,
					s.Order_Type__c
			FROM	CI_Visit__c s
    		WHERE 	s.Id = :testVis.Id];
    		
		return testVis;		
	}
		
	public static Training_Venue__c createTestTrainingVenue()
	{
		Training_Venue__c testVen = new Training_Venue__c();
		testVen.Name = 'Master Test Venue';
		List<RecordType> recTypes = [select Id from RecordType where sObjectType = 'Training_Venue__c' and developerName = 'Public'];
		if (!recTypes.isEmpty()) {
			testVen.RecordTypeId = recTypes[0].Id;
			testVen.Public_Venue__c = true;
		} else {
			testVen.Public_Venue__c = false;
		}
		testVen.Location__Latitude__s = 51.49079;
		testVen.Location__Longitude__s = -0.273457;
		testVen.Geocoding__c = '';
		insert testVen;

		// Get current object 
		testVen = [
			SELECT	s.Id,					 
					s.Name,
					s.RecordTypeId,
					s.Public_Venue__c,
					s.Location__Latitude__s,
					s.Location__Longitude__s,
					s.Geocoding__c
			FROM	Training_Venue__c s
    		WHERE 	s.Id = :testVen.Id];
    		
		return testVen;		
	}
	
	public static Training_Event__c createTestTrainingEvent(Training_Venue__c testVen)
	{
		// Setup new product
		Product2 prd1 = new Product2();
		List<RecordType> recTypes1 = [select Id from RecordType where sObjectType = 'Product2' and developerName = 'Training Course'];
		if (!recTypes1.isEmpty()) prd1.RecordTypeId = recTypes1[0].Id;
		prd1.Name = 'Test Product1';
		prd1.Course_Name_English__c = 'Test Course1';
		insert prd1;

		// Setup an event
		Training_Event__c evt = new Training_Event__c();
		List<RecordType> recTypes2 = [select Id from RecordType where sObjectType = 'Training_Event__c' and developerName = 'Global Training Event'];
		if (!recTypes2.isEmpty()) evt.RecordTypeId = recTypes2[0].Id;
		evt.Course__c = prd1.Id;
		evt.Start_date__c = date.today();
		evt.Duration_Days__c = 10;
		evt.Max_seats__c = 10;
		evt.Delivery_Language__c = 'English';
		evt.Training_Venue__c = testVen.Id;
		insert evt;
		
		return evt;
	}

	public static HttpResponse createTestResponse()
	{
		// Build XML
		XmlStreamWriter wtr = new XmlStreamWriter();

		wtr.writeStartDocument('utf-8','1.0');
			wtr.writeStartElement(null, 'GeocodeResponse', null);
				wtr.writeStartElement(null, 'status', null);
					wtr.writeCharacters('OK');
				wtr.writeEndElement();		
				wtr.writeStartElement(null, 'result', null);
					wtr.writeStartElement(null, 'geometry', null);
						wtr.writeStartElement(null, 'location', null);
							wtr.writeStartElement(null, 'lat', null);
								wtr.writeCharacters('37.4188514');
							wtr.writeEndElement();		
							wtr.writeStartElement(null, 'lng', null);
								wtr.writeCharacters('-122.0874526');
							wtr.writeEndElement();		
						wtr.writeEndElement();		
					wtr.writeEndElement();		
				wtr.writeEndElement();		
			wtr.writeEndElement();
		wtr.writeEndDocument();

	    HttpResponse res = new HttpResponse();
	    res.setStatus('OK');
	    res.setBody(wtr.getXmlString());
		return res;
	}
}