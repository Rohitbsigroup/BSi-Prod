/**
 * @Name:        RecommendationUserControllerTest
 * @Description: Test Class for RecommendationUserController
 *
 * @author:      Andrei Budescu
 * @version:     1.0
 * Change Log
 *
 * Date         author              Change Description
 * -----------------------------------------------------------------------------------
 * 20/04/2020   Andrei Budescu     Created Class
 */

@IsTest
public class RecommendationUserControllerTest {

    public class Tile{
        String title;
        String description;
        String stage;
        String type;
        String colour;
        String url;

        public Tile(String title, String url, String description, String stage, String type, String colour){
            this.title = title;
            this.url = url;
            this.description = description;
            this.stage = stage;
            this.type = type;
            this.colour = colour;
        }

    }

    /**
     * Scenario: An enrollment is accessed and it has recommended courses and qualifications linked.
     * Expected Outcome: A list with 2 recommended courses and 1 qualification tiles should be displayed.
     */
    public static testMethod void getRecommendationTilesProductsOrder1Test() {
        User uDelegate = [SELECT Id, Email FROM User WHERE Email = 'test@test.com'];
        Contact contactDelegate = [SELECT Id, Email, FirstName, Phone, LastName FROM Contact WHERE Email = 'test@test.com' LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];

        //create recommended products
        insertRecommendedProductsOrder1(prod.Id);
        //create training event and enrollment
        Training_Event__c t = [SELECT Id FROM Training_Event__c LIMIT 1];
        Training_Translations__c trainingTransl = [SELECT Id FROM Training_Translations__c LIMIT 1];
        Enrollment__c enr = [SELECT Id FROM Enrollment__c LIMIT 1];

        List<Tile> recommendationTiles  = new List<Tile>();
        Test.startTest();
        System.runAs(uDelegate){
            String listTiles = RecommendationUserController.getRecommendationTiles(enr.Id);
            recommendationTiles = (List<Tile>)System.JSON.deserialize(listTiles, List<Tile>.class);
        }
        Test.stopTest();

        Integer qualificationCounter = 0;
        Integer courseCounter = 0;
        String colorQualification = '';
        for(Tile tile : recommendationTiles){
            if(tile.type == 'Course') courseCounter++;
            if(tile.type == 'Qualification') {
                qualificationCounter++;
                colorQualification = tile.colour;
            }
        }
        System.assertEquals(4, recommendationTiles.size());
        System.assertEquals(3, courseCounter);
        System.assertEquals(1, qualificationCounter);
    }

    /**
     * Scenario: An enrollment is accessed and it has recommended courses and qualifications linked.
     * Expected Outcome: A list with 2 recommended courses and 1 qualification tiles should be displayed.
     */
    public static testMethod void getRecommendationTilesProductsOrder2Test() {
        User uDelegate = [SELECT Id, Email FROM User WHERE Email = 'test@test.com'];
        Contact contactDelegate = [SELECT Id, Email, FirstName, Phone, LastName FROM Contact WHERE Email = 'test@test.com' LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];

        //create recommended products
        insertRecommendedProductsOrder2(prod.Id);
        //create training event and enrollment
        Training_Event__c t = [SELECT Id FROM Training_Event__c LIMIT 1];
        Training_Translations__c trainingTransl = [SELECT Id FROM Training_Translations__c LIMIT 1];
        Enrollment__c enr = [SELECT Id FROM Enrollment__c LIMIT 1];

        List<Tile> recommendationTiles  = new List<Tile>();
        Test.startTest();
        System.runAs(uDelegate){
            String listTiles = RecommendationUserController.getRecommendationTiles(enr.Id);
            recommendationTiles = (List<Tile>)System.JSON.deserialize(listTiles, List<Tile>.class);
        }
        Test.stopTest();

        Integer qualificationCounter = 0;
        Integer courseCounter = 0;
        String colorQualification = '';
        for(Tile tile : recommendationTiles){
            if(tile.type == 'Course') courseCounter++;
            if(tile.type == 'Qualification') {
                qualificationCounter++;
                colorQualification = tile.colour;
            }
        }
        System.assertEquals(3, recommendationTiles.size());
        System.assertEquals(2, courseCounter);
        System.assertEquals(1, qualificationCounter);
    }

    /**
     * Scenario: An enrollment is accessed and it has recommended courses and qualifications linked.
     * Expected Outcome: A list with 2 recommended courses tiles and 1 tile with a recommended qualification should be displayed.
     */
    public static testMethod void getRecommendationTilesProductsOrder3Test() {
        User uDelegate = [SELECT Id, Email FROM User WHERE Email = 'test@test.com'];
        Contact contactDelegate = [SELECT Id, Email, FirstName, Phone, LastName FROM Contact WHERE Email = 'test@test.com' LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];

        //create recommended products
        insertRecommendedProductsOrder3(prod.Id);
        //create training event and enrollment
        Training_Event__c t = [SELECT Id FROM Training_Event__c LIMIT 1];
        Training_Translations__c trainingTransl = [SELECT Id FROM Training_Translations__c LIMIT 1];
        Enrollment__c enr = [SELECT Id FROM Enrollment__c LIMIT 1];

        List<Tile> recommendationTiles  = new List<Tile>();
        Test.startTest();
        System.runAs(uDelegate){
            String listTiles = RecommendationUserController.getRecommendationTiles(enr.Id);
            recommendationTiles = (List<Tile>)System.JSON.deserialize(listTiles, List<Tile>.class);
        }
        Test.stopTest();

        Integer qualificationCounter = 0;
        Integer courseCounter = 0;
        String colorQualification = '';
        for(Tile tile : recommendationTiles){
            if(tile.type == 'Course') courseCounter++;
            if(tile.type == 'Qualification') {
                qualificationCounter++;
                colorQualification = tile.colour;
            }
        }
        System.assertEquals(3, recommendationTiles.size());
        System.assertEquals(2, courseCounter);
        System.assertEquals(1, qualificationCounter);
    }

    /**
     * Scenario: An enrollment is accessed and it has recommended courses and qualifications linked.
     * Expected Outcome: A list with 2 recommended courses tiles and 1 tile with a recommended qualification should be displayed.
     */
    public static testMethod void getRecommendationTilesProductsOrder4Test() {
        User uDelegate = [SELECT Id, Email FROM User WHERE Email = 'test@test.com'];
        Contact contactDelegate = [SELECT Id, Email, FirstName, Phone, LastName FROM Contact WHERE Email = 'test@test.com' LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];

        //create recommended products
        insertRecommendedProductsOrder4(prod.Id);
        //create training event and enrollment
        Training_Event__c t = [SELECT Id FROM Training_Event__c LIMIT 1];
        Training_Translations__c trainingTransl = [SELECT Id FROM Training_Translations__c LIMIT 1];
        Enrollment__c enr = [SELECT Id FROM Enrollment__c LIMIT 1];

        List<Tile> recommendationTiles  = new List<Tile>();
        Test.startTest();
        System.runAs(uDelegate){
            String listTiles = RecommendationUserController.getRecommendationTiles(enr.Id);
            recommendationTiles = (List<Tile>)System.JSON.deserialize(listTiles, List<Tile>.class);
        }
        Test.stopTest();

        Integer qualificationCounter = 0;
        Integer courseCounter = 0;
        String colorQualification = '';
        for(Tile tile : recommendationTiles){
            if(tile.type == 'Course') courseCounter++;
            if(tile.type == 'Qualification') {
                qualificationCounter++;
                colorQualification = tile.colour;
            }
        }
        System.assertEquals(4, recommendationTiles.size());
        System.assertEquals(3, courseCounter);
        System.assertEquals(1, qualificationCounter);
    }

