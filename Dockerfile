# The Dockerfile defines the image's environment
# Import Python runtime and set up working directory
FROM python:2.7-alpine
#WORKDIR /app
#ADD . /app


# Open port 80 for serving the webpage
EXPOSE 1888

# Run app.py when the container launches
CMD ["cat"]
