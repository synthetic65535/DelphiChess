unit main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls, Menus, StdCtrls, Gauges, ExtCtrls;

type
  TMainForm = class(TForm)
    MainMenu: TMainMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    Image: TImage;
    Gauge: TGauge;
    N4: TMenuItem;
    N5: TMenuItem;
    N6: TMenuItem;
    N7: TMenuItem;
    N8: TMenuItem;
    N9: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure ImageMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ImageMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ImageMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure N2Click(Sender: TObject);
    procedure N3Click(Sender: TObject);
    procedure N5Click(Sender: TObject);
    procedure N6Click(Sender: TObject);
    procedure N7Click(Sender: TObject);
    procedure N8Click(Sender: TObject);
    procedure N9Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

{=========================}

const
{фигуры}
pusto=0; peshka=1; kon=2; slon=3; ladya=4; ferz=5; korol=6;
{белые фигуры}
wpeshka = 11; wkon=12; wslon=13; wladya=14; wferz=15; wkorol=16;
whites = [11..16];
{черные фигуры}
bpeshka = 21; bkon=22; bslon=23; bladya=24; bferz=25; bkorol=26;
blacks = [21..26];

maxmoves = 256; {максимальное количество ходов в списке}

{==========================}


type
tpos = record x,y:byte; end; {позиция}
thod = record a,b:tpos; end; {ход}
tfield = array[1..8,1..8] of byte; {доска}
{}
tplayerstate = record {состояние игрока}
king:tpos; {позиция короля на доске, чтобы каждый раз не искать его}
leftmoved,rightmoved,kingmoved,shah:boolean;
{двигалась ли левая ладья/правая ладья/король}
end;
{}
thodlist = record {список ходов}
h : array[1..maxmoves] of thod; {массив ходов}
c : byte; {размер массива}
end;
{}
tsit = record {ситуация}
field:tfield; {доска}
lastmove : thod; {предыдуший ход}
whitesmove:boolean; {просчитывается ли ход для белых}
white,black:tplayerstate; {состояния игроков}
moves: array[1..256] of thod; {пройденные ходы}
moves_count:byte; {количество ходов}
end;

{========================}

const startfield : tfield = ( {доска в начале игры}
(bladya,bpeshka,0,0,0,0,wpeshka,wladya),
(bkon,  bpeshka,0,0,0,0,wpeshka,wkon),
(bslon, bpeshka,0,0,0,0,wpeshka,wslon),
(bferz, bpeshka,0,0,0,0,wpeshka,wferz),
(bkorol,bpeshka,0,0,0,0,wpeshka,wkorol),
(bslon, bpeshka,0,0,0,0,wpeshka,wslon),
(bkon,  bpeshka,0,0,0,0,wpeshka,wkon),
(bladya,bpeshka,0,0,0,0,wpeshka,wladya));

{===========================}

var
  MainForm: TMainForm;
  {загруженные картинки, и картинки подогнанные под размер окна}
  original_bmp,resized_bmp: array[1..2,peshka..korol] of tbitmap;
  mainsit : tsit; {главная игровая ситуация}
  can_move:boolean; {двигаем ли фигуру}
  moving_figure:byte; {номер двигаемой фигуры}
  face_field:tfield; {поле, из которого мы выковыриваем двигаемую фигуру и рисуем его}
  hod_chela:thod; {какой ход сделал человек}
  game_ended:boolean; {закончилась ли игра}
  bmp:tbitmap; {картинка доски}
  calculation:boolean; {думает ли сейчас компьютер}
  tmplist:thodlist; {временная переменная}
  glubina : byte; {на сколько полуходов просчитывать}


implementation

{$R *.DFM}


{===========================================================================}

{записывает ситуацию в начале игры}
procedure make_start_sit(var sit:tsit);
begin
{}
sit.field := startfield;
{}
sit.black.kingmoved := false;
sit.white.kingmoved := false;
sit.black.king.x := 5;
sit.black.king.y := 1;
sit.white.king.x := 5;
sit.white.king.y := 8;
sit.black.leftmoved := false;
sit.black.rightmoved := false;
sit.white.leftmoved := false;
sit.white.rightmoved := false;
sit.whitesmove := true;
sit.lastmove.a.x := 0;
sit.lastmove.b.x := 0;
sit.lastmove.a.y := 0;
sit.lastmove.b.y := 0;
sit.white.shah := false;
sit.black.shah := false;
sit.moves_count := 0;
{}
face_field := mainsit.field;
game_ended := false;
{}
end;


{===========================================================================}

{изменяет размер картинки, дорисовывая промежуточные пиксели}
procedure ResizeBitmap(imgo, imgd: TBitmap; nw, nh: Integer);
{--------------------------}
type
TRGB = record
b, g, r: byte;
end;
ARGB = array[0..1] of TRGB;
PARGB = ^ARGB;
{--------------------------}
var
xini, xfi, yini, yfi, saltx, salty: single;
x, y, px, py, tpix: integer;
PixelColor: TColor;
r, g, b: longint;
p: PARGB;
{--------------------------}

function MyRound(const X: Double): Integer;
begin
{}
Result := Trunc(x);
if Frac(x) >= 0.5 then
   if x >= 0 then Result := Result + 1
      else Result := Result - 1;
{}
end;
{--------------------------}

var t:byte;

