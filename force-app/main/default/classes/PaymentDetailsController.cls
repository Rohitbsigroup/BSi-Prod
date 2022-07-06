/*
* Created By : PC K2 (August 2020)
* Controller class for Payment_Details component
* 
* changelog
* 20201110    JS    Updated the criteria to find the custom metadata to use for the component to use the translations ID to match rather than event country as this doesn't work for countries with multiple nodes.
* 20201111    JS    Added in further fields and training delegates method to allow controller to be used for BookingConfirmationPDF component which is used to show the PDF on email and in form   
*/

public class PaymentDetailsController {

        public Id tbId { get; set; }
    public Training_Booking_Country_Settings__mdt countrySetting { get; set; }
    

    public TrainingBooking__c booking { 
        get {
            if(booking == null){
                booking = [SELECT 
                            Name,
                            Bank_Name__c,
                            Bank_Account__c,                            
                            Billing_Name__c,
                            Billing_Notes__c,
                            Billing_Email_Address__c, 
                            Billing_Street__c,
                            Billing_City__c,
                            Billing_Country__c,
                            Billing_Phone__c,
                            Billing_Postcode__c,
                            Billing_Region__c,
                            Branch_Number__c,
                            Business_Style__c,
                            Company_Country_Code__c,
                            Company_Name__c,
                            Company_Street__c,
                            Company_City__c,
                            Contact_Phone__c,
                            Company_Postcode__c,
                            Company_Country__c,
                            Company_Region__c,
                            Contact_Mobile__c,
                            Codice_Fiscale__c,
                            CreatedDate,
                            Delegates_Inc_Accommodation__c,
                            Delegates_inc_extra_night__c,
                            Delegates_inc_exam__c,
                            Delegates_inc_standard__c,
                            Discount__c,
                            Email_Address__c,
                            First_Name__c,
                            Invoice_Category__c,
                            Invoice_Notes__c,
                            Last_Name__c,
                            Net_Price__c,
                            Number_of_Delegates__c,
                            Payment_Method__c, 
                            PO_Number__c,
                            Registered_Address_for_Invoice__c,
                            Registered_Phone_for_Invoice__c,
                            Tax__c,
                            Total_Price__c,
                            VAT_Number__c,
                            VAT_Number2__c,
                            Phone_Country_Code__c, //JE 25/01/2021
                            Mobile_Country_Code__c,
                            
                            Training_Event__r.Course__r.Training_Event_Residential__c,
                            Training_Event__r.Accommodation_available_for_this_event__c,
                            Training_Event__r.India_GST__c, 
                            Training_Event__r.Indian_Office_Address__c,
                            Training_Event__r.Indian_Office__c,
                            Training_Event__r.Event_Country__c, 
                            Training_Event__r.Course__r.Course_Format__c, 
                            
                            Training_Event__r.Training_Venue__r.Name,
                            Training_Event__r.Training_Venue__r.Venue_City__c,
                            
                            Training_Event__r.Start_date__c,
                            Training_Event__r.Trainer__c,
                            
                            Training_Event__r.Course__r.Product_Name_Local__c,
                            Training_Translations__r.Id, 
                            Training_Translations__r.Include_Exam_with_Course__c,
                            Training_Translations__r.X14_Cht_space__c,
                            Training_Translations__r.Start_Date__c,
                            Training_Translations__r.Date_Format__c,
                            Training_Translations__r.Currency_Format__c,
                            Training_Translations__r.Online_Booking_Received_Invoice__c,
                            Training_Translations__r.Online_Booking_Received_Paid_Card__c 
                      FROM TrainingBooking__c WHERE Id = :tbId];
            }
            if(countrySetting == null){
                // JS replaced with below countrySetting = [SELECT Calculate_Tax__c, Calculate_Tax_Method__c, Currency_Format__c FROM Training_Booking_Country_Settings__mdt WHERE DeveloperName = :booking.Training_Event__r.Event_Country__c];
                countrySetting = [SELECT Calculate_Tax__c, Flags__c, Calculate_Tax_Method__c, Currency_Format__c, Phone_Number__c, Tax_Name__c  FROM Training_Booking_Country_Settings__mdt WHERE Translations__c = :booking.Training_Translations__r.Id];
            }
            return booking;
        }
        set;
    }
     
     public List<TrainingDelegate__c> getDelegates() {
    
     List<TrainingDelegate__c> delegates 
                        = [SELECT 
                            d.Name,
                            d.First_Name__c,
                            d.Last_Name__c,
                            d.Email_Address__c,
                            d.Accommodation_Required__c,
                            d.Accommodation_night_before__c,
                            d.Online_Exam__c,
                            d.Standard__c,
                            d.Social_Security_Number__c
                      FROM TrainingDelegate__c d WHERE d.Training_Booking__c = :tbId];

        return delegates;
        }
    }