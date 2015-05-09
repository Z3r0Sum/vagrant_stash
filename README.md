#Stash with HA PostgreSQL

##Credits

* Special thanks to the puppet community developers and Puppetlabs individuals who worked on the stash and postgresql modules as well as their dependencies.

* Those projects can be found here:

	https://github.com/puppet-community/puppet-stash 
	
	https://github.com/puppetlabs/puppetlabs-postgresql
	

##Purpose

* To quickly demonstrate how to standup a Stash environment with two PostgreSQL servers for redundancy.
* In a real prod environment this would be much more robust.  This is just to give one a starting point.  You would also probably want Stash Server redundancy and maybe a reverse proxy stood up as well.  See the Stash documentation for an architecture that meets your needs.  
* Additionally, to simplify the amount of Vagrant boxes required, the master PostgreSQL server is being implemented alongside the Stash server.

##Assumptions

 1. Every Vagrant file is using the Fusion provider.  The box being used is also available in virtualbox, but you'll need to make the Vagrantfile adjustments.
 
 ```ruby
 #Use fusion provider
  config.vm.provider "vmware_fusion" do |v|
      v.vmx["memsize"]  = "2048"
      v.vmx["numvcpus"] = "2"
  end
```

 2. The /etc/hosts file on each server is being used for name resolution.
 3. Vagrant is assigning static IPs.  
 4. A strict roles and profiles model was **not** adhered to for this project, so it might seem a bit wonky if you're a puppet evangelist.
 5. Below is the DB User Credential info (this would be stored in an eyaml backend if this was not a masterless puppet setup):
 
 - The DB Superuser is postgres.
    

    ```yaml
    pgsql_server::postgres_password: 'supersecret'
    pgsql_server::ipv4acls: 'host stashdb stashuser all trust'
    pgsql_server::db_name: 'stashdb'
    pgsql_server::user: 'stashuser'
    pgsql_server::password: 'password'
    pgsql_server::role: 'stashuser'    
    ```
 

##Procedures to Stand Up Environment

1. Adjust the provider in the Vagrant files if necessary.
2. The 'bootstrap\_project.sh' script can be run to startup the environment in the proper order.

    Execute inside the root of the project's directory:
    

 	```shell
     cd ###TODO add directory
     ./boot_strap_project.sh
    ```
    
    
   Takes roughly 5-10 minutes.
   View the above script if you need to check the boot order.
    
3. Once everything is up, you should be able to navigate to 172.16.254.11:7990 in a browser for the initial Stash setup.
     
##Testing DB Failover 


###Failover Background


* Automatic failover is setup between 'stash-server' and 'production-db-standby'
* The 'production-db-standby' server is leveraging the 'restore\_bkup.rb' located under the production-standby Vagrant project.  The script is run for the standby server to startup correctly.
    - The standby server needs a restored copy from the master server in order to work.  It is pulling the restore files from /mnt/db\_bkup.  The backup was performed at the end of the 'stash-server' Vagrantfile configuration.  A cron entry was also added in root's crontab on the 'stash-server' to perform a weekly backup.
    - See https://wiki.postgresql.org/wiki/Hot_Standby for more details.
    
* Since we're running 'hot standby', the 'production-db-standby' can perform read-only queries right away. 


###Failover Trigger
* The trigger would normally be some monitoring software like nagios or something custom written to perform a health check at both the server and database levels.
* We're going to simulate this behavior by creating the trigger file that PostgreSQL looks for, which would have been generated by a monitoring trigger.

1. ```cd production-standby```
2. ```vagrant ssh```
3. ```sudo su -```
4. ```touch /var/lib/pgsql/data/trigger_failover.txt```
5. ```grep failover /var/lib/pgsql/data/pg_log/*```
6. If you ```less``` the logs in the above directory the standby will state it is ready.

	```shell
	LOG:  archive recovery complete
	LOG:  database system is ready to accept connections
	LOG:  autovacuum launcher started
	```
	
7. I have yet to find a way to add more than one PostgreSQL server to the jdbc.url string in the 'stash-config.properties' file.  If you know of a way, please submit a pull request updating the 'stash-server' Vagrant project under: ```puppet/modules/profiles/stash/server.pp``` as well as update this README.
	
	1. You'll definitely want to update your puppet code as well as make the change when a failover happens.  In a prod environment this could get rather tricky if you have puppet running to manage drift (I hope you do...).  You could have a custom facter fact get updated at the time of a failover, which would trigger a change in the jdbc.url string as it would be a part of the 'dburl' attribute.
  
		i.g.
		```puppet
  		dburl => "jdbc:postgresql://${fact_dbmaster}:5432/${db_name}",
		```
		
	 Hopefully Atlassian does, maybe I'm ignorant to it, or in the future will support specifying multiple servers in the jdbc.url string as it seems PostgreSQL is able to handle it with a string like the following:
  

		```shell
 		jdbc:postgresql://localhost:5432/${db_name},production-db-standby:5432/${db_name}
 		```
	
		
8. You'll need to restart stash in order for the connections to the new DB server to be picked up: ```systemctl restart stash```


##How to Contribute

* Fork the project
* Create a feature branch
* Commit your changes
* Submit a pull request








