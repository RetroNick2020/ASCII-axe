unit scrInventory;

{$mode fpc}{$H+}

interface

(* Draw the outline of the screen *)
procedure drawOutline;
(* Show the main inventory screen *)
procedure displayInventoryScreen;
(* Show the drop menu *)
procedure displayDropMenu;

implementation

uses
  ui, player_inventory;

procedure drawOutline;
begin
  { Header }
  TextOut(10, 2, 'cyan', chr(218));
  for x := 11 to 69 do
    TextOut(x, 2, 'cyan', chr(196));
  TextOut(70, 2, 'cyan', chr(191));
  TextOut(10, 3, 'cyan', chr(180));
  TextOut(70, 3, 'cyan', chr(195));
  TextOut(10, 4, 'cyan', chr(192));
  for x := 11 to 69 do
    TextOut(x, 4, 'cyan', chr(196));
  TextOut(70, 4, 'cyan', chr(217));
end;

procedure displayInventoryScreen;
var
  x, y, invItem: byte;
  letter: char;
begin
  invItem := 0;
  { draw outline }
  drawOutline;
  { Inventory title }
  TextOut(15, 3, 'cyan', 'Inventory slots');

  { Footer menu }
  TextOut(6, 23, 'cyanBGblackTXT', ' D - Drop item ');
  TextOut(23, 23, 'cyanBGblackTXT', ' Q - Quaff/drink ');
  TextOut(42, 23, 'cyanBGblackTXT', ' W - Weapons/Armour ');
  TextOut(64, 23, 'cyanBGblackTXT', ' X - Exit ');

  { Display items in inventory }
  y := 6;
  for letter := 'a' to 'j' do
  begin
    if (player_inventory.inventory[invItem].Name = 'Empty') then
      TextOut(10, y, 'darkGrey', '[' + letter + ']  ' + chr(174) +
        ' empty slot ' + chr(175))
    else
      TextOut(10, y, 'cyan', '[' + letter + ']  ' +
        player_inventory.inventory[invItem].Name);
    Inc(y);
    Inc(invItem);
  end;
end;

procedure displayDropMenu;
var
  x, y, invItem: byte;
  letter: char;
begin
  invItem := 0;
  drawOutline;
  { Inventory title }
  TextOut(15, 3, 'cyan', 'Select item to drop');
  { Footer menu }
  TextOut(5, 23, 'cyanBGblackTXT', ' a-j Select item ');
  TextOut(24, 23, 'cyanBGblackTXT', ' Q - Quaff/drink ');
  TextOut(43, 23, 'cyanBGblackTXT', ' W - Weapons/Armour ');
  TextOut(65, 23, 'cyanBGblackTXT', ' X - Exit ');

  { Display items in inventory }
  y := 6;
  for letter := 'a' to 'j' do
  begin
    { Empty slots }
    if (player_inventory.inventory[invItem].Name = 'Empty') then
      TextOut(10, y, 'darkGrey', '[' + letter + ']  ' + chr(174) +
        ' empty slot ' + chr(175))
    { Equipped items cannot be dropped }
    else if (player_inventory.inventory[invItem].equipped = True) then
      TextOut(10, y, 'darkGrey', '[' + letter + ']  ' +
        player_inventory.inventory[invItem].Name)
    { Items that can be dropped }
    else
      TextOut(10, y, 'cyan', '[' + letter + ']  ' +
        player_inventory.inventory[invItem].Name);
    Inc(y);
    Inc(invItem);
  end;
end;

end.
