/**
 * @Name:        NetworkMemberSettingsController
 * @Description: To handle the front-end operations of UserSettingsController (Used without sharing due to updates to NetworkMember)
 *
 * @author:      Patrick Fischer
 * @version:     1.0
 * Change Log
 *
 * Date         author              Change Description
 * -----------------------------------------------------------------------------------
 * 18/12/2018   Patrick Fischer     Created Class
 */
public without sharing class NetworkMemberSettingsController {

    @AuraEnabled
    public static String getNetworkMember(Id userId, Id networkId) {

        List<NetworkMember> networkMembers = [ 
                SELECT Id, PreferencesDisableAllFeedsEmail, PreferencesDisableEndorsementEmail, PreferencesDisableProfilePostEmail,
                        PreferencesDisableFollowersEmail, PreferencesDisableLikeEmail, PreferencesDisableChangeCommentEmail,
                        PreferencesDisProfPostCommentEmail, PreferencesDisableLaterCommentEmail, PreferencesDisableBookmarkEmail,
                        PreferencesDisCommentAfterLikeEmail, PreferencesDisableMentionsPostEmail, PreferencesDisMentionsCommentEmail,
                        PreferencesDisableItemFlaggedEmail, PreferencesDisableDirectMessageEmail
                FROM NetworkMember
                WHERE MemberId = :userId AND NetworkId = :networkId
        ];
        if(networkMembers.isEmpty()) {
            return null;
        } else {
            return JSON.serializePretty(networkMembers[0], true);
        }
    }

    @AuraEnabled
    public static String setNetworkMember(String data) {

        try {
            NetworkMember networkMember = (NetworkMember) System.JSON.deserialize(data, NetworkMember.class);
            update networkMember;
        } catch (Exception e) {
            return 'An error occurred: ' + e.getMessage();
        }

        return Constants.BLANK_STRING;
    }

}