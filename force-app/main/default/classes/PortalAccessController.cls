public with sharing class PortalAccessController {
    
    @AuraEnabled
    public static LoginResultDTO login(String username, String password){
        String url = '';
        PageReference siteReturn;
        try {
            siteReturn = Site.login(EncodingUtil.urlDecode(username, 'UTF-8'), 
                                    EncodingUtil.urlDecode(password, 'UTF-8'), '');
            url = (!Test.isRunningTest()) ? siteReturn.getUrl() : 'https://test.url.com';
        } catch (Exception e) {
            return new LoginResultDTO('',false,e.getMessage());
        }
        return new LoginResultDTO(url,true,'');
    }

    public class LoginResultDTO{
        @AuraEnabled public String returnUrl {get;set;}
        @AuraEnabled public Boolean isSuccess {get;set;}
        @AuraEnabled public String errorMessage {get;set;}

        public LoginResultDTO(String returnUrl,Boolean isSuccess, String errorMessage){
            this.returnUrl = returnUrl;
            this.isSuccess = isSuccess;
            this.errorMessage = errorMessage;
        }
    }
}