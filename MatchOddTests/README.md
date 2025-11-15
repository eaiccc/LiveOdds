# MatchOdd Unit Tests

## 測試結構

```
MatchOddTests/
├── Mocks/
│   ├── MockMatchRepository.swift        # Repository 的 Mock 實作
│   └── MockOddsStreamManager.swift      # OddsStreamManager 的 Mock 實作
├── ViewModels/
│   └── MatchListViewModelTests.swift    # ViewModel 測試用例
└── README.md                             # 本文件
```

## Mock 對象說明

### MockMatchRepository

模擬 `MatchRepositoryProtocol` 的實作，用於測試 ViewModel 的數據加載邏輯。

**功能**：
- 可配置返回的 matches 和 odds 數據
- 可配置拋出的錯誤
- 可模擬網路延遲
- 追蹤方法調用次數

**使用範例**：
```swift
let mockRepo = MockMatchRepository()
mockRepo.matchesToReturn = MockMatchRepository.createSampleMatches()
mockRepo.oddsToReturn = MockMatchRepository.createSampleOdds()
mockRepo.delay = 0.1  // 模擬 100ms 延遲
```

### MockOddsStreamManager

模擬 `OddsStreamManagerProtocol` 的實作，用於測試實時賠率更新。

**功能**：
- 手動控制賠率更新的發送
- 追蹤 streaming 狀態
- 追蹤方法調用次數

**使用範例**：
```swift
let mockStream = MockOddsStreamManager()
let update = MockOddsStreamManager.createSampleUpdate(
    matchID: 1,
    teamAOdds: 1.8
)
mockStream.emitUpdate(update)
```

## MatchListViewModel 測試用例

### 數據加載測試
- ✅ `testLoadInitialDataSuccess` - 成功加載初始數據
- ✅ `testLoadInitialDataFetchMatchesError` - 處理 matches 加載錯誤
- ✅ `testLoadInitialDataFetchOddsError` - 處理 odds 加載錯誤
- ✅ `testLoadingStateChanges` - 驗證 loading 狀態變化

### 賠率更新測試
- ✅ `testHandleOddsUpdate` - 處理實時賠率更新
- ✅ `testOddsChangeFlags` - 驗證賠率變化標記
- ✅ `testOddsChangeFlagsReset` - 驗證變化標記自動重置
- ✅ `testMultipleOddsUpdates` - 處理多個賠率更新

### 排序測試
- ✅ `testLiveMatchesSortedFirst` - LIVE 比賽優先排序

### 錯誤處理測試
- ✅ `testErrorClearedOnSuccess` - 錯誤狀態在成功後清除

### 邊界情況測試
- ✅ `testEmptyDataHandling` - 處理空數據

## 運行測試

### 使用 Xcode
1. 選擇 `MatchOdd` scheme
2. 按下 `Cmd + U` 運行所有測試
3. 或者打開 Test Navigator (`Cmd + 6`) 運行特定測試

### 使用命令行
```bash
# 運行所有測試
xcodebuild test -project MatchOdd.xcodeproj -scheme MatchOdd -destination 'platform=iOS Simulator,name=iPhone 17'

# 只運行 ViewModel 測試
xcodebuild test -project MatchOdd.xcodeproj -scheme MatchOdd -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:MatchOddTests/MatchListViewModelTests
```

## 測試覆蓋率

測試覆蓋了 MatchListViewModel 的核心功能：
- ✅ 數據加載流程
- ✅ 錯誤處理
- ✅ Loading 狀態管理
- ✅ 實時賠率更新
- ✅ 賠率變化動畫標記
- ✅ 數據排序邏輯
- ✅ 邊界情況處理

## Swift 6 兼容性

所有測試代碼完全符合 Swift 6 要求：
- Mock 對象使用 `@unchecked Sendable` 標記（測試環境下安全）
- 測試方法使用 `@MainActor` 確保在主執行緒運行
- 使用 `async/await` 處理非同步操作
- 符合嚴格並發檢查

## 新增測試

新增測試時請遵循以下原則：
1. 使用描述性的測試名稱（英文）
2. 遵循 Given-When-Then 模式
3. 一個測試只驗證一個行為
4. 使用 `#expect()` 進行斷言
5. 適當使用 `async/await` 處理非同步操作
6. 確保測試之間相互獨立

## 範例測試結構

```swift
@Test("描述測試目的")
func testSomething() async throws {
    // Given - 準備測試數據和狀態
    mockRepository.matchesToReturn = [...]

    // When - 執行被測試的操作
    await sut.loadInitialData()

    // Then - 驗證結果
    #expect(sut.matches.count == 2)
    #expect(sut.error == nil)
}
```
