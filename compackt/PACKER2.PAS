program packeri;

uses
  crt,miscrout;

type
  da_buf        = array[0..64000] of byte;

const
  {initialization for unpacking code}
  initunpack    : array[0..27] of byte = (
  14,14,31,7,190,28,1,191,16,224,185,68,3,144,252,
  243,164,191,0,240,185,30,0,243,164,233,228,238);

  {unpacking code}
  dounpack      : array[0..29] of byte = (
  190,16,224,191,0,1,172,60,36,117,9,172,138,200,
  172,243,170,235,2,144,170,129,254,0,240,114,235,
  233,226,16);

var
  inf, outf     : file;
  origbuf, pack : ^da_buf;
  i,j,o,k,l     : word;
  desti         : word;
  origsize      : word;

  mark          : byte;
  temmi         : string;

procedure errorexit(error : string);
begin
  writeln(error);
  halt(1);
end;

begin
  clrscr;
  mark := $24;
  textattr := lightcyan;
  writeln('cOm PaCKt v0.1á by L”k” / Napalm');
  textattr := lightgray;
  writeln;
  if paramcount<2 then errorexit('USAGE: COMPACK source destination [marker]');
  if not mr_fileexists(paramstr(1)) then errorexit('source file not found');

  {does the user want to specify marker value?}
  if paramcount>2 then begin
    temmi := paramstr(3);
    val(temmi,mark,i);
    if i<>0 then errorexit('invalid marker value');
  end;

  new(origbuf);
  new(pack);

  {load original data}
  assign(inf,paramstr(1));
  reset(inf,1);
  origsize := filesize(inf);
  blockread(inf,origbuf^,origsize);
  close(inf);

  {pack it}
  desti := 28;
  i := 0;
  repeat
    {onko enemm„n kuin kaksi samaa tavua per„kk„in ?}
    if (origbuf^[i]=origbuf^[i+1]) and (origbuf^[i] = origbuf^[i+2]) then begin
      pack^[desti] := mark;        {mark beginning of packed block}
      inc(desti);
      j := i;
      o := 0;                      {find the length of a block}
      repeat
        inc(o);
        inc(j);
      until (origbuf^[j]<>origbuf^[i]) or (o=255);
      pack^[desti] := o;            {write the count}
      inc(desti);
      pack^[desti] := origbuf^[i];  {write the value}
      inc(desti);
      inc(i,o);
    end
    {onko yksin„inen "merkint„" tavu ?}
    else if origbuf^[i]=mark then begin
      pack^[desti] := mark;
      pack^[desti+1] := 1;
      pack^[desti+2] := mark;
      inc(desti,3);
      inc(i);
    end
    {onko kaksi merkint„ tavua per„kk„in ?}
    else if (origbuf^[i]=mark) and (origbuf^[i+1]=mark) then begin
      pack^[desti] := mark; {merkint„ : packed block}
      pack^[desti+2] := 2; {packed block length}
      pack^[desti+1] := mark; {packed block value}
      inc(desti,3);
      inc(i,2);
    end
    else begin
      pack^[desti] := origbuf^[i];
      inc(desti);
      inc(i);
    end;
  until i>=origsize;

  {was the packing worth it ?}
  if (desti)>(origsize-30) then errorexit('impossible to pack enough...');
  {was the result too big ?}
  if (origsize+30)>4000 then errorexit('too big file..');

  {fix the initialization code}
  move(initunpack,pack^[0],sizeof(initunpack));
  {replace the "length" with right value}
  pack^[11] := lo(desti-28);
  pack^[12] := hi(desti-28);
  {and now, the unpacking code}
  move(dounpack,pack^[desti],sizeof(dounpack));
  {replace the "marker" with the right value}
  pack^[desti+8] := mark;

  {write the new file}
  assign(outf,paramstr(2));
  rewrite(outf,1);
  blockwrite(outf,pack^,desti+30);
  close(outf);

  dispose(origbuf);
  dispose(pack);
end.