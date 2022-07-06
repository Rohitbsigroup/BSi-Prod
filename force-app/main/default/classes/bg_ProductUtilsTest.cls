/********************************************************************
 * bg_ProductUtilsTest
 *
 * Test methods for Product Utility class
 * 
 * 
 * Author: Richard Jimenez
 * Created: 02-09-2013
 * Changes: 
 *         01-08-2015 - Clear stream in testUpdateProductClassification
 *         31/08/2017 ADS - Production Classification Fields; Division, Portoflio, Sector, Stream and Theme are now picklists
 *         05/09/2017 CPE   New test methods for getProductsForClassifications and 2 * IsAssuranceProduct methods 
 ********************************************************************/
@isTest
private class bg_ProductUtilsTest {

    private static testMethod void testGetProducts() {
        /*
            Test GetProducts Method
        */
        set<string> countries = new set<string>{bg_SiteUtils.COUNTRY_CODE_US};
        Product__c product1 = bg_UnitTestHelper.GetProduct('UT-Product-1');
        Product__c product2 = bg_UnitTestHelper.GetProduct('UT-Product-2', true, product1.Portfolio_Interest__c, product1.Product_Area_Interest__c, countries);     
        Product__c product3 = bg_UnitTestHelper.GetProduct('UT-Product-3', false);
        test.startTest();
            system.assertEquals(2, bg_ProductUtils.GetProducts().size());
            system.assertEquals(3, bg_ProductUtils.GetProducts(false).size());
            system.assertEquals(2, bg_ProductUtils.GetProducts(product1.Portfolio_Interest__c, product1.Product_Area_Interest__c).size());
            system.assertEquals(1, bg_ProductUtils.GetProducts(product1.Portfolio_Interest__c, product1.Product_Area_Interest__c, product1.Name).size());
            system.assertEquals(1, bg_ProductUtils.GetProducts(product1.Portfolio_Interest__c, product1.Product_Area_Interest__c, null, countries).size());         
        test.stopTest();
    }

    private static testMethod void testGetProductPortfolios() {
        /*
            Test GetProductPortfolios Method
        */
        Product_Classification__c pcA = bg_UnitTestHelper.GetProductClassification2('UT-ProductA', 'StreamA', 'PortfolioA','ProductAreaA');
        test.startTest();
            system.assertEquals(pcA.Portfolio2__c, bg_ProductUtils.GetProductPortfolios()[0]);
        test.stopTest();
    }
    
    private static testMethod void testGetProductAreas() {
        /*
            Test GetProductAreas Method
        */
        Product_Classification__c pcA = bg_UnitTestHelper.GetProductClassification2('UT-ProductA', 'StreamA', 'PortfolioA','ProductAreaA');     
        test.startTest();
            system.assertEquals(pcA.Family2__c, bg_ProductUtils.GetProductAreas(pcA.Portfolio2__c)[0]);
        test.stopTest();
    }
    
    private static testMethod void testGetProductByIds() {
        /*
            Test GetProductByIds Method
        */
        set<Id> Ids = new set<Id>();
        Ids.add(bg_UnitTestHelper.GetProduct('UT-Product-1').Id);
        Ids.add(bg_UnitTestHelper.GetProduct('UT-Product-2').Id);       
        test.startTest();
            system.assertEquals(2, bg_ProductUtils.GetProductByIds(Ids).size());
        test.stopTest();
    }

    private static testMethod void testGetProductByName() {
        /*
            Test GetProductByName Method
        */
        Product__c product1 = bg_UnitTestHelper.GetProduct('UT-Product-1'); 
        test.startTest();
            system.assertEquals(product1.Id, bg_ProductUtils.GetProductByName(product1.Name).Id);
        test.stopTest();
    }   
    
