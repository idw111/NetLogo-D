package arachne.simulation.server;

import java.io.FileWriter;
import java.io.IOException;
import org.eclipse.swt.SWT;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.widgets.Combo;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.widgets.FileDialog;
import org.eclipse.swt.widgets.Group;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.Listener;
import org.eclipse.swt.widgets.Table;
import org.eclipse.swt.widgets.TableColumn;
import org.eclipse.swt.widgets.TableItem;
import org.eclipse.swt.widgets.Text;

public class SettingsView extends Composite {
	static Text[] dbinfo = null;
	static Table params = null;
	static Text param = null;
	static Combo ptype = null;
	static Table reporters = null;
	static Text reporter = null;
	static Combo rtype = null;
	static FileDialog files = null;
	static Text netlogo_file = null;
	static Text netlogo_iteration = null;
	static Text netlogo_repetition = null;
	
	public SettingsView(Composite c) {
		super(c, SWT.NONE);
	    GridLayout layout = new GridLayout();
	    layout.numColumns = 6;
	    layout.makeColumnsEqualWidth = true;
	    this.setLayout(layout);
	    
	    createEtc();
	    createDbinfo();
	    createParams();
	    createReporters();
	    
	    fill();
	    
	    Label l1 = new Label(this, SWT.NONE);
	    l1.setLayoutData(new GridData(GridData.FILL, GridData.VERTICAL_ALIGN_BEGINNING, true, false, 5, 1));
	    
	    Button store = new Button(this, SWT.PUSH);
	    store.setLayoutData(new GridData(GridData.FILL, GridData.VERTICAL_ALIGN_BEGINNING, true, false, 1, 1));
	    store.setText("Store");
	    store.addListener(SWT.Selection, new Listener() {
			public void handleEvent(Event e) {
				if (e.type != SWT.Selection) return;
				
				Button button = (Button)e.widget;
				button.setEnabled(false);
				
				// write server.conf file
				FileWriter file = null;
				try {
					file = new FileWriter("server.conf");
					
					// DBINFO
					for (int i = 0; i < dbinfo.length; i++) {
						file.write("DBINFO " + i + " " + dbinfo[i].getText() + "\n");
					}
					file.write("\n");
					
					// FILEPATH
					file.write("FILENAME " + netlogo_file.getText() + "\n");
					file.write("\n");
					
					// PARAMETERS
					for (int i = 0; i < params.getItemCount(); i++) {
						TableItem item = params.getItem(i);
						file.write("PARAMETERS " + item.getText(0) + " " + item.getText(1) + "\n");
					}
					file.write("\n");
					
					// REPORTERS
					for (int i = 0; i < reporters.getItemCount(); i++) {
						TableItem item = reporters.getItem(i);
						file.write("REPORTERS " + item.getText(0) + " " + item.getText(1) + "\n");
					}
					file.write("\n");
					
					// ITERATION
					file.write("ITERATION " + netlogo_iteration.getText() + "\n");
					file.write("\n");
					
					// REPETITION
					file.write("REPETITION " + netlogo_repetition.getText() + "\n");
					file.write("\n");
					
					file.close();
				}
				catch (IOException ex) {
					ex.printStackTrace();
				}
				finally {
					try {
						if (file != null) file.close();
					}
					catch (IOException ex) {
						ex.printStackTrace();
					}
				}
				
				ServerEnvironment.read();
				SettingsView.fill();
				
				ServerEnvironment.createDatabase();
				ServerEnvironment.createTaskTable();
				ServerEnvironment.createDataTable();
				
				button.setEnabled(true);
			}
		});
	}
	
	public static String getFilePath() {
		return netlogo_file.getText();
	}
	
	private static void fill() {
		netlogo_file.setText(ServerEnvironment.FILENAME);
	    netlogo_iteration.setText(Integer.toString(ServerEnvironment.iteration));
	    netlogo_repetition.setText(Integer.toString(ServerEnvironment.repetition));

	    for (int i = 0; i < dbinfo.length && i < ServerEnvironment.DBINFO.size(); i++) {
	    	dbinfo[i].setText(ServerEnvironment.DBINFO.get(i));
	    }
	    
	    params.removeAll();
	    for (int i = 0; i < ServerEnvironment.PARAMETERS.size(); i++) {
	    	TableItem item = new TableItem(SettingsView.params, SWT.NONE);
	    	item.setText(0, ServerEnvironment.PARAMETERS.get(i));
	    	item.setText(1, ServerEnvironment.P_TYPES.get(i));
	    }
	    
	    reporters.removeAll();
	    for (int i = 0; i < ServerEnvironment.REPORTERS.size(); i++) {
	    	TableItem item = new TableItem(SettingsView.reporters, SWT.NONE);
	    	item.setText(0, ServerEnvironment.REPORTERS.get(i));
	    	item.setText(1, ServerEnvironment.R_TYPES.get(i));
	    }
	}
	
