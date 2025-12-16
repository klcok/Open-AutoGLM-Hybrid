#!/data/data/com.termux/files/usr/bin/bash

# Open-AutoGLM 混合方案 - Termux 一键部署脚本
# 版本: 1.0.0

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印函数
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo ""
    echo "============================================================"
    echo "  Open-AutoGLM 混合方案 - 一键部署"
    echo "  版本: 1.0.0"
    echo "============================================================"
    echo ""
}

# 检查网络连接
check_network() {
    print_info "检查网络连接..."
    if ping -c 1 8.8.8.8 &> /dev/null; then
        print_success "网络连接正常"
    else
        print_error "网络连接失败，请检查网络设置"
        exit 1
    fi
}

# 更新软件包
update_packages() {
    print_info "更新软件包列表..."
    pkg update -y
    print_success "软件包列表更新完成"
}

# 安装必要软件
install_dependencies() {
    print_info "安装必要软件..."
    
    # 检查并安装 Python
    if ! command -v python &> /dev/null; then
        print_info "安装 Python..."
        pkg install python -y
    else
        print_success "Python 已安装: $(python --version)"
    fi

    # Termux 中的 pip 必须通过包管理器安装/升级（不要用 pip 自己装/升级 pip）
    if ! command -v pip &> /dev/null; then
        print_info "安装 python-pip (Termux)..."
        pkg install python-pip -y
    else
        print_success "pip 已安装: $(pip --version)"
    fi

    # Pillow 在 Termux 上优先使用预编译包，避免从源码编译失败/耗时
    if ! python -c "import PIL" &> /dev/null; then
        print_info "安装 python-pillow (Termux)..."
        pkg install python-pillow -y
    else
        print_success "Pillow 已安装"
    fi
    
    # 检查并安装 Git
    if ! command -v git &> /dev/null; then
        print_info "安装 Git..."
        pkg install git -y
    else
        print_success "Git 已安装: $(git --version)"
    fi

    # 检查并安装 ADB（混合方案中作为兜底/备用：如 Android < 11 截图、或 Helper 不可用时）
    if ! command -v adb &> /dev/null; then
        print_info "安装 Android platform-tools (adb)..."
        pkg install android-tools -y
    else
        print_success "ADB 已安装: $(adb version | head -n 1)"
    fi
    
    # 安装其他工具
    pkg install curl wget -y
    
    print_success "必要软件安装完成"
}

# 安装 Python 依赖
install_python_packages() {
    print_info "安装 Python 依赖包..."

    # 注意：Termux 禁止使用 `pip install --upgrade pip`
    # 如需升级 pip，请使用：pkg upgrade python-pip

    # 兼容 Termux(Python 3.12)：
    # - openai>=1.40.0/2.x 会引入 Rust 依赖（jiter/pydantic-core 等），Termux 上经常缺 wheel
    # - 这里固定 openai==1.39.0，并固定 pydantic<2（避免 pydantic-core）
    # - openai==1.39.0 与 httpx>=0.28 不兼容（httpx 移除了 proxies 参数），需要固定 httpx<0.28
    mkdir -p ~/.autoglm
    cat > ~/.autoglm/constraints.txt << 'EOF'
openai==1.39.0
pydantic<2
httpx<0.28
EOF
    
    # 安装依赖
    pip install --retries 10 --default-timeout 120 "openai==1.39.0" "pydantic<2" "httpx<0.28" requests
    
    print_success "Python 依赖安装完成"
}

# 下载 Open-AutoGLM
download_autoglm() {
    print_info "下载 Open-AutoGLM 项目..."
    
    cd ~
    
    if [ -d "Open-AutoGLM" ]; then
        print_warning "Open-AutoGLM 目录已存在"
        read -p "是否删除并重新下载? (y/n): " confirm
        if [ "$confirm" = "y" ]; then
            rm -rf Open-AutoGLM
        else
            print_info "跳过下载，使用现有目录"
            return
        fi
    fi
    
    git clone https://github.com/zai-org/Open-AutoGLM.git
    
    print_success "Open-AutoGLM 下载完成"
}

