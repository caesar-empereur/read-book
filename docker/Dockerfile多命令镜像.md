FROM java:8

RUN apt-get update -y dracut
RUN apt install net-tools -y dracut
RUN apt install iputils-ping -y dracut

ADD webapi-service-1.0.jar app.jar
ENTRYPOINT java -jar -Xmx=400m -Xms=300m /app.jar
