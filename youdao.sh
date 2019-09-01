#!/usr/bin/env bash

function DEBUG()
{
    echo "$*" >&2
}
# Youdao dictionary Secret Key. You can get it from ai.youdao.com.
declare -r SECRET_KEY="d3JD42uvOasbJqiPSRYDHCZoiyaSRZwY"

# Youdao dictionary App Key. You can get it from ai.youdao.com.
declare -r APP_KEY="25e15dd7e2d9a14e"

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
    local len=$(echo "${word}"|wc -c)
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
    DEBUG salt=${salt}
    DEBUG curtime=${curtime}
    DEBUG word=${word}
    DEBUG input=${input}
    DEBUG ="${APP_KEY}+${input}+${salt}+${curtime}+${SECRET_KEY}"
    echo "${APP_KEY}${input}${salt}${curtime}${SECRET_KEY}"|sha256sum|cut -f1 -d " "
}

function get_app_url()
{
    local word="$*"
    salt="$(get_salt)"
    curtime=$(get_curtime)
    sign=$(get_sign "${salt}" "${curtime}" "${word}")
    DEBUG sign=${sign}
    printf "${APP_URL}" "${word}" "${from}" "${to}" "${APP_KEY}" "${salt}" "${sign}" "${SIGN_TYPE}" "${curtime}"
    echo
}

url=$(get_app_url "hello")
DEBUG url=$url
curl "${url}"
