package com.example.app;

import java.sql.*;

public class App {
    public static void main(String[] args) {
        String jdbcURL = System.getenv("DB_URL");
        String dbUser = System.getenv("DB_USER");
        String dbPassword = System.getenv("DB_PASS");

        if (jdbcURL == null || dbUser == null || dbPassword == null) {
            System.out.println("Missing DB environment variables. Please set DB_URL, DB_USER, and DB_PASS.");
            return;
        }

        try {
            Connection connection = DriverManager.getConnection(jdbcURL, dbUser, dbPassword);
            System.out.println("✅ Connected to MySQL!");

            Statement statement = connection.createStatement();
            ResultSet resultSet = statement.executeQuery("SELECT * FROM users");

            while (resultSet.next()) {
                System.out.println(
                    resultSet.getInt("id") + " | " +
                    resultSet.getString("name") + " | " +
                    resultSet.getString("email")
                );
            }

            connection.close();
        } catch (SQLException e) {
            System.out.println("Error connecting to MySQL:");
            e.printStackTrace();
        }
    }
}
