import Foundation

public struct FeeAmount: Equatable, Hashable {
    public struct OtherFee: Equatable, Hashable {
        public init(amount: UInt64, unit: String) {
            self.amount = amount
            self.unit = unit
        }

        public var amount: UInt64
        public var unit: String
    }
    
    // MARK: - Properties
    
    /// Describes transaction fee amount (sollamports)
    public var transaction: UInt64
    /// Describes amount of SOL required to create associated token account (sollamports)
    public var minRentExemption: UInt64
    /// Describes required amount which should be left on the account after transaction (sollamports)
    public var accountRentExemption: UInt64
    
    // MARK: - Deprecated
    
    @available(*, deprecated, message: "FeeAmount now doesn't have extra info for account balances fee")
    public var accountBalances: UInt64
    @available(*, deprecated, message: "FeeAmount now doesn't have extra info for deposit fee")
    public var deposit: UInt64
    
    public var others: [OtherFee]?
    
    public var total: UInt64 {
        let othersFee = others?.reduce(UInt64.zero) { result, value in
            result + value.amount
        } ?? .zero
        
        return transaction
            + minRentExemption
            + othersFee
            /// Deprecated
            + accountBalances
            + deposit
    }

    // MARK: - Init
    
    public init(
        transaction: UInt64,
        minRentExemption: UInt64,
        accountRentExemption: UInt64,
        others: [OtherFee]? = nil
    ) {
        self.transaction = transaction
        self.accountBalances = 0
        self.others = others
        self.deposit = 0
        self.minRentExemption = minRentExemption
        self.accountRentExemption = accountRentExemption
    }

    @available(*, deprecated, message: "Use `init(transaction:)` instead")
    public init(
        transaction: UInt64,
        accountBalances: UInt64,
        deposit: UInt64 = 0,
        others: [OtherFee]? = nil
    ) {
        self.transaction = transaction
        self.accountBalances = accountBalances
        self.others = others
        self.deposit = deposit
        self.minRentExemption = 0
        self.accountRentExemption = 0
    }
    
    // MARK: - Static

    public static var zero: Self {
        Self(transaction: 0, minRentExemption: 0, accountRentExemption: 0)
    }
}

public extension FeeAmount {
    static func + (lhs: FeeAmount, rhs: FeeAmount) -> FeeAmount {
        return .init(
            transaction: lhs.transaction + rhs.transaction,
            accountBalances: lhs.accountBalances + rhs.accountBalances,
            deposit: lhs.deposit + rhs.deposit,
            others: lhs.others == nil && rhs.others == nil ? nil : ((lhs.others ?? []) + (rhs.others ?? []))
        )
    }
}