    /**
     * Scenario: An enrollment is accessed and it has recommended courses and qualifications linked.
     * Expected Outcome: A list with 2 recommended courses and 1 qualification tiles should be displayed.
     */
    public static testMethod void getRecommendationTilesProductsOrder5Test() {
        User uDelegate = [SELECT Id, Email FROM User WHERE Email = 'test@test.com'];
        Contact contactDelegate = [SELECT Id, Email, FirstName, Phone, LastName FROM Contact WHERE Email = 'test@test.com' LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];

        //create recommended products
        insertRecommendedProductsOrder5(prod.Id);
        //create training event and enrollment
        Training_Event__c t = [SELECT Id FROM Training_Event__c LIMIT 1];
        Training_Translations__c trainingTransl = [SELECT Id FROM Training_Translations__c LIMIT 1];
        Enrollment__c enr = [SELECT Id FROM Enrollment__c LIMIT 1];

        List<Tile> recommendationTiles  = new List<Tile>();
        Test.startTest();
        System.runAs(uDelegate){
            String listTiles = RecommendationUserController.getRecommendationTiles(enr.Id);
            recommendationTiles = (List<Tile>)System.JSON.deserialize(listTiles, List<Tile>.class);
        }
        Test.stopTest();

        Integer qualificationCounter = 0;
        Integer courseCounter = 0;
        String colorQualification = '';
        for(Tile tile : recommendationTiles){
            if(tile.type == 'Course') courseCounter++;
            if(tile.type == 'Qualification') {
                qualificationCounter++;
                colorQualification = tile.colour;
            }
        }
        System.assertEquals(3, recommendationTiles.size());
        System.assertEquals(2, courseCounter);
        System.assertEquals(1, qualificationCounter);
    }

    /**
     * Scenario: An enrollment is accessed and it has recommended courses and qualifications linked.
     * Expected Outcome: A list with 4 recommended courses tiles and 1 tile with a recommended qualification should be displayed.
     */
    public static testMethod void getRecommendationTilesProductsOrder6Test() {
        User uDelegate = [SELECT Id, Email FROM User WHERE Email = 'test@test.com'];
        Contact contactDelegate = [SELECT Id, Email, FirstName, Phone, LastName FROM Contact WHERE Email = 'test@test.com' LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];

        //create recommended products
        insertRecommendedProductsOrder6(prod.Id);
        //create training event and enrollment
        Training_Event__c t = [SELECT Id FROM Training_Event__c LIMIT 1];
        Training_Translations__c trainingTransl = [SELECT Id FROM Training_Translations__c LIMIT 1];
        Enrollment__c enr = [SELECT Id FROM Enrollment__c LIMIT 1];

        List<Tile> recommendationTiles  = new List<Tile>();
        Test.startTest();
        System.runAs(uDelegate){
            String listTiles = RecommendationUserController.getRecommendationTiles(enr.Id);
            recommendationTiles = (List<Tile>)System.JSON.deserialize(listTiles, List<Tile>.class);
        }
        Test.stopTest();

        Integer qualificationCounter = 0;
        Integer courseCounter = 0;
        String colorQualification = '';
        for(Tile tile : recommendationTiles){
            if(tile.type == 'Course') courseCounter++;
            if(tile.type == 'Qualification') {
                qualificationCounter++;
                colorQualification = tile.colour;
            }
        }
        System.assertEquals(3, recommendationTiles.size());
        System.assertEquals(2, courseCounter);
        System.assertEquals(1, qualificationCounter);
    }

    /**
     * Scenario: An enrollment is accessed and it has recommended courses and qualifications linked.
     * Expected Outcome: A list with 2 recommended courses tiles and 1 tile with a recommended qualification should be displayed.
     */
    public static testMethod void getRecommendationTilesProductsOrder7Test() {
        User uDelegate = [SELECT Id, Email FROM User WHERE Email = 'test@test.com'];
        Contact contactDelegate = [SELECT Id, Email, FirstName, Phone, LastName FROM Contact WHERE Email = 'test@test.com' LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];

        //create recommended products
        insertRecommendedProductsOrder7(prod.Id);
        //create training event and enrollment
        Training_Event__c t = [SELECT Id FROM Training_Event__c LIMIT 1];
        Training_Translations__c trainingTransl = [SELECT Id FROM Training_Translations__c LIMIT 1];
        Enrollment__c enr = [SELECT Id FROM Enrollment__c LIMIT 1];

        List<Tile> recommendationTiles  = new List<Tile>();
        Test.startTest();
        System.runAs(uDelegate){
            String listTiles = RecommendationUserController.getRecommendationTiles(enr.Id);
            recommendationTiles = (List<Tile>)System.JSON.deserialize(listTiles, List<Tile>.class);
        }
        Test.stopTest();

        Integer qualificationCounter = 0;
        Integer courseCounter = 0;
        String colorQualification = '';
        for(Tile tile : recommendationTiles){
            if(tile.type == 'Course') courseCounter++;
            if(tile.type == 'Qualification') {
                qualificationCounter++;
                colorQualification = tile.colour;
            }
        }
        System.assertEquals(3, recommendationTiles.size());
        System.assertEquals(2, courseCounter);
        System.assertEquals(1, qualificationCounter);
    }

    /**
     * Scenario: An enrollment is accessed and it has recommended courses and qualifications linked.
     * Expected Outcome: A list with 2 recommended courses tiles and 1 tile with a recommended qualification should be displayed.
     */
    public static testMethod void getRecommendationTilesProductsOrder8Test() {
        User uDelegate = [SELECT Id, Email FROM User WHERE Email = 'test@test.com'];
        Contact contactDelegate = [SELECT Id, Email, FirstName, Phone, LastName FROM Contact WHERE Email = 'test@test.com' LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];

        //create recommended products
        insertRecommendedProductsOrder8(prod.Id);
        //create training event and enrollment
        Training_Event__c t = [SELECT Id FROM Training_Event__c LIMIT 1];
        Training_Translations__c trainingTransl = [SELECT Id FROM Training_Translations__c LIMIT 1];
        Enrollment__c enr = [SELECT Id FROM Enrollment__c LIMIT 1];

        List<Tile> recommendationTiles  = new List<Tile>();
        Test.startTest();
        System.runAs(uDelegate){
            String listTiles = RecommendationUserController.getRecommendationTiles(enr.Id);
            recommendationTiles = (List<Tile>)System.JSON.deserialize(listTiles, List<Tile>.class);
        }
        Test.stopTest();

        Integer qualificationCounter = 0;
        Integer courseCounter = 0;
        String colorQualification = '';
        for(Tile tile : recommendationTiles){
            if(tile.type == 'Course') courseCounter++;
            if(tile.type == 'Qualification') {
                qualificationCounter++;
                colorQualification = tile.colour;
            }
        }
        System.assertEquals(3, recommendationTiles.size());
        System.assertEquals(2, courseCounter);
        System.assertEquals(1, qualificationCounter);
    }

