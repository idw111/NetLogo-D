package arachne.simulation.client;

import java.io.*;
import java.net.*;
import java.text.SimpleDateFormat;
import java.util.Locale;
import arachne.simulation.UICommands;

public class NetlogoClient implements Runnable {
	String name;
	Socket socket;
	PrintWriter writer;
	BufferedReader reader;
	String input;
	FileWriter netlogo_file = null;
	boolean file_download = false;
	int progress = 0;
	
	NetlogoApplication application;
	SimpleDateFormat date;
	
	public NetlogoClient() {
		date = new SimpleDateFormat("HH:mm:ss", Locale.KOREA);
	}
	
	public void run() {
		try {
			while ((input = reader.readLine()) != null) {
				process(input);
			}
		}
		catch (Exception ex) {
			echo("Connection lost...");
			UICommands.add("CONNECT", "ENABLE", true);
			ex.printStackTrace();
		}
		finally {
			try {
				socket.close();
			}
			catch (Exception ex) {
				ex.getMessage();
			}
		}
	}
	
	public boolean process(String message) {
		String[] tokens = message.split(" ");
		String command = tokens[0];
		
		//echo(message);
		
		switch (command) {
		case "START":
			return processStart(tokens);
		case "DBINFO":
			return processDatabaseInformation(tokens);
		case "FILE":
			return processFile(tokens, message);
		case "PARAMETERS":
			return processParameters(tokens); 
		case "REPORTERS":
			return processReporters(tokens);
		case "ITERATION":
			return processIteration(tokens);
		case "ASSIGN":
			return processAssign(tokens);
		case "FINISH":
			return processFinish(tokens);
		default:
			echo("Unhandled Message!");
			return false;
		}
	}
	
	public boolean processStart(String[] tokens) {
		if (tokens.length != 2) return false;
		
		echo("Connection established...");

		name = tokens[1];
		send("DBINFO");
		return true;
	}
	
	public boolean processDatabaseInformation(String[] tokens) {
		if (tokens.length != 3) return false;
		
		if (Context.DBINFO.size() <= 0) echo("Getting database information...");
		
		String value = tokens[2];
		
		if (!value.equals("EOL")) Context.DBINFO.add(value);
		else send("FILE");

		return true;
	}
	
	public boolean processFile(String[] tokens, String message) {
		String key = tokens[1];
		
		if (!key.equals("EOL")) {
			if (!Context.filename.equals("") && Context.filesize > 0) {
				if (netlogo_file == null && !file_download) {
					try {
						netlogo_file = new FileWriter(Context.filename);
					}
					catch (Exception ex) {
						ex.printStackTrace();
					}
				}
				
				try {
					String line = "";
					for (int i = 2; i < tokens.length; i++) {
						line += tokens[i];
						if (i != tokens.length - 1) line += " ";
					}
					line += "\n";
					netlogo_file.write(line);
					progress += line.length();
					UICommands.add("PROGRESS", "SET", Math.min((int)(100 * progress / Context.filesize), 100));
				}
				catch (Exception ex) {
					ex.printStackTrace();
				}
			}
			
			switch (key) {
			case "NAME":
				//Context.filename = tokens[2];
				int r = (int)(Math.random() * Integer.MAX_VALUE);
				Context.filename = String.format("%s/%06x.nlogo", "netlogo", r);
				File dir = new File("netlogo");
				if (!dir.exists()) {
					dir.mkdir();
				}
				
				echo("Downloading netlogo file: " + Context.filename);
				
				break;
			case "SIZE":
				Context.filesize = Integer.parseInt(tokens[2]);
				break;
			}
		}
		else {
			if (netlogo_file != null) {
				try {
					file_download = true;
					netlogo_file.close();
					UICommands.add("PROGRESS", "SET", 100);
					System.out.println("file created");
					
					application = new NetlogoApplication(new String[] {}, Context.filename);
				}
				catch (Exception ex) {
					ex.printStackTrace();
				}
			}
			send("PARAMETERS");
		}
		
		return true;
	}
	
