unit CSCoder.Styler.Strings;


interface

type
  TStylerLanguage = (slEnglish, slPortuguese, slSpanish, slGerman, slFrench);
  TStylerText = (stOrganize, stProject, stCurrent, stScope, stCurrentScope,
    stOpenScope, stAllScope, stSearch, stSettings, stPreview, stBefore,
    stAfter, stCancel, stGenerate, stApply, stManual, stConfirmation,
    stConfirmQuestion, stConfirmApply, stNoSave, stNoChanges, stChanges,
    stBatchLater, stDemo, stApplied, stError, stStale, stOnePerLine,
    stAlphabetical, stIndent, stSpaces, stPriorities, stPriorityNames,
    stGroups, stGroupName, stSelectors, stAdd, stRemove, stUp, stDown,
    stBlankGroups, stUngroupedFirst, stSaveSettings, stSelectUnit,
    stPreserved, stSourceChanged, stSettingsInvalid, stExcludeInterface,
    stExcludeImplementation, stExcludedUnits, stDiagSyntax, stDiagStructure,
    stDiagDirective, stDiagComment, stDiagDuplicate, stDiagAnchor,
    stDiagAnchorComment, stDiagSpacing, stBlankBeforeSections, stBlankAfterSections,
    stViewPreview, stPreviewHint, stClose, stDiagSectionSpacing, stWrapUnits, stColumns, stAlphabeticalFull,
    // The About window, same texts as the other CS.Coder tools where they apply.
    stAbout, stAboutBy, stAboutTagline, stAboutVersion, stAboutBuild,
    stAboutCompat, stAboutDataFile, stAboutCopyPath, stAboutOpenFolder, stAboutLicType,
    stAboutLicCommercial, stAboutLicSource, stAboutLicData, stAboutLicenseDetails, stAboutUpdates,
    stAboutCheckUpdates, stAboutLicenseTitle, stFeatOrgTitle, stFeatOrgText, stFeatControlTitle,
    stFeatControlText, stFeatProdTitle, stFeatProdText, stFeatDelphiTitle, stFeatDelphiText,
    stAboutSlogan, stAboutSupport, stAboutRights,
    stAboutLicFree, stAboutLicSub, stAboutLicTypeValue, stAboutAllowed, stAboutSourceOpen, stAboutNone,
    stAboutLicenseCloseHint, stAboutReport,
    // Choice of language and the menu of the tool.
    stLanguage, stLanguageAuto, stLanguageHint, stMenuBranchHint, stMenuOrganizeHint,
    stMenuSettingsHint, stMenuAboutHint, stEditorMenuHint, stOpenOrganizeError, stOpenSettingsError,
    // Execution window, comparison and report.
    stExecCaption, stExecInfoHint, stCancelHint, stWhereApply, stScopeHint, stScopeNoBatchHint, stCountHint,
    stRunPattern, stRunPatternHint, stStatusHint, stSumOnePerLine, stSumWrap, stSumFirstName, stSumFullName,
    stSumSpaces, stSumGroups, stSumPriorities, stSumBlankBefore, stSumBlankAfter, stSumNone, stSaveNoteAuto,
    stSaveNoteOpen, stSummaryHint, stSaveNoteHint, stCountMany, stCountOne, stIgnoredOne, stIgnoredMany,
    stInterrupt, stProgress, stAnalyzing, stApplying, stAnalysisStopped, stNoUnitInScope, stNoCurrentUnit,
    stCurrentIgnored, stPreviewOf, stDiagLine, stBeforeHint, stAfterHint, stBeforeAfter, stDiagnosticsHint,
    stSplitterHint, stPreviewError, stSaveSettingsError, stConfirmCount, stConfirmAuto, stConfirmOpen,
    stReportCaption, stReportHint, stCopy, stCopyHint, stReportCloseHint, stBatchUnavailable, stIssueUnitError,
    stIssueWarning, stIssueStopped, stIssueApplyError, stBackupHint, stDoneDemo, stDoneFailed, stDoneBackup,
    stDoneAuto, stDoneOpen, stRunAborted, stIssueError, stIssueRunError, stIssueAppliedBefore,
    // Settings window and its dialogs.
    stSetTitle, stSetTitleHint, stSetSubtitle, stSetSubtitleNoProject, stSetSubtitleHint, stGrpFormatting,
    stGrpFormattingHint, stGrpGroups, stGrpGroupsHint, stGrpProject, stGrpProjectHint, stGrpProjectNone,
    stNoProjectHint, stEditPriorities, stEditPrioritiesHint, stEditGroups, stEditGroupsHint, stUngrouped,
    stUngroupedHint, stPosFirst, stPosLast, stPositionHint, stProtectedButton, stProtectedButtonHint,
    stExcludeInterfaceHint, stExcludeImplementationHint, stPreserveButton, stPreserveButtonHint, stIgnoreButton,
    stIgnoreButtonHint, stCleanButton, stCleanButtonHint, stShortcutLabel, stShortcutHint, stAutoSave,
    stAutoSaveHint, stBackupCheck, stBackupCheckHint, stSaveNote, stSaveNoteExplain, stFolderButton,
    stFolderButtonHint, stSetCancelHint, stSave, stSaveHint, stSaveHintNoProject, stDlgPriority, stDlgPreserve,
    stDlgProtected, stProtectedLabel, stPreserveMemoHint, stProtectedMemoHint, stRestoreDefault,
    stRestoreDefaultHint, stDlgCancelHint, stDlgOkHint, stFolderOpenError, stBackupNone, stBackupOne,
    stBackupMany, stFileOne, stFileMany, stBackupWhere, stDlgClean, stBackupInfoHint, stKeepNewest,
    stKeepNewestHint, stDelete, stDeleteHint, stCleanCloseHint, stDeletedOne, stDeletedMany, stDeleteFailed,
    stDlgIgnored, stIgnoredLabel, stIgnoredListHint, stIgnoredOtherLabel, stIgnoredMemoHint, stDlgGroups,
    stGroupsGridHint, stGroupAddHint, stGroupRemoveHint, stGroupUpHint, stGroupDownHint, stIndentRange,
    stCannotSave,
    // What each rule does, shown as the hint of its control.
    stHlpOnePerLine, stHlpWrapUnits, stHlpColumns, stHlpAlphabetical, stHlpAlphabeticalFull, stHlpIndent,
    stHlpSpaces, stHlpPriorities, stHlpPriorityNames, stHlpGroups, stHlpBlankGroups, stHlpBlankBefore,
    stHlpBlankAfter, stHlpCurrentScope, stHlpOpenScope, stHlpAllScope, stHlpViewPreview, stHlpApply,
    stHlpSettings, stHlpClose,
    // Reasons a unit, a rule or a settings file is refused.
    stErrUtf8Invalid, stErrUtf16Size, stErrEncodingUnknown, stErrEncodingFit, stErrChangedOnDisk, stErrReadOnly,
    stErrNoEditorServices, stErrNoProject, stErrNotUnit, stErrNotInProject, stErrProjectChanged, stErrUnitOutside,
    stErrNoEditor, stErrEditorClosed, stErrReadEditor, stErrOpenUnit, stErrClosedDuring, stErrMustOpen,
    stErrChangedAfter, stErrEmptyName, stErrBadSelector, stErrDupSelector, stErrBothLayouts, stErrWidthRange,
    stErrIndentChars, stErrGroupNoName, stErrGroupDup, stErrCfgList, stErrCfgItem, stErrCfgValue, stErrCfgJson,
    stErrCfgVersion, stErrCfgUnread, stErrCfgChanged, stErrCfgGroup, stErrCfgGroupName);

const
  // Each language is listed in its own name, whatever the current one is.
  StylerLanguageNames: array[TStylerLanguage] of string = ('English', 'Português', 'Español', 'Deutsch', 'Français');

  // Codes kept in the settings file.
  StylerLanguageCodes: array[TStylerLanguage] of string = ('en', 'pt', 'es', 'de', 'fr');

function L(Id: TStylerText; Language: TStylerLanguage): string; overload;
// Text in the language in use.
function L(Id: TStylerText): string; overload;
// Same, run through Format.
function L(Id: TStylerText; const Args: array of const): string; overload;
function LF(Id: TStylerText; Language: TStylerLanguage; const Args: array of const): string;
// Language in use: the one the user picked, otherwise the one of Windows
// (English when Windows is in a language the tool does not have).
function StylerLanguage: TStylerLanguage;
// Takes the choice kept in the settings: one of StylerLanguageCodes, or
// anything else to follow Windows. Nothing is saved here.
procedure UseStylerLanguage(const Code: string);
function AutomaticLanguage: TStylerLanguage;
function DiagnosticText(Code: Integer; Language: TStylerLanguage): string;

implementation

uses Winapi.Windows, System.SysUtils, CSCoder.Styler.Types;

