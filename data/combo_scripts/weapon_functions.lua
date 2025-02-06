
local function offset_point_direction(oldX, oldY, angle, distance)
	local newX = oldX + (distance * math.cos(math.rad(angle)))
	local newY = oldY + (distance * math.sin(math.rad(angle)))
	return Hyperspace.Pointf(newX, newY)
end

mods.combo.burstPinpoints = {}
local burstPinpoints = mods.combo.burstPinpoints
burstPinpoints["COMBO_BURST_FOCUS_1_1"] = "FOCUS_1"
burstPinpoints["COMBO_BURST_FOCUS_2_1"] = "FOCUS_1"
burstPinpoints["COMBO_BURST_FOCUS_3_1"] = "FOCUS_1"
burstPinpoints["COMBO_BURST_FOCUS_1_2"] = "FOCUS_2"
burstPinpoints["COMBO_BURST_FOCUS_2_2"] = "FOCUS_2"
burstPinpoints["COMBO_BURST_FOCUS_3_2"] = "FOCUS_2"
burstPinpoints["COMBO_BURST_FOCUS_1_3"] = "FOCUS_3"
burstPinpoints["COMBO_BURST_FOCUS_2_3"] = "FOCUS_3"
burstPinpoints["COMBO_BURST_FOCUS_3_3"] = "FOCUS_3"

script.on_internal_event(Defines.InternalEvents.PROJECTILE_FIRE, function(projectile, weapon)
	if weapon.blueprint and burstPinpoints[weapon.blueprint.name] then
		local burstPinpointBlueprint = Hyperspace.Blueprints:GetWeaponBlueprint(burstPinpoints[weapon.blueprint.name])

		local spaceManager = Hyperspace.App.world.space
		local beam = spaceManager:CreateBeam(
			burstPinpointBlueprint, 
			projectile.position, 
			projectile.currentSpace, 
			projectile.ownerId, 
			projectile.target, 
			Hyperspace.Pointf(projectile.target.x, projectile.target.y + 1), 
			projectile.destinationSpace, 
			1, 
			-0.1)
		beam.sub_start = offset_point_direction(projectile.target.x, projectile.target.y, projectile.entryAngle, 600)
		projectile:Kill()
	end
end)