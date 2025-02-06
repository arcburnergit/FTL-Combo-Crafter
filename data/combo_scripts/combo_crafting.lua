mods.combo = {}

local vter = mods.multiverse.vter

mods.combo.craftedWeapons = {}
local craftedWeapons = mods.combo.craftedWeapons
table.insert(craftedWeapons, {weapon = "COMBO_BURST_FOCUS_1_1", component_amounts = {1, 1}, components = {{"LASER_BURST_2", "LASER_CHAINGUN", "LASER_CHARGEGUN"}, {"FOCUS_1"}}} )
table.insert(craftedWeapons, {weapon = "COMBO_BURST_FOCUS_2_1", component_amounts = {1, 1}, components = {{"LASER_BURST_3", "LASER_CHARGEGUN_2"}, {"FOCUS_1"}}} )
table.insert(craftedWeapons, {weapon = "COMBO_BURST_FOCUS_3_1", component_amounts = {1, 1}, components = {{"LASER_BURST_5", "LASER_CHAINGUN_2"}, {"FOCUS_1"}}} )

table.insert(craftedWeapons, {weapon = "COMBO_BURST_FOCUS_1_2", component_amounts = {1, 1}, components = {{"LASER_BURST_2", "LASER_CHAINGUN", "LASER_CHARGEGUN"}, {"FOCUS_2"}}} )
table.insert(craftedWeapons, {weapon = "COMBO_BURST_FOCUS_2_2", component_amounts = {1, 1}, components = {{"LASER_BURST_3", "LASER_CHARGEGUN_2"}, {"FOCUS_2"}}} )
table.insert(craftedWeapons, {weapon = "COMBO_BURST_FOCUS_3_2", component_amounts = {1, 1}, components = {{"LASER_BURST_5", "LASER_CHAINGUN_2"}, {"FOCUS_2"}}} )

table.insert(craftedWeapons, {weapon = "COMBO_BURST_FOCUS_1_3", component_amounts = {1, 1}, components = {{"LASER_BURST_2", "LASER_CHAINGUN", "LASER_CHARGEGUN"}, {"FOCUS_3", "FOCUS_CHAIN"}}} )
table.insert(craftedWeapons, {weapon = "COMBO_BURST_FOCUS_2_3", component_amounts = {1, 1}, components = {{"LASER_BURST_3", "LASER_CHARGEGUN_2"}, {"FOCUS_3", "FOCUS_CHAIN"}}} )
table.insert(craftedWeapons, {weapon = "COMBO_BURST_FOCUS_3_3", component_amounts = {1, 1}, components = {{"LASER_BURST_5", "LASER_CHAINGUN_2"}, {"FOCUS_3", "FOCUS_CHAIN"}}} )

table.insert(craftedWeapons, {weapon = "COMBO_ION_FIRESTART_1", component_amounts = {1, 1}, components = {{"ION_2"}, {"LASER_FIRE"}}} )
table.insert(craftedWeapons, {weapon = "COMBO_ION_FIRESTART_2", component_amounts = {1, 1}, components = {{"ION_3"}, {"LASER_FIRE"}}} )
table.insert(craftedWeapons, {weapon = "COMBO_ION_FIRESTART_3", component_amounts = {1, 1}, components = {{"ION_4"}, {"LASER_FIRE"}}} )

local craftedItemsVisible = {}
local emptyReq = Hyperspace.ChoiceReq()
local blueReq = Hyperspace.ChoiceReq()
blueReq.object = "pilot"
blueReq.blue = true
blueReq.max_level = mods.multiverse.INT_MAX
blueReq.max_group = -1

function TEST(needed)
	local neededBlueprint = Hyperspace.Blueprints:GetWeaponBlueprint(needed) or Hyperspace.Blueprints:GetDroneBlueprint(needed) or Hyperspace.Blueprints:GetAugmentBlueprint(needed)
	print(neededBlueprint.desc.title:GetText())
end

local function addComponentStep(currentEvent, weapon, craftingData, itemLevel, itemAmount)
	--print(weapon.." ITEM LEVEL AT: "..itemLevel.." NEEDS: "..#craftingData.components.." ITEM AMOUNT AT: "..itemAmount.." NEEDS: "..craftingData.component_amounts[itemLevel])
	local eventManager = Hyperspace.Event
	local player = Hyperspace.ships.player
	currentEvent:RemoveChoice(0)
	for _, needed in ipairs(craftingData.components[itemLevel]) do
		if player:HasEquipment(needed) > 0 then
			local tempEvent = eventManager:CreateEvent("COMBO_CRAFT_STEP", 0, false)
			tempEvent.stuff.removeItem = needed
			local neededBlueprint = Hyperspace.Blueprints:GetWeaponBlueprint(needed) or Hyperspace.Blueprints:GetDroneBlueprint(needed) or Hyperspace.Blueprints:GetAugmentBlueprint(needed)
			currentEvent:AddChoice(tempEvent, "Use your "..neededBlueprint.desc.title:GetText(), emptyReq, false)
			if itemAmount >= craftingData.component_amounts[itemLevel] then
				if itemLevel >= #craftingData.components then
					tempEvent.stuff.weapon = Hyperspace.Blueprints:GetWeaponBlueprint(weapon)
					tempEvent.text.data = "You follow the supplied blueprint and eventually come away with a new item."
					tempEvent.text.isLiteral = true
				else
					addComponentStep(tempEvent, weapon, craftingData, itemLevel + 1, 1)
				end
			else
				addComponentStep(tempEvent, weapon, craftingData, itemLevel, itemAmount + 1)
			end
		end
	end
end

script.on_internal_event(Defines.InternalEvents.PRE_CREATE_CHOICEBOX, function(event)
	if event.eventName == "COMBO_MAIN_MENU" then
		local player = Hyperspace.ships.player
		local eventManager = Hyperspace.Event
		craftedItemsVisible = {}
		for _, craftingData in ipairs(craftedWeapons) do
			local weapon = craftingData.weapon
			local weaponBlueprint = Hyperspace.Blueprints:GetWeaponBlueprint(weapon)
			local displayOption = false
			for _, components in ipairs(craftingData.components) do
				for _, needed in ipairs(components) do
					if player:HasEquipment(needed) > 0 then
						displayOption = true
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
					weaponEvent:AddChoice(craftStepEvent, "Craft this item.", blueReq, false)

					addComponentStep(craftStepEvent, weapon, craftingData, 1, 1)


					event:AddChoice(weaponEvent, weaponBlueprint.desc.title:GetText(), blueReq, false)
				else
					local tempEvent = eventManager:CreateEvent("OPTION_INVALID", 0, false)
					weaponEvent:AddChoice(tempEvent, "Craft this item.", emptyReq, true)


					event:AddChoice(weaponEvent, weaponBlueprint.desc.title:GetText(), emptyReq, false)
				end

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