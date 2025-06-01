1. InsertOrderDetails Procedure

CREATE PROCEDURE InsertOrderDetails
    @OrderID INT,
    @ProductID INT,
    @UnitPrice MONEY = NULL,
    @Quantity SMALLINT,
    @Discount REAL = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Check if product exists and has enough stock
        DECLARE @CurrentStock SMALLINT, @ReorderLevel SMALLINT;
        SELECT @CurrentStock = UnitsInStock, @ReorderLevel = ReorderLevel
        FROM Production.ProductInventory
        WHERE ProductID = @ProductID;
        
        IF @CurrentStock IS NULL
        BEGIN
            PRINT 'Product does not exist.';
            ROLLBACK;
            RETURN -1;
        END
        
        IF @CurrentStock < @Quantity
        BEGIN
            PRINT 'Not enough stock available for this product.';
            ROLLBACK;
            RETURN -1;
        END
        
        -- Get UnitPrice from Product table if not provided
        IF @UnitPrice IS NULL
        BEGIN
            SELECT @UnitPrice = ListPrice
            FROM Production.Product
            WHERE ProductID = @ProductID;
        END
        
        -- Insert order details
        INSERT INTO Sales.SalesOrderDetail (
            SalesOrderID,
            ProductID,
            UnitPrice,
            OrderQty,
            UnitPriceDiscount
        )
        VALUES (
            @OrderID,
            @ProductID,
            @UnitPrice,
            @Quantity,
            @Discount
        );
        
        -- Check if insert was successful
        IF @@ROWCOUNT = 0
        BEGIN
            PRINT 'Failed to place the order. Please try again.';
            ROLLBACK;
            RETURN -1;
        END
        
        -- Update inventory
        UPDATE Production.ProductInventory
        SET UnitsInStock = UnitsInStock - @Quantity
        WHERE ProductID = @ProductID;
        
        -- Check if stock is below reorder level
        IF (@CurrentStock - @Quantity) < @ReorderLevel
        BEGIN
            PRINT 'Warning: Product stock is now below reorder level!';
        END
        
        COMMIT TRANSACTION;
        PRINT 'Order successfully placed.';
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;
        
        PRINT 'Error occurred: ' + ERROR_MESSAGE();
        RETURN -1;
    END CATCH
END;

2. UpdateOrderDetails Procedure

CREATE PROCEDURE UpdateOrderDetails
    @OrderID INT,
    @ProductID INT,
    @UnitPrice MONEY = NULL,
    @Quantity SMALLINT = NULL,
    @Discount REAL = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Check if order detail exists
        IF NOT EXISTS (
            SELECT 1 
            FROM Sales.SalesOrderDetail 
            WHERE SalesOrderID = @OrderID AND ProductID = @ProductID
        )
        BEGIN
            PRINT 'The specified order detail does not exist.';
            ROLLBACK;
            RETURN -1;
        END
        
        -- Get current quantity for inventory adjustment
        DECLARE @OldQuantity SMALLINT, @QuantityDiff SMALLINT;
        SELECT @OldQuantity = OrderQty
        FROM Sales.SalesOrderDetail
        WHERE SalesOrderID = @OrderID AND ProductID = @ProductID;
        
        -- Set @QuantityDiff only if @Quantity is provided
        IF @Quantity IS NOT NULL
            SET @QuantityDiff = @Quantity - @OldQuantity;
        ELSE
            SET @QuantityDiff = 0;
        
        -- Check inventory if quantity is being increased
        IF @QuantityDiff > 0
        BEGIN
            DECLARE @CurrentStock SMALLINT;
            SELECT @CurrentStock = UnitsInStock
            FROM Production.ProductInventory
            WHERE ProductID = @ProductID;
            
            IF @CurrentStock < @QuantityDiff
            BEGIN
                PRINT 'Not enough stock available for this update.';
                ROLLBACK;
                RETURN -1;
            END
        END
        
        -- Update order details using ISNULL to retain original values when NULL is passed
        UPDATE Sales.SalesOrderDetail
        SET 
            UnitPrice = ISNULL(@UnitPrice, UnitPrice),
            OrderQty = ISNULL(@Quantity, OrderQty),
            UnitPriceDiscount = ISNULL(@Discount, UnitPriceDiscount)
        WHERE 
            SalesOrderID = @OrderID AND 
            ProductID = @ProductID;
        
        -- Update inventory if quantity changed
        IF @QuantityDiff <> 0
        BEGIN
            UPDATE Production.ProductInventory
            SET UnitsInStock = UnitsInStock - @QuantityDiff
            WHERE ProductID = @ProductID;
            
            -- Check if stock is below reorder level
            DECLARE @ReorderLevel SMALLINT, @NewStock SMALLINT;
            SELECT @ReorderLevel = ReorderLevel, @NewStock = UnitsInStock
            FROM Production.ProductInventory
            WHERE ProductID = @ProductID;
            
            IF @NewStock < @ReorderLevel
            BEGIN
                PRINT 'Warning: Product stock is now below reorder level!';
            END
        END
        
        COMMIT TRANSACTION;
        PRINT 'Order details successfully updated.';
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;
        
        PRINT 'Error occurred: ' + ERROR_MESSAGE();
        RETURN -1;
    END CATCH
