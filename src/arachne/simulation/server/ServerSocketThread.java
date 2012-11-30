package arachne.simulation.server;

import java.io.*;
import java.net.*;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.text.SimpleDateFormat;
import java.util.*;

public class ServerSocketThread extends Thread {
	Socket socket;
	NetlogoServer server;
	PrintWriter writer;
	BufferedReader reader;
	String name = "";
	String thread_name = "Thread";
	
	ArrayList<String> values = new ArrayList<String>();
	Mysql db;
	int count = 0;
	int task_id = 0;
	//String started_at;
	Calendar started_at;
	
	public ServerSocketThread(NetlogoServer ns, Socket s) {
		db = new Mysql();
		db.connect(ServerEnvironment.DBINFO.get(0), ServerEnvironment.DBINFO.get(1), ServerEnvironment.DBINFO.get(2));
		socket = s;
		server = ns;
		thread_name = getName();
		System.out.println(socket.getInetAddress() + " entered!");
		System.out.println("Thread name: " + thread_name);
		//started_at = (new SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.KOREA)).format(new Date()).toString();
		started_at = Calendar.getInstance();
	}
	
	public InetAddress getInetAddress() {
		return socket.getInetAddress();
	}
	
	public void send(String message) {
		writer.println(message);
		//System.out.println(message);
		try {
			sleep(50);
		}
		catch (Exception ex) {
			ex.printStackTrace();
		}
	}
	
	public void setClientName(String name) {
		this.name = name;
	}
	
	public String getClientName() {
		return name;
	}
	
	public String getTaskId() {
		return String.format("Current Task: %d", task_id);
	}
	
	public String getTaskCount() {
		return String.format("Contribution: %d", count);
	}
	
	public void run() {
		try {
			reader = new BufferedReader(new InputStreamReader(socket.getInputStream()));
			writer = new PrintWriter(socket.getOutputStream(), true);
			send("START " + name);
			
			while (true) {
				String message = reader.readLine();
				process(message);
			}
		}
		catch(Exception ex) {
			ex.printStackTrace();
			System.out.println(name + " removed!");
			server.removeClient(this);
		}
		finally {
			try {
				socket.close();
			}
			catch (Exception ex) {
				ex.printStackTrace();
			}
		}
	}
	
	public boolean process(String message) {
		String[] tokens = message.split(" ");
		String command = tokens[0];
		
		switch (command) {
		case "DBINFO":
			return sendDatabaseInformation(tokens);
		case "FILE":
			return sendFile(tokens);
		case "PARAMETERS":
			return sendParameters(tokens);
		case "REPORTERS":
			return sendReporters(tokens);
		case "ITERATION":
			return sendIteration(tokens);
		case "GETTASK":
			return sendTask(tokens);
		case "FINISH":
			return sendFinish(tokens);
		default:
			return false;
		}
	}
	
	public boolean sendDatabaseInformation(String[] tokens) {
		send("DBINFO 0 " + ServerEnvironment.DBINFO.get(3));
		send("DBINFO 1 " + ServerEnvironment.DBINFO.get(4));
		send("DBINFO EOL EOL");
		return true;
	}
	
	public boolean sendFile(String[] tokens) {
		File file = new File(ServerEnvironment.FILENAME);
		if (file.exists()) {
			send("FILE NAME " + file.getName());
			send("FILE SIZE " + file.length());
			
			BufferedReader br = null;
			try {
				String line = "";
				br = new BufferedReader(new FileReader(file.getAbsolutePath()));
				for (int i = 0; (line = br.readLine()) != null; i++) {
					send("FILE " + i + " " + line);
				}
			}
			catch (Exception ex) {
				ex.printStackTrace();
			}
			finally {
				try {
					br.close();
				}
				catch (Exception ex) {
					ex.printStackTrace();
				}
			}
		}
		send("FILE EOL EOL");
		return true;
	}
	
	public boolean sendParameters(String[] tokens) {
		for (int i = 0; i < ServerEnvironment.PARAMETERS.size(); i++) {
			send("PARAMETERS " + ServerEnvironment.PARAMETERS.get(i) + " " + ServerEnvironment.P_TYPES.get(i));
		}
		send("PARAMETERS EOL EOL");
		return true;
	}
	
