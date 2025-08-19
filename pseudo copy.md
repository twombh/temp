# 대중교통 버스 정보 시스템 전체 아키텍처 분석

## 1. 전체 시스템 구조

이 시스템은 **4개의 기능 모듈**로 구성

### **메인 허브 (PT Main)**
- **PTMainActivity** → **PTMainFragment** → **PTMainViewModel**
- 사용자의 첫 진입점이자 모든 기능으로의 내비게이션 허브

### **버스 검색 시스템 (Bus Search)**
- **BusInfoSearchFragment** → **BusInfoSearchViewModel**
- 버스 노선과 정류장을 검색하는 통합 검색 시스템

### **버스 정류장 정보 (Bus Station Info)**
- **BusStationInfoFragment** → **BusStationInfoViewModel**
- 특정 정류장의 실시간 버스 도착 정보와 지도 표시

### **버스 노선 정보 (Bus Route)**
- **BusRouteFragment** → **BusRouteViewModel**
- 특정 버스의 전체 노선과 실시간 위치 정보

## 2. 플로우와 고객 여정 지도

### **시작: 메인 화면**
```
대중교통 실행
↓
PTMainActivity → Intent 분석 → bundle 값에 맞는 화면 결정 (startDestination = PTMainFragment)
↓
PTMainFragment 표시
↓
PTMainViewModel이 데이터 로드
  - 마일리지/쿠폰 정보 (API)
  - 검색 히스토리 (로컬 DB)
```

### **검색 플로우**
```
사용자가 버스 검색 또는 정류장 검색 클릭
↓
BusInfoSearchFragment 진입 (search_type에 따라 분기)
↓
BusInfoSearchViewModel 초기화
  - 지역 목록 로드 (API)
  - 검색 히스토리 표시 (로컬 DB)
↓
사용자 검색어 입력
↓
실시간 검색 결과 표시 (API 호출)
↓
결과 클릭 시
  - 버스 → BusRouteFragment로 이동
  - 정류장 → BusStationInfoFragment로 이동
```

### **정류장 정보 플로우**
```
정류장 선택
↓
BusStationInfoFragment 진입
↓
BusStationInfoViewModel이 처리
  1. 지도 초기화 (네이버 맵)
  2. 주변 정류장 조회 (API)
  3. 선택된 정류장의 버스 정보 조회 (API)
  4. 실시간 도착 정보 갱신 (타이머, 1초)
↓
지도에 정류장 마커 표시
↓
하단 시트에 버스 목록과 도착 시간 표시
↓
버스 클릭 시 → BusRouteFragment로 이동
```

### **버스 노선 정보 플로우**
```
버스 노선 선택
↓
BusRouteFragment 진입
↓
BusRouteViewModel이 처리
  1. 버스 노선 데이터 조회 (API)
  2. 실시간 버스 위치 정보 조회 (API)
  3. 버스 위치를 노선에 매핑
↓
노선도와 정류장 목록 표시
↓
실시간 버스 위치 표시 (아이콘으로 시각화)
↓
정류장 클릭 시 → BusStationInfoFragment로 이동
```
## 3. 버스 관련 공통 컴포넌트 분석

### **BusInfoBaseViewModel**
모든 버스 관련 뷰모델의 부모 클래스
- **버스 타입별 색상 결정**: 지역별, 노선별 버스 색상 체계
- **도착 시간 포맷팅**: 초 단위를 몇 분, 몇 초 형태로 변환
- **로그인 상태 확인**: 즐겨찾기 등 회원 기능 사용 가능 여부

```java
public String busTypeColor(String sggDvsCd, String rotTypCd) {
    boolean isSeoul = "1100".equals(sggDvsCd) || "11".equals(sggDvsCd);
    // 서울과 서울이 아닌 것에 따른 버스 타입별 색상 반환
    // 간선버스(파란색), 지선버스(초록색), 광역버스(빨간색)
}
```
----
<br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/>
<br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/>
<br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/>
<br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/>


# 버스 정보 시스템 전체 실행 플로우 분석


실제 앱이 실행되는 전체 플로우를 상세히 분석

## 1. 앱 시작부터 메인 화면까지

