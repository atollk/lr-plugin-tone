--[[    
    Tone Curve Editor
    Copyright (C) 2019 Andreas Tollkötter

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.

------------------------------------------------------------------------------]]

return {
	
	LrSdkVersion = 3.0,
	LrSdkMinimumVersion = 1.3, -- minimum SDK version required by this plug-in

	LrToolkitIdentifier = 'org.wurstinator.lightroom.tone-curve',

	LrPluginName = LOC "$$$/Test/PluginName=Tone Curve Editor",
	
	LrExportMenuItems = {
		title = "Tone Curve Editor",
		file = "TCDialog.lua",
	},

	VERSION = { major=1, minor=0, revision=0, },

}


	
