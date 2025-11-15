#!/bin/bash

log_with_style() {
  local level="$1"
  local message="$2"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  printf "\n[%s] [%7s]  %s\n" "${timestamp}" "${level}" "${message}"
}

if [[ -n "$USERNAME" ]] && [[ -n "$USERID" ]]; then
  log_with_style "INFO" "🚀 0. 创建用户: $USERNAME uid=$USERID"

  useradd -u "$USERID" "$USERNAME" 2>/dev/null || true

  HOME_DIR="/home/$USERNAME"

  mkdir -p "$HOME_DIR/bin"
  mkdir -p "$HOME_DIR/.ssh"

  chmod 700 "$HOME_DIR/.ssh"
  chown -R "$USERID:$USERID" "$HOME_DIR"

  export HOME="$HOME_DIR"

  # 切换用户重新执行当前脚本（递归一层）
  exec su "$USERNAME" -s /bin/bash -c "env USERNAME=$USERNAME HOME=$HOME_DIR PATH=$PATH $0 $*"
fi


export PATH="$HOME/bin:$PATH"

dir_shell=/ql/shell
. $dir_shell/share.sh

export_ql_envs() {
  export BACK_PORT="${ql_port}"
  export GRPC_PORT="${ql_grpc_port}"
}

log_with_style "INFO" "🚀 1. 检测配置文件..."
load_ql_envs
export_ql_envs
. $dir_shell/env.sh
import_config "$@"
fix_config

pm2 l &>/dev/null

log_with_style "INFO" "⚙️  2. 启动 pm2 服务..."
reload_pm2

if [[ $AutoStartBot == true ]]; then
  log_with_style "INFO" "🤖 3. 启动 bot..."
  nohup ql bot >$dir_log/bot.log 2>&1 &
fi

if [[ $EnableExtraShell == true ]]; then
  log_with_style "INFO" "🛠️ 4. 执行自定义脚本..."
  nohup ql extra >$dir_log/extra.log 2>&1 &
fi

log_with_style "SUCCESS" "🎉 容器启动成功!"

crond -f >/dev/null

exec "$@"
