import SwiftUI
import Combine

final class DocumentViewModel: ObservableObject {
    @Published var text: String = ""
    @Published var lineResults: [LineResult] = []
    
    private let engine = ExpressionEngine()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        $text
            .debounce(for: .milliseconds(50), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.recalc()
            }
            .store(in: &cancellables)
    }
    
    func recalc() {
        lineResults = engine.evaluateAll(text)
    }
    
    func resetEnvironment() {
        engine.resetEnvironment()
        recalc()
    }
}
