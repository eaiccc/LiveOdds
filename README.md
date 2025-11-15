# LiveOdds 架構文件

## 概述

LiveOdds 專案採用**Swift Concurrency** 和 **Combine Framework** 的優勢，實現即時體育賠率顯示系統。

## 展示影片

### LiveOdds 功能展示
![LiveOdds Demo](doc/MatchOdds.gif)

### Memory Leak 測試
![Memory Leak Test](doc/memoryleak.gif)

---

## 🔄 Swift Concurrency 使用場景

### 1. 資料載入與處理

```swift
// MatchListViewModel.swift:88-102
func loadInitialData() async {
    isLoading = true
    error = nil
    
    do {
        // 並行載入比賽和賠率資料
        async let matchesResult = repository.fetchMatches()
        async let oddsResult = repository.fetchOdds()
        
        let (fetchedMatches, fetchedOdds) = try await (matchesResult, oddsResult)
        
        // Actor 安全的資料存儲
        for odds in fetchedOdds {
            await oddsStore.update(odds)
        }
        
        matches = await mergeMatchesWithOdds()
        
    } catch {
        self.error = error
    }
    
    isLoading = false
}
```

**應用要點**:
- **並行執行**: `async let` 同時執行多個網路請求
- **線性程式碼**: 避免 callback 嵌套
- **自動錯誤處理**: 統一的 try-catch 機制

### 2. Actor 隔離保護

```swift
// OddsStore.swift:16-42
actor OddsStore {
    private var oddsMap: [Int: Odds] = [:]
    
    func update(_ odds: Odds) {
        oddsMap[odds.matchID] = odds
    }
    
    func get(_ matchID: Int) -> Odds? {
        return oddsMap[matchID]
    }
    
    func getAll() -> [Odds] {
        return Array(oddsMap.values)
    }
}
```

**使用場景**:
- **共享狀態保護**: 賠率資料的執行緒安全存取
- **自動隔離**: 編譯器強制執行安全性
- **簡潔 API**: 無需手動鎖定機制

### 3. Repository 層的快取管理

```swift
// MatchRepository.swift:65-97
func fetchMatches() async throws -> [Match] {
    let shouldFetchFromNetwork = await withCheckedContinuation { continuation in
        cacheQueue.async {
            // 檢查快取有效性
            if let timestamp = self.cacheTimestamp {
                let isValid = Date().timeIntervalSince(timestamp) < Constants.Cache.expirationInterval
                continuation.resume(returning: !isValid)
            } else {
                continuation.resume(returning: true)
            }
        }
    }
    
    // 使用 barrier 確保寫入安全
    await withCheckedContinuation { continuation in
        cacheQueue.async(flags: .barrier) {
            self.cachedMatches = matches
            self.cacheTimestamp = Date()
            continuation.resume()
        }
    }
}
```

**使用場景**:
- **快取策略**: 智能快取與網路請求協調
- **DispatchQueue 整合**: 與 async/await 無縫銜接
- **資料一致性**: barrier 確保寫入排他性

---

## 🔀 Combine Framework 使用場景

### 1. UI 狀態管理

```swift
// MatchListViewModel.swift:25-37
@Published var matches: [MatchViewData] = []
@Published var isLoading: Bool = false
@Published var error: Error?
@Published var connectionState: ConnectionState = .disconnected
```

**應用要點**:
- **自動 UI 更新**: @Published 屬性變更自動觸發重繪
- **聲明式綁定**: ViewController 透過 sink 訂閱狀態變更
- **記憶體安全**: AnyCancellable 自動管理訂閱

### 2. 即時資料流處理

```swift
// MockOddsStreamManager.swift:30-60
private let updateSubject = PassthroughSubject<OddsUpdate, Never>()
private let connectionStateSubject = CurrentValueSubject<ConnectionState, Never>(.disconnected)

var oddsUpdatePublisher: AnyPublisher<OddsUpdate, Never> {
    updateSubject.eraseToAnyPublisher()
}

var connectionStatePublisher: AnyPublisher<ConnectionState, Never> {
    connectionStateSubject.eraseToAnyPublisher()
}
```