# 安装 Open-AutoGLM
install_autoglm() {
    print_info "安装 Open-AutoGLM..."
    
    cd ~/Open-AutoGLM

    # Termux 兼容策略：
    # - Open-AutoGLM 的 requirements/setup.py 会要求 openai>=2.9.0 与 Pillow>=12（在 Termux 上会触发源码编译/依赖冲突）
    # - 我们已经提前用 pkg/pip 装好了可用依赖，所以这里用 --no-deps 跳过依赖解析
    pip install -e . --no-deps
    
    print_success "Open-AutoGLM 安装完成"
}

# 下载混合方案脚本
download_hybrid_scripts() {
    print_info "下载混合方案脚本..."
    
    cd ~
    
    # 创建目录
    mkdir -p ~/.autoglm
    
    # 下载 phone_controller.py (自动降级逻辑)
    # 注意: 这里需要替换为实际的下载链接
    # wget -O ~/.autoglm/phone_controller.py https://your-link/phone_controller.py
    
    # 暂时使用本地创建
    cat > ~/.autoglm/phone_controller.py << 'PYTHON_EOF'
# 这个文件会在后续步骤中创建
pass
PYTHON_EOF
    
    print_success "混合方案脚本下载完成"
}

# 配置 GRS AI
configure_grsai() {
    print_info "配置 GRS AI..."
    
    echo ""
    echo "请输入您的 GRS AI API Key:"
    read -p "API Key: " api_key
    
    if [ -z "$api_key" ]; then
        print_warning "未输入 API Key，跳过配置"
        print_warning "您可以稍后手动配置: export PHONE_AGENT_API_KEY='your_key'"
        return
    fi
    
    # 创建配置文件
    cat > ~/.autoglm/config.sh << EOF
#!/data/data/com.termux/files/usr/bin/bash

# GRS AI 配置
export PHONE_AGENT_BASE_URL="https://api.grsai.com/v1"
export PHONE_AGENT_API_KEY="$api_key"
export PHONE_AGENT_MODEL="gpt-4-vision-preview"

# AutoGLM Helper 配置
export AUTOGLM_HELPER_URL="http://127.0.0.1:8080"
EOF
    
    # 添加到 .bashrc（部分 Termux 环境默认不存在该文件）
    touch ~/.bashrc
    if ! grep -q "source ~/.autoglm/config.sh" ~/.bashrc; then
        echo "" >> ~/.bashrc
        echo "# AutoGLM 配置" >> ~/.bashrc
        echo "source ~/.autoglm/config.sh" >> ~/.bashrc
    fi
    
    # 立即加载配置
    source ~/.autoglm/config.sh
    
    print_success "GRS AI 配置完成"
}

# 创建启动脚本
create_launcher() {
    print_info "创建启动脚本..."
    
    # 创建 autoglm 命令
    mkdir -p ~/bin
    cat > ~/bin/autoglm << 'LAUNCHER_EOF'
#!/data/data/com.termux/files/usr/bin/bash

# 加载配置
source ~/.autoglm/config.sh

# 启动 AutoGLM
cd ~/Open-AutoGLM
python main.py
LAUNCHER_EOF
    
    chmod +x ~/bin/autoglm
    
    # 确保 ~/bin 在 PATH 中
    touch ~/.bashrc
    if ! grep -q 'export PATH=$PATH:~/bin' ~/.bashrc; then
        echo 'export PATH=$PATH:~/bin' >> ~/.bashrc
    fi
    
    print_success "启动脚本创建完成"
}