    private static testMethod void testGetProductsByName() {
        /*
            Test GetProductByName Method
        */
        set<string> countries = new set<string>{bg_SiteUtils.COUNTRY_CODE_US};
        Product__c product1 = bg_UnitTestHelper.GetProduct('UT-Product-1');
        Product__c product2 = bg_UnitTestHelper.GetProduct('UT-Product-2', true, product1.Portfolio_Interest__c, product1.Product_Area_Interest__c, countries);
        Product__c product3 = bg_UnitTestHelper.GetProduct('AB-Product-3');
        test.startTest();
            system.assertEquals(2, bg_ProductUtils.GetProductsByName('UT').size());
            system.assertEquals(1, bg_ProductUtils.GetProductsByName('UT', countries).size());
        test.stopTest();
    }
    
    private static testMethod void testGetProductsByPortfolio() {
        /*
            Test GetProductsByPortfolio Method
        */
        Product__c product1 = bg_UnitTestHelper.GetProduct('UT-Product-1');
        test.startTest();
            system.assertEquals(1, bg_ProductUtils.GetProductsByPortfolio(product1.Portfolio_Interest__c).size());
        test.stopTest();
    }
    
    private static testMethod void testGetProductsByProductArea() {
        /*
            Test GetProductsByProductArea Method
        */
        Product__c product1 = bg_UnitTestHelper.GetProduct('UT-Product-1');
        test.startTest();
            system.assertEquals(1, bg_ProductUtils.GetProductsByProductArea(product1.Product_Area_Interest__c).size());
        test.stopTest();
    }

    private static testMethod void testGetProductsAndRelationships() {
        /*
            Test GetProductsAndRelationships Method
        */
        Product__c product1 = bg_UnitTestHelper.GetProduct('UT-Product-1');
        Product__c product2 = bg_UnitTestHelper.GetProduct('UT-Product-2');
        bg_UnitTestHelper.GetProductRelationship(product1, product2, bg_ProductUtils.PRODUCT_RELATIONSHIP_TYPE_IMS);        
        test.startTest();
            system.assertEquals(2, bg_ProductUtils.GetProductsAndRelationships(new set<string>{bg_ProductUtils.PRODUCT_RELATIONSHIP_TYPE_IMS}).size());
        test.stopTest();
    }
    
    private static testMethod void testGetProductMap() {
        /*
            Test GetProductMap Method
        */
        Product__c product1 = bg_UnitTestHelper.GetProduct('UT-Product-1');             
        test.startTest();
            system.assertEquals(true, bg_ProductUtils.GetProductMap(bg_ProductUtils.GetProducts()).containsKey(product1.Id));
        test.stopTest();
    }
    
    private static testMethod void testGetSiteProducts() {
        /*
            Test GetSiteProducts Method
        */
        Product__c mainProduct = bg_UnitTestHelper.GetProduct('UT-Product-1');      
        Product__c siteProduct = bg_UnitTestHelper.GetProduct(bg_ProductUtils.GetSiteProductName(mainProduct.Name), true, mainProduct.Portfolio_Interest__c, mainProduct.Product_Area_Interest__c, bg_ProductUtils.PRODUCT_TYPE_SITE);              
        test.startTest();
            system.assertEquals(1, bg_ProductUtils.GetSiteProducts(new set<string>{mainProduct.Name}).size());
        test.stopTest();        
    }   

    private static testMethod void testGetMainProducts() {
        /*
            Test GetMainProducts and GetMainProductsMap Method
        */
        Product__c mainProduct = bg_UnitTestHelper.GetProduct('UT-Product-1');      
        Product__c siteProduct = bg_UnitTestHelper.GetProduct(bg_ProductUtils.GetSiteProductName(mainProduct.Name), true, mainProduct.Portfolio_Interest__c, mainProduct.Product_Area_Interest__c, bg_ProductUtils.PRODUCT_TYPE_SITE);              
        test.startTest();
            system.assertEquals(1, bg_ProductUtils.GetMainProducts(new set<string>{mainProduct.Name}).size());
            system.assertEquals(true, bg_ProductUtils.GetMainProductsMap(new set<string>{mainProduct.Name}).containsKey(mainProduct.Name));
        test.stopTest();        
    }

