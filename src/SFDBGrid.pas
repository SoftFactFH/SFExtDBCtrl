unit SFDBGrid;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Grids, Vcl.DBGrids, Winapi.Windows,
  Vcl.Themes, Data.DB, Winapi.Messages;

type
  TSFDBGridExtOption =
  (
    extOptDisableDataDelete,
    extOptDisableDataAppend
  );

  TSFDBGridExtOptions = set of TSFDBGridExtOption;

  TSFDBGrid = class(TDBGrid)
  private
    mColumnAdjustment: Boolean;
    mOnMouseDown: TMouseEvent;
    mMouseDownFired: Boolean;
    mDeletedOptions: TDBGridOptions;
    mExtOptions: TSFDBGridExtOptions;
  private
    procedure adjustColumns(pNewW, pOldW: Integer);
    function getColumnsWidth: Integer;
    procedure setColumnAdjustment(pVal: Boolean);
    procedure parentMouseDownEvt(pSender: TObject; Button: TMouseButton;
                                    Shift: TShiftState; X, Y: Integer);
    procedure WMSetFocus(var Message: TWMSetFocus); message WM_SetFOCUS;
    procedure adjustColumnEditing;
  protected
    procedure Resize; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure ColEnter; override;
  public
    procedure Assign(Source: TPersistent); override;
    procedure UpdateScrollBar; override;
  public
    constructor Create(pOwner: TComponent); override;
  published
    property ColumnAdjustment: Boolean read mColumnAdjustment write setColumnAdjustment;
    property OnMouseDown: TMouseEvent read mOnMouseDown write mOnMouseDown;
    property OptionsExt: TSFDBGridExtOptions read mExtOptions write mExtOptions;
    property OnResize;
  end;

implementation

constructor TSFDBGrid.Create(pOwner: TComponent);
begin
  inherited;

  mOnMouseDown := nil;
  inherited OnMouseDown := parentMouseDownEvt;

  mMouseDownFired := False;
  mDeletedOptions := [];
  mExtOptions := [extOptDisableDataDelete];
end;

procedure TSFDBGrid.UpdateScrollBar;
  var lOldScrollInfo, lNewScrollInfo: TScrollInfo;
      lScrollBarVisible: Boolean;
begin
  if (Datalink.Active) and (HandleAllocated) then
  begin
    with Datalink.DataSet do
    begin
      lOldScrollInfo.cbSize := sizeof(lOldScrollInfo);
      lOldScrollInfo.fMask := SIF_ALL;
      GetScrollInfo(Self.Handle, SB_VERT, lOldScrollInfo);
      lNewScrollInfo := lOldScrollInfo;
      if IsSequenced then
      begin
        lScrollBarVisible := (RecordCount > Self.VisibleRowCount);
        if (lScrollBarVisible) then
        begin
          lNewScrollInfo.nMin := 1;
          lNewScrollInfo.nPage := Self.VisibleRowCount;
          lNewScrollInfo.nMax := Integer(DWORD(RecordCount) + lNewScrollInfo.nPage - 1);

          if State in [dsInactive, dsBrowse, dsEdit] then
            lNewScrollInfo.nPos := RecNo;  // else keep old pos
        end else
        begin
          lNewScrollInfo.nMin := Self.VisibleRowCount;
          lNewScrollInfo.nPage := lNewScrollInfo.nMin;
          lNewScrollInfo.nMax := lNewScrollInfo.nMin;
          lNewScrollInfo.nPos := 1;
        end;
      end
      else
      begin
        lScrollBarVisible := True;
        lNewScrollInfo.nMin := 0;
        lNewScrollInfo.nPage := 0;
        lNewScrollInfo.nMax := 4;

        if (DataLink.BOF) then
          lNewScrollInfo.nPos := 0
        else if (DataLink.EOF) then
          lNewScrollInfo.nPos := 4
        else
          lNewScrollInfo.nPos := 2;
      end;

      // mHasVertScrollBar := lScrollBarVisible;
      ShowScrollBar(Self.Handle, SB_VERT, lScrollBarVisible);
      SetScrollInfo(Self.Handle, SB_VERT, lNewScrollInfo, True);

      if TStyleManager.IsCustomStyleActive then
        SendMessage(Handle, WM_NCPAINT, 0, 0);
    end;
  end;
