(* Handles player inventory and associated functions *)
unit player_inventory;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, entities, items, ui, scrgame, globalutils;

type
  (* Items in inventory *)
  Equipment = record
    id, useID: smallint;
    Name, description, itemType: shortstring;
    glyph: char;
    (* Is the item still in the inventory *)
    inInventory: boolean;
    (* Is the item being worn or wielded *)
    equipped: boolean;
  end;

var
  inventory: array[0..9] of Equipment;
  (* 0 - main menu, 1 - drop menu, 2 - quaff menu, 3 - wear/wield menu *)
  menuState: byte;

(* Initialise empty player inventory *)
procedure initialiseInventory;
(* Setup equipped items when loading a saved game *)
procedure loadEquippedItems;
(* Add to inventory *)
function addToInventory(itemNumber: smallint): boolean;
(* Display the inventory screen *)
procedure showInventory;
(* Show menu at bottom of screen *)
procedure bottomMenu(style: byte);
(* Show hint at bottom of screen *)
procedure showHint(message: shortstring);
(* Highlight inventory slots *)
procedure highlightSlots(i, x: smallint);
(* Dim inventory slots *)
procedure dimSlots(i, x: smallint);
(* Accept menu input *)
procedure menu(selection: word);
(* Drop menu *)
procedure drop(dropItem: byte);
(* Quaff menu *)
procedure quaff(quaffItem: byte);
(* Wear / Wield menu *)
procedure wield(wieldItem: byte);

implementation

uses
  main;

procedure initialiseInventory;
var
  i: byte;
begin
  for i := 0 to 9 do
  begin
    inventory[i].id := i;
    inventory[i].Name := 'Empty';
    inventory[i].equipped := False;
    inventory[i].description := 'x';
    inventory[i].itemType := 'x';
    inventory[i].glyph := 'x';
    inventory[i].inInventory := False;
    inventory[i].useID := 0;
  end;
end;

procedure loadEquippedItems;
var
  i: smallint;
begin
  for i := 0 to 9 do
  begin
    if (inventory[i].equipped = True) then
    begin
      (* Check for weapons *)
      if (inventory[i].itemType = 'weapon') then
        scrgame.updateWeapon(inventory[i].Name)
      (* Check for armour *)
      else if (inventory[i].itemType = 'armour') then
        scrgame.updateArmour(inventory[i].Name);
    end;
  end;
end;

(* Returns TRUE if successfully added, FALSE if the inventory is full *)
function addToInventory(itemNumber: smallint): boolean;
var
  i: smallint;
begin
  Result := False;
  for i := 0 to 9 do
  begin
    if (inventory[i].Name = 'Empty') then
    begin
      itemList[itemNumber].onMap := False;
      (* Populate inventory with item description *)
      inventory[i].id := i;
      inventory[i].Name := itemList[itemNumber].itemname;
      inventory[i].description := itemList[itemNumber].itemDescription;
      inventory[i].itemType := itemList[itemNumber].itemType;
      inventory[i].useID := itemList[itemNumber].useID;
      inventory[i].glyph := itemList[itemNumber].glyph;
      inventory[i].inInventory := True;
      ui.displayMessage('You pick up the ' + inventory[i].Name);
      Result := True;
      exit;
    end;
  end;
end;

procedure showInventory;
var
  i, x: smallint;
begin
  main.gameState := 2; // Accept keyboard commands for inventory screen
  menuState := 0;
  currentScreen := inventoryScreen; // Display inventory screen
  (* Clear the screen *)
  inventoryScreen.Canvas.Brush.Color := globalutils.BACKGROUNDCOLOUR;
  inventoryScreen.Canvas.FillRect(0, 0, inventoryScreen.Width, inventoryScreen.Height);
  (* Draw title bar *)
  inventoryScreen.Canvas.Brush.Color := globalutils.MESSAGEFADE6;
  inventoryScreen.Canvas.Rectangle(50, 40, 785, 80);
  (* Draw title *)
  inventoryScreen.Canvas.Font.Color := UITEXTCOLOUR;
  inventoryScreen.Canvas.Brush.Style := bsClear;
  inventoryScreen.Canvas.Font.Size := 12;
  inventoryScreen.Canvas.TextOut(100, 50, 'Inventory slots');
  inventoryScreen.Canvas.Font.Size := 10;
  (* List inventory *)
  x := 90; // x is position of each new line
  for i := 0 to 9 do
  begin
    x := x + 20;
    if (inventory[i].Name = 'Empty') then
      dimSlots(i, x)
    else
      highlightSlots(i, x);
  end;
  bottomMenu(0);
