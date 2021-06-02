/*	Drop existing table */
--DROP TABLE bu_ire.WAREHOUSE_STC_STATUSES_SUB;

/*	Delete existing data from table */
--DELETE FROM bu_ire.WAREHOUSE_STC_STATUSES_SUB;

/*	Recreate table with new definitions */
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE bu_ire.WAREHOUSE_STC_STATUSES_SUB
	(
		STUDENT_ACAD_CRED_ID VARCHAR(15) NOT NULL
		, COURSE_SECTIONS_ID VARCHAR(15) NULL
		, SEC_NAME VARCHAR(20) NULL
		, STUDENT_TERMS_ID VARCHAR(18) NOT NULL
		, STUDENT_TERMS_SUB_ID VARCHAR(30) NOT NULL
		, STC_PERSON_ID VARCHAR(10) NOT NULL
		, STC_TERM VARCHAR(7) NOT NULL
		, STC_ACAD_LEVEL VARCHAR(2) NOT NULL
		, TERM_RPT_YR INT NOT NULL
		, TERM_SEQ_NO TINYINT NOT NULL
		, TERM_SEQ VARCHAR(7) NOT NULL
		, SUBSESSION VARCHAR(10) NOT NULL
		, TERM_SUB_SEQ VARCHAR(20) NOT NULL
		, STC_CRED DEC(8,5) NULL
		, STAC_RANK TINYINT NOT NULL
		, STC_STATUS VARCHAR(2) NULL
		, STC_START_DATE DATETIME NULL
		, STC_END_DATE DATETIME NULL
		, UPDATE_DATE DATETIME NOT NULL
		, CONSTRAINT STAC_SUB_ID_RANK PRIMARY KEY (STUDENT_ACAD_CRED_ID ASC, STAC_RANK ASC)
		WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO

/*	Create table indices */
CREATE INDEX IDX_STUDENT_TERMS_ID ON bu_ire.WAREHOUSE_STC_STATUSES_SUB (STUDENT_TERMS_ID);
CREATE INDEX IDX_STUDENT_TERMS_SUB_ID ON bu_ire.WAREHOUSE_STC_STATUSES_SUB (STUDENT_TERMS_SUB_ID);
CREATE INDEX IDX_STC_PERSON_ID ON bu_ire.WAREHOUSE_STC_STATUSES_SUB (STC_PERSON_ID);
CREATE INDEX IDX_STC_TERM ON bu_ire.WAREHOUSE_STC_STATUSES_SUB (STC_TERM);
CREATE INDEX IDX_SUBSESSION ON bu_ire.WAREHOUSE_STC_STATUSES_SUB (SUBSESSION);
CREATE INDEX IDX_STC_ACAD_LEVEL ON bu_ire.WAREHOUSE_STC_STATUSES_SUB (STC_ACAD_LEVEL);


/*	Rebuild data in table */
;WITH STAC_CTE (STUDENT_ACAD_CRED_ID, COURSE_SECTIONS_ID, SEC_NAME, STUDENT_TERMS_ID, STUDENT_TERMS_SUB_ID, STC_PERSON_ID, STC_TERM, STC_ACAD_LEVEL, TERM_RPT_YR, TERM_SEQ_NO, TERM_SEQ, SUBSESSION, TERM_SUB_SEQ, STC_CRED, STAC_RANK, STC_STATUS, STC_START_DATE, STC_END_DATE) AS
/* build student course section enrollment CTE */
	(
		SELECT
			STUDENT_ACAD_CRED_ID
			, COURSE_SECTIONS_ID
			, SEC_NAME
			, STUDENT_TERMS_ID
			, STUDENT_TERMS_SUB_ID
			, STC_PERSON_ID
			, STC_TERM
			, STC_ACAD_LEVEL
			, TERM_RPT_YR
			, TERM_SEQ_NO
			, TERM_SEQ
			, SUBSESSION
			, TERM_SEQ+'*'+SUBSESSION AS TERM_SUB_SEQ
			, STC_CRED
			, STAC_RANK
			, STC_STATUS
			, STC_STATUS_DATE AS STC_START_DATE
			, CASE
					WHEN (LEAD(STAC_RANK,1) OVER(ORDER BY STUDENT_ACAD_CRED_ID, STAC_RANK) = 1
						OR (LEAD(STAC_RANK,1) OVER(ORDER BY STUDENT_ACAD_CRED_ID, STAC_RANK) IS NULL)) AND DATEADD(DAY, 11, TERM_END_DATE) > GETDATE()
							THEN GETDATE()
					WHEN (LEAD(STAC_RANK,1) OVER(ORDER BY STUDENT_ACAD_CRED_ID, STAC_RANK) = 1
						OR (LEAD(STAC_RANK,1) OVER(ORDER BY STUDENT_ACAD_CRED_ID, STAC_RANK) IS NULL))
							THEN DATEADD(DAY, 11, TERM_END_DATE)
					WHEN (LEAD(STC_STATUS_DATE,1) OVER(ORDER BY STUDENT_ACAD_CRED_ID, STAC_RANK) = STC_STATUS_DATE
						OR LEAD(STC_STATUS_DATE,1) OVER(ORDER BY STUDENT_ACAD_CRED_ID, STAC_RANK) IS NULL)
							THEN STC_STATUS_DATE
					WHEN (LEAD(STAC_RANK,1) OVER(ORDER BY STUDENT_ACAD_CRED_ID, STAC_RANK) > STAC_RANK
						OR LEAD(STAC_RANK,1) OVER(ORDER BY STUDENT_ACAD_CRED_ID, STAC_RANK) IS NULL)
							THEN DATEADD(DAY, -1, LEAD(STC_STATUS_DATE,1) OVER(ORDER BY STUDENT_ACAD_CRED_ID, STAC_RANK))
					ELSE DATEADD(DAY, 11, TERM_END_DATE)
				END AS STC_END_DATE

		FROM
			(
				SELECT
					STUDENT_ACAD_CRED_ID
					, COURSE_SECTIONS_ID
					, SEC_NAME
					, STC_PERSON_ID+'*'+STC_TERM+'*'+STC_ACAD_LEVEL AS STUDENT_TERMS_ID
					, STC_PERSON_ID+'*'+STC_TERM+'*'+SUBSESSION+'*'+STC_ACAD_LEVEL AS STUDENT_TERMS_SUB_ID
					, STC_PERSON_ID
					, STC_TERM
					, STC_ACAD_LEVEL
					, CASE
							WHEN STC_STATUS IN ('N', 'A') THEN STC_CRED
							ELSE NULL
						END AS STC_CRED
					, STC_STATUS
					, STC_STATUS_DATE
					, TERM_RPT_YR
					, TERM_SEQ_NO
					, TERM_SEQ
					, SUBSESSION
					, TERM_END_DATE
					, ROW_NUMBER() OVER(PARTITION BY STUDENT_ACAD_CRED_ID ORDER BY POS DESC) AS STAC_RANK

				FROM
					(
						SELECT
							E.STUDENT_ACAD_CRED_ID
							, E.B13_COURSE_SECTION_ID AS COURSE_SECTIONS_ID
							, E.B13_COURSE_SECTION_NAME AS SEC_NAME
							, E.STC_PERSON_ID
							, E.STC_TERM
							, E.STC_ACAD_LEVEL
							, E.STC_CRED
							, S.STC_STATUS
							, S.STC_STATUS_DATE
							, S.POS
							, T.TERM_REPORTING_YEAR AS TERM_RPT_YR
							, T.B13_TERM_SEQUENCE_NO AS TERM_SEQ_NO
							, CONVERT(VARCHAR(4),T.TERM_REPORTING_YEAR)+'*'+CONVERT(VARCHAR(1),T.B13_TERM_SEQUENCE_NO) AS TERM_SEQ
							, COALESCE(CT.SUBSESSION,RIGHT(T.TERMS_ID,2)+'FT') AS SUBSESSION
							, T.TERM_END_DATE
							, ROW_NUMBER() OVER(PARTITION BY S.STUDENT_ACAD_CRED_ID, S.STC_STATUS_DATE ORDER BY S.POS) AS STAC_RANK

						FROM
							ODS_TERMS T
							JOIN ODS_STUDENT_ENROLLMENT E ON T.TERMS_ID=E.STC_TERM AND T.TERM_REPORTING_YEAR >= 2016
							JOIN B13_STC_STATUSES S ON E.STUDENT_ACAD_CRED_ID=S.STUDENT_ACAD_CRED_ID
							LEFT OUTER JOIN B13_COURSE_TYPES_FLAT CT ON E.SCS_COURSE_SECTION=CT.COURSE_SECTIONS_ID

						WHERE
							E.STC_CRED_TYPE IN ('IN', 'CHAL', 'PORT', 'PH', 'SA')
							AND (E.B13_SCS_PASS_AUDIT <> 'A' OR E.B13_SCS_PASS_AUDIT IS NULL)
							AND S.STC_STATUS NOT IN ('NC', 'PR')
					) Z1
				WHERE STAC_RANK = 1
			) Z
	)

/* uncomment the line below to copy & paste into SQL Server Agent */
INSERT INTO bu_ire.WAREHOUSE_STC_STATUSES_SUB

SELECT *, GETDATE() AS UPDATE_DATE
FROM STAC_CTE
ORDER BY TERM_SEQ, STC_PERSON_ID, SEC_NAME, STAC_RANK
OPTION (MAXRECURSION 1000)


/*	Confirm the data exist */
SELECT *
FROM bu_ire.WAREHOUSE_STC_STATUSES_SUB
ORDER BY STC_PERSON_ID, TERM_SEQ, SEC_NAME, STAC_RANK


/*	Revision history:
		JDT 5/29/2020: Created view to align with the new STUB_STATUSES table.
*/
