# CS.Coder Unit Styler (beta)

> [!WARNING]
> **VERSÃO BETA.** O CS.Coder Unit Styler está em beta: ainda está em teste e pode ter defeitos.
> Mantenha o projeto em controle de versão ou deixe a cópia de segurança ligada, e confira
> a prévia antes de aplicar alterações em um projeto inteiro.
> Se encontrar algum problema, avise abrindo uma
> [issue](https://github.com/cscoder69/delphi-unit-styler/issues).

[English](README.md) | **Português (Brasil)**

**Versão:** 0.26.10.12e (beta) · **Licença:** [MIT](LICENSE.txt), gratuito e de código
aberto ([resumo em português](LICENCA.txt)) · **Delphi:** 11, 12 e 13 ·
[**Baixar**](https://github.com/cscoder69/delphi-unit-styler/releases)

O CS.Coder Unit Styler é uma extensão para a IDE do Delphi que organiza as cláusulas
`uses` das units do seu projeto. Ele só roda quando você pede, mostra uma prévia do antes
e depois e pede confirmação antes de alterar qualquer coisa.

![A mesma unit antes e depois: 34 units no uses, uma por linha, em ordem e separadas em grupos](docs/screenshots/before-after.png)

*A mesma unit antes e depois. As imagens mostram a interface em inglês; os nomes de
projeto e de units são exemplos.*

## Resumo

- **Do seu jeito.** Uma unit por linha, ou várias por linha até um limite de colunas, em
  ordem e com indentação.
- **Prioridades e grupos.** As units que você escolher vêm primeiro; grupos por nome ou
  prefixo, como `System.*`.
- **Três escopos.** A unit atual, as units abertas ou todas as units do projeto.
- **Prévia e confirmação.** Nada roda sozinho ao abrir, salvar ou compilar.
- **Cuidado com o seu código.** Comentários, diretivas de compilação, caminhos,
  codificação e quebras de linha são mantidos, e as units das bibliotecas do Delphi ficam
  no lugar por padrão.
- **Cópia de segurança.** Cada arquivo é copiado para uma pasta `.backup` do projeto antes
  de mudar.
- **Parte da IDE.** Menu, atalho e menu de contexto do editor, nos temas claro e escuro,
  em português, inglês, espanhol, alemão e francês.

## Instalação

Funciona no Delphi 11 (IDE de 32 bits) e no Delphi 12 e 13 (IDE de 32 e de 64 bits). Não
precisa de compilador nem de administrador.

1. **Baixe** `CSCoderUnitStyler-<versão>.zip` na
   [página de Releases](https://github.com/cscoder69/delphi-unit-styler/releases), em
   **Assets**. Não escolha "Source code": esse não tem o instalador.
2. **Extraia** o zip inteiro em uma pasta à sua escolha.
3. **Feche o Delphi.**
4. **Execute `Install.bat`.** Ele instala para o usuário atual do Windows em todos os
   Delphi compatíveis que encontrar e mostra uma linha por Delphi, por exemplo
   `[OK] Delphi 12 (32-bit, 64-bit)`.
5. **Abra o Delphi.** Os comandos ficam no menu principal, em **CS.Coder > Unit Styler**.

**Atualizar:** execute o `Install.bat` do zip mais novo, com o Delphi fechado. Suas
configurações são mantidas.

**Desinstalar:** `Uninstall.bat` remove a extensão e mantém as configurações.
`Uninstall.bat /data` apaga também as configurações, e não há como desfazer.

## Novidades

**0.26.10.12e**: a descrição do pacote mostra o site da CS.Coder em Component > Install Packages, e o `LICENSE.txt` traz só o texto MIT. As notas de todas as versões estão na
[página de Releases](https://github.com/cscoder69/delphi-unit-styler/releases).

## Como usar

Abra um projeto e abra **Organizar uses** pelo menu **CS.Coder > Unit Styler**, com
**Ctrl+Alt+U** no editor de código, ou com o botão direito no editor. Escolha onde
aplicar, veja a prévia se quiser e confirme.

| Organizar uses | Configurações |
|---|---|
| ![Janela Organizar uses: escopo, regras em uso, Prévia e Aplicar](docs/screenshots/organize-uses.png) | ![Janela de configurações: formatação, prioridades e grupos, configurações do projeto, cópia de segurança, atalho e idioma](docs/screenshots/settings.png) |

- **Units abertas no editor** são alteradas ali e nunca são salvas pela ferramenta: você
  pode desfazer com Ctrl+Z e decide quando salvar.
- **Units que estavam fechadas** são regravadas no disco, na codificação original, quando
  **Salvar automaticamente units fechadas** está marcada.
- **A ordem do `uses` importa para o compilador:** quando duas units declaram o mesmo
  nome, vale a que vem por último. Por isso `Winapi.*`, `System.*`, `Vcl.*`, `FMX.*` e
  `Data.*` são protegidas e nunca mudam de lugar, a não ser que você edite essa lista.

A documentação completa, com todas as regras e opções, está na
[página do produto](https://www.cscoder.com.br/projetos/unit-styler-delphi/).

## Compilar a partir do código

O `build.ps1` compila o pacote e o programa de demonstração, e o `test.ps1` roda os
testes, com os compiladores de linha de comando do Delphi. Informe as pastas do seu Delphi
no início de cada script. Há um `.dpk` por versão do Delphi em `packages/`, e os fontes
estão em `src/`.

## Outras ferramentas CS.Coder

- [CS.Coder Hub de Projetos](https://github.com/cscoder69/delphi-project-hub): atalhos de
  projetos organizados em categorias e grupos, na Welcome Page do Delphi.

## Suporte

Abra uma [issue](https://github.com/cscoder69/delphi-unit-styler/issues) para problemas e
sugestões. Pull requests são bem-vindos. Contato: contato@cscoder.com.br

## Licença

Distribuído sob a [Licença MIT](LICENSE.txt). Copyright (c) 2026 CS.Coder.

"Delphi" e "RAD Studio" são marcas da Embarcadero Technologies, Inc. O CS.Coder Unit
Styler é um projeto independente. Não é afiliado, mantido nem endossado pela Embarcadero.
