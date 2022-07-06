public with sharing class RelatedDelegatesController {
    private static final String TRAINING_EVENT_STATUS_CANCELLED = 'Cancelled';
    private static Map<String,String> countryCodeToCountryName {
        get{
            if(countryCodeToCountryName == null){
                countryCodeToCountryName = new Map<String,String>();
                for(Country_Code__mdt countrySetting : Country_Code__mdt.getAll().values()){
                    countryCodeToCountryName.put(countrySetting.ISO_Alpha_2_Country_Code__c,countrySetting.Country_Name__c);
                }
            }
            return countryCodeToCountryName;
        }
        set { countryCodeToCountryName = value; }
    }

    public RelatedDelegatesController(){
    }

    @AuraEnabled
    public static String getChildEvents(String masterEventId){
        List<EventDTO> events = new List<EventDTO>();
        System.debug('##### results:' + [SELECT Id, Name, Country_Office_ISO_code__c,
                                                        China_Region__c, MEA_Region__c,
                                                        MY_Region__c, PH_Region__c
                                                FROM Training_Event__c 
                                                WHERE Master_Training_Event__c = :masterEventId
                                                AND Event_Status__c != :TRAINING_EVENT_STATUS_CANCELLED].size());
        for(Training_Event__c currentEvent : [SELECT Id, Name, Country_Office_ISO_code__c,
                                                        China_Region__c, MEA_Region__c,
                                                        MY_Region__c, PH_Region__c
                                                FROM Training_Event__c 
                                                WHERE Master_Training_Event__c = :masterEventId
                                                AND Event_Status__c != :TRAINING_EVENT_STATUS_CANCELLED]){
            events.add(new EventDTO(currentEvent));
        }
        return JSON.serialize(events);
    }

    public class EventDTO{
        @AuraEnabled public String Id {get;set;}
        @AuraEnabled public String Name {get;set;}
        @AuraEnabled public String Country_Office_ISO_code {get;set;}
        @AuraEnabled public String Region {get;set;}

        public EventDTO(Training_Event__c event){
            this.Id = event.Id;
            this.Name = event.Name;
            this.Country_Office_ISO_code = getCountryByISOCode(event.Country_Office_ISO_code__c);
            this.Region = getRegion(event);
        }

        private String getCountryByISOCode(String isoCode){
            return countryCodeToCountryName.containsKey(isoCode) ? 
                    countryCodeToCountryName.get(isoCode) : isoCode;
        }

        private String getRegion(Training_Event__c event){
            Map<String,String> isoCodeToRegionField = new Map<String,String>{ 
                'CN' => 'China_Region__c',
                'MY' => 'MY_Region__c',
                'PH' => 'PH_Region__c'
            };
            if(isoCodeToRegionField.containsKey(event.Country_Office_ISO_code__c)){
                return (String)event.get(isoCodeToRegionField.get(event.Country_Office_ISO_code__c));
            }else {
                return event.MEA_Region__c;
            }
        }
    }
}