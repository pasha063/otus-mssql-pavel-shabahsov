/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, JOIN".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД WideWorldImporters можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

select
	StockItemID
	,StockItemName
from Warehouse.StockItems
where StockItemName like '%urgent%'
	or StockItemName like 'Animal%'

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/
select
	s.SupplierID
	,s.SupplierName
from Purchasing.Suppliers as s
	left join Purchasing.PurchaseOrders as po on po.SupplierID = s.SupplierID
where po.PurchaseOrderID is null

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/
select
	o.OrderID
	,format(o.OrderDate, 'dd.MM.yyyy') as OrderDate
	,datename(month, o.OrderDate) as [Month]
	,datepart(q, o.OrderDate) as [Quarter]
	,case
		when month(o.OrderDate) < 5
			then 1
		when month(o.OrderDate) < 9
			then 2
		else 3
	end as [ThirdPartOfTheYear]
	,c.CustomerName
from Sales.Orders as o
	inner join Sales.Customers as c on c.CustomerID = o.CustomerID
	inner join Sales.OrderLines as ol on ol.OrderID = o.OrderID
		and (ol.UnitPrice > 100 or ol.Quantity > 20)
		and ol.PickingCompletedWhen is not null
order by
	datepart(q, o.OrderDate)
	,case
		when month(o.OrderDate) < 5
			then 1
		when month(o.OrderDate) < 9
			then 2
		else 3
	end
	,o.OrderDate

-- вариант с offset
select
	o.OrderID
	,format(o.OrderDate, 'dd.MM.yyyy') as OrderDate
	,datename(month, o.OrderDate) as [Month]
	,datepart(q, o.OrderDate) as [Quarter]
	,case
		when month(o.OrderDate) < 5
			then 1
		when month(o.OrderDate) < 9
			then 2
		else 3
	end as [ThirdPartOfTheYear]
	,c.CustomerName
from Sales.Orders as o
	inner join Sales.OrderLines as ol on ol.OrderID = o.OrderID
		and (ol.UnitPrice > 100 or ol.Quantity > 20)
		and ol.PickingCompletedWhen is not null
	inner join Sales.Customers as c on c.CustomerID = o.CustomerID
order by
	datepart(q, o.OrderDate)
	,case
		when month(o.OrderDate) < 5
			then 1
		when month(o.OrderDate) < 9
			then 2
		else 3
	end
	,o.OrderDate
offset 1000 rows
fetch next 100 rows only


/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

select
	dm.DeliveryMethodName
	,po.ExpectedDeliveryDate
	,s.SupplierName
	,p.FullName as ContactPerson
from Purchasing.Suppliers as s
	inner join Purchasing.PurchaseOrders as po on po.SupplierID = s.SupplierID
		and po.ExpectedDeliveryDate between '2013-01-01' and '2013-01-31'
		and IsOrderFinalized = 1
	inner join [Application].DeliveryMethods as dm on dm.DeliveryMethodID = po.DeliveryMethodID
		and dm.DeliveryMethodName in ('Air Freight', 'Refrigerated Air Freight')
	inner join [Application].People as p on p.PersonID = po.ContactPersonID

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/
select top 10
	i.InvoiceID
	,p2.FullName as ClientName
	--,i.ConfirmedReceivedBy as AlternativeClientName -- другой вариант получения имени клиента в зависимости от конкретики
	,p.FullName as SalesPersonName
	,i.InvoiceDate
	,i.ConfirmedDeliveryTime
from Sales.Invoices as i
	inner join [Application].People as p on p.PersonID = i.SalespersonPersonID
	inner join Sales.Orders as o on o.OrderID = i.OrderID
	inner join Sales.Customers as c on c.CustomerID = o.CustomerID
	inner join [Application].People as p2 on p2.PersonID = c.PrimaryContactPersonID
order by 
	i.ConfirmedDeliveryTime desc --если продажа в момент доставки
	--,i.InvoiceDate desc --если имеет значение только дата, а не время. 

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

select distinct
	c.CustomerID
	,c.CustomerName
	,c.PhoneNumber
from Sales.Orders as o
	inner join Sales.OrderLines as ol on ol.OrderID = o.OrderID
	inner join Warehouse.StockItems as si on si.StockItemID = ol.StockItemID
		and StockItemName = 'Chocolate frogs 250g'
	inner join Sales.Customers as c on c.CustomerID = o.CustomerID