    /**
     * Scenario: An enrollment is accessed and it has recommended courses and qualifications linked.
     * Expected Outcome: A list with 2 recommended courses tiles and 1 tile with a recommended qualification should be displayed.
     */
    public static testMethod void getRecommendationTilesProductsOrder9Test() {
        User uDelegate = [SELECT Id, Email FROM User WHERE Email = 'test@test.com'];
        Contact contactDelegate = [SELECT Id, Email, FirstName, Phone, LastName FROM Contact WHERE Email = 'test@test.com' LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];

        //create recommended products
        insertRecommendedProductsOrder9(prod.Id);
        //create training event and enrollment
        Training_Event__c t = [SELECT Id FROM Training_Event__c LIMIT 1];
        Training_Translations__c trainingTransl = [SELECT Id FROM Training_Translations__c LIMIT 1];
        Enrollment__c enr = [SELECT Id FROM Enrollment__c LIMIT 1];

        List<Tile> recommendationTiles  = new List<Tile>();
        Test.startTest();
        System.runAs(uDelegate){
            String listTiles = RecommendationUserController.getRecommendationTiles(enr.Id);
            recommendationTiles = (List<Tile>)System.JSON.deserialize(listTiles, List<Tile>.class);
        }
        Test.stopTest();

        Integer qualificationCounter = 0;
        Integer courseCounter = 0;
        String colorQualification = '';
        for(Tile tile : recommendationTiles){
            if(tile.type == 'Course') courseCounter++;
            if(tile.type == 'Qualification') {
                qualificationCounter++;
                colorQualification = tile.colour;
            }
        }
        System.assertEquals(3, recommendationTiles.size());
        System.assertEquals(2, courseCounter);
        System.assertEquals(1, qualificationCounter);
    }

    /**
     * Scenario: An enrollment is accessed and it has recommended courses and qualifications linked.
     * Expected Outcome: A list with 2 recommended courses tiles and 1 tile with a recommended qualification should be displayed.
     */
    public static testMethod void getRecommendationTilesProductsOrder10Test() {
        User uDelegate = [SELECT Id, Email FROM User WHERE Email = 'test@test.com'];
        Contact contactDelegate = [SELECT Id, Email, FirstName, Phone, LastName FROM Contact WHERE Email = 'test@test.com' LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];

        //create recommended products
        insertRecommendedProductsOrder10(prod.Id);
        //create training event and enrollment
        Training_Event__c t = [SELECT Id FROM Training_Event__c LIMIT 1];
        Training_Translations__c trainingTransl = [SELECT Id FROM Training_Translations__c LIMIT 1];
        Enrollment__c enr = [SELECT Id FROM Enrollment__c LIMIT 1];

        List<Tile> recommendationTiles  = new List<Tile>();
        Test.startTest();
        System.runAs(uDelegate){
            String listTiles = RecommendationUserController.getRecommendationTiles(enr.Id);
            recommendationTiles = (List<Tile>)System.JSON.deserialize(listTiles, List<Tile>.class);
        }
        Test.stopTest();

        Integer qualificationCounter = 0;
        Integer courseCounter = 0;
        String colorQualification = '';
        for(Tile tile : recommendationTiles){
            if(tile.type == 'Course') courseCounter++;
            if(tile.type == 'Qualification') {
                qualificationCounter++;
                colorQualification = tile.colour;
            }
        }
        System.assertEquals(3, recommendationTiles.size());
        System.assertEquals(2, courseCounter);
        System.assertEquals(1, qualificationCounter);
    }

    /**
     * Scenario: An enrollment is accessed and it has recommended courses and qualifications linked.
     * Expected Outcome: A list with 2 recommended courses tiles and 1 tile with a recommended qualification should be displayed.
     */
    public static testMethod void getRecommendationTilesProductsOrder11Test() {
        User uDelegate = [SELECT Id, Email FROM User WHERE Email = 'test@test.com'];
        Contact contactDelegate = [SELECT Id, Email, FirstName, Phone, LastName FROM Contact WHERE Email = 'test@test.com' LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];

        //create recommended products
        insertRecommendedProductsOrder11(prod.Id);
        //create training event and enrollment
        Training_Event__c t = [SELECT Id FROM Training_Event__c LIMIT 1];
        Training_Translations__c trainingTransl = [SELECT Id FROM Training_Translations__c LIMIT 1];
        Enrollment__c enr = [SELECT Id FROM Enrollment__c LIMIT 1];

        List<Tile> recommendationTiles  = new List<Tile>();
        Test.startTest();
        System.runAs(uDelegate){
            String listTiles = RecommendationUserController.getRecommendationTiles(enr.Id);
            recommendationTiles = (List<Tile>)System.JSON.deserialize(listTiles, List<Tile>.class);
        }
        Test.stopTest();

        Integer qualificationCounter = 0;
        Integer courseCounter = 0;
        String colorQualification = '';
        for(Tile tile : recommendationTiles){
            if(tile.type == 'Course') courseCounter++;
            if(tile.type == 'Qualification') {
                qualificationCounter++;
                colorQualification = tile.colour;
            }
        }
        System.assertEquals(3, recommendationTiles.size());
        System.assertEquals(2, courseCounter);
        System.assertEquals(1, qualificationCounter);
    }

    /**
     * Scenario: An enrollment is accessed and it has recommended courses and qualifications linked.
     * Expected Outcome: A list with 2 recommended courses tiles and 1 tile with a recommended qualification should be displayed.
     */
    public static testMethod void getRecommendationTilesProductsOrder12Test() {
        User uDelegate = [SELECT Id, Email FROM User WHERE Email = 'test@test.com'];
        Contact contactDelegate = [SELECT Id, Email, FirstName, Phone, LastName FROM Contact WHERE Email = 'test@test.com' LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];

        //create recommended products
        insertRecommendedProductsOrder12(prod.Id);
        //create training event and enrollment
        Training_Event__c t = [SELECT Id FROM Training_Event__c LIMIT 1];
        Training_Translations__c trainingTransl = [SELECT Id FROM Training_Translations__c LIMIT 1];
        Enrollment__c enr = [SELECT Id FROM Enrollment__c LIMIT 1];

        List<Tile> recommendationTiles  = new List<Tile>();
        Test.startTest();
        System.runAs(uDelegate){
            String listTiles = RecommendationUserController.getRecommendationTiles(enr.Id);
            recommendationTiles = (List<Tile>)System.JSON.deserialize(listTiles, List<Tile>.class);
        }
        Test.stopTest();

        Integer qualificationCounter = 0;
        Integer courseCounter = 0;
        String colorQualification = '';
        for(Tile tile : recommendationTiles){
            if(tile.type == 'Course') courseCounter++;
            if(tile.type == 'Qualification') {
                qualificationCounter++;
                colorQualification = tile.colour;
            }
        }
        System.assertEquals(3, recommendationTiles.size());
        System.assertEquals(2, courseCounter);
        System.assertEquals(1, qualificationCounter);
    }

