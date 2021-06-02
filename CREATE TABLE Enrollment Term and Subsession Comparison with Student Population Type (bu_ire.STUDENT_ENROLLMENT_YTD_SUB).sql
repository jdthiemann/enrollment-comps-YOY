/*	Drop existing table */
--DROP TABLE bu_ire.STUDENT_ENROLLMENT_YTD;

/*	Recreate table with new definitions */
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE bu_ire.STUDENT_ENROLLMENT_YTD
	(
		ENRCOMPS_ID INT IDENTITY(1,1) NOT NULL
		, TERM VARCHAR(7) NOT NULL
		, TERM_DESC VARCHAR(40) NOT NULL
		, TERM_SEASON VARCHAR(10) NOT NULL
		, TERM_RPT_YR INT NOT NULL
		, TERM_SEQ_NO TINYINT NOT NULL
		, TERM_SEQ VARCHAR(7) NOT NULL
		, COLLEAGUE_FLAG VARCHAR(1) NULL
		, TEST_DATE DATETIME NOT NULL
		, BATES_STAMP INT NOT NULL
		, STUDENT_TERMS_ID VARCHAR(18) NULL
		, STTR_STUDENT VARCHAR(10) NULL
		, STTR_ACAD_LEVEL VARCHAR(2) NULL
		, STUDENT_TYPE VARCHAR(40) NULL
		, ENR_TYPE INT NULL
		, STUDENT_POPULATION VARCHAR(50) NULL
		, COHORT VARCHAR(20) NULL
		, MATRIC_TERM VARCHAR(7) NULL
		, MATRIC_TERM_SEASON VARCHAR(10) NULL
		, MATRIC_TERM_RPT_YR INT NULL
		, MATRIC_TERM_SEQ_NO TINYINT NULL
		, STAT_RANK TINYINT NULL
		, STTR_STATUS VARCHAR(2) NULL
		, STC_CRED_SUM DEC(8,5) NULL
		, UPDATE_DATE DATETIME NOT NULL
		, CONSTRAINT PK_ENRCOMPS_ID PRIMARY KEY (ENRCOMPS_ID ASC)
		WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO

/*	Create table indices */
--CREATE INDEX IDX_TERM ON bu_ire.STUDENT_ENROLLMENT_YTD (TERM);
--CREATE INDEX IDX_TERM_SEQ ON bu_ire.STUDENT_ENROLLMENT_YTD (TERM_SEQ);
--CREATE INDEX IDX_BATES_STAMP ON bu_ire.STUDENT_ENROLLMENT_YTD (BATES_STAMP);
--CREATE INDEX IDX_STTR_STUDENT ON bu_ire.STUDENT_ENROLLMENT_YTD (STTR_STUDENT);


/*	Rebuild data in table */
/* uncomment the line below to copy & paste into the SQL Server Agent */
--INSERT INTO bu_ire.STUDENT_ENROLLMENT_YTD

SELECT
	TERM
	, TERM_DESC
	, TERM_SEASON
	, TERM_RPT_YR
	, TERM_SEQ_NO
	, TERM_SEQ
	, COLLEAGUE_FLAG
	, TEST_DATE
	, BATES_STAMP
	, STUDENT_TERMS_ID
	, STTR_STUDENT
	, STTR_ACAD_LEVEL
	, STUDENT_TYPE
	, ENR_TYPE
	, CASE
			WHEN STUDENT_TYPE = 'FTIAC' THEN
				CASE
					WHEN ENR_TYPE = 0 THEN 'Incoming FTIAC'
					WHEN ENR_TYPE = 1 THEN 'Returning 1st Year FTIAC'
					WHEN ENR_TYPE = 2 THEN 'Returning 2nd Year FTIAC'
					WHEN ENR_TYPE = 3 THEN 'Returning 3rd Year FTIAC'
					WHEN ENR_TYPE = 4 THEN 'Returning 4th Year FTIAC'
					WHEN ENR_TYPE = 5 THEN 'Returning 5th Year FTIAC'
					WHEN ENR_TYPE = 6 THEN 'Returning 6th Year FTIAC'
					WHEN ENR_TYPE > 6 THEN 'Returning 7th+ Year FTIAC'
				END
			WHEN STUDENT_TYPE = 'Transfer' THEN
				CASE
					WHEN ENR_TYPE = 0 THEN 'Incoming Transfer'
					WHEN ENR_TYPE = 1 THEN 'Returning 1st Year Transfer'
					WHEN ENR_TYPE = 2 THEN 'Returning 2nd Year Transfer'
					WHEN ENR_TYPE = 3 THEN 'Returning 3rd Year Transfer'
					WHEN ENR_TYPE = 4 THEN 'Returning 4th Year Transfer'
					WHEN ENR_TYPE = 5 THEN 'Returning 5th Year Transfer'
					WHEN ENR_TYPE = 6 THEN 'Returning 6th Year Transfer'
					WHEN ENR_TYPE > 6 THEN 'Returning 7th+ Year Transfer'
				END
			WHEN STUDENT_TYPE = 'Certificate' THEN
				CASE
					WHEN ENR_TYPE = 0 THEN 'Incoming Certificate Student'
					WHEN ENR_TYPE = 1 THEN 'Returning 1st Year Certificate Student'
					WHEN ENR_TYPE = 2 THEN 'Returning 2nd Year Certificate Student'
					WHEN ENR_TYPE = 3 THEN 'Returning 3rd Year Certificate Student'
					WHEN ENR_TYPE = 4 THEN 'Returning 4th Year Certificate Student'
					WHEN ENR_TYPE > 4 THEN 'Returning 5th+ Year Certificate Student'
				END
			WHEN STUDENT_TYPE = 'Post-Baccalaureate' THEN
				CASE
					WHEN ENR_TYPE = 0 THEN 'Incoming Post-Baccalaureate'
					WHEN ENR_TYPE = 1 THEN 'Returning 1st Year Post-Bac'
					WHEN ENR_TYPE = 2 THEN 'Returning 2nd Year Post-Bac'
					WHEN ENR_TYPE = 3 THEN 'Returning 3rd Year Post-Bac'
					WHEN ENR_TYPE = 4 THEN 'Returning 4th Year Post-Bac'
					WHEN ENR_TYPE > 4 THEN 'Returning 5th+ Year Post-Bac'
				END
			WHEN STUDENT_TYPE = 'Undergraduate Degree-Seeking' THEN
				CASE
					WHEN ENR_TYPE = 0 THEN 'Incoming Undergraduate Degree-Seeking'
					WHEN ENR_TYPE > 0 THEN 'Returning Undergraduate Degree-Seeking'
				END
			WHEN STUDENT_TYPE = 'Graduate Degree-Seeking' THEN
				CASE
					WHEN ENR_TYPE = 0 THEN 'Incoming Graduate Degree-Seeking'
					WHEN ENR_TYPE = 1 THEN 'Returning 1st Year Graduate Student'
					WHEN ENR_TYPE = 2 THEN 'Returning 2nd Year Graduate Student'
					WHEN ENR_TYPE = 3 THEN 'Returning 3rd Year Graduate Student'
					WHEN ENR_TYPE = 4 THEN 'Returning 4th Year Graduate Student'
					WHEN ENR_TYPE > 4 THEN 'Returning 5th+ Year Graduate Student'
				END
			WHEN STUDENT_TYPE = 'Undergraduate Non-Degree Seeking' THEN
				CASE
					WHEN ENR_TYPE = 0 THEN 'Incoming Undergraduate Non-Degree'
					WHEN ENR_TYPE > 0 THEN 'Returning Undergraduate Non-Degree'
				END
			WHEN STUDENT_TYPE = 'Graduate Non-Degree Seeking' THEN
				CASE
					WHEN ENR_TYPE = 0 THEN 'Incoming Graduate Non-Degree'
					WHEN ENR_TYPE > 0 THEN 'Returning Graduate Non-Degree'
				END
			WHEN STTR_STUDENT IS NULL THEN NULL
			ELSE 'PROBLEM'
		END AS STUDENT_POPULATION
	, COHORT
	, MATRIC_TERM
	, MATRIC_TERM_SEASON
	, MATRIC_TERM_RPT_YR
	, MATRIC_TERM_SEQ_NO
	, STAT_RANK
	, STTR_STATUS
	, STC_CRED_SUM
	, GETDATE() AS UPDATE_DATE

FROM
	(
		SELECT
			T.TERM
			, T.TERM_DESC
			, T.TERM_SEASON
			, T.TERM_RPT_YR_NUMERIC AS TERM_RPT_YR
			, T.TERM_SEQ_NO
			, T.TERM_SEQ
			, T.COLLEAGUE_FLAG
			, T.TEST_DATE
			, T.BATES_STAMP
			, S.STUDENT_TERMS_ID
			, S.STTR_STUDENT
			, S.STTR_ACAD_LEVEL
			, P.STUDENT_TYPE
			, CASE
					WHEN P.MATRIC_TERM = T.TERM THEN 0
					WHEN P.MATRIC_TERM_SEASON = T.TERM_SEASON OR P.MATRIC_TERM_SEASON IN ('Summer', 'Fall') THEN T.TERM_RPT_YR_NUMERIC-P.MATRIC_TERM_RPT_YR+1
					WHEN P.MATRIC_TERM_SEASON = 'Spring' AND T.TERM_SEASON = 'Summer'	THEN CAST(LEFT(T.TERM,4) AS INT)-P.MATRIC_TERM_RPT_YR+1
					WHEN P.MATRIC_TERM_SEASON = 'Spring' AND T.TERM_SEASON = 'Fall' THEN T.TERM_RPT_YR_NUMERIC-P.MATRIC_TERM_RPT_YR
				END AS ENR_TYPE
			, P.COHORT
			, P.MATRIC_TERM
			, P.MATRIC_TERM_SEASON
			, P.MATRIC_TERM_RPT_YR
			, P.MATRIC_TERM_SEQ_NO
			, S.STAT_RANK
			, S.STTR_STATUS
			, SUM(E.STC_CRED) AS STC_CRED_SUM

		FROM
			bu_ire.TERM_DATES_CTE T
			LEFT OUTER JOIN bu_ire.WAREHOUSE_STTR_STATUSES S ON T.TERM=S.STTR_TERM AND T.TEST_DATE BETWEEN S.STTR_START_DATE AND S.STTR_END_DATE
			LEFT OUTER JOIN bu_ire.WAREHOUSE_STC_STATUSES E ON S.STUDENT_TERMS_ID=E.STUDENT_TERMS_ID AND T.TEST_DATE BETWEEN E.STC_START_DATE AND E.STC_END_DATE
			LEFT OUTER JOIN bu_ire.WAREHOUSE_STUDENT_POPULATION P ON S.STUDENT_TERMS_ID=P.STUDENT_TERMS_ID

		WHERE
			T.TERM_RPT_YR_NUMERIC >= 2016

		GROUP BY
			T.TERM, T.TERM_DESC, T.TERM_SEASON, T.TERM_RPT_YR_NUMERIC, T.TERM_SEQ_NO, T.TERM_SEQ, T.COLLEAGUE_FLAG, T.TEST_DATE, T.BATES_STAMP
			, S.STUDENT_TERMS_ID, S.STTR_STUDENT, S.STTR_ACAD_LEVEL, S.STAT_RANK, S.STTR_STATUS
			, P.STUDENT_TYPE, P.COHORT, P.MATRIC_TERM, P.MATRIC_TERM_SEASON, P.MATRIC_TERM_RPT_YR, P.MATRIC_TERM_SEQ_NO
	) X

ORDER BY STTR_STUDENT, TERM_SEQ, BATES_STAMP


/*	Confirm data loaded correctly */
SELECT *
FROM bu_ire.STUDENT_ENROLLMENT_YTD
ORDER BY 6, 9, 10


/*	Revision history:
		JDT 12/2/2019: United the CREATE TABLE definitions with the INSERT INTO statement; updated column definitions to align with other files used in the student enrollment comparisons project.
		JDT 11/26/2019: Removed the four CTEs and replaced them with references to four new bu_ire tables (TERM_DATES_CTE, WAREHOUSE_STTR_STATUSES, WAREHOUSE_STC_STATUSES, and WAREHOUSE_STUDENT_POPULATION).
		JDT 7/31/2019: Removed Ima Demostudent.
		JDT 7/29/2019: Added primary academic level and built a new subquery to sum credits for students with two academic levels in the same term;
				added logic to ensure that future dates are not expected nor filled by the TERM_CTE.
		JDT 7/23/2019: Revised window function syntax to explicitly use term reporting year and sequence in ORDER statements.
		JDT 7/18/2019: Created view to display point-in-time enrollment data as of specific pivot dates for each term.
*/
