# 中文文档与方案（本仓库附带的本地化产物）

这个目录不属于上游 Carbon，是本仓库维护者在本机部署与评估过程中产出的中文资料。

| 文件 | 说明 |
| --- | --- |
| `carbon-本地部署说明.md` | 在 macOS（Apple Silicon）上把 Carbon 跑起来的完整说明：Node/Docker 版本、镜像源适配、登录账号、启停命令、排错 |
| `carbon-蓝图方案.md` | Carbon 代码级逆向蓝图：分层、请求链路、权限/RLS、事件队列、追踪实体、项目模块的边界 |
| `储能系统集成-数字化蓝图方案.md` | 以「系统集成 + 按项目交付」型储能企业为主体的 To-Be 业务蓝图（业务/应用/数据/技术/实施） |
| `SAP集成版-蓝图方案.md` | Carbon 前台（SoE）+ SAP 后台（SoR）的集成方案：职责矩阵、18 个接口、一致性、对账、分期 |
| `SAP集成版-蓝图方案.html` | 同上，单文件 HTML，可离线打开、可打印 |
| `SAP集成版-蓝图方案.pdf` | 同上，A4 打印稿 |
| `carbon-db-fix.sql` | 本地栈补丁：修复 `pgmq` 事件队列权限（`permission denied for table q_event_system`） |
| `carbon-start.sh` / `carbon-stop.sh` | 本地启停脚本（含 Node、Docker、镜像源环境变量） |
| `架构图/` | 6 张架构图（SVG 源文件 + 2× PNG + 合集 PDF + 索引页） |

## 说明

- 上游代码为 AGPL-3.0；`packages/ee` 为 Carbon 商业许可，二者条款不同，商用前请分别确认。
- 本目录内容按「现状记录 + 建议」编写，不构成对上游的承诺。
