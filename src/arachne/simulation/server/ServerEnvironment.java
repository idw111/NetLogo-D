package arachne.simulation.server;

import java.io.*;
import java.sql.SQLException;
import java.util.*;

public class ServerEnvironment {
	public static int repetition = 1;
	public static int iteration = 1000;
	public static String FILENAME = "";
	public static ArrayList<String> DBINFO = new ArrayList<String>();
	public static ArrayList<String> PARAMETERS = new ArrayList<String>();
	public static ArrayList<String> P_TYPES = new ArrayList<String>();
	public static ArrayList<String> REPORTERS = new ArrayList<String>();
	public static ArrayList<String> R_TYPES = new ArrayList<String>();
	
	public ServerEnvironment() {
	}
	
	public static void read() {
		init();
		
		try {
			String line = "";
			BufferedReader file = new BufferedReader(new FileReader("server.conf"));			
			while ((line = file.readLine()) != null) {
				String[] tokens = line.split(" ");
				String command = tokens[0];
				switch (command) {
				case "DBINFO":
					ServerEnvironment.DBINFO.add(tokens[2]);
					System.out.println(ServerEnvironment.DBINFO.get(ServerEnvironment.DBINFO.size() - 1));
					break;
				case "FILENAME":
					ServerEnvironment.FILENAME = tokens[1];
					System.out.println(ServerEnvironment.FILENAME);
					break;
				case "PARAMETERS":
					ServerEnvironment.PARAMETERS.add(tokens[1]);
					ServerEnvironment.P_TYPES.add(tokens[2]);
					break;
				case "REPORTERS":
					ServerEnvironment.REPORTERS.add(tokens[1]);
					ServerEnvironment.R_TYPES.add(tokens[2]);
					break;
				case "REPETITION":
					ServerEnvironment.repetition = Integer.parseInt(tokens[1]);
					break;
				case "ITERATION":
					ServerEnvironment.iteration = Integer.parseInt(tokens[1]);
					break;
				}
			}
			file.close();
		}
		catch (IOException ex) {
			ex.printStackTrace();
		}
	}
	
	public static void init() {
		repetition = 1;
		iteration = 1000;
		FILENAME = "";
		DBINFO.clear();
		PARAMETERS.clear();
		P_TYPES.clear();
		REPORTERS.clear();
		R_TYPES.clear();
	}
	
	public static void createDatabase() {
		String[] connection = DBINFO.get(0).split("/");
		String database = connection[connection.length - 1];
		
		// check if the database exists, and create it if it doesn't exist 
	}
	
	public static void createDataTable() {
		String[] tokens = ServerEnvironment.DBINFO.get(0).split("/");
		String dbname = tokens[tokens.length - 1];
		String table = ServerEnvironment.DBINFO.get(4); // data_table
		
		Mysql db = new Mysql();
		db.connect(ServerEnvironment.DBINFO.get(0), ServerEnvironment.DBINFO.get(1), ServerEnvironment.DBINFO.get(2));

		String vars = "num INT(11) NOT NULL AUTO_INCREMENT, ";
		vars += "task_id INT(10) UNSIGNED NOT NULL, ";
		for (int i = 0; i < ServerEnvironment.REPORTERS.size(); i++) {
			switch (ServerEnvironment.R_TYPES.get(i)) {
			case "int":
				vars += String.format("%s INT(11) NOT NULL, ", ServerEnvironment.REPORTERS.get(i));
				break;
			case "float":
				vars += String.format("%s FLOAT NOT NULL, ", ServerEnvironment.REPORTERS.get(i));
				break;
			case "String":
				vars += String.format("%s TEXT NOT NULL, ", ServerEnvironment.REPORTERS.get(i));
				break;
			}
		}
		vars += "regdate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY (num)";
		String sql = String.format("CREATE TABLE %s.%s (%s)", dbname, table, vars);
		
		if (!db.hasTable(table)) {
			try {
				db.execute(sql);
			}
			catch (SQLException ex) {
				ex.printStackTrace();
			}
		}
		else System.out.println("already has the data_table!");
		
		db.close();
	}
	
	public static void createTaskTable() {
		String[] tokens = ServerEnvironment.DBINFO.get(0).split("/");
		String dbname = tokens[tokens.length - 1];
		String table = ServerEnvironment.DBINFO.get(3); // task_table
		
		Mysql db = new Mysql();
		db.connect(ServerEnvironment.DBINFO.get(0), ServerEnvironment.DBINFO.get(1), ServerEnvironment.DBINFO.get(2));
		
		String vars = "task_id INT(10) UNSIGNED NOT NULL AUTO_INCREMENT, ";
		vars += "task_assigned INT(11) NOT NULL DEFAULT 0, ";
		vars += "task_done INT(11) NOT NULL DEFAULT 0, ";
		for (int i = 0; i < ServerEnvironment.PARAMETERS.size(); i++) {
			switch (ServerEnvironment.P_TYPES.get(i)) {
			case "int":
				vars += String.format("%s INT(11) NOT NULL, ", ServerEnvironment.PARAMETERS.get(i));
				break;
			case "float":
				vars += String.format("%s FLOAT NOT NULL, ", ServerEnvironment.PARAMETERS.get(i));
				break;
			case "String":
				vars += String.format("%s TEXT NOT NULL, ", ServerEnvironment.PARAMETERS.get(i));
				break;
			}
		}
		vars += "regdate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY (task_id)";
		String sql = String.format("CREATE TABLE %s.%s (%s)", dbname, table, vars);
		
		if (!db.hasTable(table)) {
			try {
				db.execute(sql);
			}
			catch (SQLException ex) {
				ex.printStackTrace();
			}
		}
		else System.out.println("already has the task_table!");
		
		db.close();
	}	
}
