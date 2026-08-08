# nixpkgs-fast-update

Pacotes Nix a partir de **binários pré-compilados** oficiais, atualizados com mais frequência que o [nixpkgs](https://github.com/NixOS/nixpkgs).

Em vez de compilar do zero (ou esperar o canal oficial), este repositório baixa os releases oficiais, aplica `autoPatchelfHook` quando necessário e expõe os pacotes via flake.

## Pacotes

| Pacote | Binário upstream | Plataforma (bootstrap) | Licença |
|--------|------------------|------------------------|---------|
| [`grok-build`](pkgs/grok-build) | [x.ai/cli](https://x.ai/cli) | `x86_64-linux` | unfree |
| [`claude-code`](pkgs/claude-code) | [Anthropic releases](https://downloads.claude.ai/claude-code-releases) | `x86_64-linux` | unfree |
| [`pad`](pkgs/pad) | [PerpetualSoftware/pad](https://github.com/PerpetualSoftware/pad/releases) | `x86_64-linux` | Apache-2.0 |
| [`code-server`](pkgs/code-server) | [coder/code-server](https://github.com/coder/code-server/releases) | `x86_64-linux` | MIT |

`grok-build` e `claude-code` são **unfree**. O flake define `config.allowUnfree = true` para estes outputs.

## Uso

### Rodar direto

```bash
nix run github:jairbj/nixpkgs-fast-update#grok-build
nix run github:jairbj/nixpkgs-fast-update#claude-code
nix run github:jairbj/nixpkgs-fast-update#pad
nix run github:jairbj/nixpkgs-fast-update#code-server
```

### Overlay (NixOS / home-manager)

```nix
{
  inputs.nixpkgs-fast-update.url = "github:jairbj/nixpkgs-fast-update";

  outputs = { nixpkgs, nixpkgs-fast-update, ... }: {
    nixosConfigurations.hostname = nixpkgs.lib.nixosSystem {
      modules = [
        {
          nixpkgs.overlays = [ nixpkgs-fast-update.overlays.default ];
          nixpkgs.config.allowUnfree = true;
          environment.systemPackages = [
            # usa a versão deste repo em vez da do nixpkgs
            pkgs.grok-build
            pkgs.claude-code
            pkgs.pad
            pkgs.code-server
          ];
        }
      ];
    };
  };
}
```

### Flake input packages

```nix
environment.systemPackages = [
  inputs.nixpkgs-fast-update.packages.${pkgs.system}.grok-build
  inputs.nixpkgs-fast-update.packages.${pkgs.system}.claude-code
  inputs.nixpkgs-fast-update.packages.${pkgs.system}.pad
  inputs.nixpkgs-fast-update.packages.${pkgs.system}.code-server
];
```

## Automação

O workflow [`.github/workflows/update.yml`](.github/workflows/update.yml):

1. Roda a cada **6 horas** (e via `workflow_dispatch`)
2. Consulta a versão estável de cada upstream
3. Atualiza `sources.json` / `manifest.json` se houver release novo
4. Faz `nix flake check` + `nix build`
5. Faz commit e push em `main` se algo mudou

Scripts locais:

```bash
./scripts/update-all.sh          # todos os pacotes
./pkgs/grok-build/update.sh      # só grok
./pkgs/claude-code/update.sh     # só claude (ou: ./pkgs/claude-code/update.sh 2.1.224)
./pkgs/pad/update.sh             # só pad
./pkgs/code-server/update.sh     # só code-server
```

## Adicionar um pacote

1. Crie `pkgs/<nome>/package.nix` baixando o binário oficial (`fetchurl` + `autoPatchelfHook` se for ELF dinâmico).
2. Guarde versão/hash em `sources.json` ou `manifest.json`.
3. Adicione `update.sh` que consulta o endpoint de release e reescreve esses arquivos.
4. Registre em `scripts/update-all.sh` e em `flake.nix` (`packages` + `overlays`).
5. Rode `nix build .#<nome>` e faça commit.

## Referência

A lógica de empacotamento segue de perto o nixpkgs:

- [`grok-build`](https://github.com/NixOS/nixpkgs/tree/master/pkgs/by-name/gr/grok-build)
- [`claude-code`](https://github.com/NixOS/nixpkgs/tree/master/pkgs/by-name/cl/claude-code) (binário no master)

## Licença

O código deste repositório (Nix, scripts, CI) está sob [MIT](LICENSE).

Os binários empacotados permanecem sob as licenças dos respectivos vendors (xAI / Anthropic / Perpetual Software / Coder). Pacotes unfree estão marcados como `unfree` / `unfreeRedistributable`.
