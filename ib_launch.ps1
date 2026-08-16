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
    [DllImport("kernel32.dll", CharSet = CharSet.Ansi, SetLastError = true)]
    public static extern IntPtr CreateEventA(IntPtr lpEventAttributes, bool bManualReset, bool bInitialState, string lpName);
    public const uint CREATE_BREAKAWAY_FROM_JOB = 0x01000000;
    public const uint CREATE_NEW_PROCESS_GROUP = 0x00000200;
    public const uint DETACHED_PROCESS = 0x00000008;
}
'@
if (-not ([System.Management.Automation.PSTypeName]'IbNative').Type) {
    Add-Type -TypeDefinition $src
}

# A client-spawned shared server OpenEventA("ServerStarted" / "ServerClosed")
# and signals ServerStarted when ready. An independently started dedicated
# server does the same OpenEvent -- so someone must create the events first
# and hold a handle until the server opens them.
$isServer = $false
foreach ($a in $GameArgs) {
    if ($a -eq '-server') { $isServer = $true; break }
}
$evStarted = [IntPtr]::Zero
$evClosed = [IntPtr]::Zero
if ($isServer) {
    $evStarted = [IbNative]::CreateEventA([IntPtr]::Zero, $true, $false, 'ServerStarted')
    $evClosed = [IbNative]::CreateEventA([IntPtr]::Zero, $true, $false, 'ServerClosed')
    if ($evStarted -eq [IntPtr]::Zero -or $evClosed -eq [IntPtr]::Zero) {
        Write-Error ("Failed to create ServerStarted/ServerClosed events: Win32 " + [Runtime.InteropServices.Marshal]::GetLastWin32Error())
        exit 1
    }
}

$si = New-Object IbNative+STARTUPINFO
$si.cb = [Runtime.InteropServices.Marshal]::SizeOf($si)
$pi = New-Object IbNative+PROCESS_INFORMATION
$flags = [IbNative]::CREATE_BREAKAWAY_FROM_JOB -bor [IbNative]::CREATE_NEW_PROCESS_GROUP
$ok = [IbNative]::CreateProcess(
    $env:IB_EXE, $cmdLine, [IntPtr]::Zero, [IntPtr]::Zero, $false, $flags,
    [IntPtr]::Zero, $env:IB_BIN, [ref]$si, [ref]$pi)

$pidOut = 0
if ($ok) {
    $pidOut = $pi.dwProcessId
    [IbNative]::CloseHandle($pi.hThread) | Out-Null
    [IbNative]::CloseHandle($pi.hProcess) | Out-Null
} else {
    # Job forbids breakaway. WMI Create runs under WmiPrvSE, outside this job.
    try {
        $wmi = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{
            CommandLine       = $cmdLine
            CurrentDirectory  = $env:IB_BIN
        }
        if ($wmi.ReturnValue -eq 0 -and $wmi.ProcessId) {
            $pidOut = [int]$wmi.ProcessId
        } else {
            Write-Error ("Win32_Process.Create failed: return " + $wmi.ReturnValue)
            exit 1
        }
    } catch {
        Write-Error ("CreateProcess/WMI failed: " + $_.Exception.Message)
        exit 1
    }
}

if ($pidOut -le 0) {
    Write-Error "Launch succeeded but no PID was returned."
    exit 1
}

Set-Content -Path $PidFile -Value $pidOut -Encoding ascii

if ($isServer) {
    # Hold the event handles until the server has opened them (early init).
    Start-Sleep -Seconds 4
    if ($evStarted -ne [IntPtr]::Zero) { [IbNative]::CloseHandle($evStarted) | Out-Null }
    if ($evClosed -ne [IntPtr]::Zero) { [IbNative]::CloseHandle($evClosed) | Out-Null }
}
exit 0
