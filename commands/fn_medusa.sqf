params ["_computer", "_options", "_command_name"];

private _bruteforce_delay_max = MedusaMaxBruteforceDelay;
private _bruteforce_delay_min = MedusaMinBruteforceDelay;

private _bad_port = ["1", "ftp", "ftp", false, false, "CantBeGuessed", "CantBeGuessed", "", ""];
private _ui_forceable_usernames = ["katz", "yocum", "hydra", "grim", "adams", "harold", "razgriz", "nico", "vann"];
private _ui_forceable_passwords = ["Abc123", "M4ria.12", "P@ssw0rd123", "superman", "1234", "123456", "654321", "SuperPassword", "P3pe123", "Freedom123", "RikersCanadian", "Hydra'sgay", "HaroldsWoke", "HydraYouStupidMotherFucker", "Noooo!N*****", "Nitmhthi", "ShootemKillem", "ThisGamesFuckingBroken", "ICanStillControlIt", "DstandsforDrainsYourCum", "futa", "AdamsLikesFuta", "Hydrasgotasmallpeepee", "BillY!", "RazzleDazzle", "IputmyCatontheMic", "N*****dom", "IsthataBigCockorSomethin?", "IfuckedYourMom", "stupidfixi"];

private _print = {[_computer, _this] call AE3_armaos_fnc_shell_stdout};
private _getTargetPort = {
	params ["_host_ip", "_port"];
	([_computer, DistanceMin] call A3OSHACK_fnc_getFirstRouterWithinCutoffDistance) params ["_router", "_found"];
	if !(_found) then {
		"No suitable network!" call _print;
		breakOut "main";
	};

	private _targetable_host_port_to_return = [];
	private _connected = false;
	([_router, _host_ip] call A3OSHACK_fnc_getTargetableHostWithIP) params ["_targetable_host", "_ok"];
	if (_ok) then {
		([_targetable_host, _port] call A3OSHACK_fnc_getPortFromTargetableHost) params ["_targetable_host_port", "_ok"];
		if (_ok) then {
			_targetable_host_port_to_return = _targetable_host_port;
			_connected = true;
		} else {
			_targetable_host_port_to_return =_bad_port;
		};
	} else {
		_targetable_host_port_to_return =_bad_port;
	};

	[_targetable_host_port_to_return, _connected];
};
private _getActualPortFromPort = { _this select 2 };
private _getCanBruteForceUsername = { _this select 3};
private _getCanBruteForcePassword = { _this select 4};
private _getUsernameFromPort = { _this select 5};
private _getPasswordFromPort = { _this select 6};
private _getOptionalRequiredCliParam1 = { _this select 7};
private _getOptionalRequiredCliParam2 = { _this select 8};
private _findStringsInString =
{
	params ["_string", "_search"];
	if (_string == "") exitWith { [] };
	private _searchLength = count _search;
	private _return = [];
	private _i = 0;
	private _index = 0;
	while { _index = _string find _search; _index != -1 } do
	{
		_string = _string select [_index + _searchLength];
		_i = _i + _index + _searchLength;
		_return pushBack _i - _searchLength;
	};
	_return;
};

private _command_opts = 
[
	["_target_specification", "h", "", "string", "", false, "Target IP:port address"],
	["_username_to_test", "u", "", "string", "", false, "Username to test"],
	["_username_file_to_test", "U", "", "string", "", false, "File containing usernames to test"],
	["_password_to_test", "p", "", "string", "", false, "Password to test"],
	["_password_file_to_test", "P", "", "string", "", false, "File containing passwords to test"],
	["_module", "M", "", "string", "", false, "Name of the module to execute (without the .mod extension)"],
	["_dump_modules", "d", "", "bool", false, false, "Dump all known modules"],
	["_use_ssl", "s", "", "bool", false, false, "Enable SSL"]
];

private _command_syntax = 
[
	[
		["command", _command_name, true, false],
		["options", "OPTIONS", false, false]
	]
];

[] params ([_computer, _options, [_command_name, _command_opts, _command_syntax]] call AE3_armaos_fnc_shell_getOpts);
if !(_ae3OptsSuccess) exitWith {};
private _bruteforce_usernames = (_username_file_to_test != "");
private _bruteforce_passwords = (_password_file_to_test != "");

scopeName "main";

"Medusa v2.2 [http://www.foofus.net] (C) JoMo-Kun / Foofus Net <jmk@foofus.net>" call _print;
" " call _print;

if (_dump_modules) then {
	'	Available modules in "/usr/lib/x86_64-linux-gnu/medusa/modules" :' call _print;
	"		+ ftp.mod : Brute force module for FTP/FTPS sessions : version 2.1" call _print;
	"		+ smb.mod : Brute force module for SMB (LM/NTLM/NTLMv2) sessions: version 2.1" call _print;
	"		+ http.mod : Brute force module for HTTP : version 2.1" call _print;
	breakOut "main";
};

private _target_spec_split = [_target_specification, ":"] call BIS_fnc_splitString;
if ((count _target_spec_split) != 2) then {
	"Invalid target..." call _print;
	breakOut "main";
};

private _host = (_target_spec_split select 0);
private _port = (_target_spec_split select 1);

([_host, _port] call _getTargetPort) params ["_targetable_host_port", "_connected"];

if !(_connected) then {
	"	No valid network device..." call _print;
	breakOut "main";
};

