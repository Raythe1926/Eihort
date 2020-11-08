
-- This module provides localization functions


-- The localized string table
local localization = { };

------------------------------------------------------------------------------
function LANG( id, val )
	-- Main localization entrypoint
	-- Call as LANG"<string code>"
	-- or LANG("<string code>", arg) when the string contains a replaceable $$
	local s = localization[id] or "[["..id.."]]";
	if val then
		s = string.gsub( LANG(id), "%$%$", val );
	end
	return s;
end

------------------------------------------------------------------------------
local function loadLangFile( langname )
	-- Loads a language file and incorporates it into the localized string table
	
	local langfile = eihort.ProgramPath .. "/lang/" .. string.lower(langname) .. ".txt";
	local f = io.open( langfile, "rb" );
	if f then
		local langdata, err;
		if f:read(3) ~= "﻿" then
			f:close();
			f = io.open( langfile, "rb" );
		end
		langdata = f:read("*a");
		f:close();

		local langchunk;
		langchunk, err = loadstring( langdata, string.match(langfile, "[^/\\]*$"), nil, localization );
		if langchunk then
			local success;
			success, err = pcall( langchunk );
			if success then
				return;
			end
		end

		eihort.errorDialog( "Error", "Failed to read the localization file. Text may not be displayed correctly.\n\nThe specific error was:\n" .. err );
	end
end

------------------------------------------------------------------------------
function InitLocalization( language )
	-- Main localization initialization function
	-- To be called with the language selected by the user
	
	language = language or eihort.getSystemLanguage();
	if language and language ~= "en" then
		local language_nocountry = string.match( language, "^%w+" );

		if language_nocountry ~= language and language_nocountry ~= "en"then
			loadLangFile( language_nocountry );
		end
		loadLangFile( language );
	end
end


-- Load the base English file as a default
loadLangFile( "en" );
