FROM java:8
ADD webapi-service-1.0.jar app.jar
ENTRYPOINT java -jar -Xmx=400m -Xms=300m /app.jar
