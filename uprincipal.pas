unit uprincipal;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, ComCtrls, IniFiles, StrUtils, process, google_drive,
  google_oauth2, blcksock, httpsend, synautil;

type
  { TFrmPrincipal }


TFrmPrincipal = class(TForm)
    BtnIniciar: TButton;
    BtnIniciar1: TButton;
    Dom: TCheckBox;
    edtIdFolder: TLabeledEdit;
    ProgressBar1: TProgressBar;
    Seg: TCheckBox;
    Ter: TCheckBox;
    Qua: TCheckBox;
    Qui: TCheckBox;
    Sex: TCheckBox;
    Sab: TCheckBox;
    edtHora: TLabeledEdit;
    GroupBox1: TGroupBox;
    memoLog: TMemo;
    TimerProcess: TTimer;
    procedure BtnIniciar1Click(Sender: TObject);
    procedure BtnIniciarClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure TimerProcessTimer(Sender: TObject);
  private

  public
    procedure StartBackup;
    procedure SendFileGdrive(FileName: String);
    procedure CheckTokenFile;
    function Gdrivepostfile(const URL, auth, FileName: string; const Data: TStream; const ResultData: TStrings): boolean;
  end;

var
  FrmPrincipal: TFrmPrincipal;
  JDrive: Tgoogledrive;
  client_id: string = '164139322725-4dbm962sta2um6cp851tnag4s75rphjm.apps.googleusercontent.com';
  client_secret: string = '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';

implementation

{$R *.lfm}

{ TFrmPrincipal }

procedure TFrmPrincipal.BtnIniciarClick(Sender: TObject);
var
   vCount: Integer;
   CanStart: Boolean;
begin
  vCount   := 0;
  CanStart := false;
  if edtHora.Text = '' then
  begin
    ShowMessage('Hora não informada!');
    Exit;
  end;

  for vCount := 0 to FrmPrincipal.ComponentCount-1 do
  begin
    if FrmPrincipal.Components[vCount] is TCheckBox then
    begin
      CanStart :=  (FrmPrincipal.Components[vCount] as TCheckBox).Checked;
    end;
  end;

  if CanStart then
  begin
    TimerProcess.Enabled := CanStart;
  end Else
  begin
    ShowMessage(' Nenhum dia selecionado! ');
  end;
end;

procedure TFrmPrincipal.FormCreate(Sender: TObject);
begin
  Jdrive          := TGoogleDrive.Create(Self, client_id, client_secret);
  Jdrive.Progress := ProgressBar1;
  Jdrive.LogMemo  := memoLog;

  CheckTokenFile;

end;

procedure TFrmPrincipal.BtnIniciar1Click(Sender: TObject);
begin

  JDrive.gOAuth2.LogMemo := memoLog;
  Jdrive.gOAuth2.DebugMemo := memoLog;
  Jdrive.gOAuth2.GetAccess(True);

  CheckTokenFile;

  if Jdrive.gOAuth2.EMail = '' then
    exit;

  Jdrive.Open;
end;

procedure TFrmPrincipal.TimerProcessTimer(Sender: TObject);
begin
  if((DayOfWeek(Date) = 1) and (Dom.Checked)) then
  begin
    StartBackup;
  end Else if((DayOfWeek(Date) = 2) and (Seg.Checked)) then
  begin
    StartBackup;
  end Else if((DayOfWeek(Date) = 3) and (Ter.Checked)) then
  begin
    StartBackup;
  end Else if((DayOfWeek(Date) = 4) and (Qua.Checked)) then
  begin
    StartBackup;
  end Else if((DayOfWeek(Date) = 5) and (Qui.Checked)) then
  begin
    StartBackup;
  end Else if((DayOfWeek(Date) = 6) and (Sex.Checked)) then
  begin
    StartBackup;
  end Else if((DayOfWeek(Date) = 7) and (Sab.Checked)) then
  begin
    StartBackup;
  end;
end;

procedure TFrmPrincipal.StartBackup;
const READ_BYTES = 2048;
var
   Ambiente: TiniFile;
   Sections, Lines: TStringList;
   i: Integer;
   NomeBanco, NomeBackup, Versao, LocalBackup: String;

   aProcess: TProcess;
   MemStream: TMemoryStream;
   NumBytes: LongInt;
   BytesRead: LongInt;

