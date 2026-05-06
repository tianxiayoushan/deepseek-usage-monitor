# DeepSeek Usage Monitor

A local-first DeepSeek usage and balance monitoring dashboard built with React, TypeScript, Vite, Tailwind CSS, and FastAPI.

一个本地优先的 DeepSeek API 用量与余额监控仪表盘，基于 React、TypeScript、Vite、Tailwind CSS 和 FastAPI 构建。

## Preview / 预览

![DeepSeek Usage Monitor dashboard demo](./docs/assets/demo-screenshot.png)

Demo dashboard screenshot with mock data. No real API key, account, balance, or personal information is shown.

演示截图使用模拟数据，不包含真实 API key、真实账号、真实余额或个人敏感信息。

## English

### Overview

DeepSeek Usage Monitor is a local dashboard for viewing DeepSeek API balance, estimated spend, request activity, token usage, and model-level usage breakdowns. It is designed for developers who want a focused desktop-style monitor while keeping credentials on their own machine.

This project is not positioned as a production-ready billing system. Data can come from the local backend, local settings, or built-in mock/demo data depending on how it is started and configured.

### Features

- Balance dashboard with an industrial gauge-style display.
- Today metrics for requests, tokens, and estimated spend.
- Model usage breakdown with request counts, token totals, estimated cost, and share.
- Recent request table for latency, status, tokens, and estimated cost.
- Light and dark themes.
- English and Simplified Chinese UI support.
- Local-first backend proxy for DeepSeek API access.

### Tech Stack

- Frontend: React, TypeScript, Vite, Tailwind CSS, Lucide React.
- Backend: FastAPI, Uvicorn, HTTPX.
- Tooling: npm scripts for frontend development and production builds.

### Architecture

The app uses a decoupled local frontend/backend architecture.

- Frontend: a Vite-powered React single-page app that renders the dashboard and polls the local backend.
- Backend: a FastAPI service that reads local configuration, keeps secrets out of the frontend bundle, and proxies supported DeepSeek API requests.
- Demo/mock data: the frontend includes mock data so the dashboard can render a safe preview when live backend data is unavailable.

### Quick Start

1. Clone the repository.
2. Install frontend dependencies:

```bash
npm install
```

3. Start the frontend:

```bash
npm run dev
```

4. Configure the backend environment from `backend/.env.example` before using a real DeepSeek API key.

### Frontend Setup

```bash
npm install
npm run dev
```

Build for production:

```bash
npm run build
```

Type-check only:

```bash
npx tsc --noEmit
```

### Backend Setup

Create a backend environment file from the example:

```bash
cp backend/.env.example backend/.env
```

Then set your DeepSeek API key in `backend/.env`.