end;

procedure TSFDBGrid.Resize;
begin
  if (mColumnAdjustment) then
    adjustColumns(ClientWidth, getColumnsWidth);

  inherited;
end;

procedure TSFDBGrid.KeyDown(var Key: Word; Shift: TShiftState);
  var lReadOnly: Boolean;
begin
  lReadOnly := ReadOnly;
  try
    if (Key = VK_DELETE) and (ssCtrl in Shift) then
      ReadOnly := ReadOnly or (extOptDisableDataDelete in mExtOptions)
    else
    begin
      case Key of
        VK_DOWN, VK_RIGHT, VK_TAB: ReadOnly := ReadOnly or (extOptDisableDataAppend in mExtOptions);
      end;
    end;

    inherited;
  finally
    ReadOnly := lReadOnly;
  end;
end;

procedure TSFDBGrid.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  mMouseDownFired := False;
  try
    inherited;

    if not(mMouseDownFired) then
      parentMouseDownEvt(Self, Button, Shift, X, Y);
  finally
    mMouseDownFired := False;
  end;
end;

procedure TSFDBGrid.ColEnter;
begin
  adjustColumnEditing;

  inherited;
end;


procedure TSFDBGrid.Assign(Source: TPersistent);
begin
  inherited;

  if (Source is TSFDBGrid) then
  begin
    ColumnAdjustment := TSFDBGrid(Source).ColumnAdjustment;
    OptionsExt := TSFDBGrid(Source).OptionsExt;
  end;
end;

procedure TSFDBGrid.adjustColumns(pNewW, pOldW: Integer);
  var lFactor: Real;
      i, lNewW: Integer;
begin
  if (pNewW <= 0) or (pOldW <= 0) then
    Exit;

  lNewW := pNewW - 5;
  if (dgIndicator in Options) then
    lNewW := lNewW - 15;

  if (lNewW <> pOldW) then
  begin
    BeginUpdate;
    try
      lFactor := lNewW / pOldW;
      for i := 0 to (Columns.Count - 1) do
        Columns[i].Width := Round(Columns[i].Width * lFactor);
    finally
      EndUpdate;
    end;
  end;
end;

function TSFDBGrid.getColumnsWidth: Integer;
  var i: Integer;
begin
  Result := 0;

  for i := 0 to (Columns.Count - 1) do
    Result := Result + Columns[i].Width;
end;

procedure TSFDBGrid.setColumnAdjustment(pVal: Boolean);
begin
  if (pVal <> mColumnAdjustment) then
  begin
    mColumnAdjustment := pVal;
    adjustColumns(ClientWidth, getColumnsWidth);
  end;
end;

procedure TSFDBGrid.parentMouseDownEvt(pSender: TObject; Button: TMouseButton;
                                        Shift: TShiftState; X, Y: Integer);
begin
  if (Assigned(mOnMouseDown)) then
    mOnMouseDown(pSender, Button, Shift, X, Y);

  mMouseDownFired := True;
end;

procedure TSFDBGrid.WMSetFocus(var Message: TWMSetFocus);
begin
  adjustColumnEditing;

  inherited;
end;

procedure TSFDBGrid.adjustColumnEditing;
begin
  Options := Options + mDeletedOptions;

  if (SelectedIndex < Columns.Count) then
  begin
    if (dgEditing in Options) and not(dgAlwaysShowEditor in Options)
      and (Columns.Items[SelectedIndex].ReadOnly) then
    begin
      Options := Options - [dgEditing];
      mDeletedOptions := mDeletedOptions + [dgEditing];
    end;
  end;
end;

end.
