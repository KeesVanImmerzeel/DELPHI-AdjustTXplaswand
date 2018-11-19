unit uAdjustTXplaswand;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, uTSingleESRIgrid, uError, Registry, ESBPCSEdit, ESBPCSNumEdit, Math,
  uTabstractESRIgrid;

type
  TMainForm = class(TForm)
    GoButton: TButton;
    SingleESRIgridFLxBottom: TSingleESRIgrid;
    SingleESRIgridPlasRand: TSingleESRIgrid;
    SingleESRIgridTXorg: TSingleESRIgrid;
    Memo1: TMemo;
    EditflxBottom: TEdit;
    EditplasRand: TEdit;
    EditTXorg: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    OpenDialogflxBottom: TOpenDialog;
    OpenDialogPlasRand: TOpenDialog;
    OpenDialogTXorg: TOpenDialog;
    SaveDialog1: TSaveDialog;
    ESBPosFloatEdit_F: TESBPosFloatEdit;
    Label4: TLabel;
    ESBPosFloatEditLaagdikte: TESBPosFloatEdit;
    Laagdikte: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure EditflxBottomClick(Sender: TObject);
    procedure EditplasRandClick(Sender: TObject);
    procedure EditTXorgClick(Sender: TObject);
    procedure GoButtonClick(Sender: TObject);
    procedure ESBPosFloatEdit_FChange(Sender: TObject);
    procedure ESBPosFloatEditLaagdikteChange(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    
  private
    { Private declarations }
  public
    { Public declarations }
    FIniFile: TRegIniFile;
  end;

  EInputFileDoesNotExist = class( Exception );
  EErrorOpeningIDFfile = class( Exception );

ResourceString
  sInputFileDoesNotExist = 'Input-file "%s" does not exist.';
  sErrorOpeningIDFfile = 'Error opening idf-file: "%s".';

var
  MainForm: TMainForm;

  implementation

{$R *.DFM}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  InitialiseLogFile;
  Caption := ExtractFileName( ChangeFileExt( ParamStr( 0 ), '' ) );
  FIniFile := TRegIniFile.Create( 'ParamStr( 0 )' );
  if ( Mode = Interactive ) then begin
    EditflxBottom.Text  := FIniFile.ReadString( 'Settings', 'EditflxBottom', 'EditflxBottom' );
    EditplasRand.text := FIniFile.ReadString( 'Settings', 'EditplasRand', 'EditplasRand' );
    EditTXorg.Text := FIniFile.ReadString( 'Settings', 'EditTXorg', 'EditTXorg' );
    ESBPosFloatEdit_F.Text := FIniFile.ReadString( 'Settings', 'Edit_F', '2250' );
    ESBPosFloatEditLaagdikte.Text := FIniFile.ReadString( 'Settings', 'Edit_Laagdikte', '10' );
  end;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
FinaliseLogFile;
end;

procedure TMainForm.EditflxBottomClick(Sender: TObject);
begin
  with OpenDialogflxBottom do begin
    if execute then begin
      EditflxBottom.Text := ExpandFileName( FileName );
      FIniFile.WriteString( 'Settings', 'EditflxBottom', EditflxBottom.Text );
    end;
  end;
end;

procedure TMainForm.EditplasRandClick(Sender: TObject);
begin
  with OpenDialogPlasRand do begin
    if execute then begin
      EditplasRand.text := ExpandFileName( FileName );
      FIniFile.WriteString( 'Settings', 'EditplasRand', EditplasRand.text );
    end;
  end;
end;

procedure TMainForm.EditTXorgClick(Sender: TObject);
begin
  with OpenDialogTXorg do begin
    if execute then begin
      EditTXorg.Text := ExpandFileName( FileName );
      FIniFile.WriteString( 'Settings', 'EditTXorg', EditTXorg.Text );
    end;
  end;
end;

procedure TMainForm.GoButtonClick(Sender: TObject);
var
  iResult: Integer;

Procedure AdjustTXvalues; {-Verhoog de c-waarden op de plasbodem (evenredig met de infiltratieflux}
var
  NRows, NCols, i, j: integer;
  x, y, aValue, flxM3perD, OrgkValue, cOrgValue, cAddedValue, cNewValue, kNewValue, flxMperD: Single;
  fValue, CellArea: Double;
begin
  NRows := SingleESRIgridTXorg.NRows;
  NCols := SingleESRIgridTXorg.NCols;
  for i:=1 to NRows do begin
    for j:=1 to NCols do begin
      SingleESRIgridTXorg.GetCellCentre( i, j, x, y );
      aValue := SingleESRIgridPlasRand.GetValueXY( x, y );
      if ( aValue > 0 ) then begin {-Als het een cel is op de plasrand}
        flxM3perD := SingleESRIgridFLxBottom.GetValueXY( x, y );
        if ( flxM3perD < 0 ) then begin {-Als er infiltratie wordt berekend}
          CellArea := SingleESRIgridFLxBottom.CellArea;
          flxMperD := flxM3perD / CellArea;
          fValue   := ESBPosFloatEdit_F.AsFloat;
          cAddedValue := - fValue * flxMperD;

          OrgkValue := SingleESRIgridTXorg[ i, j ] / ESBPosFloatEditLaagdikte.AsFloat;
          cOrgValue := SingleESRIgridTXorg.CellSize / OrgkValue;

          cNewValue := cOrgValue + cAddedValue;
          kNewValue := max( SingleESRIgridTXorg.CellSize / cNewValue, 0.1 ); // FOUT! moet omgekeerd zijn

          SingleESRIgridTXorg[ i, j ] := min( kNewValue * ESBPosFloatEditLaagdikte.AsFloat, SingleESRIgridTXorg[ i, j ] );
        end;
      end;
    end;
  end; {-for i}
end; {-Procedure AdjustTXvalues;}

begin
  with SaveDialog1 do begin
    if ( Mode = Interactive ) then
      FileName := FIniFile.ReadString( 'Settings', 'DirOfgridcResult', 'c:' ) + '\cResult.idf';
    if ( Mode = Batch ) or ( ( Mode = Interactive ) and Execute ) then begin
      try
        try
          if ( Mode = Interactive ) then
            FIniFile.WriteString( 'Settings', 'DirOfgridcResult', ExtractFileDir ( FileName ) )
          else
            FileName := ParamStr( 6 );

          {-Controleer het bestaan van de invoer-idf bestanden}
          if ( not FileExists( EditflxBottom.Text ) ) then
            Raise EInputFileDoesNotExist.CreateResFmt( @sInputFileDoesNotExist, [ EditflxBottom.Text ] );
          if ( not FileExists( EditplasRand.Text ) ) then
            Raise EInputFileDoesNotExist.CreateResFmt( @sInputFileDoesNotExist, [ EditplasRand.Text ] );
          if ( not FileExists( EditTXorg.Text ) ) then
            Raise EInputFileDoesNotExist.CreateResFmt( @sInputFileDoesNotExist, [ EditTXorg.Text ] );

          {-Open invoer idf-bestanden}
          SingleESRIgridFLxBottom := TSingleESRIgrid.InitialiseFromIDFfile( EditflxBottom.Text, iResult, self );
          if ( iResult <> cNoError ) then
            Raise EErrorOpeningIDFfile.CreateResFmt( @sErrorOpeningIDFfile, [ EditflxBottom.Text ] );
          SingleESRIgridPlasRand := TSingleESRIgrid.InitialiseFromIDFfile( EditplasRand.Text, iResult, self );
          if ( iResult <> cNoError ) then
            Raise EErrorOpeningIDFfile.CreateResFmt( @sErrorOpeningIDFfile, [ EditplasRand.Text ] );
          SingleESRIgridTXorg := TSingleESRIgrid.InitialiseFromIDFfile( EditTXorg.Text, iResult, self );
          if ( iResult <> cNoError ) then
            Raise EErrorOpeningIDFfile.CreateResFmt( @sErrorOpeningIDFfile, [ EditTXorg.Text ] );

          AdjustTXvalues;

          SingleESRIgridTXorg.ExportToIDFfile( FileName );

        Except
          On E: Exception do begin
            HandleError( E.Message, true );
          end;
        end; {-Except}
      Finally
      end; {-Finally}

    end; {if execute }
  end; {with SaveCresultIdfDialog }
end;

procedure TMainForm.ESBPosFloatEdit_FChange(Sender: TObject);
begin
  FIniFile.WriteString( 'Settings', 'Edit_F', ESBPosFloatEdit_F.Text  );
end;

procedure TMainForm.ESBPosFloatEditLaagdikteChange(Sender: TObject);
begin
  FIniFile.WriteString( 'Settings', 'Edit_Laagdikte', ESBPosFloatEditLaagdikte.Text );
end;

initialization
  Mode := interactive;
finalization

end.
