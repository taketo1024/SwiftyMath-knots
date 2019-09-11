//
//  GridComplex.swift
//  SwiftyHomology
//
//  Created by Taketo Sano on 2019/07/04.
//

import SwiftyMath
import SwiftyHomology

public struct _Un: MPolynomialIndeterminate {
    public static let numberOfIndeterminates = Int.max
    public static func degree(_ i: Int) -> Int {
        return -2
    }
    public static func symbol(_ i: Int) -> String {
        return "U\(Format.sub(i))"
    }
}

public typealias GridComplex = ChainComplex1<FreeModule<TensorGenerator<MonomialGenerator<_Un>, GridDiagram.Generator>, 𝐙₂>>

public enum GridComplexType {
    case tilde    // [Book] p.72,  Def 4.4.1
    case hat      // [Book] p.80,  Def 4.6.12.
    case minus    // [Book] p.75,  Def 4.6.1
    case filtered // [Book] p.252, Def 13.2.1
}

extension GridComplex {
    public typealias Element = FreeModule<TensorGenerator<MonomialGenerator<_Un>, GridDiagram.Generator>, 𝐙₂>
    
    public init(type: GridComplexType, diagram G: GridDiagram) {
        self.init(type: type, diagram: G, generators: G.generators)
    }
    
    public init(type: GridComplexType, diagram G: GridDiagram, generators: GridComplexGenerators) {
        self.init(
            supported:    generators.degreeRange,
            sequence:     GridComplex.chain(type: type, diagram: G, generators: generators),
            differential: GridComplex.differential(type: type, diagram: G, generators: generators)
        )
    }
    
    public static func chain(type: GridComplexType, diagram G: GridDiagram, generators: GridComplexGenerators) -> ( (Int) -> ModuleObject<Element> ) {
        typealias T = Element.Generator
        
        let iMax = generators.degreeRange.upperBound
        
        let n = G.gridNumber
        let numberOfIndeterminates: Int = {
            switch type {
            case .tilde:    return 0
            case .hat:      return n - 1
            case .minus:    return n
            case .filtered: return n
            }
        }()
        
        return { i -> ModuleObject<Element> in
            guard i <= iMax else {
                return .zeroModule
            }
            
            let gens = (0 ... (iMax - i) / 2).flatMap { k in
                generators
                    .filter { $0.degree == i + 2 * k }
                    .flatMap { x -> [T] in
                        let indeterminates = Array(0 ..< numberOfIndeterminates)
                        let Us = MPolynomial<_Un, 𝐙₂>.monomials(ofDegree: i - x.degree, usingIndeterminates: indeterminates)
                        return Us.map{ U in T( MonomialGenerator(monomial: U), x ) }
                }
            }
            return ModuleObject(basis: gens)
        }
    }
    
    public static func differential(type: GridComplexType, diagram G: GridDiagram, generators: GridComplexGenerators) -> ( (Int) -> ModuleEnd<Element> ) {
        typealias T = Element.Generator
        
        let (Os, Xs) = (G.Os, G.Xs)
        let U: (GridDiagram.Rect) -> MonomialGenerator<_Un>? = { rect in
            switch type {
            case .tilde:
                return (rect.intersects(Xs) || rect.intersects(Os))
                        ? nil : .identity
            case .hat:
                return (rect.intersects(Xs) || rect.contains(Os.last!))
                        ? nil : .init(monomialDegree: Os.map { O in rect.contains(O) ? 1 : 0 })
            case .minus:
                return rect.intersects(Xs)
                        ? nil : .init(monomialDegree: Os.map { O in rect.contains(O) ? 1 : 0 })
            case .filtered:
                return .init(monomialDegree: Os.map { O in rect.contains(O) ? 1 : 0 })
            }
        }
        
        return { i in
            ModuleEnd.linearlyExtend { t -> Element in
                let (m, x) = t.factors
                return generators.adjacents(of: x).flatMap { y -> [Element] in
                    G.emptyRectangles(from: x, to: y).compactMap { rect -> Element? in
                        if let Us = U(rect) {
                            return .wrap( T(m * Us, y) )
                        } else {
                            return nil
                        }
                    }
                }.sumAll()
            }
        }
    }
}


extension TensorGenerator where A == MonomialGenerator<_Un>, B == GridDiagram.Generator {
    public var algebraicDegree: Int {
        let m = factors.0 // MonomialGenerator<_Un>
        return -(m.monomialDegree.indices.contains(0) ? m.monomialDegree[0] : 0)
    }
    
    public var AlexanderDegree: Int {
        let m = factors.0 // MonomialGenerator<_Un>
        let x = factors.1 // GridDiagram.Generator
        return _Un.totalDegree(exponents: m.monomialDegree) / 2 + x.AlexanderDegree
    }
    
    public static func * (a: A, t: TensorGenerator<A, B>) -> TensorGenerator<A, B> {
        return .init(a * t.factors.0, t.factors.1)
    }
}

extension GridDiagram {
    public var knotGenus: Int {
        let C = GridComplex(type: .tilde, diagram: self)
        let H = C.asBigraded { x in x.AlexanderDegree }.homology
        let M = generators.degreeRange
        let A = generators.map{ $0.AlexanderDegree }.range!
        
        for (j, i) in A.reversed() * M.reversed() {
            if !H[i, j].isZero {
                return j
            }
        }
        
        fatalError()
    }
}
