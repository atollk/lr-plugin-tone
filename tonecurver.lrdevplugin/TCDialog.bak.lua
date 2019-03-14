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

--[[
	Demonstrates a custom dialog with a multi binding, two properties from
	separate tables are bound to the value of a text field.  The dialog displays two
	sliders.  Each slider's value is shown in a field next to the slider.  A third text field
	displays the values from both sliders.
	
	Whenever either of the sliders' value changes the third text field will be updated.
	The binding is done by overriding the default property table for the key value that resides
	in the second property table.
]]
local function showCustomDialogWithMultipleBind()

	LrFunctionContext.callWithContext( "showCustomDialogWithMultipleBind", function( context )
		
		-- Create two observable tables.
		
		local table = LrBinding.makePropertyTable( context )
    
    table.contrastL = 0
    table.contrastR = 0
    table.contrastG = 0
    table.contrastB = 0
		
		local f = LrView.osFactory()
		
		local c = f:column {
		
			bind_to_object = table,
			spacing = f:control_spacing(),
		
      -- Lightness
			f:row {
				f:group_box {
					title = "Tone contrast",
					font = "<system>",
					f:slider {
						value = LrView.bind( "contrastL" ),
						min = -100,
						max = 100,
            integral = true,
						width = LrView.share( "slider_width" )
					},
					
					f:edit_field {
						place_horizontal = 0.5,
						value = LrView.bind( "contrastL" ),
						width_in_digits = 7
					},
				},
      },
      
      -- Red
			f:row {
				f:group_box {
					title = "Red contrast",
					font = "<system>",
					f:slider {
						value = LrView.bind( "contrastR" ),
						min = -100,
						max = 100,
            integral = true,
						width = LrView.share( "slider_width" )
					},
					
					f:edit_field {
						place_horizontal = 0.5,
						value = LrView.bind( "contrastR" ),
						width_in_digits = 7
					},
				},
      },
      
      -- Green
			f:row {
				f:group_box {
					title = "Green contrast",
					font = "<system>",
					f:slider {
						value = LrView.bind( "contrastG" ),
						min = -100,
						max = 100,
            integral = true,
						width = LrView.share( "slider_width" )
					},
					
					f:edit_field {
						place_horizontal = 0.5,
						value = LrView.bind( "contrastG" ),
						width_in_digits = 7
					},
				},
      },
      
      -- Blue
			f:row {
				f:group_box {
					title = "Blue contrast",
					font = "<system>",
					f:slider {
						value = LrView.bind( "contrastB" ),
						min = -100,
						max = 100,
            integral = true,
						width = LrView.share( "slider_width" )
					},
					
					f:edit_field {
						place_horizontal = 0.5,
						value = LrView.bind( "contrastB" ),
						width_in_digits = 7
					},
				},
      },
      
      
      -- foo
      f:push_button {
        title = "Log Tone",
        action = function()
          LrTasks.startAsyncTask(function()
            catalog = LrApplication.activeCatalog()
            photo = catalog:getTargetPhoto()
            devset = photo:getDevelopSettings()
            tone = devset.ToneCurvePV2012
          
            outputToLog( "Log button clicked." )
          
            outputToLog( tone )
            
            for k,v in pairs(tone) do
              outputToLog(k)
              outputToLog(v)
            end
          end)
        end
      },
      
      
      
      
      -- foo2
      f:push_button {
        title = "Log Tone from preset",
        action = function()
          LrTasks.startAsyncTask(function()
            folders = LrApplication.developPresetFolders()
            outputToLog( "Log button 2 clicked." )
            tone_folder = folders[10]:getDevelopPresets()
            foo_preset = tone_folder[5]
            for i,h in pairs(foo_preset:getSetting()) do
              outputToLog(i)
              outputToLog(h)
            end
          end)
        end
      },
      
      
      -- bar
      f:push_button {
        title = "Test set Tone",
        action = function()
          outputToLog( "Set button clicked. Start" )
          local tone = {}
          tone[1] = 0
          tone[2] = 128
          tone[3] = 255
          tone[4]= 200
          local pset = {}
          pset["ToneCurvePV2012"] = tone
          pset["Saturation"] = 50
          outputToLog( "Set button clicked. 2" )
          local preset = LrApplication.addDevelopPresetForPlugin(_PLUGIN, "test", pset)
          outputToLog( "Set button clicked. 3" )
          --preset = LrApplication.developPresetFolders ()[1]:getDevelopPresets ()[1]
          applyPreset(preset)
          outputToLog( "Set button clicked. Done" )
        end
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
