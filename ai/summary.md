# AI Setup Summary

## ⚙️ Hardware & Driver

- StackMotherboard: MSI Z87-G45 Gaming (Operating at PCIe 3.0 x8)
- GPU: ASUS Dual Nvidia RTX 4060 Ti (16GB VRAM)
- OS Framework: Kubuntu 24.04 LTS (Running mature X11 Display Server)
- Active Driver: Nvidia Production Driver 595.71.05 with CUDA 13.2
- Core Kernel Patch: /etc/default/grub contains GRUB_CMDLINE_LINUX_DEFAULT="" to handle the 16GB memory mapping layout on the Z87 chipset.

## 🤖 AI Backend Configuration (Ollama)

- Install Ollama:

```bash
curl -fsSL https://ollama.com | sh
```

- Model Storage Directory: Relocated to your large drive at /opt/ollama/models.

```bash
sudo mkdir -p /opt/open-webui
sudo chown -R $USER:$USER /opt/open-webui
chmod -R 755 /opt/open-webui
```

- System Service Rule: Configured via systemctl edit ollama.service with the override:

```text
[Service]
Environment="OLLAMA_MODELS=/opt/ollama/models"
Environment="OLLAMA_KEEP_ALIVE=60m"
```

- Active Programming Model: Qwen 2.5 Coder (14B) (qwen2.5-coder:14b), optimized for advanced multi-file local coding logic.

```bash
ollama pull qwen2.5-coder:14b
```

## 🌐 UI Layer Configuration (Podman & Open WebUI)

- Storage Path: Bound straight to /opt/open-webui with user ownership permissions.
- Rootless (but host networking) Podman Runtime Command:

```bash
podman run -d \
  --replace \
  --env 'OLLAMA_BASE_URL=http://localhost:11434' \
  -v /opt/open-webui:/app/backend/data:Z \
  --name open-webui \
  --network=host \
  --restart always \
  ghcr.io/open-webui/open-webui:main
```

## External Access

To make Ollama available to systems outside of the Ollama host we must bind it to the hosts entire network:

### Allow external connections

- Configure Ollama to listen on all interfaces:

```bash
# Edit Ollama Service:
sudo systemctl edit ollama.service
```

- Insert new Environment to listan on all networks:

```ini
[Service]
Environment="OLLAMA_CONTEXT_LENGTH=8192"
Environment="OLLAMA_MODELS=/opt/ollama/models"
Environment="OLLAMA_KEEP_ALIVE=5m"
Environment="OLLAMA_MAX_LOADED_MODELS=2"
Environment="OLLAMA_HOST=0.0.0.0"
Environment="OLLAMA_MAX_VRAM=15000000000"
Restart=on-failure
RestartSec=10
```

- Restart Services:

```bash
sudo systemctl daemon-reload
sudo systemctl restart ollama
```

- Install Tailscale for external network connectivity:

```sh
# Add Tailscale's GPG key
sudo mkdir -p --mode=0755 /usr/share/keyrings
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
# Add the tailscale repository
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list
# Install Tailscale
sudo apt-get update && sudo apt-get install tailscale -y
# Start Tailscale!
sudo tailscale up
```

- [Optional] Create SSH keys for remote access to the server:

```bash
ssh-keygen -t ed25519 -a 100
```

### Connect External Devices

- Connect External Devices

```yaml
# config.yaml
apiBase: http://100.x.x.x:11434
```

## 🔧 IDE/CLI Configuration

### VS Code Configuration

Install VS Code Extention [Continue](https://github.com/continuedev/continue).

- Configuration used in continue

```yaml
name: Local Config (RTX 4060 Ti Optimized)
version: 1.0.0
schema: v1
models:
  # Original Chat model
  - name: Qwen 2.5 Coder 14B
    apiBase: http://localhost:11434
    capabilities:
      - tool_use
    defaultCompletionOptions:
      contextLength: 8192         # Explicit limit (prevents KV cache overflow)
      temperature: 0.7
      num_predict: 1024
    model: qwen2.5-coder:14b
    provider: ollama
    roles:
      - chat
      - edit
      - apply

  # Original Autocomplete model
  - name: Qwen 2.5 Coder 1.5B (Autocomplete)
    apiBase: http://localhost:11434
    autocompleteOptions:
      disable: false
      debounceDelay: 350
      maxPromptTokens: 512
      modelTimeout: 5000
      transform: true # Enable trimming for cleaner completions
      maxSuffixPercentage: 0.2
      onlyMyCode: true # Exclude node_modules, venv, etc.
      prefixPercentage: 0.7
    defaultCompletionOptions:
      temperature: 0.1            # Deterministic completions
      num_predict: 128            # Limit completion length for speed
    model: qwen2.5-coder:1.5b
    provider: ollama
    roles:
      - autocomplete

  # Embeddings Model (Codebase Indexing)
  - name: Nomic Embed Text
    apiBase: http://localhost:11434
    defaultCompletionOptions:
      contextLength: 8192
    model: nomic-embed-text
    provider: ollama
    roles:
      - embed

# Optional: Custom slash commands for workflow automation
prompts:
  - name: test
    description: Generate unit tests
    prompt: Write comprehensive unit tests for this code with edge cases.
  - name: doc
    description: Add documentation
    prompt: Add comprehensive docstrings and type hints to this code.

analytics:
  enabled: false
```

### CLI Tool

- Install [Aider](https://github.com/Aider-AI/aider) with pipx:

```sh
python -m pip install pipx  # If you need to install pipx
pipx install aider-install setuptools
aider-install
```

- Configure Aider

For local system

```sh
export OLLAMA_API_BASE=http://localhost:11434
```

For remote system:

```sh
export OLLAMA_API_BASE=http://<DNS/IP>:11434
```

```pwsh
$env:OLLAMA_API_BASE=http://<DNS/IP>:11434
```


- Usage

```sh
# Pull desirec model wtih Ollama
ollama pull <model>

# Change directory into your codebase
cd /to/your/project

# Choose Model
aider --model ollama_chat/<model>
```

> NOTE
> Using ollama_chat/ is recommended over ollama/.

Fixed context windwow size can be confifured in Aider's configuration file:

- .aider.model.settings.yml

```yaml
- name: ollama/qwen2.5-coder:14bz
  extra_params:
    num_ctx: 65536
```
