# Carbon 本地部署（macOS / Apple Silicon）

把 [crbnos/carbon](https://github.com/crbnos/carbon)（开源制造 ERP/MES/MRP/QMS，AGPLv3）以官方支持的
开发栈方式跑在本机：React Router 应用 + Supabase 数据面（Postgres / GoTrue / PostgREST / Realtime /
Storage）+ Redis + Inngest，全部在 Docker 里，应用用 Vite 以开发模式运行。

- 代码目录：`/Users/limeng/DeepSeek Bot/carbon`
- 工具链目录：`/Users/limeng/DeepSeek Bot/.tools`（Node 24.22.1、pnpm、pnpm store、代理 HOME）
- 启动：`./carbon-start.sh`（或 `cd carbon && source ../.tools/env.sh && pnpm dev`）
- 停止：`./carbon-stop.sh`（容器卷保留，数据不丢）

## 访问地址

| 服务 | 地址 | 说明 |
| --- | --- | --- |
| ERP | http://localhost:3000 | 主应用，登录后进入 `/x` 工作台 |
| MES | http://localhost:3001 | 车间执行 |
| Supabase API | http://localhost:54321 | PostgREST / GoTrue，需带 anon key |
| Supabase Studio | http://localhost:58307 | 数据库管理界面 |
| Inbucket（邮件） | http://localhost:54324 | 本地收信，魔法链接邮件都进这里 |
| Inngest | http://localhost:58309 | 后台任务面板 |
| Postgres | `127.0.0.1:54322` | 库名 `wt_carbon`，用户 `postgres` / `postgres` |
| PgBouncer | `127.0.0.1:54329` | 应用连接池 |
| Redis（共享） | `127.0.0.1:6379` | db 0 |

## 登录账号

本地开发栈开启了 `DEV_BYPASS_EMAIL` 免密登录：

- 邮箱：`test@carbon.ms`（第二管理员 `test+admin2@carbon.ms`）
- 密码：`password`（仅在账号刚创建时设置）
- 在登录框输入邮箱点“继续”即直接登录，不发邮件。

已用 `db:seed:dev` 灌入演示数据（一个演示公司、供应商、采购单、工单、质量记录等）。

## 常用命令

在 `carbon/` 目录、先 `source ../.tools/env.sh` 之后：

| 命令 | 作用 |
| --- | --- |
| `pnpm dev` | 等同 `crbn up --no-portless`，本地固定端口模式 |
| `packages/dev/bin/crbn status` | 查看端口分配与容器健康 |
| `packages/dev/bin/crbn down` | 停止栈（保留卷） |
| `packages/dev/bin/crbn reset` | 清空卷 + 重建数据库后重启 |
| `packages/dev/bin/crbn migrate` | 重新应用数据库迁移 |
| `pnpm db:seed:dev -- --email test@carbon.ms` | 重新灌演示数据 |
| `pnpm --filter @carbon/database db:types` | 重新生成数据库类型 |

`crbn up` 的常用参数：`--no-apps`（只起服务）、`--no-migrate`、`--full`（含 Studio/meta/私有 edge runtime）、
`--run "<cmd>"`（跑完自动拆除，适合 CI）。

## 本机做了哪些适配

1. **Node 24.22.1**：仓库要求 `>=24.22.1`，本机原有的 Node 18/22 不满足，已下载官方 arm64 包到
   `.tools/node-v24.22.1-darwin-arm64`，并用 corepack 激活 `pnpm@10.33.4`。
2. **npm 镜像**：`registry.npmjs.org` 本机只有 ~80 KB/s，改用 `registry.npmmirror.com`
   （通过 `npm_config_registry` 环境变量，未改动仓库 `.npmrc`）。
3. **Docker 镜像**：Docker Hub 直连不可用，全部镜像经 `docker.m.daocloud.io` /
   `docker.1ms.run` / `hub.rat.dev` 拉取后 retag 成官方名；digest 与 compose 里固定的一致，
   所以 `crbn up` 认为镜像已就绪，不会再去 Hub 拉取。
4. **Supabase CLI**（生成数据库类型时会用）：通过 `SUPABASE_INTERNAL_IMAGE_REGISTRY=docker.1ms.run`
   让 `postgres-meta` 走镜像；也可以直接预拉 `supabase/postgres-meta:v0.96.4`。
5. **仓库根 `.env`**：由 `.env.example` 精简而来，填入随机 `SESSION_SECRET`，
   `AUTH_PROVIDERS="email"`、`BOT_PROTECTION="none"`（本地没有 Turnstile/BotID，否则
   `DEV_BYPASS_EMAIL` 登录会提示 “Bot verification failed”），`CARBON_EDITION="enterprise"`
   （见下节），OAuth / Stripe / PostHog / SMTP 留空。
6. **`pgmq` 授权补丁**：首次启动后 ERP 日志里 `permission denied for table q_event_system`
   每 5 秒刷一次（Inngest 事件队列读不到消息表）。执行 `carbon-db-fix.sql` 授权给 `postgres`
   角色后队列恢复 200。`crbn reset` 重建数据库后需要重新执行一次。
7. **克隆方式**：浅克隆（`--depth 1`，约 220 MB），`git pull` 需要 `git fetch --depth 1 && git reset --hard origin/main`。
8. **没有启用 portless**：默认的 `*.dev` HTTPS 需要 root 装 LaunchDaemon 并改 `/etc/hosts`，
   本地用固定 localhost 端口即可（`--no-portless`）。

## 排错

- **Docker 没启动**：`open -a Docker`，等 `docker info` 能返回再启动栈。
- **端口被占**：`crbn status` 看分配；`crbn down` 后重启即可；ERPs 固定用 3000/3001。
- **数据库要重来**：`crbn reset`（会删卷），再 `pnpm db:seed:dev -- --email test@carbon.ms`，再跑一次 `carbon-db-fix.sql`。
- **拉镜像卡住**：Docker Hub 在本网络基本不可用，用镜像前缀拉取后再 `docker tag` 回官方名，例如
  `docker pull docker.1ms.run/supabase/gotrue:v2.197.0 && docker tag docker.1ms.run/supabase/gotrue:v2.197.0 supabase/gotrue:v2.197.0`。
- **登录提示 Bot verification failed**：确认 `.env` 里 `BOT_PROTECTION="none"`，然后重启 dev server。
- **磁盘**：部署后本机剩余约 14 GB（仓库 3.4 GB + 工具链 2.7 GB + 镜像若干 GB），偏紧，注意清理。

## 企业版（Enterprise）功能

`.env` 里 `CARBON_EDITION="enterprise"`（原来是 `community`），改完重启 dev server 生效。
代码里的判断是 `companyHasFeature`：Community 一律 false，Cloud 按套餐，自托管 Enterprise/Test 直接通过
（`packages/ee/src/plan.server.ts`），所以不需要改数据库里的套餐记录。

解锁的功能（都在 `packages/ee`）：API Keys、Webhooks、MCP server `/api/mcp`、第三方集成、
销售规则、审计日志、邮件通知、存储规则、客户门户、AI Agent、工作流、预测、两步验证、
RBAC 角色编写、审批规则、成本核算/收入确认、控制台（kiosk）模式、OEE、Jira/Linear 问题同步等。

验证过的：

- `/x/settings/api-keys` 从“升级到 Enterprise”遮罩变成真实列表页（标题 `API Keys | Settings | Carbon`）；
- 通过表单 POST 成功创建了一条 API key，`apiKey` 表出现记录（验证后已删除）；
- `/x/settings/backups`、`/x/settings/security`、`/x/settings/people` 均 200，无升级遮罩。

还需要额外配置才能真正跑起来的：

| 功能 | 需要的配置 |
| --- | --- |
| SSO / SAML | `AUTH_PROVIDERS` 加 `sso`，`SAML_PRIVATE_KEY`、`SAML_CERT`，以及 IdP 的 ACS/metadata（不加时 `/x/settings/sso` 会跳回 security） |
| 备份 | S3 兼容存储的 bucket / key |
| 集成（Jira、Linear、QuickBooks、Xero、Ramp、Sage、Slack、Onshape…） | 各家 OAuth / API 凭据 |
| 邮件通知、客户门户 | `SMTP_*`、`ERP_URL` / `MES_URL` 对外可达 |
| AI Agent | 模型 provider 的 key |

**许可提示**：`packages/ee` 下的文件不是 AGPL，走的是 Carbon 商业许可（`packages/ee/LICENSE`），
条款写明“未经 Carbon 商业许可不得运行、测试或开发使用”。这台的设置只适合本地评估；
正式自托管请跟 Carbon 签 CCLA/ESA 或买订阅，否则属于许可违约。

## 控制台模式（Console / kiosk mode）

给车间共用终端用的：终端上以管理员身份登录，切到控制台模式后，操作员各自用 4 位 PIN 在终端上
“换上”自己的身份作业，做完再 Pin Out，不需要在共用电脑上反复登出登录。

**开启（管理员，ERP）**：http://localhost:3000/x/settings/people → Console mode 开关。
开启时会自动建好 `Console Operator` 员工类型（只给 MES 需要的 Production/Inventory/Resources/
Items/Quality/People 权限），并给操作者本人生成一次性 PIN。

**创建操作员账号（ERP）**：http://localhost:3000/x/users/operators → New。
账号是 PIN-only（邮箱形如 `<uuid>@console.internal`），创建时弹窗显示 PIN，之后只存哈希，只能重置。

**终端进控制台模式（MES）**：http://localhost:3001 登录 → 右上角头像菜单 → Console Mode 开关
（需要 `settings` 的 update 权限）。打开后立刻弹出 PIN 屏。

**操作员换上身份**：PIN 屏里选人 → 输 4 位 PIN（`/x/console/pin-in`）。列表会排除当前登录的
session 用户；工位绑定了 location 时只列该地点的员工。Pin Out 在顶部中间的头像胶囊里
（`/x/console/pin-out`）。要整体退出控制台模式，回头像菜单把开关关掉即可。

本机当前状态（已配置）：`companySettings.consoleEnabled = true`，演示操作员
**Kiosk Operator**，PIN `1727`（admin `test@carbon.ms` 的 PIN 是 `2442`，可随时在
Operators 页面重置）。注意 PIN 只在生成/重置的那一刻显示一次。

## 生产自托管（另一条路）

如果要部署到服务器而不是本机，官方给的是单节点 Docker Swarm + Caddy 自动 HTTPS：
`contrib/deploying/simple-docker-caddy/deploy.sh`（需要域名、80/443、≥4 GB 内存）。
本地开发栈不要用于生产：`DEV_BYPASS_EMAIL`、匿名密钥、明文 HTTP 都只适合内网。
