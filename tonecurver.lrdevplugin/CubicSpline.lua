--- CubicSpline.lua
-- Used to compute cubic spline functions.
-- Based on the definition from https://de.wikipedia.org/wiki/Spline-Interpolation


local CubicSpline = {}

local matrix = require 'matrix'


-- Create the logger and enable the print function.

--local LrLogger = import 'LrLogger'
--local myLogger = LrLogger( 'libraryLoggerCubicSpline' )
--myLogger:enable( "logfile" )

--local function outputToLog( message )
--	myLogger:trace( message )
--end

--- From given data points, returns the vector of moments.
-- @param dataX The x coordinates of the data points. Has to be sorted ascendingly.
-- @param dataY The y coordinates of the data points. Has to have the same size as dataX.
-- @return A vector of #dataX moment values.
function CubicSpline.moments(dataX, dataY)
  -- Construct the linear equation system.
  local n = #dataX - 1
  local A = {}
  
  -- Edge cases defined by six parameters.
  local mu0 = 1
  local mun = 1
  local lam0 = 0
  local lamn = 0
  local b0 = 0
  local bn = 0
  
  A[1] = {mu0, lam0}
  for i=3, n+1 do
    A[1][i] = 0
  end
  A[1][n+2] = b0
  
  A[n+1] = {}
  for i=1, n-1 do
    A[n+1][i] = 0
  end
  A[n+1][n] = lamn
  A[n+1][n+1] = mun
  A[n+1][n+2] = bn
  
  -- Regular rows
  local h = {}
  for i=1, n do
    h[i] = dataX[i+1] - dataX[i]
  end
  
  for i=2, n do
    local row = {}
    for j=1, i-1 do
      row[j] = 0
    end
    row[i-1] = h[i-1] / 6
    row[i] = (h[i-1] + h[i]) / 3
    row[i+1] = h[i] / 6
    for j=i+2, n+1 do
      row[j] = 0
    end
    row[n+2] = (dataY[i+1] - dataY[i]) / h[i] - (dataY[i] - dataY[i-1]) / h[i-1]
    A[i] = row
  end
  
  -- Solve
  matrix.dogauss(A)
  local sol = {}
  for i=1, n+1 do
    sol[i] = A[i][n+2]
  end
  return sol
end


--- Returns the spline as a function.
-- @param dataX The x coordinates of the data points. Has to be sorted ascendingly.
-- @param dataY The y coordinates of the data points. Has to have the same size as dataX.
-- @return A callable function.
function CubicSpline.spline(dataX, dataY)
  local moments = CubicSpline.moments(dataX, dataY)

  -- Compute each spline function.
  local splines = {}
  for i=1, (#moments - 1) do
    splines[i] = function(x)
      local hi = (dataX[i+1] - dataX[i])
      local a1 = math.pow(dataX[i+1] - x, 3) / hi
      local a2 = math.pow(x - dataX[i], 3) / hi
      local b = (a1 * moments[i] + a2 * moments[i+1]) / 6
      local c = (dataY[i+1] - dataY[i]) / hi - hi * (moments[i+1] - moments[i]) / 6
      local d = dataY[i] - hi * hi * moments[i] / 6
      return b + c * (x - dataX[i]) + d
    end
  end
  
  -- Merge the splines.
  return function(x)
    local i = 1
    while dataX[i] < x and i < #moments-1 do
      i = i+1
    end
    return splines[i](x)
  end
end
  


return CubicSpline













