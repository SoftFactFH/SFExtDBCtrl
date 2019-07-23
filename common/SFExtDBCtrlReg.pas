unit SFExtDBCtrlReg;

interface

uses System.Classes, System.SysUtils;

procedure Register;

implementation

uses SFDBGrid, SFDBGridInplaceCheckBox;

procedure Register;
begin
  RegisterComponents('SFFH ExtDBCtrls', [TSFDBGrid, TSFDBGridInplaceCheckBox]);
end;

end.
