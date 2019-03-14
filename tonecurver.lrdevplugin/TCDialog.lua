-- Access the Lightroom SDK namespaces.

local LrApplication = import 'LrApplication'
local LrFunctionContext = import 'LrFunctionContext'
local LrBinding = import 'LrBinding'
local LrDialogs = import 'LrDialogs'
local LrView = import 'LrView'
local LrTasks = import 'LrTasks'
local LrDevelopController = import 'LrDevelopController'

local CurveLogic = require 'CurveLogic'

-- Create the logger and enable the print function.

local LrLogger = import 'LrLogger'
local myLogger = LrLogger( 'libraryLogger' )
myLogger:enable( "logfile" )

local function outputToLog( message )
	myLogger:trace( message )
end

--- Apply a given preset to the currently active photo.
-- @param preset A LrDevelopPreset instance which will be applied.
local function applyPreset (preset) 
  local catalog = LrApplication.activeCatalog ()
  LrTasks.startAsyncTask (function ()
      catalog:withWriteAccessDo ("Apply Settings", function ()
          catalog:getTargetPhoto ():applyDevelopPreset (preset, _PLUGIN)
          end, {timeout = 10})
      end)
end

--- Applies a tone curve to the currently active photo.
-- Given four tables, creates a preset which sets the tone curve
-- and applies said preset to the active photo.
-- @param toneTable The lightness tone table.
-- @param toneTableRed The red tone table.
-- @param toneTableGreen The green tone table.
-- @param toneTableBlue The blue tone table.
local function applyToneTableRGB (toneTable, toneTableRed, toneTableGreen, toneTableBlue)
  local preset = {}
  preset["ToneCurvePV2012"] = toneTable
  preset["ToneCurvePV2012Red"] = toneTableRed
  preset["ToneCurvePV2012Green"] = toneTableGreen
  preset["ToneCurvePV2012Blue"] = toneTableBlue
  applyPreset(LrApplication.addDevelopPresetForPlugin(_PLUGIN, "Tone Curve", preset))
end

--- Converts the UI input to the internal settings structure.
-- @param propertyTable The table with the UI data.
-- @return A table as it is used by CurveLogic.lua.
local function extractUISettings(propertyTable)
  if propertyTable.symmetry then
    return {
      lightness = CurveLogic.settings(propertyTable.controlPoints, propertyTable.contrastLl / 100.0,  propertyTable.contrastLl / 100.0, propertyTable.crushLl / 100.0, propertyTable.crushLl / 100.0),
      red = CurveLogic.settings(propertyTable.controlPoints, propertyTable.contrastRl / 100.0,  propertyTable.contrastRl / 100.0, propertyTable.crushRl / 100.0, propertyTable.crushRl / 100.0),
      green = CurveLogic.settings(propertyTable.controlPoints, propertyTable.contrastGl / 100.0,  propertyTable.contrastGl / 100.0, propertyTable.crushGl / 100.0, propertyTable.crushGl / 100.0),
      blue = CurveLogic.settings(propertyTable.controlPoints, propertyTable.contrastBl / 100.0,  propertyTable.contrastBl / 100.0, propertyTable.crushBl / 100.0, propertyTable.crushBl / 100.0),
    }
  else
    return {
      lightness = CurveLogic.settings(propertyTable.controlPoints, propertyTable.contrastLl / 100.0,  propertyTable.contrastLh / 100.0, propertyTable.crushLl / 100.0, propertyTable.crushLh / 100.0),
      red = CurveLogic.settings(propertyTable.controlPoints, propertyTable.contrastRl / 100.0,  propertyTable.contrastRh / 100.0, propertyTable.crushRl / 100.0, propertyTable.crushRh / 100.0),
      green = CurveLogic.settings(propertyTable.controlPoints, propertyTable.contrastGl / 100.0,  propertyTable.contrastGh / 100.0, propertyTable.crushGl / 100.0, propertyTable.crushGh / 100.0),
      blue = CurveLogic.settings(propertyTable.controlPoints, propertyTable.contrastBl / 100.0,  propertyTable.contrastBh / 100.0, propertyTable.crushBl / 100.0, propertyTable.crushBh / 100.0),
    }
  end
end

--- Updates the tone table according to the UI settings.
-- @param propertyTable The table with the UI data.
local function updateToneTable(propertyTable)
  local settings = extractUISettings(propertyTable)
  applyToneTableRGB(
    CurveLogic.makeContrastTable(settings.lightness),
    CurveLogic.makeContrastTable(settings.red),
    CurveLogic.makeContrastTable(settings.green),
    CurveLogic.makeContrastTable(settings.blue)
  )
