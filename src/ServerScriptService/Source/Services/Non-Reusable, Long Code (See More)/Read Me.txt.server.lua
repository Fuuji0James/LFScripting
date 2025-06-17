--[=[
	-- FUUJI (6/5/2025 // Most Recent)
	
	    |						 	  |	
	----|---- What is a Service?  ----|----
	    |							  |
	    |							  |
	    |							  |
	    
	    A service is long code that is only initialized ONCE by the server management script
	    Its goal is to solve the problem of client-server connection where the client (controller) sends a value
	    	and the service recieves it. Think of a service as a server-sided controller that instead of deleting 
	    	and starting over its 'Init' processes etc again, it runs ONCE, and can be used only by controllers
	    	through remote events.
	    This seems to be a concise way of handling this while not creating too many (if any) useless dependencies.
	    *This is just a test run so even this is subject to change.	    	
]=]