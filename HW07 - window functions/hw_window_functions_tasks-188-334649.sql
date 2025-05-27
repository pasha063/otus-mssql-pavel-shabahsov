/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

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
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/

set statistics io on;  
go 

select distinct
	i.InvoiceDate
	,(
		select sum(il.Quantity * il.UnitPrice)
		from Sales.InvoiceLines as il
		where il.InvoiceID in (
			select InvoiceID
			from Sales.Invoices as inv 
			where year(inv.InvoiceDate) = year(i.InvoiceDate)
				and month(inv.InvoiceDate) = month(i.InvoiceDate)
				and inv.InvoiceDate <= i.InvoiceDate
		)
	) as SalesTotalAmountCumulativePerMonth
from Sales.Invoices as i
where year(i.InvoiceDate) >= 2015
order by i.InvoiceDate

/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/

select distinct
	i.InvoiceDate
	,sum(il.Quantity * il.UnitPrice) over (partition by (year(i.InvoiceDate) * 100 + month(i.InvoiceDate)) order by i.InvoiceDate) as SalesTotalAmountCumulativePerMonth
from Sales.Invoices as i
	inner join Sales.InvoiceLines as il on il.InvoiceID = i.InvoiceID
where year(i.InvoiceDate) >= 2015
order by i.InvoiceDate

set statistics io off;  
go 

/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

;with cte_2016_product_sales as (
	select
		(year(i.InvoiceDate) * 100 + month(i.InvoiceDate)) as YearMonth
		,si.StockItemName as [Product]
		,sum(il.Quantity) as Quantity
	from Sales.Invoices as i
		inner join Sales.InvoiceLines as il on il.InvoiceID = i.InvoiceID
		inner join Warehouse.StockItems as si on si.StockItemID = il.StockItemID
	where year(i.InvoiceDate) = 2016
	group by
		(year(i.InvoiceDate) * 100 + month(i.InvoiceDate))
		,si.StockItemName
)
,cte_2016_product_sales_sorted as (
	select
		YearMonth
		,[Product]
		,row_number() over (partition by YearMonth order by Quantity desc) as rn
	from cte_2016_product_sales
)

select
	YearMonth
	,[Product]
from cte_2016_product_sales_sorted
where rn <= 2
order by Yearmonth, rn

/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/
select
	StockItemID
	,StockItemName
	,Brand
	,UnitPrice
	,row_number() over(partition by left(StockItemName, 1) order by StockItemName) as FirstSymbolNameNumeration
	,count(*) over(order by StockItemID rows between unbounded preceding and unbounded following) as TotalCount
	,count(*) over(partition by left(StockItemName, 1) order by StockItemName range between unbounded preceding and unbounded following) as FirstSymbolProductCount
	,lead(StockItemID, 1) over (order by StockItemName) as NextStockItemIDOrderByName
	,lag(StockItemID, 1) over (order by StockItemName) as PreviousStockItemIDOrderByName
	,isnull(lag(StockItemName, 2) over (order by StockItemName), 'No items') as TwoPreviousStockItemNameOrderByName
	,ntile(30) over (order by TypicalWeightPerUnit) as GroupNumberByWeight
from Warehouse.StockItems
order by StockItemName

/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

select
	i.SalespersonPersonID
	,trim(replace(p.FullName, p.PreferredName, '')) as SalesPersonLastName
	,i.CustomerID
	,c.CustomerName
	,i.InvoiceDate
	,sum(il.Quantity * il.UnitPrice) as SalesAmount
from Sales.Invoices as i
	inner join [Application].People as p on p.PersonID = i.SalespersonPersonID
	inner join Sales.Customers as c on c.CustomerID = i.CustomerID
	inner join Sales.InvoiceLines as il on il.InvoiceID = i.InvoiceID
where i.InvoiceID = (select max(InvoiceID) from Sales.Invoices as inv where inv.SalespersonPersonID = i.SalespersonPersonID)
group by
	i.SalespersonPersonID
	,trim(replace(p.FullName, p.PreferredName, ''))
	,i.CustomerID
	,c.CustomerName
	,i.InvoiceDate


/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

;with cte_rawdata as (
	select distinct
		c.CustomerID
		,c.CustomerName
		,il.StockItemID
		,il.UnitPrice
		,i.InvoiceDate
	from Sales.Invoices as i
		inner join Sales.Customers as c on c.CustomerID = i.CustomerID
		inner join Sales.InvoiceLines as il on il.InvoiceID = i.InvoiceID
)
,cte_customer_product_maxPrice as (
	select
		CustomerID
		,CustomerName
		,StockItemID
		,max(UnitPrice) as UnitPrice
	from cte_rawdata
	group by 
		CustomerID
		,CustomerName
		,StockItemID
)
,cte_customer_product_maxPrice_maxDate as (
	select
		a.CustomerID
		,a.CustomerName
		,a.StockItemID
		,a.UnitPrice
		,max(b.InvoiceDate) as InvoiceDate
	from cte_customer_product_maxPrice as a
		inner join cte_rawdata as b on b.CustomerID = a.CustomerID
			and b.StockItemID = a.StockItemID
			and b.UnitPrice = a.UnitPrice
	group by
		a.CustomerID
		,a.CustomerName
		,a.StockItemID
		,a.UnitPrice
)
,cte_customer_product_maxPrice_maxDate_sorted as (
	select
		CustomerID
		,CustomerName
		,StockItemID
		,UnitPrice
		,InvoiceDate
		,row_number() over (partition by CustomerID order by UnitPrice desc) as rn
	from cte_customer_product_maxPrice_maxDate
)
select
	CustomerID
	,CustomerName
	,StockItemID
	,UnitPrice
	,InvoiceDate
from cte_customer_product_maxPrice_maxDate_sorted
where rn <= 2

--Опционально можете для каждого запроса без оконных функций сделать вариант запросов с оконными функциями и сравнить их производительность. 