use WideWorldImporters
go

SET STATISTICS IO ON
SET STATISTICS TIME ON

Select ord.CustomerID, det.StockItemID, SUM(det.UnitPrice), SUM(det.Quantity), COUNT(ord.OrderID)
FROM Sales.Orders AS ord
    JOIN Sales.OrderLines AS det
        ON det.OrderID = ord.OrderID
    JOIN Sales.Invoices AS Inv
        ON Inv.OrderID = ord.OrderID
    JOIN Sales.CustomerTransactions AS Trans
        ON Trans.InvoiceID = Inv.InvoiceID
    JOIN Warehouse.StockItemTransactions AS ItemTrans
        ON ItemTrans.StockItemID = det.StockItemID
WHERE Inv.BillToCustomerID != ord.CustomerID -- перенесено в join (строка 57)
    AND (Select SupplierId -- перенесено в join (строки 52-53)
         FROM Warehouse.StockItems AS It
         Where It.StockItemID = det.StockItemID) = 12
    AND (SELECT SUM(Total.UnitPrice*Total.Quantity) -- перенесено в cte
        FROM Sales.OrderLines AS Total
            Join Sales.Orders AS ordTotal
                On ordTotal.OrderID = Total.OrderID
        WHERE ordTotal.CustomerID = Inv.CustomerID) > 250000
    AND DATEDIFF(dd, Inv.InvoiceDate, ord.OrderDate) = 0 -- перенесено в join (строка 56)
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID

/*
	шаг 1 - переписывваю в удобный мне кодстайл, чтобы легче было прочитать запрос
	шаг 2 - инструкция where идет после from поэтому пробуем их выполнить либо во from либо в cte
	шаг 3 - сравниваем результат
*/

;with cte_customers as (
	select o.CustomerID
	from Sales.Orders as o
		inner join Sales.OrderLines as ol on ol.OrderID = o.OrderID
	group by o.CustomerID
	having sum(ol.UnitPrice * ol.Quantity) >  250000
)

select
	o.CustomerID
	,ol.StockItemID
	,sum(ol.UnitPrice) as UnitPricesum
	,sum(ol.Quantity) as TotalQuantity
	,count(o.OrderID) as OrderIDCount
from Sales.Orders as o
    inner join Sales.OrderLines as ol on ol.OrderID = o.OrderID
	inner join Warehouse.StockItems as si on si.StockItemID = ol.StockItemID
		and si.SupplierId = 12
	inner join Warehouse.StockItemTransactions as sit on sit.StockItemID = ol.StockItemID
    inner join Sales.Invoices as i on i.OrderID = o.OrderID
		and i.InvoiceDate = o.OrderDate
		and i.BillToCustomerID <> o.CustomerID
	inner join cte_customers as c on c.CustomerID = o.CustomerID
    inner join Sales.CustomerTransactions as ct on ct.InvoiceID = i.InvoiceID
group by o.CustomerID, ol.StockItemID
order by o.CustomerID, ol.StockItemID
