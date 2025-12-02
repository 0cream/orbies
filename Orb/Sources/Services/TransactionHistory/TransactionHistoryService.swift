import Dependencies
import Foundation

// MARK: - Protocol

protocol TransactionHistoryService: Actor {
    
    /// Fetch all transactions for a wallet from now back to initialization timestamp
    /// This should be called after wallet import
    func fetchInitialHistory(walletAddress: String, initTimestamp: Int) async throws
    
    /// Fetch new transactions since last fetch and complete any interrupted history fetch
    /// This should be called on app launches
    /// Will:
    /// 1. Fetch NEW transactions (from now back to most recent saved)
    /// 2. Check if initial fetch was interrupted by comparing:
    ///    - Oldest saved transaction timestamp
    ///    - vs. Wallet initialization timestamp (first tx ever)
    ///    If oldest saved > init timestamp → gap exists → initial fetch was interrupted
    /// 3. If interrupted, continue fetching OLD transactions back to init timestamp
    func fetchNewTransactions(walletAddress: String, initTimestamp: Int) async throws
    
    /// Get all stored transactions
    func getTransactions() async -> [HeliusEnhancedTransaction]
    
    /// Stream that emits whenever transactions are updated
    func transactionsStream() -> AsyncStream<[HeliusEnhancedTransaction]>
    
    /// Get transactions count
    func getTransactionCount() async -> Int
    
    /// Check if any transactions are stored
    func hasTransactions() async -> Bool
    
    /// Clear all stored transactions
    func clearHistory() async
    
    /// Start polling for new transactions every 10 seconds
    func startPolling(walletAddress: String) async
    
    /// Stop polling for new transactions
    func stopPolling() async
    
    // MARK: - Balance Reconstruction
    
    /// Get all unique token addresses that appear in transaction history
    func getUniqueTokens() async -> Set<String>
    
    /// Reconstruct token balances at a specific point in time
    /// Parses all transactions up to the given timestamp and calculates balances
    /// - Parameters:
    ///   - timestamp: Point in time (milliseconds)
    ///   - walletAddress: Wallet address to calculate balances for
    ///   - currentBalances: Optional current balances to use as starting point (avoids API call)
    /// - Returns: Dictionary of token mint → balance
    func getTokenBalancesAt(timestamp: Int, walletAddress: String, currentBalances: [String: Double]?) async -> [String: Double]
}

// MARK: - Live Implementation

