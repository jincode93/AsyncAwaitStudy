//
//  ActorsBootcamp.swift
//  SwiftConcurrencyBootcamp
//
//  Created by 진준호 on 1/19/25.
//

import SwiftUI

// 1. What is the problem that actors are solving?
// 2. How was this problem solved prior to actors?
// 3. Actors can solve the problem!

class MyDataManager {
    static let instance = MyDataManager()
    private init() { }
    
    var data: [String] = []
    private let lock = DispatchQueue(label: "com.MyApp.MyDataManager")
    
    /*
    func getRandomData() -> String? {
        self.data.append(UUID().uuidString)
        print(Thread.current)
        return data.randomElement()
    }
     */
    
    func getRandomData(completionHandler: @escaping (_ title: String?) -> ()) {
        lock.async {
            self.data.append(UUID().uuidString)
            print(Thread.current)
            completionHandler(self.data.randomElement())
        }
    }
}

actor MyActorDataManager {
    static let instance = MyActorDataManager()
    private init() { }
    
    var data: [String] = []
    nonisolated let myRandomText: String = "MyRandomText"
    
    func getRandomData() -> String? {
        self.data.append(UUID().uuidString)
        print(Thread.current)
        return data.randomElement()
    }
    
    // actor 안에서 async가 굳이 필요 없다면 nonisolated 키워드를 붙이면 해당 메서드를 실행할 때 await를 붙일 필요가 없다.
    nonisolated func getSavedData() -> String {
        return "NEW DATA"
    }
}

struct HomeView: View {
    @State private var text: String = ""
    let manager = MyActorDataManager.instance
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color.gray.opacity(0.8).ignoresSafeArea()
            
            Text(text)
                .font(.headline)
        }
        .onAppear {
            let newString = manager.getSavedData()
            let message = manager.myRandomText
        }
        .onReceive(timer) { _ in
            Task {
                if let data = await manager.getRandomData() {
                    self.text = data
                }
            }
            
            /*
            DispatchQueue.global(qos: .background).async {
                manager.getRandomData { title in
                    if let data = title {
                        DispatchQueue.main.async {
                            self.text = data
                        }
                    }
                }
            }
             */
        }
    }
}

struct BrowseView: View {
    @State private var text: String = ""
    let manager = MyActorDataManager.instance
    let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color.yellow.opacity(0.8).ignoresSafeArea()
            
            Text(text)
                .font(.headline)
        }
        .onReceive(timer) { _ in
            Task {
                if let data = await manager.getRandomData() {
                    self.text = data
                }
            }
            
            /*
            DispatchQueue.global(qos: .background).async {
                manager.getRandomData { title in
                    if let data = title {
                        DispatchQueue.main.async {
                            self.text = data
                        }
                    }
                }
            }
             */
        }
    }
}

struct ActorsBootcamp: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            BrowseView()
                .tabItem {
                    Label("Browse", systemImage: "magnifyingglass")
                }
        }
    }
}

#Preview {
    ActorsBootcamp()
}
