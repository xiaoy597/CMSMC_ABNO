.WIDTH 256;
.LOGON $PARAM{'HOSTNM'}/$PARAM{'USERNM'},$PARAM{'PASSWD'};

CREATE VOLATILE MULTISET TABLE VT_ABNO_SEC AS(
	SELECT A.SEC_CDE
	FROM $PARAM{'CMSSDB'}.ABNO_INCM_CALC_OBJ A
	WHERE A.ABNO_INCM_CALC_BTCH = '$PARAM{'abno_incm_calc_btch'}'
) WITH DATA UNIQUE PRIMARY INDEX (SEC_CDE)
ON COMMIT PRESERVE ROWS;

.IF ERRORCODE <> 0 THEN .QUIT 12;

COLLECT STATISTICS COLUMN SEC_CDE ON VT_ABNO_SEC;

CREATE VOLATILE MULTISET TABLE VT_ABNO_SSE_SEC AS(
	SELECT DISTINCT A.SEC_CDE
	FROM $PARAM{'CMSSDB'}.ABNO_INCM_CALC_OBJ A, NSOVIEW.CSDC_INTG_SEC_INFO B
	WHERE A.ABNO_INCM_CALC_BTCH = '$PARAM{'abno_incm_calc_btch'}'
	AND A.SEC_CDE = B.SEC_CDE
	AND B.E_DATE > CAST('$PARAM{'s_date'}' AS DATE FORMAT 'YYYYMMDD')
	AND B.MKT_SORT = '0'
) WITH DATA UNIQUE PRIMARY INDEX (SEC_CDE)
ON COMMIT PRESERVE ROWS;

.IF ERRORCODE <> 0 THEN .QUIT 12;

COLLECT STATISTICS COLUMN SEC_CDE ON VT_ABNO_SSE_SEC;

CREATE VOLATILE MULTISET TABLE VT_ABNO_SZSE_SEC AS(
	SELECT DISTINCT A.SEC_CDE
	FROM $PARAM{'CMSSDB'}.ABNO_INCM_CALC_OBJ A, NSOVIEW.CSDC_INTG_SEC_INFO B
	WHERE A.ABNO_INCM_CALC_BTCH = '$PARAM{'abno_incm_calc_btch'}'
	AND A.SEC_CDE = B.SEC_CDE
	AND B.E_DATE > CAST('$PARAM{'s_date'}' AS DATE FORMAT 'YYYYMMDD')
	AND B.MKT_SORT = '1'
) WITH DATA UNIQUE PRIMARY INDEX (SEC_CDE)
ON COMMIT PRESERVE ROWS;

.IF ERRORCODE <> 0 THEN .QUIT 12;

COLLECT STATISTICS COLUMN SEC_CDE ON VT_ABNO_SZSE_SEC;

.IF ERRORCODE <> 0 THEN .QUIT 12;

CREATE VOLATILE MULTISET TABLE VT_ABNO_SEC_ACCT AS (
    SELECT PRMT_VAL AS SEC_ACCT 
    FROM $PARAM{'CMSSDB'}.ABNO_INCM_CALC_INVST
    WHERE ABNO_INCM_CALC_BTCH = '$PARAM{'abno_incm_calc_btch'}' AND PRMT_TYPE = '2'
) WITH DATA UNIQUE PRIMARY INDEX (SEC_ACCT)
ON COMMIT PRESERVE ROWS;

.IF ERRORCODE <> 0 THEN .QUIT 12;

COLLECT STATISTICS COLUMN SEC_ACCT ON VT_ABNO_SEC_ACCT;

.IF ERRORCODE <> 0 THEN .QUIT 12;

DELETE FROM $PARAM{'CMSSDB'}.ABNO_INCM_CALC_RESULT 
WHERE ABNO_INCM_CALC_BTCH = '$PARAM{'abno_incm_calc_btch'}'
;

