package arachne.simulation.server;

import java.net.*;
import java.util.*;
import arachne.simulation.UICommands;

public class NetlogoServer implements Runnable {
	
	ServerSocket server_socket = null;
	Socket socket = null;
	Vector<ServerSocketThread> clients;
	static int id = 0;
	
	public NetlogoServer() {
		clients = new Vector<ServerSocketThread>(10, 10);
	}
	
	public void listen() {
		try {
			server_socket = new ServerSocket(5420);
			server_socket.getReuseAddress();
			while (true) {
				socket = server_socket.accept();
				ServerSocketThread server_thread = new ServerSocketThread(this, socket);
				String name = getId();
				server_thread.setClientName(name);
				server_thread.start();
				addClient(server_thread);
			}
		}
		catch (Exception ex) {
			ex.printStackTrace();
		}
	}
	
	public static String getId() {
		return String.format("Client%03d", ++id);
	}
	
	public void addClient(ServerSocketThread thread) {
		clients.addElement(thread);
		UICommands.add("CONNECTIONS", "ADD", thread);
	}
	
	public void removeClient(ServerSocketThread thread) {
		clients.removeElement(thread);
		UICommands.add("CONNECTIONS", "REMOVE", thread);
		System.out.println("NetlogoServer.removeClient");
	}
	
	public void refresh(ServerSocketThread thread) {
		UICommands.add("CONNECTIONS", "REFRESH", thread);
	}
	
	public void sendMessage(ServerSocketThread thread, String message) {
		thread.send(message);
	}
	
	public static void echo(String message) {
		UICommands.add("CONSOLE", "SET", message);
	}
	
	public static void warn(String message) {
		UICommands.add("CONSOLE", "WARN", message);
	}

	@Override
	public void run() {
		this.listen();
	}
}