    /**
     * Scenario: An enrollment is accessed by the system admin and it has not any recommended course or qualification.
     * Expected Outcome: No list should be displayed with recommendations.
     */
    public static testMethod void getRecommendationTilesProductSystemAdminUserTest() {
        User uDelegate = [SELECT Id, Email FROM User WHERE Email = 'test@test.com'];

        Contact contactDelegate = [SELECT Id, Email, FirstName, Phone, LastName FROM Contact WHERE Email = 'test@test.com' LIMIT 1];

        string productName = 'ISO 9001';
        Product2 prod = bg_UnitTestHelper.GetProductFee(productName);
        prod = [SELECT Id, Course_Duration_Days__c, Course_Name_English__c FROM Product2 WHERE Id =:prod.Id];
        prod.Course_Duration_Days__c = 10;
        prod.Course_Name_English__c = 'English Name Course';
        update prod;

        Qualification__c qualification = new Qualification__c(Name = 'UK - ISO 9001 Qualification', Status__c = 'Active', RecordTypeId = '0124G000000KNfBQAW');
        insert qualification;

        Qualification_Course__c qualificationCourse = new Qualification_Course__c(Product__c = prod.Id, Qualification__c = qualification.Id);
        insert qualificationCourse;

        //create recommended products
        insertRecommendedProductsOrder7(prod.Id);

        //create training event and enrollment
        Training_Event__c t = new Training_Event__c(Opportunity_Owner__c = uDelegate.Id, Course__c = prod.Id, End_Date2__c = Date.today() - 30, Max_seats__c = 3, Start_date__c = Date.today() + 8);
        insert t;

        Training_Translations__c trainingTransl = [SELECT Id FROM Training_Translations__c LIMIT 1];

        Enrollment__c enr = new Enrollment__c(Training_Translations__c = trainingTransl.Id, Delegate_name__c = contactDelegate.Id, Training_Event__c = t.Id, Booking_status__c = 'Application', Online_Training_Expiry_Date__c = Date.today() + 3, Litmos_Details_Emailed__c = Date.today(), Invoice_status__c = 'Completed');    
        insert enr;

        List<Tile> recommendationTiles  = new List<Tile>();
        Test.startTest();
        String listTiles = RecommendationUserController.getRecommendationTiles(enr.Id);
        recommendationTiles = (List<Tile>)System.JSON.deserialize(listTiles, List<Tile>.class);
        Test.stopTest();

        Integer qualificationCounter = 0;
        Integer courseCounter = 0;
        String colorQualification = '';

        for(Tile tile : recommendationTiles){
            if(tile.type == 'Course') courseCounter++;
            if(tile.type == 'Qualification') {
                qualificationCounter++;
                colorQualification = tile.colour;
            }
        }

        System.assertEquals(0, recommendationTiles.size());
        System.assertEquals(0, courseCounter);
        System.assertEquals(0, qualificationCounter);
    }


    //methods to create and oreder the recommended tiles

    private static void insertRecommendedProductsOrder1(String mainProductId){

        List<Recommendation__c> recommendedProducts = new List<Recommendation__c>();
        List<Product2> productStagesUpdate = new List<Product2>();

        Product2 prod = [SELECT Id FROM Product2 WHERE Id =:mainProductId];

        //insert 4 recommended products to the main product
        string productName1 = 'ISO 9111';
        Product2 prodRecommended1 = bg_UnitTestHelper.GetProductFee(productName1);
        prodRecommended1.Training_Stage__c = 'Understand';
        productStagesUpdate.add(prodRecommended1);
        Recommendation__c recommendedProduct1 = new Recommendation__c(Main_Course__c = prod.Id, Product_To_Recommend__c = prodRecommended1.Id, Colour_Scheme__c = '#B3E3E6', Type__c = 'Course');
        recommendedProducts.add(recommendedProduct1);

        string productName2 = 'ISO 9114';
        Product2 prodRecommended2 = bg_UnitTestHelper.GetProductFee(productName2);
        prodRecommended2.Training_Stage__c = 'Understand';
        productStagesUpdate.add(prodRecommended2);
        Recommendation__c recommendedProduct2 = new Recommendation__c(Main_Course__c = prod.Id, Product_To_Recommend__c = prodRecommended2.Id, Colour_Scheme__c = '#B3E3E6', Type__c = 'Course');
        recommendedProducts.add(recommendedProduct2);

        string productName3 = 'ISO 9011';
        Product2 prodRecommended3 = bg_UnitTestHelper.GetProductFee(productName2);
        prodRecommended3.Training_Stage__c = 'Implement';
        productStagesUpdate.add(prodRecommended3);
        Recommendation__c recommendedProduct3 = new Recommendation__c(Main_Course__c = prod.Id, Product_To_Recommend__c = prodRecommended3.Id, Colour_Scheme__c = '#B3E3E6', Type__c = 'Course');
        recommendedProducts.add(recommendedProduct3);

        //recommendation to be removed - course completed
        Recommendation__c recommendedProdCompleted = new Recommendation__c(Main_Course__c = prod.Id, Product_To_Recommend__c = prod.Id, Colour_Scheme__c = '#B3E3E6', Type__c = 'Course');
        recommendedProducts.add(recommendedProdCompleted);
        
        update productStagesUpdate;
        insert recommendedProducts;

    }

    private static void insertRecommendedProductsOrder2(String mainProductId){

        List<Recommendation__c> recommendedProducts = new List<Recommendation__c>();
        List<Product2> productStagesUpdate = new List<Product2>();

        Product2 prod = [SELECT Id FROM Product2 WHERE Id =:mainProductId];

        //insert 2 recommended products to the main product
        string productName3 = 'ISO 9014';
        Product2 prodRecommended3 = bg_UnitTestHelper.GetProductFee(productName3);
        prodRecommended3.Training_Stage__c = 'Prove it’s working';
        productStagesUpdate.add(prodRecommended3);
        Recommendation__c recommendedProduct3 = new Recommendation__c(Main_Course__c = prod.Id, Product_To_Recommend__c = prodRecommended3.Id, Colour_Scheme__c = '#B3E3E6', Type__c = 'Course');
        recommendedProducts.add(recommendedProduct3);

        string productName4 = 'ISO 9005';
        Product2 prodRecommended4 = bg_UnitTestHelper.GetProductFee(productName4);
        prodRecommended4.Training_Stage__c = 'Build resilience';
        productStagesUpdate.add(prodRecommended4);
        Recommendation__c recommendedProduct4 = new Recommendation__c(Main_Course__c = prod.Id, Product_To_Recommend__c = prodRecommended4.Id, Colour_Scheme__c = '#B3E3E6', Type__c = 'Course');
        recommendedProducts.add(recommendedProduct4);


        //recommendation to be removed - course completed
        Recommendation__c recommendedProdCompleted = new Recommendation__c(Main_Course__c = prod.Id, Product_To_Recommend__c = prod.Id, Colour_Scheme__c = '#B3E3E6', Type__c = 'Course');
        recommendedProducts.add(recommendedProdCompleted);
        
        update productStagesUpdate;
        insert recommendedProducts;

    }

    private static void insertRecommendedProductsOrder3(String mainProductId){

        List<Recommendation__c> recommendedProducts = new List<Recommendation__c>();
        List<Product2> productStagesUpdate = new List<Product2>();

        Product2 prod = [SELECT Id FROM Product2 WHERE Id =:mainProductId];


        //insert 2 recommended products to the main product
        string productName1 = 'ISO 9111';
        Product2 prodRecommended1 = bg_UnitTestHelper.GetProductFee(productName1);
        prodRecommended1.Training_Stage__c = 'Implement';
        productStagesUpdate.add(prodRecommended1);
        Recommendation__c recommendedProduct1 = new Recommendation__c(Main_Course__c = prod.Id, Product_To_Recommend__c = prodRecommended1.Id, Colour_Scheme__c = '#B3E3E6', Type__c = 'Course');
        recommendedProducts.add(recommendedProduct1);

        string productName2 = 'ISO 9011';
        Product2 prodRecommended2 = bg_UnitTestHelper.GetProductFee(productName2);
        prodRecommended2.Training_Stage__c = 'Understand';
        productStagesUpdate.add(prodRecommended2);
        Recommendation__c recommendedProduct2 = new Recommendation__c(Main_Course__c = prod.Id, Product_To_Recommend__c = prodRecommended2.Id, Colour_Scheme__c = '#B3E3E6', Type__c = 'Course');
        recommendedProducts.add(recommendedProduct2);

        //recommendation to be removed - course completed
        Recommendation__c recommendedProdCompleted = new Recommendation__c(Main_Course__c = prod.Id, Product_To_Recommend__c = prod.Id, Colour_Scheme__c = '#B3E3E6', Type__c = 'Course');
        recommendedProducts.add(recommendedProdCompleted);
        
        update productStagesUpdate;
        insert recommendedProducts;

    }

