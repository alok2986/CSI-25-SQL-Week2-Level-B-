Views

1. vwCustomerOrders View
CREATE VIEW vwCustomerOrders
AS
SELECT
    c.CompanyName,
    o.OrderID,
    o.OrderDate,
    od.ProductID,
    p.ProductName,
    od.Quantity,
    od.UnitPrice,
    (od.Quantity * od.UnitPrice) AS TotalPrice
FROM
    Customers c
    JOIN Orders o ON c.CustomerID = o.CustomerID
    JOIN [Order Details] od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID;
GO

-- Example usage:
-- SELECT * FROM vwCustomerOrders;

2. vwCustomerOrdersYesterday View
CREATE VIEW vwCustomerOrdersYesterday
AS
SELECT
    c.CompanyName,
    o.OrderID,
    o.OrderDate,
    od.ProductID,
    p.ProductName,
    od.Quantity,
    od.UnitPrice,
    (od.Quantity * od.UnitPrice) AS TotalPrice
FROM
    Customers c
    JOIN Orders o ON c.CustomerID = o.CustomerID
    JOIN [Order Details] od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
WHERE
    CONVERT(DATE, o.OrderDate) = CONVERT(DATE, DATEADD(day, -1, GETDATE()));
GO

-- Example usage:
-- SELECT * FROM vwCustomerOrdersYesterday;

3. MyProducts View
CREATE VIEW MyProducts
AS
SELECT
    p.ProductID,
    p.ProductName,
    p.QuantityPerUnit,
    p.UnitPrice,
    s.CompanyName AS SupplierName,
    c.CategoryName
FROM
    Products p
    JOIN Suppliers s ON p.SupplierID = s.SupplierID
    JOIN Categories c ON p.CategoryID = c.CategoryID
WHERE
    p.Discontinued = 0;
GO

-- Example usage:
-- SELECT * FROM MyProducts;