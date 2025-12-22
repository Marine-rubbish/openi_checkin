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
    -H "Cookie: $OPENI_COOKIE" | jq '.data.tasks | map(.task.id) | max')
echo "JOB_ID=${JOB_ID}"
echo "最大 task id: ${JOB_ID}"
chmod +x ./scripts/action.sh

PASS_WORD=cpy07060018
chmod +x ./scripts/login.sh
./scripts/login.sh "$USER_NAME" "$PASS_WORD"

# 从 cookies.txt 提取 _csrf 和 i_like_openi 并替换到 OPENI_COOKIE 中
COOKIES_FILE="${COOKIES_FILE:-cookies.txt}"
if [ ! -f "$COOKIES_FILE" ]; then
    echo "找不到 cookies 文件：$COOKIES_FILE"
    exit 1
fi

# 尝试 Netscape cookie 格式（domain ... name value），否则尝试成 'name=value' 形式
extract_cookie() {
    name="$1"
    val=""
    val=$(awk -v n="$name" 'tolower($6)==tolower(n){print $7; exit}' "$COOKIES_FILE" 2>/dev/null || true)
    if [ -z "$val" ]; then
        val=$(grep -oE "(^|[[:space:];])${name}=[^;[:space:]]+" "$COOKIES_FILE" | sed -E "s/.*${name}=//" | head -n1 || true)
    fi
    printf "%s" "$val"
}

CSRF_FROM_FILE=$(extract_cookie "_csrf")
ILIKE_FROM_FILE=$(extract_cookie "i_like_openi")

update_cookie_var() {
    var="$1"; val="$2"
    [ -z "$val" ] && return
    # 把 OPENI_COOKIE 按分号拆分，替换或追加键=值
    IFS=';' read -ra parts <<< "$OPENI_COOKIE"
    found=0
    for i in "${!parts[@]}"; do
        # 去头尾空白
        part="$(echo "${parts[i]}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        if echo "$part" | grep -q -E "^${var}="; then
            parts[i]="${var}=${val}"
            found=1
            break
        fi
    done
    if [ "$found" -eq 0 ]; then
        parts+=("${var}=${val}")
    fi
    # 重组并赋回
    OPENI_COOKIE="$(printf "%s; " "${parts[@]}" | sed 's/; $//')"
}

if [ -n "$CSRF_FROM_FILE" ]; then
    update_cookie_var "_csrf" "$CSRF_FROM_FILE"
    echo "已从 $COOKIES_FILE 提取并替换 _csrf"
else
    echo "未在 $COOKIES_FILE 中找到 _csrf，保持原 OPENI_COOKIE 中的值"
fi

if [ -n "$ILIKE_FROM_FILE" ]; then
    update_cookie_var "i_like_openi" "$ILIKE_FROM_FILE"
    echo "已从 $COOKIES_FILE 提取并替换 i_like_openi"
else
    echo "未在 $COOKIES_FILE 中找到 i_like_openi，保持原 OPENI_COOKIE 中的值"
fi

echo "$OPENI_COOKIE"

# # # restart
# # 从 OPENI_COOKIE 中提取 _csrf（如果存在）
# CSRF=$(echo "$OPENI_COOKIE" | sed -n 's/.*_csrf=\([^;]*\).*/\1/p' || true)
# # 移除 CSRF 字符串末尾的空格或换行符
# CSRF=$(echo "$CSRF" | sed 's/[\^"“”]\+$//')
# source ./scripts/action.sh
# action restart "$USER_NAME" "$REPO_NAME" "$JOB_ID" "$OPENI_COOKIE"
# echo "status = ${status}"

# sleep 100

# # action 函数测试
# # action brief "$USER_NAME" "$REPO_NAME" "$JOB_ID" "$OPENI_COOKIE"
# # echo "status = ${status}"

# # list
# JOB_ID=$(curl -s -G "https://openi.pcl.ac.cn/api/v1/${USER_NAME}/${REPO_NAME}/ai_task/list" \
#     -H "Cookie: $OPENI_COOKIE" | jq '.data.tasks | map(.task.id) | max')
# echo "JOB_ID=${JOB_ID}"
# echo "最大 task id: ${JOB_ID}"

# stop（如果需要）
source ./scripts/action.sh
action stop "$USER_NAME" "$REPO_NAME" "$JOB_ID" "$OPENI_COOKIE"
echo "status = ${status}"

echo ""
echo "请求已发送。查看返回输出确认。"