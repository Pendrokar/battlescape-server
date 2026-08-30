# Wait until a named event is signaled.
# Used so the client splash poll (WaitForSingleObject timeout 0) sees ServerStarted.
param(
    [Parameter(Mandatory = $true)]
    [string]$Name,
    [int]$TimeoutSec = 90
)

$src = @'
using System;
using System.Runtime.InteropServices;
public class IbWait {
    [DllImport("kernel32.dll", CharSet = CharSet.Ansi, SetLastError = true)]
    public static extern IntPtr OpenEventA(uint dwDesiredAccess, bool bInheritHandle, string lpName);
    [DllImport("kernel32.dll", CharSet = CharSet.Ansi, SetLastError = true)]
    public static extern IntPtr CreateEventA(IntPtr lpEventAttributes, bool bManualReset, bool bInitialState, string lpName);
    [DllImport("kernel32.dll")] public static extern uint WaitForSingleObject(IntPtr hHandle, uint dwMilliseconds);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr hObject);
    public const uint SYNCHRONIZE = 0x00100000;
    public const uint WAIT_OBJECT_0 = 0;
}
'@
if (-not ([System.Management.Automation.PSTypeName]'IbWait').Type) {
    Add-Type -TypeDefinition $src
}

$deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSec)
while ([DateTime]::UtcNow -lt $deadline) {
    $h = [IbWait]::OpenEventA([IbWait]::SYNCHRONIZE, $false, $Name)
    if ($h -eq [IntPtr]::Zero) {
        Start-Sleep -Milliseconds 250
        continue
    }
    $st = [IbWait]::WaitForSingleObject($h, 0)
    [IbWait]::CloseHandle($h) | Out-Null
    if ($st -eq [IbWait]::WAIT_OBJECT_0) {
        exit 0
    }
    Start-Sleep -Milliseconds 250
}

Write-Error "Timed out after $TimeoutSec s waiting for event '$Name'."
exit 1
