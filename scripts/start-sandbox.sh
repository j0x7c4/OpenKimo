#!/bin/bash
set -e

echo "========================================" >&2
echo "  kimi-agent-sandbox starting up..." >&2
echo "========================================" >&2

# -----------------------------------------------------------
# 1. 启动虚拟显示 (Xvfb)
# -----------------------------------------------------------
if [ "$ENABLE_BROWSER" != "false" ]; then
    echo "[1/4] Starting Xvfb virtual display..." >&2
    export DISPLAY=:99
    Xvfb :99 -screen 0 1920x1080x24 -ac +extension GLX +render -noreset &
    sleep 1
    echo "      Xvfb started on DISPLAY=:99" >&2
fi

# -----------------------------------------------------------
# 2. 启动 Jupyter Kernel Server
# -----------------------------------------------------------
if [ "$ENABLE_JUPYTER" != "false" ]; then
    echo "[2/4] Starting Jupyter Kernel Server..." >&2
    python /app/kernel_server.py \
        --host 0.0.0.0 \
        --port "${JUPYTER_KERNEL_PORT:-8888}" \
        --log-level info > /app/logs/kernel_server.log 2>&1 &
    KERNEL_PID=$!
    echo "      Kernel Server PID: $KERNEL_PID" >&2
fi

# -----------------------------------------------------------
# 3. 启动 Browser Guard (后台)
# -----------------------------------------------------------
if [ "$ENABLE_BROWSER" != "false" ]; then
    echo "[3/4] Starting Browser Guard..." >&2
    # Wait for display using xdotool (lightweight, no .Xauthority needed)
    for i in {1..30}; do
        if DISPLAY=:99 xdotool getdisplaygeometry > /dev/null 2>&1; then
            echo "      Display is ready" >&2
            break
        fi
        sleep 0.5
    done
    # BrowserGuard 在 monitor 模式下持续运行
    python /app/browser_guard.py --monitor > /app/logs/browser_guard.log 2>&1 &
    BROWSER_PID=$!
    echo "      Browser Guard PID: $BROWSER_PID" >&2
fi

# -----------------------------------------------------------
# 4. 启动 KimiCLI Worker (前台)
# -----------------------------------------------------------
echo "[4/4] Starting KimiCLI Worker..." >&2
echo "      Session ID: ${KIMI_SESSION_ID:-unknown}" >&2
echo "      Work Dir: ${KIMI_WORK_DIR:-/app}" >&2
echo "" >&2

# 等待必要的服务就绪
sleep 2

# 启动 Worker (JSON-RPC over stdin/stdout，由 Gateway 管道代理)
exec python -m kimi_cli.web.runner.worker "${KIMI_SESSION_ID:-default}"
