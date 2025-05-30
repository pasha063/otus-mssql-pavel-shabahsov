/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/

declare
	@CustomerBranchName1 as varchar(255)
	,@CustomerBranchName2 as varchar(255)
	,@CustomerBranchName3 as varchar(255)
	,@CustomerBranchName4 as varchar(255)
	,@CustomerBranchName5 as varchar(255)
	,@sql nvarchar(max)

drop table if exists #Customers 

select
	CustomerID
	,substring(
		CustomerName
		,charindex('(', CustomerName) + 1
		,(charindex(')', CustomerName)) - (charindex('(', CustomerName) + 1)
	) as CustomerBranchName
into #Customers
from Sales.Customers
where CustomerID between 2 and 6

set	@CustomerBranchName1 = (select CustomerBranchName from #Customers where CustomerID = 2)
set	@CustomerBranchName2 = (select CustomerBranchName from #Customers where CustomerID = 3)
set	@CustomerBranchName3 = (select CustomerBranchName from #Customers where CustomerID = 4)
set	@CustomerBranchName4 = (select CustomerBranchName from #Customers where CustomerID = 5)
set	@CustomerBranchName5 = (select CustomerBranchName from #Customers where CustomerID = 6)

set @sql = '
	select
		InvoiceMonth
		,[' + @CustomerBranchName1 + ']
		,[' + @CustomerBranchName2 + ']
		,[' + @CustomerBranchName3 + ']
		,[' + @CustomerBranchName4 + ']
		,[' + @CustomerBranchName5 + ']
	from (
		select
			format(dateadd(month, datediff(month, 0, i.InvoiceDate), 0), ''dd.MM.yyyy'')  as InvoiceMonth
			,c.CustomerBranchName
		from Sales.Invoices as i
			inner join #Customers as c on c.CustomerID = i.CustomerID
	) as unpvt
	pivot (count([CustomerBranchName]) for [CustomerBranchName] in ([' + @CustomerBranchName1 + '], [' + @CustomerBranchName2 + '], [' + @CustomerBranchName3 + '], [' + @CustomerBranchName4 + '], [' + @CustomerBranchName5 + '])) as pvt
'
exec sp_executesql @sql
drop table if exists #Customers

/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/

;with cte_Tailspin_Toys_customers as (select distinct CustomerName from Sales.Customers where CustomerName like '%Tailspin Toys%')
,cte_customerAdresses as (select distinct DeliveryAddressLine1 as AddressLine from Sales.Customers)

select
	CustomerName
	,AddressLine
from cte_Tailspin_Toys_customers
	cross apply cte_customerAdresses

/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/

--Буквенный код (в задании: либо-либо)
select
	CountryID
	,CountryName
	,IsoAlpha3Code as Code
from [Application].Countries

--Вариант с цифровым кодом
select
	CountryID
	,CountryName
	,IsoNumericCode as Code
from [Application].Countries

--Вариант смешанный
select
	CountryID
	,CountryName
	,iif(CountryId % 2 = 0, IsoAlpha3Code, cast(IsoNumericCode as nvarchar(6))) as Code
from [Application].Countries

--Вариант комбинированный как в примере, не подходящий под условия задачи
select
	CountryID
	,CountryName
	,IsoAlpha3Code as Code
from [Application].Countries

union all

select
	CountryID
	,CountryName
	,cast(IsoNumericCode as nvarchar(6))
from [Application].Countries
order by CountryID

/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

select
	c.CustomerID
	,c.CustomerName
	,g.StockItemID
	,g.UnitPrice
	,max(inv.InvoiceDate) as InvoiceDate
from Sales.Customers as c
	cross apply (
		select top 2
			si.StockItemID
			,max(il.UnitPrice) as UnitPrice
		from sales.Invoices as i
			inner join Sales.InvoiceLines as il on il.InvoiceID = i.InvoiceID
			inner join Warehouse.StockItems as si on si.StockItemID = il.StockItemID
		where i.CustomerID = c.CustomerID
		group by si.StockItemID	
		order by max(il.UnitPrice) desc
	) as g
	inner join sales.Invoices as inv on inv.CustomerID = c.CustomerID
	inner join Sales.InvoiceLines as invil on invil.InvoiceID = inv.InvoiceID
		and invil.StockItemID = g.StockItemID
		and invil.UnitPrice = g.UnitPrice
group by
	c.CustomerID
	,c.CustomerName
	,g.StockItemID
	,g.UnitPrice
order by c.CustomerID
			


