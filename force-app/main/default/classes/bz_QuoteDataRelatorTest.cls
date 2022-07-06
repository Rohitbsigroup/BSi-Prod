@isTest
private class bz_QuoteDataRelatorTest {
	
    static testMethod void bz_TestProductToPropertyToPropertyRelation() {
        
        string propertyGuid = '96BEEBB6-9EB7-4561-9A48-92B11782978A';         
        string productGuid = 'A76A92FC-182F-4189-AE9A-545D08D43CC4';
        string propertyGuid2 = '96BEEBB6-9EB7-4561-9A48-92B11782978B';         
        string productGuid2 = 'A76A92FC-182F-4189-AE9A-545D08D43CC5';
        
        test.startTest();
        
        // Property and Product specified
        Product__c prod1 = new Product__c();
        prod1.Guid__c = productGuid;        
        
        Property__c prop1 = new Property__c();
        prop1.Guid__c = propertyGuid;
        prop1.Name__c = 'TestProperty1';
        prop1.Active__c = true;
        
        Product__c prod2 = new Product__c();
        prod2.Guid__c = productGuid2;        
        
        Property__c prop2 = new Property__c();
        prop2.Guid__c = propertyGuid2;
        prop2.Name__c = 'TestProperty2';
        prop2.Active__c = true;

		insert prod1;
        insert prop1;
        insert prod2;
        insert prop2;
                
        ProductToProperty__c p2p1 = new ProductToProperty__c();        
        p2p1.PropertyGuid__c = propertyGuid;
        p2p1.ProductGuid__c = productGuid;
        
        
        ProductToProperty__c p2p2 = new ProductToProperty__c();        
        p2p2.PropertyGuid__c = propertyGuid;
        
        ProductToProperty__c p2p3 = new ProductToProperty__c();        
        p2p3.ProductGuid__c = productGuid;
        
        ProductToProperty__c p2p4 = new ProductToProperty__c();
        
        ProductToProperty__c p2p5 = new ProductToProperty__c();
        p2p5.PropertyGuid__c = propertyGuid;
        p2p5.ProductGuid__c = productGuid;
        
        ProductToProperty__c p2p6 = new ProductToProperty__c();
        p2p6.PropertyGuid__c = propertyGuid;
        p2p6.ProductGuid__c = productGuid;
        
        insert p2p1;
        insert p2p2;
        insert p2p3;
        insert p2p4;
        insert p2p5;
        insert p2p6;
        
        p2p5.PropertyGuid__c = null;
        p2p5.ProductGuid__c = null;
        
        update p2p5;
        
        p2p6.PropertyGuid__c = propertyGuid2;
        p2p6.ProductGuid__c = productGuid2;
        
        update p2p6;
        
        test.stopTest();
        
        // Property and Product specified
        ProductToProperty__c p2pUpdated = [SELECT Id, Property__c, Product__c, PropertyGuid__c FROM ProductToProperty__c WHERE Id = :p2p1.Id];  
        system.assertEquals( prop1.Id, p2pUpdated.Property__c );
        system.assertEquals( prod1.Id, p2pUpdated.Product__c );
        
        // No Product Guid
        p2pUpdated = [SELECT Id, Property__c, Product__c, PropertyGuid__c FROM ProductToProperty__c WHERE Id = :p2p2.Id];  
        system.assertEquals( prop1.Id, p2pUpdated.Property__c );
        system.assertEquals( null, p2pUpdated.Product__c );
        
        // No Property Guid
        p2pUpdated = [SELECT Id, Property__c, Product__c, PropertyGuid__c FROM ProductToProperty__c WHERE Id = :p2p3.Id];  
        system.assertEquals( null, p2pUpdated.Property__c );
        system.assertEquals( prod1.Id, p2pUpdated.Product__c );
        
        // Everythings null
        p2pUpdated = [SELECT Id, Property__c, Product__c, PropertyGuid__c FROM ProductToProperty__c WHERE Id = :p2p4.Id];  
        system.assertEquals( null, p2pUpdated.Property__c );
        system.assertEquals( null, p2pUpdated.Product__c );
        
        // Clearing products & property
        p2pUpdated = [SELECT Id, Property__c, Product__c, PropertyGuid__c FROM ProductToProperty__c WHERE Id = :p2p5.Id];  
        system.assertEquals( null, p2pUpdated.Property__c );
        system.assertEquals( null, p2pUpdated.Product__c );
        
        // Updating products & property
        p2pUpdated = [SELECT Id, Property__c, Product__c, PropertyGuid__c FROM ProductToProperty__c WHERE Id = :p2p6.Id];  
        system.assertEquals( prop2.Id, p2pUpdated.Property__c );
        system.assertEquals( prod2.Id, p2pUpdated.Product__c );
    }
    