	public boolean sendReporters(String[] tokens) {
		for (int i = 0; i < ServerEnvironment.REPORTERS.size(); i++) {
			send("REPORTERS " + ServerEnvironment.REPORTERS.get(i) + " " + ServerEnvironment.R_TYPES.get(i));
		}
		send("REPORTERS EOL EOL");
		return true;
	}
	
	public boolean sendIteration(String[] tokens) {
		send("ITERATION " + ServerEnvironment.iteration);
		send("ITERATION EOL");
		return true;
	}
	
	public boolean sendTask(String[] tokens) {
		ArrayList<String> task = retrieveTask();
		if (task.size() != ServerEnvironment.PARAMETERS.size() + 1) {
			if (task.size() == 0) send("ASSIGN -1 -1 -1");
			return false;
		}
		
		task_id = Integer.parseInt(task.get(task.size() - 1));
		if (task_id > 0) {
			send("ASSIGN " + task_id + " " + task_id + " " + task_id);
			for (int i = 0; i < ServerEnvironment.PARAMETERS.size(); i++) {
				send("ASSIGN " + task_id + " " + ServerEnvironment.PARAMETERS.get(i) + " " + task.get(i));				
			}
		}
		send("ASSIGN " + task_id + " EOL EOL");
		updateTaskAssigned(task_id);
		task.clear();
		
		return true;
	}
	
	public boolean sendFinish(String[] tokens) {
		String sql = "";
		for (int i = 2; i < tokens.length; i++) {
			sql += tokens[i];
			if (i != tokens.length - 1) sql += " "; 
		}
		updateData(sql);
		
		int task_id = Integer.parseInt(tokens[1]);
		send("FINISH " + task_id);
		updateTaskDone(task_id);
		
		server.refresh(this);

		return true;
	}

	public ArrayList<String> retrieveTask() {
		int task_id = 0;
		ArrayList<String> values = new ArrayList<String>();
		String sql = String.format("SELECT * FROM %s WHERE task_assigned<%d LIMIT 0, 1", ServerEnvironment.DBINFO.get(3), ServerEnvironment.repetition);
		try {
			ResultSet rs = db.query(sql);
			if (rs.next()) {
				for (int i = 0; i < ServerEnvironment.PARAMETERS.size(); i++) {
					String parameter = ServerEnvironment.PARAMETERS.get(i);
					String type = ServerEnvironment.P_TYPES.get(i);
					switch (type) {
					case "int":
						values.add(String.format("%d", rs.getInt(parameter)));
						break;
					case "float":
						values.add(String.format("%f", rs.getFloat(parameter)));
						break;
					case "String":
						values.add(String.format("%s", rs.getString(parameter)));
						break;
					}
				}
				task_id = rs.getInt("task_id");
				values.add(String.format("%d", task_id));
			}
		}
		catch (SQLException ex) {
			ex.printStackTrace();
			task_id = 0;
			values.clear();
		}
		
		return values;
	}
	
	public void updateTaskAssigned(int task_id) {
		String sql = String.format("UPDATE %s SET task_assigned=task_assigned+1 WHERE task_id=%d", ServerEnvironment.DBINFO.get(3), task_id);
		try {
			db.execute(sql);
		}
		catch (SQLException ex) {
			ex.printStackTrace();
		}
		count++;
	}
	
	public void updateTaskDone(int task_id) {
		String sql = String.format("UPDATE %s SET task_done=task_done+1 WHERE task_id=%d", ServerEnvironment.DBINFO.get(3), task_id);
		try {
			db.execute(sql);
		}
		catch (SQLException ex) {
			ex.printStackTrace();
		}
		System.out.println("updateTaskDone: " + sql);
	}
	
	public void updateData(String sql) {
		try {
			db.execute(sql);
		}
		catch (SQLException ex) {
			ex.printStackTrace();
		}
	}
	
	public String getConnectionTime() {
		return "Connection Time: " + (new SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.KOREA)).format(started_at.getTime()).toString();
	}
	
	public String getRunningTime() {
		return "Duration : " + ((Calendar.getInstance().getTimeInMillis() - started_at.getTimeInMillis()) / 1000) + " sec";
	}
	
	@Override
	public String toString() {
		return getClientName() + this.getInetAddress().toString();
		//return getClientName() + ":" + task_id + " (" + count + ")";
	}
	
	@Override
	public boolean equals(Object other) {
		ServerSocketThread thread = (ServerSocketThread)other;
		if (this.toString().equals(thread.toString())) return true;
		return false;
	}
}

