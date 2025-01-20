# AsyncAwaitStudy
- [링크](https://www.youtube.com/playlist?list=PLwvDm4Vfkdphr2Dl4sY4rS9PLzPdyi8PM)를 참고해서 AsyncAwait에 대해 학습하고 회사코드에 적용해보기 위한 Study를 목적으로 작성됨

## 1. DoCatchTryThrows
- 1강에서는 기본적으로 Do Catch 구문, Try 및 Throws를 통해 Error Throw를 하는 기본적인 내용을 담고 있다.
- 기본적인 내용이기 때문에 설명은 남기지 않음

## 2. DownloadImageAsync
- 2강에서는 URLSession의 기본적은 메서드를 활용해 @escaping, Combine, async throws 각 방법별로 비동기처리를 하고 에러핸들링을 하는 내용을 담고 있다.
- 비동기 처리를 한 후 UI 관련 업데이트 시에는 꼭 MainThread에서 실행해야되기 때문에 await MainActor.run 혹인 @MainActor 키워드를 사용해 UI 업데이트를 진행해야함
    <details>
    <summary>코드 정리</summary>
    <div markdown="1">
    
    ```swift
    // 기본적인 Async 활용 방법
    
    // 구현
    class DownloadImageAsyncImageLoader {
        let url = URL(string: "https://picsum.photos/200")!
        
        func handleResponse(data: Data?, response: URLResponse?) -> UIImage? {
            guard
                let data = data,
                let image = UIImage(data: data),
                let response = response as? HTTPURLResponse,
                response.statusCode >= 200 && response.statusCode < 300
            else {
                return nil
            }
            return image
        }
    
        func downloadWithAsync() async throws -> UIImage? {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                return handleResponse(data: data, response: response)
            } catch {
                throw error
            }
        }
    }
    
    // 사용
    class DownloadImageAsyncViewModel: ObservableObject {
        @Published var image: UIImage? = nil
        let loader = DownloadImageAsyncImageLoader()
    
        func fetchImage() async {
            let image = try? await loader.downloadWithAsync()
            await MainActor.run {
                self.image = image
            }
        }
    }
    
    struct DownloadImageAsync: View {
        @StateObject private var viewModel = DownloadImageAsyncViewModel()
        
        var body: some View {
            ZStack {
                if let image = viewModel.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                }
            }
            .onAppear {
                Task {
                    await viewModel.fetchImage()
                }
            }
        }
    }
    ```
    
    </div>
    </details>

## 3. AsyncAwait
- 3강에서는 print를 통해 Async Await, Multi Thread 환경에서 코드의 동작이 어떠한 방식으로 이루어지는지에 대해 다루고 있다.
- 실질적으로 사용하는 코드 보다는 원리에 대한 이해가 필요한 강의이기 때문에 코드정리는 따로 진행하지 않음

## 4. Task
- 4강에서는 Task에 대한 설명을 다루고 있다.
- 기본적으로 Task 내부에서 실행하는 코드는 순차적으로 이루어지기 때문에 await 키워드를 사용하게 된다면 다음 줄의 코드는 await의 메서드가 실행이 완료된 후 실행이 된다.
- 만약 기본적인 Task만 사용해서 병렬로 여러 코드를 실행하고 싶다면 각각의 Task를 따로 만들어서 사용해야된다. -> 해당 부분에 대한 내용은 다음 강의에서 이어서 다룬다. 실질적으로는 Task를 나눠서 실행하는 비효율적인 방법을 사용하진 않는다.

## 5. AsyncLet
- 5강에서는 AsyncLet 키워드에 대해서 다루고 있다.
- async let 키워드를 사용한다면 위에서 병렬로 실행하기 위해 여러 Task를 만들어서 사용하는 비효율적인 부분을 없앨 수 있지만, 반복되는 여러가지의 작업을 병렬로 실행할 때에는 다음 강의에서 배울 TaskGroup이 더 적합하다.
    <details>
    <summary>코드 정리</summary>
    <div markdown="1">
        
    ```swift
    struct AsyncLetBootcamp: View {
        @State private var images: [UIImage] = []
        @State private var title = "Async Let 🥳"
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        let url = URL(string: "https://picsum.photos/300")!
        
        var body: some View {
            NavigationView {
                ScrollView {
                    LazyVGrid(columns: columns) {
                        ForEach(images, id: \.self) { image in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 150)
                        }
                    }
                }
                .navigationTitle(title)
                .onAppear {
                    Task {
                        do {
                            // async let 키워드를 통해 여러 메서드를 병렬로 실행하고 await 키워드로 종료되기를 기다렸다가 다음 작업을 진행할 수 있다.
                            async let fetchImage1 = fetchImage()
                            async let fetchTitle = fetchTitle()
                            let (image, title) = await (try fetchImage1, fetchTitle)
                            self.images.append(image)
                            self.title = title
                        } catch {
                            
                        }
                    }
                }
            }
        }
        
        func fetchTitle() async -> String {
            return "NEW TITLE 🤩"
        }
        
        func fetchImage() async throws -> UIImage {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    return image
                } else {
                    throw URLError(.badURL)
                }
            } catch {
                throw error
            }
        }
    }
    ```
    
    </div>
    </details>

## 6. TaskGroup
- 6강에서는 TaskGroup을 활용해 반복적인 async 작업들을 병렬적으로 처리할 수 있는 방법에 대해서 설명하고 있다.
- withThrowingTaskGroup이라는 메서드를 실행한 후 각 작업들을 TaskGroup에 추가해주는 방식으로 async throws 반복 작업을 병렬적으로 실행해줄 수 있다.
    <details>
    <summary>코드 정리</summary>
    <div markdown="1">

    ```swift
    class TaskGroupBootcampDataManager {
        func fetchImagesWithTaskGroup() async throws -> [UIImage] {
            let urlStrings = [
                "https://picsum.photos/300",
                "https://picsum.photos/300",
                "https://picsum.photos/300",
                "https://picsum.photos/300",
                "https://picsum.photos/300"
            ]
        
            return try await withThrowingTaskGroup(of: UIImage?.self) { group in
                var images: [UIImage] = []
                images.reserveCapacity(urlStrings.count)
                
                for urlString in urlStrings {
                    group.addTask {
                        try? await self.fetchImage(urlString: urlString)
                    }
                }
                
                for try await image in group {
                    if let image = image {
                        images.append(image)
                    }
                }
                
                return images
            }
        }

        private func fetchImage(urlString: String) async throws -> UIImage {
            guard let url = URL(string: urlString) else {
                throw URLError(.badURL)
            }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    return image
                } else {
                    throw URLError(.badURL)
                }
            } catch {
                throw error
            }
        }
    }

    class TaskGroupBootcampViewModel: ObservableObject {
        @Published var images: [UIImage] = []
        let manager = TaskGroupBootcampDataManager()
        
        func getImages() async {
            if let images = try? await manager.fetchImagesWithTaskGroup() {
                self.images.append(contentsOf: images)
            }
        }
    }

    struct TaskGroupBootcamp: View {
        @StateObject private var viewModel = TaskGroupBootcampViewModel()
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        
        var body: some View {
            NavigationView {
                ScrollView {
                    LazyVGrid(columns: columns) {
                        ForEach(viewModel.images, id: \.self) { image in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 150)
                        }
                    }
                }
                .navigationTitle("Task Group 🥳")
                .task {
                    await viewModel.getImages()
                }
            }
        }
    }
    ```

    </div>
    </details>

## 7. Continuations
- 7강에서는 withCheckedContinuation, withCheckedThrowingContinuation을 활용해 기존에 @escaping, Combine을 활용하던 메서드를 async 메서드로 변환하는 방법에 대해 다루고 있다.
- 해당 강의를 통해 애플에서 기본적으로 제공하고 있는 async 메서드 뿐만 아니라 서드파티 라이브러리의 비동기 메서드들을 async 메서드로 변환해서 사용할 수 있기 때문에 코드의 통일성을 올릴 수 있다.
    <details>
    <summary>코드 정리</summary>
    <div markdown="1">

    ```swift
    // 구현
    class CheckedContinuationBootcampNetworkManager {
        // URLSession의 메서드 중 async 메서드 활용 방법
        func getData(url: URL) async throws -> Data {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                return data
            } catch {
                throw error
            }
        }

        // URLSession의 메서드 중 completionHandler를 활용한 메서드를 내부적으로 async throws 메서드로 변환하는 예시
        // 영상에서 예시로 사용했을 뿐, 위와 같이 기본적으로 제공하는 async 메서드를 사용하는 것이 정석
        func getData2(url: URL) async throws -> Data {
            return try await withCheckedThrowingContinuation { continuation in
                URLSession.shared.dataTask(with: url) { data, response, error in
                    if let data = data {
                        continuation.resume(returning: data)
                    } else if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(throwing: URLError(.badURL))
                    }
                }
                .resume()
            }
        }

        // 서드파티 라이브러리 메서드 중 completionHanlder를 제공하는 메서드와 동일한 형태의 메서드 예제
        func getHeartImageFromDatabase(completionHandler: @escaping (_ image: UIImage) -> ()) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                completionHandler(UIImage(systemName: "heart.fill")!)
            }
        }

        // 위의 메서드를 async 메서드로 변환하는 방법
        func getHeartImageFromDatabase() async -> UIImage {
            await withCheckedContinuation { continuation in
                self.getHeartImageFromDatabase { image in
                    continuation.resume(returning: image)
                }
            }
        }
    }

    // 사용
    class CheckedContinuationBootcampViewModel: ObservableObject {
        @Published var image: UIImage? = nil
        let networkManager = CheckedContinuationBootcampNetworkManager()
        
        func getImage() async {
            guard let url = URL(string: "https://picsum.photos/300") else { return }
            do {
                let data = try await networkManager.getData2(url: url)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        self.image = image
                    }
                }
            } catch {
                print(error)
            }
        }
        
        func getHeartImage() async {
            self.image = await networkManager.getHeartImageFromDatabase()
        }
    }

    struct CheckedContinuationBootcamp: View {
        @StateObject private var viewModel = CheckedContinuationBootcampViewModel()
        
        var body: some View {
            ZStack {
                if let image = viewModel.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                }
            }
            .task {
                await viewModel.getHeartImage()
            }
        }
    }
    ```
    
    </div>
    </details>

## 8. Struct / Class / Actor
- 8장에서는 다음 강의전 Struct, Class, Actor의 차이점에 대해서 다루고 있다.
- 기본적인 내용을 다루고 있지만 Struct, Class, Actor의 차이점과 차이가 발생하게 되는 이유에 대해 꽤나 자세히 설명해주기 때문에 좋은 강의라고 생각한다.

    <details>
    <summary>내용 정리</summary>
    <div markdown="1">
    
    ### Links:
    - https://blog.onewayfirst.com/ios/posts/2019-03-19-class-vs-struct/
    - https://stackoverflow.com/questions/24217586/structure-vs-class-in-swift-language
    - https://medium.com/@vinayakkini/swift-basics-struct-vs-class-31b44ade28ae
    - https://stackoverflow.com/questions/24217586/structure-vs-class-in-swift-language/59219141#59219141
    - https://stackoverflow.com/questions/27441456/swift-stack-and-heap-understanding
    - https://stackoverflow.com/questions/24232799/why-choose-struct-over-class/24232845
    - https://www.backblaze.com/blog/whats-the-diff-programs-processes-and-threads/
    
    ### VALUE TYPES:
     - Struct, Enum, String, Int, etc.
     - Stored in the Stack
     - Faster
     - Thread safe!
     - When you assign or pass value type a new copy of data is created
     
    ### REFERENCE TYPES:
     - Class, Function, Actor
     - Stored in the Heap
     - Slower, but synchronized
     - Not Thread safe (default)
     - When you assign or pass reference type a new reference to original instance will be created (pointer)
     
    - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     
    ### STACK:
     - Stored Value types
     - Variables allocated on the stack are stored directly to the memory, and access to this memory is very fast
     - Each thread has it's own stack!
     
    ### HEAP:
     - Stores Reference types
     - Shared across threads!
     
    - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     
    ### STRUCT:
     - Based on VALUES
     - Can me mutated
     - Stored in the Stack!
     
    ### CLASS:
     - Based on REFERENCES (INSTANCES)
     - Stored in the Heap!
     - Inherit from other classes
     
     ### ACTOR:
     - Same as Class, but thread safe!
     
     - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     
     - Structs: Data Models, Views
     - Classes: ViewModels
     - Actors: Shared 'Manager' and 'Data Store'
 
    ## 요약
    - Multi Thread 환경에서 각 Thread 마다 별도의 Stack을 가지고 있다.
    - 그래서 Stack과 Thread와의 Data 전달이 빠른 편이다.
    - Heap은 여러 Thread와 Sync를 맞추고 있기 때문에 Stack에 비해 Data 전달이 느린편이다.
    - Struct는 기본적으로 값 복사이고 Stack에 생성된다. 그래서 Multi Thread 환경에서 기본적으로 Data 전달이 빠르다.
    - Class는 기본적으로 참조 복사이고 Heap에 생성된다. 그래서 Multi Thread 환경에서 기본적으로 Data 전달이 Struct에 비해 느리다.
    - 또한 여러 Thread에서 Sync를 맞추고 있기 때문에 여러 Thread에서 동시에 Heap에 접근해서 Data를 바꾸려고 하게 되면 락이 걸릴수도 있다. -> Thread safe하지 않다.
    - 이 때 Thread safe하도록 만든것이 바로 Actor이다.
    - Actor는 class와 동일하지만 하나의 Thread에서 변경을 시도한다면 해당 작업이 끝나기 전에 다른 Thread에서는 접근을 하지 못하도록 막는다. 그렇기 때문에 Thread safe하게 된다.
    
    </div>
    </details>

## 9. Actor
- 9장에서는 Actor를 활용해 Thread safe하게 사용하는 방법에 대해 다루고 있다.
- Actor는 class와 거의 동일하지만 Thread가 공통된 Data를 수정하려고 할 때 하나의 Thread에서 Actor에 접근하게 되면 await를 통해 해당 작업이 끝날 때까지 기다리도록 해서 Thread로부터 안전하도록 만든다.
- Actor를 사용하지 않고 class를 Thread safe하게 하려면 class 내부에 하나의 Queue를 만들고 해당 큐에서만 작업이 이루어지도록 하면 가능하다.
    <details>
    <summary>코드 정리</summary>
    <div markdown="1">
        
    ```swift
    // Queue를 생성해서 class를 Thread safe하게 만드는 방법
    class MyDataManager {
        static let instance = MyDataManager()
        private init() { }
        
        var data: [String] = []
        private let lock = DispatchQueue(label: "com.MyApp.MyDataManager")
        func getRandomData(completionHandler: @escaping (_ title: String?) -> ()) {
            lock.async {
                self.data.append(UUID().uuidString)
                print(Thread.current)
                completionHandler(self.data.randomElement())
            }
        }
    }

    // Actor 사용 방법
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
            }
        }
    }
    ```
    
    </div>
    </details>

## 10. GlobalActor
- 10강은 GlobalActor Protocol에 대해서 다루고 있다.
- GlobalActor는 Protocol인데 @globalActor 키워드로 사용할 수 있으며, 필수적으로 static var shared를 선언해야하기 때문에 싱글톤 패턴과 동일하다고 보면 된다.
- 여러 class에서 Thread safe하도록 하나의 GlobalActor로 제한해서 실행하는 것인데 실질적으로 GlobalActor를 만들어서 사용하는 경우는 거의 없을 것 같고, 그나마 사용한다면 @MainActor를 많이 사용하지 않을까 싶다.
- @MainActor 또한 MainThread에서 safe하게 동작하도록 하는 하나의 GlobalActor라고 보면 된다.
    <details>
    <summary>코드 정리</summary>
    <div markdown="1">

    ```swift
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
        @MainActor @Published var dataArray: [String] = []
        let manager = MyFirstGlobalActor.shared
        
        @MyFirstGlobalActor
        func getData() {
            Task {
                let data = await manager.getDataFromDatabase()
                // UI를 업데이트하는 내용인데 MainActor.run 키워드를 사용하지 않더라도 현재 컴파일 에러가 발생하지 않는다.
                // @Published var dataArray 앞에 @MainActor를 사용하게 되면 아래 코드에서 컴파일 에러가 발생하게 된다.
                // 혹은 class 자체에 @MainActor를 사용하게 되면 아래 코드에서 컴파일 에러가 발생하게 된다.
                await MainActor.run {
                    self.dataArray = data
                }
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
    ```
    
    </div>
    </details>

## 11. Sendable
- 11강은 Sendable Protocol에 대해서 다루고 있다.
- Sendable은 비동기환경에서 데이터경쟁을 만들지 않고 데이터를 전달할 수 있도록 하는 protocol이다.
    <details>
    <summary>코드 정리</summary>
    <div markdown="1">

    ```swift
    actor CurrentUserManager {
        func updateDatabase(userInfo: MyUserInfo) {
            
        }
    }
    
    // 기본적으로 Struct는 쓰레드로부터 안전하기 때문에 굳이 Sendable을 표기할 필요는 없다.
    struct MyUserInfo: Sendable {
        var name: String
    }
    
    // @unchecked라는 것은 컴파일러에게 직접 체크할테니 체크하지 말라고 하는것이지, Sendable을 만족하는 것은 아니다. 그러므로 근본적인 해결이 될 수 없다.
    // @unchecked를 사용할 경우 수동적으로 쓰레드로부터 안전하게 만들어줘야 한다.
    // 해결법 중 하나는 내부에서 메서드를 통해 값을 바꿀 수 있도록 하고, 값을 바꾸는 과정을 하나의 내부 큐에서 처리하도록 하는 것이다.
    // 다만 이 또한 가장 좋은 방법은 아니고, 가장 최선의 방법은 Sendable을 만족하도록 하는것이다.
    final class MyClassUserInfo: @unchecked Sendable {
        // 만약 let이라면 해당 클래스에는 바꿀 수 있는 프로퍼티가 없으므로 쓰레드로 부터 안전하기 때문에 Sendable을 채택하더라도 에러가 발생하지 않는다.
        // 만약 var라면 해당 클래스에서 바꿀 수 있는 프로퍼티가 있다는 뜻이고, 여러 쓰레드에서 접근해서 바꾸게 될 수 있기 때문에 쓰레드로 부터 안전하지 않다고 판단하기 때문에 Sendable을 채택하면 에러가 발생한다.
        // 다만 class의 장점 중 하나는 여러쓰레드에서 접근해서 프로퍼티를 바꿀 수 있다는 것인데 모든 프로퍼티를 let으로 만들어서 Sendable을 만족한다는 것은 class를 굳이 사용할 필요가 없기 때문에 다른 방법으로 에러를 해결하는 것이 좋다.
        private var name: String
        let queue = DispatchQueue(label: "com.MyApp.MyClassUserInfo")
        
        init(name: String) {
            self.name = name
        }
        
        func updateName(name: String) {
            queue.async {
                self.name = name
            }
        }
    }
    
    class SendableBootcampViewModel: ObservableObject {
        let manager = CurrentUserManager()
        
        func updateCurrentUserInfo() async {
            let info = MyUserInfo(name: "info")
            await manager.updateDatabase(userInfo: info)
        }
    }
    
    struct SendableBootcamp: View {
        @StateObject private var viewModel = SendableBootcampViewModel()
        var body: some View {
            Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
                .task {
                    await viewModel.updateCurrentUserInfo()
                }
        }
    }
    ```
    
    </div>
    </details>

## 12. AsyncPublisher
- 12강에서는 AsyncPublisher에 대해 다루고 있는데, 기존 Combine 처럼 Async를 체이닝 할 수 있는 방법에 대해 다루고 있다.
- 기본적으로 Published의 values를 통해 AsyncPublisher를 생성할 수 있고 For await를 사용해 각각의 비동기 Task를 순차적으로 실행할 수 있게 된다.
    <details>
    <summary>코드 정리</summary>
    <div markdown="1">
        
    ```swift
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
    ```
      
    </div>
    </details>
