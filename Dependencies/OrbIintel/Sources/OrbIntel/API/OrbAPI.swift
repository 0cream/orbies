struct OrbAPI {
    static func initialize(parameters: OrbInitializeRequestBody) -> Request {
        Request(
            path: "initialize_connection",
            method: .post,
            parameters: .create(body: .encodable(parameters))
        )
    }
    
    static func connect(apiKey: String) -> Request {
        Request(
            path: "connect",
            headers: ["X-API-Key": apiKey]
        )
    }
    
    static func getAgentInfo() -> Request {
        Request(
            path: "get_agent_info",
            method: .get
        )
    }
}

// MARK: - Requests

struct OrbInitializeRequestBody: Encodable {
    let api_key: String
    let public_key: String
    let network: String
}
