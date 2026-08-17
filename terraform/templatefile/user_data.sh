#!/bin/bash
set -euo pipefail
SOURCE_REPO_URL="${source_repo_url}"
SOURCE_REF="${source_ref}"
yum makecache
yum install -y git vim python3 python3-pip python3-devel alsa-lib-devel firewalld unzip wget
dnf -y install oraclelinux-developer-release-el9
dnf -y install python39-oci-cli
pip3 install oci oracledb python-dotenv
systemctl start firewalld
systemctl enable firewalld
firewall-cmd --add-port=8501/tcp --permanent
firewall-cmd --add-port=5901/tcp --permanent
firewall-cmd --reload
dnf -y install python3.11 python3.11-devel
python3.11 -m venv /home/opc/.venv
chown -R opc:opc /home/opc/.venv
echo 'if [ -d "$$HOME/.venv" ]; then source "$$HOME/.venv/bin/activate"; fi' >> /home/opc/.bashrc
chown opc:opc /home/opc/.bashrc
sudo -u opc -i bash -c 'source ~/.bashrc && python -m ensurepip --upgrade --default-pip'
sudo -u opc -i bash -c 'source ~/.bashrc && python -m pip install --upgrade pip wheel setuptools'
yum install -y gcc make autoconf automake libtool alsa-lib-devel git
if [ ! -d "/root/portaudio" ]; then
  git clone --depth=1 https://github.com/PortAudio/portaudio.git /root/portaudio
fi
cd /root/portaudio
./configure --prefix=/usr/local
make -j"$(nproc)"
make install
echo '/usr/local/lib' > /etc/ld.so.conf.d/portaudio.conf
ldconfig
git clone --depth=1 --branch "$SOURCE_REF" "$SOURCE_REPO_URL" /home/opc/oracle-ai-accelerator
chown -R opc:opc /home/opc/oracle-ai-accelerator
python3 - <<'PY'
from pathlib import Path

setup_py = Path("/home/opc/oracle-ai-accelerator/setup/setup.py")
setup_text = setup_py.read_text(encoding="utf-8")
setup_text = setup_text.replace(
    "        print(f'[Query]:')\n",
    "        print('[Query]: statements redacted by CloudTechNext')\n",
)
setup_text = setup_text.replace(
    "            print(f'  > {statement}\\n')\n",
    "            print('  > [statement redacted]')\n",
)
setup_py.write_text(setup_text, encoding="utf-8")

users_sql = Path("/home/opc/oracle-ai-accelerator/setup/autonomous_database/developer/c.TABLE_USERS.sql")
users_text = users_sql.read_text(encoding="utf-8")
old = "        'admin', \n        'admin',\n        'p_a_s_s_w_o_r_d',"
new = "        'admin', \n        'p_a_s_s_w_o_r_d',\n        'p_a_s_s_w_o_r_d',"
if old not in users_text:
    raise SystemExit("Could not patch default application password in c.TABLE_USERS.sql")
