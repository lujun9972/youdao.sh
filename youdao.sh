#!/usr/bin/env bash
_DEBUG=0

set -e
cd $(dirname "${BASH_SOURCE[0]}")
function DEBUG()
{
    [[ _DEBUG -ne 0 ]] && echo DEBUG: "$*" >&2
}
# Youdao dictionary Secret Key. You can get it from ai.youdao.com.
declare -r SECRET_KEY="atY68WyfGGoVE5WBc09ihdc2lxZP9sUR"

# Youdao dictionary App Key. You can get it from ai.youdao.com.
declare -r APP_KEY="72c03449033eb239"

# 签名类型
declare -r SIGN_TYPE="v3"

# Youdao dictionary API template, URL `http://dict.youdao.com/'.
declare -r APP_URL="https://openapi.youdao.com/api?q=%s&from=%s&to=%s&appKey=%s&salt=%s&sign=%s&signType=%s&curtime=%s"

# Youdao dictionary API for query the voice of word.
declare -r VOICE_URL="http://dict.youdao.com/dictvoice?type=2&audio=%s"

from="auto"
to="auto"

function get_salt()
{
    echo "${RANDOM}"
}

function get_curtime()
{
    date "+%s"
}

function get_input()
{
    local word="$*"
    local len=$"${#word}"
    if [[ ${len} -gt 20 ]];then
        local input="${word:0:10}${len}${word: -10}"
    else
        local input="${word}"
    fi
    echo "${input}"
}

function get_sign()
{
    local salt="$1"
    local curtime="$2"
    shift 2
    local word="$*"
    local input=$(get_input "${word}")
    local signstr="${APP_KEY}${input}${salt}${curtime}${SECRET_KEY}"
    DEBUG salt=${salt}
    DEBUG curtime=${curtime}
    DEBUG word=${word}
    DEBUG input=${input}
    DEBUG signstr=${signstr}
    echo -n "${signstr}"|sha256sum|cut -f1 -d " "
}

urlencode() {
    local l=${#1}
    for (( i = 0 ; i < l ; i++ )); do
        local c=${1:i:1}
        case "$c" in
            [,\'\\\".-—\+]) printf '%%%.2X' "'$c";;
            ' ') printf + ;;
            *)  printf "$c"
        esac
    done
}

function get_app_url()
{
    local word="$*"
    local query="$(urlencode "${word}")"
    DEBUG query=$query
    local salt="$(get_salt)"
    local curtime=$(get_curtime)
    local sign=$(get_sign "${salt}" "${curtime}" "${word}")
    DEBUG sign=${sign}
    printf "${APP_URL}" "${query}" "${from}" "${to}" "${APP_KEY}" "${salt}" "${sign}" "${SIGN_TYPE}" "${curtime}"
    echo
}

url=$(get_app_url $@)
result=$(curl -s "${url}")
. youdao.cfg
while read field;
do
    eval $field=\"$(echo "${result}"|jq -r ${!field})\"
done < <(cat youdao.cfg|cut -f1 -d "=")
template=$(cat youdao.template)
eval "echo ${template}"
exit ${errorCode}
