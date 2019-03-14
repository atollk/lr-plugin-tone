--[[----------------------------------------------------------------------------

ADOBE SYSTEMS INCORPORATED
 Copyright 2007 Adobe Systems Incorporated
 All Rights Reserved.

NOTICE: Adobe permits you to use, modify, and distribute this file in accordance
with the terms of the Adobe license agreement accompanying it. If you have received
this file from a source other than Adobe, then your use, modification, or distribution
of it requires the prior written permission of Adobe.

--------------------------------------------------------------------------------

CustomDialogMultipleBind.lua
From the Hello World sample plug-in. Displays several custom dialog and writes debug info.

------------------------------------------------------------------------------]]

-- Access the Lightroom SDK namespaces.

local LrApplication = import 'LrApplication'
local LrFunctionContext = import 'LrFunctionContext'
local LrBinding = import 'LrBinding'
local LrDialogs = import 'LrDialogs'
local LrView = import 'LrView'
local LrLogger = import 'LrLogger'
local LrTasks = import 'LrTasks'
local LrDevelopController = import 'LrDevelopController'

-- Create the logger and enable the print function.

local myLogger = LrLogger( 'libraryLogger' )
myLogger:enable( "logfile" ) -- Pass either a string or a table of actions.

-- Write trace information to the logger.

local function outputToLog( message )
	myLogger:trace( message )
end

local function applyPreset (preset) 
  outputToLog(preset)
  local catalog = LrApplication.activeCatalog ()
  LrTasks.startAsyncTask (function ()
      catalog:withWriteAccessDo ("Apply Settings", function ()
          outputToLog("bar")
          catalog:getTargetPhoto ():applyDevelopPreset (preset, _PLUGIN)
          end, {timeout = 15})
      end)
end

local function applyToneTable (toneTable)
  local preset = {}
  preset["ToneCurvePV2012"] = toneTable
  applyPreset(LrApplication.addDevelopPresetForPlugin(_PLUGIN, "Tone Curve", preset))
end

local function applyToneTableRGB (toneTable, toneTableRed, toneTableGreen, toneTableBlue)
  local preset = {}
  preset["ToneCurvePV2012"] = toneTable
  preset["ToneCurvePV2012Red"] = toneTableRed
  preset["ToneCurvePV2012Green"] = toneTableGreen
  preset["ToneCurvePV2012Blue"] = toneTableBlue
  applyPreset(LrApplication.addDevelopPresetForPlugin(_PLUGIN, "Tone Curve", preset))
end

local function makeContrastTable(controlPoints, contrastLow, contrastHigh, crushLow, crushHigh)
  local xs = {}
  local variances = {}
  local ys = {}
  local min = 128 * crushLow
  local max = 255 - (128 * crushHigh)
  for i = 1, controlPoints do
    local x = (i - 1) * 255 / (controlPoints - 1)
    xs[i] = x
    
    if x < 64 then
      variances[i] = -x
    elseif x < 192 then
      variances[i] = x - 128
    else
      variances[i] = 255 - x
    end
    
    if x < 128 then
      contrast = contrastLow
      crush = crushLow
    else
      contrast = contrastHigh
      crush = crushHigh
    end
    
    ys[i] = (xs[i] + variances[i] * contrast) * (1 - crush) + crush * 128
  end
  
  table = {}
  for i = 1, controlPoints do
    table[2*i - 1] = xs[i]
    table[2*i] = ys[i]
  end
  
  return table
end

local function updateToneTable(propertyTable)
  l_input = {propertyTable.contrastLl / 100.0,  propertyTable.contrastLh / 100.0, propertyTable.crushLl / 100.0, propertyTable.crushLh / 100.0}
  r_input = {propertyTable.contrastRl / 100.0,  propertyTable.contrastRh / 100.0, propertyTable.crushRl / 100.0, propertyTable.crushRh / 100.0}
  g_input = {propertyTable.contrastGl / 100.0,  propertyTable.contrastGh / 100.0, propertyTable.crushGl / 100.0, propertyTable.crushGh / 100.0}
  b_input = {propertyTable.contrastBl / 100.0,  propertyTable.contrastBh / 100.0, propertyTable.crushBl / 100.0, propertyTable.crushBh / 100.0}
  contrast_tables = {}
  for i, inp in pairs({l_input, r_input, g_input, b_input}) do
    if propertyTable.symmetry then
      contrast_tables[i] = makeContrastTable(propertyTable.controlPoints, inp[1], inp[1], inp[3], inp[3])
    else
      contrast_tables[i] = makeContrastTable(propertyTable.controlPoints, inp[1], inp[2], inp[3], inp[4])
    end
  end
  applyToneTableRGB(contrast_tables[1], contrast_tables[2], contrast_tables[3], contrast_tables[4])
end

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

local function showCustomDialogWithMultipleBind()

	LrFunctionContext.callWithContext( "showCustomDialogWithMultipleBind", function( context )
		
		-- Create two observable tables.
		
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
    updateToneTable(table)
    
    table.autoUpdate = false
    table.symmetry = true
    
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
		
		local f = LrView.osFactory()
		
		local c = f:column {
		
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
		
		LrDialogs.presentModalDialog {
			title = "Custom Dialog Multiple Bind",
			contents = c
		}
		
	end )


end

-- Now display the dialogs.

showCustomDialogWithMultipleBind()
