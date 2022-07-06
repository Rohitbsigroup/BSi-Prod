@isTest
private class TrainingEventManagementControllerTest
{

    @isTest static void testNoRowsSelected()
    {
        // Initialise Custom Settings
        bg_UnitTestHelper.SetupCustomSettings();

        User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');
        System.runAs(user1)
        {

            List<Training_Event__c> events = new List<Training_Event__c>();

            Test.setCurrentPage(Page.trainingEventAdmin);
            ApexPages.StandardSetController stdCont1 = new ApexPages.standardSetController(events);
            stdCont1.setSelected(events);
            TrainingEventManagementController eventController = new TrainingEventManagementController(stdCont1);

            Test.startTest();
            eventController.rotateExam();
            system.assertEquals(true, eventController.noRows);
            Test.stopTest();
        }
    }

    @isTest static void testNoPermission()
    {

        // Initialise Custom Settings
        bg_UnitTestHelper.SetupCustomSettings();

        User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');
        System.runAs(user1)
        {
            //setup account
            Account acc = bg_UnitTestHelper.CreateAccount();
            insert acc;
            List<Training_Event__c> events = new List<Training_Event__c>();
            Training_Venue__c masterVenue = bg_TrainingUnitTestHelper.createTrainingVenue('Master Venue', 'GBP');
            Training_Venue__c tv = bg_TrainingUnitTestHelper.createTrainingVenue(masterVenue,'Training Venue', 'GBP');
            Contact con = bg_UnitTestHelper.CreateContact('ILOVEUNITTESTS', acc);
            con.Country_Office__c = tv.Id;
            insert con;
            Product2 product = bg_TrainingUnitTestHelper.GetProductTraining('Test Course','Icode1,Icode2');
            Training_Event__c te = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 5, product, Date.today()+5,con.Id);
            events.add(te);

            Test.setCurrentPage(Page.trainingEventAdmin);
            ApexPages.StandardSetController stdCont1 = new ApexPages.standardSetController(events);
            stdCont1.setSelected(events);
            TrainingEventManagementController eventController = new TrainingEventManagementController(stdCont1);

            Test.startTest();
            eventController.rotateExam();
            system.assertEquals(false, eventController.noRows);
            system.assertEquals(false, bg_CustomSettingsUtils.GetPermissionSettings().CanExecuteExamRotation__c);
            system.assertEquals(true, eventController.errorFlag);
            Test.stopTest();
        }
    }

    @isTest static void testCancel()
    {

        // Initialise Custom Settings
        bg_UnitTestHelper.SetupCustomSettings();

        User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');
        System.runAs(user1)
        {

            List<Training_Event__c> events = new List<Training_Event__c>();

            Test.setCurrentPage(Page.trainingEventAdmin);
            ApexPages.StandardSetController stdCont1 = new ApexPages.standardSetController(events);
            stdCont1.setSelected(events);
            TrainingEventManagementController eventController = new TrainingEventManagementController(stdCont1);

            Test.startTest();
            eventController.cancel();
            system.assertNotEquals(ApexPages.currentPage(), Page.trainingEventAdmin);
            Test.stopTest();
        }
    }

    @isTest static void TestTrainingEventsExamAssigments()
    {
        // Initialise Custom Settings
        bg_UnitTestHelper.SetupCustomSettings();

        User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');

        BSIPermissions__c perms = new BSIPermissions__c(SetupOwnerId=user1.Id, CanExecuteExamRotation__c=true);
        insert perms;

        System.runAs(user1)
        {
            //setup account
            Account acc = bg_UnitTestHelper.CreateAccount();
            List<Training_Event__c> events = new List<Training_Event__c>();
            Training_Venue__c masterVenue = bg_TrainingUnitTestHelper.createTrainingVenue('Master Venue', 'GBP');
            Training_Venue__c tv = bg_TrainingUnitTestHelper.createTrainingVenue(masterVenue,'Training Venue', 'GBP');
            Contact con = bg_UnitTestHelper.CreateContact('ILOVEUNITTESTS', acc);
            con.Country_Office__c = tv.Id;
            insert con;

            Product2 product = bg_TrainingUnitTestHelper.GetProductTraining('Test Course','Icode1,Icode2');
            product.Number_of_Exam_Papers__c = 3;
            product.Course_Has_Exam__c = true;
            update product;
            Product2 product2 = bg_TrainingUnitTestHelper.GetProductTraining('Test Course 2','Icode3,Icode4');
            product2.Number_of_Exam_Papers__c = 2;
            product2.Course_Has_Exam__c = true;
            update product2;
            
            // no training events in past
            Product2 product3 = bg_TrainingUnitTestHelper.GetProductTraining('Test Course 3','Icode5,Icode6');
            product3.Number_of_Exam_Papers__c = 2;
            product3.Course_Has_Exam__c = true;
            update product3;
            
            Training_Event__c eventInPast1 = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 5, product, Date.today()-5, con.Id);
            eventInPast1.Exam_paper_reference__c = '2';
            update eventInPast1;
            Training_Event__c eventInPast2 = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 5, product2, Date.today()-5, con.Id);
            eventInPast2.Exam_paper_reference__c = '2';
            update eventInPast2;

            Training_Event__c eventInFuture1 = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 5, product, Date.today()+5, con.Id);
            events.add(eventInFuture1);
            Training_Event__c eventInFuture2 = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 5, product2, Date.today()+10, con.Id);
            events.add(eventInFuture2);
            Training_Event__c eventInFuture3 = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 5, product2, Date.today()+5, con.Id);
            events.add(eventInFuture3);
            Training_Event__c eventInFuture4 = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 5, product2, Date.today()+15, con.Id);
            events.add(eventInFuture4);
            Training_Event__c eventInFuture5 = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 5, product3, Date.today()+5, con.Id);
            events.add(eventInFuture5);

            Test.setCurrentPage(Page.trainingEventAdmin);
            ApexPages.StandardSetController stdCont1 = new ApexPages.standardSetController(events);
            stdCont1.setSelected(events);
            TrainingEventManagementController eventController = new TrainingEventManagementController(stdCont1);

            Test.startTest();
            eventController.rotateExam();
            system.assertEquals(false, eventController.noRows);
            system.assertEquals(true, bg_CustomSettingsUtils.GetPermissionSettings().CanExecuteExamRotation__c);
            system.assertEquals(false, eventController.errorFlag);

            for (Training_Event__c event : eventController.events)
            {
                if (event.Course__c == product.id)
                {
                    system.assertEquals('3', event.Exam_paper_reference__c);
                }
                else if (event.Course__c == product2.id)
                {
                    if (event.Start_date__c == Date.today()+5)
                    {
                        system.assertEquals('1', event.Exam_paper_reference__c);
                    }
                    else if (event.Start_date__c == Date.today()+10)
                    {
                        system.assertEquals('2', event.Exam_paper_reference__c);
                    }
                    else if (event.Start_date__c == Date.today()+15)
                    {
                        system.assertEquals('1', event.Exam_paper_reference__c);
                    }
                }
                else if (event.Course__c == product3.id)
                {
                    system.assertEquals('1', event.Exam_paper_reference__c);
                }
            }

            Test.stopTest();

        }
    }

    @isTest static void TestTrainingEventsExamAssigmentsConfirm()
    {
        // Initialise Custom Settings
        bg_UnitTestHelper.SetupCustomSettings();

        User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');

        BSIPermissions__c perms = new BSIPermissions__c(SetupOwnerId=user1.Id, CanExecuteExamRotation__c=true);
        insert perms;

        System.runAs(user1)
        {
            //setup account
            Account acc = bg_UnitTestHelper.CreateAccount();

            List<Training_Event__c> events = new List<Training_Event__c>();
            Training_Venue__c masterVenue = bg_TrainingUnitTestHelper.createTrainingVenue('Master Venue', 'GBP');
            Training_Venue__c tv = bg_TrainingUnitTestHelper.createTrainingVenue(masterVenue,'Training Venue', 'GBP');

            Contact con = bg_UnitTestHelper.CreateContact('ILOVEUNITTESTS', acc);
            con.Country_Office__c = tv.Id;
            insert con;

            Product2 product = bg_TrainingUnitTestHelper.GetProductTraining('Test Course','Icode1,Icode2');
            product.Number_of_Exam_Papers__c = 3;
            product.Course_Has_Exam__c = true;
            update product;
            Product2 product2 = bg_TrainingUnitTestHelper.GetProductTraining('Test Course 2','Icode3,Icode4');
            product2.Number_of_Exam_Papers__c = 2;
            product2.Course_Has_Exam__c = true;
            update product2;
            
            // no training events in past
            Product2 product3 = bg_TrainingUnitTestHelper.GetProductTraining('Test Course 3','Icode5,Icode6');
            product3.Number_of_Exam_Papers__c = 2;
            product3.Course_Has_Exam__c = true;
            update product3;
            
            Training_Event__c eventInPast1 = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 5, product, Date.today()-5, con.Id);
            eventInPast1.Exam_paper_reference__c = '2';
            update eventInPast1;
            Training_Event__c eventInPast2 = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 5, product2, Date.today()-5, con.Id);
            eventInPast2.Exam_paper_reference__c = '2';
            update eventInPast2;

            Training_Event__c eventInFuture1 = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 5, product, Date.today()+5, con.Id);
            events.add(eventInFuture1);
            Training_Event__c eventInFuture2 = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 5, product2, Date.today()+10, con.Id);
            events.add(eventInFuture2);
            Training_Event__c eventInFuture3 = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 5, product2, Date.today()+5, con.Id);
            events.add(eventInFuture3);
            Training_Event__c eventInFuture4 = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 5, product2, Date.today()+15, con.Id);
            events.add(eventInFuture4);
            Training_Event__c eventInFuture5 = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 5, product3, Date.today()+5, con.Id);
            events.add(eventInFuture5);

            List<Id> eventsIds = new List<Id>();
            eventsIds.add(eventInFuture1.id);
            eventsIds.add(eventInFuture2.id);
            eventsIds.add(eventInFuture3.id);
            eventsIds.add(eventInFuture4.id);
            eventsIds.add(eventInFuture5.id);

            Test.setCurrentPage(Page.trainingEventAdmin);
            ApexPages.StandardSetController stdCont1 = new ApexPages.standardSetController(events);
            stdCont1.setSelected(events);
            TrainingEventManagementController eventController = new TrainingEventManagementController(stdCont1);

            Test.startTest();
            eventController.rotateExam();
            system.assertEquals(false, eventController.noRows);
            system.assertEquals(true, bg_CustomSettingsUtils.GetPermissionSettings().CanExecuteExamRotation__c);
            system.assertEquals(false, eventController.errorFlag);

            eventController.confirm();

            List<Training_Event__c> updatedEvents = [SELECT id, Start_date__c, Exam_paper_reference__c, Course__c from Training_Event__c
                where id in :eventsIds];

            for (Training_Event__c event : updatedEvents)
            {
                if (event.Course__c == product.id)
                {
                    system.assertEquals('3', event.Exam_paper_reference__c);
                }
                else if (event.Course__c == product2.id)
                {
                    if (event.Start_date__c == Date.today()+5)
                    {
                        system.assertEquals('1', event.Exam_paper_reference__c);
                    }
                    else if (event.Start_date__c == Date.today()+10)
                    {
                        system.assertEquals('2', event.Exam_paper_reference__c);
                    }
                    else if (event.Start_date__c == Date.today()+15)
                    {
                        system.assertEquals('1', event.Exam_paper_reference__c);
                    }
                }
                else if (event.Course__c == product3.id)
                {
                    system.assertEquals('1', event.Exam_paper_reference__c);
                }
            }
            Test.stopTest();
        }
    }

    @isTest static void TestTrainingEventsExamAssigmentsConfirmError()
    {
        // Initialise Custom Settings
        bg_UnitTestHelper.SetupCustomSettings();

        User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');

        BSIPermissions__c perms = new BSIPermissions__c(SetupOwnerId=user1.Id, CanExecuteExamRotation__c=true);
        insert perms;

        System.runAs(user1)
        {

            //setup account
            Account acc = bg_UnitTestHelper.CreateAccount();

            List<Training_Event__c> events = new List<Training_Event__c>();
            Training_Venue__c masterVenue = bg_TrainingUnitTestHelper.createTrainingVenue('Master Venue', 'GBP');
            Training_Venue__c tv = bg_TrainingUnitTestHelper.createTrainingVenue(masterVenue,'Training Venue', 'GBP');

            Contact con = bg_UnitTestHelper.CreateContact('ILOVEUNITTESTS', acc);
            con.Country_Office__c = tv.Id;
            insert con;

            Product2 product = bg_TrainingUnitTestHelper.GetProductTraining('Test Course','Icode1,Icode2');
            product.Number_of_Exam_Papers__c = 3;
            product.Course_Has_Exam__c = true;
            update product;
            
            Training_Event__c eventInPast1 = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 5, product, Date.today()-5, con.Id);
            eventInPast1.Exam_paper_reference__c = '2';
            update eventInPast1;

            Training_Event__c eventInFuture1 = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 5, product, Date.today()+5, con.Id);
            events.add(eventInFuture1);

            List<Id> eventsIds = new List<Id>();
            eventsIds.add(eventInFuture1.id);

            Test.setCurrentPage(Page.trainingEventAdmin);
            ApexPages.StandardSetController stdCont1 = new ApexPages.standardSetController(events);
            stdCont1.setSelected(events);
            TrainingEventManagementController eventController = new TrainingEventManagementController(stdCont1);

            Test.startTest();
            eventController.rotateExam();
            system.assertEquals(false, eventController.noRows);
            system.assertEquals(true, bg_CustomSettingsUtils.GetPermissionSettings().CanExecuteExamRotation__c);
            system.assertEquals(false, eventController.errorFlag);

             for (Training_Event__c event : eventController.events)
            {
                if (event.Course__c == product.id)
                {
                    event.Exam_paper_reference__c = '4';
                }
            }

            eventController.confirm();

            List<Training_Event__c> updatedEvents = [SELECT id, Name, Start_date__c, Exam_paper_reference__c, Course__c from Training_Event__c
                where id in :eventsIds];

            for (Training_Event__c event : updatedEvents)
            {
                if (event.Course__c == product.id)
                {
                    String error = string.format(Label.Training_Event_Exam_Rotation_Wrong_Number_of_Exam_Papers,new list<string>{event.Name});
                    system.assertEquals(error, eventController.errorsEvent);
                }
            }
            Test.stopTest();
        }
    }

    @isTest static void TestTrainingEventCourseNoExamAssignmentAndConfirm()
    {
        // Initialise Custom Settings
        bg_UnitTestHelper.SetupCustomSettings();

        User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');

        BSIPermissions__c perms = new BSIPermissions__c(SetupOwnerId=user1.Id, CanExecuteExamRotation__c=true);
        insert perms;

        System.runAs(user1)
        {
            //setup account
            Account acc = bg_UnitTestHelper.CreateAccount();

            List<Training_Event__c> events = new List<Training_Event__c>();
            Training_Venue__c masterVenue = bg_TrainingUnitTestHelper.createTrainingVenue('Master Venue', 'GBP');
            Training_Venue__c tv = bg_TrainingUnitTestHelper.createTrainingVenue(masterVenue,'Training Venue', 'GBP');

            Contact con = bg_UnitTestHelper.CreateContact('ILOVEUNITTESTS', acc);
            con.Country_Office__c = tv.Id;
            insert con;

            Product2 product = bg_TrainingUnitTestHelper.GetProductTraining('Test Course','Icode1,Icode2');
            product.Number_of_Exam_Papers__c = 3;
            product.Course_Has_Exam__c = false;
            update product;
            
            Training_Event__c eventInPast1 = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 5, product, Date.today()-5, con.Id);
            eventInPast1.Exam_paper_reference__c = '2';
            update eventInPast1;

            Training_Event__c eventInFuture1 = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 5, product, Date.today()+5, con.Id);
            events.add(eventInFuture1);

            List<Id> eventsIds = new List<Id>();
            eventsIds.add(eventInFuture1.id);

            Test.setCurrentPage(Page.trainingEventAdmin);
            ApexPages.StandardSetController stdCont1 = new ApexPages.standardSetController(events);
            stdCont1.setSelected(events);
            TrainingEventManagementController eventController = new TrainingEventManagementController(stdCont1);

            Test.startTest();
            eventController.rotateExam();
            system.assertEquals(false, eventController.noRows);
            system.assertEquals(true, bg_CustomSettingsUtils.GetPermissionSettings().CanExecuteExamRotation__c);
            system.assertEquals(false, eventController.errorFlag);

             for (Training_Event__c event : eventController.events)
            {
                if (event.Course__c == product.id)
                {
                    system.assertEquals(null,event.Exam_paper_reference__c);
                }
            }

            eventController.confirm();

            List<Training_Event__c> updatedEvents = [SELECT id, Name, Start_date__c, Exam_paper_reference__c, Course__c from Training_Event__c
                where id in :eventsIds];

            for (Training_Event__c event : updatedEvents)
            {
                if (event.Course__c == product.id)
                {
                    system.assertEquals(null,event.Exam_paper_reference__c);
                }
            }
            Test.stopTest();
        }
    }

}