users_sql.write_text(users_text.replace(old, new), encoding="utf-8")
PY
chown -R opc:opc /home/opc/oracle-ai-accelerator/setup
mkdir -p /home/opc/.oci
echo "${oci_config_content}" > /home/opc/.oci/config
echo "${oci_key_content}" > /home/opc/.oci/key.pem
chmod 600 /home/opc/.oci/*
chown -R opc:opc /home/opc/.oci
mkdir -p /home/opc/oracle-ai-accelerator/app/wallet
OCI_CLI_CONFIG_FILE=/home/opc/.oci/config oci os object get \
  --bucket-name ${bucket_name} \
  --name adb_wallet.zip \
  --file /home/opc/oracle-ai-accelerator/app/wallet/adb_wallet_encoded.zip
base64 -d /home/opc/oracle-ai-accelerator/app/wallet/adb_wallet_encoded.zip > \
        /home/opc/oracle-ai-accelerator/app/wallet/adb_wallet.zip
rm -f /home/opc/oracle-ai-accelerator/app/wallet/adb_wallet_encoded.zip
unzip /home/opc/oracle-ai-accelerator/app/wallet/adb_wallet.zip \
      -d /home/opc/oracle-ai-accelerator/app/wallet
OCI_CLI_CONFIG_FILE=/home/opc/.oci/config oci os object delete \
  --bucket-name ${bucket_name} \
  --name adb_wallet.zip \
  --force
echo "${env}" > /home/opc/oracle-ai-accelerator/app/.env
chmod 600 /home/opc/oracle-ai-accelerator/app/.env
chown opc:opc /home/opc/oracle-ai-accelerator/app/.env
sudo -u opc -i bash <<'EOF'
cd /home/opc/oracle-ai-accelerator/setup
source /home/opc/.venv/bin/activate
python --version
python setup.py
deactivate
EOF

# Step 13: Launch multiple Streamlit workers (4 instances) on different ports
sudo -u opc -i bash <<'EOF'
cd /home/opc/oracle-ai-accelerator/app
source /home/opc/.venv/bin/activate
echo "Using Python from: $(which python)"

# Launch 4 workers on ports 8501-8504
for PORT in 8501 8502 8503 8504; do
    echo "Starting worker on port $PORT..."
    nohup python -m streamlit run app.py \
        --server.port $PORT \
        --server.address 127.0.0.1 \
        --logger.level=INFO \
        > /home/opc/streamlit_$PORT.log 2>&1 &
    
    # Save worker PID
    echo $! > /home/opc/streamlit_$PORT.pid
    echo "Worker on port $PORT started with PID $(cat /home/opc/streamlit_$PORT.pid)"
    
    # Wait a bit between each worker
    sleep 2
done

deactivate || true
exit 0
EOF

# Step 14: Create monitoring and management scripts
cat > /home/opc/health_check.sh <<'HEALTHCHECK'
#!/bin/bash
# Health check script for Streamlit workers
# Runs every 5 minutes via cron

PORTS=(8501 8502 8503 8504)
LOGFILE="/home/opc/health_check.log"

echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting workers health check" >> "$LOGFILE"

for PORT in "$${PORTS[@]}"; do
    if ! ss -tuln | grep -q ":$PORT "; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: Worker on port $PORT not listening" >> "$LOGFILE"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - OK: Worker on port $PORT running" >> "$LOGFILE"
    fi
done
HEALTHCHECK

chmod +x /home/opc/health_check.sh
chown opc:opc /home/opc/health_check.sh

cat > /home/opc/restart_worker.sh <<'RESTARTSCRIPT'
#!/bin/bash
# Script to restart a specific Streamlit worker
# Usage: ./restart_worker.sh [PORT]

PORT=$${1:-8501}
APP_DIR="/home/opc/oracle-ai-accelerator/app"
LOGFILE="/home/opc/streamlit_$PORT.log"
PIDFILE="/home/opc/streamlit_$PORT.pid"

echo "$(date '+%Y-%m-%d %H:%M:%S') - Restarting worker on port $PORT"

# Stop existing worker if running
if [ -f "$PIDFILE" ]; then
    PID=$(cat "$PIDFILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        kill "$PID" 2>/dev/null
        sleep 2
    fi
    rm -f "$PIDFILE"
fi

# Start worker
cd "$APP_DIR" || exit 1
source /home/opc/.venv/bin/activate

nohup python -m streamlit run app.py \
    --server.port "$PORT" \
    --server.address 127.0.0.1 \
    --logger.level=INFO \
    > "$LOGFILE" 2>&1 &

echo $! > "$PIDFILE"
echo "Worker on port $PORT restarted with PID $(cat $PIDFILE)"
deactivate
RESTARTSCRIPT

chmod +x /home/opc/restart_worker.sh
chown opc:opc /home/opc/restart_worker.sh

# Add cron job for health check every 5 minutes when crontab is available.
if command -v crontab >/dev/null 2>&1; then
  (crontab -u opc -l 2>/dev/null; echo "*/5 * * * * /home/opc/health_check.sh") | crontab -u opc -
else
  echo "crontab not available; skipping scheduled health check"
fi

# Step 15: Install and configure Nginx as Load Balancer for multiple Streamlit workers
bash <<'EOF'
set -euo pipefail
dnf -y install oracle-epel-release-el9 || true
dnf -y install nginx openssl policycoreutils-python-utils || dnf -y install nginx openssl

# Allow Nginx to connect to upstreams (Streamlit) with SELinux enforcing
setsebool -P httpd_can_network_connect 1 || true

# Open HTTP/HTTPS
firewall-cmd --add-service=http --permanent || true
firewall-cmd --add-service=https --permanent || true
firewall-cmd --reload || true

# Remove default configurations
rm -f /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/welcome.conf /etc/nginx/conf.d/example_ssl.conf 2>/dev/null || true