actor LiveTransactionHistoryService: TransactionHistoryService {
    
    // MARK: - Dependencies
    
    @Dependency(\.heliusService)
    private var heliusService: HeliusService
    
    // MARK: - Storage
    
    private let storageKey = "com.os.orb.transactionHistory"
    
    private var cachedTransactions: [HeliusEnhancedTransaction] = []
    private var isFetching = false
    
    // Cache current balances to avoid repeated API calls
    private var cachedCurrentBalances: [String: Double]?
    private var currentBalancesWalletAddress: String?
    
    // Polling
    private var pollingTask: Task<Void, Never>?
    private var isPolling = false
    
    // Stream continuations with IDs for tracking
    private var streamContinuations: [UUID: AsyncStream<[HeliusEnhancedTransaction]>.Continuation] = [:]
    
    // MARK: - Public Methods
    
    func fetchInitialHistory(walletAddress: String, initTimestamp: Int) async throws {
        guard !isFetching else {
            print("⚠️ TransactionHistoryService: Already fetching, skipping")
            return
        }
        
        isFetching = true
        defer { isFetching = false }
        
        print("📜 TransactionHistoryService: Fetching initial transaction history")
        print("   Wallet: \(walletAddress)")
        print("   From init timestamp: \(initTimestamp) (\(formatDate(initTimestamp)))")
        
        var allTransactions: [HeliusEnhancedTransaction] = []
        var beforeSignature: String? = nil
        let batchSize = 100 // Helius limit per request
        
        let initDate = Date(timeIntervalSince1970: TimeInterval(initTimestamp))
        
        // Fetch transactions in batches going backwards in time
        while true {
            print("   Fetching batch (before: \(beforeSignature ?? "latest"))...")
            
            let batch: [HeliusEnhancedTransaction]
            do {
                batch = try await heliusService.getEnhancedTransactions(
                    address: walletAddress,
                    before: beforeSignature,
                    limit: batchSize,
                    type: nil,
                    source: nil
                )
            } catch {
                print("   ❌ Error fetching batch: \(error)")
                print("   Error details: \(error.localizedDescription)")
                throw error
            }
            
            if batch.isEmpty {
                print("   No more transactions found")
                break
            }
            
            // Filter transactions that are after init timestamp
            let validTransactions = batch.filter { tx in
                let txDate = Date(timeIntervalSince1970: TimeInterval(tx.timestamp))
                return txDate >= initDate
            }
            
            allTransactions.append(contentsOf: validTransactions)
            
            print("   Fetched \(batch.count) transactions, \(validTransactions.count) valid (total: \(allTransactions.count))")
            
            // Check if we've reached transactions before init timestamp
            if validTransactions.count < batch.count {
                print("   Reached init timestamp, stopping")
                break
            }
            
            // Get the last signature for pagination
            if let lastTx = batch.last {
                beforeSignature = lastTx.signature
            } else {
                break
            }
            
            // Safety: don't fetch more than 10,000 transactions
            if allTransactions.count >= 10_000 {
                print("   ⚠️ Reached 10,000 transaction limit, stopping")
                break
            }
        }
        
        // Sort by timestamp (newest first)
        allTransactions.sort { $0.timestamp > $1.timestamp }
        
        // Store transactions
        await storeTransactions(allTransactions)
        
        print("✅ TransactionHistoryService: Initial history fetch complete")
        print("   Total transactions: \(allTransactions.count)")
        if let newest = allTransactions.first {
            print("   Newest: \(formatDate(newest.timestamp))")
        }
        if let oldest = allTransactions.last {
            print("   Oldest: \(formatDate(oldest.timestamp))")
        }
    }
    
    func fetchNewTransactions(walletAddress: String, initTimestamp: Int) async throws {
        guard !isFetching else {
            print("⚠️ TransactionHistoryService: Already fetching, skipping")
            return
        }
        
        isFetching = true
        defer { isFetching = false }
        
        // Load existing transactions
        await loadTransactions()
        
        guard !cachedTransactions.isEmpty else {
            print("⚠️ TransactionHistoryService: No previous transactions, use fetchInitialHistory instead")
            return
        }
        
        print("📜 TransactionHistoryService: Syncing transaction history")
        
        // Step 1: Fetch NEW transactions (from now back to most recent saved)
        print("   Step 1: Fetching NEW transactions...")
        let newTransactions = try await fetchNewTransactionsForward(walletAddress: walletAddress)
        
        // Step 2: Check if we need to continue fetching OLD transactions (interrupted initial fetch)
        // Logic: If the oldest saved transaction is MORE RECENT than the wallet's first-ever transaction,
        // then there's a gap in history and the initial fetch was interrupted.
        // Example:
        //   Init timestamp: Jan 25 (first tx ever)
        //   Oldest saved:   Jan 27 (where we stopped)
        //   → Gap exists! Need to fetch Jan 25-27
        let oldestSaved = cachedTransactions.last!.timestamp
        let initDate = Date(timeIntervalSince1970: TimeInterval(initTimestamp))
        let oldestSavedDate = Date(timeIntervalSince1970: TimeInterval(oldestSaved))
        
        var missingOldTransactions: [HeliusEnhancedTransaction] = []
        
        if oldestSavedDate > initDate {
            print("   Step 2: Initial fetch was interrupted, continuing backward fetch...")
            print("   Oldest saved: \(formatDate(oldestSaved))")
            print("   Need to reach: \(formatDate(initTimestamp))")
            
            missingOldTransactions = try await fetchOldTransactionsBackward(
                walletAddress: walletAddress,
                fromSignature: cachedTransactions.last!.signature,
                initTimestamp: initTimestamp
            )
        } else {
            print("   Step 2: All historical transactions already fetched ✅")
        }
        
        // Merge all transactions
        var allTransactions = cachedTransactions
        allTransactions.append(contentsOf: newTransactions)
        allTransactions.append(contentsOf: missingOldTransactions)
        
        // Remove duplicates by signature
        var seen = Set<String>()
        allTransactions = allTransactions.filter { tx in
            if seen.contains(tx.signature) {
                return false
            }
            seen.insert(tx.signature)
            return true
        }
        
        // Sort by timestamp (newest first)
        allTransactions.sort { $0.timestamp > $1.timestamp }
        
        // Store updated transactions
        await storeTransactions(allTransactions)
        
        print("✅ TransactionHistoryService: Sync complete")
        print("   New transactions: \(newTransactions.count)")
        print("   Missing old transactions: \(missingOldTransactions.count)")
        print("   Total transactions: \(allTransactions.count)")
    }
    
    // MARK: - Private Fetch Methods
    
    /// Fetch new transactions from now back to most recent saved
    private func fetchNewTransactionsForward(walletAddress: String) async throws -> [HeliusEnhancedTransaction] {
        guard let mostRecentTx = cachedTransactions.first else {
            return []
        }
        
        let lastFetch = mostRecentTx.timestamp
        let lastFetchDate = Date(timeIntervalSince1970: TimeInterval(lastFetch))
        
        var newTransactions: [HeliusEnhancedTransaction] = []
        var beforeSignature: String? = nil
        let batchSize = 100
        
        while true {
            let batch: [HeliusEnhancedTransaction]
            do {
                batch = try await heliusService.getEnhancedTransactions(
                    address: walletAddress,
                    before: beforeSignature,
                    limit: batchSize,
                    type: nil,
                    source: nil
                )
            } catch {
                print("   ❌ Error fetching new transactions: \(error)")
                throw error
            }
            
            if batch.isEmpty {
                break
            }
            
            // Filter transactions newer than last saved
            let validTransactions = batch.filter { tx in
                let txDate = Date(timeIntervalSince1970: TimeInterval(tx.timestamp))
                return txDate > lastFetchDate
            }
            
            newTransactions.append(contentsOf: validTransactions)
            
            // If we found transactions older than last saved, we're done with new ones
            if validTransactions.count < batch.count {
                break
            }
            
            if let lastTx = batch.last {
                beforeSignature = lastTx.signature
            } else {
                break
            }
            
            // Safety limit
            if newTransactions.count >= 1000 {
                break
            }
        }
        
        return newTransactions
    }
    
    /// Continue fetching old transactions from where we left off back to init timestamp
    private func fetchOldTransactionsBackward(
        walletAddress: String,
        fromSignature: String,
        initTimestamp: Int
    ) async throws -> [HeliusEnhancedTransaction] {
        var oldTransactions: [HeliusEnhancedTransaction] = []
        var beforeSignature: String? = fromSignature
        let batchSize = 100
        
        let initDate = Date(timeIntervalSince1970: TimeInterval(initTimestamp))
        
        while true {
            let batch: [HeliusEnhancedTransaction]
            do {
                batch = try await heliusService.getEnhancedTransactions(
                    address: walletAddress,
                    before: beforeSignature,
                    limit: batchSize,
                    type: nil,
                    source: nil
                )
            } catch {
                print("   ❌ Error fetching old transactions: \(error)")
                throw error
            }
            
            if batch.isEmpty {
                break
            }
            
            // Filter transactions after init timestamp
            let validTransactions = batch.filter { tx in
                let txDate = Date(timeIntervalSince1970: TimeInterval(tx.timestamp))
                return txDate >= initDate
            }
            
            oldTransactions.append(contentsOf: validTransactions)
            
            print("   Backward fetch: \(batch.count) txs, \(validTransactions.count) valid (total old: \(oldTransactions.count))")
            
            // If we reached init timestamp, stop
            if validTransactions.count < batch.count {
                print("   Reached init timestamp ✅")
                break
            }
            
            if let lastTx = batch.last {
                beforeSignature = lastTx.signature
            } else {
                break
            }
            
            // Safety limit
            if oldTransactions.count >= 10_000 {
                break
            }
        }
        
        return oldTransactions
    }
    
    func getTransactions() async -> [HeliusEnhancedTransaction] {
        if cachedTransactions.isEmpty {
            await loadTransactions()
        }
        return cachedTransactions
    }
    
    func transactionsStream() -> AsyncStream<[HeliusEnhancedTransaction]> {
        AsyncStream { continuation in
            // Generate unique ID for this stream
            let id = UUID()
            
            // Add continuation to dictionary
            Task {
                await self.addContinuation(id: id, continuation: continuation)
                
                // Immediately send current cached transactions
                continuation.yield(await self.cachedTransactions)
            }
            
            // Clean up when stream is cancelled
            continuation.onTermination = { [weak self] _ in
                guard let self = self else { return }
                Task {
                    await self.removeContinuation(id: id)
                }
            }
        }
    }
    
    private func addContinuation(id: UUID, continuation: AsyncStream<[HeliusEnhancedTransaction]>.Continuation) {
        streamContinuations[id] = continuation
    }
    
    private func removeContinuation(id: UUID) {
        streamContinuations.removeValue(forKey: id)
    }
    
    func getTransactionCount() async -> Int {
        if cachedTransactions.isEmpty {
            await loadTransactions()
        }
        return cachedTransactions.count
    }
    
    func hasTransactions() async -> Bool {
        if cachedTransactions.isEmpty {
            await loadTransactions()
        }
        return !cachedTransactions.isEmpty
    }
    
    func clearHistory() async {
        await stopPolling()
        cachedTransactions = []
        cachedCurrentBalances = nil
        currentBalancesWalletAddress = nil
        UserDefaults.standard.removeObject(forKey: storageKey)
        print("🗑️ TransactionHistoryService: History and balance cache cleared")
    }
    
    // MARK: - Polling
    
    func startPolling(walletAddress: String) async {
        guard !isPolling else {
            print("⚠️ TransactionHistoryService: Already polling")
            return
        }
        
        print("🔄 TransactionHistoryService: Starting polling for new transactions")
        isPolling = true
        
        // Load existing transactions from storage first
        if cachedTransactions.isEmpty {
            await loadTransactions()
        }
        
        pollingTask = Task {
            while !Task.isCancelled {
                // Wait 10 seconds before next poll
                try? await Task.sleep(for: .seconds(10))
                
                guard !Task.isCancelled else { break }
                
                // Poll for new transactions
                await pollNewTransactions(walletAddress: walletAddress)
            }
        }
    }
    
    func stopPolling() async {
        guard isPolling else { return }
        
        print("🛑 TransactionHistoryService: Stopping polling")
        isPolling = false
        pollingTask?.cancel()
        pollingTask = nil
    }
    
    private func pollNewTransactions(walletAddress: String) async {
        guard !isFetching else {
            print("⚠️ TransactionHistoryService: Skipping poll - already fetching")
            return
        }
        
        isFetching = true
        defer { isFetching = false }
        
        do {
            // Get the most recent transaction timestamp
            let mostRecentTimestamp = cachedTransactions.first?.timestamp ?? 0
            
            // Fetch new transactions (limit to 10 to be efficient)
            let newBatch = try await heliusService.getEnhancedTransactions(
                address: walletAddress,
                before: nil,
                limit: 10,
                type: nil,
                source: nil
            )
            
            // Filter out transactions we already have
            let newTransactions = newBatch.filter { tx in
                tx.timestamp > mostRecentTimestamp
            }
            
            if !newTransactions.isEmpty {
                print("🆕 TransactionHistoryService: Found \(newTransactions.count) new transaction(s)")
                
                // Add new transactions to the beginning
                var updatedTransactions = newTransactions + cachedTransactions
                
                // Remove duplicates
                var seen = Set<String>()
                updatedTransactions = updatedTransactions.filter { tx in
                    if seen.contains(tx.signature) {
                        return false
                    }
                    seen.insert(tx.signature)
                    return true
                }
                
                // Sort by timestamp (newest first)
                updatedTransactions.sort { $0.timestamp > $1.timestamp }
                
                // Store and update cache
                await storeTransactions(updatedTransactions)
            }
        } catch {
            print("⚠️ TransactionHistoryService: Polling error: \(error)")
        }
    }
    
    // MARK: - Balance Reconstruction
    
    func getUniqueTokens() async -> Set<String> {
        if cachedTransactions.isEmpty {
            await loadTransactions()
        }
        
        var tokens = Set<String>()
        
        // Always include SOL
        tokens.insert("So11111111111111111111111111111111111111112")
        
        for tx in cachedTransactions {
            // Extract tokens from token transfers
            if let tokenTransfers = tx.tokenTransfers {
                for transfer in tokenTransfers {
                    tokens.insert(transfer.mint)
                }
            }
            
            // Extract tokens from native transfers (SOL)
            if let nativeTransfers = tx.nativeTransfers, !nativeTransfers.isEmpty {
                tokens.insert("So11111111111111111111111111111111111111112")
            }
            
            // Extract tokens from swap events
            if let events = tx.events {
                if let swap = events.swap {
                    if let tokenInputs = swap.tokenInputs {
                        for input in tokenInputs {
                            tokens.insert(input.mint)
                        }
                    }
                    if let tokenOutputs = swap.tokenOutputs {
                        for output in tokenOutputs {
                            tokens.insert(output.mint)
                        }
                    }
                }
            }
            
            // Extract tokens from account data
            if let accountData = tx.accountData {
                for account in accountData {
                    if let tokenBalanceChanges = account.tokenBalanceChanges {
                        for change in tokenBalanceChanges {
                            tokens.insert(change.mint)
                        }
                    }
                }
            }
        }
        
        print("🔍 TransactionHistoryService: Found \(tokens.count) unique tokens")
        return tokens
    }
    
    /// Fetch current balances from Helius (used as starting point for historical reconstruction)
    private func fetchCurrentBalances(walletAddress: String) async -> [String: Double] {
        do {
            let response = try await heliusService.searchAssets(
                walletAddress: walletAddress,
                tokenType: "fungible",
                showZeroBalance: false
            )
            
            var currentBalances: [String: Double] = [:]
            
            let solMint = "So11111111111111111111111111111111111111112"
            let usdcMint = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
            
            // Add SOL balance
            if let nativeBalance = response.result.nativeBalance {
                let solAmount = Double(nativeBalance.lamports) / 1_000_000_000.0
                currentBalances[solMint] = solAmount
                print("      Current SOL: \(String(format: "%.4f", solAmount))")
            }
            
            // Add token balances
            for item in response.result.items {
                guard let tokenInfo = item.token_info,
                      let balance = tokenInfo.balance,
                      let decimals = tokenInfo.decimals else {
                    continue
                }
                
                let tokenAddress = item.id
                let actualBalance = Double(balance) / pow(10.0, Double(decimals))
                currentBalances[tokenAddress] = actualBalance
                
                if tokenAddress == usdcMint {
                    print("      Current USDC: \(String(format: "%.2f", actualBalance))")
                }
            }
            
            return currentBalances
        } catch {
            print("      ❌ Failed to fetch current balances: \(error)")
            return [:]
        }
    }
    
    func getTokenBalancesAt(timestamp: Int, walletAddress: String, currentBalances: [String: Double]? = nil) async -> [String: Double] {
        if cachedTransactions.isEmpty {
            await loadTransactions()
        }
        
        // ✅ USE PROVIDED BALANCES OR FETCH/CACHE THEM
        let balancesToUse: [String: Double]
        if let providedBalances = currentBalances {
            // Use provided balances (preferred - avoids API call)
            balancesToUse = providedBalances
        } else if cachedCurrentBalances == nil || currentBalancesWalletAddress != walletAddress {
            // Fetch and cache balances
            print("   🔍 Fetching current balances for historical reconstruction...")
            cachedCurrentBalances = await fetchCurrentBalances(walletAddress: walletAddress)
            currentBalancesWalletAddress = walletAddress
            print("   ✅ Cached \(cachedCurrentBalances?.count ?? 0) current balances")
            balancesToUse = cachedCurrentBalances ?? [:]
        } else {
            // Use cached balances
            balancesToUse = cachedCurrentBalances ?? [:]
        }
        
        // Start with CURRENT balances (not zero!)
        var balances: [String: Double] = balancesToUse
        
        let solMint = "So11111111111111111111111111111111111111112"
        let usdcMint = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
        
        // ✅ WORK BACKWARDS: Process transactions AFTER the timestamp in REVERSE
        // This "undoes" transactions to go back in time from current balances
        let transactionsAfterTimestamp = cachedTransactions
            .filter { $0.timestamp > timestamp }
            .sorted { $0.timestamp > $1.timestamp } // Newest first
        
        for tx in transactionsAfterTimestamp {
            // Process native transfers (SOL) - REVERSE operations!
            if let nativeTransfers = tx.nativeTransfers {
                for transfer in nativeTransfers {
                    let currentSolBalance = balances[solMint] ?? 0.0
                    let amountSol = Double(transfer.amount) / 1_000_000_000.0 // lamports to SOL
                    
                    // If we received SOL → SUBTRACT it (undo receive)
                    if transfer.toUserAccount.lowercased() == walletAddress.lowercased() {
                        balances[solMint] = currentSolBalance - amountSol
                    }
                    // If we sent SOL → ADD it back (undo send)
                    else if transfer.fromUserAccount.lowercased() == walletAddress.lowercased() {
                        balances[solMint] = currentSolBalance + amountSol
                    }
                }
            }
            
            // Process token transfers - REVERSE operations!
            if let tokenTransfers = tx.tokenTransfers {
                for transfer in tokenTransfers {
                    let mint = transfer.mint
                    let currentBalance = balances[mint] ?? 0.0
                    
                    // If we received tokens → SUBTRACT them (undo receive)
                    if transfer.toUserAccount.lowercased() == walletAddress.lowercased() {
                        balances[mint] = currentBalance - transfer.tokenAmount
                    }
                    // If we sent tokens → ADD them back (undo send)
                    else if transfer.fromUserAccount.lowercased() == walletAddress.lowercased() {
                        balances[mint] = currentBalance + transfer.tokenAmount
                    }
                }
            }
            
            // Process swap events - REVERSE operations!
            if let events = tx.events, let swap = events.swap {
                // ADD BACK input tokens (undo spending them)
                if let tokenInputs = swap.tokenInputs {
                    for input in tokenInputs {
                        let mint = input.mint
                        let currentBalance = balances[mint] ?? 0.0
                        // Convert raw token amount using decimals
                        let amount = Double(input.rawTokenAmount.tokenAmount) ?? 0.0
                        let adjustedAmount = amount / pow(10.0, Double(input.rawTokenAmount.decimals))
                        balances[mint] = currentBalance + adjustedAmount  // ✅ ADD (was subtract)
                    }
                }
                
                // SUBTRACT output tokens (undo receiving them)
                if let tokenOutputs = swap.tokenOutputs {
                    for output in tokenOutputs {
                        let mint = output.mint
                        let currentBalance = balances[mint] ?? 0.0
                        // Convert raw token amount using decimals
                        let amount = Double(output.rawTokenAmount.tokenAmount) ?? 0.0
                        let adjustedAmount = amount / pow(10.0, Double(output.rawTokenAmount.decimals))
                        balances[mint] = currentBalance - adjustedAmount  // ✅ SUBTRACT (was add)
                    }
                }
            }
        }
        
        // Filter out zero or negative balances
        let filteredBalances = balances.filter { $0.value > 0 }
        
        return filteredBalances
    }
    
    // MARK: - Private Methods
    
    private func storeTransactions(_ transactions: [HeliusEnhancedTransaction]) async {
        cachedTransactions = transactions
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(transactions)
            UserDefaults.standard.set(data, forKey: storageKey)
            print("💾 TransactionHistoryService: Stored \(transactions.count) transactions")
            
            // Notify all stream subscribers
            for continuation in streamContinuations.values {
                continuation.yield(transactions)
            }
        } catch {
            print("❌ TransactionHistoryService: Failed to store transactions: \(error)")
        }
    }
    
    private func loadTransactions() async {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            cachedTransactions = []
            return
        }
        
        do {
            let decoder = JSONDecoder()
            cachedTransactions = try decoder.decode([HeliusEnhancedTransaction].self, from: data)
            print("📂 TransactionHistoryService: Loaded \(cachedTransactions.count) transactions from storage")
        } catch {
            print("❌ TransactionHistoryService: Failed to load transactions: \(error)")
            cachedTransactions = []
        }
    }
    
    private func formatDate(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Dependency Registration

extension DependencyValues {
    var transactionHistoryService: TransactionHistoryService {
        get { self[TransactionHistoryServiceKey.self] }
        set { self[TransactionHistoryServiceKey.self] = newValue }
    }
}

private enum TransactionHistoryServiceKey: DependencyKey {
    static let liveValue: TransactionHistoryService = LiveTransactionHistoryService()
    static let testValue: TransactionHistoryService = { preconditionFailure() }()
}

