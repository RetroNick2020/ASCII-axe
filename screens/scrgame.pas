(* Main game screen *)

unit scrGame;

{$mode fpc}{$H+}

interface


(* Draws the panel on side of screen *)
procedure drawSidepanel;
(* Clear screen and load various panels for game *)
procedure displayGameScreen;


implementation

uses
  ui, entities;

procedure drawSidepanel;
var
  i: smallint;
begin
  (* Stats window *)
  { top line }
  TextOut(58, 1, 'cyan', Chr(218));
  for i := 59 to 79 do
  begin
    TextOut(i, 1, 'cyan', Chr(196));
  end;
  TextOut(80, 1, 'cyan', Chr(191));
  { edges }
  for i := 2 to 13 do
  begin
    TextOut(58, i, 'cyan', Chr(179) + '                     ' + Chr(179));
  end;
  { bottom }
  TextOut(58, 14, 'cyan', Chr(192));
  for i := 59 to 79 do
  begin
    TextOut(i, 14, 'cyan', Chr(196));
  end;
  TextOut(80, 14, 'cyan', Chr(217));

  (* Equipment window *)
  { top line }
  TextOut(58, 15, 'cyan', Chr(218));
  for i := 59 to 79 do
  begin
    TextOut(i, 15, 'cyan', Chr(196));
  end;
  TextOut(80, 15, 'cyan', Chr(191));
  TextOut(60, 15, 'cyan', 'Equipment');
  { edges }
  for i := 16 to 20 do
  begin
    TextOut(58, i, 'cyan', Chr(179) + '                     ' + Chr(179));
  end;
  { bottom }
  TextOut(58, 20, 'cyan', Chr(192));
  for i := 59 to 79 do
  begin
    TextOut(i, 20, 'cyan', Chr(196));
  end;
  TextOut(80, 20, 'cyan', Chr(217));

  (* Write stat titles *)
  TextOut(60, 2, 'cyan', entities.entityList[0].race);
  TextOut(60, 3, 'cyan', 'The ' + entities.entityList[0].description);
  TextOut(60, 4, 'cyan', 'Level:');
  TextOut(60, 6, 'cyan', 'Experience:');
  TextOut(60, 7, 'cyan', 'Health:');
  TextOut(60, 9, 'cyan', 'Attack:');
  TextOut(60, 10, 'cyan', 'Defence:');

  (* Write stats *)
  ui.updateLevel;
  ui.updateXP;
  ui.updateHealth;
  ui.updateAttack;
  ui.updateDefence;
  ui.updateWeapon;
  ui.updateArmour;
end;

procedure displayGameScreen;
begin
  drawSidepanel;
end;

end.

