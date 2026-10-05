# 游戏开发 Neovim 配置

适配当前机器的 Neovim 0.12，保留 Catppuccin、Snacks、nvim-tree、Harpoon、Git 和现有 Unity snippets。
项目根目录从当前文件向上识别，支持 Unity（Assets + ProjectSettings）、Godot（project.godot）、Unreal（*.uproject）。

## 配置结构

`init.lua` 只加载 `config`。基础设置和工作流分开；插件由 Lazy 按类别导入，不需要手工合并列表。

```text
lua/
├── config/       # options、keymaps、autocmds、runtime、lazy 与启动顺序
├── plugins/
│   ├── ui/       # 主题、状态栏、标签栏、缩进线、Noice、which-key
│   ├── editor/   # 编辑增强、文件导航、Snacks、Treesitter
│   ├── coding/   # 补全、LSP、Mason 工具、格式化、诊断
│   ├── debug/    # DAP 与调试 UI
│   ├── git/      # Neogit、Diffview
│   ├── game/     # Unity 同步插件
│   └── ai/       # CodeCompanion 与 adapter 配置
├── game/         # 引擎设置、项目识别、文件类型、运行/构建/测试、终端、Unity 对应文件
├── ai/           # Codex 会话、模型/历史面板、独立输入框、代码上下文、CLI 入口
├── ui/           # 首页布局与绫波丽点阵素材
└── snippets/     # unity、godot、unreal、shaders，由 init.lua 统一注册
tests/            # 启动、插件、问题回归、格式化和 Codex 集成检查
```

新增插件：在对应 `lua/plugins/<类别>/` 下添加返回 Lazy spec 的 Lua 文件。
修改基础键位：`lua/config/keymaps.lua`；引擎键位：`lua/game/keymaps.lua`。
格式化、调试、聊天等插件键位放在对应插件 spec 的 `keys` 中，使用时才加载。
通知统一由 Snacks 管理；Noice 负责命令行、消息和 LSP 文档，缩进线由 indent-blankline 管理。
用 `.stylua.toml` 统一 Lua 排版，删去了重复默认值、失效注释与未使用的图标配置。

本次审查修复了标签栏关闭未保存文件、Unity Test.cs/meta 双向切换、特殊 buffer 项目识别、光标位置保存及 Codex 跨项目聊天问题。
Unity 同步插件保留 `:Ustatus`、`:Usync`、`:Uopen`；移除了上游退出时无条件执行 `pkill -f unity2025` 的钩子。

## 立即使用

重启 Neovim。插件由 Lazy 管理，语言服务和辅助工具由 Mason 管理。

不带文件参数启动时显示绫波丽首页。大窗口使用双栏：左侧 NEOVIM 与人物点阵，右侧菜单、最近文件和项目。
首页背景透明，跟随终端背景；浅蓝和淡紫高亮不改变代码 buffer 的主题。
`lua/ui/layout.lua` 统一分配文件树、主编辑区和 AI 面板宽度，展开/收起侧栏或调整终端尺寸时自动更新。
文件树占约 16%（16–28 列）；AI 使用扣除文件树后可用宽度的约 40%，为主编辑区保留空间。140 列同时打开三者时约为 22 / 70 / 46 列。
首页缩放后重新居中并清除旧的水平滚动偏移；人物按宽度和高度选择完整素材，窄窗口保留完整身体及菜单。
人物点阵按参考图原始点位读取，包含身体；小窗口缩小完整人物，宽度不足 90 列时使用单栏。
布局配置在 `lua/ui/dashboard.lua`，点阵文字在 `lua/ui/art/rei.lua`，无需图片渲染工具。
`:Dashboard` 可再次打开首页；`f/n/p/g/r/c/a/l/q` 对应查找文件、新建、项目、搜索、最近文件、配置、Codex、插件管理、退出。
主页最近项目按游戏引擎根目录识别，也支持没有 Git 的引擎项目；字符图标建议使用 Nerd Font。

