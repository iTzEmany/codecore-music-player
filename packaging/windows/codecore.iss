; Inno Setup script: per-user installer, no administrator rights.
; Built by .github/workflows/release.yml with:
;   iscc /DAppVersion=1.2.0 packaging\windows\codecore.iss
; Expects, next to the release build, the third-party tools in build\windows\tools\
; (yt-dlp.exe, ffmpeg.exe and their licence texts: see the workflow).
#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif

[Setup]
AppId={{6C1F4B3A-0D6B-4F1E-9B5C-2E7A9C3D41A8}
AppName=Codecore
AppVersion={#AppVersion}
AppPublisher=Codecore
DefaultDirName={localappdata}\Programs\Codecore
DefaultGroupName=Codecore
PrivilegesRequired=lowest
OutputDir=..\..\build
OutputBaseFilename=Codecore-Setup-{#AppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
UninstallDisplayIcon={app}\codecore.exe
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "italian"; MessagesFile: "compiler:Languages\Italian.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion
; yt-dlp (Unlicense) and ffmpeg (LGPL build) go next to codecore.exe, where the app looks first.
Source: "..\..\build\windows\tools\yt-dlp.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\build\windows\tools\ffmpeg.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\build\windows\tools\licenses\*"; DestDir: "{app}\licenses"; Flags: recursesubdirs ignoreversion

[Icons]
Name: "{group}\Codecore"; Filename: "{app}\codecore.exe"
Name: "{autodesktop}\Codecore"; Filename: "{app}\codecore.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\codecore.exe"; Description: "{cm:LaunchProgram,Codecore}"; Flags: nowait postinstall skipifsilent

[Code]
// The user's data (library database, covers, downloads index) lives in
// %APPDATA% and is kept unless the user says otherwise.
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usPostUninstall then
    if MsgBox('Eliminare anche i dati di Codecore (libreria, playlist, copertine)?', mbConfirmation, MB_YESNO or MB_DEFBUTTON2) = IDYES then
      DelTree(ExpandConstant('{userappdata}\codecore'), True, True, True);
end;
