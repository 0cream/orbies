import Foundation

public enum BlockchainClientError: Error, Equatable {
    case sendTokenToYourSelf
    case invalidAccountInfo
    case other(String)
}

public enum SolanaAPIVersion {
    case above_2_0_0
    case below_2_0_0
}

/// Default implementation of SolanaBlockchainClient
public class BlockchainClient: SolanaBlockchainClient {

    // MARK: - Public
    
    public var apiClient: SolanaAPIClient
    
    // MARK: - Private
    
    private let minRentExemptionService: MinRentExemptionService

    // MARK: - Init
    
    public init(apiClient: SolanaAPIClient) {
        self.apiClient = apiClient
        self.minRentExemptionService = MinRentExemptionService(apiClient: apiClient)
    }
    
    public func calculateMinRentExemptionAmount(transaction: Transaction, minRentExemption: UInt64) -> UInt64 {
        transaction.instructions.reduce(into: UInt64.zero) { result, instruction in
            switch instruction.programId {
            case SystemProgram.id:
                guard instruction.data.count >= 4 else { break }
                
                let index = UInt32(bytes: instruction.data[0 ..< 4])
                
                if index == SystemProgram.Index.create, instruction.keys.last?.publicKey != nil {
                    result += minRentExemption
                }

            case AssociatedTokenProgram.id:
                if instruction.keys[safe: 1]?.publicKey != nil {
                    result += minRentExemption
                }

            default:
                break
            }
        }
    }

    /// Prepare a transaction to be sent using SolanaBlockchainClient
    /// - Parameters:
    ///   - instructions: the instructions of the transaction
    ///   - signers: the signers of the transaction
    ///   - feePayer: the feePayer of the transaction
    ///   - feeCalculator: (Optional) fee custom calculator for calculating fee
    /// - Returns: PreparedTransaction, can be sent or simulated using SolanaBlockchainClient
    public func prepareTransaction(
        instructions: [TransactionInstruction],
        signers: [KeyPair],
        feePayer: PublicKey,
        feeCalculator fc: FeeCalculator? = nil,
        version: SolanaAPIVersion
    ) async throws -> PreparedTransaction {
        // form transaction
        var transaction = Transaction(instructions: instructions, recentBlockhash: nil, feePayer: feePayer)

        transaction.recentBlockhash = try await {
            switch version {
                // devnet
            case .above_2_0_0:
                return try await apiClient.getLatestBlockhash()
                
                // mainnet
            case .below_2_0_0:
                return try await apiClient.getRecentBlockhash()
            }
        }()
        
        let expectedFee = try await calculateTransactionFee(transaction: transaction, version: version)

        // if any signers, sign
        if !signers.isEmpty {
            try transaction.sign(signers: signers)
        }

        // return formed transaction
        return .init(transaction: transaction, signers: signers, expectedFee: expectedFee)
    }
        
    public func calculateTransactionFee(transaction: Transaction, version: SolanaAPIVersion) async throws -> FeeAmount {
        var transaction = try await updateTransactionIfNeeded(
            transaction: transaction,
            version: version
        )
        
        let minRentExemption = try await minRentExemptionService.getMinimumBalanceForRentExemption(
            span: 165,
            commitment: "finalized"
        )
        
        let accountRentExemption = try await minRentExemptionService.getMinimumBalanceForRentExemption(
            span: 0,
            commitment: "finalized"
        )
        
        let transactionFee = try await apiClient.getFeeForMessage(
            message: try transaction.compileMessage(),
            commitment: nil
        )
        
        return FeeAmount(
            transaction: transactionFee,
            minRentExemption: calculateMinRentExemptionAmount(
                transaction: transaction,
                minRentExemption: minRentExemption
            ),
            /// Account balance after buy should be upper `accountRentExemption`
            accountRentExemption: accountRentExemption
        )
    }

    /// Create prepared transaction for sending SOL
    /// - Parameters:
    ///   - account
    ///   - to: destination wallet address
    ///   - amount: amount in lamports
    ///   - feePayer: customm fee payer, can be omited if the authorized user is the payer
    ///    - recentBlockhash optional
    /// - Returns: PreparedTransaction, can be sent or simulated using SolanaBlockchainClient
    public func prepareSendingNativeSOL(
        from account: KeyPair,
        to destination: String,
        amount: UInt64,
        feePayer: PublicKey? = nil,
        version: SolanaAPIVersion
    ) async throws -> PreparedTransaction {
        let feePayer = feePayer ?? account.publicKey
        let fromPublicKey = account.publicKey
        if fromPublicKey.base58EncodedString == destination {
            throw BlockchainClientError.sendTokenToYourSelf
        }
        var accountInfo: BufferInfo<EmptyInfo>?
        do {
            accountInfo = try await apiClient.getAccountInfo(account: destination)
            guard accountInfo == nil || accountInfo?.owner == SystemProgram.id.base58EncodedString
            else { throw BlockchainClientError.invalidAccountInfo }
        } catch let error as APIClientError where error == .couldNotRetrieveAccountInfo {
            // ignoring error
            accountInfo = nil
        } catch {
            throw error
        }

        // form instruction
        let instruction = try SystemProgram.transferInstruction(
            from: fromPublicKey,
            to: PublicKey(string: destination),
            lamports: amount
        )
        return try await prepareTransaction(
            instructions: [instruction],
            signers: [account],
            feePayer: feePayer,
            version: version
        )
    }

