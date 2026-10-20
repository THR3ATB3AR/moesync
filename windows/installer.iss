#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif

#ifndef BuildNumber
  #define BuildNumber "0"
#endif

#define AppName "MoeSync"
#define AppExeName "moesync.exe"

[Setup]
AppId={{D4339C88-ECF8-47CF-9BCA-6BF4A1F32B26}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion} (Build {#BuildNumber})
AppPublisher=THR3ATB3AR
DefaultDirName={autopf}\MoeSync
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
OutputDir=..\dist
OutputBaseFilename=moesync-{#AppVersion}+{#BuildNumber}-windows-x64-setup
SetupIconFile=runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExeName}
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
PrivilegesRequired=lowest
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
VersionInfoProductVersion={#AppVersion}
VersionInfoCompany=THR3ATB3AR
VersionInfoDescription=MoeSync Setup

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional icons:"; Flags: unchecked

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "Launch MoeSync"; Flags: postinstall nowait skipifsilent
