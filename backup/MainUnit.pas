unit MainUnit;

{$mode objfpc}{$H+}
{$define use_logging}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  {$if defined(use_logging)}
  CastleLog,
  {$endif}
  {$ifndef VER3_0} OpenSSLSockets, {$endif}
  StdCtrls, Menus, JsonTools,
  CastleControl, CastleDialogs, CastleCameras, CastleDownload,
  CastleApplicationProperties, X3DNodes, CastleSceneCore, CastleVectors,
  CastleScene, CastleViewport, CastleTimeUtils;

type

  { TMainForm }

  TMainForm = class(TForm)
    CastleControlBase1: TCastleControlBase;
    ModelOpenDialog: TCastleOpenDialog;
    MainMenu1: TMainMenu;
    Memo1: TMemo;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    PageControl1: TPageControl;
    PanelContent: TPanel;
    PanelSceneTree: TPanel;
    PanelViewport: TPanel;
    Splitter1: TSplitter;
    TabScene: TTabSheet;
    TabDebug: TTabSheet;
    TreeViewScene: TTreeView;
    procedure CastleControlBase1Open(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure MenuItem2Click(Sender: TObject);
    procedure MenuItem3Click(Sender: TObject);
  private
    Viewport: TCastleViewport;
    Scene: TCastleScene;
    procedure LoadScene(filename: String);
  public
    procedure Analyse(filename: String);
  end;

var
  MainForm: TMainForm;

function CreateStreamFromFile(Filename: String): TStream;
procedure DebugMessage(Text: String);
procedure MapJsonObject(Json: TJsonNode);

implementation

{$R *.lfm}

{ TMainForm }

procedure DebugMessage(Text: String);
begin
  MainForm.Memo1.Lines.Add(Text);
end;

procedure MapJsonObject(Json: TJsonNode);
var
  Node: TJsonNode;
  Txt: String;
begin
  for Node in Json do
    begin
      case Node.Name of
      'dummyField':
        begin
          // Just a dummy field
        end;
      else
          begin
            Txt := Chr(39) + Node.Name + Chr(39) + ':' + LineEnding +
            '  begin' + LineEnding +
            '    if not(Node.Kind = ' + Node.KindAsString + ') then' + LineEnding +
            '      DebugMessage(' + Chr(39) +  'TypeError for ' +
              Node.Name + ' expected '  + Node.KindAsString +
              ' got ' + Chr(39) + ' + Node.KindAsString' + ')' + LineEnding +
            '    else' + LineEnding;
            if Node.Kind = nkString then
              Txt += '      Rec.' + Node.Name + ' := Node.AsString;' + LineEnding
            else if Node.Kind = nkNumber then
              Txt += '      Rec.' + Node.Name + ' := Trunc(Node.AsNumber);' + LineEnding
            else if Node.Kind = nkBool then
              Txt += '      Rec.' + Node.Name + ' := Node.AsBoolean;' + LineEnding
            else if Node.Kind = nkObject then
              Txt += '      // Rec.' + Node.Name + ' := MapJsonObject(Node); // *** FIXME ***' + LineEnding
            else if Node.Kind = nkArray then
              Txt += '      // Rec.' + Node.Name + ' := MapJsonArray(Node); // *** FIXME ***' + LineEnding
            else
              Txt += '      Rec.' + Node.Name + ' := Node.AsString; // *** FIXME ***' + LineEnding;
            Txt += '  end;';
            DebugMessage(Txt);
          end;
      end;
    end;
end;

function CreateStreamFromFile(Filename: String): TStream;
var
  Stream: TStream;
begin
  Result := nil;
  EnableBlockingDownloads := True;
  Stream := Download(Filename, [soForceMemoryStream]);
  try
    try
    except
      on E : Exception do
        begin
          DebugMessage('Oops' + LineEnding +
                      'Trying to download : ' + Filename + LineEnding +
                       E.ClassName + LineEnding +
                       E.Message);
          Stream := nil;
         end;
    end;
  finally
    Result := Stream;
    EnableBlockingDownloads := False;
  end;
end;

procedure TMainForm.Analyse(Filename: String);
var
  Stream: TStream;
  Json: TJsonNode;
  Node: TJsonNode;
  idx: Integer;
begin
  Memo1.Clear;
  Inc(idx);
  Stream := CreateStreamFromFile(Filename);
  Json := TJsonNode.Create;
  Json.LoadFromStream(Stream);
  DebugMessage('Node[' + IntToStr(idx) + '] : ' +  Json.Name + ' -> ' + Json.KindAsString);
  for Node in Json do
    begin
      Inc(idx);
      DebugMessage('Node[' + IntToStr(idx) + '] : ' +  Node.Name + ' -> ' + Node.KindAsString);
    end;
end;


procedure TMainForm.CastleControlBase1Open(Sender: TObject);
begin
  if not(Scene = nil) then
  begin
    Viewport.PrepareResources('Loading');
    {$if defined(use_logging)}
    WritelnLog('========== Profiler ==========');
    WritelnLog(Profiler.Summary);
    WritelnLog('========== Profiler ==========');
    {$endif}
  end;
end;

procedure TMainForm.LoadScene(filename: String);
begin
  // Set up the main viewport
  Viewport := TCastleViewport.Create(Application);
  // Use all the viewport
  Viewport.FullSize := true;
  // Automatically position the camera
  Viewport.AutoCamera := true;
  // Use default navigation keys
  Viewport.AutoNavigation := true;

  // Add the viewport to the CGE control
  CastleControlBase1.Controls.InsertFront(Viewport);

  // Create a scene
  Scene := TCastleScene.Create(Application);
  // Load a model into the scene
  Scene.load(filename);
  // Add the scene to the viewport
  Viewport.Items.Add(Scene);

  // Tell the control this is the main scene so it gets some lighting
  Viewport.Items.MainScene := Scene;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  Scene := nil;
  {$if defined(use_logging)}
  InitializeLog;
  Profiler.Enabled := true;
  {$endif}
  ModelOpenDialog.URL := 'castle-data:/box_rotx.gltf';
  PageControl1.ActivePage := TabScene;
  Memo1.Clear;
end;

procedure TMainForm.MenuItem2Click(Sender: TObject);
begin
  if not(Scene = nil) then
  begin
    FreeAndNil(Scene);
  end;
  if ModelOpenDialog.Execute then
    begin
      Analyse(ModelOpenDialog.FileName);
      LoadScene(ModelOpenDialog.FileName);
    end;
end;

procedure TMainForm.MenuItem3Click(Sender: TObject);
begin
  Application.Terminate;
end;

end.

