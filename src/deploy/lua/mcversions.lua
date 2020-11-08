
-- List of Minecraft versions to help select the best version
-- when trying to autodetect the MC jar

MinecraftVersions = {
	["1.6-pre"]     = "13w26b";
	["1.6"]         = "13w26c";
	["1.6.1-pre"]   = "13w26d";
	["1.6.1"]       = "13w27a";
	["1.6.2-pre"]   = "13w27b";
	["1.6.2"]       = "13w28a";
	["1.6.3-pre"]   = "13w37a";
	["1.6.3"]       = "13w37b";
	["1.6.4"]       = "13w38a";
	["1.7-pre"]     = "13w43b";
	["1.7"]         = "13w43c";
	["1.7.1-pre"]   = "13w43d";
	["1.7.1"]       = "13w43e";
	["1.7.2-pre"]   = "13w43f";
	["1.7.2"]       = "13w43g";
	["1.7.3-pre"]   = "13w49b";
	["1.7.4-pre"]   = "13w50a";
	["1.7.4"]       = "13w50b";
	["1.7.5"]       = "13w50c";
	["1.7.6-pre1"]  = "13w50d";
	["1.7.6-pre2"]  = "13w50e";
	["1.7.6"]       = "13w50f";
	["1.7.7"]       = "13w50g";
	["1.7.8"]       = "13w50h";
	["1.7.9"]       = "13w50i";
	["1.7.10-pre1"] = "13w50j";
	["1.7.10-pre2"] = "13w50k";
	["1.7.10-pre3"] = "13w50l";
	["1.7.10-pre4"] = "13w50m";
	["1.7.10"]      = "13w50n";
	["1.8-pre1"]    = "14w34e";
	["1.8-pre2"]    = "14w35a";
	["1.8-pre3"]    = "14w35b";
	["1.8"]         = "14w36a";
	["1.8.1-pre1"]  = "14w42a";
	["1.8.1-pre2"]  = "14w42b";
	["1.8.1-pre3"]  = "14w43a";
	["1.8.1-pre4"]  = "14w45a";
	["1.8.1-pre5"]  = "14w47a";
	["1.8.1"]       = "14w48a";
	["1.8.2-pre1"]  = "14w51a";
	["1.8.2-pre2"]  = "15w03a";
	["1.8.2-pre3"]  = "15w03b";
	["1.8.2-pre4"]  = "15w03c";
	["1.8.2-pre5"]  = "15w05a";
	["1.8.2-pre6"]  = "15w05b";
	["1.8.2-pre7"]  = "15w08a";
	["1.8.2"]       = "15w08b";
	["1.8.3"]       = "15w08c";
	["1.8.4"]       = "15w16a";
	["1.8.5"]       = "15w21a";
	["1.8.6"]       = "15w22a";
	["1.8.7"]       = "15w23a";
	["1.8.8-pre"]	= "15w31a";
	["1.8.8"]       = "15w31b";
	["1.8.9"]		= "15w31c";
	["1.9-pre1"]    = "16w07c";
	["1.9-pre2"]    = "16w07d";
	["1.9-pre3"]    = "16w08a";
	["1.9-pre4"]    = "16w08b";
	["1.9"]         = "16w09a";
	["1.9.1-pre1"]  = "16w10a";
	["1.9.1-pre2"]  = "16w10b";
	["1.9.1-pre3"]  = "16w10c";
	["1.9.1"]       = "16w13a";
	["1.9.2"]       = "16w13b";
	["1.9.3-pre1"]  = "16w16a";
	["1.9.3-pre2"]  = "16w17a";
	["1.9.3-pre3"]  = "16w18a";
	["1.9.3"]       = "16w19a";
	["1.9.4"]       = "16w19b";
	["1.10-pre1"]   = "16w22a";
	["1.10-pre2"]   = "16w23a";
	["1.10"]        = "16w23b";
	["1.10.1"]      = "16w25a";
	["1.10.2"]      = "16w25b";
	["1.11-pre1"]   = "16w45a";
	["1.11"]        = "16w46a";
	["1.11.1"]      = "16w51a";
	["1.11.2"]      = "16w51b";
	["1.12-pre1"]   = "17w19a";
	["1.12-pre2"]   = "17w19b";
	["1.12-pre3"]   = "17w20a";
	["1.12-pre4"]   = "17w20b";
	["1.12-pre5"]   = "17w20c";
	["1.12-pre6"]   = "17w22a";
	["1.12-pre7"]   = "17w22b";
	["1.12"]        = "17w23a";
	["1.12.1-pre1"] = "17w31b";
	["1.12.1"]      = "17w31c";
	["1.12.2-pre1"] = "17w37a";
	["1.12.2-pre2"] = "17w37b";
	["1.12.2"]      = "17w38a";
	["1.13-pre1"]   = "18w23a";
	["1.13-pre2"]   = "18w24a";
	["1.13-pre3"]   = "18w25a";
	["1.13-pre4"]   = "18w26a";
	["1.13-pre5"]   = "18w26b";
	["1.13-pre6"]   = "18w27a";
	["1.13-pre7"]   = "18w28a";
	["1.13-pre8"]   = "18w28b";
	["1.13-pre9"]   = "18w29a";
	["1.13-pre10"]  = "18w29b";
	["1.13"]        = "18w29c";
	["1.13.1-pre1"] = "18w33a";
	["1.13.1-pre2"] = "18w34a";
	["1.13.1"]      = "18w34b";
	["1.13.2-pre1"] = "18w42a";
	["1.13.2-pre2"] = "18w42b";
	["1.13.2"]      = "18w43a";
	["1.14-pre1"]   = "19w15a";
	["1.14-pre2"]   = "19w15b";
	["1.14-pre3"]   = "19w16a";
	["1.14-pre4"]   = "19w16b";
	["1.14-pre5"]   = "19w16c";
	["1.14"]        = "19w17a";
	["1.14.1-pre1"] = "19w19a";
	["1.14.1-pre2"] = "19w19b";
	["1.14.1"]      = "19w20a";
	["1.14.2-pre1"] = "19w20a";
	["1.14.2-pre2"] = "19w20b";
	["1.14.2-pre3"] = "19w21a";
	["1.14.2-pre4"] = "19w21b";
	["1.14.2"]      = "19w22a";
	["1.14.3-pre1"] = "19w23a";
	["1.14.3-pre2"] = "19w23b";
	["1.14.3-pre3"] = "19w24a";
	["1.14.3-pre4"] = "19w25a";
	["1.14.3"]      = "19w26a";
	["1.14.4-pre1"] = "19w27a";
	["1.14.4-pre2"] = "19w27b";
	["1.14.4-pre3"] = "19w28a";
	["1.14.4-pre4"] = "19w28b";
	["1.14.4-pre5"] = "19w28c";
	["1.14.4-pre6"] = "19w29a";
	["1.14.4-pre7"] = "19w29b";
	["1.14.4"]      = "19w29c";
	["1.15-pre1"]   = "19w47a";
	["1.15-pre2"]   = "19w48a";
	["1.15-pre3"]   = "19w48b";
	["1.15-pre4"]   = "19w49a";
	["1.15-pre5"]   = "19w49b";
	["1.15-pre6"]   = "19w49c";
	["1.15-pre7"]   = "19w50a";
	["1.15"]        = "19w50b";
	["1.15.1-pre1"] = "19w50c";
	["1.15.1"]      = "19w51a";
}