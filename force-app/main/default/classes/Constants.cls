/**
 * @Name:        Constants
 * @Description: This is a helper class to hold all Constants of this Org
 *
 * @author:      Patrick Fischer
 * @version:     1.0
 * Change Log
 *
 * Date         author              Change Description
 * -----------------------------------------------------------------------------------
 * 27/11/2018   Patrick Fischer     Created Class
 */
public with sharing class Constants {

    /* STRING DEFAULT */
    public static final String BLANK_STRING = '';
    public static final String COMMA_STRING = ',';
    public static final String SINGLE_QUOTE_ESCAPED = '\'';
    public static final String SPACE_STRING = ' ';
    public static final String PERCENT_STRING = '%';
    public static final String DOUBLE_QUOTE_STRING = '\"';

    /* CONTACT CONSTANTS */
    public static final String CONTACT_ISF_STATUS_CURRENT = 'Current';
    public static final String CONTACT_MEMBERSHIP_TYPE_FULLM = 'Full Member';
    public static final String CONTACT_MEMBERSHIP_TYPE_SME = 'SME';
    public static final String CONTACT_MEMBER_ROLE_SECONDARY = 'Secondary';
    public static final String CONTACT_CHAPTER_GROUP_UK = 'United Kingdom';
    public static final String CONTACT_FUNCTIONAL_AREA_IT = 'IT';
    public static final String CONTACT_INDUSTRY_OTHER = 'Other';
    public static final String CONTACT_ROLE_LEVEL_OTHER = 'Other';
    public static final String CONTACT_LEAD_SOURCE_SELF_REG = 'Membership - ISF Live';

    /* COLLABORATION GROUP CONSTANTS */
    public static final String COLLAB_GROUP_TYPE_DEFAULT = 'DEFAULT';
    public static final String COLLAB_GROUP_TYPE_CHAPTER = 'Chapter_Value_Set';
    public static final String COLLAB_GROUP_TYPE_ALL = 'ALL';

    /* PERMISSION SET CONSTANTS */
    public static final String PERMISSION_SET_ISF_PRIMARY_SECONDARY = 'ISF_Live_Primary_Secondary';

    /* COMMUNITY CONSTANTS */
    public static final String COMMUNITY_ISF_LIVE_NAME = 'ISF Live';

    /* ERROR LOGS */
    public static final String CUSTOM_LOGS_RELATED_FEATURE_COMMUN_USER_CHATTER = 'Community User Chatter';
    public static final String CUSTOM_LOGS_RELATED_FEATURE_USER_CONTACT_SYNC = 'User Contact Sync';
    public static final String CUSTOM_LOGS_RELATED_FEATURE_MEMBER_MANAGEMENT = 'Member Management';
    public static final String CUSTOM_LOGS_RELATED_FEATURE_USER_REGISTRATION = 'User Registration';
    public static final String CUSTOM_LOGS_RELATED_FEATURE_CONNECT_API_POST = 'ConnectApi Post';
    public static final String CUSTOM_LOGS_TYPE_ERROR = 'Error';

    /* USER CREATION */
    public static final String LICENSE_CUSTOMER_COMMUNITY_LOGIN = 'Customer Community Login';
    public static final String USER_PROFILE_BENCHMARK_ONLY = 'Benchmark only';
    public static final String USER_DEFAULT_EMAIL_ENCODING_KEY = 'UTF-8';
    public static final String USER_DEFAULT_LANGUAGE_LOCAL_KEY = 'en_US';
    public static final String USER_DEFAULT_LOCALE_SID_KEY = 'en_GB';
    public static final String USER_DEFAULT_TIME_ZONE_SID_KEY = 'Europe/London';

    /* CUSTOM METADATA */
    public static final String METADATA_CHAPTER_VALUE_SET = 'Chapter_Value_Set';

    /* DYNAMIC SOQL SUPPORT */
    public static final String QUERY_SELECT = 'SELECT ';
    public static final String QUERY_FROM = ' FROM ';
    public static final String QUERY_WHERE = ' WHERE ';
    public static final String QUERY_AND = ' AND ';
    public static final String QUERY_LIKE = ' LIKE ';
    public static final String QUERY_ORDER_BY = ' ORDER BY ';
    public static final String QUERY_LIMIT = ' LIMIT ';
    public static final String QUERY_OFFSET = ' OFFSET ';

    /* Lightning Data Table */
    public static final Map<String, String> DATA_TABLE_DATETIME_FORMAT = new Map<String, String> {
            'day' => 'numeric',
            'month' => 'short',
            'year' => 'numeric',
            'hour' => '2-digit',
            'minute' => '2-digit',
            'second' => '2-digit'
    };
}