/*	Drop existing table */
--DROP TABLE bu_ire.WEEKLY_WITHDRAWN_STUDENTS;

/*	Delete data from table */
--DELETE FROM bu_ire.WEEKLY_WITHDRAWN_STUDENTS;

/*	Recreate table with new definitions */
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE bu_ire.WEEKLY_WITHDRAWN_STUDENTS
	(
		WW_ID INT IDENTITY(1,1) NOT NULL
		, STUDENT_TERMS_ID VARCHAR(17) NOT NULL
		, STTR_STUDENT VARCHAR(7) NOT NULL
		, TERM VARCHAR(6) NOT NULL
		, TERM_DESC VARCHAR(40) NULL
		, TERM_SEQ VARCHAR(6) NOT NULL
		, STAT1 VARCHAR(2) NULL
		, STAT2 VARCHAR(2) NULL
		, CRED1 DEC(8,5) NULL
		, CRED2 DEC(8,5) NULL
		, UPDATE_DATE DATETIME NOT NULL
		, CONSTRAINT PK_WW_ID PRIMARY KEY (WW_ID ASC)
		WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO

/*	Create table indices */
CREATE INDEX IDX_TERM ON bu_ire.WEEKLY_WITHDRAWN_STUDENTS (TERM);
CREATE INDEX IDX_TERM_SEQ ON bu_ire.WEEKLY_WITHDRAWN_STUDENTS (TERM_SEQ);
CREATE INDEX IDX_STTR_STUDENT ON bu_ire.WEEKLY_WITHDRAWN_STUDENTS (STTR_STUDENT);
CREATE INDEX IDX_STUDENT_TERMS_ID ON bu_ire.WEEKLY_WITHDRAWN_STUDENTS (STUDENT_TERMS_ID);

/*	Rebuild data in table */
/* uncomment the line below to copy & paste into the SQL Server Agent */
INSERT INTO bu_ire.WEEKLY_WITHDRAWN_STUDENTS

SELECT *, GETDATE() AS UPDATE_DATE
FROM
	(
		SELECT STUDENT_TERMS_ID, STTR_STUDENT, TERM, TERM_DESC, TERM_SEQ
			, MIN(COALESCE(CASE WHEN BATES_DIST = -8 THEN STTR_STATUS END
					, CASE WHEN BATES_DIST = -7 THEN STTR_STATUS END
					, CASE WHEN BATES_DIST = -6 THEN STTR_STATUS END
					, CASE WHEN BATES_DIST = -5 THEN STTR_STATUS END
					, CASE WHEN BATES_DIST = -4 THEN STTR_STATUS END
					, CASE WHEN BATES_DIST = -3 THEN STTR_STATUS END
					, CASE WHEN BATES_DIST = -2 THEN STTR_STATUS END)) AS STAT1
			, MAX(CASE WHEN BATES_DIST = -1 THEN STTR_STATUS END) AS STAT2
			, MAX(COALESCE(CASE WHEN BATES_DIST = -8 THEN STC_CRED_SUM END
					, CASE WHEN BATES_DIST = -7 THEN STC_CRED_SUM END
					, CASE WHEN BATES_DIST = -6 THEN STC_CRED_SUM END
					, CASE WHEN BATES_DIST = -5 THEN STC_CRED_SUM END
					, CASE WHEN BATES_DIST = -4 THEN STC_CRED_SUM END
					, CASE WHEN BATES_DIST = -3 THEN STC_CRED_SUM END
					, CASE WHEN BATES_DIST = -2 THEN STC_CRED_SUM END)) AS CRED1
			, MAX(CASE WHEN BATES_DIST = -1 THEN STC_CRED_SUM END) AS CRED2
		FROM
			(
				SELECT STUDENT_TERMS_ID, DATEADD(D,1,TEST_DATE) AS TEST_DATE, STTR_STUDENT, TERM, TERM_DESC, TERM_SEQ, STTR_STATUS, STC_CRED_SUM, BATES_DIST
				FROM bu_ire.STUDENT_ENROLLMENT_COMPS_ALL
				WHERE BATES_DIST BETWEEN -8 AND 0 AND TERM = LATEST_TERM
			) X
		GROUP BY STUDENT_TERMS_ID, STTR_STUDENT, TERM, TERM_DESC, TERM_SEQ
	) X
WHERE STAT1 = 'R' AND (STAT2 IN ('W', 'X') OR (STAT2 = 'T' AND CRED1 > ISNULL(CRED2,0)))

/*	Confirm data loaded correctly */
SELECT *
FROM bu_ire.WEEKLY_WITHDRAWN_STUDENTS W
ORDER BY TERM_SEQ, STTR_STUDENT

/*	Revision history:
		JDT 4/21/2021: Further repairs to the BATES_DIST syntax, implementing a COALESCE statement and adding an extra day to the STAT1 logic; added
				a DATEADD function to bring the dates back into alignment with reality.
		JDT 4/1/2021: Repaired problem with the BATES_DIST < -6 and BATES_DIST = -6 approach in the lowest subquery.
		JDT 12/23/2020: Added X term status to outermost WHERE statement to ensure future term melt is included.
		JDT 9/24/2020: Created view to explicitly identify any student whose enrollment dropped to 0 credits within the past week in any active term.
				This will form the basis of a major rebuild of the Weekly Withdrawn report, which up to this point has consistently included a lot of
				false positives because of its reliance on the STUDENT_ACAD_CRED metadata to determine when a students' enrollment level has changed.
*/
