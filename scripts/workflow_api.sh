#!/usr/bin/env bash

extract_csrf() {
  echo "$1" | sed -n 's/.*_csrf=\([^;]*\).*/\1/p' | head -n 1
}

build_my_list_url() {
  local cookie="$1"
  local page="${2:-1}"
  local page_size="${3:-30}"
  local csrf
  csrf="$(extract_csrf "$cookie")"
  echo "https://openi.pcl.ac.cn/api/v1/ai_task/my_list?page=${page}&pageSize=${page_size}&_csrf=${csrf}"
}

debug_response() {
  local label="$1"
  local resp="$2"
  echo "[DEBUG] ${label} response_len=${#resp}" >&2
  echo "[DEBUG] ${label} response_preview=$(echo "$resp" | tr '\n' ' ' | cut -c1-500)" >&2
}

assert_tasks_json() {
  local label="$1"
  local resp="$2"
  if ! is_tasks_json "$resp"; then
    echo "[ERROR] ${label}: response is not expected tasks JSON" >&2
    debug_response "$label" "$resp"
    return 1
  fi
  return 0
}

fetch_my_list() {
  local cookie="$1"
  local page="${2:-1}"
  local page_size="${3:-30}"
  local retry_count="${4:-2}"
  local use_fail="${5:-0}"
  local csrf
  csrf="$(extract_csrf "$cookie")"
  local url
  url="$(build_my_list_url "$cookie" "$page" "$page_size")"
  echo "[DEBUG] fetch_my_list url=${url}" >&2

  if [ "$use_fail" = "1" ]; then
    curl --fail --show-error --silent \
      --retry "$retry_count" --retry-delay 2 \
      --connect-timeout 20 --max-time 60 --tlsv1.2 \
      -H "Cookie: $cookie" \
      -H 'accept: application/json, text/plain, */*' \
      "$url"
  else
    curl --show-error --silent \
      --retry "$retry_count" --retry-delay 2 \
      --connect-timeout 20 --max-time 60 --tlsv1.2 \
      -H "Cookie: $cookie" \
      -H 'accept: application/json, text/plain, */*' \
      "$url"
  fi
}

probe_my_list_http_code() {
  local cookie="$1"
  local csrf
  csrf="$(extract_csrf "$cookie")"

  if [ -z "$csrf" ]; then
    echo "0"
    return 0
  fi

  curl -s -o /dev/null -w "%{http_code}" \
    -H "Cookie: $cookie" \
    "https://openi.pcl.ac.cn/api/v1/ai_task/my_list?pageSize=1&_csrf=${csrf}"
}

is_tasks_json() {
  local resp="$1"
  echo "$resp" | jq -e '.code==0 and (.data.tasks|type=="array")' >/dev/null 2>&1
}

renew_cookie() {
  local user_name="$1"
  local pass_word="$2"
  local current_cookie="$3"
  local renewed

  renewed="$(./scripts/login.sh "$user_name" "$pass_word")"
  if [ -z "$renewed" ]; then
    # 兜底：保留旧逻辑，避免异常场景直接丢失 cookie
    export OPENI_COOKIE="$current_cookie"
    renewed="$(./scripts/replace_csrf.sh)"
  fi
  normalize_cookie "$renewed"
}

normalize_cookie() {
  local raw_cookie="$1"
  echo "$raw_cookie" \
    | tr '\r\n' ';' \
    | sed 's/[[:space:]]*;[[:space:]]*/;/g' \
    | tr ';' '\n' \
    | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' \
    | grep -E '^[A-Za-z0-9_\-]+=[^;[:space:]]+$' \
    | awk -F= '
        {
          key=$1
          val=substr($0, length($1) + 2)
          if (key == "by") next
          if (!(key in seen_order)) {
            order[++count]=key
            seen_order[key]=1
          }
          latest[key]=val
        }
        END {
          out=""
          for (i=1; i<=count; i++) {
            k=order[i]
            if (latest[k] == "") continue
            out = out (out=="" ? "" : "; ") k "=" latest[k]
          }
          print out
        }
      '
}

is_cookie_valid() {
  local cookie="$1"
  # 必需键
  echo "$cookie" | grep -q 'gitea_incredible=' || return 1
  echo "$cookie" | grep -q '_csrf=' || return 1
  # 明显脏数据特征
  echo "$cookie" | grep -qi 'by=libcurl' && return 1
  # 至少有分号分隔（防止全串粘连）
  echo "$cookie" | grep -q ';' || return 1
  return 0
}

ensure_valid_cookie() {
  local user_name="$1"
  local pass_word="$2"
  local cookie="$3"
  local normalized

  normalized="$(normalize_cookie "$cookie")"
  if is_cookie_valid "$normalized"; then
    echo "$normalized"
    return 0
  fi

  normalized="$(renew_cookie "$user_name" "$pass_word" "$normalized")"
  if is_cookie_valid "$normalized"; then
    echo "$normalized"
    return 0
  fi

  echo "ERROR: failed to produce a valid cookie" >&2
  return 1
}

extract_max_job_id() {
  local resp="$1"
  local repo_name="$2"

  if ! is_tasks_json "$resp"; then
    echo ""
    return 0
  fi

  echo "$resp" | jq -r --arg REPO "$repo_name" '.data.tasks
    | map(select(.repo_name == $REPO or .task.repo_name == $REPO))
    | map(.task.id // .id)
    | max'
}

extract_status_by_job_id() {
  local resp="$1"
  local job_id="$2"

  if ! is_tasks_json "$resp"; then
    echo ""
    return 0
  fi

  echo "$resp" | jq -r --arg ID "$job_id" '
    .data.tasks[]
    | select((.id|tostring) == $ID or (.task.id|tostring) == $ID)
    | (.status // .task.status // "")
  ' | head -n 1
}
