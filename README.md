# che-apple-mail-mcp

Comprehensive Apple Mail management via MCP and AppleScript.

## Features

| Category | Tool | Description |
|----------|------|-------------|
| **Accounts** | `list_accounts` | List all mail accounts |
| | `get_account_info` | Get account details |
| **Mailboxes** | `list_mailboxes` | List all mailboxes (folders) |
| | `create_mailbox` | Create a new mailbox |
| | `delete_mailbox` | Delete a mailbox |
| **Emails** | `list_emails` | List emails in a mailbox |
| | `get_email` | Get full email content |
| | `search_emails` | Search by subject/content |
| | `get_unread_count` | Get unread count |
| **Actions** | `mark_read` | Mark as read/unread |
| | `flag_email` | Flag/unflag email |
| | `move_email` | Move to another mailbox |
| | `delete_email` | Delete email (to trash) |
| **Compose** | `compose_email` | Send new email |
| | `reply_email` | Reply to email |
| | `forward_email` | Forward email |
| **Drafts** | `list_drafts` | List draft emails |
| | `create_draft` | Create a draft |
| **Attachments** | `list_attachments` | List email attachments |
| | `save_attachment` | Save attachment to disk |
| **VIP** | `list_vip_senders` | List VIP senders |
| **Rules** | `list_rules` | List mail rules |
| | `enable_rule` | Enable/disable a rule |

## Requirements

- macOS 13.0+
- Xcode Command Line Tools
- Apple Mail configured with at least one account

## Installation

### 1. Clone and Build

```bash
git clone https://github.com/kiki830621/che-apple-mail-mcp.git
cd che-apple-mail-mcp

# Build release version
swift build -c release

# Verify the binary exists
ls -la .build/release/CheAppleMailMCP
```

### 2. Configure MCP Client

#### Option A: Claude Desktop

Edit `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "che-apple-mail-mcp": {
      "command": "/path/to/che-apple-mail-mcp/.build/release/CheAppleMailMCP"
    }
  }
}
```

#### Option B: Claude Code

Edit `~/.claude/settings.json`:

```json
{
  "mcpServers": {
    "che-apple-mail-mcp": {
      "command": "/path/to/che-apple-mail-mcp/.build/release/CheAppleMailMCP"
    }
  }
}
```

Or use CLI:
```bash
claude mcp add che-apple-mail-mcp /path/to/che-apple-mail-mcp/.build/release/CheAppleMailMCP
```

Replace `/path/to/` with your actual path.

### 3. Grant Automation Permissions

On first use, macOS will prompt for Automation permission to control Mail.app:

1. Open System Settings:
   ```bash
   open "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"
   ```

2. Allow CheAppleMailMCP to control Mail.app

### 4. Restart

For Claude Desktop:
```bash
osascript -e 'quit app "Claude"' && sleep 2 && open -a "Claude"
```

For Claude Code:
```bash
# Start a new session
claude
```

## Usage Examples

```
"List all my mail accounts"
"Show emails in INBOX of Gmail"
"Search for emails about 'meeting' in INBOX"
"Send an email to john@example.com with subject 'Hello'"
"Mark that email as read"
"Move email to Archive folder"
"List my mail rules"
```

## Technical Details

- Built with Swift and [MCP Swift SDK](https://github.com/modelcontextprotocol/swift-sdk) v0.10.0
- Uses AppleScript via NSAppleScript for Mail.app automation
- Runs as stdio transport MCP server

## Comparison with other Apple Mail MCPs

| Feature | apple-mail-mcp | che-apple-mail-mcp |
|---------|----------------|-------------------|
| Language | Python | Swift |
| Tools | 20 | 24 |
| Mailbox create/delete | ❌ | ✅ |
| VIP management | ❌ | ✅ |
| Rule management | ❌ | ✅ |

## License

MIT

## Author

Created by Che Cheng ([@kiki830621](https://github.com/kiki830621))
