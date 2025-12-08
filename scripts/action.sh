#!/usr/bin/env bash

# 函数：重启 AI 任务
# 用法：action [ACTION] [USER_NAME] [REPO_NAME] [JOB_ID] [COOKIE]
action() {
    local ACTION=${1:-$ACTION}
    local USER_NAME=${2:-$USER_NAME}
    local REPO_NAME=${3:-$REPO_NAME}
    local JOB_ID=${4:-$JOB_ID}
    local COOKIE=${5:-$COOKIE}
    local CSRF

    # 从 COOKIE 中提取 _csrf（如果存在）
    CSRF=$(printf '%s' "$COOKIE" | sed -n 's/.*_csrf=\([^;]*\).*/\1/p' || true)
    # 移除 CSRF 字符串末尾的引号、空格或换行符
    CSRF=$(printf '%s' "$CSRF" | sed 's/[\^"“”[:space:]]\+$//')

    # 仅当 ACTION 不是 brief 时附加请求体
    local DATA_ARGS=()
    if [ "${ACTION}" != "brief" ]; then
        DATA_ARGS=(--data-raw "{\"_csrf\":\"${CSRF}\"}")
    fi

    # 捕获 body + http_code（最后一行）
    local resp
    resp=$(curl --fail -sS "https://openi.pcl.ac.cn/api/v1/${USER_NAME}/${REPO_NAME}/ai_task/${ACTION}?id=${JOB_ID}&_csrf=${CSRF}" \
        -H 'accept: application/json, text/plain, */*' \
        -H 'accept-language: en,en-GB;q=0.9,en-US;q=0.8,zh-CN;q=0.7,zh;q=0.6' \
        -H 'content-type: application/json;charset=UTF-8' \
        -H "cookie: ${COOKIE}" \
        -H 'origin: https://openi.pcl.ac.cn' \
        -H 'priority: u=1, i' \
        -H 'referer: https://openi.pcl.ac.cn/cloudbrains' \
        -H 'sec-ch-ua: "Chromium";v="142", "Microsoft Edge";v="142", "Not_A Brand";v="99"' \
        -H 'sec-ch-ua-mobile: ?0' \
        -H 'sec-ch-ua-platform: "Windows"' \
        -H 'sec-fetch-dest: empty' \
        -H 'sec-fetch-mode: cors' \
        -H 'sec-fetch-site: same-origin' \
        -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36 Edg/142.0.0.0' \
        "${DATA_ARGS[@]}")
    
    echo "Action: $ACTION, raw response: $resp"
    status=$(echo "${resp}" | jq -r '.data.status')
    echo "Status: $status"
    return 0
}

# 可执行入口
if [ -n "${BASH_VERSION:-}" ] && [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    action "$@"
fi