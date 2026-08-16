# Launch Infinity Battlescape so it outlives the parent console/job.
# Expects env: IB_EXE, IB_BIN, and either IB_CLIENT_PID_FILE or IB_SERVER_PID_FILE
# via -PidFile. Game arguments are passed as remaining args.

param(
    [Parameter(Mandatory = $true)]
    [string]$PidFile,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$GameArgs
)

if (-not $env:IB_EXE -or -not (Test-Path -LiteralPath $env:IB_EXE)) {
    Write-Error "IB_EXE is missing or not found: '$env:IB_EXE'"
    exit 1
}
if (-not $env:IB_BIN -or -not (Test-Path -LiteralPath $env:IB_BIN)) {
    Write-Error "IB_BIN is missing or not found: '$env:IB_BIN'"
    exit 1
}

$quoted = foreach ($a in $GameArgs) {
    if ($null -eq $a -or $a -eq '') { continue }
    if ($a -match '\s') { '"' + $a + '"' } else { $a }
}
$argString = [string]::Join(' ', $quoted)
$cmdLine = '"' + $env:IB_EXE + '" ' + $argString

$src = @'
using System;
using System.Runtime.InteropServices;
public class IbNative {
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct STARTUPINFO {
        public int cb;
        public string lpReserved;
        public string lpDesktop;
        public string lpTitle;
        public int dwX, dwY, dwXSize, dwYSize, dwXCountChars, dwYCountChars, dwFillAttribute, dwFlags;
        public short wShowWindow, cbReserved2;
        public IntPtr lpReserved2, hStdInput, hStdOutput, hStdError;
    }
    [StructLayout(LayoutKind.Sequential)]
    public struct PROCESS_INFORMATION {
        public IntPtr hProcess, hThread;
        public int dwProcessId, dwThreadId;
    }
    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern bool CreateProcess(
        string lpApplicationName, string lpCommandLine, IntPtr lpProcessAttributes, IntPtr lpThreadAttributes,
        bool bInheritHandles, uint dwCreationFlags, IntPtr lpEnvironment, string lpCurrentDirectory,
        ref STARTUPINFO lpStartupInfo, out PROCESS_INFORMATION lpProcessInformation);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr hObject);
    public const uint CREATE_BREAKAWAY_FROM_JOB = 0x01000000;
    public const uint CREATE_NEW_PROCESS_GROUP = 0x00000200;
    public const uint DETACHED_PROCESS = 0x00000008;
}
'@
if (-not ([System.Management.Automation.PSTypeName]'IbNative').Type) {
    Add-Type -TypeDefinition $src
}

$si = New-Object IbNative+STARTUPINFO
$si.cb = [Runtime.InteropServices.Marshal]::SizeOf($si)
$pi = New-Object IbNative+PROCESS_INFORMATION
$flags = [IbNative]::CREATE_BREAKAWAY_FROM_JOB -bor [IbNative]::CREATE_NEW_PROCESS_GROUP
$ok = [IbNative]::CreateProcess(
    $env:IB_EXE, $cmdLine, [IntPtr]::Zero, [IntPtr]::Zero, $false, $flags,
    [IntPtr]::Zero, $env:IB_BIN, [ref]$si, [ref]$pi)

if (-not $ok) {
    # Job may forbid breakaway. Fall back to explorer, which is outside the agent job.
    $ok = [IbNative]::CreateProcess(
        $env:IB_EXE, $cmdLine, [IntPtr]::Zero, [IntPtr]::Zero, $false,
        [IbNative]::CREATE_NEW_PROCESS_GROUP, [IntPtr]::Zero, $env:IB_BIN, [ref]$si, [ref]$pi)
}

if (-not $ok) {
    Write-Error ("CreateProcess failed: Win32 " + [Runtime.InteropServices.Marshal]::GetLastWin32Error())
    exit 1
}

[IbNative]::CloseHandle($pi.hThread) | Out-Null
[IbNative]::CloseHandle($pi.hProcess) | Out-Null
Set-Content -Path $PidFile -Value $pi.dwProcessId -Encoding ascii
exit 0
