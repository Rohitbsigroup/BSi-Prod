/********************************************************************
 * bg_ProductUtils
 *
 * Utility methods to support product functions
 * 
 * 
 * Author: Richard Jimenez
 * Created: 02-09-2013
 * Changes: 31/08/2017 ADS
 *            - Production Classification Fields; Division, Portoflio, Sector, Stream and Theme are now picklists
 *  05/09/2017 CPE  Uplifted IsAssuranceProduct by correctly handle a blank productname being passed.  Currently 
 *                  returns true if first product found in later SOQL is an assurance product
 *  15/09/2017 RC   Added static string PRODUCT_STREAM_TRAINING_SERVICES
 *  02/10/2017 RC   Added grid into query.
  ********************************************************************/
public class bg_ProductUtils {

    public static final string PRODUCT_TYPE_MAIN = 'Main';
    public static final string PRODUCT_TYPE_SITE = 'Site';
    public static final string PRODUCT_TYPE_QUESTION = 'Question';
    public static final string QUESTION_PRODUCT_POSTFIX = 'Q';
    public static final string QUESTION_PRODUCT_IMS = 'IMS';
    
    public static final string PRODUCT_RELATIONSHIP_TYPE_IMS = 'IMS';
    public static final string PRODUCT_RELATIONSHIP_TYPE_BUNDLE = 'Bundle'; 
    public static final string PRODUCT_RELATIONSHIP_TYPE_SUGGESTED = 'Suggested';   
    
    public static final string PRODUCT_NAME_CE_MARKING = 'CE Marking';
    public static final string PRODUCT_NAME_ISO_13485  = 'ISO 13485';
    
    public static final string PRODUCT_TYPE_RISK = 'Risk';
    public static final string PRODUCT_TYPE_NON_RISK = 'Non Risk';

    public static final string PRODUCT_STREAM_PS = 'Professional Services';
    public static final string PRODUCT_STREAM_TRAINING = 'Training';
    public static final string PRODUCT_STREAM_TRAINING_SERVICES = 'Training Services';
    
/*
    public static list<string> GetProductStreams() {
        / *
            Return list of Product Streams
        * /
        list<string> results = new list<string>();
        AggregateResult[] groupedResults = [SELECT Stream2__c 
                                            FROM Product_Classification__c p 
                                            GROUP BY Stream2__c];
        for (AggregateResult ar : groupedResults)  {
            results.add(string.valueOf(ar.get('Stream2__c')));
        }
        return results;
    }
*/

    public static list<string> GetProductPortfolios() {
        /*
            Return list of Product Portfolios
        */
        list<string> results = new list<string>();
        AggregateResult[] groupedResults = [SELECT Portfolio2__c 
                                            FROM Product_Classification__c p 
                                            GROUP BY Portfolio2__c];
        for (AggregateResult ar : groupedResults)  {
            results.add(string.valueOf(ar.get('Portfolio2__c')));
        }
        return results;
    }

    public static list<string> GetProductAreas(string portfolio) {
        /*
            Return list of Product Areas
        */
        list<string> results = new list<string>();
        if(!bg_StringUtils.IsBlank(portfolio)) {
            AggregateResult[] groupedResults = [SELECT Family2__c 
                                                FROM Product_Classification__c p 
                                                WHERE Portfolio2__c = :portfolio
                                                GROUP BY Family2__c];
            for (AggregateResult ar : groupedResults)  {
                results.add(string.valueOf(ar.get('Family2__c')));
            }
        }
        return results;
    }

    public static list<Product__c> GetProducts() {
        /*
            Return list of active products
        */
        return GetProducts(true);
    }
    
    public static list<Product__c> GetProducts(boolean activeOnly) {
        /* Return list of products */
        return GetProducts(activeOnly, null);
    }
    
    public static list<Product__c> GetProducts(boolean activeOnly, string productPortfolio) {
        /* Return list of products */
        return GetProducts(activeOnly, productPortfolio, null);
    }
    
