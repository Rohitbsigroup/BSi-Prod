/*
* Created By:  Philip Holtom (philip.holtom@opensymmetry.com)
* Updated By : Vimlesh Azad - June 2017 
* Purpose: Class to record LMS API Webservice methods 
*
* changelog
* ------------------------------------------------
* PC K2           12-10-2018    optimised methods, added fix in getCourseDetails() for AssignedDate
* PC K2           17-12-2019    re-written methods to further optimise
* JS              18-10-2021    adjusted the setting for Score as was diving by number of modules   
*/

public with sharing class LitmosAPI {

    public String apiKey;
    public String apiURL;
    public String source;
    public String parseid;
    public static Boolean TestRunning = true;

    public class CourseDetails {
        public String CourseId {get; set;}
        public DateTime AccessTillDate {get; set;}
        public DateTime AssignedDate {get; set;}
        public Boolean Complete {get; set;}
        public Decimal PercentageComplete {get; set;}
        public DateTime DateCompleted {get; set;}
        public Decimal Score {get; set;}
        public Decimal Attempt {get; set;}
        public Decimal Passmark {get; set;}
    }

    public class UserDetails {
        public String userId;
        public Boolean active;
        public DateTime createdDate;
        public String email;
        public String firstName;
        public String lastName;
        public String loginKey;
        public String userName;
        public Integer statusCode;
    }

    public class LitmosUser {
        public String Id;
        public Boolean Active;
        public DateTime CreatedDate;
        public String Email;
        public String FirstName;
        public String LastName;
        public String LoginKey;
        public String UserName;
        public Integer statusCode;
    }


    /* UTILITY */

    //create a generic Http request object based on a standard user search
    public HttpRequest buildHttpRequest(String method, String searchtext){
        if(String.isBlank(apiKey) || String.isBlank(apiURL) || String.isBlank(source)){
            LitmosSettings__c ls = LitmosSettings__c.getOrgDefaults();
            apiKey = ls.API_Key__c;
            apiURL = ls.API__c;
            source = ls.Source__c;
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint(apiURL +  'users?source=' + source + '&search=' + searchtext + '&sendmessage=false'); 
        req.setMethod(method);
        req.setHeader('apikey', apiKey);
        req.setHeader('Content-Type', 'text/xml');
        return req;
    }
    
    //debug Status Code
    public Integer handleWebServiceResponse(HttpResponse res){
        Integer statusCode = 999;
        try{
            statusCode = res.getStatusCode();
            System.debug('### LITMOS Http Status Code: ' + statusCode);
        }catch(Exception e){
            System.debug('### LITMOS Error in Response: ' + e.getMessage());
        }
        return statusCode;
    }

    //handling the response
    public String parseResponse(HttpResponse res, String fieldName){
        handleWebServiceResponse(res);
        String fieldValue;
        Dom.Document doc = res.getBodyDocument();
        System.debug(doc.toXmlString());
        
        //Retrieve the root element for this document.
        Dom.XMLNode envelope = doc.getRootElement();
        System.debug('**Envelope** ' + envelope);
        Dom.XMLNode[] body = envelope.getChildElements();
        System.debug('**Body** ' + body);

        for(Dom.XMLNode child : body){
            for(dom.XmlNode awr : child.getChildren()){
                if(awr.getName() == fieldName){
                    System.debug('*** LITMOS *** ' + fieldName + ': ' + awr.getText());
                    fieldValue = awr.getText();
                    return fieldValue;
                }
            }  
        }
        return fieldValue;
    }
    
    //handling the response (different to handle XML document when parseresponse does not return required node)
    public String parseRetResponse(HttpResponse res, String fieldName){
        handleWebServiceResponse(res);  
    
        Dom.Document doc = res.getBodyDocument();
        System.debug(doc.toXmlString());
        
        //Retrieve the root element for this document.
        Dom.XMLNode envelope = doc.getRootElement();
        System.debug('**Envelope** ' + fieldName + ': ' + envelope);
        return envelope.getChildElement(fieldName, null).getText();
    }


    /* COURSE */
  
    public void assignCourse(String userId, String courseId, Boolean isTest){
        System.debug('');
        System.debug('### LitmosAPI.assignCourse: ' + userId + ', ' + courseId + ', ' + isTest);
        Http h = new Http();
        HttpRequest req = buildHttpRequest('POST', '');
        req.setEndpoint(apiURL + 'users/' + userId + '/courses?source=' + source + '&sendmessage=false');
        req.setBody('<Courses><Course><Id>' + courseId + '</Id></Course></Courses>');  

        HttpResponse res;
        if(!isTest){
            res = h.send(req);
        }else{
            res = new HttpResponse();
            res.setStatusCode(200);
        }
        System.debug('### response: ' + res);
        System.debug('### response body: ' + res.getBody());
    }

    public String getCourseAssignedDate(String email, String courseName, Boolean isTest){
        String assignedDate;
        
        //Get all the ID's required
        String userId = getUserId(email, isTest); 
        System.debug('*** LITMOS User ID:**** ' + userId);

        //Get CourseID
        String courseId = getCourseId(coursename, isTest);
        System.debug('*** LITMOS CourseID: ***** ' + courseId);

        Http h = new Http(); 
        HttpRequest req = buildHttpRequest('GET', '');
        req.setEndpoint(apiURL + 'users/' + userId + '/courses/'+ courseId + '?source=' + source + '&search=' + EncodingUtil.urlEncode(courseName,'UTF-8') + '&sendmessage=false');  
        
        HttpResponse res;
        if(!isTest){
            res = h.send(req);
            System.debug('##response GetCourseAssignedDate## '+ res.getBody());
        }else{
            res = new HttpResponse();
            res.setStatusCode(200);
            System.debug('*** LITMOS TEST MODE ***');
            res.setbody('<Course><Id>1xjF9osAXp81</Id><Code>OA301401ENUK</Code><Name>ONLINE ASSESSMENT - LITMOS</Name><Active>true</Active><Complete>true</Complete><PercentageComplete>100.00</PercentageComplete><DateCompleted>2013-02-15T10:11:56.077</DateCompleted><UpToDate>true</UpToDate><Overdue>false</Overdue><AssignedDate>2013-02-15T10:11:56.077</AssignedDate></Course>');
            handleWebServiceResponse(res);
        }
        assignedDate = parseRetResponse(res, 'AssignedDate');
        return assignedDate;
    }    

    public String getCourseAccessTillDate(String emailAddress, String courseName, Boolean isTest){
        String accessTillDate;
        
        //Get all the ID's required
        String userId = getUserId(emailAddress, isTest); 
        System.debug('*** LITMOS User ID:**** ' + userId);
        
        //Get CourseID
        string courseId = getCourseId(courseName, isTest);
        System.debug('*** LITMOS CourseID: ***** ' + courseId);

        Http h = new Http(); 
        HttpRequest req = buildHttpRequest('GET', '');
        req.setEndpoint(apiURL + 'users/' + userId + '/courses/' + courseId + '?source=' + source + '&search=' + EncodingUtil.urlEncode(courseName,'UTF-8') + '&sendmessage=false');  

        HttpResponse res;
        if(!isTest){
            res = h.send(req);
            System.debug('##response GetCourseAccessTillDate## ' + res.getBody());
        }else{
            res = new HttpResponse();
            res.setStatusCode(200);
            System.debug('*** LITMOS TEST MODE ***');
            res.setBody('<Courses xmlns:i="http://www.w3.org/2001/XMLSchema-instance"><Course><Id>1xjF9osAXp81</Id><Code>OA301401ENUK</Code><Name>ONLINE ASSESSMENT - LITMOS</Name><Active>true</Active><Complete>true</Complete><PercentageComplete>100.00</PercentageComplete><DateCompleted>2013-02-15T10:11:56.077</DateCompleted><UpToDate>true</UpToDate><Overdue>false</Overdue></Course></Courses>');
        }
        accessTillDate = parseResponse(res, 'AccessTillDate');
        return accessTillDate;
    }

    public String getCourseDateCompleted(String emailAddress, String courseName, Boolean isTest){
        String dateCompleted;

        //Get all the ID's required
        String userId = getUserId(emailAddress, isTest);
        System.debug('*** LITMOS User ID:**** ' + userId);
        
        //Get CourseID
        String courseId = getCourseId(courseName, isTest);
        System.debug('*** LITMOS CourseID: ***** ' + courseId);

        Http h = new Http(); 
        HttpRequest req = buildHttpRequest('GET', '');
        req.setEndpoint(apiURL + 'users/' + userId + '/courses/' + courseId + '?source=' + source + '&search=' + EncodingUtil.urlEncode(courseName,'UTF-8') + '&sendmessage=false');  

        HttpResponse res;
        if(!isTest){
            res = h.send(req);
            System.debug('##response GetDateCompleted## ' + res.getBody());
        }else{
            res = new HttpResponse();
            res.setStatusCode(200);
            System.debug('*** LITMOS TEST MODE ***');
            res.setbody('<Courses xmlns:i="http://www.w3.org/2001/XMLSchema-instance"><Course><Id>1xjF9osAXp81</Id><Code>OA301401ENUK</Code><Name>ONLINE ASSESSMENT - LITMOS</Name><Active>true</Active><Complete>true</Complete><PercentageComplete>100.00</PercentageComplete><DateCompleted>2013-02-15T10:11:56.077</DateCompleted><UpToDate>true</UpToDate><Overdue>false</Overdue></Course></Courses>');
        }
        dateCompleted = parseResponse(res, 'DateCompleted');
        return dateCompleted;
    }
   
    public String getCourseCompleted(String emailAddress, String courseName, Boolean isTest){
        String courseCompleted;

        //Get all the ID's required
        String userId = getUserId(emailAddress, isTest);
        System.debug('*** LITMOS User ID:**** ' + userId);

        //Get CourseID
        String courseId = getCourseId(courseName, isTest);
        System.debug('*** LITMOS CourseID: ***** ' + courseId);

        Http h = new Http(); 
        HttpRequest req = buildHttpRequest('GET', '');
        req.setEndpoint(apiURL + 'users/' + userId + '/courses/' + courseId + '?source=' + source + '&search=' + EncodingUtil.urlEncode(courseName,'UTF-8') + '&sendmessage=false');  

        HttpResponse res;
        if(!isTest){
            res = h.send(req);
            System.debug('##response GetCourseCompleted## ' + res.getBody());
        }else{
            res = new HttpResponse();
            res.setStatusCode(200);
            System.debug('*** LITMOS TEST MODE ***');
            res.setbody('<Courses xmlns:i="http://www.w3.org/2001/XMLSchema-instance"><Course><Id>1xjF9osAXp81</Id><Code>OA301401ENUK</Code><Name>ONLINE ASSESSMENT - LITMOS</Name><Active>true</Active><Complete>true</Complete><PercentageComplete>100.00</PercentageComplete><DateCompleted>2013-02-15T10:11:56.077</DateCompleted><UpToDate>true</UpToDate><Overdue>false</Overdue></Course></Courses>');
        }
        courseCompleted = parseResponse(res, 'Complete');
        return courseCompleted;
    }

    public CourseDetails getCourseDetails(String userId, String courseName, String courseId, Boolean isTest){
        System.debug('');
        System.debug('### LitmosAPI.getCourseDetails: ' + userId + ', ' + courseName + ', ' + courseId + ', ' + isTest);
        CourseDetails courseDetails = new CourseDetails();
        
        Http h = new Http(); 
        HttpRequest req = buildHttpRequest('GET', '');
        req.setEndpoint(apiURL + 'users/' + userId + '/courses/' + courseId + '?source=' + source + '&search=' + EncodingUtil.urlEncode(courseName,'UTF-8') + '&sendmessage=false');  

        HttpResponse res;
        if(!isTest){
            res = h.send(req);
        }else{
            res = new HttpResponse();
            res.setStatusCode(200);
            System.debug('*** LITMOS TEST MODE ***');
            res.setBody('<Course><Id>1xjF9osAXp81</Id><Code>OA301401ENUK</Code><Name>ONLINE ASSESSMENT - LITMOS</Name><Active>true</Active><Complete>true</Complete><PercentageComplete>100</PercentageComplete><AccessTillDate>2013-02-15T10:11:56.077</AccessTillDate><AssignedDate>2013-02-15T10:11:56.077</AssignedDate><DateCompleted>2013-02-15T10:11:56.077</DateCompleted><UpToDate>true</UpToDate><Overdue>false</Overdue><Modules><Module><Score>50</Score><Completed>true</Completed><Attempt>1</Attempt><Passmark>80</Passmark></Module></Modules></Course>');
        }
        System.debug('### response: ' + res);
        System.debug('### response body: ' + res.getBody());

        if(res.getStatusCode() == 200){
            courseDetails.CourseId = courseId;
            Dom.Document doc = res.getBodyDocument();
            System.debug(doc.toXmlString());
                
            //Retrieve the root element for this document.
            Dom.XMLNode root = doc.getRootElement();
            String data;

            data = root.getChildElement('AccessTillDate', null).getText();
            courseDetails.AccessTillDate = (data != '') ? DateTime.valueOf(data.replace('T', ' ').left(19)) : null;

            data = root.getChildElement('AssignedDate', null).getText();
            courseDetails.AssignedDate = (data != '') ? DateTime.valueOf(data.replace('T', ' ').left(19)) : null;

            // PC K2 20181017 Assigned Date is invalid when fetched immediately after User re-activation
            // this fix assumes Course is assigned at the same time this call is processed
            System.debug('### courseDetails.AssignedDate: ' + courseDetails.AssignedDate);
            if((courseDetails.AssignedDate != null) && (courseDetails.AssignedDate < DateTime.newInstance(1900, 1, 1))) courseDetails.AssignedDate = DateTime.now();

            data = root.getChildElement('Complete', null).getText();
            courseDetails.Complete = Boolean.valueOf(data);

            data = root.getChildElement('PercentageComplete', null).getText();
            courseDetails.PercentageComplete = Decimal.valueOf(data);

            data = root.getChildElement('DateCompleted', null).getText();
            courseDetails.DateCompleted = (data != '') ? DateTime.valueOf(data.replace('T', ' ').left(19)) : null;

            courseDetails.Attempt = 0;
            Decimal totalScore = 0;
            Decimal nModules = 0;
            Dom.XMLNode node = root.getChildElement('Modules', null);
            if (node != null) {
                Dom.XmlNode[] listNodes = node.getChildElements();
                for(Dom.XmlNode mnode : listNodes) {
                    data = mnode.getChildElement('Score', null).getText();
                    Decimal score = (data != '') ? Decimal.valueOf(data) : null;
                    //Take scores only if it is available
                    if (score != null) {
                        totalScore += score;
                        nModules += 1;
                    }

                    data = mnode.getChildElement('Attempt', null).getText();
                    Decimal attempt = (data != '') ? Decimal.valueOf(data) : null;
                    if (attempt != null && attempt > courseDetails.Attempt) {
                        courseDetails.Attempt = attempt;
                    }

                    data = mnode.getChildElement('Passmark', null).getText();
                    Decimal passmark = (data != '') ? Decimal.valueOf(data) : null;
                    if (passmark != null) {
                        courseDetails.Passmark = passmark;
                        courseDetails.Score = totalScore; //JS added 20211018
                    }
                }
            }
            
            //if (nModules > 0) {
            //    courseDetails.Score = totalScore / nModules;
            //}
        }
        return courseDetails;
    }

    public String getCourseId(String courseName, Boolean isTest){
        System.debug('');
        System.debug('### LitmosAPI.getCourseId');
        String courseId;

        Http h = new Http(); 
        HttpRequest req = buildHttpRequest('GET', '');
        req.setEndpoint(apiURL + 'courses?source=' + source + '&search=' + EncodingUtil.urlEncode(courseName,'UTF-8')+ '&sendmessage=false');  

        HttpResponse res;
        if(!isTest){
            res = h.send(req);
        }else{
            res = new HttpResponse();
            res.setStatusCode(200);
            System.debug('*** LITMOS TEST MODE ***');
            res.setBody('<Courses xmlns:i="http://www.w3.org/2001/XMLSchema-instance"><Course><Id>1xjF9osAXp81</Id><Code>OA301401ENUK</Code><Name>ONLINE ASSESSMENT - LITMOS</Name><Active>true</Active><ForSale>false</ForSale><OriginalId>32225</OriginalId><Description>QMS04105ENUK</Description><EcommerceShortDescription /><EcommerceLongDescription /></Course></Courses>');
        }
        System.debug('### response: ' + res);
        System.debug('### response body: ' + res.getBody());
        courseId = parseresponse(res, 'Id');
        return courseId;
    }
    
    public String getCoursePercentage(String emailAddress, String courseName, Boolean isTest){
        String percentageComplete;

        //Get all the ID's required
        string userId = getUserId(emailAddress, isTest);
        System.debug('*** LITMOS User ID:**** ' + userId);

        //Get CourseID
        string courseId = getCourseId(courseName, isTest);
        System.debug('*** LITMOS CourseID: *****' + courseId);
        
        Http h = new Http(); 
        HttpRequest req = buildHttpRequest('GET', '');
        req.setEndpoint(apiURL + 'users/' + userId + '/courses/' + courseId + '?source=' + source + '&search=' + EncodingUtil.urlEncode(courseName,'UTF-8') + '&sendmessage=false');  
        
        HttpResponse res;
        if(!isTest){
            res = h.send(req);
            System.debug('##response GetPercentageComplete## ' + res.getBody());
        }else{
            res = new HttpResponse();
            res.setStatusCode(200);
            System.debug('*** LITMOS TEST MODE ***');
            res.setBody('<Courses xmlns:i="http://www.w3.org/2001/XMLSchema-instance"><Course><Id>1xjF9osAXp81</Id><Code>OA301401ENUK</Code><Name>ONLINE ASSESSMENT - LITMOS</Name><Active>true</Active><Complete>true</Complete><PercentageComplete>100</PercentageComplete><DateCompleted>2013-02-15T10:11:56.077</DateCompleted><UpToDate>true</UpToDate><Overdue>false</Overdue></Course></Courses>');
        }
        handleWebServiceResponse(res);
        percentageComplete = parseResponse(res, 'PercentageComplete');
        return percentageComplete;
    }

    public void removeCourse(String emailAddress, String courseName, Boolean isTest){
        String userId = getUserId(emailAddress, isTest);
        System.debug('*** LITMOS User ID:**** ' + userId);
        
        String courseId = getCourseId(courseName, isTest);
        System.debug('*** LITMOS CourseID: ***** ' + courseId);
    
        Http h = new Http();
        HttpRequest req = buildHttpRequest('DELETE', '');
        req.setEndpoint(apiURL + 'users/' + userId + '/courses/' + courseId + '?source=' + source + '&sendmessage=false'); 

        HttpResponse res;
        if(!isTest){
            res = h.send(req);
            System.debug('##response removeCourse## ' + res.getBody());
        }else{
            res = new HttpResponse();
            res.setStatusCode(200);
        }
        handleWebServiceResponse(res);
    }


    /*  USER  */

    public Boolean activateUser(String email, String firstName, String lastName, Boolean isTest){
        Boolean userActivated;
        Integer statusCode;

        //Get all the ID's required
        String userId = getUserId(email, isTest); 
        System.debug('*** LITMOS User ID:**** ' + userId);
        System.debug('*** In User Activation ***');

        Http h = new Http(); 
        HttpRequest req = buildHttpRequest('PUT', '');
        req.setEndpoint(apiURL + 'users/'+ userId + '?source=' + source + '&sendmessage=false');  
        req.setBody('<User><Id>'+userid+'</Id> <UserName>'+email+'</UserName> <FirstName>'+firstName+'</FirstName> <LastName>'+lastName+'</LastName> <FullName></FullName> <Email>'+email+'</Email> <AccessLevel>Learner</AccessLevel> <DisableMessages>true</DisableMessages> <Active>true</Active> <LastLogin></LastLogin><LoginKey></LoginKey><IsCustomUsername>false</IsCustomUsername> <SkipFirstLogin>false</SkipFirstLogin> <TimeZone></TimeZone> </User>');
    
        HttpResponse res;
        if(!isTest){
            res = h.send(req);
            statusCode = handleWebServiceResponse(res);
            System.debug('** response from user activation api ** ' + res.getBody());
            userActivated = (StatusCode == 201 || StatusCode == 409);
        }else{
            res = new HttpResponse();
            res.setStatusCode(200);
            handleWebServiceResponse(res);
            userActivated = false;
        } 
        return userActivated;
    }

    public LitmosUser createUser(String firstName, String lastName, String email, String username, String companyName, String country, String language, String taxonomyCode, String courseId, Boolean isTest){
        System.debug('');
        System.debug('### LitmosAPI.createUser: ' + firstName + ', ' + lastName + ', ' + email + ', ' + username + ', ' + companyName + ', ' + country + ', ' + language + ', ' + taxonomyCode + ', ' + courseId + ', ' + isTest);
        LitmosUser litmosUser = new LitmosUser();
        Integer statusCode;

        Http h = new Http();
        HttpRequest req = buildHttpRequest('POST', 'users');
        req.setEndpoint(apiURL + 'users?source=' + source + '&sendmessage=false');

        //if companyName is not null, create Company Tag to send to Litmos. Litmos takes max length 100 for Company
        companyName = (companyName != null && companyName.length() > 100) ? companyName.substring(0, 100) : companyName;
        String companyTag = companyName != null ? ('<CompanyName>' + companyName + '</CompanyName>') : '';
        companyTag = companyTag.replace('&','and');

        req.setBody('<User><Id></Id><UserName>' + username +'</UserName><FirstName>' + firstName + '</FirstName><LastName>' + lastName + '</LastName><FullName></FullName><Email>' + email +'</Email><AccessLevel>Learner</AccessLevel> <DisableMessages>true</DisableMessages> <Active>true</Active> <LastLogin></LastLogin><LoginKey></LoginKey><IsCustomUsername>false</IsCustomUsername> <SkipFirstLogin>false</SkipFirstLogin> <TimeZone></TimeZone><Country>' + country + '</Country>' + companyTag + '<Culture>' + language + '</Culture></User>');
        System.debug('### request: ' + req);
        System.debug('### request body: ' + req.getBody());

        HttpResponse res;
        if(!isTest){
            res = h.send(req);
        }else{
            res = new HttpResponse();
            res.setStatusCode(409);
            System.debug('*** LITMOS TEST MODE ***');
            res.setBody('<User><Id>1xjF9osAXp81</Id><UserName>u</UserName><FirstName>f</FirstName><LastName>l</LastName><Email>email@test.com</Email><Active>true</Active><LoginKey>key</LoginKey><CreatedDate>2010-01-07T04:37:06.23</CreatedDate></User>');
        }
        System.debug('### response: ' + res);
        System.debug('### response body: ' + res.getBody());

        //handling the response
        statusCode = handleWebServiceResponse(res);
        
        // PC K2 20200112 refetch Litmos User Details to fix Litmos issue returning invalid Ids
        UserDetails litmosUserDetails = getUserDetails(username, isTest);

        Dom.XMLNode root = res.getBodyDocument().getRootElement();
        litmosUser.Id = litmosUserDetails.userId;
        litmosUser.Active = litmosUserDetails.active;
        litmosUser.CreatedDate = litmosUserDetails.createdDate;
        litmosUser.Email = root.getChildElement('Email', null).getText();
        litmosUser.FirstName = root.getChildElement('FirstName', null).getText();
        litmosUser.LastName = root.getChildElement('LastName', null).getText();
        litmosUser.LoginKey = litmosUserDetails.loginKey;
        litmosUser.UserName = root.getChildElement('UserName', null).getText();
        litmosUser.statusCode = statusCode;

        return litmosUser;
    }

    public String getUserCreatedDate(String email, Boolean isTest){
        String createdDate;

        Http h = new Http(); 
        HttpRequest req = buildHttpRequest('GET', '');
        req.setEndpoint(apiURL + 'users/details?source=' + source + '&search=' + email + '&sendmessage=false');
        
        HttpResponse res;
        if(!isTest){
            res = h.send(req);
            System.debug('** response**' + res.getBody());
            createdDate = parseresponse(res, 'CreatedDate');
            System.debug('*** Litmos User ' + email + ' Created Date *** ' + createdDate);
        }else{
            res = new HttpResponse();
            res.setStatusCode(200);
            createdDate = null;
        } 
        return createdDate;
    }

    public UserDetails getUserDetails(String username, Boolean isTest){
        System.debug('');
        System.debug('### LitmosAPI.getUserDetails');
        UserDetails userDetails = new UserDetails();

        Http h = new Http(); 
        HttpRequest req = buildHttpRequest('GET', '');
        req.setEndpoint(apiURL + 'users/' + username + '?source=' + source + '&sendmessage=false');
        
        HttpResponse res;
        if(!isTest){
            res = h.send(req);
        }else{
            res = new HttpResponse();
            res.setStatusCode(200);
            System.debug('*** LITMOS TEST MODE ***');
            res.setBody('<User><Id>1xjF9osAXp81</Id><UserName>u</UserName><FirstName>f</FirstName><LastName>l</LastName><Email>email@test.com</Email><Active>true</Active><LoginKey>key</LoginKey><CreatedDate>2010-01-07T04:37:06.23</CreatedDate></User>');
        }  
        System.debug('### response: ' + res);
        System.debug('### response body: ' + res.getBody());

        if(res.getStatusCode() == 200){
            Dom.Document doc = res.getBodyDocument();
            Dom.XMLNode root = doc.getRootElement();
            userDetails.userId = root.getChildElement('Id', null).getText();
            userDetails.active = Boolean.valueOf(root.getChildElement('Active', null).getText());
            String cDate = root.getChildElement('CreatedDate', null).getText();
            userDetails.createdDate = (cDate != '') ? DateTime.valueOf(cDate.replace('T',  ' ').left(19)) : null;
            userDetails.email = root.getChildElement('Email', null).getText();
            userDetails.firstName = root.getChildElement('FirstName', null).getText();
            userDetails.lastName = root.getChildElement('LastName', null).getText();
            userDetails.loginKey = root.getChildElement('LoginKey', null).getText();
            userDetails.userName = root.getChildElement('UserName', null).getText();
            userDetails.statusCode = 200;
            System.debug('### ' + userDetails);
        }
        return userDetails;
    }

    public String getUserId(String email, Boolean isTest){
        System.debug('');
        System.debug('### LitmosAPI.getUserId');
        String userId;

        Http h = new Http(); 
        HttpRequest req = buildHttpRequest('GET', '');
        req.setEndpoint(apiURL + 'users/' + email + '?source=' + source);
        
        HttpResponse res;
        if(!isTest){
            res = h.send(req);
            userId = parseRetResponse(res, 'Id');
        }else{
            res = new HttpResponse();
            res.setStatusCode(200);
            userId = 'Id1xjF9osAXp81';
        }
        System.debug('### response: ' + res);
        System.debug('### response body: ' + res.getBody());
        return userId;
    }

    public String getUserLoginKey(String email, Boolean isTest){
        System.debug('');
        System.debug('### LitmosAPI.getUserLoginKey');
        String userLoginKey;

        Http h = new Http(); 
        HttpRequest req = buildHttpRequest('GET', '');
        req.setEndpoint(apiURL + 'users/details?source=' + source + '&search=' + email + '&sendmessage=false');
        
        HttpResponse res;
        if(!isTest){
            res = h.send(req);
            userLoginKey = parseresponse(res, 'LoginKey');
        }else{
            res = new HttpResponse();
            res.setStatusCode(200);
            userLoginKey = 'Test';
        }
        System.debug('### response: ' + res);
        System.debug('### response body: ' + res.getBody());
        return userLoginKey;
    }

    public String getUserStatus(String email, Boolean isTest){
        String userActive;

        //Get all the ID's required
        String userId = getUserId(email, isTest);
        System.debug('*** LITMOS User ID:**** ' + userId);
        
        Http h = new Http(); 
        HttpRequest req = buildHttpRequest('GET', '');
        req.setEndpoint(apiURL + 'users/' + userId + '?source=' + source + '&search=' + email + '&sendmessage=false');
        
        HttpResponse res;
        if(!isTest){
            res = h.send(req);
            userActive = parseRetResponse(res, 'Active');
        }else{
            res = new HttpResponse();
            res.setStatusCode(200);
            userActive = 'true';
        } 
        return userActive;
    }

    public LitmosUser updateUser(String userId, String firstName, String lastName, String email, String username, String companyName, String country, String language, Boolean isTest){
        System.debug('');
        System.debug('### LitmosAPI.updateUser');
        LitmosUser litmosUser = new LitmosUser();
        Integer statusCode;

        Http h = new Http(); 
        HttpRequest req = buildHttpRequest('PUT', '');
        req.setEndpoint(apiURL + 'users/' + userId + '?source=' + source + '&sendmessage=false');
    
        String companyTag = (companyName != null) ? ('<CompanyName>' + companyName + '</CompanyName>') : '';
        companyTag = companyTag.replace('&','and');

        req.setBody('<User><Id>' + userId + '</Id><UserName>' + username +'</UserName><FirstName>' + firstName + '</FirstName><LastName>' + lastName + '</LastName><FullName></FullName><Email>' + email +'</Email> <DisableMessages>true</DisableMessages> <Active>true</Active> <LastLogin></LastLogin><LoginKey></LoginKey><IsCustomUsername>false</IsCustomUsername> <SkipFirstLogin>false</SkipFirstLogin> <TimeZone></TimeZone><Country>' + country + '</Country>' + companyTag + '<Culture>' + language + '</Culture></User>');
        System.debug('Update user request body: ' + req.getBody());

        HttpResponse res;
        if(!isTest){        
            res = h.send(req);
        }else{
            res = new HttpResponse();
            res.setStatusCode(200);
            System.debug('*** LITMOS TEST MODE ***');
            res.setBody('<User><Id>1xjF9osAXp81</Id><UserName>u</UserName><FirstName>f</FirstName><LastName>l</LastName><Email>email@test.com</Email><Active>true</Active><LoginKey>key</LoginKey><CreatedDate>2010-01-07T04:37:06.23</CreatedDate></User>');
        }
        System.debug('### response: ' + res);
        System.debug('### response body: ' + res.getBody());

        //handling the response
        statusCode = handleWebServiceResponse(res);

        UserDetails litmosUserDetails = getUserDetails(username, isTest);
        litmosUser.Id = litmosUserDetails.userId;
        litmosUser.Active = litmosUserDetails.active;
        litmosUser.CreatedDate = litmosUserDetails.createdDate;
        litmosUser.Email = litmosUserDetails.email;
        litmosUser.FirstName = litmosUserDetails.firstName;
        litmosUser.LastName = litmosUserDetails.lastName;
        litmosUser.LoginKey = litmosUserDetails.loginKey;
        litmosUser.UserName = litmosUserDetails.userName;
        litmosUser.statusCode = statusCode;
        return litmosUser;
    }

}