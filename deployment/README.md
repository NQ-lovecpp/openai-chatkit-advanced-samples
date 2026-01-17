# 部署说明

这个目录包含将所有四个FastAPI后端打包进一个容器、配合系统服务自动启动，以及备用的 Nginx 配置片段。主要步骤如下：

1. **构建 Docker 镜像**
   ```bash
   cd /home/cydia4384nq/openai-chatkit-advanced-samples
   docker build -t chatkit-backends -f deployment/Dockerfile .
   ```
2. **创建环境变量文件**
   ```bash
   sudo tee /etc/chatkit-backends.env <<'EOF'
   OPENAI_API_KEY='sk--lDxuIP7Sb7XqaPXJ2h394mHo1oG12iKSG5cb0qkhQT3BlbkFJ4bQdm8Yx3ekL3YkAYVPgBq285vlujdvAeml-Lfl34A'
   EOF
   sudo chmod 600 /etc/chatkit-backends.env
   ```
3. **部署 systemd 服务**
   ```bash
   sudo cp deployment/chatkit-backends.service /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable --now chatkit-backends.service
   ```
   该服务会使用 `chatkit-backends:latest` 镜像并把 8000~8003 映射到本机的同样端口，通过 `/etc/chatkit-backends.env` 提供 OpenAI Key。

4. **构建前端静态站点**
   每个前端的 `npm run build` 输出会生成对应 `examples/*/frontend/dist` 目录，Nginx 配置直接服务这些静态文件。以下命令已经将你的 `domain_pk_696b4bfec9e4819683afe540174e42790b4f2b563b3ffc37` 域名密钥注入构建过程中（必要时把 `VITE_*_DOMAIN_KEY` 改为你的 key）：

   ```bash
   cd examples/cat-lounge/frontend
   npm install
   VITE_BASE_PATH=/cat-lounge/ \
     VITE_CHATKIT_API_URL=/cat-lounge/chatkit \
     VITE_CAT_STATE_API_URL=/cat-lounge/cats \
     VITE_CHATKIT_API_DOMAIN_KEY=domain_pk_696b4bfec9e4819683afe540174e42790b4f2b563b3ffc37 \
     npm run build
   ```

   ```bash
   cd examples/customer-support/frontend
   npm install
   VITE_BASE_PATH=/customer-support/ \
     VITE_SUPPORT_API_BASE=/customer-support/support \
     VITE_SUPPORT_CHATKIT_API_DOMAIN_KEY=domain_pk_696b4bfec9e4819683afe540174e42790b4f2b563b3ffc37 \
     npm run build
   ```

   ```bash
   cd examples/news-guide/frontend
   npm install
   VITE_BASE_PATH=/news-guide/ \
     VITE_CHATKIT_API_URL=/news-guide/chatkit \
     VITE_ARTICLES_API_URL=/news-guide/articles \
     VITE_CHATKIT_API_DOMAIN_KEY=domain_pk_696b4bfec9e4819683afe540174e42790b4f2b563b3ffc37 \
     npm run build
   ```

   ```bash
   cd examples/metro-map/frontend
   npm install
   VITE_BASE_PATH=/metro-map/ \
     VITE_CHATKIT_API_URL=/metro-map/chatkit \
     VITE_MAP_API_URL=/metro-map/map \
     VITE_CHATKIT_API_DOMAIN_KEY=domain_pk_696b4bfec9e4819683afe540174e42790b4f2b563b3ffc37 \
     npm run build
   ```

   如果你有多个域名，可以针对不同域 supply 对应的 `VITE_*_DOMAIN_KEY`；在开发阶段仍可使用默认值 `domain_pk_localhost_dev` 继续跑 `npm run dev`。

5. **配置 Nginx 反向代理**
   ```bash
   sudo cp deployment/nginx/ai.chenzhuowen.vip.conf /etc/nginx/sites-available/
   sudo mkdir -p /etc/nginx/snippets
   sudo cp deployment/nginx/proxy-settings.conf /etc/nginx/snippets/chatkit-proxy.conf
   sudo ln -sf /etc/nginx/sites-available/ai.chenzhuowen.vip.conf /etc/nginx/sites-enabled/
   sudo nginx -t
   sudo systemctl reload nginx
   ```
   - `ai.chenzhuowen.vip/cat-lounge/` / `.../customer-support/` / `.../news-guide/` / `.../metro-map/` 会分别直接映射到各自 `examples/*/frontend/dist` 目录；
   - `/cat-lounge/chatkit`、`/cat-lounge/cats` 等 API 路径由 `/etc/nginx/snippets/chatkit-proxy.conf` 代理到 8000～8003 四个后端；
   `/etc/nginx/snippets/chatkit-proxy.conf` 仍然包含 websocket 所需的头部设置以及标准的转发头。

6. **验证**
   - 使用 `curl http://127.0.0.1:8000` 等确认后端正在响应。
   - `systemctl status chatkit-backends.service` 确认容器运行。
   - 访问 `http://ai.chenzhuowen.vip/cat-lounge/` 等确保前端通过 Nginx 可达。