const
  LB = sLineBreak;

  Texts: array[TStylerText, TStylerLanguage] of string = (
    ('Organize uses', 'Organizar uses', 'Organizar uses', 'Uses organisieren', 'Organiser uses'),
    ('Project', 'Projeto', 'Proyecto', 'Projekt', 'Projet'),
    ('Current unit', 'Unit atual', 'Unit actual', 'Aktuelle Unit', 'Unit actuelle'),
    ('Where to run?', 'Onde executar?', '¿Dónde ejecutar?', 'Wo ausführen?', 'Où exécuter ?'),
    ('Current unit', 'Unit atual', 'Unit actual', 'Aktuelle Unit', 'Unit actuelle'),
    ('Open units', 'Units abertas', 'Units abiertas', 'Geöffnete Units', 'Units ouvertes'),
    ('All project units', 'Todas as units do projeto', 'Todas las units del proyecto', 'Alle Projekt-Units', 'Toutes les units du projet'),
    ('Search unit...', 'Buscar unit...', 'Buscar unit...', 'Unit suchen...', 'Rechercher une unit...'),
    ('Settings...', 'Configurações...', 'Configuración...', 'Einstellungen...', 'Paramètres...'),
    ('Change preview', 'Prévia das alterações', 'Vista previa de cambios', 'Änderungsvorschau', 'Aperçu des modifications'),
    ('Before', 'Antes', 'Antes', 'Vorher', 'Avant'),
    ('After', 'Depois', 'Después', 'Nachher', 'Après'),
    ('Cancel', 'Cancelar', 'Cancelar', 'Abbrechen', 'Annuler'),
    ('Generate preview', 'Gerar prévia', 'Generar vista previa', 'Vorschau erstellen', 'Générer un aperçu'),
    ('Apply', 'Aplicar', 'Aplicar', 'Anwenden', 'Appliquer'),
    ('Nothing changes without your confirmation. Manual execution only.', 'Nada será alterado sem sua confirmação. Execução somente manual.', 'Nada cambia sin su confirmación. Ejecución solo manual.', 'Keine Änderung ohne Bestätigung. Nur manuelle Ausführung.', 'Aucune modification sans confirmation. Exécution manuelle uniquement.'),
    ('Confirm application', 'Confirmar aplicação', 'Confirmar aplicación', 'Anwendung bestätigen', 'Confirmer l’application'),
    ('Apply changes to %d unit(s) in project %s?', 'Aplicar alterações em %d unit(s) do projeto %s?', '¿Aplicar cambios en %d unit(s) del proyecto %s?', 'Änderungen an %d Unit(s) im Projekt %s anwenden?', 'Appliquer les modifications à %d unit(s) du projet %s ?'),
    ('Confirm and apply', 'Confirmar e aplicar', 'Confirmar y aplicar', 'Bestätigen und anwenden', 'Confirmer et appliquer'),
    ('Source files will not be saved automatically.', 'Os fontes não serão salvos automaticamente.', 'Los fuentes no se guardarán automáticamente.', 'Quelldateien werden nicht automatisch gespeichert.', 'Les fichiers source ne seront pas enregistrés automatiquement.'),
    ('No changes proposed.', 'Nenhuma alteração proposta.', 'No se proponen cambios.', 'Keine Änderungen vorgeschlagen.', 'Aucune modification proposée.'),
    ('%d unit(s) with changes', '%d unit(s) com alterações', '%d unit(s) con cambios', '%d Unit(s) mit Änderungen', '%d unit(s) avec modifications'),
    ('Batch execution will be available in a later stage.', 'Execução em lote estará disponível em uma próxima etapa.', 'La ejecución por lotes estará disponible más adelante.', 'Stapelverarbeitung folgt in einer späteren Phase.', 'Le traitement par lot sera disponible ultérieurement.'),
    ('DEMO — changes affect only samples in memory.', 'DEMONSTRAÇÃO — alterações somente nos exemplos em memória.', 'DEMOSTRACIÓN — cambios solo en ejemplos en memoria.', 'DEMO — Änderungen nur an Beispielen im Speicher.', 'DÉMONSTRATION — modifications des exemples en mémoire uniquement.'),
    ('Changes applied. Source files were not saved.', 'Alterações aplicadas. Os fontes não foram salvos.', 'Cambios aplicados. Los fuentes no se guardaron.', 'Änderungen angewendet. Quelldateien nicht gespeichert.', 'Modifications appliquées. Les fichiers source n’ont pas été enregistrés.'),
    ('The operation could not be completed.', 'Não foi possível concluir a operação.', 'No se pudo completar la operación.', 'Der Vorgang konnte nicht abgeschlossen werden.', 'L’opération n’a pas pu être effectuée.'),
    ('The source changed. Generate a new preview.', 'O código mudou. Gere uma nova prévia.', 'El código cambió. Genere una nueva vista previa.', 'Der Quelltext wurde geändert. Neue Vorschau erstellen.', 'Le code a changé. Générez un nouvel aperçu.'),
    ('One unit per line', 'Uma unit por linha', 'Una unit por línea', 'Eine Unit pro Zeile', 'Une unit par ligne'),
    ('Sort A to Z by first name', 'Ordenar de A a Z pelo primeiro nome', 'Ordenar de A a Z por el primer nombre', 'A bis Z nach dem ersten Namen', 'Trier de A à Z par le premier nom'),
    ('Apply indentation', 'Aplicar indentação', 'Aplicar sangría', 'Einzug anwenden', 'Appliquer l’indentation'),
    ('Spaces', 'Espaços', 'Espacios', 'Leerzeichen', 'Espaces'),
    ('Prioritize units', 'Priorizar units', 'Priorizar units', 'Units priorisieren', 'Prioriser des units'),
    ('One unit name or namespace prefix per line', 'Um nome de unit ou prefixo de namespace por linha', 'Un nombre de unit o prefijo por línea', 'Ein Unit-Name oder Namespace-Präfix pro Zeile', 'Un nom d’unit ou préfixe par ligne'),
    ('Organize by groups', 'Organizar por grupos', 'Organizar por grupos', 'Nach Gruppen ordnen', 'Organiser par groupes'),
    ('Group name', 'Nome do grupo', 'Nombre del grupo', 'Gruppenname', 'Nom du groupe'),
    ('Unit names or prefixes, separated by semicolons', 'Nomes ou prefixos separados por ponto e vírgula', 'Nombres o prefijos separados por punto y coma', 'Namen oder Präfixe, getrennt durch Semikolon', 'Noms ou préfixes séparés par des points-virgules'),
    ('Add', 'Adicionar', 'Añadir', 'Hinzufügen', 'Ajouter'),
    ('Remove', 'Remover', 'Eliminar', 'Entfernen', 'Supprimer'),
    ('Move up', 'Mover acima', 'Subir', 'Nach oben', 'Monter'),
    ('Move down', 'Mover abaixo', 'Bajar', 'Nach unten', 'Descendre'),
    ('Blank line between groups', 'Linha em branco entre grupos', 'Línea en blanco entre grupos', 'Leerzeile zwischen Gruppen', 'Ligne vide entre les groupes'),
    ('Ungrouped units first', 'Units sem grupo no início', 'Units sin grupo al inicio', 'Nicht gruppierte Units zuerst', 'Units sans groupe au début'),
    ('Save settings', 'Salvar configurações', 'Guardar configuración', 'Einstellungen speichern', 'Enregistrer les paramètres'),
    ('Select at least one unit.', 'Selecione pelo menos uma unit.', 'Seleccione al menos una unit.', 'Mindestens eine Unit auswählen.', 'Sélectionnez au moins une unit.'),
    ('A source region was preserved conservatively.', 'Um trecho foi preservado por segurança da transformação.', 'Se conservó un fragmento por seguridad de la transformación.', 'Ein Quellbereich wurde vorsorglich beibehalten.', 'Une portion de code a été conservée par prudence.'),
    ('The editor or project context changed. Reopen the tool.', 'O editor ou o contexto do projeto mudou. Reabra a ferramenta.', 'El editor o el proyecto cambió. Abra de nuevo la herramienta.', 'Editor oder Projektkontext geändert. Werkzeug erneut öffnen.', 'L’éditeur ou le contexte du projet a changé. Rouvrez l’outil.'),
    ('Settings are invalid or changed elsewhere.', 'Configurações inválidas ou alteradas externamente.', 'Configuración inválida o modificada externamente.', 'Einstellungen ungültig oder extern geändert.', 'Paramètres invalides ou modifiés ailleurs.'),
    ('Do not organize interface uses', 'Não organizar uses da interface', 'No organizar uses de interface', 'Interface-Uses nicht organisieren', 'Ne pas organiser les uses de l’interface'),
    ('Do not organize implementation uses', 'Não organizar uses da implementation', 'No organizar uses de implementation', 'Implementation-Uses nicht organisieren', 'Ne pas organiser les uses de l’implémentation'),
    ('Units to preserve: one name or prefix per line', 'Units a preservar: um nome ou prefixo por linha', 'Units a conservar: un nombre o prefijo por línea', 'Beizubehaltende Units: ein Name oder Präfix pro Zeile', 'Units à conserver : un nom ou préfixe par ligne'),
    ('Incomplete or invalid syntax: region preserved.', 'Sintaxe incompleta ou inválida: trecho preservado.', 'Sintaxis incompleta o inválida: fragmento conservado.', 'Unvollständige oder ungültige Syntax: Bereich beibehalten.', 'Syntaxe incomplète ou invalide : portion conservée.'),
    ('Unsupported structure or mixed line endings: region preserved.', 'Estrutura não suportada ou quebras de linha mistas: trecho preservado.', 'Estructura no compatible o saltos mixtos: fragmento conservado.', 'Nicht unterstützte Struktur oder gemischte Zeilenenden: Bereich beibehalten.', 'Structure non prise en charge ou fins de ligne mixtes : portion conservée.'),
    ('Compiler directives: region preserved without moving dependencies.', 'Diretivas de compilação: trecho preservado sem mover dependências.', 'Directivas de compilación: fragmento conservado sin mover dependencias.', 'Compiler-Direktiven: Bereich ohne Verschieben von Abhängigkeiten beibehalten.', 'Directives du compilateur : portion conservée sans déplacer les dépendances.'),
    ('Loose comment in the middle of the uses: clause preserved. Only a comment at the end of the line of a unit goes with the unit.', 'Comentário solto no meio do uses: seção uses preservada. Só o comentário no fim da linha de uma unit acompanha a unit.', 'Comentario suelto en medio del uses: uses conservado. Solo el comentario al final de la línea de una unit acompaña a la unit.', 'Loser Kommentar mitten im Uses: Uses beibehalten. Nur ein Kommentar am Zeilenende einer Unit wandert mit der Unit.', 'Commentaire isolé au milieu du uses : clause uses conservée. Seul un commentaire en fin de ligne d’une unit suit la unit.'),
    ('Duplicate unit: clause preserved.', 'Unit duplicada: seção uses preservada.', 'Unit duplicada: uses conservado.', 'Doppelte Unit: Uses beibehalten.', 'Unit en double : clause uses conservée.'),
    ('Preserved unit: the ordering does not cross this dependency.', 'Unit preservada: a ordem não atravessa essa dependência.', 'Unit conservada: el orden no cruza esta dependencia.', 'Beibehaltene Unit: Die Reihenfolge wandert nicht an dieser Abhängigkeit vorbei.', 'Unit conservée : le tri ne franchit pas cette dépendance.'),
    ('Comments with excluded units: clause preserved.', 'Comentários junto de units excluídas: seção uses preservada.', 'Comentarios con units excluidas: uses conservado.', 'Kommentare bei ausgeschlossenen Units: Uses beibehalten.', 'Commentaires avec des units exclues : clause uses conservée.'),
    ('Blank line omitted to preserve comment association.', 'Linha em branco omitida para preservar a associação do comentário.', 'Línea vacía omitida para conservar la asociación del comentario.', 'Leerzeile zur Erhaltung der Kommentarzuordnung ausgelassen.', 'Ligne vide omise pour conserver l’association du commentaire.'),
    ('Blank line before sections', 'Linha em branco antes das seções', 'Línea en blanco antes de las secciones', 'Leerzeile vor Abschnitten', 'Ligne vide avant les sections'),
    ('Blank line after sections', 'Linha em branco depois das seções', 'Línea en blanco después de las secciones', 'Leerzeile nach Abschnitten', 'Ligne vide après les sections'),
    ('Preview', 'Prévia', 'Vista previa', 'Vorschau', 'Aperçu'),
    ('Select a file tab and open its comparison. The preview is read-only.', 'Visualizar prévia gera a proposta e abre a comparação da unit. Nenhum fonte é alterado.', 'Seleccione la pestaña de una unit y abra su comparación. La vista es de solo lectura.', 'Unit-Register wählen und Vergleich öffnen. Die Vorschau ist schreibgeschützt.', 'Sélectionnez l’onglet d’une unit et ouvrez sa comparaison. L’aperçu est en lecture seule.'),
    ('Close', 'Fechar', 'Cerrar', 'Schließen', 'Fermer'),
    ('Section spacing preserved near comments, directives, exclusions or uncertain structure.', 'Espaçamento das seções preservado junto de comentários, diretivas, exclusões ou estrutura incerta.', 'Espaciado de secciones conservado junto a comentarios, directivas, exclusiones o estructura incierta.', 'Abschnittsabstand bei Kommentaren, Direktiven, Ausschlüssen oder unklarer Struktur beibehalten.', 'Espacement des sections conservé près des commentaires, directives, exclusions ou structure incertaine.'),
    ('Several units per line', 'Várias units por linha', 'Varias units por línea', 'Mehrere Units pro Zeile', 'Plusieurs units par ligne'),
    ('Columns', 'Colunas', 'Columnas', 'Spalten', 'Colonnes'),
    ('And by second name', 'E pelo segundo nome', 'Y por segundo nombre', 'Und nach zweitem Namen', 'Et par deuxième nom'),
    ('About', 'Sobre', 'Acerca de', 'Info', 'À propos'),
    ('by', 'por', 'por', 'von', 'par'),
    ('Organize the uses clauses of your Delphi units quickly and safely.', 'Organize as cláusulas uses das suas units Delphi de forma rápida e segura.', 'Organice las cláusulas uses de sus units Delphi de forma rápida y segura.', 'Organisieren Sie die Uses-Klauseln Ihrer Delphi-Units schnell und sicher.', 'Organisez les clauses uses de vos units Delphi rapidement et en toute sécurité.'),
    ('Version', 'Versão', 'Versión', 'Version', 'Version'),
    ('Build', 'Build', 'Compilación', 'Build', 'Build'),
    ('Compatibility', 'Compatibilidade', 'Compatibilidad', 'Kompatibilität', 'Compatibilité'),
    ('Settings', 'Configurações', 'Configuración', 'Einstellungen', 'Paramètres'),
    ('Copy path', 'Copiar caminho', 'Copiar ruta', 'Pfad kopieren', 'Copier le chemin'),
    ('Open folder', 'Abrir pasta', 'Abrir carpeta', 'Ordner öffnen', 'Ouvrir le dossier'),
    ('License type', 'Tipo de licença', 'Tipo de licencia', 'Lizenztyp', 'Type de licence'),
    ('Commercial use', 'Uso comercial', 'Uso comercial', 'Kommerzielle Nutzung', 'Usage commercial'),
    ('Source code', 'Código-fonte', 'Código fuente', 'Quellcode', 'Code source'),
    ('Data collection', 'Coleta de dados', 'Recopilación de datos', 'Datenerfassung', 'Collecte de données'),
    ('License details', 'Detalhes da licença', 'Detalles de la licencia', 'Lizenzdetails', 'Détails de la licence'),
    ('Updates', 'Atualizações', 'Actualizaciones', 'Updates', 'Mises à jour'),
    ('Check for updates', 'Verificar atualizações', 'Buscar actualizaciones', 'Nach Updates suchen', 'Rechercher des mises à jour'),
    ('License', 'Licença', 'Licencia', 'Lizenz', 'Licence'),
    ('Smart organization', 'Organização inteligente', 'Organización inteligente', 'Clevere Ordnung', 'Organisation intelligente'),
    ('Priorities and groups', 'Prioridades e grupos', 'Prioridades y grupos', 'Prioritäten und Gruppen', 'Priorités et groupes'),
    ('Full control', 'Controle total', 'Control total', 'Volle Kontrolle', 'Contrôle total'),
    ('Preview and confirmation', 'Prévia e confirmação', 'Vista previa y confirmación', 'Vorschau und Bestätigung', 'Aperçu et confirmation'),
    ('Productivity', 'Produtividade', 'Productividad', 'Produktivität', 'Productivité'),
    ('More focus on your work', 'Mais foco no seu trabalho', 'Más foco en su trabajo', 'Mehr Fokus auf Ihre Arbeit', 'Plus de concentration sur votre travail'),
    ('Made for Delphi', 'Feito para Delphi', 'Hecho para Delphi', 'Für Delphi gemacht', 'Conçu pour Delphi'),
    ('Part of your code editor', 'Integrado ao editor de código', 'Integrado en el editor de código', 'Teil Ihres Code-Editors', 'Intégré à l’éditeur de code'),
    ('Code with PURPOSE. Solutions with INTELLIGENCE.', 'Código com PROPÓSITO. Soluções com INTELIGÊNCIA.', 'Código con PROPÓSITO. Soluciones con INTELIGENCIA.', 'Code mit SINN. Lösungen mit INTELLIGENZ.', 'Du code avec un BUT. Des solutions avec INTELLIGENCE.'),
    ('Support and documentation', 'Suporte e documentação', 'Soporte y documentación', 'Support und Dokumentation', 'Support et documentation'),
    ('%s is a product of %s.' + LB + 'Open source under the MIT License.', '%s é um produto da %s.' + LB + 'Código aberto sob a licença MIT.', '%s es un producto de %s.' + LB + 'Código abierto bajo la licencia MIT.', '%s ist ein Produkt von %s.' + LB + 'Open Source unter der MIT-Lizenz.', '%s est un produit de %s.' + LB + 'Code ouvert sous licence MIT.'),
    { stAboutLicFree } ('Open source', 'Código aberto', 'Código abierto', 'Open Source', 'Code ouvert'),
    { stAboutLicSub } ('Free to use, change and share', 'Livre para usar, alterar e compartilhar', 'Libre para usar, modificar y compartir', 'Frei zum Nutzen, Ändern und Weitergeben', 'Libre d''utiliser, de modifier et de partager'),
    { stAboutLicTypeValue } ('MIT License', 'Licença MIT', 'Licencia MIT', 'MIT-Lizenz', 'Licence MIT'),
    { stAboutAllowed } ('Allowed', 'Permitido', 'Permitido', 'Erlaubt', 'Autorisé'),
    { stAboutSourceOpen } ('Open, may be changed', 'Aberto, pode modificar', 'Abierto, modificable', 'Offen, veränderbar', 'Ouvert, modifiable'),
    { stAboutNone } ('None', 'Nenhuma', 'Ninguna', 'Keine', 'Aucune'),
    { stAboutLicenseCloseHint } ('Closes the license text and returns to the About window', 'Fecha o texto da licença e volta à tela Sobre', 'Cierra el texto de la licencia y vuelve a la ventana Acerca de', 'Schließt den Lizenztext und kehrt zum Info-Fenster zurück', 'Ferme le texte de la licence et revient à la fenêtre À propos'),
    { stAboutReport } ('Report a problem', 'Avisar de um problema', 'Informar de un problema', 'Ein Problem melden', 'Signaler un problème'),

    { stLanguage } ('Language:', 'Idioma:', 'Idioma:', 'Sprache:', 'Langue :'),
    { stLanguageAuto } ('Automatic', 'Automático', 'Automático', 'Automatisch', 'Automatique'),
    { stLanguageHint } (
      'Language of the Unit Styler windows. Automatic follows the display language of Windows; when it is not one of the five, English is used.' + LB +
      'The choice is kept with the other rules of this Delphi and applies to the windows opened after you save.',
      'Idioma das janelas do Unit Styler. Automático segue o idioma de exibição do Windows; quando não é um dos cinco, usa inglês.' + LB +
      'A escolha fica guardada com as outras regras deste Delphi e vale para as janelas abertas depois de salvar.',
      'Idioma de las ventanas de Unit Styler. Automático sigue el idioma de visualización de Windows; si no es uno de los cinco, se usa inglés.' + LB +
      'La elección se guarda con las demás reglas de este Delphi y se aplica a las ventanas abiertas después de guardar.',
      'Sprache der Fenster von Unit Styler. Automatisch folgt der Anzeigesprache von Windows; ist sie keine der fünf, wird Englisch verwendet.' + LB +
      'Die Auswahl wird mit den anderen Regeln dieses Delphi gespeichert und gilt für Fenster, die nach dem Speichern geöffnet werden.',
      'Langue des fenêtres de Unit Styler. Automatique suit la langue d’affichage de Windows ; si ce n’est pas l’une des cinq, l’anglais est utilisé.' + LB +
      'Le choix est conservé avec les autres règles de ce Delphi et s’applique aux fenêtres ouvertes après l’enregistrement.'),
    { stMenuBranchHint } ('Uses organization and settings of Unit Styler.', 'Organização de uses e configurações do Unit Styler.',
      'Organización de uses y configuración de Unit Styler.', 'Uses-Organisation und Einstellungen von Unit Styler.',
      'Organisation des uses et paramètres de Unit Styler.'),
    { stMenuOrganizeHint } (
      'Opens the run window to choose the scope, see the preview or organize uses after confirmation.',
      'Abre a execução para escolher o escopo, visualizar a prévia ou organizar uses após confirmação.',
      'Abre la ejecución para elegir el alcance, ver la vista previa u organizar uses tras confirmar.',
      'Öffnet die Ausführung, um den Bereich zu wählen, die Vorschau zu sehen oder Uses nach Bestätigung zu organisieren.',
      'Ouvre l’exécution pour choisir la portée, voir l’aperçu ou organiser les uses après confirmation.'),
    { stMenuSettingsHint } (
      'Opens the rules of Unit Styler and the settings of the open project, without changing code. Also works with no project open.',
      'Abre as regras do Unit Styler e as configurações do projeto aberto, sem alterar o código. Funciona também sem projeto aberto.',
      'Abre las reglas de Unit Styler y la configuración del proyecto abierto, sin cambiar el código. También funciona sin proyecto abierto.',
      'Öffnet die Regeln von Unit Styler und die Einstellungen des geöffneten Projekts, ohne Code zu ändern. Funktioniert auch ohne geöffnetes Projekt.',
      'Ouvre les règles de Unit Styler et les paramètres du projet ouvert, sans modifier le code. Fonctionne aussi sans projet ouvert.'),
    { stMenuAboutHint } ('Shows version, compatibility, license and contact of Unit Styler.',
      'Mostra versão, compatibilidade, licença e contato do Unit Styler.',
      'Muestra versión, compatibilidad, licencia y contacto de Unit Styler.',
      'Zeigt Version, Kompatibilität, Lizenz und Kontakt von Unit Styler.',
      'Affiche la version, la compatibilité, la licence et le contact de Unit Styler.'),
    { stEditorMenuHint } (
      'Opens Organize uses for the unit in the editor: choose the scope, see the preview or apply after confirming.',
      'Abre Organizar uses para a unit do editor: escolha o escopo, veja a prévia ou aplique após confirmar.',
      'Abre Organizar uses para la unit del editor: elija el alcance, vea la vista previa o aplique tras confirmar.',
      'Öffnet Uses organisieren für die Unit im Editor: Bereich wählen, Vorschau ansehen oder nach Bestätigung anwenden.',
      'Ouvre Organiser uses pour la unit de l’éditeur : choisissez la portée, voyez l’aperçu ou appliquez après confirmation.'),
    { stOpenOrganizeError } ('Organize uses could not be opened.', 'Não foi possível abrir Organizar uses.',
      'No se pudo abrir Organizar uses.', 'Uses organisieren konnte nicht geöffnet werden.', 'Impossible d’ouvrir Organiser uses.'),
    { stOpenSettingsError } ('The settings could not be opened.', 'Não foi possível abrir as configurações.',
      'No se pudo abrir la configuración.', 'Die Einstellungen konnten nicht geöffnet werden.', 'Impossible d’ouvrir les paramètres.'),

    { stExecCaption } ('Run', 'Execução', 'Ejecución', 'Ausführung', 'Exécution'),
    { stExecInfoHint } ('Run information: %s', 'Informação da execução: %s', 'Información de la ejecución: %s',
      'Information zur Ausführung: %s', 'Information sur l’exécution : %s'),
    { stCancelHint } (
      'Closes the run window. Applies no new changes and does not undo what was already confirmed. Use Undo in Delphi to revert an earlier run.',
      'Fecha a execução. Não aplica novas alterações e não desfaz o que já foi confirmado. Use Desfazer no Delphi para reverter uma aplicação anterior.',
      'Cierra la ejecución. No aplica nuevos cambios ni deshace lo ya confirmado. Use Deshacer en Delphi para revertir una aplicación anterior.',
      'Schließt die Ausführung. Wendet keine neuen Änderungen an und macht bereits Bestätigtes nicht rückgängig. Verwenden Sie Rückgängig in Delphi, um eine frühere Anwendung zurückzunehmen.',
      'Ferme l’exécution. N’applique aucune nouvelle modification et n’annule pas ce qui a déjà été confirmé. Utilisez Annuler dans Delphi pour revenir sur une application précédente.'),
    { stWhereApply } ('Where to apply', 'Onde aplicar', 'Dónde aplicar', 'Wo anwenden', 'Où appliquer'),
    { stScopeHint } (
      'Chooses the set of units analyzed when you click Apply. Preview always shows only the current unit. Units already open stay edited, unsaved.',
      'Escolhe o conjunto de units que será analisado ao clicar em Aplicar. Prévia sempre mostra apenas a unit atual. As units já abertas permanecem editadas sem salvar.',
      'Elige el conjunto de units que se analizará al hacer clic en Aplicar. La vista previa siempre muestra solo la unit actual. Las units ya abiertas quedan editadas sin guardar.',
      'Wählt die Units, die beim Klick auf Anwenden analysiert werden. Die Vorschau zeigt immer nur die aktuelle Unit. Bereits geöffnete Units bleiben bearbeitet und ungespeichert.',
      'Choisit l’ensemble des units analysées en cliquant sur Appliquer. L’aperçu montre toujours uniquement la unit actuelle. Les units déjà ouvertes restent modifiées, sans enregistrement.'),
    { stScopeNoBatchHint } (
      ' In this version of the package, Open units and All project units still wait for batch support.',
      ' Nesta versão do pacote, Units abertas e Todas do projeto ainda aguardam a implementação do lote.',
      ' En esta versión del paquete, Units abiertas y Todas las del proyecto aún esperan el soporte por lotes.',
      ' In dieser Paketversion warten Geöffnete Units und Alle Projekt-Units noch auf die Stapelverarbeitung.',
      ' Dans cette version du paquet, Units ouvertes et Toutes les units du projet attendent encore le traitement par lot.'),
    { stCountHint } (
      'Number of units in the chosen scope. Only those with proposed changes are modified, after your confirmation. Units in folders or files ignored in Settings are counted apart and never changed.',
      'Quantidade de units pertencentes ao escopo escolhido. Só as que tiverem alterações propostas serão modificadas, depois de sua confirmação. Units em pastas ou arquivos ignorados nas Configurações são contadas à parte e nunca são alteradas.',
      'Cantidad de units del alcance elegido. Solo se modifican las que tengan cambios propuestos, tras su confirmación. Las units en carpetas o archivos ignorados en Configuración se cuentan aparte y nunca se cambian.',
      'Anzahl der Units im gewählten Bereich. Nur Units mit vorgeschlagenen Änderungen werden nach Ihrer Bestätigung geändert. Units in Ordnern oder Dateien, die in den Einstellungen ignoriert werden, werden getrennt gezählt und nie geändert.',
      'Nombre de units dans la portée choisie. Seules celles qui ont des modifications proposées sont modifiées, après votre confirmation. Les units des dossiers ou fichiers ignorés dans les Paramètres sont comptées à part et jamais modifiées.'),
    { stRunPattern } ('Rules in use', 'Padrão de execução', 'Reglas en uso', 'Verwendete Regeln', 'Règles utilisées'),
    { stRunPatternHint } (
      'Summary of the Unit Styler rules in this Delphi. Use Settings to change these rules and the exceptions of this project.',
      'Resumo das regras do Unit Styler neste Delphi. Use Configurações para mudar essas regras e as exceções deste projeto.',
      'Resumen de las reglas de Unit Styler en este Delphi. Use Configuración para cambiar estas reglas y las excepciones de este proyecto.',
      'Zusammenfassung der Regeln von Unit Styler in diesem Delphi. Über Einstellungen ändern Sie diese Regeln und die Ausnahmen dieses Projekts.',
      'Résumé des règles de Unit Styler dans ce Delphi. Utilisez Paramètres pour modifier ces règles et les exceptions de ce projet.'),
    { stStatusHint } (
      'Result of the analysis or of the last run. Only a Yes confirmation allows code to be changed.',
      'Resultado da análise ou da última aplicação. Apenas uma confirmação Sim permite modificar código.',
      'Resultado del análisis o de la última aplicación. Solo una confirmación Sí permite modificar el código.',
      'Ergebnis der Analyse oder der letzten Anwendung. Nur eine Bestätigung mit Ja erlaubt Codeänderungen.',
      'Résultat de l’analyse ou de la dernière application. Seule une confirmation Oui permet de modifier le code.'),
    { stSumOnePerLine } ('One unit per line', 'Uma unit por linha', 'Una unit por línea', 'Eine Unit pro Zeile', 'Une unit par ligne'),
    { stSumWrap } ('Several units per line (%d columns)', 'Várias units por linha (%d colunas)', 'Varias units por línea (%d columnas)',
      'Mehrere Units pro Zeile (%d Spalten)', 'Plusieurs units par ligne (%d colonnes)'),
    { stSumFirstName } ('A–Z by first name', 'A–Z pelo primeiro nome', 'A–Z por el primer nombre', 'A–Z nach erstem Namen', 'A–Z par le premier nom'),
    { stSumFullName } ('A–Z by full name', 'A–Z pelo nome completo', 'A–Z por el nombre completo', 'A–Z nach vollem Namen', 'A–Z par le nom complet'),
    { stSumSpaces } ('%d spaces', '%d espaços', '%d espacios', '%d Leerzeichen', '%d espaces'),
    { stSumGroups } ('With groups', 'Com grupos', 'Con grupos', 'Mit Gruppen', 'Avec groupes'),
    { stSumPriorities } ('With priorities', 'Com prioridades', 'Con prioridades', 'Mit Prioritäten', 'Avec priorités'),
    { stSumBlankBefore } ('Blank line before sections', 'Espaço antes das seções', 'Espacio antes de las secciones',
      'Leerzeile vor Abschnitten', 'Ligne vide avant les sections'),
    { stSumBlankAfter } ('Blank line after sections', 'Espaço depois das seções', 'Espacio después de las secciones',
      'Leerzeile nach Abschnitten', 'Ligne vide après les sections'),
    { stSumNone } ('No organization rules active', 'Sem regras de organização ativas', 'Sin reglas de organización activas',
      'Keine Organisationsregeln aktiv', 'Aucune règle d’organisation active'),
    { stSaveNoteAuto } (
      'Units already open stay unsaved. Only the closed ones are saved.',
      'Units já abertas ficam sem salvar. Somente as fechadas serão salvas.',
      'Las units ya abiertas quedan sin guardar. Solo se guardan las cerradas.',
      'Geöffnete Units bleiben ungespeichert. Nur geschlossene werden gespeichert.',
      'Les units déjà ouvertes ne sont pas enregistrées. Seules les fermées le sont.'),
    { stSaveNoteOpen } (
      'Changed units stay open in the editor, unsaved.',
      'As units alteradas ficarão abertas no editor, sem salvar.',
      'Las units cambiadas quedarán abiertas en el editor, sin guardar.',
      'Geänderte Units bleiben im Editor geöffnet und ungespeichert.',
      'Les units modifiées restent ouvertes dans l’éditeur, sans enregistrement.'),
    { stSummaryHint } (
      'Active rules: %s. Use Settings to see and edit each rule.',
      'Regras ativas deste projeto: %s. Use Configurações para ver e editar cada regra.',
      'Reglas activas: %s. Use Configuración para ver y editar cada regla.',
      'Aktive Regeln: %s. Über Einstellungen sehen und bearbeiten Sie jede Regel.',
      'Règles actives : %s. Utilisez Paramètres pour voir et modifier chaque règle.'),
    { stSaveNoteHint } (
      'Units that were already open are never saved by the tool. Automatic saving applies only to units that were closed before the run.',
      'Units que já estavam abertas nunca são salvas pela ferramenta. A opção de salvamento automático só vale para units que estavam fechadas antes da execução.',
      'Las units que ya estaban abiertas nunca son guardadas por la herramienta. El guardado automático solo vale para las units que estaban cerradas antes de la ejecución.',
      'Bereits geöffnete Units werden vom Werkzeug nie gespeichert. Das automatische Speichern gilt nur für Units, die vor der Ausführung geschlossen waren.',
      'Les units déjà ouvertes ne sont jamais enregistrées par l’outil. L’enregistrement automatique ne vaut que pour les units fermées avant l’exécution.'),
    { stCountMany } ('%d units will be processed', '%d units serão processadas', '%d units se procesarán',
      '%d Units werden verarbeitet', '%d units seront traitées'),
    { stCountOne } ('1 unit will be processed', '1 unit será processada', '1 unit se procesará',
      '1 Unit wird verarbeitet', '1 unit sera traitée'),
    { stIgnoredOne } (' · 1 ignored', ' · 1 ignorada', ' · 1 ignorada', ' · 1 ignoriert', ' · 1 ignorée'),
    { stIgnoredMany } (' · %d ignored', ' · %d ignoradas', ' · %d ignoradas', ' · %d ignoriert', ' · %d ignorées'),
    { stInterrupt } ('Stop', 'Interromper', 'Interrumpir', 'Stoppen', 'Interrompre'),
    { stProgress } ('%s %d of %d...', '%s %d de %d...', '%s %d de %d...', '%s %d von %d...', '%s %d sur %d...'),
    { stAnalyzing } ('Analyzing', 'Analisando', 'Analizando', 'Analysiere', 'Analyse'),
    { stApplying } ('Applying', 'Aplicando', 'Aplicando', 'Wende an', 'Application'),
    { stAnalysisStopped } (
      'Analysis stopped on request; no unit was changed.',
      'Análise interrompida a pedido; nenhuma unit foi alterada.',
      'Análisis interrumpido a petición; no se cambió ninguna unit.',
      'Analyse auf Wunsch abgebrochen; keine Unit wurde geändert.',
      'Analyse interrompue à la demande ; aucune unit n’a été modifiée.'),
    { stNoUnitInScope } ('No unit in the chosen scope.', 'Nenhuma unit no escopo escolhido.', 'Ninguna unit en el alcance elegido.',
      'Keine Unit im gewählten Bereich.', 'Aucune unit dans la portée choisie.'),
    { stNoCurrentUnit } ('No current unit to preview.', 'Nenhuma unit atual para visualizar.', 'No hay unit actual para ver.',
      'Keine aktuelle Unit für die Vorschau.', 'Aucune unit actuelle à afficher.'),
    { stCurrentIgnored } (
      'The current unit is in the ignored list and will not be changed.',
      'A unit atual está na lista de ignorados e não será alterada.',
      'La unit actual está en la lista de ignorados y no se cambiará.',
      'Die aktuelle Unit steht in der Ignorierliste und wird nicht geändert.',
      'La unit actuelle est dans la liste des ignorés et ne sera pas modifiée.'),
    { stPreviewOf } ('Preview: %s', 'Prévia: %s', 'Vista previa: %s', 'Vorschau: %s', 'Aperçu : %s'),
    { stDiagLine } ('Line %d: %s', 'Linha %d: %s', 'Línea %d: %s', 'Zeile %d: %s', 'Ligne %d : %s'),
    { stBeforeHint } (
      'Current code of the unit in the editor, unsaved changes included. Read-only: this panel does not change the source.',
      'Código atual da unit no editor, inclusive alterações não salvas. Somente leitura: este painel não altera o fonte.',
      'Código actual de la unit en el editor, incluidos los cambios sin guardar. Solo lectura: este panel no cambia el fuente.',
      'Aktueller Code der Unit im Editor, einschließlich ungespeicherter Änderungen. Nur lesbar: Dieses Feld ändert den Quelltext nicht.',
      'Code actuel de la unit dans l’éditeur, modifications non enregistrées comprises. Lecture seule : ce panneau ne modifie pas le source.'),
    { stAfterHint } (
      'How the unit will look if the organization is applied. A read-only proposal; closing this window applies nothing.',
      'Como a unit ficará se a organização for aplicada. É uma proposta somente leitura; fechar esta janela não aplica alterações.',
      'Cómo quedará la unit si se aplica la organización. Es una propuesta de solo lectura; cerrar esta ventana no aplica cambios.',
      'So sieht die Unit aus, wenn die Organisation angewendet wird. Ein nur lesbarer Vorschlag; das Schließen dieses Fensters wendet nichts an.',
      'Aspect de la unit si l’organisation est appliquée. Proposition en lecture seule ; fermer cette fenêtre n’applique rien.'),
    { stBeforeAfter } ('Before / After', 'Antes / Depois', 'Antes / Después', 'Vorher / Nachher', 'Avant / Après'),
    { stDiagnosticsHint } (
      'Explanations of the parts kept as they are or that could not be organized safely, such as directives and loose comments.',
      'Explicações dos trechos preservados ou que não puderam ser organizados com segurança, como diretivas e comentários soltos.',
      'Explicaciones de los tramos conservados o que no pudieron organizarse con seguridad, como directivas y comentarios sueltos.',
      'Erläuterungen zu Stellen, die beibehalten wurden oder nicht sicher organisiert werden konnten, etwa Direktiven und lose Kommentare.',
      'Explications des parties conservées ou qui n’ont pas pu être organisées en toute sécurité, comme les directives et les commentaires isolés.'),
    { stSplitterHint } (
      'Drag to adjust the width of the Before and After panels. The window opens with the divider in the middle and keeps the proportion when resized or maximized.',
      'Arraste para ajustar a largura dos painéis Antes e Depois. A janela abre com o divisor no meio e mantém a proporção ao redimensionar ou maximizar.',
      'Arrastre para ajustar el ancho de los paneles Antes y Después. La ventana se abre con el divisor en el centro y mantiene la proporción al redimensionar o maximizar.',
      'Ziehen, um die Breite der Felder Vorher und Nachher anzupassen. Das Fenster öffnet mit dem Trenner in der Mitte und behält das Verhältnis beim Ändern der Größe oder Maximieren.',
      'Faites glisser pour ajuster la largeur des panneaux Avant et Après. La fenêtre s’ouvre avec le séparateur au milieu et conserve la proportion au redimensionnement ou à l’agrandissement.'),
    { stPreviewError } ('The preview could not be built.', 'Não foi possível montar a prévia.', 'No se pudo generar la vista previa.',
      'Die Vorschau konnte nicht erstellt werden.', 'Impossible de générer l’aperçu.'),
    { stSaveSettingsError } ('The settings could not be saved.', 'Não foi possível salvar as configurações.', 'No se pudo guardar la configuración.',
      'Die Einstellungen konnten nicht gespeichert werden.', 'Impossible d’enregistrer les paramètres.'),
    { stConfirmCount } ('Apply changes to %d unit(s)?', 'Aplicar alterações em %d unit(s)?', '¿Aplicar cambios en %d unit(s)?',
      'Änderungen auf %d Unit(s) anwenden?', 'Appliquer les modifications à %d unit(s) ?'),
    { stConfirmAuto } (
      'Only the units that were closed are saved. Those already open stay unsaved.',
      'Salvar somente as units que estavam fechadas. As já abertas ficam sem salvar.',
      'Se guardan solo las units que estaban cerradas. Las ya abiertas quedan sin guardar.',
      'Nur Units, die geschlossen waren, werden gespeichert. Bereits geöffnete bleiben ungespeichert.',
      'Seules les units qui étaient fermées sont enregistrées. Celles déjà ouvertes ne le sont pas.'),
    { stConfirmOpen } (
      'Changed units stay open, unsaved.',
      'As units alteradas ficarão abertas, sem salvar.',
      'Las units cambiadas quedarán abiertas, sin guardar.',
      'Geänderte Units bleiben geöffnet und ungespeichert.',
      'Les units modifiées restent ouvertes, sans enregistrement.'),
    { stReportCaption } ('Warnings and errors of the run', 'Avisos e erros da execução', 'Avisos y errores de la ejecución',
      'Warnungen und Fehler der Ausführung', 'Avertissements et erreurs de l’exécution'),
    { stReportHint } (
      'Report of this run: only warnings and errors, with the unit involved and the reason. The text can be selected and copied.',
      'Relatório desta execução: mostra apenas avisos e erros, com a unit envolvida e o motivo. O texto pode ser selecionado e copiado.',
      'Informe de esta ejecución: solo avisos y errores, con la unit afectada y el motivo. El texto se puede seleccionar y copiar.',
      'Bericht dieser Ausführung: nur Warnungen und Fehler, mit betroffener Unit und Grund. Der Text kann markiert und kopiert werden.',
      'Rapport de cette exécution : uniquement les avertissements et erreurs, avec la unit concernée et le motif. Le texte peut être sélectionné et copié.'),
    { stCopy } ('Copy', 'Copiar', 'Copiar', 'Kopieren', 'Copier'),
    { stCopyHint } (
      'Copies the whole report to the clipboard, to analyze or share the warnings and errors.',
      'Copia o relatório inteiro para a área de transferência, para analisar ou compartilhar os avisos e erros.',
      'Copia el informe completo al portapapeles, para analizar o compartir los avisos y errores.',
      'Kopiert den gesamten Bericht in die Zwischenablage, um Warnungen und Fehler zu prüfen oder weiterzugeben.',
      'Copie tout le rapport dans le presse-papiers, pour analyser ou partager les avertissements et erreurs.'),
    { stReportCloseHint } (
      'Closes the report and returns to the run window. Does not undo changes already applied.',
      'Fecha o relatório e retorna à execução. Não desfaz as alterações já aplicadas.',
      'Cierra el informe y vuelve a la ejecución. No deshace los cambios ya aplicados.',
      'Schließt den Bericht und kehrt zur Ausführung zurück. Macht bereits angewendete Änderungen nicht rückgängig.',
      'Ferme le rapport et revient à l’exécution. N’annule pas les modifications déjà appliquées.'),
    { stBatchUnavailable } (
      'Batch runs are not available in this version of the integration.',
      'Execução em lote ainda não disponível nesta versão da integração.',
      'La ejecución por lotes aún no está disponible en esta versión de la integración.',
      'Die Stapelausführung ist in dieser Version der Integration noch nicht verfügbar.',
      'L’exécution par lot n’est pas encore disponible dans cette version de l’intégration.'),
    { stIssueUnitError } (
      '%s | Error | %s The unit was not analyzed or changed.',
      '%s | Erro | %s A unit não foi analisada nem alterada.',
      '%s | Error | %s La unit no fue analizada ni cambiada.',
      '%s | Fehler | %s Die Unit wurde weder analysiert noch geändert.',
      '%s | Erreur | %s La unit n’a été ni analysée ni modifiée.'),
    { stIssueWarning } ('%s | Warning | %s (line %d)', '%s | Aviso | %s (linha %d)', '%s | Aviso | %s (línea %d)',
      '%s | Warnung | %s (Zeile %d)', '%s | Avertissement | %s (ligne %d)'),
    { stIssueStopped } (
      'Run | Warning | Stopped on request: %d of %d units changed. The others stayed as they were.',
      'Execução | Aviso | Interrompida a pedido: %d de %d units alteradas. As demais ficaram como estavam.',
      'Ejecución | Aviso | Interrumpida a petición: %d de %d units cambiadas. Las demás quedaron como estaban.',
      'Ausführung | Warnung | Auf Wunsch abgebrochen: %d von %d Units geändert. Die übrigen blieben unverändert.',
      'Exécution | Avertissement | Interrompue à la demande : %d units sur %d modifiées. Les autres sont restées telles quelles.'),
    { stIssueApplyError } (
      '%s | Error | %s Check the state of this unit.',
      '%s | Erro | %s Confira o estado dessa unit.',
      '%s | Error | %s Compruebe el estado de esta unit.',
      '%s | Fehler | %s Prüfen Sie den Zustand dieser Unit.',
      '%s | Erreur | %s Vérifiez l’état de cette unit.'),
    { stBackupHint } (
      'Before changing, each unit was copied as it was saved on disk to %s. To go back, copy the contents of that folder over the project folder.',
      'Antes de alterar, cada unit foi copiada como estava gravada no disco para %s. Para voltar atrás, copie o conteúdo dessa pasta sobre a pasta do projeto.',
      'Antes de cambiar, cada unit se copió tal como estaba guardada en disco en %s. Para volver atrás, copie el contenido de esa carpeta sobre la carpeta del proyecto.',
      'Vor der Änderung wurde jede Unit so, wie sie auf der Festplatte gespeichert war, nach %s kopiert. Zum Zurückgehen kopieren Sie den Inhalt dieses Ordners über den Projektordner.',
      'Avant modification, chaque unit a été copiée telle qu’elle était enregistrée sur le disque vers %s. Pour revenir en arrière, copiez le contenu de ce dossier sur le dossier du projet.'),
    { stDoneDemo } ('Demonstration: changes in memory only.', 'Demonstração: alterações somente em memória.',
      'Demostración: cambios solo en memoria.', 'Demonstration: Änderungen nur im Speicher.', 'Démonstration : modifications en mémoire uniquement.'),
    { stDoneFailed } (
      '%d units changed, %d with errors; see the report.',
      '%d units alteradas, %d com erro; consulte o relatório.',
      '%d units cambiadas, %d con error; consulte el informe.',
      '%d Units geändert, %d mit Fehlern; siehe Bericht.',
      '%d units modifiées, %d en erreur ; consultez le rapport.'),
    { stDoneBackup } ('%d units changed. Originals in %s.', '%d units alteradas. Originais em %s.', '%d units cambiadas. Originales en %s.',
      '%d Units geändert. Originale in %s.', '%d units modifiées. Originaux dans %s.'),
    { stDoneAuto } (
      '%d units changed. Those already open stay unsaved.',
      '%d units alteradas. As já abertas ficam sem salvar.',
      '%d units cambiadas. Las ya abiertas quedan sin guardar.',
      '%d Units geändert. Bereits geöffnete bleiben ungespeichert.',
      '%d units modifiées. Celles déjà ouvertes ne sont pas enregistrées.'),
    { stDoneOpen } (
      '%d units changed, open in the editor and unsaved.',
      '%d units alteradas, abertas no editor sem salvar.',
      '%d units cambiadas, abiertas en el editor sin guardar.',
      '%d Units geändert, im Editor geöffnet und ungespeichert.',
      '%d units modifiées, ouvertes dans l’éditeur sans enregistrement.'),
    { stRunAborted } ('Run stopped; see the report.', 'Execução interrompida; consulte o relatório.', 'Ejecución interrumpida; consulte el informe.',
      'Ausführung abgebrochen; siehe Bericht.', 'Exécution interrompue ; consultez le rapport.'),
    { stIssueError } ('%s | Error | %s', '%s | Erro | %s', '%s | Error | %s', '%s | Fehler | %s', '%s | Erreur | %s'),
    { stIssueRunError } ('Run | Error | %s', 'Execução | Erro | %s', 'Ejecución | Error | %s', 'Ausführung | Fehler | %s', 'Exécution | Erreur | %s'),
    { stIssueAppliedBefore } (
      'Units changed before the stop: %d.',
      'Units alteradas antes da interrupção: %d.',
      'Units cambiadas antes de la interrupción: %d.',
      'Vor dem Abbruch geänderte Units: %d.',
      'Units modifiées avant l’interruption : %d.'),

    { stSetTitle } ('Styler settings', 'Configurações do Styler', 'Configuración de Styler', 'Styler-Einstellungen', 'Paramètres de Styler'),
    { stSetTitleHint } (
      'Set up organization, what stays in place and the saving of closed units.',
      'Configure organização, preservação de dependências e salvamento das units fechadas.',
      'Configure la organización, lo que se conserva y el guardado de las units cerradas.',
      'Legen Sie Organisation, Beizubehaltendes und das Speichern geschlossener Units fest.',
      'Configurez l’organisation, ce qui reste en place et l’enregistrement des units fermées.'),
    { stSetSubtitle } ('Rules of Unit Styler and exceptions of this project.', 'Regras do Unit Styler e exceções deste projeto.',
      'Reglas de Unit Styler y excepciones de este proyecto.', 'Regeln von Unit Styler und Ausnahmen dieses Projekts.',
      'Règles de Unit Styler et exceptions de ce projet.'),
    { stSetSubtitleNoProject } ('Rules of Unit Styler. No project open.', 'Regras do Unit Styler. Nenhum projeto aberto.',
      'Reglas de Unit Styler. Ningún proyecto abierto.', 'Regeln von Unit Styler. Kein Projekt geöffnet.',
      'Règles de Unit Styler. Aucun projet ouvert.'),
    { stSetSubtitleHint } (
      'Formatting, priorities, groups and saving are rules of Unit Styler: they apply to every project in this Delphi.' + LB +
      'The Project settings group applies only to the open project. Everything is kept in your Windows profile; the demonstration keeps it in memory only.',
      'Formatação, prioridades, grupos e salvamento são regras do Unit Styler: valem para todos os projetos neste Delphi.' + LB +
      'O grupo Configurações do projeto vale só para o projeto aberto. Tudo fica guardado no seu perfil do Windows; a demonstração guarda somente em memória.',
      'Formato, prioridades, grupos y guardado son reglas de Unit Styler: valen para todos los proyectos en este Delphi.' + LB +
      'El grupo Configuración del proyecto vale solo para el proyecto abierto. Todo se guarda en su perfil de Windows; la demostración lo guarda solo en memoria.',
      'Formatierung, Prioritäten, Gruppen und Speichern sind Regeln von Unit Styler: Sie gelten für alle Projekte in diesem Delphi.' + LB +
      'Die Gruppe Projekteinstellungen gilt nur für das geöffnete Projekt. Alles liegt in Ihrem Windows-Profil; die Demonstration behält es nur im Speicher.',
      'Mise en forme, priorités, groupes et enregistrement sont des règles de Unit Styler : elles valent pour tous les projets de ce Delphi.' + LB +
      'Le groupe Paramètres du projet ne vaut que pour le projet ouvert. Tout est conservé dans votre profil Windows ; la démonstration ne le garde qu’en mémoire.'),
    { stGrpFormatting } ('Formatting', 'Formatação', 'Formato', 'Formatierung', 'Mise en forme'),
    { stGrpFormattingHint } (
      'Rules of Unit Styler, the same for every project in this Delphi: layout and order of the uses dependencies and spacing of the allowed headers.',
      'Regras do Unit Styler, iguais para todos os projetos neste Delphi: apresentação e ordem das dependências do uses e espaçamento dos cabeçalhos permitidos.',
      'Reglas de Unit Styler, iguales para todos los proyectos en este Delphi: presentación y orden de las dependencias del uses y espaciado de los encabezados permitidos.',
      'Regeln von Unit Styler, gleich für alle Projekte in diesem Delphi: Darstellung und Reihenfolge der Uses-Abhängigkeiten und Abstände der erlaubten Überschriften.',
      'Règles de Unit Styler, identiques pour tous les projets de ce Delphi : présentation et ordre des dépendances du uses et espacement des en-têtes autorisés.'),
    { stGrpGroups } ('Priorities and groups', 'Prioridades e grupos', 'Prioridades y grupos', 'Prioritäten und Gruppen', 'Priorités et groupes'),
    { stGrpGroupsHint } (
      'Rules of Unit Styler, the same for every project in this Delphi: which dependencies come first and how the others are arranged in groups.',
      'Regras do Unit Styler, iguais para todos os projetos neste Delphi: quais dependências vêm primeiro e como organizar as restantes por grupos.',
      'Reglas de Unit Styler, iguales para todos los proyectos en este Delphi: qué dependencias van primero y cómo organizar las demás por grupos.',
      'Regeln von Unit Styler, gleich für alle Projekte in diesem Delphi: welche Abhängigkeiten zuerst kommen und wie die übrigen in Gruppen geordnet werden.',
      'Règles de Unit Styler, identiques pour tous les projets de ce Delphi : quelles dépendances viennent en premier et comment organiser les autres par groupes.'),
    { stGrpProject } ('Project settings', 'Configurações do projeto', 'Configuración del proyecto', 'Projekteinstellungen', 'Paramètres du projet'),
    { stGrpProjectHint } (
      'Applies only to the open project and is kept separately for each project, the same in any Delphi version and even if the project changes folder:' + LB +
      'which uses, dependencies, folders and files must stay untouched. The other rules of this window apply to every project.',
      'Vale somente para o projeto aberto e fica guardado separadamente para cada projeto, igual em qualquer versão do Delphi e mesmo que o projeto mude de pasta:' + LB +
      'quais uses, dependências, pastas e arquivos devem permanecer intactos. As demais regras desta janela valem para todos os projetos.',
      'Vale solo para el proyecto abierto y se guarda por separado para cada proyecto, igual en cualquier versión de Delphi y aunque el proyecto cambie de carpeta:' + LB +
      'qué uses, dependencias, carpetas y archivos deben quedar intactos. Las demás reglas de esta ventana valen para todos los proyectos.',
      'Gilt nur für das geöffnete Projekt und wird für jedes Projekt getrennt gespeichert, gleich in jeder Delphi-Version und auch wenn das Projekt den Ordner wechselt:' + LB +
      'welche Uses, Abhängigkeiten, Ordner und Dateien unverändert bleiben müssen. Die übrigen Regeln dieses Fensters gelten für alle Projekte.',
      'Ne vaut que pour le projet ouvert et est conservé séparément pour chaque projet, identique dans toute version de Delphi et même si le projet change de dossier :' + LB +
      'quels uses, dépendances, dossiers et fichiers doivent rester intacts. Les autres règles de cette fenêtre valent pour tous les projets.'),
    { stGrpProjectNone } ('Project settings (no project open)', 'Configurações do projeto (nenhum projeto aberto)',
      'Configuración del proyecto (ningún proyecto abierto)', 'Projekteinstellungen (kein Projekt geöffnet)',
      'Paramètres du projet (aucun projet ouvert)'),
    { stNoProjectHint } (
      'No project open: open a project in Delphi to edit its settings. The rules of Unit Styler, in the rest of this window, can be edited and saved normally.',
      'Nenhum projeto aberto: abra um projeto no Delphi para editar as configurações dele. As regras do Unit Styler, no restante desta janela, podem ser editadas e salvas normalmente.',
      'Ningún proyecto abierto: abra un proyecto en Delphi para editar su configuración. Las reglas de Unit Styler, en el resto de esta ventana, se pueden editar y guardar normalmente.',
      'Kein Projekt geöffnet: Öffnen Sie ein Projekt in Delphi, um dessen Einstellungen zu bearbeiten. Die Regeln von Unit Styler im übrigen Fenster können normal bearbeitet und gespeichert werden.',
      'Aucun projet ouvert : ouvrez un projet dans Delphi pour modifier ses paramètres. Les règles de Unit Styler, dans le reste de cette fenêtre, peuvent être modifiées et enregistrées normalement.'),
    { stEditPriorities } ('Edit priorities...', 'Editar prioridades...', 'Editar prioridades...', 'Prioritäten bearbeiten...', 'Modifier les priorités...'),
    { stEditPrioritiesHint } (
      'Opens the list of names or prefixes whose order defines which dependencies come first. One item per line; OK keeps the edit in this window, and Save stores it.',
      'Abre a lista de nomes ou prefixos cuja ordem define quais dependências vêm primeiro. Um item por linha; OK mantém a edição nesta janela, e Salvar guarda no projeto.',
      'Abre la lista de nombres o prefijos cuyo orden define qué dependencias van primero. Un elemento por línea; OK mantiene la edición en esta ventana y Guardar la almacena.',
      'Öffnet die Liste der Namen oder Präfixe, deren Reihenfolge bestimmt, welche Abhängigkeiten zuerst kommen. Ein Eintrag pro Zeile; OK behält die Bearbeitung in diesem Fenster, Speichern sichert sie.',
      'Ouvre la liste des noms ou préfixes dont l’ordre définit quelles dépendances viennent en premier. Un élément par ligne ; OK conserve la modification dans cette fenêtre et Enregistrer la sauvegarde.'),
    { stEditGroups } ('Edit groups...', 'Editar grupos...', 'Editar grupos...', 'Gruppen bearbeiten...', 'Modifier les groupes...'),
    { stEditGroupsHint } (
      'Opens the dependency groups and their matching rules. Enter names or prefixes separated by semicolons and use the buttons to set the order of the groups.',
      'Abre os grupos de dependências e suas regras de correspondência. Cadastre nomes ou prefixos separados por ponto e vírgula e use os botões para definir a ordem dos grupos.',
      'Abre los grupos de dependencias y sus reglas de correspondencia. Indique nombres o prefijos separados por punto y coma y use los botones para definir el orden de los grupos.',
      'Öffnet die Abhängigkeitsgruppen und ihre Zuordnungsregeln. Geben Sie Namen oder Präfixe durch Semikolon getrennt ein und legen Sie mit den Schaltflächen die Reihenfolge der Gruppen fest.',
      'Ouvre les groupes de dépendances et leurs règles de correspondance. Saisissez des noms ou préfixes séparés par des points-virgules et utilisez les boutons pour définir l’ordre des groupes.'),
    { stUngrouped } ('No group:', 'Sem grupo:', 'Sin grupo:', 'Ohne Gruppe:', 'Sans groupe :'),
    { stUngroupedHint } (
      'Chooses where the units that match no group go. The option only acts when Organize by groups is checked.',
      'Escolhe onde ficam as units que não correspondem a nenhum grupo. A opção só atua quando Organizar por grupos está marcada.',
      'Elige dónde quedan las units que no corresponden a ningún grupo. La opción solo actúa cuando Organizar por grupos está marcada.',
      'Legt fest, wohin Units kommen, die zu keiner Gruppe passen. Die Option wirkt nur, wenn Nach Gruppen ordnen aktiviert ist.',
      'Choisit où vont les units qui ne correspondent à aucun groupe. L’option n’agit que si Organiser par groupes est cochée.'),
    { stPosFirst } ('At the start', 'No início', 'Al inicio', 'Am Anfang', 'Au début'),
    { stPosLast } ('At the end', 'No final', 'Al final', 'Am Ende', 'À la fin'),
    { stPositionHint } (
      'At the start: puts the units without a group before the registered groups. At the end: puts them after. Priority units still come first, and preserved units are not moved.',
      'No início: coloca as units sem grupo antes dos grupos cadastrados. No final: coloca depois deles. Units prioritárias continuam primeiro, e units preservadas não são movidas.',
      'Al inicio: coloca las units sin grupo antes de los grupos registrados. Al final: las coloca después. Las units prioritarias siguen primero y las conservadas no se mueven.',
      'Am Anfang: setzt Units ohne Gruppe vor die eingetragenen Gruppen. Am Ende: setzt sie dahinter. Prioritäts-Units bleiben vorn, beibehaltene Units werden nicht verschoben.',
      'Au début : place les units sans groupe avant les groupes enregistrés. À la fin : les place après. Les units prioritaires restent en premier et les units conservées ne sont pas déplacées.'),
    { stProtectedButton } ('Protected units...', 'Units protegidas...', 'Units protegidas...', 'Geschützte Units...', 'Units protégées...'),
    { stProtectedButtonHint } (
      'Advanced setting. Opens the list of units the tool never moves, in any project.' + LB +
      'In Delphi, when two units declare the same name, the one that comes last in the uses wins; changing the order of system units' + LB +
      'can make the project stop compiling or change behavior. That is why Winapi, System, Vcl, FMX and Data already come in the list.' + LB +
      'A protected unit stays where it is and no other unit crosses it; the units between two protected ones are organized right there.',
      'Configuração avançada. Abre a lista de units que a ferramenta nunca muda de lugar, em nenhum projeto.' + LB +
      'No Delphi, quando duas units declaram o mesmo nome, vale a que aparece por último no uses; trocar a ordem das units de sistema' + LB +
      'pode fazer o projeto deixar de compilar ou mudar de comportamento. Por isso Winapi, System, Vcl, FMX e Data já vêm na lista.' + LB +
      'Unit protegida fica onde está e nenhuma outra passa por cima dela; as units entre duas protegidas são organizadas ali mesmo.',
      'Configuración avanzada. Abre la lista de units que la herramienta nunca cambia de lugar, en ningún proyecto.' + LB +
      'En Delphi, cuando dos units declaran el mismo nombre, vale la que aparece última en el uses; cambiar el orden de las units de sistema' + LB +
      'puede hacer que el proyecto deje de compilar o cambie de comportamiento. Por eso Winapi, System, Vcl, FMX y Data ya vienen en la lista.' + LB +
      'Una unit protegida queda donde está y ninguna otra la cruza; las units entre dos protegidas se organizan allí mismo.',
      'Erweiterte Einstellung. Öffnet die Liste der Units, die das Werkzeug in keinem Projekt verschiebt.' + LB +
      'Wenn in Delphi zwei Units denselben Namen deklarieren, gilt die im Uses zuletzt genannte; eine geänderte Reihenfolge der System-Units' + LB +
      'kann dazu führen, dass das Projekt nicht mehr kompiliert oder sich anders verhält. Deshalb stehen Winapi, System, Vcl, FMX und Data bereits in der Liste.' + LB +
      'Eine geschützte Unit bleibt an ihrem Platz und keine andere wandert an ihr vorbei; Units zwischen zwei geschützten werden dort geordnet.',
      'Paramètre avancé. Ouvre la liste des units que l’outil ne déplace jamais, dans aucun projet.' + LB +
      'Dans Delphi, quand deux units déclarent le même nom, c’est la dernière du uses qui l’emporte ; changer l’ordre des units système' + LB +
      'peut empêcher le projet de compiler ou modifier son comportement. C’est pourquoi Winapi, System, Vcl, FMX et Data figurent déjà dans la liste.' + LB +
      'Une unit protégée reste où elle est et aucune autre ne la franchit ; les units entre deux protégées sont organisées sur place.'),
    { stExcludeInterfaceHint } (
      'Interface is the part of the unit with declarations other units can use.' + LB +
      'Checked: keeps the uses between interface and implementation untouched, with no change of order, groups or indentation.' + LB +
      'It also ignores the blank line options in that section. No dependency is removed.' + LB +
      'Unchecked: allows this uses to be organized by the chosen rules.',
      'Interface é a parte da unit com declarações que podem ser usadas por outras units.' + LB +
      'Marcada: mantém intacto o uses entre interface e implementation, sem mudar ordem, grupos ou indentação.' + LB +
      'Também ignora as opções de linhas em branco nessa seção. Nenhuma dependência é removida.' + LB +
      'Desmarcada: permite organizar esse uses conforme as regras escolhidas.',
      'Interface es la parte de la unit con declaraciones que otras units pueden usar.' + LB +
      'Marcada: mantiene intacto el uses entre interface e implementation, sin cambiar orden, grupos ni sangría.' + LB +
      'También ignora las opciones de líneas en blanco en esa sección. No se elimina ninguna dependencia.' + LB +
      'Desmarcada: permite organizar ese uses según las reglas elegidas.',
      'Interface ist der Teil der Unit mit Deklarationen, die andere Units verwenden können.' + LB +
      'Aktiviert: Lässt das Uses zwischen interface und implementation unverändert, ohne Reihenfolge, Gruppen oder Einzug zu ändern.' + LB +
      'Auch die Leerzeilen-Optionen werden in diesem Abschnitt ignoriert. Keine Abhängigkeit wird entfernt.' + LB +
      'Deaktiviert: Dieses Uses darf nach den gewählten Regeln organisiert werden.',
      'Interface est la partie de la unit dont les déclarations peuvent être utilisées par d’autres units.' + LB +
      'Cochée : laisse intact le uses entre interface et implementation, sans changer l’ordre, les groupes ni l’indentation.' + LB +
      'Les options de lignes vides sont aussi ignorées dans cette section. Aucune dépendance n’est supprimée.' + LB +
      'Décochée : permet d’organiser ce uses selon les règles choisies.'),
    { stExcludeImplementationHint } (
      'Implementation is the part of the unit with the code of its routines.' + LB +
      'Checked: keeps the uses that comes after implementation untouched, with no change of order, groups or indentation.' + LB +
      'It also ignores the blank line options in that section. No dependency is removed.' + LB +
      'Unchecked: allows this uses to be organized by the chosen rules.',
      'Implementation é a parte da unit com o código de implementação das rotinas.' + LB +
      'Marcada: mantém intacto o uses que aparece depois de implementation, sem mudar ordem, grupos ou indentação.' + LB +
      'Também ignora as opções de linhas em branco nessa seção. Nenhuma dependência é removida.' + LB +
      'Desmarcada: permite organizar esse uses conforme as regras escolhidas.',
      'Implementation es la parte de la unit con el código de sus rutinas.' + LB +
      'Marcada: mantiene intacto el uses que aparece después de implementation, sin cambiar orden, grupos ni sangría.' + LB +
      'También ignora las opciones de líneas en blanco en esa sección. No se elimina ninguna dependencia.' + LB +
      'Desmarcada: permite organizar ese uses según las reglas elegidas.',
      'Implementation ist der Teil der Unit mit dem Code ihrer Routinen.' + LB +
      'Aktiviert: Lässt das Uses nach implementation unverändert, ohne Reihenfolge, Gruppen oder Einzug zu ändern.' + LB +
      'Auch die Leerzeilen-Optionen werden in diesem Abschnitt ignoriert. Keine Abhängigkeit wird entfernt.' + LB +
      'Deaktiviert: Dieses Uses darf nach den gewählten Regeln organisiert werden.',
      'Implementation est la partie de la unit qui contient le code de ses routines.' + LB +
      'Cochée : laisse intact le uses situé après implementation, sans changer l’ordre, les groupes ni l’indentation.' + LB +
      'Les options de lignes vides sont aussi ignorées dans cette section. Aucune dépendance n’est supprimée.' + LB +
      'Décochée : permet d’organiser ce uses selon les règles choisies.'),
    { stPreserveButton } ('Preserve units...', 'Preservar units...', 'Conservar units...', 'Units beibehalten...', 'Conserver units...'),
    { stPreserveButtonHint } (
      'Opens the list of units that must not be moved when the uses is organized.' + LB +
      'Enter one name or prefix per line, for example: MyApp.Core or MyApp.*.',
      'Abre a lista de units que não devem ser movidas na organização do uses.' + LB +
      'Informe um nome ou prefixo por linha, por exemplo: MinhaApp.Core ou MinhaApp.*.',
      'Abre la lista de units que no deben moverse al organizar el uses.' + LB +
      'Indique un nombre o prefijo por línea, por ejemplo: MiApp.Core o MiApp.*.',
      'Öffnet die Liste der Units, die beim Organisieren des Uses nicht verschoben werden dürfen.' + LB +
      'Geben Sie einen Namen oder ein Präfix pro Zeile ein, zum Beispiel: MyApp.Core oder MyApp.*.',
      'Ouvre la liste des units qui ne doivent pas être déplacées lors de l’organisation du uses.' + LB +
      'Saisissez un nom ou un préfixe par ligne, par exemple : MonApp.Core ou MonApp.*.'),
    { stIgnoreButton } ('Ignore folders...', 'Ignorar pastas...', 'Ignorar carpetas...', 'Ordner ignorieren...', 'Ignorer dossiers...'),
    { stIgnoreButtonHint } (
      'Opens the list of project folders and files the tool never analyzes or changes, such as third-party libraries.' + LB +
      'It applies to every scope, Current unit included. Different from Preserve units, which keeps one dependency fixed inside the uses.',
      'Abre a lista de pastas e arquivos do projeto que a ferramenta nunca analisa nem altera, como bibliotecas de terceiros.' + LB +
      'Vale para todos os escopos, inclusive Unit atual. Diferente de Preservar units, que mantém fixa uma dependência dentro do uses.',
      'Abre la lista de carpetas y archivos del proyecto que la herramienta nunca analiza ni cambia, como bibliotecas de terceros.' + LB +
      'Vale para todos los alcances, incluida Unit actual. Distinto de Conservar units, que mantiene fija una dependencia dentro del uses.',
      'Öffnet die Liste der Projektordner und -dateien, die das Werkzeug nie analysiert oder ändert, etwa Bibliotheken von Drittanbietern.' + LB +
      'Gilt für jeden Bereich, auch für Aktuelle Unit. Anders als Units beibehalten, das eine Abhängigkeit innerhalb des Uses festhält.',
      'Ouvre la liste des dossiers et fichiers du projet que l’outil n’analyse ni ne modifie jamais, comme les bibliothèques tierces.' + LB +
      'Vaut pour toutes les portées, Unit actuelle comprise. Différent de Conserver units, qui garde une dépendance fixe dans le uses.'),
    { stCleanButton } ('Clean backups...', 'Limpar backups...', 'Limpiar copias...', 'Backups löschen...', 'Nettoyer les copies...'),
    { stCleanButtonHint } (
      'Shows how many backup copies Unit Styler left in the .backup folder of this project and how much space they take, and lets you delete them.' + LB +
      'Nothing is deleted on opening: you have to click Delete. Only the folders created by Unit Styler, with date and time in the name, are removed;' + LB +
      'anything else kept in .backup stays where it is. The units of the project are not touched.',
      'Mostra quantas cópias de segurança o Unit Styler deixou na pasta .backup deste projeto e quanto espaço ocupam, e permite apagá-las.' + LB +
      'Nada é apagado ao abrir: é preciso clicar em Apagar. Só saem as pastas criadas pelo Unit Styler, com data e hora no nome;' + LB +
      'qualquer outra coisa guardada em .backup fica onde está. As units do projeto não são tocadas.',
      'Muestra cuántas copias de seguridad dejó Unit Styler en la carpeta .backup de este proyecto y cuánto espacio ocupan, y permite eliminarlas.' + LB +
      'No se elimina nada al abrir: hay que hacer clic en Eliminar. Solo salen las carpetas creadas por Unit Styler, con fecha y hora en el nombre;' + LB +
      'cualquier otra cosa guardada en .backup queda donde está. Las units del proyecto no se tocan.',
      'Zeigt, wie viele Sicherungskopien Unit Styler im Ordner .backup dieses Projekts hinterlassen hat und wie viel Platz sie belegen, und erlaubt das Löschen.' + LB +
      'Beim Öffnen wird nichts gelöscht: Sie müssen auf Löschen klicken. Entfernt werden nur die von Unit Styler angelegten Ordner mit Datum und Uhrzeit im Namen;' + LB +
      'alles andere in .backup bleibt, wo es ist. Die Units des Projekts werden nicht angerührt.',
      'Indique combien de copies de sauvegarde Unit Styler a laissées dans le dossier .backup de ce projet et la place qu’elles occupent, et permet de les supprimer.' + LB +
      'Rien n’est supprimé à l’ouverture : il faut cliquer sur Supprimer. Seuls partent les dossiers créés par Unit Styler, avec date et heure dans le nom ;' + LB +
      'tout le reste conservé dans .backup reste en place. Les units du projet ne sont pas touchées.'),
    { stShortcutLabel } ('Shortcut for Organize uses:', 'Atalho de Organizar uses:', 'Atajo de Organizar uses:', 'Tastenkürzel für Uses organisieren:', 'Raccourci d’Organiser uses :'),
    { stShortcutHint } (
      'Key combination that opens Organize uses when the code editor has the focus. Default: Ctrl+Alt+U.' + LB +
      'Click the field and press the combination you want; Backspace or Delete leaves it without a shortcut.' + LB +
      'The shortcut only opens the window: applying still asks for your confirmation. It applies to every project in this Delphi.',
      'Combinação de teclas que abre Organizar uses quando o editor de código está em foco. Padrão: Ctrl+Alt+U.' + LB +
      'Clique no campo e pressione a combinação desejada; Backspace ou Delete deixa sem atalho.' + LB +
      'O atalho só abre a janela: aplicar continua pedindo a sua confirmação. Vale para todos os projetos neste Delphi.',
      'Combinación de teclas que abre Organizar uses cuando el editor de código tiene el foco. Predeterminado: Ctrl+Alt+U.' + LB +
      'Haga clic en el campo y pulse la combinación deseada; Retroceso o Supr lo deja sin atajo.' + LB +
      'El atajo solo abre la ventana: aplicar sigue pidiendo su confirmación. Vale para todos los proyectos en este Delphi.',
      'Tastenkombination, die Uses organisieren öffnet, wenn der Code-Editor den Fokus hat. Standard: Strg+Alt+U.' + LB +
      'Klicken Sie in das Feld und drücken Sie die gewünschte Kombination; Rücktaste oder Entf entfernt das Kürzel.' + LB +
      'Das Kürzel öffnet nur das Fenster: Das Anwenden verlangt weiterhin Ihre Bestätigung. Gilt für alle Projekte in diesem Delphi.',
      'Combinaison de touches qui ouvre Organiser uses quand l’éditeur de code a le focus. Par défaut : Ctrl+Alt+U.' + LB +
      'Cliquez dans le champ et appuyez sur la combinaison voulue ; Retour arrière ou Suppr retire le raccourci.' + LB +
      'Le raccourci ouvre seulement la fenêtre : l’application demande toujours votre confirmation. Vaut pour tous les projets de ce Delphi.'),
    { stAutoSave } ('Save closed units automatically', 'Salvar automaticamente units fechadas', 'Guardar automáticamente las units cerradas',
      'Geschlossene Units automatisch speichern', 'Enregistrer automatiquement les units fermées'),
    { stAutoSaveHint } (
      'Checked: saves only the units that were closed and were changed after the confirmation. Units already open are never saved by the tool. Unchecked: closed units that are changed stay open and edited, for you to decide when to save.',
      'Marcada: salva somente as units que estavam fechadas e foram alteradas após a confirmação. Units já abertas nunca são salvas pela ferramenta. Desmarcada: as units fechadas que forem alteradas ficam ' + 'abertas e editadas, para você decidir quando salvar.',
      'Marcada: guarda solo las units que estaban cerradas y fueron cambiadas tras la confirmación. Las units ya abiertas nunca son guardadas por la herramienta. Desmarcada: las units cerradas que se cambien ' + 'quedan abiertas y editadas, para que usted decida cuándo guardar.',
      'Aktiviert: Speichert nur Units, die geschlossen waren und nach der Bestätigung geändert wurden. Bereits geöffnete Units werden vom Werkzeug nie gespeichert. Deaktiviert: Geänderte geschlossene Units ' + 'bleiben geöffnet und bearbeitet, damit Sie entscheiden, wann gespeichert wird.',
      'Cochée : enregistre uniquement les units qui étaient fermées et ont été modifiées après la confirmation. Les units déjà ouvertes ne sont jamais enregistrées par l’outil. Décochée : les units fermées ' + 'modifiées restent ouvertes et modifiées, pour que vous décidiez quand enregistrer.'),
    { stBackupCheck } ('Make a backup copy of the units before changing them', 'Fazer cópia de segurança das units antes de alterar',
      'Hacer copia de seguridad de las units antes de cambiarlas', 'Units vor dem Ändern sichern', 'Sauvegarder les units avant de les modifier'),
    { stBackupCheckHint } (
      'Checked: before changing a unit, open or closed, copies the file as it is saved on disk to the .backup folder of the project, in a subfolder with the date and time of the run.' + LB +
      'To go back, copy the contents of that subfolder over the project folder.' + LB +
      'Unchecked: no copy is made; a closed unit rewritten on disk has no Undo. It applies to every project in this Delphi.',
      'Marcada: antes de alterar uma unit, aberta ou fechada, copia o arquivo como está gravado no disco para a pasta .backup do projeto, em uma subpasta com a data e a hora da execução.' + LB +
      'Para voltar atrás, copie o conteúdo dessa subpasta sobre a pasta do projeto.' + LB +
      'Desmarcada: nenhuma cópia é feita; unit fechada regravada no disco não tem Desfazer. Vale para todos os projetos neste Delphi.',
      'Marcada: antes de cambiar una unit, abierta o cerrada, copia el archivo tal como está guardado en disco en la carpeta .backup del proyecto, en una subcarpeta con la fecha y la hora de la ejecución.' + LB +
      'Para volver atrás, copie el contenido de esa subcarpeta sobre la carpeta del proyecto.' + LB +
      'Desmarcada: no se hace ninguna copia; una unit cerrada reescrita en disco no tiene Deshacer. Vale para todos los proyectos en este Delphi.',
      'Aktiviert: Vor dem Ändern einer Unit, geöffnet oder geschlossen, wird die Datei so, wie sie auf der Festplatte gespeichert ist, in den Ordner .backup des Projekts kopiert, in einen Unterordner mit Datum und Uhrzeit der Ausführung.' + LB +
      'Zum Zurückgehen kopieren Sie den Inhalt dieses Unterordners über den Projektordner.' + LB +
      'Deaktiviert: Es wird keine Kopie erstellt; eine auf der Festplatte neu geschriebene geschlossene Unit hat kein Rückgängig. Gilt für alle Projekte in diesem Delphi.',
      'Cochée : avant de modifier une unit, ouverte ou fermée, copie le fichier tel qu’il est enregistré sur le disque dans le dossier .backup du projet, dans un sous-dossier portant la date et l’heure de l’exécution.' + LB +
      'Pour revenir en arrière, copiez le contenu de ce sous-dossier sur le dossier du projet.' + LB +
      'Décochée : aucune copie n’est faite ; une unit fermée réécrite sur le disque n’a pas d’Annuler. Vaut pour tous les projets de ce Delphi.'),
    { stSaveNote } ('Saving the settings applies no changes to the units.', 'Salvar configurações não aplica alterações às units.',
      'Guardar la configuración no aplica cambios a las units.', 'Das Speichern der Einstellungen ändert keine Units.',
      'Enregistrer les paramètres n’applique aucune modification aux units.'),
    { stSaveNoteExplain } (
      'Editing the rules does not modify code. Apply is a separate action and always asks for confirmation.',
      'A edição das regras não modifica o código. Aplicar é uma ação separada e sempre pede confirmação.',
      'Editar las reglas no modifica el código. Aplicar es una acción aparte y siempre pide confirmación.',
      'Das Bearbeiten der Regeln ändert keinen Code. Anwenden ist eine eigene Aktion und verlangt immer eine Bestätigung.',
      'Modifier les règles ne change pas le code. Appliquer est une action distincte qui demande toujours une confirmation.'),
    { stFolderButton } ('Settings folder', 'Pasta das configurações', 'Carpeta de configuración', 'Einstellungsordner', 'Dossier des paramètres'),
    { stFolderButtonHint } (
      'Opens in Explorer the folder where the settings are kept, so you can back them up or copy them to another computer.' + LB +
      'Each folder D11, D12 or D13 keeps in settings.json the rules of Unit Styler for that Delphi.' + LB +
      'The projects folder keeps one file per project, the same in any Delphi version; the project is recognized by the identifier in its .dproj, even if it changes folder.',
      'Abre no Explorer a pasta onde ficam as configurações, para você fazer backup ou copiar para outro computador.' + LB +
      'Cada pasta D11, D12 ou D13 guarda em settings.json as regras do Unit Styler daquele Delphi.' + LB +
      'A pasta projects guarda um arquivo para cada projeto, o mesmo em qualquer versão do Delphi; o projeto é reconhecido pelo identificador do .dproj, mesmo que mude de pasta.',
      'Abre en el Explorador la carpeta donde se guarda la configuración, para hacer copia o llevarla a otro equipo.' + LB +
      'Cada carpeta D11, D12 o D13 guarda en settings.json las reglas de Unit Styler de ese Delphi.' + LB +
      'La carpeta projects guarda un archivo por proyecto, el mismo en cualquier versión de Delphi; el proyecto se reconoce por el identificador de su .dproj, aunque cambie de carpeta.',
      'Öffnet im Explorer den Ordner mit den Einstellungen, damit Sie sie sichern oder auf einen anderen Rechner kopieren können.' + LB +
      'Jeder Ordner D11, D12 oder D13 enthält in settings.json die Regeln von Unit Styler für dieses Delphi.' + LB +
      'Der Ordner projects enthält eine Datei pro Projekt, dieselbe in jeder Delphi-Version; das Projekt wird an der Kennung in seiner .dproj erkannt, auch wenn es den Ordner wechselt.',
      'Ouvre dans l’Explorateur le dossier où sont conservés les paramètres, pour les sauvegarder ou les copier sur un autre ordinateur.' + LB +
      'Chaque dossier D11, D12 ou D13 conserve dans settings.json les règles de Unit Styler pour ce Delphi.' + LB +
      'Le dossier projects conserve un fichier par projet, le même dans toute version de Delphi ; le projet est reconnu par l’identifiant de son .dproj, même s’il change de dossier.'),
    { stSetCancelHint } (
      'Closes the settings and discards every edit made in this window and its dialogs.',
      'Fecha as configurações e descarta todas as edições feitas nesta janela e em seus diálogos.',
      'Cierra la configuración y descarta todas las ediciones hechas en esta ventana y sus diálogos.',
      'Schließt die Einstellungen und verwirft alle Änderungen in diesem Fenster und seinen Dialogen.',
      'Ferme les paramètres et abandonne toutes les modifications faites dans cette fenêtre et ses dialogues.'),
    { stSave } ('Save', 'Salvar', 'Guardar', 'Speichern', 'Enregistrer'),
    { stSaveHint } (
      'Checks and stores the rules of Unit Styler and the settings of the open project, and closes the window. Does not organize the units.',
      'Valida e guarda as regras do Unit Styler e as configurações do projeto aberto e fecha a janela. Não aplica organização às units.',
      'Valida y guarda las reglas de Unit Styler y la configuración del proyecto abierto, y cierra la ventana. No organiza las units.',
      'Prüft und speichert die Regeln von Unit Styler und die Einstellungen des geöffneten Projekts und schließt das Fenster. Organisiert die Units nicht.',
      'Vérifie et enregistre les règles de Unit Styler et les paramètres du projet ouvert, puis ferme la fenêtre. N’organise pas les units.'),
    { stSaveHintNoProject } (
      'Checks and stores the rules of Unit Styler, which apply to every project, and closes the window. Does not organize the units.',
      'Valida e guarda as regras do Unit Styler, que valem para todos os projetos, e fecha a janela. Não aplica organização às units.',
      'Valida y guarda las reglas de Unit Styler, que valen para todos los proyectos, y cierra la ventana. No organiza las units.',
      'Prüft und speichert die Regeln von Unit Styler, die für alle Projekte gelten, und schließt das Fenster. Organisiert die Units nicht.',
      'Vérifie et enregistre les règles de Unit Styler, qui valent pour tous les projets, puis ferme la fenêtre. N’organise pas les units.'),
    { stDlgPriority } ('Priority order of the units', 'Ordem de prioridade das units', 'Orden de prioridad de las units',
      'Prioritätsreihenfolge der Units', 'Ordre de priorité des units'),
    { stDlgPreserve } ('Units to preserve', 'Units a preservar', 'Units a conservar', 'Beizubehaltende Units', 'Units à conserver'),
    { stDlgProtected } ('Protected units (advanced)', 'Units protegidas (avançado)', 'Units protegidas (avanzado)',
      'Geschützte Units (erweitert)', 'Units protégées (avancé)'),
    { stProtectedLabel } (
      'Units that never change place: one name or prefix per line',
      'Units que nunca mudam de lugar: um nome ou prefixo por linha',
      'Units que nunca cambian de lugar: un nombre o prefijo por línea',
      'Units, die nie den Platz wechseln: ein Name oder Präfix pro Zeile',
      'Units qui ne changent jamais de place : un nom ou préfixe par ligne'),
    { stPreserveMemoHint } (
      'One name or prefix per line, for example MyApp.Core or MyApp.*. The matching dependencies stay as fixed points; other units do not cross these points during the organization.',
      'Um nome ou prefixo por linha, por exemplo MinhaApp.Core ou MinhaApp.*. As dependências correspondentes permanecem como pontos fixos; outras units não atravessam esses pontos durante a organização.',
      'Un nombre o prefijo por línea, por ejemplo MiApp.Core o MiApp.*. Las dependencias correspondientes quedan como puntos fijos; las demás units no cruzan esos puntos durante la organización.',
      'Ein Name oder Präfix pro Zeile, zum Beispiel MyApp.Core oder MyApp.*. Die passenden Abhängigkeiten bleiben als feste Punkte; andere Units wandern beim Organisieren nicht an ihnen vorbei.',
      'Un nom ou préfixe par ligne, par exemple MonApp.Core ou MonApp.*. Les dépendances correspondantes restent des points fixes ; les autres units ne les franchissent pas pendant l’organisation.'),
    { stProtectedMemoHint } (
      'One name or prefix per line, for example Winapi.* or System.SysUtils. It applies to every project in this Delphi.' + LB +
      'These units stay where they are and the others do not cross them, which keeps the precedence the code already has.' + LB +
      'Removing an item from the list frees those units to be sorted: do it only if you know no call in the project depends on the order.',
      'Um nome ou prefixo por linha, por exemplo Winapi.* ou System.SysUtils. Vale para todos os projetos neste Delphi.' + LB +
      'Essas units ficam onde estão e as outras não passam por cima delas, o que mantém a precedência que o código já tem.' + LB +
      'Tirar um item da lista libera aquelas units para serem ordenadas: faça isso só se souber que nenhuma chamada do projeto depende da ordem.',
      'Un nombre o prefijo por línea, por ejemplo Winapi.* o System.SysUtils. Vale para todos los proyectos en este Delphi.' + LB +
      'Estas units quedan donde están y las demás no las cruzan, lo que mantiene la precedencia que el código ya tiene.' + LB +
      'Quitar un elemento de la lista libera esas units para ser ordenadas: hágalo solo si sabe que ninguna llamada del proyecto depende del orden.',
      'Ein Name oder Präfix pro Zeile, zum Beispiel Winapi.* oder System.SysUtils. Gilt für alle Projekte in diesem Delphi.' + LB +
      'Diese Units bleiben an ihrem Platz und die anderen wandern nicht an ihnen vorbei, was den Vorrang erhält, den der Code bereits hat.' + LB +
      'Wird ein Eintrag entfernt, dürfen diese Units sortiert werden: Tun Sie das nur, wenn kein Aufruf im Projekt von der Reihenfolge abhängt.',
      'Un nom ou préfixe par ligne, par exemple Winapi.* ou System.SysUtils. Vaut pour tous les projets de ce Delphi.' + LB +
      'Ces units restent où elles sont et les autres ne les franchissent pas, ce qui conserve la priorité que le code a déjà.' + LB +
      'Retirer un élément de la liste libère ces units pour le tri : ne le faites que si aucun appel du projet ne dépend de l’ordre.'),
    { stRestoreDefault } ('Restore default', 'Restaurar padrão', 'Restaurar predeterminado', 'Standard wiederherstellen', 'Rétablir par défaut'),
    { stRestoreDefaultHint } (
      'Puts back the list that comes with Unit Styler: Winapi, System, Vcl, FMX, Data and the old names without prefix. You still have to confirm with OK and Save.',
      'Volta a lista para a que vem com o Unit Styler: Winapi, System, Vcl, FMX, Data e os nomes antigos sem prefixo. Ainda é preciso confirmar com OK e Salvar.',
      'Devuelve la lista a la que viene con Unit Styler: Winapi, System, Vcl, FMX, Data y los nombres antiguos sin prefijo. Aún hay que confirmar con OK y Guardar.',
      'Stellt die mit Unit Styler gelieferte Liste wieder her: Winapi, System, Vcl, FMX, Data und die alten Namen ohne Präfix. Sie müssen noch mit OK und Speichern bestätigen.',
      'Rétablit la liste fournie avec Unit Styler : Winapi, System, Vcl, FMX, Data et les anciens noms sans préfixe. Il faut encore confirmer avec OK et Enregistrer.'),
    { stDlgCancelHint } ('Discards the edit of this dialog and returns to the settings.', 'Descarta a edição deste diálogo e volta às configurações.',
      'Descarta la edición de este diálogo y vuelve a la configuración.', 'Verwirft die Bearbeitung dieses Dialogs und kehrt zu den Einstellungen zurück.',
      'Abandonne la modification de ce dialogue et revient aux paramètres.'),
    { stDlgOkHint } (
      'Keeps the edit of this dialog in the settings. Use Save in the main window to store it.',
      'Mantém a edição deste diálogo nas configurações. Use Salvar na janela principal para guardar no projeto.',
      'Mantiene la edición de este diálogo en la configuración. Use Guardar en la ventana principal para almacenarla.',
      'Behält die Bearbeitung dieses Dialogs in den Einstellungen. Mit Speichern im Hauptfenster wird sie gesichert.',
      'Conserve la modification de ce dialogue dans les paramètres. Utilisez Enregistrer dans la fenêtre principale pour la sauvegarder.'),
    { stFolderOpenError } ('The folder could not be opened:', 'Não foi possível abrir a pasta:', 'No se pudo abrir la carpeta:',
      'Der Ordner konnte nicht geöffnet werden:', 'Impossible d’ouvrir le dossier :'),
    { stBackupNone } (
      'This project has no backup copies made by Unit Styler.',
      'Este projeto não tem cópias de segurança do Unit Styler.',
      'Este proyecto no tiene copias de seguridad de Unit Styler.',
      'Dieses Projekt hat keine Sicherungskopien von Unit Styler.',
      'Ce projet n’a aucune copie de sauvegarde de Unit Styler.'),
    { stBackupOne } ('1 backup copy, from %s: %s, %s.', '1 cópia de segurança, de %s: %s, %s.', '1 copia de seguridad, del %s: %s, %s.',
      '1 Sicherungskopie, vom %s: %s, %s.', '1 copie de sauvegarde, du %s : %s, %s.'),
    { stBackupMany } ('%d backup copies, from %s to %s: %s, %s.', '%d cópias de segurança, de %s a %s: %s, %s.',
      '%d copias de seguridad, del %s al %s: %s, %s.', '%d Sicherungskopien, vom %s bis %s: %s, %s.',
      '%d copies de sauvegarde, du %s au %s : %s, %s.'),
    { stFileOne } ('1 file', '1 arquivo', '1 archivo', '1 Datei', '1 fichier'),
    { stFileMany } ('%d files', '%d arquivos', '%d archivos', '%d Dateien', '%d fichiers'),
    { stBackupWhere } ('They are in the .backup folder of the project.', 'Ficam na pasta .backup do projeto.', 'Están en la carpeta .backup del proyecto.',
      'Sie liegen im Ordner .backup des Projekts.', 'Elles se trouvent dans le dossier .backup du projet.'),
    { stDlgClean } ('Clean backup copies', 'Limpar cópias de segurança', 'Limpiar copias de seguridad', 'Sicherungskopien löschen', 'Nettoyer les copies de sauvegarde'),
    { stBackupInfoHint } (
      'Copies Unit Styler made of the units before changing them, one folder per run, in:',
      'Cópias que o Unit Styler fez das units antes de alterá-las, uma pasta por execução, em:',
      'Copias que Unit Styler hizo de las units antes de cambiarlas, una carpeta por ejecución, en:',
      'Kopien, die Unit Styler vor dem Ändern der Units angelegt hat, ein Ordner pro Ausführung, in:',
      'Copies que Unit Styler a faites des units avant de les modifier, un dossier par exécution, dans :'),
    { stKeepNewest } ('Keep the most recent copy', 'Manter a cópia mais recente', 'Mantener la copia más reciente',
      'Neueste Kopie behalten', 'Conserver la copie la plus récente'),
    { stKeepNewestHint } (
      'Checked: deletes the old copies and keeps the one of the last run, so you can still go back to it.' + LB +
      'Unchecked: deletes every backup copy Unit Styler made in this project.',
      'Marcada: apaga as cópias antigas e mantém a da última execução, para você ainda poder voltar atrás nela.' + LB +
      'Desmarcada: apaga todas as cópias de segurança do Unit Styler neste projeto.',
      'Marcada: elimina las copias antiguas y mantiene la de la última ejecución, para que aún pueda volver a ella.' + LB +
      'Desmarcada: elimina todas las copias de seguridad de Unit Styler en este proyecto.',
      'Aktiviert: Löscht die alten Kopien und behält die der letzten Ausführung, damit Sie noch darauf zurückgehen können.' + LB +
      'Deaktiviert: Löscht alle Sicherungskopien von Unit Styler in diesem Projekt.',
      'Cochée : supprime les anciennes copies et conserve celle de la dernière exécution, pour que vous puissiez encore y revenir.' + LB +
      'Décochée : supprime toutes les copies de sauvegarde de Unit Styler dans ce projet.'),
    { stDelete } ('Delete', 'Apagar', 'Eliminar', 'Löschen', 'Supprimer'),
    { stDeleteHint } (
      'Deletes from disk the backup copies shown above. They do not go to the Recycle Bin and this cannot be undone.' + LB +
      'The units of the project and any other folders in .backup are not touched.',
      'Apaga do disco as cópias de segurança indicadas acima. Não vão para a Lixeira e não há como desfazer.' + LB +
      'As units do projeto e as outras pastas que existam em .backup não são tocadas.',
      'Elimina del disco las copias de seguridad indicadas arriba. No van a la Papelera y no se puede deshacer.' + LB +
      'Las units del proyecto y las demás carpetas que existan en .backup no se tocan.',
      'Löscht die oben genannten Sicherungskopien von der Festplatte. Sie kommen nicht in den Papierkorb, und das lässt sich nicht rückgängig machen.' + LB +
      'Die Units des Projekts und andere Ordner in .backup werden nicht angerührt.',
      'Supprime du disque les copies de sauvegarde indiquées ci-dessus. Elles ne vont pas à la Corbeille et c’est irréversible.' + LB +
      'Les units du projet et les autres dossiers présents dans .backup ne sont pas touchés.'),
    { stCleanCloseHint } ('Closes this dialog without deleting anything else.', 'Fecha este diálogo sem apagar mais nada.',
      'Cierra este diálogo sin eliminar nada más.', 'Schließt diesen Dialog, ohne weiter etwas zu löschen.',
      'Ferme ce dialogue sans rien supprimer d’autre.'),
    { stDeletedOne } ('1 copy deleted.', '1 cópia apagada.', '1 copia eliminada.', '1 Kopie gelöscht.', '1 copie supprimée.'),
    { stDeletedMany } ('%d copies deleted.', '%d cópias apagadas.', '%d copias eliminadas.', '%d Kopien gelöscht.', '%d copies supprimées.'),
    { stDeleteFailed } (
      ' %d could not be deleted completely: a file in them is in use.',
      ' %d não puderam ser apagadas por inteiro: algum arquivo delas está em uso.',
      ' %d no pudieron eliminarse por completo: algún archivo de ellas está en uso.',
      ' %d konnten nicht vollständig gelöscht werden: Eine ihrer Dateien wird verwendet.',
      ' %d n’ont pas pu être supprimées entièrement : un de leurs fichiers est en cours d’utilisation.'),
    { stDlgIgnored } ('Ignored folders and files', 'Pastas e arquivos ignorados', 'Carpetas y archivos ignorados',
      'Ignorierte Ordner und Dateien', 'Dossiers et fichiers ignorés'),
    { stIgnoredLabel } (
      'Check the project folders that must not be changed:',
      'Marque as pastas do projeto que não devem ser alteradas:',
      'Marque las carpetas del proyecto que no deben cambiarse:',
      'Markieren Sie die Projektordner, die nicht geändert werden dürfen:',
      'Cochez les dossiers du projet qui ne doivent pas être modifiés :'),
    { stIgnoredListHint } (
      'Folders where the project has units. Checked: no unit of that folder or its subfolders is analyzed or changed, in any scope. Use it for third-party libraries included in the project.',
      'Pastas onde o projeto tem units. Marcada: nenhuma unit dessa pasta ou de suas subpastas é analisada ou alterada, em nenhum escopo. Use para bibliotecas de terceiros incluídas no projeto.',
      'Carpetas donde el proyecto tiene units. Marcada: ninguna unit de esa carpeta o de sus subcarpetas se analiza ni se cambia, en ningún alcance. Úselo para bibliotecas de terceros incluidas en el proyecto.',
      'Ordner, in denen das Projekt Units hat. Aktiviert: Keine Unit dieses Ordners oder seiner Unterordner wird analysiert oder geändert, in keinem Bereich. Für Bibliotheken von Drittanbietern im Projekt gedacht.',
      'Dossiers où le projet a des units. Coché : aucune unit de ce dossier ou de ses sous-dossiers n’est analysée ni modifiée, dans aucune portée. À utiliser pour les bibliothèques tierces incluses dans le projet.'),
    { stIgnoredOtherLabel } (
      'Other files or folders, one per line, relative to the project:',
      'Outros arquivos ou pastas, um por linha, relativos ao projeto:',
      'Otros archivos o carpetas, uno por línea, relativos al proyecto:',
      'Weitere Dateien oder Ordner, einer pro Zeile, relativ zum Projekt:',
      'Autres fichiers ou dossiers, un par ligne, relatifs au projet :'),
    { stIgnoredMemoHint } (
      'Paths that do not appear in the list above, relative to the project folder. A file, such as Lib\Third.pas, ignores only that unit; a folder, such as Lib\Third\, ignores everything below it.',
      'Caminhos que não aparecem na lista acima, relativos à pasta do projeto. Um arquivo, como Lib\Terceiro.pas, ignora só essa unit; uma pasta, como Lib\Terceiros\, ignora tudo abaixo dela.',
      'Rutas que no aparecen en la lista de arriba, relativas a la carpeta del proyecto. Un archivo, como Lib\Tercero.pas, ignora solo esa unit; una carpeta, como Lib\Terceros\, ignora todo lo que hay debajo.',
      'Pfade, die in der Liste oben nicht erscheinen, relativ zum Projektordner. Eine Datei wie Lib\Third.pas ignoriert nur diese Unit; ein Ordner wie Lib\Third\ ignoriert alles darunter.',
      'Chemins absents de la liste ci-dessus, relatifs au dossier du projet. Un fichier, comme Lib\Tiers.pas, n’ignore que cette unit ; un dossier, comme Lib\Tiers\, ignore tout ce qu’il contient.'),
    { stDlgGroups } ('Unit groups', 'Grupos de units', 'Grupos de units', 'Unit-Gruppen', 'Groupes de units'),
    { stGroupsGridHint } (
      'First column: unique name of the group. Second: unit names or prefixes separated by semicolons, such as System.*; MyApp.Core. The first rule that matches the unit wins. The order of the rows defines the order of the groups.',
      'Primeira coluna: nome exclusivo do grupo. Segunda: nomes ou prefixos de units separados por ponto e vírgula, como System.*; MinhaApp.Core. A primeira regra que corresponde à unit vence. A ordem das linhas define a ordem dos grupos.',
      'Primera columna: nombre único del grupo. Segunda: nombres o prefijos de units separados por punto y coma, como System.*; MiApp.Core. Gana la primera regla que corresponde a la unit. El orden de las filas define el orden de los grupos.',
      'Erste Spalte: eindeutiger Name der Gruppe. Zweite: Unit-Namen oder Präfixe, durch Semikolon getrennt, etwa System.*; MyApp.Core. Die erste passende Regel gewinnt. Die Reihenfolge der Zeilen bestimmt die Reihenfolge der Gruppen.',
      'Première colonne : nom unique du groupe. Seconde : noms ou préfixes de units séparés par des points-virgules, comme System.*; MonApp.Core. La première règle qui correspond à la unit l’emporte. L’ordre ' + 'des lignes définit l’ordre des groupes.'),
    { stGroupAddHint } (
      'Adds a row to register a group and its names or prefixes.',
      'Adiciona uma linha para cadastrar um grupo e seus nomes ou prefixos.',
      'Añade una fila para registrar un grupo y sus nombres o prefijos.',
      'Fügt eine Zeile für eine Gruppe und ihre Namen oder Präfixe hinzu.',
      'Ajoute une ligne pour enregistrer un groupe et ses noms ou préfixes.'),
    { stGroupRemoveHint } (
      'Removes the row of the selected group from the settings. Removes no dependency from the code.',
      'Remove da configuração a linha do grupo selecionado. Não remove dependências do código.',
      'Quita de la configuración la fila del grupo seleccionado. No elimina dependencias del código.',
      'Entfernt die Zeile der ausgewählten Gruppe aus den Einstellungen. Entfernt keine Abhängigkeiten aus dem Code.',
      'Retire des paramètres la ligne du groupe sélectionné. Ne supprime aucune dépendance du code.'),
    { stGroupUpHint } (
      'Moves the selected group one position up, so it comes earlier in the order and in the matching.',
      'Move o grupo selecionado uma posição para cima, antecipando sua ordem e sua prioridade de correspondência.',
      'Mueve el grupo seleccionado una posición hacia arriba, adelantando su orden y su prioridad de correspondencia.',
      'Verschiebt die ausgewählte Gruppe eine Position nach oben; sie kommt in Reihenfolge und Zuordnung früher.',
      'Déplace le groupe sélectionné d’une position vers le haut : il passe plus tôt dans l’ordre et la correspondance.'),
    { stGroupDownHint } (
      'Moves the selected group one position down, so it comes later in the order and in the matching.',
      'Move o grupo selecionado uma posição para baixo, adiando sua ordem e sua prioridade de correspondência.',
      'Mueve el grupo seleccionado una posición hacia abajo, retrasando su orden y su prioridad de correspondencia.',
      'Verschiebt die ausgewählte Gruppe eine Position nach unten; sie kommt in Reihenfolge und Zuordnung später.',
      'Déplace le groupe sélectionné d’une position vers le bas : il passe plus tard dans l’ordre et la correspondance.'),
    { stIndentRange } (
      'Enter the number of indentation spaces, from 0 to 16.',
      'Informe a quantidade de espaços da indentação, de 0 a 16.',
      'Indique la cantidad de espacios de la sangría, de 0 a 16.',
      'Geben Sie die Anzahl der Einzugs-Leerzeichen an, von 0 bis 16.',
      'Indiquez le nombre d’espaces d’indentation, de 0 à 16.'),
    { stCannotSave } ('The settings cannot be saved like this.', 'As configurações não podem ser salvas assim.',
      'La configuración no puede guardarse así.', 'Die Einstellungen können so nicht gespeichert werden.',
      'Les paramètres ne peuvent pas être enregistrés ainsi.'),

    { stHlpOnePerLine } (
      'Puts each uses dependency on a line of its own. Not together with Several units per line: checking one unchecks the other. With both unchecked, the existing line layout is kept when no other rule changes it.',
      'Coloca cada dependência do uses em uma linha própria. Não combina com Várias units por linha: marcar uma desmarca a outra. Com as duas desmarcadas, preserva o formato de linhas existente quando nenhuma outra regra o modifica.',
      'Coloca cada dependencia del uses en una línea propia. No se combina con Varias units por línea: marcar una desmarca la otra. Con ambas desmarcadas, se conserva el formato de líneas existente cuando ninguna otra regla lo modifica.',
      'Setzt jede Uses-Abhängigkeit in eine eigene Zeile. Nicht zusammen mit Mehrere Units pro Zeile: Das Aktivieren der einen deaktiviert die andere. Sind beide deaktiviert, bleibt das vorhandene ' + 'Zeilenlayout erhalten, sofern keine andere Regel es ändert.',
      'Place chaque dépendance du uses sur sa propre ligne. Incompatible avec Plusieurs units par ligne : cocher l’une décoche l’autre. Avec les deux décochées, la disposition des lignes existante est ' + 'conservée si aucune autre règle ne la modifie.'),
    { stHlpWrapUnits } (
      'Puts several dependencies on each line, up to the column limit beside it. With priorities or groups on, the priority block and each group start a line of their own. Not together with One unit per ' + 'line: checking one unchecks the other. With both unchecked, the existing line breaks are kept.' + LB +
      'A unit with a comment at the end of its line always keeps a line of its own, with the comment.',
      'Coloca várias dependências em cada linha, até o limite de colunas ao lado. Com prioridades ou grupos ligados, o bloco de prioridades e cada grupo começam em uma linha própria. Não combina com Uma unit ' + 'por linha: marcar uma desmarca a outra. Com as duas desmarcadas, as quebras de linha existentes são mantidas.' + LB +
      'Unit com comentário no fim da linha fica sempre em uma linha só dela, com o comentário.',
      'Coloca varias dependencias en cada línea, hasta el límite de columnas de al lado. Con prioridades o grupos activos, el bloque de prioridades y cada grupo empiezan en una línea propia. No se combina ' + 'con Una unit por línea: marcar una desmarca la otra. Con ambas desmarcadas, se mantienen los saltos de línea existentes.' + LB +
      'Una unit con comentario al final de la línea queda siempre en una línea solo para ella, con el comentario.',
      'Setzt mehrere Abhängigkeiten in jede Zeile, bis zur Spaltengrenze daneben. Mit Prioritäten oder Gruppen beginnen der Prioritätsblock und jede Gruppe in einer eigenen Zeile. Nicht zusammen mit Eine ' + 'Unit pro Zeile: Das Aktivieren der einen deaktiviert die andere. Sind beide deaktiviert, bleiben die vorhandenen Zeilenumbrüche erhalten.' + LB +
      'Eine Unit mit Kommentar am Zeilenende behält immer eine eigene Zeile, mit dem Kommentar.',
      'Place plusieurs dépendances sur chaque ligne, jusqu’à la limite de colonnes indiquée à côté. Avec les priorités ou les groupes activés, le bloc de priorités et chaque groupe commencent sur leur propre ' + 'ligne. Incompatible avec Une unit par ligne : cocher l’une décoche l’autre. Avec les deux décochées, les sauts de ligne existants sont conservés.' + LB +
      'Une unit avec un commentaire en fin de ligne garde toujours sa propre ligne, avec le commentaire.'),
    { stHlpColumns } (
      'Maximum line width, from 40 to 500 columns, counting the indentation and the comma. Use the same value as the right margin of the Delphi editor. A unit whose name alone passes the limit gets a line to itself.',
      'Largura máxima da linha, de 40 a 500 colunas, contando o recuo e a vírgula. Use o mesmo valor da margem direita do editor do Delphi. Uma unit cujo nome sozinho passe do limite fica em uma linha só para ela.',
      'Ancho máximo de la línea, de 40 a 500 columnas, contando la sangría y la coma. Use el mismo valor del margen derecho del editor de Delphi. Una unit cuyo nombre por sí solo pase del límite queda en una línea solo para ella.',
      'Maximale Zeilenbreite, von 40 bis 500 Spalten, einschließlich Einzug und Komma. Verwenden Sie denselben Wert wie den rechten Rand des Delphi-Editors. Eine Unit, deren Name allein die Grenze überschreitet, erhält eine eigene Zeile.',
      'Largeur maximale de la ligne, de 40 à 500 colonnes, indentation et virgule comprises. Utilisez la même valeur que la marge droite de l’éditeur Delphi. Une unit dont le nom seul dépasse la limite occupe une ligne à elle seule.'),
    { stHlpAlphabetical } (
      'Sorts the units by the part of the name before the first dot only: Data, System, Vcl, Winapi. A unit with no dot counts by its whole name.' + LB +
      'Units with the same first name stay together and keep the order they already had: System.SysUtils stays before System.Classes if it was so.' + LB +
      'With groups, it sorts inside each group. Priorities and preserved units take precedence.' + LB + LB +
      'Attention: in Delphi, when two units declare the same name, the one that comes last in the uses wins.' + LB +
      'Changing the order can make a call use the routine of another unit and the project stop compiling.' + LB +
      'The most common case: System ends up before Winapi, and RegisterClass or DeleteFile become the Windows ones.' + LB +
      'That is why the system units (Winapi, System, Vcl, FMX, Data) come protected: they stay where they are and only the rest is sorted.' + LB +
      'That list is in Protected units, in the group beside this one. Your own or third-party units can repeat names too: compile after applying; the .backup folder keeps the originals.',
      'Ordena as units comparando só a parte do nome antes do primeiro ponto: Data, System, Vcl, Winapi. Unit sem ponto conta pelo nome inteiro.' + LB +
      'Units com o mesmo primeiro nome ficam juntas e mantêm entre si a ordem em que já estavam: System.SysUtils continua antes de System.Classes se era assim.' + LB +
      'Com grupos, ordena dentro de cada grupo. Prioridades e units preservadas têm precedência.' + LB + LB +
      'Atenção: no Delphi, quando duas units declaram o mesmo nome, vale a que aparece por último no uses.' + LB +
      'Mudar a ordem pode fazer uma chamada passar a usar a rotina de outra unit e o projeto deixar de compilar.' + LB +
      'O caso mais comum: System fica antes de Winapi, e RegisterClass ou DeleteFile passam a ser os do Windows.' + LB +
      'Por isso as units de sistema (Winapi, System, Vcl, FMX, Data) vêm protegidas de fábrica: ficam onde estão e só o restante é ordenado.' + LB +
      'Essa lista está em Units protegidas, no grupo ao lado. Units suas ou de terceiros também podem repetir nomes: compile depois de aplicar; a pasta .backup guarda os originais.',
      'Ordena las units comparando solo la parte del nombre anterior al primer punto: Data, System, Vcl, Winapi. Una unit sin punto cuenta por su nombre completo.' + LB +
      'Las units con el mismo primer nombre quedan juntas y mantienen entre sí el orden que ya tenían: System.SysUtils sigue antes de System.Classes si era así.' + LB +
      'Con grupos, ordena dentro de cada grupo. Las prioridades y las units conservadas tienen precedencia.' + LB + LB +
      'Atención: en Delphi, cuando dos units declaran el mismo nombre, vale la que aparece última en el uses.' + LB +
      'Cambiar el orden puede hacer que una llamada pase a usar la rutina de otra unit y que el proyecto deje de compilar.' + LB +
      'El caso más común: System queda antes de Winapi, y RegisterClass o DeleteFile pasan a ser los de Windows.' + LB +
      'Por eso las units de sistema (Winapi, System, Vcl, FMX, Data) vienen protegidas de fábrica: quedan donde están y solo se ordena el resto.' + LB +
      'Esa lista está en Units protegidas, en el grupo de al lado. Sus units o las de terceros también pueden repetir nombres: compile después de aplicar; la carpeta .backup guarda los originales.',
      'Sortiert die Units nur nach dem Namensteil vor dem ersten Punkt: Data, System, Vcl, Winapi. Eine Unit ohne Punkt zählt mit ihrem ganzen Namen.' + LB +
      'Units mit demselben ersten Namen bleiben zusammen und behalten untereinander ihre bisherige Reihenfolge: System.SysUtils bleibt vor System.Classes, wenn es so war.' + LB +
      'Mit Gruppen wird innerhalb jeder Gruppe sortiert. Prioritäten und beibehaltene Units haben Vorrang.' + LB + LB +
      'Achtung: Wenn in Delphi zwei Units denselben Namen deklarieren, gilt die im Uses zuletzt genannte.' + LB +
      'Eine geänderte Reihenfolge kann dazu führen, dass ein Aufruf die Routine einer anderen Unit verwendet und das Projekt nicht mehr kompiliert.' + LB +
      'Der häufigste Fall: System steht vor Winapi, und RegisterClass oder DeleteFile sind dann die von Windows.' + LB +
      'Deshalb sind die System-Units (Winapi, System, Vcl, FMX, Data) ab Werk geschützt: Sie bleiben an ihrem Platz, nur der Rest wird sortiert.' + LB +
      'Diese Liste steht unter Geschützte Units in der Gruppe daneben. Auch eigene Units oder solche von Drittanbietern können Namen wiederholen: Kompilieren Sie nach dem Anwenden; der Ordner .backup enthält die Originale.',
      'Trie les units selon la seule partie du nom située avant le premier point : Data, System, Vcl, Winapi. Une unit sans point compte par son nom entier.' + LB +
      'Les units de même premier nom restent ensemble et gardent entre elles l’ordre qu’elles avaient : System.SysUtils reste avant System.Classes si c’était le cas.' + LB +
      'Avec les groupes, le tri se fait dans chaque groupe. Les priorités et les units conservées ont la priorité.' + LB + LB +
      'Attention : dans Delphi, quand deux units déclarent le même nom, c’est la dernière du uses qui l’emporte.' + LB +
      'Changer l’ordre peut faire qu’un appel utilise la routine d’une autre unit et que le projet ne compile plus.' + LB +
      'Le cas le plus courant : System passe avant Winapi, et RegisterClass ou DeleteFile deviennent ceux de Windows.' + LB +
      'C’est pourquoi les units système (Winapi, System, Vcl, FMX, Data) sont protégées d’origine : elles restent en place et seul le reste est trié.' + LB +
      'Cette liste se trouve dans Units protégées, dans le groupe voisin. Vos units ou celles de tiers peuvent aussi répéter des noms : compilez après application ; le dossier .backup conserve les originaux.'),
    { stHlpAlphabeticalFull } (
      'Checked: inside each first name, also sorts by the rest: System.Classes before System.SysUtils, Vcl.Controls before Vcl.Forms.' + LB +
      'Unchecked: units with the same first name keep the order they already had.' + LB + LB +
      'Attention, this can cause trouble: units of the same first name also repeat names among themselves, and the last one wins.' + LB +
      'Reordering them changes the code more than the option above and raises the chance of the project not compiling, or changing behavior with no error.' + LB +
      'Use it in projects you can compile and test right after; the .backup folder keeps the originals.',
      'Marcada: dentro de cada primeiro nome, ordena também pelo restante: System.Classes antes de System.SysUtils, Vcl.Controls antes de Vcl.Forms.' + LB +
      'Desmarcada: units com o mesmo primeiro nome mantêm a ordem em que já estavam.' + LB + LB +
      'Atenção, pode dar problema: units do mesmo primeiro nome também repetem nomes entre si, e a que fica por último vence.' + LB +
      'Reordená-las muda mais o código do que a opção de cima e aumenta a chance de o projeto deixar de compilar ou de mudar de comportamento sem erro.' + LB +
      'Use em projetos que você possa compilar e testar logo depois; a pasta .backup guarda os originais.',
      'Marcada: dentro de cada primer nombre, ordena también por el resto: System.Classes antes de System.SysUtils, Vcl.Controls antes de Vcl.Forms.' + LB +
      'Desmarcada: las units con el mismo primer nombre mantienen el orden que ya tenían.' + LB + LB +
      'Atención, puede dar problemas: las units del mismo primer nombre también repiten nombres entre sí, y gana la que queda última.' + LB +
      'Reordenarlas cambia más el código que la opción de arriba y aumenta la probabilidad de que el proyecto deje de compilar o cambie de comportamiento sin error.' + LB +
      'Úsela en proyectos que pueda compilar y probar enseguida; la carpeta .backup guarda los originales.',
      'Aktiviert: Sortiert innerhalb jedes ersten Namens auch nach dem Rest: System.Classes vor System.SysUtils, Vcl.Controls vor Vcl.Forms.' + LB +
      'Deaktiviert: Units mit demselben ersten Namen behalten ihre bisherige Reihenfolge.' + LB + LB +
      'Achtung, das kann Probleme machen: Auch Units mit demselben ersten Namen wiederholen untereinander Namen, und die letzte gewinnt.' + LB +
      'Ihre Umsortierung ändert den Code stärker als die Option darüber und erhöht das Risiko, dass das Projekt nicht kompiliert oder sich ohne Fehler anders verhält.' + LB +
      'Verwenden Sie dies in Projekten, die Sie gleich danach kompilieren und testen können; der Ordner .backup enthält die Originale.',
      'Cochée : dans chaque premier nom, trie aussi selon le reste : System.Classes avant System.SysUtils, Vcl.Controls avant Vcl.Forms.' + LB +
      'Décochée : les units de même premier nom gardent l’ordre qu’elles avaient.' + LB + LB +
      'Attention, cela peut poser problème : les units de même premier nom répètent aussi des noms entre elles, et la dernière l’emporte.' + LB +
      'Les réordonner modifie davantage le code que l’option du dessus et augmente le risque que le projet ne compile plus ou change de comportement sans erreur.' + LB +
      'À utiliser dans des projets que vous pouvez compiler et tester aussitôt ; le dossier .backup conserve les originaux.'),
    { stHlpIndent } (
      'Applies the indentation set in the spaces field to the dependency lines of the uses. Unchecked, this rule does not change the existing indentation.',
      'Aplica o recuo definido no campo de espaços às linhas de dependências do uses. Desmarcada, esta regra não altera o recuo existente.',
      'Aplica la sangría definida en el campo de espacios a las líneas de dependencias del uses. Desmarcada, esta regla no cambia la sangría existente.',
      'Wendet den im Feld Leerzeichen festgelegten Einzug auf die Abhängigkeitszeilen des Uses an. Deaktiviert ändert diese Regel den vorhandenen Einzug nicht.',
      'Applique l’indentation définie dans le champ des espaces aux lignes de dépendances du uses. Décochée, cette règle ne modifie pas l’indentation existante.'),
    { stHlpSpaces } (
      'Number of indentation spaces, from 0 to 16, used when Apply indentation is checked. For example, 2 indents each dependency by two spaces.',
      'Quantidade de espaços de recuo, de 0 a 16, usada quando Aplicar indentação está marcada. Por exemplo, 2 recua cada dependência em dois espaços.',
      'Cantidad de espacios de sangría, de 0 a 16, usada cuando Aplicar sangría está marcada. Por ejemplo, 2 sangra cada dependencia dos espacios.',
      'Anzahl der Einzugs-Leerzeichen, von 0 bis 16, die verwendet wird, wenn Einzug anwenden aktiviert ist. Zum Beispiel rückt 2 jede Abhängigkeit um zwei Leerzeichen ein.',
      'Nombre d’espaces d’indentation, de 0 à 16, utilisé quand Appliquer l’indentation est cochée. Par exemple, 2 indente chaque dépendance de deux espaces.'),
    { stHlpPriorities } (
      'Puts the units of the priority list before the others, following the order of the registered names or prefixes. Unchecked, the list is ignored without being erased. Preserved units stay fixed.',
      'Coloca as units da lista de prioridades antes das demais, seguindo a ordem dos nomes ou prefixos cadastrados. Desmarcada, ignora a lista sem apagá-la. Units preservadas continuam fixas.',
      'Coloca las units de la lista de prioridades antes de las demás, siguiendo el orden de los nombres o prefijos registrados. Desmarcada, ignora la lista sin borrarla. Las units conservadas siguen fijas.',
      'Setzt die Units der Prioritätsliste vor die übrigen, in der Reihenfolge der eingetragenen Namen oder Präfixe. Deaktiviert wird die Liste ignoriert, aber nicht gelöscht. Beibehaltene Units bleiben fest.',
      'Place les units de la liste de priorités avant les autres, dans l’ordre des noms ou préfixes enregistrés. Décochée, la liste est ignorée sans être effacée. Les units conservées restent fixes.'),
    { stHlpPriorityNames } (
      'Enter one unit name or prefix per line, such as MyApp.Core or MyApp.*. The order of the lines defines the priority; names missing from the uses are not inserted in the code.',
      'Informe um nome de unit ou prefixo por linha, como MinhaApp.Core ou MinhaApp.*. A ordem das linhas define a prioridade; nomes ausentes do uses não são inseridos no código.',
      'Indique un nombre de unit o prefijo por línea, como MiApp.Core o MiApp.*. El orden de las líneas define la prioridad; los nombres ausentes del uses no se insertan en el código.',
      'Geben Sie einen Unit-Namen oder ein Präfix pro Zeile ein, etwa MyApp.Core oder MyApp.*. Die Reihenfolge der Zeilen bestimmt die Priorität; im Uses fehlende Namen werden nicht in den Code eingefügt.',
      'Saisissez un nom de unit ou un préfixe par ligne, comme MonApp.Core ou MonApp.*. L’ordre des lignes définit la priorité ; les noms absents du uses ne sont pas insérés dans le code.'),
    { stHlpGroups } (
      'Arranges the dependencies by the registered groups. The order of the groups defines their position; if a unit matches several groups, the first one counts. Unchecked, the groups are ignored without being erased.',
      'Organiza as dependências pelos grupos cadastrados. A ordem dos grupos define sua posição; se uma unit combinar com vários grupos, vale o primeiro. Desmarcada, ignora os grupos sem apagá-los.',
      'Organiza las dependencias por los grupos registrados. El orden de los grupos define su posición; si una unit coincide con varios grupos, vale el primero. Desmarcada, ignora los grupos sin borrarlos.',
      'Ordnet die Abhängigkeiten nach den eingetragenen Gruppen. Die Reihenfolge der Gruppen bestimmt ihre Position; passt eine Unit zu mehreren Gruppen, gilt die erste. Deaktiviert werden die Gruppen ignoriert, aber nicht gelöscht.',
      'Organise les dépendances selon les groupes enregistrés. L’ordre des groupes définit leur position ; si une unit correspond à plusieurs groupes, le premier compte. Décochée, les groupes sont ignorés sans être effacés.'),
    { stHlpBlankGroups } (
      'Separates the priority block and the groups with a blank line.',
      'Separa os blocos de prioridades e grupos com uma linha em branco.',
      'Separa los bloques de prioridades y grupos con una línea en blanco.',
      'Trennt den Prioritätsblock und die Gruppen durch eine Leerzeile.',
      'Sépare le bloc de priorités et les groupes par une ligne vide.'),
    { stHlpBlankBefore } (
      'Inserts a blank line before interface, uses, implementation, initialization and finalization where it is safe. If there is already enough space, no other line is added. Unchecked, existing lines are not removed.',
      'Insere uma linha em branco antes de interface, uses, implementation, initialization e finalization nos trechos seguros. Se já houver espaço suficiente, não adiciona outra linha. Desmarcada, não remove linhas existentes.',
      'Inserta una línea en blanco antes de interface, uses, implementation, initialization y finalization en los tramos seguros. Si ya hay espacio suficiente, no añade otra línea. Desmarcada, no elimina líneas existentes.',
      'Fügt vor interface, uses, implementation, initialization und finalization eine Leerzeile ein, wo es sicher ist. Ist bereits genug Abstand vorhanden, wird keine weitere Zeile hinzugefügt. Deaktiviert ' + 'werden vorhandene Zeilen nicht entfernt.',
      'Insère une ligne vide avant interface, uses, implementation, initialization et finalization là où c’est sûr. S’il y a déjà assez d’espace, aucune autre ligne n’est ajoutée. Décochée, les lignes existantes ne sont pas supprimées.'),
    { stHlpBlankAfter } (
      'Inserts a blank line after interface, uses, implementation, initialization and finalization where it is safe. After uses, it goes between the header and the first dependency. Unchecked, existing lines are not removed.',
      'Insere uma linha em branco depois de interface, uses, implementation, initialization e finalization nos trechos seguros. Depois de uses, fica entre o cabeçalho e a primeira dependência. Desmarcada, não remove linhas existentes.',
      'Inserta una línea en blanco después de interface, uses, implementation, initialization y finalization en los tramos seguros. Después de uses, queda entre el encabezado y la primera dependencia. Desmarcada, no elimina líneas existentes.',
      'Fügt nach interface, uses, implementation, initialization und finalization eine Leerzeile ein, wo es sicher ist. Nach uses steht sie zwischen der Überschrift und der ersten Abhängigkeit. Deaktiviert ' + 'werden vorhandene Zeilen nicht entfernt.',
      'Insère une ligne vide après interface, uses, implementation, initialization et finalization là où c’est sûr. Après uses, elle se place entre l’en-tête et la première dépendance. Décochée, les lignes existantes ne sont pas supprimées.'),
    { stHlpCurrentScope } (
      'Applies only to the .pas unit active in the editor of the project. It is already open and stays edited, with no automatic saving. Unavailable when the active file is not a unit of the project.',
      'Aplica somente à unit .pas ativa no editor do projeto. Ela já está aberta e ficará editada, sem salvamento automático. Indisponível quando o arquivo ativo não é uma unit do projeto.',
      'Aplica solo a la unit .pas activa en el editor del proyecto. Ya está abierta y quedará editada, sin guardado automático. No disponible cuando el archivo activo no es una unit del proyecto.',
      'Gilt nur für die im Editor aktive .pas-Unit des Projekts. Sie ist bereits geöffnet und bleibt bearbeitet, ohne automatisches Speichern. Nicht verfügbar, wenn die aktive Datei keine Unit des Projekts ist.',
      'S’applique uniquement à la unit .pas active dans l’éditeur du projet. Elle est déjà ouverte et reste modifiée, sans enregistrement automatique. Indisponible si le fichier actif n’est pas une unit du projet.'),
    { stHlpOpenScope } (
      'Applies to the units of the project already open in the editor, unsaved changes included. All of them stay open and edited for you to decide when to save.',
      'Aplica às units do projeto que já estão abertas no editor, inclusive com alterações não salvas. Todas permanecem abertas e editadas para você decidir quando salvar.',
      'Aplica a las units del proyecto que ya están abiertas en el editor, incluso con cambios sin guardar. Todas quedan abiertas y editadas para que usted decida cuándo guardar.',
      'Gilt für die Units des Projekts, die bereits im Editor geöffnet sind, auch mit ungespeicherten Änderungen. Alle bleiben geöffnet und bearbeitet, damit Sie entscheiden, wann gespeichert wird.',
      'S’applique aux units du projet déjà ouvertes dans l’éditeur, y compris avec des modifications non enregistrées. Toutes restent ouvertes et modifiées pour que vous décidiez quand enregistrer.'),
    { stHlpAllScope } (
      'Applies to the .pas units that belong to the project, open and closed. Those already open are never saved by the tool; the closed ones follow the automatic saving option.',
      'Aplica às units .pas pertencentes ao projeto, abertas e fechadas. As já abertas nunca são salvas pela ferramenta; as fechadas seguem a opção de salvamento automático.',
      'Aplica a las units .pas que pertenecen al proyecto, abiertas y cerradas. Las ya abiertas nunca son guardadas por la herramienta; las cerradas siguen la opción de guardado automático.',
      'Gilt für die .pas-Units des Projekts, geöffnet und geschlossen. Bereits geöffnete werden vom Werkzeug nie gespeichert; geschlossene folgen der Option für automatisches Speichern.',
      'S’applique aux units .pas appartenant au projet, ouvertes et fermées. Celles déjà ouvertes ne sont jamais enregistrées par l’outil ; les fermées suivent l’option d’enregistrement automatique.'),
    { stHlpViewPreview } (
      'Builds and opens Before/After for the current unit of the editor only. The view does not change or save code and does not depend on the scope chosen for Apply.',
      'Gera e abre Antes/Depois somente da unit atual do editor. A visualização não altera nem salva código e não depende do escopo escolhido para Aplicar.',
      'Genera y abre Antes/Después solo de la unit actual del editor. La vista no cambia ni guarda código y no depende del alcance elegido para Aplicar.',
      'Erstellt und öffnet Vorher/Nachher nur für die aktuelle Unit des Editors. Die Ansicht ändert oder speichert keinen Code und hängt nicht vom für Anwenden gewählten Bereich ab.',
      'Génère et ouvre Avant/Après uniquement pour la unit actuelle de l’éditeur. L’affichage ne modifie ni n’enregistre le code et ne dépend pas de la portée choisie pour Appliquer.'),
    { stHlpApply } (
      'Analyzes the chosen scope and asks Yes or No before changing the units. The preview is optional. No keeps the code untouched; Yes applies the rules and follows the saving policy.' + LB +
      'With the backup copy on in Settings, each unit is first copied as it is saved on disk to the .backup folder of the project, in a subfolder with the date and time of the run.',
      'Analisa o escopo escolhido e pergunta Sim ou Não antes de modificar as units. A prévia é opcional. A resposta Não mantém o código intacto; Sim aplica as regras e respeita a política de salvamento.' + LB +
      'Com a cópia de segurança ligada nas Configurações, cada unit é antes copiada como está gravada no disco para a pasta .backup do projeto, em uma subpasta com a data e a hora da execução.',
      'Analiza el alcance elegido y pregunta Sí o No antes de modificar las units. La vista previa es opcional. No mantiene el código intacto; Sí aplica las reglas y respeta la política de guardado.' + LB +
      'Con la copia de seguridad activada en Configuración, cada unit se copia antes tal como está guardada en disco en la carpeta .backup del proyecto, en una subcarpeta con la fecha y la hora de la ejecución.',
      'Analysiert den gewählten Bereich und fragt Ja oder Nein, bevor Units geändert werden. Die Vorschau ist optional. Nein lässt den Code unverändert; Ja wendet die Regeln an und beachtet die Speicherregel.' + LB +
      'Ist die Sicherungskopie in den Einstellungen aktiviert, wird jede Unit zuvor so, wie sie auf der Festplatte gespeichert ist, in den Ordner .backup des Projekts kopiert, in einen Unterordner mit Datum und Uhrzeit der Ausführung.',
      'Analyse la portée choisie et demande Oui ou Non avant de modifier les units. L’aperçu est facultatif. Non laisse le code intact ; Oui applique les règles et respecte la politique d’enregistrement.' + LB +
      'Avec la copie de sauvegarde activée dans les Paramètres, chaque unit est d’abord copiée telle qu’elle est enregistrée sur le disque dans le dossier .backup du projet, dans un sous-dossier portant la date et l’heure de l’exécution.'),
    { stHlpSettings } (
      'Opens the rules used in this project. Save stores the settings and closes the window; organizing the code depends on Apply and on the confirmation.',
      'Abre as regras usadas neste projeto. Salvar guarda as configurações e fecha a janela; organizar o código depende de Aplicar e da confirmação.',
      'Abre las reglas usadas en este proyecto. Guardar almacena la configuración y cierra la ventana; organizar el código depende de Aplicar y de la confirmación.',
      'Öffnet die in diesem Projekt verwendeten Regeln. Speichern sichert die Einstellungen und schließt das Fenster; das Organisieren des Codes hängt von Anwenden und der Bestätigung ab.',
      'Ouvre les règles utilisées dans ce projet. Enregistrer sauvegarde les paramètres et ferme la fenêtre ; l’organisation du code dépend d’Appliquer et de la confirmation.'),
    { stHlpClose } (
      'Closes the comparison and returns to the run window, without applying or saving changes to the code.',
      'Fecha a comparação e volta à execução, sem aplicar nem salvar alterações no código.',
      'Cierra la comparación y vuelve a la ejecución, sin aplicar ni guardar cambios en el código.',
      'Schließt den Vergleich und kehrt zur Ausführung zurück, ohne Änderungen am Code anzuwenden oder zu speichern.',
      'Ferme la comparaison et revient à l’exécution, sans appliquer ni enregistrer de modifications dans le code.'),

    { stErrUtf8Invalid } (
      'The file has a UTF-8 mark but contains bytes that are not valid UTF-8.',
      'O arquivo tem marca UTF-8, mas contém bytes que não são UTF-8 válido.',
      'El archivo tiene marca UTF-8, pero contiene bytes que no son UTF-8 válido.',
      'Die Datei hat eine UTF-8-Markierung, enthält aber Bytes, die kein gültiges UTF-8 sind.',
      'Le fichier porte une marque UTF-8 mais contient des octets qui ne sont pas de l’UTF-8 valide.'),
    { stErrUtf16Size } ('The UTF-16 file has an invalid size.', 'O arquivo UTF-16 tem tamanho inválido.', 'El archivo UTF-16 tiene un tamaño no válido.',
      'Die UTF-16-Datei hat eine ungültige Größe.', 'Le fichier UTF-16 a une taille non valide.'),
    { stErrEncodingUnknown } (
      'The encoding of the file could not be identified safely.',
      'A codificação do arquivo não pôde ser identificada com segurança.',
      'La codificación del archivo no pudo identificarse con seguridad.',
      'Die Kodierung der Datei konnte nicht sicher erkannt werden.',
      'L’encodage du fichier n’a pas pu être identifié de façon sûre.'),
    { stErrEncodingFit } (
      'The new text does not fit the original encoding of the file.',
      'O texto novo não cabe na codificação original do arquivo.',
      'El texto nuevo no cabe en la codificación original del archivo.',
      'Der neue Text passt nicht in die ursprüngliche Kodierung der Datei.',
      'Le nouveau texte ne tient pas dans l’encodage d’origine du fichier.'),
    { stErrChangedOnDisk } (
      'The file was changed on disk after the analysis.',
      'O arquivo foi alterado no disco depois da análise.',
      'El archivo fue cambiado en disco después del análisis.',
      'Die Datei wurde nach der Analyse auf der Festplatte geändert.',
      'Le fichier a été modifié sur le disque après l’analyse.'),
    { stErrReadOnly } ('The file is read-only.', 'O arquivo é somente leitura.', 'El archivo es de solo lectura.',
      'Die Datei ist schreibgeschützt.', 'Le fichier est en lecture seule.'),
    { stErrNoEditorServices } (
      'The Delphi editor services are not available.',
      'Os serviços do editor Delphi não estão disponíveis.',
      'Los servicios del editor de Delphi no están disponibles.',
      'Die Dienste des Delphi-Editors sind nicht verfügbar.',
      'Les services de l’éditeur Delphi ne sont pas disponibles.'),
    { stErrNoProject } (
      'Open a project in Delphi before using Unit Styler.',
      'Abra um projeto no Delphi antes de usar o Unit Styler.',
      'Abra un proyecto en Delphi antes de usar Unit Styler.',
      'Öffnen Sie ein Projekt in Delphi, bevor Sie Unit Styler verwenden.',
      'Ouvrez un projet dans Delphi avant d’utiliser Unit Styler.'),
    { stErrNotUnit } (
      'Open a .pas unit of the active project. The project file (.dpr) is not a unit.',
      'Abra uma unit .pas do projeto ativo. O arquivo de projeto (.dpr) não é uma unit.',
      'Abra una unit .pas del proyecto activo. El archivo de proyecto (.dpr) no es una unit.',
      'Öffnen Sie eine .pas-Unit des aktiven Projekts. Die Projektdatei (.dpr) ist keine Unit.',
      'Ouvrez une unit .pas du projet actif. Le fichier de projet (.dpr) n’est pas une unit.'),
    { stErrNotInProject } (
      'The open unit does not belong to the active project.',
      'A unit aberta não pertence ao projeto ativo.',
      'La unit abierta no pertenece al proyecto activo.',
      'Die geöffnete Unit gehört nicht zum aktiven Projekt.',
      'La unit ouverte n’appartient pas au projet actif.'),
    { stErrProjectChanged } (
      'The active project changed. Open Unit Styler again.',
      'O projeto ativo mudou. Reabra o Unit Styler.',
      'El proyecto activo cambió. Vuelva a abrir Unit Styler.',
      'Das aktive Projekt hat sich geändert. Öffnen Sie Unit Styler erneut.',
      'Le projet actif a changé. Rouvrez Unit Styler.'),
    { stErrUnitOutside } ('Unit outside the project.', 'Unit fora do projeto.', 'Unit fuera del proyecto.',
      'Unit außerhalb des Projekts.', 'Unit hors du projet.'),
    { stErrNoEditor } ('The Delphi editor is not available.', 'O editor Delphi não está disponível.', 'El editor de Delphi no está disponible.',
      'Der Delphi-Editor ist nicht verfügbar.', 'L’éditeur Delphi n’est pas disponible.'),
    { stErrEditorClosed } (
      'The editor of the current unit was closed or replaced. Open Unit Styler again.',
      'O editor da unit atual foi fechado ou substituído. Reabra o Unit Styler.',
      'El editor de la unit actual fue cerrado o sustituido. Vuelva a abrir Unit Styler.',
      'Der Editor der aktuellen Unit wurde geschlossen oder ersetzt. Öffnen Sie Unit Styler erneut.',
      'L’éditeur de la unit actuelle a été fermé ou remplacé. Rouvrez Unit Styler.'),
    { stErrReadEditor } ('The editor could not be read.', 'Não foi possível ler o editor.', 'No se pudo leer el editor.',
      'Der Editor konnte nicht gelesen werden.', 'Impossible de lire l’éditeur.'),
    { stErrOpenUnit } ('The unit could not be opened in the editor.', 'Não foi possível abrir a unit no editor.', 'No se pudo abrir la unit en el editor.',
      'Die Unit konnte nicht im Editor geöffnet werden.', 'Impossible d’ouvrir la unit dans l’éditeur.'),
    { stErrClosedDuring } (
      'The unit was open and was closed during the run.',
      'A unit estava aberta e foi fechada durante a execução.',
      'La unit estaba abierta y fue cerrada durante la ejecución.',
      'Die Unit war geöffnet und wurde während der Ausführung geschlossen.',
      'La unit était ouverte et a été fermée pendant l’exécution.'),
    { stErrMustOpen } (
      'The closed unit has to be opened in the editor before being changed without saving.',
      'A unit fechada precisa ser aberta no editor antes de ser alterada sem salvar.',
      'La unit cerrada debe abrirse en el editor antes de cambiarse sin guardar.',
      'Die geschlossene Unit muss im Editor geöffnet werden, bevor sie ohne Speichern geändert wird.',
      'La unit fermée doit être ouverte dans l’éditeur avant d’être modifiée sans enregistrement.'),
    { stErrChangedAfter } ('The unit changed after the analysis.', 'A unit mudou depois da análise.', 'La unit cambió después del análisis.',
      'Die Unit wurde nach der Analyse geändert.', 'La unit a changé après l’analyse.'),
    { stErrEmptyName } (
      'There is an empty unit name in one of the lists.',
      'Há um nome de unit vazio em uma das listas.',
      'Hay un nombre de unit vacío en una de las listas.',
      'In einer der Listen steht ein leerer Unit-Name.',
      'Il y a un nom de unit vide dans l’une des listes.'),
    { stErrBadSelector } ('Invalid unit name or prefix: %s', 'Nome ou prefixo de unit inválido: %s', 'Nombre o prefijo de unit no válido: %s',
      'Ungültiger Unit-Name oder Präfix: %s', 'Nom ou préfixe de unit non valide : %s'),
    { stErrDupSelector } (
      'Unit name or prefix repeated in the same list: %s',
      'Nome ou prefixo de unit repetido na mesma lista: %s',
      'Nombre o prefijo de unit repetido en la misma lista: %s',
      'Unit-Name oder Präfix in derselben Liste wiederholt: %s',
      'Nom ou préfixe de unit répété dans la même liste : %s'),
    { stErrBothLayouts } (
      'One unit per line and Several units per line cannot be checked together.',
      'Uma unit por linha e Várias units por linha não podem ficar marcadas juntas.',
      'Una unit por línea y Varias units por línea no pueden estar marcadas a la vez.',
      'Eine Unit pro Zeile und Mehrere Units pro Zeile können nicht zusammen aktiviert sein.',
      'Une unit par ligne et Plusieurs units par ligne ne peuvent pas être cochées ensemble.'),
    { stErrWidthRange } (
      'The column limit must be between %d and %d.',
      'O limite de colunas deve ficar entre %d e %d.',
      'El límite de columnas debe estar entre %d y %d.',
      'Die Spaltengrenze muss zwischen %d und %d liegen.',
      'La limite de colonnes doit être comprise entre %d et %d.'),
    { stErrIndentChars } (
      'The indentation can only have spaces or tabs.',
      'A indentação só pode ter espaços ou tabulações.',
      'La sangría solo puede tener espacios o tabulaciones.',
      'Der Einzug darf nur Leerzeichen oder Tabulatoren enthalten.',
      'L’indentation ne peut contenir que des espaces ou des tabulations.'),
    { stErrGroupNoName } ('There is a group with no name.', 'Há um grupo sem nome.', 'Hay un grupo sin nombre.',
      'Es gibt eine Gruppe ohne Namen.', 'Il y a un groupe sans nom.'),
    { stErrGroupDup } ('There are two groups with the same name: %s', 'Há dois grupos com o mesmo nome: %s', 'Hay dos grupos con el mismo nombre: %s',
      'Zwei Gruppen haben denselben Namen: %s', 'Deux groupes portent le même nom : %s'),
    { stErrCfgList } ('Invalid list in the settings file: %s', 'Lista inválida no arquivo de configurações: %s', 'Lista no válida en el archivo de configuración: %s',
      'Ungültige Liste in der Einstellungsdatei: %s', 'Liste non valide dans le fichier de paramètres : %s'),
    { stErrCfgItem } ('Invalid item in the settings file: %s', 'Item inválido no arquivo de configurações: %s', 'Elemento no válido en el archivo de configuración: %s',
      'Ungültiger Eintrag in der Einstellungsdatei: %s', 'Élément non valide dans le fichier de paramètres : %s'),
    { stErrCfgValue } ('Invalid value in the settings file: %s', 'Valor inválido no arquivo de configurações: %s', 'Valor no válido en el archivo de configuración: %s',
      'Ungültiger Wert in der Einstellungsdatei: %s', 'Valeur non valide dans le fichier de paramètres : %s'),
    { stErrCfgJson } ('The settings file is not valid JSON: %s', 'O arquivo de configurações não é um JSON válido: %s', 'El archivo de configuración no es un JSON válido: %s',
      'Die Einstellungsdatei ist kein gültiges JSON: %s', 'Le fichier de paramètres n’est pas un JSON valide : %s'),
    { stErrCfgVersion } (
      'The settings file is of a version that is not recognized: %s',
      'O arquivo de configurações é de uma versão não reconhecida: %s',
      'El archivo de configuración es de una versión no reconocida: %s',
      'Die Einstellungsdatei hat eine nicht erkannte Version: %s',
      'Le fichier de paramètres est d’une version non reconnue : %s'),
    { stErrCfgUnread } (
      'The settings file could not be read, so it will not be overwritten. Fix or delete the file.',
      'O arquivo de configurações não pôde ser lido, então não será sobrescrito. Corrija ou apague o arquivo.',
      'El archivo de configuración no pudo leerse, así que no se sobrescribirá. Corrija o elimine el archivo.',
      'Die Einstellungsdatei konnte nicht gelesen werden und wird daher nicht überschrieben. Korrigieren oder löschen Sie die Datei.',
      'Le fichier de paramètres n’a pas pu être lu, il ne sera donc pas écrasé. Corrigez ou supprimez le fichier.'),
    { stErrCfgChanged } (
      'The settings were changed by another program or another window while this one was open. Close and open again.',
      'As configurações foram alteradas por outro programa ou outra janela enquanto esta estava aberta. Feche e abra de novo.',
      'La configuración fue cambiada por otro programa u otra ventana mientras esta estaba abierta. Cierre y vuelva a abrir.',
      'Die Einstellungen wurden von einem anderen Programm oder Fenster geändert, während dieses geöffnet war. Schließen und erneut öffnen.',
      'Les paramètres ont été modifiés par un autre programme ou une autre fenêtre pendant que celle-ci était ouverte. Fermez et rouvrez.'),
    { stErrCfgGroup } ('Invalid group in the settings file.', 'Grupo inválido no arquivo de configurações.', 'Grupo no válido en el archivo de configuración.',
      'Ungültige Gruppe in der Einstellungsdatei.', 'Groupe non valide dans le fichier de paramètres.'),
    { stErrCfgGroupName } (
      'Group with no valid name in the settings file.',
      'Grupo sem nome válido no arquivo de configurações.',
      'Grupo sin nombre válido en el archivo de configuración.',
      'Gruppe ohne gültigen Namen in der Einstellungsdatei.',
      'Groupe sans nom valide dans le fichier de paramètres.')
  );

