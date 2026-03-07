import SwiftUI
import MathBridge

struct ContentView: View {
    @State private var inputA: String = ""
    @State private var inputB: String = ""
    @State private var result: String = ""
    @State private var selectedOperation: Operation = .add
    @State private var singleInput: String = ""
    @State private var singleResult: String = ""
    @State private var selectedSingleOp: SingleOperation = .factorial

    enum Operation: String, CaseIterable, Identifiable {
        case add = "Add"
        case subtract = "Subtract"
        case multiply = "Multiply"
        case divide = "Divide"
        var id: String { rawValue }
    }

    enum SingleOperation: String, CaseIterable, Identifiable {
        case factorial = "Factorial"
        case fibonacci = "Fibonacci"
        var id: String { rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            ScrollView {
                VStack(spacing: 24) {
                    binaryOperationSection
                    Divider()
                    singleOperationSection
                }
                .padding(24)
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 4) {
            Text("MathLib Demo")
                .font(.title)
                .fontWeight(.bold)
            Text("SwiftUI wrapping a C library via SPM")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.bar)
    }

    private var binaryOperationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Two-operand operations")
                .font(.headline)

            Picker("Operation", selection: $selectedOperation) {
                ForEach(Operation.allCases) { op in
                    Text(op.rawValue).tag(op)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 12) {
                TextField("A", text: $inputA)
                    .textFieldStyle(.roundedBorder)
                Text(operationSymbol)
                    .font(.title2)
                    .frame(width: 30)
                TextField("B", text: $inputB)
                    .textFieldStyle(.roundedBorder)
            }

            Button("Calculate") {
                computeBinaryResult()
            }
            .buttonStyle(.borderedProminent)

            if !result.isEmpty {
                resultLabel(result)
            }
        }
    }

    private var singleOperationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Single-operand operations")
                .font(.headline)

            Picker("Operation", selection: $selectedSingleOp) {
                ForEach(SingleOperation.allCases) { op in
                    Text(op.rawValue).tag(op)
                }
            }
            .pickerStyle(.segmented)

            TextField("N", text: $singleInput)
                .textFieldStyle(.roundedBorder)

            Button("Calculate") {
                computeSingleResult()
            }
            .buttonStyle(.borderedProminent)

            if !singleResult.isEmpty {
                resultLabel(singleResult)
            }
        }
    }

    private func resultLabel(_ text: String) -> some View {
        HStack {
            Text("Result:")
                .fontWeight(.medium)
            Text(text)
                .font(.system(.body, design: .monospaced))
            Spacer()
        }
        .padding(12)
        .background(Color.accentColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var operationSymbol: String {
        switch selectedOperation {
        case .add: return "+"
        case .subtract: return "-"
        case .multiply: return "x"
        case .divide: return "/"
        }
    }

    private func computeBinaryResult() {
        guard let a = Int32(inputA), let b = Int32(inputB) else {
            result = "Invalid input -- enter integers"
            return
        }
        switch selectedOperation {
        case .add:
            result = "\(MathBridge.add(a, b))"
        case .subtract:
            result = "\(MathBridge.subtract(a, b))"
        case .multiply:
            result = "\(MathBridge.multiply(a, b))"
        case .divide:
            do {
                result = "\(try MathBridge.divide(a, b))"
            } catch {
                result = "\(error)"
            }
        }
    }

    private func computeSingleResult() {
        guard let n = Int32(singleInput) else {
            singleResult = "Invalid input -- enter an integer"
            return
        }
        do {
            switch selectedSingleOp {
            case .factorial:
                singleResult = "\(try MathBridge.factorial(n))"
            case .fibonacci:
                singleResult = "\(try MathBridge.fibonacci(n))"
            }
        } catch {
            singleResult = "\(error)"
        }
    }
}

#Preview {
    ContentView()
}
