Testing Objects

1.Stored Procedures:
-- Test InsertOrderDetails
EXEC InsertOrderDetails @OrderID=43659, @ProductID=707, @Quantity=2;  -- Success
EXEC InsertOrderDetails @OrderID=43659, @ProductID=999, @Quantity=1;  -- Fail (invalid product)
EXEC InsertOrderDetails @OrderID=43659, @ProductID=707, @Quantity=9999; -- Fail (insufficient stock)

-- Test UpdateOrderDetails
EXEC UpdateOrderDetails @OrderID=43659, @ProductID=707, @Quantity=3;  -- Update quantity
EXEC UpdateOrderDetails @OrderID=43659, @ProductID=707, @Discount=0.1; -- Update discount
EXEC UpdateOrderDetails @OrderID=99999, @ProductID=707, @Quantity=1;  -- Fail (invalid order)

-- Test GetOrderDetails
EXEC GetOrderDetails @OrderID=43659;  -- Success
EXEC GetOrderDetails @OrderID=99999;  -- Fail (no such order)

-- Test DeleteOrderDetails
EXEC DeleteOrderDetails @OrderID=43659, @ProductID=707;  -- Success
EXEC DeleteOrderDetails @OrderID=99999, @ProductID=707;  -- Fail (invalid order)

2.Test Functions:
SELECT dbo.FormatDateMMDDYYYY(GETDATE()) AS CurrentDateFormatted;
SELECT dbo.FormatDateYYYYMMDD(GETDATE()) AS CurrentDateFormatted;

3.Test Views:
SELECT * FROM vwCustomerOrders;
SELECT * FROM vwCustomerOrdersYesterday;
SELECT * FROM MyProducts;

4.Test Triggers:
-- Test order deletion (should delete from Order Details first)
DELETE FROM Orders WHERE OrderID = 99999;

-- Test insufficient stock
INSERT INTO [Order Details] (OrderID, ProductID, UnitPrice, Quantity, Discount)
VALUES (10248, 998, 19.00, 500, 0); -- Should fail as we only have 50 in stock