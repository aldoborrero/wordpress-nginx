# ------------------------------------------------------------------------------
#	Virtual Host:
#		- http://domain.com
#
#	Main Options:
#		- Redirects www to non www
#		- Main website is handled by Wordpress with MU enabled… or not, depends on you ;)
#
#	Info:
#		- Nginx is behind Varnish Cache
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Virtual host:
#		- http://www.domain.com
#
#	Description:
# 	- www.domain.com -> domain.com
# ------------------------------------------------------------------------------

server {
	server_name		www.domain.com;
	listen				8080;
	return 301		$scheme://domain.com$request_uri;
}

# ------------------------------------------------------------------------------
# Virtual host:
#		- http://domain.com
#
#	Description:
# 	- My main website implemented in Wordpress
#
#	Info:
#		- server_name uses .domain.com, that way Wordpress MU will handle all 
#			subdomains with no problem!
#
# TODO:
#   - Enable security measures for WordPress
# ------------------------------------------------------------------------------

server {
	server_name		.domain.com;
	listen				8080;
	root					/path/to/wordpress;
	
	access_log		/var/log/nginx/domain.access.log main buffer=32k;
	error_log			/var/log/nginx/domain.error.log error;
	#error_log		/var/log/nginx/domain.debug.log debug;
	
	# Locations
	
	# Pretty Permalinks with Wordpress
  # Note that I'm using W3 Total Cache
	location / { try_files try_files /wp-content/w3tc-$host/pgcache/$request_uri/_index.html $uri $uri/ /index.php?$args; }
	
	# About caching
	include 			common-locations.conf;
	
  # Working on it
	#include 			wordpress-mu-files.conf;
	
	# PHP
	location ~ \.php$ {
		try_files		$uri =404;
		
		fastcgi_split_path_info ^(.+\.php)(/.+)$;
		fastcgi_pass    	127.0.0.1:9000;
		fastcgi_index   	index.php;
		
		include		fastcgi_params;
	}
}