    public static list<Product__c> GetProducts(string productPortfolio, string productArea) {
        /* Return list of products */
        return GetProducts(true, productPortfolio, productArea);
    }
    
    public static list<Product__c> GetProducts(string productPortfolio, string productArea, string productName) {
        /* Return list of products */
        return GetProducts(true, productPortfolio, productArea, productName);
    }

    public static list<Product__c> GetProducts(string productPortfolio, string productArea, string productName, set<string> countries) {
        /* Return list of products */
        return GetProducts(true, productPortfolio, productArea, productName, countries);
    }
        
    public static list<Product__c> GetProducts(boolean activeOnly, string productPortfolio, string productArea) {
        /* Return list of products */
        return GetProducts(activeOnly, productPortfolio, productArea, null);
    }

    public static list<Product__c> GetProducts(boolean activeOnly, string productPortfolio, string productArea, string name) {
        /* Return list of products */
        return GetProducts(activeOnly, productPortfolio, productArea, name, null);
    }

    public static list<Product__c> GetProducts(boolean activeOnly, string productPortfolio, string productArea, string name, set<string> countries) {
        /* Return list of products */
        return GetProducts(activeOnly, productPortfolio, productArea, name, countries, null);
    }

    public static list<Product__c> GetProducts(boolean activeOnly, string productPortfolio, string productArea, string name, set<string> countries, set<string> relationshipTypes) {
        /* Return list of products */
        return GetProducts(activeOnly, productPortfolio, productArea, name, countries, relationshipTypes, null);
    }
    
    public static list<Product__c> GetProducts(boolean activeOnly, string productPortfolio, string productArea, string name, set<string> countries, set<string> relationshipTypes, set<Id> ProductIds) {
        /* 
            Return list of products 
        */
        System.debug('+++ activeOnly = ' + activeOnly);
        System.debug('+++ productPortfolio = ' + productPortfolio);
        System.debug('+++ productArea = ' + productArea);
        System.debug('+++ name = ' + name);
        System.debug('+++ countries = ' + countries);
        System.debug('+++ relationshipTypes = ' + relationshipTypes);
        System.debug('+++ ProductIds = ' + ProductIds);
        
        
        
        
        // Main products Only
        string productTypeMain = PRODUCT_TYPE_MAIN;
        // If a category has been selected then query for the related values
        string query = 'SELECT Id, Name, Type__c, CCode__c, AllowMultipleInstances__c, ShowClassificationName__c, Product_Stream__c, Product_SubStream__c, Portfolio_Interest__c, Product_Area_Interest__c, IMS__c, RegistrationPaths__c, HQ_Only__c, FileUpload__c, RequiresCCodeToQuote__c, SingleSellProduct__c, CountriesRequiringBSIMembership__c, ' +
                           'Sampling_Threshold__c, Sampling_Rule__c, Sampling1inN__c, GridView__c, ' +  
                           'Product_Classification__c, Product_Classification__r.Stream2__c, Product_Classification__r.Product__c, Product_Classification__r.Standard__c, Product_Classification__r.Standard__r.Division__c, Product_Classification__r.Standard__r.RequiresContractReview__c ' +
                            (relationshipTypes==null?'':', (SELECT All_Products_Relations__c, Related_Product_Name__c FROM Related_Products__r WHERE Active__c = true AND Type__c IN :relationshipTypes) ') +
                            'FROM Product__c ' + 
                            'WHERE (Active_In_SF__c = true OR Active_In_SF__c = :activeOnly) ' +
                                'AND Product_Type__c =:productTypeMain ';

        if(!bg_StringUtils.IsBlank(productPortfolio)) {
            query += 'AND Portfolio_Interest__c = :productPortfolio ';
        }

        if(!bg_StringUtils.IsBlank(productArea)) {
            query += 'AND Product_Area_Interest__c =:productArea ';
        }

        if(!bg_StringUtils.IsBlank(name)) {
            if(name.contains('%')) {
                query += 'AND Name like :name ';
            } else {
                query += 'AND Name = :name ';
            }
        }
        
        string countryList = '';
        if(countries != null && !countries.isEmpty()) {
            // Filter List of available Products based on sites' countries
            for (string c : countries) {
                countryList += '\'' + c + '\''+',';
            }
            countryList = countryList.substring(0, countryList.length()-1);
            query += 'AND Country__c INCLUDES (' + countryList + ') ';
        }

        if(productIds != null) {
            query += 'AND Id IN :productIds '; 
        }

        // order by product name
        query += 'ORDER BY Name';
        System.debug('+++ query = ' + query);
        return Database.query(query);
    }