- `:checkhealth game`：检查 PATH、项目、Codex ACP 和 Godot 端口。
- `:Mason`：查看语言服务、格式化器和调试器的安装结果。
- `:GameLspInstall`：按当前文件类型安装语言服务，也可指定名称，例如 `:GameLspInstall lua_ls omnisharp clangd`；安装后重开文件。
- `:MasonToolsInstall`：按需补装配置要求的辅助工具；启动时不再自动安装。
- `:GameProjectRefresh`：立即刷新根目录缓存；缓存最多保留 5 秒，写入项目标记或切换目录时自动清除。
- `:GameParsersInstall`：安装配置使用的语法解析器；需要 C compiler、curl、tar 和 tree-sitter-cli。
- `:ConformInfo`：查看当前文件实际使用的格式化器。
- `:checkhealth vim.lsp`：检查 LSP；先打开对应语言文件。

`<leader>` 是空格。原有 `s` 保存、`jk` 退出插入模式、`Ctrl+h/j/k/l` 窗口导航继续可用。
`Ctrl+n` 打开文件树时，会自动展开当前文件所在文件夹并选中该文件；切换文件时同步定位，跨目录时更新文件树根目录。
文件树关闭 Git 状态查询，避免 Windows 下 Unity 大项目打开时阻塞；Git 状态和差异仍可通过 Neogit、Diffview 查看。
搜索、文件树与 Lua LSP 共用引擎生成目录名单，保留 `Assets`、`Packages` 和 `.EmmyLuaUnity`；文件树中按 `U` 可暂时取消自定义过滤。