var
  Current: TStylerLanguage;

function L(Id: TStylerText; Language: TStylerLanguage): string;
begin
  Result := Texts[Id, Language];
end;

function L(Id: TStylerText): string;
begin
  Result := Texts[Id, Current];
end;

function L(Id: TStylerText; const Args: array of const): string;
begin
  Result := Format(Texts[Id, Current], Args);
end;

function LF(Id: TStylerText; Language: TStylerLanguage; const Args: array of const): string;
begin
  Result := Format(Texts[Id, Language], Args);
end;

function StylerLanguage: TStylerLanguage;
begin
  Result := Current;
end;

procedure UseStylerLanguage(const Code: string);
var Language: TStylerLanguage;
begin
  Current := AutomaticLanguage;
  for Language := Low(TStylerLanguage) to High(TStylerLanguage) do
    if SameText(StylerLanguageCodes[Language], Trim(Code)) then Current := Language;
end;

function AutomaticLanguage: TStylerLanguage;
begin
  case GetUserDefaultUILanguage and $3FF of
    $16: Result := slPortuguese;
    $0A: Result := slSpanish;
    $07: Result := slGerman;
    $0C: Result := slFrench;
  else Result := slEnglish;
  end;
end;

function DiagnosticText(Code: Integer; Language: TStylerLanguage): string;
begin
  case TDiagnosticCode(Code) of
    dcUnterminatedToken, dcInvalidUses: Result := L(stDiagSyntax, Language);
    dcUnsupportedStructure: Result := L(stDiagStructure, Language);
    dcDirectiveBarrier: Result := L(stDiagDirective, Language);
    dcCommentAssociation: Result := L(stDiagComment, Language);
    dcDuplicateUnit: Result := L(stDiagDuplicate, Language);
    dcExcludedUnitBarrier: Result := L(stDiagAnchor, Language);
    dcExcludedCommentClause: Result := L(stDiagAnchorComment, Language);
    dcCommentGroupSpacing: Result := L(stDiagSpacing, Language);
    dcSectionSpacingPreserved: Result := L(stDiagSectionSpacing, Language);
  else Result := L(stPreserved, Language);
  end;
end;

initialization
  Current := AutomaticLanguage;

end.
