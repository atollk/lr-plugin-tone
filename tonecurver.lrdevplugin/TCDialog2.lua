
local LrApplication = import 'LrApplication'


local LrDialogs = import 'LrDialogs'


local LrTasks = import 'LrTasks'


local LrView = import 'LrView'



local catalog = LrApplication.activeCatalog ()


local f = LrView.osFactory()


-- Create the logger and enable the print function.

local LrLogger = import 'LrLogger'
local myLogger = LrLogger( 'libraryLogger' )
myLogger:enable( "logfile" ) -- Pass either a string or a table of actions.

-- Write trace information to the logger.

local function outputToLog( message )
	myLogger:trace( message )
end


local function applyPreset (preset) 
  outputToLog(preset)
  LrTasks.startAsyncTask (function ()
      catalog:withWriteAccessDo ("Apply Settings", function ()
          outputToLog("bar")
          catalog:getTargetPhoto ():applyDevelopPreset (preset, _PLUGIN)
          end, {timeout = 15})
      end)
  end


LrTasks.startAsyncTask (function ()

    local folders = LrApplication.developPresetFolders ()
    local preset1 = folders [1]:getDevelopPresets ()[1]
    local preset2 = folders [1]:getDevelopPresets ()[2]
    local pset = {}
    pset["EnableSplitToning"] = false
    pset["Saturation"] = 10
    local preset3 = LrApplication.addDevelopPresetForPlugin(_PLUGIN, "test", pset)
    preset1 = preset3
    
    LrDialogs.presentModalDialog {title = "Preset Bug", contents = 
        f:column {spacing = f:control_spacing (),
            f:push_button {title = preset1:getName (), 
                action = function () applyPreset (preset1) end},
            f:push_button {title = preset2:getName (), 
                action = function () applyPreset (preset2) end}}}
    end)