CREATE VOLATILE MULTISET TABLE VT_SEC_ACCT_QUOT AS (
SELECT 
T1.SEC_CDE
,T1.SEC_ACCT
,T2.CALC_S_DATE
,T2.CALC_S_PRC
,T2.CALC_E_DATE
,T2.CALC_E_PRC
FROM
(
	SELECT
		SEC_EXCH_CDE
		,SEC_CDE
		,SEC_ACCT
	FROM $PARAM{'CMSSDB'}.MID_ABNO_INCM_CACL_DTL
	WHERE ABNO_INCM_CALC_BTCH = '$PARAM{'abno_incm_calc_btch'}'
	GROUP BY SEC_EXCH_CDE, SEC_CDE, SEC_ACCT
) T1, 
(
	SELECT 
		TT1.SEC_EXCH_CDE,
		TT1.SEC_CDE, 
		TT1.CALC_S_DATE, 
		TT2.CLS_PRC AS CALC_S_PRC,
		TT1.CALC_E_DATE, 
		TT3.CLS_PRC AS CALC_E_PRC
	FROM
	(
		SELECT SEC_EXCH_CDE,
		SEC_CDE,
		MIN(TRAD_DATE) AS CALC_S_DATE,
		MAX(TRAD_DATE) AS CALC_E_DATE
		FROM $PARAM{'CMSSVIEW'}.SEC_QUOT
		WHERE TRAD_DATE >= CAST('$PARAM{'s_date'}' AS DATE FORMAT 'YYYYMMDD')
		AND TRAD_DATE <= CAST('$PARAM{'e_date'}' AS DATE FORMAT 'YYYYMMDD')
		GROUP BY SEC_EXCH_CDE, SEC_CDE
	) TT1, $PARAM{'CMSSVIEW'}.SEC_QUOT TT2, $PARAM{'CMSSVIEW'}.SEC_QUOT TT3
	WHERE TT1.SEC_CDE = TT2.SEC_CDE
	AND TT1.SEC_CDE = TT3.SEC_CDE
	AND TT1.CALC_S_DATE = TT2.TRAD_DATE
	AND TT1.CALC_E_DATE = TT3.TRAD_DATE
	AND TT1.SEC_EXCH_CDE = TT2.SEC_EXCH_CDE
	AND TT1.SEC_EXCH_CDE = TT3.SEC_EXCH_CDE
) T2
WHERE
T1.SEC_CDE = T2.SEC_CDE
AND T1.SEC_EXCH_CDE = T2.SEC_EXCH_CDE
) WITH DATA UNIQUE PRIMARY INDEX (SEC_CDE, SEC_ACCT)
ON COMMIT PRESERVE ROWS
;


INSERT INTO $PARAM{'CMSSDB'}.ABNO_INCM_CALC_RESULT
SELECT
TB1.SEC_EXCH_CDE AS SEC_EXCH_CDE
,TB1.SEC_ACCT AS SEC_ACCT
,TB1.SEC_CDE AS SEC_CDE
,TB2.OAP_ACCT_NBR AS OAP_ACCT_NBR
,TB2.SEC_ACCT_NAME AS ACCT_NAME
,COALESCE(TB3.CLSF_2, '') AS CLSF_2
,COALESCE(TB3.CLSF_3, '') AS CLSF_3
,CASE WHEN TB5.OAP_ACCT_NBR IS NOT NULL THEN '1' ELSE '0' END AS IS_ODS
,CASE WHEN TB7.OAP_ACCT_NBR IS NOT NULL THEN '1' ELSE '0' END AS IS_TOP10_SHDR
,CASE WHEN TB6.SHDR_ACCT IS NOT NULL THEN '1' ELSE '0' END AS IS_LIFT_BAN_LMT_SHDR
,COALESCE(TB41.START_BAL, 0) AS START_HLD_MKT_VAL
,COALESCE(TB42.END_BAL, 0) AS END_HLD_MKT_VAL
,SUM(BUY_AMT) AS BUY_AMT
,SUM(SAL_AMT) AS SAL_AMT
,SUM(CASE WHEN BIZ_TYPE = '2000' THEN SAL_AMT ELSE 0 END) AS NON_TRAD_TRAN_INCM_AMT
,SUM(CASE WHEN BIZ_TYPE = '2000' THEN BUY_AMT ELSE 0 END) AS NON_TRAD_TRAN_EXPDT_AMT
,SUM(CASE WHEN BIZ_TYPE = '9999' THEN BUY_AMT+SAL_AMT ELSE 0 END)AS SPRD_STOCK_ESTMT_AMT
,SUM(CASE WHEN BIZ_TYPE = '4004' THEN SAL_AMT ELSE 0 END) AS CASH_DVD
,SUM(TAX_FEE) AS TAX_FEE
,SUM((BUY_AMT+SAL_AMT) * TB8.CMSN_ABTM) AS CMSN
,SUM(SAL_AMT-BUY_AMT)
	+ (COALESCE(TB42.END_BAL, 0) - COALESCE(TB41.START_BAL, 0))
	- SUM(TAX_FEE) - SUM((BUY_AMT+SAL_AMT) * TB8.CMSN_ABTM) AS BRKV_AMT
