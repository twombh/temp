좋지! 티머니GO 홈 화면(하단 탭 + 상단 탭 + 배너 캐러셀 + 아이콘 그리드 + 프로모 카드) 느낌으로 Jetpack Compose 기반 클론코딩 스켈레톤을 바로 돌릴 수 있게 줘볼게. 아이콘‧이미지는 일단 기본 Icons.Default.*와 색 블록으로 대체했고, 나중에 네가 에셋만 교체하면 된다.

1) Gradle 설정 (Compose + Pager)
app/build.gradle.kts

kotlin

plugins {
    id("com.android.application")
    kotlin("android")
}

android {
    namespace = "com.example.tmoneyclone"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.example.tmoneyclone"
        minSdk = 24
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
        vectorDrawables.useSupportLibrary = true
    }
    buildFeatures { compose = true }
    composeOptions { kotlinCompilerExtensionVersion = "1.5.14" }
}

dependencies {
    val composeBom = platform("androidx.compose:compose-bom:2024.06.00")
    implementation(composeBom)
    androidTestImplementation(composeBom)

    implementation("androidx.activity:activity-compose:1.9.1")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-tooling-preview")
    debugImplementation("androidx.compose.ui:ui-tooling")
    implementation("androidx.compose.foundation:foundation")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("androidx.navigation:navigation-compose:2.7.7")

    // HorizontalPager
    implementation("androidx.compose.foundation:foundation:1.6.8")
}
2) 엔트리포인트
MainActivity.kt


package com.example.tmoneyclone

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                Surface { TmoneyApp() }
            }
        }
    }
}
3) 네비게이션 + 하단 바
TmoneyApp.kt

kotlin
복사
편집
package com.example.tmoneyclone

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CardGiftcard
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material.icons.filled.PersonPinCircle
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier

@Composable
fun TmoneyApp() {
    var current by remember { mutableStateOf(BottomTab.Home) }

    Scaffold(
        bottomBar = {
            NavigationBar {
                BottomTab.entries.forEach { tab ->
                    NavigationBarItem(
                        selected = current == tab,
                        onClick = { current = tab },
                        icon = { Icon(tab.icon, contentDescription = tab.title) },
                        label = { Text(tab.title) }
                    )
                }
            }
        }
    ) { padding ->
        when (current) {
            BottomTab.Find -> PlaceholderScreen("길찾기")
            BottomTab.My -> PlaceholderScreen("마이")
            BottomTab.Home -> HomeScreen(Modifier.padding(padding))
            BottomTab.Benefit -> PlaceholderScreen("혜택")
            BottomTab.Menu -> PlaceholderScreen("전체메뉴")
        }
    }
}

enum class BottomTab(val title: String, val icon: androidx.compose.ui.graphics.vector.ImageVector) {
    Find("길찾기", Icons.Default.PersonPinCircle),
    My("마이", Icons.Default.PersonPinCircle),
    Home("홈", Icons.Default.Home),
    Benefit("혜택", Icons.Default.CardGiftcard),
    Menu("전체메뉴", Icons.Default.Menu)
}

@Composable
fun PlaceholderScreen(title: String) {
    Surface { Text(title, style = MaterialTheme.typography.headlineMedium) }
}
4) 홈 화면(상단 탭 + 배너 + 그리드 + 카드)
HomeScreen.kt


package com.example.tmoneyclone

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.DirectionsBus
import androidx.compose.material.icons.filled.DirectionsCar
import androidx.compose.material.icons.filled.DirectionsRailway
import androidx.compose.material.icons.filled.ElectricScooter
import androidx.compose.material.icons.filled.LocalTaxi
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun HomeScreen(modifier: Modifier = Modifier) {
    var tabIndex by remember { mutableStateOf(0) }
    val tabs = listOf("교통", "여행/생활")

    Column(modifier.fillMaxSize()) {
        // 상단 탭
        TabRow(selectedTabIndex = tabIndex) {
            tabs.forEachIndexed { i, title ->
                Tab(
                    selected = tabIndex == i,
                    onClick = { tabIndex = i },
                    text = { Text(title) }
                )
            }
        }

        // 배너 캐러셀
        val pager = rememberPagerState(pageCount = { BannerData.items.size })
        HorizontalPager(state = pager, modifier = Modifier
            .fillMaxWidth()
            .height(120.dp)) { page ->
            BannerCard(BannerData.items[page])
        }

        Spacer(Modifier.height(12.dp))

        // 그리드(교통/여행 둘 다 재사용)
        val features = if (tabIndex == 0) FeatureData.transport else FeatureData.life
        FeatureGrid(features = features, modifier = Modifier.weight(1f))

        // 아래 프로모 카드 2~3개
        PromoCard(title = "온다택시가 처음이라면? 기본료 무료!")
        Spacer(Modifier.height(8.dp))
        PromoCard(title = "렌터카 빌릴 때마다 7% 무한 적립!")
        Spacer(Modifier.height(12.dp))
    }
}

/** 배너 카드(색 블록 대체) */
@Composable
private fun BannerCard(banner: BannerItem) {
    Surface(
        modifier = Modifier
            .padding(horizontal = 16.dp, vertical = 8.dp)
            .fillMaxWidth(),
        shape = MaterialTheme.shapes.medium,
        tonalElevation = 2.dp,
        color = banner.bg
    ) {
        Box(Modifier.height(120.dp).padding(16.dp)) {
            Text(banner.title, style = MaterialTheme.typography.titleMedium, color = Color.White)
        }
    }
}

