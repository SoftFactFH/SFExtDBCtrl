unit SFDBGridInplaceCheckBox;

interface

uses
  System.SysUtils, System.Classes, Vcl.DBCtrls, Vcl.Controls, Vcl.Grids,
  Vcl.DBGrids, System.Types;

type
  TSFDBGridInplaceCheckBox = class(TDBCheckBox)
  private
    mDBGrid: TDBGrid;
    mColumnIdx: Integer;
    mGrdDrawColCellSave: TDrawColumnCellEvent;
  private
    procedure setDBGrid(pVal: TDBGrid);
    procedure setColumnIdx(pVal: Integer);
    function findAssignedGrid(pParent: TWinControl; pName: String): TControl;
  private
    procedure grdDrawColumnCell(Sender: TObject; const Rect: TRect; DataCol: Integer;
                                  Column: TColumn; State: TGridDrawState);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure DoExit; override;
  public
    procedure Assign(Source: TPersistent); override;
  public
    constructor Create(pOwner: TComponent); override;
    destructor Destroy; override;
  published
    property DBGrid: TDBGrid read mDBGrid write setDBGrid;
    property ColIdx: Integer read mColumnIdx write setColumnIdx;
  end;

implementation

uses Winapi.Windows, Data.DB;

constructor TSFDBGridInplaceCheckBox.Create(pOwner: TComponent);
begin
  inherited;

  mDBGrid := nil;
  mColumnIdx := -1;
  mGrdDrawColCellSave := nil;
end;

destructor TSFDBGridInplaceCheckBox.Destroy;
begin
  inherited;

  if (Assigned(mDBGrid)) then
  begin
    mDBGrid.OnDrawColumnCell := mGrdDrawColCellSave;
    mDBGrid := nil;
  end;
end;

procedure TSFDBGridInplaceCheckBox.Assign(Source: TPersistent);
  var lNewGrd: TControl;
begin
  inherited;

  if (Source is TSFDBGridInplaceCheckBox) then
  begin
    if (Assigned(TSFDBGridInplaceCheckBox(Source).DBGrid)) then
    begin
      lNewGrd := findAssignedGrid(Parent, TSFDBGridInplaceCheckBox(Source).DBGrid.Name);
      if (Assigned(lNewGrd)) and (lNewGrd is TDBGrid) then
        DBGrid := TDBGrid(lNewGrd);
    end;

    ColIdx := TSFDBGridInplaceCheckBox(Source).ColIdx;
  end;
end;

procedure TSFDBGridInplaceCheckBox.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;

  if (Operation = opRemove) and (Assigned(mDBGrid)) and (AComponent = mDBGrid) then
    mDBGrid := nil;
end;

procedure TSFDBGridInplaceCheckBox.DoExit;
begin
  inherited;

  if (Assigned(mDBGrid)) then
    Visible := False;
end;

procedure TSFDBGridInplaceCheckBox.grdDrawColumnCell(Sender: TObject;
    const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
  const
    LC_CHECKSIZE = 15;
  var
    lInplaceRect, lCellRect: TRect;
    lHandled: Boolean;
begin
  inherited;

  lHandled := False;
  if (Assigned(mGrdDrawColCellSave)) then
  begin
    mGrdDrawColCellSave(Sender, Rect, DataCol, Column, State);
    lHandled := True;
  end;

  if (Assigned(mDBGrid)) and (Assigned(DataSource)) and (DataSource = mDBGrid.DataSource)
    and (Assigned(DataSource.DataSet)) and (DataCol = mColumnIdx) then
  begin
    if (mDBGrid.Focused) and (gdSelected in State) and
      ((DataSource.AutoEdit) or (DataSource.DataSet.State in [dsEdit, dsInsert]))
      and (DataSource.DataSet.RecNo >= 1) then
    begin
      lInplaceRect := Rect;
      lInplaceRect.Left := mDBGrid.Left + lInplaceRect.Left;
      lInplaceRect.Top := mDBGrid.Top + lInplaceRect.Top;
      lInplaceRect.Right := mDBGrid.Left + lInplaceRect.Right;
      lInplaceRect.Bottom := mDBGrid.Top + lInplaceRect.Bottom;

      Width := LC_CHECKSIZE;
      Height := LC_CHECKSIZE;
      Left := lInplaceRect.Left + ((lInplaceRect.Right - lInplaceRect.Left - LC_CHECKSIZE) div 2) + 2;
      Top := lInplaceRect.Top + ((lInplaceRect.Bottom - lInplaceRect.Top - LC_CHECKSIZE) div 2) + 2;
      Checked := (DataSource.DataSet.FieldByName(Column.FieldName).AsString = ValueChecked);
      Visible := True;
      BringToFront;
      SetFocus;
    end else
    begin
      lCellRect := Rect;
      lCellRect.Top := lCellRect.Top + ((lCellRect.Bottom - lCellRect.Top - LC_CHECKSIZE) div 2);
      lCellRect.Bottom := lCellRect.Top + LC_CHECKSIZE;
      lCellRect.Left := lCellRect.Left + ((lCellRect.Right - lCellRect.Left - LC_CHECKSIZE) div 2);
      lCellRect.Right := lCellRect.Left + LC_CHECKSIZE;
      if (DataSource.DataSet.FieldByName(Column.FieldName).AsString = ValueChecked) then
        DrawFrameControl(mDBGrid.Canvas.Handle, lCellRect, DFC_BUTTON, DFCS_CHECKED)
      else
        DrawFrameControl(mDBGrid.Canvas.Handle, lCellRect, DFC_BUTTON, DFCS_BUTTONCHECK);
    end;
  end else
  if not(lHandled) then
    mDBGrid.DefaultDrawColumnCell(Rect, DataCol, Column, State);
end;

procedure TSFDBGridInplaceCheckBox.setDBGrid(pVal: TDBGrid);
begin
  if (pVal <> mDBGrid) then
  begin
    if (Assigned(mDBGrid)) then
    begin
      mDBGrid.OnDrawColumnCell := mGrdDrawColCellSave;
      mDBGrid.RemoveFreeNotification(Self);
    end;

    mDBGrid := pVal;
    mGrdDrawColCellSave := mDBGrid.OnDrawColumnCell;
    mDBGrid.OnDrawColumnCell := grdDrawColumnCell;
    mDBGrid.FreeNotification(Self);

    Visible := False;

    if (mColumnIdx > -1) then
      mDBGrid.Invalidate;
  end;
end;

procedure TSFDBGridInplaceCheckBox.setColumnIdx(pVal: Integer);
begin
  if (pVal <> mColumnIdx) then
  begin
    mColumnIdx := pVal;

    Visible := False;

    if (Assigned(mDBGrid)) then
      mDBGrid.Invalidate;
  end;
end;

function TSFDBGridInplaceCheckBox.findAssignedGrid(pParent: TWinControl; pName: String): TControl;
begin
  Result := nil;

  if not(Assigned(pParent)) then
    Exit;

  Result := pParent.FindChildControl(pName);
  if not(Assigned(Result)) and (Assigned(pParent.Parent)) then
    Result := findAssignedGrid(pParent.Parent, pName);
end;

end.
