---
name: setup-agent-council
description: Set up or change the roster of AI agents the agent-council skill can consult. Detects installed agent CLIs (Claude Code, Codex, OpenCode, Antigravity agy, Gemini CLI, Qwen Code, Cursor, Copilot, Droid, Amp, Goose, Crush, Kimi, Aider, Ollama, llm, or any other CLI with a print mode) and live sessions, lets the user pick members and models, writes ~/.config/agent-council/roster.json, and smoke-tests each member. Use when the user runs /setup-agent-council, wants to add, remove, or change council agents or models, or when agent-council reports a missing roster.
---

# Setup Agent Council

Build `~/.config/agent-council/roster.json`, the list of agents the `agent-council` skill may ask. If the file already exists, read it first and treat this as an edit: show the current members and ask what to add, remove, or change.

## 1. Detect what the user has

```bash
for c in claude codex opencode agy gemini qwen cursor-agent copilot droid amp goose crush kimi aider ollama llm; do
  command -v "$c" >/dev/null && echo "found: $c"
done
```

Also:
- If `opencode` was found, run `opencode models` to see which providers and models are configured. That is often the easiest way to reach Gemini, GPT, or local models.
- If `agy` (Antigravity) was found, run `agy models` to list its models. It often includes Gemini, Claude, and GPT-OSS models on the user's Antigravity plan.
- If `codex` was found, read `model` from `~/.codex/config.toml` to know its default model.
- If `ollama` was found, run `ollama list`. Local models are free and private, but weaker, so they suit brainstorming more than final votes.
- If `llm` was found, run `llm models` to see which providers are configured.
- If you have a ListAgents tool, call it to see live sessions. These are optional members, useful only when the user keeps a long-running reviewer session open.
- If you are running inside Claude Code, Claude subagents (`opus`, `sonnet`, `haiku`, `fable`) are always available and need no install. In any other host, such as Codex or Antigravity, there are no subagent members. Use the `claude` CLI row below instead if it is installed.

Being installed is not the same as being usable: the user may be logged out or have no subscription. The smoke test in step 5 catches this, so detect broadly and let the test decide.

## 2. Let the user choose

Ask the user, with AskUserQuestion and `multiSelect: true` if you have it, or as a numbered list otherwise. Offer only what you detected. Recommend a mix of model families: for example, one Claude model, one GPT model, and one Gemini model, from whichever tools provide them. Members from the same family share blind spots, so diversity matters more than count. A single multi-provider tool (opencode, agy, llm) can supply several families on its own. Then ask which member is the `strongest`. It is always included in a council and is preferred as a challenger. Default to the most capable model the user picked.

## 3. Command templates for CLI members

The council runs CLI members through `agent-council/scripts/ask.sh`, which pipes the prompt to stdin and also sets `$PROMPT_FILE`. Members should be **read-only**: they give advice and must not edit the repo.

"Tested" means the template was run end to end. The other rows follow each tool's documented print mode but haven't been run. If one fails the smoke test, check `<cli> --help` and fix the flags.

| CLI | Tool | `command` | Models / notes | Tested |
|---|---|---|---|---|
| claude | Claude Code | `claude -p --model <model> --permission-mode plan` | `opus`, `sonnet`, `haiku`. Use this outside Claude Code, or for a second account | yes |
| codex | OpenAI Codex | `codex exec -s read-only --skip-git-repo-check --ephemeral -m <model> -` | GPT models; needs a ChatGPT plan or an OpenAI key | partly: flags accepted, but no full answer seen yet (needs login) |
| opencode | OpenCode | `opencode run -m <provider/model> "$(cat "$PROMPT_FILE")"` | Any configured provider: Google, OpenRouter, free `opencode/*` models | yes |
| agy | Google Antigravity | `agy -p "$(cat "$PROMPT_FILE")" --model <model> --mode plan` | `agy models`: Gemini, Claude, GPT-OSS | yes |
| gemini | Gemini CLI | `gemini -m <model> -p "$(cat "$PROMPT_FILE")"` | Gemini models | no |
| qwen | Qwen Code | `qwen -p "$(cat "$PROMPT_FILE")"` | Qwen models | no |
| cursor-agent | Cursor CLI | `cursor-agent -p --model <model> --output-format text "$(cat "$PROMPT_FILE")"` | Models on the Cursor plan | no |
| copilot | GitHub Copilot CLI | `copilot -p "$(cat "$PROMPT_FILE")"` | Models on the Copilot plan; leave out `--allow-all-tools` so it stays read-only | no |
| droid | Factory Droid | `droid exec "$(cat "$PROMPT_FILE")"` | Read-only by default | no |
| amp | Amp | `amp -x "$(cat "$PROMPT_FILE")"` | | no |
| goose | Goose | `goose run -t "$(cat "$PROMPT_FILE")"` | Any configured provider | no |
| crush | Crush | `crush run "$(cat "$PROMPT_FILE")"` | Any configured provider | no |
| kimi | Kimi CLI | `kimi -p "$(cat "$PROMPT_FILE")"` | Kimi models | no |
| aider | Aider | `aider --chat-mode ask --no-auto-commits --no-git --yes-always --message "$(cat "$PROMPT_FILE")"` | Any configured provider; `ask` mode doesn't edit files | no |
| ollama | Ollama (local) | `ollama run <model>` | Local models; prompt comes from stdin; no repo access, so paste code into the brief | no |
| llm | Simon Willison's `llm` | `llm -m <model>` | Any configured provider; prompt comes from stdin; no repo access | no |

Leave out the model flag to use the tool's default model. For a tool not listed here, find its non-interactive or print mode in `<cli> --help`, prefer a read-only or plan mode, and build the command the same way. Members that can't read files (ollama, llm) need any relevant code pasted into the brief itself.

## 4. Write the roster

```json
{
  "strongest": "opus",
  "members": [
    {"name": "opus",   "kind": "subagent", "model": "opus"},
    {"name": "codex",  "kind": "cli",      "command": "codex exec -s read-only --skip-git-repo-check --ephemeral -"},
    {"name": "gemini", "kind": "cli",      "command": "opencode run -m google/gemini-3.8-flash \"$(cat \"$PROMPT_FILE\")\""}
  ]
}
```

Each `name` is unique and short. Valid `kind` values are `subagent` (needs `model`), `cli` (needs `command`), and `session` (needs `to`, the name ListAgents shows). Validate the file with `jq . ~/.config/agent-council/roster.json`.

## 5. Smoke-test

For each `cli` member, write `Reply with exactly: COUNCIL-OK` to a scratch file and run `bash <agent-council-skill-dir>/scripts/ask.sh <name> <file>`, all in parallel. Report a table to the user: member, kind, model, status (OK, wrong output, or the error text). Offer to fix or remove any member that failed. Typical causes are being logged out or a wrong model name.