    private static void insertRecommendedProductsOrder4(String mainProductId){

        List<Recommendation__c> recommendedProducts = new List<Recommendation__c>();
        List<Product2> productStagesUpdate = new List<Product2>();

        Product2 prod = [SELECT Id FROM Product2 WHERE Id =:mainProductId];

        //insert 2 recommended products to the main product
        string productName3 = 'ISO 9014';
        Product2 prodRecommended3 = bg_UnitTestHelper.GetProductFee(productName3);
        prodRecommended3.Training_Stage__c = 'Build resilience';
        productStagesUpdate.add(prodRecommended3);
        Recommendation__c recommendedProduct3 = new Recommendation__c(Main_Course__c = prod.Id, Product_To_Recommend__c = prodRecommended3.Id, Colour_Scheme__c = '#B3E3E6', Type__c = 'Course');
        recommendedProducts.add(recommendedProduct3);

        string productName4 = 'ISO 9005';
        Product2 prodRecommended4 = bg_UnitTestHelper.GetProductFee(productName4);
        prodRecommended4.Training_Stage__c = 'Prove it’s working';
        productStagesUpdate.add(prodRecommended4);
        Recommendation__c recommendedProduct4 = new Recommendation__c(Main_Course__c = prod.Id, Product_To_Recommend__c = prodRecommended4.Id, Colour_Scheme__c = '#B3E3E6', Type__c = 'Course');
        recommendedProducts.add(recommendedProduct4);
        

        string productName1 = 'ISO 9011';
        Product2 prodRecommended1 = bg_UnitTestHelper.GetProductFee(productName1);
        prodRecommended1.Training_Stage__c = 'Build resilience';
        prodRecommended1.Product_Name_Local__c = prodRecommended1.Name;
        productStagesUpdate.add(prodRecommended1);
        Recommendation__c recommendedProduct1 = new Recommendation__c(Main_Course__c = prod.Id, Product_To_Recommend__c = prodRecommended1.Id, Colour_Scheme__c = '#B3E3E6', Type__c = 'Course');
        recommendedProducts.add(recommendedProduct1);

        /*string productName2 = 'ISO 9011';
        Product2 prodRecommended2 = bg_UnitTestHelper.GetProductFee(productName2);
        prodRecommended2.Training_Stage__c = 'Build resilience';
        prodRecommended2.Product_Name_Local__c = prodRecommended2.Name;
        productStagesUpdate.add(prodRecommended2);
        Recommendation__c recommendedProduct2 = new Recommendation__c(Main_Course__c = prod.Id, Product_To_Recommend__c = prodRecommended2.Id, Colour_Scheme__c = '#B3E3E6', Type__c = 'Course');
        recommendedProducts.add(recommendedProduct2);

        string productName3 = 'ISO 9014';
        Product2 prodRecommended3 = bg_UnitTestHelper.GetProductFee(productName3);
        prodRecommended3.Training_Stage__c = 'Understand';
        prodRecommended3.Product_Name_Local__c = prodRecommended3.Name;
        productStagesUpdate.add(prodRecommended3);
        Recommendation__c recommendedProduct3 = new Recommendation__c(Main_Course__c = prod.Id, Product_To_Recommend__c = prodRecommended3.Id, Colour_Scheme__c = '#B3E3E6', Type__c = 'Course');
        recommendedProducts.add(recommendedProduct3);

        string productName4 = 'ISO 9005';
        Product2 prodRecommended4 = bg_UnitTestHelper.GetProductFee(productName4);
        prodRecommended4.Training_Stage__c = 'Prove it’s working';
        prodRecommended4.Product_Name_Local__c = prodRecommended4.Name;
        productStagesUpdate.add(prodRecommended4);
        Recommendation__c recommendedProduct4 = new Recommendation__c(Main_Course__c = prod.Id, Product_To_Recommend__c = prodRecommended4.Id, Colour_Scheme__c = '#B3E3E6', Type__c = 'Course');
        recommendedProducts.add(recommendedProduct4);*/

        //recommendation to be removed - course completed
        Recommendation__c recommendedProdCompleted = new Recommendation__c(Main_Course__c = prod.Id, Product_To_Recommend__c = prod.Id, Colour_Scheme__c = '#B3E3E6', Type__c = 'Course');
        recommendedProducts.add(recommendedProdCompleted);
        
        update productStagesUpdate;
        insert recommendedProducts;

        /*Qualification__c qualification = new Qualification__c(Name = 'UK - ISO 9001 Qualification', Status__c = 'Active', RecordTypeId = '0124G000000KNfBQAW');
        insert qualification;

        Qualification_Course__c qualificationCourse = new Qualification_Course__c(Product__c = prod.Id, Qualification__c = qualification.Id);
        insert qualificationCourse;*/


    }

    private static void insertRecommendedProductsOrder5(String mainProductId){

        List<Recommendation__c> recommendedProducts = new List<Recommendation__c>();
        List<Product2> productStagesUpdate = new List<Product2>();

        Product2 prod = [SELECT Id FROM Product2 WHERE Id =:mainProductId];

        //insert 4 recommended products to the main product
        string productName1 = 'ISO 9111';
        Product2 prodRecommended1 = bg_UnitTestHelper.GetProductFee(productName1);
        prodRecommended1.Training_Stage__c = 'Prove it’s working';
        productStagesUpdate.add(prodRecommended1);
        Recommendation__c recommendedProduct1 = new Recommendation__c(Main_Course__c = prod.Id, Product_To_Recommend__c = prodRecommended1.Id, Colour_Scheme__c = '#B3E3E6', Type__c = 'Course');
        recommendedProducts.add(recommendedProduct1);

        string productName3 = 'ISO 9014';
        Product2 prodRecommended3 = bg_UnitTestHelper.GetProductFee(productName3);
        prodRecommended3.Training_Stage__c = 'Understand';
        prodRecommended3.Product_Name_Local__c = prodRecommended3.Name;
        productStagesUpdate.add(prodRecommended3);
        Recommendation__c recommendedProduct3 = new Recommendation__c(Main_Course__c = prod.Id, Product_To_Recommend__c = prodRecommended3.Id, Colour_Scheme__c = '#B3E3E6', Type__c = 'Course');
        recommendedProducts.add(recommendedProduct3);

        /*string productName1 = 'ISO 9111';
        Product2 prodRecommended1 = bg_UnitTestHelper.GetProductFee(productName1);
        prodRecommended1.Training_Stage__c = 'Understand';
        prodRecommended1.Product_Name_Local__c = prodRecommended1.Name;
        productStagesUpdate.add(prodRecommended1);
        Recommendation__c recommendedProduct1 = new Recommendation__c(Main_Course__c = prod.Id, Product_To_Recommend__c = prodRecommended1.Id, Colour_Scheme__c = '#B3E3E6', Type__c = 'Course');
        recommendedProducts.add(recommendedProduct1);

        string productName2 = 'ISO 9011';
        Product2 prodRecommended2 = bg_UnitTestHelper.GetProductFee(productName2);
        prodRecommended2.Training_Stage__c = 'Understand';
        prodRecommended2.Product_Name_Local__c = prodRecommended2.Name;
        productStagesUpdate.add(prodRecommended2);
        Recommendation__c recommendedProduct2 = new Recommendation__c(Main_Course__c = prod.Id, Product_To_Recommend__c = prodRecommended2.Id, Colour_Scheme__c = '#B3E3E6', Type__c = 'Course');
        recommendedProducts.add(recommendedProduct2);

        string productName3 = 'ISO 9014';
        Product2 prodRecommended3 = bg_UnitTestHelper.GetProductFee(productName3);
        prodRecommended3.Training_Stage__c = 'Prove it’s working';
        prodRecommended3.Product_Name_Local__c = prodRecommended3.Name;
        productStagesUpdate.add(prodRecommended3);
        Recommendation__c recommendedProduct3 = new Recommendation__c(Main_Course__c = prod.Id, Product_To_Recommend__c = prodRecommended3.Id, Colour_Scheme__c = '#B3E3E6', Type__c = 'Course');
        recommendedProducts.add(recommendedProduct3);

        string productName4 = 'ISOF 9005';
        Product2 prodRecommended4 = bg_UnitTestHelper.GetProductFee(productName4);
        prodRecommended4.Training_Stage__c = 'Prove it’s working';
        prodRecommended4.Product_Name_Local__c = prodRecommended4.Name;
        productStagesUpdate.add(prodRecommended4);
        Recommendation__c recommendedProduct4 = new Recommendation__c(Main_Course__c = prod.Id, Product_To_Recommend__c = prodRecommended4.Id, Colour_Scheme__c = '#B3E3E6', Type__c = 'Course');
        recommendedProducts.add(recommendedProduct4);*/

        //recommendation to be removed - course completed
        Recommendation__c recommendedProdCompleted = new Recommendation__c(Main_Course__c = prod.Id, Product_To_Recommend__c = prod.Id, Colour_Scheme__c = '#B3E3E6', Type__c = 'Course');
        recommendedProducts.add(recommendedProdCompleted);
        
        update productStagesUpdate;
        insert recommendedProducts;

    }

