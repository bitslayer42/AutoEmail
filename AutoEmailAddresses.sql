go
ALTER FUNCTION AutoEmailAddresses(@ListName NVARCHAR(50))
--called from AutoEmailsSend: Given ListName, return email recipients by GRP(Dealership Group), DLR(Dealership), or ALL in table 

-- NOTE: Can be one dealership or a group or [ALL]
RETURNS TABLE 
AS
RETURN ( 

WITH Emails AS (
		SELECT DISTINCT RTRIM(EmplEMail) Email,   -- NotificationListEmailGroups.JobTitle, JobTitles.JobTitle,employees.JobTitles ,NotificationListEmailGroups.JobTitle,
		IIF(JobTitles.OfficePosition=1,1,0) AS [ALL],
		grp.dealershipGroup AS GRP,
		dlr.dealership AS DLR
		FROM NotificationListEmailGroups
		INNER JOIN JobTitles
		ON NotificationListEmailGroups.JobTitle = JobTitles.JobTitle
		INNER JOIN employees
		ON employees.JobTitles like '%'+NotificationListEmailGroups.JobTitle+'%'
		LEFT JOIN dealership dlr
		ON employees.Dealerships = dlr.dealership
		LEFT JOIN dealership grp
		ON employees.Dealerships = grp.dealershipGroupName
		WHERE NotificationListEmailGroups.ListName = @ListName
		AND (employees.TermDate IS NULL)
		AND employees.EmplEMail <> ''
		AND (dlr.dealership IS NOT NULL OR grp.dealershipGroupName IS NOT NULL OR JobTitles.OfficePosition=1)
)
--select * from Emails
SELECT [ALL],GRP, DLR, AddressList = STUFF
(
    (
        SELECT ';' + Email
        FROM Emails As T2
        WHERE ISNULL(T2.[ALL],'') = ISNULL(T1.[ALL],'')
		AND   ISNULL(T2.GRP,'') = ISNULL(T1.GRP,'')
		AND   ISNULL(T2.DLR,'') = ISNULL(T1.DLR,'')
        ORDER BY Email
        FOR XML PATH (''), TYPE
    ).value('.', 'NVARCHAR(max)')
, 1, 1, '')
FROM Emails As T1
GROUP BY [ALL], GRP, DLR
)



