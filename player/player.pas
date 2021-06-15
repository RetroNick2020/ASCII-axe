(* Player setup and stats *)
unit player;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, player_inventory, plot_gen, combat_resolver, items;

(* Create player character *)
procedure createPlayer;
(* Moves the player on the map *)
procedure movePlayer(dir: word);
(* Process status effects *)
procedure processStatus;
(* Check if tile is occupied by an NPC *)
function combatCheck(x, y: smallint): boolean;
(* Pick up an item from the floor *)
procedure pickUp;
(*Increase Health, no more than maxHP *)
procedure increaseHealth(amount: smallint);

implementation

uses
  map, fov, ui, entities;

procedure createPlayer;
begin
  plot_gen.generateName;
  { Add Player to the list of creatures }
  entities.listLength := length(entities.entityList);
  SetLength(entities.entityList, entities.listLength + 1);
  with entities.entityList[0] do
  begin
    npcID := 0;
    race := plot_gen.playerName;
    description := plot_gen.playerTitle;
    glyph := '@';
    glyphColour := 'yellow';
    maxHP := 20;
    currentHP := 20;
    attack := 5;
    defence := 2;
    weaponDice := 0;
    weaponAdds := 0;
    xpReward := 0;
    visionRange := 4;
    moveCount := 0;
    targetX := 0;
    targetY := 0;
    inView := True;
    blocks := False;
    discovered := True;
    weaponEquipped := False;
    armourEquipped := False;
    isDead := False;
    stsDrunk := False;
    stsPoison := False;
    tmrDrunk := 0;
    tmrPoison := 0;
    posX := map.startX;
    posY := map.startY;
  end;
  (* Occupy tile *)
  map.occupy(entityList[0].posX, entityList[0].posY);
  (* set up inventory *)
  player_inventory.initialiseInventory;
  ui.equippedWeapon := 'No weapon equipped';
  ui.equippedArmour := 'No armour worn';
  (* Draw player and FOV *)
  fov.fieldOfView(entityList[0].posX, entityList[0].posY, entityList[0].visionRange, 1);
end;

(* Move the player within the confines of the game map *)
procedure movePlayer(dir: word);
var
  (* store original values in case player cannot move *)
  originalX, originalY: smallint;
begin
  (* Unoccupy tile *)
  map.unoccupy(entityList[0].posX, entityList[0].posY);
  (* Repaint visited tiles *)
  fov.fieldOfView(entities.entityList[0].posX, entities.entityList[0].posY,
    entities.entityList[0].visionRange, 0);
  originalX := entities.entityList[0].posX;
  originalY := entities.entityList[0].posY;
  case dir of
    1: Dec(entities.entityList[0].posY); // N
    2: Dec(entities.entityList[0].posX); // W
    3: Inc(entities.entityList[0].posY); // S
    4: Inc(entities.entityList[0].posX); // E
    5:                      // NE
    begin
      Inc(entities.entityList[0].posX);
      Dec(entities.entityList[0].posY);
    end;
    6:                      // SE
    begin
      Inc(entities.entityList[0].posX);
      Inc(entities.entityList[0].posY);
    end;
    7:                      // SW
    begin
      Dec(entities.entityList[0].posX);
      Inc(entities.entityList[0].posY);
    end;
    8:                      // NW
    begin
      Dec(entities.entityList[0].posX);
      Dec(entities.entityList[0].posY);
    end;
  end;
  (* check if tile is occupied *)
  if (map.isOccupied(entities.entityList[0].posX, entities.entityList[0].posY) =
    True) then
    (* check if tile is occupied by hostile NPC *)
    if (combatCheck(entities.entityList[0].posX, entities.entityList[0].posY) =
      True) then
    begin
      entities.entityList[0].posX := originalX;
      entities.entityList[0].posY := originalY;
    end;
  Inc(entities.entityList[0].moveCount);
  (* check if tile is walkable *)
  if (map.canMove(entities.entityList[0].posX, entities.entityList[0].posY) = False) then
  begin
    entities.entityList[0].posX := originalX;
    entities.entityList[0].posY := originalY;
    (* display a clumsy message if player is intoxicated *)
    if (entityList[0].stsDrunk = True) then
      ui.displayMessage('You bump into a wall');
    Dec(entities.entityList[0].moveCount);
  end;
  (* Occupy tile *)
  map.occupy(entityList[0].posX, entityList[0].posY);
  fov.fieldOfView(entities.entityList[0].posX, entities.entityList[0].posY,
    entities.entityList[0].visionRange, 1);
  ui.writeBufferedMessages;
end;

procedure processStatus;
begin
  (* Inebriation *)
  if (entities.entityList[0].stsDrunk = True) then
  begin
    if (entities.entityList[0].tmrDrunk <= 0) then
    begin
      entities.entityList[0].tmrDrunk := 0;
      entities.entityList[0].stsDrunk := False;
      ui.bufferMessage('The effects of the alcohol wear off');
    end
    else
      Dec(entities.entityList[0].tmrDrunk);
  end;

  (* Poison *)
  if (entities.entityList[0].stsPoison = True) then
  begin
    if (ui.poisonStatusSet = False) then
    begin
      (* Update UI *)
      ui.displayStatusEffect(1, 'poison');
      ui.poisonStatusSet := True;
      entityList[0].glyphColour := 'green';
    end;
    if (entities.entityList[0].tmrPoison <= 0) then
    begin
      entities.entityList[0].tmrPoison := 0;
      entities.entityList[0].stsPoison := False;
      (* Update UI *)
      ui.displayStatusEffect(0, 'poison');
      ui.poisonStatusSet := False;
      entityList[0].glyphColour := 'yellow';
    end
    else
    begin
      Dec(entityList[0].currentHP);
      Dec(entityList[0].tmrPoison);
      updateHealth;
    end;
  end;
end;


function combatCheck(x, y: smallint): boolean;
  { TODO : Replace this with a check to see if the tile is occupied }
var
  i: smallint;
begin
  Result := False;
  for i := 1 to entities.npcAmount do
  begin
    if (x = entities.entityList[i].posX) then
    begin
      if (y = entities.entityList[i].posY) then
        combat_resolver.combat(i);
      Result := True;
    end;
  end;
end;

procedure pickUp;
var
  i: smallint;
begin
  for i := 1 to itemAmount do
  begin
    if (entities.entityList[0].posX = itemList[i].posX) and
      (entities.entityList[0].posY = itemList[i].posY) and
      (itemList[i].onMap = True) then
    begin
      if (player_inventory.addToInventory(i) = True) then
        Inc(entities.entityList[0].moveCount)
      else
        ui.displayMessage('Your inventory is full');
    end
    else if (entities.entityList[0].posX = itemList[i].posX) and
      (entities.entityList[0].posY = itemList[i].posY) and
      (itemList[i].onMap = False) then
      ui.displayMessage('There is nothing on the ground here');
  end;
end;

procedure increaseHealth(amount: smallint);
begin
  if (entities.entityList[0].currentHP <> entities.entityList[0].maxHP) then
  begin
    if ((entities.entityList[0].currentHP + amount) >= entities.entityList[0].maxHP) then
      entities.entityList[0].currentHP := entities.entityList[0].maxHP
    else
      entities.entityList[0].currentHP := entities.entityList[0].currentHP + amount;
    ui.updateHealth;
    ui.bufferMessage('You feel restored');
  end
  else
    ui.bufferMessage('You are already at full health');
end;

end.