# 检查 AutoGLM Helper
check_helper_app() {
    print_info "检查 AutoGLM Helper APP..."
    
    echo ""
    echo "请确保您已经:"
    echo "1. 安装了 AutoGLM Helper APK"
    echo "2. 开启了无障碍服务权限"
    echo ""
    
    read -p "是否已完成以上步骤? (y/n): " confirm
    
    if [ "$confirm" != "y" ]; then
        print_warning "请先完成以上步骤，然后重新运行部署脚本"
        print_info "APK 文件位置: 项目根目录/AutoGLM-Helper.apk"
        print_info "安装命令: adb install AutoGLM-Helper.apk"
        exit 0
    fi
    
    # 测试连接
    print_info "测试 AutoGLM Helper 连接..."
    
    if curl -s http://127.0.0.1:8080/status > /dev/null 2>&1; then
        print_success "AutoGLM Helper 连接成功！"
    else
        print_warning "无法连接到 AutoGLM Helper"
        print_info "这可能是因为:"
        print_info "1. AutoGLM Helper 未运行"
        print_info "2. 无障碍服务未开启"
        print_info "3. HTTP 服务器未启动"
        print_info ""
        print_info "请检查后重试"
    fi
}

patch_open_autoglm_for_helper() {
    print_info "为 Open-AutoGLM 打补丁：优先使用 AutoGLM Helper（无障碍），避免强依赖 ADB Keyboard..."

    if [ ! -d "$HOME/Open-AutoGLM" ]; then
        print_warning "未找到 ~/Open-AutoGLM，跳过补丁"
        return
    fi

    # 1) Patch main.py: 如果本地 Helper 可用，则跳过 ADB/ADB Keyboard 的系统自检
    python - <<'PY'
import os
from pathlib import Path

main_py = Path.home() / "Open-AutoGLM" / "main.py"
if not main_py.exists():
    raise SystemExit(0)

s = main_py.read_text(encoding="utf-8")
marker = "# === Hybrid(Helper) Patch ==="
if marker not in s:
    needle = "    all_passed = True\n"
    if needle in s:
        helper_block = (
            f"{needle}"
            f"\n"
            f"    {marker}\n"
            f"    helper_url = os.getenv(\"AUTOGLM_HELPER_URL\")\n"
            f"    if helper_url:\n"
            f"        try:\n"
            f"            import json\n"
            f"            from urllib.request import Request, urlopen\n"
            f"            req = Request(helper_url.rstrip('/') + \"/status\")\n"
            f"            with urlopen(req, timeout=2) as resp:\n"
            f"                data = json.loads(resp.read().decode(\"utf-8\"))\n"
            f"            if resp.status == 200 and data.get(\"accessibility_enabled\"):\n"
            f"                print(\"✅ Detected AutoGLM Helper (accessibility). Skipping ADB Keyboard check.\\n\")\n"
            f"                return True\n"
            f"        except Exception:\n"
            f"            pass\n"
            f"    # === End Hybrid(Helper) Patch ===\n"
        )
        s = s.replace(needle, helper_block, 1)
        main_py.write_text(s, encoding="utf-8")
PY

    # 2) Overwrite adb modules with Helper-aware implementations (keep ADB as fallback)
    adb_dir="$HOME/Open-AutoGLM/phone_agent/adb"
    mkdir -p "$adb_dir"

    cat > "$adb_dir/input.py" <<'PY'
"""Input utilities for Android device text input.

Hybrid mode:
- If AUTOGLM_HELPER_URL is set and reachable, use AutoGLM Helper (/input) to type/clear text.
- Otherwise, fall back to original ADB Keyboard broadcast approach.
"""

import base64
import json
import os
import subprocess
from urllib.error import URLError
from urllib.request import Request, urlopen


def _get_helper_url() -> str | None:
    url = os.getenv("AUTOGLM_HELPER_URL")
    if not url:
        return None
    return url.rstrip("/")


def _helper_post(path: str, payload: dict, timeout: int = 5) -> bool:
    base = _get_helper_url()
    if not base:
        return False
    try:
        data = json.dumps(payload).encode("utf-8")
        req = Request(
            base + path,
            data=data,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        with urlopen(req, timeout=timeout) as resp:
            body = resp.read().decode("utf-8")
        if resp.status != 200:
            return False
        try:
            j = json.loads(body)
            return bool(j.get("success", False))
        except Exception:
            return False
    except Exception:
        return False


def type_text(text: str, device_id: str | None = None) -> None:
    """
    Type text into the currently focused input field.

    In hybrid mode, this uses AutoGLM Helper accessibility (/input),
    so ADB Keyboard is NOT required.
    """
    if _get_helper_url():
        if _helper_post("/input", {"text": text}):
            return
        # If helper is set but temporarily unavailable, fall back to ADB path below.

    adb_prefix = _get_adb_prefix(device_id)
    encoded_text = base64.b64encode(text.encode("utf-8")).decode("utf-8")
    subprocess.run(
        adb_prefix
        + [
            "shell",
            "am",
            "broadcast",
            "-a",
            "ADB_INPUT_B64",
            "--es",
            "msg",
            encoded_text,
        ],
        capture_output=True,
        text=True,
    )


def clear_text(device_id: str | None = None) -> None:
    """Clear text in the currently focused input field."""
    if _get_helper_url():
        if _helper_post("/input", {"text": ""}):
            return

    adb_prefix = _get_adb_prefix(device_id)
    subprocess.run(
        adb_prefix + ["shell", "am", "broadcast", "-a", "ADB_CLEAR_TEXT"],
        capture_output=True,
        text=True,
    )


def detect_and_set_adb_keyboard(device_id: str | None = None) -> str:
    """
    Detect current keyboard and switch to ADB Keyboard if needed.

    In hybrid mode, this becomes a no-op.
    """
    if _get_helper_url():
        return ""

    adb_prefix = _get_adb_prefix(device_id)
    result = subprocess.run(
        adb_prefix + ["shell", "settings", "get", "secure", "default_input_method"],
        capture_output=True,
        text=True,
    )
    current_ime = (result.stdout + result.stderr).strip()
    if "com.android.adbkeyboard/.AdbIME" not in current_ime:
        subprocess.run(
            adb_prefix + ["shell", "ime", "set", "com.android.adbkeyboard/.AdbIME"],
            capture_output=True,
            text=True,
        )
    # Warm up
    type_text("", device_id)
    return current_ime


def restore_keyboard(ime: str, device_id: str | None = None) -> None:
    """Restore the original keyboard IME (no-op in hybrid mode)."""
    if _get_helper_url():
        return
    if not ime:
        return
    adb_prefix = _get_adb_prefix(device_id)
    subprocess.run(
        adb_prefix + ["shell", "ime", "set", ime], capture_output=True, text=True
    )


def _get_adb_prefix(device_id: str | None) -> list:
    if device_id:
        return ["adb", "-s", device_id]
    return ["adb"]
PY

    cat > "$adb_dir/device.py" <<'PY'
"""Device control utilities for Android automation.

Hybrid mode:
- If AUTOGLM_HELPER_URL is set, use AutoGLM Helper accessibility for tap/swipe/long-press
  and optionally current app detection.
- Keep ADB as fallback for actions not covered by Helper (launch/back/home, etc.).
"""

import json
import os
import subprocess
import time
from urllib.request import Request, urlopen

from phone_agent.config.apps import APP_PACKAGES
from phone_agent.config.speed import ACTION_DELAY, LAUNCH_DELAY


def _get_helper_url() -> str | None:
    url = os.getenv("AUTOGLM_HELPER_URL")
    if not url:
        return None
    return url.rstrip("/")


def _helper_get(path: str, timeout: int = 3) -> dict | None:
    base = _get_helper_url()
    if not base:
        return None
    try:
        req = Request(base + path, method="GET")
        with urlopen(req, timeout=timeout) as resp:
            body = resp.read().decode("utf-8")
        if resp.status != 200:
            return None
        return json.loads(body)
    except Exception:
        return None


def _helper_post(path: str, payload: dict, timeout: int = 5) -> dict | None:
    base = _get_helper_url()
    if not base:
        return None
    try:
        data = json.dumps(payload).encode("utf-8")
        req = Request(
            base + path,
            data=data,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        with urlopen(req, timeout=timeout) as resp:
            body = resp.read().decode("utf-8")
        if resp.status != 200:
            return None
        return json.loads(body)
    except Exception:
        return None


def get_current_app(device_id: str | None = None) -> str:
    """
    Get the currently focused app name.
    """
    # Prefer Helper (if it implements /current_app)
    data = _helper_get("/current_app")
    if data and data.get("accessibility_enabled") and data.get("package"):
        pkg = data["package"]
        for app_name, package in APP_PACKAGES.items():
            if package == pkg:
                return app_name
        return str(pkg)

    # Fallback to ADB dumpsys
    adb_prefix = _get_adb_prefix(device_id)
    result = subprocess.run(
        adb_prefix + ["shell", "dumpsys", "window"], capture_output=True, text=True
    )
    output = result.stdout
    for line in output.split("\n"):
        if "mCurrentFocus" in line or "mFocusedApp" in line:
            for app_name, package in APP_PACKAGES.items():
                if package in line:
                    return app_name
    return "System Home"


def tap(x: int, y: int, device_id: str | None = None, delay: float = ACTION_DELAY) -> None:
    # Prefer Helper
    resp = _helper_post("/tap", {"x": x, "y": y}, timeout=5)
    if resp and resp.get("success") is True:
        time.sleep(delay)
        return

    adb_prefix = _get_adb_prefix(device_id)
    subprocess.run(
        adb_prefix + ["shell", "input", "tap", str(x), str(y)], capture_output=True
    )
    time.sleep(delay)


def double_tap(x: int, y: int, device_id: str | None = None, delay: float = ACTION_DELAY) -> None:
    # Helper: two taps
    base = _get_helper_url()
    if base:
        tap(x, y, device_id=device_id, delay=0.1)
        tap(x, y, device_id=device_id, delay=delay)
        return

    adb_prefix = _get_adb_prefix(device_id)
    subprocess.run(
        adb_prefix + ["shell", "input", "tap", str(x), str(y)], capture_output=True
    )
    time.sleep(0.1)
    subprocess.run(
        adb_prefix + ["shell", "input", "tap", str(x), str(y)], capture_output=True
    )
    time.sleep(delay)


def long_press(
    x: int,
    y: int,
    duration_ms: int = 3000,
    device_id: str | None = None,
    delay: float = ACTION_DELAY,
) -> None:
    # Helper: use swipe with same start/end to emulate long press
    resp = _helper_post(
        "/swipe",
        {"x1": x, "y1": y, "x2": x, "y2": y, "duration": int(duration_ms)},
        timeout=10,
    )
    if resp and resp.get("success") is True:
        time.sleep(delay)
        return

    adb_prefix = _get_adb_prefix(device_id)
    subprocess.run(
        adb_prefix
        + ["shell", "input", "swipe", str(x), str(y), str(x), str(y), str(duration_ms)],
        capture_output=True,
    )
    time.sleep(delay)


def swipe(
    start_x: int,
    start_y: int,
    end_x: int,
    end_y: int,
    duration_ms: int | None = None,
    device_id: str | None = None,
    delay: float = ACTION_DELAY,
) -> None:
    if duration_ms is None:
        dist_sq = (start_x - end_x) ** 2 + (start_y - end_y) ** 2
        duration_ms = int(dist_sq / 1000)
        duration_ms = max(1000, min(duration_ms, 2000))

    resp = _helper_post(
        "/swipe",
        {"x1": start_x, "y1": start_y, "x2": end_x, "y2": end_y, "duration": int(duration_ms)},
        timeout=10,
    )
    if resp and resp.get("success") is True:
        time.sleep(delay)
        return

    adb_prefix = _get_adb_prefix(device_id)
    subprocess.run(
        adb_prefix
        + [
            "shell",
            "input",
            "swipe",
            str(start_x),
            str(start_y),
            str(end_x),
            str(end_y),
            str(duration_ms),
        ],
        capture_output=True,
    )
    time.sleep(delay)


def back(device_id: str | None = None, delay: float = ACTION_DELAY) -> None:
    adb_prefix = _get_adb_prefix(device_id)
    subprocess.run(adb_prefix + ["shell", "input", "keyevent", "4"], capture_output=True)
    time.sleep(delay)


def home(device_id: str | None = None, delay: float = ACTION_DELAY) -> None:
    adb_prefix = _get_adb_prefix(device_id)
    subprocess.run(
        adb_prefix + ["shell", "input", "keyevent", "KEYCODE_HOME"], capture_output=True
    )
    time.sleep(delay)


def launch_app(app_name: str, device_id: str | None = None, delay: float = LAUNCH_DELAY) -> bool:
    if app_name not in APP_PACKAGES:
        return False
    adb_prefix = _get_adb_prefix(device_id)
    package = APP_PACKAGES[app_name]
    subprocess.run(
        adb_prefix
        + [
            "shell",
            "monkey",
            "-p",
            package,
            "-c",
            "android.intent.category.LAUNCHER",
            "1",
        ],
        capture_output=True,
    )
    time.sleep(delay)
    return True


def _get_adb_prefix(device_id: str | None) -> list:
    if device_id:
        return ["adb", "-s", device_id]
    return ["adb"]
PY

    cat > "$adb_dir/screenshot.py" <<'PY'
"""Screenshot utilities for capturing Android device screen.

Hybrid mode:
- If AUTOGLM_HELPER_URL is set, try GET /screenshot and convert to PNG base64.
- Otherwise, fall back to ADB screencap.
"""

import base64
import json
import os
import subprocess
import tempfile
import uuid
from dataclasses import dataclass
from io import BytesIO
from urllib.request import Request, urlopen

from PIL import Image


@dataclass
class Screenshot:
    base64_data: str
    width: int
    height: int
    is_sensitive: bool = False


def _get_helper_url() -> str | None:
    url = os.getenv("AUTOGLM_HELPER_URL")
    if not url:
        return None
    return url.rstrip("/")


def get_screenshot(device_id: str | None = None, timeout: int = 5) -> Screenshot:
    helper = _get_helper_url()
    if helper:
        try:
            req = Request(helper + "/screenshot", method="GET")
            with urlopen(req, timeout=timeout) as resp:
                body = resp.read().decode("utf-8")
            if resp.status == 200:
                data = json.loads(body)
                if data.get("success") and data.get("image"):
                    raw = base64.b64decode(data["image"])
                    img = Image.open(BytesIO(raw))
                    width, height = img.size
                    buffered = BytesIO()
                    img.save(buffered, format="PNG")
                    b64 = base64.b64encode(buffered.getvalue()).decode("utf-8")
                    return Screenshot(base64_data=b64, width=width, height=height, is_sensitive=False)
        except Exception:
            # Helper not reachable: fall back to ADB
            pass

    temp_path = os.path.join(tempfile.gettempdir(), f"screenshot_{uuid.uuid4()}.png")
    adb_prefix = _get_adb_prefix(device_id)
    try:
        result = subprocess.run(
            adb_prefix + ["shell", "screencap", "-p", "/sdcard/tmp.png"],
            capture_output=True,
            text=True,
            timeout=timeout,
        )
        output = result.stdout + result.stderr
        if "Status: -1" in output or "Failed" in output:
            return _create_fallback_screenshot(is_sensitive=True)
        subprocess.run(
            adb_prefix + ["pull", "/sdcard/tmp.png", temp_path],
            capture_output=True,
            text=True,
            timeout=5,
        )
        if not os.path.exists(temp_path):
            return _create_fallback_screenshot(is_sensitive=False)
        img = Image.open(temp_path)
        width, height = img.size
        buffered = BytesIO()
        img.save(buffered, format="PNG")
        base64_data = base64.b64encode(buffered.getvalue()).decode("utf-8")
        os.remove(temp_path)
        return Screenshot(base64_data=base64_data, width=width, height=height, is_sensitive=False)
    except Exception as e:
        print(f"Screenshot error: {e}")
        return _create_fallback_screenshot(is_sensitive=False)


def _get_adb_prefix(device_id: str | None) -> list:
    if device_id:
        return ["adb", "-s", device_id]
    return ["adb"]


def _create_fallback_screenshot(is_sensitive: bool) -> Screenshot:
    default_width, default_height = 1080, 2400
    black_img = Image.new("RGB", (default_width, default_height), color="black")
    buffered = BytesIO()
    black_img.save(buffered, format="PNG")
    base64_data = base64.b64encode(buffered.getvalue()).decode("utf-8")
    return Screenshot(
        base64_data=base64_data,
        width=default_width,
        height=default_height,
        is_sensitive=is_sensitive,
    )
PY

    # 3) Ensure speed config exists (some forks/branches may miss it)
    cfg_dir="$HOME/Open-AutoGLM/phone_agent/config"
    mkdir -p "$cfg_dir"
    touch "$cfg_dir/__init__.py" >/dev/null 2>&1 || true
    if [ ! -f "$cfg_dir/speed.py" ]; then
        cat > "$cfg_dir/speed.py" <<'PY'
"""速度优化配置

某些分支/精简版可能缺失此文件，导致 import phone_agent.config.speed 失败。
这里提供默认值，确保 Open-AutoGLM 可运行。
"""

# 操作后延迟时间（秒）
ACTION_DELAY = 0.3

# 打开应用后延迟
LAUNCH_DELAY = 0.5

# 键盘切换/输入延迟（即使走 Helper 也会被 handler 引用）
KEYBOARD_SWITCH_DELAY = 0.3
TEXT_INPUT_DELAY = 0.2

# 截图超时（备用）
SCREENSHOT_TIMEOUT = 5
PY
    fi

    print_success "Open-AutoGLM 补丁完成（Helper 优先，ADB Keyboard 不再是硬依赖）"
}

# 显示完成信息
show_completion() {
    print_success "部署完成！"
    
    echo ""
    echo "============================================================"
    echo "  部署成功！"
    echo "============================================================"
    echo ""
    echo "使用方法:"
    echo "  1. 确保 AutoGLM Helper 已运行并开启无障碍权限"
    echo "  2. 在 Termux 中输入: autoglm"
    echo "  3. 输入任务，如: 打开淘宝搜索蓝牙耳机"
    echo ""
    echo "配置文件:"
    echo "  ~/.autoglm/config.sh"
    echo ""
    echo "启动命令:"
    echo "  autoglm"
    echo ""
    echo "故障排除:"
    echo "  - 检查 AutoGLM Helper 是否运行"
    echo "  - 检查无障碍权限是否开启"
    echo "  - 测试连接: curl http://127.0.0.1:8080/status"
    echo ""
    echo "============================================================"
    echo ""
}

# 主函数
main() {
    print_header
    
    # 检查是否在 Termux 中运行
    if [ ! -d "/data/data/com.termux" ]; then
        print_error "此脚本必须在 Termux 中运行！"
        exit 1
    fi
    
    # 执行部署步骤
    check_network
    update_packages
    install_dependencies
    install_python_packages
    download_autoglm
    install_autoglm
    download_hybrid_scripts
    configure_grsai
    create_launcher
    patch_open_autoglm_for_helper
    check_helper_app
    show_completion
}

# 运行主函数
main
