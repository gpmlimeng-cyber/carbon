-- 本地开发栈补丁：让 app 使用的 postgres 角色可以访问 pgmq 事件队列。
-- 症状：ERP 日志反复出现 `permission denied for table q_event_system`，
-- Inngest 的 carbon-event-queue 函数每 5 秒失败一次。
-- 运行：docker exec -i carbon-postgres psql -U supabase_admin -d wt_carbon < carbon-db-fix.sql
GRANT USAGE ON SCHEMA pgmq TO postgres;
GRANT ALL ON ALL TABLES IN SCHEMA pgmq TO postgres;
GRANT ALL ON ALL SEQUENCES IN SCHEMA pgmq TO postgres;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA pgmq TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA pgmq GRANT ALL ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA pgmq GRANT ALL ON SEQUENCES TO postgres;
