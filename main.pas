(* Axes, Armour & Ale - Roguelike for Linux and Windows.
   @author (Chris Hawkins)
*)

unit main;

{$mode fpc}{$H+}

interface

uses
  Video, SysUtils, KeyboardInput, ui, camera, map, scrGame, globalUtils, universe;

type
  gameStatus = (stTitle, stGame, stInventory, stQuitMenu, stGameOver);

var
  (* State machine for game menus / controls *)
  gameState: gameStatus;


procedure setSeed;
procedure initialise;
procedure exitApplication;
procedure newGame;
procedure gameLoop;

implementation

uses
  entities;

procedure setSeed;
begin
  {$IFDEF Linux}
  RandSeed := RandSeed shl 8;
  {$ENDIF}
  {$IFDEF Windows}
  RandSeed := ((RandSeed shl 8) or GetProcessID);
  {$ENDIF}
end;

procedure initialise;
begin
  gameState := stTitle;
  Randomize;
  { Check if seed set as command line parameter }
  if (ParamCount = 2) then
  begin
    if (ParamStr(1) = '--seed') then
      RandSeed := StrToDWord(ParamStr(2))
    else
    begin
      { Set random seed if not specified }
      setSeed;
    end;
  end
  else
    setSeed;
  { Initialise video unit and show title screen }
  ui.setupScreen;
  { Initialise keyboard unit }
  keyboardinput.setupKeyboard;
  { wait for keyboard input }
  keyboardinput.waitForInput;
end;

procedure exitApplication;
begin
  gameState := stGameOver;
  { Shutdown keyboard unit }
  keyboardinput.shutdownKeyboard;
  { Shutdown video unit }
  ui.shutdownScreen;
  (* Clear screen and display author message *)
  ui.exitMessage;
  Halt;
end;

procedure newGame;
begin
  (* Game state = game running *)
  gameState := stGame;
  playerTurn := 0;
  (* Initialise the game world and create 1st cave *)
  universe.dungeonAmount := 0;
  SetLength(universe.dungeonList, 0);
  (* first map type is always a cave *)
  map.mapType := 2;
  (* first map is number 1, map type is a cave with tunnels *)
  universe.createNewDungeon(2, map.mapType);
  (* Spawn game entities *)
  entities.spawnNPCs;

  { prepare changes to the screen }
  LockScreenUpdate;
  (* Clear the screen *)
  ui.screenBlank;
  (* Draw the game screen *)
  scrGame.displayGameScreen;

  (* draw map through the camera *)
  camera.drawMap;
  ui.displayMessage('Welcome message here...');
  { Write those changes to the screen }
  UnlockScreenUpdate;
  { only redraws the parts that have been updated }
  UpdateScreen(False);
end;

procedure gameLoop;
begin
  { prepare changes to the screen }
  LockScreenUpdate;

  (* BEGIN DRAWING TO THE BUFFER *)


  (* draw map through the camera *)
  camera.drawMap;

  (* FINISH DRAWING TO THE BUFFER *)

  { Write those changes to the screen }
  UnlockScreenUpdate;
  { only redraws the parts that have been updated }
  UpdateScreen(False);
end;

end.
