<p align="center">
  <img src="assets/logo.svg" alt="Tarefas" width="360">
</p>

# Tarefas

Sistema de gerenciamento de tarefas em Delphi 13, composto por uma **API REST** e um **cliente VCL** que a consome.

- **API**: criar, listar, atualizar status, remover e consultar estatísticas de tarefas. Usa o framework [Horse](https://github.com/HashLoad/horse), SQLite com FireDAC e Clean Architecture.
- **Cliente VCL**: aplicação de tela única, sem persistência local, que usa somente a API.

## Sumário

- [Visão geral](#visão-geral)
- [Pré-requisitos](#pré-requisitos)
- [Como executar](#como-executar)
- [Configuração](#configuração)
- [API](#api)
- [Cliente VCL](#cliente-vcl)
- [Testes](#testes)

## Visão geral

### Arquitetura da API

A requisição desce da camada HTTP até o banco; as dependências apontam para o Domain.

```mermaid
flowchart TD
    Cli["Cliente HTTP"]
    Mid["Horse + middlewares<br/>tratamento de erros, validação de X-API-Key"]
    Api["API<br/>rotas e controllers"]
    App["Application<br/>serviços, validadores e DTOs"]
    Dom["Domain<br/>entidades, value objects e<br/>interfaces de repositório"]
    Inf["Infrastructure<br/>repositório FireDAC, pool de conexões"]
    Db[("SQLite<br/>database/tarefas.db")]
    Sh["Shared<br/>TResult e exceções"]
    St["Startup<br/>lê config.json, compõe as dependências<br/>e registra middlewares e rotas"]

    Cli --> Mid --> Api --> App --> Dom
    Inf -. implementa .-> Dom
    Inf --> Db
    Sh -. usado por todas as camadas .- Dom
    St -. compõe .-> Mid
```

### Arquitetura do cliente

O cliente segue o padrão Presenter: a tela não fala HTTP nem guarda estado de paginação.

```mermaid
flowchart TD
    UI["UI (VCL)<br/>Principal.Form: tela única,<br/>dispara operações em TTask"]
    Pr["Presenter<br/>TTarefasPresenter: estado e paginação,<br/>sem dependência de VCL"]
    Sv["Serviço REST<br/>ITarefasApi / TTarefasApi:<br/>requisições HTTP e tradução de erros"]
    Api["API de Tarefas<br/>Horse"]
    Md["Model<br/>TTarefa, TPaginaTarefas, TEstatisticas"]
    Cf["Config<br/>URL base e API Key"]

    UI -->|"ação do usuário"| Pr
    Pr -->|"consulta ou comando"| Sv
    Sv -->|"HTTP + X-API-Key"| Api
    Api -.->|"JSON ou erro"| Sv
    Sv -.->|"records"| Pr
    Pr -.->|"carga ou erro"| UI
    Md -.- Pr
    Md -.- Sv
    Cf -->|"lida ao criar o serviço"| Sv
```

## Pré-requisitos

- **Delphi 13 (RAD Studio)** para compilar e executar os projetos. O FireDAC já inclui o driver SQLite.
- **[Boss](https://github.com/HashLoad/boss)** para baixar o Horse em `modules/` (somente a API).

Não é preciso preparar o banco: ao iniciar, a API cria o arquivo SQLite (`database/tarefas.db`) e a tabela `Tarefas` caso ainda não existam.

> Se você já tem um `database/tarefas.db` de uma versão anterior do projeto, apague-o para que seja recriado com o schema atual (a coluna `Responsavel` passou a ser obrigatória).

## Como executar

1. Baixe as dependências, na raiz do projeto:

   ```sh
   boss install
   ```

2. Crie o `config.json` (ignorado pelo Git) a partir do modelo e defina sua chave em `api.apiKey`:

   ```sh
   cp config.example.json config.json
   ```

3. Abra `api/Tarefas.API.dproj` no Delphi 13, compile (Build) e execute (F9). A API sobe em `http://localhost:9000`.

4. Teste:

   ```sh
   curl -H "X-API-Key: SUA_CHAVE" http://localhost:9000/api/tarefas
   ```

5. Para usar o cliente, abra `app/Tarefas.App.dproj`, compile e execute (F9) com a API em execução.

A API e o cliente procuram o `config.json` subindo as pastas a partir do executável, então o arquivo da raiz é encontrado sem cópia. O caminho do banco é relativo à pasta do `config.json`.

## Configuração

Arquivo `config.json`, na raiz do projeto:

| Chave | Padrão | Uso |
| --- | --- | --- |
| `database.file` | `database/tarefas.db` | Arquivo SQLite |
| `api.port` | `9000` | Porta HTTP |
| `api.host` | `0.0.0.0` | Interface de escuta (`127.0.0.1` aceita só conexões locais) |
| `api.apiKey` | *(sem padrão)* | Valor aceito no header `X-API-Key`. Obrigatória: a API não inicia sem ela. Também pode vir da variável `TAREFAS_API_KEY` |
| `api.environment` | `development` | Nome do ambiente |
| `pagination.defaultLimit` / `maxLimit` | `10` / `100` | Padrão e teto do `limit` da listagem, aplicados pelo serviço |

## API

### Endpoints

> 🔐 Todas as rotas exigem o header `X-API-Key`; sem ele a API responde **401** (`API_KEY_AUSENTE` ou `API_KEY_INVALIDA`).

| Método | Rota | Descrição | Sucesso |
| :---: | --- | --- | :---: |
| 🟢 `GET` | `/api/tarefas` | Lista tarefas (query `limit` e `offset`) | `200` |
| 🟢 `GET` | `/api/tarefas/:id` | Busca uma tarefa | `200` |
| 🔵 `POST` | `/api/tarefas` | Cria uma tarefa | `201` |
| 🟠 `PUT` | `/api/tarefas/:id` | Atualiza o status da tarefa | `200` |
| 🔴 `DELETE` | `/api/tarefas/:id` | Remove a tarefa | `204` |
| 🟢 `GET` | `/api/tarefas/stats/resumo` | Total, média de prioridade e concluídas nos últimos 7 dias | `200` |

#### Exemplos

<details>
<summary>🔵 <code>POST /api/tarefas</code> — criar tarefa</summary>

```sh
curl -X POST http://localhost:9000/api/tarefas \
  -H "X-API-Key: SUA_CHAVE" \
  -H "Content-Type: application/json" \
  -d '{"titulo":"Estudar Delphi","descricao":"Clean Architecture","prioridade":3,"responsavel":"Ana","dataPrevisaoFinalizacao":"2030-01-15"}'
```

</details>

<details>
<summary>🟢 <code>GET /api/tarefas</code> — listar com paginação</summary>

```sh
curl "http://localhost:9000/api/tarefas?limit=10&offset=0" \
  -H "X-API-Key: SUA_CHAVE"
```

</details>

<details>
<summary>🟠 <code>PUT /api/tarefas/:id</code> — concluir tarefa</summary>

```sh
curl -X PUT http://localhost:9000/api/tarefas/1 \
  -H "X-API-Key: SUA_CHAVE" \
  -H "Content-Type: application/json" \
  -d '{"status":"Concluída"}'
```

</details>

<details>
<summary>🔴 <code>DELETE /api/tarefas/:id</code> — remover tarefa</summary>

```sh
curl -X DELETE http://localhost:9000/api/tarefas/1 \
  -H "X-API-Key: SUA_CHAVE"
```

</details>

### Comportamento

- Erros inesperados do servidor retornam 500 com a mensagem genérica "Erro interno do servidor"; o detalhe vai só para o console da API.
- Uma `prioridade` presente mas não inteira (texto, `null`, `2.5`) retorna 400 `PRIORIDADE_INVALIDA`; só a chave ausente assume 1.
- Repetir `PUT` com `Concluída` numa tarefa já concluída mantém a data de finalização original.

### Estrutura de dados

As tarefas ficam em uma única tabela `Tarefas` de um banco **SQLite** (`database/tarefas.db`), acessada via FireDAC pela camada de infraestrutura (`Infra.Connection` cria o schema e `Infra.Repository` lê e grava). Em memória, cada linha é representada pela entidade `TTarefa` (`Domain.Entities`).

| Coluna | Tipo SQLite | Restrições | Descrição |
| --- | --- | --- | --- |
| `Id` | `INTEGER` | PK, `AUTOINCREMENT` | Identificador gerado pelo banco |
| `Titulo` | `TEXT` | `NOT NULL` | Título da tarefa |
| `Descricao` | `TEXT` | opcional | Descrição detalhada |
| `Prioridade` | `INTEGER` | `NOT NULL`, padrão `1` | `1` = Baixa, `2` = Média, `3` = Alta |
| `Status` | `TEXT` | `NOT NULL`, padrão `'Pendente'` | `Pendente`, `Em Progresso` ou `Concluída` |
| `DataCriacao` | `DATETIME` | `NOT NULL` | Preenchida pela API ao criar a tarefa |
| `DataFinalizacao` | `DATETIME` | opcional | Preenchida ao concluir; volta a `NULL` ao reabrir |
| `DataPrevisaoFinalizacao` | `DATETIME` | opcional | Previsão informada pelo usuário |
| `Responsavel` | `TEXT` | `NOT NULL` | Quem responde pela tarefa (até 100 caracteres, validado pela API) |

O `Status` e a `Prioridade` são validados no domínio antes de gravar, e `DataFinalizacao` só tem valor quando o status é `Concluída`.

### Swagger / OpenAPI

Com a API rodando, abra `http://localhost:9000/docs` (Swagger UI) e use o botão **Authorize** para informar a `X-API-Key`. A especificação OpenAPI 3 está em `http://localhost:9000/openapi.json`. As duas rotas são públicas.

A especificação fica em `api/openapi.json`, lida do disco na inicialização (procurada a partir da pasta do executável subindo os diretórios, como o `config.json`). Ao criar ou alterar endpoints, edite esse arquivo e reinicie a API. A interface carrega os arquivos do Swagger UI via CDN (jsDelivr), então o navegador precisa de acesso à internet.

## Cliente VCL

Aplicação VCL de tela única que usa **somente** a API. Usa `REST.Client` da própria RTL; não precisa de Boss nem de componentes de terceiros.

### Recursos

- **Estatísticas** no topo: total de tarefas, média de prioridade das pendentes e concluídas nos últimos 7 dias.
- **Nova tarefa**: título (até 100), descrição (até 500), prioridade Baixa, Média ou Alta, responsável (obrigatório) e previsão de finalização. A previsão já vem marcada com amanhã (hoje + 1 dia); desmarcar a caixa cria a tarefa sem previsão.
- **Lista** paginada (10/25/50/100 por página), com status colorido.
- **Atualizar status** da tarefa selecionada: Pendente, Em Progresso ou Concluída.
- **Remover** com confirmação (tecla Del).
- **F5** recarrega. O rodapé mostra a URL da API e se ela está acessível.

### Configuração do cliente

A URL e a API Key vêm do `config.json` da raiz. Sem o arquivo, a URL padrão é `http://localhost:9000`; a API Key não tem padrão e precisa vir do `config.json` ou da variável `TAREFAS_API_KEY`. A variável `TAREFAS_API_URL` sobrescreve a URL.

### Comportamento

- A tela fala com um presenter (`TTarefasPresenter`, sem VCL), que usa `ITarefasApi`.
- As chamadas HTTP rodam em `TTask` e o resultado é aplicado na thread principal. A janela não fecha enquanto há requisição em andamento.
- Título e responsável vazios são validados na tela antes de chamar a API. Os demais limites (100, 500, prioridade de 1 a 3) são apenas dicas de interface; a API é a validadora.
- Erros de validação da API (`TITULO_*`, `DESCRICAO_*`, `PRIORIDADE_*`, `RESPONSAVEL_*`, `DATA_PREVISAO_*`) levam o foco ao campo correspondente.
- Respostas HTTP 5xx mostram o erro real da API; somente a falta de resposta (timeout de 10 s ou conexão recusada) é exibida como "API indisponível" e marca o rodapé como Desconectado.

### Estrutura do cliente

| Caminho | Conteúdo |
| --- | --- |
| `app/src/Config` | Leitura de URL e API Key |
| `app/src/Model` | Records da tarefa, página e estatísticas; nomes de prioridade; leitura de datas da API |
| `app/src/Service` | `ITarefasApi` / `TTarefasApi`: chamadas REST e tradução de erros |
| `app/src/Presenter` | `TTarefasPresenter`: limite, deslocamento, página atual, regra de página vazia e texto de paginação |
| `app/src/UI` | Tela principal (`Principal.Form`) |

## Testes

Os testes usam DUnitX e são executados pelo IDE.

O projeto `api/tests/Tarefas.API.Tests.dproj` cobre domínio, serviços, validadores e `TResult`, com fake de repositório. Os testes de controller são HTTP: exigem a API rodando (`http://localhost:9000` ou a variável `TAREFAS_API_URL`); sem servidor, terminam como PULADO.

Para detectar vazamentos de memória, o projeto ativa `ReportMemoryLeaksOnShutdown`: feche a API ou o runner normalmente para ver o relatório.
