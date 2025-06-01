Sample Data Creation

-- Sample Customers
INSERT INTO Customers (CustomerID, CompanyName, ContactName)
VALUES ('TEST1', 'Test Company', 'Test Contact');

-- Sample Products
INSERT INTO Products (ProductID, ProductName, SupplierID, CategoryID, QuantityPerUnit, UnitPrice, UnitsInStock, Discontinued)
VALUES 
(999, 'Test Product 1', 1, 1, '10 boxes', 18.00, 100, 0),
(998, 'Test Product 2', 1, 1, '24 boxes', 19.00, 50, 0);

-- Sample Orders (for yesterday)
INSERT INTO Orders (OrderID, CustomerID, OrderDate)
VALUES 
(99999, 'TEST1', DATEADD(day, -1, GETDATE()));

-- Sample Order Details
INSERT INTO [Order Details] (OrderID, ProductID, UnitPrice, Quantity, Discount)
VALUES 
(99999, 999, 18.00, 5, 0);