    private static testMethod void testGetMainProductName() {
        /*
            Test GetMainProductName Method
        */
        Product__c mainProduct = bg_UnitTestHelper.GetProduct('UT-Product-1');      
        Product__c siteProduct = bg_UnitTestHelper.GetProduct(bg_ProductUtils.GetSiteProductName(mainProduct.Name), true, mainProduct.Portfolio_Interest__c, mainProduct.Product_Area_Interest__c, bg_ProductUtils.PRODUCT_TYPE_SITE);              
        Product__c newProduct = bg_UnitTestHelper.GetProduct('UT-Product-2');
        newProduct.Product_Type__c  = 'NEW_TYPE';
        test.startTest();
            system.assertEquals(mainProduct.Name, bg_ProductUtils.GetMainProductName(mainProduct));
            system.assertEquals(mainProduct.Name, bg_ProductUtils.GetMainProductName(siteProduct));
            system.assertEquals(newProduct.Name, bg_ProductUtils.GetMainProductName(newProduct));
            system.assertEquals(mainProduct.Name, bg_ProductUtils.GetMainProductName(mainProduct.Name));
            system.assertEquals(mainProduct.Name, bg_ProductUtils.GetMainProductName(siteProduct.Name));
        test.stopTest();        
    }
    
    private static testMethod void testGetProductNameMap() {
        /*
            Test GetProductNameMap Method
        */
        Product__c product = bg_UnitTestHelper.GetProduct('UT-Product-1');  
        test.startTest();
            system.assertEquals(true, bg_ProductUtils.GetProductNameMap(new list<Product__c>{product}).containsKey(product.name));
        test.stopTest();        
    }
    
    private static testMethod void testGetProductBundles() {
        /*
            Test GetProductBundles and GetProductBundlesMap method
        */
        Product__c product = bg_UnitTestHelper.GetProduct('UT-Product-1');  
        Product_Bundle__c bundle =  bg_UnitTestHelper.GetProductBundle('UT-Bundle');
        Product_Relationship__c pr = bg_UnitTestHelper.GetProductBundleRelationship(bundle, product);
        test.startTest();
            system.assertEquals(1, bg_ProductUtils.GetProductBundles().size());
            system.assertEquals(1, bg_ProductUtils.GetProductBundles(product.Id).size());
            system.assertEquals(1, bg_ProductUtils.GetProductBundles(new set<Id>{product.Id}).size());
            system.assertEquals(1, bg_ProductUtils.GetProductBundlesMap(new set<Id>{product.Id}).size());
        test.stopTest();
    }

    private static testMethod void testGetProductNamesInBundle() {
        /*
            Test GetProductNamesInBundle method
        */
        Product__c product = bg_UnitTestHelper.GetProduct('UT-Product-1');  
        Product_Bundle__c bundle =  bg_UnitTestHelper.GetProductBundle('UT-Bundle');
        Product_Relationship__c pr = bg_UnitTestHelper.GetProductBundleRelationship(bundle, product);
        test.startTest();
            system.assertEquals(1, bg_ProductUtils.GetProductNamesInBundle(bundle.Name).size());
        test.stopTest();
    }