# Nginx Load Balancer config for multiple Streamlit workers with sticky sessions
cat >/etc/nginx/conf.d/streamlit.conf <<'NGINXCONF'
upstream streamlit_backend {
    # Use IP hash for sticky sessions - same client always goes to same worker
    ip_hash;
    
    server 127.0.0.1:8501;
    server 127.0.0.1:8502;
    server 127.0.0.1:8503;
    server 127.0.0.1:8504;
}

server {
    listen 80;
    listen [::]:80;
    server_name _;

    client_max_body_size 500m;
    
    # Increase timeouts for better stability
    proxy_connect_timeout 600s;
    proxy_send_timeout 600s;
    proxy_read_timeout 600s;
    send_timeout 600s;

    location / {
        proxy_pass http://streamlit_backend;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Disable buffering for real-time updates
        proxy_buffering off;
        proxy_cache off;
    }

    location /_health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
NGINXCONF

systemctl enable nginx
systemctl restart nginx

# Create a self-signed certificate and enable HTTPS
mkdir -p /etc/ssl/private
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/streamlit-selfsigned.key \
  -out /etc/ssl/certs/streamlit-selfsigned.crt \
  -subj "/CN=localhost"

# SSL configuration with Load Balancer and sticky sessions
cat >/etc/nginx/conf.d/streamlit-ssl.conf <<'NGINXSSL'
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name _;

    ssl_certificate     /etc/ssl/certs/streamlit-selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/streamlit-selfsigned.key;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:10m;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;

    client_max_body_size 500m;
    
    # Increase timeouts for better stability
    proxy_connect_timeout 600s;
    proxy_send_timeout 600s;
    proxy_read_timeout 600s;
    send_timeout 600s;

    location / {
        proxy_pass http://streamlit_backend;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Disable buffering for real-time updates
        proxy_buffering off;
        proxy_cache off;
    }
}
NGINXSSL

nginx -t
systemctl reload nginx || true
EOF

# Step 16: Create system resources monitoring script
cat > /home/opc/monitor_system.sh <<'MONITOR'
#!/bin/bash
# System resources monitoring script
# Displays CPU, memory, and worker status

echo "=== System Resources Monitor ==="
echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
echo "--- CPU ---"
top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print "CPU Usage: " 100 - $1"%"}'
echo ""
echo "--- Memory ---"
free -h
echo ""
echo "--- Streamlit Workers ---"
for PORT in 8501 8502 8503 8504; do
    if ss -tuln | grep -q ":$PORT "; then
        PID=$(cat /home/opc/streamlit_$PORT.pid 2>/dev/null || echo "N/A")
        if [ "$PID" != "N/A" ] && ps -p "$PID" > /dev/null 2>&1; then
            MEM=$(ps -p "$PID" -o rss= | awk '{printf "%.2f MB", $1/1024}')
            CPU=$(ps -p "$PID" -o %cpu= | awk '{printf "%.1f%%", $1}')
            echo "Worker :$PORT [PID: $PID] - CPU: $CPU, MEM: $MEM - ✓ RUNNING"
        else
            echo "Worker :$PORT - ✗ NOT RUNNING (invalid PID)"
        fi
    else
        echo "Worker :$PORT - ✗ NOT LISTENING"
    fi
done
echo ""
echo "--- Nginx Status ---"
systemctl is-active nginx >/dev/null 2>&1 && echo "Nginx: ✓ RUNNING" || echo "Nginx: ✗ STOPPED"
MONITOR

chmod +x /home/opc/monitor_system.sh
chown opc:opc /home/opc/monitor_system.sh

# Step 17: Create load testing script
cat > /home/opc/load_test_results.txt <<'LOADTEST_SKIPPED'
LOAD TEST RESULTS:
   Skipped during automated provisioning.
   Run load testing manually after validating the app URL.
LOADTEST_SKIPPED

: <<'LOADTEST_DISABLED'
cat > /home/opc/load_test.sh <<'LOADTEST'
#!/bin/bash
# Load testing script for Streamlit multi-worker setup
# Runs incremental load tests and generates capacity report

OUTPUT_FILE="/home/opc/load_test_results.txt"

echo "Starting load testing to determine capacity..."

