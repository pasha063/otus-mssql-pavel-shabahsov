/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "10 - Операторы изменения данных".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/

insert into Sales.Customers (
	CustomerID
	,CustomerName
	,BillToCustomerID
	,CustomerCategoryID
	,BuyingGroupID
	,PrimaryContactPersonID
	,AlternateContactPersonID
	,DeliveryMethodID
	,DeliveryCityID
	,PostalCityID
	,CreditLimit
	,AccountOpenedDate
	,StandardDiscountPercentage
	,IsStatementSent
	,IsOnCreditHold
	,PaymentDays
	,PhoneNumber
	,FaxNumber
	,DeliveryRun
	,RunPosition
	,WebsiteURL
	,DeliveryAddressLine1
	,DeliveryAddressLine2
	,DeliveryPostalCode
	--,DeliveryLocation
	,PostalAddressLine1
	,PostalAddressLine2
	,PostalPostalCode
	,LastEditedBy
	--,ValidFrom
	--,ValidTo
)
values
	(1062, 'xxx', 1062, 5, null, 3261, null, 3, 19881, 19881, 1500, '2016-05-07', 0, 0, 0, 7, '(xxx) xxx-xxxx', '(xxx) xxx-xxxx', null, null, 'xxx', 'xxx', 'xxx', 'xxx', 'xxx', 'xxx', 'xxx', 1)
	,(1063, 'yyy', 1063, 5, null, 3261, null, 3, 19881, 19881, 1500, '2016-05-07', 0, 0, 0, 7, '(yyy) yyy-yyyy', '(yyy) yyy-yyyy', null, null, 'yyy', 'yyy', 'yyy', 'yyy', 'yyy', 'yyy', 'yyy', 1)
	,(1064, 'zzz', 1064, 5, null, 3261, null, 3, 19881, 19881, 1500, '2016-05-07', 0, 0, 0, 7, '(zzz) zzz-zzzz', '(zzz) zzz-zzzz', null, null, 'zzz', 'zzz', 'zzz', 'zzz', 'zzz', 'zzz', 'zzz', 1)
	,(1065, 'aaa', 1065, 5, null, 3261, null, 3, 19881, 19881, 1500, '2016-05-07', 0, 0, 0, 7, '(aaa) aaa-aaaa', '(aaa) aaa-aaaa', null, null, 'aaa', 'aaa', 'aaa', 'aaa', 'aaa', 'aaa', 'aaa', 1)
	,(1066, 'bbb', 1066, 5, null, 3261, null, 3, 19881, 19881, 1500, '2016-05-07', 0, 0, 0, 7, '(bbb) bbb-bbbb', '(bbb) bbb-bbbb', null, null, 'bbb', 'bbb', 'bbb', 'bbb', 'bbb', 'bbb', 'bbb', 1)

/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

delete from Sales.Customers where CustomerID = 1062


/*
3. Изменить одну запись, из добавленных через UPDATE
*/

update Sales.Customers set CustomerName = 'ccc' where CustomerID = 1066

