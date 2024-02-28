params ["_computer", "_options", "_command_name"];

private _remote_computer_var_name = "admin_laptop";

private _bad_port = ["1", "ftp", "ftp", false, false, "CantBeGuessed", "CantBeGuessed", "", ""];
private _print = {[_computer, _this] call AE3_armaos_fnc_shell_stdout};
private _router_id = "";
private _getTargetPort = {
	params ["_host_ip", "_port"];
	([_computer, DistanceMin] call A3OSHACK_fnc_getFirstRouterWithinCutoffDistance) params ["_router", "_found"];
	if !(_found) then {
		"No suitable network!" call _print;
		breakOut "main";
	};

	_router_id = _router select 0;

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

	[_targetable_host_port_to_return, _connected]
};
private _getActualPortFromPort = { _this select 2 };
private _getCanBruteForceUsername = { _this select 3};
private _getCanBruteForcePassword = { _this select 4};
private _getUsernameFromPort = { _this select 5};
private _getPasswordFromPort = { _this select 6};

private _command_opts = [
	["_user_password_combo", "u", "user", "string", "", false, "Server user and password"],
	["_output_file", "o", "output", "string", "", false, "Write output to file instead of stdout"],
	["_upload_file", "T", "upload-file", "string", "", false, "Transfer local file to destination"]

];
private _command_syntax = [
	[
		["command", _command_name, true, false],
		["options", "OPTIONS", true, false],
		["path", "<url>", true, false]
	]
];

[] params ([_computer, _options, [_command_name, _command_opts, _command_syntax]] call AE3_armaos_fnc_shell_getOpts);
if !(_ae3OptsSuccess) exitWith {};

_ae3OptsThings params ["_url"];

scopeName "main";

if (_url == "") then {
	"A URL is required..." call _print;
};

private _do_upload = false;
if (_upload_file != "") then {
	_do_upload = true;
};

private _is_directory = false;
if ((_url select [((count _url)-1), 1]) == "/") then {
	_is_directory = true;
};

private _url_protocol_split = _url splitString ":";
if ((count _url_protocol_split) < 2) then {"Not a valid url" call _print;};
private _protocol = _url_protocol_split select 0;

private _url_slash_split = _url splitString "/";
if ((count _url_slash_split) < 2) then {"Not a valid url" call _print;};
private _targetable_host = _url_slash_split select 1;
private _targetable_host_split = _targetable_host splitString ":";
private _ip = "";
private _port = "";
private _path_elements = [];

if ((count _url_slash_split) > 2) then {
	_path_elements = _url_slash_split;
	_path_elements deleteRange [0, 2];
};

private _uri = "";
if ((count _path_elements) == 0) then {
	_uri = "/";
	_is_directory = true;
};

if ((count _targetable_host_split) == 2) then {
	_ip = _targetable_host_split select 0;
	_port = _targetable_host_split select 1;
} else {
	if ((count _targetable_host_split) == 1) then {
		_ip = _targetable_host_split select 0;

		switch _protocol do {
			case "ftp": {_port = "21"};
			case "ftps": {_port = "990"};
			case "http": {_port = "80"};
			case "https": {_port = "443"};
			case "smb": {_port = "445"};
			case "smtp": {_port = "25"};
			case "smtps": {_port = "587"};
			case "pop3": {_port = "110"};
			case "pop3s": {_port = "995"};
			default { "Unknown protocol" call _print; breakOut "main"};
		};
	};
};

private _username = "";
private _password = "";

if (_user_password_combo != "") then {
	private _user_creds_split = _user_password_combo splitString ":";
	if ((count _user_creds_split) < 1) then {
		"Couldn't parse provided credentials" call _print;
	};

	if ((count _user_creds_split) == 1 ) then {
		private _user_creds_chars = toArray _user_password_combo;
		private _username_or_password = _user_creds_split select 0;
		if ((_user_creds_chars select 0) == 58) then {
			_password = _username_or_password;
		} else {
			_username = _username_or_password;
		};
	};

	if ((count _user_creds_split) == 2 ) then {
		_username = _user_creds_split select 0;
		_password = _user_creds_split select 1;
	};

	if ((count _user_creds_split) > 2) then {
		"Couldn't parse provided credentials" call _print;
	};
};

private _doSimpleUpload = {
	params ["_raw_fs_uri", "_upload_file"];

	private _ok = true;
	if ((_raw_fs_uri select [((count _raw_fs_uri)-1), 1]) == "/") then {
		_raw_fs_uri = _raw_fs_uri + _upload_file;
	};

	try {
		[_remote_ptr, _remote_filesystem, _local_ptr, _local_filesystem, _user, _raw_fs_uri, _upload_file] call A3OSHACK_fnc_remoteUpload;
		_remote_computer setVariable ["AE3_filesystem", _remote_filesystem, 2];
	} catch {
		_ok = false;
	};

	_ok
};