    private static void insertRecommendedProductsOrder6(String mainProductId){

        List<Recommendation__c> recommendedProducts = new List<Recommendation__c>();
        List<Product2> productStagesUpdate = new List<Product2>();

        Product2 prod = [SELECT Id FROM Product2 WHERE Id =:mainProductId];

        //insert 2 recommended products to the main product
        /*string productName1 = 'ISO 9111';
        Product2 prodRecommended1 = bg_UnitTestHelper.GetProductFee(productName1);
        prodRecommended1.Training_Stage__c = 'Implement';
        prodRecommended1.Product_Name_Local__c = prodRecommended1.Name;
        productStagesUpdate.add(prodRecommended1);
        Recommendation__c recommendedProduct1 = new Recommendation__c(Main_Course__c = prod.Id, Product_To_Recommend__c = prodRecommended1.Id, Colour_Scheme__c = '#B3E3E6', Type__c = 'Course');
        recommendedProducts.add(recommendedProduct1);

        string productName2 = 'ISO 9011';
        Product2 prodRecommended2 = bg_UnitTestHelper.GetProductFee(productName2);
        prodRecommended2.Training_Stage__c = 'Implement';
        prodRecommended2.Product_Name_Local__c = prodRecommended2.Name;
        productStagesUpdate.add(prodRecommended2);
        Recommendation__c recommendedProduct2 = new Recommendation__c(Main_Course__c = prod.Id, Product_To_Recommend__c = prodRecommended2.Id, Colour_Scheme__c = '#B3E3E6', Type__c = 'Course');
        recommendedProducts.add(recommendedProduct2);*/

        string productName3 = 'ISO 9014';
        Product2 prodRecommended3 = bg_UnitTestHelper.GetProductFee(productName3);
        prodRecommended3.Training_Stage__c = 'Understand';
        prodRecommended3.Product_Name_Local__c = prodRecommended3.Name;
        productStagesUpdate.add(prodRecommended3);
        Recommendation__c recommendedProduct3 = new Recommendation__c(Main_Course__c = prod.Id, Product_To_Recommend__c = prodRecommended3.Id, Colour_Scheme__c = '#B3E3E6', Type__c = 'Course');
        recommendedProducts.add(recommendedProduct3);

        string productName4 = 'ISOF 9005';
        Product2 prodRecommended4 = bg_UnitTestHelper.GetProductFee(productName4);
        prodRecommended4.Training_Stage__c = 'Build resilience';
        prodRecommended4.Product_Name_Local__c = prodRecommended4.Name;
        productStagesUpdate.add(prodRecommended4);
        Recommendation__c recommendedProduct4 = new Recommendation__c(Main_Course__c = prod.Id, Product_To_Recommend__c = prodRecommended4.Id, Colour_Scheme__c = '#B3E3E6', Type__c = 'Course');
        recommendedProducts.add(recommendedProduct4);

        //recommendation to be removed - course completed
        Recommendation__c recommendedProdCompleted = new Recommendation__c(Main_Course__c = prod.Id, Product_To_Recommend__c = prod.Id, Colour_Scheme__c = '#B3E3E6', Type__c = 'Course');
        recommendedProducts.add(recommendedProdCompleted);
        
        update productStagesUpdate;
        insert recommendedProducts;

    }

    private static void insertRecommendedProductsOrder7(String mainProductId){

        List<Recommendation__c> recommendedProducts = new List<Recommendation__c>();
        List<Product2> productStagesUpdate = new List<Product2>();

        Product2 prod = [SELECT Id FROM Product2 WHERE Id =:mainProductId];

        //insert 4 recommended products to the main product
        string productName1 = 'ISO 9111';
        Product2 prodRecommended1 = bg_UnitTestHelper.GetProductFee(productName1);
        prodRecommended1.Training_Stage__c = 'Understand';
        productStagesUpdate.add(prodRecommended1);
        Recommendation__c recommendedProduct1 = new Recommendation__c(Main_Course__c = prod.Id, Product_To_Recommend__c = prodRecommended1.Id, Colour_Scheme__c = '#B3E3E6', Type__c = 'Course');
        recommendedProducts.add(recommendedProduct1);

        string productName4 = 'ISO 9005';
        Product2 prodRecommended4 = bg_UnitTestHelper.GetProductFee(productName4);
        prodRecommended4.Training_Stage__c = 'Prove it’s working';
        productStagesUpdate.add(prodRecommended4);
        Recommendation__c recommendedProduct4 = new Recommendation__c(Main_Course__c = prod.Id, Product_To_Recommend__c = prodRecommended4.Id, Colour_Scheme__c = '#B3E3E6', Type__c = 'Course');
        recommendedProducts.add(recommendedProduct4);

        update productStagesUpdate;
        insert recommendedProducts;

    }

    private static void insertRecommendedProductsOrder8(String mainProductId){

        List<Recommendation__c> recommendedProducts = new List<Recommendation__c>();
        List<Product2> productStagesUpdate = new List<Product2>();

        Product2 prod = [SELECT Id FROM Product2 WHERE Id =:mainProductId];

        //insert 2 recommended products to the main product
        string productName1 = 'ISO 9111';
        Product2 prodRecommended1 = bg_UnitTestHelper.GetProductFee(productName1);
        prodRecommended1.Training_Stage__c = 'Implement';
        prodRecommended1.Product_Name_Local__c = prodRecommended1.Name;
        productStagesUpdate.add(prodRecommended1);
        Recommendation__c recommendedProduct1 = new Recommendation__c(Main_Course__c = prod.Id, Product_To_Recommend__c = prodRecommended1.Id, Colour_Scheme__c = '#B3E3E6', Type__c = 'Course');
        recommendedProducts.add(recommendedProduct1);

        string productName4 = 'ISO 9005';
        Product2 prodRecommended4 = bg_UnitTestHelper.GetProductFee(productName4);
        prodRecommended4.Training_Stage__c = 'Prove it’s working';
        productStagesUpdate.add(prodRecommended4);
        Recommendation__c recommendedProduct4 = new Recommendation__c(Main_Course__c = prod.Id, Product_To_Recommend__c = prodRecommended4.Id, Colour_Scheme__c = '#B3E3E6', Type__c = 'Course');
        recommendedProducts.add(recommendedProduct4);
        
        update productStagesUpdate;
        insert recommendedProducts;

    }

