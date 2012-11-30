package arachne.simulation.client;

import org.nlogo.app.App;
import org.nlogo.headless.HeadlessWorkspace;

public class NetlogoApplication extends Thread {
	HeadlessWorkspace workspace;
	
	public NetlogoApplication(String[] args, String path) {
		App.main(args);
		workspace = HeadlessWorkspace.newInstance();
		try {
			workspace.open(path);
		}
		catch (Exception ex) {
			ex.printStackTrace();
		}
	}
	
	public void command(String message) {
		try {
			workspace.command(message);
		}
		catch (Exception ex) {
			ex.printStackTrace();
		}
	}
	
	public String report(String message) {
		String value = "";
		try {
			value = workspace.report(message).toString();
		}
		catch (Exception ex) {
			ex.printStackTrace();
			value = "";
		}
		return value;
	}

}
