@isTest
private class TrainingDelegateImportControllerTest {

    @isTest
    static void uploadCSVTest() {

        // Initialise Custom Settings
        bg_UnitTestHelper.SetupCustomSettings();

        User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');
        System.runAs(user1)
        {

            // Set up data
            Training_Venue__c masterVenue = bg_TrainingUnitTestHelper.createTrainingVenue('Master Venue', 'GBP');
            Training_Venue__c tv = bg_TrainingUnitTestHelper.createTrainingVenue(masterVenue,'Training Venue', 'GBP');
            Product2 product = bg_UnitTestHelper.GetProductFee('Test Course');
            Training_Event__c te = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 5, product, Date.today()+5);
            TrainingBooking__c tb = bg_TrainingUnitTestHelper.createTrainingBooking(te, 5);


            Test.setCurrentPage(Page.trainingDelegateImport);
            ApexPages.currentPage().getParameters().put('trainingBookingId', tb.Id);
            TrainingDelegateImportController controller = new TrainingDelegateImportController();
            
            // Upload a test csv
            String testCSV = 'Salutation__c,First_Name__c,Last_Name__c,First_Name_English__c,Last_Name_English__c,Job_Title__c,Email_Address__c,Mobile_Number__c,Social_Security_Number__c,Accommodation_Required__c\r'
                +'Salutation,First Name,Last Name,First Name (English),Last Name (English),Job Title,Email Address,Mobile Number,Social Security Number,Accommodation required?\r'
                +'Test,Test,GB\r'
                +'Test,"Test,Comma",GB\r'
                +'Test,"Test""Doublequote",GB\r'
                +'Test,"Test\nNewline",GB\r';

            Test.startTest();
            controller.docfile.body = Blob.valueOf(testCSV);
            controller.readFile();
            
            System.assertEquals(controller.back().getUrl(),'/' + tb.Id);

            // reason for 9 is that when the booking is created it will automatically create dummy delegate
            // number is base on value passed in createTrainingBooking numberOfDelegate
            system.assertEquals(4,controller.getDelegates().size());

            // Check format Errors
            testCSV = 'Wrongformat;""';
            controller.docfile.body = Blob.valueOf(testCSV);
            controller.readFile();

            system.assertEquals(controller.getDelegates(),null);
            Test.stopTest();
        }
    }

    @isTest
    static void eventDateInPast() {

        // Initialise Custom Settings
        bg_UnitTestHelper.SetupCustomSettings();

        User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');
        System.runAs(user1)
        {

            // Set up data
            Training_Venue__c masterVenue = bg_TrainingUnitTestHelper.createTrainingVenue('Master Venue', 'GBP');
            Training_Venue__c tv = bg_TrainingUnitTestHelper.createTrainingVenue(masterVenue,'Training Venue', 'GBP');
            Product2 product = bg_UnitTestHelper.GetProductFee('Test Course');
            Training_Event__c te = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 5, product, Date.today()-1);
            TrainingBooking__c tb = bg_TrainingUnitTestHelper.createTrainingBooking(te, 5);


            Test.setCurrentPage(Page.trainingDelegateImport);
            ApexPages.currentPage().getParameters().put('trainingBookingId', tb.Id);
            TrainingDelegateImportController controller = new TrainingDelegateImportController();
            
            Test.startTest();
            system.assertEquals(false, controller.canImport);

            Test.stopTest();
        }
    }

    @isTest
    static void validatedDelegatesList() {
        // Initialise Custom Settings
        bg_UnitTestHelper.SetupCustomSettings();

        User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');
        System.runAs(user1)
        {

            // Set up data
            Training_Venue__c masterVenue = bg_TrainingUnitTestHelper.createTrainingVenue('Master Venue', 'GBP');
            Training_Venue__c tv = bg_TrainingUnitTestHelper.createTrainingVenue(masterVenue,'Training Venue', 'GBP');
            Product2 product = bg_UnitTestHelper.GetProductFee('Test Course');
            Training_Event__c te = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 2, product, Date.today()+5);
            TrainingBooking__c tb = bg_TrainingUnitTestHelper.createTrainingBooking(te, 2);
            TrainingDelegate__c td = bg_TrainingUnitTestHelper.createTrainingDelegate(tb, 'John', 'Smith', null, null, null, null, false, null);
            TrainingDelegate__c td1 = bg_TrainingUnitTestHelper.createTrainingDelegate(tb, 'Anna', 'Potter', null, null, null, null, false, null);

            Test.setCurrentPage(Page.trainingDelegateImport);
            ApexPages.currentPage().getParameters().put('trainingBookingId', tb.Id);
            TrainingDelegateImportController controller = new TrainingDelegateImportController();
            
            // Upload a test csv
            String testCSV = 'Salutation__c,First_Name__c,Last_Name__c,First_Name_English__c,Last_Name_English__c,Job_Title__c,Email_Address__c,Mobile_Number__c,Social_Security_Number__c,Accommodation_Required__c\r'
                +'Salutation,First Name,Last Name,First Name (English),Last Name (English),Job Title,Email Address,Mobile Number,Social Security Number,Accommodation required?\r'
                +'Mr,John,Smith,,,Developer,john.smith@company.com,0123456789,123456789,true\r'
                +'Mr,Steve,William,,,Manager,steve.william@company.com,098765432,987654322,false\r';

            Test.startTest();
            controller.docfile.body = Blob.valueOf(testCSV);
            controller.readFile();

            // size of validatedDelegates should be 1 (td1 - td is added as existing for first record in csv) + 2 (from csv) = 6
            system.assertEquals(3,controller.getDelegates().size());

            Integer actionInsert = 0;
            Integer actionUpdate = 0;
            Integer actionDelete = 0;

            for (TrainingDelegateImportController.ValidatedDelegate vd : controller.getDelegates() ) {
                if (vd.delegate != null) {
                    if (vd.action == TrainingDelegateImportController.ACTION_UPDATE) {
                        system.assertEquals(td.id, vd.existingDelegate.id);
                    }
                    if (vd.action == TrainingDelegateImportController.ACTION_DELETE) {
                        system.assertEquals(null, vd.existingDelegate);
                    }
                }

                if (vd.action == TrainingDelegateImportController.ACTION_INSERT) {
                    actionInsert++;
                }

                if (vd.action == TrainingDelegateImportController.ACTION_UPDATE) {
                    actionUpdate++;
                }

                if (vd.action == TrainingDelegateImportController.ACTION_DELETE) {
                    actionDelete++;
                }
            }

            system.assertEquals(1,actionInsert);
            system.assertEquals(1,actionUpdate);
            system.assertEquals(1,actionDelete);

            controller.updateDelegates();

            TrainingBooking__c updatedTb = [Select id, Training_Event__c, Number_of_Delegates__c, Event_Start_Date__c, (
            Select First_Name__c, Last_Name__c, Salutation__c, First_Name_English__c, Last_Name_English__c, Email_Address__c, Job_Title__c, 
                Mobile_Number__c, Social_Security_Number__c, Accommodation_Required__c from Training_Delegates__r) 
            from TrainingBooking__c where id =:tb.id];

            system.assertEquals(2,updatedTb.Training_Delegates__r.size());

            Test.stopTest();
        }
    }

    @isTest
    static void validatedDelegatesListwithAccountAndContact() {
        // Initialise Custom Settings
        bg_UnitTestHelper.SetupCustomSettings();

        User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');
        System.runAs(user1)
        {
            // Set up data

            // Account and contacts
            Account acc = bg_UnitTestHelper.GetAccount('Test Account');
            Contact con = bg_UnitTestHelper.GetContact('Test Contact 1', acc);
            con.Email = 'john.smith@comapny.com';
            update con;

            Contact con1 = bg_UnitTestHelper.GetContact('Test Contact 2', acc);
            con1.Email = 'email2@email.com';
            con1.FirstName = 'Email';
            con1.LastName = 'Email';
            update con1;

            // training data
            Training_Venue__c masterVenue = bg_TrainingUnitTestHelper.createTrainingVenue('Master Venue', 'GBP');
            Training_Venue__c tv = bg_TrainingUnitTestHelper.createTrainingVenue(masterVenue,'Training Venue', 'GBP');
            Product2 product = bg_UnitTestHelper.GetProductFee('Test Course');
            Training_Event__c te = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 2, product, Date.today()+5);
            TrainingBooking__c tb = bg_TrainingUnitTestHelper.createTrainingBooking(te, 2, acc.Id);
            TrainingDelegate__c td = bg_TrainingUnitTestHelper.createTrainingDelegate(tb, 'John', 'Smith', null, null, null, null, false, null);
            TrainingDelegate__c td1 = bg_TrainingUnitTestHelper.createTrainingDelegate(tb, 'Anna', 'Potter', null, null, null, null, false, null);

            // associated td to con1
            td.Conversion_Contact__c = con1.Id;
            update td;

            Test.setCurrentPage(Page.trainingDelegateImport);
            ApexPages.currentPage().getParameters().put('trainingBookingId', tb.Id);
            TrainingDelegateImportController controller = new TrainingDelegateImportController();
            
            // Upload a test csv
            String testCSV = 'Salutation__c,First_Name__c,Last_Name__c,First_Name_English__c,Last_Name_English__c,Job_Title__c,Email_Address__c,Mobile_Number__c,Social_Security_Number__c,Accommodation_Required__c\r'
                +'Salutation,First Name,Last Name,First Name (English),Last Name (English),Job Title,Email Address,Mobile Number,Social Security Number,Accommodation required?\r'
                +'Mr,John,Smith,,,Developer,john.smith@comapny.com,0123456789,123456789,true\r'
                +'Mr,Steve,William,,,Manager,steve.william@company.com,098765432,987654322,false\r'
                +'Mrs,Isabell,Black,,,Manager,isabell.black@company.com,098765432,987654322,false\r'
                +'Mrs,Isabell,Black,,,Manager,isabell.black@company.com,098765432,987654322,false\r';

            Test.startTest();
            controller.docfile.body = Blob.valueOf(testCSV);
            controller.readFile();

            system.assertEquals(5,controller.getDelegates().size());

            Integer actionInsert = 0;
            Integer actionUpdate = 0;
            Integer actionDelete = 0;
            Integer actionNoAction = 0;

            Integer contactActionLink = 0;
            Integer contactActionUpdate = 0;

            for (TrainingDelegateImportController.ValidatedDelegate vd : controller.getDelegates() ) {
                if (vd.delegate != null) {
                    if (vd.action == TrainingDelegateImportController.ACTION_UPDATE) {
                        system.assertEquals(td.id, vd.existingDelegate.id);
                    }
                    if (vd.action == TrainingDelegateImportController.ACTION_DELETE) {
                        system.assertEquals(null, vd.existingDelegate);
                    }
                }

                if (vd.action == TrainingDelegateImportController.ACTION_INSERT) {
                    actionInsert++;
                }

                if (vd.action == TrainingDelegateImportController.ACTION_UPDATE) {
                    actionUpdate++;
                }

                if (vd.action == TrainingDelegateImportController.ACTION_DELETE) {
                    actionDelete++;
                }

                if (vd.action == TrainingDelegateImportController.ACTION_IGNORE) {
                    actionNoAction++;
                }

                if (vd.contactAction == TrainingDelegateImportController.ACTION_LINK) {
                    contactActionLink++;
                }

                if (vd.contactAction == TrainingDelegateImportController.ACTION_UPDATE_CONTACT) {
                    contactActionUpdate++;
                }
            }

            system.assertEquals(acc.id, controller.trainingBookingAccount.Id);

            system.assertEquals(2,actionInsert);
            system.assertEquals(1,actionUpdate);
            system.assertEquals(1,actionNoAction);
            system.assertEquals(1,actionDelete);
            system.assertEquals(0,contactActionUpdate);
            system.assertEquals(1,contactActionLink);

            controller.updateDelegates();

            Test.stopTest();
        }
    }
}