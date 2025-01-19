//
//  GlobalActorBootcamp.swift
//  SwiftConcurrencyBootcamp
//
//  Created by 진준호 on 1/19/25.
//

import SwiftUI

@globalActor final class MyFirstGlobalActor {
    // globalActor protocol을 사용하기 위해서는 필수적으로 싱글톤 패턴을 사용할 수 밖에 없다.
    static var shared = MyNewDataManager()
}

actor MyNewDataManager {
    func getDataFromDatabase() -> [String] {
        return ["One", "Two", "Three", "Four", "FIVE", "SIX"]
    }
}

class GlobalActorBootcampViewModel: ObservableObject {
    @Published var dataArray: [String] = []
    let manager = MyFirstGlobalActor.shared
    
    @MyFirstGlobalActor
    func getData() {
        Task {
            let data = await manager.getDataFromDatabase()
            // UI를 업데이트하는 내용인데 MainActor.run 키워드를 사용하지 않더라도 현재 컴파일 에러가 발생하지 않는다.
            // @Published var dataArray 앞에 @MainActor를 사용하게 되면 아래 코드에서 컴파일 에러가 발생하게 된다.
            // 혹은 class 자체에 @MainActor를 사용하게 되면 아래 코드에서 컴파일 에러가 발생하게 된다.
            self.dataArray = data
        }
    }
}

struct GlobalActorBootcamp: View {
    @StateObject private var viewModel = GlobalActorBootcampViewModel()
    
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
            await viewModel.getData()
        }
    }
}

#Preview {
    GlobalActorBootcamp()
}