**使用場景**:
- **事件流發布**: PassthroughSubject 發布即時賠率更新
- **狀態廣播**: CurrentValueSubject 維護連線狀態
- **類型擦除**: AnyPublisher 提供統一介面

### 3. UI 層資料綁定

```swift
// MatchListViewController.swift:178-215
private func setupBindings() {
    // 比賽資料變更綁定
    viewModel.$matches.receive(on: DispatchQueue.main)
        .sink { [weak self] matches in
            self?.updateDataSource(with: matches)
        }
        .store(in: &cancellables)
    
    // 載入狀態綁定
    viewModel.$isLoading.receive(on: DispatchQueue.main)
        .sink { [weak self] isLoading in
            if isLoading {
                self?.showLoading()
            } else {
                self?.hideLoading()
            }
        }
        .store(in: &cancellables)
    
    // 錯誤狀態綁定
    viewModel.$error.receive(on: DispatchQueue.main)
        .sink { [weak self] error in
            if let error = error {
                self?.showError(error.localizedDescription) { [weak self] in
                    self?.loadData()
                }
            } else {
                self?.hideError()
            }
        }
        .store(in: &cancellables)
}
```

**綁定模式**:
- **主執行緒保證**: `receive(on: DispatchQueue.main)` 確保 UI 安全
- **弱引用防護**: `[weak self]` 避免記憶體循環引用
- **集中管理**: `cancellables` 統一管理訂閱生命週期

---

## 🛡 Thread-Safe 資料存取機制

### 1. @MainActor 隔離

```swift
// MatchListViewModel.swift:19
@MainActor
final class MatchListViewModel: ObservableObject {
    // 所有屬性和方法自動在主執行緒執行
    @Published var matches: [MatchViewData] = []
    
    // 可安全呼叫其他 Actor
    private func handleOddsUpdate(_ oddsUpdate: OddsUpdate) async {
        await oddsStore.update(odds)  // 跨 Actor 安全呼叫
        await updateMatchesWithOddsAnimation(oddsUpdate)
    }
}
```

**安全保證**:
- **編譯器強制**: 所有 UI 操作自動在主執行緒
- **跨 Actor 協作**: 可安全呼叫其他 Actor 方法
- **狀態一致性**: @Published 變更原子性更新

### 2. Actor 系統隔離

```swift
// 資料存取流程
ViewModel (@MainActor) 
    ↓ await call
OddsStore (Actor) 
    ↓ thread-safe access
Private Storage (oddsMap)
```

### 3. Sendable 協議保證

```swift
// Models/Odds.swift:14
struct Odds: Codable, Hashable, Sendable {
    let matchID: Int
    let teamAOdds: Double
    let teamBOdds: Double
    let drawOdds: Double?
}

// Models/OddsUpdate.swift:14
struct OddsUpdate: Codable, Sendable {
    let matchID: Int
    let teamAOdds: Double
    let teamBOdds: Double
    let drawOdds: Double?
    let timestamp: Date
}
```

**跨執行緒安全**:
- **值類型優先**: struct 避免reference
- **不變性設計**: let 屬性確保資料穩定
- **編譯器驗證**: Sendable 自動檢查跨執行緒安全

### 4. DispatchQueue 併發控制

```swift
// MatchRepository.swift:25
private let cacheQueue = DispatchQueue(label: "com.matchodd.repository.cache", attributes: .concurrent)

// 讀取操作 - 併發執行
cacheQueue.async {
    continuation.resume(returning: self.cachedMatches)
}

// 寫入操作 - 排他執行
cacheQueue.async(flags: .barrier) {
    self.cachedMatches = matches
    self.cacheTimestamp = Date()
    continuation.resume()
}
```

