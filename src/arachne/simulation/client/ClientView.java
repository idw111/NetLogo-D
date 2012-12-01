package arachne.simulation.client;

import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.widgets.*;
import org.eclipse.swt.*;
import arachne.simulation.UICommand;
import arachne.simulation.UICommands;

public class ClientView {
	
	static Display display = null;
	static Shell shell = null;
	static Text address = null;
	static Button connect = null;
	static Text console = null;
	static ProgressBar bar = null;
	
	static NetlogoApplication netlogo = null;
	static NetlogoClient client = null;
	
	public static void createNetlogoInstance(String filepath) {
		if (netlogo == null) {
			String[] args = {};
			netlogo = new NetlogoApplication(args, filepath);
		}
	}
	
	public static NetlogoApplication getNetlogoInstance() {
		return netlogo;
	}
	
	public static NetlogoClient getClientInstance() {
		if (client == null) {
			client = new NetlogoClient();
		}
		return client;
	}
	
	public static String getIpAddress() {
		if (address.getText().split(":").length == 2) {
			return address.getText().split(":")[0];			
		}
		else {
			return address.getText();
		}
	}
	
	public static int getPort() {
		if (address.getText().split(":").length == 2) {
			return Integer.parseInt(address.getText().split(":")[1]);			
		}
		else {
			return 5420;
		}
	}
	
	public static void main(String[] args) {
		Context.read();
		
		createView();
	}
	
	private static void updateView() {
		while (UICommands.size("PROGRESS") > 0) {
			ClientView.updateProgressCommand();
		}
		while (UICommands.size("CONSOLE") > 0) {
			ClientView.updateConsoleCommand();
		}
		while (UICommands.size("CONNECT") > 0) {
			ClientView.updateConnectCommand();
		}
	}
	
	private static void updateProgressCommand() {
		UICommand task = UICommands.pop("PROGRESS");
		
		if (task == null) return;
		
		int value = (int)task.data;
		
		switch (task.command) {
		case "SET":
			bar.setSelection(value);
			break;
		}
	}
	
	private static void updateConsoleCommand() {
		UICommand task = UICommands.pop("CONSOLE");
		
		if (task == null) return;
		
		if (console.getLineCount() > 100) {
			console.setText("");
		}
		
		String log = (String)task.data;
		
		switch (task.command) {
		case "SET":
			console.append(log);
			break;
		}
	}
	
	private static void updateConnectCommand() {
		UICommand task = UICommands.pop("CONNECT");
		
		if (task == null) return;
		
		boolean value = (boolean)task.data;
		
		switch (task.command) {
		case "ENABLE":
			connect.setEnabled(value);
			break;
		}
	}
	
	public static void createView() {
		display = new Display();
		shell = new Shell(display);
		
		GridLayout layout = new GridLayout();
		layout.numColumns = 3;
		layout.makeColumnsEqualWidth = false;
		shell.setLayout(layout);
		shell.setText("NetLogo-D client");
		
		Label label = new Label(shell, SWT.NONE);
		label.setText("IP Address");
		label.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_BEGINNING, GridData.VERTICAL_ALIGN_BEGINNING, false, false, 1, 1));
		
		address = new Text(shell, SWT.BORDER);
		address.setText(Context.ip);
		address.setLayoutData(new GridData(GridData.FILL, GridData.VERTICAL_ALIGN_BEGINNING, true, false, 1, 1));
		
		connect = new Button(shell, SWT.PUSH);
		connect.setText("Connect");
		connect.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END, GridData.VERTICAL_ALIGN_BEGINNING, false, false, 1, 1));
		connect.addListener(SWT.Selection, new Listener() {
			public void handleEvent(Event e) {
				if (e.type != SWT.Selection) return;
				String ip = ClientView.getIpAddress();
				int port = ClientView.getPort();
				ClientView.getClientInstance().connect(ip, port);
				ClientView.connect.setEnabled(false);
			}
		});
		
		console = new Text(shell, SWT.WRAP|SWT.MULTI|SWT.BORDER|SWT.SCROLLBAR_OVERLAY|SWT.V_SCROLL|SWT.READ_ONLY);
		console.setLayoutData(new GridData(GridData.FILL, GridData.FILL, true, true, 3, 1));
		console.setBackground(display.getSystemColor(SWT.COLOR_BLACK));
		console.setForeground(display.getSystemColor(SWT.COLOR_WHITE));
		
		bar = new ProgressBar(shell, SWT.SMOOTH);
		bar.setLayoutData(new GridData(GridData.FILL, GridData.VERTICAL_ALIGN_BEGINNING, true, false, 3, 1));
		bar.setMaximum(100);
		bar.setSelection(0);
		
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
							ClientView.updateView();
						}
					});
				}
			}
		}.start();		
		
		shell.setSize(600, 600);
		shell.open();
		while (!shell.isDisposed()) {
			if (!display.readAndDispatch()) display.sleep();
		}
		display.dispose();
		System.exit(0);
	}

}