begin
  TimerProcess.Enabled := false;
  Sections := TStringList.Create;
  Ambiente := TIniFile.Create('AMBIENTE.ini');
  Ambiente.ReadSections(Sections);
  for i := 0 to Sections.Count - 1 do
  begin
    NomeBanco := Ambiente.ReadString(Sections[i], 'BANCO', '');
    Versao    := Ambiente.ReadString(Sections[i], 'VERSAO', '2.5');
    if NomeBanco <> '' then
    begin
      MemStream := TMemoryStream.Create;
      Lines     := TStringList.Create;
      BytesRead := 0;
      NomeBackup  := StringReplace(ExtractFileName(NomeBanco), '.FDB' ,'.FBK', [rfReplaceAll, rfIgnoreCase]);
      LocalBackup := ExtractFilePath(NomeBanco)+PathDelim+'Backups'+PathDelim+NomeBackup;
      aProcess   := TProcess.Create(nil);
      if Versao = '2.5' then
      begin
         aProcess.Executable := 'C:\Program Files (x86)\Firebird\Firebird_2_5\bin\gbak.exe';
      end Else
      begin
        aProcess.Executable := 'C:\Program Files (x86)\Firebird\Firebird_3_0\gbak.exe';
      end;
      aProcess.Parameters.Add('-backup');
      aProcess.Parameters.Add('-user');
      aProcess.Parameters.Add( Ambiente.ReadString(Sections[i], 'USUARIO', 'SYSDBA') );
      aProcess.PArameters.Add('-password');
      aProcess.Parameters.Add( Ambiente.ReadString(Sections[i], 'SENHA', 'masterkey') );
      aProcess.Parameters.Add('-v');
      aProcess.Parameters.Add(NomeBanco);
      aProcess.Parameters.Add(LocalBackup);
      aprocess.ShowWindow := swoHIDE;
      AProcess.Options := AProcess.Options + [poUsePipes,poStderrToOutPut];
      memoLog.lines.Add('Backup in progress ... '+NomeBanco+' '+DateTimeToStr(Now));
      aProcess.Execute;
      while aProcess.Running do
      begin
         MemStream.SetSize(BytesRead + READ_BYTES);
         // try reading it
         NumBytes := aProcess.Output.Read((MemStream.Memory + BytesRead)^, READ_BYTES);
         if NumBytes > 0
            then Inc(BytesRead, NumBytes)
         else
            BREAK
      end;
      MemStream.SetSize(BytesRead);
      Lines.LoadFromStream(MemStream);
      memoLog.lines.AddStrings(Lines);
      memoLog.lines.Add('Backup terminated '+DateTimeToStr(Now));

      aProcess.Free;
      Lines.Free;
      MemStream.Free;
      //Enviando para GDrive
      SendFileGdrive(LocalBackup);
      TimerProcess.Enabled := True;
    end;
  end;
end;

procedure TFrmPrincipal.SendFileGdrive(FileName: String);
var
  URL: string;
  Data: TFileStream;
  ResultData: TStringList;
begin
  // URL := 'https://www.googleapis.com/upload/drive/v3/files?uploadType=media';
  // URL := 'https://www.googleapis.com/upload/drive/v3/files?uploadType=resumable';
  URL := 'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart';

  JDrive.gOAuth2 := TGoogleOAuth2.Create(client_id, client_secret);
  ResultData := TStringList.Create;
  Data := TFileStream.Create(FileName, fmOpenRead);
  try
    if not FileExists('tokens.dat') then
    begin
      // first get all access clicked on Groupbox
      BtnIniciar1.Click;
    end;

    JDrive.gOAuth2.LogMemo := memoLog;
    JDrive.gOAuth2.DebugMemo := memoLog;
    JDrive.gOAuth2.GetAccess(True);
    if JDrive.gOAuth2.EMail = '' then
      exit;

    Gdrivepostfile(URL, JDrive.gOAuth2.Access_token, FileName, Data, ResultData);

    memoLog.Lines.Add(ResultData.Text);

  finally
    Data.Free;
    ResultData.Free;
    JDrive.gOAuth2.Free;
  end;

end;

procedure TFrmPrincipal.CheckTokenFile;
begin
  
  if FileExists('tokens.dat') then // already tokens
  begin
    BtnIniciar1.Caption := 'Check access GDrive';
  end
  else
  begin
    BtnIniciar1.Caption := 'Entrar GDrive';
  end;

end;


function TFrmPrincipal.Gdrivepostfile(const URL, auth, FileName: string; const Data: TStream; const ResultData: TStrings): boolean;
var
  HTTP: THTTPSend;
  Bound, s: string;
begin
  Bound := IntToHex(Random(MaxInt), 8) + '_Synapse_boundary';
  HTTP := THTTPSend.Create;
  try
    s := '--' + Bound + CRLF;
    s := s + 'Content-Type: application/json; charset=UTF-8' + CRLF + CRLF;
    s := s + '{' + CRLF;
    if edtIdFolder.Text <> EmptyStr then
    begin
       s := s + '"parents": ["'+edtIdFolder.Text+'"], ' + CRLF;
    end;
    s := s + '"name": "' + ExtractFileName(FileName) + '"' + CRLF;
    s := s + '}' + CRLF;
    s := s + CRLF + CRLF;
    s := s + '--' + Bound + CRLF;
    s := s + 'Content-Type: application/octet-stream' + CRLF + CRLF;
    WriteStrToStream(HTTP.Document, ansistring(s));
    HTTP.Document.CopyFrom(Data, 0);

    s := CRLF + '--' + Bound + '--' + CRLF;
    WriteStrToStream(HTTP.Document, ansistring(s));

    HTTP.Headers.Add('Authorization: Bearer ' + auth);
    HTTP.MimeType := 'multipart/form-data; boundary=' + Bound;
    Result := HTTP.HTTPMethod('POST', URL);
    //Mainform.Memo2.Lines.Add(HTTP.Headers.Text);

    if Result then
      ResultData.LoadFromStream(HTTP.Document);
  finally
    HTTP.Free;
  end;
end;

end.

