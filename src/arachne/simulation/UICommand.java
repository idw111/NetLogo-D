package arachne.simulation;

public class UICommand {
	public String target = "";
	public String command = "";
	public Object data = null;
	
	public UICommand(String t, String c, Object d) {
		target = t;
		command = c;
		data = d;
	}
}
