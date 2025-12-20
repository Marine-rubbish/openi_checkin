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

# 可执行入口
if [ -n "${BASH_VERSION:-}" ] && [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    action "$@"
fi