# Function to run load test and parse results
run_load_test() {
    local users=$1
    local requests=$((users * 10))
    
    # Run Apache Bench test
    result=$(ab -n $requests -c $users -k -t 30 http://127.0.0.1/ 2>&1)
    
    # Parse results
    failed=$(echo "$result" | grep "Failed requests:" | awk '{print $3}')
    total=$(echo "$result" | grep "Complete requests:" | awk '{print $3}')
    avg_time=$(echo "$result" | grep "Time per request:" | head -1 | awk '{print $4}')
    
    # Calculate fail percentage
    if [ "$total" -gt 0 ]; then
        fail_pct=$(awk "BEGIN {printf \"%.1f\", ($failed/$total)*100}")
    else
        fail_pct="100.0"
    fi
    
    # Convert ms to seconds
    avg_sec=$(awk "BEGIN {printf \"%.1f\", $avg_time/1000}")
    
    # Determine status emoji
    if (( $(echo "$fail_pct < 1" | bc -l) )); then
        status="✅"
    elif (( $(echo "$fail_pct < 5" | bc -l) )); then
        status="⚠️ "
    else
        status="❌"
    fi
    
    echo "$users|$fail_pct|$avg_sec|$status"
}

# Run incremental load tests
echo "Running load tests with 10, 25, 50, 75, 100 concurrent users..."

test_10=$(run_load_test 10)
sleep 5
test_25=$(run_load_test 25)
sleep 5
test_50=$(run_load_test 50)
sleep 5
test_75=$(run_load_test 75)
sleep 5
test_100=$(run_load_test 100)

# Parse results
IFS='|' read -r u10 f10 t10 s10 <<< "$test_10"
IFS='|' read -r u25 f25 t25 s25 <<< "$test_25"
IFS='|' read -r u50 f50 t50 s50 <<< "$test_50"
IFS='|' read -r u75 f75 t75 s75 <<< "$test_75"
IFS='|' read -r u100 f100 t100 s100 <<< "$test_100"

# Determine recommended capacity
if (( $(echo "$f50 < 5" | bc -l) )); then
    capacity="~50-75 concurrent users"
elif (( $(echo "$f25 < 5" | bc -l) )); then
    capacity="~25-40 concurrent users"
else
    capacity="~10-20 concurrent users"
fi

# Save results to file using echo to properly expand variables
echo "📊 LOAD TEST RESULTS:" > $OUTPUT_FILE
echo "   ├─ $u10 users  → $s10 $${f10}% fails, $${t10}s avg" >> $OUTPUT_FILE
echo "   ├─ $u25 users  → $s25 $${f25}% fails, $${t25}s avg" >> $OUTPUT_FILE
echo "   ├─ $u50 users  → $s50 $${f50}% fails, $${t50}s avg" >> $OUTPUT_FILE
echo "   ├─ $u75 users  → $s75 $${f75}% fails, $${t75}s avg" >> $OUTPUT_FILE
echo "   └─ $u100 users → $s100 $${f100}% fails, $${t100}s avg" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE
echo "   Recommended capacity: $capacity" >> $OUTPUT_FILE

echo "Load testing completed. Results saved to $OUTPUT_FILE"
LOADTEST

chmod +x /home/opc/load_test.sh
chown opc:opc /home/opc/load_test.sh

# Install Apache Bench and run load testing
yum install -y httpd-tools
sleep 10
sudo -u opc /home/opc/load_test.sh
LOADTEST_DISABLED

# Step 18: Display startup information
cat > /home/opc/startup_info.txt <<'INFO'
╔══════════════════════════════════════════════════════════════════════╗
             APPLICATION ACCESS: HTTPS: https://[PUBLIC-IP]
╚══════════════════════════════════════════════════════════════════════╝
   
⚠️  NOTE: The SSL certificate is self-signed. Your browser will show
    a security warning. For production, configure a valid certificate
    with Let's Encrypt.

🔧 USEFUL COMMANDS:
   - View system status:          ./monitor_system.sh
   - Check workers:               ./health_check.sh
   - Restart worker:              ./restart_worker.sh [PORT]
   - Worker logs:                 tail -f streamlit_8501.log
   - Nginx logs:                  sudo tail -f /var/log/nginx/error.log
   - Nginx status:                sudo systemctl status nginx

INFO

# Append load test results at the end
echo "" >> /home/opc/startup_info.txt
cat /home/opc/load_test_results.txt >> /home/opc/startup_info.txt

chown opc:opc /home/opc/startup_info.txt

# Step 19: Mark userdata completion (sentinel)
mkdir -p /var/local
touch /var/local/userdata.done

# Display startup information
cat /home/opc/startup_info.txt
