{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: JvgExport.PAS, released on 2003-01-15.

The Initial Developer of the Original Code is Andrey V. Chudin,  [chudin@yandex.ru]
Portions created by Andrey V. Chudin are Copyright (C) 2003 Andrey V. Chudin.
All Rights Reserved.

Contributor(s):
Michael Beck [mbeck@bigfoot.com].
Burov Dmitry, translation of russian text.

Last Modified:  2003-01-15

You may retrieve the latest version of this file at the Project JEDI's JVCL home page,
located at http://jvcl.sourceforge.net

Known Issues:
-----------------------------------------------------------------------------}

{$I JVCL.INC}

unit JvgExport;

interface

uses
  Windows, Messages, Graphics, ExtCtrls, SysUtils, Classes, Controls, Forms,
  QuickRpt, QRExport, DB,
  JclUnitConv,
  JvgTypes;

type
  TOnExportProgress = procedure(Progress: Integer) of object;

procedure ExportToExcel(QuickRep: TCustomQuickRep);
procedure ExportDataSetToExcel(DataSet: TDataSet; OnExportProgress: TOnExportProgress);

implementation

uses
  ComObj, JvgUtils;

procedure ExportToExcel(QuickRep: TCustomQuickRep);
var
  P: PChar;
  XL: Variant;
  Sheet: Variant;
  I, J, RecNo: Integer;
  SL1, SL2: TStringList;
  AExportFilter: TQRCommaSeparatedFilter;
  MemStream: TMemoryStream;
  TempFileName: string;
  Buffer: array [0..MAX_PATH] of Char;

  function DeleteEOLs(str: string): string;
  var
    I: Integer;
  begin
    for I := 1 to Length(str) do
      if (str[I] = #13) then str[I] := ' ';
    Result := str;
  end;
begin

  try
    XL := GetActiveOleObject('Excel.Application');
  except
    XL := CreateOleObject('Excel.Application');
  end;

  GetTempPath(SizeOf(Buffer), Buffer);
  TempFileName := Buffer + 'JvgExportToExcelTemp.txt';
  AExportFilter := TQRCommaSeparatedFilter.Create(TempFileName);
  try
    QuickRep.ExportToFilter(AExportFilter);
  finally
    AExportFilter.Free;
  end;

  XL.Visible := True;
  XL.WorkBooks.Add;
  XL.WorkBooks[XL.WorkBooks.Count].WorkSheets[1].Name := 'Report';
  Sheet := XL.WorkBooks[XL.WorkBooks.Count].WorkSheets['Report'];

  SL1 := TStringList.Create;
  SL2 := TStringList.Create;
  try
    //  Sheet.SetBackgroundPicture(FileName:=ExtractFilePath(ParamStr(0))+'data\bg.JPG');
    //  Sheet.Cells[1, 1] := 'Biblio'; Sheet.Cells[1, 1].Font.Color := $FFFFFF;
    //  Sheet.Cells[2, 1] := 'Globus'; Sheet.Cells[2, 1].Font.Color := $FFFFFF;
    //  Sheet.Columns[1].ColumnWidth := 11;

    RecNo := 1;
    Sheet.Cells[RecNo, 1] := 'Report created on ' + DateToStr(Date);
    Sheet.Cells[RecNo, 1].Font.Italic := True;
    Inc(RecNo);
    Sheet.Cells[RecNo, 1] := 'User ' + UserName;
    Sheet.Cells[RecNo, 1].Font.Italic := True;

    Inc(RecNo, 2);
    Sheet.Cells[RecNo, 1] := '';
    Sheet.Cells[RecNo, 1].Font.Bold := True;
    Sheet.Cells[RecNo, 1].Font.Size := 14;

    Inc(RecNo, 2);

    MemStream := TMemoryStream.Create;
    MemStream.LoadFromFile(TempFileName);
    P := MemStream.Memory;
    for I := 0 to MemStream.Size - 1 do
      if P[I] = Chr(0) then
        P[I] := ',';

    SL1.LoadFromStream(MemStream);
    MemStream.Free;
    for I := 0 to SL1.Count - 1 do
    begin
      SL2.CommaText := SL1[I];
      for J := 0 to SL2.Count - 1 do
        Sheet.Cells[RecNo, 1 + J] := SL2[J];
      Inc(RecNo);
    end;
  finally
    SL1.Free;
    SL2.Free;
    if FileExists(TempFileName) then
      DeleteFile(TempFileName);
  end;
end;

procedure ExportDataSetToExcel(DataSet: TDataSet; OnExportProgress: TOnExportProgress);
var
  XL: Variant;
  Sheet: Variant;
  I, RecNo, ColIndex: Integer;
begin
  try
    XL := GetActiveOleObject('Excel.Application');
  except
    XL := CreateOleObject('Excel.Application');
  end;

  XL.Visible := True;
  XL.WorkBooks.Add;
  XL.WorkBooks[XL.WorkBooks.Count].WorkSheets[1].Name := 'Report';
  Sheet := XL.WorkBooks[XL.WorkBooks.Count].WorkSheets['Report'];
  //  Sheet.SetBackgroundPicture(FileName:=ExtractFilePath(ParamStr(0))+'bg.JPG');

  //  Sheet.Cells[1, 1] := 'Biblio'; Sheet.Cells[1, 1].Font.Bold := True; Sheet.Cells[1, 1].Font.Color := clWhite;
  //  Sheet.Cells[2, 1] := 'Globus'; Sheet.Cells[2, 1].Font.Bold := True; Sheet.Cells[2, 1].Font.Color := clWhite;

  RecNo := 1;
  Sheet.Cells[RecNo, 2] := 'Document created on ' + DateToStr(Date) + '   ' + TimeToStr(Time);
  Sheet.Cells[RecNo, 2].Font.Italic := True;
  Inc(RecNo);
  Sheet.Cells[RecNo, 2] := 'User: ' + ComputerName + ' / ' + UserName;
  Sheet.Cells[RecNo, 2].Font.Italic := True;
  Inc(RecNo);
  Sheet.Cells[RecNo, 2] := 'Program: ' + ExtractFileName(ParamStr(0));
  Sheet.Cells[RecNo, 2].Font.Italic := True;

  // �����
  { Header [translated] }
  Inc(RecNo, 3);
  ColIndex := 0;
  for I := 0 to DataSet.FieldCount - 1 do
    if DataSet.Fields[I].Visible then
    begin
      if DataSet.Fields[I].DisplayLabel <> '' then
        Sheet.Cells[RecNo, 2 + ColIndex] := DataSet.Fields[I].DisplayLabel
      else
        Sheet.Cells[RecNo, 2 + ColIndex] := DataSet.Fields[I].FieldName;
      Sheet.Cells[RecNo, 2 + ColIndex].Font.Bold := True;
      Sheet.Cells[RecNo, 2 + ColIndex].Font.Size := 10;
      Inc(ColIndex);
    end;

  // ������ �����
  { Data has begun to pass in [translated] }
  DataSet.First;
  Inc(RecNo, 3);
  while not DataSet.Eof do
  begin
    ColIndex := 0;
    for I := 0 to DataSet.FieldCount - 1 do
      if DataSet.Fields[I].Visible then
      begin
        Sheet.Cells[RecNo, 2 + ColIndex] := DataSet.Fields[I].AsString;
        Inc(ColIndex);
      end;
    DataSet.Next;
    // (rom) using HowAOneLinerCanBiteYou as my easter egg ;-)
    if Assigned(OnExportProgress) then
      OnExportProgress(HowAOneLinerCanBiteYou(DataSet.RecNo, DataSet.RecordCount));
    Inc(RecNo);
  end;
end;

end.