### **앱 실행 시퀀스**
```kotlin
// 1. 시스템이 PTMainActivity 생성
PTMainActivity.onCreate() {
    // 2. Navigation 컴포넌트 초기화
    setContentView(R.layout.activity_pt_main)
    
    // 3. NavHostFragment 및 NavController 설정
    navHostFragment = supportFragmentManager.findFragmentById(R.id.nav_host_fragment)
    navController = navHostFragment.navController.apply {
        navigatorProvider.addNavigator(navigator)
        setGraph(R.navigation.pt_main_navigation) // pt_main_fragment가 시작점
    }
    
    // 4. Intent 분석 - 외부 진입 처리
    intent?.let {
        when {
            bundle != null -> navController.navigate(R.id.action_bus_route_fragment, bundle)
            line == true -> navController.navigate(검색_버스노선)
            station == true -> navController.navigate(검색_정류장)
            else -> // 기본적으로 pt_main_fragment가 표시됨
        }
    }
}
```

### **PTMainFragment 초기화 과정**
```kotlin
// 1. Fragment 생성
PTMainFragment.onCreate() {
    // ViewModel 인스턴스 생성
    viewModel = ViewModelProvider(this)[PTMainViewModel::class.java]
    busFavoriteViewModel = ViewModelProvider(this)[BusFavoriteViewModel::class.java]
}

// 2. View 생성
PTMainFragment.onCreateView() {
    // Data Binding 설정
    binding = FragmentPtMainBinding.inflate(inflater)
    binding.lifecycleOwner = this
    binding.viewModel = viewModel
    binding.busFavoriteViewModel = busFavoriteViewModel
}

// 3. View 초기화 완료
PTMainFragment.onViewCreated() {
    observe() // LiveData 관찰 시작
    init()    // 어댑터 및 UI 컴포넌트 초기화
}
```
## 2. 메인 화면 데이터 로딩 플로우

### **onResume에서의 분기 처리**
```kotlin
PTMainFragment.onResume() {
    if (isLoggedIn) {
        // === 로그인 상태 플로우 ===
        
        // 1. 마일리지/쿠폰 정보 조회
        viewModel.reqMileageAndCoupon() {
            dataLoading.value = true
            TIARetrofitCallableMlgAmtCpnCnt.create() 실행
            ↓
            성공 시: _eventRewordCouponValue.value = 쿠폰개수
            실패 시: error 처리
            ↓  
            dataLoading.value = false
        }
        
        // 2. 검색 히스토리 조회
        viewModel.reqHistory() {
            Tasks.callInIO {
                val list = mutableListOf<Any?>()
                list.addAll(버스검색기록)      // AppDatabase.busSearchHistoryDao()
                list.addAll(정류장검색기록)    // AppDatabase.busStationSearchHistoryDao()  
                list.addAll(지하철검색기록)    // AppDatabase.subwaySearchInfoDao()
                
                // 시간순 정렬 후 최대 10개만
                list.sortByDescending { 각_아이템의_저장시간 }
                return 상위_10개_아이템
            }
            ↓
            _historyList.value = 결과
            _historyEmptyViewVisible.value = 결과.isEmpty()
        }
        
        // 3. 마케팅 동의 팝업 및 즐겨찾기 데이터
        TGoMarketingPushAgreeBottomSheet.show(activity)
        busFavoriteViewModel.start() // 즐겨찾기 버스/정류장 로드
        
    } else {
        // === 비로그인 상태 플로우 ===
        viewModel.setBottomPopUpVisivle(true) // 로그인 유도 팝업
    }
}
```


### **UI 업데이트 체인**
```kotlin
// ViewModel의 LiveData 변경 → Fragment의 observe()에서 감지 → UI 업데이트

// 1. 마일리지 정보 업데이트
viewModel.eventRewordCouponValue.observe() { value ->
    // Data Binding을 통해 자동으로 텍스트 업데이트
    binding.couponCountText = value
}

// 2. 히스토리 목록 업데이트  
viewModel.historyList.observe() { historyData ->
    historyAdapter.setItems(historyData) // RecyclerView 갱신
}

// 3. 즐겨찾기 데이터 업데이트
busFavoriteViewModel.favoriteItems.observe() { favoriteData ->
    favoriteAdapter.setItems(favoriteData) // 즐겨찾기 RecyclerView 갱신
}
```

## 3. 사용자 액션별 상세 플로우

