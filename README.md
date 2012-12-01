# NetLogo-D
NetLogo-D enables NetLogo users to conduct simulations in a distributed manner.

## Prerequisite
You should have MySQL running on your server.

## How to use NetLogo-D
1. Run NetLogo-D server
	* You should have MySQL running on your server
	* Otherwise, NetLogo-D will failed to be executed
2. Fill the form in settings tab
	* When you fill all the settings and press store button, task-table and data-table is created in your specified MySQL database
3. Goto MySQL and fill the task table
	* Currently, you should this **by yourself**
	* Automatic task-table-filling feature will be developed in the next version
4. Run NetLogo-D client
	* When you specify the server address and press connect button, the client will download the NetLogo file from the server and conduct simulations
	* On finishing each simulation, the client sends the simulation result to the server
5. Collect simulation results
	* On receiving the simulation results, NetLogo-D server will store them in MySQL data-table 

## Settings
* MySQL
	* **MySQL connection** 
	> jdbc:mysql://localhost:3306/netlogo
* Etc
	* **NetLogo file** Specify the NetLogo file that you want run
	* **Simulation iteration** Iteration specifies how many times the 'go' is performed in a simulation
	* **Simulation repetition** Repetition specifies how many times a simulations is performed
