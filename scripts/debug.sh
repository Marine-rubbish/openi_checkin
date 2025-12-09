set -e

# 用法:
#   export OPENI_COOKIE='gitea_...; _csrf=xxxx; ...'
#   # 可选：如果没有单独设置 OPENI_CSRF，则脚本会从 OPENI_COOKIE 提取
#   ./scripts/debug.sh

# 从 OPENI_COOKIE 提取 CSRF（如果未设置 OPENI_CSRF）
if [ -z "$OPENI_CSRF" ]; then
    OPENI_CSRF=$(echo "$OPENI_COOKIE" | sed -n 's/.*_csrf=\([^;]*\).*/\1/p' || true)
    echo "从 OPENI_COOKIE 提取到的 CSRF: $OPENI_CSRF"
fi

if [ -z "$OPENI_COOKIE" ] || [ -z "$OPENI_CSRF" ]; then
    echo "请先设置环境变量 OPENI_COOKIE（必须）和可选的 OPENI_CSRF："
    echo "  export OPENI_COOKIE='...; _csrf=...; ...'"
    echo "  export OPENI_CSRF='...'"
    exit 1
fi

# list
set -euo pipefail
JOB_ID=$(curl -s -G "https://openi.pcl.ac.cn/api/v1/${USER_NAME}/${REPO_NAME}/ai_task/list" \
    -H "Cookie: $OPENI_COOKIE" \
| jq '.data.tasks | map(.task.id) | max')
echo "JOB_ID=${JOB_ID}"
echo "最大 task id: ${JOB_ID}"
chmod +x ./scripts/action.sh

# # restart
# 从 OPENI_COOKIE 中提取 _csrf（如果存在）
CSRF=$(echo "$OPENI_COOKIE" | sed -n 's/.*_csrf=\([^;]*\).*/\1/p' || true)
# 移除 CSRF 字符串末尾的空格或换行符
CSRF=$(echo "$CSRF" | sed 's/[\^"“”]\+$//')
source ./scripts/action.sh
action restart "$USER_NAME" "$REPO_NAME" "$JOB_ID" "$OPENI_COOKIE"
echo "status = ${status}"

sleep 100

# action 函数测试
# action brief "$USER_NAME" "$REPO_NAME" "$JOB_ID" "$OPENI_COOKIE"
# echo "status = ${status}"

# list
JOB_ID=$(curl -s -G "https://openi.pcl.ac.cn/api/v1/${USER_NAME}/${REPO_NAME}/ai_task/list" \
    -H "Cookie: $OPENI_COOKIE" | jq '.data.tasks | map(.task.id) | max')
echo "JOB_ID=${JOB_ID}"
echo "最大 task id: ${JOB_ID}"

# stop（如果需要）
action stop "$USER_NAME" "$REPO_NAME" "$JOB_ID" "$OPENI_COOKIE"
echo "status = ${status}"

echo ""
echo "请求已发送。查看返回输出确认。"