end

--- Creates a widget with an integral slider, a label, and an edit field displaying the slider's value.
-- @param factory An LrView factory object to construct the widgets.
-- @param property Name of the property to be bound to the slider value.
-- @param label Text used for the label.
-- @param minVal Minimum value of the slider.
-- @param maxVal Maximum value of the slider.
-- @return A widget to be used by LrView or similar.
local function makeLabeledSlider(factory, property, label, minVal, maxVal)
  return factory:column {
    factory:slider {
      value = LrView.bind(property),
      min = minVal,
      max = maxVal,
      integral = true,
      width = LrView.share( "slider_width" )
    },
    
    factory:spacer {
      height = 5
    },
    
    factory:row {
      factory:static_text {
        place_horizontal = 0,
        title = label
      },
      factory:edit_field {
        place_horizontal = 0.9,
        value = LrView.bind(property),
        width_in_digits = 7
      }
    }
  }
end

local function getCurrentCurveTable()
  local devSettings = nil
  devSettings = LrApplication.activeCatalog():getTargetPhoto():getDevelopSettings()
  return devSettings.ToneCurvePV2012, devSettings.ToneCurvePV2012Red, devSettings.ToneCurvePV2012Green, devSettings.ToneCurvePV2012Blue
end

--- Sets up the property table for the UI when it is first opened.
-- @param context
-- @return The property table.
local function initPropertyTable(context)
  local table = LrBinding.makePropertyTable( context )
  
  table.controlPoints = 5
  table.contrastLl = 0
  table.contrastRl = 0
  table.contrastGl = 0
  table.contrastBl = 0
  table.crushLl = 0
  table.crushRl = 0
  table.crushGl = 0
  table.crushBl = 0
  table.contrastLh = 0
  table.contrastRh = 0
  table.contrastGh = 0
  table.contrastBh = 0
  table.crushLh = 0
  table.crushRh = 0
  table.crushGh = 0
  table.crushBh = 0
  table.autoUpdate = false
  table.symmetry = false
  
  -- TODO WIP does this work like this?
  local devSettings = LrApplication.activeCatalog():getTargetPhoto():getDevelopSettings()
  local currentL, currentR, currentG, currentB = getCurrentCurveTable()
  
  local best_settings = CurveLogic.minimizeSettingsDifference(currentL)
  table.contrastLl = best_settings.contrastLow * 100
  table.contrastLh = best_settings.contrastHigh * 100
  table.crushLl = best_settings.crushLow * 100
  table.crushLh = best_settings.crushHigh * 100
  
  best_settings = CurveLogic.minimizeSettingsDifference(currentR)
  table.contrastRl = best_settings.contrastLow * 100
  table.contrastRh = best_settings.contrastHigh * 100
  table.crushRl = best_settings.crushLow * 100
  table.crushRh = best_settings.crushHigh * 100
  
  best_settings = CurveLogic.minimizeSettingsDifference(currentG)
  table.contrastGl = best_settings.contrastLow * 100
  table.contrastGh = best_settings.contrastHigh * 100
  table.crushGl = best_settings.crushLow * 100
  table.crushGh = best_settings.crushHigh * 100
  
  best_settings = CurveLogic.minimizeSettingsDifference(currentB)
  table.contrastBl = best_settings.contrastLow * 100
  table.contrastBh = best_settings.contrastHigh * 100
  table.crushBl = best_settings.crushLow * 100
  table.crushBh = best_settings.crushHigh * 100
  
  for _, x in pairs({'controlPoints', 'contrastLl', 'contrastRl', 'contrastGl', 'contrastBl', 'crushLl', 'crushRl', 'crushGl', 'crushBl', 'contrastLh', 'contrastRh', 'contrastGh', 'contrastBh', 'crushLh', 'crushRh', 'crushGh', 'crushBh'}) do
      table:addObserver(x, function(thisTable, key, newValue)
          if table.autoUpdate then
            updateToneTable(table)
          end
      end)
    end
    
  table:addObserver('symmetry', function(thisTable, key, newValue)
      if newValue then
        if table.autoUpdate then
          updateToneTable(table)
        end
      else 
        thisTable.contrastLh = thisTable.contrastLl
        thisTable.contrastRh = thisTable.contrastRl
        thisTable.contrastGh = thisTable.contrastGl
        thisTable.contrastBh = thisTable.contrastBl
        thisTable.crushLh = thisTable.crushLl
        thisTable.crushRh = thisTable.crushRl
        thisTable.crushGh = thisTable.crushGl
        thisTable.crushBh = thisTable.crushBl
      end
  end)

  return table
end