    private static testMethod void testGetSuggestedProducts() {
        /*
            Test GetProductNamesInBundle method
        */
        set<string> COUNTRY_CODE_US = new set<string>{bg_SiteUtils.COUNTRY_CODE_US};
        set<string> COUNTRY_CODE_UK = new set<string>{bg_SiteUtils.COUNTRY_CODE_UK};
        Product__c product1 = bg_UnitTestHelper.GetProduct('UT-Product-1');
        Product__c product2 = bg_UnitTestHelper.GetProduct('UT-Product-2', true, product1.Portfolio_Interest__c, product1.Product_Area_Interest__c, COUNTRY_CODE_US);
        Product__c product3 = bg_UnitTestHelper.GetProduct('UT-Product-3', true, product1.Portfolio_Interest__c, product1.Product_Area_Interest__c, COUNTRY_CODE_UK);
        
        Product_Bundle__c bundle =  bg_UnitTestHelper.GetProductBundle('UT-Bundle');
        bg_UnitTestHelper.GetProductBundleRelationship(bundle, product1);
        bg_UnitTestHelper.GetProductBundleRelationship(bundle, product2);
        bg_UnitTestHelper.GetProductRelationship(product1, product3, bg_ProductUtils.PRODUCT_RELATIONSHIP_TYPE_SUGGESTED);
        bg_UnitTestHelper.GetProductRelationship(product1, product3, bg_ProductUtils.PRODUCT_RELATIONSHIP_TYPE_IMS);

        test.startTest();
            system.assertEquals(2, bg_ProductUtils.GetSuggestedProducts(new set<Id>{product1.Id}).size());
            system.assertEquals(1, bg_ProductUtils.GetSuggestedProducts(new set<Id>{product1.Id}, COUNTRY_CODE_US).size());
        test.stopTest();
    }
    
    private static testMethod void testGetQuestionProductByName() {
        /*
            Test GetQuestionProductByName method
        */
        string productName = 'ISO 9001';
        Product__c questionProd = bg_UnitTestHelper.GetQuestionProduct(productName);
        test.startTest();       
            system.assertEquals(questionProd.Id, bg_ProductUtils.GetQuestionProductByName(productName).Id);
            system.assertEquals(questionProd.Id, bg_ProductUtils.GetQuestionProductByName(productName).Id);
        test.stopTest();        
        
    }
    
    private static testMethod void testGetProductById() {
        /*
            Test GetProductById method
        */
        Product__c product = bg_UnitTestHelper.GetProduct('UT-Product-1');
        test.startTest();
            system.assertEquals(product.Id, bg_ProductUtils.GetProductById(product.Id).Id);
        test.stopTest();        
    }
    
    private static testMethod void testGetProductsByProductClassification() {
        /*
            Test GetProductsByProductClassification method
        */
        Product__c product = bg_UnitTestHelper.GetProduct('UT-Product-1', true, 'PortfolioA', 'ProductAreaA', bg_ProductUtils.PRODUCT_TYPE_MAIN, new set<string>{'US','GB'});
        Product_Classification__c pcA = bg_UnitTestHelper.GetProductClassification2(product.Name, 'StreamA', product.Portfolio_Interest__c, product.Product_Area_Interest__c, product);
    
        test.startTest();
            system.assertEquals(product.Name, bg_ProductUtils.GetProductsByProductClassification(new list<string>{pcA.Product__c})[0].SF_Product__r.Name);
            system.assertEquals(product.Id, bg_ProductUtils.GetProductsByProductClassification(pcA.Portfolio2__c, pcA.Family2__c, new set<string>{'GB','US'})[0].Id);
        test.stopTest();
    }
    
    private static testMethod void testUpdateProductClassification() {
        /*
            Test UpdateProductClassification method
        */
        // Initialise Custom Settings
        bg_UnitTestHelper.SetupCustomSettings();

        Product_Classification__c pcA = bg_UnitTestHelper.GetProductClassification2('UT-ProductName', 'StreamA', 'PortfolioA', 'FamilyA');
        
        User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');
        System.runAs(user1) {
            Lead leadt1 = bg_UnitTestHelper.GetLead('Lead1name');
            leadt1.Source_Sub_Category__c = 'BSI Employee';
            leadt1.Description = 'Desctest1';
            leadt1.Product_Interests__c = pcA.Product__c;
            leadt1.Product_Stream__c = 'StreamA';
    
            system.debug('leadt1.Product_Interests__c: ' + leadt1.Product_Interests__c);
            
            test.startTest();
                update leadt1;
            test.stopTest();

            leadt1 = [SELECT Product_Stream__c, Product_SubStream__c, Portfolio_Interests__c, Product_Area_Interests__c FROM Lead WHERE Id = :leadt1.Id];
            system.assertEquals(pcA.Stream2__c,     leadt1.Product_Stream__c);
            system.assertEquals(pcA.SubStream__c,   leadt1.Product_SubStream__c);
            system.assertEquals(pcA.Portfolio2__c,  leadt1.Portfolio_Interests__c);
            system.assertEquals(pcA.Family2__c,     leadt1.Product_Area_Interests__c);
        }
        
    
    }


