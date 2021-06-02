/*	Drop existing table */
--DROP TABLE bu_ire.WAREHOUSE_STTR_STATUSES_SUB;

/*	Delete data from table */
--DELETE FROM bu_ire.WAREHOUSE_STTR_STATUSES_SUB;

/*	Recreate table with new definitions */
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE bu_ire.WAREHOUSE_STTR_STATUSES_SUB
	(
		STUDENT_TERMS_ID VARCHAR(18) NOT NULL
		, STUDENT_TERMS_SUB_ID VARCHAR(30) NOT NULL
		, STTR_STUDENT VARCHAR(7) NOT NULL
		, STTR_TERM VARCHAR(7) NOT NULL
		, SUBSESSION VARCHAR(10) NOT NULL
		, TERM_SUB_ID VARCHAR(20) NOT NULL
		, STTR_ACAD_LEVEL VARCHAR(2) NOT NULL
		, TERM_RPT_YR INT NOT NULL
		, TERM_SEQ_NO INT NOT NULL
		, TERM_SEQ VARCHAR(7) NOT NULL
		, STAT_RANK INT
		, STTR_STATUS VARCHAR(2)
		, STTR_START_DATE DATETIME
		, STTR_END_DATE DATETIME
		, UPDATE_DATE DATETIME
		, CONSTRAINT STUDENT_TERMS_SUB_ID_STATUS PRIMARY KEY (STUDENT_TERMS_SUB_ID ASC, STAT_RANK ASC)
		WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO

/*	Create table indices */
CREATE INDEX IDX_STUDENT_TERMS_ID ON bu_ire.WAREHOUSE_STTR_STATUSES_SUB (STUDENT_TERMS_ID);
CREATE INDEX IDX_STUDENT_TERMS_SUB_ID ON bu_ire.WAREHOUSE_STTR_STATUSES_SUB (STUDENT_TERMS_SUB_ID);
CREATE INDEX IDX_STTR_TERM ON bu_ire.WAREHOUSE_STTR_STATUSES_SUB (STTR_TERM);
CREATE INDEX IDX_SUBSESSION ON bu_ire.WAREHOUSE_STTR_STATUSES_SUB (SUBSESSION);
CREATE INDEX IDX_STTR_ACAD_LEVEL ON bu_ire.WAREHOUSE_STTR_STATUSES_SUB (STTR_ACAD_LEVEL);


/*	Rebuild data in table */
;WITH STTR_CTE (STUDENT_TERMS_ID, STUDENT_TERMS_SUB_ID, STTR_STUDENT, STTR_TERM, SUBSESSION, TERM_SUB_ID, STTR_ACAD_LEVEL, TERM_RPT_YR, TERM_SEQ_NO, TERM_SEQ, STAT_RANK, STTR_STATUS, STTR_START_DATE, STTR_END_DATE) AS
	(
		SELECT
			STUDENT_TERMS_ID
			, STUDENT_TERMS_SUB_ID
			, STC_PERSON_ID
			, STC_TERM
			, SUBSESSION
			, STC_TERM+'*'+SUBSESSION AS TERM_SUB_ID
			, STC_ACAD_LEVEL
			, TERM_RPT_YR
			, TERM_SEQ_NO
			, TERM_SEQ
			, STAT_RANK
			, STUB_STATUS
			, STUB_STATUS_DATE AS STUB_START_DATE
			, CASE
					WHEN (LEAD(STUDENT_TERMS_SUB_ID,1) OVER(ORDER BY STC_PERSON_ID, TERM_RPT_YR, TERM_SEQ_NO, STC_ACAD_LEVEL, STAT_RANK) <> STUDENT_TERMS_SUB_ID
						OR LEAD(STUDENT_TERMS_SUB_ID,1) OVER(ORDER BY STC_PERSON_ID, TERM_RPT_YR, TERM_SEQ_NO, STC_ACAD_LEVEL, STAT_RANK) IS NULL) AND DATEADD(DAY, 11, TERM_END_DATE) > GETDATE()
							THEN GETDATE()
					WHEN (LEAD(STUDENT_TERMS_SUB_ID,1) OVER(ORDER BY STC_PERSON_ID, TERM_RPT_YR, TERM_SEQ_NO, STC_ACAD_LEVEL, STAT_RANK) <> STUDENT_TERMS_SUB_ID
						OR LEAD(STUDENT_TERMS_SUB_ID,1) OVER(ORDER BY STC_PERSON_ID, TERM_RPT_YR, TERM_SEQ_NO, STC_ACAD_LEVEL, STAT_RANK) IS NULL)
							THEN DATEADD(DAY, 11, TERM_END_DATE)
					WHEN (LEAD(STUB_STATUS_DATE,1) OVER(ORDER BY STC_PERSON_ID, TERM_RPT_YR, TERM_SEQ_NO, STC_ACAD_LEVEL, STAT_RANK) = STUB_STATUS_DATE
						OR LEAD(STUDENT_TERMS_SUB_ID,1) OVER(ORDER BY STC_PERSON_ID, TERM_RPT_YR, TERM_SEQ_NO, STC_ACAD_LEVEL, STAT_RANK) IS NULL)
							THEN STUB_STATUS_DATE
					WHEN (LEAD(STAT_RANK,1) OVER(ORDER BY STC_PERSON_ID, TERM_RPT_YR, TERM_SEQ_NO, STC_ACAD_LEVEL, STAT_RANK) > STAT_RANK
						OR LEAD(STAT_RANK,1) OVER(ORDER BY STC_PERSON_ID, TERM_RPT_YR, TERM_SEQ_NO, STC_ACAD_LEVEL, STAT_RANK) IS NULL) 
							THEN DATEADD(DAY, -1, LEAD(STUB_STATUS_DATE,1) OVER(ORDER BY STC_PERSON_ID, TERM_RPT_YR, TERM_SEQ_NO, STC_ACAD_LEVEL, STAT_RANK))
					ELSE DATEADD(DAY, 11, TERM_END_DATE)
				END AS STUB_END_DATE

		FROM
			(
				SELECT
					STUDENT_TERMS_ID
					, STUDENT_TERMS_SUB_ID
					, STC_PERSON_ID
					, STC_TERM
					, SUBSESSION
					, STC_ACAD_LEVEL
					, STUB_STATUS
					, STUB_STATUS_DATE
					, TERM_RPT_YR
					, TERM_SEQ_NO
					, TERM_SEQ
					, SUB_START_DATE
					, TERM_END_DATE
					, ROW_NUMBER() OVER(PARTITION BY STC_PERSON_ID, TERM_RPT_YR, TERM_SEQ_NO, SUBSESSION, STC_ACAD_LEVEL ORDER BY POS DESC) AS STAT_RANK

				FROM
					(
						SELECT
							S2.STUDENT_TERMS_ID
							, S2.STUDENT_TERMS_SUB_ID
							, STS.POS
							, STS.STC_PERSON_ID
							, STS.STC_TERM
							, S2.SUBSESSION
							, STS.STC_ACAD_LEVEL
							, STS.STUB_STATUS
							, STS.STUB_STATUS_DATE
							, STS.STUB_REG_DATE
							, S2.TERM_RPT_YR
							, S2.TERM_SEQ_NO
							, S2.TERM_SEQ
							, S2.SUB_START_DATE
							, S2.TERM_END_DATE
							, ROW_NUMBER() OVER(PARTITION BY STS.STC_PERSON_ID, S2.TERM_RPT_YR, S2.TERM_SEQ_NO, S2.SUBSESSION, STS.STC_ACAD_LEVEL, STS.STUB_STATUS_DATE ORDER BY STS.POS) AS STAT_RANK

						FROM
							(
								SELECT
									ST.STUDENT_TERMS_ID
									, S.STUDENT_TERMS_SUB_ID
									, ST.STTR_STUDENT
									, ST.STTR_TERM
									, T.SUBSESSION
									, ST.STTR_ACAD_LEVEL
									, T.TERM_RPT_YR_NUMERIC AS TERM_RPT_YR
									, T.TERM_SEQ_NO
									, T.TERM_SEQ
									, S.STUB_REG_DATE
									, T.SUB_START_DATE
									, T.TERM_END_DATE
									, ROW_NUMBER() OVER(PARTITION BY ST.STTR_STUDENT, T.TERM_RPT_YR_NUMERIC, T.TERM_SEQ_NO, T.TERM_SUB_ID ORDER BY ST.STTR_ACAD_LEVEL) AS STAT_RANK

								FROM
									bu_ire.TERM_SUB_DATES_CTE T
									JOIN ODS_STUDENT_TERMS ST ON T.TERM=ST.STTR_TERM AND T.TERM_RPT_YR_STRING>='2016'
									JOIN bu_ire.STUB_STATUSES S ON ST.STUDENT_TERMS_ID=S.STUDENT_TERMS_ID AND T.SUBSESSION=S.SUBSESSION

								WHERE
									ST.STTR_STUDENT <> '1251343'
							) S2
							JOIN bu_ire.STUB_STATUSES STS ON S2.STUDENT_TERMS_SUB_ID=STS.STUDENT_TERMS_SUB_ID AND STS.STUB_STATUS<>'E'
					) S1
				WHERE STAT_RANK = 1
			) S
	)

/*	check CTE */
/*
SELECT * FROM STTR_CTE
OPTION (MAXRECURSION 1000)
*/

/* remove comment from line below to copy & paste into SQL Server Agent */
INSERT INTO bu_ire.WAREHOUSE_STTR_STATUSES_SUB

SELECT *, GETDATE() AS UPDATE_DATE
FROM STTR_CTE
ORDER BY TERM_SEQ, STTR_STUDENT, STAT_RANK
OPTION (MAXRECURSION 1000)


/*	Confirm data loaded correctly */
SELECT *
FROM bu_ire.WAREHOUSE_STTR_STATUSES_SUB
ORDER BY 16, 14, 5


/*	Revision history:
		JDT 5/29/2020: Rebuilt to incorporate term-and-subsession as the unique table key for each student.
		JDT 4/29/2020: Removed the offending lowest-level subquery that was excluding students who eventually had an "X" term status but were registered at some point prior.
		JDT 12/2/2019: Updated column definitions to align with other files used in the student enrollment comparisons project.
		JDT 11/27/2019: Created file.
*/