    public static Product__c GetProductById(Id productId) {
        /* Return product by Id */
        list<Product__c> products = GetProducts(true, null, null, null, null, null, new set<Id>{productId});
        if(!products.isEmpty()) {
            return products[0];
        } else { 
            return null;
        }
    }   
    
    public static list<Product__c> GetProductByIds(set<Id> productIds) {
        /* Return product by Ids */
        return GetProducts(true, null, null, null, null, null, productIds);
    }   
    
    public static Product__c GetProductByName(string name) {
        /* Return product by name */
        list<Product__c> products = GetProducts(true, null, null, name);
        if (products.size()==0) {
            return null;
        } else {
            return products[0];
        }
    }   

    public static list<Product__c> GetProductsByName(string name) {
        /* Return list of products by name */       
        return GetProducts(true, null, null, name.trim().replace('*','%') + '%');
    }

    public static list<Product__c> GetProductsByName(string name, set<string> countries) {
        /* Return list of products by name */       
        return GetProducts(true, null, null, name.trim().replace('*','%') + '%', countries);
    }
    
    public static list<Product__c> GetProductsByPortfolio(string productPortfolio) {
        /* Return list of products by name */       
        return GetProducts(true, productPortfolio);
    }
    
    public static list<Product__c> GetProductsByProductArea(string productArea) {
        /* Return list of products by name */       
        return GetProducts(true, null, productArea);
    }

    public static list<Product__c> GetProductsAndRelationships(set<string> relationshipTypes ) {
        /* Return list of products by name */
        return GetProducts(true, null, null, null, null, relationshipTypes);
    }
    
    public static map<Id, Product__c> GetProductMap(list<Product__c> products) {
        /* Return Product Map */
        return new map<Id, Product__c>(products);
    }

    public static list<Product__c> GetSiteProducts(set<string> mainProducts) {
        /*
            Get Site products
        */
        string productTypeSite = PRODUCT_TYPE_SITE;
        set<string> siteProducts = new set<string>();
        
        for(string mainProduct : mainProducts) {
            siteProducts.add(GetSiteProductName(mainProduct));
        }

        string query = 'SELECT Id, Name ' +
                            'FROM Product__c ' + 
                            'WHERE Active_In_SF__c = true ' +
                                'AND Product_Type__c = :productTypeSite ' +
                                'AND Name IN :siteProducts ';
        return Database.query(query);
    }

    public static map<string, Product__c> GetMainProductsMap(set<string> mainProducts) {
        /*
            Get Main Products Map (by name)
        */
        map<string, Product__c> productMap = new map<string, Product__c>();
        list<Product__c> products = GetMainProducts(mainProducts);
        for(Product__c product : products) {
            productMap.put(product.Name, product);
        }
        return productMap;
    }