private _doFileTransfer = {
	params ["_targetable_host_port", "_connected"];
	private _port_username = (_targetable_host_port call _getUsernameFromPort);
	private _port_password = (_targetable_host_port call _getPasswordFromPort);

	if !(_connected) then {
		format ["Failed to connect to %1", _protocol + "://" + _targetable_host] call _print;
		breakOut "main";
	};

	if (_port_username != "" and _port_password != "") then {
		if (_username != _port_username and _password != _port_password) then {
			"cURL failed to login!" call _print;
			breakOut "main";
		};
	};

	private _raw_fs_uri_prefix = "/" + _router_id + "/" + _ip + ":" + _port;
	for "_path_elem_count" from 0 to (count _path_elements)-1 do {
		private _elem = _path_elements select _path_elem_count;
		_uri = _uri + "/" + _elem;
	};
	private _raw_fs_uri = _raw_fs_uri_prefix + _uri;

	format ["do_upload: %1", _do_upload] call _print;
	if (_do_upload) then {
		private _ok = [_raw_fs_uri, _upload_file] call _doSimpleUpload;
		if !(_ok) then {
			"Failed to upload file, the remote closed the connection before the file could finish uploading." call _print;
		};
	} else {
		if (_is_directory) then {
			private _content = "";
			try {
				_content = [_remote_ptr, _remote_filesystem, _raw_fs_uri, "root", true] call AE3_filesystem_fnc_lsdir;
			} catch {
				"File not found..." call _print;
				breakOut "main";
			};

			_content call _print;
		} else {
			if (_output_file != "") then {
				try {
					[_remote_computer, _local_ptr, _local_filesystem, _user, _raw_fs_uri, _output_file] call A3OSHACK_fnc_remoteDownload;
					_computer setVariable ["AE3_filesystem", _local_filesystem, 2];
				} catch {
					"Failed to download file..." call _print;
					breakOut "main";
				}
			} else {
				private _content = "";
				try { // Try incase they fat finger! gotta handle the exception!
					_content = [_remote_ptr, _remote_filesystem, _raw_fs_uri, "root", 1] call AE3_filesystem_fnc_getFile;
				} catch {
					"File not found..." call _print;
					breakOut "main";
				};

				if (_content isEqualType {}) then {
					"Cowardly refusing to write binary data to the terminal... Use --output to save the binary data to a file." call _print;
					breakOut "main";
				};

				if (_content isEqualType createHashMap) then {
					private _content = [_remote_ptr, _remote_filesystem, _raw_fs_uri, "root", true] call AE3_filesystem_fnc_lsdir;
					_content call _print;
					breakOut "main";
				};
			
				_content = _content splitString endl; // Split on endlines
				_content call _print;
			};
		};
	}; 
};

private _doHttp = {
	params ["_targetable_host_port", "_connected"];
	private _port_username = (_targetable_host_port call _getUsernameFromPort);
	private _port_password = (_targetable_host_port call _getPasswordFromPort);

	if !(_connected) then {
		format ["Failed to connect to %1", _protocol + "://" + _targetable_host] call _print;
		breakOut "main";
	};

	if (_port_username != "" and _port_password != "") then {
		if (_username != _port_username and _password != _port_password) then {
			"401 Unauthorized" call _print;
			breakOut "main";
		};
	};

	private _raw_fs_uri_prefix = "/" + _router_id + "/" + _ip + ":" + _port;
	for "_path_elem_count" from 0 to (count _path_elements)-1 do {
		private _elem = _path_elements select _path_elem_count;
		_uri = _uri + "/" + _elem;
	};
	private _raw_fs_uri = _raw_fs_uri_prefix + _uri;

	if (_is_directory) then {
		"405 Method Not Allowed" call _print;
	} else {
		private _content = ""; 
		try {
			_content = [_remote_ptr, _remote_filesystem, _raw_fs_uri, "root", 1] call AE3_filesystem_fnc_getFile;
		} catch {
			"404 Not Found" call _print;
			breakOut "main";
		};

		if (_content isEqualType {}) then {
			try {
				private _handler = [_computer, [], (_url_slash_split select (count _url_slash_split)-1)] spawn _content;
				_terminal set ["AE3_terminalProcess", _handler];
				_computer setVariable ["AE3_terminal", _terminal];

				waitUntil {
					isNull _handler;
				};
			} catch {
				"500 Internal Server Error" call _print;
				breakOut "main";
			};
		};

		if (_content isEqualType createHashMap) then {
			"405 Method Not Allowed" call _print;
			breakOut "main";
		};

		// Display it, or just download it
		if (_output_file != "") then {
			try {
				[_remote_computer, _local_ptr, _local_filesystem, _user, _raw_fs_uri, _output_file] call A3OSHACK_fnc_remoteDownload;
				_computer setVariable ["AE3_filesystem", _local_filesystem, 2];
			} catch {
				"404 Not Found" call _print;
				breakOut "main";
			};
		} else {
			_content = _content splitString endl; // Split on endlines
			_content call _print;
		};
	};
};

private _doSendEmail = {};
private _doReceiveEmail = {};

private _remote_computer = missionNamespace getVariable [_remote_computer_var_name, objNull];
if (isNull _remote_computer) then {
	["Critical failure accessing remote device", "#e53109"] call _print;
	breakOut "main";
};
private _remote_filesystem = _remote_computer getVariable "AE3_filesystem";
private _remote_ptr = _remote_computer getVariable "AE3_Filepointer";

private _local_filesystem = _computer getVariable "AE3_filesystem";
private _local_ptr = _computer getVariable "AE3_Filepointer";
private _terminal = _computer getVariable "AE3_terminal";
private _user = _terminal get "AE3_terminalLoginUser";

([_ip, _port] call _getTargetPort) params ["_targetable_host_port", "_connected"];
if ((_targetable_host_port call _getActualPortFromPort) != _protocol) then {
	_connected = false;
};

switch _protocol do {
	case "ftp";
	case "ftps";
	case "smb": {[_targetable_host_port, _connected] call _doFileTransfer};
	case "http";
	case "https": {[_targetable_host_port, _connected] call _doHttp};
	case "smtp";
	case "smtps": {[_targetable_host_port, _connected] call _doSendEmail};
	case "pop3";
	case "pop3s": {[_targetable_host_port, _connected] call _doReceiveEmail};
	default { "Unknown protocol" call _print; breakOut "main"};
};