	public boolean processParameters(String[] tokens) {
		if (Context.PARAMETERS.size() <= 0) echo("Getting parameters...");
		
		String value = tokens[1];
		String type = tokens[2];
		
		if (!value.equals("EOL")) {
			Context.PARAMETERS.add(value);
			Context.P_TYPES.add(type);
		}
		else send("REPORTERS");
		
		return true;
	}
	
	public boolean processReporters(String[] tokens) {
		if (Context.REPORTERS.size() <= 0) echo("Getting reporters...");

		String value = tokens[1];
		String type = tokens[2];
		
		if (!value.equals("EOL")) {
			Context.REPORTERS.add(value);
			Context.R_TYPES.add(type);
		}
		else send("ITERATION");
		
		return true;
	}
	
	public boolean processIteration(String[] tokens) {
		String value = tokens[1];
		
		if (!value.equals("EOL")) {
			echo("Getting iteration...");
			
			Context.iteration = Integer.parseInt(value);
		}
		else send("GETTASK");
		return true;
	}

	public boolean processAssign(String[] tokens) {
		String task_id = tokens[1];
		String parameter = tokens[2];
		String value = tokens[3];
		
		if (task_id.equals(parameter) && task_id.equals(value)) {
			int _task = Integer.parseInt(task_id);
			
			if (_task >= 0) {
				Context.task_id = task_id;
				echo("Task " + task_id + " is assigned");
			}
			else {
				echo("All tasks are finished.");
			}
		}
		else if (task_id.equals(Context.task_id)) {
			if (!parameter.equals("EOL")) {
				String command = "";
				if (value.matches("((-|\\+)?[0-9]+(\\.[0-9]+)?)+")) {
					command = String.format("set %s %s", parameter, value);
				}
				else {
					command = String.format("set %s \"%s\"", parameter, value);
				}
				application.command(command);
			}
			else {
				application.command("setup");
				application.command("repeat " + Context.iteration + " [go]");

				String fields = "task_id";
				String values = Context.task_id;
				for (int i = 0; i < Context.REPORTERS.size(); i++) {
					fields += ", " + Context.REPORTERS.get(i);
					switch (Context.R_TYPES.get(i)) {
					case "int":
					case "float":
						values += ", " + application.report(Context.REPORTERS.get(i)) + "";
						break;
					case "String":
						values += ", '" + application.report(Context.REPORTERS.get(i)) + "'";
						break;
					}
				}
				String sql = "INSERT INTO " + Context.DBINFO.get(1) + " (" + fields + ") VALUES (" + values + ")";
				send("FINISH " + Context.task_id + " " + sql);
			}
		}

		return true;
	}
	
	public boolean processFinish(String[] tokens) {
		if (Context.task_id.equals(tokens[1])) {
			echo("Task " + Context.task_id + " finished...");

			Context.task_id = "0";			
			send("GETTASK");
			return true;
		}
		return false;
	}

	public void send(String message) {
		writer.println(message);
		//echo(message);
	}
	
	public void echo(String message) {
		UICommands.add("CONSOLE", "SET", message + "\n");
	}
	
	public boolean connect(String ip, int port) {
		try {
			System.out.println(ip + ", " + port);
			socket = new Socket(ip, port);
		}
		catch (Exception ex) {
			ex.printStackTrace();
			echo("Failed to connect to the server...");
			UICommands.add("CONNECT", "ENABLE", true);
			return false;
		}
		
		try {
			writer = new PrintWriter(socket.getOutputStream(), true);
			reader = new BufferedReader(new InputStreamReader(socket.getInputStream()));
			Thread thread = new Thread(this);
			thread.start();
		}
		catch (Exception ex) {
			ex.printStackTrace();
			return false;
		}
		
		return true;
	}	
}
