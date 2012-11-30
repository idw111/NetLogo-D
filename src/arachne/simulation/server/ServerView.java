package arachne.simulation.server;

import org.eclipse.swt.SWT;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.TabFolder;
import org.eclipse.swt.widgets.TabItem;
import org.eclipse.swt.widgets.Table;
import org.eclipse.swt.widgets.Tree;

public class ServerView {
	static Display display = null;
	static Shell shell = null;
	static NetlogoServer server = null;
	static Tree connections = null;
	static Table settings = null;
	
	public static NetlogoServer getServerInstance() {
		return server;
	}
	
	public static void main(String[] args) {
		ServerEnvironment.read();
		ServerEnvironment.createTaskTable();
		ServerEnvironment.createDataTable();
		
		server = new NetlogoServer();
		Thread thread = new Thread((Runnable)server);
		thread.start();
		
		createView();
	}
	
	public static void createView() {
		display = new Display();
		shell = new Shell(display);
		
		GridLayout layout = new GridLayout();
		layout.numColumns = 3;
		layout.makeColumnsEqualWidth = false;
		shell.setLayout(layout);
		shell.setText("NetLogo-D server");
		
		// tab folder
		TabFolder tabs = new TabFolder(shell, SWT.NONE);
		tabs.setLayoutData(new GridData(GridData.FILL, GridData.FILL, true, true, 3, 1));
		
		// tab #1
		TabItem tab_connections = new TabItem(tabs, SWT.NULL);
		tab_connections.setText("Connections");
		tab_connections.setControl(new ConnectionsView(tabs));
		
		// tab #2
		TabItem tab_settings = new TabItem(tabs, SWT.NULL);
		tab_settings.setText("Settings");
		tab_settings.setControl(new SettingsView(tabs));
		
		new Thread() {
			public void run() {
				while (true) {
					try {
						Thread.sleep(1000);
					}
					catch (Exception ex) {
						ex.printStackTrace();
					}
					
					if (display.isDisposed()) return;
					display.asyncExec(new Runnable() {
						public void run() {
							ConnectionsView.updateView();
						}
					});
				}
			}
		}.start();
		
		shell.setSize(900, 600);
		shell.open();
		while (!shell.isDisposed()) {
			if (!display.readAndDispatch()) {
				display.sleep();
			}
		}
		display.dispose();
		System.exit(0);
	}
}
