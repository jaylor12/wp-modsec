FROM wordpress:4.9.8-php7.2-apache

# Install ModSecurity and sendmail
RUN set -ex; \
        \
        apt-get update; \
        apt-get install -y --no-install-recommends\
                libapache2-mod-security2 modsecurity-crs sendmail \
        ; \
        rm -rf /var/lib/apt/lists/*

# Move, Edit, and Link Files
RUN mv /etc/modsecurity/modsecurity.conf-recommended  /etc/modsecurity/modsecurity.conf && \
    sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/modsecurity/modsecurity.conf && \
    ln -s /dev/stdout /var/log/apache2/modsec_audit.log

# Configure php to use sendmail (from https://github.com/docker-library/wordpress/issues/30)
# Create script to use as new entrypoint, which
# 1. Creates a localhost entry for container hostname in /etc/hosts
# 2. Restarts sendmail to discover this entry
# 3. Calls original docker-entrypoint.sh
RUN echo "sendmail_path=sendmail -t -i" >> /usr/local/etc/php/conf.d/sendmail.ini && \
    echo '#!/bin/bash' >> /usr/local/bin/docker-entrypoint-wrapper.sh && \
    echo 'set -euo pipefail' >> /usr/local/bin/docker-entrypoint-wrapper.sh && \
    echo 'echo "127.0.0.1 $(hostname) localhost localhost.localdomain" >> /etc/hosts' >> /usr/local/bin/docker-entrypoint-wrapper.sh && \
    echo 'service sendmail restart' >> /usr/local/bin/docker-entrypoint-wrapper.sh && \
    echo 'exec docker-entrypoint.sh "$@"' >> /usr/local/bin/docker-entrypoint-wrapper.sh && \
    chmod +x /usr/local/bin/docker-entrypoint-wrapper.sh

# Copy in custom rules, if any
COPY ./modsecurity_custom_rules.conf /etc/modsecurity/

ENTRYPOINT ["docker-entrypoint-wrapper.sh"]

CMD ["apache2-foreground"]
