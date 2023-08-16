build:
	sudo docker build -t plumber-api .
	
run:
	sudo docker run --network host -p 4114:4114 plumber-api