begin
{}
imgo.PixelFormat := pf24bit;
{}
// Set target size 
imgd.Width  := nw;
imgd.Height := nh;
// Calcs width & height of every area of pixels of the source bitmap
saltx := imgo.Width / nw;
salty := imgo.Height / nh;
{}
yfi := 0;
for y := 0 to nh - 1 do
   begin
   // Set the initial and final Y coordinate of a pixel area 
   {}
   yini := yfi;
   yfi  := yini + salty;
   if yfi >= imgo.Height then yfi := imgo.Height - 1;
   {}
   xfi := 0;
   for x := 0 to nw - 1 do
      begin
      // Set the inital and final X coordinate of a pixel area 
      {}
      xini := xfi;
      xfi  := xini + saltx;
      if xfi >= imgo.Width then xfi := imgo.Width - 1;
      {}
      // This loop calcs del average result color of a pixel area
      // of the imaginary grid
      {}
      r := 0;
      g := 0;
      b := 0;
      tpix := 0;
      {}
      if MyRound(yfi) >= imgo.height then t:=1 else t:=0;{?!?!?!?!?}
      {}
      for py := MyRound(yini) to MyRound(yfi)-t do
         begin
         {}
         p := imgo.scanline[py];
         {}
         for px := MyRound(xini) to MyRound(xfi) do
            begin
            {}
            Inc(tpix);
            {}
            PixelColor := rgb(p[px].r,p[px].g,p[px].b);
            {}
            r := r + GetRValue(PixelColor);
            g := g + GetGValue(PixelColor);
            b := b + GetBValue(PixelColor);
            {}
            end;
         end;
      {}
      // Draws the result pixel
      {}
      if tpix<>0 then
      imgd.Canvas.Pixels[x, y] :=
      rgb(MyRound(r / tpix),
      MyRound(g / tpix),
      MyRound(b / tpix));
      {}
      end;
   {}
   end;
{}
end;

{===========================================================================}

{разрезает загруженную картинку на отдельные фигуры}
procedure make_bitmaps(fn:string);

var
x,y:byte;
source_bmp:tbitmap;
cw,ch:word;

begin
{читаем файл}
source_bmp := tbitmap.create;
source_bmp.LoadFromFile(fn);
{получаеи размер каждой картинки}
cw := source_bmp.width div 6;
ch := source_bmp.height div 2;
{устанавливаем размеры картинок}
for y:=1 to 2 do
for x:=peshka to korol do
   begin
   original_bmp[y,x].Width := cw-1;
   original_bmp[y,x].height := ch-1;
   end;
{разрезаем картинку}
for x:=peshka to korol do
   begin
   {}
   for y:=1 to 2 do
      begin
      {}
      original_bmp[y,x].canvas.copyrect(rect(0,0,cw-1,ch-1),source_bmp.canvas,
      rect((x-1)*cw,(y-1)*ch,x*cw,y*ch));
      {}
      end;
   {}
   end;
{}
end;

{===========================================================================}

{подгоняет размер всех картинок}
procedure resize_bitmaps(new_w,new_h:word);
var x,y:byte;
begin
{}
for y:=1 to 2 do
   for x:=peshka to korol do
      ResizeBitmap(original_bmp[y,x],resized_bmp[y,x],new_w,new_h);
{}
end;

{===========================================================================}

{рисует доску}
procedure paint_field(const field: tfield);

var st,sw:word;
x,y:byte;
white_cell,painted:boolean;

begin
{}
if (MainForm.ClientHeight - MainForm.Gauge.height) <= MainForm.ClientWidth then
st := (MainForm.ClientHeight - MainForm.Gauge.height) div 8 else
st := MainForm.ClientWidth div 8;
{}
if resized_bmp[1,1].width <> st then resize_bitmaps(st,st);
{}
sw := st*8 + 1;
bmp.width := sw;
bmp.height := sw;
{clear}
bmp.canvas.Brush.color := clwhite;
bmp.canvas.FillRect(rect(0,0,sw,sw));
{}
{рисуем доску}
{}
bmp.Canvas.pen.color := clsilver;
white_cell := true;
painted := false;
{}
for y:=1 to 8 do
   begin
   {}
   for x:=1 to 8 do
      begin
      {рисуем клетку, белую или черную}
      bmp.Canvas.brush.style := bssolid;
      if white_cell then
      bmp.Canvas.brush.color := clwhite else
      bmp.Canvas.brush.color := clsilver ;
      {}
      bmp.Canvas.Rectangle((x-1)*st,(y-1)*st,x*st+1,y*st+1);
      {}
      {штрихуем последний ход, поверх клетки}
      if (mainsit.lastmove.a.x = x) and (mainsit.lastmove.a.y = y) or
         (mainsit.lastmove.b.x = x) and (mainsit.lastmove.b.y = y) then
            begin
            bmp.Canvas.brush.style := bsdiagcross;
            bmp.Canvas.brush.color := $8080ff;
            bmp.Canvas.Rectangle((x-1)*st,(y-1)*st,x*st+1,y*st+1);
            end;
      {поверх всего этого добра рисуем фигуру которая на этой клетке стоит}
      if field[x,y] <> pusto then
      bmp.Canvas.draw((x-1)*st,(y-1)*st,
      resized_bmp[field[x,y] div 10,field[x,y] mod 10]);
      {изменяем цвет клетки}
      white_cell := not white_cell;
      {}
      end;
   {}
   white_cell := not white_cell;
   {}
   end;
{отображаем что нарисовали}
MainForm.image.Picture.bitmap.width := bmp.width;
MainForm.image.Picture.bitmap.height := bmp.height;
MainForm.image.Picture.bitmap.Canvas.CopyRect(rect(0,0,sw,sw),bmp.canvas,rect(0,0,sw,sw));
{}
end;

