Triggers

1. Instead of Delete Trigger for Orders
CREATE TRIGGER tr_Orders_InsteadOfDelete
ON Orders
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- First delete from Order Details
        DELETE FROM [Order Details]
        WHERE OrderID IN (SELECT OrderID FROM deleted);
        
        -- Then delete from Orders
        DELETE FROM Orders
        WHERE OrderID IN (SELECT OrderID FROM deleted);
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        PRINT 'Error occurred while deleting order: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

-- Example usage:
-- DELETE FROM Orders WHERE OrderID = 10248;

2. Order Details Insert Trigger for Stock Validation
CREATE TRIGGER tr_OrderDetails_CheckStock
ON [Order Details]
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check stock for all products in the inserted rows
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN Products p ON i.ProductID = p.ProductID
        WHERE p.UnitsInStock < i.Quantity
    )
    BEGIN
        -- Find which products are out of stock
        SELECT 
            i.ProductID,
            p.ProductName,
            p.UnitsInStock AS CurrentStock,
            i.Quantity AS RequiredQuantity
        FROM 
            inserted i
            JOIN Products p ON i.ProductID = p.ProductID
        WHERE 
            p.UnitsInStock < i.Quantity;
            
        RAISERROR('Cannot place order - insufficient stock for some products', 16, 1);
        RETURN;
    END
    ELSE
    BEGIN
        -- All products have sufficient stock, proceed with insert
        INSERT INTO [Order Details] (
            OrderID, 
            ProductID, 
            UnitPrice, 
            Quantity, 
            Discount
        )
        SELECT 
            OrderID, 
            ProductID, 
            UnitPrice, 
            Quantity, 
            Discount
        FROM 
            inserted;
        
        -- Update stock levels
        UPDATE p
        SET p.UnitsInStock = p.UnitsInStock - i.Quantity
        FROM 
            Products p
            JOIN inserted i ON p.ProductID = i.ProductID;
            
        PRINT 'Order successfully placed and stock levels updated';
    END
END;
GO

-- Example usage:
-- INSERT INTO [Order Details] (OrderID, ProductID, UnitPrice, Quantity, Discount)
-- VALUES (10248, 11, 14.00, 50, 0);

