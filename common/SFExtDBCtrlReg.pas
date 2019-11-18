//
//   Title:         SFExtDBCtrlReg
//
//   Description:   register controls
//
//   Created by:    Frank Huber
//
//   Copyright:     Frank Huber - The SoftwareFactory -
//                  Alberweilerstr. 1
//                  D-88433 Schemmerhofen
//
//                  http://www.thesoftwarefactory.de
//
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