    /*
        Test getProductsForClassifications
        No classification ids supplied
    */
    static testMethod void testgetProductsForClassificationsNoIds()
    {
        Set<Id> classificationIds = new Set<Id>();
        List<Product__c> results;
        
        results = bg_ProductUtils.getProductsForClassifications(classificationIds);
        
        system.assertEquals(false, results == null);
        system.assertEquals(true, results.isEmpty());
        
    }
    

    /*
        Test getProductsForClassifications
        Single classification
    */
    static testMethod void testgetProductsForClassificationsSingle()
    {
        Set<Id> classificationIds = new Set<Id>();
        List<Product__c> forInsert = new List<Product__c>();
        Set<String> countries = new Set<String>{ 'GB', 'US', 'ES' };
        Integer productCount = 5;

        List<Product__c> results;
        
        Product_Classification__c pcA = bg_UnitTestHelper.GetProductClassification2('UT-ProductName', 'StreamA', 'PortfolioA', 'FamilyA');
        classificationIds.add(pcA.Id);
        
        for (Integer iterator=0; iterator<productCount; iterator++)
        {
            Product__c testProduct = bg_UnitTestHelper.CreateProduct('TEST-PROD-CLASS-' + iterator, true, pcA.Portfolio2__c, pcA.Family2__c, bg_ProductUtils.PRODUCT_TYPE_MAIN, countries, pcA.Id);
            forInsert.add(testProduct);
        }
        insert forInsert;
        
        
        results = bg_ProductUtils.getProductsForClassifications(classificationIds);
        
        system.assertEquals(false, results == null);
        system.assertEquals(false, results.isEmpty());
        system.assertEquals(productCount, results.size());
        Map<Id, Product__c> testProducts = new Map<Id, Product__c>();
        testProducts.putAll(forInsert);
        for (Product__c result : results)
        {
            system.assertEquals(true, testProducts.containsKey(result.Id));
        }
    }

    /*
        Test getProductsForClassifications
        Multi classifications
    */
    static testMethod void testgetProductsForClassificationsMulti()
    {
        Map<Id, Product_Classification__c> classificationIds = new Map<Id, Product_Classification__c>();
        List<Product_Classification__c> forInsertPC = new List<Product_Classification__c>();
        List<Product__c> forInsert = new List<Product__c>();
        
        Set<String> countries = new Set<String>{ 'GB', 'US', 'ES' };
        Integer classificationCount = 5;
        Integer productCount = 5;

        List<Product__c> results;
        
        for (Integer iteratorPC=0; iteratorPC<classificationCount; iteratorPC++)
        {
            Product_Classification__c testPC = bg_UnitTestHelper.CreateProductClassification('UT-ProductName-' + iteratorPC, 'Stream-' + iteratorPC, 'Portfolio-' + iteratorPC, 'Family-' + iteratorPC, null, null);
            forInsertPC.add(testPC);
        }
        insert forInsertPC;
        classificationIds.putAll(forInsertPC);
        
        for (Product_Classification__c pc : forInsertPC)
        {
            for (Integer iterator=0; iterator<productCount; iterator++)
            {
                Product__c testProduct = bg_UnitTestHelper.CreateProduct('TEST-PROD-CLASS-' + iterator, true, pc.Portfolio2__c, pc.Family2__c, bg_ProductUtils.PRODUCT_TYPE_MAIN, countries, pc.Id);
                forInsert.add(testProduct);
            }
        }
        insert forInsert;
        
        
        results = bg_ProductUtils.getProductsForClassifications(classificationIds.keySet());
        
        system.assertEquals(false, results == null);
        system.assertEquals(false, results.isEmpty());
        system.assertEquals(productCount * classificationCount, results.size());
        Map<Id, Product__c> testProducts = new Map<Id, Product__c>();
        testProducts.putAll(forInsert);
        for (Product__c result : results)
        {
            system.assertEquals(true, testProducts.containsKey(result.Id));
            system.assertEquals(true, classificationIds.containsKey(result.Product_Classification__c));
        }
    }

