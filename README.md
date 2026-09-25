<div align="center">

# acal

### an Apple Calendar CLI

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](./LICENSE)

</div>

> **Disclaimer:** acal is an independent open source project. It is not affiliated with, endorsed by, or associated with Apple Inc. in any way. Apple Calendar and EventKit are trademarks of Apple Inc.

---

`acal` is a single binary. Install it, grant access once, and any script or agent can read and write your Apple Calendar natively via EventKit — no server process required.

Works with shell scripts, cron jobs, and AI agents — anything that can run a command.

## Install

### One-line install

```bash
curl -sSL https://raw.githubusercontent.com/Helmi/acal-apple-calendar-cli/main/install.sh | sh
```

Downloads the latest signed binary, verifies the checksum, and installs to `/usr/local/bin`. Set `ACAL_INSTALL_DIR` to install elsewhere.

### Homebrew

```bash
brew tap Helmi/homebrew-tap
brew install acal
```

### Mint (Swift CLI manager)

```bash
mint install Helmi/acal-apple-calendar-cli
```

### macOS installer (.pkg)

Download the installer: **[acal-0.4.0-macos-universal.pkg](https://github.com/Helmi/acal-apple-calendar-cli/releases/download/v0.4.0/acal-0.4.0-macos-universal.pkg)**

Double-click to install. No terminal required. Works on both Apple Silicon and Intel Macs.

The installer places `acal` in `/usr/local/bin`. See all versions on the [Releases](https://github.com/Helmi/acal-apple-calendar-cli/releases) page.

### Direct download

Download the latest `acal-<version>-macos-universal.zip` from [Releases](https://github.com/Helmi/acal-apple-calendar-cli/releases):

```bash
curl -L -o acal.zip \
  https://github.com/Helmi/acal-apple-calendar-cli/releases/download/v0.4.0/acal-0.4.0-macos-universal.zip
unzip acal.zip
chmod +x acal
mv acal /usr/local/bin/acal
```

## Quick start

```bash
# Check permissions and EventKit status
acal doctor

# Grant calendar access (first run)
acal auth grant

# List your calendars
acal calendars list

# List upcoming events as JSON
acal events list --format json

# Create an event
acal events create \
  --calendar "Work" \
  --title "Team Standup" \
  --start "2026-03-16T09:00:00+01:00" \
  --end "2026-03-16T09:30:00+01:00"
```

## Calendar permission

`acal` has its own macOS privacy identity (`com.helmi.acal`). Run `acal auth grant` once, click "Allow" in the dialog for **acal**, and the permission applies to `acal` itself — no matter which process starts it: your terminal, AI agents, MCP clients like Claude Desktop, cron or launchd jobs. It survives reboots and `acal` updates.

Before 0.4.0, macOS attributed access to the app that launched `acal` (for example Terminal), so a grant made in one terminal did not carry over to agents or MCP clients. After upgrading, run `acal auth grant` once more.

Notes:

- The grant is tied to the install location. If `acal` moves to a different path (for example a new versioned Homebrew folder after `brew upgrade`), macOS may ask once more.
- Check the state with `acal auth status`. Manage or revoke it in System Settings → Privacy & Security → Calendars.

## Commands

| Command | What it does |
|---|---|
| `doctor` | Health check — EventKit access, permission state |
| `auth status\|grant\|reset` | Manage calendar permissions |
| `calendars list\|get` | List or inspect calendars |
| `events list\|get\|search\|create\|update\|delete` | Full event lifecycle, including recurrence-safe edits |
| `mcp` | Start MCP server on stdio for AI assistants |
| `schema` | Print the stable JSON output contract |
| `completion bash\|zsh\|fish` | Install shell completions |

All commands accept `--format json` for machine-readable output.

## MCP server mode

`acal mcp` starts a [Model Context Protocol](https://modelcontextprotocol.io) server on stdio. This lets AI assistants like Claude access your calendar directly through structured tool calls instead of shell commands.

### Setting up with Claude Desktop

1. **Install acal** using any method above (Homebrew, installer, or the one-line script).

2. **Find your config file.** Open Claude Desktop, then go to Settings (gear icon) and click "Developer" in the sidebar. Click "Edit Config" to open `claude_desktop_config.json`.

3. **Add acal as an MCP server.** Add the following to the config file:

   ```json
   {
     "mcpServers": {
       "acal": {
         "command": "/usr/local/bin/acal",
         "args": ["mcp"]
       }
     }
   }
   ```

   If you installed via Homebrew, use `/opt/homebrew/bin/acal` instead.

4. **Restart Claude Desktop.** You should see a hammer icon in the chat input, showing acal's 10 calendar tools are available.

5. **Grant calendar access.** Run `acal auth grant` once in a terminal and click "Allow" (or ask Claude about your calendar and allow the dialog for "acal"). The same grant covers the MCP server — see [Calendar permission](#calendar-permission).

6. **Try it out.** Ask Claude something like:

   > "What's on my calendar this week?"

   > "Schedule a team standup for tomorrow at 9am on my Work calendar"

   > "Find all meetings with 'design' in the title this month"

### Setting up with Claude Code

Add to your project's `.mcp.json`:

```json
{
  "mcpServers": {
    "acal": {
      "command": "acal",
      "args": ["mcp"]
    }
  }
}
```

### Available MCP tools

| Tool | What it does |
|---|---|
| `auth_status` | Check calendar access permissions |
| `auth_grant` | Request calendar access (triggers macOS permission dialog) |
| `list_calendars` | List all calendars |
| `get_calendar` | Get calendar by ID or name |
| `list_events` | List events in a date range (default limit: 50) |
| `get_event` | Get event by ID or external ID |
| `search_events` | Search events by text (default limit: 50) |
| `create_event` | Create a new event with optional recurrence and alarms |
| `update_event` | Update event fields with optimistic concurrency |
| `delete_event` | Delete event with scope control for recurring events |

### Testing with MCP Inspector

```bash
npx @modelcontextprotocol/inspector acal mcp
```

## For agents and scripts

`acal` is designed to be called by AI agents with bash access. Every response uses the same envelope — `ok`, `data`, `error`, `meta` — so agents can handle success and failure without guesswork.

```bash
acal events list --format json
```

```json
{
  "ok": true,
  "data": {
    "events": [
      {
        "id": "abc123",
        "calendarId": "work-cal-id",
        "title": "Team Standup",
        "start": "2026-03-16T09:00:00+01:00",
        "end": "2026-03-16T09:30:00+01:00",
        "timezone": "Europe/Berlin",
        "allDay": false,
        "recurrence": null,
        "alarms": []
      }
    ]
  },
  "meta": {
    "command": "events list",
    "schemaVersion": "1.0.0",
    "timestamp": "2026-03-16T08:00:00Z"
  }
}
```

Full contract: `acal schema`

## Build from source

```bash
git clone https://github.com/Helmi/acal-apple-calendar-cli.git
cd acal-apple-calendar-cli
swift build -c release
swift test
```

Local builds are ad-hoc signed, so macOS treats every rebuild as a new app and asks for Calendar access again. Release builds are signed with a Developer ID and keep the grant across updates.

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md).

## License

MIT — see [LICENSE](./LICENSE).
