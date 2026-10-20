package com.example.uth_flow

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.util.concurrent.TimeUnit
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.uth_flow/moodle"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.isStatusBarContrastEnforced = false
            window.isNavigationBarContrastEnforced = false
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getMoodleDeadlines") {
                val username = call.argument<String>("username") ?: ""
                val password = call.argument<String>("password") ?: ""

                thread {
                    try {
                        val json = fetchDeadlines(username, password)
                        runOnUiThread {
                            result.success(json)
                        }
                    } catch (e: Exception) {
                        runOnUiThread {
                            result.error("MOODLE_ERROR", e.message, null)
                        }
                    }
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun fetchDeadlines(username: String, password: String): String {
        val userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        val cookieStore = mutableListOf<Cookie>()

        val client = OkHttpClient.Builder()
            .cookieJar(object : CookieJar {
                override fun saveFromResponse(url: HttpUrl, cookies: List<Cookie>) {
                    synchronized(cookieStore) {
                        for (newCookie in cookies) {
                            cookieStore.removeAll { it.name == newCookie.name }
                            cookieStore.add(newCookie)
                        }
                    }
                    android.util.Log.d("MoodleSync", "saveFromResponse url=$url, added: ${cookies.map { it.name }}")
                }

                override fun loadForRequest(url: HttpUrl): List<Cookie> {
                    val matching = synchronized(cookieStore) {
                        cookieStore.filter { it.matches(url) }
                    }
                    android.util.Log.d("MoodleSync", "loadForRequest url=$url, returning count=${matching.size}")
                    return matching
                }
            })
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .followRedirects(true)
            .followSslRedirects(true)
            .build()

        android.util.Log.d("MoodleSync", "Starting Moodle sync for user=$username, passLen=${password.length}")

        // 1. Tải trang login
        val loginUrl = "https://courses.ut.edu.vn/login/index.php"
        val req1 = Request.Builder()
            .url(loginUrl)
            .header("User-Agent", userAgent)
            .header("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8")
            .build()

        val res1 = client.newCall(req1).execute()
        val html1 = res1.body?.string() ?: ""

        val tokenRegex = Regex("""name="logintoken"\s+value="([^"]+)"""")
        val logintoken = tokenRegex.find(html1)?.groupValues?.get(1)
        android.util.Log.d("MoodleSync", "Step 1 loaded: logintoken=${logintoken != null}")

        var sesskey: String? = null

        if (logintoken != null) {
            // 2. Submit đăng nhập
            val formBody = FormBody.Builder()
                .add("anchor", "")
                .add("logintoken", logintoken)
                .add("username", username)
                .add("password", password)
                .build()

            val req2 = Request.Builder()
                .url(loginUrl)
                .header("User-Agent", userAgent)
                .header("Origin", "https://courses.ut.edu.vn")
                .header("Referer", loginUrl)
                .header("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8")
                .post(formBody)
                .build()

            val res2 = client.newCall(req2).execute()
            val html2 = res2.body?.string() ?: ""
            val finalUrl = res2.request.url.toString()
            android.util.Log.d("MoodleSync", "Step 2 submitted: code=${res2.code}, finalUrl=$finalUrl, htmlLen=${html2.length}")

            // Kiểm tra nếu login thất bại
            if (finalUrl.contains("/login/index.php") && html2.contains("name=\"logintoken\"")) {
                val errorAlertRegex = Regex("""<div[^>]*class="[^"]*alert-danger[^"]*"[^>]*>(.*?)</div>""")
                val alertMsg = errorAlertRegex.find(html2)?.groupValues?.get(1)?.replace(Regex("<[^>]+>"), "")?.trim()
                android.util.Log.e("MoodleSync", "Login failed with alert: $alertMsg")
                throw Exception(alertMsg ?: "Đăng nhập Moodle không thành công. Vui lòng kiểm tra lại thông tin đăng nhập.")
            }

            // Tìm sesskey từ response sau redirect
            sesskey = Regex(""""sesskey":"([^"]+)"""").find(html2)?.groupValues?.get(1)
                ?: Regex("""name="sesskey"\s+value="([^"]+)"""").find(html2)?.groupValues?.get(1)
            android.util.Log.d("MoodleSync", "sesskey from step 2: $sesskey")
        } else {
            // Đã có phiên đăng nhập sẵn
            sesskey = Regex(""""sesskey":"([^"]+)"""").find(html1)?.groupValues?.get(1)
                ?: Regex("""name="sesskey"\s+value="([^"]+)"""").find(html1)?.groupValues?.get(1)
            android.util.Log.d("MoodleSync", "sesskey from step 1: $sesskey")
        }

        // 3. Nếu chưa có sesskey từ redirect, tải trang courses.php
        if (sesskey == null || sesskey.isEmpty()) {
            val coursesUrl = "https://courses.ut.edu.vn/my/courses.php"
            val req3 = Request.Builder()
                .url(coursesUrl)
                .header("User-Agent", userAgent)
                .header("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8")
                .build()

            val res3 = client.newCall(req3).execute()
            val html3 = res3.body?.string() ?: ""

            sesskey = Regex(""""sesskey":"([^"]+)"""").find(html3)?.groupValues?.get(1)
                ?: Regex("""name="sesskey"\s+value="([^"]+)"""").find(html3)?.groupValues?.get(1)
                ?: throw Exception("Không tìm thấy sesskey Moodle (phiên đăng nhập không hợp lệ)")
            android.util.Log.d("MoodleSync", "sesskey from step 3: $sesskey")
        }

        // 4. Lấy lịch hạn chót (Khớp hoàn toàn uth-sync: limitnum = 50)
        val nowSeconds = System.currentTimeMillis() / 1000
        val startTs = nowSeconds - (365 * 24 * 60 * 60)
        val endTs = nowSeconds + (365 * 24 * 60 * 60)

        val payload = JSONArray().apply {
            put(JSONObject().apply {
                put("index", 0)
                put("methodname", "core_calendar_get_action_events_by_timesort")
                put("args", JSONObject().apply {
                    put("timesortfrom", startTs)
                    put("timesortto", endTs)
                    put("limitnum", 50)
                })
            })
            put(JSONObject().apply {
                put("index", 1)
                put("methodname", "core_course_get_enrolled_courses_by_timeline_classification")
                put("args", JSONObject().apply {
                    put("offset", 0)
                    put("limit", 100)
                    put("classification", "all")
                    put("sort", "ul.timeaccess desc")
                    put("customfieldname", "")
                    put("customfieldvalue", "")
                })
            })
        }.toString()

        val serviceUrl = "https://courses.ut.edu.vn/lib/ajax/service.php?sesskey=$sesskey&info=core_calendar_get_action_events_by_timesort,core_course_get_enrolled_courses_by_timeline_classification"
        val req4 = Request.Builder()
            .url(serviceUrl)
            .header("User-Agent", userAgent)
            .header("Content-Type", "application/json")
            .header("Accept", "application/json, text/plain, */*")
            .post(payload.toRequestBody("application/json".toMediaType()))
            .build()

        val res4 = client.newCall(req4).execute()
        val resBody = res4.body?.string() ?: "[]"
        android.util.Log.d("MoodleSync", "Moodle service response: ${resBody.take(200)}")

        if (resBody.contains("servicerequireslogin")) {
            throw Exception("Dịch vụ Moodle yêu cầu đăng nhập lại (phiên hết hạn)")
        }
        return resBody
    }
}
