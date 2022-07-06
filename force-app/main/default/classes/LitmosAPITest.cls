@IsTest(SeeAllData=True)
private class LitmosAPITest {
    static testmethod void mymethod(){      
       try
       {
/* MD - TEST DATA NOT NEEDED?
            //Create a test E-LLearning Training Course
            Product2 product = new Product2();
            product.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Training Course').getRecordTypeId();
            product.Name = 'Test Course E-Learning';
            product.CurrencyIsoCode = 'GBP';
            product.IsActive = true;
            product.TrainingTaxonomyCode__c = 'OLE001';
            product.Delivery_Method__c = 'E-Learning';
            product.ProductArea__c = 'Training';
            insert product;
            product = [select Id, Name from Product2 where Id = :product.Id];
            System.assertEquals('Test Course E-Learning', product.Name);
           
           // Create a test Blended Training Course
            Product2 product2 = new Product2();
            product2.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Training Course').getRecordTypeId();
            product2.Name = 'Test Course Blended';
            product2.CurrencyIsoCode = 'GBP';
            product2.IsActive = true;
            product2.Delivery_Method__c = 'Blended Learning';
            product.ProductArea__c = 'Training';
            insert product2;
            product2 = [select Id, Name from Product2 where Id = :product2.Id];
            System.assertEquals('Test Course Blended', product2.Name);
  
  
        
            // Create a test Pricebook
            Pricebook2 pb = new Pricebook2();
            pb.Name = 'Test Pricebook';
            pb.IsActive = true;
            pb.Year__c = '2017';
            insert pb;
            pb = [select Id, Name from Pricebook2 where Id = :pb.Id];
            System.assertEquals('Test Pricebook', pb.Name);
      
            // Create a standard Pricebook Entry for eLearning
            Pricebook2 stdPb = [select Id from Pricebook2 where IsStandard  = true limit 1];
            PricebookEntry stdPbe = new PricebookEntry();
            stdPbe.Product2Id = product.Id;
            stdPbe.Pricebook2Id = stdPb.Id;
            stdPbe.IsActive = true;
            stdPbe.CurrencyIsoCode = 'GBP';
            stdPbe.UnitPrice = 0;
            stdPb.Year__c = '2017';
            stdPbe.UseStandardPrice = false;
            insert stdPbe;
            stdPbe = [select Id, UnitPrice from PricebookEntry where Id = :stdPbe.Id];
            System.assertEquals(0, stdPbe.UnitPrice);
        
            // Create a standard Pricebook Entry for Blended
            Pricebook2 stdPb2 = [select Id from Pricebook2 where IsStandard  = true limit 1];
            PricebookEntry stdPbe2 = new PricebookEntry();
            stdPbe2.Product2Id = product2.Id;
            stdPbe2.Pricebook2Id = stdPb.Id;
            stdPbe2.IsActive = true;
            stdPbe2.CurrencyIsoCode = 'GBP';
            stdPbe2.UnitPrice = 0;
            stdPb2.Year__c='2017';
            stdPbe2.UseStandardPrice = false;
            insert stdPbe2;
            stdPbe2 = [select Id, UnitPrice from PricebookEntry where Id = :stdPbe2.Id];
            System.assertEquals(0, stdPbe2.UnitPrice);
      
            // Create a test Pricebook Entry for eLearning
           PricebookEntry pbe = new PricebookEntry();
            pbe.Product2Id = product.Id;
            pbe.Pricebook2Id = pb.Id;
            pbe.IsActive = true;
            pbe.CurrencyIsoCode = 'GBP';
            pbe.UnitPrice = 200;
            pbe.UseStandardPrice = false;
            insert pbe;
            pbe = [select Id, UnitPrice from PricebookEntry where Id = :pbe.Id];
            System.assertEquals(200, pbe.UnitPrice);
            
            // Create a test Pricebook Entry for Blended
            PricebookEntry pbe2 = new PricebookEntry();
            pbe2.Product2Id = product2.Id;
            pbe2.Pricebook2Id = pb.Id;
            pbe2.IsActive = true;
            pbe2.CurrencyIsoCode = 'GBP';
            pbe2.UnitPrice = 200;
            pbe2.UseStandardPrice = false;
            insert pbe2;
            pbe2 = [select Id, UnitPrice from PricebookEntry where Id = :pbe2.Id];
            System.assertEquals(200, pbe2.UnitPrice);
        
            system.debug('*** CREATE TRAINING VENUE ***');
            Training_Venue__c masterVenue = bg_TrainingUnitTestHelper.createTrainingVenue('Master Venue', 'GBP');
            // Create a training venue
            RecordType inHouseRecordType = [SELECT Id, Name     FROM RecordType WHERE sObjectType = 'Training_Venue__c' AND Name = 'Public' LIMIT 1]; 
            
            Training_Venue__c venue = new Training_Venue__c();
            venue.RecordTypeId = inHouseRecordType.id;
            venue.Training_Office__c = mastervenue.id;
            venue.Name = 'Bedford Training Centre';
            venue.Venue_Street__c = '10 High St.';
            venue.Venue_city__c = 'Bedford';
            venue.Venue_State__c = 'Bedfordshire';
            venue.Venue_Country__c = 'UK';
            venue.Venue_SAP_Ship_To__c = '47406390';
            
            venue.Public_Venue__c = true;
            insert venue;
            venue = [select Id, Name, Venue_Street__c, Venue_city__c, Venue_State__c, Venue_Country__c, Venue_SAP_Ship_To__c from Training_Venue__c LIMIT 1];
            //System.assertEquals('Bedford Training Centre', venue.Name );
            system.debug('*** DONE CREATE TRAINING VENUE ***');
    
            // Create an instructor
            system.debug('*** CREATE INSTRUCTOR ***');
            Contact ins1 = new Contact();
            ins1.FirstName = 'John';
            ins1.LastName = 'Jones';
            ins1.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Instructor').getRecordTypeId();
            ins1.Instructor_SAP_number__c = 1111111;
            ins1.Trainer_Day_Rate__c = 100;
            ins1.MailingCountry = 'GB';
            insert ins1;
            ins1 = [select Id, Name, FirstName, LastName, RecordTypeId, Instructor_SAP_number__c from Contact limit 1];
            //System.assertEquals('John', ins1.FirstName);
            system.debug('*** DONE CREATE INSTRUCTOR ***');
        
            // Create a test eLearning Training Event
            Training_Event__c trainingEvent = new Training_Event__c();
            trainingEvent.RecordTypeId = Schema.SObjectType.Training_Event__c.getRecordTypeInfosByName().get('Global Training Event').getRecordTypeId();
            trainingEvent.Course__c = product.Id;
            trainingEvent.Training_Venue__c = venue.Id;
            trainingEvent.Delivery_Language__c = 'English';
            trainingEvent.Max_seats__c = 100;
            trainingEvent.CurrencyIsoCode = 'GBP';
            trainingEvent.Start_Date__c = Date.valueOf('2018-01-01');
            trainingEvent.Trainer__c = ins1.Id;
            trainingEvent.Event_status__c = 'Active';
            insert trainingEvent;
            trainingEvent = [select Id, RecordTypeId, Course__c, Training_Venue__c, Delivery_Language__c, Max_seats__c, Start_Date__c, Trainer__c, Event_status__c from Training_Event__c where Id = :trainingEvent.Id];
            System.assertEquals(100, trainingEvent.Max_seats__c);
            system.debug('*** DONE CREATE TRAINING EVENT 1 ***');   
           
            // Create a test Blended Training Event
            Training_Event__c trainingEvent2 = new Training_Event__c();
            trainingEvent2.RecordTypeId = Schema.SObjectType.Training_Event__c.getRecordTypeInfosByName().get('Global Training Event').getRecordTypeId();
            trainingEvent2.Course__c = product2.Id;
            trainingEvent2.Training_Venue__c = venue.Id;
            trainingEvent2.Delivery_Language__c = 'English';
            trainingEvent2.Max_seats__c = 100;
            trainingEvent2.CurrencyIsoCode = 'GBP';
            trainingEvent2.Start_Date__c = Date.valueOf('2018-01-01');
            trainingEvent2.Trainer__c = ins1.Id;
            trainingEvent2.Event_status__c = 'Active';
            insert trainingEvent2;
            trainingEvent2 = [select Id, RecordTypeId, Course__c, Training_Venue__c, Delivery_Language__c, Max_seats__c, Start_Date__c, Trainer__c, Event_status__c from Training_Event__c where Id = :trainingEvent2.Id];
            System.assertEquals(100, trainingEvent2.Max_seats__c);   
            system.debug('*** DONE CREATE TRAINING EVENT 2 ***');   
            // Create a test Account
            Account account = new Account();
            account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
            account.Name = 'Test Account';
            account.CurrencyIsoCode = 'GBP';
            account.Local_City__c = 'Test';
            account.Local_State__c = 'Test';
            account.Local_Country__c = 'GB';
            account.BillingCountry = 'GB';
            account.BillingState = 'PO';
            account.BillingPostalCode = 'TS1 4BS';
            account.BillingStreet = 'North End Road 2B';
            insert account;
            account = [select Id, Name from Account where Id = :account.Id];
            System.assertEquals('Test Account', account.Name);
            system.debug('*** DONE CREATE ACCOUNT ***');    
           
            //Create a test Contact for the Account
            Contact delegate = new Contact();
            delegate.FirstName = 'John';
            delegate.LastName = 'Jones';
            delegate.Phone = '12345667';
            delegate.MobilePhone = '123456';
            delegate.MailingCountry = 'GB';
            
            delegate.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Account Contacts').getRecordTypeId();
            delegate.Email = 'VG.azad@bsigroup.com';
            delegate.AccountId = account.id;
            
            insert delegate;
            delegate = [select Id, Name, FirstName, LastName, Email from Contact where Id = :delegate.Id];
            //System.assertEquals('VG.azad@bsigroup.com', delegate.Email);
            system.debug('*** DONE CREATE DELEGATE ***');   
           
            // Create a test Opportunity
            Opportunity opp = new Opportunity();
            //opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Training Only Opportunity').getRecordTypeId();
            opp.Name = 'Test ELearning Opportunity';
            opp.AccountId = account.Id;
            opp.CurrencyIsoCode = 'GBP';
            opp.Amount = 1111;
            opp.StageName = '9 - Closed won';
            opp.Probability = 100;
            opp.CloseDate = System.today();
            insert opp;
            opp = [select Id, Name, StageName, Probability, IsWon, IsClosed, CurrencyIsoCode from Opportunity where Id = :opp.Id];
            System.assertEquals('9 - Closed won', opp.StageName);
            
        
            system.debug('*** CREATE OPP LINE ITEM ***');
            // Add test OpportunityLineItems
            OpportunityLineItem item1 = new OpportunityLineItem();
            item1.OpportunityId = opp.Id;
            item1.Training_Event__c = trainingEvent.Id;
            item1.PricebookEntryId = pbe.Id;
            item1.TotalPrice = 1.00;
            item1.Quantity = 1;
            insert item1;
            item1 = [select Id, TotalPrice, CurrencyIsoCode from OpportunityLineItem where Id = :item1.Id];
            System.assertEquals(1.00, item1.TotalPrice);

            system.debug('*** CREATE OPP LINE ITEM 2 ***');
            // Add test OpportunityLineItems2
            OpportunityLineItem item2 = new OpportunityLineItem();
            item2.OpportunityId = opp.Id;
            item2.Training_Event__c = trainingEvent2.Id;
            item2.PricebookEntryId = pbe2.Id;
            item2.TotalPrice = 1.00;
            item2.Quantity = 1;
            insert item2;
            item2 = [select Id, TotalPrice, CurrencyIsoCode from OpportunityLineItem where Id = :item2.Id];
            System.assertEquals(1.00, item2.TotalPrice);
            
            system.debug('*** CREATE ENROLLMENT ***');
            
        
            system.debug('*** OPP ID ***' + opp.id);
            system.debug('*** TrainingEvent ID ***' + trainingEvent.id);
            system.debug('*** Delegate ID ***' + delegate.id);
            system.debug('*** RECORD ID ***' + Schema.SObjectType.Enrollment__c.getRecordTypeInfosByName().get('E-Learning').getRecordTypeId());
        
            // Create Enrolment to eLearning
            Enrollment__c enr1 = new Enrollment__c();
            enr1.RecordTypeId = Schema.SObjectType.Enrollment__c.getRecordTypeInfosByName().get('E-Learning').getRecordTypeId();
            enr1.Opportunity__c = opp.Id;
            enr1.Training_Event__c = trainingEvent.Id;
            enr1.Delegate_name__c = delegate.Id;
            enr1.Accomodation__c = 'Non-Residential';
            Training_Translations__c  tran = new Training_Translations__c ();
            tran = [select id from Training_Translations__c limit 1];
            enr1.Training_Translations__c = tran.id;
            
            enr1.Booking_status__c = 'Booked';
            enr1.Invoice_status__c = 'Pending';
            insert enr1;
            enr1 = [select Id, Booking_status__c from Enrollment__c where Id = :enr1.Id];
            System.assertEquals('Booked', enr1.Booking_status__c); 
            enr1.LitmosAccountCreated__c = true;
            enr1.Online_Training_Assigned__c = true;
    
            // Create Enrolment to Blended
            Enrollment__c enr2 = new Enrollment__c();
            enr2.RecordTypeId = Schema.SObjectType.Enrollment__c.getRecordTypeInfosByName().get('E-Learning').getRecordTypeId();
            enr2.Opportunity__c = opp.Id;
            enr2.Training_Event__c = trainingEvent2.Id;
            enr2.Delegate_name__c = delegate.Id;
            enr2.Accomodation__c = 'Non-Residential';
            Training_Translations__c  tran2 = new Training_Translations__c ();
            tran2 = [select id from Training_Translations__c limit 1];
             enr2.Training_Translations__c = tran2.id;
            //enr2.Training_Translations__c = 'a0VM00000008QFiMAM';
            enr2.Booking_status__c = 'Booked';
            enr2.Invoice_status__c = 'Pending';
            insert enr2;
            enr2 = [select Id, Booking_status__c from Enrollment__c where Id = :enr2.Id];
            System.assertEquals('Booked', enr2.Booking_status__c);  
            
            enr2.LitmosAccountCreated__c = true;
            enr2.Online_Training_Assigned__c = true;
            update enr2;
           
             system.debug('*** CREATE ENROLLMENT DONE ***');
*/
            LitmosAPI LAPI = new LitmosAPI();
            //Test Web Service Build and Response
            LAPI.buildHttpRequest('GET', '');
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            LAPI.handleWebServiceResponse(res);
            System.debug('*** Done WebService TEST***');
           
            //Test Web Service Build and Response
            LAPI.buildHttpRequest('POST', '');
            HttpResponse res1 = new HttpResponse();
            res1.setStatusCode(200);
            LAPI.handleWebServiceResponse(res1);
            System.debug('*** Done WebService Post TEST***');
            
            //Test User Creation
            LAPI.createUser('FirstName','LastName','vimlesh.guptaazad@bsigroup.com','username','company','US','ENG','OA301401ENUK','001', true);
            System.debug('*** CREATE USER TEST DONE ***');
           
            LitmosAPI obj = New LitmosAPI();
            obj.apiKey = 'B6DCCE41-BD77-4F99-9FFA-C102D9B5ADEA'; // BSI Sandbox Dev
            obj.source = 'bsisandboxDev';
            obj.buildHttpRequest('POST', 'Sample Data');
            obj.createUser('FirstName','LastName','vimlesh.guptaazad@bsigroup.com','username','company','US','ENG','OA301401ENUK', '001', true);
            obj.updateUser('123', 'FirstName','LastName','vimlesh.guptaazad@bsigroup.com','username','company','US','ENG', true);
            Http h;
            HttpRequest req;
            HttpResponse ss;
            try{
                obj.getCourseDateCompleted('vimlesh.guptaazad@bsigroup.com','OA301401ENUK',true);
                obj.parseResponse(ss,'testmethod');
            }catch(Exception e){}

            obj.getUserId('vimlesh.guptaazad@bsigroup.com',true);
            obj.getUserStatus('vimlesh.guptaazad@bsigroup.com',true);
            obj.getUserCreatedDate('vimlesh.guptaazad@bsigroup.com',true);
            obj.activateUser('vimlesh.guptaazad@bsigroup.com','FirstName','LastName',true);
            obj.getCourseId('OA301401ENUK',true);
            obj.assignCourse('1xjF9osAXp81','001',true);

            obj.getCoursePercentage('vimlesh.guptaazad@bsigroup.com','OA301401ENUK',true);
            obj.getCourseDateCompleted('vimlesh.guptaazad@bsigroup.com','OA301401ENUK',true);
            obj.getCourseAssignedDate('vimlesh.guptaazad@bsigroup.com','OA301401ENUK',true);
            obj.getCourseCompleted('vimlesh.guptaazad@bsigroup.com','OA301401ENUK',true);
            obj.getCourseDetails('1xjF9osAXp81','OA301401ENUK','001',true);
            obj.removeCourse('vimlesh.guptaazad@bsigroup.com','OA301401ENUK',true);
            obj.getCourseAccessTillDate('vimlesh.guptaazad@bsigroup.com','OA301401ENUK',true);
            obj.getUserLoginKey('vimlesh.guptaazad@bsigroup.com',true);
            obj.updateUser('1xjF9osAXp81', 'FirstName', 'LastName', 'test@test.com', 'username', 'company', 'UK', 'ENG', true);
            obj.getUserDetails('vimlesh.guptaazad@bsigroup.com', true);
           
            //Test Batch
            LitmosBatchUpdate b = new LitmosBatchUpdate(); 
            //b.query = 'SELECT Id,  Online_Training_Complete__c,Online_Training_Completed_Date__c,Online_Training_perc_Complete__c ,LitmosAccountCreated__c,Delegate_name__r.Email,Training_Event__r.Taxonomy__c FROM Enrollment__c WHERE Online_Training_Complete__c = false and LitmosAccountCreated__c = true LIMIT 1';
            Database.executeBatch(b, 1);

        }catch(Exception e){
            System.debug('*** Test Exception *** ' + e.getMessage());
       }
    }

    static testmethod void batchTest(){
        LitmosBatchUpdate obj = new LitmosBatchUpdate();
        //obj.query='SELECT  Online_Training_Complete__c,Online_Training_Completed_Date__c,Online_Training_perc_Complete__c ,LitmosAccountCreated__c,Delegate_name__r.Email,Training_Event__r.Taxonomy__c FROM Enrollment__c WHERE LitmosAccountCreated__c = true and Online_Training_Complete__c = false limit 200'; 

        Test.startTest();
            LitmosAPI li = New LitmosAPI();
            li.apiKey = 'B6DCCE41-BD77-4F99-9FFA-C102D9B5ADEA'; // BSI Sandbox Dev
            li.apiURL = 'https://api.litmos.com/v1.svc/';
            li.source = 'bsisandboxDev';

            Id batchProcessId = Database.executeBatch(obj, 200);
        Test.stopTest();
    
    }
  


    
}