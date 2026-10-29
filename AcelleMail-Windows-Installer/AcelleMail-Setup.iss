#define AppName "Acelle Mail Local"
#define AppVersion "3.0.21"
#define Publisher "OFUQ"
#define StageDir "staging"

[Setup]
AppId={{D31BDA0D-3E3B-4A91-9C8E-ACE11E302101}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#Publisher}
DefaultDirName={localappdata}\Programs\AcelleMailLocal
DefaultGroupName={#AppName}
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
DisableProgramGroupPage=yes
OutputDir=output
OutputBaseFilename=AcelleMail-Setup-x64
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "arabic"; MessagesFile: "compiler:Languages\Arabic.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "{#StageDir}\app\*"; DestDir: "{app}\app"; Flags: recursesubdirs createallsubdirs ignoreversion
Source: "{#StageDir}\runtime\php\*"; DestDir: "{app}\runtime\php"; Flags: recursesubdirs createallsubdirs ignoreversion
Source: "{#StageDir}\runtime\mariadb\*"; DestDir: "{app}\runtime\mariadb"; Flags: recursesubdirs createallsubdirs ignoreversion
Source: "src\AcelleMailLauncher.ps1"; DestDir: "{app}\src"; Flags: ignoreversion
Source: "src\Stop-AcelleMail.ps1"; DestDir: "{app}\src"; Flags: ignoreversion
Source: "scripts\README-FIRST.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "docs\BUILD_REQUIREMENTS_AR.md"; DestDir: "{app}\docs"; Flags: ignoreversion

[Icons]
Name: "{group}\Acelle Mail Local - Start"; Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ""{app}\src\AcelleMailLauncher.ps1"""; WorkingDir: "{app}"
Name: "{userdesktop}\Acelle Mail Local"; Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ""{app}\src\AcelleMailLauncher.ps1"""; WorkingDir: "{app}"; Tasks: desktopicon
Name: "{group}\Acelle Mail Local - Stop"; Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ""{app}\src\Stop-AcelleMail.ps1"""; WorkingDir: "{app}"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional shortcuts:"; Flags: unchecked

[Run]
Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\src\AcelleMailLauncher.ps1"""; Description: "Start Acelle Mail Local"; Flags: postinstall nowait skipifsilent