    static testMethod void bz_TestPropertyValueToProductToPropertyRelation() {
    	
    	string productToPropertyGuid = '96BEEBB6-9EB7-4561-9A48-92B117829781';
    	string quoteToProductGuid = '95CEEBB6-9EB7-4561-9A48-92B117829781';
    	
    	test.startTest();
    	
    	PropertyValue__c pv1 = new PropertyValue__c();
    	pv1.ProductToPropertyGuid__c = productToPropertyGuid;
    	pv1.QuoteToProductGuid__c = quoteToProductGuid;
    	
    	insert pv1;
    	
    	ProductToProperty__c p2p1 = new ProductToProperty__c();
        p2p1.Guid__c = productToPropertyGuid;
        
        insert p2p1;
        
        Quote__c q1 = new Quote__c();
        
        insert q1;
        
    	Quote_Product__c qp1 = new Quote_Product__c();
    	qp1.Guid__c = quoteToProductGuid;
    	qp1.Quote_Ref__c = q1.Id;
    	qp1.Price_Book_Name__c = 'UK Pricing Guide 2013';
    	
    	insert qp1;
    	
    	test.stopTest();
    	
    	// Property and Product specified
        PropertyValue__c pvUpdated = [SELECT Id, ProductToProperty__c, QuoteToProduct__c FROM PropertyValue__c WHERE Id = :pv1.Id];  
        system.assertEquals( p2p1.Id, pvUpdated.ProductToProperty__c );
        system.assertEquals( qp1.Id, pvUpdated.QuoteToProduct__c );
        
        
    }
    
    static testMethod void bz_TestEnumValueToProductRelation() {    
    	string propertyGuid = 'A76A92FC-182F-4189-AE9A-545D08D43CC4';
    	
        Property__c prop1 = new Property__c();
        prop1.Guid__c = propertyGuid;
        prop1.Name__c = 'TestProperty1';
        prop1.Active__c = true;
        
        insert prop1;
    	
    	EnumValue__c ev = new EnumValue__c();
    	ev.Name__c = 'EnumVal';
    	ev.Value__c = 1;
    	ev.PropertyGuid__c = propertyGuid;
    	 
    	test.startTest();
    	
    	insert ev;
    	
    	test.stopTest();
    	
    	EnumValue__c evUpdated = [SELECT Id, Property__c FROM EnumValue__c WHERE Id = :ev.Id];
    	system.assertEquals(prop1.Id, evUpdated.Property__c);
    }
    
    static testMethod void bz_TestRelatedPropertyValueRelation() {
    	string pv1Guid = 'B48FD687-0CC6-41F5-9682-F34BDCB39538';
    	string pv2Guid = 'E5E3239D-BD78-4FA2-AD3F-973027E754D9';
    	string pv3Guid = '9E6BAE3D-BB5E-4EC5-A462-1CD97D5011E3';
    	string pv4guid = '8234FAA9-0B1D-4FCF-91F1-97C6A6D0538E';
    	    	
    	PropertyValue__c pv1 = new PropertyValue__c();
    	pv1.Guid__c = pv1Guid;
    	pv1.RelatedPropertyValueGuid__c = null;
    	
    	PropertyValue__c pv2 = new PropertyValue__c();
    	pv2.Guid__c = pv2Guid;
    	pv2.RelatedPropertyValueGuid__c = pv1Guid;
    	
    	PropertyValue__c pv3 = new PropertyValue__c();
    	pv3.Guid__c = pv3Guid;
    	pv3.RelatedPropertyValueGuid__c = pv4guid;
    	
    	PropertyValue__c pv4 = new PropertyValue__c();
    	pv4.Guid__c = pv4Guid;
    	
    	insert pv4;
    	
    	insert pv3;
    	
    	test.startTest();
    	
    	//Test a null related record
    	insert pv1;
    	
    	//test an actually related record
    	insert pv2;
    	
    	
    	
    	
    	System.debug('BZ: Testing Clearing related propertyvalue');
    	pv3.RelatedPropertyValueGuid__c = null;
    	update pv3;
    	
    	test.stopTest();
    	
    	PropertyValue__c readPropertyValue = [SELECT RelatedPropertyValue__c, RelatedPropertyValueGuid__c FROM PropertyValue__c WHERE Id = :pv2.Id];
    	System.assertEquals(pv1.Id, readPropertyValue.RelatedPropertyValue__c);
    	
    	PropertyValue__c readPv3 = [SELECT RelatedPropertyValue__c, RelatedPropertyValueGuid__c FROM PropertyValue__c WHERE Id = :pv3.Id];
    	System.assertEquals(null, readPv3.RelatedPropertyValue__c);

    	
    	
    }
    
}