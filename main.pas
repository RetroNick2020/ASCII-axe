(* Axes, Armour & Ale - Roguelike for Linux and Windows.
   @author (Chris Hawkins)
*)

unit main;

{$mode objfpc}{$H+}

interface

uses
  Video, SysUtils, KeyboardInput, ui, camera, map, scrGame, globalUtils,
  universe, fov, player, scrRIP, plot_gen;

type
  gameStatus = (stTitle, stGame, stInventory, stDropMenu, stQuaffMenu,
    stWearWield, stQuitMenu, stGameOver);

var
  (* State machine for game menus / controls *)
  gameState: gameStatus;

procedure setSeed;
procedure initialise;
procedure exitApplication;
procedure newGame;
procedure gameLoop;
procedure returnToGameScreen;
procedure gameOver;

implementation

uses
  entities, items;

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

  (* Check for previous save file *)
  if (FileExists(globalUtils.saveDirectory + DirectorySeparator +
    globalutils.saveFile)) then
    { Initialise video unit and show title screen }
    ui.setupScreen(1)
  else
  begin
    try
      { create directory }
      CreateDir(globalUtils.saveDirectory);
    finally
      { Initialise video unit and show title screen }
      ui.setupScreen(0);
    end;
  end;
  { Initialise keyboard unit }
  keyboardinput.setupKeyboard;
  { wait for keyboard input }
  keyboardinput.waitForInput;
end;

procedure exitApplication;
begin
  try
    gameState := stGameOver;
    { Shutdown keyboard unit }
    keyboardinput.shutdownKeyboard;
    { Shutdown video unit }
    ui.shutdownScreen;
    (* Clear screen and display author message *)
    ui.exitMessage;
    (* Clear arrays *)
    entityList := nil;
    itemList := nil;
  finally
    halt;
  end;
end;

procedure newGame;
begin
  (* Game state = game running *)
  gameState := stGame;
  killer := 'empty';
  (* Initialise the game world and create 1st cave *)
  universe.dlistLength := 0;
  (* first map type is always a cave *)
  map.mapType := tCave;
  (* map type is a cave with tunnels *)
  universe.createNewDungeon(map.mapType);
  (* Create the Player *)
  entities.spawnPlayer;
  (* Spawn game entities *)
  universe.spawnDenizens;
  (* Drop items *)
  items.initialiseItems;

  { prepare changes to the screen }
  LockScreenUpdate;
  (* Clear the screen *)
  ui.screenBlank;
  (* Draw the game screen *)
  scrGame.displayGameScreen;

  (* draw map through the camera *)
  camera.drawMap;

  (* Generate the welcome message *)
  plot_gen.getTrollDate;
  ui.displayMessage('Good Luck...');
  ui.displayMessage('You enter the cave on ' + plot_gen.trollDate);
  { Write those changes to the screen }
  UnlockScreenUpdate;
  { only redraws the parts that have been updated }
  UpdateScreen(False);
end;

procedure gameLoop;
var
  i: byte;
begin
  (* Check for player death at start of game loop *)
  if (entityList[0].currentHP <= 0) then
  begin
    gameState := stGameOver;
    gameOver;
  end;
  (* move NPC's *)
  entities.NPCgameLoop;
  (* Process status effects *)
  player.processStatus;
  (* Draw player and FOV *)
  fov.fieldOfView(entityList[0].posX, entityList[0].posY, entityList[0].visionRange, 1);

  (* Redraw all items *)
  for i := 1 to items.itemAmount do
    if (map.canSee(items.itemList[i].posX, items.itemList[i].posY) = True) and
      (items.itemList[i].onMap = True) then
    begin
      items.itemList[i].inView := True;
      items.drawItemsOnMap(i);
      (* Display a message if this is the first time seeing this item *)
      if (items.itemList[i].discovered = False) then
      begin
        ui.displayMessage('You see a ' + items.itemList[i].itemName);
        items.itemList[i].discovered := True;
      end;
    end
    else
    begin
      items.itemList[i].inView := False;
      map.drawTile(itemList[i].posX, itemList[i].posY, 0);
    end;

  (* Redraw all NPC'S *)
  for i := 1 to entities.npcAmount do
    entities.redrawMapDisplay(i);

  { prepare changes to the screen }
  LockScreenUpdate;

  (* BEGIN DRAWING TO THE BUFFER *)

  entities.occupyUpdate;
  (* Update health display to show damage *)
  ui.updateHealth;
  (* draw map through the camera *)
  camera.drawMap;

  (* FINISH DRAWING TO THE BUFFER *)

  { Write those changes to the screen }
  UnlockScreenUpdate;
  { only redraws the parts that have been updated }
  UpdateScreen(False);
  (* Check for player death at end of game loop *)
  if (entityList[0].currentHP <= 0) then
  begin
    gameState := stGameOver;
    gameOver;
  end;
end;

procedure returnToGameScreen;
var
  i: byte;
begin
  { prepare changes to the screen }
  LockScreenUpdate;
  (* BEGIN DRAWING TO THE BUFFER *)

  (* Clear the screen *)
  ui.screenBlank;
  (* Draw the game screen *)
  scrGame.displayGameScreen;
  (* Draw player and FOV *)
  fov.fieldOfView(entityList[0].posX, entityList[0].posY, entityList[0].visionRange, 1);
  (* Redraw all NPC'S *)
  for i := 1 to entities.npcAmount do
    entities.redrawMapDisplay(i);
  (* Redraw all items *)
  for i := 1 to items.itemAmount do
    if (map.canSee(items.itemList[i].posX, items.itemList[i].posY) = True) then
    begin
      items.itemList[i].inView := True;
      items.drawItemsOnMap(i);
      (* Display a message if this is the first time seeing this item *)
      if (items.itemList[i].discovered = False) then
      begin
        ui.displayMessage('You see a ' + items.itemList[i].itemName);
        items.itemList[i].discovered := True;
      end;
    end
    else
    begin
      items.itemList[i].inView := False;
      map.drawTile(itemList[i].posX, itemList[i].posY, 0);
    end;
  (* draw map through the camera *)
  camera.drawMap;
  entities.occupyUpdate;
  (* Update health display to show damage *)
  ui.updateHealth;
  (* draw map through the camera *)
  camera.drawMap;
  (* Redraw message log *)
  ui.restoreMessages;
  ui.writeBufferedMessages;

  (* FINISH DRAWING TO THE BUFFER *)
  { Write those changes to the screen }
  UnlockScreenUpdate;
  { only redraws the parts that have been updated }
  UpdateScreen(False);
end;

procedure gameOver;
begin
  scrRIP.displayRIPscreen;

end;

end.
