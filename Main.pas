unit Main;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, Menus,
  StdCtrls, Dialogs, Buttons, Messages, ExtCtrls, ComCtrls, StdActns,
  ActnList, ToolWin, ImgList, Math;

type
  TMainForm = class(TForm)
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    FileNewItem: TMenuItem;
    FileOpenItem: TMenuItem;
    Window1: TMenuItem;
    Help1: TMenuItem;
    N1: TMenuItem;
    FileExitItem: TMenuItem;
    OpenDialog: TOpenDialog;
    FileSaveIn: TMenuItem;
    FileSaveOut: TMenuItem;
    Edit1: TMenuItem;
    CutItem: TMenuItem;
    CopyItem: TMenuItem;
    PasteItem: TMenuItem;
    StatusBar: TStatusBar;
    ActionList1: TActionList;
    EditCut1: TEditCut;
    EditCopy1: TEditCopy;
    EditPaste1: TEditPaste;
    FileNew1: TAction;
    FileExit1: TAction;
    FileOpen1: TAction;
    ImageList1: TImageList;
    Calculate1: TMenuItem;
    N2: TMenuItem;
    SaveInputFile1: TMenuItem;
    N3: TMenuItem;
    procedure FileNewClick(Sender: TObject);
    procedure OpenInputFileClick(Sender: TObject);
    procedure SaveInputFileClick(Sender: TObject);
    procedure SaveInputFileAsClick(Sender: TObject);
    procedure SaveOutputFileAsClick(Sender: TObject);
    procedure FileExitClick(Sender: TObject);
    procedure TileClick(Sender: TObject);
    procedure CalculateClick(Sender: TObject);
    procedure AboutClick(Sender: TObject);

    procedure start(Sender: TObject);
    procedure resize(Sender: TObject);
    procedure createwindows(Sender: TObject);

  private
    { Private declarations }
    procedure CreateMDIChilds;
  public
    { Public declarations }
  end;

type
  TNode = class
    ID: string;
    lbl: string;
    cat: string;
    val: Double;
    prob: Double;
    accumul: Double;
    ev: Double;
  private
    { Private declarations }
  public
    { Public declarations }
    constructor Create; overload;
  end;

var
  MainForm: TMainForm;
  NodeStrings: TStringList;
  Nodes: array of TNode;
  maxl: Integer;
  filename: string;

implementation

uses Childwin;

constructor TNode.Create;
begin
end;

{$R *.dfm}

var
  Child_in, Child_out: TMDIChild;

procedure loadnodes;
var
  Ln: string;
  param: array[0..6] of string;
  i, j, k: Integer;
begin
  i := 0;
  while i < Child_in.Memo1.Lines.Count do
  begin
    i := i + 1;
    setlength(Nodes, i);
    Ln := Child_in.Memo1.Lines[i - 1];
    k := 7;
    repeat
      k := k - 1;
      param[k] := ''
    until k = 0;
    for j := 1 to length(Ln) do
    begin
      if Ln[j] = ',' then k := k + 1 else
      begin
        if k > 4 then break;
        param[k] := param[k] + Ln[j];
      end;
    end;
    Nodes[i - 1] := TNode.Create;
    Nodes[i - 1].ID := trim(param[0]);
    Nodes[i - 1].Lbl := trim(param[1]);
    Nodes[i - 1].cat := trim(param[2]);
    if trim(param[3]) = '' then param[3] := '0';
    try
    Nodes[i - 1].val := strtofloat(trim(param[3]));
    except
      on Exception : EConvertError do
      begin
      Showmessage('Error: Node on line #' + inttostr(i) + ' contains non float value! The program will ignore it.');
      Nodes[i - 1].val := 0;
      end;
    end;
    if trim(param[4]) = '' then param[4] := '0';
    try
    Nodes[i - 1].prob := strtofloat(trim(param[4]));
    except
      on Exception : EConvertError do
      begin
      Showmessage('Error: Node on line #' + inttostr(i) + ' contains non float probability! The program will ignore it.');
      Nodes[i - 1].prob := 0;
      end;
    end;
  end;
end;

function level(Nd: TNode): Integer;
var
  i: Integer;
begin
  Result := 1;
  for i := 1 to length(Nd.ID) do
    if Nd.ID[i] = '.' then Result := Result + 1;
end;

function maxlevel: Integer;
var
  i: Integer;
begin
  Result := 1;
  for i := 1 to length(Nodes) do
    if level(Nodes[i - 1]) > Result then Result := level(Nodes[i - 1])
end;

function parent(Str: string): string;
var v: string;
begin
  v := copy(Str, 1, LastDelimiter('.', Str) - 1);
  Result := copy(Str, 1, LastDelimiter('.', Str) - 1);
end;

function findnode(Str: string): TNode;
var
  i: Integer;
begin
  for i := 1 to length(Nodes) do
    if Nodes[i - 1].ID = Str then Result := Nodes[i - 1];
end;

function endnode(Str: string): boolean;
var
  i: Integer;
begin
  Result := false;
  for i := 1 to length(Nodes) do
    if AnsiPos(str, Nodes[i - 1].ID) = 1 then Result := true;