END;

3. GetOrderDetails Procedure

CREATE PROCEDURE GetOrderDetails
    @OrderID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    IF NOT EXISTS (
        SELECT 1 
        FROM Sales.SalesOrderDetail 
        WHERE SalesOrderID = @OrderID
    )
    BEGIN
        PRINT 'The OrderID ' + CAST(@OrderID AS VARCHAR(10)) + ' does not exist';
        RETURN 1;
    END
    
    -- Return all order details for the given OrderID
    SELECT 
        SalesOrderID AS OrderID,
        ProductID,
        OrderQty AS Quantity,
        UnitPrice,
        UnitPriceDiscount AS Discount,
        LineTotal
    FROM 
        Sales.SalesOrderDetail
    WHERE 
        SalesOrderID = @OrderID
    ORDER BY 
        ProductID;
    
    RETURN 0;
END;

4. DeleteOrderDetails Procedure

CREATE PROCEDURE DeleteOrderDetails
    @OrderID INT,
    @ProductID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validate parameters
        IF NOT EXISTS (
            SELECT 1 
            FROM Sales.SalesOrderHeader 
            WHERE SalesOrderID = @OrderID
        )
        BEGIN
            PRINT 'Error: The OrderID ' + CAST(@OrderID AS VARCHAR(10)) + ' does not exist.';
            RETURN -1;
        END
        
        IF NOT EXISTS (
            SELECT 1 
            FROM Sales.SalesOrderDetail 
            WHERE SalesOrderID = @OrderID AND ProductID = @ProductID
        )
        BEGIN
            PRINT 'Error: The ProductID ' + CAST(@ProductID AS VARCHAR(10)) + ' does not exist in the specified order.';
            RETURN -1;
        END
        
        BEGIN TRANSACTION;
        
        -- Get quantity for inventory adjustment
        DECLARE @Quantity SMALLINT;
        SELECT @Quantity = OrderQty
        FROM Sales.SalesOrderDetail
        WHERE SalesOrderID = @OrderID AND ProductID = @ProductID;
        
        -- Delete the order detail
        DELETE FROM Sales.SalesOrderDetail
        WHERE SalesOrderID = @OrderID AND ProductID = @ProductID;
        
        -- Check if delete was successful
        IF @@ROWCOUNT = 0
        BEGIN
            PRINT 'Failed to delete the order detail.';
            ROLLBACK;
            RETURN -1;
        END
        
        -- Update inventory
        UPDATE Production.ProductInventory
        SET UnitsInStock = UnitsInStock + @Quantity
        WHERE ProductID = @ProductID;
        
        COMMIT TRANSACTION;
        PRINT 'Order detail successfully deleted.';
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;
        
        PRINT 'Error occurred: ' + ERROR_MESSAGE();
        RETURN -1;
    END CATCH
END;