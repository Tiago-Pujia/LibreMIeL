; Script de Inno Setup para generar el instalador de Windows (.exe) de LibreMIeL (x64 y arm64)
; Compilación:
;   iscc /DAppVersion=0.1.0 /DAppArch=x64   packaging\windows\installer.iss
;   iscc /DAppVersion=0.1.0 /DAppArch=arm64 packaging\windows\installer.iss

#ifndef AppVersion
  #define AppVersion "0.1.0"
#endif

#ifndef AppArch
  #define AppArch "x64"
#endif

#if AppArch == "arm64"
  #define SetupArchAllowed "arm64"
  #define SetupArch64Bit "arm64"
#else
  #define SetupArchAllowed "x64compatible"
  #define SetupArch64Bit "x64compatible"
#endif

#define AppName "LibreMIeL"
#define AppPublisher "LibreMIeL Contributors"
#define AppURL "https://github.com/Tiago-Pujia/LibreMIeL"
#define AppExeName "libremiel.exe"

[Setup]
AppId={{7C3A8D12-4B65-4E9A-9F11-84C0A5C8F310}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
AllowNoIcons=yes
LicenseFile=..\..\LICENSE
OutputDir=..\..\dist\windows-{#AppArch}
OutputBaseFilename=LibreMIeL-{#AppVersion}-windows-{#AppArch}-setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed={#SetupArchAllowed}
ArchitecturesInstallIn64BitMode={#SetupArch64Bit}
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
AppMutex=LibreMIeL_App_Mutex
CloseApplications=yes
RestartApplications=yes

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "startup"; Description: "Iniciar LibreMIeL automáticamente con Windows"; GroupDescription: "Opciones adicionales:"; Flags: unchecked

[Files]
Source: "..\..\app\build\windows\{#AppArch}\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{group}\Desinstalar {#AppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon
Name: "{userstartup}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: startup

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(AppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
Filename: "{app}\{#AppExeName}"; Flags: nowait; Check: WizardSilent
