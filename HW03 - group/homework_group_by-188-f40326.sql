/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

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
1. Посчитать среднюю цену товара, общую сумму продажи по месяцам.
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select
	Year(i.InvoiceDate) as [Год продажи]
	,Month(i.InvoiceDate) as [Месяц продажи]
	,avg(il.UnitPrice) as [Средняя цена за месяц по всем товарам]
	,sum(il.Quantity * il.UnitPrice) as [Общая сумма продаж за месяц]
from Sales.Invoices as i
	inner join Sales.InvoiceLines as il on il.InvoiceID = i.InvoiceID
group by 
	Year(i.InvoiceDate)
	,Month(i.InvoiceDate)


/*
2. Отобразить все месяцы, где общая сумма продаж превысила 4 600 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select
	Year(i.InvoiceDate) as [Год продажи]
	,Month(i.InvoiceDate) as [Месяц продажи]
	,sum(il.Quantity * il.UnitPrice) as [Общая сумма продаж]
from Sales.Invoices as i
	inner join Sales.InvoiceLines as il on il.InvoiceID = i.InvoiceID
group by 
	Year(i.InvoiceDate)
	,Month(i.InvoiceDate)
having sum(il.Quantity * il.UnitPrice) > 4600000

/*
3. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select
	Year(i.InvoiceDate) as [Год продажи]
	,Month(i.InvoiceDate) as [Месяц продажи]
	,StockItemName as [Наименование товара]
	,sum(il.Quantity * il.UnitPrice) as [Сумма продаж]
	,min(i.InvoiceDate) as [Дата первой продажи]
	,sum(il.Quantity) as [Количество проданного]
from Sales.Invoices as i
	inner join Sales.InvoiceLines as il on il.InvoiceID = i.InvoiceID
	inner join Warehouse.StockItems as si on si.StockItemID = il.StockItemID
group by 
	Year(i.InvoiceDate)
	,Month(i.InvoiceDate)
	,StockItemName
having sum(il.Quantity) < 50


-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 2-3 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/

select
	Year(i.InvoiceDate) as [Год продажи]
	,Month(i.InvoiceDate) as [Месяц продажи]
	,case 
		when sum(il.Quantity * il.UnitPrice) > 4600000
			then sum(il.Quantity * il.UnitPrice)
		else 0
	end as [Общая сумма продаж]
from Sales.Invoices as i
	inner join Sales.InvoiceLines as il on il.InvoiceID = i.InvoiceID
group by 
	Year(i.InvoiceDate)
	,Month(i.InvoiceDate)
order by 
	Year(i.InvoiceDate)
	,Month(i.InvoiceDate)

drop table if exists #YearMonth
drop table if exists #Report

select
	Year(InvoiceDate) as [Год продажи]
	,Month(InvoiceDate) as [Месяц продажи]
into #YearMonth
from Sales.Invoices
group by
	Year(InvoiceDate)
	,Month(InvoiceDate)

select
	Year(i.InvoiceDate) as [Год продажи]
	,Month(i.InvoiceDate) as [Месяц продажи]
	,StockItemName as [Наименование товара]
	,sum(il.Quantity * il.UnitPrice) as [Сумма продаж]
	,min(i.InvoiceDate) as [Дата первой продажи]
	,sum(il.Quantity) as [Количество проданного]
into #Report
from Sales.Invoices as i
	inner join Sales.InvoiceLines as il on il.InvoiceID = i.InvoiceID
	inner join Warehouse.StockItems as si on si.StockItemID = il.StockItemID
group by 
	Year(i.InvoiceDate)
	,Month(i.InvoiceDate)
	,StockItemName
having sum(il.Quantity) < 50

select
	ym.[Год продажи]
	,ym.[Месяц продажи]
	,r.[Наименование товара]
	,r.[Сумма продаж]
	,r.[Дата первой продажи]
	,r.[Количество проданного]
from #YearMonth as ym
	left join #Report as r on r.[Год продажи] = ym.[Год продажи]
		and r.[Месяц продажи] = ym.[Месяц продажи]
order by
	ym.[Год продажи]
	,ym.[Месяц продажи]	