,TB8.ABNO_INCM_CALC_BTCH AS ABNO_INCM_CALC_BTCH
FROM
(
    select * from $PARAM{'CMSSDB'}.MID_ABNO_INCM_CACL_DTL
    where ABNO_INCM_CALC_BTCH = '$PARAM{'abno_incm_calc_btch'}'
) tb1
inner join $PARAM{'CMSSDB'}.ABNO_INCM_CALC_LOG tb8
on tb1.ABNO_INCM_CALC_BTCH = tb8.ABNO_INCM_CALC_BTCH
inner join 
(
    select a.oap_acct_nbr, a.sec_acct, a.sec_acct_name 
	from NsoVIEW.CSDC_INTG_SEC_ACCT a,
		(select sec_acct, max(s_date) as s_date
			from NsoVIEW.CSDC_INTG_SEC_ACCT
			where e_date > CAST('$PARAM{'s_date'}' AS DATE FORMAT 'YYYYMMDD')
			group by sec_acct
		) b
    where 
    a.e_date > CAST('$PARAM{'s_date'}' AS DATE FORMAT 'YYYYMMDD')
	and a.s_date = b.s_date
	and a.sec_acct = b.sec_acct
) tb2
on tb1.sec_acct = tb2.sec_acct
left outer join 
(
    select * from nspview.ACT_STK_INVST_CLSF_HIS
    where s_date <= CAST('$PARAM{'e_date'}' AS DATE FORMAT 'YYYYMMDD') 
    and e_date > CAST('$PARAM{'e_date'}' AS DATE FORMAT 'YYYYMMDD') 
) tb3
on tb1.sec_acct = tb3.SEC_ACCT_NBR
left outer join
( -- 期初市值
	select t1.sec_cde, t1.sec_acct, sum(t1.calc_s_prc * t3.TD_END_HOLD_VOL) as start_bal
	from VT_SEC_ACCT_QUOT t1, NSPVIEW.ACT_SEC_HOLD_HIS T3
	WHERE T1.SEC_CDE = T3.SEC_CDE
	AND T1.SEC_ACCT = T3.SEC_ACCT_NBR
	AND T3.S_DATE <= T1.CALC_S_DATE
	AND T3.E_DATE > T1.CALC_S_DATE
	group  by 1,2
) tb41
on tb1.sec_acct = tb41.sec_acct
and tb1.sec_cde = tb41.sec_cde
left outer join
( -- 期末市值
	select t1.sec_cde, t1.sec_acct, sum(t1.calc_e_prc * t4.TD_END_HOLD_VOL) as end_bal
	from VT_SEC_ACCT_QUOT t1, NSPVIEW.ACT_SEC_HOLD_HIS T4
	WHERE T1.SEC_CDE = T4.SEC_CDE
	AND T1.SEC_ACCT = T4.SEC_ACCT_NBR
	AND T4.S_DATE <= T1.CALC_E_DATE
	AND T4.E_DATE > T1.CALC_E_DATE
	group  by 1,2
) tb42
on tb1.sec_acct = tb42.sec_acct
and tb1.sec_cde = tb42.sec_cde
left outer join
(
      ----高管名单（估算）--------------------------------------------------------------------  
         SELECT
            k2.OAP_ACCT_NBR
            ,CAST(SEC_CDE AS  CHAR(6)) AS SEC_CDE
            ,k2.MKT_SORT
        FROM
            NSoVIEW.CSDC_H_DSE_TRAD_LMT_CNDT k1
            INNER JOIN
            NsoVIEW.CSDC_INTG_SEC_ACCT k2
            ON k1.SHDR_ACCT = k2.SEC_ACCT AND k2.MKT_SORT = '0'
        WHERE
            k2.S_DATE <= CAST('$PARAM{'e_date'}' AS DATE FORMAT 'YYYYMMDD')  
            AND k2.E_DATE > CAST('$PARAM{'e_date'}' AS DATE FORMAT 'YYYYMMDD') 
        GROUP BY 1,2,3
        UNION ALL
        SELECT
            k2.OAP_ACCT_NBR
            ,k1.COMP_CDE AS SEC_CDE
            ,k2.MKT_SORT
        FROM
            (SELECT CERT_NBR,COMP_CDE FROM NsoVIEW.SZSE_LC_EXCUT_INFO 
             WHERE
                LENGTH(CERT_NBR)>=6
             GROUP BY 1,2
            ) k1
            INNER JOIN
            NsoVIEW.CSDC_INTG_SEC_ACCT k2
            ON k1.CERT_NBR = k2.CERT_NBR  AND k2.MKT_SORT = '1'
        WHERE
            k2.S_DATE <= CAST('$PARAM{'e_date'}' AS DATE FORMAT 'YYYYMMDD')  
            AND k2.E_DATE >  CAST('$PARAM{'e_date'}' AS DATE FORMAT 'YYYYMMDD') 
           AND k2.MKT_SORT='1' AND k2.SEC_ACCT_SORT = '1'
        GROUP BY 1,2,3
) tb5
on tb1.sec_cde = tb5.sec_cde
and tb2.oap_acct_nbr = tb5.oap_acct_nbr
left outer join
(
     ----限售股股东（估算）--------------------------------------------------------------------  
    select shdr_acct, sec_cde
    from
    (
     SELECT 
         k1.SHDR_ACCT
        ,substr(CAST(1000000+k1.SEC_CDE AS CHAR(7)),2,6) as sec_cde
        ,k2.MKT_SORT
        -- ,CAST(k1.TRAD_DATE AS FORMAT 'yyyymmdd')                                AS RELEASE_DATE ---- 解禁日期
        -- ,CASE 
        --     WHEN k1.CAP_TYPE='XL' AND (k1.NEGT_TYPE = 'A' OR k1.NEGT_TYPE = 'B')    THEN 'SF'
        --     WHEN k1.CAP_TYPE='XL' AND  k1.NEGT_TYPE = 'F'                           THEN 'ZF'
        --     ELSE 'OTH'
        -- END AS CAP_TYPE        
        -- ,SUM(k1.TRANS_VOL)                                                      AS RELEASE_VOL  ---- 解禁数量
    FROM
        NsoVIEW.CSDC_H_SEC_TRAN k1
        INNER JOIN
        (SELECT a.SEC_CDE,MKT_SORT FROM NsoVIEW.CSDC_INTG_SEC_INFO a, VT_ABNO_SSE_SEC b
         WHERE
           S_DATE <= CAST('$PARAM{'e_date'}' AS DATE FORMAT 'YYYYMMDD') 
           AND E_DATE > CAST('$PARAM{'e_date'}' AS DATE FORMAT 'YYYYMMDD')
           AND SEC_CTG = '11' AND MKT_LVL_SORT IN ('1','2','3')
           AND MKT_SORT = '0'
		   and a.sec_cde = b.sec_cde
        )k2
        ON substr(CAST(1000000+k1.SEC_CDE AS CHAR(7)),2,6) = k2.SEC_CDE
		inner join VT_ABNO_SEC_ACCT k3
		on k1.shdr_acct = k3.sec_acct
    WHERE 
        k1.TRAD_DATE BETWEEN 
        (
            select max(calendar_date)
            from nsoview.tdsum_date_exchange 
            where calendar_date <= CAST('$PARAM{'s_date'}' AS DATE FORMAT 'YYYYMMDD') - interval '1' year
            and is_trd_dt = '1'
        )
        AND CAST('$PARAM{'e_date'}' AS DATE FORMAT 'YYYYMMDD')
        AND k1.TRAD_DIRC = 'S'
        AND k1.TRANS_TYPE = '00G'
        AND k1.CAP_TYPE  = 'XL' --AND k1.NEGT_TYPE ='F' 
        AND k1.EQUT_TYPE <> 'HL'  -- 实测未发现在此前限定条件有该取值，因此测试数据范围内，该条件是否限定不影响结果
        AND k1.TRANS_VOL <> 0
    GROUP BY 1,2,3
    UNION ALL
    SELECT 
         k1.SHDR_ACCT
        ,substr(CAST(1000000+k1.SEC_CDE AS CHAR(7)),2,6) as sec_cde
        ,k2.MKT_SORT
        -- ,CAST(k1.CHG_DATE AS FORMAT 'yyyymmdd')                                     AS RELEASE_DATE     ---- 中登记录的解禁日期
        -- ,CASE 
        --     WHEN  k1.STK_CHRC IN ('05','06')    THEN 'SF'
        --     WHEN  k1.STK_CHRC IN ('01','03')    THEN 'ZF'
        --     ELSE 'OTH'
        -- END AS CAP_TYPE
        -- ,SUM(ABS(k1.CHG_VOL))                                                       AS RELEASE_VOL  ---- 首发数量
    FROM
        NsoVIEW.CSDC_S_SHDR_HLD_CHG k1
        INNER JOIN
        (SELECT a.SEC_CDE,MKT_SORT FROM NsoVIEW.CSDC_INTG_SEC_INFO a, VT_ABNO_SZSE_SEC b
         WHERE
           S_DATE <= CAST('$PARAM{'e_date'}' AS DATE FORMAT 'YYYYMMDD')  
           AND E_DATE > CAST('$PARAM{'e_date'}' AS DATE FORMAT 'YYYYMMDD') 
           AND SEC_CTG = '11' AND MKT_LVL_SORT IN ('1','2','3')
           AND MKT_SORT = '1'
		   AND a.SEC_CDE = b.SEC_CDE
        )k2
        ON substr(CAST(1000000+k1.SEC_CDE AS CHAR(7)),2,6) = k2.SEC_CDE
		inner join VT_ABNO_SEC_ACCT k3
		on k1.shdr_acct = k3.sec_acct
        INNER JOIN
        NsoVIEW.CSDC_S_SHDR_HLD_CHG k0
        ON k1.SHDR_ACCT = k0.SHDR_ACCT AND k1.SEC_CDE = k0.SEC_CDE AND k1.CHG_DATE = k0.CHG_DATE AND k1.SEAT_CDE = k0.SEAT_CDE
    WHERE 
        k1.CHG_DATE BETWEEN 
        (
            select max(calendar_date)
            from nsoview.tdsum_date_exchange 
            where calendar_date <= CAST('$PARAM{'s_date'}' AS DATE FORMAT 'YYYYMMDD') - interval '1' year
            and is_trd_dt = '1'
        ) AND CAST('$PARAM{'e_date'}' AS DATE FORMAT 'YYYYMMDD') 
        
        AND k1.CHG_CDE  IN ('A50')
        AND k0.STK_CHRC IN ('00')       ---- 解禁后，股份性质为00，转为高管锁定股的不算
        
        AND k1.CHG_VOL < 0 AND k0.CHG_VOL >0 
        AND k1.CHG_VOL + k0.CHG_VOL = 0
        --  AND k1.BEF_CHG_HOLD_VOL > 0
    GROUP BY 1,2,3
    UNION ALL
    SELECT 
         k1.SHDR_ACCT
		,substr(CAST(1000000+k1.SEC_CDE AS CHAR(7)),2,6) as sec_cde
        ,k2.MKT_SORT
        -- ,CAST(k1.CHG_DATE AS FORMAT 'yyyymmdd')                                     AS RELEASE_DATE     ---- 中登记录的解禁日期
        -- ,CASE 
        --     WHEN  k1.STK_CHRC IN ('05','06')    THEN 'SF'
        --     WHEN  k1.STK_CHRC IN ('01','03')    THEN 'ZF'
        --     ELSE 'OTH'
        -- END AS CAP_TYPE
        -- ,SUM(ABS(k1.CHG_VOL))                                                       AS RELEASE_VOL  ---- 首发数量
    FROM
        NsoVIEW.CSDC_S_STK_CHG k1
        INNER JOIN
        (SELECT a.SEC_CDE,MKT_SORT FROM NsoVIEW.CSDC_INTG_SEC_INFO a, VT_ABNO_SZSE_SEC b
        WHERE
           S_DATE <= CAST('$PARAM{'e_date'}' AS DATE FORMAT 'YYYYMMDD') 
           AND E_DATE > CAST('$PARAM{'e_date'}' AS DATE FORMAT 'YYYYMMDD')
           AND SEC_CTG = '11' AND MKT_LVL_SORT IN ('1','2','3')
           AND MKT_SORT = '1'
		   AND a.sec_cde = b.sec_cde
        ) k2
        ON substr(CAST(1000000+k1.SEC_CDE AS CHAR(7)),2,6) = k2.SEC_CDE
		inner join VT_ABNO_SEC_ACCT k3
		on k1.shdr_acct = k3.sec_acct        
		INNER JOIN NsoVIEW.CSDC_S_STK_CHG k0
        ON k1.SHDR_ACCT = k0.SHDR_ACCT AND k1.SEC_CDE = k0.SEC_CDE AND k1.CHG_DATE = k0.CHG_DATE AND k1.CSTD_UNIT = k0.CSTD_UNIT
    WHERE 
        k1.CHG_DATE BETWEEN 
        (
            select max(calendar_date)
            from nsoview.tdsum_date_exchange 
            where calendar_date <= CAST('$PARAM{'s_date'}' AS DATE FORMAT 'YYYYMMDD') - interval '1' year
            and is_trd_dt = '1'
        )
        AND CAST('$PARAM{'e_date'}' AS DATE FORMAT 'YYYYMMDD') 
        
        AND k1.CHG_CDE  IN ('A50')
        AND k0.STK_CHRC IN ('00')       ---- 解禁后，股份性质为00，转为高管锁定股的不算
        
        AND k1.CHG_VOL < 0 AND k0.CHG_VOL >0 
        AND k1.CHG_VOL + k0.CHG_VOL = 0
        --  AND k1.BEF_CHG_HOLD_VOL > 0
    GROUP BY 1,2,3
    ) xsgd
    group by 1,2
) tb6
on tb1.sec_acct = tb6.shdr_acct
and tb1.sec_cde = tb6.sec_cde
left outer join
(
  ---- 十大股东 --------------------------------------------------------------------  
  SEL  
    T2.OAP_ACCT_NBR,
    T1.SEC_CDE,
    SUM(TD_END_HOLD_VOL) as hold_vol,
    RANK() OVER( PARTITION BY t2.oap_acct_nbr, T1.SEC_CDE ORDER BY SUM(TD_END_HOLD_VOL) DESC) AS RANK_1
  FROM 
    NSPVIEW.ACT_SEC_HOLD_HIS T1
	inner join VT_ABNO_SEC t3
	on t1.sec_cde = t3.sec_cde
    LEFT JOIN
    NSOVIEW.CSDC_INTG_SEC_ACCT T2 
    ON T1.SEC_ACCT_NBR = T2.SEC_ACCT
    AND T1.MKT_SORT = T2.MKT_SORT
    AND T2.S_DATE <= CAST('$PARAM{'s_date'}' AS DATE FORMAT 'YYYYMMDD')
    AND T2.E_DATE > CAST('$PARAM{'s_date'}' AS DATE FORMAT 'YYYYMMDD')
  WHERE T1.S_DATE <= CAST('$PARAM{'s_date'}' AS DATE FORMAT 'YYYYMMDD')
    AND T1.E_DATE >= CAST('$PARAM{'s_date'}' AS DATE FORMAT 'YYYYMMDD')
    QUALIFY  RANK_1 <= 10
    GROUP BY 1,2
) tb7
on tb2.oap_acct_nbr = tb7.oap_acct_nbr
and tb1.sec_cde = tb7.sec_cde
group by 1,2,3,4,5,6,7,8,9,10,11,12,22
;


.IF ERRORCODE <> 0 THEN .QUIT 12;

.QUIT;

