-- создадим файловую группу
alter database MerchReports add filegroup YearMonth

-- добавляем файл БД
alter database MerchReports add file
( name = N'YearMonth', filename = N'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER01\MSSQL\DATA\YearMonthdata.ndf' ,
size = 1097152KB , filegrowth = 65536KB ) to filegroup YearMonth

-- граничные точки
create partition function fnYearMonthPartition(int)
as
	range right for values (20250601, 20250701, 20250801, 20250901, 20251001, 20251101, 20251201)

-- расположение секций
create partition scheme schmYearMonthPartition
as
	partition fnYearMonthPartition all to (YearMonth)

-- создаем таблицу для секционированния
create table merch.tbl_Visits_Partitioned(
	SK_Visit_ID bigint not null,
	SK_Date_ID int not null,
	SK_Outlet_ID bigint not null,
	SK_Position_ID bigint not null,
	SK_Time_ID_Start int not null,
	SK_Time_ID_End int not null,
	VisitTimeSec int not null,
	PhotoFileName nvarchar(max) null,
) on schmYearMonthPartition(SK_Date_ID)

--создадим кластерный индекс в той же схеме с ключом секционирования
alter table merch.tbl_Visits_Partitioned add constraint PK_ref_tbl_Visits_Partitioned primary key clustered (SK_Date_ID, SK_Visit_ID) on schmYearMonthPartition(SK_Date_ID)
alter table merch.tbl_Visits_Partitioned with nocheck add constraint FK_tbl_Visits_Partitioned_SK_Date_ID_tbl_Date FOREIGN KEY(SK_Date_ID) references ref.tbl_Date (ID)
alter table merch.tbl_Visits_Partitioned check constraint FK_tbl_Visits_Partitioned_SK_Date_ID_tbl_Date
alter table merch.tbl_Visits_Partitioned with nocheck add constraint FK_tbl_Visits_Partitioned_SK_Outlet_ID_tbl_Outlets FOREIGN KEY(SK_Outlet_ID) references ref.tbl_Outlets (SK_Outlet_ID)
alter table merch.tbl_Visits_Partitioned check constraint FK_tbl_Visits_Partitioned_SK_Outlet_ID_tbl_Outlets
alter table merch.tbl_Visits_Partitioned with nocheck add constraint FK_tbl_Visits_Partitioned_SK_Position_ID_tbl_Positions FOREIGN KEY(SK_Position_ID) references ref.tbl_Positions (SK_Position_ID)
alter table merch.tbl_Visits_Partitioned check constraint FK_tbl_Visits_Partitioned_SK_Position_ID_tbl_Positions

insert into merch.tbl_Visits_Partitioned (
	SK_Visit_ID
	,SK_Date_ID
	,SK_Outlet_ID
	,SK_Position_ID
	,SK_Time_ID_Start
	,SK_Time_ID_End
	,VisitTimeSec
	,PhotoFileName
)
select
	SK_Visit_ID
	,SK_Date_ID
	,SK_Outlet_ID
	,SK_Position_ID
	,SK_Time_ID_Start
	,SK_Time_ID_End
	,VisitTimeSec
	,PhotoFileName
from merch.tbl_Visits