    public static list<Product__c> GetMainProducts(set<string> mainProducts) {
        /*
            Get Main Products (by name)
        */
        string productTypeMain = PRODUCT_TYPE_MAIN;
        string query = 'SELECT Id, Name, Type__c, CCode__c, AllowMultipleInstances__c, ShowClassificationName__c, Product_Stream__c, Product_SubStream__c, Portfolio_Interest__c, Product_Area_Interest__c, HQ_Only__c, FileUpload__c, IMS__c, RegistrationPaths__c, SingleSellProduct__c, CountriesRequiringBSIMembership__c, ' +
                            'Sampling_Threshold__c, Sampling_Rule__c, Sampling1inN__c, GridView__c, ' +
                            'Product_Classification__c, Product_Classification__r.Stream2__c, Product_Classification__r.Product__c, Product_Classification__r.Standard__c ' +
                            'FROM Product__c ' + 
                            'WHERE Active_In_SF__c = true ' +
                                'AND Product_Type__c = :productTypeMain ' +
                                'AND Name IN :mainProducts ';
        query += 'ORDER BY Name ASC';
        return Database.query(query);
    }
    
    public static string GetSiteProductName(string mainProductName) {
        /* return site product name */
        return mainProductName + ' ' + PRODUCT_TYPE_SITE;   
    }
    
    public static string GetMainProductName(Product__c product) {
        /* Return main product name */
        if(product.Product_Type__c == bg_ProductUtils.PRODUCT_TYPE_MAIN) {
            return product.Name;
        } else if (product.Product_Type__c == bg_ProductUtils.PRODUCT_TYPE_SITE) { 
            return GetMainProductName(product.Name);
        } else {
            return product.Name;
        }
    }
    
    public static string GetMainProductName(string productName) {
        /* Return main product name */
        if(productName.endsWith(PRODUCT_TYPE_SITE)) {
            return productName.substring(0, productName.length() - (PRODUCT_TYPE_SITE.length() + 1));
        } else {
            return productName;
        }
    }
    
    public static map<string, Product__c> GetProductNameMap(list<Product__c> products) {
        /* Return Product Map Keyed by Name */
        map<string, Product__c> productMap = new map<string, Product__c>();
        for(Product__c product : products) {
            productMap.put(product.Name, product);
        }
        return productMap;
    }
    
    public static list<Product_Bundle__c> GetProductBundles() {
        /* Return list of active products bundles */        
        return GetProductBundles(new set<Id>());    
    }
    
    public static list<Product_Bundle__c> GetProductBundles(Id productId) {
        /* Return list of active products bundles */
        return GetProductBundles(new set<Id>{productId});
    }

    public static map<Id, Product_Bundle__c> GetProductBundlesMap(set<Id> productIds) {
        return new map<Id, Product_Bundle__c>(GetProductBundles(productIds));
    }
    
    public static list<Product_Bundle__c> GetProductBundles(set<Id> productsIds) {
        /*
            Return list of active products bundles
        */
        string query = 'SELECT Id, Name ' +
                        'FROM Product_Bundle__c '+
                        'WHERE Active__c = true ';
        // Get bundles contains specific products Id
        if(productsIds != null && productsIds.size() > 0) { 
            query += 'AND Id IN (SELECT Product_Bundle__c ' +
                                    'FROM Product_Relationship__c ' +
                                    'WHERE Related_Product__c IN :productsIds) ';
        }               
        // order by name
        query += 'ORDER BY Name';
        return Database.query(query);
    }
    
    public static list<string> GetProductNamesInBundle(string bundleName) {
        /*
            Return list of active products bundles
        */
        list<string> products = new list<string>();
        for(Product_Relationship__c pr : [SELECT Id, Name, Related_Product_Name__c
                                            FROM Product_Relationship__c
                                            WHERE Active__c = true 
                                                AND Related_Product__r.Active_In_SF__c = true
                                                AND Product_Bundle__r.Name = :bundleName
                                            ORDER BY Related_Product_Name__c ASC]){
            products.add(pr.Related_Product_Name__c);                       
        }
        return products;
    }

    public static list<Product_Relationship__c> GetSuggestedProducts(set<Id> productIds) {
        /*
            Return list of related products
        */
        return GetSuggestedProducts(productIds, null);
    }
        
