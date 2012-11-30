package arachne.simulation.client;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.util.*;

public class Context {
	
	public static ArrayList<String> DBINFO = new ArrayList<String>();
	public static ArrayList<String> PARAMETERS = new ArrayList<String>();
	public static ArrayList<String> P_TYPES = new ArrayList<String>();
	public static ArrayList<String> REPORTERS = new ArrayList<String>();
	public static ArrayList<String> R_TYPES = new ArrayList<String>();
	public static int iteration = 1;
	public static String ip = "";
	public static String task_id = "0";
	public static String filename = "";
	public static int filesize = 0;
	
	public Context() {
	}
	
	public static String read() {
		try {
			BufferedReader file = new BufferedReader(new FileReader("client.conf"));
			String line = "";
			while ((line = file.readLine()) != null) {
				String[] tokens = line.split(" ");
				String command = tokens[0];
				switch (command) {
				case "IP":
					Context.ip = tokens[1];
					System.out.println(Context.ip);
					break;
				case "FILENAME":
					Context.filename = tokens[1];
					System.out.println(Context.filename);
					break;
				}
			}
			file.close();
		}
		catch (IOException ex) {
			ex.printStackTrace();
		}	
		
		return Context.ip;
	}
	
	public static void write(String ip, String file) {
		
	}	
}