{===========================================================================}
{###########################################################################}

{правильность хода без учета шахов}
function is_legal_move(const sit:tsit; const hod:thod): boolean;

{----------------------------}

{свободна ли линия хода}
function linefree(const x1,y1,x2,y2:byte):boolean;
var x,y:byte; dx,dy:shortint;
begin
{}
dx := 0;
dy := 0;
{}
{устанавливаем дельта в зависимости от направления движения}
if x1 = x2 then dx := 0;
if y1 = y2 then dy := 0;
if x1 > x2 then dx := -1;
if x1 < x2 then dx := 1;
if y1 > y2 then dy := -1;
if y1 < y2 then dy := 1;
{устанавливаем начальную позицию и линия предположительно свободна}
x := x1;
y := y1;
linefree := true;
{до тех пор пока не дойдем до конечной позиции}
while not((x=x2) and (y=y2)) do
   begin
   {изменяем координаты проверяемой клетки}
   x := x + dx;
   y := y + dy;
   {если в этой клетке кто-то есть и он не на конечной позиции}
   if (sit.field[x,y] <> pusto) and not((x=x2) and (y=y2)) then
      begin
      linefree := false; {то линия занята}
      exit;
      end;
   {}
   end;
{}
end;

{----------------------------}

{не под атакой ли линия рокировки}
function linesafe(const x1,y1,x2,y2:byte; whiteattacker:boolean):boolean;
var x,y,a,b:byte; dx,dy:shortint;
tmphod:thod;
begin
{}
dx := 0;
dy := 0;
{}
{устанавливаем дельта в зависимости от направления движения}
if x1 = x2 then dx := 0;
if y1 = y2 then dy := 0;
if x1 > x2 then dx := -1;
if x1 < x2 then dx := 1;
if y1 > y2 then dy := -1;
if y1 < y2 then dy := 1;
{устанавливаем начальную позицию и линия предположительно свободна}
x := x1;
y := y1;
linesafe := true;
{до тех пор пока не дойдем до конечной позиции}
while not((x=x2) and (y=y2)) do
   begin
   {изменяем координаты проверяемой клетки}
   x := x + dx;
   y := y + dy;
   {перебираем все клетки в поисках атакующего}
   for a:=1 to 8 do
      for b:=1 to 8 do
         {если цвет атакующего совпал с цветом найденной фигуры}
         if (whiteattacker = (sit.field[a,b] in whites)) and
         {и фигура вообще существует и она - не король}
         not ((sit.field[a,b] mod 10) in [korol,pusto]) then
            begin
            {создаем временный ход}
            tmphod.a.x := a;
            tmphod.a.y := b;
            tmphod.b.x := x;
            tmphod.b.y := y;
            {проверяем возможен ли он}
            if is_legal_move(sit,tmphod) then
               begin
               linesafe := false;
               exit;
               end;
            {}
            end;
   {}
   end;
{}
end;

{--------------------------------------}

begin
{}
is_legal_move := false;
{}
if (sit.field[hod.a.x,hod.a.y] = pusto) or {источник хода - пустая клетка}
   (hod.a.x = hod.b.x) and (hod.a.y = hod.b.y) then {или ход нулевой}
   begin
   is_legal_move := false;
   exit;
   end;
{}
if ((sit.field[hod.a.x,hod.a.y] in whites) = {цвет источника и цели совпадает}
   (sit.field[hod.b.x,hod.b.y] in whites)) and
   (sit.field[hod.b.x,hod.b.y] <> pusto) then
   begin
   is_legal_move := false;
   exit;
   end;
{}
case sit.field[hod.a.x,hod.a.y] mod 10 of
{}
peshka:
   is_legal_move := (
   {СЛУЧАЙ1 - БОЛЬШОЙ ПРЫЖОК ПЕШКИ}
   {если пешка белая и находится на 7 горизонтали или}
   (sit.field[hod.a.x,hod.a.y] in whites) and (hod.a.y = 7) or
   {пешка черная и находится на 2 горизонтали}
   (sit.field[hod.a.x,hod.a.y] in blacks) and (hod.a.y = 2) ) and
   {если пешка прыгает через 1 клетку на той же вертикали}
   (abs(hod.a.y - hod.b.y) = 2) and (hod.a.x = hod.b.x) and
   {и если перед ней пусто}
   (sit.field[hod.b.x,hod.b.y] = pusto) and
   (sit.field[hod.b.x,(hod.a.y + hod.b.y) div 2] = pusto) or
   {СЛУЧАЙ2 - ОБЫЧНЫЙ ХОД ПЕШКИ}
   {если та же вертикаль а по горизонталям перемещение на 1 клетку}
   (hod.a.x = hod.b.x) and ({}( hod.a.y - hod.b.y = 1) and {вперед}
   (sit.field[hod.a.x,hod.a.y] in whites) or {для белой пешки}
   ( hod.a.y - hod.b.y = -1) and {или назад}
   (sit.field[hod.a.x,hod.a.y] in blacks){}) and {для черной пешки}
   {и если перед ней пусто}
   (sit.field[hod.b.x,hod.b.y] = pusto) or
   {СЛУЧАЙ3 - АТАКА ПЕШКИ}
   {если пешка белая и перемещается по горизонтали на 1 клетку}
   (sit.field[hod.a.x,hod.a.y] in whites) and (abs(hod.a.x - hod.b.x)=1) and
   {и перемещается вверх на одну клетку}
   (hod.b.y = hod.a.y - 1) and
   {и там черная фигура}
   (sit.field[hod.b.x,hod.b.y] in blacks) or
   {если пешка черная и перемещается по горизонтали на 1 клетку}
   (sit.field[hod.a.x,hod.a.y] in blacks) and (abs(hod.a.x - hod.b.x)=1) and
   {и перемещается вниз на одну клетку}
   (hod.b.y = hod.a.y + 1) and
   {и там белая фигура}
   (sit.field[hod.b.x,hod.b.y] in whites) or
   {СЛУЧАЙ4 - АТАКА НА ВРАЖЕСКУЮ ПЕШКУ, ПЕРЕПРЫГНУВШУЮ БИТОЕ ПОЛЕ}
   {если пешка белая}
   (sit.field[hod.a.x,hod.a.y] in whites) and
   {переместилась по горизонтали на 1 клетку и по вертикали на 1 клетку вверх}
   (abs(hod.a.x-hod.b.x) = 1) and ((hod.a.y - hod.b.y)=1) and
   {и предыдущий ход делала вражеская пешка}
   (sit.field[sit.lastmove.b.x,sit.lastmove.b.y] = bpeshka) and
   {из клетки с соответствующей горизонталью и вертикулью}
   (sit.lastmove.a.x = hod.b.x) and (sit.lastmove.a.y = hod.b.y - 1) and
   {в клетку}
   (sit.lastmove.b.x = hod.b.x) and (sit.lastmove.b.y = hod.b.y + 1) or
   {если пешка черная}
   (sit.field[hod.a.x,hod.a.y] in blacks) and
   {переместилась по горизонтали на 1 клетку и по вертикали на 1 клетку вниз}
   (abs(hod.a.x-hod.b.x) = 1) and ((hod.a.y - hod.b.y)=-1) and
   {и предыдущий ход делала вражеская пешка}
   (sit.field[sit.lastmove.b.x,sit.lastmove.b.y] = wpeshka) and
   {из клетки с соответствующей горизонталью и вертикулью}
   (sit.lastmove.a.x = hod.b.x) and (sit.lastmove.a.y = hod.b.y + 1) and
   {в клетку}
   (sit.lastmove.b.x = hod.b.x) and (sit.lastmove.b.y = hod.b.y - 1);
{}
kon:
   is_legal_move :=
   {если начало и конец хода не совпадают ни горизонталью ни вертикалью}
   (hod.a.x <> hod.b.x) and (hod.a.y <> hod.b.y) and
   {и расстояние перемещения по горизонтали + вертикали = 3 клетки (буква Г)}
   ((abs(hod.a.x - hod.b.x) + abs(hod.a.y - hod.b.y)) = 3);
{}
slon:
   is_legal_move :=
   {если ходим по диагонали и путь чист}
   ( abs(hod.a.x - hod.b.x) = abs(hod.a.y - hod.b.y) ) and
   linefree(hod.a.x,hod.a.y,hod.b.x,hod.b.y);
{}
ladya:
   is_legal_move :=
   {если ходим по вертикали или горизонтали и путь чист}
   ( (hod.a.x = hod.b.x) or (hod.a.y = hod.b.y) ) and
   linefree(hod.a.x,hod.a.y,hod.b.x,hod.b.y);
{}
ferz:
   is_legal_move := (
   {слон +}
   ( abs(hod.a.x - hod.b.x) = abs(hod.a.y - hod.b.y) ) or
   {ладья + путь чист}
   (hod.a.x = hod.b.x) or (hod.a.y = hod.b.y) ) and
   linefree(hod.a.x,hod.a.y,hod.b.x,hod.b.y);
{}
korol:
   is_legal_move :=
   {СЛУЧАЙ1 - ОБЫЧНЫЙ ХОД}
   {только на 1 клетку по горизонтали}
   (abs(hod.a.x - hod.b.x) = 1) and (abs(hod.a.y - hod.b.y) = 0) or
   {только на 1 клетку по вертикали}
   (abs(hod.a.x - hod.b.x) = 0) and (abs(hod.a.y - hod.b.y) = 1) or
   {или одновременно и по горизонтали и по вертикали на 1 клетку}
   (abs(hod.a.x - hod.b.x) = 1) and (abs(hod.a.y - hod.b.y) = 1) or
   {СЛУЧАЙ2 - РОКИРОВКА}
   {белый король не двигался}
   (sit.field[hod.a.x,hod.a.y] in whites) and not sit.white.kingmoved and
   {и белому королю не шах}
   not sit.white.shah and
   {и при рокировке влево не двигалась левая ладья}
   ( (hod.a.x - hod.b.x = 2) and not sit.white.leftmoved and
   (sit.field[1,8] = wladya) and (hod.a.y = hod.b.y) and
   {и между королем и ладьей никого нет и линия не под ударом}
   linefree(5,8,1,8) and linesafe(5,8,1,8,false) or
   {или же при рокировке вправо не двигалась правая ладья}
   (hod.a.x - hod.b.x = -2) and not sit.white.rightmoved  and
   (sit.field[8,8] = wladya) and (hod.a.y = hod.b.y) and
   {и между королем и ладьей никого нет и линия не под ударом}
   linefree(5,8,8,8) ) and linesafe(5,8,8,8,false) or
   {аналогично рокировка для черного короля}
   (sit.field[hod.a.x,hod.a.y] in blacks) and not sit.black.kingmoved and
   not sit.black.shah and
   ( (hod.a.x - hod.b.x = 2) and not sit.black.leftmoved and
   (sit.field[1,1] = bladya) and (hod.a.y = hod.b.y) and
   linefree(5,1,1,1) and linesafe(5,1,1,1,true) or
     (hod.a.x - hod.b.x = -2) and not sit.black.rightmoved and
   (sit.field[8,1] = bladya) and (hod.a.y = hod.b.y) and
   linefree(5,1,8,1) and linesafe(5,1,8,1,true));
{}
end;{case}
{}
end;

{=================================}

{делает ход. процедура вызывается только при после проверки правильности хода}
procedure makemove(var sit:tsit; const hod:thod);
var a,b:byte;
tmphod:thod;
begin
{}
case sit.field[hod.a.x,hod.a.y] mod 10 of
{}
peshka:
   begin
   {если пешка поменяла вертикаль и ушла в пустоту то убиваем врага}
   if (hod.a.x <> hod.b.x) and (sit.field[hod.b.x,hod.b.y] = pusto) then
   sit.field[hod.b.x,hod.a.y] := pusto;
   {если пешка дошла до конца, превращаем ее в ферзя}
   if (hod.b.y = 1) or (hod.b.y = 8) then
      begin
      {белая пешка}
      if (sit.field[hod.a.x,hod.a.y] = wpeshka) then
      sit.field[hod.a.x,hod.a.y] := wferz;
      {черная пешка}
      if (sit.field[hod.a.x,hod.a.y] = bpeshka) then
      sit.field[hod.a.x,hod.a.y] := bferz;
      {}
      end;
      {}
   {}
   end;
{}
korol:
   begin
   {рокировка}
   if (abs(hod.a.x - hod.b.x) = 2) then {перепрыгнул клетку горизонтально}
      {для белого короля}
      if sit.whitesmove then
         begin
         if hod.a.x > hod.b.x then
            begin
            sit.white.leftmoved := true;
            sit.field[4,8] := wladya;
            sit.field[1,8] := pusto;
            end;
         if hod.a.x < hod.b.x then
            begin
            sit.white.rightmoved := true;
            sit.field[6,8] := wladya;
            sit.field[8,8] := pusto;
            end;
         end else
            begin {для черного короля}
            if hod.a.x > hod.b.x then
               begin
               sit.black.leftmoved := true;
               sit.field[4,1] := bladya;
               sit.field[1,1] := pusto;
               end;
            if hod.a.x < hod.b.x then
               begin
               sit.black.rightmoved := true;
               sit.field[6,1] := bladya;
               sit.field[8,1] := pusto;
               end;
            end; {if}
   {}
   {помечаем что король ходил}
   if sit.whitesmove then sit.white.kingmoved := true else
   sit.black.kingmoved := true;
   {изменяем его координаты}
   if sit.whitesmove then sit.white.king := hod.b else
   sit.black.king := hod.b;
   {}
   end;
{}
ladya:
   begin
   {помечаем какая ладья ходила}
   if (hod.a.x = 1) and (hod.a.y = 1) then sit.black.leftmoved := true;
   if (hod.a.x = 8) and (hod.a.y = 1) then sit.black.rightmoved := true;
   if (hod.a.x = 1) and (hod.a.y = 8) then sit.white.leftmoved := true;
   if (hod.a.x = 8) and (hod.a.y = 8) then sit.white.rightmoved := true;
   {}
   end;
{}
end;{case}
{делаем ход}
sit.field[hod.b.x,hod.b.y] := sit.field[hod.a.x,hod.a.y];
sit.field[hod.a.x,hod.a.y] := pusto;
{передаем ход оппоненту}
sit.whitesmove := not sit.whitesmove;
{}
{детектор шахов}
{предполагаем что шахов нет}
sit.black.shah := false;
sit.white.shah := false;
{перебираем все клетки доски}
for a:=1 to 8 do
   for b:=1 to 8 do
      {если в этой клетке не пустота значит оттуда возможно могут напасть}
      if sit.field[a,b]<>pusto then
        begin
        {устанавливаем источником хода - эту клетку}
        tmphod.a.x := a;
        tmphod.a.y := b;
        {если на этой клетке белая фигура то приемник хода - черный король}
        if sit.field[a,b] in whites then
        tmphod.b := sit.black.king;
        {а если там черные то нападаем на белого короля}
        if sit.field[a,b] in blacks then
        tmphod.b := sit.white.king;
        {если фигура на этой клетке может атаковать короля}
        if is_legal_move(sit,tmphod) then
           begin
           {значит соответвтвующему королю - шах}
           if sit.field[a,b] in whites then sit.black.shah := true else
           sit.white.shah := true;
           {}
           end;
        {}
        end;
{помечаем последний сделанный ход}
sit.lastmove := hod;
{добавляем ход в список}
inc(sit.moves_count);
sit.moves[sit.moves_count] := hod;
end;

{=================================}

{возможен ли ход}
function canmove(const sit:tsit; const hod:thod):boolean;
var nextsit : tsit; {ситуация после проверяемого хода}
begin
{предполагаем что ход возможен}
canmove := true;
{копируем ситуацию}
nextsit := sit;
{если фигура может так ходить то делаем ход}
if is_legal_move(sit,hod) and
((sit.field[hod.a.x,hod.a.y] in whites) = sit.whitesmove) then
makemove(nextsit,hod) else {иначе ход уже точно невозможен}
   begin
   canmove := false;
   exit;
   end;
{если после хода образуется шах тому кто ходил то ход невозможен}
if (nextsit.whitesmove and nextsit.black.shah) or
   (not nextsit.whitesmove and nextsit.white.shah) then canmove := false;
{}
end;

{=================================}

{получить список всех возможных ходов}
procedure get_all_moves(const sit:tsit; var list:thodlist);
var a,b,c,d:byte; tmphod:thod;
list1,list2:thodlist;
begin
{в начале - списки пусты}
list1.c := 0;
list2.c := 0;
{перебираем все клетки доски}
for a:=1 to 8 do
   for b:=1 to 8 do
      {если на клетке не пусто значит оттуда можно ходить}
      if sit.field[a,b] <> pusto then
         for c:=1 to 8 do
            for d:=1 to 8 do
               begin
               {}
               if ((sit.field[c,d] in whites) <>
                  (sit.field[a,b] in whites)) and
                  (sit.field[c,d] <> pusto) then {добавляем взятия}
                     begin
                     {}
                     tmphod.a.x := a;
                     tmphod.a.y := b;
                     tmphod.b.x := c;
                     tmphod.b.y := d;
                     {}
                     if canmove(sit,tmphod) then
                        begin
                        {}
                        inc(list1.c);
                        list1.h[list1.c] := tmphod;
                        {}
                        end;
                     {}
                     end;
               {}
               if (sit.field[c,d] = pusto) then {добавляем обычные ходы}
                     begin
                     {}
                     tmphod.a.x := a;
                     tmphod.a.y := b;
                     tmphod.b.x := c;
                     tmphod.b.y := d;
                     {}
                     if canmove(sit,tmphod) then
                        begin
                        {}
                        inc(list2.c);
                        list2.h[list2.c] := tmphod;
                        {}
                        end;
                     {}
                     end;
               {}
               end;{for}
{объедияем списки}
list.c := 0;
{}
for a:=1 to list1.c do
   begin
   inc(list.c);
   list.h[list.c] := list1.h[a];
   end;
{}
for a:=1 to list2.c do
   begin
   inc(list.c);
   list.h[list.c] := list2.h[a];
   end;
{}
end;

{=================================}

{закончилась ли игра}
function is_game_ended(const sit:tsit; var list:thodlist):boolean;
var cwslon,cwkon,cbslon,cbkon,a,b,d:byte;
sovp:boolean;
begin
{получаем список всех возможных ходов}
get_all_moves(sit,list);
{если список пуст - значит игра закончилась}
is_game_ended := (list.c=0);
{}
if (list.c=0) then exit;
{}
{если ходы повторились (3) 4 раза то наступает ничья}
{}
a := 4; {длина серии}
d := 0; {смещение серий}
{пока помещается 2 длины серии ищем повторяющиеся}
while (sit.moves_count>=a*2) and (a<=128) do
   begin
   {в начале совпавших серий нет}
   sovp := true;
   {перебираем последовательные серии}
   for b:=1 to a do {если ходы не равны}
      if (sit.moves[b+d].a.x <> sit.moves[b+a+d].a.x) or
         (sit.moves[b+d].a.y <> sit.moves[b+a+d].a.y) or
         (sit.moves[b+d].b.x <> sit.moves[b+a+d].b.x) or
         (sit.moves[b+d].b.y <> sit.moves[b+a+d].b.y) then
         begin {совпадений нет}
         sovp := false;
         break;
         end;
   {если совпадения есть}
   if sovp then
      begin {то ничья}
      is_game_ended := true;
      exit;
      end;
   {пока можно, увеличиваем сдвиг а затем увеличиваем длину серии}
   if sit.moves_count>a*2+d then inc(d) else inc(a,2);
   {}
   end;{while}
{}
{возможно ничья наступила из-за нехватки фигур}
cwslon := 0; cwkon := 0; cbslon := 0; cbkon := 0;
{считаем фигуры}
for a:=1 to 8 do
   for b:=1 to 8 do
      begin
      {считаем слонов и коней}
      case sit.field[a,b] of
      wslon: inc(cwslon);
      bslon: inc(cbslon);
      wkon: inc(cwkon);
      bkon: inc(cbkon);
      end;
      {если на поле все еще есть ферзь или ладья или пешка но это - не ничья}
      if (sit.field[a,b] mod 10) in [ferz,ladya,peshka] then exit;
      {если слонов и коней достаточно для победы то ничья не наступила}
      if (cwslon > 1) or (cbslon > 1) or (cbkon > 1) or (cwkon > 1) or
      (cwslon = 1) and (cwkon = 1) or (cbslon = 1) and (cbkon = 1) then exit;
      {}
      end;
{если фигур все же не хватает то наступила ничья}
is_game_ended := true;
{}
end;

{=================================}

{материальный вес фигуры}
const ves:array[peshka..korol] of word = (100,300,300,500,900,0);
korol_not_moved = 20; {нетронутый король}
ladya_not_moved = 10; {нетронутая ладья}
king_attack = 50; {оценка за шах}
{}
{позиционная оценка фигур}
peshka_pos: array[1..8,1..8] of shortint =
((0, 0, 0, 0, 0, 0, 0, 0),
 (4, 4, 4, 0, 0, 4, 4, 4),
 (6, 8, 2,10,10, 2, 8, 6),
 (6, 8,12,16,16,12, 8, 6),
 (8,12,16,24,24,16,12, 8),
 (12,16,24,32,32,24,16,12),
 (12,16,24,32,32,24,16,12),
 (0, 0, 0, 0, 0, 0, 0, 0));
{}
korol1_pos: array[1..8,1..8] of shortint =
((  0,  0, -4,-10,-10, -4,  0,  0),
 ( -4, -4, -8,-12,-12, -8, -4, -4),
 (-12,-16,-20,-20,-20,-20,-16,-12),
 (-16,-20,-24,-24,-24,-24,-20,-16),
 (-16,-20,-24,-24,-24,-24,-20,-16),
 (-12,-16,-20,-20,-20,-20,-16,-12),
 (-4,  -4, -8,-12,-12, -8, -4, -4),
 ( 0,   0, -4,-10,-10, -4,  0, 0));
{}
korol2_pos: array[1..8,1..8] of shortint =
((  0,  6, 12, 18, 18, 12,  6,  0),
 (  6, 12, 18, 24, 24, 18, 12,  6),
 ( 12, 18, 24, 30, 30, 24, 18, 12),
 ( 18, 24, 30, 36, 36, 30, 24, 18),
 ( 18, 24, 30, 36, 36, 30, 24, 18),
 ( 12, 18, 24, 30, 30, 24, 18, 12),
 (  6, 12, 18, 24, 24, 18, 12,  6),
 (  0,  6, 12, 18, 18, 12,  6,  0));
{}
kon_pos: array[1..8,1..8] of shortint =
(( 0, 4, 8,10,10, 8, 4, 0),
 ( 4, 8,16,20,20,16, 8, 4),
 ( 8,16,24,28,28,24,16, 8),
 (10,20,28,32,32,28,20,10),
 (10,20,28,32,32,28,20,10),
 ( 8,16,24,28,28,24,16, 8),
 ( 4, 8,16,20,20,16, 8, 4),
 ( 0, 4, 8,10,10, 8, 4, 0));
{}
slon_pos: array[1..8,1..8] of shortint =
((14,14,14,14,14,14,14,14),
 (14,22,18,18,18,18,22,14),
 (14,18,22,22,22,22,18,14),
 (14,18,22,22,22,22,18,14),
 (14,18,22,22,22,22,18,14),
 (14,18,22,22,22,22,18,14),
 (14,22,18,18,18,18,22,14),
 (14,14,14,14,14,14,14,14));
{}
ferz_pos = 50; {коэффициент который делится на расстояние до вражеского короля}
{}

{оценочная функция}
procedure evaluate(const sit:tsit; var mark:integer);
{}
var a,b,figures:byte;
ka:shortint;
{}
begin
{}
mark := 0;
figures := 0;
{подсчет материала}
for a:=1 to 8 do
   for b:=1 to 8 do
      if sit.field[a,b]<>pusto then
         begin
         {увеличиваем число фигур на доске}
         inc(figures);
         {черные фигуры + а белые -}
         if sit.field[a,b] in blacks then ka := 1 else ka := -1;
         {материальная оценка}
         mark := mark + ves[sit.field[a,b] mod 10]*ka;
         {позиционная оценка}
         case sit.field[a,b] mod 10 of
         peshka:
            if sit.field[a,b] in blacks then
               mark := mark + peshka_pos[a,b] else
               mark := mark - peshka_pos[a,9-b];
         {}
         kon: mark := mark + kon_pos[a,b]*ka;
         slon: mark := mark + slon_pos[a,b]*ka;
         {}
         ferz: if sit.field[a,b] in blacks then
            mark := round(mark + ferz_pos / ( abs(a-sit.white.king.x)
            + abs(b-sit.white.king.y) )) else
            mark := round(mark - ferz_pos / ( abs(a-sit.black.king.x)
            + abs(b-sit.black.king.y) ));
         end;{case}
         {}
         end;
{оценка нетронутой ладьи и короля}
if sit.white.kingmoved then mark := mark + korol_not_moved;
if sit.black.kingmoved then mark := mark - korol_not_moved;
if sit.white.leftmoved then mark := mark + ladya_not_moved;
if sit.black.leftmoved then mark := mark - ladya_not_moved;
if sit.white.rightmoved then mark := mark + ladya_not_moved;
if sit.black.rightmoved then mark := mark - ladya_not_moved;
{оценка за шах}
if sit.white.shah then mark := mark + king_attack;
if sit.black.shah then mark := mark - king_attack;
{оценка позиции короля}
mark := round(mark + korol1_pos[sit.black.king.x,sit.black.king.y] * figures / 30+
   korol2_pos[sit.black.king.x,sit.black.king.y] * (1-figures / 30));
mark := round(mark - korol1_pos[sit.white.king.x,sit.white.king.y] * figures / 30-
   korol2_pos[sit.white.king.x,sit.white.king.y] * (1-figures / 30));
{}
end;

{=================================}

{оценка ситуации}
procedure search(const sit:tsit; const whitecolor:boolean; const depth:byte;
                 {игровая ситуация, за белых ли считаем, грубина перебора}
                  alpha,beta:integer; var mark:integer);
                 {границы отсечений, возвращаемая оценка}
{}
var list:thodlist; {список возможных ходов}
nextsit:tsit; {ситуация после хода}
a:byte; {доп переменная}
mabyend:boolean; {возможно, что (depth=0)and(list.c=0)}
tempmark:integer; {лучшая оценка и возвращенная оценка}
{}
begin
{}
Application.ProcessMessages;
{}
mabyend := false;
{если достигли дна стека то включаем оценочную функцию}
if (depth=0) then
   begin
   {}
   evaluate(sit,mark);
   {тк оценочная функция работает на черных для того чтобы
   она работала на белых результат нужно взять с обратным знаком}
   if whitecolor then mark := -mark;
   {если кому-то шах значит это может бить концом игры и оценка будет другая}
   if not sit.black.shah and not sit.white.shah then exit else mabyend := true;
   {}
   end;
{получаем все ходы и если ходов нету, значит мат или ничья}
if is_game_ended(sit,list) then
   begin
   {с точки зрения черных оцениваем мат и ничью}
   if sit.white.shah then mark := 32000 else
   if sit.black.shah then mark := -32000 else mark := -32000;
   {а для белых инвертируем}
   if whitecolor then mark := -mark;
   exit;
   {}
   end;
{если конец игры не подтвердился, все равно выходим}
if mabyend then exit;
{перебираем ходы}
a := 1;
{если максимальная оценка хода для игрока А (альфа) превысила
максимальную нценку для игрока Б (бета), которая была получена на
предыдущем ходе, то мы может досрочно прекратить перебор и вернуть
альфа в качестве результата, т.к. уровнем выше мы все равно выберем
ход с максимальной оценкой (альфа) и поднимать ее еще выше не имеет
смысла. Если мы продолжим перебор то альфа будет только увеличиваться}
while (a<>list.c+1) and (alpha<beta) do
   begin
   {создаем следующую ситуацию}
   nextsit := sit;
   makemove(nextsit,list.h[a]);
   {считаем ее пользу}
   search(nextsit,not whitecolor,depth - 1,-beta,-alpha,tempmark);
   {тк считаем для врага, его польза нам во вред}
   tempmark := - tempmark;
   {если нашли ход получше, записываем его}
   if tempmark > alpha then alpha := tempmark;
   {}
   inc(a);
   end;
{возвращаем результат}
mark := alpha;
{}
end;

{=================================}
{=================================}

{ход компа}
procedure hod_compa(var sit:tsit; const whitecolor:boolean);
{}
var list:thodlist; {ходы}
nextsit:tsit; {ситуация после хода}
a,bestmove:byte; {доп переменная и номер лучшего хода}
tempmark:integer; {возвращенная и лучшая оценки}
alpha,beta:integer; {границы оценок}
{}
begin
{получаем ходы}
get_all_moves(sit,list);
alpha := -22000; beta := 22000;
bestmove := 1;
{перебираем}
a := 1;
{}
MainForm.Gauge.MaxValue := list.c+1;
{}
while (a<>list.c+1) {and (alpha<beta)} do
   begin
   {}
   MainForm.Gauge.progress := a;
   Application.ProcessMessages;
   {создаем ситуацию}
   nextsit := sit;
   makemove(nextsit,list.h[a]);
   {считаем ее пользу}
   search(nextsit,not whitecolor,glubina-1,-beta,-alpha,tempmark);
   tempmark := - tempmark;
   {обновляем лучшую оценку и лучший ход}
   if tempmark > alpha then
      begin
      bestmove := a;
      alpha := tempmark;
      end;
   {progress bar}
   {}
   inc(a);
   end;
{делаем ход}
makemove(sit,list.h[bestmove]);
MainForm.Gauge.progress := 0;
{}
end;

{==================================}

{###########################################################################}

procedure TMainForm.FormCreate(Sender: TObject);

const fn='pic.bmp';  {файл из которого будем доставать картинки фигур}

var a,b:byte;

begin
{чтобы не моргало при перерисовке}
DoubleBuffered := true;
{}
bmp := tbitmap.create;
{резервируем память для картинок и делаем их прозрачными}
for b:=1 to 2 do
for a:=peshka to korol do
   begin
   original_bmp[b,a] := tbitmap.create;
   original_bmp[b,a].transparent := true;
   original_bmp[b,a].transparentcolor := clsilver;
   resized_bmp[b,a] := tbitmap.create;
   resized_bmp[b,a].transparent := true;
   resized_bmp[b,a].transparentcolor := clsilver;
   end;
{проверяем наличие файла с картинками, и разрезаем его}
if fileexists(fn) then
make_bitmaps(fn) else
   begin
   showmessage('File ' + fn + ' not found!');
   halt;
   end;
{начинаем игру}
make_start_sit(mainsit);
{сложность по умолчанию}
glubina := 4;
{}
end;

procedure TMainForm.FormResize(Sender: TObject);
{максимальная сторона квадрата который поместится в окне}
var w:word;
{}
begin
{вычисляем сторону квадрата}
if (MainForm.ClientHeight - MainForm.Gauge.height) <= MainForm.ClientWidth then
w := (MainForm.ClientHeight - MainForm.Gauge.height) else
w := MainForm.ClientWidth ;
{и устанавливаем размер картинки}
image.width := w;
image.height := w;
{двигаем картинку в центр экрна}
image.Left := MainForm.ClientWidth div 2 - w div 2;
image.Top := (MainForm.ClientHeight - MainForm.Gauge.height) div 2 - w div 2;
{двигаем индикатор прогресса в низ окна}
gauge.width := MainForm.ClientWidth-1;
Gauge.Top := MainForm.ClientHeight - Gauge.Height-1;
{перерисовываем доску}
paint_field(face_field);
{}
end;

procedure TMainForm.ImageMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
{}
var cx,cy:byte;
w:word;
{}
begin
{если идет работа то нельзя тыкать по картинке}
if calculation then exit;
if game_ended then exit;
{}
w := image.height;
{получаем координаты клетки в которую ткнули}
cx := x div (w div 8) +1; if cx > 8 then cx := 8;
cy := y div (w div 8) +1; if cy > 8 then cy := 8;
{готовим доску для рисования}
face_field := mainsit.field; {!! pointers !!}
{отрываем фигуру от доски}
moving_figure := face_field[cx,cy];
face_field[cx,cy] := pusto;
{можно двигать фигуру}
can_move := true;
{начальные координаты хода}
hod_chela.a.x := cx;
hod_chela.a.y := cy;
{перерисовываем}
paint_field(face_field);
{}
end;

procedure TMainForm.ImageMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);

{---------------------------------}
procedure who_wins;
begin
{}
if mainsit.white.shah and not mainsit.black.shah then
   begin
   showmessage('Черные выиграли!');
   exit;
   end;
{}
if mainsit.black.shah and not mainsit.white.shah then
   begin
   showmessage('Белые выиграли!');
   exit;
   end;
{}
showmessage('Ничья!');
{}
end;
{---------------------------------}

var cx,cy:byte;
w:word;
{}
begin
{нельзя тыкать во время работы}
if calculation then exit;
if game_ended then exit;
{если перетащили фигуру то}
if can_move then
   begin
   {}
   w := (MainForm.ClientHeight - MainForm.Gauge.height);
   {вычисляем координаты}
   cx := x div (w div 8) + 1; if cx > 8 then cx := 8;
   cy := y div (w div 8) + 1; if cy > 8 then cy := 8;
   {устанавливаем конечную позицию хода}
   hod_chela.b.x := cx;
   hod_chela.b.y := cy;
   {если такой ход - правильный}
   if canmove(mainsit,hod_chela)
   and not game_ended then
      begin
      {ходим}
      makemove(mainsit,hod_chela);
      {перерисовываем}
      face_field := mainsit.field; {!! pointers !!}
      can_move := false;
      paint_field(face_field);
      {определяем победителя}
      game_ended := is_game_ended(mainsit,tmplist);
      if game_ended then who_wins;
      {}
      if not game_ended then
         begin
         {вычисления идут}
         calculation := true;
         {делаем ход}
         hod_compa(mainsit,false);
         {вычисления закончились}
         calculation := false;
         {перерисовываем}
         face_field := mainsit.field; {!! pointers !!}
         paint_field(face_field);
         {}
         game_ended := is_game_ended(mainsit,tmplist);
         if game_ended then who_wins;
         {}
         end;
      {}
      end else
         begin
         {если ход неправильный - возвращаем фигуру на родину}
         face_field[hod_chela.a.x,hod_chela.a.y] := moving_figure;
         paint_field(face_field);
         {}
         end;
   {}
   end;
{подвинули}
can_move := false;
{}
end;

procedure TMainForm.ImageMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
{}
var st:word;
{}
begin
{во время работы нельзя тыкать}
if calculation then exit;
if game_ended then exit;
{}
if (MainForm.ClientHeight - MainForm.Gauge.height) <= MainForm.ClientWidth then
st := MainForm.ClientHeight div 8 else
st := (MainForm.ClientHeight - MainForm.Gauge.height) div 8;
{если двигаем фигуру}
if can_move then
   begin
   {копируем прорисованную картинку из переменной на экран}
   MainForm.image.Picture.bitmap.width := bmp.width;
   MainForm.image.Picture.bitmap.height := bmp.height;
   MainForm.image.Picture.bitmap.Canvas.CopyRect(rect(0,0,bmp.width,bmp.height),bmp.canvas,rect(0,0,bmp.width,bmp.height));
   {поверх этой картинки рисуем ту фигуру которую двигаем}
   if moving_figure <> pusto then
   MainForm.image.Picture.bitmap.Canvas.draw(x - st div 2,y - st div 2,
   resized_bmp[moving_figure div 10,moving_figure mod 10]);
   {получаем довольно быструю смену кадров во время движения мышки}
   end;
{}
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
halt;
end;

procedure TMainForm.N2Click(Sender: TObject);
begin
{во время работы нельзя начать новую игру}
if calculation then exit;
{создаем начальную ситуацию}
make_start_sit(mainsit);
{перерисовываем экран}
face_field := mainsit.field; {!! pointers !!}
paint_field(face_field);
{}
end;

procedure TMainForm.N3Click(Sender: TObject);
begin
halt;
end;

{----------------------------------}

{сбрасывает галочки сложности в меню}
procedure uncheck;
begin
with mainform do
   begin
   n5.checked := false;
   n6.checked := false;
   n7.checked := false;
   n8.checked := false;
   n9.checked := false;
   end;
end;

{----------------------------------}

procedure TMainForm.N5Click(Sender: TObject);
begin
glubina := 1;
uncheck;
n5.checked := true;
end;

procedure TMainForm.N6Click(Sender: TObject);
begin
glubina := 2;
uncheck;
n6.checked := true;
end;

procedure TMainForm.N7Click(Sender: TObject);
begin
glubina := 3;
uncheck;
n7.checked := true;
end;

procedure TMainForm.N8Click(Sender: TObject);
begin
glubina := 4;
uncheck;
n8.checked := true;
end;

procedure TMainForm.N9Click(Sender: TObject);
begin
glubina := 5;
uncheck;
n9.checked := true;
end;

end.