    public static list<Product_Relationship__c> GetSuggestedProducts(set<Id> productIds, set<string> countries) {
        /*
            Return list of related products
        */
        map<Id, Product_Relationship__c> relatedProductMap = new map<Id, Product_Relationship__c>(); 
        list<Product_Relationship__c> relatedProducts = new list<Product_Relationship__c>();

        if(!productIds.isEmpty()) {
            // Add related products
            relatedProducts.addAll(GetSuggestedProducts(productIds, countries, null, null));
    
            // Add products related in Bundles
            set<Id> excludeProductIds = new set<Id>();
            for(Product_Relationship__c pr : relatedProducts) {
                excludeProductIds.add(pr.Related_Product__c);
            }
            excludeProductIds.addAll(productIds);
            // Add products from other bundles
            map<Id, Product_Bundle__c> productBundles = GetProductBundlesMap(productIds);
            relatedProducts.addAll(GetSuggestedProducts(null, countries, excludeProductIds, productBundles.keySet()));
            

            for(Product_Relationship__c relatedProduct : relatedProducts) {
                if(!relatedProductMap.containsKey(relatedProduct.Related_Product__c)) {
                    relatedProductMap.put(relatedProduct.Related_Product__c, relatedProduct);
                } else {
                    Product_Relationship__c exProduct = relatedProductMap.get(relatedProduct.Related_Product__c);
                    if(!exProduct.Type__c.contains(relatedProduct.Type__c)) {
                        exProduct.Type__c += '/' + relatedProduct.Type__c;
                    }
                }
            }
        }

        return relatedProductMap.values();
    }

    public static list<Product_Relationship__c> GetSuggestedProducts(set<Id> productIds, set<string> countries, set<Id> excludeProductIds, set<Id> bundleIds) {
        
        // Add related products
        string query = 'SELECT Id, Type__c, Related_Product__c, Related_Product__r.RequiresCCodeToQuote__c, ' +
                            'Related_Product__r.Name, Related_Product__r.Type__c, Related_Product__r.CCode__c, ' + 
                            'Related_Product__r.Portfolio_Interest__c, Related_Product__r.Product_Area_Interest__c, ' +
                            'Related_Product__r.Product_Stream__c, Related_Product__r.Product_SubStream__c ' +
                        'FROM Product_Relationship__c ' +
                        'WHERE Active__c = true ' +
                            'AND Related_Product__r.Active_In_SF__c = true ';
                                        
        if(productIds != null && !productIds.isEmpty()) {                                                               
            query += 'AND Product__c IN :productIds ' +
                        'AND Related_Product__c != null ' +
                        'AND Related_Product__c NOT IN :productIds ';
        }

        if(excludeProductIds != null && !excludeProductIds.isEmpty()) {                                                             
            query += 'AND Related_Product__c NOT IN :excludeProductIds ';
        }

        if(bundleIds != null && !bundleIds.isEmpty()) {                                                             
            query += 'AND Product_Bundle__c IN :bundleIds ';
        }

        string countryList = '';
        if(countries != null && !countries.isEmpty()) {
            // Filter List of available Products based on sites' countries
            for (string c : countries) {
                countryList += '\'' + c + '\''+',';
            }
            countryList = countryList.substring(0, countryList.length()-1);
            query += 'AND Related_Product__r.Country__c INCLUDES (' + countryList + ') ';
        }
        // Order by product name
        query += 'ORDER BY Related_Product__r.Name ASC ';

        return database.query(query);       
    }

    private static map<string, Product__c> questionProductMap;
    public static Product__c GetQuestionProductByName(string productName) {
        /*
            Return Question Product by Name
        */
        string qProductName = productName + QUESTION_PRODUCT_POSTFIX;
        string qProductType = PRODUCT_TYPE_QUESTION;
        Product__c qp;

        if(questionProductMap == null) {
            questionProductMap = new map<string, Product__c>();
        }
                            
        if(!questionProductMap.containsKey(qProductName)) {
            try {
                qp = [SELECT Id 
                        FROM Product__c
                        WHERE Name = :qProductName 
                            AND Product_Type__c = :qProductType];
                questionProductMap.put(qProductName, qp);
            } catch (Exception e) {}
        } else {
            qp = questionProductMap.get(qProductName);
        }   
        return qp;
    }

