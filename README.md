# CS.Coder Unit Styler (beta)

> [!WARNING]
> **BETA VERSION.** CS.Coder Unit Styler is in beta: it is still being tested and may have defects.
> Keep your project under version control or leave the backup option on, and check the
> preview before applying changes to a whole project.
> Please report anything you find by opening an
> [issue](https://github.com/cscoder69/delphi-unit-styler/issues).

**English** | [Português (Brasil)](README.pt-BR.md)

**Version:** 0.26.10.12e (beta) · **License:** [MIT](LICENSE.txt), free and open source ·
**Delphi:** 11, 12 and 13 · [**Download**](https://github.com/cscoder69/delphi-unit-styler/releases)

CS.Coder Unit Styler is an extension for the Delphi IDE that organizes the `uses` clauses
of the units of your project. It runs only when you ask, shows a before/after preview and
asks for confirmation before changing anything.

![The same unit before and after: 34 units in the uses clauses, one per line, sorted and separated in groups](docs/screenshots/before-after.png)

*The same unit before and after. Project and unit names in the screenshots are examples.*

## Summary

- **Your layout.** One unit per line, or several per line up to a column limit, sorted and
  indented.
- **Priorities and groups.** Units you choose come first; groups by name or prefix, such
  as `System.*`.
- **Three scopes.** The current unit, the open units or every unit of the project.
- **Preview and confirmation.** Nothing runs by itself on open, save or compile.
- **Careful with your code.** Comments, compiler directives, paths, encoding and line
  breaks are kept, and the units of the Delphi libraries stay in place by default.
- **Backup.** Each file is copied to a `.backup` folder of the project before it changes.
- **Part of the IDE.** Menu, shortcut and editor context menu, in the light and dark
  themes, in English, Portuguese, Spanish, German and French.

## Installation

Works with Delphi 11 (32-bit IDE) and Delphi 12 and 13 (32-bit and 64-bit IDE). No
compiler and no administrator rights are needed.

1. **Download** `CSCoderUnitStyler-<version>.zip` from the
   [Releases page](https://github.com/cscoder69/delphi-unit-styler/releases), under
   **Assets**. Do not pick "Source code": that one has no installer.
2. **Extract** the whole zip into a folder of your choice.
3. **Close Delphi.**
4. **Run `Install.bat`.** It installs for the current Windows user in every supported
   Delphi it finds and prints one line per Delphi, for example
   `[OK] Delphi 12 (32-bit, 64-bit)`.
5. **Open Delphi.** The commands are in the main menu, under **CS.Coder > Unit Styler**.

**Updating:** run the `Install.bat` of the newer zip, with Delphi closed. Your settings are
kept.

**Uninstalling:** `Uninstall.bat` removes the extension and keeps your settings.
`Uninstall.bat /data` also deletes the settings, and cannot be undone.

## What's new

**0.26.10.12e**: the package description shows the CS.Coder site in Component > Install Packages, and `LICENSE.txt` holds the MIT text only. The notes of every version are on the
[Releases page](https://github.com/cscoder69/delphi-unit-styler/releases).

## Using it

Open a project and open **Organize uses** from the menu **CS.Coder > Unit Styler**, with
**Ctrl+Alt+U** in the code editor, or with a right-click in the editor. Choose where to
apply, look at the preview if you want, and confirm.

| Organize uses | Settings |
|---|---|
| ![Organize uses window: scope, rules in use, Preview and Apply](docs/screenshots/organize-uses.png) | ![Settings window: formatting, priorities and groups, project settings, backup, shortcut and language](docs/screenshots/settings.png) |

- **Units open in the editor** are changed there and never saved by the tool: you can undo
  with Ctrl+Z and you decide when to save.
- **Units that were closed** are rewritten on disk, in their original encoding, when
  **Save closed units automatically** is checked.
- **The order of `uses` matters to the compiler:** when two units declare the same name,
  the one listed last is used. That is why `Winapi.*`, `System.*`, `Vcl.*`, `FMX.*` and
  `Data.*` are protected and never change places unless you edit that list.

The complete documentation, with every rule and option, is on the
[product page](https://www.cscoder.com.br/projetos/unit-styler-delphi/) (in Portuguese).

## Build from source

`build.ps1` builds the package and the demonstration program, and `test.ps1` runs the
tests, with the command-line compilers of Delphi. Set your Delphi folders at the top of
each script. There is one `.dpk` per Delphi version in `packages/`, and the sources are in
`src/`.

## Other CS.Coder tools

- [CS.Coder Project Hub](https://github.com/cscoder69/delphi-project-hub): project
  shortcuts organized in categories and groups, on the Delphi Welcome Page.

## Support

Open an [issue](https://github.com/cscoder69/delphi-unit-styler/issues) for problems and
suggestions. Pull requests are welcome. Contact: contato@cscoder.com.br

## License

Released under the [MIT License](LICENSE.txt). Copyright (c) 2026 CS.Coder.

"Delphi" and "RAD Studio" are trademarks of Embarcadero Technologies, Inc. CS.Coder Unit
Styler is an independent project. It is not affiliated with, maintained by or endorsed by
Embarcadero.
