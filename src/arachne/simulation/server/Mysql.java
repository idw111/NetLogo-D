package arachne.simulation.server;

import java.sql.*;

public class Mysql {
	Connection conn;
	Statement stmt;
	PreparedStatement pstmt;
	ResultSet rs;
	
	public Mysql() {
		conn = null;
		stmt = null;
		rs = null;
		try {
			Class.forName("com.mysql.jdbc.Driver");
		}
		catch(ClassNotFoundException ex) {
			ex.printStackTrace();
		}
	}
	
	public boolean hasTable(String table) {
		if (conn == null) return false;
		
		try {
			ResultSet rs = this.query("SHOW TABLES LIKE '" + table + "'");
			if (rs.next()) return true;
		}
		catch (SQLException ex) {
			ex.printStackTrace();
		}
		return false;
	}
	
	public void connect(String url, String id, String pw) {
		try {
            Class.forName("com.mysql.jdbc.Driver");
		}
		catch (Exception ex) {
			ex.printStackTrace();
		}
		
		try {
			conn = DriverManager.getConnection(url, id, pw);
			stmt = conn.createStatement();
		}
		catch (SQLException ex) {
			ex.printStackTrace();
		}
	}
	
	public void close() {
		try {
			conn.close();
		}
		catch (Exception ex) {
			ex.printStackTrace();
		}
	}
	
	public ResultSet query(String sql) {
		System.out.println(sql);
		rs = null;
		try {
			rs = stmt.executeQuery(sql);
		}
		catch (SQLException ex) {
			ex.printStackTrace();
			rs = null;
		}
		return rs;
	}
	
	public void execute(String sql) throws SQLException {
		System.out.println(sql);
		try {
			conn.setAutoCommit(false);
			pstmt = conn.prepareStatement(sql);
			pstmt.execute();
			conn.commit();
		}
		catch (SQLException ex) {
			ex.printStackTrace();
		}
		finally {
			conn.setAutoCommit(true);
		}
	}
}