    private static void insertRecommendedProductsOrder9(String mainProductId){

        List<Recommendation__c> recommendedProducts = new List<Recommendation__c>();
        List<Product2> productStagesUpdate = new List<Product2>();

        Product2 prod = [SELECT Id FROM Product2 WHERE Id =:mainProductId];

        //insert 2 recommended products to the main product
        string productName1 = 'ISO 9111';
        Product2 prodRecommended1 = bg_UnitTestHelper.GetProductFee(productName1);
        prodRecommended1.Training_Stage__c = 'Implement';
        prodRecommended1.Product_Name_Local__c = prodRecommended1.Name;
        productStagesUpdate.add(prodRecommended1);
        Recommendation__c recommendedProduct1 = new Recommendation__c(Main_Course__c = prod.Id, Product_To_Recommend__c = prodRecommended1.Id, Colour_Scheme__c = '#B3E3E6', Type__c = 'Course');
        recommendedProducts.add(recommendedProduct1);

        string productName4 = 'ISOF 9005';
        Product2 prodRecommended4 = bg_UnitTestHelper.GetProductFee(productName4);
        prodRecommended4.Training_Stage__c = 'Build resilience';
        prodRecommended4.Product_Name_Local__c = prodRecommended4.Name;
        productStagesUpdate.add(prodRecommended4);
        Recommendation__c recommendedProduct4 = new Recommendation__c(Main_Course__c = prod.Id, Product_To_Recommend__c = prodRecommended4.Id, Colour_Scheme__c = '#B3E3E6', Type__c = 'Course');
        recommendedProducts.add(recommendedProduct4);
        
        update productStagesUpdate;
        insert recommendedProducts;

    }

    private static void insertRecommendedProductsOrder10(String mainProductId){

        List<Recommendation__c> recommendedProducts = new List<Recommendation__c>();
        List<Product2> productStagesUpdate = new List<Product2>();

        Product2 prod = [SELECT Id FROM Product2 WHERE Id =:mainProductId];

        //insert 4 recommended products to the main product
        string productName4 = 'ISO 9005';
        Product2 prodRecommended4 = bg_UnitTestHelper.GetProductFee(productName4);
        prodRecommended4.Training_Stage__c = 'Prove it’s working';
        productStagesUpdate.add(prodRecommended4);
        Recommendation__c recommendedProduct4 = new Recommendation__c(Main_Course__c = prod.Id, Product_To_Recommend__c = prodRecommended4.Id, Colour_Scheme__c = '#B3E3E6', Type__c = 'Course');
        recommendedProducts.add(recommendedProduct4);

        string productName1 = 'ISO 9111';
        Product2 prodRecommended1 = bg_UnitTestHelper.GetProductFee(productName1);
        prodRecommended1.Training_Stage__c = 'Implement';
        prodRecommended1.Product_Name_Local__c = prodRecommended1.Name;
        productStagesUpdate.add(prodRecommended1);
        Recommendation__c recommendedProduct1 = new Recommendation__c(Main_Course__c = prod.Id, Product_To_Recommend__c = prodRecommended1.Id, Colour_Scheme__c = '#B3E3E6', Type__c = 'Course');
        recommendedProducts.add(recommendedProduct1);
        
        update productStagesUpdate;
        insert recommendedProducts;

    }

    private static void insertRecommendedProductsOrder11(String mainProductId){

        List<Recommendation__c> recommendedProducts = new List<Recommendation__c>();
        List<Product2> productStagesUpdate = new List<Product2>();

        Product2 prod = [SELECT Id FROM Product2 WHERE Id =:mainProductId];

        //insert 4 recommended products to the main product
        string productName4 = 'ISOF 9005';
        Product2 prodRecommended4 = bg_UnitTestHelper.GetProductFee(productName4);
        prodRecommended4.Training_Stage__c = 'Build resilience';
        prodRecommended4.Product_Name_Local__c = prodRecommended4.Name;
        productStagesUpdate.add(prodRecommended4);
        Recommendation__c recommendedProduct4 = new Recommendation__c(Main_Course__c = prod.Id, Product_To_Recommend__c = prodRecommended4.Id, Colour_Scheme__c = '#B3E3E6', Type__c = 'Course');
        recommendedProducts.add(recommendedProduct4);

        string productName1 = 'ISO 9111';
        Product2 prodRecommended1 = bg_UnitTestHelper.GetProductFee(productName1);
        prodRecommended1.Training_Stage__c = 'Understand';
        productStagesUpdate.add(prodRecommended1);
        Recommendation__c recommendedProduct1 = new Recommendation__c(Main_Course__c = prod.Id, Product_To_Recommend__c = prodRecommended1.Id, Colour_Scheme__c = '#B3E3E6', Type__c = 'Course');
        recommendedProducts.add(recommendedProduct1);

        update productStagesUpdate;
        insert recommendedProducts;

    }

    private static void insertRecommendedProductsOrder12(String mainProductId){

        List<Recommendation__c> recommendedProducts = new List<Recommendation__c>();
        List<Product2> productStagesUpdate = new List<Product2>();

        Product2 prod = [SELECT Id FROM Product2 WHERE Id =:mainProductId];

        //insert 4 recommended products to the main product
        string productName4 = 'ISOF 9005';
        Product2 prodRecommended4 = bg_UnitTestHelper.GetProductFee(productName4);
        prodRecommended4.Training_Stage__c = 'Build resilience';
        prodRecommended4.Product_Name_Local__c = prodRecommended4.Name;
        productStagesUpdate.add(prodRecommended4);
        Recommendation__c recommendedProduct4 = new Recommendation__c(Main_Course__c = prod.Id, Product_To_Recommend__c = prodRecommended4.Id, Colour_Scheme__c = '#B3E3E6', Type__c = 'Course');
        recommendedProducts.add(recommendedProduct4);

        string productName1 = 'ISO 9111';
        Product2 prodRecommended1 = bg_UnitTestHelper.GetProductFee(productName1);
        prodRecommended1.Training_Stage__c = 'Implement';
        prodRecommended1.Product_Name_Local__c = prodRecommended1.Name;
        productStagesUpdate.add(prodRecommended1);
        Recommendation__c recommendedProduct1 = new Recommendation__c(Main_Course__c = prod.Id, Product_To_Recommend__c = prodRecommended1.Id, Colour_Scheme__c = '#B3E3E6', Type__c = 'Course');
        recommendedProducts.add(recommendedProduct1);
        
        update productStagesUpdate;
        insert recommendedProducts;

    }