    public static list<Product_Classification__c> GetProductsByProductClassification(list<string> productClass) {
        /* Get Products by Product Class */
        return GetProductsByProductClassification(productClass, true);
    }
    
    public static list<Product_Classification__c> GetProductsByProductClassification(list<string> productClass, boolean onlyConfiguredProducts) {
        /*
            Get Products by Product Class
        */
        if(onlyConfiguredProducts) {
            return [SELECT Stream2__c, SubStream__c, Portfolio2__c, Family2__c, Sector2__c, Product__c, SF_Product__r.Name, Standard__c, Standard__r.RequiresContractReview__c, Standard__r.Division__c
                FROM Product_Classification__c 
                WHERE Product__c IN :productClass
                    AND SF_Product__c != null]; 
        } else {        
            return [SELECT Stream2__c, SubStream__c, Portfolio2__c, Family2__c, Sector2__c, Product__c, SF_Product__r.Name, Standard__c, Standard__r.RequiresContractReview__c, Standard__r.Division__c
                    FROM Product_Classification__c 
                    WHERE Product__c IN :productClass];
        }   
    }

    public static list<Product__c> GetProductsByProductClassification(set<string> countries, string productName) {
        /*
            Get Products by Product Class
        */
        return GetProductsByProductClassification(null, null, countries, productName);
    }

    public static list<Product__c> GetProductsByProductClassification(string portfolio, string family, set<string> countries) {
        /*
            Get Products by Product Class
        */
        return GetProductsByProductClassification(portfolio, family, countries, null);
    }

    public static list<Product__c> GetProductsByProductClassification(string portfolio, string family, set<string> countries, string productName) {
        /*
            Get Products by Product Class
        */
        list<Product_Classification__c> pcList = GetProductsClassification(portfolio, family, countries, productName);
        set<Id> productIds = new set<Id>();
        for(Product_Classification__c pc : pcList) {
            productIds.add(pc.SF_Product__c);
        }
        
        if(!bg_StringUtils.IsBlank(productName)) {
            productName = productName.replace('*','');
            productName = '%' + productName + '%';
            list<Product__c> configProducts = new list<Product__c>();
            set<Id> configProductIds;           
            configProducts = bg_ProductUtils.GetProductsByName(productName, new set<string>(countries));
            configProductIds = new map<Id, Product__c>(configProducts).keySet();
            productIds.addAll(configProductIds);
        }
        
        list<Product__c> products = GetProductByIds(productIds);
        return products;            
    }

    /*
        Get Product Classification
    */
    public static list<Product_Classification__c> GetProductsClassification(string portfolio, string family, set<string> countries, string productName) {
        return GetProductsClassification(null, null, portfolio, family, countries, productName, true);
    }

