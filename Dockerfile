FROM wordpress:4.8.3-php5.6-apache

# Install ModSecurity
RUN set -ex; \
        \
        apt-get update; \
        apt-get install -y \
                libapache2-modsecurity \
        ; \
        rm -rf /var/lib/apt/lists/*

# Move, Edit, and Link Files
RUN mv /etc/modsecurity/modsecurity.conf-recommended  /etc/modsecurity/modsecurity.conf && \
    sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/modsecurity/modsecurity.conf && \
    ln -s /usr/share/modsecurity-crs/slr_rules/modsecurity_46_slr_et_wordpress.data /etc/modsecurity/modsecurity_46_slr_et_wordpress.data && \
    ln -s /usr/share/modsecurity-crs/slr_rules/modsecurity_crs_46_slr_et_wordpress_attacks.conf /etc/modsecurity/modsecurity_crs_46_slr_et_wordpress_attacks.conf && \
    ln -s /dev/stdout /var/log/apache2/modsec_audit.log

COPY ./modsecurity_custom_rules.conf /etc/modsecurity/
