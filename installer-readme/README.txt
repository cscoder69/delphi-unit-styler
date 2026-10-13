*******************************************************************************
*  BETA VERSION                                                               *
*  CS.Coder Unit Styler is in beta: it is still being tested and may have     *
*  defects. Keep your project under version control or leave the backup       *
*  option on, and check the preview before applying changes to a whole        *
*  project.                                                                   *
*  Please report anything you find:                                           *
*  https://github.com/cscoder69/delphi-unit-styler/issues                     *
*******************************************************************************

CS.Coder - Unit Styler (beta)
=============================

An extension for the Delphi IDE that organizes the uses clauses of the units
of the project you have open: sorted, indented, with priorities and groups
that you define. It runs only when you ask, shows a preview and asks for
confirmation before changing anything.

Works with Delphi 11, 12 and 13 (32-bit IDE, and the 64-bit IDE of 12 and 13).


INSTALL
  1. Close Delphi.
  2. Double-click Install.bat.
  3. Open Delphi. The commands are in the menu CS.Coder > Unit Styler, on
     Ctrl+Alt+U with the code editor in focus, and in the right-click menu of
     the code editor.

  It installs for every supported Delphi found on this Windows user, with no
  administrator rights. Running Install.bat again updates to the version in
  this folder and keeps your settings.

UNINSTALL
  1. Close Delphi.
  2. Double-click Uninstall.bat.

  Your settings are kept. To delete them as well, run:  Uninstall.bat /data

WHERE THINGS ARE
  Packages:          %LOCALAPPDATA%\CSCoder\UnitStyler\bin
  Rules:             %LOCALAPPDATA%\CSCoder\UnitStyler\D11\settings.json  (D12,
                     D13 for the other versions). Each Delphi keeps its own
                     rules, shortcut and language.
  Project settings:  %LOCALAPPDATA%\CSCoder\UnitStyler\projects
                     No setting is kept in the Windows registry.

LANGUAGE
  English, Portuguese, Spanish, German and French. The windows follow the
  language of Windows; to pick another, use Settings > Language.

LICENSE
  Open source, MIT License. See LICENSE.txt.

  https://github.com/cscoder69/delphi-unit-styler