    /*
        Test for IsAssuranceProduct - Name
        Blank product name
    */
    static testMethod void testIsAssuranceProductNameBlank()
    {
        Set<String> countries = new Set<String>{ 'GB', 'US', 'ES' };
        Product_Classification__c pcA = bg_UnitTestHelper.GetProductClassification2('UT-ProductName', 'StreamA', 'PortfolioA', 'FamilyA');
        String productName = '';
        
        Product__c testProduct = bg_UnitTestHelper.CreateProduct('TEST-PROD-CLASS', true, pcA.Portfolio2__c, pcA.Family2__c, bg_ProductUtils.PRODUCT_TYPE_MAIN, countries, pcA.Id);
        testProduct.Product_Stream__c = 'Assurance'; //CPE not happy with this - should really being derived from a custom label (this should also be applied to the utility method being called)
        insert testProduct;

        
        Boolean result;
        
        result = bg_ProductUtils.IsAssuranceProduct(productName);

        system.assertEquals(false, result);
    }
    

    /*
        Test for IsAssuranceProduct - Name
        product name not found
    */
    static testMethod void testIsAssuranceProductNameNotFound()
    {
        Set<String> countries = new Set<String>{ 'GB', 'US', 'ES' };
        Product_Classification__c pcA = bg_UnitTestHelper.GetProductClassification2('UT-ProductName', 'StreamA', 'PortfolioA', 'FamilyA');
        String productName = 'CPE-INVALID-PRODUCT-NAME';
        
        Product__c testProduct = bg_UnitTestHelper.CreateProduct('TEST-PROD-CLASS', true, pcA.Portfolio2__c, pcA.Family2__c, bg_ProductUtils.PRODUCT_TYPE_MAIN, countries, pcA.Id);
        testProduct.Product_Stream__c = 'Assurance'; //CPE not happy with this - should really being derived from a custom label (this should also be applied to the utility method being called)
        insert testProduct;

        
        Boolean result;
        
        result = bg_ProductUtils.IsAssuranceProduct(productName);

        system.assertEquals(false, result);
    }

    /*
        Test for IsAssuranceProduct - Name
        Is Assurance product
    */
    static testMethod void testIsAssuranceProductNameIsAssurance()
    {
        Set<String> countries = new Set<String>{ 'GB', 'US', 'ES' };
        Product_Classification__c pcA = bg_UnitTestHelper.GetProductClassification2('UT-ProductName', 'StreamA', 'PortfolioA', 'FamilyA');
        String productName = 'TEST-ASSURANCE-PRODUCT';
        
        Product__c testProduct = bg_UnitTestHelper.CreateProduct(productName, true, pcA.Portfolio2__c, pcA.Family2__c, bg_ProductUtils.PRODUCT_TYPE_MAIN, countries, pcA.Id);
        testProduct.Product_Stream__c = 'Assurance'; //CPE not happy with this - should really being derived from a custom label (this should also be applied to the utility method being called)
        insert testProduct;

        
        Boolean result;
        
        result = bg_ProductUtils.IsAssuranceProduct(productName);

        system.assertEquals(true, result);
    }
    
