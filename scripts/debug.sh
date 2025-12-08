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
# 列出任务（示例接口名可能不同，按 Network 捕获的实际接口替换）
JOB_ID=$(curl -s -G "https://openi.pcl.ac.cn/api/v1/marine_sci/openstl-hycom-code/ai_task/list" \
    -H "Cookie: $OPENI_COOKIE" \
    | jq '.data.tasks | map(.task.id) | max')

echo "最大 task id: $JOB_ID"

echo '{"code":0,"msg":"ok","data":{"id":727827,"status":"WAITING"}}' | jq -r '.data.status'

# # restart
# 从 OPENI_COOKIE 中提取 _csrf（如果存在）
CSRF=$(echo "$OPENI_COOKIE" | sed -n 's/.*_csrf=\([^;]*\).*/\1/p' || true)
# 移除 CSRF 字符串末尾的空格或换行符
CSRF=$(echo "$CSRF" | sed 's/[\^"“”]\+$//')
# curl "https://openi.pcl.ac.cn/api/v1/marine_sci/openstl-hycom-code/ai_task/restart?id=${JOB_ID}&_csrf=${CSRF}" \
#     -H 'accept: application/json, text/plain, */*' \
#     -H 'accept-language: en,en-GB;q=0.9,en-US;q=0.8,zh-CN;q=0.7,zh;q=0.6' \
#     -H 'content-type: application/json;charset=UTF-8' \
#     -b "${OPENI_COOKIE}" \
#     -H 'origin: https://openi.pcl.ac.cn' \
#     -H 'priority: u=1, i' \
#     -H 'referer: https://openi.pcl.ac.cn/cloudbrains' \
#     -H 'sec-ch-ua: "Chromium";v="142", "Microsoft Edge";v="142", "Not_A Brand";v="99"' \
#     -H 'sec-ch-ua-mobile: ?0' \
#     -H 'sec-ch-ua-platform: "Windows"' \
#     -H 'sec-fetch-dest: empty' \
#     -H 'sec-fetch-mode: cors' \
#     -H 'sec-fetch-site: same-origin' \
#     -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36 Edg/142.0.0.0' \
#     --data-raw '{"_csrf":"${CSRF}"}'

# # brief
# curl "https://openi.pcl.ac.cn/api/v1/marine_sci/openstl-hycom-code/ai_task/brief?id=${JOB_ID}&_csrf=${CSRF}" \
#     -H 'accept: application/json, text/plain, */*' \
#     -H 'accept-language: en,en-GB;q=0.9,en-US;q=0.8,zh-CN;q=0.7,zh;q=0.6' \
#     -H 'content-type: application/json;charset=UTF-8' \
#     -b "${OPENI_COOKIE}" \
#     -H 'origin: https://openi.pcl.ac.cn' \
#     -H 'priority: u=1, i' \
#     -H 'sec-ch-ua: "Chromium";v="142", "Microsoft Edge";v="142", "Not_A Brand";v="99"' \
#     -H 'sec-ch-ua-mobile: ?0' \
#     -H 'sec-ch-ua-platform: "Windows"' \
#     -H 'sec-fetch-dest: empty' \
#     -H 'sec-fetch-mode: cors' \
#     -H 'sec-fetch-site: same-origin' \
#     -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36 Edg/142.0.0.0'

# stop（如果需要）
curl "https://openi.pcl.ac.cn/api/v1/marine_sci/openstl-hycom-code/ai_task/stop?id=${JOB_ID}&_csrf=${CSRF}" \
    -H 'accept: application/json, text/plain, */*' \
    -H 'accept-language: en,en-GB;q=0.9,en-US;q=0.8,zh-CN;q=0.7,zh;q=0.6' \
    -H 'content-type: application/json;charset=UTF-8' \
    -b "${OPENI_COOKIE}" \
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
    --data-raw '{"_csrf":"${CSRF}"}'

echo ""
echo "请求已发送。查看返回输出确认。"