/*
4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/

create table #source (
	[CustomerID] [int] NOT NULL,
	[CustomerName] [nvarchar](100) NOT NULL,
	[BillToCustomerID] [int] NOT NULL,
	[CustomerCategoryID] [int] NOT NULL,
	[BuyingGroupID] [int] NULL,
	[PrimaryContactPersonID] [int] NOT NULL,
	[AlternateContactPersonID] [int] NULL,
	[DeliveryMethodID] [int] NOT NULL,
	[DeliveryCityID] [int] NOT NULL,
	[PostalCityID] [int] NOT NULL,
	[CreditLimit] [decimal](18, 2) NULL,
	[AccountOpenedDate] [date] NOT NULL,
	[StandardDiscountPercentage] [decimal](18, 3) NOT NULL,
	[IsStatementSent] [bit] NOT NULL,
	[IsOnCreditHold] [bit] NOT NULL,
	[PaymentDays] [int] NOT NULL,
	[PhoneNumber] [nvarchar](20) NOT NULL,
	[FaxNumber] [nvarchar](20) NOT NULL,
	[DeliveryRun] [nvarchar](5) NULL,
	[RunPosition] [nvarchar](5) NULL,
	[WebsiteURL] [nvarchar](256) NOT NULL,
	[DeliveryAddressLine1] [nvarchar](60) NOT NULL,
	[DeliveryAddressLine2] [nvarchar](60) NULL,
	[DeliveryPostalCode] [nvarchar](10) NOT NULL,
	[PostalAddressLine1] [nvarchar](60) NOT NULL,
	[PostalAddressLine2] [nvarchar](60) NULL,
	[PostalPostalCode] [nvarchar](10) NOT NULL,
	[LastEditedBy] [int] NOT NULL
)

insert into #source (
	CustomerID
	,CustomerName
	,BillToCustomerID
	,CustomerCategoryID
	,BuyingGroupID
	,PrimaryContactPersonID
	,AlternateContactPersonID
	,DeliveryMethodID
	,DeliveryCityID
	,PostalCityID
	,CreditLimit
	,AccountOpenedDate
	,StandardDiscountPercentage
	,IsStatementSent
	,IsOnCreditHold
	,PaymentDays
	,PhoneNumber
	,FaxNumber
	,DeliveryRun
	,RunPosition
	,WebsiteURL
	,DeliveryAddressLine1
	,DeliveryAddressLine2
	,DeliveryPostalCode
	,PostalAddressLine1
	,PostalAddressLine2
	,PostalPostalCode
	,LastEditedBy
)
values
	(1062, 'xxx', 1062, 5, null, 3261, null, 3, 19881, 19881, 1500, '2016-05-07', 0, 0, 0, 7, '(xxx) xxx-xxxx', '(xxx) xxx-xxxx', null, null, 'xxx', 'xxx', 'xxx', 'xxx', 'xxx', 'xxx', 'xxx', 1)
	,(1063, 'yyy', 1063, 5, null, 3261, null, 3, 19881, 19881, 1500, '2016-05-07', 0, 0, 0, 7, '(yyy) yyy-yyyy', '(yyy) yyy-yyyy', null, null, 'yyy', 'yyy', 'yyy', 'yyy', 'yyy', 'yyy', 'yyy', 1)
	,(1064, 'zzz', 1064, 5, null, 3261, null, 3, 19881, 19881, 1500, '2016-05-07', 0, 0, 0, 7, '(zzz) zzz-zzzz', '(zzz) zzz-zzzz', null, null, 'zzz', 'zzz', 'zzz', 'zzz', 'zzz', 'zzz', 'zzz', 1)
	,(1065, 'ddd', 1065, 5, null, 3261, null, 3, 19881, 19881, 1500, '2016-05-07', 0, 0, 0, 7, '(ddd) ddd-ddda', '(ddd) ddd-ddda', null, null, 'ddd', 'ddd', 'ddd', 'ddd', 'ddd', 'ddd', 'ddd', 1)
	,(1066, 'bbb', 1066, 5, null, 3261, null, 3, 19881, 19881, 1500, '2016-05-07', 0, 0, 0, 7, '(bbb) bbb-bbbb', '(bbb) bbb-bbbb', null, null, 'bbb', 'bbb', 'bbb', 'bbb', 'bbb', 'bbb', 'bbb', 1)


merge Sales.Customers as t
using #source as s on s.CustomerID = t.CustomerID
when matched
    then update 
        set CustomerName = s.CustomerName
			,BillToCustomerID = s.BillToCustomerID
			,CustomerCategoryID = s.CustomerCategoryID
			,BuyingGroupID = s.BuyingGroupID
			,PrimaryContactPersonID = s.PrimaryContactPersonID
			,AlternateContactPersonID = s.AlternateContactPersonID
			,DeliveryMethodID = s.DeliveryMethodID
			,DeliveryCityID = s.DeliveryCityID
			,PostalCityID = s.PostalCityID
			,CreditLimit = s.CreditLimit
			,AccountOpenedDate = s.AccountOpenedDate
			,StandardDiscountPercentage = s.StandardDiscountPercentage
			,IsStatementSent = s.IsStatementSent
			,IsOnCreditHold = s.IsOnCreditHold
			,PaymentDays = s.PaymentDays
			,PhoneNumber = s.PhoneNumber
			,FaxNumber = s.FaxNumber
			,DeliveryRun = s.DeliveryRun
			,RunPosition = s.RunPosition
			,WebsiteURL = s.WebsiteURL
			,DeliveryAddressLine1 = s.DeliveryAddressLine1
			,DeliveryAddressLine2 = s.DeliveryAddressLine2
			,DeliveryPostalCode = s.DeliveryPostalCode
			,PostalAddressLine1 = s.PostalAddressLine1
			,PostalAddressLine2 = s.PostalAddressLine2
			,PostalPostalCode = s.PostalPostalCode
			,LastEditedBy = s.LastEditedBy
when not matched
    then insert (
		CustomerID
		,CustomerName
		,BillToCustomerID
		,CustomerCategoryID
		,BuyingGroupID
		,PrimaryContactPersonID
		,AlternateContactPersonID
		,DeliveryMethodID
		,DeliveryCityID
		,PostalCityID
		,CreditLimit
		,AccountOpenedDate
		,StandardDiscountPercentage
		,IsStatementSent
		,IsOnCreditHold
		,PaymentDays
		,PhoneNumber
		,FaxNumber
		,DeliveryRun
		,RunPosition
		,WebsiteURL
		,DeliveryAddressLine1
		,DeliveryAddressLine2
		,DeliveryPostalCode
		,PostalAddressLine1
		,PostalAddressLine2
		,PostalPostalCode
		,LastEditedBy
	) 
        values (
			s.CustomerID
			,s.CustomerName
			,s.BillToCustomerID
			,s.CustomerCategoryID
			,s.BuyingGroupID
			,s.PrimaryContactPersonID
			,s.AlternateContactPersonID
			,s.DeliveryMethodID
			,s.DeliveryCityID
			,s.PostalCityID
			,s.CreditLimit
			,s.AccountOpenedDate
			,s.StandardDiscountPercentage
			,s.IsStatementSent
			,s.IsOnCreditHold
			,s.PaymentDays
			,s.PhoneNumber
			,s.FaxNumber
			,s.DeliveryRun
			,s.RunPosition
			,s.WebsiteURL
			,s.DeliveryAddressLine1
			,s.DeliveryAddressLine2
			,s.DeliveryPostalCode
			,s.PostalAddressLine1
			,s.PostalAddressLine2
			,s.PostalPostalCode
			,s.LastEditedBy			
		)
;

/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/

EXEC sp_configure 'show advanced options', 1;  
GO  
-- To update the currently configured value for advanced options.  
RECONFIGURE;  
GO  
-- To enable the feature.  
EXEC sp_configure 'xp_cmdshell', 1;  
GO  
-- To update the currently configured value for this feature.  
RECONFIGURE;  
GO  

declare @out varchar(255);
set @out = 'bcp WideWorldImporters.Sales.Customers OUT "D:\courses\OTUS\demo.txt" -T -c -S ' + @@SERVERNAME;

EXEC master..xp_cmdshell @out

drop table if exists WideWorldImporters.Sales.Customers_Copy

select *
into WideWorldImporters.Sales.Customers_Copy
from Sales.Customers
where 1 = 2

declare @in varchar(250);
set @in = 'bcp WideWorldImporters.Sales.Customers_Copy IN "D:\courses\OTUS\demo.txt" -T -c -S ' + @@SERVERNAME;

EXEC master..xp_cmdshell @in

--------
--------
delete from Sales.Customers where CustomerID between 1062 and 1066
drop table if exists Sales.Customers_Copy