    /*
        Test for IsAssuranceProduct - Name
        Is NOT Assurance product
    */
    static testMethod void testIsAssuranceProductNameIsNotAssurance()
    {
        Set<String> countries = new Set<String>{ 'GB', 'US', 'ES' };
        Product_Classification__c pcA = bg_UnitTestHelper.GetProductClassification2('UT-ProductName', 'StreamA', 'PortfolioA', 'FamilyA');
        String productName = 'TEST-ASSURANCE-PRODUCT';
        
        Product__c testProduct = bg_UnitTestHelper.CreateProduct(productName, true, pcA.Portfolio2__c, pcA.Family2__c, bg_ProductUtils.PRODUCT_TYPE_MAIN, countries, pcA.Id);
        testProduct.Product_Stream__c = 'GRC'; 
        insert testProduct;
        
        Boolean result;
        
        result = bg_ProductUtils.IsAssuranceProduct(productName);

        system.assertEquals(false, result);
    }   

    /*
    public static boolean IsAssuranceProduct(Product__c prod) {
    */



    /*
        Test for IsAssuranceProduct - Product
        Product is null
    */
    static testMethod void testIsAssuranceProductNull()
    {
        Set<String> countries = new Set<String>{ 'GB', 'US', 'ES' };
        Product_Classification__c pcA = bg_UnitTestHelper.GetProductClassification2('UT-ProductName', 'StreamA', 'PortfolioA', 'FamilyA');
        
        Product__c testProduct = bg_UnitTestHelper.CreateProduct('TEST-PROD-CLASS', true, pcA.Portfolio2__c, pcA.Family2__c, bg_ProductUtils.PRODUCT_TYPE_MAIN, countries, pcA.Id);
        testProduct.Product_Stream__c = 'Assurance'; //CPE not happy with this - should really being derived from a custom label (this should also be applied to the utility method being called)
        insert testProduct;
        
        Boolean result;
        Product__c prodToTest = null;
        
        result = bg_ProductUtils.IsAssuranceProduct(prodToTest);

        system.assertEquals(false, result);
    }
    


    /*
        Test for IsAssuranceProduct - Product
        Is Assurance product
    */
    static testMethod void testIsAssuranceProductIsAssurance()
    {
        Set<String> countries = new Set<String>{ 'GB', 'US', 'ES' };
        Product_Classification__c pcA = bg_UnitTestHelper.GetProductClassification2('UT-ProductName', 'StreamA', 'PortfolioA', 'FamilyA');
        String productName = 'TEST-ASSURANCE-PRODUCT';
        
        Product__c testProduct = bg_UnitTestHelper.CreateProduct(productName, true, pcA.Portfolio2__c, pcA.Family2__c, bg_ProductUtils.PRODUCT_TYPE_MAIN, countries, pcA.Id);
        testProduct.Product_Stream__c = 'Assurance'; //CPE not happy with this - should really being derived from a custom label (this should also be applied to the utility method being called)
        insert testProduct;

        
        Boolean result;
        
        result = bg_ProductUtils.IsAssuranceProduct(testProduct);

        system.assertEquals(true, result);
    }
    
    /*
        Test for IsAssuranceProduct - Product
        Is NOT Assurance product
    */
    static testMethod void testIsAssuranceProductIsNotAssurance()
    {
        Set<String> countries = new Set<String>{ 'GB', 'US', 'ES' };
        Product_Classification__c pcA = bg_UnitTestHelper.GetProductClassification2('UT-ProductName', 'StreamA', 'PortfolioA', 'FamilyA');
        String productName = 'TEST-ASSURANCE-PRODUCT';
        
        Product__c testProduct = bg_UnitTestHelper.CreateProduct(productName, true, pcA.Portfolio2__c, pcA.Family2__c, bg_ProductUtils.PRODUCT_TYPE_MAIN, countries, pcA.Id);
        testProduct.Product_Stream__c = 'GRC'; 
        insert testProduct;
        
        Boolean result;
        
        result = bg_ProductUtils.IsAssuranceProduct(testProduct);

        system.assertEquals(false, result);
    }

}