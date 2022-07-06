/*
* Created By:  PC K2 - May 2020
* Purpose: Class to integrate with Mimeo API Webservice methods 
*
* changelog
* ------------------------------------------------
*/

public with sharing class MimeoAPI {

    public String apiURL;
    private String subscriptionKey;

    public class FindDocumentsResponse {
        public Integer TotalCount;
        public List<FindDocumentsData> Data;
    }
    
    public class FindDocumentsData {
        public String DigitalAssetId;
        public String FileName;
        public String ContentName;
        public Double FileSize;
        public String ContentType;
        public Double Version;
        public String Created;
        public String LastModifyTime;
        public String OwnerUserId;
        public String CreateUserName;
        public String StoreItemId;
        public Integer Status;
        public String CatalogStoreItemId;
        public String RemovedDate;
        public Boolean InCategories;
    }
    
    public class CreateDistributionRequest {
        public String DistributionTitle;
        public List<CreateDistributionDocument> Documents;
        public Boolean ExpirationDateEnabled;
        public String ExpirationDate;
        public Boolean GroupNotesEnabled;
        public String ReferenceFields;
        public String KeyType;
        public Integer NumberOfKeys;
    }
    
    public class CreateDistributionDocument {
        public String AssetId;
        public Boolean AllowDownload;
        public Boolean AllowLocalPrinting;
        public Boolean AllowCopyPaste;
        public Boolean AllowOfflineDownload;
    }
    
    public class CreateDistributionResponse {
        public Boolean Success;
        public Integer Code;
        public String DistributionId;
        List<String> EContentCodes;
        public Integer ErrorType;
        public String RedeemKeyUrl;
        public String ErrorMessage;
    }

    public class ResponseWrapper {
        public String json;
        public Integer statusCode;
    }

    public class AssignKeysResponse200 {
        public String AssignEmail;
        public String Status;
        public String Message;
        public String EContentCode;
    }

    //constructor
    public mimeoAPI(String countryCode){
        System.debug('### MimeoAPI');
        try{
            Mimeo_Settings__c ms = Mimeo_Settings__c.getOrgDefaults();
            apiURL = ms.API__c;
            
            Mimeo_Country_Settings__mdt mcs = [SELECT API_Subscription_Key__c FROM Mimeo_Country_Settings__mdt WHERE Label = :countryCode LIMIT 1];
            subscriptionKey = mcs.API_Subscription_Key__c;
        }catch(Exception e){
            System.debug('### MimeoAPI error: ' + e.getMessage());
        }
    }

    //create Http Request
    public HttpRequest buildHttpRequest(String method, String url){
        HttpRequest req = new HttpRequest();
        req.setMethod(method);
        req.setEndpoint(apiURL + url);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Ocp-Apim-Subscription-Key', subscriptionKey);
        return req;
    }

    //find Documents
    public FindDocumentsResponse findDocuments(String documentName){
        System.debug('### MimeoAPI.findDocuments: ' + documentName);
        if(String.isBlank(documentName)){
            System.debug('### MimeoAPI.findDocuments error - Document Name cannot be empty');
            FindDocumentsResponse fdr = new FindDocumentsResponse();
            fdr.TotalCount = 0;
            return fdr;
        }

        Http h = new Http();
        HttpRequest req = buildHttpRequest('POST', 'assets/libraries/finddocuments');
        req.setBody('{"Name": "' + documentName + '", "PageSize":5, "PageIndex":1}');
        
        HttpResponse res;
        if(!Test.isRunningTest()){
            System.debug('### MimeoAPI findDocuments request: ' + req);
            System.debug('### MimeoAPI findDocuments request body: ' + req.getBody());
            res = h.send(req);
        }else{
            res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"TotalCount":1, "Data":[{"DigitalAssetId":"01", "FileName":"01.pdf", "ContentName":"test"}]}');
        }
        System.debug('### MimeoAPI findDocuments response: ' + res);
        System.debug('### MimeoAPI findDocuments response body: ' + res.getBody());
        
        FindDocumentsResponse fdr;
        try{
            fdr = (FindDocumentsResponse)JSON.deserialize(res.getBody(), FindDocumentsResponse.class);
        }catch(Exception e){
            System.debug('### mimeoAPI.findDocuments error: ' + e.getMessage());
            fdr = new FindDocumentsResponse();
            fdr.TotalCount = 0;
        }

        System.debug('### MimeoAPI FindDocumentsResponse: ' + fdr);
        return fdr;
    }


    //create Distribution
    public CreateDistributionResponse createDistribution(String eventId){
        System.debug('### MimeoAPI.createDistribution: ' + eventId);
        if(String.isBlank(eventId)){
            System.debug('### MimeoAPI.createDistribution error - Training Event Id cannot be empty');
            CreateDistributionResponse cdr = new CreateDistributionResponse();
            cdr.Success = false;
            cdr.ErrorMessage = 'Training Event Id cannot be empty';
            return cdr;
        }
        
        Training_Event__c event = [SELECT Name, Start_date__c, End_Date3__c, Course__c FROM Training_Event__c WHERE Id = :eventId];
        Date endDate = event.End_Date3__c.addDays(180);

        //distribution
        CreateDistributionRequest cdRequest = new CreateDistributionRequest();
        cdRequest.DistributionTitle = event.Name;
        cdRequest.Documents = new List<CreateDistributionDocument>();
        cdRequest.ExpirationDateEnabled = true;
        cdRequest.ExpirationDate = endDate.year() + '-' + endDate.month() + '-' + endDate.day();
        cdRequest.GroupNotesEnabled = false;
        cdRequest.ReferenceFields = event.Name;
        cdRequest.KeyType = 'Unique';
        cdRequest.NumberOfKeys = 1;
        
        //documents
        List<Mimeo_Document__c> mimeoDocumentList = [SELECT Asset_Id__c FROM Mimeo_Document__c WHERE Course__c = :event.Course__c AND Active__c = true];
        for(Mimeo_Document__c doc : mimeoDocumentList){
            CreateDistributionDocument cdd = new CreateDistributionDocument();
            cdd.AssetId = doc.Asset_Id__c;
            cdd.AllowDownload = true;
            cdd.AllowLocalPrinting = true;
            cdd.AllowCopyPaste = true;
            cdd.AllowOfflineDownload = true;
            cdRequest.Documents.add(cdd);
        }
        
        Http h = new Http();
        HttpRequest req = buildHttpRequest('POST', 'distributions/create');
        req.setBody(JSON.serialize(cdRequest));
        
        HttpResponse res;
        if(!Test.isRunningTest()){
            System.debug('### MimeoAPI createDistribution request: ' + req);
            System.debug('### MimeoAPI createDistribution request body: ' + req.getBody());
            res = h.send(req);
        }else{
            res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"Success":true, "Code":0, "DistributionId":"00000000-0000-0000-0000-000000000000", "EContentCodes":["XXXXXXXXXXXX"], "ErrorType":0, "RedeemKeyUrl":"https://mimeo.digital/#?k=", "ErrorMessage":""}');
        }
        System.debug('### MimeoAPI createDistribution response: ' + res);
        System.debug('### MimeoAPI createDistribution response body: ' + res.getBody());
        
        CreateDistributionResponse cdr;
        try{
            cdr = (CreateDistributionResponse)JSON.deserialize(res.getBody(), CreateDistributionResponse.class);
        }catch(Exception e){
            System.debug('### mimeoAPI.createDistribution error: ' + e.getMessage());
            cdr = new CreateDistributionResponse();
            cdr.Success = false;
            cdr.ErrorMessage = e.getMessage();
        }

        System.debug('### MimeoAPI CreateDistributionResponse: ' + cdr);
        return cdr;
    }

    //assign Keys To Users
    public ResponseWrapper assignKeysToUsers(String email, String firstName, String lastName, String distributionId){
        System.debug('### MimeoAPI.assignKeysToUsers: ' + email + ', ' + firstName + ', ' + lastName + ', ' + distributionId);
        if(String.isBlank(email) || String.isBlank(firstName) || String.isBlank(lastName) || String.isBlank(distributionId)){
            System.debug('### MimeoAPI.assignKeysToUsers error - Email, FirstName, LastName, Distribution Id cannot be empty');
            ResponseWrapper wrapper = new ResponseWrapper();
            wrapper.statusCode = 0;
            return wrapper;
        }

        Http h = new Http();
        HttpRequest req = buildHttpRequest('POST', 'distributions/' + distributionId + '/direct-distributions');
        req.setBody('{"UserDetails": [{"Email": "' + email + '", "FirstName": "' + firstName + '", "LastName": "' + lastName + '"}]}');
        
        HttpResponse res;
        if(!Test.isRunningTest()){
            System.debug('### MimeoAPI assignKeysToUsers request: ' + req);
            System.debug('### MimeoAPI assignKeysToUsers request body: ' + req.getBody());
            res = h.send(req);
        }else{
            res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('[{"AssignEmail": "test@test.com", "Status": "Success", "Message": "Key assigned successfully", "EContentCode": "test"}]');
        }
        System.debug('### MimeoAPI assignKeysToUsers response: ' + res);
        System.debug('### MimeoAPI assignKeysToUsers response body: ' + res.getBody());

        ResponseWrapper wrapper = new ResponseWrapper();
        wrapper.json = res.getBody();
        wrapper.statusCode = res.getStatusCode();

        System.debug('### MimeoAPI ResponseWrapper: ' + wrapper);
        return wrapper;
    }

    //revoke Keys From Distribution
    public ResponseWrapper revokeKeysFromDistribution(String key){
        System.debug('### MimeoAPI.revokeKeysFromDistribution: ' + key);
        if(String.isBlank(key)){
            System.debug('### MimeoAPI.revokeKeysFromDistribution error - key cannot be empty');
            ResponseWrapper wrapper = new ResponseWrapper();
            wrapper.statusCode = 0;
            return wrapper;
        }

        Http h = new Http();
        HttpRequest req = buildHttpRequest('POST', 'distributions/keys/' + key + '/revoke');
        req.setBody('');

        HttpResponse res;
        if(!Test.isRunningTest()){
            System.debug('### MimeoAPI revokeKeysFromDistribution request: ' + req);
            System.debug('### MimeoAPI revokeKeysFromDistribution request body: ' + req.getBody());
            res = h.send(req);
        }else{
            res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"XXXXXXXXXXXX key is successfully revoked."}');
        }
        System.debug('### MimeoAPI revokeKeysFromDistribution response: ' + res);
        System.debug('### MimeoAPI revokeKeysFromDistribution response body: ' + res.getBody());

        ResponseWrapper wrapper = new ResponseWrapper();
        wrapper.json = res.getBody();
        wrapper.statusCode = res.getStatusCode();

        System.debug('### MimeoAPI ResponseWrapper: ' + wrapper);
        return wrapper;
    }
}