### **버스 검색 플로우**
```kotlin
// 1. 사용자가 "버스 검색" 버튼 클릭
PTMainFragment.gotoBusSearch() {
    val bundle = Bundle()
    bundle.putInt(BusInfoSearchFragment.SEARCH_TYPE, BusInfoSearchFragment.BUS)
    Navigation.findNavController(binding.root)
        .navigate(R.id.action_bus_info_main_fragment_to_bus_info_search_fragment, bundle)
}

// 2. Navigation으로 BusInfoSearchFragment 생성
BusInfoSearchFragment.onCreate() {
    viewModel = BusInfoSearchViewModel()
    searchAdapter = BusInfoSearchAdapter() 
    historyAdapter = BusInfoHistoryAdapter()
    
    // Bundle에서 검색 타입 확인
    searchType = getArguments().getInt(SEARCH_TYPE) // BUS = 0
}

// 3. 검색 화면 초기화
BusInfoSearchFragment.onViewCreated() {
    // 탭 설정 (버스/정류장)
    binding.tabLayout.selectTab(binding.tabLayout.getTabAt(searchType))
    
    // 초기 데이터 로드
    viewModel.start() {
        reqArea() // 지역 목록 API 호출
        ↓
        areaData.setValue(API응답.getAreaList())
        selectAreaData.setValue(첫번째_지역) // 기본 선택 지역
    }
    
    // 검색 히스토리 표시
    binding.recyclerView.adapter = historyAdapter
    viewModel.historyData() // 로컬 DB에서 버스 검색 기록 조회
}
```

### **검색 상세 플로우**
```kotlin
// 1. 사용자 검색어 입력
binding.searchEditText.addTextChangedListener {
    afterTextChanged(s) {
        if (s.length == 0) {
            // 검색어 비움 → 히스토리 표시
            binding.recyclerView.adapter = historyAdapter
            viewModel.historyData()
        }
    }
}

// 2. 검색 실행 (엔터 또는 검색 버튼)
binding.searchEditText.setOnEditorActionListener { textView, actionId, keyEvent ->
    if (EditorInfo.IME_ACTION_DONE == actionId) {
        if (검색어_존재) {
            binding.recyclerView.adapter = searchAdapter
            viewModel.searchData(true) // 첫 페이지 검색
        }
    }
}

// 3. 검색 API 호출
BusInfoSearchViewModel.searchData(first = true) {
    if (first) {
        pageNo = 1
        searchResultData = ArrayList() // 결과 초기화
    }
    
    if (searchType == 버스검색) {
        reqBusSearch(검색어, 선택지역, pageNo++) {
            TIARetrofitCallableBusInfoBusSearch.create() 실행
            ↓
            성공 시: addList(응답.getSrchRotList()) // 지역별 그룹핑 처리
            ↓
            recyclerViewItemList.setValue(결과) // UI 업데이트
        }
    } else {
        reqBusStationSearch() // 정류장 검색
    }
}

// 4. 검색 결과 표시 및 페이징
BusInfoSearchAdapter.onBindViewHolder() {
    // 검색 결과 타입별 ViewHolder 바인딩
    when (getItemViewType(position)) {
        AREA_SECTION -> HeaderViewHolder // "서울시", "경기도" 등
        BUS_SEARCH -> BusViewHolder       // 버스 노선 결과
        BUS_STATION_SEARCH -> BusStationViewHolder // 정류장 결과
    }
}

// 5. 스크롤 페이징
binding.recyclerView.addOnScrollListener {
    onScrolled() {
        if (마지막_아이템_보임) {
            viewModel.pagingData() // 다음 페이지 로드
        }
    }
}
```

## 4. 정류장 정보 화면 플로우

### **정류장 화면 진입 및 지도 초기화**
```kotlin
// 1. 정류장 선택 → BusStationInfoFragment 진입
// (Navigation Bundle: lat, lng, stationId, busId)

BusStationInfoFragment.onViewCreated() {
    initData() // Bundle 파라미터 추출
    initObserve() // LiveData 관찰 설정
    initListener() // 클릭 리스너 설정
    initNaverMap() // 네이버 맵 초기화
    initBottomSheet() // 하단 시트 설정
}

// 2. 네이버 맵 비동기 초기화
initNaverMap() {
    MapFragment.newInstance(options)
    getChildFragmentManager().beginTransaction().add(mapFragment)
    
    mapFragment.getMapAsync { naverMap ->
        this.naverMap = naverMap
        
        // 지도 설정
        naverMap.getUiSettings().setTiltGesturesEnabled(false)
        naverMap.getUiSettings().setZoomControlEnabled(false)
        
        // 권한 확인 후 내 위치 표시
        if (isPermissionGranted()) {
            setMyLocationMarker(false)
        }
        
        // 초기 위치가 있으면 해당 위치로 이동 후 데이터 로드
        if (위치정보_존재) {
            naverMap.moveCamera(CameraUpdate.toCameraPosition(초기위치))
            viewModel.start() // 주변 정류장 조회 시작
        }
    }
}
```

