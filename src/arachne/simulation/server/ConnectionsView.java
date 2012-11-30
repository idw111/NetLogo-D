package arachne.simulation.server;

import org.eclipse.swt.SWT;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Group;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.Tree;
import org.eclipse.swt.widgets.TreeItem;
import arachne.simulation.UICommand;
import arachne.simulation.UICommands;

public class ConnectionsView extends Composite {
	static Tree connections = null;
	static TreeItem root = null;
	static Label console = null;
	
	public ConnectionsView(Composite c) {
		super(c, SWT.NONE);
	    GridLayout layout = new GridLayout();
	    layout.numColumns = 6;
	    layout.makeColumnsEqualWidth = true;
	    this.setLayout(layout);
	    
	    createTree();
	    createConsole();		
	}
	
	private void createTree() {
	    GridLayout layout = new GridLayout();
	    layout.numColumns = 6;
	    layout.makeColumnsEqualWidth = true;
	    
	    Group group = new Group(this, SWT.NONE);
	    group.setLayout(layout);
	    group.setLayoutData(new GridData(GridData.FILL, GridData.FILL, true, true, 6, 1));
	    
		connections = new Tree(group, SWT.SINGLE);
		connections.setLayoutData(new GridData(GridData.FILL, GridData.FILL, true, true, 6, 1));
		
		root = new TreeItem(connections, SWT.NONE);
		root.setText("Clients");
	}
	
	private void createConsole() {
	    GridLayout layout = new GridLayout();
	    layout.numColumns = 6;
	    layout.makeColumnsEqualWidth = true;
		
	    console = new Label(this, SWT.NONE);
	    console.setLayoutData(new GridData(GridData.FILL, GridData.VERTICAL_ALIGN_BEGINNING, true, false, 6, 1));
	    console.setAlignment(SWT.RIGHT);
	    console.setText("NetLogo-D enables NetLogo users to conduct simulations in a distributed manner!");
	}
	
	public static void updateView() {
		while (UICommands.size("CONNECTIONS") > 0) {
			ConnectionsView.updateTreeCommand();
		}
		while (UICommands.size("CONSOLE") > 0) {
			ConnectionsView.updateConsoleCommand();
		}
	}
	
	public static void updateConsoleCommand() {
		UICommand task = UICommands.pop("CONSOLE");
		
		if (task == null) return;
		
		String message = (String)task.data;
		
		switch (task.command) {
		case "SET":
			console.setForeground(Display.getCurrent().getSystemColor(SWT.COLOR_BLACK));
			console.setText(message);
			break;
		case "WARN":
			console.setForeground(Display.getCurrent().getSystemColor(SWT.COLOR_RED));
			console.setText(message);
			break;
		}
	}
	
	public static void updateTreeCommand() {
		UICommand task = UICommands.pop("CONNECTIONS");
		
		if (task == null) return;
		
		ServerSocketThread client = (ServerSocketThread)task.data;
		
		switch (task.command) {
		case "ADD":
			addClient(client);
			break;
		case "REMOVE":
			removeClient(client);
			break;
		case "REFRESH":
			refreshClient(client);
			break;
		}
	}
	
	public static void addClient(ServerSocketThread thread) {
		if (root == null) return;
		
		TreeItem item = addChild(root, thread.toString());
		addChild(item, thread.getConnectionTime());
		addChild(item, thread.getRunningTime());
		addChild(item, thread.getTaskCount());
		
		item.setData(thread);
	}
	
	public static void removeClient(ServerSocketThread thread) {
		if (connections == null || root == null) return;
		
		removeItem(thread.toString());
	}
	
	public static void refreshClient(ServerSocketThread thread) {
		if (connections == null || root == null) return;
		
		for (int i = 0; i < root.getItemCount(); i++) {
			TreeItem item = root.getItem(i);
			ServerSocketThread client = (ServerSocketThread)item.getData();
			if (client.getClientName().equals(thread.getClientName())) {
				ConnectionsView.refreshItem(item);
			}
		}
	}
	
	private static void refreshItem(TreeItem item) {
		if (item == null || item.getData() == null) return;
		
		ServerSocketThread thread = (ServerSocketThread)item.getData();
		if (item.getItemCount() == 3) {
			item.getItem(1).setText(thread.getRunningTime());
			item.getItem(2).setText(thread.getTaskCount());
		}
	}
	
	private static TreeItem addChild(TreeItem parent, String name) {
		if (connections == null || root == null) return null;
		
		TreeItem item = null;
		if (parent == null) {
			item = new TreeItem(connections, SWT.NONE);
		}
		else {
			item = new TreeItem(parent, SWT.NONE);
		}
		item.setText(name);
		
		return item;
	}
	
	private static boolean removeItem(String name) {
		if (connections == null) return false;
		
		TreeItem item = getItem(name);
		if (item != null) item.dispose();
		
		return true;
	}
	
	private static TreeItem getItem(String name) {
		TreeItem[] items = root.getItems();
		for (int i = 0; i < items.length; i++) {
			if (items[i].getText().equals(name)) return items[i];
		}
		return null;
	}
}
