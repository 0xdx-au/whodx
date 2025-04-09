#!/bin/bash
set -e

supervisord -c /etc/supervisor/conf.d/supervisord.conf &

if [[ ! -z "$SESSION_TIME" && "$SESSION_TIME" =~ ^[0-9]+$ ]]; then
  SESSION_DURATION=$((SESSION_TIME * 60))
  echo "[⏳] Auto-set session from ENV: ${SESSION_TIME} minutes"
else
  echo "[🕓] Select session duration:"
  options=("1min" "5min" "15min" "30min" "45min" "60min" "Persistent")
  select opt in "${options[@]}"
  do
      echo "You selected: $opt"
      break
  done
  declare -A durations=( ["1min"]=60 ["5min"]=300 ["15min"]=900 ["30min"]=1800 ["45min"]=2700 ["60min"]=3600 ["Persistent"]=-1 )
  SESSION_DURATION=${durations[$opt]}
fi

echo "[🔐] Creating encrypted volume..."
mkdir -p /secure-data
KEY=$(openssl rand -hex 32)
echo $KEY > /tmp/ephemeral.key

dd if=/dev/zero of=/ephemeral.img bs=1M count=100
cryptsetup luksFormat /ephemeral.img --key-file=/tmp/ephemeral.key --batch-mode
cryptsetup luksOpen /ephemeral.img ephemeral --key-file=/tmp/ephemeral.key
mkfs.ext4 /dev/mapper/ephemeral
mount /dev/mapper/ephemeral /secure-data
echo "[🔒] Volume mounted at /secure-data"

IP=$(hostname -I | awk '{print $1}')
echo -e "\n📡 Access noVNC via: https://$IP\n"

sleep 5
echo "[🧅] Checking TOR connectivity..."
tor_check=$(torsocks curl -s https://check.torproject.org/ | grep -o "Congratulations. This browser is configured to use Tor.")
if [[ "$tor_check" != "" ]]; then
  echo "[✅] TOR is ACTIVE and routing traffic"
else
  echo "[❌] TOR is NOT working properly"
fi

if [[ $SESSION_DURATION -gt 0 ]]; then
  echo "⏳ Self-destruct in $SESSION_DURATION seconds..."
  sleep $SESSION_DURATION

  echo "💣 Destroying mount..."
  umount /secure-data
  cryptsetup luksClose ephemeral
  shred -u /ephemeral.img
  shred -u /tmp/ephemeral.key

  echo "🧨 Mount wiped. Killing services..."
  pkill -f supervisor
  rm -rf /etc/ssl/novnc/*
  echo "🔥 Self-destruct complete."
else
  echo "🛡️ Persistent mode. Manual shutdown required."
fi