Typical backend startup:

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --port 8789 --reload
```

On Windows, activate the virtual environment with:

```bash
backend\.venv\Scripts\activate
```

### One-click Scripts

The repository includes platform helper scripts for local startup:

- macOS: `start-mac.command`
- Windows: `start-windows.bat`

These scripts are intended as local convenience wrappers. Review and configure `backend/.env` before connecting a real API key.

### Environment Variables

The backend reads secrets from `backend/.env`. The committed template is `backend/.env.example`.

| Variable | Required | Description |
| --- | --- | --- |
| `DEEPSEEK_API_KEY` | Yes, for live API access | Your DeepSeek API key. Keep it only in `backend/.env`. |
| `INITIAL_TOTAL_CREDIT_CNY` | Optional | User-configured baseline used to estimate total spend. |

Do not put the DeepSeek API key into any frontend `VITE_` variable. Frontend environment variables are exposed to the browser bundle. Do not commit a real `.env` file. Only `.env.example` should be committed.

### Data & Calculation Notes

Due to current API limitations, total spend is estimated from a user-configured initial balance minus current balance, rather than retrieved as an official cumulative billing field.

Formula:

```text
Total Spend = Initial Total Credit CNY - Current Balance CNY
```

This value is useful for local monitoring, but it should not be treated as an official DeepSeek billing statement.

### Security Notes

- Keep `DEEPSEEK_API_KEY` only in `backend/.env`.
- Do not place real secrets in frontend `VITE_` variables.
- Do not commit real `.env` files, screenshots with account data, logs, or other sensitive local artifacts.
- Use `backend/.env.example` as the only committed environment template.
- The dashboard screenshot in this README uses mock/demo data only.

### Roadmap

- Monthly and historical usage views.
- Local persistence for usage history.
- Exportable reports.
- Multi-account workflows.
- Remaining React Hooks lint maintenance items.

### Disclaimer

This is an unofficial third-party tool and is not affiliated with DeepSeek. API availability, billing fields, and balance semantics may change. Verify important billing information with official DeepSeek sources.

### License

MIT License

## 中文

### 项目简介

DeepSeek Usage Monitor 是一个本地优先的 DeepSeek API 用量与余额监控仪表盘，用于查看账户余额、估算消费、请求活动、Token 用量以及模型维度的使用占比。它更适合个人开发者在本机做日常观察，而不是替代官方账单系统。

根据启动方式与配置不同，页面数据可能来自本地后端、本地设置，或项目内置的 mock/demo 数据。

### 功能特性

- 仪表盘式余额展示。
- 今日请求数、Token 数与估算消费。
- 按模型展示请求数、Token 总量、估算费用和占比。
- 最近请求列表，包含延迟、状态、Token 与估算费用。
- 深色与浅色主题。
- 英文与简体中文界面。
- 本地 FastAPI 后端代理 DeepSeek API，避免把密钥暴露到前端。

### 技术栈

- 前端：React、TypeScript、Vite、Tailwind CSS、Lucide React。
- 后端：FastAPI、Uvicorn、HTTPX。
- 工具链：npm scripts 用于前端开发、类型检查与构建。

### 架构说明

项目采用本地前后端分离架构。

- 前端：基于 Vite 的 React 单页应用，负责渲染仪表盘并轮询本地后端。
- 后端：FastAPI 服务，负责读取本地配置、隔离密钥，并代理支持的 DeepSeek API 请求。
- 演示数据：前端包含 mock 数据，因此在没有真实后端数据时也可以展示安全的 dashboard 预览。

### 快速开始

1. 克隆本仓库。
2. 安装前端依赖：

```bash
npm install
```

3. 启动前端：

```bash
npm run dev
```

4. 如需连接真实 DeepSeek API，请先根据 `backend/.env.example` 配置 `backend/.env`。

### 前端启动

```bash
npm install
npm run dev
```

生产构建：

```bash
npm run build
```

仅运行类型检查：

```bash
npx tsc --noEmit
```

### 后端启动

先从示例文件创建本地环境变量文件：

```bash
cp backend/.env.example backend/.env
```

然后在 `backend/.env` 中填写你的 DeepSeek API key。

常见后端启动方式：

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --port 8789 --reload
```

Windows 下可使用：

```bash
backend\.venv\Scripts\activate
```

### 一键启动脚本

仓库内包含本地启动辅助脚本：

- macOS：`start-mac.command`
- Windows：`start-windows.bat`

这些脚本只是本地启动便利工具。连接真实 API key 前，请先检查并配置 `backend/.env`。

### 环境变量

后端从 `backend/.env` 读取密钥。仓库中提交的模板文件是 `backend/.env.example`。

| 变量 | 是否必需 | 说明 |
| --- | --- | --- |
| `DEEPSEEK_API_KEY` | 连接真实 API 时必需 | DeepSeek API key，只应放在 `backend/.env`。 |
| `INITIAL_TOTAL_CREDIT_CNY` | 可选 | 用于估算 Total Spend 的用户配置初始额度。 |

不要把 DeepSeek API key 放进任何前端 `VITE_` 变量。前端环境变量会进入浏览器 bundle。不要提交真实 `.env` 文件；仓库中只应提交 `.env.example`。

### 数据与计算口径

由于当前 API 不直接提供官方累计消费字段，本项目中的 Total Spend 基于用户配置的初始额度与当前余额差额进行估算，并非官方账单口径。

公式：

```text
Total Spend = 初始总额度 CNY - 当前余额 CNY
```

这个数值适合本地监控参考，不应视为 DeepSeek 官方账单。

### 安全说明

- `DEEPSEEK_API_KEY` 只应放在 `backend/.env`。
- 不要把真实密钥放入前端 `VITE_` 变量。
- 不要提交真实 `.env`、包含账号信息的截图、日志或其他本地敏感文件。
- 仓库中只提交 `backend/.env.example` 作为环境变量模板。
- README 中的 dashboard 截图仅使用 mock/demo 数据。

### 路线图

- 月度与历史用量视图。
- 本地用量历史持久化。
- 导出报表。
- 多账号工作流。
- 剩余 React Hooks lint 维护项。

### 免责声明

本项目是非官方第三方工具，与 DeepSeek 官方无关联。API 可用性、账单字段和余额口径可能变化，重要账单信息请以 DeepSeek 官方来源为准。

### 许可证

MIT License
