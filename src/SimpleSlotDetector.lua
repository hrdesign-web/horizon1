--@class SimpleSlotDetector
core = nil
antigrav = nil
warpDrive = nil
radarUnit = nil
flightModeDb = nil

function getElements()
  for k,var in pairs(_G) do
    if type(var) == "table" and var["getElementClass"] then
      local class = var["getElementClass"]()

      if class == "CoreUnitDynamic" or class == "CoreUnitStatic" or class == "CoreUnitSpace" then
        core = var
      end
      
      if class == "AtmoFuelContainer" or class == "SpaceFuelContainer" then
        var.show()
      end
      
      if class == "WarpDriveUnit" then
        warpDrive = var
        var.show()
      end
      
      if class == "RadarPvPAtmospheric" or class == "RadarPvPSpace" then
        radarUnit = var
        var.show()
      end
      
      if class == "DataBankUnit" then
        flightModeDb = var
      end
      
      if class == "AntiGravityGeneratorUnit" then
        antigrav = var
      end
    end
  end
end

getElements()


