/*	Drop existing table */
--DROP TABLE bu_ire.WAREHOUSE_STUDENT_POPULATION;

/*	Delete data from existing table */
--DELETE FROM bu_ire.WAREHOUSE_STUDENT_POPULATION;

/*	Recreate table with new definitions */
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE bu_ire.WAREHOUSE_STUDENT_POPULATION
	(
		STUDENT_TERMS_ID VARCHAR(18) NOT NULL
		, STTR_STUDENT VARCHAR(10) NOT NULL
		, STTR_TERM VARCHAR(7) NOT NULL
		, STTR_ACAD_LEVEL VARCHAR(2) NOT NULL
		, STUDENT_TYPE VARCHAR(40) NULL
		, COHORT VARCHAR(20) NULL
		, TERM_SEASON VARCHAR(10) NOT NULL
		, TERM_RPT_YR INT NOT NULL
		, TERM_SEQ_NO TINYINT NOT NULL
		, TERM_RANK INT NOT NULL
		, MATRIC_TERM VARCHAR(7) NULL
		, MATRIC_TERM_SEASON VARCHAR(10) NULL
		, MATRIC_TERM_RPT_YR INT NULL
		, MATRIC_TERM_SEQ_NO TINYINT NULL
		, UPDATE_DATE DATETIME
		, CONSTRAINT POP_STUDENT_TERMS_ID PRIMARY KEY (STUDENT_TERMS_ID ASC)
		WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO

/*	Create table indices */
CREATE INDEX IDX_STUDENT_TERMS_ID ON bu_ire.WAREHOUSE_STUDENT_POPULATION (STUDENT_TERMS_ID);
CREATE INDEX IDX_STTR_STUDENT ON bu_ire.WAREHOUSE_STUDENT_POPULATION (STTR_STUDENT);
CREATE INDEX IDX_STTR_TERM ON bu_ire.WAREHOUSE_STUDENT_POPULATION (STTR_TERM);
CREATE INDEX IDX_STTR_ACAD_LEVEL ON bu_ire.WAREHOUSE_STUDENT_POPULATION (STTR_ACAD_LEVEL);


/*	Rebuild data in table */
;WITH POPULATION_CTE AS
	(
		SELECT
			STUDENT_TERMS_ID
			, STTR_STUDENT
			, STTR_TERM
			, STTR_ACAD_LEVEL
			, STUDENT_TYPE
			, COHORT
			, TERM_SEASON
			, T1.TERM_REPORTING_YEAR AS TERM_RPT_YR
			, T1.B13_TERM_SEQUENCE_NO AS TERM_SEQ_NO
			, TERM_RANK
			, MATRIC_TERM
			, MATRIC_TERM_SEASON
			, T2.TERM_REPORTING_YEAR AS MATRIC_TERM_RPT_YR
			, T2.B13_TERM_SEQUENCE_NO AS MATRIC_TERM_SEQ_NO

		FROM
			(
				SELECT
					STUDENT_TERMS_ID
					, STTR_STUDENT
					, STTR_TERM
					, STTR_ACAD_LEVEL
					, CASE
							WHEN DS_STATUS = 'NDS' AND STTR_ACAD_LEVEL = 'UG' THEN 'Undergraduate Non-Degree Seeking'
							WHEN DS_STATUS = 'NDS' AND STTR_ACAD_LEVEL = 'GR' THEN 'Graduate Non-Degree Seeking'
							WHEN DS_STATUS = 'DS' AND STTR_ACAD_LEVEL = 'UG' AND (LEFT(COHORT,1) IN ('F', 'P') OR (RIGHT(COHORT,1) IN ('F', 'P') AND NOT(SUBSTRING(COHORT,4,1) = 'S')) OR APPL_ADMIT_STATUS IN ('FF', 'FN')) THEN 'FTIAC'
							WHEN DS_STATUS = 'DS' AND STTR_ACAD_LEVEL = 'UG' AND (LEFT(COHORT,1) = 'T' OR APPL_ADMIT_STATUS = 'TR') THEN 'Transfer'
							WHEN DS_STATUS = 'DS' AND STTR_ACAD_LEVEL = 'UG' AND LEFT(COHORT,1) = 'C' THEN 'Certificate'
							WHEN DS_STATUS = 'DS' AND STTR_ACAD_LEVEL = 'UG' AND (LEFT(COHORT,1) = 'B' OR APPL_ADMIT_STATUS = 'PB') THEN 'Post-Baccalaureate'
							WHEN DS_STATUS = 'NDS' AND STTR_ACAD_LEVEL = 'UG' AND LEFT(COHORT,1) = 'H' THEN 'High School'
							WHEN DS_STATUS = 'DS' AND STTR_ACAD_LEVEL = 'UG' THEN 'Undergraduate Degree-Seeking'
							WHEN DS_STATUS = 'DS' AND (APPL_ADMIT_STATUS = 'GR' OR STTR_ACAD_LEVEL = 'GR') THEN 'Graduate Degree-Seeking'
							ELSE NULL
						END AS STUDENT_TYPE
					, COHORT, APPL_ADMIT_STATUS
					, CASE RIGHT(STTR_TERM,2)
							WHEN 'FA' THEN 'Fall'
							WHEN 'SP' THEN 'Spring'
							WHEN 'SU' THEN 'Summer'
						END AS TERM_SEASON
					, TERM_RANK
					, MATRIC_TERM
					, CASE RIGHT(MATRIC_TERM,2)
							WHEN 'FA' THEN 'Fall'
							WHEN 'SP' THEN 'Spring'
							WHEN 'SU' THEN 'Summer'
						END AS MATRIC_TERM_SEASON

				FROM
					(
						SELECT
							STUDENT_TERMS_ID
							, STTR_STUDENT
							, STTR_TERM
							, STTR_ACAD_LEVEL
							, TERM_RPT_YR
							, TERM_SEQ_NO
							, DS_STATUS
							, MAJOR1
							, COALESCE(COHORT
									, CASE
											WHEN TERM_START_DATE >= GETDATE()
												AND LAG(STTR_STUDENT,1) OVER(ORDER BY STTR_STUDENT, TERM_RPT_YR, TERM_SEQ_NO) = STTR_STUDENT
												AND LAG(STTR_ACAD_LEVEL,1) OVER(ORDER BY STTR_STUDENT, TERM_RPT_YR, TERM_SEQ_NO) = STTR_ACAD_LEVEL
													THEN LAG(COHORT,1) OVER(ORDER BY STTR_STUDENT, TERM_RPT_YR, TERM_SEQ_NO)
										END)
								AS COHORT
							, EARLIEST_MATRIC_TERM
							, APPL_ACAD_LEVEL
							, APPL_START_TERM
							, APPL_ADMIT_STATUS
							, FIRST_ENR_TERM_UG
							, FIRST_ENR_TERM_GR
							, COALESCE(MATRIC_TERM, LAG(MATRIC_TERM,1) OVER(ORDER BY STTR_STUDENT, TERM_RPT_YR, TERM_SEQ_NO)) AS MATRIC_TERM
							, ROW_NUMBER() OVER(PARTITION BY STTR_STUDENT ORDER BY TERM_RPT_YR, TERM_SEQ_NO) AS TERM_RANK
						
						FROM
							(
								SELECT *
									, CASE
											WHEN APPL_START_TERM IS NOT NULL THEN APPL_START_TERM
											WHEN STTR_ACAD_LEVEL = 'UG' AND LEN(UG_COHORT) = 5 THEN EARLIEST_MATRIC_TERM
											WHEN STTR_ACAD_LEVEL = 'UG' AND COHORT IS NOT NULL THEN COHORT_MATRIC_TERM
											WHEN TERM_START_DATE >= GETDATE() AND LAG(STTR_STUDENT,1) OVER(ORDER BY STTR_STUDENT, TERM_RPT_YR, TERM_SEQ_NO) = STTR_STUDENT
												AND STTR_ACAD_LEVEL = 'UG' AND LAG(STTR_ACAD_LEVEL,1) OVER(ORDER BY STTR_STUDENT, TERM_RPT_YR, TERM_SEQ_NO) = 'UG' /* only works for UG cohorts right now */
													THEN COALESCE(LAG(COHORT_MATRIC_TERM,1) OVER(ORDER BY STTR_STUDENT, TERM_RPT_YR, TERM_SEQ_NO), LAG(EARLIEST_MATRIC_TERM,1) OVER(ORDER BY STTR_STUDENT, TERM_RPT_YR, TERM_SEQ_NO))
											WHEN STTR_ACAD_LEVEL = 'UG' AND FIRST_ENR_TERM_UG IS NOT NULL THEN FIRST_ENR_TERM_UG
											WHEN STTR_ACAD_LEVEL = 'GR' AND FIRST_ENR_TERM_GR IS NOT NULL THEN FIRST_ENR_TERM_GR
											ELSE NULL
										END AS MATRIC_TERM
										
								FROM
									(
										SELECT
											STUDENT_TERMS_ID
											, STTR_STUDENT
											, STTR_TERM
											, STTR_ACAD_LEVEL
											, TERM_RPT_YR
											, TERM_SEQ_NO
											, TERM_START_DATE
											, DS_STATUS
											, MAX(MAJOR1) AS MAJOR1
											, MAX(COHORT) AS COHORT
											, MAX(COHORT_MATRIC_TERM) AS COHORT_MATRIC_TERM
											, UG_COHORT
											, EARLIEST_MATRIC_TERM
											, APPL_ACAD_LEVEL
											, APPL_START_TERM
											, APPL_ADMIT_STATUS
											, FIRST_ENR_TERM_UG
											, FIRST_ENR_TERM_GR

										FROM
											(
												SELECT DISTINCT
													ST.STUDENT_TERMS_ID
													, ST.STTR_STUDENT
													, ST.STTR_TERM
													, ST.STTR_ACAD_LEVEL
													, T.TERM_RPT_YR_NUMERIC AS TERM_RPT_YR
													, T.TERM_SEQ_NO
													, T.TERM_START_DATE
													, CASE
															WHEN COALESCE(LEFT(SS.PROG1,2), LEFT(CS.PROG1,2), LEFT(P.STPR_ACAD_PROGRAM,2)) = 'XD' THEN 'NDS'
															WHEN P.P_DS_STATUS = 'DS' THEN 'DS'
															WHEN P.P_DS_STATUS = 'NDS' THEN 'NDS'
															ELSE 'DS'
														END AS DS_STATUS
													, COALESCE(SS.MAJOR1, CS.MAJOR1, P.MAJOR, CASE
															WHEN LAG(ST.STTR_STUDENT,1) OVER(ORDER BY ST.STTR_STUDENT, T.TERM_RPT_YR_NUMERIC, T.TERM_SEQ_NO) = ST.STTR_STUDENT
																AND LAG(ST.STTR_TERM,1) OVER(ORDER BY ST.STTR_STUDENT, T.TERM_RPT_YR_NUMERIC, T.TERM_SEQ_NO) = ST.STTR_TERM
																AND LAG(ST.STTR_ACAD_LEVEL,1) OVER(ORDER BY ST.STTR_STUDENT, T.TERM_RPT_YR_NUMERIC, T.TERM_SEQ_NO) = ST.STTR_ACAD_LEVEL
																AND COALESCE(LEFT(SS.PROG1,2), LEFT(CS.PROG1,2), LEFT(P.STPR_ACAD_PROGRAM,2), 'XD') <> 'XD'
																	THEN LAG(CS.MAJOR1,1) OVER(ORDER BY ST.STTR_STUDENT, T.TERM_RPT_YR_NUMERIC, T.TERM_SEQ_NO)
															WHEN LAG(ST.STTR_STUDENT,1) OVER(ORDER BY ST.STTR_STUDENT, T.TERM_RPT_YR_NUMERIC, T.TERM_SEQ_NO) = ST.STTR_STUDENT
																AND COALESCE(LEFT(SS.PROG1,2), LEFT(CS.PROG1,2), LEFT(P.STPR_ACAD_PROGRAM,2), 'XD') <> 'XD'
																	THEN LAG(CS.MAJOR1,1) OVER(ORDER BY ST.STTR_STUDENT, T.TERM_RPT_YR_NUMERIC, T.TERM_SEQ_NO)
															WHEN LAG(ST.STTR_STUDENT,1) OVER(ORDER BY ST.STTR_STUDENT, T.TERM_RPT_YR_NUMERIC, T.TERM_SEQ_NO) = ST.STTR_STUDENT
																AND LAG(ST.STTR_ACAD_LEVEL,1) OVER(ORDER BY ST.STTR_STUDENT, T.TERM_RPT_YR_NUMERIC, T.TERM_SEQ_NO) = ST.STTR_ACAD_LEVEL
																AND SS.MAJOR1 IS NULL
																	THEN LAG(CS.MAJOR1,1) OVER(ORDER BY ST.STTR_STUDENT, T.TERM_RPT_YR_NUMERIC, T.TERM_SEQ_NO)
														END) AS MAJOR1
													, CASE
															WHEN UG_COHORT IS NULL THEN NULL
															ELSE COALESCE(CS.COHORT, CASE
																WHEN LAG(ST.STTR_STUDENT,1) OVER(ORDER BY ST.STTR_STUDENT, T.TERM_RPT_YR_NUMERIC, T.TERM_SEQ_NO) = ST.STTR_STUDENT
																	AND LAG(ST.STTR_TERM,1) OVER(ORDER BY ST.STTR_STUDENT, T.TERM_RPT_YR_NUMERIC, T.TERM_SEQ_NO) = ST.STTR_TERM
																	AND LAG(ST.STTR_ACAD_LEVEL,1) OVER(ORDER BY ST.STTR_STUDENT, T.TERM_RPT_YR_NUMERIC, T.TERM_SEQ_NO) = ST.STTR_ACAD_LEVEL
																	AND COALESCE(LEFT(SS.PROG1,2), LEFT(CS.PROG1,2), LEFT(P.STPR_ACAD_PROGRAM,2), 'XD') <> 'XD'
																		THEN LAG(CS.COHORT,1) OVER(ORDER BY ST.STTR_STUDENT, T.TERM_RPT_YR_NUMERIC, T.TERM_SEQ_NO)
																WHEN LAG(ST.STTR_STUDENT,1) OVER(ORDER BY ST.STTR_STUDENT, T.TERM_RPT_YR_NUMERIC, T.TERM_SEQ_NO) = ST.STTR_STUDENT
																	AND COALESCE(LEFT(SS.PROG1,2), LEFT(CS.PROG1,2), LEFT(P.STPR_ACAD_PROGRAM,2), 'XD') <> 'XD'
																		THEN LAG(CS.COHORT,1) OVER(ORDER BY ST.STTR_STUDENT, T.TERM_RPT_YR_NUMERIC, T.TERM_SEQ_NO)
																WHEN LAG(ST.STTR_STUDENT,1) OVER(ORDER BY ST.STTR_STUDENT, T.TERM_RPT_YR_NUMERIC, T.TERM_SEQ_NO) = ST.STTR_STUDENT
																	AND LAG(ST.STTR_ACAD_LEVEL,1) OVER(ORDER BY ST.STTR_STUDENT, T.TERM_RPT_YR_NUMERIC, T.TERM_SEQ_NO) = ST.STTR_ACAD_LEVEL
																	AND SS.MAJOR1 IS NULL
																		THEN LAG(CS.COHORT,1) OVER(ORDER BY ST.STTR_STUDENT, T.TERM_RPT_YR_NUMERIC, T.TERM_SEQ_NO)
																END)
														END AS COHORT
													, CASE
															WHEN UG_COHORT IS NULL THEN NULL
															ELSE COALESCE(CS.COHORT_MATRIC_TERM, CASE
																WHEN LAG(ST.STTR_STUDENT,1) OVER(ORDER BY ST.STTR_STUDENT, T.TERM_RPT_YR_NUMERIC, T.TERM_SEQ_NO) = ST.STTR_STUDENT
																	AND LAG(ST.STTR_TERM,1) OVER(ORDER BY ST.STTR_STUDENT, T.TERM_RPT_YR_NUMERIC, T.TERM_SEQ_NO) = ST.STTR_TERM
																	AND LAG(ST.STTR_ACAD_LEVEL,1) OVER(ORDER BY ST.STTR_STUDENT, T.TERM_RPT_YR_NUMERIC, T.TERM_SEQ_NO) = ST.STTR_ACAD_LEVEL
																	AND COALESCE(LEFT(SS.PROG1,2), LEFT(CS.PROG1,2), LEFT(P.STPR_ACAD_PROGRAM,2), 'XD') <> 'XD'
																		THEN LAG(CS.COHORT_MATRIC_TERM,1) OVER(ORDER BY ST.STTR_STUDENT, T.TERM_RPT_YR_NUMERIC, T.TERM_SEQ_NO)
																WHEN LAG(ST.STTR_STUDENT,1) OVER(ORDER BY ST.STTR_STUDENT, T.TERM_RPT_YR_NUMERIC, T.TERM_SEQ_NO) = ST.STTR_STUDENT
																	AND COALESCE(LEFT(SS.PROG1,2), LEFT(CS.PROG1,2), LEFT(P.STPR_ACAD_PROGRAM,2), 'XD') <> 'XD'
																		THEN LAG(CS.COHORT_MATRIC_TERM,1) OVER(ORDER BY ST.STTR_STUDENT, T.TERM_RPT_YR_NUMERIC, T.TERM_SEQ_NO)
																WHEN LAG(ST.STTR_STUDENT,1) OVER(ORDER BY ST.STTR_STUDENT, T.TERM_RPT_YR_NUMERIC, T.TERM_SEQ_NO) = ST.STTR_STUDENT
																	AND LAG(ST.STTR_ACAD_LEVEL,1) OVER(ORDER BY ST.STTR_STUDENT, T.TERM_RPT_YR_NUMERIC, T.TERM_SEQ_NO) = ST.STTR_ACAD_LEVEL
																	AND SS.MAJOR1 IS NULL
																		THEN LAG(CS.COHORT_MATRIC_TERM,1) OVER(ORDER BY ST.STTR_STUDENT, T.TERM_RPT_YR_NUMERIC, T.TERM_SEQ_NO)
															END)
														END AS COHORT_MATRIC_TERM
													, L.UG_COHORT
													, L.EARLIEST_MATRIC_TERM
													, A.APPL_ACAD_LEVEL
													, A.APPL_START_TERM
													, A.APPL_ADMIT_STATUS
													, F.FIRST_ENR_TERM_UG
													, F.FIRST_ENR_TERM_GR

												FROM
													bu_ire.WAREHOUSE_STTR_STATUSES ST
													JOIN bu_ire.TERM_DATES_CTE T ON ST.STTR_TERM=T.TERM
													LEFT OUTER JOIN B13_ACTIVE_ACAD_LEVELS_FLAT L ON ST.STTR_STUDENT=L.STA_STUDENT AND ST.STTR_ACAD_LEVEL='UG'
													LEFT OUTER JOIN bu_ire.CENSUS_SNAPSHOT CS ON ST.STTR_STUDENT=CS.STU_ID AND ST.STTR_ACAD_LEVEL=CS.PRI_ACAD_LEVEL AND ST.STTR_TERM=CS.TERM
													LEFT OUTER JOIN bu_ire.STUDENT_SNAPSHOT SS ON ST.STTR_STUDENT=SS.ID AND ST.STTR_ACAD_LEVEL=SS.ACAD_LEVEL AND ST.STTR_TERM=SS.TERM
													LEFT OUTER JOIN
														(
															SELECT STUDENT_PROGRAMS_ID, STPR_STUDENT, STPR_ACAD_PROGRAM, STPR_ACAD_LEVEL, MAJOR, P_DS_STATUS
															FROM
																(
																	SELECT P.STUDENT_PROGRAMS_ID, P.STPR_STUDENT, P.STPR_ACAD_PROGRAM, P.STPR_ACAD_LEVEL, PM.MAJOR
																		, CASE LEFT(P.STPR_ACAD_PROGRAM,3)
																				WHEN 'DR.' THEN 'DS'
																				WHEN 'GR.' THEN 'DS'
																				WHEN 'UG.' THEN 'DS'
																				ELSE 'NDS'
																			END AS P_DS_STATUS
																		, ROW_NUMBER() OVER(PARTITION BY P.STPR_STUDENT, P.STPR_ACAD_LEVEL
																				ORDER BY CASE
																					WHEN LEFT(P.STPR_ACAD_PROGRAM,5) = 'XD.CE' THEN 0
																					WHEN LEFT(P.STPR_ACAD_PROGRAM,5) = 'XD.UG' THEN 1
																					WHEN LEFT(P.STPR_ACAD_PROGRAM,5) = 'XD.GR' THEN 2
																					WHEN A.ACPG_DEGREE = 'CERT' THEN 3
																					WHEN LEFT(P.STPR_ACAD_PROGRAM,2) = 'UG' THEN 4
																					WHEN LEFT(P.STPR_ACAD_PROGRAM,2) IN ('DR', 'GR') THEN 5
																					ELSE 0
																				END DESC,
																			CONVERT(DATE,P.START_DATE,112) ASC
																		) AS PRGM_RANK
																	FROM ODS_STUDENT_PROGRAMS P JOIN ODS_STUDENT_PROGRAM_MAJORS PM ON P.STUDENT_PROGRAMS_ID=PM.STUDENT_PROGRAMS_ID AND PM.POS=1 JOIN ODS_ACAD_PROGRAMS A ON P.STPR_ACAD_PROGRAM=A.ACAD_PROGRAMS_ID
																	WHERE P.STPR_CURRENT_STATUS = 'A' AND (P.END_DATE > GETDATE() OR P.END_DATE IS NULL)
																) P1
															WHERE PRGM_RANK = 1
														) P ON ST.STTR_STUDENT=P.STPR_STUDENT AND ST.STTR_ACAD_LEVEL=P.STPR_ACAD_LEVEL
													LEFT OUTER JOIN ODS_STUDENT_PROGRAM_MAJORS PM ON ST.STTR_STUDENT=PM.STPR_STUDENT AND ST.STTR_ACAD_LEVEL=PM.STPR_ACAD_LEVEL AND PM.POS=1
													LEFT OUTER JOIN
														(
															SELECT APPL_APPLICANT, APPL_START_TERM, APPL_ACAD_LEVEL, APPL_ADMIT_STATUS
															FROM
																(
																	SELECT A.APPL_APPLICANT, A.APPL_START_TERM, A.B13_APPL_ACAD_LEVEL AS APPL_ACAD_LEVEL, A.APPL_ADMIT_STATUS, ROW_NUMBER() OVER(PARTITION BY A.APPL_APPLICANT, A.APPL_START_TERM, A.B13_APPL_ACAD_LEVEL ORDER BY A.APPL_ADMIT_STATUS) AS APPL_RANK
																	FROM ODS_APPLICATIONS A
																	WHERE A.APPL_CURRENT_STATUS IN ('MS', 'CNF', 'CNFC', 'CNFN') AND A.APPL_ADMIT_STATUS <> 'RA'
																) A1
															WHERE APPL_RANK = 1
														) A ON ST.STTR_STUDENT=A.APPL_APPLICANT AND ST.STTR_TERM=A.APPL_START_TERM AND ST.STTR_ACAD_LEVEL=A.APPL_ACAD_LEVEL
													LEFT OUTER JOIN B13_FIRST_ENR_TERM F ON ST.STTR_STUDENT=F.STUDENT_ID
											) C5
										GROUP BY STUDENT_TERMS_ID, STTR_STUDENT, STTR_TERM, STTR_ACAD_LEVEL, TERM_RPT_YR, TERM_SEQ_NO, TERM_START_DATE, DS_STATUS, UG_COHORT, EARLIEST_MATRIC_TERM, APPL_ACAD_LEVEL, APPL_START_TERM, APPL_ADMIT_STATUS, FIRST_ENR_TERM_UG, FIRST_ENR_TERM_GR
									) C4
							) C3
					) C2
			) C1
		LEFT OUTER JOIN ODS_TERMS T1 ON STTR_TERM=T1.TERMS_ID
		LEFT OUTER JOIN ODS_TERMS T2 ON MATRIC_TERM=T2.TERMS_ID
	)

/* uncomment the line below to copy & paste into SQL Server Agent */
INSERT INTO bu_ire.WAREHOUSE_STUDENT_POPULATION

SELECT *, GETDATE() AS UPDATE_DATE
FROM POPULATION_CTE
ORDER BY STTR_STUDENT, STTR_ACAD_LEVEL DESC, TERM_RPT_YR, TERM_SEQ_NO
OPTION (MAXRECURSION 1000)

/*	Confirm data loaded correctly */
SELECT *
FROM bu_ire.WAREHOUSE_STUDENT_POPULATION
WHERE STTR_STUDENT IN (1147177, 2086033, 53454, 34)
ORDER BY 2, 4 DESC, 8, 9


/*	Revision history:
		JDT 6/17/2020: Updated column names based on changes to the STUDENT_SNAPSHOT and CENSUS_SNAPSHOT tables.
		JDT 4/29/2020: Troubleshooting cohort codes that would propagate across academic levels; added logic to include most recent major persists when there is no snapshot data,
				as I already did for cohort and cohort matriculation term in the 1/9/2020 update.
		JDT 3/16/2020: Updated column names from B13_FIRST_ENR_TERM.
		JDT 1/9/2020: Troubleshooting to ensure cohort data persists for students when there is no census snapshot data yet.
		JDT 1/3/2020: Revised matriculation term logic to avoid null data on future terms.
		JDT 12/2/2019: Updated column definitions to align with other files used in the student enrollment comparisons project.
		JDT 11/26/2019: Created file.
*/