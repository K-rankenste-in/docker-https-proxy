# edge needed for apache2-http2
FROM alpine:edge
MAINTAINER Candid Dauth <cdauth@cdauth.eu> 

RUN apk update && apk add \
	curl tar \
	gcc libffi-dev musl-dev openssl-dev py-virtualenv py-pip python-dev \
	apache2 apache2-http2 apache2-proxy apache2-ssl \
	bash parallel vim

RUN curl -L https://github.com/kuba/simp_le/archive/master.tar.gz | tar -xz -C /usr/local/share --transform 's@^simp_le-master@simp_le@' && \
	cd /usr/local/share/simp_le && \
	./bootstrap.sh && \
	./venv.sh && \
	ln -s /usr/local/share/simp_le/venv/bin/simp_le /usr/local/bin/

COPY custom.conf /etc/apache2/conf.d/custom.conf
COPY start.sh mkconfig.sh renew-ssl.sh /usr/local/bin/

RUN sed -ri /etc/apache2/httpd.conf \
		-e 's@^(\s*)(CustomLog\s)@\1#\2@g' \
		-e 's@^(\s*)(LoadModule mpm_prefork_module modules/mod_mpm_prefork.so)@\1#\2@g' \
		-e 's@^(\s*)(ErrorLog\s)@\1#\2@g' \
	&& \
	sed -ri /etc/apache2/conf.d/mpm.conf -e 's@^(\s*)(PidFile\s)@\1#\2@g' && \
	bash -c 'rm -f /etc/apache2/conf.d/{ssl.conf,userdir.conf,info.conf,proxy.conf}' && \
	mkdir -p /etc/apache2/ssl /etc/apache2/htdocs/.well-known/acme-challenge /run/apache2 && \
	adduser -D -H -s /bin/bash acme && \
	mkdir -p /home/acme/.parallel && \
	chown acme:acme /etc/apache2/htdocs/.well-known/acme-challenge /home/acme/.parallel

CMD ["/bin/bash", "/usr/local/bin/start.sh"]

VOLUME ["/etc/apache2/ssl"]

EXPOSE 80 443
