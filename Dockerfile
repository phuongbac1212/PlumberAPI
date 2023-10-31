# Use the official R base image
FROM rstudio/plumber

# Install necessary system packages
RUN apt-get update && apt-get install -y mysql-server mysql-client libmysqlclient-dev


# Install required R packages
RUN Rscript -e "install.packages(c('plumber', 'R6', 'RMariaDB', 'lubridate', 'wkb'))"

# Copy your R script into the image
RUN mkdir /home/PlumberApi/
COPY plumber.R GPSTime.R AuxiliaryClass.R /home/PlumberApi/

# Expose the port your API will run on
EXPOSE 4114

# Command to run your API when the container starts
CMD ["Rscript", "-e /home/PlumberApi/plumber.R"]
