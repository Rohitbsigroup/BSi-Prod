@isTest
public  class TrainingBookingUtilitiesTest{
    
    public static testMethod void testEUCountries()
    {
       
       TrainingBookingController ctl = new TrainingBookingController();
       boolean isValidEUCountry = TrainingBookingUtilities.validateEUCountryCodes('CY');
       System.debug(isValidEUCountry);
       
    }
    public static testMethod void testErrorPage()
    {
       	Test.setCurrentPage(Page.TrainingBooking7);
       	ApexPages.currentPage().getParameters().put('L', 'EN');
        ApexPages.currentPage().getParameters().put('CT', 'GB');
        ApexPages.currentPage().getParameters().put('ID', null);
        
        TrainingBookingController ctl = new TrainingBookingController();
        boolean isValidEUCountry = TrainingBookingUtilities.validateEUCountryCodes('GB');
        System.debug(isValidEUCountry);
    }
        
}