end;

function verify: boolean;
var
  i, j, n: Integer;
  str: string;
begin
  Result := true;
  //Check #1: Find root
  for i := 1 to Child_in.Memo1.Lines.Count do
    if findnode('1') = nil then
    begin
      ShowMessage('Error: Root Node was not found! Cannot continue.');
      Result := false;
      exit;
    end;

  //Check #2: Find duplicates
  for i := 1 to Child_in.Memo1.Lines.Count do
  begin
    n := 0;
    for j := 1 to Child_in.Memo1.Lines.Count do
      if Nodes[i - 1].ID = Nodes[j - 1].ID then
      begin
        n := n + 1;
        if n > 1 then
        begin
          Child_out.Memo1.Text := 'Error: Node on line ' + inttostr(j) + ' has a duplicate ID! Cannot continue.';
          Result := false;
          exit;
        end;
      end;
  end;

  //Check #3: See that the number of parameters is btw 3 to 5 per line
  for i := 1 to Child_in.Memo1.Lines.Count do
    if (Nodes[i - 1].ID = '') or (Nodes[i - 1].lbl = '') or (Nodes[i - 1].cat = '') then
    begin
      Child_out.Memo1.Text := 'Error: Node on line #' + inttostr(i) + ' should be defined with a minimum of 3 parameters separated by commas.';
      Result := false;
    end;

  //Check #4: Verify that the type of nodes are correct
  for i := 1 to Child_in.Memo1.Lines.Count do
    if (Nodes[i - 1].cat <> 'decision') and (Nodes[i - 1].cat <> 'chance') and (Nodes[i - 1].cat <> 'terminal') then
    begin
      Child_out.Memo1.Text := 'Error: Node on line #' + inttostr(i) + ' has an unknown type. ' + sLineBreak + 'The type should be: chance/decision/terminal.';
      Result := false;
    end;

  //Check #5: Verify that the ending nodes are terminal nodes
  for i := 1 to Child_in.Memo1.Lines.Count do
    if (findNode(Nodes[i - 1].ID + '.') = nil) and (Nodes[i - 1].cat <> 'terminal') then
    begin
      Child_out.Memo1.Text := 'Error: Node on line #' + inttostr(i) + ' should be connected or converted to a terminal node! Cannot continue.';
      Result := false;
      exit;
    end;

  //Check #6: Verify that each node has a parent, except for the root node
  n := 0;
  for i := 1 to Child_in.Memo1.Lines.Count do
  begin
    Str := parent(Nodes[i - 1].ID);
    if Nodes[i - 1].ID <> '1' then
      for j := 1 to Child_in.Memo1.Lines.Count do
        if findNode(Str) = nil then n := n + 1;
    if n > 2 then
    begin
      Child_out.Memo1.Text := 'Error: Node on line ' + inttostr(i) + ' has no parent! Cannot continue.';
      Result := false;
      exit;
    end;
  end;
end;

procedure calculate_accumulatives;
var
  i, j: Integer;
begin
  for i := 2 to maxl do
    for j := 1 to length(Nodes) do
      if level(Nodes[j - 1]) = i then
        Nodes[j - 1].accumul := findnode(parent(Nodes[j - 1].ID)).accumul + Nodes[j - 1].val;
end;

procedure calculate_EVs;
var
  i, j, k: Integer;
  pr: Double;
begin
  for j := 1 to length(Nodes) do
    if endnode(Nodes[j - 1].ID + '.') = false then
      Nodes[j - 1].ev := Nodes[j - 1].accumul;
  for i := maxl downto 1 do
    for j := 1 to length(Nodes) do
      if level(Nodes[j - 1]) = i then
        if endnode(Nodes[j - 1].ID + '.') = true then
        begin
          if Nodes[j - 1].cat = 'chance' then
          begin
            pr := 0;
            Nodes[j - 1].ev := 0;
            for k := 1 to length(Nodes) do
              if (Nodes[j - 1].ID + '.' = Copy(Nodes[k - 1].ID, 1, length(Nodes[j - 1].ID) + 1)) and (level(Nodes[k - 1]) - level(Nodes[j - 1]) = 1) then
              begin
                Nodes[j - 1].ev := Nodes[j - 1].ev + Nodes[k - 1].ev * Nodes[k - 1].prob;
                pr := pr + Nodes[k - 1].prob;
              end;
            if pr <> 1 then
            begin
              Child_out.Memo1.Text := 'Error: The sum of probabilities on all the branches of node ' + inttostr(j) + ' should be equal to one!';
              exit;
            end;
          end else
          begin
            Nodes[j - 1].ev := 0;
            for k := 1 to length(Nodes) do
              if (Nodes[j - 1].ID + '.' = Copy(Nodes[k - 1].ID, 1, length(Nodes[j - 1].ID) + 1)) and (level(Nodes[k - 1]) - level(Nodes[j - 1]) = 1) then
                Nodes[j - 1].ev := max(Nodes[j - 1].ev, Nodes[k - 1].ev);
          end;
        end;
end;

