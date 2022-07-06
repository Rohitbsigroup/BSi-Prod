/**
*  Author    : Chandrashekar HL
*  Description  : 1)To display the Opportunity, Account & Contact information upon CIF request
*  Enchancement : 1)Sending the Account and Contact information to the Appian System to update on there end to make sure information in SF 
*                 and Appian are in sync based on the Account and Contact Update Request
*				  2) Error Handling
*/
public with sharing class emq_CIFRequestController {
    
    public Opportunity opportunity {get; set;}
    public CustomOpportunity custOpportunity{get; set;}
    public List<ContactWrapper> contacts {get; set;}    
    public boolean canRequestCIF {get; set;}
    public boolean backToOpp {get; set;}
    public boolean updateForm {get; set;}
    public boolean cifForm {get; set;}
    public boolean submissionSuccess {get; set;}    
    public Map<String, Object> jsonDeserialize{get; set;}
    public  Map<String, Object> accDetails{get; set;}    
    public Map<String, Object> conDetails{get; set;}    
    public string preAccBillStreet {get; set;}
    public string preLocalAccBillStreet {get; set;}
    public List<CustomContact> conRecList {get; set;}
    public CustomContact conRec {get; set;}
    public CustomAccount accountRec  {get; set;}
    public string billingStreet {get; set;}
    // public string localBillingStreet {get; set;}
    public string missingFields = '';
    
    public emq_CIFRequestController(ApexPages.StandardController controller) {
        
        Id id = controller.getRecord().id;
        opportunity = [SELECT 
                       Id, OpportunityID2__c, Name, Owner.Id, Owner.Name, Owner.Email, Owner.FederationIdentifier, DeliveryDateExpectations__c, CIFStatus__c, StageName,
                       AccountId, Account.Name, Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingPostalCode, Account.BillingCountry, Account.Website,Account.NameLocal,Account.Local_City_c__c,
                       Account.Local_Country__c,Account.Local_Post_Code__c,Account.Local_State__c,Account.Local_Street__c, PrimaryContact__r.firstNameLocal, PrimaryContact__r.LastNameLocal,                       
                       PrimaryContact__c, PrimaryContact__r.FirstName, PrimaryContact__r.LastName, PrimaryContact__r.Title, PrimaryContact__r.Phone, PrimaryContact__r.MobilePhone, PrimaryContact__r.Email,
                       Consultant1__c, Consultant1__r.FirstName, Consultant1__r.LastName, Consultant1__r.Title, Consultant1__r.Phone, Consultant1__r.MobilePhone, Consultant1__r.Email,Consultant1__r.FirstNameLocal,Consultant1__r.LastNameLocal
                       FROM Opportunity WHERE Id = :id FOR UPDATE];    
        
        List<Contact> accountContacts = [SELECT Id, FirstName, LastName, Title, Phone, MobilePhone, Email,FirstNameLocal,LastNameLocal
                                         FROM Contact WHERE AccountId = :opportunity.AccountId AND Id NOT IN (:opportunity.PrimaryContact__c)];
        contacts = new List<ContactWrapper>();
        
        for(Contact contact: accountContacts) {
            contacts.add(new ContactWrapper(contact));
        }
        
        canRequestCIF = bg_CustomSettingsUtils.GetPermissionSettings().CanRequestforCIF__c;
        submissionSuccess = false;
        if(opportunity.CIFStatus__c == 'CIF Accepted' || opportunity.CIFStatus__c == 'Voided' || opportunity.CIFStatus__c == 'Cancelled by BSI'){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, system.label.Cif_Nothing_To_Submit));
            backToOpp = true;
            updateForm = false;
            cifForm = false;
        }
        else if(opportunity.CIFStatus__c == 'Requested' || opportunity.CIFStatus__c == 'CIF Submitted' || opportunity.CIFStatus__c == 'CIF Incomplete' || 
                opportunity.CIFStatus__c == 'Pending Queries from customer'){
                    updateForm = true;
                    cifForm = false;
                }else{
                    updateForm = false;
                    cifForm = true;
                }
        
        if(!canRequestCIF) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, system.label.Cif_Insufficient_Permission));
            canRequestCIF = false;
        }   
        
        /*if(opportunity.Owner.Id != UserInfo.getUserId()) {
ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Only opportunity owners are allowed to Request for CIF. Please contact your acministrator.'));
canRequestCIF = false;
}*/   
        
        //Start - Fetching the Json data from the CIF Histroy Object to display the previous submitted data based on there previous request.
        //it might be Account or Contact Update request, If not both fetch the original json (Cif Requested) for the future Account or Contact 
        //Update request.
        List<CIFHistory__c> cifHisRecordAccList = new List<CIFHistory__c> ();
        List<CIFHistory__c> cifHisRecordConList = new List<CIFHistory__c> ();
        List<CIFHistory__c> cifHisRecord =  [SELECT id, opportunity__r.name, Request_Payload__c FROM CIFHistory__c WHERE Opportunity__c  =: id and Status__c = 'Requested' ORDER BY CreatedDate DESC  LIMIT 1];
        List<CIFHistory__c> cifHisAccRecord =  [SELECT id, opportunity__r.name, Request_Payload__c FROM CIFHistory__c WHERE Opportunity__c  =: id and Status__c = 'Account Update' ORDER BY CreatedDate DESC  LIMIT 1];
        List<CIFHistory__c> cifHisConRecord =  [SELECT id, opportunity__r.name, Request_Payload__c FROM CIFHistory__c WHERE Opportunity__c  =: id and Status__c = 'Contact Update' ORDER BY CreatedDate DESC  LIMIT 1];
        
        if(cifHisAccRecord.size() < 1 ){
            cifHisRecordAccList.addall(cifHisRecord);
        }else{
            cifHisRecordAccList.addall(cifHisAccRecord);
        }
        
        if(cifHisConRecord.size() < 1 ){
            cifHisRecordConList.addall(cifHisRecord);
        }else{
            cifHisRecordConList.addall(cifHisConRecord);
        }
        
        if(cifHisRecordAccList.size()  > 0){
            for(CIFHistory__c cifHisRec: cifHisRecordAccList){
                if( String.isNotBlank(cifHisRec.Request_Payload__c) ){
                    CustomOpportunity custOpportunity = (CustomOpportunity)System.JSON.deserialize(cifHisRec.Request_Payload__c, CustomOpportunity.class);
                    accountRec = custOpportunity.account;
                    if(String.IsNotBlank (custOpportunity.account.localAddressLine1)){
                        preLocalAccBillStreet =custOpportunity.account.localAddressLine1;
                    }
                    
                    if(String.IsNotBlank (custOpportunity.account.addressLine1)){
                        preAccBillStreet =custOpportunity.account.addressLine1;
                    }
                }                
            } 
        }
        
        if(cifHisRecordConList.size() > 0){
            for(CIFHistory__c cifHisRec: cifHisRecordConList){
                if( String.isNotBlank(cifHisRec.Request_Payload__c) ){
                    CustomOpportunity custOpportunity = (CustomOpportunity)System.JSON.deserialize(cifHisRec.Request_Payload__c, CustomOpportunity.class);
                    //  conRecList = new List<CustomContact>(custOpportunity.contacts);
                    for(CustomContact con :custOpportunity.contacts ){
                        if(con.contactType =='Primary Contact'){
                            conRec = con;
                        }
                    }
                }                
            } 
        }
        
        /*        if(cifHisRecord.size() >0){
List<CustomContact> conList = new List<CustomContact>();
for(CIFHistory__c cifHisRec: cifHisRecord){
if( String.isNotBlank(cifHisRec.Request_Payload__c) ){
CustomOpportunity custOpportunity = (CustomOpportunity)System.JSON.deserialize(cifHisRec.Request_Payload__c, CustomOpportunity.class);
//  conRecList = new List<CustomContact>(custOpportunity.contacts);
for(CustomContact con :custOpportunity.contacts ){
if(con.contactType =='Primary Contact'){
conRec = con;
}
}
accountRec = custOpportunity.account;
if(String.IsNotBlank (custOpportunity.account.localAddressLine1)){
preLocalAccBillStreet =custOpportunity.account.localAddressLine1;
}

if(String.IsNotBlank (custOpportunity.account.addressLine1)){
preAccBillStreet =custOpportunity.account.addressLine1;
}
}                
}                
}
*/  
    }
    //End
    
    //Sending the Opportunity,Contact and Account information to the Appian system  
    public void Send() {        
        missingFields = '';
        Opportunity opportunityStatusCheck = [SELECT Id, CIFStatus__c FROM Opportunity WHERE Id = :opportunity.Id FOR UPDATE];
        SystemSetting__c ss = bg_CustomSettingsUtils.GetSystemSettings();
        CustomOpportunity opp = customOpportunityJson('cifInitialRequest');
        if(String.isBlank(missingFields)){
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            /*String url = 'https://login.microsoftonline.com/54946ffc-68d3-4955-ac70-dca726d445b4/oauth2/v2.0/token';
request.setEndpoint(url);
request.setMethod('POST');
request.setBody('client_id=6eb44011-cf6a-4160-9e2b-1c3c78cf53d9' + 
'&client_secret=yNeHfaew38hE0plE~3u2-AFm4cIs0DK~.u' +
'&scope=api://6eb44011-cf6a-4160-9e2b-1c3c78cf53d9/.default' +
'&grant_type=client_credentials');
HttpResponse response = http.send(request);     
Token token = (Token)System.JSON.deserialize(response.getBody(), Token.class);*/
            
            request.setHeader('Appian-API-Key', ss.Appian_APIKey__c);
            request.setEndpoint(ss.Appian_URL__c);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setBody(System.JSON.serialize(opp));
            HttpResponse response = http.send(request);
            system.debug('Initial response-->'+response);
            System.debug('Initial Request-->'+System.JSON.serialize(opp));
            if(response.getStatusCode() == 409) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, system.label.Cif_Already_Submitted));
                submissionSuccess = false;
                return;
            } else if(response.getStatusCode() == 503  ) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, system.label.Cif_Service_Unavailable));
                submissionSuccess = false;
                return;
            } else if(response.getStatusCode() == 401  ) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, system.label.Cif_Authentication_failed));
                submissionSuccess = false;
                return;
            } else if(response.getStatusCode() != 201 && response.getStatusCode() != 200) {
                JsonResponse jResponse = (JsonResponse)JSON.deserialize(response.getBody(), JsonResponse.class);
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, jResponse.code+':' + jResponse.message));
                //  ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Your request could not be submitted. Try after sometime or contact your administrator.'));
                submissionSuccess = false;
                return;
            }
            
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Confirm, system.label.Cif_Submitted));
            opportunityStatusCheck.CIFStatus__c = 'Requested';
            update opportunityStatusCheck;
            
            cifHistotyCreate('Requested', opportunity.Id, opp);
            cifForm = false;
            backToOpp = true;
        }
    }
    
    //Cancel Button - return to original page (i.e Opportunity revcord)
    public PageReference Cancel() {
        PageReference pageRef = new PageReference('/' + Apexpages.currentpage().getParameters().get('id'));
        return pageRef;
    }
    
    public class ContactWrapper {
        public boolean selected {get; set;}     
        public Contact contact {get; set;}
        
        public ContactWrapper(Contact contact) {
            this.contact = contact;
            this.selected = false;
        }
    }
    
    public class CustomOpportunity {
        public String opportunityId {get; set;}
        public String opportunityNumber {get; set;}
        public String opportunityName {get; set;}
        public String opportunityOwnerUpn {get; set;}
        public String needByDate {get; set;}
        public String stage {get; set;}
        
        public CustomAccount account  {get; set;}
        public List<CustomContact> contacts {get; set;}
    }
    
    public class CustomAccount{
        public String accountId {get; set;}
        public String accountName {get; set;}
        public String addressLine1 {get; set;}
        public String billingCity {get; set;}
        public String billingState {get; set;}
        public String postalCode {get; set;}
        public String billingCountry {get; set;}
        public String billingCountryCode {get; set;}
        public String website {get; set;}
        public String localAccountName {get; set;}
        //  public String localBillingStreet {get; set;}
        public String billingStreet {get; set;}
        public String localCity {get; set;}
        public String localState {get; set;}
        public String localPostalCode {get; set;}
        public String localCountry {get; set;}
        //  public String addressLine2 {get; set;}
        //  public String addressLine3 {get; set;}
        public String localAddressLine1 {get; set;}
        //  public String localAddressLine2 {get; set;}
        //  public String localAddressLine3 {get; set;}
        
    }
    
    public class CustomContact{
        public String contactId {get; set;}
        public String firstName {get; set;}
        public String lastName {get; set;}
        public String phone {get; set;}
        public String mobilePhone {get; set;}
        public String email {get; set;}
        public String contactType {get; set;}
        public String localFirstName {get; set;}
        public String localLastName {get; set;}
    }
    
    public class Token {
        public String token_type {get; set;}
        public String expires_in {get; set;}
        public String access_token {get; set;}          
    }
    
    //Fecth the country full name based the countrycode
    public String getCountryFullName(String countryCode) {
        Map<String, String> countryMap = new Map<String, String>();
        countryMap.put('AF','Afghanistan');
        countryMap.put('AL','Albania');
        countryMap.put('DZ','Algeria');
        countryMap.put('AS','American Samoa');
        countryMap.put('AD','Andorra');
        countryMap.put('AO','Angola');
        countryMap.put('AI','Anguilla');
        countryMap.put('AQ','Antarctica');
        countryMap.put('AG','Antigua and Barbuda');
        countryMap.put('AR','Argentina');
        countryMap.put('AM','Armenia');
        countryMap.put('AW','Aruba');
        countryMap.put('AU','Australia');
        countryMap.put('AT','Austria');
        countryMap.put('AZ','Azerbaijan');
        countryMap.put('BS','Bahamas (the)');
        countryMap.put('BH','Bahrain');
        countryMap.put('BD','Bangladesh');
        countryMap.put('BB','Barbados');
        countryMap.put('BY','Belarus');
        countryMap.put('BE','Belgium');
        countryMap.put('BZ','Belize');
        countryMap.put('BJ','Benin');
        countryMap.put('BM','Bermuda');
        countryMap.put('BT','Bhutan');
        countryMap.put('BO','Bolivia (Plurinational State of)');
        countryMap.put('BQ','Bonaire, Sint Eustatius and Saba');
        countryMap.put('BA','Bosnia and Herzegovina');
        countryMap.put('BW','Botswana');
        countryMap.put('BV','Bouvet Island');
        countryMap.put('BR','Brazil');
        countryMap.put('IO','British Indian Ocean Territory (the)');
        countryMap.put('BN','Brunei Darussalam');
        countryMap.put('BG','Bulgaria');
        countryMap.put('BF','Burkina Faso');
        countryMap.put('BI','Burundi');
        countryMap.put('CV','Cabo Verde');
        countryMap.put('KH','Cambodia');
        countryMap.put('CM','Cameroon');
        countryMap.put('CA','Canada');
        countryMap.put('KY','Cayman Islands (the)');
        countryMap.put('CF','Central African Republic (the)');
        countryMap.put('TD','Chad');
        countryMap.put('CL','Chile');
        countryMap.put('CN','China');
        countryMap.put('CX','Christmas Island');
        countryMap.put('CC','Cocos (Keeling) Islands (the)');
        countryMap.put('CO','Colombia');
        countryMap.put('KM','Comoros (the)');
        countryMap.put('CD','Congo (the Democratic Republic of the)');
        countryMap.put('CG','Congo (the)');
        countryMap.put('CK','Cook Islands (the)');
        countryMap.put('CR','Costa Rica');
        countryMap.put('HR','Croatia');
        countryMap.put('CU','Cuba');
        countryMap.put('CW','Curaçao');
        countryMap.put('CY','Cyprus');
        countryMap.put('CZ','Czechia');
        countryMap.put('DK','Denmark');
        countryMap.put('DJ','Djibouti');
        countryMap.put('DM','Dominica');
        countryMap.put('DO','Dominican Republic (the)');
        countryMap.put('EC','Ecuador');
        countryMap.put('EG','Egypt');
        countryMap.put('SV','El Salvador');
        countryMap.put('GQ','Equatorial Guinea');
        countryMap.put('ER','Eritrea');
        countryMap.put('EE','Estonia');
        countryMap.put('SZ','Eswatini');
        countryMap.put('ET','Ethiopia');
        countryMap.put('FK','Falkland Islands (the) [Malvinas]');
        countryMap.put('FO','Faroe Islands (the)');
        countryMap.put('FJ','Fiji');
        countryMap.put('FI','Finland');
        countryMap.put('FR','France');
        countryMap.put('GF','French Guiana');
        countryMap.put('PF','French Polynesia');
        countryMap.put('TF','French Southern Territories (the)');
        countryMap.put('GA','Gabon');
        countryMap.put('GM','Gambia (the)');
        countryMap.put('GE','Georgia');
        countryMap.put('DE','Germany');
        countryMap.put('GH','Ghana');
        countryMap.put('GI','Gibraltar');
        countryMap.put('GR','Greece');
        countryMap.put('GL','Greenland');
        countryMap.put('GD','Grenada');
        countryMap.put('GP','Guadeloupe');
        countryMap.put('GU','Guam');
        countryMap.put('GT','Guatemala');
        countryMap.put('GG','Guernsey');
        countryMap.put('GN','Guinea');
        countryMap.put('GW','Guinea-Bissau');
        countryMap.put('GY','Guyana');
        countryMap.put('HT','Haiti');
        countryMap.put('HM','Heard Island and McDonald Islands');
        countryMap.put('VA','Holy See (the)');
        countryMap.put('HN','Honduras');
        countryMap.put('HK','Hong Kong');
        countryMap.put('HU','Hungary');
        countryMap.put('IS','Iceland');
        countryMap.put('IN','India');
        countryMap.put('ID','Indonesia');
        countryMap.put('IR','Iran (Islamic Republic of)');
        countryMap.put('IQ','Iraq');
        countryMap.put('IE','Ireland');
        countryMap.put('IM','Isle of Man');
        countryMap.put('IL','Israel');
        countryMap.put('IT','Italy');
        countryMap.put('JM','Jamaica');
        countryMap.put('JP','Japan');
        countryMap.put('JE','Jersey');
        countryMap.put('JO','Jordan');
        countryMap.put('KZ','Kazakhstan');
        countryMap.put('KE','Kenya');
        countryMap.put('KI','Kiribati');
        countryMap.put('KW','Kuwait');
        countryMap.put('KG','Kyrgyzstan');
        countryMap.put('LV','Latvia');
        countryMap.put('LB','Lebanon');
        countryMap.put('LS','Lesotho');
        countryMap.put('LR','Liberia');
        countryMap.put('LY','Libya');
        countryMap.put('LI','Liechtenstein');
        countryMap.put('LT','Lithuania');
        countryMap.put('LU','Luxembourg');
        countryMap.put('MO','Macao');
        countryMap.put('MG','Madagascar');
        countryMap.put('MW','Malawi');
        countryMap.put('MY','Malaysia');
        countryMap.put('MV','Maldives');
        countryMap.put('ML','Mali');
        countryMap.put('MT','Malta');
        countryMap.put('MH','Marshall Islands (the)');
        countryMap.put('MQ','Martinique');
        countryMap.put('MR','Mauritania');
        countryMap.put('MU','Mauritius');
        countryMap.put('YT','Mayotte');
        countryMap.put('MX','Mexico');
        countryMap.put('FM','Micronesia (Federated States of)');
        countryMap.put('MD','Moldova (the Republic of)');
        countryMap.put('MC','Monaco');
        countryMap.put('MN','Mongolia');
        countryMap.put('ME','Montenegro');
        countryMap.put('MS','Montserrat');
        countryMap.put('MA','Morocco');
        countryMap.put('MZ','Mozambique');
        countryMap.put('MM','Myanmar');
        countryMap.put('NA','Namibia');
        countryMap.put('NR','Nauru');
        countryMap.put('NP','Nepal');
        countryMap.put('NL','Netherlands (the)');
        countryMap.put('NC','New Caledonia');
        countryMap.put('NZ','New Zealand');
        countryMap.put('NI','Nicaragua');
        countryMap.put('NE','Niger (the)');
        countryMap.put('NG','Nigeria');
        countryMap.put('NU','Niue');
        countryMap.put('NF','Norfolk Island');
        countryMap.put('MP','Northern Mariana Islands (the)');
        countryMap.put('NO','Norway');
        countryMap.put('OM','Oman');
        countryMap.put('PK','Pakistan');
        countryMap.put('PW','Palau');
        countryMap.put('PS','Palestine, State of');
        countryMap.put('PA','Panama');
        countryMap.put('PG','Papua New Guinea');
        countryMap.put('PY','Paraguay');
        countryMap.put('PE','Peru');
        countryMap.put('PH','Philippines (the)');
        countryMap.put('PN','Pitcairn');
        countryMap.put('PL','Poland');
        countryMap.put('PT','Portugal');
        countryMap.put('PR','Puerto Rico');
        countryMap.put('QA','Qatar');
        countryMap.put('MK','Republic of North Macedonia');
        countryMap.put('RO','Romania');
        countryMap.put('RU','Russian Federation (the)');
        countryMap.put('RW','Rwanda');
        countryMap.put('RE','Réunion');
        countryMap.put('BL','Saint Barthélemy');
        countryMap.put('SH','Saint Helena, Ascension and Tristan da Cunha');
        countryMap.put('KN','Saint Kitts and Nevis');
        countryMap.put('LC','Saint Lucia');
        countryMap.put('MF','Saint Martin (French part)');
        countryMap.put('PM','Saint Pierre and Miquelon');
        countryMap.put('VC','Saint Vincent and the Grenadines');
        countryMap.put('WS','Samoa');
        countryMap.put('SM','San Marino');
        countryMap.put('ST','Sao Tome and Principe');
        countryMap.put('SA','Saudi Arabia');
        countryMap.put('SN','Senegal');
        countryMap.put('RS','Serbia');
        countryMap.put('SC','Seychelles');
        countryMap.put('SL','Sierra Leone');
        countryMap.put('SG','Singapore');
        countryMap.put('SX','Sint Maarten (Dutch part)');
        countryMap.put('SK','Slovakia');
        countryMap.put('SI','Slovenia');
        countryMap.put('SB','Solomon Islands');
        countryMap.put('SO','Somalia');
        countryMap.put('ZA','South Africa');
        countryMap.put('GS','South Georgia and the South Sandwich Islands');
        countryMap.put('SS','South Sudan');
        countryMap.put('ES','Spain');
        countryMap.put('LK','Sri Lanka');
        countryMap.put('SD','Sudan (the)');
        countryMap.put('SR','Suriname');
        countryMap.put('SJ','Svalbard and Jan Mayen');
        countryMap.put('SE','Sweden');
        countryMap.put('CH','Switzerland');
        countryMap.put('SY','Syrian Arab Republic');
        countryMap.put('TW','Taiwan (Province of China)');
        countryMap.put('TJ','Tajikistan');
        countryMap.put('TZ','Tanzania, United Republic of');
        countryMap.put('TH','Thailand');
        countryMap.put('TL','Timor-Leste');
        countryMap.put('TG','Togo');
        countryMap.put('TK','Tokelau');
        countryMap.put('TO','Tonga');
        countryMap.put('TT','Trinidad and Tobago');
        countryMap.put('TN','Tunisia');
        countryMap.put('TR','Turkey');
        countryMap.put('TM','Turkmenistan');
        countryMap.put('TC','Turks and Caicos Islands (the)');
        countryMap.put('TV','Tuvalu');
        countryMap.put('UG','Uganda');
        countryMap.put('UA','Ukraine');
        countryMap.put('AE','United Arab Emirates (the)');
        countryMap.put('GB','United Kingdom');
        countryMap.put('US','United States of America');
        countryMap.put('UY','Uruguay');
        countryMap.put('UZ','Uzbekistan');
        countryMap.put('VU','Vanuatu');
        countryMap.put('VE','Venezuela (Bolivarian Republic of)');
        countryMap.put('VN','Viet Nam');
        countryMap.put('VG','Virgin Islands (British)');
        countryMap.put('VI','Virgin Islands (U.S.)');
        countryMap.put('WF','Wallis and Futuna');
        countryMap.put('EH','Western Sahara');
        countryMap.put('YE','Yemen');
        countryMap.put('ZM','Zambia');
        countryMap.put('ZW','Zimbabwe');
        countryMap.put('AX','Åland Islands');
        countryMap.put('KR','South Korea');
        
        return countryMap.get(countryCode);
    }
    
    //Sending the contact information to update in Appian system 
    public void updateConButton(){
        missingFields = '';
        SystemSetting__c ss = bg_CustomSettingsUtils.GetSystemSettings();
        CustomOpportunity opp = customOpportunityJson('Contact');
        if(string.isBlank(missingFields)){
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            
            request.setHeader('Appian-API-Key', ss.Appian_APIKey__c);
            request.setEndpoint(ss.Appian_Contact_URL__c);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setBody(System.JSON.serialize(opp));
            HttpResponse response = http.send(request);
            
            System.debug('Request ConUpdate->'+System.JSON.serialize(opp));
            System.debug('response --> '+response);
            if(response.getStatusCode() == 200){
                backToOpp = true;
                updateForm = false;
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Confirm, system.label.Cif_Update_Submitted)); 
            } else if(response.getStatusCode() == 503  ) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, system.label.Cif_Service_Unavailable));
            } else if(response.getStatusCode() == 401  ) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, system.label.Cif_Authentication_failed));
            }else{
                JsonResponse jResponse = (JsonResponse)JSON.deserialize(response.getBody(), JsonResponse.class);
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, jResponse.code+':' + jResponse.message));
            }
            cifHistotyCreate('Contact Update', opportunity.Id, opp);   
        }
    }
    
    //Sending the Account information to update in Appian system
    public  void updateAccButton(){
        missingFields = '';
        CustomOpportunity opp = customOpportunityJson('Account');        
        SystemSetting__c ss = bg_CustomSettingsUtils.GetSystemSettings();
        if(string.isBlank(missingFields)){
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            
            request.setHeader('Appian-API-Key', ss.Appian_APIKey__c);
            request.setEndpoint(ss.Appian_Account_URL__c);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setBody(System.JSON.serialize(opp));
            HttpResponse response = http.send(request);
            
            System.debug('Request AccUpdate->'+System.JSON.serialize(opp));
            System.debug('response --> '+response);
            
            if(response.getStatusCode() == 200){
                backToOpp = true;
                updateForm = false;
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Confirm, 'Your request has been submitted.'));
            } else if(response.getStatusCode() == 503  ) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, system.label.Cif_Service_Unavailable));
            } else if(response.getStatusCode() == 401  ) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, system.label.Cif_Authentication_failed));
            }
            else{
                JsonResponse jResponse = (JsonResponse)JSON.deserialize(response.getBody(), JsonResponse.class);
                system.debug('Acc jResponse--> '+jResponse);
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, jResponse.code+':' + jResponse.message));
            }     
            cifHistotyCreate('Account Update', opportunity.Id, opp);
        }
    }
    
    //Creating the json structure
    public CustomOpportunity customOpportunityJson (String cifRequest){
        
        Opportunity opportunityStatusCheck = [SELECT Id, CIFStatus__c FROM Opportunity WHERE Id = :opportunity.Id FOR UPDATE];
        
        CustomOpportunity opp = new CustomOpportunity();
        opp.contacts = new List<CustomContact>();
        
        opp.opportunityId = opportunity.Id;
        opp.opportunityName = opportunity.Name;
        opp.opportunityNumber = opportunity.OpportunityID2__c;
        
        if(string.isBlank(opportunity.Owner.FederationIdentifier)){
            missingFields += 'opportunity.Owner.FederationIdentifier, ';        }
        opp.opportunityOwnerUpn = opportunity.Owner.FederationIdentifier;
        
        if(opportunity.DeliveryDateExpectations__c != null)
            opp.needByDate = opportunity.DeliveryDateExpectations__c.year() + '-' + opportunity.DeliveryDateExpectations__c.month() + '-' + 
            opportunity.DeliveryDateExpectations__c.day();        
        opp.stage = opportunity.StageName;
        
        //Account Details
        CustomAccount account = new CustomAccount();                
        account.accountId = opportunity.AccountId;
        account.accountName = opportunity.Account.Name;        
        account.addressLine1 = opportunity.Account.BillingStreet;
        /* 
List<String>myBillingStreet= new List<String>();
if(String.isNotBlank(opportunity.Account.BillingStreet )){
myBillingStreet = opportunity.Account.BillingStreet.split('\n',3);
integer count = myBillingStreet.size();
system.debug('count--'+count);
system.debug('myBillingStreet--'+myBillingStreet);
if (myBillingStreet.size() > 0){  account.addressLine1 = myBillingStreet[0];  
account.addressLine1 = account.addressLine1.replace('\r', ' ');
}        
if (myBillingStreet.size() > 1){  account.addressLine2 = myBillingStreet[1];   
account.addressLine2 = account.addressLine2.replace('\r', ' ');
}
if (myBillingStreet.size() > 2){  account.addressLine3 = myBillingStreet[2];  
account.addressLine3 = account.addressLine3.replace('\r', ' ');
} 

}
*/
        account.billingStreet  = opportunity.Account.BillingStreet;
        account.billingCity = opportunity.Account.BillingCity;
        account.billingState = opportunity.Account.BillingState;
        account.postalCode = opportunity.Account.BillingPostalCode; 
        account.billingCountry = getCountryFullName(opportunity.Account.BillingCountry);
        account.billingCountryCode = opportunity.Account.BillingCountry;
        account.website = opportunity.Account.Website;
        account.localAccountName = opportunity.Account.NameLocal;
        account.localAddressLine1 = opportunity.Account.Local_Street__c;
        /*   List<String>myLocalBillingStreet= new List<String>();

if(String.isNotBlank(opportunity.Account.Local_Street__c)){

myLocalBillingStreet = opportunity.Account.Local_Street__c.split('\n',3);
system.debug('local myLocalBillingStreet--'+myLocalBillingStreet);

integer countLocal = myLocalBillingStreet.size();

if (myLocalBillingStreet.size() > 0){ account.localAddressLine1 = myLocalBillingStreet[0];    
account.localAddressLine1 = account.localAddressLine1.replace('\r', ' ');
}        
if (myLocalBillingStreet.size() > 1){ account.localAddressLine2 = myLocalBillingStreet[1];    
account.localAddressLine2 = account.localAddressLine2.replace('\r', ' ');
}
if (myLocalBillingStreet.size() > 2){ account.localAddressLine3 = myLocalBillingStreet[2];    
account.localAddressLine3 = account.localAddressLine3.replace('\r', ' ');
}

}
*/
        account.localCity  = opportunity.Account.Local_City_c__c;
        account.localState = opportunity.Account.Local_State__c;
        account.localPostalCode = opportunity.Account.Local_Post_Code__c;
        account.localCountry = opportunity.Account.Local_Country__c;
        
        
        if(cifRequest == 'Account' || cifRequest == 'cifInitialRequest') { 
            
            if( String.isBlank(account.addressLine1)){
                missingFields += 'Billing Street, ';
            }
            if( String.isBlank(opportunity.Account.BillingCity)){
                missingFields += 'Billing City, ';
            }
            
            if((opportunity.Account.BillingCountry == 'CN' && string.isNotBlank(opportunity.Account.Local_Post_Code__c)) 
               || opportunity.Account.BillingCountry == 'GB'){
                   if(String.isBlank(opportunity.Account.BillingPostalCode)){
                       missingFields += 'Billing Zip/Postal Code, ';
                   }
               }
            if(opportunity.Account.BillingCountry == 'CN'){   
                
                if( String.isBlank(opportunity.Account.Local_City_c__c)){
                    missingFields += 'Local City, ';
                }
                
                if(String.isNotBlank(opportunity.Account.BillingState) && String.isBlank(opportunity.Account.Local_State__c)){
                    missingFields += 'Local State, ';
                }
                
                if(String.isNotBlank(opportunity.Account.BillingPostalCode) && String.isBlank(opportunity.Account.Local_Post_Code__c)){
                    missingFields += 'Local Postal Code, ';
                }
                if(String.isBlank(account.localAddressLine1)){
                    missingFields += 'Local Street, ';
                }
                /*
if(String.isNotBlank(account.addressLine2) && String.isBlank(account.localAddressLine2) && String.isNotBlank(account.localAddressLine1)){
missingFields += 'Local Street, ';
}
if(String.isNotBlank(account.addressLine3) && String.isBlank(account.localAddressLine3) && String.isNotBlank(account.localAddressLine2)){
missingFields += 'Local Street, ';
}
*/
                if( String.isBlank(opportunity.Account.NameLocal)){
                    missingFields += 'AccountName (Local), ';
                }
                if(String.isNotBlank(opportunity.Account.Local_State__c) && String.isBlank(opportunity.Account.BillingState)){
                    missingFields += 'Billing State, ';
                }
                /*                
if(String.isNotBlank(account.localAddressLine2) && String.isBlank(account.addressLine2) && String.isNotBlank(account.addressLine1)){
missingFields += 'Billing Street, ';
}
if(String.isNotBlank(account.localAddressLine3) && String.isBlank(account.addressLine3) && String.isNotBlank(account.addressLine2)){
missingFields += 'Billing Street, ';
}
*/
            }
        }
        //Contact Details
        CustomContact primaryContact = new CustomContact();
        if(cifRequest == 'Contact'|| cifRequest == 'cifInitialRequest'){
            if(String.isBlank(opportunity.PrimaryContact__c)){
                missingFields += 'Please add Primary Contact to an Opportunity, ';
            }
        }
        if(opportunity.PrimaryContact__c != null) {
            primaryContact.contactId = opportunity.PrimaryContact__c;
            primaryContact.firstName = opportunity.PrimaryContact__r.FirstName;
            primaryContact.lastName = opportunity.PrimaryContact__r.LastName;
            primaryContact.phone = opportunity.PrimaryContact__r.Phone;
            primaryContact.mobilePhone = opportunity.PrimaryContact__r.MobilePhone;
            primaryContact.email = opportunity.PrimaryContact__r.Email;
            primaryContact.contactType = 'Primary Contact';            
            primaryContact.localFirstName = opportunity.PrimaryContact__r.FirstNameLocal;
            primaryContact.localLastName = opportunity.PrimaryContact__r.LastNameLocal;  
            
            //Data Validation
            if(opportunity.Account.BillingCountry == 'CN' && (cifRequest == 'Contact' || cifRequest == 'cifInitialRequest') ){
                if(String.isBlank(opportunity.PrimaryContact__r.FirstNameLocal)){
                    missingFields += 'FirstName (Local), ';
                }
                if(String.isBlank(opportunity.PrimaryContact__r.LastNameLocal)){
                    missingFields += 'LasttName (Local), ';
                }
            }    
            if(cifRequest == 'Contact'|| cifRequest == 'cifInitialRequest'){
                if(String.isBlank(opportunity.PrimaryContact__r.FirstName)){
                    missingFields += 'First Name, ';
                }
            }
            
        }        
        opp.account = account;
        opp.contacts.add(primaryContact);
        
        // outof scope
        /*   
for(ContactWrapper con: contacts) {
if(con.selected) {
CustomContact secondaryContact = new CustomContact();
secondaryContact.contactId = con.Contact.Id;
secondaryContact.firstName = con.Contact.FirstName;
secondaryContact.lastName = con.Contact.LastName;
secondaryContact.phone = con.Contact.Phone;
secondaryContact.mobilePhone = con.Contact.MobilePhone;
secondaryContact.email = con.Contact.Email;
secondaryContact.contactType = 'Secondary Contact';
secondaryContact.localFirstName = con.Contact.FirstNameLocal;
secondaryContact.localLastName = con.Contact.LastNameLocal;
opp.contacts.add(secondaryContact);

if(opportunity.Account.BillingCountry == 'CN' && (cifRequest == 'Contact' || cifRequest == 'cifInitialRequest') ){
if(String.isBlank(con.Contact.FirstNameLocal)){
missingFields += 'SecondaryContact LocalFirstName, ';
}
if(String.isBlank(con.Contact.LastNameLocal)){
missingFields += 'SecondaryContact LocalLasttName, ';
}
}    
if(cifRequest == 'Contact'){
if(String.isBlank(con.Contact.FirstName)){
missingFields += 'SecondaryContact FirstName, ';
}
}
break;
}
}        

CustomContact consultant = new CustomContact();
if(opportunity.Consultant1__c != null) {
consultant.contactId = opportunity.Consultant1__c;
consultant.firstName = opportunity.Consultant1__r.FirstName;
consultant.lastName = opportunity.Consultant1__r.LastName;
consultant.phone = opportunity.Consultant1__r.Phone;
consultant.mobilePhone = opportunity.Consultant1__r.MobilePhone;
consultant.email = opportunity.Consultant1__r.Email;
consultant.contactType = 'Consultant';
consultant.localFirstName = opportunity.Consultant1__r.FirstNameLocal;
consultant.localLastName = opportunity.Consultant1__r.LastNameLocal;
opp.contacts.add(consultant);
if(opportunity.Account.BillingCountry == 'CN' && (cifRequest == 'Contact' || cifRequest == 'cifInitialRequest') ){
if(String.isBlank(opportunity.Consultant1__r.FirstNameLocal)){
missingFields += 'ConsultantContact LocalFirstName, ';
}
if(String.isBlank(opportunity.Consultant1__r.LastNameLocal)){
missingFields += 'ConsultantContact LocalLasttName, ';
}
}    
if(cifRequest == 'Contact'){
if(String.isBlank(opportunity.Consultant1__r.FirstName)){
missingFields += 'ConsultantContact FirstName, ';
}
}
}

*/
        if(!String.isBlank(missingFields)){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Please fill missing data :- '+ missingFields.Substring(0, missingFields.Length()-2) ));
        }
        return opp;  
        }   
    
    //After successfully hitting the Appian endpoint url, we are creating the CIF History record
    public void cifHistotyCreate(String status, ID oppID, CustomOpportunity opp){
        CIFHistory__c history = new CIFHistory__c();
        history.Status__c = status;
        history.SubmittedDate__c = DateTime.now();
        history.Opportunity__c = oppID;
        history.Request_Payload__c = JSON.serialize(opp);
        insert history;
        submissionSuccess = true;
    }
    
    public class JsonResponse {
        public string code;
        public String message;
    }
    
    public static CustomOpportunity parse(String json){
        return (CustomOpportunity) System.JSON.deserialize(json, CustomOpportunity.class);
    }
}