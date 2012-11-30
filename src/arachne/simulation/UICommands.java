package arachne.simulation;

import java.util.ArrayList;

public class UICommands {
	public static ArrayList<UICommand> commands = new ArrayList<UICommand>();

	public UICommands() {
	}
	
	public static void add(String target, String command, Object data) {
		commands.add(new UICommand(target, command, data));
	}
	
	public static UICommand pop(String target) {
		for (int i = 0; i < commands.size(); i++) {
			if (commands.get(i).target.equals(target)) return commands.remove(i); 
		}
		return null;
	}
	
	public static int size(String target) {
		int value = 0;
		for (int i = 0; i < commands.size(); i++) {
			if (commands.get(i).target.equals(target)) value++; 
		}
		return value;
	}
}