procedure TMainForm.start(Sender: TObject);
begin
  NodeStrings := TStringList.Create;
  try
    NodeStrings.LoadFromFile(FILENAME);
    Child_in.Memo1.Lines := NodeStrings;
  finally
    NodeStrings.Free;
  end;
end;

procedure TMainForm.AboutClick(Sender: TObject);
begin
  ShowMessage('DecisionTree v0.2' + sLineBreak + '(c) Shpati Koleka - MIT License');
end;

procedure TMainForm.CalculateClick(Sender: TObject);
var
  i: Integer;
begin
  setlength(Nodes, 0);
  loadnodes;
  Child_out.Memo1.text := '';
  if verify = true then
  begin
    maxl := maxlevel;
    calculate_accumulatives;
    calculate_EVs;
    if Copy(Child_out.Memo1.text, 1, 5) <> 'Error' then
    begin
      Child_out.Memo1.text := 'Expected Values for each of the nodes:';
      for i := 1 to length(Nodes) do
        Child_out.Memo1.Lines.Add(Nodes[i - 1].ID + ': ' + floattostr(Nodes[i - 1].EV));
    end;
  end;
end;

procedure TMainForm.SaveInputFileClick(Sender: TObject);
begin
  NodeStrings := TStringList.Create;
  try
    if filename = '' then SaveInputFileAsClick(self);
    NodeStrings.AddStrings(Child_in.Memo1.Lines);
    NodeStrings.SaveToFile(filename);
  finally
    NodeStrings.Free;
  end;
end;

procedure TMainForm.SaveOutputFileAsClick(Sender: TObject);
var
  saveDialog: TSaveDialog; // Save dialog variable
begin
  saveDialog := TSaveDialog.Create(self);
  saveDialog.Title := 'Save your Output as a file';
  saveDialog.InitialDir := GetCurrentDir;
  saveDialog.Filter := 'Text files|*.txt|All files|*.*';
  saveDialog.DefaultExt := 'txt';
  saveDialog.FilterIndex := 1;
  if saveDialog.Execute then
  begin
    NodeStrings := TStringList.Create;
    try
      NodeStrings.AddStrings(Child_out.Memo1.Lines);
      NodeStrings.SaveToFile(saveDialog.FileName);
      Child_out.Caption := 'Output - ' + saveDialog.FileName;
    finally
      NodeStrings.Free;
    end;
    saveDialog.Free;
  end;
end;

procedure TMainForm.OpenInputFileClick(Sender: TObject);
var
  openDialog: TOpenDialog; // Open dialog variable
begin
  openDialog := TOpenDialog.Create(self);
  openDialog.InitialDir := GetCurrentDir;
  openDialog.Options := [ofFileMustExist];
  openDialog.Filter := 'Text files|*.txt|All files|*.*';
  openDialog.FilterIndex := 1;
  if openDialog.Execute then
  begin
    filename := openDialog.FileName;
    Child_in.Caption := 'Input - ' + OpenDialog.FileName;
    Child_out.Memo1.text := '';
    Child_out.Caption := 'Output';
    MainForm.start(self);
  end;
  openDialog.Free;
end;

procedure TMainForm.SaveInputFileAsClick(Sender: TObject);
var
  saveDialog: TSaveDialog; // Save dialog variable
begin
  saveDialog := TSaveDialog.Create(self);
  saveDialog.Title := 'Save your Decision Tree as a file';
  saveDialog.InitialDir := GetCurrentDir;
  saveDialog.Filter := 'Text files|*.txt|All files|*.*';
  saveDialog.DefaultExt := 'txt';
  saveDialog.FilterIndex := 1;
  if saveDialog.Execute then
  begin
    NodeStrings := TStringList.Create;
    try
      NodeStrings.AddStrings(Child_in.Memo1.Lines);
      NodeStrings.SaveToFile(saveDialog.FileName);
      Child_in.Caption := 'Input - ' + saveDialog.FileName;
      filename := saveDialog.FileName;
    finally
      NodeStrings.Free;
    end;
    saveDialog.Free;
  end;
end;

procedure TMainForm.CreateMDIChilds;
begin
  { create a new MDI child window }
  Child_out := TMDIChild.Create(Application);
  Child_out.Caption := 'Output';
  Child_out.BorderIcons := Child_out.BorderIcons - [biMinimize];
  Child_in := TMDIChild.Create(Application);
  Child_in.Caption := 'Input';
  Child_in.BorderIcons := Child_in.BorderIcons - [biMinimize];
end;

procedure TMainForm.resize(Sender: TObject);
begin
  MainForm.Tile;
end;

procedure TMainForm.FileNewClick(Sender: TObject);
begin
  Child_in.Caption := 'Input';
  Child_in.Memo1.Text := '';
  Child_out.Caption := 'Output';
  Child_out.Memo1.Text := '';
end;

procedure TMainForm.FileExitClick(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.createwindows(Sender: TObject);
begin
  CreateMDIChilds;
end;

procedure TMainForm.TileClick(Sender: TObject);
begin
  if MainForm.TileMode = tbVertical then MainForm.TileMode := tbHorizontal else MainForm.TileMode := tbVertical;
  MainForm.Tile;
end;

end.