/** 기능 그리드 */
@Composable
private fun FeatureGrid(features: List<FeatureItem>, modifier: Modifier = Modifier) {
    LazyVerticalGrid(
        columns = GridCells.Fixed(4),
        modifier = modifier.padding(horizontal = 8.dp)
    ) {
        items(features) { f ->
            FeatureCell(f)
        }
    }
}

@Composable
private fun FeatureCell(item: FeatureItem) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier
            .padding(8.dp)
            .fillMaxWidth()
    ) {
        Surface(
            shape = MaterialTheme.shapes.medium,
            color = item.tint.copy(alpha = 0.1f)
        ) {
            Box(Modifier.size(56.dp), contentAlignment = Alignment.Center) {
                Icon(item.icon, contentDescription = item.title, tint = item.tint)
            }
        }
        Spacer(Modifier.height(6.dp))
        Text(item.title, style = MaterialTheme.typography.labelMedium)
    }
}

/** 하단 프로모 카드 */
@Composable
private fun PromoCard(title: String) {
    Surface(
        modifier = Modifier.padding(horizontal = 16.dp),
        shape = MaterialTheme.shapes.medium,
        tonalElevation = 1.dp
    ) {
        Row(
            Modifier
                .fillMaxWidth()
                .background(Color(0xFFE7F0FF))
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(Modifier.size(48.dp).background(Color(0xFFBFD4FF)))
            Spacer(Modifier.width(12.dp))
            Text(title, style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.Bold))
        }
    }
}

/** 더미 데이터 */
data class FeatureItem(val title: String, val icon: ImageVector, val tint: Color)
data class BannerItem(val title: String, val bg: Color)

object FeatureData {
    val transport = listOf(
        FeatureItem("고속·시외", Icons.Default.DirectionsBus, Color(0xFF7B61FF)),
        FeatureItem("공항버스", Icons.Default.DirectionsBus, Color(0xFF7B61FF)),
        FeatureItem("대중교통", Icons.Default.DirectionsRailway, Color(0xFF6E6E6E)),
        FeatureItem("자전거·킥보드", Icons.Default.ElectricScooter, Color(0xFF7AC943)),
        FeatureItem("공공자전거", Icons.Default.ElectricScooter, Color(0xFF7AC943)),
        FeatureItem("항공", Icons.Default.DirectionsCar, Color(0xFF5EC1FF)),
        FeatureItem("택시", Icons.Default.LocalTaxi, Color(0xFFFF7A00)),
        FeatureItem("지하철", Icons.Default.DirectionsRailway, Color(0xFF9B51E0)),
        FeatureItem("기동카따릉이", Icons.Default.DirectionsCar, Color(0xFFFF8FB1)),
        FeatureItem("고속페리", Icons.Default.DirectionsCar, Color(0xFF7B61FF)),
        FeatureItem("렌터카", Icons.Default.DirectionsCar, Color(0xFF00A8E8)),
        FeatureItem("SRT", Icons.Default.DirectionsRailway, Color(0xFF6E6E6E)),
        FeatureItem("쿠팡혜택", Icons.Default.CardGiftcard, Color(0xFFE63E6D)),
        FeatureItem("첫구매특가", Icons.Default.CardGiftcard, Color(0xFF5E60CE)),
    )

    val life = listOf(
        FeatureItem("쿠폰", Icons.Default.CardGiftcard, Color(0xFFE63E6D)),
        FeatureItem("이벤트", Icons.Default.CardGiftcard, Color(0xFF5E60CE)),
        FeatureItem("보험", Icons.Default.CardGiftcard, Color(0xFF00A8E8)),
        FeatureItem("배지", Icons.Default.CardGiftcard, Color(0xFF7B61FF)),
    )
}

object BannerData {
    val items = listOf(
        BannerItem("관광택시 출시기념 50% 할인 EVENT", Color(0xFF4E8AF0)),
        BannerItem("모바일티머니 결제 30% 할인", Color(0xFF8ADCE6)),
        BannerItem("전기자전거/킥보드 첫 1,900원 3회", Color(0xFFB7E3B6)),
    )
}
5) 바꿔 끼우면 좋은 포인트
아이콘/이미지: FeatureItem의 icon을 실제 PNG/SVG로 교체하면 더 비슷해진다. (Compose는 painterResource(R.drawable.xxx) 사용)

색/폰트: 실제 브랜드 컬러 팔레트로 Color(...)만 바꾸면 톤이 확 달라진다.

배너 자동 슬라이드: LaunchedEffect와 delay로 pager.animateScrollToPage(...) 추가하면 자동 롤링된다.

상단 공지/마이메뉴: 홈 상단에 작은 Card와 LazyRow를 하나 더 얹으면 된다.

원하는 디테일(알림 뱃지, 마일리지 배지, 점수 뱃지, 실시간 위치 권한, 실제 API 바인딩 등) 붙이고 싶으면 그 파트만 말해줘. 해당 섹션용 컴포저블이랑 상태모델까지 확장해줄게.