    /// Prepare for sending any SPLToken
    /// - Parameters:
    ///   - account: user's account to send from
    ///   - mintAddress: mint address of sending token
    ///   - decimals: decimals of the sending token
    ///   - fromPublicKey: the concrete spl token address in user's account
    ///   - destinationAddress: the destination address, can be token address or native Solana address
    ///   - amount: amount to be sent
    ///   - feePayer: (Optional) if the transaction would be paid by another user
    ///   - transferChecked: (Default: false) use transferChecked instruction instead of transfer transaction
    ///   - minRentExemption: (Optional) pre-calculated min rent exemption, will be fetched if not provided
    /// - Returns: (preparedTransaction: PreparedTransaction, realDestination: String), preparedTransaction can be sent
    /// or simulated using SolanaBlockchainClient, the realDestination is the real spl address of destination. Can be
    /// different from destinationAddress if destinationAddress is a native Solana address
    public func prepareSendingSPLTokens(
        account: KeyPair,
        mintAddress: String,
        tokenProgramId: PublicKey,
        decimals: Decimals,
        from fromPublicKey: String,
        to destinationAddress: String,
        amount: UInt64,
        feePayer: PublicKey? = nil,
        transferChecked: Bool = false,
        version: SolanaAPIVersion
    ) async throws -> (preparedTransaction: PreparedTransaction, realDestination: String) {
        let feePayer = feePayer ?? account.publicKey

        let splDestination = try await apiClient.findSPLTokenDestinationAddress(
            mintAddress: mintAddress,
            destinationAddress: destinationAddress,
            tokenProgramId: tokenProgramId
        )

        // get address
        let toPublicKey = splDestination.destination

        // catch error
        if fromPublicKey == toPublicKey.base58EncodedString {
            throw BlockchainClientError.sendTokenToYourSelf
        }

        let fromPublicKey = try PublicKey(string: fromPublicKey)

        var instructions = [TransactionInstruction]()

        // create associated token address
        var accountsCreationFee: UInt64 = 0
        if splDestination.isUnregisteredAsocciatedToken {
            let mint = try PublicKey(string: mintAddress)
            let owner = try PublicKey(string: destinationAddress)

            let createATokenInstruction = try AssociatedTokenProgram.createAssociatedTokenAccountInstruction(
                mint: mint,
                owner: owner,
                payer: feePayer,
                tokenProgramId: tokenProgramId
            )
            instructions.append(createATokenInstruction)
        }

        // send instruction
        let sendInstruction: TransactionInstruction

        // use transfer checked transaction for proxy, otherwise use normal transfer transaction
        if transferChecked {
            // transfer checked transaction
            if tokenProgramId == TokenProgram.id {
                sendInstruction = try TokenProgram.transferCheckedInstruction(
                    source: fromPublicKey,
                    mint: PublicKey(string: mintAddress),
                    destination: splDestination.destination,
                    owner: account.publicKey,
                    multiSigners: [],
                    amount: amount,
                    decimals: decimals
                )
            } else {
                sendInstruction = try Token2022Program.transferCheckedInstruction(
                    source: fromPublicKey,
                    mint: PublicKey(string: mintAddress),
                    destination: splDestination.destination,
                    owner: account.publicKey,
                    multiSigners: [],
                    amount: amount,
                    decimals: decimals
                )
            }
        } else {
            // transfer transaction
            if tokenProgramId == TokenProgram.id {
                sendInstruction = TokenProgram.transferInstruction(
                    source: fromPublicKey,
                    destination: toPublicKey,
                    owner: account.publicKey,
                    amount: amount
                )
            } else {
                sendInstruction = Token2022Program.transferInstruction(
                    source: fromPublicKey,
                    destination: toPublicKey,
                    owner: account.publicKey,
                    amount: amount
                )
            }
        }

        instructions.append(sendInstruction)

        var realDestination = destinationAddress
        if !splDestination.isUnregisteredAsocciatedToken {
            realDestination = splDestination.destination.base58EncodedString
        }

        // if not, serialize and send instructions normally
        let preparedTransaction = try await prepareTransaction(
            instructions: instructions,
            signers: [account],
            feePayer: feePayer,
            feeCalculator: nil,
            version: version
        )

        return (preparedTransaction, realDestination)
    }
    
    private func updateTransactionIfNeeded(
        transaction: Transaction,
        version: SolanaAPIVersion
    ) async throws -> Transaction {
        
        guard transaction.recentBlockhash == nil else {
            return transaction
        }
        
        var transaction = transaction
        let recentBlockhash: String
        
        switch version {
        case .above_2_0_0:
            recentBlockhash = try await apiClient.getLatestBlockhash()
        case .below_2_0_0:
            recentBlockhash = try await apiClient.getRecentBlockhash()
        }
        
        transaction.recentBlockhash = recentBlockhash
        
        return transaction
    }
}

private final class MinRentExemptionService {
    struct CacheKey: Hashable {
        let span: UInt64
        let commitment: String
    }
    
    struct CacheValue {
        let result: UInt64
        let createdAt: Date
    }
    
    private var cache: [CacheKey: CacheValue] = [:]
    private var apiClient: SolanaAPIClient
    
    init(apiClient: SolanaAPIClient) {
        self.apiClient = apiClient
    }
    
    func getMinimumBalanceForRentExemption(span: UInt64, commitment: String) async throws -> UInt64 {
        let key = CacheKey(span: span, commitment: commitment)
        
        guard
            let value = cache[key],
            Date().timeIntervalSince(value.createdAt) < 30
        else {
            return try await getMinimumBalanceForRentExemptionAndUpdateCache(span: span, commitment: commitment)
        }
        
        return value.result
    }
    
    func getMinimumBalanceForRentExemptionAndUpdateCache(span: UInt64, commitment: String) async throws -> UInt64 {
        let result = try await apiClient.getMinimumBalanceForRentExemption(
            span: span,
            commitment: commitment
        )
        
        let key = CacheKey(span: span, commitment: commitment)
        let value = CacheValue(result: result, createdAt: Date())
        
        cache[key] = value
        
        return value.result
    }
}