    public static list<Product_Classification__c> GetProductsClassification(string division, string stream, string portfolio, string family, set<string> countries, string productName, boolean activeConfiguratorOnly) {
        /*
            Get Product Classification
        */
        
        string query = 'SELECT SF_Product__c, Product__c, SF_Product__r.Id, SF_Product__r.Name, SF_Product__r.AllowMultipleInstances__c, SF_Product__r.ShowClassificationName__c, Standard__c, Standard__r.RequiresContractReview__c, Standard__r.Division__c, ';
        query += 'SF_Product__r.Sampling_Threshold__c, SF_Product__r.Sampling_Rule__c, SF_Product__r.Sampling1inN__c, ';
        query += 'Stream2__c, Portfolio2__c, Family2__c, SF_Product__r.Product_Stream__c, SF_Product__r.CCode__c, SF_Product__r.RequiresCCodeToQuote__c, SF_Product__r.Type__c ';
        query += 'FROM Product_Classification__c ';
        query += 'WHERE Product__c != NULL ';

        if(activeConfiguratorOnly) {
            query += 'AND SF_Product__c != NULL AND SF_Product__r.Active_In_SF__c = true ';
        }

/*
        if(!String.IsBlank(division)) {
            query += 'AND Division__c = :division ';
        }
*/
        if(!String.IsBlank(stream)) {
            query += 'AND Stream2__c = :stream ';
        }
                
        if(!String.IsBlank(portfolio)) {
            query += 'AND Portfolio2__c = :portfolio ';
        }

        if(!String.IsBlank(family)) {
            query += 'AND Family2__c = :family ';
        }       
         
        if(!String.IsBlank(productName)) {
            productName = '%' + productName.replace('*','') + '%';
            query += 'AND (Product__c like :productName ';
            if(activeConfiguratorOnly) {
                query += ' OR SF_Product__r.Name like :productName)';
            } else {
                query += ') ';
            }
        }

        string countryList = '';
        if(countries != null && !countries.isEmpty()) {
            // Filter List of available Products based on sites' countries
            for (string c : countries) {
                countryList += '\'' + c + '\''+',';
            }
            countryList = countryList.substring(0, countryList.length()-1);
            query += 'AND SF_Product__r.Country__c INCLUDES (' + countryList + ') ';
        }
        
        query += 'ORDER BY Product__c ASC';

        return database.query(query);           
    }
    
    public static void UpdateProductClassification(list<Opportunity> opps, map<Id, Opportunity> oldMap) {
        UpdateProductClassification((list<sObject>)opps, (map<Id, sObject>)oldMap);
    }

    public static void UpdateProductClassification(list<Lead> leads, map<Id, Opportunity> oldMap) {
        UpdateProductClassification((list<sObject>)leads, (map<Id, sObject>)oldMap);
    }

    public static void UpdateProductClassification(list<sObject> objs, map<Id, sObject> oldMap) {
        /*
            Method to update product classification on opp or lead
        */
        set<string> products = new set<string>();
        for(sObject obj : objs) {
            if(obj.get('Product_Stream__c') != null && (string)obj.get('Product_Stream__c') != 'Training Public' 
                    && (string)obj.get('Product_Stream__c') != 'Training In-house'
                    && (string)obj.get('Product_Stream__c') != 'Training In-house;Training Public') {
                if(oldMap == null || oldMap.get(obj.Id).get('Product_Interests__c') != obj.get('Product_Interests__c')) {                
                        products.addAll(bg_StringUtils.ConvertPicklistValueToSet((string)obj.get('Product_Interests__c')));
                }       
                if(oldMap == null || oldMap.get(obj.Id).get('Training_Interests__c') != obj.get('Training_Interests__c')) {
                    products.addAll(bg_StringUtils.ConvertPicklistValueToSet((string)obj.get('Training_Interests__c')));
                }      
            } 
        }

        if(!products.isEmpty()) {
            list<Product_Classification__c> pcList = GetProductsByProductClassification(new list<string>(products), false);
            map<string, Product_Classification__c> pcMap = new map<string, Product_Classification__c>();
            for(Product_Classification__c pc : pcList) {
                pcMap.put(pc.Product__c, pc);
            }

            for(sObject obj : objs) {
                //set<string> objProducts = bg_StringUtils.ConvertPicklistValueToSet((string)obj.get('Product_Interests__c'));
                for(string product : products) {
                    Product_Classification__c pc = pcMap.get(product);
                    system.debug('product: ' + product);
                    system.debug('Product_Classification__c: ' + pc);
                    if(pc != null) {
                        if(!bg_StringUtils.IsBlank(pc.Stream2__c) && pc.Stream2__c != 'None') {
                            obj.put('Product_Stream__c', bg_StringUtils.AddValueToPicklistString((string)obj.get('Product_Stream__c'), pc.Stream2__c));
                        }
                        if(!bg_StringUtils.IsBlank(pc.Portfolio2__c) && pc.Portfolio2__c != 'None') {
                            obj.put('Portfolio_Interests__c', bg_StringUtils.AddValueToPicklistString((string)obj.get('Portfolio_Interests__c'), pc.Portfolio2__c));            
                        }
                        if(!bg_StringUtils.IsBlank(pc.Family2__c) && pc.Family2__c != 'None') {
                            obj.put('Product_Area_Interests__c', bg_StringUtils.AddValueToPicklistString((string)obj.get('Product_Area_Interests__c'), pc.Family2__c));         
                        }
                    }
                }
            }
        }
    }

