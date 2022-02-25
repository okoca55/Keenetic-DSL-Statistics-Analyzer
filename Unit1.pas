unit Unit1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, System.IOUtils,
  IdBaseComponent, IdComponent, IdCustomTCPServer, IdCustomHTTPServer, IdSocketHandle, 
  IdHTTPServer, IdContext, IdServerIOHandler, IdServerIOHandlerSocket,
  IdServerIOHandlerStack, FMX.WebBrowser, FMX.Controls.Presentation,
  FMX.StdCtrls, FMX.Memo.Types, FMX.ScrollBox, FMX.Memo, FMX.Layouts,
  FMX.ListBox, Winapi.EdgeUtils, WinApi.ShellAPI;

type
  TMain = class(TForm)
    IdHTTPServer: TIdHTTPServer;
    IdServerIOHandlerStack: TIdServerIOHandlerStack;
    WebBrowser: TWebBrowser;
    TimerStartup: TTimer;
    ListBox_GraphFields: TListBox;
    Splitter1: TSplitter;
    Memo_RequestLog: TMemo;
    Layout1: TLayout;
    procedure FormCreate(Sender: TObject);
    procedure IdHTTPServerCommandGet(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
    procedure TimerStartupTimer(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ListBox_GraphFieldsItemClick(const Sender: TCustomListBox; const Item: TListBoxItem);
    procedure ListBox_GraphFieldsChangeCheck(Sender: TObject);
  private
    { Private declarations }
    Procedure WebBrowser_EdgeDestegiYukluDegil;
  public
    { Public declarations }
  end;

var
  Main: TMain;

implementation

{$R *.fmx}

Const
 pos_Date = 0;
 pos_LineState = 1;
 pos_LastDropReason = 2;
 pos_US_bitrate_Kbps = 3;
 pos_DS_bitrate_Kbps = 4;
 pos_US_FEC_fast = 5;
 pos_DS_FEC_fast = 6;
 pos_US_CRC_fast = 7;
 pos_DS_CRC_fast = 8;
 pos_US_HEC_fast = 9;
 pos_DS_HEC_fast = 10;
 pos_US_FEC_interleaved = 11;
 pos_DS_FEC_interleaved = 12;
 pos_US_CRC_interleaved = 13;
 pos_DS_CRC_interleaved = 14;
 pos_US_HEC_interleaved = 15;
 pos_DS_HEC_interleaved = 16;
 pos_US_line_capacity = 17; // %
 pos_DS_line_capacity = 18; // %
 pos_US_noise_margin_dB = 19;
 pos_DS_noise_margin_dB = 20;
 pos_US_output_power_dBm = 21;
 pos_DS_output_power_dBm = 22;
 pos_US_attenuation_dB = 23;
 pos_DS_attenuation_dB = 24;
 pos_US_errored_seconds_ES = 25;
 pos_DS_errored_seconds_ES = 26;
 pos_US_severly_errored_seconds_SES = 27;
 pos_DS_severly_errored_seconds_SES = 28;
 pos_US_unavailable_seconds_UAS = 29;
 pos_DS_unavailable_seconds_UAS = 30;
 pos_TX_ethernet_packets = 31;
 pos_RX_ethernet_packets = 32;
 
Var
 WebServerBindPort:Integer=5000;
 WebServerBindIP:String='127.0.0.1';
 WebServerRequestAddress:String='';
 WebServerRequestDiagramPrmKey:String='showdiagram=';
 // -------------------------------
 dataStatisticsCSV:TStringList;


// ------------------------------------------------- 

function StreamToString(Stream: TStream):String;
begin
 with TStringStream.Create do
 try
  CopyFrom(Stream, Stream.Size-Stream.Position);
  Result:=DataString;
 finally
  Free;
 end;
end;

Function Resource2Stream(ResourceName:String):String;
var
 rStream:TResourceStream;

begin
 Result:='';
 Try
  rStream:=TResourceStream.Create(hInstance, ResourceName, RT_RCDATA);
 Except
  rStream:=Nil;
 End;
 if rStream <> nil then
 Begin
  Try
   rStream.Position:=0;
   Result:=StreamToString(rStream);
  Finally
   rStream.Free;
  End;
 End;
End; 

Function GenerateRandomNumber(Min, Max:Integer):Integer;
Begin
 Repeat
  Result:=Random(Max);
 Until (Result>Min) And (Result<Max);
End;

Function GetCharCount(Data:String; sChar:Char):Integer;
Var
 I:Integer;

Begin
 Result:=0;
 if Length(Data)=0 then Exit;
 for I:=Low(Data) To High(Data) Do
 Begin
  if Data[I]=sChar then
   Result:=Result+1;
 End;
End;

Function DSL_Statistics_CSV_GetSectorData(ndm_dsl_statistics_csv_data:String; sectorIndex:Byte; UseDubleQuateForValues:Boolean):String; // [array]
Var
 dataStatisticsCSV, ExplodedData:TStringList;
 DataLine:String;
 I:Integer;

Begin
 Result:='';
 dataStatisticsCSV:=TStringList.Create;
 dataStatisticsCSV.Text:=Trim(ndm_dsl_statistics_csv_data);
 If (Length(ndm_dsl_statistics_csv_data)>0) Then
 Begin
  Result:='';
  ExplodedData:=TStringList.Create;
  ExplodedData.Delimiter:=',';
  ExplodedData.StrictDelimiter:=True;

  for I:=1 To dataStatisticsCSV.Count-1 Do
  Begin
   DataLine:=Trim(dataStatisticsCSV.Strings[I]);
   if (Length(DataLine)>0) And
      (GetCharCount(DataLine, ',')=32) then
   Begin
    ExplodedData.DelimitedText:=DataLine;
    if (UseDubleQuateForValues=True) then    
    Begin
     Result:=Result+'"'+ExplodedData.Strings[sectorIndex]+'", ';
    End
    Else
    Begin
     Result:=Result+ExplodedData.Strings[sectorIndex]+', ';    
    End;
   End;
  End; 
  ExplodedData.Free;
 End;
 dataStatisticsCSV.Free;
End;
 
Procedure DSL_StatisticsFile_LoadFile(Const ndm_dsl_statistics_csv:String);
Begin
 if Not FileExists(ndm_dsl_statistics_csv) then Exit;
 dataStatisticsCSV.LoadFromFile(ndm_dsl_statistics_csv);
End;

Function DSL_Statistics_GenerateLabels:String;
Begin 
 Result:=DSL_Statistics_CSV_GetSectorData(dataStatisticsCSV.Text, pos_Date, True);
End;

Function datasetIndex2Str(Index:Byte):String;
Begin
 Result:='?';
 If (Index=pos_Date) Then Begin Result:='Date'; End;
 If (Index=pos_LineState) Then Begin Result:='Line State'; End;
 If (Index=pos_LastDropReason) Then Begin Result:='Last Drop Reason'; End;
 If (Index=pos_US_bitrate_Kbps) Then Begin Result:='US bitrate Kbps'; End;
 If (Index=pos_DS_bitrate_Kbps) Then Begin Result:='DS bitrate Kbps'; End;
 If (Index=pos_US_FEC_fast) Then Begin Result:='US FEC fast'; End;
 If (Index=pos_DS_FEC_fast) Then Begin Result:='DS FEC fast'; End;
 If (Index=pos_US_CRC_fast) Then Begin Result:='US CRC fast'; End;
 If (Index=pos_DS_CRC_fast) Then Begin Result:='DS CRC fast'; End;
 If (Index=pos_US_HEC_fast) Then Begin Result:='US HEC fast'; End;
 If (Index=pos_DS_HEC_fast) Then Begin Result:='DS HEC fast'; End;
 If (Index=pos_US_FEC_interleaved) Then Begin Result:='US FEC interleaved'; End;
 If (Index=pos_DS_FEC_interleaved) Then Begin Result:='DS FEC interleaved'; End;
 If (Index=pos_US_CRC_interleaved) Then Begin Result:='US CRC interleaved'; End;
 If (Index=pos_DS_CRC_interleaved) Then Begin Result:='DS CRC interleaved'; End;
 If (Index=pos_US_HEC_interleaved) Then Begin Result:='US HEC interleaved'; End;
 If (Index=pos_DS_HEC_interleaved) Then Begin Result:='DS HEC interleaved'; End;
 If (Index=pos_US_line_capacity) Then Begin Result:='US line capacity'; End;
 If (Index=pos_DS_line_capacity) Then Begin Result:='DS line capacity'; End;
 If (Index=pos_US_noise_margin_dB) Then Begin Result:='US noise margin dB'; End;
 If (Index=pos_DS_noise_margin_dB) Then Begin Result:='DS noise margin dB'; End;
 If (Index=pos_US_output_power_dBm) Then Begin Result:='US output power dBm'; End;
 If (Index=pos_DS_output_power_dBm) Then Begin Result:='DS output power dBm'; End;
 If (Index=pos_US_attenuation_dB) Then Begin Result:='US attenuation dB'; End;
 If (Index=pos_DS_attenuation_dB) Then Begin Result:='DS attenuation dB'; End;
 If (Index=pos_US_errored_seconds_ES) Then Begin Result:='US errored seconds ES'; End;
 If (Index=pos_DS_errored_seconds_ES) Then Begin Result:='DS errored seconds ES'; End;
 If (Index=pos_US_severly_errored_seconds_SES) Then Begin Result:='US severly errored seconds SES'; End;
 If (Index=pos_DS_severly_errored_seconds_SES) Then Begin Result:='DS severly errored seconds SES'; End;
 If (Index=pos_US_unavailable_seconds_UAS) Then Begin Result:='US unavailable seconds UAS'; End;
 If (Index=pos_DS_unavailable_seconds_UAS) Then Begin Result:='DS unavailable seconds UAS'; End;
 If (Index=pos_TX_ethernet_packets) Then Begin Result:='TX ethernet packets'; End;
 If (Index=pos_RX_ethernet_packets) Then Begin Result:='RX ethernet packets'; End;
End;

Function DSL_Statistics_GenerateDataSet(datasetIndex:Byte):String;
Var
 UseDubleQuateForValues:Boolean;
 
Begin
 UseDubleQuateForValues:=False;
 if (datasetIndex=pos_Date) then UseDubleQuateForValues:=True;
 // ----------------------------------------------------------
 Result:='{ label: '+#39+' '+datasetIndex2Str(datasetIndex)+' '+#39+', '+
         '   data: ['+DSL_Statistics_CSV_GetSectorData(dataStatisticsCSV.Text, datasetIndex, UseDubleQuateForValues)+'], '+
         '   fill: true, '+
         '   borderColor: '+#39+' rgb('+Random(255).ToString+', '+Random(255).ToString+', '+Random(255).ToString+') '+#39+', '+
         '   tension: 0.1, '+
         '}, ';
End;

procedure TMain.IdHTTPServerCommandGet(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
Var
 sContentText,
 sRequestParam,
 sRequestDocument:String;
 
begin                                                   
 sRequestDocument:=LowerCase(ARequestInfo.Document);
 sRequestParam:=LowerCase(StringReplace(ARequestInfo.UnparsedParams,'%20', ' ', [rfReplaceAll, rfIgnoreCase]));
 AResponseInfo.ServerSoftware:='okoca'+#39+'s web server.';
 // -------------------------------------------------------
 sContentText:='File not found.';
 AResponseInfo.ContentType:='text/html';
 AResponseInfo.ResponseNo:=404;

 if (sRequestDocument=LowerCase('/')) And
    (Pos(LowerCase(WebServerRequestDiagramPrmKey), sRequestParam)>0) then
 Begin
  sContentText:=Resource2Stream('index_html');
  sContentText:=StringReplace(sContentText, '/*{{ chart.labels }}*/', DSL_Statistics_GenerateLabels, [rfReplaceAll, rfIgnoreCase]);
  
  If (Pos(LowerCase(datasetIndex2Str(Pos_Date)), sRequestParam)>0) Then
   sContentText:=StringReplace(sContentText, '/*{{ chart.dataset.Date }}*/', DSL_Statistics_GenerateDataSet(Pos_Date), [rfReplaceAll, rfIgnoreCase]); 

  If (Pos(LowerCase(datasetIndex2Str(Pos_LineState)), sRequestParam)>0) Then
   sContentText:=StringReplace(sContentText, '/*{{ chart.dataset.LineState }}*/', DSL_Statistics_GenerateDataSet(Pos_LineState), [rfReplaceAll, rfIgnoreCase]); 

  If (Pos(LowerCase(datasetIndex2Str(pos_LastDropReason)), sRequestParam)>0) Then
  sContentText:=StringReplace(sContentText, '/*{{ chart.dataset.LastDropReason }}*/', DSL_Statistics_GenerateDataSet(pos_LastDropReason), [rfReplaceAll, rfIgnoreCase]); 

  If (Pos(LowerCase(datasetIndex2Str(pos_US_bitrate_Kbps)), sRequestParam)>0) Then
   sContentText:=StringReplace(sContentText, '/*{{ chart.dataset.US_bitrate_Kbps }}*/', DSL_Statistics_GenerateDataSet(pos_US_bitrate_Kbps), [rfReplaceAll, rfIgnoreCase]); 

  If (Pos(LowerCase(datasetIndex2Str(pos_DS_bitrate_Kbps)), sRequestParam)>0) Then
   sContentText:=StringReplace(sContentText, '/*{{ chart.dataset.DS_bitrate_Kbps }}*/', DSL_Statistics_GenerateDataSet(pos_DS_bitrate_Kbps), [rfReplaceAll, rfIgnoreCase]); 

  If (Pos(LowerCase(datasetIndex2Str(pos_US_FEC_fast)), sRequestParam)>0) Then
   sContentText:=StringReplace(sContentText, '/*{{ chart.dataset.US_FEC_fast }}*/', DSL_Statistics_GenerateDataSet(pos_US_FEC_fast), [rfReplaceAll, rfIgnoreCase]); 
   
  If (Pos(LowerCase(datasetIndex2Str(pos_DS_FEC_fast)), sRequestParam)>0) Then
   sContentText:=StringReplace(sContentText, '/*{{ chart.dataset.DS_FEC_fast }}*/', DSL_Statistics_GenerateDataSet(pos_DS_FEC_fast), [rfReplaceAll, rfIgnoreCase]); 
   
  If (Pos(LowerCase(datasetIndex2Str(pos_US_CRC_fast)), sRequestParam)>0) Then
   sContentText:=StringReplace(sContentText, '/*{{ chart.dataset.US_CRC_fast }}*/', DSL_Statistics_GenerateDataSet(pos_US_CRC_fast), [rfReplaceAll, rfIgnoreCase]); 
   
  If (Pos(LowerCase(datasetIndex2Str(pos_DS_CRC_fast)), sRequestParam)>0) Then
   sContentText:=StringReplace(sContentText, '/*{{ chart.dataset.DS_CRC_fast }}*/', DSL_Statistics_GenerateDataSet(pos_DS_CRC_fast), [rfReplaceAll, rfIgnoreCase]); 
   
  If (Pos(LowerCase(datasetIndex2Str(pos_US_HEC_fast)), sRequestParam)>0) Then
   sContentText:=StringReplace(sContentText, '/*{{ chart.dataset.US_HEC_fast }}*/', DSL_Statistics_GenerateDataSet(pos_US_HEC_fast), [rfReplaceAll, rfIgnoreCase]); 
   
  If (Pos(LowerCase(datasetIndex2Str(pos_DS_HEC_fast)), sRequestParam)>0) Then
   sContentText:=StringReplace(sContentText, '/*{{ chart.dataset.DS_HEC_fast }}*/', DSL_Statistics_GenerateDataSet(pos_DS_HEC_fast), [rfReplaceAll, rfIgnoreCase]); 
   
  If (Pos(LowerCase(datasetIndex2Str(pos_US_FEC_interleaved)), sRequestParam)>0) Then
   sContentText:=StringReplace(sContentText, '/*{{ chart.dataset.US_FEC_interleaved }}*/', DSL_Statistics_GenerateDataSet(pos_US_FEC_interleaved), [rfReplaceAll, rfIgnoreCase]); 
   
  If (Pos(LowerCase(datasetIndex2Str(pos_DS_FEC_interleaved)), sRequestParam)>0) Then
   sContentText:=StringReplace(sContentText, '/*{{ chart.dataset.DS_FEC_interleaved }}*/', DSL_Statistics_GenerateDataSet(pos_DS_FEC_interleaved), [rfReplaceAll, rfIgnoreCase]); 

  If (Pos(LowerCase(datasetIndex2Str(pos_US_CRC_interleaved)), sRequestParam)>0) Then
   sContentText:=StringReplace(sContentText, '/*{{ chart.dataset.US_CRC_interleaved }}*/', DSL_Statistics_GenerateDataSet(pos_US_CRC_interleaved), [rfReplaceAll, rfIgnoreCase]); 

  If (Pos(LowerCase(datasetIndex2Str(pos_DS_CRC_interleaved)), sRequestParam)>0) Then
   sContentText:=StringReplace(sContentText, '/*{{ chart.dataset.DS_CRC_interleaved }}*/', DSL_Statistics_GenerateDataSet(pos_DS_CRC_interleaved), [rfReplaceAll, rfIgnoreCase]); 
  
  If (Pos(LowerCase(datasetIndex2Str(pos_US_HEC_interleaved)), sRequestParam)>0) Then
   sContentText:=StringReplace(sContentText, '/*{{ chart.dataset.US_HEC_interleaved }}*/', DSL_Statistics_GenerateDataSet(pos_US_HEC_interleaved), [rfReplaceAll, rfIgnoreCase]); 
  
  If (Pos(LowerCase(datasetIndex2Str(pos_DS_HEC_interleaved)), sRequestParam)>0) Then
   sContentText:=StringReplace(sContentText, '/*{{ chart.dataset.DS_HEC_interleaved }}*/', DSL_Statistics_GenerateDataSet(pos_DS_HEC_interleaved), [rfReplaceAll, rfIgnoreCase]); 
  
  If (Pos(LowerCase(datasetIndex2Str(pos_US_line_capacity)), sRequestParam)>0) Then // %
   sContentText:=StringReplace(sContentText, '/*{{ chart.dataset.US_line_capacity }}*/', DSL_Statistics_GenerateDataSet(pos_US_line_capacity), [rfReplaceAll, rfIgnoreCase]); 
   
  If (Pos(LowerCase(datasetIndex2Str(pos_DS_line_capacity)), sRequestParam)>0) Then // %
   sContentText:=StringReplace(sContentText, '/*{{ chart.dataset.DS_line_capacity }}*/', DSL_Statistics_GenerateDataSet(pos_DS_line_capacity), [rfReplaceAll, rfIgnoreCase]); 
   
  If (Pos(LowerCase(datasetIndex2Str(pos_US_noise_margin_dB)), sRequestParam)>0) Then
   sContentText:=StringReplace(sContentText, '/*{{ chart.dataset.US_noise_margin_dB }}*/', DSL_Statistics_GenerateDataSet(pos_US_noise_margin_dB), [rfReplaceAll, rfIgnoreCase]); 
  
  If (Pos(LowerCase(datasetIndex2Str(pos_DS_noise_margin_dB)), sRequestParam)>0) Then
   sContentText:=StringReplace(sContentText, '/*{{ chart.dataset.DS_noise_margin_dB }}*/', DSL_Statistics_GenerateDataSet(pos_DS_noise_margin_dB), [rfReplaceAll, rfIgnoreCase]); 
  
  If (Pos(LowerCase(datasetIndex2Str(pos_US_output_power_dBm)), sRequestParam)>0) Then
   sContentText:=StringReplace(sContentText, '/*{{ chart.dataset.US_output_power_dBm }}*/', DSL_Statistics_GenerateDataSet(pos_US_output_power_dBm), [rfReplaceAll, rfIgnoreCase]); 
  
  If (Pos(LowerCase(datasetIndex2Str(pos_DS_output_power_dBm)), sRequestParam)>0) Then
   sContentText:=StringReplace(sContentText, '/*{{ chart.dataset.DS_output_power_dBm }}*/', DSL_Statistics_GenerateDataSet(pos_DS_output_power_dBm), [rfReplaceAll, rfIgnoreCase]); 
   
  If (Pos(LowerCase(datasetIndex2Str(pos_US_attenuation_dB)), sRequestParam)>0) Then
   sContentText:=StringReplace(sContentText, '/*{{ chart.dataset.US_attenuation_dB }}*/', DSL_Statistics_GenerateDataSet(pos_US_attenuation_dB), [rfReplaceAll, rfIgnoreCase]); 

  If (Pos(LowerCase(datasetIndex2Str(pos_DS_attenuation_dB)), sRequestParam)>0) Then
   sContentText:=StringReplace(sContentText, '/*{{ chart.dataset.DS_attenuation_dB }}*/', DSL_Statistics_GenerateDataSet(pos_DS_attenuation_dB), [rfReplaceAll, rfIgnoreCase]); 
  
  If (Pos(LowerCase(datasetIndex2Str(pos_US_errored_seconds_ES)), sRequestParam)>0) Then
   sContentText:=StringReplace(sContentText, '/*{{ chart.dataset.US_errored_seconds_ES }}*/', DSL_Statistics_GenerateDataSet(pos_US_errored_seconds_ES), [rfReplaceAll, rfIgnoreCase]); 
   
  If (Pos(LowerCase(datasetIndex2Str(pos_DS_errored_seconds_ES)), sRequestParam)>0) Then
  sContentText:=StringReplace(sContentText, '/*{{ chart.dataset.DS_errored_seconds_ES }}*/', DSL_Statistics_GenerateDataSet(pos_DS_errored_seconds_ES), [rfReplaceAll, rfIgnoreCase]); 

  If (Pos(LowerCase(datasetIndex2Str(pos_US_severly_errored_seconds_SES)), sRequestParam)>0) Then
  sContentText:=StringReplace(sContentText, '/*{{ chart.dataset.US_severly_errored_seconds_SES }}*/', DSL_Statistics_GenerateDataSet(pos_US_severly_errored_seconds_SES), [rfReplaceAll, rfIgnoreCase]); 

  If (Pos(LowerCase(datasetIndex2Str(pos_DS_severly_errored_seconds_SES)), sRequestParam)>0) Then
  sContentText:=StringReplace(sContentText, '/*{{ chart.dataset.DS_severly_errored_seconds_SES }}*/', DSL_Statistics_GenerateDataSet(pos_DS_severly_errored_seconds_SES), [rfReplaceAll, rfIgnoreCase]); 

  If (Pos(LowerCase(datasetIndex2Str(pos_US_unavailable_seconds_UAS)), sRequestParam)>0) Then
  sContentText:=StringReplace(sContentText, '/*{{ chart.dataset.US_unavailable_seconds_UAS }}*/', DSL_Statistics_GenerateDataSet(pos_US_unavailable_seconds_UAS), [rfReplaceAll, rfIgnoreCase]); 

  If (Pos(LowerCase(datasetIndex2Str(pos_DS_unavailable_seconds_UAS)), sRequestParam)>0) Then
  sContentText:=StringReplace(sContentText, '/*{{ chart.dataset.pos_DS_unavailable_seconds_UAS }}*/', DSL_Statistics_GenerateDataSet(pos_DS_unavailable_seconds_UAS), [rfReplaceAll, rfIgnoreCase]); 

  If (Pos(LowerCase(datasetIndex2Str(pos_TX_ethernet_packets)), sRequestParam)>0) Then
  sContentText:=StringReplace(sContentText, '/*{{ chart.dataset.pos_TX_ethernet_packets }}*/', DSL_Statistics_GenerateDataSet(pos_TX_ethernet_packets), [rfReplaceAll, rfIgnoreCase]); 

  If (Pos(LowerCase(datasetIndex2Str(pos_RX_ethernet_packets)), sRequestParam)>0) Then
   sContentText:=StringReplace(sContentText, '/*{{ chart.dataset.pos_RX_ethernet_packets }}*/', DSL_Statistics_GenerateDataSet(pos_RX_ethernet_packets), [rfReplaceAll, rfIgnoreCase]); 
   
  AResponseInfo.ContentType:='text/html';
  AResponseInfo.ResponseNo:=200;
 End;

 if (sRequestDocument=LowerCase('/chart.js')) then
 Begin
  sContentText:=Resource2Stream('chart_js');
  AResponseInfo.ContentType:='application/javascript';
  AResponseInfo.ResponseNo:=200;
 End;

 if (sRequestDocument=LowerCase('/favicon.ico')) then
 Begin
  sContentText:=Resource2Stream('favicon_ico');
  AResponseInfo.ContentType:='image/x-icon';
  AResponseInfo.ResponseNo:=200;
 End; 
                                        
 AResponseInfo.CacheControl:='no-cache';
 AResponseInfo.CustomHeaders.Add('Access-Control-Allow-Origin: *');
 AResponseInfo.ContentText:=sContentText;
 AResponseInfo.WriteContent;

 AContext.Connection.Disconnect;             
 // -----------------------------
 Memo_RequestLog.Lines.Add('> '+ARequestInfo.Command+' '+sRequestDocument+' '+sRequestParam+' '+AResponseInfo.ResponseNo.ToString);
end;

procedure TMain.ListBox_GraphFieldsChangeCheck(Sender: TObject);
Var
 NavigateURL,
 reqDiagrams:String;
 I:Integer;
 
begin              
 Memo_RequestLog.Lines.Clear;
 // -------------------------
 reqDiagrams:='';
 for I:=0 To ListBox_GraphFields.Items.Count-1 Do
 Begin
  if (ListBox_GraphFields.ListItems[I].IsChecked=True) then
  Begin
   reqDiagrams:=reqDiagrams+LowerCase(ListBox_GraphFields.Items[I])+'+';
  End;
 End;
 NavigateURL:=WebServerRequestAddress+'?'+WebServerRequestDiagramPrmKey+reqDiagrams+LowerCase(ListBox_GraphFields.Items[ListBox_GraphFields.ItemIndex]); 
 Try WebBrowser.Navigate(NavigateURL); Except End;
end;

procedure TMain.ListBox_GraphFieldsItemClick(const Sender: TCustomListBox; const Item: TListBoxItem);
begin
 ListBox_GraphFieldsChangeCheck(Sender);
end;

Procedure TMain.FormCreate(Sender: TObject);
var
 SHandle:TIdSocketHandle;

begin
 Application.Title:=Self.Caption;
 dataStatisticsCSV:=TStringList.Create;
 WebServerBindPort:=GenerateRandomNumber(20000, 60000);
 WebServerRequestAddress:='http://'+WebServerBindIP+':'+WebServerBindPort.ToString+'/';

 DSL_StatisticsFile_LoadFile(ExtractFilePath(ParamStr(0))+'ndm_dsl-statistics.csv');
 
 // -------------------------
 IdHTTPServer.Bindings.Clear;
 SHandle:=IdHTTPServer.Bindings.Add;
 SHandle.IP:=WebServerBindIP;
 SHandle.Port:=WebServerBindPort;
 IdHTTPServer.Active:=True;

 Memo_RequestLog.Visible:=False;
 
 // ------------------------
 ListBox_GraphFields.Items.Clear;
 ListBox_GraphFields.Items.Add(datasetIndex2Str(pos_LineState));
 ListBox_GraphFields.Items.Add(datasetIndex2Str(pos_LastDropReason));
 ListBox_GraphFields.Items.Add(datasetIndex2Str(pos_US_bitrate_Kbps));
 ListBox_GraphFields.Items.Add(datasetIndex2Str(pos_DS_bitrate_Kbps));
 ListBox_GraphFields.Items.Add(datasetIndex2Str(pos_US_FEC_fast));
 ListBox_GraphFields.Items.Add(datasetIndex2Str(pos_DS_FEC_fast));
 ListBox_GraphFields.Items.Add(datasetIndex2Str(pos_US_CRC_fast));
 ListBox_GraphFields.Items.Add(datasetIndex2Str(pos_DS_CRC_fast));
 ListBox_GraphFields.Items.Add(datasetIndex2Str(pos_US_HEC_fast));
 ListBox_GraphFields.Items.Add(datasetIndex2Str(pos_DS_HEC_fast));
 ListBox_GraphFields.Items.Add(datasetIndex2Str(pos_US_FEC_interleaved));
 ListBox_GraphFields.Items.Add(datasetIndex2Str(pos_DS_FEC_interleaved));
 ListBox_GraphFields.Items.Add(datasetIndex2Str(pos_US_CRC_interleaved));
 ListBox_GraphFields.Items.Add(datasetIndex2Str(pos_DS_CRC_interleaved));
 ListBox_GraphFields.Items.Add(datasetIndex2Str(pos_US_HEC_interleaved));
 ListBox_GraphFields.Items.Add(datasetIndex2Str(pos_DS_HEC_interleaved));
 ListBox_GraphFields.Items.Add(datasetIndex2Str(pos_US_line_capacity));
 ListBox_GraphFields.Items.Add(datasetIndex2Str(pos_DS_line_capacity));
 ListBox_GraphFields.Items.Add(datasetIndex2Str(pos_US_noise_margin_dB));
 ListBox_GraphFields.Items.Add(datasetIndex2Str(pos_DS_noise_margin_dB));
 ListBox_GraphFields.Items.Add(datasetIndex2Str(pos_US_output_power_dBm));
 ListBox_GraphFields.Items.Add(datasetIndex2Str(pos_DS_output_power_dBm));
 ListBox_GraphFields.Items.Add(datasetIndex2Str(pos_US_attenuation_dB));
 ListBox_GraphFields.Items.Add(datasetIndex2Str(pos_DS_attenuation_dB));
 ListBox_GraphFields.Items.Add(datasetIndex2Str(pos_US_errored_seconds_ES));
 ListBox_GraphFields.Items.Add(datasetIndex2Str(pos_DS_errored_seconds_ES));
 ListBox_GraphFields.Items.Add(datasetIndex2Str(pos_US_severly_errored_seconds_SES));
 ListBox_GraphFields.Items.Add(datasetIndex2Str(pos_DS_severly_errored_seconds_SES));
 ListBox_GraphFields.Items.Add(datasetIndex2Str(pos_US_unavailable_seconds_UAS));
 ListBox_GraphFields.Items.Add(datasetIndex2Str(pos_DS_unavailable_seconds_UAS));
 ListBox_GraphFields.Items.Add(datasetIndex2Str(pos_TX_ethernet_packets));
 ListBox_GraphFields.Items.Add(datasetIndex2Str(pos_RX_ethernet_packets));

 // ------------------------
 TimerStartup.Enabled:=True;
end;                                            

procedure TMain.FormDestroy(Sender: TObject);
begin
 dataStatisticsCSV.Free;
end;

Procedure TMain.WebBrowser_EdgeDestegiYukluDegil;
Var
 EdgeInstallURL:String;
 
Begin
 Self.Hide;
 EdgeInstallURL:='https://developer.microsoft.com/en-us/microsoft-edge/webview2/';
 ShowMessage(EdgeInstallURL+#13+#13+'Edge Browser Desteği Mevcut Değil, Uygulamanın Düzgün Çalışabilmesi İçin Yukarıdaki Web Adresinden Sayfanın En Altında Evergreen Standalone Installer Alanındaki x86 Sürümünü Yükleyin, Pencere Kapatıldığında Otomatik Web Sayfası Açılacakdır.');  
 ShellExecute(0, 'open', PChar(EdgeInstallURL), nil, nil, 0);  
 Halt; 
End;

procedure TMain.TimerStartupTimer(Sender: TObject);
begin
 TimerStartup.Enabled:=False;
 // --------------------------
 if Not IsEdgeAvailable then Begin WebBrowser_EdgeDestegiYukluDegil; End;
 Try
  WebBrowser.WindowsEngine:=TWindowsEngine.EdgeOnly; // Burada initilizate de hata oluşuyor.
 Except
  WebBrowser_EdgeDestegiYukluDegil;
 End;
 WebBrowser.Navigate(WebServerRequestAddress+'?'+WebServerRequestDiagramPrmKey+LowerCase(datasetIndex2Str(pos_Date)));
end;

end.
