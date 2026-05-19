---
name: sherpa-onnx-local-model-ops
description: 在当前 sherpa-onnx 项目中下载、恢复、验证、启动服务并清理本地 ASR 模型时使用。适用于 GitHub 下载不稳定、需要走本地代理、模型统一落在 D 盘、以及只保留最小可运行或最小测试文件集合的场景。
---

# sherpa-onnx 本地模型操作

## 何时使用
- 用户要求下载或恢复 sherpa-onnx 模型
- 用户要求走本地代理下载 GitHub 发布模型
- 用户要求把模型落到 D 盘而不是 C 盘
- 用户要求验证英文或中文离线识别是否可运行
- 用户要求启动 `non_streaming_server.py`
- 用户要求清理大模型文件，只保留最小可运行集或最小测试集

## 固定约定
- 仓库根目录：`D:\knowledgeBase\sherpa-onnx`
- 模型目录：`D:\knowledgeBase\sherpa-onnx\models`
- Python 优先使用：`.venv\Scripts\python.exe`
- 本地代理优先使用：`http://127.0.0.1:18080`
- 下载优先使用支持断点续传的 `curl.exe -L -C -`

## 下载流程
1. 先确认目标模型名和下载地址是否在仓库 `README.md` 或 `python-api-examples` 示例中出现
2. 下载统一写入 `D:\knowledgeBase\sherpa-onnx\models`
3. 命令优先使用：

```powershell
curl.exe --proxy http://127.0.0.1:18080 -L -C - -o D:\knowledgeBase\sherpa-onnx\models\文件名.tar.bz2 下载地址
```

4. 下载完成后解压：

```powershell
tar -xf D:\knowledgeBase\sherpa-onnx\models\文件名.tar.bz2 -C D:\knowledgeBase\sherpa-onnx\models
```

## 已验证模型
### 英文离线模型
目录：`models/sherpa-onnx-zipformer-en-2023-06-26`

最小可运行集：
- `encoder-epoch-99-avg-1.int8.onnx`
- `decoder-epoch-99-avg-1.int8.onnx`
- `joiner-epoch-99-avg-1.int8.onnx`
- `tokens.txt`

最小测试集：
- 最小可运行集
- `test_wavs/`

### 中文离线模型
目录：`models/sherpa-onnx-paraformer-zh-2024-03-09`

当前最小可运行集：
- `model.int8.onnx`
- `tokens.txt`

当前最小测试集：
- 当前最小可运行集
- `test_wavs/`

## 验证命令
### 中文离线识别
```powershell
.\.venv\Scripts\python.exe .\python-api-examples\offline-decode-files.py `
  --paraformer D:\knowledgeBase\sherpa-onnx\models\sherpa-onnx-paraformer-zh-2024-03-09\model.int8.onnx `
  --tokens D:\knowledgeBase\sherpa-onnx\models\sherpa-onnx-paraformer-zh-2024-03-09\tokens.txt `
  D:\knowledgeBase\sherpa-onnx\models\sherpa-onnx-paraformer-zh-2024-03-09\test_wavs\0.wav
```

### 英文离线识别
```powershell
.\.venv\Scripts\python.exe .\python-api-examples\offline-decode-files.py `
  --encoder D:\knowledgeBase\sherpa-onnx\models\sherpa-onnx-zipformer-en-2023-06-26\encoder-epoch-99-avg-1.int8.onnx `
  --decoder D:\knowledgeBase\sherpa-onnx\models\sherpa-onnx-zipformer-en-2023-06-26\decoder-epoch-99-avg-1.int8.onnx `
  --joiner D:\knowledgeBase\sherpa-onnx\models\sherpa-onnx-zipformer-en-2023-06-26\joiner-epoch-99-avg-1.int8.onnx `
  --tokens D:\knowledgeBase\sherpa-onnx\models\sherpa-onnx-zipformer-en-2023-06-26\tokens.txt `
  D:\knowledgeBase\sherpa-onnx\models\sherpa-onnx-zipformer-en-2023-06-26\test_wavs\0.wav
```

## 中文服务启动
```powershell
.\.venv\Scripts\python.exe .\python-api-examples\non_streaming_server.py `
  --paraformer D:\knowledgeBase\sherpa-onnx\models\sherpa-onnx-paraformer-zh-2024-03-09\model.int8.onnx `
  --tokens D:\knowledgeBase\sherpa-onnx\models\sherpa-onnx-paraformer-zh-2024-03-09\tokens.txt `
  --port 6006
```

当前已验证该服务可以正常监听 `6006`。

### 一键脚本
自检脚本：

```powershell
powershell -ExecutionPolicy Bypass -File D:\knowledgeBase\sherpa-onnx\scripts\check_local_zh_server.ps1
```

自动启动并自检脚本：

```powershell
powershell -ExecutionPolicy Bypass -File D:\knowledgeBase\sherpa-onnx\scripts\start_and_check_local_zh_server.ps1
```

自动启动脚本职责：
- 检查 `6006` 是否已监听
- 如果未监听，则后台启动中文 `non_streaming_server.py`
- 如果已监听，则直接复用现有服务
- 等待服务就绪
- 调用 `check_local_zh_server.ps1` 完成模型、端口、websocket 三项自检

自检脚本判定标准：
- 模型文件必须存在
- `6006` 必须处于监听状态
- websocket 实测必须返回非空识别文本

## 清理原则
- 先验证能跑，再删归档和浮点模型
- 仅做测试时，保留 `test_wavs/`
- 删除前必须确认目标路径仍在 `D:\knowledgeBase\sherpa-onnx\models\目标模型目录` 下
- 优先删除：
  - `.tar.bz2` 归档
  - 浮点模型 `*.onnx`
  - 辅助脚本、量化脚本、生成脚本
  - 非必要元数据文件

## 极简测试保留建议
英文：
- `encoder-epoch-99-avg-1.int8.onnx`
- `decoder-epoch-99-avg-1.int8.onnx`
- `joiner-epoch-99-avg-1.int8.onnx`
- `tokens.txt`
- `test_wavs/`

中文：
- `model.int8.onnx`
- `tokens.txt`
- `test_wavs/`