    public static List<Product__c> getProductsForClassifications(Set<Id> classificationIds)
    {
        return [SELECT Id, 
                       Name, 
                       Type__c, 
                       CCode__c, 
                       AllowMultipleInstances__c, 
                       ShowClassificationName__c, 
                       Product_Stream__c, 
                       Product_SubStream__c, 
                       Portfolio_Interest__c, 
                       Product_Area_Interest__c, 
                       IMS__c, 
                       RegistrationPaths__c, 
                       HQ_Only__c, 
                       FileUpload__c, 
                       RequiresCCodeToQuote__c, 
                       SingleSellProduct__c, 
                       CountriesRequiringBSIMembership__c,
                       Sampling_Threshold__c, 
                       Sampling_Rule__c, 
                       Sampling1inN__c,
                       Product_Classification__c,
                       Product_Classification__r.Stream2__c, 
                       Product_Classification__r.Product__c, 
                       Product_Classification__r.Standard__c, 
                       Product_Classification__r.Standard__r.Division__c, 
                       Product_Classification__r.Standard__r.RequiresContractReview__c,
                       Product_Classification__r.Product_Type__c,
                       Product_Classification__r.Sector2__c,
                       Product_Classification__r.Product_Topic__c,
                       Product_Classification__r.Product_Territory__c 
                FROM Product__c
                WHERE Product_Classification__c IN :classificationIds
                AND Active_In_SF__c = true
                AND Product_Type__c = :PRODUCT_TYPE_MAIN
                ORDER BY Name ASC]; 
    }

    /*
        Validates if the product name supplied is associated with an Assurance (Product_Stream__c) product.
        Returns false if the supplied value is an empty string
    */
    public static boolean IsAssuranceProduct(string productName) 
    {
        Boolean result = false;  //default to false
        if(!bg_StringUtils.IsBlank(productName))
        {
            Product__c prod = GetProductByName(productName);
            result =  IsAssuranceProduct(prod);
        }
        return result;
    }

    /*
        Validates if the product supplied is associated with an Assurance (Product_Stream__c) product.
        Returns false if the supplied value is an empty string
    */
    public static boolean IsAssuranceProduct(Product__c prod) {
        if (prod!=null) {
            return prod.Product_Stream__c == 'Assurance'; //TODO:  Replace string with custom label
        } else {
            return false;
        }
    }

    /*
        
    */
    public static Map<Id, Product2> getProductsById(Set<Id> product2Ids)
    {
        return new Map<Id, Product2>([SELECT Id,
                                             Name,
                                             Course_Delivery__c,
                                             Pricing_Method__c,
                                             Bespoke_Event__c
                                      FROM Product2
                                      WHERE Id IN :product2Ids]);
    }

    public static Boolean priceByTrainingDays(Product2 product)
    {
        Boolean returnVal = false;
        if(null!=product.Course_Delivery__c && null!=product.Pricing_Method__c)
        {
            if(product.Course_Delivery__c.Equals(bg_Constants.INHOUSE_PRODUCT) && product.Pricing_Method__c.Equals(bg_Constants.PRICINGMETHOD_DAYRATE))
            {
                returnVal = true;
            }
        }
        return returnVal;
    }

}