import Foundation
import MCP

/// MCP Server for Apple Mail
class CheAppleMailMCPServer {
    private let server: Server
    private let transport: StdioTransport
    private let mailController = MailController.shared
    private let tools: [Tool]

    init() async throws {
        self.tools = Self.defineTools()
        self.server = Server(
            name: "che-apple-mail-mcp",
            version: "0.1.0",
            capabilities: .init(tools: .init())
        )
        self.transport = StdioTransport()

        await registerHandlers()
    }

    func run() async throws {
        try await server.start(transport: transport)
        await server.waitUntilCompleted()
    }

    // MARK: - Tool Definitions

    private static func defineTools() -> [Tool] {
        [
            // Account Tools
            Tool(
                name: "list_accounts",
                description: "List all mail accounts configured in Apple Mail",
                inputSchema: .object(["type": .string("object"), "properties": .object([:])])
            ),
            Tool(
                name: "get_account_info",
                description: "Get detailed information about a specific mail account",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "account_name": .object(["type": .string("string"), "description": .string("The name of the mail account")])
                    ]),
                    "required": .array([.string("account_name")])
                ])
            ),

            // Mailbox Tools
            Tool(
                name: "list_mailboxes",
                description: "List all mailboxes (folders) for an account",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "account_name": .object(["type": .string("string"), "description": .string("The name of the mail account (optional, lists all if omitted)")])
                    ])
                ])
            ),
            Tool(
                name: "create_mailbox",
                description: "Create a new mailbox (folder) in an account",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "name": .object(["type": .string("string"), "description": .string("Name of the new mailbox")]),
                        "account_name": .object(["type": .string("string"), "description": .string("The account to create the mailbox in")])
                    ]),
                    "required": .array([.string("name"), .string("account_name")])
                ])
            ),
            Tool(
                name: "delete_mailbox",
                description: "Delete a mailbox (folder) from an account",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "name": .object(["type": .string("string"), "description": .string("Name of the mailbox to delete")]),
                        "account_name": .object(["type": .string("string"), "description": .string("The account containing the mailbox")])
                    ]),
                    "required": .array([.string("name"), .string("account_name")])
                ])
            ),

            // Email Reading Tools
            Tool(
                name: "list_emails",
                description: "List emails in a mailbox",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "mailbox": .object(["type": .string("string"), "description": .string("Mailbox name (e.g., 'INBOX')")]),
                        "account_name": .object(["type": .string("string"), "description": .string("The mail account")]),
                        "limit": .object(["type": .string("integer"), "description": .string("Maximum number of emails to return (default: 50)")])
                    ]),
                    "required": .array([.string("mailbox"), .string("account_name")])
                ])
            ),
            Tool(
                name: "get_email",
                description: "Get full content of a specific email",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "id": .object(["type": .string("string"), "description": .string("The email ID")]),
                        "mailbox": .object(["type": .string("string"), "description": .string("Mailbox name")]),
                        "account_name": .object(["type": .string("string"), "description": .string("The mail account")])
                    ]),
                    "required": .array([.string("id"), .string("mailbox"), .string("account_name")])
                ])
            ),
            Tool(
                name: "search_emails",
                description: "Search emails by subject or content",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "query": .object(["type": .string("string"), "description": .string("Search query")]),
                        "mailbox": .object(["type": .string("string"), "description": .string("Mailbox to search in")]),
                        "account_name": .object(["type": .string("string"), "description": .string("The mail account")]),
                        "limit": .object(["type": .string("integer"), "description": .string("Maximum results (default: 20)")])
                    ]),
                    "required": .array([.string("query"), .string("mailbox"), .string("account_name")])
                ])
            ),
            Tool(
                name: "get_unread_count",
                description: "Get the number of unread emails",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "mailbox": .object(["type": .string("string"), "description": .string("Mailbox name (optional)")]),
                        "account_name": .object(["type": .string("string"), "description": .string("Account name (optional)")])
                    ])
                ])
            ),

            // Email Action Tools
            Tool(
                name: "mark_read",
                description: "Mark an email as read or unread",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "id": .object(["type": .string("string"), "description": .string("The email ID")]),
                        "mailbox": .object(["type": .string("string"), "description": .string("Mailbox name")]),
                        "account_name": .object(["type": .string("string"), "description": .string("The mail account")]),
                        "read": .object(["type": .string("boolean"), "description": .string("true=read, false=unread")])
                    ]),
                    "required": .array([.string("id"), .string("mailbox"), .string("account_name"), .string("read")])
                ])
            ),
            Tool(
                name: "flag_email",
                description: "Flag or unflag an email",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "id": .object(["type": .string("string"), "description": .string("The email ID")]),
                        "mailbox": .object(["type": .string("string"), "description": .string("Mailbox name")]),
                        "account_name": .object(["type": .string("string"), "description": .string("The mail account")]),
                        "flagged": .object(["type": .string("boolean"), "description": .string("true=flag, false=unflag")])
                    ]),
                    "required": .array([.string("id"), .string("mailbox"), .string("account_name"), .string("flagged")])
                ])
            ),
            Tool(
                name: "move_email",
                description: "Move an email to another mailbox",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "id": .object(["type": .string("string"), "description": .string("The email ID")]),
                        "from_mailbox": .object(["type": .string("string"), "description": .string("Source mailbox")]),
                        "to_mailbox": .object(["type": .string("string"), "description": .string("Destination mailbox")]),
                        "account_name": .object(["type": .string("string"), "description": .string("The mail account")])
                    ]),
                    "required": .array([.string("id"), .string("from_mailbox"), .string("to_mailbox"), .string("account_name")])
                ])
            ),
            Tool(
                name: "delete_email",
                description: "Delete an email (move to trash)",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "id": .object(["type": .string("string"), "description": .string("The email ID")]),
                        "mailbox": .object(["type": .string("string"), "description": .string("Mailbox name")]),
                        "account_name": .object(["type": .string("string"), "description": .string("The mail account")])
                    ]),
                    "required": .array([.string("id"), .string("mailbox"), .string("account_name")])
                ])
            ),

            // Compose Tools
            Tool(
                name: "compose_email",
                description: "Compose and send a new email",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "to": .object(["type": .string("array"), "items": .object(["type": .string("string")]), "description": .string("Recipient email addresses")]),
                        "subject": .object(["type": .string("string"), "description": .string("Email subject")]),
                        "body": .object(["type": .string("string"), "description": .string("Email body content")]),
                        "cc": .object(["type": .string("array"), "items": .object(["type": .string("string")]), "description": .string("CC recipients (optional)")]),
                        "bcc": .object(["type": .string("array"), "items": .object(["type": .string("string")]), "description": .string("BCC recipients (optional)")])
                    ]),
                    "required": .array([.string("to"), .string("subject"), .string("body")])
                ])
            ),
            Tool(
                name: "reply_email",
                description: "Reply to an email",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "id": .object(["type": .string("string"), "description": .string("The email ID to reply to")]),
                        "mailbox": .object(["type": .string("string"), "description": .string("Mailbox name")]),
                        "account_name": .object(["type": .string("string"), "description": .string("The mail account")]),
                        "body": .object(["type": .string("string"), "description": .string("Reply content")]),
                        "reply_all": .object(["type": .string("boolean"), "description": .string("Reply to all recipients (default: false)")])
                    ]),
                    "required": .array([.string("id"), .string("mailbox"), .string("account_name"), .string("body")])
                ])
            ),
            Tool(
                name: "forward_email",
                description: "Forward an email",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "id": .object(["type": .string("string"), "description": .string("The email ID to forward")]),
                        "mailbox": .object(["type": .string("string"), "description": .string("Mailbox name")]),
                        "account_name": .object(["type": .string("string"), "description": .string("The mail account")]),
                        "to": .object(["type": .string("array"), "items": .object(["type": .string("string")]), "description": .string("Recipients to forward to")]),
                        "body": .object(["type": .string("string"), "description": .string("Optional message to add")])
                    ]),
                    "required": .array([.string("id"), .string("mailbox"), .string("account_name"), .string("to")])
                ])
            ),

            // Draft Tools
            Tool(
                name: "list_drafts",
                description: "List all draft emails",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "account_name": .object(["type": .string("string"), "description": .string("The mail account")])
                    ]),
                    "required": .array([.string("account_name")])
                ])
            ),
            Tool(
                name: "create_draft",
                description: "Create a new draft email",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "to": .object(["type": .string("array"), "items": .object(["type": .string("string")]), "description": .string("Recipient email addresses")]),
                        "subject": .object(["type": .string("string"), "description": .string("Email subject")]),
                        "body": .object(["type": .string("string"), "description": .string("Email body content")])
                    ]),
                    "required": .array([.string("to"), .string("subject"), .string("body")])
                ])
            ),

            // Attachment Tools
            Tool(
                name: "list_attachments",
                description: "List attachments of an email",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "id": .object(["type": .string("string"), "description": .string("The email ID")]),
                        "mailbox": .object(["type": .string("string"), "description": .string("Mailbox name")]),
                        "account_name": .object(["type": .string("string"), "description": .string("The mail account")])
                    ]),
                    "required": .array([.string("id"), .string("mailbox"), .string("account_name")])
                ])
            ),
            Tool(
                name: "save_attachment",
                description: "Save an email attachment to disk",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "id": .object(["type": .string("string"), "description": .string("The email ID")]),
                        "mailbox": .object(["type": .string("string"), "description": .string("Mailbox name")]),
                        "account_name": .object(["type": .string("string"), "description": .string("The mail account")]),
                        "attachment_name": .object(["type": .string("string"), "description": .string("Name of the attachment to save")]),
                        "save_path": .object(["type": .string("string"), "description": .string("Full path where to save the file")])
                    ]),
                    "required": .array([.string("id"), .string("mailbox"), .string("account_name"), .string("attachment_name"), .string("save_path")])
                ])
            ),

            // VIP Tools
            Tool(
                name: "list_vip_senders",
                description: "List VIP senders",
                inputSchema: .object(["type": .string("object"), "properties": .object([:])])
            ),

            // Rule Tools
            Tool(
                name: "list_rules",
                description: "List all mail rules",
                inputSchema: .object(["type": .string("object"), "properties": .object([:])])
            ),
            Tool(
                name: "enable_rule",
                description: "Enable or disable a mail rule",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "name": .object(["type": .string("string"), "description": .string("Name of the rule")]),
                        "enabled": .object(["type": .string("boolean"), "description": .string("true=enable, false=disable")])
                    ]),
                    "required": .array([.string("name"), .string("enabled")])
                ])
            ),
        ]
    }

    // MARK: - Handler Registration

    private func registerHandlers() async {
        await server.withMethodHandler(ListTools.self) { [tools] _ in
            ListTools.Result(tools: tools)
        }

        await server.withMethodHandler(CallTool.self) { [weak self] params in
            guard let self = self else {
                return CallTool.Result(content: [.text("Server unavailable")], isError: true)
            }
            return await self.handleToolCall(name: params.name, arguments: params.arguments ?? [:])
        }
    }

    // MARK: - Tool Call Handler

    private func handleToolCall(name: String, arguments: [String: Value]) async -> CallTool.Result {
        do {
            let result = try await executeToolCall(name: name, arguments: arguments)
            return CallTool.Result(content: [.text(result)])
        } catch {
            return CallTool.Result(content: [.text("Error: \(error.localizedDescription)")], isError: true)
        }
    }

    private func executeToolCall(name: String, arguments: [String: Value]) async throws -> String {
        switch name {
        // Account Tools
        case "list_accounts":
            let accounts = try await mailController.listAccounts()
            return formatJSON(accounts)

        case "get_account_info":
            guard let accountName = arguments["account_name"]?.stringValue else {
                throw MailError.invalidParameter("account_name is required")
            }
            let info = try await mailController.getAccountInfo(accountName: accountName)
            return formatJSON(info)

        // Mailbox Tools
        case "list_mailboxes":
            let accountName = arguments["account_name"]?.stringValue
            let mailboxes = try await mailController.listMailboxes(accountName: accountName)
            return formatJSON(mailboxes)

        case "create_mailbox":
            guard let name = arguments["name"]?.stringValue,
                  let accountName = arguments["account_name"]?.stringValue else {
                throw MailError.invalidParameter("name and account_name are required")
            }
            return try await mailController.createMailbox(name: name, accountName: accountName)

        case "delete_mailbox":
            guard let name = arguments["name"]?.stringValue,
                  let accountName = arguments["account_name"]?.stringValue else {
                throw MailError.invalidParameter("name and account_name are required")
            }
            return try await mailController.deleteMailbox(name: name, accountName: accountName)

        // Email Reading Tools
        case "list_emails":
            guard let mailbox = arguments["mailbox"]?.stringValue,
                  let accountName = arguments["account_name"]?.stringValue else {
                throw MailError.invalidParameter("mailbox and account_name are required")
            }
            let limit = arguments["limit"]?.intValue ?? 50
            let emails = try await mailController.listEmails(mailbox: mailbox, accountName: accountName, limit: limit)
            return formatJSON(emails)

        case "get_email":
            guard let id = arguments["id"]?.stringValue,
                  let mailbox = arguments["mailbox"]?.stringValue,
                  let accountName = arguments["account_name"]?.stringValue else {
                throw MailError.invalidParameter("id, mailbox, and account_name are required")
            }
            let email = try await mailController.getEmail(id: id, mailbox: mailbox, accountName: accountName)
            return formatJSON(email)

        case "search_emails":
            guard let query = arguments["query"]?.stringValue,
                  let mailbox = arguments["mailbox"]?.stringValue,
                  let accountName = arguments["account_name"]?.stringValue else {
                throw MailError.invalidParameter("query, mailbox, and account_name are required")
            }
            let limit = arguments["limit"]?.intValue ?? 20
            let results = try await mailController.searchEmails(query: query, mailbox: mailbox, accountName: accountName, limit: limit)
            return formatJSON(results)

        case "get_unread_count":
            let mailbox = arguments["mailbox"]?.stringValue
            let accountName = arguments["account_name"]?.stringValue
            let count = try await mailController.getUnreadCount(mailbox: mailbox, accountName: accountName)
            return "Unread count: \(count)"

        // Email Action Tools
        case "mark_read":
            guard let id = arguments["id"]?.stringValue,
                  let mailbox = arguments["mailbox"]?.stringValue,
                  let accountName = arguments["account_name"]?.stringValue,
                  let read = arguments["read"]?.boolValue else {
                throw MailError.invalidParameter("id, mailbox, account_name, and read are required")
            }
            return try await mailController.markRead(id: id, mailbox: mailbox, accountName: accountName, read: read)

        case "flag_email":
            guard let id = arguments["id"]?.stringValue,
                  let mailbox = arguments["mailbox"]?.stringValue,
                  let accountName = arguments["account_name"]?.stringValue,
                  let flagged = arguments["flagged"]?.boolValue else {
                throw MailError.invalidParameter("id, mailbox, account_name, and flagged are required")
            }
            return try await mailController.flagEmail(id: id, mailbox: mailbox, accountName: accountName, flagged: flagged)

        case "move_email":
            guard let id = arguments["id"]?.stringValue,
                  let fromMailbox = arguments["from_mailbox"]?.stringValue,
                  let toMailbox = arguments["to_mailbox"]?.stringValue,
                  let accountName = arguments["account_name"]?.stringValue else {
                throw MailError.invalidParameter("id, from_mailbox, to_mailbox, and account_name are required")
            }
            return try await mailController.moveEmail(id: id, fromMailbox: fromMailbox, toMailbox: toMailbox, accountName: accountName)

        case "delete_email":
            guard let id = arguments["id"]?.stringValue,
                  let mailbox = arguments["mailbox"]?.stringValue,
                  let accountName = arguments["account_name"]?.stringValue else {
                throw MailError.invalidParameter("id, mailbox, and account_name are required")
            }
            return try await mailController.deleteEmail(id: id, mailbox: mailbox, accountName: accountName)

        // Compose Tools
        case "compose_email":
            guard let toArray = arguments["to"]?.arrayValue,
                  let subject = arguments["subject"]?.stringValue,
                  let body = arguments["body"]?.stringValue else {
                throw MailError.invalidParameter("to, subject, and body are required")
            }
            let to = toArray.compactMap { $0.stringValue }
            let cc = arguments["cc"]?.arrayValue?.compactMap { $0.stringValue }
            let bcc = arguments["bcc"]?.arrayValue?.compactMap { $0.stringValue }
            return try await mailController.composeEmail(to: to, subject: subject, body: body, cc: cc, bcc: bcc)

        case "reply_email":
            guard let id = arguments["id"]?.stringValue,
                  let mailbox = arguments["mailbox"]?.stringValue,
                  let accountName = arguments["account_name"]?.stringValue,
                  let body = arguments["body"]?.stringValue else {
                throw MailError.invalidParameter("id, mailbox, account_name, and body are required")
            }
            let replyAll = arguments["reply_all"]?.boolValue ?? false
            return try await mailController.replyEmail(id: id, mailbox: mailbox, accountName: accountName, body: body, replyAll: replyAll)

        case "forward_email":
            guard let id = arguments["id"]?.stringValue,
                  let mailbox = arguments["mailbox"]?.stringValue,
                  let accountName = arguments["account_name"]?.stringValue,
                  let toArray = arguments["to"]?.arrayValue else {
                throw MailError.invalidParameter("id, mailbox, account_name, and to are required")
            }
            let to = toArray.compactMap { $0.stringValue }
            let body = arguments["body"]?.stringValue
            return try await mailController.forwardEmail(id: id, mailbox: mailbox, accountName: accountName, to: to, body: body)

        // Draft Tools
        case "list_drafts":
            guard let accountName = arguments["account_name"]?.stringValue else {
                throw MailError.invalidParameter("account_name is required")
            }
            let drafts = try await mailController.listDrafts(accountName: accountName)
            return formatJSON(drafts)

        case "create_draft":
            guard let toArray = arguments["to"]?.arrayValue,
                  let subject = arguments["subject"]?.stringValue,
                  let body = arguments["body"]?.stringValue else {
                throw MailError.invalidParameter("to, subject, and body are required")
            }
            let to = toArray.compactMap { $0.stringValue }
            return try await mailController.createDraft(to: to, subject: subject, body: body)

        // Attachment Tools
        case "list_attachments":
            guard let id = arguments["id"]?.stringValue,
                  let mailbox = arguments["mailbox"]?.stringValue,
                  let accountName = arguments["account_name"]?.stringValue else {
                throw MailError.invalidParameter("id, mailbox, and account_name are required")
            }
            let attachments = try await mailController.listAttachments(id: id, mailbox: mailbox, accountName: accountName)
            return formatJSON(attachments)

        case "save_attachment":
            guard let id = arguments["id"]?.stringValue,
                  let mailbox = arguments["mailbox"]?.stringValue,
                  let accountName = arguments["account_name"]?.stringValue,
                  let attachmentName = arguments["attachment_name"]?.stringValue,
                  let savePath = arguments["save_path"]?.stringValue else {
                throw MailError.invalidParameter("id, mailbox, account_name, attachment_name, and save_path are required")
            }
            return try await mailController.saveAttachment(id: id, mailbox: mailbox, accountName: accountName, attachmentName: attachmentName, savePath: savePath)

        // VIP Tools
        case "list_vip_senders":
            let vips = try await mailController.listVIPSenders()
            return formatJSON(vips)

        // Rule Tools
        case "list_rules":
            let rules = try await mailController.listRules()
            return formatJSON(rules)

        case "enable_rule":
            guard let name = arguments["name"]?.stringValue,
                  let enabled = arguments["enabled"]?.boolValue else {
                throw MailError.invalidParameter("name and enabled are required")
            }
            return try await mailController.enableRule(name: name, enabled: enabled)

        default:
            throw MailError.invalidParameter("Unknown tool: \(name)")
        }
    }

    // MARK: - Helpers

    private func formatJSON(_ value: Any) -> String {
        do {
            let data = try JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys])
            return String(data: data, encoding: .utf8) ?? "[]"
        } catch {
            return String(describing: value)
        }
    }
}

// MARK: - Value Extensions

extension Value {
    var stringValue: String? {
        if case .string(let s) = self { return s }
        return nil
    }

    var intValue: Int? {
        if case .int(let i) = self { return i }
        if case .string(let s) = self { return Int(s) }
        return nil
    }

    var boolValue: Bool? {
        if case .bool(let b) = self { return b }
        if case .string(let s) = self { return s == "true" }
        return nil
    }

    var arrayValue: [Value]? {
        if case .array(let arr) = self { return arr }
        return nil
    }
}
