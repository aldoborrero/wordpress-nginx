server {
	listen        8080 default_server;
	server_name   _;

	include       error-pages.conf;

	return        403;
}