if (_username_to_test != "" and _username_file_to_test != "") then {
	"Invalid flag combination..."
	breakOut "main";
};

if (_password_to_test != "" and _password_file_to_test != "") then {
	"Invalid flag combination..."
	breakOut "main";
};

if (_password_file_to_test != "") then {
	private _password_file_to_test_split = _password_file_to_test splitString "/";
	if ((_password_file_to_test_split select (count _password_file_to_test_split)-1) != "rockyou.txt") then {
		"Failed to open and get passwords from file!" call _print;
		breakOut "main";
	};
};

if (_username_file_to_test != "") then {
	private _username_file_to_test_split = _username_file_to_test splitString "/";
	if ((_username_file_to_test_split select (count _username_file_to_test_split)-1) != "top-usernames.txt") then {
		"Failed to open and get usernames from file!" call _print;
		breakOut "main";
	};
};

private _doBruteForce = {
	params ["_targetable_host_port", "_connected_ok"];

	private _can_brute_force_username = (_targetable_host_port call _getCanBruteForceUsername);
	private _can_brute_force_password = (_targetable_host_port call _getCanBruteForcePassword);
	private _true_username = (_targetable_host_port call _getUsernameFromPort);
	private _true_password = (_targetable_host_port call _getPasswordFromPort);
	private _wins_username = ((_can_brute_force_username and _bruteforce_usernames) or (_username_to_test == _true_username));
	private _wins_password = (_wins_username and ((_can_brute_force_password and _bruteforce_passwords) or (_password_to_test == _true_password)));
	private _wins = ((_wins_username and _wins_password) and _connected_ok);
	private _one_try = _username_to_test != "" and _password_to_test != "";
	private _first_try_win = (_wins and (_username_to_test == _true_username and _password_to_test == _true_password));

	if (!_first_try_win and !_one_try) then {
		if !(_username_to_test == "" and _password_to_test == "") then {
			if (_username_to_test != "") then {
				private _win_after = ((random (count _ui_forceable_passwords)) + 1);
				private _username = _username_to_test;
				for "_count" from 0 to (count _ui_forceable_passwords) - 1 do {
					_password = (_ui_forceable_passwords select _count);
					sleep ((random _bruteforce_delay_max) + _bruteforce_delay_min);

					if (_wins) then {
						if (_win_after <= 0) then {
							break;
						} else {
							_win_after = _win_after - 1;
						};
					};
	
					if !(_connected_ok) then {
						format ["The answer was NOT successfully received, understood, and accepted while trying %1 %2: error code 1", _username, _password] call _print;
					} else {
						format ["ACCOUNT CHECK: [%1] Host: %2 User: %3 Password: %4", _module, _host, _username, _password] call _print;
					};
				};
			};
	
			if (_password_to_test != "") then {
				private _win_after = ((random (count _ui_forceable_usernames)) + 1);
				private _password = _password_to_test;
				for "_count" from 0 to (count _ui_forceable_usernames) - 1 do {
					_username = (_ui_forceable_usernames select _count);
					sleep ((random _bruteforce_delay_max) + _bruteforce_delay_min);

					if (_wins) then {
						if (_win_after <= 0) then {
							break;
						} else {
							_win_after = _win_after - 1;
						};
					};
				
					if !(_connected_ok) then {
						format ["The answer was NOT successfully received, understood, and accepted while trying %1 %2: error code 1", _username, _password] call _print;
					} else {
						format ["ACCOUNT CHECK: [%1] Host: %2 User: %3 Password: %4", _module, _host, _username, _password] call _print;
					};
				};
			};
		} else {
			private _win_after = ((random ((count _ui_forceable_usernames) * (count _ui_forceable_passwords))) + 1);
	
			for "_username_count" from 0 to (count _ui_forceable_usernames) - 1 do {
				scopeName "user_and_pword_brute";
				_username = (_ui_forceable_usernames select _username_count);
				for "_password_count" from 0 to (count _ui_forceable_passwords) - 1 do {
					_password = (_ui_forceable_passwords select _password_count);
					sleep ((random _bruteforce_delay_max) + _bruteforce_delay_min);
	
					if (_wins) then {
						if (_win_after <= 0) then {
							breakOut "user_and_pword_brute";
						} else {
							_win_after = _win_after - 1;
						};
					};
	
					if !(_connected_ok) then {
						format ["The answer was NOT successfully received, understood, and accepted while trying %1 %2: error code 1", _username, _password] call _print;
					} else {
						format ["ACCOUNT CHECK: [%1] Host: %2 User: %3 Password: %4", _module, _host, _username, _password] call _print;
					};
				};
			};
		};
	};

	if (_wins) then {
		_username = _true_username;
		_password = _true_password;
		format ["ACCOUNT FOUND: [%1] Host: %2 User: %3 Password: %4", _module, _host, _username, _password] call _print;
	} else {
		format ["FAILED: [%1]: no identified login credentials for host %2...", _module, _host] call _print;
	};

	" " call _print;
	"Medusa exiting..." call _print;
};

if (_use_ssl) then {
	format ["Wrapping %1 in TLS/SSL", _module] call _print;
	_module = _module + "s";
};

[_targetable_host_port, (_connected and ((_targetable_host_port call _getActualPortFromPort) == _module))] call _doBruteForce;
