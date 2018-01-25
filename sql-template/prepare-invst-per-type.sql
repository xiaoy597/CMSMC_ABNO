.WIDTH 256;
.LOGON $PARAM{'HOSTNM'}/$PARAM{'USERNM'},$PARAM{'PASSWD'};

DELETE FROM $PARAM{'CMSSDB'}.ABNO_INCM_CALC_INVST WHERE ABNO_INCM_CALC_BTCH = '$PARAM{'abno_incm_calc_btch'}';

-- 将用户指定的投资者三级分类代码插入ABNO_INCM_CALC_INVST表。
-- INSERT INTO $PARAM{'CMSSDB'}.ABNO_INCM_CALC_INVST (ABNO_INCM_CALC_BTCH, PRMT_TYPE, PRMT_VAL)
-- VALUES ('$PARAM{'abno_incm_calc_btch'}', '3', '$PARAM{'invst_cntnt'}');

-- 将用户指定的投资者三级分类对应的证券账号插入ABNO_INCM_CALC_INVST表。
INSERT INTO $PARAM{'CMSSDB'}.ABNO_INCM_CALC_INVST (ABNO_INCM_CALC_BTCH, PRMT_TYPE, PRMT_VAL)
SELECT DISTINCT '$PARAM{'abno_incm_calc_btch'}', '2', A.SEC_ACCT
FROM NsoVIEW.CSDC_INTG_SEC_ACCT A
LEFT JOIN NSPVIEW.ACT_STK_INVST_CLSF_HIS B
ON A.OAP_ACCT_NBR = B.OAP_ACCT_NBR
WHERE B.CLSF_3 in ($PARAM{'invst_cntnt_quot'})     --投资者三级分类 
AND A.OAP_ACCT_NBR IS NOT NULL
AND TRIM(A.OAP_ACCT_NBR) <> ''
AND A.E_DATE > CAST('$PARAM{'s_date'}' AS DATE FORMAT 'YYYYMMDD')
AND B.S_DATE <= CAST('$PARAM{'e_date'}' AS DATE FORMAT 'YYYYMMDD')
AND B.E_DATE > CAST('$PARAM{'e_date'}' AS DATE FORMAT 'YYYYMMDD')
;

.QUIT;