    public static testMethod void getRecommendationTilesQualificationsTest() {
        List<Qualification__c> qualificationInsert = new List<Qualification__c>();
        List<Qualification_Course__c> qualificationCourseInsert = new List<Qualification_Course__c>();

        User uDelegate = [SELECT Id, Email FROM User WHERE Email = 'test@test.com'];

        Contact contactDelegate = [SELECT Id, Email, FirstName, Phone, LastName FROM Contact WHERE Email = 'test@test.com' LIMIT 1];

        string productName = 'ISO 9001';
        Product2 prod = bg_UnitTestHelper.GetProductFee(productName);
        prod = [SELECT Id, Course_Duration_Days__c FROM Product2 WHERE Id =:prod.Id];
        prod.Course_Duration_Days__c = 10;
        update prod;

        //create qualifications linked to the product
        Qualification__c qualification = new Qualification__c(Name = 'UK - ISO 9001 Qualification', Status__c = 'Active', RecordTypeId = '0124G000000KNfBQAW');
        qualificationInsert.add(qualification);
        Qualification__c qualification2 = new Qualification__c(Name = 'UK - ISO 9011 Qualification2', Status__c = 'Active');
        qualificationInsert.add(qualification2);

        insert qualificationInsert;

        Qualification_Course__c qualificationCourse = new Qualification_Course__c(Product__c = prod.Id, Qualification__c = qualification.Id);
        qualificationCourseInsert.add(qualificationCourse);
        Qualification_Course__c qualificationCourse2 = new Qualification_Course__c(Product__c = prod.Id, Qualification__c = qualification2.Id);
        qualificationCourseInsert.add(qualificationCourse2);

        insert qualificationCourseInsert;

        //qualification to be removed - personal qualification linked to the same qualification - qualification completed
        Personal_Qualification__c personalQualification = new Personal_Qualification__c(Qualification__c = qualification.Id, Delegate__c = contactDelegate.Id);
        insert personalQualification;

        //create training event and enrollment
        Training_Event__c t = new Training_Event__c(Course__c = prod.Id, End_Date2__c = Date.today() - 8, Max_seats__c = 3, Start_date__c = Date.today() + 8);
        insert t;

        Enrollment__c enr = new Enrollment__c(Delegate_name__c = contactDelegate.Id, Training_Event__c = t.Id, Booking_status__c = 'Application', Online_Training_Expiry_Date__c = Date.today() + 3, Litmos_Details_Emailed__c = Date.today(), Invoice_status__c = 'Completed');    
        insert enr;

        List<Tile> recommendationTiles  = new List<Tile>();
        Test.startTest();
        System.runAs(uDelegate){
            String listTiles = RecommendationUserController.getRecommendationTiles(enr.Id);
            recommendationTiles = (List<Tile>)System.JSON.deserialize(listTiles, List<Tile>.class);
        }
        Test.stopTest();
        Integer qualificationCounter = 0;
        Integer courseCounter = 0;
        String colorQualification = '';

        for(Tile tile : recommendationTiles){
            if(tile.type == 'Course') courseCounter++;
            if(tile.type == 'Qualification') {
                qualificationCounter++;
                colorQualification = tile.colour;
            }
        }

        System.assertEquals(1, recommendationTiles.size());
        System.assertEquals(0, courseCounter);
        System.assertEquals(1, qualificationCounter);
        System.assertEquals('#ff8273', colorQualification);

    }

    @TestSetup 
    private static void generateOrgData(){

        Account a = new Account(Name = 'test', BillingCountry = 'GB');
        insert a;

        Contact c = new Contact(AccountId = a.Id, FirstName = 'test', Phone = '07123436542', LastName = 'test', Email = 'test@test.com', MailingCountry = 'GB');
        insert c;

        List<Contact> contacts1 = new List<Contact>{c};
        
        List<User> users = TestData.createPortalUsers(contacts1, true);

        string productName = 'ISO 9001';
        Product2 prod = bg_UnitTestHelper.GetProductFee(productName);
        prod = [SELECT Id, Course_Duration_Days__c, Course_Name_English__c FROM Product2 WHERE Id =:prod.Id];
        prod.Course_Duration_Days__c = 10;
        prod.Course_Name_English__c = 'English Name Course';
        update prod;

        Qualification__c qualification = new Qualification__c(Name = 'UK - ISO 9001 Qualification', Status__c = 'Active', RecordTypeId = '0124G000000KNfBQAW');
        insert qualification;

        Qualification_Course__c qualificationCourse = new Qualification_Course__c(Product__c = prod.Id, Qualification__c = qualification.Id);
        insert qualificationCourse;

        //user
        User uDelegate = users[0];

        Training_Event__c t = new Training_Event__c(Opportunity_Owner__c = uDelegate.Id, Course__c = prod.Id, End_Date2__c = Date.today() - 30, Max_seats__c = 3, Start_date__c = Date.today() + 8);
        insert t;

        Training_Translations__c trainingTransl = new Training_Translations__c(Name = 'UK (English)', Text_Box_1__c = 'This is to certify that', Text_Box_2__c = 'has attended', Text_box_3__c = 'has attended and passed', 
        Course_Number__c = 'Course number', Certified_By_IRCA__c = 'certified by IRCA', Certified_By__c = 'For and on behalf of BSI:', Signature__c = 'https://bsi--c.documentforce.com/servlet/servlet.ImageServer?id=015D0000003ufJw&oid=00DD0000000mhEp',
        Training_Manager__c = 'Commercial Training Director: BSI Training Academy', Certificate_Number__c = 'Certificate Number:', Office_Address__c = 'A member of the BSI Group of Companies.', Booking_Confirmation__c = 'Booking Confirmation', 
        Reminder__c = 'Reminder', Rem_Text1__c = 'We would like to take this opportunity to remind you that you are confirmed to attend:', InH_Text1__c = 'Thank you for arranging an In-company training course with BSI. Please find your course details below.', 
        General_Info__c = 'General Information', Aims__c = 'Aims', Start_Date__c = 'Course Start Date', Contact_Us__c = 'Contact Us', Contact_Email__c = 'training.admin@bsigroup.com', Email_Ending__c = 'We hope you enjoy and benefit from the course you have selected. We look forward to seeing you there!', 
        Email_Header__c = 'https://bsi--c.documentforce.com/servlet/servlet.ImageServer?id=015D0000003uZoe&oid=00DD0000000mhEp', IRCA_Logo__c = 'https://bsi--c.documentforce.com/servlet/servlet.ImageServer?id=015D0000003uZoN&oid=00DD0000000mhEp', 
        Prerequisites__c = 'Prerequisites', Residential_Text1__c = 'You have chosen the following option:', Residential_Text2__c = 'BSI offer a residential option with this course which includes 4 nights accommodation and evening meals starting from', 
        Location__c = 'Venue', Course_Details__c = 'Course Details', Schedule__c = 'The course schedule', Outcomes__c = 'When the course is finished, you should be able to', Contact_Details_for_Email__c = 'If you have any questions about this course, give us a call on +44 0345 086 9000. If you’d like to see our other courses, please visit http://www.bsigroup.com/en-GB/our-services/training-courses/.', 
        Dear__c = 'Dear', Thank_You__c = 'Thank you for booking with BSI. We can confirm your place on the', Exam_Resit__c = 'Exam Resit', ExR_Text2__c = 'Please be at the venue for 9am. The exam will finish around 12pm.', 
        Booking_Reference__c = 'Booking Reference', OnlineBooking_Notfn_Subject__c = 'Confirmation of BSI Online Booking', Contact_Phone__c = '+44 345 086 9000', Date__c = 'Date', Notfn_Subject__c = 'Important! Your BSI course joining instructions', 
        Notification_New_ENR_added_to_the_portal__c = 'You have been enrolled into the following -', Notification_Pre_Course_Learning_avail__c = 'There are Pre-Course Learning materials available for the following -');
        insert trainingTransl;

        Enrollment__c enr = new Enrollment__c(Training_Translations__c = trainingTransl.Id, Delegate_name__c = c.Id, Training_Event__c = t.Id, Booking_status__c = 'Application', Online_Training_Expiry_Date__c = Date.today() + 3, Litmos_Details_Emailed__c = Date.today(), Invoice_status__c = 'Completed');    
        insert enr;
    }

    @isTest
    static void getTrainingTranslationTest(){
        RecommendationUserController.getTrainingTranslation();
    }
}