超过 1 MB 或 20000 行的代码/资源 buffer 启用大文件保护：跳过 LSP、补全、Treesitter、缩进线与自动格式化，保持编辑和保存。
Lua LSP 按项目隔离：仅 Nvim 配置加载 `VIMRUNTIME`；Unity 项目自动加载已有的 `.EmmyLuaUnity`，匹配 `Assets/Lua` 的 require 路径。
项目根目录存在 `.luarc.json` / `.luarc.jsonc` 时优先采用项目设置。Lua 运行时可在项目配置中指定；全局默认也可设置 `vim.g.game_dev.lua_runtime`。
LuaLS 库与排除规则依据[官方配置说明](https://luals.github.io/wiki/settings/#workspacelibrary)。

C# 保存后异步格式化并自动写回；其他语言保留原有保存策略，`<leader>cf` 仍可手动格式化。
AI 上下文最多 1500 行 / 64 KB，诊断最多 50 条；超过限制会提示缩小选区，不会截掉代码后发送。诊断也计入大小限制。
可在加载配置前通过 `vim.g.game_dev` 覆盖阈值：

```lua
vim.g.game_dev = {
    performance = { max_file_bytes = 1024 * 1024, max_file_lines = 20000 },
    ai_context = { max_bytes = 64 * 1024, max_lines = 1500, max_diagnostics = 50 },
}
```

| 快捷键 | 用途 |
| --- | --- |
| `<leader>ff` / `fg` | 从项目根目录查文件/查内容，遵循 gitignore 并过滤引擎生成目录 |
| `<leader>fF` / `fG` | 包含忽略文件和生成目录的完整搜索 |
| `<leader>fs` / `fm` | 文件符号/成员 |
| `gd` / `gr` / `K` | 定义/引用/文档 |
| `<leader>rn` / `ca` / `ck` | 重命名/代码操作/函数签名 |
| `<leader>ch` | clangd：切换 C++ 头文件/源文件 |
| `<leader>cf` | 手动格式化当前文件或选中范围 |
| `<leader>pi` / `pc` | 项目信息/切换工作目录到项目根目录 |
| `<leader>pe` / `pr` | 打开引擎编辑器/运行游戏；Unity 两者均打开编辑器 |
| `<leader>pb` | Unity/.NET：dotnet build；Unreal：选 Target 构建；Godot：打开编辑器进行导出 |
| `<leader>pt` | Unity Test Framework（EditMode/PlayMode）；普通 .NET 项目：dotnet test |
| `<leader>ha` / `1`–`4` / `Ctrl+e` | Harpoon 添加/跳转/菜单 |
| `<leader>uu` | Undo Tree；启用持久撤销历史 |
| `<leader>gg` | Neogit |
| `<leader>db` / `dc` / `do` / `di` / `dO` | 断点/开始或继续/单步越过/进入/跳出 |
| `<leader>dt` | 调试 UI |

`<leader>ha` 和 `<leader>uu` 避免与 AI、Unity 的快捷键前缀冲突。
自动格式化保留 C# 等代码类型；C++、GDScript、Shader、Unity YAML 资源使用手动格式化。
`Packages`、`Plugins`、`.meta` 保持可搜索。配置不会自动创建项目 `.ignore`。

## AI：Codex

默认通过 CodeCompanion v19.25.0 + `@agentclientprotocol/codex-acp` 2.1.1 接入 Codex。
本机已安装桥接程序，并验证现有 ChatGPT 登录可以创建 ACP 会话；无需设置 API key。
聊天和代码修改在 Codex 会话中进行，可使用它的项目工具与文件编辑能力。

首次在其他机器配置时：

```powershell
codex login
npm.cmd install --prefix "$env:LOCALAPPDATA\nvim-data\game-tools" @agentclientprotocol/codex-acp@2.1.1
nvim
```

需要 Node.js。配置直接运行 Node + 桥接入口，避免 Windows npm `.cmd` 包装器干扰 ACP stdio。
也可通过 `CODEX_ACP_BIN` 指定现有 ACP 可执行程序，或用 `vim.g.game_dev.codex_acp = { 'node', 'path/to/index.js' }` 设置 argv。
桥接包使用它自带的兼容 Codex 版本，并沿用本机 Codex 登录和配置；模型不使用 `AI_MODEL`。

| 快捷键 | 用途 |
| --- | --- |
| `<leader>ac` | 打开当前项目的 Codex 聊天 |
| `<leader>ai` | 进入独立消息输入框，自动进入插入模式 |
| `<leader>am` | 选择当前对话的模型，标记当前模型 |
| `<leader>ah` / `<leader>aH` | 恢复当前项目 / 全部本地 Codex 历史对话 |
| `<leader>an` | 新建 Codex 对话，保留已有聊天和草稿 |
| `<leader>aa` | Codex 操作菜单：聊天、模型、历史、新建、代码检查、终端 |
| `<leader>ae` | 输入修改需求，将当前文件或选中行与诊断加入新的 Codex 聊天草稿 |
| 可视模式 `<leader>as` | 把选中代码、路径、引擎类型和诊断加入 Codex 聊天草稿 |
| `<leader>ay` | 复制代码及上下文，粘贴给任意 AI 工具 |
| `<leader>at` / `al` | 在当前项目目录打开/恢复 Codex / Claude Code 终端 |

使用这些快捷键时，会将当前 tab 的工作目录设为识别到的引擎项目根目录；跨项目时使用独立聊天，返回已有项目会恢复之前的聊天。
`<leader>ae` 为新的修改需求创建草稿；异步操作使用开始时记录的项目目录。
面板位于右侧，上方阅读对话，下方独立输入消息；窗口背景沿用透明主题。打开聊天会同时显示输入框，按 `Tab` 或 `gi` 进入输入；输入框中 `Enter` 换行，`Ctrl+s` 发送，`Tab` 返回阅读区。
输入框默认占约 16% 高度（3–6 行），多行草稿可增高，最多占约 30%；窄侧栏按钮缩为“模 / 史 / ⋯”与“发 / 停 / 收”，操作与快捷键不变。
顶部模型、历史、更多，以及输入框的发送、停止、收起按钮都支持鼠标点击；鼠标已启用。`g?` 打开操作菜单，也可查看并切换本次 Nvim 已打开的对话。
输入框草稿按对话隔离，收起、重新打开、切换对话会保留；仅本次 Nvim 进程内保存。确认提交后才清空输入；生成中、会话同步中或提交被拒绝时保留输入，可在生成期间提前写下一条需求。
`Ctrl+c` 收起阅读区与输入框并保留草稿；输入框中 `Ctrl+q` 停止生成，阅读区也可用 `q`。仍可通过 `Ctrl+h/j/k/l` 导航窗口。
代码上下文草稿显示在阅读区，不会自动发送；输入框的消息会追加到当前草稿一起发送。阅读区 `Ctrl+s` 或普通模式回车可直接发送阅读区草稿，不会清除输入框里另写的内容。
聊天顶部显示当前模型；普通模式直接按 `gm` 选择模型、`gh` 打开项目历史、`gH` 打开全部本地历史、`gn` 新建对话，`?` 查看完整帮助。
模型列表由当前登录的 Codex 接口实时提供，切换作用于当前对话；取消选择不会更改草稿。
历史按更新时间排序，显示标题和目录，支持搜索。项目历史包含引擎根目录及其子目录（例如 `Assets/Lua`），跨项目恢复使用会话原始目录。
选择历史后通过 ACP `session/load` 恢复原会话 ID 和可回放的消息，可以继续发送；旧聊天保留，取消或恢复失败时不会覆盖旧草稿。
同一会话被其他 Codex 客户端占用时，面板会提示先在原应用或 CLI 中关闭该会话，再恢复；不会强制抢占。
本次 Neovim 已打开的会话直接切回原聊天，保留其未发送内容。
模型查询与历史恢复在异步协程执行；生成中禁止切换模型或恢复历史，先按 `q` 停止生成。
历史来自当前 Codex 桥接可访问的本机存储及 provider，包括本地 CLI 和应用会话；不会同步 ChatGPT 网页聊天或另一台机器的记录。
依照 [Codex 本地会话与模型接口说明](https://learn.chatgpt.com/docs/app-server) 使用原生接口，不直接读写会话数据库。
文件/命令权限按 Codex 和 CodeCompanion 的实际提示处理。
终端中双按 `Esc` 返回普通模式。外部工具修改文件后，切回 Neovim 会检查磁盘变化；有未保存修改时不会强行覆盖。
可在终端运行 `codex login status` 检查登录状态。

### 可选：OpenAI / 兼容 HTTP API

保留 `game_ai` HTTP adapter，可通过 `:CodeCompanionChat adapter=game_ai` 打开 API 聊天。
`:CodeCompanion` 的 inline 编辑使用 HTTP adapter，因为 CodeCompanion 的 inline 不支持 ACP；默认 Codex 的 `<leader>ae` 走聊天修改流程。
使用 HTTP API 时，在启动 Neovim 前设置以下变量；替换示例值，不要把真实密钥提交到 Git。

```powershell
# OpenAI
$env:OPENAI_API_KEY = '<your-api-key>'
$env:AI_MODEL = 'gpt-4.1'
nvim

# 兼容服务；BASE_URL 包含 API 版本前缀，不包含 /chat/completions
$env:AI_API_KEY = '<your-api-key>'
$env:AI_BASE_URL = 'https://your-provider.example/v1'
$env:AI_MODEL = '<provider-model-id>'
nvim
```

优先级：`AI_API_KEY` > `OPENAI_API_KEY`；`AI_BASE_URL` > `OPENAI_BASE_URL` > OpenAI 的 `/v1` 地址。
模型默认 `gpt-4.1`，兼容服务请设置它实际支持的模型 ID。
本地免鉴权服务可把 `AI_API_KEY` 设为占位值。服务需支持 Chat Completions 和相应的 streaming 格式。

HTTP API 调用使用你设置的服务。默认 Codex 聊天使用 ChatGPT 登录，配置不会自动发送推理请求。

### 插件更新修复

CodeCompanion 明确指定 `main` 分支并固定 tag，修复了只有 tag 的浅克隆导致 Lazy 解析更新目标失败的问题。
本机两个 Mason 仓库的 origin 已迁移到 `mason-org`。三个仓库已通过真实 `:Lazy update`，锁文件也已重新生成。
这三个仓库使用 Git 的 OpenSSL backend，避免本机 Schannel 的 GitHub TLS 握手失败，证书验证保持开启。

## 引擎设置

可在启动前设置环境变量，也可在 init.lua 的第一条 require 前设置 `vim.g.game_dev`（只放非敏感路径、端口等）。

```powershell
$env:UNITY_EDITOR = 'C:\Program Files\Unity\Hub\Editor\<version>\Editor\Unity.exe'
$env:GODOT_BIN = 'D:\Tools\Godot\Godot.exe'
$env:UNREAL_ENGINE_PATH = 'D:\Epic Games\UE_5.x'
```

Unity 优先使用 `UNITY_EDITOR`，否则根据 ProjectVersion.txt 查找 Unity Hub 默认安装位置。
Godot 优先使用 `GODOT_BIN`，否则查找 PATH 中的 godot/godot4/godot-mono。
Unreal 路径必须指向包含 `Engine` 的目录；构建时从 `Source/*.Target.cs` 选择目标，默认 Win64 Development。

### Unity / C#

只启用 OmniSharp，读取 `.editorconfig`，开启补全和分析器。
在 Unity 中设置外部脚本编辑器并重新生成 `.sln/.csproj`，确认需要的包包含在生成结果中。
`<leader>ub` 是 `.NET` 编译检查，不能替代 Unity Player Build；`<leader>ut` 使用 Unity Test Framework。
批处理测试前关闭同项目的 Unity Editor。测试结果写入 Neovim state 目录的 `unity-test-results.xml`。
原来的 `<leader>uf`、`uo`、`um`、`ua` 保留：格式化/打开编辑器/打开 meta/切换同目录 Test.cs。
Unity 项目同步插件按实际命令 `:Ustatus`、`:Usync`、`:Uopen` 按需加载。

netcoredbg 调试 CoreCLR/.NET DLL，不适用于 Unity Editor 的 Mono/IL2CPP。
Unity Editor 的断点调试需要 Unity 专用适配器；当前配置没有伪装成可用的 Unity Attach。

### Godot / GDScript

先在 Godot Editor 打开当前项目，再编辑 `.gd` 文件。LSP 连接 `127.0.0.1:6005`；DAP 连接 `6006`。
如先打开了 Neovim，再启动 Godot，执行 `:lsp restart gdscript` 重连。
端口可通过 `GODOT_LSP_PORT`、`GODOT_DAP_PORT`、`GODOT_DEBUG_PORT` 修改，需与 Godot 设置一致。
默认 GDScript 使用 Tab；`project.godot`、`.tscn`、`.tres` 使用 Godot 资源语法。
启用 Godot 的 `Text Editor > Behavior > Auto Reload Scripts on External Change`。
Godot C# 使用 OmniSharp 和 netcoredbg，需要 Godot 的 .NET 版本及相应 .NET SDK。

### Unreal / C++

clangd 需要与当前目标匹配的 `compile_commands.json`，以解析 Unreal 宏、生成头文件和 include 路径。
用项目对应版本的 UnrealBuildTool 的 `GenerateClangDatabase` 模式生成数据库，放到项目根目录。
没有数据库时，普通补全能启动，但 Unreal 相关诊断和跳转可能不准确。
C++ 格式化由 clang-format 读取项目 `.clang-format`；没有配置时建议先约定项目格式。
CodeLLDB 可用于启动/附加 C++ 进程；Windows 上调试 Unreal/MSVC PDB 的可用性依赖调试器和符号格式，可按项目选用 cppvsdbg 等适配器。

项目 `.vscode/launch.json` 从引擎根目录自动读取；`:GameDebugLoad` 检查 JSON 是否有效。
launch.json 只提供配置，额外 adapter 仍需自行注册。请使用有效 JSON，不要保留尾随逗号。

## 代码片段

插入模式输入前缀后用补全菜单或 Tab 展开，并用 Tab 在占位符间跳转。

- Unity：保留 `mono`、`scriptable`、`sf`、`coroutine` 等。
- Godot：`gdnode`、`gdprocess`、`gdphysics`、`gdsignal`、`gdexport`、`gdonready`。
- Unreal：`ueactor`、`ueprop`、`uefunc`、`uelog`；替换 API 宏、类名、generated.h 文件名，并由 Unreal 项目生成工具创建匹配源文件。
- Godot Shader：`gdfragment`。

## 验证

```powershell
nvim --headless -u NONE -i NONE -l tests/game_dev.lua
nvim --headless -i NONE -u init.lua -c "lua dofile('tests/smoke.lua')"
nvim --headless -i NONE -u init.lua -c "lua dofile('tests/formatters.lua')"
nvim --headless -i NONE -u init.lua -c "lua dofile('tests/plugin_updates.lua')"
nvim --headless -i NONE -u init.lua -c "lua dofile('tests/codex.lua')"
nvim --headless -i NONE -u init.lua -c "lua dofile('tests/audit.lua')"
nvim --headless -i NONE -u init.lua -c "lua dofile('tests/plugins.lua')"
nvim --headless -i NONE -u init.lua -c "lua dofile('tests/dashboard.lua')"
nvim --headless -i NONE -u init.lua -c "lua dofile('tests/navigation.lua')"
nvim --headless -i NONE -u init.lua -c "lua dofile('tests/optimization.lua')"
nvim --headless -i NONE -u init.lua -c "lua dofile('tests/ai_panel.lua')"
nvim --headless -i NONE -u init.lua -c "lua dofile('tests/ai_composer.lua')"
nvim --headless -i NONE -u init.lua -c "lua dofile('tests/layout.lua')"
```

第一个检查 Lua 语法、三个引擎的根目录、搜索过滤、AI 上下文、文件类型和缩进；第二个在真实插件环境中检查完整加载。
第三个实际格式化 C#、C++、GDScript，并打开 AI 聊天界面（不发送 API 请求）。
第四个检查 Lazy 的 Git 更新目标、origin 和锁文件；第五个实际验证 Codex ACP、ChatGPT 登录与会话创建，不发送模型推理请求。
第六个验证未保存内容保护、Unity 对应文件切换、光标保存和特殊 buffer 的项目目录；第七个加载全部插件并检查延迟 UI、通知和命令。
第八个实际渲染 160×62、140×40、90×42、80×42、80×24 首页，检查透明背景、完整人物、双栏/单栏、快捷键和内容溢出。
第九个通过真实 Ctrl+n 检查首次定位、跨目录定位、文件跟随，并确保文件树不执行同步 Git 查询。
第十个验证根目录缓存、生成目录过滤、Lua 类型库隔离、大文件编辑/保存、AI 上下文限制、按文件类型安装和 C# 保存后格式化。
第十一个验证真实 Codex 模型目录、模型切换、历史列表及已有会话恢复，并回归分页、子目录筛选、草稿保留和失败回滚；不发送模型推理请求，不输出历史对话内容。
第十二个使用真实 Chat/UI/submit 流程并替换传输层，验证独立输入框、多行发送、草稿隔离、拒绝发送恢复、操作按钮、已打开会话切换和 160×50 / 90×30 / 80×24 布局；不调用模型。
第十三个联合打开真实文件树、首页与 AI 阅读/输入区，验证五种终端尺寸、开关顺序、完整人物/菜单、水平视图复位及多行输入自适应，不调用模型。
真实游戏构建、Editor 附加调试和模型响应仍需在实际项目中验证。

本机已通过 uv 安装 Python 3.12。若 PATH 中没有 Python，配置优先查找 uv 管理的 Python 3.12，再查找其他已有版本；也可设置 `NVIM_PYTHON_BIN`。这只影响 Neovim 进程的 PATH。
Windows 上没有 cl.exe 时，配置使用 PATH 中已有的 GCC 编译 Treesitter parser；可通过 `CC`/`CXX` 覆盖。
本机 `gdformat` 和 `clang-format` 通过 uv 安装，Mason 检测到 PATH 中已有工具时不重复安装。
Prettier 是可选工具；未安装时 JSON/TypeScript 等格式化使用可用的 LSP。需要 Prettier 时可在 `:Mason` 手动安装。
代理不再固定为 127.0.0.1:7897；保留启动环境中的 HTTP_PROXY/HTTPS_PROXY，也可设置 `NVIM_HTTP_PROXY` 显式覆盖。

参考：[Lazy 分类导入](https://lazy.folke.io/usage/structuring)、[Codex ACP](https://github.com/agentclientprotocol/codex-acp)、[CodeCompanion 配置](https://codecompanion.olimorris.dev/configuration/adapters-http)、[Godot 外部编辑器/LSP/DAP](https://docs.godotengine.org/en/stable/tutorials/editor/external_editor.html)、[clangd 编译数据库](https://clangd.llvm.org/installation.html)、[netcoredbg](https://github.com/Samsung/netcoredbg)。
