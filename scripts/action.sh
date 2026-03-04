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

    # 从 COOKIE 中提取 _csrf（只取最后一个，避免多个 _csrf 造成换行）
    CSRF=$(echo "$COOKIE" | grep -o '_csrf=[^;]*' | sed 's/_csrf=//' | tail -n 1 || echo "")
    
    # 构建 URL，将 ID 和 CSRF 都作为查询参数
    local FETCH_URL="https://openi.pcl.ac.cn/api/v1/ai_task/${ACTION}?id=${JOB_ID}&_csrf=${CSRF}"

    # 准备 DATA 负载
    local DATA_PAYLOAD=""
    if [ "${ACTION}" != "brief" ]; then
        DATA_PAYLOAD="{\"_csrf\":\"${CSRF}\"}"
    fi

    echo "DEBUG: ACTION=$ACTION, USER_NAME=$USER_NAME, REPO_NAME=$REPO_NAME, JOB_ID=$JOB_ID"
    echo "DEBUG: CSRF=$CSRF"
    echo "DEBUG: URL=$FETCH_URL"

    # 执行请求
    local resp
    if [ -n "$DATA_PAYLOAD" ]; then
        # POST 请求（用于 restart, stop 等）
        resp=$(curl --fail -sS -X POST "$FETCH_URL" \
            -H 'accept: application/json, text/plain, */*' \
            -H 'accept-language: zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6' \
            -H 'content-type: application/json;charset=UTF-8' \
            -H "cookie: ${COOKIE}" \
            -H 'origin: https://openi.pcl.ac.cn' \
            -H 'referer: https://openi.pcl.ac.cn/cloudbrains' \
            -H 'sec-ch-ua: "Not:A-Brand";v="99", "Microsoft Edge";v="145", "Chromium";v="145"' \
            -H 'sec-ch-ua-mobile: ?0' \
            -H 'sec-ch-ua-platform: "Windows"' \
            -H 'sec-fetch-dest: empty' \
            -H 'sec-fetch-mode: cors' \
            -H 'sec-fetch-site: same-origin' \
            -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36 Edg/145.0.0.0' \
            --data-raw "$DATA_PAYLOAD")
    else
        # GET 请求（用于 brief 等）
        resp=$(curl --fail -sS "$FETCH_URL" \
            -H 'accept: application/json, text/plain, */*' \
            -H "cookie: ${COOKIE}" \
            -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36')
    fi
    
    echo "Action: $ACTION, raw response: $resp"
    status=$(echo "${resp}" | jq -r '.data.status')
    echo "Status: $status"
    return 0
}

# 可执行入口
if [ -n "${BASH_VERSION:-}" ] && [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    action "$@"
fi