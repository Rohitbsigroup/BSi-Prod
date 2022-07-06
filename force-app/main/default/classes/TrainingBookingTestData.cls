/*
*           15-01-2016 ASD  - Fixed Unit Tests to suit VR rules and WFRs (too many SOQLS) added inMemory Creators
            22-02-2016 CP   - createTestPromo() overloaded and updated to use overloaded method
            06-11-2017 ADS  - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry
*/

@isTest(seeAllData=false) // Needed for access to standard pricebook
public with sharing class TrainingBookingTestData
{
    public static Training_Venue__c createTestVenue()
    {
        // Create object
        Training_Venue__c testVenue = new Training_Venue__c();
        testVenue.Name = 'Master Test Venue'; // Master is required to bypass validation rule
        /* 21/11/2014 NF */
        RecordType inHouseRecordType = [SELECT Id, Name
                                        FROM RecordType
                                        WHERE sObjectType = 'Training_Venue__c'
                                        AND Name = 'In-House'
                                        LIMIT 1];
        
        if(inHouseRecordType != null)
        {
            testVenue.RecordTypeId = inHouseRecordType.Id;
        }
        /* END */
        insert testVenue;
        
        // Retrieve object
        testVenue = [
            SELECT  s.Id, 
                    s.Name
            FROM    Training_Venue__c s
            WHERE   s.Id = :testVenue.Id];
            
        return testVenue;
    }

    public static Product2 createTestCourse(String courseType,  String courseName)
    {
        // CB TO FIX
        return createTestCourse(courseType, null, courseName, null, null, null, null, null, null);
    }

    public static Product2 createTestCourse(String courseType,  String courseName, Product2 accommodationProduct)
    {
        // CB TO FIX
        return createTestCourse(courseType, null, courseName, null, null, null, accommodationProduct, null, null);
    }
        
    public static Product2 createTestCourse(String courseType, Integer noOfDays, String courseName, String isoCode, String courseClass, String taxonomy, Product2 accommodationProduct, Product2 extraNightProduct, Product2 premiumPriceProduct)
    {
        // Create object
        Product2 testCourse = new Product2();
        Map<String, Schema.RecordTypeInfo> recTypesByName = Product2.SObjectType.getDescribe().getRecordTypeInfosByName();
        if (recTypesByName.containsKey('Training Course'))
        {
            testCourse.RecordTypeId = recTypesByName.get('Training Course').getRecordTypeId();  
        } 
        testCourse.Name = courseName;
        testCourse.Course_Name_English__c = courseName;
        testCourse.CurrencyIsoCode = isoCode;
        testCourse.Training_Taxonomy_Code__c = taxonomy;
        testCourse.Enable_Online_Booking__c = true;
        testCourse.Class__c = courseClass;
        testCourse.Course_Duration_Days__c = noOfDays;
        testCourse.IsActive = true;
        testCourse.Course_Format__c = 'ILT';
        testCourse.ProductArea__c = 'Training';

        // Set type according to parameter
        if (courseType == 'Normal')
        {
            testCourse.Delivery_Method__c = 'Instructor Lead Training';
            testCourse.Training_Event_Residential__c = false;
        }
        else if (courseType == 'Residential')
        {
            testCourse.Delivery_Method__c = 'Instructor Lead Training';
            testCourse.Training_Event_Residential__c = true;
            if(null != accommodationProduct)
            {
                testCourse.Base_Product__c = accommodationProduct.Id;
            }
            if(null != extraNightProduct)
            {
                testCourse.Extra_Night__c = extraNightProduct.Id;
            }
        }
        else if (courseType == 'Distance')
        {
            testCourse.Delivery_Method__c = 'Distance Learning';
            testCourse.Training_Event_Residential__c = false;
        }

        if(null != premiumPriceProduct)
        {
            testCourse.Premium_Product__c = premiumPriceProduct.Id;
        }
        
        insert testCourse;
            
        return [SELECT  s.Id, 
                        s.Name, 
                        s.Course_Name_English__c, 
                        s.CurrencyIsoCode, 
                        s.Training_Taxonomy_Code__c, 
                        s.Enable_Online_Booking__c, 
                        s.Class__c, 
                        s.IsActive, 
                        s.RecordTypeId, 
                        s.Delivery_Method__c, 
                        s.Training_Event_Residential__c, 
                        s.Base_Product__c,
                        s.Extra_Night__c,
                        s.Premium_Product__c,
                        s.Course_duration_days__c,
                        s.Product_Name_Local__c
                FROM    Product2 s
                WHERE   s.Id = :testCourse.Id];
    }

public static Product2 getTestCourse(String courseType,  String courseName)
    {
        // CB TO FIX
        return getTestCourse(courseType, null, courseName, null, null, null, null, null, null);
    }

    public static Product2 getTestCourse(String courseType,  String courseName, Product2 accommodationProduct)
    {
        // CB TO FIX
        return getTestCourse(courseType, null, courseName, null, null, null, accommodationProduct, null, null);
    }
        
    public static Product2 getTestCourse(String courseType, Integer noOfDays, String courseName, String isoCode, String courseClass, String taxonomy, Product2 accommodationProduct, Product2 extraNightProduct, Product2 premiumPriceProduct)
    {
        // Create object
        Product2 testCourse = new Product2();
        Map<String, Schema.RecordTypeInfo> recTypesByName = Product2.SObjectType.getDescribe().getRecordTypeInfosByName();
        if (recTypesByName.containsKey('Training Course'))
        {
            testCourse.RecordTypeId = recTypesByName.get('Training Course').getRecordTypeId();  
        } 
        testCourse.Name = courseName;
        testCourse.Course_Name_English__c = courseName;
        testCourse.CurrencyIsoCode = isoCode;
        testCourse.Training_Taxonomy_Code__c = taxonomy;
        testCourse.Enable_Online_Booking__c = true;
        testCourse.Class__c = courseClass;
        testCourse.Course_Duration_Days__c = noOfDays;
        testCourse.IsActive = true;
        testCourse.Course_Format__c = 'ILT';

        // Set type according to parameter
        if (courseType == 'Normal')
        {
            testCourse.Delivery_Method__c = 'Instructor Lead Training';
            testCourse.Training_Event_Residential__c = false;
        }
        else if (courseType == 'Residential')
        {
            testCourse.Delivery_Method__c = 'Instructor Lead Training';
            testCourse.Training_Event_Residential__c = true;
            if(null != accommodationProduct)
            {
                testCourse.Base_Product__c = accommodationProduct.Id;
            }
            if(null != extraNightProduct)
            {
                testCourse.Extra_Night__c = extraNightProduct.Id;
            }
        }
        else if (courseType == 'Distance')
        {
            testCourse.Delivery_Method__c = 'Distance Learning';
            testCourse.Training_Event_Residential__c = false;
        }

        if(null != premiumPriceProduct)
        {
            testCourse.Premium_Product__c = premiumPriceProduct.Id;
        }
        
        return testCourse;
    }
    
    public static Training_Event__c createTestEvent(Product2 product, Training_Venue__c venue, Integer maxSeats, Id pInstructorId)
    {
        // Create object
        Training_Event__c testEvent = new Training_Event__c();
        Map<String, Schema.RecordTypeInfo> recTypesByName = Training_Event__c.SObjectType.getDescribe().getRecordTypeInfosByName();
        if (recTypesByName.containsKey('Global Training Event')) testEvent.RecordTypeId = recTypesByName.get('Global Training Event').getRecordTypeId();
        testEvent.Course__c = product.Id;
        testEvent.Start_date__c = Date.today().addDays(1);
        testEvent.Max_seats__c = maxSeats;
        testEvent.Delivery_Language__c = 'English';
        testEvent.Training_Venue__c = venue.Id;
        testEvent.Exclude_From_Online_Booking__c = false;
        testEvent.Event_status__c = 'Active';
        testEvent.Trainer__c = pInstructorId;
        testEvent.Max_Accommodation__c = 10;
        insert testEvent;
        
        // Retrieve object
        testEvent = [
            SELECT  s.Id, 
                    s.Name, 
                    s.Course__c, 
                    s.Start_date__c, 
                    s.Max_seats__c, 
                    s.Delivery_Language__c, 
                    s.Training_Venue__c, 
                    s.RecordTypeId, 
                    s.Exclude_From_Online_Booking__c,
                    s.Event_Status__c,
                    s.Active_1_0__c,
                    s.Course__r.Course_Format__c,
                    s.End_date3__c,
                    s.Max_Accommodation__c,
                    s.Remaining_Accommodation__c
            FROM    Training_Event__c s
            WHERE   s.Id = :testEvent.Id];
            
        return testEvent;
    }
    
    public static PricebookEntry createTestPbe(Product2 course, Decimal unitPrice, String isoCode)
    {
        // Create object
        Id stdId;
        Pricebook2 std;
        If(Test.isRunningTest())
        {
            stdId = Test.getStandardPricebookId();
        }
        else
        {
            std = [SELECT Id FROM Pricebook2 WHERE isStandard = true];
        }
        PricebookEntry testPbe = new PricebookEntry();
        testPbe.IsActive = true;
        testPbe.Product2Id = course.Id;
        if(std != null)
        {
            testPbe.Pricebook2Id = std.Id;
        }
        else
        {
            testPbe.Pricebook2Id = stdId;
        }
        // 06/11/2017 ADS - Updates for new Validation Rule "All Standard Prices Must Be Zero" on Pricebook Entry
        // testPbe.UnitPrice = unitPrice;
        testPbe.UnitPrice = 0.0;
        testPbe.CurrencyIsoCode = isoCode;
        insert testPbe;
        
        // Retrieve object
        testPbe = [
            SELECT  s.Id, 
                    s.Name, 
                    s.IsActive, 
                    s.Product2Id, 
                    s.Pricebook2Id, 
                    s.UnitPrice, 
                    s.CurrencyIsoCode 
            FROM    PricebookEntry s
            WHERE   s.Id = :testPbe.Id];
            
        return testPbe;
    }   

    //CP refactored
    public static Training_Promo_Code__c createTestPromo()
    {       
        return createTestPromo('PROMO',0,25);
    }

    public static Training_Promo_Code__c createTestPromo(String promoCode, Integer valueDiscount, Integer percentDiscount)
    {
        // Create object
        Training_Promo_Code__c testPromo = new Training_Promo_Code__c();
        testPromo.Name = promoCode;
        testPromo.Country__c = 'UK';
        testPromo.Start_Date__c = Date.newInstance(1900, 1, 1);
        testPromo.End_Date__c = Date.newInstance(2099, 1, 1);
        testPromo.Apply_to_all_Courses__c = true;
        testPromo.CurrencyIsoCode = 'GBP';
        testPromo.Discount_Percentage__c = percentDiscount;
        testPromo.Discount_Value__c = valueDiscount;
        testPromo.Status__c = 'Active';
        testPromo.Description__c = 'Just testing'+ promoCode;
        insert testPromo;
        return testPromo;
    }

    public static TrainingBooking__c createTestBooking(Training_Event__c event, PricebookEntry pbeExc, PricebookEntry pbeInc)
    {
        // Create object
        TrainingBooking__c testBkg = new TrainingBooking__c();
        testBkg.Booking_Country__c = 'GB';
        testBkg.Booking_Language__c = 'EN';

        // Event elements
        testBkg.Training_Event__c = event.Id;
        testBkg.Is_Residential__c = true;
        testBkg.Price_Exc_Accommodation__c = 50.00;
        testBkg.Price_Inc_Accommodation__c = 50.00;
        testBkg.Price_Per_Delegate__c = null;
        testBkg.Pricebook_Entry__c = null;
        testBkg.Pricebook_Exc_Accommodation__c = pbeExc.Id;
        testBkg.Pricebook_Inc_Accommodation__c = pbeInc.Id;

        // Contact elements
        testBkg.Salutation__c = '';
        testBkg.First_Name__c = 'Test';
        testBkg.Last_Name__c = 'Contact';
        testBkg.Email_Address__c = 'test@bsigroup.com';
        testBkg.Email_Confirmation__c = 'test@bsigroup.com';
        testBkg.Job_Title__c = 'Manager';
        testBkg.Attending_Course__c = true;

        // Company elements
        testBkg.Company_Name__c = 'Test Company';
        testBkg.Company_Street__c = '389 High Rd';
        testBkg.Company_City__c = 'London';
        testBkg.Company_Region__c = 'Buckinghamshire';
        testBkg.Company_Region_Code__c = 'BU';
        testBkg.Company_Postcode__c = 'W4 4AL';
        //testBkg.Company_Country__c = 'United Kingdom';
        testBkg.Company_Country__c = 'GB';
        testBkg.Company_Country_Code__c = 'GB';
        testBkg.Contact_Phone__c = '02089969000';
        testBkg.Contact_Mobile__c = '07123456789';
        testBkg.Contact_Fax__c = '02089969001';
        testBkg.VAT_Number__c = '';

        // Billing elements
        testBkg.Billing_Address__c = true;
        testBkg.Billing_Name__c = 'Test Company';
        testBkg.Billing_Street__c = '389 High Rd';
        testBkg.Billing_City__c = 'London';
        testBkg.Billing_Region__c = 'Buckinghamshire';
        testBkg.Billing_Region_Code__c = 'BU';
        //testBkg.Billing_Postcode__c = 'W4 4AL';
        //testBkg.Billing_Country__c = 'United Kingdom';
        //testBkg.Billing_Country_Code__c = 'GB';
        testBkg.Billing_Postcode__c = '12345';
        testBkg.Billing_Country__c = 'SG';
        testBkg.Billing_Country_Code__c = 'SG';

        // Delegate and pricing elements
        testBkg.Number_of_Delegates__c = null;
        testBkg.Delegates_Exc_Accommodation__c = 1;
        testBkg.Delegates_Inc_Accommodation__c = 1;
        testBkg.Net_Price__c = 100.00;
        testBkg.Tax__c = 20.00;
        testBkg.Discount__c = 0.00;
        testBkg.Discount_Percentage__c = 0.00;
        testBkg.Discount_Value__c = 0.00;
        testBkg.Total_Price__c = 120.00;

        // Payment elements
        testBkg.Payment_Method__c = 'Invoice';
        testBkg.Payment_Order_No__c = '';
        testBkg.PO_Number__c = '';
        testBkg.Promotional_Code__c = '';
        testBkg.SAP_Order_No__c = '';
        testBkg.Agree_Personal_Data_Statement__c = true;
        testBkg.Agree_Terms_Conditions__c = true;

        // Conversion elements
        testBkg.Conversion_Account__c = null;
        testBkg.Conversion_Contact__c = null;
        testBkg.Conversion_Opportunity__c = null;
        testBkg.Converted__c = false;

        insert testBkg;

        // Retrieve object
        testBkg = [
            SELECT  s.Id, 
                    s.Name, 
                    s.Training_Event__c, 
                    s.Is_Residential__c, 
                    s.Price_Exc_Accommodation__c, 
                    s.Price_Inc_Accommodation__c, 
                    s.Price_Per_Delegate__c, 
                    s.Pricebook_Entry__c, 
                    s.Pricebook_Exc_Accommodation__c, 
                    s.Pricebook_Inc_Accommodation__c, 
                    s.Salutation__c, 
                    s.First_Name__c, 
                    s.Last_Name__c, 
                    s.Email_Address__c, 
                    s.Email_Confirmation__c, 
                    s.Job_Title__c, 
                    s.Attending_Course__c, 
                    s.Company_Name__c, 
                    s.Company_Street__c, 
                    s.Company_City__c, 
                    s.Company_Region__c, 
                    s.Company_Region_Code__c, 
                    s.Company_Postcode__c, 
                    s.Company_Country__c, 
                    s.Company_Country_Code__c, 
                    s.Contact_Phone__c, 
                    s.Contact_Mobile__c, 
                    s.Contact_Fax__c, 
                    s.VAT_Number__c, 
                    s.Billing_Address__c, 
                    s.Billing_Name__c, 
                    s.Billing_Street__c, 
                    s.Billing_City__c, 
                    s.Billing_Region__c, 
                    s.Billing_Region_Code__c, 
                    s.Billing_Postcode__c, 
                    s.Billing_Country__c, 
                    s.Billing_Country_Code__c, 
                    s.Number_of_Delegates__c, 
                    s.Delegates_Exc_Accommodation__c, 
                    s.Delegates_Inc_Accommodation__c, 
                    s.Net_Price__c, 
                    s.Tax__c, 
                    s.Discount__c, 
                    s.Discount_Percentage__c, 
                    s.Discount_Value__c, 
                    s.Total_Price__c, 
                    s.Payment_Method__c, 
                    s.Payment_Order_No__c, 
                    s.PO_Number__c, 
                    s.Promotional_Code__c, 
                    s.SAP_Order_No__c, 
                    s.Agree_Personal_Data_Statement__c, 
                    s.Agree_Terms_Conditions__c, 
                    s.Conversion_Account__c, 
                    s.Conversion_Contact__c, 
                    s.Conversion_Opportunity__c, 
                    s.Converted__c 
            FROM    TrainingBooking__c s
            WHERE   s.Id = :testBkg.Id];
            
        return testBkg;
    }

    public static TrainingDelegate__c createTestDelegate(TrainingBooking__c booking, Boolean booker, Boolean accommodation)
    {
        // Create object
        TrainingDelegate__c testDlg = new TrainingDelegate__c();
        testDlg.Salutation__c = '';
        testDlg.First_Name__c = 'Test';
        testDlg.Last_Name__c = 'Delegate1';
        testDlg.First_Name_English__c = 'John';
        testDlg.Last_Name_English__c = 'Smith';
        testDlg.Email_Address__c = 'test@bsigroup.com';
        testDlg.Email_Confirmation__c = 'test@bsigroup.com';
        testDlg.Job_Title__c = 'Test Title';
        testDlg.Accommodation_Required__c = accommodation;
        testDlg.Is_Booker__c = booker;
        testDlg.Training_Booking__c = booking.Id;
        testDlg.Conversion_Contact__c = null;
        testDlg.Converted__c = false;
        insert testDlg;
        
        // Retrieve object
        testDlg = [
            SELECT  s.Id, 
                    s.Name, 
                    s.Salutation__c, 
                    s.First_Name__c, 
                    s.Last_Name__c, 
                    s.First_Name_English__c, 
                    s.Last_Name_English__c, 
                    s.Email_Address__c, 
                    s.Email_Confirmation__c, 
                    s.Job_Title__c, 
                    s.Accommodation_Required__c, 
                    s.Is_Booker__c, 
                    s.Training_Booking__c, 
                    s.Conversion_Contact__c, 
                    s.Converted__c  
            FROM    TrainingDelegate__c s
            WHERE   s.Id = :testDlg.Id];
            
        return testDlg;
    }
}