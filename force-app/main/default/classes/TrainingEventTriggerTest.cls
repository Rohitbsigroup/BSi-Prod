@isTest(SeeAllData=true)
private class TrainingEventTriggerTest
{
	static testMethod void myUnitTest()
	{

		SystemSetting__c cs = bg_UnitTestHelper.GetSystemSettings();
		cs.SkipValidationRule__c = true;
    	update cs;
		// Create a test Training Course
		Product2 product = new Product2();
		//product.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Training Course').getRecordTypeId();
		product.Name = 'Test Course';
		product.CurrencyIsoCode = 'GBP';
		product.IsActive = true;
		insert product;
		product = [select Id, Name from Product2 where Id = :product.Id];
		System.assertEquals('Test Course', product.Name);
	
		// Create a test Pricebook
		Date myDate = Date.today();
		Pricebook2 pb = new Pricebook2();
		pb.Name = 'Test Pricebook';
		pb.IsActive = true;
		pb.Year__c = String.valueOf(myDate.year());
		insert pb;
		pb = [select Id, Name from Pricebook2 where Id = :pb.Id];
		System.assertEquals('Test Pricebook', pb.Name);
        	
		// Create a standard Pricebook Entry
		Pricebook2 stdPb = [select Id from Pricebook2 where isStandard = true];
        
        // 12/02/2018 ADS - Updates for new Process Builder "Create Price Book Entry for ALL Currencies in Standard Price Book"
        delete [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :stdPb.Id AND Product2Id = :product.Id AND CurrencyIsoCode = 'GBP'];                 
        
		PricebookEntry stdPbe = new PricebookEntry();
		stdPbe.Product2Id = product.Id;
		stdPbe.Pricebook2Id = stdPb.Id;
		stdPbe.IsActive = true;
		stdPbe.CurrencyIsoCode = 'GBP';
        // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry
		// stdPbe.UnitPrice = 10000.00;
		Decimal unitPrice = 0.0;
		stdPbe.UnitPrice = unitPrice;
		stdPbe.UseStandardPrice = false;
		insert stdPbe;
		stdPbe = [select Id, UnitPrice from PricebookEntry where Id = :stdPbe.Id];
        // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry
		// System.assertEquals(10000.00, stdPbe.UnitPrice);
        System.assertEquals(unitPrice, stdPbe.UnitPrice);
	
		// Create a test Pricebook Entry
		PricebookEntry pbe = new PricebookEntry();
		pbe.Product2Id = product.Id;
		pbe.Pricebook2Id = pb.Id;
		pbe.IsActive = true;
		pbe.CurrencyIsoCode = 'GBP';
        // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry
		// pbe.UnitPrice = 10000.00;
		pbe.UnitPrice = unitPrice;
		pbe.UseStandardPrice = false;
		insert pbe;
		pbe = [select Id, UnitPrice from PricebookEntry where Id = :pbe.Id];
        // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry
		// System.assertEquals(10000.00, pbe.UnitPrice);
		System.assertEquals(unitPrice, pbe.UnitPrice);

		Training_Venue__c masterVenue = bg_TrainingUnitTestHelper.createTrainingVenue('Master Venue', 'GBP');
		// Create a training venue
		Training_Venue__c venue = new Training_Venue__c();
		venue.Name = 'Bedford Training Centre';
		venue.Training_Office__c = masterVenue.Id;
		venue.Venue_Street__c = '10 High St.';
		venue.Venue_city__c = 'Bedford';
		venue.Venue_State__c = 'Bedfordshire';
		venue.Venue_Country__c = 'United Kingdom';
		venue.Venue_SAP_Ship_To__c = '47406390';
		insert venue;
		venue = [select Id, Name, Venue_Street__c, Venue_city__c, Venue_State__c, Venue_Country__c, Venue_SAP_Ship_To__c from Training_Venue__c where Id = :venue.Id];
		System.assertEquals('47406390', venue.Venue_SAP_Ship_To__c);

		// Create an instructor
		Contact ins1 = new Contact();
		ins1.FirstName = 'John';
		ins1.LastName = 'Jones';
		ins1.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Instructor').getRecordTypeId();
		ins1.Instructor_SAP_number__c = 1111111;
		ins1.Trainer_Day_Rate__c = 100;
		ins1.Country_Office__c = venue.Id;
		ins1.MailingCountry = 'GB';
		insert ins1;
		ins1 = [select Id, Name, FirstName, LastName, RecordTypeId, Instructor_SAP_number__c from Contact where Id = :ins1.Id];
		System.assertEquals(1111111, ins1.Instructor_SAP_number__c);
		
		// Create an instructor
		Contact ins2 = new Contact();
		ins2.FirstName = 'Bob';
		ins2.LastName = 'Smith';
		ins2.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Instructor').getRecordTypeId();
		ins2.Instructor_SAP_number__c = 2222222;
		ins2.Trainer_Day_Rate__c = 100;
		ins2.Country_Office__c = venue.Id;
		ins2.MailingCountry = 'GB';
		insert ins2;
		ins2 = [select Id, Name, FirstName, LastName, RecordTypeId, Instructor_SAP_number__c from Contact where Id = :ins2.Id];
		System.assertEquals(2222222, ins2.Instructor_SAP_number__c);
		
		// Create an instructor
		Contact ins3 = new Contact();
		ins3.FirstName = 'Mike';
		ins3.LastName = 'Wells';
		ins3.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Instructor').getRecordTypeId();
		ins3.Instructor_SAP_number__c = 3333333;
		ins3.Trainer_Day_Rate__c = 100;
		ins3.Country_Office__c = venue.Id;
		ins3.MailingCountry = 'GB';
		insert ins3;
		ins3 = [select Id, Name, FirstName, LastName, RecordTypeId, Instructor_SAP_number__c from Contact where Id = :ins3.Id];
		System.assertEquals(3333333, ins3.Instructor_SAP_number__c);
		
		// Create a test Training Event
		Training_Event__c trainingEvent = new Training_Event__c();
		trainingEvent.RecordTypeId = Schema.SObjectType.Training_Event__c.getRecordTypeInfosByName().get('Global Training Event').getRecordTypeId();
		trainingEvent.Course__c = product.Id;
		trainingEvent.Training_Venue__c = venue.Id;
		trainingEvent.Delivery_Language__c = 'English';
		trainingEvent.Max_seats__c = 100;
		trainingEvent.CurrencyIsoCode = 'GBP';
		trainingEvent.SAP_SMO_number__c = '1234567';
		trainingEvent.Start_Date__c = Date.valueOf('2012-01-01');
		trainingEvent.Trainer__c = ins1.Id;
		trainingEvent.Trainer_2nd__c = ins2.Id;
		trainingEvent.Instructor_3rd__c = ins3.Id;
		trainingEvent.Event_status__c = 'Active';
		insert trainingEvent;
		trainingEvent = [select Id, RecordTypeId, Course__c, Training_Venue__c, Delivery_Language__c, Max_seats__c, CurrencyIsoCode, SAP_SMO_number__c, Start_Date__c, Trainer__c,/* Trainer_2nd__c,*/ Instructor_3rd__c, Event_status__c/*, SMO_Ship_to__c, SMO_Instructor_2__c*/ from Training_Event__c where Id = :trainingEvent.Id];
		System.assertEquals(100, trainingEvent.Max_seats__c);
	
		// Change training event
		trainingEvent.Start_Date__c = Date.valueOf('2013-01-01');
		// Reset the flag so that it will run again
		TrainingEventTriggerHandler.firstRun = true;
		update trainingEvent;
		trainingEvent = [select Id, RecordTypeId, Course__c, Training_Venue__c, Delivery_Language__c, Max_seats__c, CurrencyIsoCode, SAP_SMO_number__c, Start_Date__c, Trainer__c,/* Trainer_2nd__c,*/ Instructor_3rd__c, Event_status__c/*, SMO_Ship_to__c, SMO_Instructor_2__c*/ from Training_Event__c where Id = :trainingEvent.Id];
		System.assertEquals(Date.valueOf('2013-01-01'), trainingEvent.Start_Date__c);
	}
}