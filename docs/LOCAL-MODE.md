# 本地模式启动指南

本地模式（local mode）直接在宿主机上运行 kimi-agent，无需 Docker。适用于计算资源密集型任务（如本地 GPU 推理、直接访问硬件）或不便使用 Docker 的环境。

---

## 与 Docker 模式的区别

| 特性 | Docker 模式 | 本地模式 |
|------|-------------|----------|
| Session 隔离 | 每个 session 独立容器 | 每个 session 独立子进程 |
| 浏览器自动化 | 支持（沙箱内） | 不支持 |
| Jupyter Kernel | 支持（沙箱内） | 不支持 |
| GPU / 硬件访问 | 需额外配置 | 直接访问 |
| 依赖安装 | 镜像内置 | 需手动安装 |

---

## 前置要求

- Python 3.10+
- kimi-cli 依赖已安装（见下方）
- 至少一个 LLM API Key

---

## 安装依赖

```bash
# 从仓库源码安装（推荐）
pip install -e ./kimi-cli

# 安装后验证
python -c "import kimi_cli; print('ok')"
```

---

## 快速启动

```bash
# 自动检测模式（有 Docker daemon 则用 Docker，否则用本地模式）
./scripts/start.sh

# 强制本地模式
./scripts/start.sh --mode=local

# 指定端口
./scripts/start.sh --mode=local --port=8080

# 指定绑定地址（默认 0.0.0.0）
./scripts/start.sh --mode=local --host=127.0.0.1 --port=8080
```

启动后访问 `http://localhost:5494`（或自定义端口）。

---

## 配置

### 方式一：`.env` 文件（推荐）

复制模板并编辑：

```bash
cp .env.example .env
```

本地模式相关配置项：

```bash
# 强制使用本地模式（也可通过 --mode=local 参数指定）
# MODE=local

# LLM 配置（至少填一个）
KIMI_API_KEY=sk-your-key
KIMI_BASE_URL=https://api.moonshot.cn/v1
KIMI_MODEL_NAME=kimi-k2

# Web 服务端口（也可通过 --port 参数覆盖）
KIMI_WEB_PORT=5494

# Web 服务绑定地址（也可通过 --host 参数覆盖）
# KIMI_WEB_HOST=0.0.0.0

# 访问认证 Token
KIMI_WEB_SESSION_TOKEN=your-secret-token

# Session 数据及用户数据库存储目录
# KIMI_SESSION_DATA_DIR=./data/sessions

# 新建 Session 的默认工作目录（未填时默认 ~/.openkimi）
# KIMI_DEFAULT_WORK_DIR=~/.openkimi
```

### 方式二：环境变量

```bash
KIMI_API_KEY=sk-xxx MODE=local ./scripts/start.sh --port=8080
```

---

## 目录结构

本地模式启动后会自动创建以下目录：

```
~/.openkimi/          # 新建 Session 的默认工作目录
./data/sessions/      # Session 历史、用户数据库（users.db）
```

两者均可通过环境变量自定义：

```bash
KIMI_DEFAULT_WORK_DIR=/data/my-workspace
KIMI_SESSION_DATA_DIR=/data/kimi-sessions
```

---

## Skill 加载路径

本地模式按以下优先级加载 skill（高优先级覆盖同名 skill）：

| 优先级 | 来源 | 路径 |
|--------|------|------|
| 1 | Project | `{work_dir}/.kimi/skills`、`.claude/skills`、`.agents/skills` |
| 2 | User (brand) | `~/.kimi/skills` > `~/.claude/skills` > `~/.codex/skills` |
| 3 | User (generic) | `~/.config/agents/skills` > `~/.agents/skills` |
| 4 | Extra | `config.toml` 中的 `extra_skill_dirs` |
| 5 | Plugin | `./data/sessions/plugins/` |
| 6 | Built-in | kimi-cli 包内置 |

> **注意**：Docker 模式的 `CUSTOM_SKILLS_HOST_PATH`（volume 挂载）在本地模式中无效。如需加载项目自定义 skill，可将其放入 `~/.kimi/skills` 或在 `config.toml` 中配置 `extra_skill_dirs`。

---

## 用户系统

本地模式与 Docker 模式使用相同的用户认证系统（SQLite + cookie）。

- 用户数据库位于 `./data/sessions/users.db`
- 首次启动自动创建默认管理员账号：用户名 `admin`，密码 `admin123`
- **首次登录后请立即修改密码**

---

## 常见问题

**启动报错 `kimi_cli package not found`**

```bash
pip install -e ./kimi-cli
```

**端口被占用**

```bash
./scripts/start.sh --mode=local --port=8081
```

**切换到 Docker 模式**

```bash
./scripts/start.sh --mode=docker
```
