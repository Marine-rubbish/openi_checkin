#!/usr/bin/env bash
set -e

# 用法: ./scripts/login.sh <USERNAME> <PASSWORD>
# 输出: 登录成功后的完整 Cookie 字符串

USERNAME="$1"
PASSWORD="$2"
COOKIE_FILE="cookies.txt"

if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
    echo "Usage: $0 <username> <password>" >&2
    exit 1
fi

# 函数：从 cookie 文件输出完整的 Cookie header 字符串
print_cookies() {
    # 把第6列作为 name，7..NF 拼接为 value（处理可能的空格或多列）
    awk 'NF >= 7 {
        name = $6
        value = $7
        for(i=8;i<=NF;i++) value = value " " $i
        printf("%s=%s; ", name, value)
    }' "$1" | sed 's/; $//'
}

# ==========================================
# 0. 检查现有 Cookie 是否仍然有效
# ==========================================
if [ -f "$COOKIE_FILE" ]; then
    # 尝试访问一个需要登录的 API (如通知数接口)
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -b "$COOKIE_FILE" "https://openi.pcl.ac.cn/api/v1/notifications/new")
    
    if [ "$HTTP_CODE" == "200" ]; then
        # 输出完整 cookie 字符串
        print_cookies "$COOKIE_FILE"
        exit 0
    else
        rm -f "$COOKIE_FILE"
    fi
fi

# ==========================================
# 1. 新建会话：获取登录页面 CSRF
# ==========================================
curl -s -c "$COOKIE_FILE" "https://openi.pcl.ac.cn/user/login" > /dev/null

# 从 cookie 文件中提取 _csrf
CSRF_TOKEN=$(grep "_csrf" "$COOKIE_FILE" | awk '{print $7}' | head -n 1)

if [ -z "$CSRF_TOKEN" ]; then
    echo "Error: Failed to fetch initial CSRF token." >&2
    exit 1
fi

# ==========================================
# 2. 发送登录请求
# ==========================================
curl -s -L -b "$COOKIE_FILE" -c "$COOKIE_FILE" \
    -X POST "https://openi.pcl.ac.cn/user/login" \
    --data-urlencode "user_name=${USERNAME}" \
    --data-urlencode "password=${PASSWORD}" \
    --data-urlencode "_csrf=${CSRF_TOKEN}" > /dev/null

# 额外再访问一次首页（或其他页面），以确保服务器发放所有登录相关的 cookie
curl -s -L -b "$COOKIE_FILE" -c "$COOKIE_FILE" "https://openi.pcl.ac.cn/" > /dev/null

# ==========================================
# 3. 验证并输出完整 cookie
# ==========================================
if grep -q "i_like_openi" "$COOKIE_FILE" || grep -q "gitea_" "$COOKIE_FILE"; then
    print_cookies "$COOKIE_FILE"
else
    echo "Error: Login failed. Please check username/password." >&2
    rm -f "$COOKIE_FILE"
    exit 1
fi