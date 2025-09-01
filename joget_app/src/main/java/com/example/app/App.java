package com.example.app;

import com.sun.net.httpserver.HttpServer;
import com.sun.net.httpserver.HttpExchange;

import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class App {

    private static String jdbcURL;
    private static String dbUser;
    private static String dbPassword;
    private static int appPort;

    public static void main(String[] args) throws Exception {
        jdbcURL = getenvOrFail("DB_URL");
        dbUser = getenvOrFail("DB_USER");
        dbPassword = getenvOrFail("DB_PASS");
        appPort = Integer.parseInt(System.getenv().getOrDefault("APP_PORT", "8080"));

        HttpServer server = HttpServer.create(new InetSocketAddress("127.0.0.1", appPort), 0);

        // Root - info
        server.createContext("/", exchange -> {
            String body = "Hybrid Demo App is running. Try GET /users";
            respondText(exchange, 200, body);
        });

        // Users endpoint - returns JSON array of {id, name, email}
        server.createContext("/users", exchange -> {
            if (!"GET".equalsIgnoreCase(exchange.getRequestMethod())) {
                respondText(exchange, 405, "Method Not Allowed");
                return;
            }
            try (Connection connection = DriverManager.getConnection(jdbcURL, dbUser, dbPassword);
                 Statement stmt = connection.createStatement();
                 ResultSet rs = stmt.executeQuery("SELECT id, name, email FROM users")) {

                List<String> items = new ArrayList<>();
                while (rs.next()) {
                    int id = rs.getInt("id");
                    String name = rs.getString("name");
                    String email = rs.getString("email");
                    // naive JSON (safe for this simple example)
                    items.add(String.format("{\"id\":%d,\"name\":\"%s\",\"email\":\"%s\"}",
                            id, escape(name), escape(email)));
                }
                String json = "[" + String.join(",", items) + "]";
                respondJson(exchange, 200, json);

            } catch (SQLException e) {
                e.printStackTrace();
                respondText(exchange, 500, "DB error: " + e.getMessage());
            }
        });

        server.setExecutor(null);
        server.start();
        System.out.println("App started on 127.0.0.1:" + appPort);
    }

    private static String getenvOrFail(String key) {
        String v = System.getenv(key);
        if (v == null || v.isBlank()) {
            throw new IllegalStateException("Missing environment variable: " + key);
        }
        return v;
    }

    private static void respondText(HttpExchange exchange, int status, String body) throws IOException {
        byte[] bytes = body.getBytes();
        exchange.getResponseHeaders().add("Content-Type", "text/plain; charset=utf-8");
        exchange.sendResponseHeaders(status, bytes.length);
        try (OutputStream os = exchange.getResponseBody()) {
            os.write(bytes);
        }
    }

    private static void respondJson(HttpExchange exchange, int status, String json) throws IOException {
        byte[] bytes = json.getBytes();
        exchange.getResponseHeaders().add("Content-Type", "application/json; charset=utf-8");
        exchange.sendResponseHeaders(status, bytes.length);
        try (OutputStream os = exchange.getResponseBody()) {
            os.write(bytes);
        }
    }

    private static String escape(String s) {
        return s.replace("\"", "\\\"");
    }
}