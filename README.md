# Agent Question Hub

Agent skills that let your coding agent **ask other AI agents for help**: get a second opinion when it's stuck, have several models debate and defend ideas, vote on the result, and keep a written record of who proposed what, who voted for what, and what was decided.

It works with whatever agents you already have. These include Claude Code subagents, Codex, OpenCode, Google Antigravity, Gemini CLI, Cursor, Copilot, Ollama and [more](#supported-agents). One agent tool with access to two model families is enough to start.

## Why

Models from the same family share blind spots. A Claude model reviewing another Claude model's work tends to make the same mistakes. Asking a *different* model, and making each idea survive an attack from a member who didn't write it, catches problems one model working alone misses.

## Use cases

Your agent can call the council on its own, or you can ask for one.

**Your agent calls it when it's:**
- **stuck on a bug** after 2 or more failed fixes. Two other models diagnose it, and they must defend their answer if they disagree.
- **going in circles**, undoing and redoing the same change.
- **about to start a big change**, so a fresh model checks the plan first.
- **facing a hard-to-reverse choice** mid-task. For these, it asks you before starting a council.

**You call it for:**
- **architecture and design:** schema, monolith vs services, state management.
- **choosing a library or vendor:** Stripe vs Paddle, Supabase vs Firebase.
- **brainstorming:** feature ideas, names, ways to approach a problem.
- **testing your own idea:** "here's my plan, attack it."
- **risky changes:** migrations, auth, security design.
- **settling a disagreement:** both ideas go in anonymously, and you see which one holds up.

Every council leaves a record in `docs/`, so later you can see *why* something was decided and who disagreed.

**Skip it for** facts you can check (read the docs or run the code), small choices that are easy to undo, and matters of taste. A full council takes about 10 minutes and several model calls. Use it when being wrong is expensive.

## Skills

| Skill | What it does |
|---|---|
| [`agent-council`](skills/agent-council/SKILL.md) | Calls the council. **Consult** mode: when stuck, ask the strongest model plus one from another family to diagnose; if they disagree, each must defend its answer or concede. **Council** mode: for decisions and brainstorms, with propose, challenge, defend, anonymous vote, and decide. |
| [`setup-agent-council`](skills/setup-agent-council/SKILL.md) | `/setup-agent-council` finds the agent tools you have, lets you pick members and choose the strongest, writes `~/.config/agent-council/roster.json`, and checks that each member responds. |

## How a council decides

1. **Propose.** Each member answers on its own, without seeing the others.
2. **Challenge.** Each idea is attacked by a member who didn't write it. Objections are marked *critical* or *minor*.
3. **Defend.** The author answers each critical objection with evidence, or concedes.
4. **Vote.** Ideas are shown without author names. No member may vote for its own idea.
5. **Decide.** An idea is adopted only with **at least 2/3 of the votes cast and every critical objection answered**. Ties and anything else go to you.

When the agent is stuck, it calls the council on its own. For hard-to-reverse decisions, such as architecture or vendor choices, it asks you first. You can always overrule the result.

## What gets written

```
docs/
├── council/2026-10-21-cache-strategy.md   # the brainstorming sheet: ideas + authors, challenges, votes, decision, dissent
└── decisions/0001-cache-strategy.md       # short decision record, only when an idea is adopted
```

The sheet template is [`skills/agent-council/assets/sheet-template.md`](skills/agent-council/assets/sheet-template.md).

## Install

**Option 1: the skills CLI**

```bash
npx skills add usoy410/agent-question-hub
```

**Option 2: manual install.** Clone the repo and copy both skill folders into your agent's skills directory:

```bash
git clone https://github.com/usoy410/agent-question-hub.git
cp -r agent-question-hub/skills/* ~/.claude/skills/   # Claude Code
cp -r agent-question-hub/skills/* ~/.agents/skills/   # Codex, Antigravity, and other agents that read ~/.agents/skills
```

To get updates with a plain `git pull`, symlink the folders instead of copying them:

```bash
ln -s "$PWD/agent-question-hub/skills/agent-council"       ~/.claude/skills/agent-council
ln -s "$PWD/agent-question-hub/skills/setup-agent-council" ~/.claude/skills/setup-agent-council
```

Then restart your agent and run `/setup-agent-council`, or ask it to "set up the agent council".

**Requirements:** `bash`, `jq`, and at least one agent CLI. `timeout` is optional: on macOS, `brew install coreutils` provides `gtimeout`.

## Supported agents

Anything with a non-interactive or print mode works. The setup skill knows these:

| Tool | Tested |
|---|---|
| Claude Code (subagents, or `claude -p`) | ✅ |
| OpenAI Codex (`codex exec`) | partly: flags accepted, no full answer seen yet |
| OpenCode (`opencode run`): Google, OpenRouter, free models | ✅ |
| Google Antigravity (`agy -p`): Gemini, Claude, GPT-OSS | ✅ |
| Gemini CLI, Qwen Code, Cursor CLI, GitHub Copilot CLI, Factory Droid, Amp, Goose, Crush, Kimi CLI, Aider | not yet |
| Ollama, `llm` (these can't read your repo, so code is pasted into the question) | not yet |

"Not yet" means the command is based on the tool's documented flags but hasn't been run end to end. Setup tests every member you pick, so a wrong flag shows up right away. If you test one, please open a PR or issue to mark it ✅ or fix its command.

## Roster format

```json
{
  "strongest": "opus",
  "members": [
    {"name": "opus",   "kind": "subagent", "model": "opus"},
    {"name": "gemini", "kind": "cli", "command": "agy -p \"$(cat \"$PROMPT_FILE\")\" --model gemini-3.8-flash-high --mode plan"},
    {"name": "local",  "kind": "cli", "command": "ollama run qwen3"}
  ]
}
```

- `subagent` is for Claude Code only.
- `cli` runs any shell command. The question arrives on stdin and in `$PROMPT_FILE`.
- `session` messages a live agent session.

Set `AGENT_COUNCIL_ROSTER` to use a different file, and `AGENT_COUNCIL_TIMEOUT` to change the time limit per member (in seconds, default 600).