	private void createEtc() {
	    GridLayout layout = new GridLayout();
	    layout.numColumns = 3;
	    layout.makeColumnsEqualWidth = false;
	    
	    Group group = new Group(this, SWT.NONE);
	    group.setLayout(layout);
	    group.setLayoutData(new GridData(GridData.FILL, GridData.FILL, true, false, 3, 1));
	    
	    // file browser
	    files = new FileDialog(this.getShell(), SWT.NONE);
	    files.setFilterExtensions(new String[] {"*.nlogo"});
	    
	    Label l1 = new Label(group, SWT.NONE);
	    l1.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_BEGINNING, GridData.VERTICAL_ALIGN_BEGINNING, false, false, 1, 1));
	    l1.setText("Netlogo file");
	    
	    netlogo_file = new Text(group, SWT.BORDER|SWT.READ_ONLY);
	    netlogo_file.setLayoutData(new GridData(GridData.FILL, GridData.VERTICAL_ALIGN_BEGINNING, true, false, 1, 1));

	    Button browse = new Button(group, SWT.PUSH);
	    browse.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_BEGINNING, GridData.VERTICAL_ALIGN_BEGINNING, false, false, 1, 1));
	    browse.setText("Browse");
	    browse.addListener(SWT.Selection, new Listener() {
			public void handleEvent(Event e) {
				if (e.type != SWT.Selection) return;
				String path = SettingsView.files.open();
				if (path != null) SettingsView.netlogo_file.setText(path);
			}
		});
	    
	    // simulation iteration
	    Label l2 = new Label(group, SWT.NONE);
	    l2.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_BEGINNING, GridData.VERTICAL_ALIGN_BEGINNING, false, false, 1, 1));
	    l2.setText("Simulation iteration");
	    
	    netlogo_iteration = new Text(group, SWT.BORDER);
	    netlogo_iteration.setLayoutData(new GridData(GridData.FILL, GridData.VERTICAL_ALIGN_BEGINNING, true, false, 2, 1));
	    
	    // simulation repetition
	    Label l3 = new Label(group, SWT.NONE);
	    l3.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_BEGINNING, GridData.VERTICAL_ALIGN_BEGINNING, false, false, 1, 1));
	    l3.setText("Simulation repetition");
	    
	    netlogo_repetition = new Text(group, SWT.BORDER);
	    netlogo_repetition.setLayoutData(new GridData(GridData.FILL, GridData.VERTICAL_ALIGN_BEGINNING, true, false, 2, 1));
	}
	
	private void createDbinfo() {
	    dbinfo = new Text[6];
	    
	    GridLayout layout = new GridLayout();
	    layout.numColumns = 3;
	    layout.makeColumnsEqualWidth = false;
	    
	    Group group = new Group(this, SWT.NONE);
	    group.setLayout(layout);
	    group.setLayoutData(new GridData(GridData.FILL, GridData.FILL, true, false, 3, 1));
	    
	    Label l0 = new Label(group, SWT.NONE);
	    l0.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_BEGINNING, GridData.VERTICAL_ALIGN_BEGINNING, false, false, 1, 1));
	    l0.setText("MySQL connection");
	    
	    dbinfo[0] = new Text(group, SWT.SINGLE|SWT.BORDER);
	    dbinfo[0].setLayoutData(new GridData(GridData.FILL, GridData.VERTICAL_ALIGN_BEGINNING, true, false, 2, 1));

	    Label l1 = new Label(group, SWT.NONE);
	    l1.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_BEGINNING, GridData.VERTICAL_ALIGN_BEGINNING, false, false, 1, 1));
	    l1.setText("MySQL database");
	    
	    dbinfo[1] = new Text(group, SWT.SINGLE|SWT.BORDER);
	    dbinfo[1].setLayoutData(new GridData(GridData.FILL, GridData.VERTICAL_ALIGN_BEGINNING, true, false, 2, 1));
	    
	    Label l2 = new Label(group, SWT.NONE);
	    l2.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_BEGINNING, GridData.VERTICAL_ALIGN_BEGINNING, false, false, 1, 1));
	    l2.setText("MySQL ID");

	    dbinfo[2] = new Text(group, SWT.SINGLE|SWT.BORDER);
	    dbinfo[2].setLayoutData(new GridData(GridData.FILL, GridData.VERTICAL_ALIGN_BEGINNING, true, false, 2, 1));
	    
	    Label l3 = new Label(group, SWT.NONE);
	    l3.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_BEGINNING, GridData.VERTICAL_ALIGN_BEGINNING, false, false, 1, 1));
	    l3.setText("MySQL password");

	    dbinfo[3] = new Text(group, SWT.SINGLE|SWT.BORDER);
	    dbinfo[3].setLayoutData(new GridData(GridData.FILL, GridData.VERTICAL_ALIGN_BEGINNING, true, false, 2, 1));

	    Label l4 = new Label(group, SWT.NONE);
	    l4.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_BEGINNING, GridData.VERTICAL_ALIGN_BEGINNING, false, false, 1, 1));
	    l4.setText("MySQL task table");

	    dbinfo[4] = new Text(group, SWT.SINGLE|SWT.BORDER);
	    dbinfo[4].setLayoutData(new GridData(GridData.FILL, GridData.VERTICAL_ALIGN_BEGINNING, true, false, 2, 1));

	    Label l5 = new Label(group, SWT.NONE);
	    l5.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_BEGINNING, GridData.VERTICAL_ALIGN_BEGINNING, false, false, 1, 1));
	    l5.setText("MySQL data table");

	    dbinfo[5] = new Text(group, SWT.SINGLE|SWT.BORDER);
	    dbinfo[5].setLayoutData(new GridData(GridData.FILL, GridData.VERTICAL_ALIGN_BEGINNING, true, false, 2, 1));		
	}
	
	private void createParams() {
	    GridLayout layout = new GridLayout();
	    layout.numColumns = 3;
	    layout.makeColumnsEqualWidth = true;
	    
	    Group group = new Group(this, SWT.NONE);
	    group.setLayout(layout);
	    group.setLayoutData(new GridData(GridData.FILL, GridData.FILL, true, true, 3, 1));
	    
	    params = new Table(group, SWT.BORDER);
	    params.setLayoutData(new GridData(GridData.FILL, GridData.FILL, true, true, 3, 1));
	    params.setHeaderVisible(true);
	    
	    TableColumn tc1 = new TableColumn(params, SWT.LEFT);
	    tc1.setText("Parameter");
	    tc1.setWidth(150);
	    TableColumn tc2 = new TableColumn(params, SWT.LEFT);
	    tc2.setText("Type");
	    tc2.setWidth(70);
	    TableColumn tc3 = new TableColumn(params, SWT.LEFT);
	    tc3.setText("Value");
	    tc3.setWidth(150);
	    	    
	    Label l1 = new Label(group, SWT.NONE);
	    l1.setLayoutData(new GridData(GridData.FILL, GridData.VERTICAL_ALIGN_BEGINNING, true, false, 1, 1));
	    l1.setText("Parameter");
	    
	    param = new Text(group, SWT.BORDER);
	    param.setLayoutData(new GridData(GridData.FILL, GridData.VERTICAL_ALIGN_BEGINNING, true, false, 2, 1));
	    
	    Label l2 = new Label(group, SWT.NONE);
	    l2.setLayoutData(new GridData(GridData.FILL, GridData.VERTICAL_ALIGN_BEGINNING, true, false, 1, 1));
	    l2.setText("Type");
	    
	    ptype = new Combo(group, SWT.BORDER|SWT.READ_ONLY);
	    ptype.setLayoutData(new GridData(GridData.FILL, GridData.VERTICAL_ALIGN_BEGINNING, true, false, 2, 1));
	    ptype.add("int");
	    ptype.add("float");
	    ptype.add("String");
	    ptype.select(0);
	    
	    Label l3 = new Label(group, SWT.NONE);
	    l3.setLayoutData(new GridData(GridData.FILL, GridData.VERTICAL_ALIGN_BEGINNING, true, false, 1, 1));
	    	    
	    Button insert = new Button(group, SWT.PUSH);
	    insert.setLayoutData(new GridData(GridData.FILL, GridData.VERTICAL_ALIGN_END, true, false, 1, 1));
	    insert.setText("Insert");
	    insert.addListener(SWT.Selection, new Listener() {
			public void handleEvent(Event e) {
				if (e.type != SWT.Selection) return;
				String param = SettingsView.param.getText();
				String type = SettingsView.ptype.getText();
				if (param != null && param.length() > 0 && type != null && type.length() >0) {
					TableItem item = new TableItem(SettingsView.params, SWT.NONE);
					item.setText(0, param);
					item.setText(1, type);
				}
				else {
					System.out.println("Invalid input");
				}
			}
		});
	    
	    Button remove = new Button(group, SWT.PUSH);
	    remove.setLayoutData(new GridData(GridData.FILL, GridData.VERTICAL_ALIGN_BEGINNING, true, false, 1, 1));
	    remove.setText("Remove");
	    remove.addListener(SWT.Selection, new Listener() {
			public void handleEvent(Event e) {
				if (e.type != SWT.Selection) return;
				if (SettingsView.params.getItemCount() <= 0) return;
				
				int index = SettingsView.params.getSelectionIndex();
				if (index != -1) SettingsView.params.remove(index);				
			}
		});

	}
	
	private void createReporters() {
	    GridLayout layout = new GridLayout();
	    layout.numColumns = 3;
	    layout.makeColumnsEqualWidth = true;
	    
	    Group group = new Group(this, SWT.NONE);
	    group.setLayout(layout);
	    group.setLayoutData(new GridData(GridData.FILL, GridData.FILL, true, true, 3, 1));
	    
	    reporters = new Table(group, SWT.BORDER);
	    reporters.setLayoutData(new GridData(GridData.FILL, GridData.FILL, true, true, 3, 1));
	    reporters.setHeaderVisible(true);
	    
	    TableColumn tc1 = new TableColumn(reporters, SWT.LEFT);
	    tc1.setText("Reporter");
	    tc1.setWidth(180);
	    TableColumn tc2 = new TableColumn(reporters, SWT.LEFT);
	    tc2.setText("Type");
	    tc2.setWidth(70);
	    
	    Label l1 = new Label(group, SWT.NONE);
	    l1.setLayoutData(new GridData(GridData.FILL, GridData.VERTICAL_ALIGN_BEGINNING, true, false, 1, 1));
	    l1.setText("Reporter");
	    
	    reporter = new Text(group, SWT.BORDER);
	    reporter.setLayoutData(new GridData(GridData.FILL, GridData.VERTICAL_ALIGN_BEGINNING, true, false, 2, 1));
	    
	    Label l2 = new Label(group, SWT.NONE);
	    l2.setLayoutData(new GridData(GridData.FILL, GridData.VERTICAL_ALIGN_BEGINNING, true, false, 1, 1));
	    l2.setText("Type");
	    
	    rtype = new Combo(group, SWT.BORDER|SWT.READ_ONLY);
	    rtype.setLayoutData(new GridData(GridData.FILL, GridData.VERTICAL_ALIGN_BEGINNING, true, false, 2, 1));
	    rtype.add("int");
	    rtype.add("float");
	    rtype.add("String");
	    rtype.select(0);
	    	    
	    Label l3 = new Label(group, SWT.NONE);
	    l3.setLayoutData(new GridData(GridData.FILL, GridData.VERTICAL_ALIGN_BEGINNING, true, false, 1, 1));
	    
	    Button insert = new Button(group, SWT.PUSH);
	    insert.setLayoutData(new GridData(GridData.FILL, GridData.VERTICAL_ALIGN_END, true, false, 1, 1));
	    insert.setText("Insert");
	    insert.addListener(SWT.Selection, new Listener() {
			public void handleEvent(Event e) {
				if (e.type != SWT.Selection) return;
				String param = SettingsView.reporter.getText();
				String type = SettingsView.rtype.getText();
				if (param != null && param.length() > 0 && type != null && type.length() >0) {
					TableItem item = new TableItem(SettingsView.reporters, SWT.NONE);
					item.setText(0, param);
					item.setText(1, type);
				}
				else {
					System.out.println("Invalid input");
				}
			}
		});
	    
	    Button remove = new Button(group, SWT.PUSH);
	    remove.setLayoutData(new GridData(GridData.FILL, GridData.VERTICAL_ALIGN_BEGINNING, true, false, 1, 1));
	    remove.setText("Remove");
	    remove.addListener(SWT.Selection, new Listener() {
			public void handleEvent(Event e) {
				if (e.type != SWT.Selection) return;
				if (SettingsView.reporters.getItemCount() <= 0) return;
				
				int index = SettingsView.reporters.getSelectionIndex();
				if (index != -1) SettingsView.reporters.remove(index);
			}
		});
	}
}
