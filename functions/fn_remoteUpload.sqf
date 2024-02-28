/**
 * Administratively uploads a file from the local computer to a different computer. This will bypass remote filesystem permission requirements.
 * Arguments:
 * 0: Remote Computer <OBJECT>
 * 1: Local Filesystem Pointer <[STRING]>
 * 2: Local Filesystem <HASHMAP>
 * 3: Local User <STRING>
 * 4: Remote file path to write to <STRING>
 * 5: Local file path to read from <STRING>
 *
 * Results:
 * None
 * 
 * Most of the credit for this file belongs to @GermanHydrogen on Github. The logic is straight copied from them, I simply inverted the logic and changed *which* filesystems
 * are being written/read.
 */

params ["_remote_ptr", "_remote_filesystem", "_local_ptr", "_local_fs", "_local_user", "_remote_file_to_upload", "_local_file_to_upload"];

private _remote_dir = [_remote_ptr, _remote_filesystem, _remote_file_to_upload, "root"] call AE3_filesystem_fnc_getParentDir;
private _remote_current = _remote_dir select 1;
private _remote_new = _remote_dir select 2;

private _local_dir = [_local_ptr, _local_fs, _local_file_to_upload, _local_user] call AE3_filesystem_fnc_getParentDir;
private _local_current = _local_dir select 1;
private _local_file = _local_dir select 2;

if (_remote_new in (_remote_current select 0)) then {
	if (((_remote_current select 0) get _remote_new) select 0 isEqualType (createHashMap)) then {
		_remote_file_to_upload = _remote_file_to_upload + "/";
	};
};

_local_current = _local_current select 0;
if (!(_local_file in _local_current)) throw (format [localize "STR_AE3_Filesystem_Exception_NotFound", _local_file]);

if ((_remote_file_to_upload find ["/", count _remote_file_to_upload - 1]) == (count _remote_file_to_upload - 1)) then { // Last character in string is a "/"
	_remote_current = _remote_current select 0;
	if(!(_remote_new in _remote_current)) throw (format [localize "STR_AE3_Filesystem_Exception_NotFound", _remote_new]);
	_remote_current = (_remote_current get _remote_new);

	[_remote_current, "root", 2] call AE3_filesystem_fnc_hasPermission;
	_remote_current = _remote_current select 0;

	if(_remote_new in _remote_current) throw (format [localize "STR_AE3_Filesystem_Exception_AlreadyExists", _remote_new]);

	_remote_current set [_remote_new, _local_current get _local_file];
} else {
	[_remote_current, "root", 2] call AE3_filesystem_fnc_hasPermission;
	_remote_current = _remote_current select 0;

	if(_remote_new in _remote_current) throw (format [localize "STR_AE3_Filesystem_Exception_AlreadyExists", _local_file]);

	_remote_current set [_remote_new, _local_current get _local_file];
};
