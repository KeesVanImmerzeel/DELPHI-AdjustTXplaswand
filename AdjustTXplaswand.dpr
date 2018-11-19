program AdjustTXplaswand;

uses
  Forms,
  Sysutils,
  uError,
  AVGRIDIO,
  uAdjustTXplaswand in 'uAdjustTXplaswand.pas' {MainForm};

{$R *.RES}

begin
  Application.Initialize;

  InitialiseGridIO;

  Application.CreateForm(TMainForm, MainForm);
  Mode := Interactive;
  Try
    Try

      if ( ParamCount = 6 ) then begin
        Mode := Batch;
        with MainForm do begin
          EditflxBottom.Text := ParamStr( 1 );
          Editplasrand.Text := ParamStr( 2 );
          EditTXorg.Text := ParamStr( 3 );
          ESBPosFloatEdit_F.Text := ParamStr( 4 );
          ESBPosFloatEditLaagdikte.Text := ParamStr( 5 );
          {-ParamStr( 6 ): result-idf, zie unit 'uAdjustCbodem' }
        end;
      end; {if ( ParamCount = 6 )}

      if ( Mode = Interactive ) then begin
        Application.Run;
      end else begin
        MainForm.GoButton.Click;
      end;
    Except
      WriteToLogFileFmt( 'Error in application: [%s].', [ApplicationFileName] );
    end;
  Finally

  end;
end.
