/********************************************************************
 * PcaDefaultCountrySettingController
 *
 * Controller to support PCA default country
 * 
 * Author: Richard Jimenez
 * Created: 29-01-2014
 * Changes: 
 ********************************************************************/
public class PcaDefaultCountrySettingController {

    private User currentUser;
    
    public PcaDefaultCountrySettingController() {
    	currentUser = bg_UserUtils.GetUserById(UserInfo.getUserId());
    }

    public string getDefaultCountry() {
        return currentUser.OperationCountry__c;
    }
    
    static testMethod void testController() {
        PcaDefaultCountrySettingController con = new PcaDefaultCountrySettingController();
        String testDefaultCountry = con.getDefaultCountry();
    }
}