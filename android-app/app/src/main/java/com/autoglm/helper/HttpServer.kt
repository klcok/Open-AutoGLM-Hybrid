package com.autoglm.helper

import android.util.Log
import fi.iki.elonen.NanoHTTPD
import org.json.JSONObject
import java.io.ByteArrayInputStream

class HttpServer(private val service: AutoGLMAccessibilityService, port: Int = 8080) : NanoHTTPD(port) {
    
    companion object {
        private const val TAG = "AutoGLM-HttpServer"
    }

    override fun serve(session: IHTTPSession): Response {
        val uri = session.uri
        val method = session.method
        
        Log.d(TAG, "Request: $method $uri")

        return try {
            when {
                uri == "/status" && method == Method.GET -> handleStatus()
                uri == "/current_app" && method == Method.GET -> handleCurrentApp()
                uri == "/screenshot" && method == Method.GET -> handleScreenshot()
                uri == "/launch" && method == Method.POST -> handleLaunch(session)
                uri == "/resolve" && method == Method.POST -> handleResolve(session)
                uri == "/tap" && method == Method.POST -> handleTap(session)
                uri == "/swipe" && method == Method.POST -> handleSwipe(session)
                uri == "/input" && method == Method.POST -> handleInput(session)
                else -> newFixedLengthResponse(
                    Response.Status.NOT_FOUND,
                    "application/json",
                    """{"error": "Not found"}"""
                )
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error handling request", e)
            newFixedLengthResponse(
                Response.Status.INTERNAL_ERROR,
                "application/json",
                """{"error": "${e.message}"}"""
            )
        }
    }

    private fun handleStatus(): Response {
        val json = JSONObject()
        json.put("status", "ok")
        json.put("service", "AutoGLM Helper")
        json.put("version", "1.0.0")
        json.put("accessibility_enabled", service.isAccessibilityEnabled())
        
        return newFixedLengthResponse(
            Response.Status.OK,
            "application/json",
            json.toString()
        )
    }

    private fun handleCurrentApp(): Response {
        val json = JSONObject()
        json.put("status", "ok")
        json.put("accessibility_enabled", service.isAccessibilityEnabled())
        json.put("package", service.getCurrentPackageName())

        return newFixedLengthResponse(
            Response.Status.OK,
            "application/json",
            json.toString()
        )
    }

    private fun handleScreenshot(): Response {
        val screenshot = service.takeScreenshotBase64()
        
        return if (screenshot != null) {
            val json = JSONObject()
            json.put("success", true)
            json.put("image", screenshot)
            json.put("format", "base64")
            
            newFixedLengthResponse(
                Response.Status.OK,
                "application/json",
                json.toString()
            )
        } else {
            val json = JSONObject()
            json.put("success", false)
            json.put("error", "Failed to take screenshot")
            
            newFixedLengthResponse(
                Response.Status.INTERNAL_ERROR,
                "application/json",
                json.toString()
            )
        }
    }

    private fun handleLaunch(session: IHTTPSession): Response {
        val body = getRequestBody(session)
        val json = JSONObject(body)

        val packageName = json.optString("package", "").trim()
        if (packageName.isEmpty()) {
            return newFixedLengthResponse(
                Response.Status.BAD_REQUEST,
                "application/json",
                """{"success": false, "error": "Missing 'package'"}"""
            )
        }

        val success = service.launchPackage(packageName)
        val resp = JSONObject()
        resp.put("success", success)
        if (!success) {
            resp.put("error", "Failed to launch package")
        }

        return newFixedLengthResponse(
            Response.Status.OK,
            "application/json",
            resp.toString()
        )
    }

    private fun handleResolve(session: IHTTPSession): Response {
        val body = getRequestBody(session)
        val json = JSONObject(body)

        val name = json.optString("name", "").trim()
        if (name.isEmpty()) {
            return newFixedLengthResponse(
                Response.Status.BAD_REQUEST,
                "application/json",
                """{"success": false, "error": "Missing 'name'"}"""
            )
        }

        val pkg = service.resolvePackageByLabel(name)
        val resp = JSONObject()
        resp.put("success", pkg != null)
        resp.put("package", pkg)
        if (pkg == null) {
            resp.put("error", "No matching app")
        }

        return newFixedLengthResponse(
            Response.Status.OK,
            "application/json",
            resp.toString()
        )
    }

    private fun handleTap(session: IHTTPSession): Response {
        val body = getRequestBody(session)
        val json = JSONObject(body)
        
        val x = json.getInt("x")
        val y = json.getInt("y")
        
        val success = service.performTap(x, y)
        
        val response = JSONObject()
        response.put("success", success)
        
        return newFixedLengthResponse(
            Response.Status.OK,
            "application/json",
            response.toString()
        )
    }

    private fun handleSwipe(session: IHTTPSession): Response {
        val body = getRequestBody(session)
        val json = JSONObject(body)
        
        val x1 = json.getInt("x1")
        val y1 = json.getInt("y1")
        val x2 = json.getInt("x2")
        val y2 = json.getInt("y2")
        val duration = json.optInt("duration", 300)
        
        val success = service.performSwipe(x1, y1, x2, y2, duration)
        
        val response = JSONObject()
        response.put("success", success)
        
        return newFixedLengthResponse(
            Response.Status.OK,
            "application/json",
            response.toString()
        )
    }

    private fun handleInput(session: IHTTPSession): Response {
        val body = getRequestBody(session)
        val json = JSONObject(body)
        
        val text = json.getString("text")
        
        val success = service.performInput(text)
        
        val response = JSONObject()
        response.put("success", success)
        
        return newFixedLengthResponse(
            Response.Status.OK,
            "application/json",
            response.toString()
        )
    }

    private fun getRequestBody(session: IHTTPSession): String {
        val map = HashMap<String, String>()
        session.parseBody(map)
        return map["postData"] ?: ""
    }
}
