//
//  AsyncPublisherBootcamp.swift
//  SwiftConcurrencyBootcamp
//
//  Created by 진준호 on 1/20/25.
//

import SwiftUI
import Combine

class AsyncPublisherDataManager {
    @Published var myData: [String] = []
    
    func addData() async {
        myData.append("Apple")
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        myData.append("Banana")
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        myData.append("Orange")
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        myData.append("Watermelon")
    }
}

class AsyncPublisherBootcampViewModel: ObservableObject {
    @MainActor @Published var dataArray: [String] = []
    let manager = AsyncPublisherDataManager()
    var cancellables = Set<AnyCancellable>()
    
    init() {
        addSubscribers()
    }
    
    private func addSubscribers() {
        Task {
            // 아래와 같이 수행할 때에는 주의해야될 점이 있는데 Publisher의 끝이 언제인지 모르기 때문에 영원히 await해야되는 경우가 발생할 수도 있다.
            // AsyncSequence, AsyncStream
            for await value in manager.$myData.values {
                await MainActor.run {
                    self.dataArray = value
                }
            }
        }
        
        /*
        manager.$myData
            .receive(on: DispatchQueue.main)
            .sink { dataArray in
                self.dataArray = dataArray
            }
            .store(in: &cancellables)
         */ // combine을 이용한 구독
    }
    
    func start() async {
        await manager.addData()
    }
}

struct AsyncPublisherBootcamp: View {
    @StateObject private var viewModel = AsyncPublisherBootcampViewModel()
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach(viewModel.dataArray, id: \.self) {
                    Text($0)
                        .font(.headline)
                }
            }
        }
        .task {
            await viewModel.start()
        }
    }
}

#Preview {
    AsyncPublisherBootcamp()
}
