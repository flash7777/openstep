FROM smallstep/step-ca:latest

# step-ca mit ACME-Provisioner fuer nuhost6
# Konfiguration per Environment und init-Script

COPY init-ca.sh /usr/local/bin/init-ca.sh
RUN chmod +x /usr/local/bin/init-ca.sh

ENV STEPPATH=/home/step
ENV CA_NAME=nuhost6-ca
ENV CA_DNS=step-ca
ENV CA_ADDRESS=:9000
ENV ACME_PROVISIONER=acme

VOLUME /home/step
EXPOSE 9000

ENTRYPOINT ["init-ca.sh"]
