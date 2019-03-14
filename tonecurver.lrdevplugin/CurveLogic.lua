--- CurveLogic.lua
-- This file is responsible for handling logic to convert between the simplified parameters
-- that are offered to the user (e.g. contrast and number of control points) and the 
-- actual tone curve.
-- For settings, see @see CurveLogic.settings for the list of options. 
-- The curve tables are defined by Adobe's format. They are arrays in the form {x1, y1, x2, y2, ...}
-- where (xi, yi) is the ith control point. Both xi and yi are byte values (from 0 to 255) which
-- encode a percentage on the tone grid (from 0% to 100%).

local matrix = require 'matrix'
local CubicSpline = require 'CubicSpline'

local CurveLogic = {}


-- Create the logger and enable the print function.

local LrLogger = import 'LrLogger'
local myLogger = LrLogger( 'libraryLoggerCurveLogic' )
myLogger:enable( "logfile" )

local function outputToLog( message )
	myLogger:trace( message )
end

--- Constructs a settings table.
-- @param controlPoints
-- @param contrastLow
-- @param contrastHigh
-- @param crushLow
-- @param crushHigh
function CurveLogic.settings(controlPoints, contrastLow, contrastHigh, crushLow, crushHigh)
  return {controlPoints = controlPoints, contrastLow = contrastLow, contrastHigh = contrastHigh, crushLow = crushLow, crushHigh = crushHigh}
end

--- Given a table of settings, constructs the table of control points.
-- @param settings The table of settings. 
-- @return The array of control points 
function CurveLogic.makeContrastTable(settings)
  local xs = {}
  local variances = {}
  local ys = {}
  local min = 128 * settings.crushLow
  local max = 255 - (128 * settings.crushHigh)
  for i = 1, settings.controlPoints do
    local x = (i - 1) * 255 / (settings.controlPoints - 1)
    xs[i] = x
    
    if x < 64 then
      variances[i] = -x
    elseif x < 192 then
      variances[i] = x - 128
    else
      variances[i] = 255 - x
    end
    
    local contrast
    local crush
    if x < 128 then
      contrast = settings.contrastLow
      crush = settings.crushLow
    else
      contrast = settings.contrastHigh
      crush = settings.crushHigh
    end
    
    ys[i] = (xs[i] + variances[i] * contrast) * (1 - crush) + crush * 128
  end
  
  local table = {}
  for i = 1, settings.controlPoints do
    table[2*i - 1] = xs[i]
    table[2*i] = ys[i]
  end
  
  return table
end


local function curveTableToSpline(refTable)
  local data = {}
  for i=1, (#refTable / 2) do
    data[i] = {x = refTable[2*i - 1], y = refTable[2*i]}
  end
  table.sort(data, function(lhs, rhs)
    return lhs.x < rhs.x
  end)

  local dataX = {}
  local dataY = {}
  for i, d in pairs(data) do
    dataX[i] = d.x / 255
    dataY[i] = d.y / 255
  end
  return CubicSpline.spline(dataX, dataY)
end

local function curveTableDifference(table1, table2)
  local spline1 = curveTableToSpline(table1)
  local spline2 = curveTableToSpline(table2)
  local diff = 0
  local steps = 0.1
  for x=0,1,steps do
    diff = diff + math.abs(spline1(x) - spline2(x))
  end
  return diff * steps
end


function CurveLogic.minimizeSettingsDifference(table)
  -- TODO improve
  local best_settings = nil
  local best_diff = 2
  for contrastL=-1,1,0.1 do
    for contrastH=-1,1,0.1 do
      for crushL=0,1,0.2 do
        for crushH=0,1,0.2 do
          local settings = CurveLogic.settings(7, contrastL, contrastH, crushL, crushH)
          local diff = curveTableDifference(table, CurveLogic.makeContrastTable(settings))
          if diff < best_diff then
            best_diff = diff
            best_settings = settings
          end
        end
      end
    end
  end
  return best_settings
end


return CurveLogic

















