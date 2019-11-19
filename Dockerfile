FROM maven:3-jdk-8-alpine
RUN apk --no-cache add curl

WORKDIR /opt/opentripplanner
RUN curl -sSfL https://github.com/HSLdevcom/OpenTripPlanner/archive/20191113.tar.gz \
        | tar --strip-components 1 -xzf - \
    && mvn -Dmaven.test.skip=true package

# ---

FROM openjdk:8-jre-alpine
RUN apk --no-cache add curl ttf-dejavu

WORKDIR /opt/opentripplanner

COPY --from=0 /opt/opentripplanner/target/*-shaded.jar ./otp-shaded.jar

# http://docs.opentripplanner.org/en/latest/Configuration/#graph-build-configuration
COPY ./build-config.json /var/otp/graphs/cfm/

RUN cd /var/otp/graphs/cfm \
    && curl -sSfL -o ./STWMS.zip \
        # https://www.stadtwerke-muenster.de/privatkunden/mobilitaet/fahrplaninfos/fahr-netzplaene-downloads/open-data-gtfs/gtfs-download.html
        https://www.stadtwerke-muenster.de/fileadmin/stwms/busverkehr/kundencenter/dokumente/GTFS/stadtwerke_feed_20191028.zip \
    && curl -sSfL -o ./muenster-regbez.pbf \
        # https://download.geofabrik.de/europe/germany/nordrhein-westfalen/
        https://download.geofabrik.de/europe/germany/nordrhein-westfalen/muenster-regbez-191118.osm.pbf \
    && java -Xmx10g -jar /opt/opentripplanner/otp-shaded.jar --build . \
    && rm ./muenster-regbez.pbf ./STWMS.zip

EXPOSE 8080
CMD ["java", \
        "-jar", "/opt/opentripplanner/otp-shaded.jar", \
        "--server"]