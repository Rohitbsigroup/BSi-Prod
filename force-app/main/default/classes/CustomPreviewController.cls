/**
 * @Name:        CustomPreviewController
 * @Description: Class to handle the records of Material_List__c object
 *
 * @author:      Andrei Budescu
 * @version:     1.0
 * Change Log
 *
 * Date         author              Change Description
 * -----------------------------------------------------------------------------------
 * 20/04/2020   Andrei Budescu     Created Class
 */

public without sharing class CustomPreviewController {

    //extensions for files
    public static final Set<String> DOC_TYPE_IMAGE = new Set<String> {
        'png', 'gif', 'jpg', 'jpeg', 'tiff', 'bmp'
        };
    public static final Set<String> DOC_TYPE_EXCEL = new Set<String> {
        'xls','xlsx'
        };
    public static final Set<String> DOC_TYPE_WORD = new Set<String> {
        'doc','docx'
        };
    public static final Set<String> DOC_TYPE_CSV = new Set<String> {
        'csv'
        };
    public static final Set<String> DOC_TYPE_TXT = new Set<String> {
        'txt'
        };
    public static final Set<String> DOC_TYPE_PDF = new Set<String> {
        'pdf'
        };
    public static final Set<String> DOC_TYPE_XML = new Set<String> {
        'xml'
        };
    public static final Set<String> DOC_TYPE_ZIP = new Set<String> {
        'zip'
        };
    public static final Set<String> DOC_TYPE_POWER_POINT = new Set<String> {
        'ppt','pptx'
        };


    //wrapper class for the elements of the list of materials
    public class Material{
        String materialId;
        String name;
        Decimal order;
        String type;
        String topic;
        String recordTypeName;
        String content;
        String videoUrl;
        String fileId;
        Boolean isDownloadable;
        String fileExtension;

        public Material(String materialId, String name, Decimal order, String type, String topic, String recordTypeName, String content, String videoUrl, String fileId, Boolean isDownloadable, String fileExtension){
            this.materialId = materialId;
            this.name = name;
            this.order = order;
            this.type = type;
            this.topic = topic;
            this.recordTypeName = recordTypeName;
            this.content = content;
            this.videoUrl = videoUrl;
            this.fileId = fileId;
            this.isDownloadable = isDownloadable;
            this.fileExtension = fileExtension;
        }
    }

    /**
	 * Get List of Material for Pre-Course Learning and Extra Resources
	 *
	 * @param recordId Record id of the enrollment accessed
     * @param tileClicked Name of the tile clicked(Pre-Course Learning or Extra Resources)
 	 *
	 * @return String with list of materials available
	 */
    @AuraEnabled
    public static String getMaterialList(String recordId, String tileClicked){

        List<Material> materialList = new List<Material>();
        
        Enrollment__c enrollment = [SELECT Id, Training_Event__r.Course__c FROM Enrollment__c WHERE Id =:recordId];
        Product2 product = [SELECT Id, 
                                    (SELECT ID, Name, Content__c, Type__c, Topic__c, Video_URL__c, Order__c, RecordType.Name 
                                        FROM Material_Lists__r 
                                        WHERE Type__c = :tileClicked 
                                        AND Status__c != 'Archived'
                                        ORDER BY Order__c) 
                                FROM Product2 
                                WHERE ID =:enrollment.Training_Event__r.Course__c];
        Set<Id> materialFileIds = new Set<Id>();

        for(Material_List__c material : product.Material_Lists__r){
            if(material.RecordType.Name == 'File'){
                Material materialItem = new Material(material.Id, material.Name, material.Order__c, material.Type__c, material.Topic__c, material.RecordType.Name, null, null, null, null, null);
                materialList.add(materialItem);
                materialFileIds.add(material.Id);
            } else{
                Material materialItem = new Material(material.Id, material.Name, material.Order__c, material.Type__c, material.Topic__c, material.RecordType.Name, material.Content__c, material.Video_URL__c, null, null, null); 
                materialList.add(materialItem);
            }
        }

        //related record type to get content version of the file
        List<FeedItem> itemsFiles = [SELECT Id, RelatedRecordId, Title, ParentId FROM FeedItem WHERE ParentId IN :materialFileIds];

        //set Id of files
        Set<ID> itemsFilesIds = new Set<Id>();
        for(FeedItem item : itemsFiles){
            itemsFilesIds.add(item.RelatedRecordId);
        }
        List<ContentVersion> filesContentVersion = [SELECT Id, ContentDocumentId, FileExtension FROM ContentVersion WHERE Id IN :itemsFilesIds];
 
        for(FeedItem item : itemsFiles){
            for(Material m : materialList){
                if(m.materialId == item.ParentId){
                    for(ContentVersion content : filesContentVersion){
                        if(item.RelatedRecordId == content.Id){
                            m.fileId = content.ContentDocumentId;
                            //m.fileExtension = content.FileExtension;
                            if(DOC_TYPE_IMAGE.contains(content.FileExtension)){
                                m.isDownloadable = true;
                                m.fileId = getUrlDownload(content.ContentDocumentId);
                               
                            }else{
                                m.isDownloadable = false;
                            }
                            //extension name used for the icon on the component
                            m.fileExtension = getIconName(content.fileExtension);
                        }
                    }
                }
            }
        }
        System.debug(materialList);
        System.debug('Site url: ' + Site.getBaseUrl());

        return JSON.serialize(materialList);
    }

    /**
	 * Create an url to download directly the images added as a material on the material list
	 *
	 * @param fileId Record id of the file(image) added
 	 *
	 * @return String with the download url for the image
	 */
    private static String getUrlDownload(String fileId){
        System.debug(Site.getBaseUrl());
        String downloadUrl = Site.getBaseUrl() + '/sfc/servlet.shepherd/document/download/' + fileId;

        return downloadUrl;
    }

    /**
	 * Returns name of the lightning icon depending on the extension of the file added
	 *
	 * @param fileExtension Name of the extension of the file added
 	 *
	 * @return String with name of the lightning icon to be shown on the material list
	 */
    private static String getIconName(String fileExtension){
        String iconName = 'attachment';
        if(DOC_TYPE_IMAGE.contains(fileExtension)){
            iconName = 'image';
        }else if(DOC_TYPE_EXCEL.contains(fileExtension)){
            iconName = 'excel';
        }else if(DOC_TYPE_WORD.contains(fileExtension)){
            iconName = 'word';
        }else if(DOC_TYPE_CSV.contains(fileExtension)){
            iconName = 'csv';
        }else if(DOC_TYPE_TXT.contains(fileExtension)){
            iconName = 'txt';
        }else if(DOC_TYPE_PDF.contains(fileExtension)){
            iconName = 'pdf';
        }else if(DOC_TYPE_XML.contains(fileExtension)){
            iconName = 'xml';
        }else if(DOC_TYPE_ZIP.contains(fileExtension)){
            iconName = 'zip';
        }else if(DOC_TYPE_POWER_POINT.contains(fileExtension)){
            iconName = 'ppt';
        }

        return 'doctype:' + iconName;
    }

}