--- Creates the main UI with all its elements.
-- @param table The property table to be used for all values.
-- @return A widget.
local function initUI(table)
  local f = LrView.osFactory()
  return f:column {
    bind_to_object = table,
    spacing = f:control_spacing(),
    
    f:row {
      -- Control points
      f:group_box {
        title = "Control points",
        font = "<system>",
        f:row {
          f:slider {
            value = LrView.bind( "controlPoints" ),
            min = 2,
            max = 8,
            integral = true,
            width = LrView.share( "slider_width" )
          },
          
          f:edit_field {
            value = LrView.bind( "controlPoints" ),
            width_in_digits = 2
          },
        },
      },
      
      f:spacer {
        width = 15
      },
    
      -- Update
      f:group_box {
        title = "Updates",
        font = "<system>",
        f:row {
          f:push_button {
            title = "Update image",
            action = function()
              updateToneTable(table)
            end
          },
          f:checkbox {
            title = "Auto update",
            value = LrView.bind("autoUpdate")
          }
        }
      },
      
      f:spacer {
        width = 15
      },
      
      -- Symmetric
      f:checkbox {
        title = "Symmetry",
        value = LrView.bind("symmetry"),
        place_vertical = 0.5,
      },
    },
    
    -- Reset
    f:group_box {
      title = "Reset",
      font = "<system>",
      f:row {
        f:push_button {
          title = "Reset L",
          action = function()
            table.contrastLl = 0
            table.contrastLh = 0
            table.crushLl = 0
            table.crushLh = 0
            updateToneTable(table)
          end
        },
        f:push_button {
          title = "Reset R",
          action = function()
            table.contrastRl = 0
            table.contrastRh = 0
            table.crushRl = 0
            table.crushRh = 0
            updateToneTable(table)
          end
        },
        f:push_button {
          title = "Reset G",
          action = function()
            table.contrastGl = 0
            table.contrastGh = 0
            table.crushGl = 0
            table.crushGh = 0
            updateToneTable(table)
          end
        },
        f:push_button {
          title = "Reset B",
          action = function()
            table.contrastBl = 0
            table.contrastBh = 0
            table.crushBl = 0
            table.crushBh = 0
            updateToneTable(table)
          end
        },
      },
    },
  
    -- Contrast (lower)
    f:group_box {
      title = "Contrast",
      font = "<system>",
      f:row {
        makeLabeledSlider(f, 'contrastLl', 'Lightness', -100, 100),
        makeLabeledSlider(f, 'contrastRl', 'Red', -100, 100),
        makeLabeledSlider(f, 'contrastGl', 'Green', -100, 100),
        makeLabeledSlider(f, 'contrastBl', 'Blue', -100, 100),
      },
    },
    
    -- Contrast (higher)
    f:group_box {
      title = "Contrast (upper end)",
      font = "<system>",
      visible = LrBinding.negativeOfKey( "symmetry" ),
      f:row {
        makeLabeledSlider(f, 'contrastLh', 'Lightness', -100, 100),
        makeLabeledSlider(f, 'contrastRh', 'Red', -100, 100),
        makeLabeledSlider(f, 'contrastGh', 'Green', -100, 100),
        makeLabeledSlider(f, 'contrastBh', 'Blue', -100, 100),
      },
    },
  
    -- Endpoints (lower)
    f:group_box {
      title = "Endpoints",
      font = "<system>",
      f:row {
        makeLabeledSlider(f, 'crushLl', 'Lightness', 0, 100),
        makeLabeledSlider(f, 'crushRl', 'Red', 0, 100),
        makeLabeledSlider(f, 'crushGl', 'Green', 0, 100),
        makeLabeledSlider(f, 'crushBl', 'Blue', 0, 100),
      },
    },
    
    -- Endpoints (higher)
    f:group_box {
      title = "Endpoints (upper end)",
      font = "<system>",
      visible = LrBinding.negativeOfKey( "symmetry" ),
      f:row {
        makeLabeledSlider(f, 'crushLh', 'Lightness', 0, 100),
        makeLabeledSlider(f, 'crushRh', 'Red', 0, 100),
        makeLabeledSlider(f, 'crushGh', 'Green', 0, 100),
        makeLabeledSlider(f, 'crushBh', 'Blue', 0, 100),
      },
    },
  }
end

-- Show the dialog.
LrTasks.startAsyncTask(function()
  LrFunctionContext.callWithContext( "showCustomDialogWithMultipleBind", function( context )
    local table = initPropertyTable(context)
    local c = initUI(table)
    LrDialogs.presentModalDialog {
      title = "Custom Dialog Multiple Bind",
      contents = c
    }
  end)
end)
