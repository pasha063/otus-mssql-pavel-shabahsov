declare @in varchar(250);
set @in = 'bcp MerchReports.ref.tbl_date IN "D:\courses\OTUS\MerchProject\tbl_Date.txt" -T -c -C 65001 -S ' + @@SERVERNAME;
EXEC master..xp_cmdshell @in

set @in = 'bcp MerchReports.ref.tbl_RetailChain IN "D:\courses\OTUS\MerchProject\tbl_RetailChain.txt" -T -c -C 65001 -S ' + @@SERVERNAME;
exec master..xp_cmdshell @in

set @in = 'bcp MerchReports.ref.tbl_Outlets IN "D:\courses\OTUS\MerchProject\tbl_Outlets.txt" -T -c -C 65001 -S ' + @@SERVERNAME;
exec master..xp_cmdshell @in

set @in = 'bcp MerchReports.ref.tbl_Positions IN "D:\courses\OTUS\MerchProject\tbl_Positions.txt" -T -c -C 65001 -S ' + @@SERVERNAME;
exec master..xp_cmdshell @in

set @in = 'bcp MerchReports.ref.tbl_DailyCalcConfig IN "D:\courses\OTUS\MerchProject\tbl_DailyCalcConfig.txt" -T -c -C 65001 -S ' + @@SERVERNAME;
exec master..xp_cmdshell @in

set @in = 'bcp MerchReports.ref.tbl_MerchCalendar IN "D:\courses\OTUS\MerchProject\tbl_MerchCalendar.txt" -T -c -C 65001 -S ' + @@SERVERNAME;
exec master..xp_cmdshell @in

set @in = 'bcp MerchReports.ref.tbl_MerchKPI IN "D:\courses\OTUS\MerchProject\tbl_MerchKPI.txt" -T -c -C 65001 -S ' + @@SERVERNAME;
exec master..xp_cmdshell @in

set @in = 'bcp MerchReports.ref.tbl_MerchKPIGrades IN "D:\courses\OTUS\MerchProject\tbl_MerchKPIGrades.txt" -T -c -C 65001 -S ' + @@SERVERNAME;
exec master..xp_cmdshell @in

set @in = 'bcp MerchReports.ref.tbl_MerchBaseCity IN "D:\courses\OTUS\MerchProject\tbl_MerchBaseCity.txt" -T -c -C 65001 -S ' + @@SERVERNAME;
exec master..xp_cmdshell @in

set @in = 'bcp MerchReports.merch.tbl_Visits IN "D:\courses\OTUS\MerchProject\tbl_Visits.txt" -T -c -C 65001 -S ' + @@SERVERNAME;
exec master..xp_cmdshell @in

set @in = 'bcp MerchReports.merch.tbl_SurveyFact IN "D:\courses\OTUS\MerchProject\tbl_SurveyFact.txt" -T -c -C 65001 -S ' + @@SERVERNAME;
exec master..xp_cmdshell @in

set @in = 'bcp MerchReports.merch.tbl_AgencyRates IN "D:\courses\OTUS\MerchProject\tbl_AgencyRates.txt" -T -c -C 65001 -S ' + @@SERVERNAME;
exec master..xp_cmdshell @in

set @in = 'bcp MerchReports.merch.tbl_AuditCoefficient IN "D:\courses\OTUS\MerchProject\tbl_AuditCoefficient.txt" -T -c -C 65001 -S ' + @@SERVERNAME;
exec master..xp_cmdshell @in

set @in = 'bcp MerchReports.merch.tbl_CityRates IN "D:\courses\OTUS\MerchProject\tbl_CityRates.txt" -T -c -C 65001 -S ' + @@SERVERNAME;
exec master..xp_cmdshell @in

set @in = 'bcp MerchReports.merch.tbl_DigitalAuditFact IN "D:\courses\OTUS\MerchProject\tbl_DigitalAuditFact.txt" -T -c -C 65001 -S ' + @@SERVERNAME;
exec master..xp_cmdshell @in

set @in = 'bcp MerchReports.merch.tbl_POSPlan IN "D:\courses\OTUS\MerchProject\tbl_POSPlan.txt" -T -c -C 65001 -S ' + @@SERVERNAME;
exec master..xp_cmdshell @in

set @in = 'bcp MerchReports.merch.tbl_VisitOrder IN "D:\courses\OTUS\MerchProject\tbl_VisitOrder.txt" -T -c -C 65001 -S ' + @@SERVERNAME;
exec master..xp_cmdshell @in

set @in = 'bcp MerchReports.kpi.tbl_OSA IN "D:\courses\OTUS\MerchProject\tbl_OSA.txt" -T -c -C 65001 -S ' + @@SERVERNAME;
exec master..xp_cmdshell @in

set @in = 'bcp MerchReports.kpi.tbl_SP IN "D:\courses\OTUS\MerchProject\tbl_SP.txt" -T -c -C 65001 -S ' + @@SERVERNAME;
exec master..xp_cmdshell @in

set @in = 'bcp MerchReports.kpi.tbl_WorkingDaysReport IN "D:\courses\OTUS\MerchProject\tbl_WorkingDaysReport.txt" -T -c -C 65001 -S ' + @@SERVERNAME;
exec master..xp_cmdshell @in