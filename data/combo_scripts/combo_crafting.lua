mods.combo = {}

local vter = mods.multiverse.vter

mods.combo.craftedWeapons = {}
local craftedWeapons = mods.arc_combo.craftedWeapons
craftedWeapons["COMBO_BURST_FOCUS_1_1"] = {component_amounts = {1, 1}, components = {{"LASER_BURST_2"}, {"FOCUS_1"}}}

local craftedItemsVisible = {}
local emptyReq = Hyperspace.ChoiceReq()

local function addComponentStep(currentEvent, weapon, craftingData, itemLevel, itemAmount)
	--print(weapon.." ITEM LEVEL AT: "..itemLevel.." NEEDS: "..#craftingData.components.." ITEM AMOUNT AT: "..itemAmount.." NEEDS: "..craftingData.component_amounts[itemLevel])
	local eventManager = Hyperspace.Event
	currentEvent:RemoveChoice(0)
	for _, needed in ipairs(craftingData.components[itemLevel]) do
		local tempEvent = eventManager:CreateEvent("COMBO_CRAFT_STEP", 0, false)
		tempEvent.stuff.removeItem = needed
		local neededBlueprint = Hyperspace.Blueprints:GetWeaponBlueprint(needed)
		currentEvent:AddChoice(tempEvent, "Use your "..neededBlueprint.desc.title:GetText(), emptyReq, false)
		if itemAmount >= craftingData.component_amounts[itemLevel] then
			if itemLevel >= #craftingData.components then
				--[[tempEvent:RemoveChoice(0)
				local rewardEvent = eventManager:CreateEvent("AEA_COMBO_CRAFT_STEP", 0, false)
				rewardEvent.stuff.weapon = Hyperspace.Blueprints:GetWeaponBlueprint(weapon)
				tempEvent:AddChoice(rewardEvent, "Continue...", emptyReq, false)]]
				tempEvent.stuff.weapon = Hyperspace.Blueprints:GetWeaponBlueprint(weapon)
				weaponEvent.text.data = eventString
				weaponEvent.text.isLiteral = true
			else
				addComponentStep(tempEvent, weapon, craftingData, itemLevel + 1, 1)
			end
		else
			addComponentStep(tempEvent, weapon, craftingData, itemLevel, itemAmount + 1)
		end
	end
end

script.on_internal_event(Defines.InternalEvents.PRE_CREATE_CHOICEBOX, function(event)
	if event.eventName == "COMBO_MAIN_MENU" then
		local player = Hyperspace.ships.player
		local eventManager = Hyperspace.Event
		craftedItemsVisible = {}
		for weapon, craftingData in pairs(craftedWeapons) do
			local weaponBlueprint = Hyperspace.Blueprints:GetWeaponBlueprint(weapon)
			local displayOption = false
			for _, components in ipairs(craftingData.components) do
				for _, needed in ipairs(components) do
					if player:HasEquipment(needed) > 0 then
						displayOption = true
						break
					end
				end
			end
			if displayOption then
				local weaponEvent = eventManager:CreateEvent("COMBO_CRAFT", 0, false)
				weaponEvent.eventName = "COMBO_CRAFT_"..weapon
				weaponEvent:AddChoice(weaponEvent, "Blueprint:", emptyReq, false)

				local eventString = weaponBlueprint.desc.title:GetText().." Requires:"
				for i, components in ipairs(craftingData.components) do
					eventString = eventString.."\n  Atleast "..craftingData.component_amounts[i]..":"
					for _, needed in ipairs(components) do
						local tempBlueprint = Hyperspace.Blueprints:GetWeaponBlueprint(needed)
						eventString = eventString.."\n    "..tempBlueprint.desc.title:GetText()
					end
				end
				weaponEvent.text.data = eventString
				weaponEvent.text.isLiteral = true

				local canCraft = true
				for i, components in ipairs(craftingData.components) do
					local amount = 0
					local amount_need = craftingData.component_amounts[i]
					for _, needed in ipairs(components) do
						amount = amount + player:HasEquipment(needed)
					end
					if amount < amount_need then 
						canCraft = false
					end
				end

				if canCraft then
					local craftStepEvent = eventManager:CreateEvent("COMBO_CRAFT_STEP", 0, false)
					weaponEvent:AddChoice(craftStepEvent, "Craft this item.", emptyReq, false)

					addComponentStep(craftStepEvent, weapon, craftingData, 1, 1)
				else
					local tempEvent = eventManager:CreateEvent("OPTION_INVALID", 0, false)
					weaponEvent:AddChoice(tempEvent, "Craft this item.", emptyReq, true)
				end

				event:AddChoice(weaponEvent, weaponBlueprint.desc.title:GetText(), emptyReq, false)
				table.insert(craftedItemsVisible, weapon)
			end
		end
	end
end)

script.on_internal_event(Defines.InternalEvents.POST_CREATE_CHOICEBOX, function(choiceBox, event)
	--print(string.sub(event.eventName, 1, 16).." AND "..string.sub(event.eventName, 17, string.len(event.eventName)))
	if event.eventName == "COMBO_MAIN_MENU" then
		local i = 1
		for choice in vter(choiceBox:GetChoices()) do
			if i > 1 then
				choice.rewards.weapon = Hyperspace.Blueprints:GetWeaponBlueprint(craftedItemsVisible[i-1])
			end
			i = i + 1
		end
	elseif string.sub(event.eventName, 1, 12) == "COMBO_CRAFT_" then
		local weapon = string.sub(event.eventName, 13, string.len(event.eventName))
		local i = 1
		for choice in vter(choiceBox:GetChoices()) do
			if i == 2 then
				choice.rewards.weapon = Hyperspace.Blueprints:GetWeaponBlueprint(weapon)
			end
			i = i + 1
		end
	end
end)