### **정류장 로딩 및 지도 마커 생성**
```kotlin
// 3. ViewModel에서 주변 정류장 조회
BusStationInfoViewModel.start() {
    reqBusStationBusInfo(bsstLttd, bsstLngt) {
        dataLoading.value = true
        
        TIARetrofitCallableBusInfoAreaBsstListData.create(위도, 경도) 실행
        ↓
        성공 시: {
            deleteStationMarker() // 기존 마커 제거
            
            val stations = 응답.getBusStopStationList()
            if (stations.isNotEmpty()) {
                setStationMarker(stations) // 새 마커 생성
                clearBottomSheet(true) // 하단 시트 표시
            }
        }
        ↓
        dataLoading.value = false
    }
}

// 4. 정류장 마커 생성 및 클릭 이벤트
setStationMarker(stations) {
    for (station in stations) {
        makeStationMarker(lat, lon, stationId, sggDvsCd, isFirst) {
            val marker = Marker()
            marker.setPosition(LatLng(lat, lon))
            marker.setIcon(정류장_아이콘)
            
            marker.setOnClickListener {
                // 선택 마커 표시
                selectMarker.setPosition(LatLng(lat, lon))
                selectMarker.setIcon(선택된_정류장_아이콘)
                
                // 해당 정류장의 버스 정보 조회
                reqBusStationBusInfoList(sggDvsCd, stationId, false)
                
                // 카메라 이동
                moveCamera.setValue(Event(LatLng(lat, lon)))
            }
            
            markers.add(marker)
            makeMarker.setValue(marker) // Fragment에서 지도에 추가
        }
    }
    
    // 캐시에 저장
    NearByBusStationsInfo.getInstance().addAll(stations)
    
    // 첫 번째 정류장 자동 선택
    if (stationId가_비어있음) {
        첫번째_마커.performClick()
    }
}
```

### **실시간 버스 도착 정보 처리**
```kotlin
// 5. 선택된 정류장의 버스 목록 조회
reqBusStationBusInfoList(sggDvsCd, bsstId, isFavorite) {
    endTimer() // 기존 타이머 중지
    
    TIARetrofitCallableBusInfoRotBsstAcsVhclInfoData.create(sggDvsCd, bsstId) 실행
    ↓
    성공 시: {
        data = 응답_버스목록_및_도착시간
        
        // 특정 버스 하이라이트 처리 (busId가 있는 경우)
        if (bus_id_존재) {
            해당_버스를_목록_맨앞으로_이동
        }
        
        busInfoStationInnerData.setValue(data) // UI 업데이트
        bottomSheetCollapsed.setValue(false) // 하단 시트 펼치기
        startTimer() // 실시간 타이머 시작
    }
}

// 6. 실시간 타이머 동작
private Handler handler = new Handler(Looper.getMainLooper()) {
    handleMessage(msg) {
        timeCal() // 모든 버스의 도착시간 1초씩 감소
        handler.sendEmptyMessageDelayed(0, 1000) // 1초 후 재실행
    }
}

timeCal() {
    val busInfoData = busInfoStationInnerData.getValue()
    val busList = busInfoData.getBsstRotList()
    
    for (busInfo in busList) {
        if (busInfo.getArscDrtm1() > 0) busInfo.setArscDrtm1(busInfo.getArscDrtm1() - 1)
        if (busInfo.getArscDrtm2() > 0) busInfo.setArscDrtm2(busInfo.getArscDrtm2() - 1)
    }
    
    busInfoStationInnerData.setValue(busInfoData) // UI 즉시 업데이트
}
```

## 5. 버스 노선 화면의 위치 매핑

