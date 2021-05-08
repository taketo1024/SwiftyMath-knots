//
//  JonesPolynomial.swift
//  SwiftyKnots
//
//  Created by Taketo Sano on 2018/04/04.
//

import SwiftyMath

public struct _A: PolynomialIndeterminate {
    public static let symbol = "A"
}

public func KauffmanBracket(_ L: Link, normalized: Bool = false) -> LaurentPolynomial<_A, 𝐙> {
    typealias P = LaurentPolynomial<_A, 𝐙>
    let A = P.indeterminate
    let B = -A.pow(2) - A.pow(-2)
    
    let n = L.crossingNumber
    return Link.State.allSequences(length: n).sum { s -> P in
        let L1 = L.resolved(by: s)
        let n = L1.components.count
        let c1 = s.weight
        let c0 = s.count - c1
        return A.pow(c0 - c1) * B.pow(normalized ? n - 1 : n)
    }
}

public struct _q: PolynomialIndeterminate {
    public static let symbol = "q"
}

public func JonesPolynomial(_ L: Link, normalized: Bool = true) -> LaurentPolynomial<_q, 𝐙> {
    let A = LaurentPolynomial<_A, 𝐙>.indeterminate
    let f = (-A).pow( -3 * L.writhe ) * KauffmanBracket(L, normalized: normalized)
    let range = -f.highestExponent / 2 ... -f.lowestExponent / 2
    let coeffs = Dictionary(keys: range) { i -> 𝐙 in
        (-1).pow(i) * f.coeff(-2 * i)
    }
    return .init(coeffs: coeffs)
}
