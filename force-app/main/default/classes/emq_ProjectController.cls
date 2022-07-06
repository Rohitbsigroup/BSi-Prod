/**
*   Author      : Prasad JN
*   Description : Custom APEX for project creation & prod cert product search
*/
public with sharing class emq_ProjectController {
    
    public Project__c project { get; set; }
    
    public Boolean prodCertProject { get; set; }
    
    public String productName { get; set; }
    
    public String standard { get; set; }
    
    public String[] selectedCertificationTypes { get; set; }
    
    public Boolean directTestingAvailable { get; set; }
    
    public String[] selectedSpecifiers { get; set; }
    
    public Boolean directTestingOnly { get; set; }
    
    public List<SelectOption> availableCertTypes { get; set; }
    
    public List<SelectOption> availableRegistrationPaths { get; set; }
    
    public List<SelectOption> availableSpecifiers { get; set; }
    
    public List<Product__c> products { get; set; } 
    
    private List<ProductAttributes__c> productAttributes;
    
    public emq_ProjectController(ApexPages.StandardController stdController){
        // Default values
        prodCertProject = false;
        directTestingAvailable = false;
        directTestingOnly = false;
        availableCertTypes = new List<SelectOption>();
        availableRegistrationPaths = new List<SelectOption>();
        availableSpecifiers = new List<SelectOption>();
        
        Id id = ApexPages.currentPage().getParameters().get('id');
        Id accId = ApexPages.currentPage().getParameters().get('CF00ND0000006KAQM_lkid');
        
        if(id == null) {
            project = new Project__c();
            project.Account__c = accId;
            String recordTypeId = ApexPages.currentPage().getParameters().get('RecordType');
            String recordType = Schema.SObjectType.Project__c.getRecordTypeInfosById().get(recordTypeId).getName();
            project.Project_Family__c = recordType;
            project.RecordTypeId = recordTypeId ;
            
            if(recordType == 'Regulatory Services')            
        		onProjectFamilyChange();
        } else {
            project = [SELECT Active__c, Name , Area_of_Practice__c, Account__c, CertificationType__c, CertificationTypeText__c, ConfigurationType__c, DirectTesting__c, External_Project_ID__c, 
                NotesClauses__c, Product__c, ProductName__c, Project_End_Date__c, ProjectEndDate__c, Project_Family__c, Project_Name__c, 
                Project_Start_Date__c, ProjectStartDate__c, Project_Status__c, Project_Template__c, RegistrationPath__c, Standard__c, SubPractice__c, ProductId__c,
                Product__r.Id, Product__r.Name, Product__r.LongProductName__c, Product__r.Standard__c, 
                Product__r.CertificationType__c, Product__r.ClientSector__c, AccreditationDeliveryBody__c, QuoteSignature__c, Specifier__c, ContractParty__c
                FROM Project__c WHERE Id = :id];
            
            productAttributes = [SELECT DirectTesting__c, ConfigurationType__c, ConfigurationTypeforApplication__c, ConfigurationTypeforETS__c, 
                            ConfigurationTypeforGapAnalysis__c, CertificationType__c, SANASAccreditation__c, JAZAccreditation__c, UKASAccreditation__c, RVAAccreditation__c 
                            FROM ProductAttributes__c WHERE Product__c= :project.Product__c];
            
            if(project.Project_Family__c == 'Product Certification') {
                prodCertProject = true;
                selectedCertificationTypes = project.CertificationTypeText__c != null ? project.CertificationTypeText__c.split(',') : null;
            }
        }        
    }
    
    public void onProjectFamilyChange() {
        if(project.Project_Family__c == 'Product Certification') {
            prodCertProject = true;
            project.Project_Template__c = 'Generic';
        } else if(project.Project_Family__c == 'Customized Audits') {
            prodCertProject = false;
            project.Project_Template__c = 'Generic';
            //searchCustomisedAuditProducts();
        } else if(project.Project_Family__c == 'Regulatory Services') {
        	prodCertProject = false;
            project.Area_of_Practice__c = 'NA';
            project.Project_Template__c = 'Generic';
            searchRegulatoryServicesProducts();
        } else
            prodCertProject = false;
    }
    
    public void searchProducts() {
        products = new List<Product__c>();
        
        if(String.isEmpty(project.Area_of_Practice__c) || String.isEmpty(project.SubPractice__c)) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please select both Area of Practice and Sub-Practice'));
        }
        
        if(String.isEmpty(productName) && String.isEmpty(standard)) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please enter either product name or standard for search'));
        } else {
            ApexPages.getMessages().clear();
            String query = 'SELECT Id, Name, LongProductName__c, Standard__c, CertificationType__c, ClientSector__c, RecordType.Name '  +
                                ' FROM Product__c WHERE RecordType.Name = \'Product Certification\'' +
                                ' AND ExcludefromProductCatalogue__c = False AND Active_In_SF__c=True AND AreaofPractice__c = \'' + project.Area_of_Practice__c + '\' AND SubPractice__c = \'' + project.SubPractice__c  + '\' ';
            if(String.isNotEmpty(productName) && String.isNotEmpty(standard)) {
                query = query + ' AND LongProductName__c LIKE \'%' + productName + '%\'' + ' AND Standard__c LIKE \'%' + standard + '%\'';
            } else if(String.isNotEmpty(productName)) {
                query = query + ' AND LongProductName__c LIKE \'%' + productName + '%\'';
            } else if(String.isNotEmpty(standard)) {
                query = query + ' AND Standard__c LIKE \'%' + standard + '%\'';
            }
            products = Database.query(query);
            
        }
    }
    
    public void searchCustomisedAuditProducts() {
        products = new List<Product__c>();
        
        if(String.isEmpty(project.Area_of_Practice__c)) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please select an Area of Practice'));
        }
        
        ApexPages.getMessages().clear();
        String query = 'SELECT Id, Name, LongProductName__c, Standard__c, CertificationType__c, ClientSector__c, RecordType.Name, RegistrationPaths__c, Specifier__c '  +
                            ' FROM Product__c WHERE RecordType.Name = \'Customized Audits\'' +
                            ' AND ExcludefromProductCatalogue__c = False AND Active_In_SF__c=True AND AreaofPractice__c = \'' + project.Area_of_Practice__c + '\' ';
        if(String.isNotEmpty(productName)) {
            query = query + ' AND Name LIKE \'%' + productName + '%\'';
        } else {
            query = query + ' LIMIT 10';
        }
        System.debug(query);
        products = Database.query(query);
    }
    
    public void searchRegulatoryServicesProducts() {
        products = new List<Product__c>();
        
        ApexPages.getMessages().clear();
        String query = 'SELECT Id, Name, LongProductName__c, Standard__c, CertificationType__c, ClientSector__c, RecordType.Name, RegistrationPaths__c '  +
                            ' FROM Product__c WHERE RecordType.Name = \'Regulatory Services\'' +
                            ' AND ExcludefromProductCatalogue__c = False AND Active_In_SF__c=True';
        if(String.isNotEmpty(productName)) {
            query = query + ' AND Name LIKE \'%' + productName + '%\'';
        } else {
            query = query + ' LIMIT 10';
        }
        System.debug(query);
        products = Database.query(query);
    }
    
    public void selectProduct() {
        availableCertTypes = new List<SelectOption>();
        availableRegistrationPaths = new List<SelectOption>();
        availableSpecifiers = new List<SelectOption>();
        
        String selectedProduct = System.currentPagereference().getParameters().get('selectedProductId');
        
        for(Product__c prod:products) {
            if(prod.Id == selectedProduct) {
            	if(prod.RecordType.Name == 'Customized Audits' || prod.RecordType.Name == 'Regulatory Services') {
            		String[] regPaths = prod.RegistrationPaths__c.split(';');
            		
            		for(String rp: regPaths) {
            			availableRegistrationPaths.add(new SelectOption(rp, rp));
            		}	
            	}
            	
            	if(prod.RecordType.Name == 'Customized Audits' && prod.Specifier__c != null) {
            		String[] specifiers = prod.Specifier__c.split(';');
            		
            		for(String rp: specifiers) {
            			availableSpecifiers.add(new SelectOption(rp, rp));
            		}
            	}
            	
                If(String.isNotBlank(prod.CertificationType__c)) {
                    directTestingOnly = false;
                    String[] arr = prod.CertificationType__c.split(';');
                    for(String s: arr)
                        availableCertTypes.add(new SelectOption(s, s));                     
                } else
                    directTestingOnly = true;
                
                productAttributes = [SELECT DirectTesting__c, ConfigurationType__c, ConfigurationTypeforApplication__c, ConfigurationTypeforETS__c, 
                            ConfigurationTypeforGapAnalysis__c, CertificationType__c, SANASAccreditation__c, JAZAccreditation__c, UKASAccreditation__c, RVAAccreditation__c
                            FROM ProductAttributes__c WHERE Product__c= :prod.Id];
                directTestingAvailable = productAttributes.size() > 0 ? productAttributes.get(0).DirectTesting__c : false;
                    
                selectedCertificationTypes = new String[]{};
                project.RegistrationPath__c = '';
                project.ConfigurationType__c = '';
                System.debug(prod.RecordType.Name);
                if(prod.RecordType.Name == 'Customized Audits' || prod.RecordType.Name == 'Regulatory Services')
                    project.Project_Name__c = prod.Name;
                else
                    project.Project_Name__c = prod.LongProductName__c;
                    
                project.Product__c = selectedProduct;
                    
                if(directTestingOnly && productAttributes.size() > 0)
                    project.ConfigurationType__c = productAttributes.get(0).ConfigurationTypeforApplication__c;
                    
                break;
            }
        }
        project.DirectTesting__c = false;
        ApexPages.getMessages().clear();
    }
    
    public void updateConfiguratorType() {
        if(productAttributes != null && productAttributes.size() > 0) {
            if(project.RegistrationPath__c == 'Application')
                project.ConfigurationType__c = productAttributes.get(0).ConfigurationTypeforApplication__c;
            else if(project.RegistrationPath__c == 'Extension to Scope')
                project.ConfigurationType__c = productAttributes.get(0).ConfigurationTypeforETS__c;
            else if(project.RegistrationPath__c == 'Gap Analysis')
                project.ConfigurationType__c = productAttributes.get(0).ConfigurationTypeforGapAnalysis__c; 
        }
        
        if(project.ConfigurationType__c == 'Complex')
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Info,'You have selected a Complex configurator, please collaborate with the team for specifics'));
    }

    public PageReference save() {
        try {
            if(selectedCertificationTypes != null && project.Id == null) {
                String selCert = '', selCertTxt ='';
                for(String s:selectedCertificationTypes) {
                    selCert = (selCert == ''? '' : selCert + ';') + s; //selCert + ';' + s;
                    selCertTxt = (selCertTxt == ''? '' : selCertTxt + ',') + s;
                }
                project.CertificationType__c = selCert; 
                project.CertificationTypeText__c = selCertTxt;
            }
            
            if(project.Id == null){
                accreditationDeliveryBody();
                if(project.DirectTesting__c)
                    project.RegistrationPath__c = '';
                    
                if(project.Project_Family__c == 'Customized Audits' && project.ContractParty__c == null
                	&& project.Area_of_Practice__c != 'Internal Audit') {
                	ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Please choose the Contract Party'));
                	return null;
                }
                
                if(selectedSpecifiers != null)
                	project.Specifier__c = String.join(selectedSpecifiers, ';');
                
                insert project;
            } else {
                accreditationDeliveryBody();
                update project;
            }
            
            return new Pagereference('/' + project.Id);
        } catch(Exception e){
            ApexPages.addMessages(e);
        }
        
        return null;
    }
    
    private void accreditationDeliveryBody() {
        
        if(project.Project_Family__c == 'Professional Services' || project.Project_Family__c == 'Customized Audits' || project.Project_Family__c == 'Regulatory Services')
            return;
               
        String accreditationDeliveryBody = '', quoteSignature = '';
        
        if(selectedCertificationTypes == null || selectedCertificationTypes.size() == 0) {//This is only direct testing
            for(ProductAttributes__c attribute:productAttributes) {
                if(attribute.SANASAccreditation__c == 'Yes'){
                    accreditationDeliveryBody = 'Accredited by SANAS Delivered by BSI Group South Africa (Pty) Ltd';
                    quoteSignature = quoteSignature + ';' + 'SANAS';
                } else if(attribute.JAZAccreditation__c == 'Yes') {
                    accreditationDeliveryBody = 'Accredited by JAS-ANZ delivered by BSI Group ANZ Pty Ltd';
                    quoteSignature = quoteSignature + ';' + 'JAZ';
                } else if(attribute.UKASAccreditation__c == 'Yes') {
                    accreditationDeliveryBody = 'Delivered by BSI Assurance UK Limited';
                    quoteSignature = quoteSignature + ';' + 'UKAS';
                } else if(attribute.RVAAccreditation__c == 'Yes') {
                    accreditationDeliveryBody = 'Delivered by BSI Group The Netherlands B.V.';
                    quoteSignature = quoteSignature + ';' + 'RVA';
                } else {
                    accreditationDeliveryBody = 'Delivered by BSI Assurance UK Limited';
                    quoteSignature = quoteSignature + ';' + 'UKAS';
                }
            }
            
            project.AccreditationDeliveryBody__c = (project.AccreditationDeliveryBody__c == '' || project.AccreditationDeliveryBody__c == null 
                                                ? accreditationDeliveryBody : project.AccreditationDeliveryBody__c + '\n' + accreditationDeliveryBody);
            project.QuoteSignature__c = quoteSignature;
            return;
        }
        
        
        Set<String> certTypes = new Set<String>(selectedCertificationTypes);
        project.AccreditationDeliveryBody__c = '';
        // For each of the selected certification type find the Product Attribute record and get the accreditation body
        for(String certType:certTypes) {
            for(ProductAttributes__c attribute:productAttributes) {
                if(certType == 'ESMA') {
                    accreditationDeliveryBody = certType + ' - Delivered by BSI Management Systems Limited (Dubai Br)';
                    quoteSignature = quoteSignature + ';' + 'ESMA';
                } else if(certType == attribute.CertificationType__c) {
                    if(attribute.SANASAccreditation__c == 'Yes'){
                        accreditationDeliveryBody = certType + ' - Accredited by SANAS Delivered by BSI Group South Africa (Pty) Ltd';
                        quoteSignature = quoteSignature + ';' + 'SANAS';
                    } else if(attribute.JAZAccreditation__c == 'Yes') {
                        accreditationDeliveryBody = certType + ' - Accredited by JAS-ANZ delivered by BSI Group ANZ Pty Ltd';
                        quoteSignature = quoteSignature + ';' + 'JAZ';
                    } else if(attribute.UKASAccreditation__c == 'Yes') {
                        if(certType == 'Kitemark')
                            accreditationDeliveryBody = certType + ' - Accredited by UKAS delivered by BSI Assurance UK Limited';
                        else if(certType == 'CE (NB 2797)')
                            accreditationDeliveryBody = certType + ' - Delivered by BSI Assurance UK Limited under our notified body status';
                        else if(certType == 'CE (NB 0086)')
                            accreditationDeliveryBody = certType + ' - Delivered by BSI Assurance UK Limited under our notified body status';
                        else
                            accreditationDeliveryBody = certType + ' - Delivered by BSI Assurance UK Limited';
                        
                        quoteSignature = quoteSignature + ';' + 'UKAS';
                    } else if(attribute.RVAAccreditation__c == 'Yes') {
                        accreditationDeliveryBody = certType + ' - Delivered by BSI Group The Netherlands B.V. under our notified body status';
                        quoteSignature = quoteSignature + ';' + 'RVA';
                    } else {
                        accreditationDeliveryBody = certType + ' - Delivered by BSI Assurance UK Limited';
                        quoteSignature = quoteSignature + ';' + 'UKAS';
                    }
                }
                System.debug(certType + ' Single--' +  selectedCertificationTypes.size() + 'Testinggggg');
            }
            
            project.AccreditationDeliveryBody__c = (project.AccreditationDeliveryBody__c == '' || project.AccreditationDeliveryBody__c == null 
                                ? accreditationDeliveryBody : project.AccreditationDeliveryBody__c + '\n' + accreditationDeliveryBody);
            project.QuoteSignature__c = quoteSignature;
        }
    }
}