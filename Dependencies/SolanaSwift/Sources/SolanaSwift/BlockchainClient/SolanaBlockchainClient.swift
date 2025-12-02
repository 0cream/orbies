import Foundation
import Task_retrying

/// BlockchainClient that prepares and serialises transaction to send to blockchain
public protocol SolanaBlockchainClient: AnyObject {
    /// APIClient for handling network requests
    var apiClient: SolanaAPIClient { get set }

    /// Prepare a transaction base on its instructions
    /// - Parameters:
    ///   - instructions: instructions of the transaction
    ///   - signers: the signers
    ///   - feePayer: the feePayer, usually is the first signer
    ///   - recentBlockhash: recentBlockhash, can be fetched lately when the value is nil
    ///   - feeCalculator: the fee calculator, leave it nil to use DefaultFeeCalculator
    /// - Returns: information of a prepared transaction
    func prepareTransaction(
        instructions: [TransactionInstruction],
        signers: [KeyPair],
        feePayer: PublicKey,
        feeCalculator: FeeCalculator?,
        version: SolanaAPIVersion
    ) async throws -> PreparedTransaction

    /// Send transaction
    /// - Parameter preparedTransaction: a prepared transaction
    /// - Returns: Transaction id
    func sendTransaction(
        preparedTransaction: PreparedTransaction,
        version: SolanaAPIVersion
    ) async throws -> String

    /// Simulate transaction
    /// - Parameter preparedTransaction: a prepared transaction
    func simulateTransaction(
        preparedTransaction: PreparedTransaction,
        version: SolanaAPIVersion
    ) async throws -> SimulationResult
}

public extension SolanaBlockchainClient {
    private func updateTransactionIfNeeded(
        preparedTransaction: PreparedTransaction,
        version: SolanaAPIVersion
    ) async throws -> PreparedTransaction {
        
        guard preparedTransaction.transaction.recentBlockhash == nil else {
            return preparedTransaction
        }
        
        var preparedTransaction = preparedTransaction
        let recentBlockhash: String
        
        switch version {
        case .above_2_0_0:
            recentBlockhash = try await apiClient.getLatestBlockhash()
        case .below_2_0_0:
            recentBlockhash = try await apiClient.getRecentBlockhash()
        }
        
        preparedTransaction.transaction.recentBlockhash = recentBlockhash
        
        return preparedTransaction
    }
    
    /// Send preparedTransaction
    /// - Parameter preparedTransaction: preparedTransaction to be sent
    /// - Returns: Transaction signature
    func sendTransaction(
        preparedTransaction: PreparedTransaction,
        version: SolanaAPIVersion
    ) async throws -> String {
        try await Task.retrying(
            where: { $0.isEqualTo(.blockhashNotFound) },
            maxRetryCount: 3,
            retryDelay: 1,
            timeoutInSeconds: 60
        ) { [weak self] in
            
            guard let self else {
                throw NSError(domain: "org.p2p.solana-swift", code: 9999)
            }
            
            let preparedTransaction = try await updateTransactionIfNeeded(
                preparedTransaction: preparedTransaction,
                version: version
            )
            
            guard let recentBlockhash = preparedTransaction.transaction.recentBlockhash else {
                throw NSError(domain: "org.p2p.solana-swift", code: 9999)
            }
            
            let serializedTransaction = try self.signAndSerialize(
                preparedTransaction: preparedTransaction,
                recentBlockhash: recentBlockhash
            )
            
            return try await apiClient.sendTransaction(
                transaction: serializedTransaction,
                configs: RequestConfiguration(encoding: "base64")!
            )
        }
        .value
    }

    /// Simulate transaction (for testing purpose)
    /// - Parameter preparedTransaction: preparedTransaction to be simulated
    /// - Returns: The result of Simulation
    func simulateTransaction(
        preparedTransaction: PreparedTransaction,
        version: SolanaAPIVersion
    ) async throws -> SimulationResult {
        
        let preparedTransaction = try await updateTransactionIfNeeded(
            preparedTransaction: preparedTransaction,
            version: version
        )
        
        guard let recentBlockhash = preparedTransaction.transaction.recentBlockhash else {
            throw NSError(domain: "org.p2p.solana-swift", code: 9999)
        }
        
        let serializedTransaction = try signAndSerialize(
            preparedTransaction: preparedTransaction,
            recentBlockhash: recentBlockhash
        )
        
        return try await apiClient.simulateTransaction(
            transaction: serializedTransaction, configs: RequestConfiguration(
                commitment: "confirmed",
                encoding: "base64",
                replaceRecentBlockhash: true
            )!
        )
    }

    // MARK: - Helpers

    /// Sign and serialize transaction (for testing purpose)
    /// - Parameters:
    ///   - preparedTransaction: preparedTransaction
    ///   - recentBlockhash: recentBlockhash
    /// - Returns: serializedTransaction
    internal func signAndSerialize(
        preparedTransaction: PreparedTransaction,
        recentBlockhash: String
    ) throws -> String {
        var preparedTransaction = preparedTransaction
        preparedTransaction.transaction.recentBlockhash = recentBlockhash
        try preparedTransaction.sign()
        return try preparedTransaction.serialize()
    }
}
