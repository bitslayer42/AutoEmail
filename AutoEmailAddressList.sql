ALTER VIEW AutoEmailAddressList AS
-- select * from AutoEmailAddressList
	SELECT ListName, Full_Name,   
	IIF(JobTitles.OfficePosition=1,'All','') AS [ALL],
	grp.dealershipGroup AS GRP,
	dlr.dealership AS DLR,
	MIN(NotificationListEmailGroups.JobTitle) JobTitle
	FROM NotificationListEmailGroups
	INNER JOIN JobTitles
	ON NotificationListEmailGroups.JobTitle = JobTitles.JobTitle
	INNER JOIN employees
	ON employees.JobTitles like '%'+NotificationListEmailGroups.JobTitle+'%'
	LEFT JOIN dealership dlr
	ON employees.Dealerships = dlr.dealership
	LEFT JOIN dealership grp
	ON employees.Dealerships = grp.dealershipGroupName
	WHERE employees.TermDate IS NULL
	AND employees.EmplEMail <> ''
	AND (dlr.dealership IS NOT NULL OR grp.dealershipGroupName IS NOT NULL OR JobTitles.OfficePosition=1)
	GROUP BY ListName, Full_Name,   
	IIF(JobTitles.OfficePosition=1,'All',''),
	grp.dealershipGroup,
	dlr.dealership
	--ORDER BY ListName, Full_Name