/**
*	Author		: Prasad JN
*	Description	: Mock service for D&B API Lookup
*/
@isTest
global class emq_DBLookupProviderMock implements WebServiceMock{
    global void doInvoke(
           Object stub,
           Object request,
           Map<String, Object> response,
           String endpoint,
           String soapAction,
           String requestName,
           String responseNS,
           String responseName,
           String responseType) {
          if (requestName == 'ws_LookUp') {
            emq_DBLookupProvider.ws_LookUpResponse resp = new emq_DBLookupProvider.ws_LookUpResponse();
            resp.lookUpResponse = new emq_DBLookupProvider.lookUpResponse();
            resp.lookUpResponse.DGX = new emq_DBLookupProvider.DGX();
            resp.lookUpResponse.DGX.SIGNONMSGSRSV1 = new emq_DBLookupProvider.SIGNONMSGSRSV1();
            resp.lookUpResponse.DGX.SIGNONMSGSRSV1.SONRS = new emq_DBLookupProvider.SONRS();
            resp.lookUpResponse.DGX.SIGNONMSGSRSV1.SONRS.STATUS = new emq_DBLookupProvider.STATUS();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2 = new emq_DBLookupProvider.CREDITMSGSRSV2();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS = new emq_DBLookupProvider.LOOKUPTRNRS();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.STATUS = new emq_DBLookupProvider.STATUS2();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.STATUS.CODE = '0';
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.LOOKUPRS = new emq_DBLookupProvider.LOOKUPRS();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.LOOKUPRS.LOOKUPDUPLICATETOWNRS = new emq_DBLookupProvider.ArrayOfLOOKUPDUPLICATETOWNRS();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.LOOKUPRS.LOOKUPDUPLICATETOWNRS.ArrayOfLOOKUPDUPLICATETOWNRSItem = new List<emq_DBLookupProvider.LOOKUPDUPLICATETOWNRS>();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.LOOKUPRS.LOOKUPDUPLICATETOWNRS.ArrayOfLOOKUPDUPLICATETOWNRSItem.add(new emq_DBLookupProvider.LOOKUPDUPLICATETOWNRS());
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.LOOKUPRS.LOOKUPRSCLOSETOWN = new emq_DBLookupProvider.ArrayOfLOOKUPRSCLOSETOWN();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.LOOKUPRS.LOOKUPRSCLOSETOWN.ArrayOfLOOKUPRSCLOSETOWNItem = new List<emq_DBLookupProvider.LOOKUPRSCLOSETOWN>();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.LOOKUPRS.LOOKUPRSCLOSETOWN.ArrayOfLOOKUPRSCLOSETOWNItem.add(new emq_DBLookupProvider.LOOKUPRSCLOSETOWN());
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.LOOKUPRS.LOOKUPRSCOMPANY = new emq_DBLookupProvider.ArrayOfLOOKUPRSCOMPANY();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.LOOKUPRS.LOOKUPRSCOMPANY.ArrayOfLOOKUPRSCOMPANYItem = new List<emq_DBLookupProvider.LOOKUPRSCOMPANY>();
            for (Integer i = 0; i < 2; i++) {
                emq_DBLookupProvider.LOOKUPRSCOMPANY lc = new emq_DBLookupProvider.LOOKUPRSCOMPANY();
                lc.NME = 'BSI Test Account' + i;
                lc.ADR_LINE = '389 Chiswick High Road';
                lc.DUNS_NBR = String.valueOf(i * 5414415);
                lc.NON_POST_TOWN = 'London';
                lc.POST_CODE = 'W4 4AL';
                lc.MTCH_BASS = new emq_DBLookupProvider.MTCH_BASS();
                lc.MTCH_BASS.MTCH_BASS_ENTR = new emq_DBLookupProvider.ArrayOfMTCH_BASS_ENTR();
                lc.MTCH_BASS.MTCH_BASS_ENTR.ArrayOfMTCH_BASS_ENTRItem = new List<emq_DBLookupProvider.MTCH_BASS_ENTR>();
                lc.MTCH_BASS.MTCH_BASS_ENTR.ArrayOfMTCH_BASS_ENTRItem.add(new emq_DBLookupProvider.MTCH_BASS_ENTR());        
                resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.LOOKUPRS.LOOKUPRSCOMPANY.ArrayOfLOOKUPRSCOMPANYItem.add(lc);
            }

            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.FRD_RISK_SCR = new emq_DBLookupProvider.FRD_RISK_SCR();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.FRD_RISK_SCR.STATUS = new emq_DBLookupProvider.STATUS3();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.FRD_RISK_SCR.FDSLOOKUPRS = new emq_DBLookupProvider.FDSLOOKUPRS();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.FRD_RISK_SCR.FDSLOOKUPRS.SCR_RSLT_INTERPRET = new emq_DBLookupProvider.SCR_RSLT_INTERPRET();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.FRD_RISK_SCR.FDSLOOKUPRS.SRCH_PFL_CHRT = new emq_DBLookupProvider.SRCH_PFL_CHRT();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.FRD_RISK_SCR.FDSLOOKUPRS.SRCH_PFL_CHRT.FINANCIAL_SVCS = new emq_DBLookupProvider.FINANCIAL_SVCS();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.FRD_RISK_SCR.FDSLOOKUPRS.SRCH_PFL_CHRT.SERVICES = new emq_DBLookupProvider.SERVICES();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.FRD_RISK_SCR.FDSLOOKUPRS.SRCH_PFL_CHRT.MFG_SVCS = new emq_DBLookupProvider.MFG_SVCS();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.FRD_RISK_SCR.FDSLOOKUPRS.SRCH_PFL_CHRT.WHOLESALE_SVCS = new emq_DBLookupProvider.WHOLESALE_SVCS();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.FRD_RISK_SCR.FDSLOOKUPRS.SRCH_PFL_CHRT.COMM_SVCS= new emq_DBLookupProvider.COMM_SVCS();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.FRD_RISK_SCR.FDSLOOKUPRS.SRCH_PFL_CHRT.TRANSPORT_SVCS = new emq_DBLookupProvider.TRANSPORT_SVCS();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.FRD_RISK_SCR.FDSLOOKUPRS.SRCH_PFL_CHRT.RETAIL_SVCS = new emq_DBLookupProvider.RETAIL_SVCS();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.FRD_RISK_SCR.FDSLOOKUPRS.SRCH_PFL_CHRT.UTILITY_SVCS = new emq_DBLookupProvider.UTILITY_SVCS();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.FRD_RISK_SCR.FDSLOOKUPRS.SRCH_PFL_CHRT.CONT_CNST_SVCS = new emq_DBLookupProvider.CONT_CNST_SVCS();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.FRD_RISK_SCR.FDSLOOKUPRS.SRCH_PFL_CHRT.PUB_SVCS = new emq_DBLookupProvider.PUB_SVCS();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.FRD_RISK_SCR.FDSLOOKUPRS.SRCH_PFL_CHRT.METAL_MINING_SVCS = new emq_DBLookupProvider.METAL_MINING_SVCS();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.FRD_RISK_SCR.FDSLOOKUPRS.SRCH_PFL_CHRT.AGRICULTURAL_SVCS = new emq_DBLookupProvider.AGRICULTURAL_SVCS();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.FRD_RISK_SCR.FDSLOOKUPRS.SRCH_PFL_CHRT.UCLS_SVCS = new emq_DBLookupProvider.UCLS_SVCS();                      
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.FRD_RISK_SCR.FDSLOOKUPRS.LAST_SRCHS = new emq_DBLookupProvider.LAST_SRCHS();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.FRD_RISK_SCR.FDSLOOKUPRS.LAST_SRCHS.LAST_1_SRCH = new emq_DBLookupProvider.LAST_1_SRCH();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.FRD_RISK_SCR.FDSLOOKUPRS.LAST_SRCHS.LAST_2_SRCH = new emq_DBLookupProvider.LAST_2_SRCH();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.FRD_RISK_SCR.FDSLOOKUPRS.LAST_SRCHS.LAST_3_SRCH = new emq_DBLookupProvider.LAST_3_SRCH();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.FRD_RISK_SCR.FDSLOOKUPRS.LAST_SRCHS.LAST_4_SRCH = new emq_DBLookupProvider.LAST_4_SRCH();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.FRD_RISK_SCR.FDSLOOKUPRS.LAST_SRCHS.LAST_5_SRCH = new emq_DBLookupProvider.LAST_5_SRCH();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.FRD_RISK_SCR.FDSLOOKUPRS.INFO_CONSISTENCY = new emq_DBLookupProvider.INFO_CONSISTENCY();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.FRD_RISK_SCR.FDSLOOKUPRS.INFO_CONSISTENCY.MOST_FREQ_1_TLCM_NBR = new emq_DBLookupProvider.MOST_FREQ_1_TLCM_NBR();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.FRD_RISK_SCR.FDSLOOKUPRS.INFO_CONSISTENCY.MOST_FREQ_2_TLCM_NBR = new emq_DBLookupProvider.MOST_FREQ_2_TLCM_NBR();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.FRD_RISK_SCR.FDSLOOKUPRS.INFO_CONSISTENCY.MOST_FREQ_3_TLCM_NBR = new emq_DBLookupProvider.MOST_FREQ_3_TLCM_NBR();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.FRD_RISK_SCR.FDSLOOKUPRS.INFO_CONSISTENCY.MOST_FREQ_4_TLCM_NBR = new emq_DBLookupProvider.MOST_FREQ_4_TLCM_NBR();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.FRD_RISK_SCR.FDSLOOKUPRS.INFO_CONSISTENCY.MOST_FREQ_5_TLCM_NBR = new emq_DBLookupProvider.MOST_FREQ_5_TLCM_NBR();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.FRD_RISK_SCR.FDSLOOKUPRS.INFO_CONSISTENCY.MOST_FREQ_1_DUNS = new emq_DBLookupProvider.MOST_FREQ_1_DUNS();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.FRD_RISK_SCR.FDSLOOKUPRS.INFO_CONSISTENCY.MOST_FREQ_2_DUNS = new emq_DBLookupProvider.MOST_FREQ_2_DUNS();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.FRD_RISK_SCR.FDSLOOKUPRS.INFO_CONSISTENCY.MOST_FREQ_3_DUNS = new emq_DBLookupProvider.MOST_FREQ_3_DUNS();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.FRD_RISK_SCR.FDSLOOKUPRS.INFO_CONSISTENCY.MOST_FREQ_4_DUNS = new emq_DBLookupProvider.MOST_FREQ_4_DUNS();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.FRD_RISK_SCR.FDSLOOKUPRS.INFO_CONSISTENCY.MOST_FREQ_5_DUNS = new emq_DBLookupProvider.MOST_FREQ_5_DUNS();
            resp.lookUpResponse.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.FRD_RISK_SCR.FDSLOOKUPRS.FR_IND = new emq_DBLookupProvider.FR_IND();

            response.put('response_x', resp);
        }
    }
}