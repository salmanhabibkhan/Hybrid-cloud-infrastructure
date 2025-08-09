package com.example.app;

import java.sql.*;

public class App {
    public static void main(String[] args) {
        String jdbcURL = "jdbc:mysql://localhost:3306/joget_db";
        String dbUser = "jogetuser";
        String dbPassword = "StrongPassword123!"; // change this Accordingly

        try {

            Connection connection = DriverManager.getConnection(jdbcURL, dbUser, dbPassword);
            System.out.println("Connected to MySQL!");

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