# NetLogo-D
NetLogo-D enables NetLogo users to conduct simulations in a distributed manner.

## Prerequisite
You should have MySQL running on your server.
NetLogo-D assumes that your NetLogo simulation has conventional 'setup' and 'go' procedures

## How to use NetLogo-D
1. **Run NetLogo-D server**
	* You should have MySQL running on your server
	* Otherwise, NetLogo-D will fail to be executed
2. **Fill the form in settings tab**
	* When you fill all the settings and press store button, task-table and data-table is created in your specified MySQL database
3. **Goto MySQL and fill the task table**
	* Currently, you should this **by yourself**
	* Automatic task-table-filling feature will be developed in the next version
4. **Run NetLogo-D client**
	* When you specify the server address and press connect button, the client will download the NetLogo file from the server and conduct simulations
	* On finishing each simulation, the client sends the simulation result to the server
5. **Collect simulation results**
	* On receiving the simulation results, NetLogo-D server will store them in MySQL data-table 

## Settings
* **MySQL**
	* **MySQL connection** This connection string specifies the server address, port and MySQL database name (ex: jdbc:mysql://localhost:3306/netlogo)
	* **MySQL ID** MySQL login ID
	* **MySQL password** MySQL login password
	* **MySQL task table** In NetLogo-D, a task is a set of parameter values, and the values are stored in a task table as a record
	* **MySQL data table** In NetLogo-D, data is a set of simulation results, and the values are stored in a data table as a record
* **Etc**
	* **NetLogo file** Specify the NetLogo file that you want run
	* **Simulation iteration** Iteration specifies how many times the 'go' is performed in a simulation
	* **Simulation repetition** Repetition specifies how many times a simulations is performed
* **Parameters**
	* You can add or remove parameters
	* Parameters are input values of your simulation
* **Reporters**
	* You can add or remove reporters
	* Reporters are output values (or results) of your simulation
	
## Screenshots
[NetLogo-D server](./screenshot/server.png)
[NetLogo-D client](./screenshot/client.png)


	