end;

procedure bottomMenu(style: byte);
(* 0 - main menu, 1 - inventory slots, exit *)
begin
  (* Draw menu bar *)
  inventoryScreen.Canvas.Brush.Color := globalutils.MESSAGEFADE6;
  inventoryScreen.Canvas.Rectangle(50, 345, 785, 375);
  (* Show menu options at bottom of screen *)
  case style of
    0:  { Main menu }
    begin
      inventoryScreen.Canvas.Font.Color := UITEXTCOLOUR;
      inventoryScreen.Canvas.Brush.Style := bsClear;
      inventoryScreen.Canvas.TextOut(100, 350,
        'D key for drop menu  |  Q key for quaff/drink menu  |  W key to equip armour/weapons  |  ESC key to exit');
    end;
    1:  { Select Inventory slot }
    begin
      inventoryScreen.Canvas.Font.Color := UITEXTCOLOUR;
      inventoryScreen.Canvas.Brush.Style := bsClear;
      inventoryScreen.Canvas.TextOut(100, 350,
        '0..9 to select an inventory slot  |  ESC key to go back');
    end;
  end;
end;

procedure showHint(message: shortstring);
begin
  inventoryScreen.Canvas.Font.Color := UITEXTCOLOUR;
  inventoryScreen.Canvas.Brush.Style := bsClear;
  inventoryScreen.Canvas.TextOut(100, 480, message);
end;

procedure highlightSlots(i, x: smallint);
begin
  inventoryScreen.Canvas.Font.Color := UITEXTCOLOUR;
  inventoryScreen.Canvas.TextOut(50, x, '[' + IntToStr(i) + '] ' +
    inventory[i].Name + ' - ' + inventory[i].description);
end;

procedure dimSlots(i, x: smallint);
begin
  inventoryScreen.Canvas.Font.Color := MESSAGEFADE1;
  inventoryScreen.Canvas.TextOut(50, x, '[' + IntToStr(i) + '] <empty slot>');
end;

procedure menu(selection: word);
begin
  case selection of
    0: { ESC key is pressed }
    begin
      if (menuState = 0) then
      begin
        main.gameState := 1;
        main.currentScreen := tempScreen;
        exit;
      end
      else if (menuState = 1) then { In the Drop screen }
        showInventory
      else if (menuState = 2) then { In the Quaff screen }
        showInventory
      else if (menuState = 3) then { In the Wear / Wield screen }
        showInventory;
    end;
    1: drop(10); { Drop menu }
    2:  { slot 0 }
    begin
      if (menuState = 1) then
        drop(0)
      else if (menuState = 2) then
        quaff(0)
      else if (menuState = 3) then
        wield(0);
    end;
    3: { slot 1 }
    begin
      if (menuState = 1) then
        drop(1)
      else if (menuState = 2) then
        quaff(1)
      else if (menuState = 3) then
        wield(1);
    end;
    4: { slot 2 }
    begin
      if (menuState = 1) then
        drop(2)
      else if (menuState = 2) then
        quaff(2)
      else if (menuState = 3) then
        wield(2);
    end;
    5: { slot 3 }
    begin
      if (menuState = 1) then
        drop(3)
      else if (menuState = 2) then
        quaff(3)
      else if (menuState = 3) then
        wield(3);
    end;
    6: { slot 4 }
    begin
      if (menuState = 1) then
        drop(4)
      else if (menuState = 2) then
        quaff(4)
      else if (menuState = 3) then
        wield(4);
    end;
    7: { slot 5 }
    begin
      if (menuState = 1) then
        drop(5)
      else if (menuState = 2) then
        quaff(5)
      else if (menuState = 3) then
        wield(5);
    end;
    8: { slot 6 }
    begin
      if (menuState = 1) then
        drop(6)
      else if (menuState = 2) then
        quaff(6)
      else if (menuState = 3) then
        wield(6);
    end;
    9: { slot 7 }
    begin
      if (menuState = 1) then
        drop(7)
      else if (menuState = 2) then
        quaff(7)
      else if (menuState = 3) then
        wield(7);
    end;
    10: { slot 8 }
    begin
      if (menuState = 1) then
        drop(8)
      else if (menuState = 2) then
        quaff(8)
      else if (menuState = 3) then
        wield(8);
    end;
    11: { slot 9 }
    begin
      if (menuState = 1) then
        drop(9)
      else if (menuState = 2) then
        quaff(9)
      else if (menuState = 3) then
        wield(9);
    end;
    12: quaff(10);  { Quaff menu }
    13: wield(10);  { Wear / Wield menu }
  end;
