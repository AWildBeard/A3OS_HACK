params ["_computer", "_options", "_command_name"];

private _default_scan_delay = NmapBaseScanDelay;
private _default_full_scan_delay = NmapFullScanDelay;
private _default_version_check_delay = NmapScanThuroughnessTimePenalty;

private _print = {[_computer, _this] call AE3_armaos_fnc_shell_stdout};
private _getRouterIpAddr = {_this select 2};
private _getClientIpAddr = {_this select 3};
private _getRouterRespondsToPing = {_this select 5};
private _getTargetDevices = {_this select 6};
private _getTargetedDeviceIp = {_this select 0};
private _getTargetedDeviceRespondsToPing = {_this select 1};
private _getTargetedDevicePorts = {_this select 2};
private _getTargetedDevicePortNumber = {_this select 0};
private _getTargetedDevicePortsServiceName = {
	private _service_name = "";
	params ["_port", "_version_checked"];

	if (_version_checked) then {
		_service_name = _port select 2;
	} else {
		_service_name = _port select 1;
	};

	_service_name;
};

([_computer, DistanceMin] call A3OSHACK_fnc_getFirstRouterWithinCutoffDistance) params ["_router", "_connected"];

private _command_opts = 
[
	["_no_ping_check", "", "Pn", "bool", false, false, "Treat all hosts as online -- skip host discovery"],
	["_syn_scan", "", "sS", "bool", false, false, "TCP SYN/Connect() scan"],
	["_version_check", "", "sV", "bool", false, false, "Probe open ports to determine service/version info"],
	["_write_output_to", "", "oN", "string", "", false, "Output scan in normal format to the given filename"],
	["_ping_scan", "", "sn", "bool", false, false, "Ping Scan - disable port scan"]
];

private _command_syntax = 
[
	[
		["command", _command_name, true, false],
		["options", "OPTIONS", false, false],
		["path", "{target specification}", true, false]
	]
];

[] params ([_computer, _options, [_command_name, _command_opts, _command_syntax]] call AE3_armaos_fnc_shell_getOpts);
if !(_ae3OptsSuccess) exitWith {};

_ae3OptsThings params ["_target_specification"];

scopeName "main";

private _split_target_specification = ([_target_specification, "."] call BIS_fnc_splitString);
private _pointer = _computer getVariable "AE3_Filepointer";
private _filesystem = _computer getVariable "AE3_Filesystem";
private _terminal = _computer getVariable "AE3_terminal";
private _user = _terminal get "AE3_terminalLoginUser";

if (_write_output_to != "") then {
	try {
		[_pointer, _filesystem, _write_output_to, "", _user, _user, [[true, true, false], [true, true, false]]] call AE3_filesystem_fnc_createFile;
	} catch {
		[_computer, [_write_output_to], "rm"] call AE3_armaos_fnc_os_rm;
		[_pointer, _filesystem, _write_output_to, "", _user, _user, [[true, true, false], [true, true, false]]] call AE3_filesystem_fnc_createFile;
	};
	_print = {
		[_computer, _this] call AE3_armaos_fnc_shell_stdout;
		_this = _this + endl;
		[_pointer, _filesystem, _write_output_to, _user, _this, true] call AE3_filesystem_fnc_writeToFile;
	};
};

date params ["_year", "_month", "_day", "_hours", "_minutes"];
format ["Starting Nmap 7.80 (https://nmap.org) at %1-%2-%3 %4:%5 AST", _year, _month, _day, _hours, _minutes] call _print;

if (_connected) then {
	"Using network device eth0" call _print;
} else {
	"Using network device lo" call _print;
	private _first_octet = _split_target_specification select 0;
	if (_first_octet == "127") then {
		"Refusing to scan localhost" call _print;
	} else {
		format ["Unable to access %1", _target_specification] call _print;
		breakOut "main";
	};
};

