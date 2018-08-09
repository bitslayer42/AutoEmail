
ALTER VIEW vEmailFloorPlansPaidFormat AS
	SELECT NULL GRP, NULL DLR, NULL Date, NULL [ ], NULL [Stock #], NULL Vin, NULL Year, NULL Make,
	'SUM' [Floor Plan], NULL [Days],NULL [Paid Date], NULL [Paid Time], NULL [Paid Person]
	go
ALTER VIEW vEmailFloorPlansPaid AS
-- select * from vEmailFloorPlansPaid
	SELECT Floor_Plan_Dealership AS GRP, 
	Store AS DLR, Date, LEFT(new_used_certused,1) AS [ ], 
	deals.Stock_Number [Stock #], deals.Vin Vin, deals.Year, deals.Make,
	CONVERT(INT,ui.Ally_Floor_Plan_Amount) [Floor Plan], Ally_Days_Floored [Days],
	deals.DATE_ALLY_FLOORPLAN_PAID [Paid Date], deals.ALLY_FLOORPLAN_TIMESTAMP [Paid Time], 
	deals.ALLY_FLOORPLAN_PERSON [Paid Person]
	FROM deals
	INNER JOIN UsedInventory ui
	ON deals.Stock_Number = ui.Stock_Number
	WHERE DATE_ALLY_FLOORPLAN_PAID = CAST(GETDATE() AS DATE)
	AND Floor_Plan_Dealership <> ''