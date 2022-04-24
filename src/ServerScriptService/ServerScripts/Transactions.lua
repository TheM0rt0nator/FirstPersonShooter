-- Most of this code copied from Roblox website

local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local loadModule, getDataStream = table.unpack(require(ReplicatedStorage.Framework))

local MapHandler = loadModule("MapHandler")
 
-- Data store for tracking purchases that were successfully processed
local purchaseHistoryStore = DataStoreService:GetDataStore("PurchaseHistory")

local Transactions = {
	productFunctions = {
		[1259784642] = function(receipt, player)
			print("Purhcasing")
			-- We want to check that we are still in the map voting phase and if we are, we can return true after making the supervote value
			local gameStatus = ReplicatedStorage:WaitForChild("GameValues"):WaitForChild("GameStatus")
			local mapVotes = ReplicatedStorage:WaitForChild("MapVotes")
			if gameStatus.Value ~= "MapVoting" or mapVotes.Timer.Value < 5 or mapVotes:FindFirstChild("SuperVote") then return end
			print("Check1")
			local superVoteVal = Instance.new("StringValue")
			superVoteVal.Name = "SuperVote"
			superVoteVal.Value = MapHandler.superVotes[tostring(player.UserId)]
			superVoteVal.Parent = mapVotes
			MapHandler.canSuperVote = false
			return true
		end;
	};
}

function Transactions.processReceipt(receiptInfo)
	-- Determine if the product was already granted by checking the data store  
	local playerProductKey = receiptInfo.PlayerId .. "_" .. receiptInfo.PurchaseId
 
	local success, isPurchaseRecorded = pcall(function()
		return purchaseHistoryStore:UpdateAsync(playerProductKey, function(alreadyPurchased)
			if alreadyPurchased then
				return true
			end
 
			print(receiptInfo.ProductId)
			-- Find the player who made the purchase in the server
			local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
			if not player then
				-- The player probably left the game
				-- If they come back, the callback will be called again
				return nil
			end
 
			local handler = Transactions.productFunctions[receiptInfo.ProductId]
 
			local success, result = pcall(handler, receiptInfo, player)
			-- If granting the product failed, do NOT record the purchase in datastores.
			if not success or not result then
				error("Failed to process a product purchase for ProductId:", receiptInfo.ProductId, " Player:", player)
				return nil
			end
 
			-- Record the transcation in purchaseHistoryStore.
			return true
		end)
	end)
 
	if not success then
		error("Failed to process receipt due to data store error.")
		return Enum.ProductPurchaseDecision.NotProcessedYet
	elseif isPurchaseRecorded == nil then
		-- Didn't update the value in data store.
		return Enum.ProductPurchaseDecision.NotProcessedYet
	else	
		-- IMPORTANT: Tell Roblox that the game successfully handled the purchase
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end

MarketplaceService.ProcessReceipt = Transactions.processReceipt

return Transactions