if (_connected) then {
	if (_ping_scan or _syn_scan) then {
		if (_ping_scan and _no_ping_check) then {
			"Invalid flag combination..." call _print;
			breakOut "main";
		};

		private _is_subnet = (count ([_target_specification, "/"] call BIS_fnc_splitString)) == 2;
		private _split_router_address = [(_router call _getRouterIpAddr), "."] call BIS_fnc_splitString;
		private _scanned_host_count = 0;

		if ((_split_router_address select 0) != (_split_target_specification select 0) or (_split_router_address select 1) != (_split_target_specification select 1) or (_split_router_address select 2) != (_split_target_specification select 2)) then {
			"No route to target..." call _print;
			breakOut "main";
		};

		private _sleep_timer = if (_no_ping_check) then {40} else {10};
		" " call _print;

		if (_is_subnet) then {
			if (_no_ping_check or (_router call _getRouterRespondsToPing)) then {
				if !(_ping_scan) then {
					if (_no_ping_check) then {
						sleep _default_full_scan_delay;
					} else {
						sleep _default_scan_delay;
					};
				};

				format ["Nmap scan report for %1", _router call _getRouterIpAddr] call _print;
				"Host is up" call _print;

				if (!_ping_scan) then {
					format ["All 1000 scanned ports on %1 are closed.", _router call _getRouterIpAddr] call _print;
				};

				_scanned_host_count = _scanned_host_count + 1;
				" " call _print;
			};

			private _target_devices = (_router call _getTargetDevices);
			for "_target_device_count" from 0 to (count _target_devices)-1 do {
				if !(_ping_scan) then {
					if (_no_ping_check) then {
						sleep _default_full_scan_delay;
					} else {
						sleep _default_scan_delay;
					};

					if (_version_check) then {
						sleep _default_version_check_delay;
					};
				};

				private _targetable_device = (_target_devices select _target_device_count);
				if (_no_ping_check or (_targetable_device call _getTargetedDeviceRespondsToPing)) then {
					format ["Nmap scan report for %1", _targetable_device call _getTargetedDeviceIp] call _print;
					"Host is up" call _print;
					if !(_ping_scan) then {
						"PORT 	STATE 	SERVICE" call _print;

						private _targeted_device_ports = (_targetable_device call _getTargetedDevicePorts);
						for "_targeted_device_port_count" from 0 to (count _targeted_device_ports)-1 do {
							private _port = (_targeted_device_ports select _targeted_device_port_count);
							format ["%1 	open 	%2", (_port call _getTargetedDevicePortNumber), ([_port, _version_check] call _getTargetedDevicePortsServiceName)] call _print;
						};
					};

					" " call _print;
				};

				_scanned_host_count = _scanned_host_count + 1;
			};
		} else {
			if (_target_specification == (_router call _getRouterIpAddr)) then {
				if (_no_ping_check or (_router call _getRouterRespondsToPing)) then {
					if !(_ping_scan) then {
						if (_no_ping_check) then {
							sleep _default_full_scan_delay;
						} else {
							sleep _default_scan_delay;
						};
					};

					format ["Nmap scan report for %1", _router call _getRouterIpAddr] call _print;
					"Host is up" call _print;

					if !(_ping_scan) then {
						format ["All 1000 scanned ports on %1 are closed.", _router call _getRouterIpAddr] call _print;
					};

					_scanned_host_count = _scanned_host_count + 1;
					" " call _print;
				};
			} else {
				private _target_devices = (_router call _getTargetDevices);
				for "_target_device_count" from 0 to (count _target_devices)-1 do {
					scopeName "singleTargetDeviceScanSearch";

					private _targetable_device = (_target_devices select _target_device_count);

					if (_target_specification == (_targetable_device call _getTargetedDeviceIp)) then {
						if !(_ping_scan) then {
							if (_no_ping_check) then {
								sleep (_default_full_scan_delay / 2.0);
							} else {
								sleep (_default_scan_delay / 2.0);
							};

							if (_version_check) then {
								sleep (_default_version_check_delay / 2.0);
							};
						};

						if (_no_ping_check or (_targetable_device call _getTargetedDeviceRespondsToPing)) then {
							format ["Nmap scan report for %1", _targetable_device call _getTargetedDeviceIp] call _print;
							"Host is up" call _print;

							if !(_ping_scan) then {
								"PORT 	STATE 	SERVICE" call _print;
	
								private _targeted_device_ports = (_targetable_device call _getTargetedDevicePorts);
								for "_targeted_device_port_count" from 0 to (count _targeted_device_ports)-1 do {
									private _port = (_targeted_device_ports select _targeted_device_port_count);
									format ["%1 	open 	%2", (_port call _getTargetedDevicePortNumber), ([_port, _version_check] call _getTargetedDevicePortsServiceName)] call _print;
								};
							};

							" " call _print;
						};

						_scanned_host_count = _scanned_host_count + 1;
						breakOut "singleTargetDeviceScanSearch";
					}; 
				};
			};
		};

		format ["Nmap done: %1 IP address (%1 host up) scanned", _scanned_host_count] call _print;


	} else {
		"Nothing to do..." call _print;
		breakOut "main";
	};
};

