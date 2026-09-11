# 开发模板

新项目不从零搭骨架，直接基于公司模板创建仓库，保证日志、监控、部署配置开箱即用。

## Flask 模板（flask_starter）

- 仓库：https://github.com/wuhanchu/flask_starter （Public template，直接 Use this template 创建新仓库）
- 技术栈：Python 3.12+ / Flask / [flask_frame](https://github.com/bistro-x/flask_frame) / Gunicorn + Gevent / Docker

### 内置能力

- **统一入口**：`run.py` 创建应用，自动加载扩展和业务模块，默认带 `/`、`/healthy`（健康检查）、`/flask/log*`（日志查看）路由
- **扩展按需开启**：`ENABLED_EXTENSION` 列表声明即可自动加载 flask_frame 内置扩展
- **模块化开发**：`module/` 下实现 `init_app(app)` 注册蓝图，`ENABLED_MODULE` 声明后自动挂载
- **多环境配置**：`FLASK_CONFIG` 环境变量切换 development / production
- **容器部署**：`docker/Dockerfile` + `script/run.sh`（Gunicorn），对接 Drone 自动部署

### 常用扩展

| 扩展 | 用途 | 需要的配置 |
|------|------|-----------|
| `loguru` | 结构化日志，持久化到 `log/` | 无 |
| `sentry` | 异常上报 Sentry | `SENTRY_DS` |
| `database` | SQLAlchemy 封装 | `SQLALCHEMY_DATABASE_URI` |
| `redis` | Redis 连接池 | `REDIS_URL` |
| `celery` | 异步任务（worker/beat） | 配合 `script/run.sh` |

### 快速开始

```bash
git clone https://github.com/wuhanchu/flask_starter.git
cd flask_starter
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python run.py   # http://127.0.0.1:5000/
```

新增业务模块：

```python
# module/example/__init__.py
from flask import Blueprint

bp = Blueprint("example", __name__, url_prefix="/api/example")

@bp.route("/ping")
def ping():
    return {"message": "pong"}

def init_app(app):
    app.register_blueprint(bp)
```

在 `config.py` 的 `ENABLED_MODULE` 中加入 `'example'` 即生效。

完整配置项、Docker 构建与 Gunicorn 参数见仓库 [README](https://github.com/wuhanchu/flask_starter)。

## ASP.NET 模板（aspnet_starter）

- 仓库：http://192.168.51.92:33000/baofeng/aspnet_starter （内网 Gitea，需登录）
- 适用：ASP.NET 业务系统二开、Windows 桌面应用（界面以 WebView2 为主，简单工具类可用 WinForms，见[技术选型](07_技术选型.md)）

```bash
git clone http://192.168.51.92:33000/baofeng/aspnet_starter.git
```

目录结构与使用说明见仓库 README。
