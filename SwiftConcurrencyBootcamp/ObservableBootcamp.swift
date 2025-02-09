//
//  ObservableBootcamp.swift
//  SwiftConcurrencyBootcamp
//
//  Created by 진준호 on 2/10/25.
//

import SwiftUI

actor TitleDatabase {
    func getNewTitle() -> String {
        "Some new title!"
    }
}

@Observable class ObservableViewModel {
    @ObservationIgnored let database = TitleDatabase()
    @MainActor var title: String = "Starting title"
    
//    @MainActor
//    func updateTitle() async {
//        title = await database.getNewTitle()
//        print(Thread.current)
//    }
    
    func updateTitle() async {
        let title = await database.getNewTitle()
        
        await MainActor.run {
            self.title = title
            print(Thread.current)
        }
    }
    
//    func updateTitle() {
//        Task { @MainActor in
//            title = await database.getNewTitle()
//            print(Thread.current)
//        }
//    }
}

struct ObservableBootcamp: View {
    @State private var viewModel = ObservableViewModel()
    
    var body: some View {
        Text(viewModel.title)
            .task {
                await viewModel.updateTitle()
            }
//            .onAppear {
//                viewModel.updateTitle()
//            }
    }
}

#Preview {
    ObservableBootcamp()
}
