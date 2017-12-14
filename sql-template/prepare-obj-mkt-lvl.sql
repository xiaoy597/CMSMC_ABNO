.WIDTH 256;
.LOGON $PARAM{'HOSTNM'}/$PARAM{'USERNM'},$PARAM{'PASSWD'};

INSERT INTO $PARAM{'CMSSDB'}.ABNO_INCM_CALC_OBJ (ABNO_INCM_CALC_BTCH, SEC_CDE)
SELECT '$PARAM{'abno_incm_calc_btch'}', SEC_CDE
FROM	NSOVIEW.CSDC_INTG_SEC_INFO
WHERE S_DATE <= CAST('$PARAM{'s_date'}' AS DATE FORMAT 'YYYYMMDD')
AND	E_DATE > CAST('$PARAM{'e_date'}' AS DATE FORMAT 'YYYYMMDD')
AND	MKT_LVL_SORT = '$PARAM{'obj_cntnt'}'        --1：主板，2：中小板，3：创业板
AND	SEC_REG_STS_SORT NOT IN ('2','5')			--证券登记状态类别 2：退市、5：废弃
AND MKT_SORT IN ($PARAM{'sec_exch_cde_quot'})
;

.QUIT;
