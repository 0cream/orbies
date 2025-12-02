import SwiftUI
import SFSafeSymbols
import UIKit

struct CurrencyUI: Equatable, Hashable {
    let currency: AnyCurrency
    
    var symbol: UIImage?
    var sfSymbol: SFSymbol?
    var code: String { currency.code }
    
    let hasTextSymbol: Bool
    var string: String { currency.string }
    var stringWithCurrency: String { currency.stringWithCurrency }

    init(_ currency: AnyCurrency, symbol: UIImage? = nil, sfSymbol: SFSymbol? = nil) {
        self.currency = currency
        self.symbol = symbol
        self.sfSymbol = sfSymbol
        self.hasTextSymbol = symbol != nil || sfSymbol != nil
    }
    
    init(_ currency: AnyCurrency) {
        self.currency = currency
        self.symbol = nil
        self.sfSymbol = nil
        self.hasTextSymbol = false
    }

    @ViewBuilder
    func textWithCurrency(
        valueFontSize: CGFloat,
        valueColor: Color,
        signFontSize: CGFloat,
        signFontWeight: Font.Weight,
        fractionDigits: Int = 2,
        useGroupingSeparator: Bool = false,
        roundingMode: NumberFormatter.RoundingMode = .down
    ) -> some View {
        HStack(spacing: .zero) {
            if let sfSymbol {
                Text(sfSymbol.image)
                    .font(.system(size: signFontSize, weight: signFontWeight))
                    .frame(width: valueFontSize, height: valueFontSize)
                    .padding(.trailing, 1)

                Text(
                    string(
                        fractionDigits: fractionDigits,
                        useGroupingSeparator: useGroupingSeparator,
                        roundingMode: roundingMode
                    )
                )
                .foregroundColor(valueColor)
            } else {
                Text(
                    stringWithCurrency(
                        fractionDigits: fractionDigits,
                        useGroupingSeparator: useGroupingSeparator,
                        roundingMode: roundingMode
                    )
                )
                .foregroundColor(valueColor)
            }
        }
    }

    func stringWithCurrency(
        fractionDigits: Int,
        useGroupingSeparator: Bool,
        roundingMode: NumberFormatter.RoundingMode
    ) -> String {
        currency.stringWithCurrency(
            fractionDigits: fractionDigits,
            useGroupingSeparator: useGroupingSeparator,
            roundingMode: roundingMode
        )
    }

    func string(
        fractionDigits: Int,
        useGroupingSeparator: Bool,
        roundingMode: NumberFormatter.RoundingMode
    ) -> String {
        currency.string(
            fractionDigits: fractionDigits,
            useGroupingSeparator: useGroupingSeparator,
            roundingMode: roundingMode
        )
    }
    
    func abbreviateAmount(fractionDigits: Int = 2) -> String {
        currency.abbreviateAmount(fractionDigits: fractionDigits)
    }
    
    func abbreviateAmountWithCurrency(fractionDigits: Int = 2) -> String {
        currency.abbreviateAmountWithCurrency(fractionDigits: fractionDigits)
    }
}

extension View {
    func asAnyView() -> AnyView {
        AnyView(self)
    }
}

