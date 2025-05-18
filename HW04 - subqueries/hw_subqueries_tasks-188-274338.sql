/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

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
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

select
	p.PersonID
	,p.FullName
from [Application].People as p
where p.IsSalesperson = 1
	and not exists (select 1 from Sales.Invoices as s where s.InvoiceDate = '20150704' and s.SalespersonPersonID = p.PersonID)

/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/
select
	StockItemID
	,StockItemName
	,UnitPrice
from Warehouse.StockItems
where UnitPrice = (select min(UnitPrice) from Warehouse.StockItems)

select
	StockItemID
	,StockItemName
	,UnitPrice
from Warehouse.StockItems
where UnitPrice <= all (select UnitPrice from Warehouse.StockItems)

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

select *
from Sales.Customers
where CustomerID in (
	select top 5 with ties
		CustomerID
	from Sales.CustomerTransactions
	order by TransactionAmount desc
)

select *
from Sales.Customers
where CustomerID = any (
	select top 5 with ties
		CustomerID
	from Sales.CustomerTransactions
	order by TransactionAmount desc
)

;with cte_top5_sales as (
	select top 5 with ties
		CustomerID
	from Sales.CustomerTransactions
	order by TransactionAmount desc		
)

select *
from Sales.Customers as c
where CustomerID in (select CustomerID from cte_top5_sales)

/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/
	select distinct
		ct.CityID
		,ct.CityName
		,p.FullName
	from Sales.Invoices as i
		inner join [Application].People as p on p.PersonID = i.PackedByPersonID
		inner join Sales.InvoiceLines as il on il.InvoiceID = i.InvoiceID
		inner join Sales.Customers as c on c.CustomerID = i.CustomerID
		inner join [Application].Cities as ct on ct.CityID = c.DeliveryCityID
	where il.StockItemID in (
		select top 3 with ties
			StockItemID
		from Warehouse.StockItems
		order by UnitPrice desc
	)

-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- не знаю как оптимизовать, но повысить читаемость с примерно одинаковыми затратами можно, например, так

;with cte_TotalSummForPickedItems as (
	select
		o.OrderID
		,sum(ol.PickedQuantity * ol.UnitPrice) as TotalSummForPickedItems
	from Sales.Orders as o
		inner hash join Sales.OrderLines as ol on ol.OrderID = o.OrderID
	where o.PickingCompletedWhen is not null
	group by o.OrderID
)

select 
	i.InvoiceId
	,i.InvoiceDate
	,p.FullName as SalesPersonName
	,sum(il.Quantity * il.UnitPrice) as TotalSummByInvoice
	,ts.TotalSummForPickedItems
from Sales.Invoices as i
	inner hash join Sales.InvoiceLines as il on il.InvoiceID = i.InvoiceID
	inner hash join [Application].People as p on p.PersonID = i.SalespersonPersonID
	inner hash join	cte_TotalSummForPickedItems as ts on ts.OrderID = i.OrderID
group by 
	i.InvoiceId
	,i.InvoiceDate
	,p.FullName
	,ts.TotalSummForPickedItems
having sum(il.Quantity * il.UnitPrice) > 27000
order by sum(il.Quantity * il.UnitPrice) desc