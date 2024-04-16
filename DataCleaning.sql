
-- Changing datatype for SaleDate
ALTER TABLE DataCleaning.dbo.Housing
ALTER COLUMN SaleDate DATE

SELECT SaleDate
FROM DataCleaning.dbo.Housing


-- Handling nulls in PropertyAddress 
-- Before, we can see that there exist NULL property addresses when ParcelIDs are the same 
SELECT id.ParcelID, id.PropertyAddress, pa.ParcelID, pa.PropertyAddress
FROM DataCleaning.dbo.Housing id
JOIN DataCleaning.dbo.Housing pa
	on id.ParcelID = pa.ParcelID
WHERE pa.PropertyAddress is null and pa.[UniqueID ] <> id.[UniqueID ]

-- After running the update, the previous SQL query will have no results becauses the addresses will be copied in the NULL spaces. 
UPDATE pa
SET PropertyAddress = ISNULL(pa.PropertyAddress, id.PropertyAddress)
FROM DataCleaning.dbo.Housing id
JOIN DataCleaning.dbo.Housing pa
	on id.ParcelID = pa.ParcelID
WHERE pa.PropertyAddress is null and pa.[UniqueID ] <> id.[UniqueID ]


-- Separating address and city into two separate columns from PropertyAddress
ALTER TABLE DataCleaning.dbo.Housing
ADD NewAddress NvarChar(255);
GO 

UPDATE DataCleaning.dbo.Housing
SET NewAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)
GO 

ALTER TABLE DataCleaning.dbo.Housing
ADD NewCity NvarChar(255);
GO

UPDATE DataCleaning.dbo.Housing
SET NewCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))
GO 

SELECT NewAddress, NewCity
FROM  DataCleaning.dbo.Housing


-- Splitting OwnerAddress using PARSENAME
SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM  DataCleaning.dbo.Housing
WHERE OwnerAddress is not null

ALTER TABLE DataCleaning.dbo.Housing
ADD NewState NvarChar(255);
GO

UPDATE DataCleaning.dbo.Housing
SET NewState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
GO 

SELECT NewAddress, NewCity, NewState
FROM  DataCleaning.dbo.Housing


-- Making sure all cells in SoldAsVacant are either 'Yes' or 'No' using CASE statement 
-- After the update, there will only be two rows of distinct values
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM  DataCleaning.dbo.Housing
GROUP BY SoldAsVacant

UPDATE DataCleaning.dbo.Housing
SET SoldAsVacant =
CASE 
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END


-- Remove duplicates using a CTE
WITH RowNum AS(
SELECT *, ROW_NUMBER() OVER(
	PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference 
	ORDER BY UniqueID) RowNumber
FROM  DataCleaning.dbo.Housing
)
DELETE
FROM RowNum
WHERE RowNumber > 1


-- Removing collumns 
SELECT *
FROM  DataCleaning.dbo.Housing
ALTER TABLE  DataCleaning.dbo.Housing
DROP COLUMN LandValue, TotalValue, BuildingValue