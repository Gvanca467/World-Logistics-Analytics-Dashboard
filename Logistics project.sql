/* 
   PROJECT: END-TO-END LOGISTICS DATA TRANSFORMATION
   GOAL: Clean and transform raw supply chain data for BI.
*/
-- 1. Let`s check the whole origin table as first step
SELECT * FROM [Gvantsa].[dbo].[supply_chain];

-- Starting cleaning non needed columns, but first check if exists
IF EXISTS (
    SELECT *
    FROM sys.columns
    WHERE name = 'SKU'
    AND object_id = OBJECT_ID('dbo.supply_chain')
)
BEGIN
    ALTER TABLE [Gvantsa].[dbo].[supply_chain] 
    DROP COLUMN [SKU]
	end

--2. Adding column Cntr Type and update
    ALTER TABLE [Gvantsa].[dbo].[supply_chain] 
    ADD [Cntr Type] NVARCHAR(100);


;WITH CTE AS (
    SELECT [Cntr Type], 
           ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) as RowNum
    FROM [Gvantsa].[dbo].[supply_chain]
)
UPDATE CTE 
SET [Cntr Type] = CASE 
    WHEN RowNum <= 50 THEN '20ft Container' 
    ELSE '40ft Container' 
END;


--3.Cleaning again

ALTER TABLE [Gvantsa].[dbo].[supply_chain] 
    DROP COLUMN [Defect_rates]


--4.updating column

UPDATE [Gvantsa].[dbo].[supply_chain]
SET [Shipping_costs] = CASE 
    WHEN [Cntr Type] = '20ft Container' THEN 500
    WHEN [Cntr Type] = '40ft Container' THEN 1000
    ELSE 250 
END;

--5. Renamed columns without coding

--6. Adding Column and Update existing ones

ALTER TABLE [Gvantsa].[dbo].[supply_chain]
ALTER COLUMN [Arrival_Place] NVARCHAR(100);


UPDATE [Gvantsa].[dbo].[supply_chain]
SET [Arrival_Place] = CASE 
    WHEN [Departure_Place] = 'Mumbai' THEN 'Poti'
    WHEN [Departure_Place] = 'Kolkata' THEN 'Batumi'
    ELSE 'Tbilisi'
END;


UPDATE [Gvantsa].[dbo].[supply_chain]
SET [Shipping_carriers] = CASE 
    WHEN [Shipping_carriers] = 'Carrier B' THEN 'Sea Lead'
    WHEN [Shipping_carriers] = 'Carrier A' THEN 'Maersk'
    ELSE 'CMA CGM'
END;

--7. Replacement again

;WITH CTE_Years AS (
    SELECT [Transportation_Years], 
           ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) as RowNum
    FROM [Gvantsa].[dbo].[supply_chain]
)
UPDATE CTE_Years 
SET [Transportation_Years] = CASE 
    WHEN RowNum <= 50 THEN 2024 
    ELSE 2025 
END;

--8. Changing columns sequence

SELECT 
    [Transportation_Years],
	[Supplier_name],
	[Volume],
    [Container_Type],     
    [Departure_Place],
    [Arrival_Place],
	[Transportation_Route],
	[Transportation_Mode],
	[Shipping_carriers],
    [Shipping_times],
    [Shipping_costs]
	
INTO [Gvantsa].[dbo].[supply_chain_new]
FROM [Gvantsa].[dbo].[supply_chain];

-- Deleting old one
DROP TABLE [Gvantsa].[dbo].[supply_chain];

USE [Gvantsa];
GO

-- Rename
EXEC sp_rename '[dbo].[supply_chain_new]', 'supply_chain';
GO


--9. Adding columns and creating differnet transpotrtation prices

USE [Gvantsa];
GO

-- 1. Adding Month column
ALTER TABLE [supply_chain] 
ADD [Transportation_Month] INT;
GO

-- 2. Changing prices
;WITH CTE_Update AS (
    SELECT 
        [Transportation_Month], 
        [Transportation_Price],
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) as RN
    FROM [supply_chain]
)
UPDATE CTE_Update 
SET 

    [Transportation_Month] = (RN % 12) + 1,
    

    [Transportation_Price] = CASE 
        WHEN RN % 3 = 0 THEN [Transportation_Price] * 1.2   
        WHEN RN % 2 = 0 THEN [Transportation_Price] * 0.9  
        ELSE [Transportation_Price] 
    END;
GO

--Check

SELECT * FROM [Gvantsa].[dbo].[supply_chain]




USE [Gvantsa];
GO

--10. Changing cntrs sequence
;WITH CTE_Mix AS (
    SELECT [Container_Type], 
           ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) as RN
    FROM [supply_chain]
)
UPDATE CTE_Mix 
SET [Container_Type] = CASE 
    WHEN RN % 2 = 0 THEN '40ft Container' 
    ELSE '20ft Container' 
END;

-- Final check

SELECT * FROM [Gvantsa].[dbo].[supply_chain]
