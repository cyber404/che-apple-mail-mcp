import Foundation

/// Controller for Apple Mail via AppleScript
actor MailController {
    static let shared = MailController()

    private init() {}

    // MARK: - AppleScript Execution

    /// Execute AppleScript and return result
    func runScript(_ source: String) throws -> String {
        var error: NSDictionary?
        guard let script = NSAppleScript(source: source) else {
            throw MailError.scriptCreationFailed
        }

        let result = script.executeAndReturnError(&error)

        if let error = error {
            let message = error["NSAppleScriptErrorMessage"] as? String ?? "Unknown AppleScript error"
            let code = error["NSAppleScriptErrorNumber"] as? Int ?? -1
            throw MailError.scriptFailed(message: message, code: code)
        }

        return result.stringValue ?? ""
    }

    /// Execute AppleScript and return result as list
    func runScriptAsList(_ source: String) throws -> [String] {
        var error: NSDictionary?
        guard let script = NSAppleScript(source: source) else {
            throw MailError.scriptCreationFailed
        }

        let result = script.executeAndReturnError(&error)

        if let error = error {
            let message = error["NSAppleScriptErrorMessage"] as? String ?? "Unknown AppleScript error"
            let code = error["NSAppleScriptErrorNumber"] as? Int ?? -1
            throw MailError.scriptFailed(message: message, code: code)
        }

        // Parse list result
        var items: [String] = []
        let count = result.numberOfItems
        if count > 0 {
            for i in 1...count {
                if let item = result.atIndex(i)?.stringValue {
                    items.append(item)
                }
            }
        }
        return items
    }

    // MARK: - Account Operations

    /// List all mail accounts
    func listAccounts() throws -> [[String: Any]] {
        let script = """
        tell application "Mail"
            set accountList to {}
            repeat with acc in accounts
                set accInfo to {|name|:name of acc, |id|:id of acc, |enabled|:enabled of acc, |type|:account type of acc as string}
                set end of accountList to accInfo
            end repeat
            return accountList
        end tell
        """

        // For simplicity, get names and basic info
        let namesScript = """
        tell application "Mail"
            get name of every account
        end tell
        """

        let names = try runScriptAsList(namesScript)

        return names.map { name in
            ["name": name]
        }
    }

    /// Get account details
    func getAccountInfo(accountName: String) throws -> [String: Any] {
        let script = """
        tell application "Mail"
            set acc to account "\(escapeForAppleScript(accountName))"
            return {|name|:name of acc, |enabled|:enabled of acc, |email|:email addresses of acc}
        end tell
        """

        let enabledScript = """
        tell application "Mail"
            get enabled of account "\(escapeForAppleScript(accountName))"
        end tell
        """

        let emailsScript = """
        tell application "Mail"
            get email addresses of account "\(escapeForAppleScript(accountName))"
        end tell
        """

        let enabled = try runScript(enabledScript)
        let emails = try runScriptAsList(emailsScript)

        return [
            "name": accountName,
            "enabled": enabled == "true",
            "email_addresses": emails
        ]
    }

    // MARK: - Mailbox Operations

    /// List mailboxes for an account
    func listMailboxes(accountName: String? = nil) throws -> [[String: Any]] {
        let script: String
        if let account = accountName {
            script = """
            tell application "Mail"
                set mbList to {}
                repeat with mb in mailboxes of account "\(escapeForAppleScript(account))"
                    set mbInfo to {|name|:name of mb, |unreadCount|:unread count of mb, |messageCount|:count of messages of mb}
                    set end of mbList to mbInfo
                end repeat
                return mbList
            end tell
            """
        } else {
            script = """
            tell application "Mail"
                set mbList to {}
                repeat with acc in accounts
                    repeat with mb in mailboxes of acc
                        set mbInfo to {|name|:name of mb, |account|:name of acc, |unreadCount|:unread count of mb}
                        set end of mbList to mbInfo
                    end repeat
                end repeat
                return mbList
            end tell
            """
        }

        // Simplified: get mailbox names
        let namesScript: String
        if let account = accountName {
            namesScript = """
            tell application "Mail"
                get name of every mailbox of account "\(escapeForAppleScript(account))"
            end tell
            """
        } else {
            namesScript = """
            tell application "Mail"
                set allNames to {}
                repeat with acc in accounts
                    set accMailboxes to name of every mailbox of acc
                    set allNames to allNames & accMailboxes
                end repeat
                return allNames
            end tell
            """
        }

        let names = try runScriptAsList(namesScript)

        return names.map { name in
            var info: [String: Any] = ["name": name]
            if let account = accountName {
                info["account"] = account
            }
            return info
        }
    }

    /// Create a new mailbox
    func createMailbox(name: String, accountName: String) throws -> String {
        let script = """
        tell application "Mail"
            make new mailbox with properties {name:"\(escapeForAppleScript(name))"} at account "\(escapeForAppleScript(accountName))"
            return "Created mailbox: \(escapeForAppleScript(name))"
        end tell
        """
        return try runScript(script)
    }

    /// Delete a mailbox
    func deleteMailbox(name: String, accountName: String) throws -> String {
        let script = """
        tell application "Mail"
            delete mailbox "\(escapeForAppleScript(name))" of account "\(escapeForAppleScript(accountName))"
            return "Deleted mailbox: \(escapeForAppleScript(name))"
        end tell
        """
        return try runScript(script)
    }

    // MARK: - Email Operations

    /// List emails in a mailbox
    func listEmails(mailbox: String, accountName: String, limit: Int = 50) throws -> [[String: Any]] {
        let script = """
        tell application "Mail"
            set msgs to messages 1 thru \(limit) of mailbox "\(escapeForAppleScript(mailbox))" of account "\(escapeForAppleScript(accountName))"
            set msgList to {}
            repeat with msg in msgs
                set msgInfo to {|id|:id of msg, |subject|:subject of msg, |sender|:sender of msg, |dateReceived|:date received of msg as string, |read|:read status of msg}
                set end of msgList to msgInfo
            end repeat
            return msgList
        end tell
        """

        // Simplified approach: get basic info
        let subjectsScript = """
        tell application "Mail"
            get subject of messages 1 thru \(limit) of mailbox "\(escapeForAppleScript(mailbox))" of account "\(escapeForAppleScript(accountName))"
        end tell
        """

        let sendersScript = """
        tell application "Mail"
            get sender of messages 1 thru \(limit) of mailbox "\(escapeForAppleScript(mailbox))" of account "\(escapeForAppleScript(accountName))"
        end tell
        """

        let idsScript = """
        tell application "Mail"
            get id of messages 1 thru \(limit) of mailbox "\(escapeForAppleScript(mailbox))" of account "\(escapeForAppleScript(accountName))"
        end tell
        """

        let subjects = try runScriptAsList(subjectsScript)
        let senders = try runScriptAsList(sendersScript)
        let ids = try runScriptAsList(idsScript)

        var emails: [[String: Any]] = []
        for i in 0..<min(subjects.count, senders.count, ids.count) {
            emails.append([
                "id": ids[i],
                "subject": subjects[i],
                "sender": senders[i]
            ])
        }

        return emails
    }

    /// Get email content by ID
    func getEmail(id: String, mailbox: String, accountName: String) throws -> [String: Any] {
        let script = """
        tell application "Mail"
            set msg to message id \(id) of mailbox "\(escapeForAppleScript(mailbox))" of account "\(escapeForAppleScript(accountName))"
            set msgSubject to subject of msg
            set msgSender to sender of msg
            set msgContent to content of msg
            set msgDate to date received of msg as string
            set msgRead to read status of msg
            return {|subject|:msgSubject, |sender|:msgSender, |content|:msgContent, |date|:msgDate, |read|:msgRead}
        end tell
        """

        // Get individual properties
        let subjectScript = """
        tell application "Mail"
            get subject of message id \(id) of mailbox "\(escapeForAppleScript(mailbox))" of account "\(escapeForAppleScript(accountName))"
        end tell
        """

        let senderScript = """
        tell application "Mail"
            get sender of message id \(id) of mailbox "\(escapeForAppleScript(mailbox))" of account "\(escapeForAppleScript(accountName))"
        end tell
        """

        let contentScript = """
        tell application "Mail"
            get content of message id \(id) of mailbox "\(escapeForAppleScript(mailbox))" of account "\(escapeForAppleScript(accountName))"
        end tell
        """

        let subject = try runScript(subjectScript)
        let sender = try runScript(senderScript)
        let content = try runScript(contentScript)

        return [
            "id": id,
            "subject": subject,
            "sender": sender,
            "content": content
        ]
    }

    /// Search emails
    func searchEmails(query: String, mailbox: String, accountName: String, limit: Int = 20) throws -> [[String: Any]] {
        let script = """
        tell application "Mail"
            set foundMsgs to (messages of mailbox "\(escapeForAppleScript(mailbox))" of account "\(escapeForAppleScript(accountName))" whose subject contains "\(escapeForAppleScript(query))" or content contains "\(escapeForAppleScript(query))")
            set msgList to {}
            set counter to 0
            repeat with msg in foundMsgs
                if counter ≥ \(limit) then exit repeat
                set msgInfo to {|id|:id of msg as string, |subject|:subject of msg, |sender|:sender of msg}
                set end of msgList to msgInfo
                set counter to counter + 1
            end repeat
            return msgList
        end tell
        """

        // Simplified: search by subject
        let searchScript = """
        tell application "Mail"
            set foundMsgs to (messages of mailbox "\(escapeForAppleScript(mailbox))" of account "\(escapeForAppleScript(accountName))" whose subject contains "\(escapeForAppleScript(query))")
            set subjects to {}
            set counter to 0
            repeat with msg in foundMsgs
                if counter ≥ \(limit) then exit repeat
                set end of subjects to subject of msg
                set counter to counter + 1
            end repeat
            return subjects
        end tell
        """

        let subjects = try runScriptAsList(searchScript)

        return subjects.map { subject in
            ["subject": subject, "query": query]
        }
    }

    /// Get unread count
    func getUnreadCount(mailbox: String? = nil, accountName: String? = nil) throws -> Int {
        let script: String
        if let mailbox = mailbox, let account = accountName {
            script = """
            tell application "Mail"
                get unread count of mailbox "\(escapeForAppleScript(mailbox))" of account "\(escapeForAppleScript(account))"
            end tell
            """
        } else if let account = accountName {
            script = """
            tell application "Mail"
                set total to 0
                repeat with mb in mailboxes of account "\(escapeForAppleScript(account))"
                    set total to total + (unread count of mb)
                end repeat
                return total
            end tell
            """
        } else {
            script = """
            tell application "Mail"
                set total to 0
                repeat with acc in accounts
                    repeat with mb in mailboxes of acc
                        set total to total + (unread count of mb)
                    end repeat
                end repeat
                return total
            end tell
            """
        }

        let result = try runScript(script)
        return Int(result) ?? 0
    }

    // MARK: - Email Actions

    /// Mark email as read/unread
    func markRead(id: String, mailbox: String, accountName: String, read: Bool) throws -> String {
        let script = """
        tell application "Mail"
            set read status of message id \(id) of mailbox "\(escapeForAppleScript(mailbox))" of account "\(escapeForAppleScript(accountName))" to \(read)
            return "Email marked as \(read ? "read" : "unread")"
        end tell
        """
        return try runScript(script)
    }

    /// Flag email
    func flagEmail(id: String, mailbox: String, accountName: String, flagged: Bool) throws -> String {
        let script = """
        tell application "Mail"
            set flagged status of message id \(id) of mailbox "\(escapeForAppleScript(mailbox))" of account "\(escapeForAppleScript(accountName))" to \(flagged)
            return "Email \(flagged ? "flagged" : "unflagged")"
        end tell
        """
        return try runScript(script)
    }

    /// Move email to another mailbox
    func moveEmail(id: String, fromMailbox: String, toMailbox: String, accountName: String) throws -> String {
        let script = """
        tell application "Mail"
            set msg to message id \(id) of mailbox "\(escapeForAppleScript(fromMailbox))" of account "\(escapeForAppleScript(accountName))"
            move msg to mailbox "\(escapeForAppleScript(toMailbox))" of account "\(escapeForAppleScript(accountName))"
            return "Email moved to \(escapeForAppleScript(toMailbox))"
        end tell
        """
        return try runScript(script)
    }

    /// Delete email (move to trash)
    func deleteEmail(id: String, mailbox: String, accountName: String) throws -> String {
        let script = """
        tell application "Mail"
            delete message id \(id) of mailbox "\(escapeForAppleScript(mailbox))" of account "\(escapeForAppleScript(accountName))"
            return "Email deleted"
        end tell
        """
        return try runScript(script)
    }

    // MARK: - Compose Operations

    /// Compose and send a new email
    func composeEmail(to: [String], subject: String, body: String, cc: [String]? = nil, bcc: [String]? = nil, accountName: String? = nil) throws -> String {
        var script = """
        tell application "Mail"
            set newMessage to make new outgoing message with properties {subject:"\(escapeForAppleScript(subject))", content:"\(escapeForAppleScript(body))", visible:true}
            tell newMessage
        """

        for recipient in to {
            script += """
                make new to recipient at end of to recipients with properties {address:"\(escapeForAppleScript(recipient))"}
            """
        }

        if let cc = cc {
            for recipient in cc {
                script += """
                    make new cc recipient at end of cc recipients with properties {address:"\(escapeForAppleScript(recipient))"}
                """
            }
        }

        if let bcc = bcc {
            for recipient in bcc {
                script += """
                    make new bcc recipient at end of bcc recipients with properties {address:"\(escapeForAppleScript(recipient))"}
                """
            }
        }

        script += """
            end tell
            send newMessage
            return "Email sent successfully"
        end tell
        """

        return try runScript(script)
    }

    /// Reply to an email
    func replyEmail(id: String, mailbox: String, accountName: String, body: String, replyAll: Bool = false) throws -> String {
        let replyType = replyAll ? "reply all" : "reply"
        let script = """
        tell application "Mail"
            set originalMsg to message id \(id) of mailbox "\(escapeForAppleScript(mailbox))" of account "\(escapeForAppleScript(accountName))"
            set replyMsg to \(replyType) originalMsg with opening window
            tell replyMsg
                set content to "\(escapeForAppleScript(body))" & return & return & content
            end tell
            send replyMsg
            return "Reply sent successfully"
        end tell
        """
        return try runScript(script)
    }

    /// Forward an email
    func forwardEmail(id: String, mailbox: String, accountName: String, to: [String], body: String? = nil) throws -> String {
        var script = """
        tell application "Mail"
            set originalMsg to message id \(id) of mailbox "\(escapeForAppleScript(mailbox))" of account "\(escapeForAppleScript(accountName))"
            set fwdMsg to forward originalMsg with opening window
            tell fwdMsg
        """

        for recipient in to {
            script += """
                make new to recipient at end of to recipients with properties {address:"\(escapeForAppleScript(recipient))"}
            """
        }

        if let body = body {
            script += """
                set content to "\(escapeForAppleScript(body))" & return & return & content
            """
        }

        script += """
            end tell
            send fwdMsg
            return "Email forwarded successfully"
        end tell
        """

        return try runScript(script)
    }

    // MARK: - Draft Operations

    /// List drafts
    func listDrafts(accountName: String) throws -> [[String: Any]] {
        let script = """
        tell application "Mail"
            get subject of messages of mailbox "Drafts" of account "\(escapeForAppleScript(accountName))"
        end tell
        """

        let subjects = try runScriptAsList(script)

        return subjects.map { subject in
            ["subject": subject]
        }
    }

    /// Create a draft
    func createDraft(to: [String], subject: String, body: String, accountName: String? = nil) throws -> String {
        var script = """
        tell application "Mail"
            set newMessage to make new outgoing message with properties {subject:"\(escapeForAppleScript(subject))", content:"\(escapeForAppleScript(body))", visible:true}
            tell newMessage
        """

        for recipient in to {
            script += """
                make new to recipient at end of to recipients with properties {address:"\(escapeForAppleScript(recipient))"}
            """
        }

        script += """
            end tell
            save newMessage
            return "Draft created successfully"
        end tell
        """

        return try runScript(script)
    }

    // MARK: - Attachment Operations

    /// List attachments of an email
    func listAttachments(id: String, mailbox: String, accountName: String) throws -> [[String: Any]] {
        let script = """
        tell application "Mail"
            set msg to message id \(id) of mailbox "\(escapeForAppleScript(mailbox))" of account "\(escapeForAppleScript(accountName))"
            set attachmentList to {}
            repeat with att in mail attachments of msg
                set attInfo to {|name|:name of att, |size|:file size of att}
                set end of attachmentList to attInfo
            end repeat
            return attachmentList
        end tell
        """

        let namesScript = """
        tell application "Mail"
            get name of every mail attachment of message id \(id) of mailbox "\(escapeForAppleScript(mailbox))" of account "\(escapeForAppleScript(accountName))"
        end tell
        """

        let names = try runScriptAsList(namesScript)

        return names.map { name in
            ["name": name]
        }
    }

    /// Save attachment to disk
    func saveAttachment(id: String, mailbox: String, accountName: String, attachmentName: String, savePath: String) throws -> String {
        let script = """
        tell application "Mail"
            set msg to message id \(id) of mailbox "\(escapeForAppleScript(mailbox))" of account "\(escapeForAppleScript(accountName))"
            repeat with att in mail attachments of msg
                if name of att is "\(escapeForAppleScript(attachmentName))" then
                    save att in POSIX file "\(escapeForAppleScript(savePath))"
                    return "Attachment saved to \(escapeForAppleScript(savePath))"
                end if
            end repeat
            return "Attachment not found"
        end tell
        """
        return try runScript(script)
    }

    // MARK: - VIP Operations

    /// List VIP senders
    func listVIPSenders() throws -> [String] {
        let script = """
        tell application "Mail"
            get sender of messages of mailbox "VIP"
        end tell
        """

        return try runScriptAsList(script)
    }

    // MARK: - Rule Operations

    /// List mail rules
    func listRules() throws -> [[String: Any]] {
        let script = """
        tell application "Mail"
            get name of every rule
        end tell
        """

        let names = try runScriptAsList(script)

        return names.map { name in
            ["name": name]
        }
    }

    /// Enable/disable a rule
    func enableRule(name: String, enabled: Bool) throws -> String {
        let script = """
        tell application "Mail"
            set enabled of rule "\(escapeForAppleScript(name))" to \(enabled)
            return "Rule '\(escapeForAppleScript(name))' \(enabled ? "enabled" : "disabled")"
        end tell
        """
        return try runScript(script)
    }

    // MARK: - Helpers

    /// Escape special characters for AppleScript strings
    private func escapeForAppleScript(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
    }
}

// MARK: - Mail Error

enum MailError: LocalizedError {
    case scriptCreationFailed
    case scriptFailed(message: String, code: Int)
    case invalidParameter(String)

    var errorDescription: String? {
        switch self {
        case .scriptCreationFailed:
            return "Failed to create AppleScript"
        case .scriptFailed(let message, let code):
            return "AppleScript error (\(code)): \(message)"
        case .invalidParameter(let message):
            return "Invalid parameter: \(message)"
        }
    }
}