### **노선 정보 및 실시간 버스 위치 처리**
```kotlin
// 1. 버스 노선 화면 진입 (sggDvsCd, rotId 전달)
BusRouteViewModel.start() {
    reqBusLineData() {
        TIARetrofitCallableBusInfoBusLineData.create(sggDvsCd, rotId) 실행
        ↓
        성공 시: busPositionRouteMapper(응답데이터)
    }
}

// 2. 복잡한 버스 위치 매핑 알고리즘
busPositionRouteMapper(data) {
    val busStationList = data.getBsstList() // 노선의 모든 정류장
    val realTimeBusList = data.getAcsVhclList() // 실시간 버스 위치
    
    // 각 정류장에 대해
    for (i in 0 until busStationList.size) {
        val station = busStationList[i]
        
        // 실시간 버스들 중에서
        for (bus in realTimeBusList) {
            if (station.getOprnSeq() == bus.getRngSqno()) { // 버스가 이 구간에 있음
                
                // 정류장 간 거리와 버스의 오프셋 거리로 정확한 위치 계산
                val 정류장간_거리 = station.getDistBtwBsst()
                val 버스_오프셋 = bus.getRngOfstDist()
                val 구간_단위 = 정류장간_거리 / 10
                
                // 0~10 사이의 비율로 변환 (시각적 표현용)
                val rate = (버스_오프셋 / 구간_단위) + 1
                bus.setRate(rate)
                
                // 거리 중점을 기준으로 어느 정류장에 표시할지 결정
                val half = 정류장간_거리 / 2
                val 표시할_정류장_인덱스 = if (버스_오프셋 < half) {
                    i - 1 // 이전 정류장에 표시
                } else {
                    i // 현재 정류장에 표시
                }
                
                // 해당 정류장에 버스 정보 추가
                data.getBsstList().get(표시할_정류장_인덱스).setBusList(bus)
            }
        }
    }
    
    busLineData.setValue(data) // UI 업데이트
}
```

### **버스 아이콘 배치**
```kotlin
// 3. RecyclerView에서 각 정류장 아이템 그리기
BusRouteViewHolder.setBusStationRouteItem(item, position, isLastItem) {
    // 버스 아이콘 초기화
    binding.busIcon1.setVisibility(View.INVISIBLE)
    binding.busIcon2.setVisibility(View.INVISIBLE)  
    binding.busIcon3.setVisibility(View.INVISIBLE)
    
    val busList = item.getBusList()
    if (busList != null && busList.size > 0) {
        
        // 최대 3대의 버스까지 표시
        for (i in 0 until min(busList.size, 3)) {
            val bus = busList[i]
            val rate = bus.getRate() // 0~10 사이의 위치 비율
            
            // rate 값에 따른 아이콘 위치 계산
            val topMarginPixel = when {
                rate in 0..5 -> {
                    // 정류장 하단 영역에 배치
                    TypedValue.applyDimension(COMPLEX_UNIT_DIP, 
                        22 + 4*rate, displayMetrics) // 하단에서 점진적으로 위로
                }
                rate in 6..10 -> {
                    // 정류장 상단 영역에 배치  
                    TypedValue.applyDimension(COMPLEX_UNIT_DIP,
                        3*(rate-5), displayMetrics) // 상단에서 점진적으로 아래로
                }
                else -> 0
            }
            
            // 해당하는 버스 아이콘의 마진 설정 및 표시
            when (i) {
                0 -> {
                    val params = binding.busIcon1.layoutParams as ConstraintLayout.LayoutParams
                    params.topMargin = topMarginPixel
                    binding.busIcon1.layoutParams = params
                    binding.busIcon1.visibility = View.VISIBLE
                }
                1 -> { /* busIcon2 처리 */ }
                2 -> { /* busIcon3 처리 */ }
            }
        }
    }
}
```

## 6. 전체 시스템의 상태 관리

### **리소스 관리**
```kotlin
// Fragment 생명주기와 연동된 리소스 정리
BusStationInfoFragment.onPause() {
    viewModel.endTimer() // 타이머 정지로 메모리 누수 방지
}

BusStationInfoFragment.onDestroy() {
    // 지도 마커 정리
    viewModel.removeSelectedMarker()
    // 네트워크 요청 취소 등
}
```

### **데이터 공유**
```kotlin
// 싱글톤 패턴으로 정류장 정보 캐싱
NearByBusStationsInfo.getInstance() {
    // 지도에서 조회한 주변 정류장 정보를
    // 정류장 목록 화면에서도 재활용
    
    // BusStationInfoFragment에서 저장
    NearByBusStationsInfo.getInstance().addAll(stations)
    
    // PTStationListActivity에서 활용
    val nearByStations = NearByBusStationsInfo.getInstance().getAll()
    adapter = PTStationListAdapter(nearByStations) { selectedStation ->
        // 선택된 정류장 정보로 다시 BusStationInfoFragment로
        setResult(RESULT_OK, Intent().apply {
            putExtra(STATION_ID, selectedStation.bsstId)
            putExtra(LOCATION, LatLng(selectedStation.lat, selectedStation.lng))
        })
    }
}
```
