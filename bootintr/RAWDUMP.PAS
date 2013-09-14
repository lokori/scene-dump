program rawdumppi;

var
  b : array[0..6400] of byte;
  f : file of byte;
  f2 : text;
  s : string;
  i,j : integer;

begin
  assign(f,'fdb.com');
  reset(f);
  for i := 0 to filesize(f)-1 do
    read(f,b[i]);
  close(f);
  assign(f2,'fdboot.666');
  rewrite(f2);
  for i := 0 to 511 do begin
    str(b[i],s);
    write(f2,s);
    writeln(f2,',');
  end;
  close(f2);
end.