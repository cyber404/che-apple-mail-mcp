import Foundation
import MCP

// Entry point for che-apple-mail-mcp
let server = try await CheAppleMailMCPServer()
try await server.run()