end;

procedure drop(dropItem: byte);
var
  i, x: smallint;
begin
  menuState := 1;
  (* Clear the screen *)
  inventoryScreen.Canvas.Brush.Color := globalutils.BACKGROUNDCOLOUR;
  inventoryScreen.Canvas.FillRect(0, 0, inventoryScreen.Width, inventoryScreen.Height);
  (* Draw title bar *)
  inventoryScreen.Canvas.Brush.Color := globalutils.MESSAGEFADE6;
  inventoryScreen.Canvas.Rectangle(50, 40, 785, 80);
  (* Draw title *)
  inventoryScreen.Canvas.Font.Color := UITEXTCOLOUR;
  inventoryScreen.Canvas.Brush.Style := bsClear;
  inventoryScreen.Canvas.Font.Size := 12;
  inventoryScreen.Canvas.TextOut(100, 50, 'Select item to drop');
  inventoryScreen.Canvas.Font.Size := 10;
  (* List inventory *)
  x := 90; { x is position of each new line }
  for i := 0 to 9 do
  begin
    x := x + 20;
    if (inventory[i].Name = 'Empty') or (inventory[i].equipped = True) then
      dimSlots(i, x)
    else
      highlightSlots(i, x);
  end;
  (* Bottom menu *)
  bottomMenu(1);
  if (dropItem <> 10) then
  begin
    if (inventory[dropItem].Name <> 'Empty') and
      (inventory[dropItem].equipped <> True) then
    begin   { TODO : First search for a space in the itemList that has the onMap flag set to false and use that slot }
      (* Create a new entry in item list and copy item description *)
      Inc(items.itemAmount);
      items.listLength := length(items.itemList);
      SetLength(items.itemList, items.listLength + 1);
      with items.itemList[items.listLength] do
      begin
        itemID := items.listLength;
        itemName := inventory[dropItem].Name;
        itemDescription := inventory[dropItem].description;
        itemType := inventory[dropItem].itemType;
        glyph := inventory[dropItem].glyph;
        inView := True;
        posX := entities.entityList[0].posX;
        posY := entities.entityList[0].posY;
        onMap := True;
        discovered := True;
      end;
      ui.displayMessage('You drop the ' + inventory[dropItem].Name);
      Inc(playerTurn);
      (* Remove from inventory *)
      inventory[dropItem].Name := 'Empty';
      showInventory;
    end;
  end;
end;

procedure quaff(quaffItem: byte);
var
  i, x: smallint;
begin
  menuState := 2;
  (* Clear the screen *)
  inventoryScreen.Canvas.Brush.Color := globalutils.BACKGROUNDCOLOUR;
  inventoryScreen.Canvas.FillRect(0, 0, inventoryScreen.Width, inventoryScreen.Height);
  (* Draw title bar *)
  inventoryScreen.Canvas.Brush.Color := globalutils.MESSAGEFADE6;
  inventoryScreen.Canvas.Rectangle(50, 40, 785, 80);
  (* Draw title *)
  inventoryScreen.Canvas.Font.Color := UITEXTCOLOUR;
  inventoryScreen.Canvas.Brush.Style := bsClear;
  inventoryScreen.Canvas.Font.Size := 12;
  inventoryScreen.Canvas.TextOut(100, 50, 'Select item to drink');
  inventoryScreen.Canvas.Font.Size := 10;
  (* List inventory *)
  x := 90; { x is position of each new line }
  for i := 0 to 9 do
  begin
    x := x + 20;
    if (inventory[i].Name = 'Empty') or (inventory[i].itemType <> 'drink') then
    (* dimSlots(i, x) *)
    else
      highlightSlots(i, x);
  end;
  (* Bottom menu *)
  bottomMenu(1);
  if (quaffItem <> 10) then
  begin
    if (inventory[quaffItem].Name <> 'Empty') and
      (inventory[quaffItem].itemType = 'drink') then
    begin
      ui.writeBufferedMessages;
      ui.bufferMessage('You quaff the ' + inventory[quaffItem].Name);
      items.lookupUse(inventory[quaffItem].useID, False);
      Inc(playerTurn);
      (* Remove from inventory *)
      inventory[quaffItem].Name := 'Empty';
      showInventory;
    end;
  end;
