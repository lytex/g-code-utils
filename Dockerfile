# Runs the g-code-utils JavaFX GUI inside a container, displaying on the host
# X server (works with XWayland on Wayland desktops). See docker-run.sh.
#
#   docker build -t g-code-utils .
#   ./docker-run.sh
#
# The app targets Java 8 + JavaFX, which Debian no longer ships; OpenJDK 17
# with the Debian OpenJFX package runs the same assembly jar unchanged.
FROM debian:bookworm-slim

ARG JAR=g-code-utils-assembly-1.2.1.jar

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      openjdk-17-jre \
      openjfx \
      libgl1 \
      libgl1-mesa-dri \
      libgtk-3-0 \
      libxxf86vm1 \
      libxtst6 \
      fonts-dejavu \
      fontconfig \
 && rm -rf /var/lib/apt/lists/*

COPY ${JAR} /opt/g-code-utils/g-code-utils.jar

# The app reads/writes ./settings.config, so run from a writable directory
# that docker-run.sh bind-mounts from the host to persist settings.
WORKDIR /data

ENV NO_AT_BRIDGE=1 \
    JAVA_TOOL_OPTIONS="-Dawt.useSystemAAFontSettings=on -Dprism.lcdtext=false"

ENTRYPOINT ["java", \
            "--module-path", "/usr/share/openjfx/lib", \
            "--add-modules", "javafx.controls,javafx.fxml", \
            "-jar", "/opt/g-code-utils/g-code-utils.jar"]