**併發模式**:
- **Reader-Writer 模式**: 併發讀取，排他寫入
- **async/await 整合**: withCheckedContinuation 橋接
- **效能優化**: 避免不必要的執行緒阻塞

---

## 📱 UI 與 ViewModel 資料綁定方式

### 1. @Published + Sink 模式

```swift
// ViewModel 發布狀態
@MainActor final class MatchListViewModel: ObservableObject {
    @Published var matches: [MatchViewData] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var connectionState: ConnectionState = .disconnected
}

// ViewController 訂閱狀態
viewModel.$matches
    .receive(on: DispatchQueue.main)
    .sink { [weak self] matches in
        self?.updateDataSource(with: matches)
    }
    .store(in: &cancellables)
```

### 2. DiffableDataSource 更新

```swift
// MatchListViewController.swift:251-260
private func applySnapshot(_ matches: [MatchViewData]) {
    var snapshot = NSDiffableDataSourceSnapshot<Section, MatchViewData>()
    snapshot.appendSections([Section.main])
    snapshot.appendItems(matches, toSection: Section.main)

    // 效能優化：無動畫更新確保 60 FPS
    dataSource.apply(snapshot, animatingDifferences: false, completion: nil)
}
```

### 3. 狀態管理與持久化

```swift
// ViewStateManager.swift:49-50
@MainActor
final class ViewStateManager: ObservableObject {
    @Published private(set) var currentState: ViewState?
    @Published var isStateRestorationEnabled: Bool = true
    
    // UITableView 狀態保存
    func saveTableViewState(_ tableView: UITableView) {
        let scrollPosition = tableView.contentOffset
        let visibleIndexes = tableView.indexPathsForVisibleRows?.map { $0.row } ?? []
        saveViewState(scrollPosition: scrollPosition, visibleIndexes: visibleIndexes)
    }
}
```

### 4. 錯誤處理與使用者回饋

```swift
// 統一錯誤處理綁定
viewModel.$error
    .receive(on: DispatchQueue.main)
    .sink { [weak self] error in
        if let error = error {
            self?.showError(error.localizedDescription) { [weak self] in
                self?.loadData()  // 重試邏輯
            }
        } else {
            self?.hideError()
        }
    }
    .store(in: &cancellables)
```

**綁定特性**:
- **自動更新**: @Published 變更立即反映到 UI
- **執行緒安全**: receive(on: DispatchQueue.main) 確保 UI 執行緒
- **記憶體安全**: weak self 避免循環引用
- **生命週期管理**: cancellables 自動清理

---

## 🎯 架構整合模式

### 資料流向圖

```
WebSocket/Network
        ↓
MockOddsStreamManager (Combine Publishers)
        ↓
MatchListViewModel (@MainActor + @Published)
        ↓
MatchListViewController (Combine Subscribers)
        ↓
UITableView (DiffableDataSource)
```

### 併發協作模式

```
UI Layer (@MainActor)
    ↕ async/await calls
Actor Layer (OddsStore)
    ↕ Sendable data
Repository Layer (DispatchQueue + Cache)
    ↕ Network requests
Network Layer (async/await)
```

---

## 🚀 效能與安全總結

### ✅ Swift Concurrency 優勢
- **結構化併發**: 自動任務取消和錯誤傳播
- **Actor 隔離**: 編譯器保證的執行緒安全
- **並行處理**: async let 提升資料載入效能

### ✅ Combine Framework 優勢
- **響應式 UI**: @Published 自動觸發更新
- **事件流處理**: Subject 模式處理即時資料
- **記憶體管理**: AnyCancellable 自動清理

### ✅ Thread-Safe 保證
- **@MainActor**: UI 操作強制主執行緒執行
- **Actor 系統**: 共享狀態自動保護
- **Sendable 協議**: 跨執行緒資料安全驗證

### ✅ UI-ViewModel 綁定
- **宣告式更新**: @Published + sink 自動同步
- **效能優化**: DiffableDataSource 高效更新
- **狀態持久化**: ViewStateManager 保存使用者體驗