end;

procedure wield(wieldItem: byte);
var
  i, x: smallint;
begin
  menuState := 3;
  (* Clear the screen *)
  inventoryScreen.Canvas.Brush.Color := globalutils.BACKGROUNDCOLOUR;
  inventoryScreen.Canvas.FillRect(0, 0, inventoryScreen.Width, inventoryScreen.Height);
  (* Draw title bar *)
  inventoryScreen.Canvas.Brush.Color := globalutils.MESSAGEFADE6;
  inventoryScreen.Canvas.Rectangle(50, 40, 785, 80);
  (* Draw title *)
  inventoryScreen.Canvas.Font.Color := UITEXTCOLOUR;
  inventoryScreen.Canvas.Brush.Style := bsClear;
  inventoryScreen.Canvas.Font.Size := 12;
  inventoryScreen.Canvas.TextOut(100, 50, 'Select item to wear / wield');
  inventoryScreen.Canvas.Font.Size := 10;
  (* List inventory *)
  x := 90; { x is position of each new line }
  for i := 0 to 9 do
  begin
    x := x + 20;
    if (inventory[i].Name = 'Empty') or (inventory[i].itemType = 'drink') then
    (* dimSlots(i, x) *)
    else
      highlightSlots(i, x);
  end;
  (* Bottom menu *)
  bottomMenu(1);
  if (wieldItem <> 10) then
  begin
    if (inventory[wieldItem].Name <> 'Empty') then
    begin
      (* If the item is an unequipped weapon, and the player already has a weapon equipped
         prompt the player to unequip their weapon first *)
      if (inventory[wieldItem].equipped = False) and
        (inventory[wieldItem].itemType = 'weapon') and
        (entityList[0].weaponEquipped = True) then
      begin
        showHint('You must first unequip the weapon you already hold');
      end
      (* If the item is unworn armour, and the player is already wearing armour
         prompt the player to unequip their armour first *)
      else if (inventory[wieldItem].equipped = False) and
        (inventory[wieldItem].itemType = 'armour') and
        (entityList[0].armourEquipped = True) then
      begin
        showHint('You must first remove the armour you already wear');
      end
      (* Check whether the item is already equipped or not *)
      else if (inventory[wieldItem].equipped = False) then
      begin
        ui.writeBufferedMessages;
        if (inventory[wieldItem].itemType = 'weapon') then
          ui.bufferMessage('You equip the ' + inventory[wieldItem].Name)
        else
          ui.bufferMessage('You put on the ' + inventory[wieldItem].Name);
        items.lookupUse(inventory[wieldItem].useID, False);
        inventory[wieldItem].equipped := True;
        (* Add equipped suffix *)
        inventory[wieldItem].description :=
          inventory[wieldItem].description + ' [equipped]';
        Inc(playerTurn);
        showInventory;
      end
      else
      begin
        ui.writeBufferedMessages;
        if (inventory[wieldItem].itemType = 'weapon') then
          ui.bufferMessage('You unequip the ' + inventory[wieldItem].Name)
        else
          ui.bufferMessage('You take off the ' + inventory[wieldItem].Name);
        items.lookupUse(inventory[wieldItem].useID, True);
        inventory[wieldItem].equipped := False;
        (* Remove equipped suffix *)
        SetLength(inventory[wieldItem].description,
          Length(inventory[wieldItem].description) - 11);
        Inc(playerTurn);
        showInventory;
      end;
    end;
  end;
end;

end.

