//
//  AsyncStreamBootcamp.swift
//  SwiftConcurrencyBootcamp
//
//  Created by 진준호 on 2/10/25.
//

import SwiftUI

class AsyncStreamDataManager {
    func getAsyncStream() -> AsyncStream<Int> {
        AsyncStream(Int.self) { [weak self] continuation in
            self?.getFakeData(newValue: { value in
                continuation.yield(value)
            }, onFinish: {
                continuation.finish()
            })
        }
    }
    
    func getFakeData(
        newValue: @escaping (_ value: Int) -> Void,
        onFinish: @escaping () -> Void
    ) {
        let items: [Int] = [1,2,3,4,5,6,7,8,9,10]
        
        for item in items {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(item)) {
                newValue(item)
                
                if item == items.last {
                    onFinish()
                }
            }
        }
    }
    
    func getAsyncStreamWithError() -> AsyncThrowingStream<Int, Error> {
        AsyncThrowingStream(Int.self) { [weak self] continuation in
            self?.getFakeDataWithError(newValue: { value in
                continuation.yield(value)
            }, onFinish: { error in
                continuation.finish(throwing: error)
            })
        }
    }
    
    func getFakeDataWithError(
        newValue: @escaping (_ value: Int) -> Void,
        onFinish: @escaping (_ error: Error?) -> Void
    ) {
        let items: [Int] = [1,2,3,4,5,6,7,8,9,10]
        
        for item in items {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(item)) {
                newValue(item)
                print("NEW DATA: \(item)")
                
                if item == items.last {
                    onFinish(nil)
                }
            }
        }
    }

}

@MainActor
final class AsyncStreamViewModel: ObservableObject {
    let manager = AsyncStreamDataManager()
    @Published private(set) var currentNumber: Int = 0
    
    func onViewAppear() {
//        manager.getFakeData { [weak self] value in
//            self?.currentNumber = value
//        }
        
//        Task {
//            for await value in manager.getAsyncStream() {
//                currentNumber = value
//            }
//        }
        
//        Task {
//            do {
//                for try await value in manager.getAsyncStreamWithError() {
//                    currentNumber = value
//                }
//            } catch {
//                print(error)
//            }
//        }
        
        let task = Task {
            do {
                for try await value in manager.getAsyncStreamWithError().dropFirst(2) {
                    currentNumber = value
                }
            } catch {
                print(error)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            task.cancel()
            print("TASK CANCELLED!")
        }
    }
}

struct AsyncStreamBootcamp: View {
    @StateObject private var viewModel = AsyncStreamViewModel()
    
    var body: some View {
        Text("\(viewModel.currentNumber)")
            .onAppear {
                viewModel.onViewAppear()
            }
    }
}

#Preview {
    AsyncStreamBootcamp()
}
