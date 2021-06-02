# enrollment-comps-YOY
A set of SQL views designed to surface historic and ongoing enrollment data and transform it into year-over-year, point-in-time headcount and student credit hour trend data for higher education institutional research and effectiveness analysis.

Current run order in SQL Server Agent is as follows:
1. Delete/Rebuild Term Dates CTE Table (bu_ire.TERM_DATES_CTE)
2. Delete/Rebuild Term Subsession Dates CTE Table (bu_ire.TERM_SUB_DATES_CTE)
3. Delete/Rebuild Cohort Counts Warehouse Table (bu_ire.WAREHOUSE_COHORT_COUNTS)
4. Delete/Rebuild STC Status Warehouse Table (bu_ire.WAREHOUSE_STC_STATUSES)
5. Delete/Rebuild STTR Status Warehouse Table (bu_ire.WAREHOUSE_STTR_STATUSES)
6. Delete/Rebuild Student Population Warehouse Table (bu_ire.WAREHOUSE_STUDENT_POPULATION)
7. Delete/Rebuild Raw Student Enrollment YTD Table (bu_ire.STUDENT_ENROLLMENT_YTD)
8. Delete/Rebuild Student Enrollment Comps (Single Day) Table (bu_ire.STUDENT_ENROLLMENT_COMPS)
9. Delete/Rebuild Weekly Withdrawn Students Table (bu_ire.WEEKLY_WITHDRAWN_STUDENTS)
10. Add New Rows to Daily Enrollment Activity Table (bu_ire.DAILY_ENROLLMENT_ACTIVITY)
11. Add New Rows to Daily Enrollment Activity Report Table (bu_ire.DAILY_ENROLLMENT_REPORT)
12. Delete Old Rows from Daily Enrollment Activity Table
13. Delete/Rebuild Enrollment Statistics Table (bu_ire.WAREHOUSE_ENR_STATS)
14. Delete/Rebuild Student Enrollment Comps (All Days) Table (bu_ire.STUDENT_ENROLLMENT_COMPS_ALL)
